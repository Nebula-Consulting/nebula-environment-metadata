# Nebula Environment Metadata

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

### Custom Metadata Type: Property

Properties are for unstructured metadata in a basic `key: value` form. So, they may be the sort of thing you would think 
of storing in a hierarchy custom setting or label. If you want to store lists of metadata, then define a custom metadata type 
(see below).

Their structure is simple, for example:

| Name | Key | Value | Environment | 
| --- | --- | --- | --- |
| My Label: Production | My_Label | Production Value | Production |
| My Label: UAT | My_Label | UAT Value | UAT |

Name can be anything you want. Environment is a reference to an instance of the Environment custom metadata type. Keys 
must match for items you consider to be the same.

### Custom Metadata Type: Other

You can use any other metadata type by adding a Metadata Relationship field to your type, linking it to Environment. You
may then create multiple records of your type for each environment and use the Apex API to access the relevant ones for 
your current environment. 

## Apex Interface

Of course, you may query the metadata records directly. Convenience methods are provided to access properties which can
give you all the metadata for the current environment or read a key at a time

### Apex Interface: Properties

Metadata stored in the Property custom metadata type can be read via the [EnvironmentProperties](force-app/main/default/classes/EnvironmentProperties.cls) class e.g.

    EnvironmentProperties.get('My_Label')

If there is an exact match for this key, associated with an Environment that matches `Url.getOrgDomainUrl().toExternalForm()`,
then that value is returned. If there is a key in an Environment with no Org Domain URL set, then that value is returned. If
no key matches, `null` is returned.

### Apex Interface: Other Custom Metadata Types

Custom metadata types that have added a reference to Environment can use [EnvironmentMetadata](force-app/main/default/classes/EnvironmentMetadata.cls)
to access either all the metadata records for the current environment or a single record.

The custom metadata type must have some notion of a key (it can be compound key across multiple fields), or else the 
notion of overriding doesn't make sense. When you construct an instance of EnvironmentMetadata, you must supply the 
SObjectType of the metadata, and the key e.g.

    EnvironmentMetadata myEnvironmentMetadata = new EnvironmentMetadata(My_Type__mdt.SObjectType, My_Type__mdt.Key__c);

EnvironmentMetadata will examine the types to find how it is linked to Environment. You may then read records with 
values on the key:

    My_Type__mdt record = (My_Type__mdt)myEnvironmentMetadata.get(key);