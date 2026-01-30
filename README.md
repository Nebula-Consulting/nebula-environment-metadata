# Nebula Environment Metadata

Provides a method to store metadata values so that each environment (production, sandbox, scratch org, etc)
can have its own version of the value. These values can all be stored together in source control and exist in every 
environment. 

This library provides an API to access values so that code using it will automatically read whichever 
value is relevant for the current environment. It's like having environment variables stored directly on the platform!

## Table of Contents

- [Installation](#installation)
- [Why?](#why)
- [What Can I Store?](#what-can-i-store)
- [How Do I Specify Environments?](#how-do-i-specify-environments)
- [The Custom Metadata](#the-custom-metadata)
  - [Environment Custom Metadata Type](#custom-metadata-type-environment)
  - [Property Custom Metadata Type](#custom-metadata-type-property)
  - [Other Custom Metadata Types](#custom-metadata-type-other)
- [Matching Values in Environments](#matching-values-in-environments)
- [Apex Interface](#apex-interface)
  - [Properties](#apex-interface-properties)
  - [Other Custom Metadata Types](#apex-interface-other-custom-metadata-types)
  - [LWC](#apex-interface-lwc)
  - [Flow](#apex-interface-flow)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Security Model](#security-model)
- [Contributing](#contributing)

## Installation

### Package Installation URL

Install the latest version using this URL:
```
https://login.salesforce.com/packaging/installPackage.apexp?p0=04tQB000000EqTNYA0
```

For sandbox environments:
```
https://test.salesforce.com/packaging/installPackage.apexp?p0=04tQB000000EqTNYA0
```

**Note:** The package ID above (`04tQB000000EqTNYA0`) points to version 1.4.0. Check the [releases](https://github.com/Nebula-Consulting/nebula-environment-metadata/releases) for the latest available version.

### SFDX/Salesforce CLI Installation

Add the package dependency to your `sfdx-project.json`:

```json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true,
      "dependencies": [
        {
          "package": "Nebula Environment Metadata",
          "versionNumber": "1.4.0.LATEST"
        }
      ]
    }
  ]
}
```

Or use the package ID directly: `04tQB000000EqTNYA0`

**Note:** This package requires the **Nebula Core** package as a dependency, this must be manually installed.

## Why?

Values may have to be different between different environments. Say, for example, you have an integration to an 
external system. You would not want a sandbox Salesforce environment to access the production instance of the external 
system. So, you can have a Named Credential for the production external system and a separate Named Credential for the 
sandbox. 

Apex code calling the external system can then read an 
Environment Metadata Property to specify which Named Credential to use. 

Both Named Credentials and both Environment Metadata Properties exist in production. As soon as you make a 
new sandbox, the sandbox will automatically switch to using the sandbox version of the Named Credential.

### Use Cases

- **Integration Endpoints**: Different API endpoints for production, UAT, and development environments
- **Feature Flags**: Enable/disable features per environment
- **Configuration Values**: Store environment-specific settings like batch sizes, timeouts, or thresholds
- **Named Credentials**: Reference different Named Credentials for each environment
- **External IDs**: Store different external system IDs for integration purposes

## What can I store?

This package includes a Custom Metadata Type called Environment for specifying each of your environments. It also 
includes Property for storing basic key-value pairs for each environment. 

You can also add a Lookup field from your 
own Custom Metadata Type to Environment. And then use the API here to get the right metadata records for whichever 
environment your code is running in. 

## How do I specify environments?

Environments are specified via their base URL e.g. `https://company.my.salesforce.com` for production or 
`https://company--uat.sandbox.my.salesforce.com` for UAT. This works best for companies using My Domain. 

The system will match environments using any of the following:
- Full URL from `Url.getOrgDomainUrl().toExternalForm()` (e.g., `https://company.my.salesforce.com`)
- Full My Domain hostname from `DomainCreator.getOrgMyDomainHostname()` (e.g., `company.my.salesforce.com`)
- Just the My Domain subdomain (e.g., `company` or `company--uat`)

A **default** configuration may exist with no URL specified. This is useful for:
- **Scratch orgs** where the actual URL will keep changing
- **Generic fallbacks** where you don't need a different value for each environment
- **Development** environments that don't have a stable URL

**Note:** Although it's now possible to get a sandbox name using the Domain class, that still returns null for scratch orgs, 
which is why the URL-based approach with a default fallback is more robust.

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

| Name       | Org Domain URL                                 |
|------------|------------------------------------------------|
| Production | https://company.my.salesforce.com              |
| UAT        | https://company--uat.sandbox.my.salesforce.com |
| Default    |                                                |

Each environment record serves as a reference for other metadata. The **Name** is not significant to the 
implementation, so it can be whatever you find to be descriptive. 

The **Org Domain URL** must match one of the following:
- The value returned by `Url.getOrgDomainUrl().toExternalForm()` (e.g., `https://company.my.salesforce.com`)
- The value returned by `DomainCreator.getOrgMyDomainHostname()` (e.g., `company.my.salesforce.com`)
- Just the My Domain subdomain (e.g., `company` or `company--uat`)

The environment with **no Org Domain URL** is regarded as the **default**, irrespective of its name. This default will be used 
when no other environment matches the current org's URL. 

### Custom Metadata Type: Property

Properties are for unstructured metadata in a basic `key: value` form. So, they may be the sort of thing you would think 
of storing in a hierarchy custom setting or label. If you want to store lists of metadata, then define a custom metadata type 
(see below).

Their structure is simple, for example:

| Name                 | Key      | Value            | Environment | 
|----------------------|----------|------------------|-------------|
| My Label: Production | My_Label | Production Value | Production  |
| My Label: UAT        | My_Label | UAT Value        | UAT         |

- **Name**: Can be anything you want. This is just for your reference in the Setup UI.
- **Key**: The identifier used to retrieve the property. Keys must match for items you consider to be the same property across environments.
- **Value**: The actual value stored for this property (max 255 characters).
- **Environment**: A lookup/reference to an instance of the Environment custom metadata type.

**Important:** Keys must match exactly (case-sensitive) for properties that represent the same configuration across different environments.

### Custom Metadata Type: Other

You can use any other custom metadata type by adding a **Metadata Relationship** field to your type, linking it to `Environment__mdt`. You
may then create multiple records of your type for each environment and use the Apex API to access the relevant ones for 
your current environment. 

**Steps to create your own custom metadata type:**

1. Create your custom metadata type (e.g., `My_Config__mdt`)
2. Add your custom fields to store the data you need
3. Add a **Metadata Relationship** field that references `Environment__mdt`
4. Define at least one field as a key (or multiple fields for a compound key)
5. Create records for each environment, linking them to the appropriate Environment record

**Example:**

If you have a custom metadata type `API_Config__mdt` with fields:
- `Environment__c` (Metadata Relationship to `Environment__mdt`)
- `Service_Name__c` (Text, used as key)
- `Endpoint__c` (URL)
- `Timeout__c` (Number)

You would create records like:
- Production record: Service_Name = "PaymentAPI", Environment = Production, Endpoint = "https://api.prod.example.com"
- UAT record: Service_Name = "PaymentAPI", Environment = UAT, Endpoint = "https://api.uat.example.com" 

## Matching values in environments

Values in environments are matched by looking at their Environment reference and the Org Domain URL within it. Matching
happens in order of preference:

1. **Specific environment match**: If there is a custom metadata record associated with an Environment that matches the 
   current org (via `Url.getOrgDomainUrl().toExternalForm()`, `DomainCreator.getOrgMyDomainHostname()`, or My Domain subdomain),
   then that record is returned.
2. **Default environment**: If there is a record in an Environment with no Org Domain URL set, then that record is returned.
3. **No match**: Otherwise, nothing is returned. The form that "nothing" takes depends on the API you use to access the property:
   - `nebc.EnvironmentProperties.get()` returns `null`
   - `nebc.EnvironmentMetadata.get()` returns `null`
   - `nebc.EnvironmentMetadata.getAll()` returns an empty list

**Example Matching Logic:**

If your org URL is `https://company--uat.sandbox.my.salesforce.com` and you have:
- Property "API_Endpoint" in Production environment (URL: `https://company.my.salesforce.com`)
- Property "API_Endpoint" in UAT environment (URL: `https://company--uat.sandbox.my.salesforce.com`)
- Property "API_Endpoint" in Default environment (URL: blank)

The system will return the UAT value since it's an exact match.
 

## Apex Interface

Of course, you may query the metadata records directly. Convenience methods are provided which respect the rules of 
matching described above. These methods can give you all the metadata for the current environment or read a key at a time.

### Apex Interface: Properties

Metadata stored in the Property custom metadata type can be read via the [EnvironmentProperties](force-app/main/default/classes/EnvironmentProperties.cls) class:

```apex
// Get a single property value
String apiEndpoint = nebc.EnvironmentProperties.get('API_Endpoint');

// Returns null if the property doesn't exist
String missingValue = nebc.EnvironmentProperties.get('NonExistent_Key'); // returns null
```

**Method Signature:**
```apex
global static String get(String key)
```

**Parameters:**
- `key` - The key of the property to retrieve (case-sensitive)

**Returns:**
- `String` - The value of the property for the current environment, or `null` if not found

**Notes:**
- The method automatically determines the current environment based on the org's URL
- Keys are case-sensitive
- Maximum value length is 255 characters (limitation of the Value__c field)
- All classes in this package use the `nebc` namespace

### Apex Interface: Other Custom Metadata Types

Custom metadata types that have added a reference to Environment can use [EnvironmentMetadata](force-app/main/default/classes/EnvironmentMetadata.cls)
to access either all the metadata records for the current environment or a single record.

The custom metadata type must have a key (it can be a compound key across multiple fields), or else the 
notion of overriding doesn't make sense. When you construct an instance of EnvironmentMetadata, you must supply the 
SObjectType of the metadata, and the key field(s).

#### Constructor Patterns

**Single key field:**
```apex
nebc.EnvironmentMetadata myEnvironmentMetadata = new nebc.EnvironmentMetadata(
    My_Type__mdt.SObjectType, 
    My_Type__mdt.Key__c
);
```

**Compound key (multiple fields):**
```apex
nebc.EnvironmentMetadata myEnvironmentMetadata = new nebc.EnvironmentMetadata(My_Type__mdt.SObjectType)
    .addKeyField(My_Type__mdt.Key_1__c)
    .addKeyField(My_Type__mdt.Key_2__c);
```

#### Retrieving Records

EnvironmentMetadata will examine the types to find how it is linked to Environment. You may then read records with 
values on the key:

**Get a single record by key value:**
```apex
// Single key
My_Type__mdt record = (My_Type__mdt)myEnvironmentMetadata.get('keyValue');

// Compound key using SObject
My_Type__mdt record = (My_Type__mdt)myEnvironmentMetadata.get(
    new My_Type__mdt(Key_1__c = val1, Key_2__c = val2)
);

// Compound key using Map
My_Type__mdt record = (My_Type__mdt)myEnvironmentMetadata.get(
    new Map<String, Object>{'Key_1__c' => val1, 'Key_2__c' => val2}
);
```

Where the `key` could be:
- A **single value** (if there is only one key field)
- An **SObject** with the key fields filled in
- A **Map** with the key fields as keys

**Get all records for this environment:**
```apex
List<My_Type__mdt> records = myEnvironmentMetadata.getAll();
```

The returned list will be for this environment and also unique based on your supplied key.

#### Method Signatures

```apex
global EnvironmentMetadata(SObjectType metadataType)
global EnvironmentMetadata(SObjectType metadataType, SObjectField keyField)
global EnvironmentMetadata addKeyField(SObjectField field)
global List<SObject> getAll()
global SObject get(Object key)
global SObject get(SObject key)
global SObject get(Map<String, Object> key)
```

#### Complete Example

```apex
// Define your custom metadata type with a relationship to Environment
// Let's say you have API_Config__mdt with:
// - Service_Name__c (Text, key field)
// - Environment__c (MetadataRelationship to Environment__mdt)
// - Endpoint__c (URL)
// - Timeout__c (Number)

// Initialize the EnvironmentMetadata
nebc.EnvironmentMetadata apiConfigs = new nebc.EnvironmentMetadata(
    API_Config__mdt.SObjectType,
    API_Config__mdt.Service_Name__c
);

// Get a specific config
API_Config__mdt paymentConfig = (API_Config__mdt)apiConfigs.get('PaymentAPI');
if (paymentConfig != null) {
    System.debug('Endpoint: ' + paymentConfig.Endpoint__c);
    System.debug('Timeout: ' + paymentConfig.Timeout__c);
}

// Get all configs for this environment
List<API_Config__mdt> allConfigs = (List<API_Config__mdt>)apiConfigs.getAll();
for (API_Config__mdt config : allConfigs) {
    System.debug('Service: ' + config.Service_Name__c + ', Endpoint: ' + config.Endpoint__c);
}
``` 

### Apex Interface: LWC

[EnvironmentPropertiesLwc](force-app/main/default/classes/EnvironmentPropertiesLwc.cls) provides two `@AuraEnabled` 
methods to access the properties from Lightning Web Components.

#### Methods

**Get a single property:**
```apex
@AuraEnabled(Cacheable=true)
global static String get(String key)
```

**Get all properties as a map:**
```apex
@AuraEnabled(Cacheable=true)
global static Map<String, String> getAll()
```

#### JavaScript/LWC Examples

**Import and use in your LWC:**

```javascript
import { LightningElement, wire } from 'lwc';
import getEnvironmentProperty from '@salesforce/apex/nebc.EnvironmentPropertiesLwc.get';
import getAllEnvironmentProperties from '@salesforce/apex/nebc.EnvironmentPropertiesLwc.getAll';

export default class MyComponent extends LightningElement {
    apiEndpoint;
    allProperties;
    
    // Get a single property
    @wire(getEnvironmentProperty, { key: 'API_Endpoint' })
    wiredProperty({ error, data }) {
        if (data) {
            this.apiEndpoint = data;
            console.log('API Endpoint:', this.apiEndpoint);
        } else if (error) {
            console.error('Error retrieving property:', error);
        }
    }
    
    // Get all properties
    @wire(getAllEnvironmentProperties)
    wiredAllProperties({ error, data }) {
        if (data) {
            this.allProperties = data;
            console.log('All properties:', this.allProperties);
            // Access specific properties: data.API_Endpoint, data.Feature_Flag, etc.
        } else if (error) {
            console.error('Error retrieving properties:', error);
        }
    }
}
```

**Imperative call example:**

```javascript
import { LightningElement } from 'lwc';
import getEnvironmentProperty from '@salesforce/apex/nebc.EnvironmentPropertiesLwc.get';

export default class MyComponent extends LightningElement {
    async loadProperty() {
        try {
            const endpoint = await getEnvironmentProperty({ key: 'API_Endpoint' });
            console.log('Endpoint:', endpoint);
        } catch (error) {
            console.error('Error:', error);
        }
    }
}
```

**Notes:**
- Both methods are marked as `Cacheable=true`, making them suitable for use with `@wire`
- The `getAll()` method returns a JavaScript object/map where keys are property keys and values are property values
- When importing from a managed package, reference the class name directly with the namespace prefix (e.g., `nebc.EnvironmentPropertiesLwc`).
- In Apex code, you must use the namespace prefix: `nebc.EnvironmentProperties.get('key')`

### Apex Interface: Flow

[FlowEnvironmentProperty.getProperty()](force-app/main/default/classes/FlowEnvironmentProperty.cls) provides access to
the properties in Flow. You will find it as an Apex Action called **"Get Environment Property"** under the category 
**"Configuration"**.

#### Method Signature

```apex
@InvocableMethod(
    Label='Get Environment Property' 
    Description='Reads a string from the Nebula Environment Property custom metadata' 
    Category='Configuration'
)
global static List<String> getProperty(List<String> key)
```

#### Usage in Flow

1. **Add an Action** to your Flow
2. Search for **"Get Environment Property"** in the Configuration category
3. **Input**: Provide the property key (e.g., `API_Endpoint`)
4. **Output**: Store the returned value in a Text variable

#### Flow Builder Example

**Get a single property:**
- Action: "Get Environment Property"
- Input: `API_Endpoint`
- Store Output In: `{!varApiEndpoint}` (Text variable)

**Using in Decision Element:**
```
Decision: Check Environment
  Outcome: Is Production
    Condition: {!varEnvironmentName} Equals "Production"
  Outcome: Is UAT
    Condition: {!varEnvironmentName} Equals "UAT"
```

#### Bulk Processing

The method accepts a list of keys and returns a list of values, which allows for efficient bulk processing:

```apex
// Input: ['API_Endpoint', 'Feature_Flag', 'Timeout']
// Output: ['https://api.prod.com', 'true', '30']
```

In Flow Builder, if you pass a collection of keys, you'll receive a collection of values in the same order.

**Note**: The method processes keys in order, so the first key in the input list corresponds to the first value in the output list.

## Best Practices

### Naming Conventions

- **Keys**: Use clear, descriptive names with underscores (e.g., `API_Endpoint`, `Feature_Flag_NewUI`)
- **Environment Names**: Use consistent naming (e.g., "Production", "UAT", "QA", "Development")
- **Property Names**: Include both the key and environment in the name for clarity (e.g., "API_Endpoint: Production")

### Key Management

- **Document your keys**: Maintain a list of all keys and their purposes
- **Use consistent casing**: Keys are case-sensitive, so establish a convention (e.g., Snake_Case)
- **Prefix related keys**: Group related properties with common prefixes (e.g., `API_Endpoint`, `API_Timeout`, `API_RetryCount`)

### Environment Setup

- **Always create a Default environment**: This serves as a fallback for scratch orgs and new environments
- **Test in scratch orgs**: Scratch orgs will use the default environment, so ensure it has appropriate values
- **Document URL patterns**: Keep track of your org URLs to ensure proper environment matching

### Performance

- **Cache results when appropriate**: If you're calling the same property multiple times, cache the result
- **Use getAll() for multiple properties**: When you need several properties, consider using `getAll()` and accessing from the map
- **Consider LWC caching**: The LWC methods are cacheable, which improves performance

### Custom Metadata Types

- **Keep it simple**: Only create custom metadata types when Properties aren't sufficient
- **Define clear keys**: Ensure your key fields uniquely identify records
- **Use compound keys sparingly**: While supported, they add complexity
- **Document relationships**: Clearly document which field links to `Environment__mdt`

### Testing

- **Mock in tests**: Use dependency injection to mock environment metadata in your tests
- **Test multiple environments**: Ensure your code works correctly in different environments
- **Test the default fallback**: Verify behavior when no specific environment matches

## Troubleshooting

### Property Returns Null

**Possible causes:**
1. **Key mismatch**: Keys are case-sensitive. Verify exact spelling and casing
2. **Missing environment**: No Environment record matches the current org's URL
3. **Missing default**: No default Environment record exists (with blank URL)
4. **No property record**: The Property record doesn't exist for any environment

**Solutions:**
- Double-check the key spelling and casing
- Create a Default environment with no URL to serve as fallback
- Verify the Environment's Org Domain URL matches your org
- Check that a Property record exists with the correct key

### Environment Not Matching

**Possible causes:**
1. **URL format mismatch**: The Org Domain URL doesn't match any supported format
2. **My Domain not configured**: Older orgs without My Domain may have issues
3. **Incorrect URL in metadata**: The stored URL doesn't match the actual org URL

**Solutions:**
- Run this in Anonymous Apex to see your org's URLs:
  ```apex
  System.debug('getOrgDomainUrl: ' + Url.getOrgDomainUrl().toExternalForm());
  System.debug('getOrgMyDomainHostname (from Nebula Core): ' + DomainCreator.getOrgMyDomainHostname());
  ```
  Note: `DomainCreator.getOrgMyDomainHostname()` is a utility method from the Nebula Core dependency.
- Ensure your Environment records use one of these exact formats
- Consider using just the My Domain subdomain for sandbox environments

### Custom Metadata Type Not Working

**Possible causes:**
1. **Missing MetadataRelationship**: The field linking to `Environment__mdt` doesn't exist
2. **No key fields defined**: You must specify at least one key field in the constructor
3. **Key field mismatch**: The key values don't match between calls

**Solutions:**
- Verify the MetadataRelationship field exists and references `Environment__mdt`
- Ensure you specify key fields: `new EnvironmentMetadata(Type, KeyField)`
- Debug to verify the key values you're passing match the metadata records

### Namespace Issues

**Problem**: Getting errors about `nebc` namespace

**Solution**: This package uses the `nebc` namespace. Ensure you:
- Reference classes with the namespace: `nebc.EnvironmentProperties`
- Reference custom metadata types with namespace: `nebc__Property__mdt`
- Use the namespace in queries: `SELECT nebc__Key__c FROM nebc__Property__mdt`

### SOQL Query Limits

**Problem**: Running into SOQL query limits

**Solution**:
- The package queries custom metadata efficiently using bind variables
- Custom metadata queries count toward SOQL limits but are generally lightweight
- Cache results when calling repeatedly in the same transaction
- Use `getAll()` instead of multiple `get()` calls when you need several records

## Security Model

### Sharing Model

- **EnvironmentProperties**: Uses `inherited sharing`, respecting the calling context's sharing rules
- **EnvironmentPropertiesLwc**: Uses `with sharing`, enforcing user-level sharing
- **FlowEnvironmentProperty**: Uses `with sharing`, enforcing user-level sharing
- **EnvironmentMetadata**: Uses `inherited sharing`, respecting the calling context's sharing rules

### Access Level

Queries in the **EnvironmentMetadata** class execute in **SYSTEM_MODE** (via `Database.queryWithBinds()` with `AccessLevel.SYSTEM_MODE`). Since **EnvironmentProperties** and **EnvironmentPropertiesLwc** delegate to **EnvironmentMetadata**, they inherit this behavior. This means:
- Users can access custom metadata regardless of their permissions
- Custom metadata is configuration data meant to be accessible
- FLS (Field-Level Security) and object permissions are bypassed
- This is standard practice for custom metadata as it's configuration, not data

### Permission Considerations

- **Custom Metadata records**: Visible to all users by default (standard Salesforce behavior)
- **Apex classes**: Global classes can be called from anywhere
- **LWC methods**: Use `@AuraEnabled(Cacheable=true)` so they can be called from Lightning components
- **Flow actions**: Use `@InvocableMethod` so they can be used in Flow Builder

### Security Best Practices

1. **Don't store sensitive data**: Custom metadata is visible to all users; don't store passwords or API keys directly
2. **Use Named Credentials**: Store references to Named Credentials in properties, not credentials themselves
3. **Audit usage**: Monitor which properties are accessed in production
4. **Control deployment**: Use source control and proper deployment processes for metadata changes

## Contributing

This package is maintained by [Nebula Consulting](https://nebulaconsulting.co.uk/).

### Reporting Issues

If you encounter any issues or have questions:
1. Check this documentation and the Troubleshooting section
2. Search existing [GitHub Issues](https://github.com/Nebula-Consulting/nebula-environment-metadata/issues)
3. Create a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Salesforce org type (scratch org, sandbox, production)
   - Package version

### Feature Requests

We welcome feature requests! Please:
1. Check if the feature has already been requested
2. Create an issue describing:
   - The use case
   - Proposed solution or API
   - Why it can't be achieved with current functionality

### Code Contributions

We may accept code contributions. Before submitting:
1. Discuss the proposed changes in an issue first
2. Follow existing code style and patterns
3. Include comprehensive test coverage
4. Update documentation as needed

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright 2022 Nebula Consulting

---

**Package Version**: 1.4.0  
**Salesforce API Version**: 60.0  
**Namespace**: `nebc`  
**Dependencies**: Nebula Core