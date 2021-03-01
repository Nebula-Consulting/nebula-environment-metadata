/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 26/02/2021
 * @description Tests for EnvironmentProperties that don't rely on the metadata records (which don't go in the package)
 */

@IsTest
private class EnvironmentPropertiesDummyTest {

    static String specificValue = 'Specific Value';
    static String defaultValue = 'Default Value';

    @IsTest
    static void specific() {
        EnvironmentProperties.environmentProperties.databaseConnection =
                new EnvironmentMetadataTest.DatabaseConnectionMock(new List<Property__mdt> {
                        new Property__mdt(DeveloperName = 'Default', Key__c = 'My_Label', Value__c = defaultValue),
                        new Property__mdt(DeveloperName = 'Specific', Key__c = 'My_Label', Value__c = specificValue)
                });

        String value = EnvironmentProperties.get('My_Label');
        System.assertEquals(specificValue, value);
    }

    @IsTest
    static void default() {
        EnvironmentProperties.environmentProperties.databaseConnection =
                new EnvironmentMetadataTest.DatabaseConnectionMock(new List<Property__mdt> {
                        new Property__mdt(DeveloperName = 'Default', Key__c = 'My_Label', Value__c = defaultValue)
                });

        String value = EnvironmentProperties.get('My_Label');
        System.assertEquals(defaultValue, value);
    }
}