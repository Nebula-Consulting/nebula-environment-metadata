/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 11/08/2021
 */

@IsTest
private class EnvironmentPropertyKeyToValueTest {

    static String specificValue = 'Specific Value';
    static String defaultValue = 'Default Value';

    @IsTest
    static void specific() {
        EnvironmentProperties.environmentProperties.databaseConnection =
                new EnvironmentMetadataTest.DatabaseConnectionMock(new List<Property__mdt> {
                        new Property__mdt(DeveloperName = 'Default', Key__c = 'My_Label', Value__c = defaultValue),
                        new Property__mdt(DeveloperName = 'Specific', Key__c = 'My_Label', Value__c = specificValue)
                });

        String value = FlowEnvironmentProperty.getProperty(new List<String>{'My_Label'})[0];
        System.assertEquals(specificValue, value);
    }

    @IsTest
    static void default() {
        EnvironmentProperties.environmentProperties.databaseConnection =
                new EnvironmentMetadataTest.DatabaseConnectionMock(new List<Property__mdt> {
                        new Property__mdt(DeveloperName = 'Default', Key__c = 'My_Label', Value__c = defaultValue)
                });

        String value = FlowEnvironmentProperty.getProperty(new List<String>{'My_Label'})[0];
        System.assertEquals(defaultValue, value);
    }
}
