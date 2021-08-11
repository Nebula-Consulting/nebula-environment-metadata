/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 11/08/2021
 */

global inherited sharing class EnvironmentPropertyKeyToValue implements Function {

    global String call(Object o) {
        return EnvironmentProperties.get((String)o);
    }
}
