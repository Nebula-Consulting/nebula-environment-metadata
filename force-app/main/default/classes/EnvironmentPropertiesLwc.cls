/**
 * @author: paulk@nebulaconsulting.co.uk
 * @date: 23/07/2021
 * @description: Lightning enabled methods to return specific or all properties for the environment.
 */

global with sharing class EnvironmentPropertiesLwc {

    @TestVisible
    private static EnvironmentMetadata environmentProperties = new EnvironmentMetadata(Property__mdt.SObjectType, Property__mdt.Key__c);

    @AuraEnabled(Cacheable=true)
    global static String get(String key) {
        return ((Property__mdt)environmentProperties.get(key))?.Value__c;
    }

    @AuraEnabled(Cacheable=true)
    global static Map<String, String> getAll() {
        Map<String, String> allProperties =  new Map<String, String>();
        for (Property__mdt property : (List<Property__mdt>) environmentProperties.getAll()) {
            allProperties.put(property.Key__c, property.Value__c);
        }
        return allProperties;
    }

}