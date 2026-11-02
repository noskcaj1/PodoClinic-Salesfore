public with sharing class CpfTriggerHandler {
    public static void validate(List<SObject> records) {
        for (SObject r : records) {
            String cpf = (String) r.get('CPF__c');
            if (String.isNotBlank(cpf) && !CpfValidator.isValid(cpf)) {
                r.addError('CPF__c', 'CPF inválido.');
            }
        }
    }
}
