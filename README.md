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

There are two custom metadata types defined here: Environment, and Property. One environment has many properties, and 
the properties are where actual values are stored e.g. for storing two properties, "Remote" and "Currency", in two 
environments, "Production" and "UAT", the records may be organised like this:

  - Environment: Production
    - Property: Remote = https://livesystem.com
    - Property: Currency = USD
  - Environment: UAT
      - Property: Remote = https://uat.livesystem.com
      - Property: Currency = GBP

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

## Matching values in environments

Values in environments are matched by looking at their Environment reference and the Org Domain URL within it. 

If there is a custom metadata record associated with an Environment that matches `Url.getOrgDomainUrl().toExternalForm()`,
then that record is returned. If there is a record in an Environment with no Org Domain URL set, then that record is returned.

## Apex Interface

Of course, you may query the metadata records directly. Convenience methods are provided which respect the rules of 
matching described above. These methods can give you all the metadata for the current environment or read a key at a time.

### Apex Interface: Properties

Metadata stored in the Property custom metadata type can be read via the [EnvironmentProperties](force-app/main/default/classes/EnvironmentProperties.cls) class e.g.

    EnvironmentProperties.get('My_Label')

### Apex Interface: Other Custom Metadata Types

Custom metadata types that have added a reference to Environment can use [EnvironmentMetadata](force-app/main/default/classes/EnvironmentMetadata.cls)
to access either all the metadata records for the current environment or a single record.

The custom metadata type must have a key (it can be compound key across multiple fields), or else the 
notion of overriding doesn't make sense. When you construct an instance of EnvironmentMetadata, you must supply the 
SObjectType of the metadata, and the key e.g.

    EnvironmentMetadata myEnvironmentMetadata = new EnvironmentMetadata(My_Type__mdt.SObjectType, My_Type__mdt.Key__c);

OR

    EnvironmentMetadata myEnvironmentMetadata = new EnvironmentMetadata(My_Type__mdt.SObjectType)
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