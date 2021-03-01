/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 26/02/2021
 */

@IsTest
public class EnvironmentMetadataTest {

    @IsTest
    static void testBehavior() {
        EnvironmentMetadata environmentMetadata = new EnvironmentMetadata(Property__mdt.SObjectType);
        environmentMetadata.databaseConnection = new DatabaseConnectionMock(new List<Property__mdt>());

    }

    public class DatabaseConnectionMock implements EnvironmentMetadata.DatabaseConnection {

        private List<SObject> results;

        public DatabaseConnectionMock(List<SObject> results) {
            this.results = results;
        }

        public List<SObject> query(String query, String orgDomainUrl) {
            return results;
        }
    }
}