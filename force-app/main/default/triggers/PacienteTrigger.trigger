trigger PacienteTrigger on Paciente__c (before insert, before update) {
    CpfTriggerHandler.validate(Trigger.new);
}
