# Elastic APM Module

This module adds support to enable Elastic APM on the servers you start inside CommandBox.  

## Installation

Install the module like so:

```bash
install commandbox-elastic-apm
```

Every server that starts will have the JVM args to add the elastic APM java agent.  

# Configuration

You can configure your Elastic APM client in the `server.json` like so:

```js
{
  "elasticAPM" : {
    "enable" : false,
    "installID" : "jar:https://repo1.maven.org/maven2/co/elastic/apm/elastic-apm-agent/1.24.0/elastic-apm-agent-1.24.0.jar",
    "settings" : {
      "SERVICE_NAME" : "${serverinfo.name}",
      "SERVER_URL" : "http://elk-host.local:8200",
      "ENVIRONMENT" : "${ENVIRONMENT}",
      "USE_PATH_AS_TRANSACTION_NAME" : true      
    }
  }
}
``` 
The keys in the `settings` struct above would be turned into these enviroment variables for you.

* `ELASTIC_APM_SERVICE_NAME`
* `ELASTIC_APM_SERVER_URL`
* `ELASTIC_APM_ENVIRONMENT`
* `ELASTIC_APM_USE_PATH_AS_TRANSACTION_NAME`

The possible settings are defined by Elastic APM here:
https://www.elastic.co/guide/en/apm/agent/java/current/configuration.html
    
The `enable` flag defaults to true and the `installID` defaults to a recent version of the jar.  These are optional and you don't need to provide them unless you're overriding a default.