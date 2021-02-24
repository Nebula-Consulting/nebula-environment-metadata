/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 23/02/2021
 * @description (if required)
 */

global inherited sharing class EnvironmentProperties {

    @TestVisible
    global static Map<String, String> properties {get; private set;}

    global List<SObject> getAll(SObjectType metadataType) {
        return null;
    }

    static {
        // Note: Custom Metadata can't order by NULLS FIRST, so we have to deal overriding defaults manually later
        List<Property__mdt> propertyList = [
                SELECT Key__c, Value__c, Environment__c, Environment__r.Org_Domain_URL__c
                FROM Property__mdt
                WHERE Environment__r.Org_Domain_URL__c = :Url.getOrgDomainUrl().toExternalForm()
                OR Environment__r.Org_Domain_URL__c = NULL
        ];

        properties = new Map<String, String>();

        for(Property__mdt thisProperty : propertyList) {
            if(!properties.containsKey(thisProperty.Key__c) || thisProperty.Environment__r.Org_Domain_URL__c != null) {
                properties.put(thisProperty.Key__c, thisProperty.Value__c);
            }
        }
    }
}