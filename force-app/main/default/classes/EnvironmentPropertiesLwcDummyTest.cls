/**
 * @author: paulk@nebulaconsulting.co.uk
 * @date: 23/07/2021
 * @description: Tests for EnvironmentPropertiesLwc that don't rely on the metadata records (which don't go in the package)
 */
@IsTest
private class EnvironmentPropertiesLwcDummyTest {

    static String specificValue = 'Specific Value';
    static String defaultValue = 'Default Value';

    @IsTest
    static void specific() {
        EnvironmentPropertiesLwc.environmentProperties.databaseConnection =
            new EnvironmentMetadataTest.DatabaseConnectionMock(new List<Property__mdt> {
                new Property__mdt(DeveloperName = 'Default', Key__c = 'My_Label', Value__c = defaultValue),
                new Property__mdt(DeveloperName = 'Specific', Key__c = 'My_Label', Value__c = specificValue)
            });

        String value = EnvironmentPropertiesLwc.get('My_Label');
        System.assertEquals(specificValue, value);
    }

    @IsTest
    static void allSpecific() {
        EnvironmentPropertiesLwc.environmentProperties.databaseConnection =
            new EnvironmentMetadataTest.DatabaseConnectionMock(new List<Property__mdt> {
                new Property__mdt(DeveloperName = 'Default', Key__c = 'My_Label', Value__c = defaultValue),
                new Property__mdt(DeveloperName = 'Specific', Key__c = 'My_Label', Value__c = specificValue)
            });

        Map<String, String> values = EnvironmentPropertiesLwc.getAll();
        System.assertEquals(true, values.containsKey('My_Label'));
        System.assertEquals(specificValue, values.get('My_Label'));
    }

    @IsTest
    static void default() {
        EnvironmentPropertiesLwc.environmentProperties.databaseConnection =
            new EnvironmentMetadataTest.DatabaseConnectionMock(new List<Property__mdt> {
                new Property__mdt(DeveloperName = 'Default', Key__c = 'My_Label', Value__c = defaultValue)
            });

        String value = EnvironmentPropertiesLwc.get('My_Label');
        System.assertEquals(defaultValue, value);
    }

    @IsTest
    static void allDefault() {
        EnvironmentPropertiesLwc.environmentProperties.databaseConnection =
            new EnvironmentMetadataTest.DatabaseConnectionMock(new List<Property__mdt> {
                new Property__mdt(DeveloperName = 'Default', Key__c = 'My_Label', Value__c = defaultValue)
            });

        Map<String, String> values = EnvironmentPropertiesLwc.getAll();
        System.assertEquals(true, values.containsKey('My_Label'));
        System.assertEquals(defaultValue, values.get('My_Label'));
    }

}