/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 11/08/2021
 * @description Reads a string from the Nebula Environment Property custom metadata
 */

global with sharing class FlowEnvironmentProperty {

    @InvocableMethod(Label='Get Environment Property' Description='Reads a string from the Nebula Environment Property custom metadata' Category='Configuration')
    global static List<String> getProperty(List<String> key) {
        return (List<String>)new LazyIterator(key)
                .mapValues(new EnvironmentPropertyKeyToValue())
                .toList(new List<String>());
    }
}
