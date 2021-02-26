/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 24/02/2021
 * @description (if required)
 */

global inherited sharing class EnvironmentMetadata {

    public String orgDomainUrl = Url.getOrgDomainUrl().toExternalForm();
    private SObjectType metadataType;
    private List<String> keyFields;

    private SObjectIndex metadataIndex {get {
        if(metadataIndex == null) {
            metadataIndex = new SObjectIndex(keyFields);

            DescribeSObjectResult metadataTypeDescribe = metadataType.getDescribe();
            Map<String, SObjectField> fieldMap = metadataTypeDescribe.fields.getMap();
            List<String> fields = new List<String>(fieldMap.keySet());
            String orgDomainField;
            for(String thisFieldName : fields) {
                DescribeFieldResult thisFieldDescribe = fieldMap.get(thisFieldName).getDescribe();
                if(thisFieldDescribe.referenceTo.contains(Environment__mdt.SObjectType)) {
                    orgDomainField = thisFieldName.replace('__c', '__r.') + Environment__mdt.Org_Domain_URL__c.getDescribe().name;
                }
            }
            // Note: Custom Metadata can't order by NULLS LAST, so we have to sort afterwards
            List<SObject> metadataList = Database.query(
                    'SELECT ' + String.join(fields, ', ') + ', ' + orgDomainField
                            + ' FROM ' + metadataTypeDescribe.getName()
                            + ' WHERE ' + orgDomainField + ' = :orgDomainUrl'
                            + ' OR ' + orgDomainField + ' = NULL'
            );

            Lists.sort(metadataList, new NullsLastComparator(orgDomainField));
            metadataIndex.putAll(metadataList);
        }
        return metadataIndex;
    }
    set; }

    global EnvironmentMetadata(SObjectType metadataType) {
        this.metadataType = metadataType;
        this.keyFields = new List<String>();
    }

    global EnvironmentMetadata(SObjectType metadataType, SObjectField keyField) {
        this.metadataType = metadataType;
        this.keyFields = new List<String>{ keyField.getDescribe().name };
    }

    global EnvironmentMetadata addField(SObjectField field) {
        keyFields.add(field.getDescribe().name);
        return this;
    }

    global EnvironmentMetadata overrideEnvironment(String orgDomainUrl) {
        this.orgDomainUrl = orgDomainUrl;
        return this;
    }

    global List<SObject> getAll() {
        List<SObject> result = new List<SObject>();
        for(String thisKey : (List<String>)metadataIndex.keyList(new List<String>())) {
            result.add(metadataIndex.get(thisKey));
        }
        return result;
    }

    global SObject get(Object key) {
        return metadataIndex.get(key);
    }

    global SObject get(SObject key) {
        return metadataIndex.get(key);
    }

    global SObject get(Map<String, Object> key) {
        return metadataIndex.get(key);
    }
}