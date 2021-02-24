/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 23/02/2021
 * @description (if required)
 */

global inherited sharing class EnvironmentProperties {

    private static EnvironmentMetadata environmentProperties = new EnvironmentMetadata(Property__mdt.SObjectType, Property__mdt.Key__c);

    global static String get(String key) {
        return ((Property__mdt)environmentProperties.get(key))?.Value__c;
    }
}