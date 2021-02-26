/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 24/02/2021
 * @description Access custom metadata records that have a lookup to Environment__mdt according to matching the org
 * domain url
 */

global inherited sharing class EnvironmentMetadata {

    private String orgDomainUrl = Url.getOrgDomainUrl().toExternalForm();
    private SObjectType metadataType;
    private List<String> keyFields;
    @TestVisible
    private static List<SObject> dummyMetadataRecords;

    private SObjectIndex metadataIndex {
        get {
            if(metadataIndex == null) {
                metadataIndex = new SObjectIndex(keyFields)
                        .putAll(getMetadataRecords());
            }
            return metadataIndex;
        }
        set;
    }

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

    private List<SObject> getMetadataRecords() {
        DescribeSObjectResult metadataTypeDescribe = metadataType.getDescribe();
        Map<String, SObjectField> fieldMap = metadataTypeDescribe.fields.getMap();
        List<String> fields = new List<String>(fieldMap.keySet());

        String orgDomainField = (String)new LazyIterator(fields)
                .filter(new IsReferenceToEnvironment(fieldMap))
                .mapValues(new MakeReferenceToOrgDomain())
                .firstOrDefault(null);

        // Note: Custom Metadata can't order by NULLS LAST, so we have to sort afterwards
        List<SObject> metadataList = dummyMetadataRecords != null ? dummyMetadataRecords : Database.query(
                'SELECT ' + String.join(fields, ', ') + ', ' + orgDomainField
                        + ' FROM ' + metadataTypeDescribe.getName()
                        + ' WHERE ' + orgDomainField + ' = :orgDomainUrl'
                        + ' OR ' + orgDomainField + ' = NULL'
        );

        return (List<SObject>)Lists.sort(metadataList, new NullsLastComparator(orgDomainField));
    }

    private class IsReferenceToEnvironment implements BooleanFunction {

        private Map<String, SObjectField> fieldMap;

        public IsReferenceToEnvironment(Map<String, SObjectField> fieldMap) {
            this.fieldMap = fieldMap;
        }

        public Boolean isTrueFor(Object o) {
            return fieldMap.get((String)o).getDescribe().referenceTo.contains(Environment__mdt.SObjectType);
        }
    }

    private class MakeReferenceToOrgDomain implements Function {

        public String call(Object o) {
            return ((String)o).replace('__c', '__r.') + Environment__mdt.Org_Domain_URL__c.getDescribe().name;
        }
    }
}