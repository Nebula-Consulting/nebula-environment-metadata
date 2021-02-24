# Nebula Environment Properties

Provides a method to store property values in metadata so that each environment (production, sandbox, scratch org, etc)
can have its own value. These values can all be stored simultaneously, and accessed transparently via an Apex
API.

Environments are specified via their base URL e.g. https://company.my.salesforce.com for production or 
https://company--uat.my.salesforce.com for UAT. This works best for companies using My Domain and it's a 
workaround for the inability to detect the current sandbox name from Apex.  

A default configuration may exist with no URL specified. This allows for scratch orgs where the actual URL will keep 
changing, and also for the situation where you don't need a different value for each environment.

## The Custom Metadata

There are two custom metadata types defined here:

### Custom Metadata Type: Environment

| Name | Org Domain URL |
| --- | --- |
| Production | https://company.my.salesforce.com |
| UAT | https://company--uat.my.salesforce.com |
| Default |  |

Each environment record serves simply as a reference for other metadata. The Name is not significant to the 
implementation, so it can be whatever you find to be descriptive. The Org Domain URL must match the value returned by 
`Url.getOrgDomainUrl().toExternalForm()` in the org where you want the setting to be active.

The environment with no Org Domain URL is regarded as the default, irrespective of its name. 

So, when a property is accessed, the default is read first and then overridden 