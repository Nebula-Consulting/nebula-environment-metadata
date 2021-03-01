/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 26/02/2021
 */

@IsTest
public class EnvironmentMetadataTest {

    static String specificValue = 'Specific Value';
    static String defaultValue = 'Default Value';
    static String specificOrgDomainUrl = 'https://default.my.salesforce.com';
    static Environment__mdt defaultEnvironment = new Environment__mdt();
    static Environment__mdt specificEnvironment = new Environment__mdt(Org_Domain_URL__c = specificOrgDomainUrl);

    @IsTest
    static void specific() {
        EnvironmentMetadata environmentMetadata = new EnvironmentMetadata(Property__mdt.SObjectType, Property__mdt.Key__c);
        environmentMetadata.databaseConnection = new DatabaseConnectionMock(new List<Property__mdt>{
                new Property__mdt(DeveloperName = 'Default', Key__c = 'My_Label', Value__c = defaultValue, Environment__r = defaultEnvironment),
                new Property__mdt(DeveloperName = 'Specific', Key__c = 'My_Label', Value__c = specificValue, Environment__r = specificEnvironment)
        })
                .addQueryFragmentToAssert('nebc__Environment__r.nebc__Org_Domain_URL__c');

        String value = ((Property__mdt)environmentMetadata.get('My_Label')).Value__c;
        System.assertEquals(specificValue, value);
    }

    @IsTest
    static void specificReverseOrder() {
        EnvironmentMetadata environmentMetadata = new EnvironmentMetadata(Property__mdt.SObjectType)
                .addKeyField(Property__mdt.Key__c);

        environmentMetadata.databaseConnection = new DatabaseConnectionMock(new List<Property__mdt>{
                new Property__mdt(DeveloperName = 'Specific', Key__c = 'My_Label', Value__c = specificValue, Environment__r = specificEnvironment),
                new Property__mdt(DeveloperName = 'Default', Key__c = 'My_Label', Value__c = defaultValue, Environment__r = defaultEnvironment)
        })
                .addQueryFragmentToAssert('nebc__Environment__r.nebc__Org_Domain_URL__c');

        String value = ((Property__mdt)environmentMetadata.get(new Property__mdt(Key__c = 'My_Label'))).Value__c;
        System.assertEquals(specificValue, value);
    }

    @IsTest
    static void getByMap() {
        EnvironmentMetadata environmentMetadata = new EnvironmentMetadata(Property__mdt.SObjectType, Property__mdt.Key__c);
        environmentMetadata.databaseConnection = new DatabaseConnectionMock(new List<Property__mdt>{
                new Property__mdt(DeveloperName = 'Default', Key__c = 'My_Label', Value__c = defaultValue, Environment__r = defaultEnvironment),
                new Property__mdt(DeveloperName = 'Specific', Key__c = 'My_Label', Value__c = specificValue, Environment__r = specificEnvironment)
        })
                .addQueryFragmentToAssert('nebc__Environment__r.nebc__Org_Domain_URL__c');

        String value = ((Property__mdt)environmentMetadata.get(new Map<String, Object>{
                Property__mdt.Key__c.getDescribe().name => 'My_Label'
        })).Value__c;
        System.assertEquals(specificValue, value);
    }

    @IsTest
    static void realDatabaseQuery() {
        EnvironmentMetadata environmentMetadata = new EnvironmentMetadata(Property__mdt.SObjectType, Property__mdt.Key__c)
                .overrideOrgDomainUrl(specificOrgDomainUrl);

        List<SObject> allValues = environmentMetadata.getAll();

        // Weak assertion - we don't know much about what will be returned
        System.assertEquals([SELECT Id FROM Property__mdt].isEmpty(), allValues.isEmpty());
    }

    public class DatabaseConnectionMock implements EnvironmentMetadata.DatabaseConnection {

        private List<SObject> results;
        private Set<String> queryFragmentsToAssert = new Set<String>();

        public DatabaseConnectionMock(List<SObject> results) {
            this.results = results;
        }

        public DatabaseConnectionMock addQueryFragmentToAssert(String caseInsensitiveQueryFragment) {
            queryFragmentsToAssert.add(caseInsensitiveQueryFragment);
            return this;
        }

        public List<SObject> query(String query, String orgDomainUrl) {
            for(String thisQueryFragment : queryFragmentsToAssert) {
                System.assert(query.containsIgnoreCase(thisQueryFragment), String.format('"{0}" not found in query string "{1}"', new List<String>{thisQueryFragment, query}));
            }
            return results;
        }
    }
}