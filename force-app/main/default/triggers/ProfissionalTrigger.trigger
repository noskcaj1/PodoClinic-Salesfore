trigger ProfissionalTrigger on Profissional__c (before insert, before update) {
    CpfTriggerHandler.validate(Trigger.new);
}
