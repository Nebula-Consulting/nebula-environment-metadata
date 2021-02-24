
/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 24/02/2021
 * @description Compares an SObject on a given fields, only respecting values as null or not-null. Orders nulls last
 */

public class NullsLastComparator implements Comparator {

    private String fieldToCompare;

    public NullsLastComparator(String fieldToCompare) {
        this.fieldToCompare = fieldToCompare;
    }

    public Integer compare(Object leftObject, Object rightObject) {
        Object leftValue = SObjectGetter.get((SObject)leftObject, fieldToCompare);
        Object rightValue = SObjectGetter.get((SObject)rightObject, fieldToCompare);

        return (leftValue != null && rightValue != null) ||  (leftValue == null && rightValue == null)? 0 : (leftValue == null ? 1 : -1);
    }
}