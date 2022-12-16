# Nebula Environment Metadata

Provides a method to store metadata values so that each environment (production, sandbox, scratch org, etc)
can have its own version of the value. These values can all be stored together in source control and exist in every 
environment. 

This library provides an API to access values so that code using it will automatically read whichever 
value is relevant for the current environment. It's like having environment variables stored directly on the platform!

## Installation

- URL: /packaging/installPackage.apexp?p0=04t6M000000gazOQAQ
- SFDX project as "Nebula Environment Metadata": "04t6M000000gazOQAQ"

## Why?

Values may have to be different between different environments. Say, for example, you have an integration to an 
external system. You would not want a sandbox Salesforce environment to access the production instance of the external 
system. So, you can have a Named Credential for the production external system and separate Named Credential for the 
sandbox. 

Apex code calling the external system can then read an 
Environment Metadata Property to specify which Named Credential to use. 

Both Named Credentials and both Environment Metadata Properties exist in production. As soon as you make a 
new sandbox, the sandbox will automatically switch to using the sandbox version of the Named Credential.

## What can I store?

This package includes a Custom Metadata Type called Environment for specifying each of your environments. It also 
includes Property for storing basic key-value pairs for each environment. 

You can also add a Lookup field from your 
own Custom Metadata Type to Environment. And then use the API here to get the right metadata records for whichever 
environment your code is running in. 

## How do I specify environments?

Environments are specified via their base URL e.g. https://company.my.salesforce.com for production or 
https://company--uat.my.salesforce.com for UAT. This works best for companies using My Domain. Although it's now 
possible to get a sandbox name using the Domain class, that still returns null for scratch orgs.  

A default configuration may exist with no URL specified. This allows for scratch orgs where the actual URL will keep 
changing, and also for the situation where you don't need a different value for each environment.

## The Custom Metadata

There are two custom metadata types defined here: Environment, and Property. 

One environment has many properties, and 
the properties are where individual values are stored e.g. for storing two properties, "Remote" and "Currency", in two 
environments, "Production" and "UAT", the records may be organised like this:

  - Environment: Production
    - Property: Remote = https://livesystem.com
    - Property: Currency = USD
  - Environment: UAT
      - Property: Remote = https://uat.livesystem.com
      - Property: Currency = GBP

### Custom Metadata Type: Environment

Example data:

| Name       | Org Domain URL                         |
|------------|----------------------------------------|
| Production | https://company.my.salesforce.com      |
| UAT        | https://company--uat.my.salesforce.com |
| Default    |                                        |

Each environment record serves as a reference for other metadata. The Name is not significant to the 
implementation, so it can be whatever you find to be descriptive. The Org Domain URL must match the value returned by 
`Url.getOrgDomainUrl().toExternalForm()` in the org where you want the setting to be active.

The environment with no Org Domain URL is regarded as the default, irrespective of its name. 

### Custom Metadata Type: Property

Properties are for unstructured metadata in a basic `key: value` form. So, they may be the sort of thing you would think 
of storing in a hierarchy custom setting or label. If you want to store lists of metadata, then define a custom metadata type 
(see below).

Their structure is simple, for example:

| Name                 | Key      | Value            | Environment | 
|----------------------|----------|------------------|-------------|
| My Label: Production | My_Label | Production Value | Production  |
| My Label: UAT        | My_Label | UAT Value        | UAT         |

Name can be anything you want. Environment is a reference to an instance of the Environment custom metadata type. Keys 
must match for items you consider to be the same.

### Custom Metadata Type: Other

You can use any other metadata type by adding a Metadata Relationship field to your type, linking it to Environment. You
may then create multiple records of your type for each environment and use the Apex API to access the relevant ones for 
your current environment. 

## Matching values in environments

Values in environments are matched by looking at their Environment reference and the Org Domain URL within it. Matching
happens in order of preference

1. If there is a custom metadata record associated with an Environment that matches `Url.getOrgDomainUrl().toExternalForm()`,
   then that record is returned.
2. If there is a record in an Environment with no Org Domain URL set, then that record is returned.
3. Otherwise, nothing is returned. This form that "nothing" takes depends on the API you use to access the property
 

## Apex Interface

Of course, you may query the metadata records directly. Convenience methods are provided which respect the rules of 
matching described above. These methods can give you all the metadata for the current environment or read a key at a time.

### Apex Interface: Properties

Metadata stored in the Property custom metadata type can be read via the [EnvironmentProperties](force-app/main/default/classes/EnvironmentProperties.cls) class e.g.

    nebc.EnvironmentProperties.get('My_Label')

### Apex Interface: Other Custom Metadata Types

Custom metadata types that have added a reference to Environment can use [EnvironmentMetadata](force-app/main/default/classes/EnvironmentMetadata.cls)
to access either all the metadata records for the current environment or a single record.

The custom metadata type must have a key (it can be compound key across multiple fields), or else the 
notion of overriding doesn't make sense. When you construct an instance of EnvironmentMetadata, you must supply the 
SObjectType of the metadata, and the key e.g.

    nebc.EnvironmentMetadata myEnvironmentMetadata = new nebc.EnvironmentMetadata(My_Type__mdt.SObjectType, My_Type__mdt.Key__c);

OR

    nebc.EnvironmentMetadata myEnvironmentMetadata = new nebc.EnvironmentMetadata(My_Type__mdt.SObjectType)
        .addKeyField(My_Type__mdt.Key_1__c)
        .addKeyField(My_Type__mdt.Key_2__c);


EnvironmentMetadata will examine the types to find how it is linked to Environment. You may then read records with 
values on the key:

    My_Type__mdt record = (My_Type__mdt)myEnvironmentMetadata.get(key);
    My_Type__mdt record = (My_Type__mdt)myEnvironmentMetadata.get(new My_Type__mdt(Key_1__c = val1, Key_2__c = val2));
    My_Type__mdt record = (My_Type__mdt)myEnvironmentMetadata.get(new Map<String, Object>{'Key_1__c' => val1, 'Key_2__c' => val2});

Where the `key` could be a single value (if there is only one key field), or an SObject with the key fields filled in, or
a map with the key fields in.

Or get all metadata records for this environment:

    List<My_Type__mdt> records = myEnvironmentMetadata.getAll();

The returned list will be for this environment and also unique based on your supplied key. 

### Apex Interface: LWC

[EnvironmentPropertiesLwc](force-app/main/default/classes/EnvironmentPropertiesLwc.cls) provides two `AuraEnabled` 
methods to access the properties. You can use `get(key)` to get a single property or `getAll()` to get all current
keys/values as a map/Javascript object.

### Apex Interface: Flow

[FlowEnvironmentProperty.getProperty()](force-app/main/default/classes/FlowEnvironmentProperty.cls) provides access to
the properties in Flow. You will find it as an Apex Action called "Get Environment Property" under the category 
"Configuration".