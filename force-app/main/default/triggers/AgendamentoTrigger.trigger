trigger AgendamentoTrigger on Agendamento__c (before insert, before update, after update) {
    if (Trigger.isBefore) {
        AgendamentoTriggerHandler.validarConflito(Trigger.new, Trigger.oldMap);
    } else {
        AgendamentoTriggerHandler.criarAtendimentos(Trigger.new, Trigger.oldMap);
    }
}
