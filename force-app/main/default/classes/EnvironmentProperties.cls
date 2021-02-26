/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 23/02/2021
 * @description Access the values stored in Property__mdt for the current environment
 */

global inherited sharing class EnvironmentProperties {

    @TestVisible
    private static EnvironmentMetadata environmentProperties = new EnvironmentMetadata(Property__mdt.SObjectType, Property__mdt.Key__c);

    global static String get(String key) {
        return ((Property__mdt)environmentProperties.get(key))?.Value__c;
    }
}