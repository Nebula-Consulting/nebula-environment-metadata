/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 24/02/2021
 */

@IsTest
private class EnvironmentPropertiesTest {

    static nebc.TestRecordSource testRecordSource = new nebc.TestRecordSource();

    @IsTest
    static void testBehavior() {
        String value = EnvironmentProperties.get('My_Label');
        System.assertEquals([SELECT Value__c FROM Property__mdt WHERE Environment__r.DeveloperName = 'Specific'].Value__c, value);
    }
}