component {

	function configure() {

		settings = {
			'enable' : true,
			'installID' : 'jar:https://repo1.maven.org/maven2/co/elastic/apm/elastic-apm-agent/1.24.0/elastic-apm-agent-1.24.0.jar',
			'settings' : {
				
			}
		};

	}

	function onServerStart( required struct interceptData ) {
		var job = wirebox.getInstance( 'interactiveJob' );
		var serverService = wirebox.getInstance( 'ServerService' );
		var configService = wirebox.getInstance( 'ConfigService' );
		var systemSettings = wirebox.getInstance( 'SystemSettings' );
		var filesystemUtil = wirebox.getInstance( 'filesystem' );

		var serverInfo = arguments.interceptData.serverInfo;
		var serverJSON = arguments.interceptData.serverJSON;
		// Get defaults
		var defaults = duplicate( configService.getSetting( 'server.defaults', {} ) );

		systemSettings.expandDeepSystemSettings( defaults );

		serverInfo.APMEnable = serverJSON.elasticAPM.enable ?: defaults.elasticAPM.enable ?: settings.enable;

		if( isBoolean( serverInfo.APMEnable ) && serverInfo.APMEnable ) {

			job.addLog( '******************************************' );
			job.addLog( '* CommandBox Elastic APM Module Loaded *' );
			job.addLog( '******************************************' );

			// Get all of our defaulted settings
			
			serverInfo.APMInstallID = serverJSON.elasticAPM.installID ?: defaults.elasticAPM.installID ?: settings.installID;
			serverInfo.APMHomeDirectory = ( serverInfo.serverHomeDirectory ?: serverInfo.serverHome ?: serverInfo.webConfigDir & '/' & replace( serverInfo.cfengine, '@', '-' ) ) & '/apm/';

			// Optimize installation for the default ForgeBox package
			var endpointService = wirebox.getInstance( 'endpointService' );
			var packageService = wirebox.getInstance( 'packageService' );
			var semanticVersion = wirebox.getInstance( 'semanticVersion@semver' );
			var endpointData = endpointService.resolveEndpoint( serverInfo.APMInstallID, 'fake' );
			var skipInstall = false;
			
			// Are we installing the "apm" endpoint APMom ForgeBox
			if( packageService.isPackage( serverInfo.APMHomeDirectory ) ) {

				var APMBoxJSON = packageService.readPackageDescriptor( serverInfo.APMHomeDirectory );
				if( ( APMBoxJSON.installPaths ?: {} ).count() ) {
					var APMClientBoxJSON = packageService.readPackageDescriptor( serverInfo.APMHomeDirectory.listAppend( APMBoxJSON.installPaths[ APMBoxJSON.installPaths.keyArray().first() ], '/' ) );

					var updateData = endpointData.endpoint.getUpdate( serverInfo.APMInstallID, APMClientBoxJSON.version, serverinfo.verbose );
					if( !updateData.isOutdated ) {
						job.addLog( 'Your Elastic APM version [#APMClientBoxJSON.version#] is already the latest, skipping installation.' );
						skipInstall = true;	
					} else {
						job.addLog( 'Your Elastic APM version [#APMClientBoxJSON.version#] does not satisfy [#serverInfo.APMInstallID#].  Installing fresh' );
					}
				}
			}
			
			if( !skipInstall ) {
				var APMBoxJSONFile = serverInfo.APMHomeDirectory & 'box.json';
				if( fileExists( APMBoxJSON ) ) {
					fileDelete( APMBoxJSON );
				}
				// install APM jar and debug binaries
				packageService.installPackage( id=serverInfo.APMInstallID, directory=serverInfo.APMHomeDirectory, currentWorkingDirectory=serverInfo.APMHomeDirectory, save=true, verbose=serverinfo.verbose );	
			}

			var APMBoxJSON = packageService.readPackageDescriptor( serverInfo.APMHomeDirectory );
			// Find the jar, whose name may vary
			var qryJarPath = directoryList(
				serverInfo.APMHomeDirectory.listAppend( APMBoxJSON.installPaths[ APMBoxJSON.installPaths.keyArray().first() ], '/' ),
				false,
				'query',
				'*.jar',
				'name asc',
				'file'
			);
			serverInfo.JVMArgs &= ' "-javaagent:#qryJarPath.directory#/#qryJarPath.name#"';

			var apmSettings = defaults.elasticAPM.settings ?: {};
			apmSettings.append( settings.settings, true );
			apmSettings.append( serverJSON.elasticAPM.settings ?: {}, true );
			apmSettings.each( (k,v)=>{
				var name = ucase( k );
				if( !name.startsWith( 'ELASTIC_APM_' ) ) {
					name = 'ELASTIC_APM_' & name;
				}
				// If this env var already exiss, don't override.  Pre-existing env vars shuold always override server.json, config settings, and module defaults
				if( systemSettings.getSystemSetting( name, '__NOT_EXISTS__' ) == '__NOT_EXISTS__' ) {
					if( serverinfo.verbose ) {
						job.addLog( 'Setting env var [#name#].' );
					}
					systemSettings.setSystemSetting( name, v );
				}
			} );
			
		}

	}

}
