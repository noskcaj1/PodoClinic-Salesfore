public with sharing class AgendaController {
    public class Opcao {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
    }

    @AuraEnabled(cacheable=true)
    public static List<Opcao> getProfissionais() {
        List<Opcao> opcoes = new List<Opcao>();
        for (Profissional__c p : [SELECT Id, Name FROM Profissional__c WHERE Ativo__c = true ORDER BY Name LIMIT 200]) {
            Opcao o = new Opcao();
            o.value = p.Id;
            o.label = p.Name;
            opcoes.add(o);
        }
        return opcoes;
    }

    @AuraEnabled(cacheable=true)
    public static List<Agendamento__c> getAgendamentos(Datetime inicio, Datetime fim, Id profissionalId) {
        String soql = 'SELECT Id, Name, Data_Hora__c, Status__c, Paciente__r.Name, Profissional__r.Name, Servico__r.Name'
            + ' FROM Agendamento__c WHERE Data_Hora__c >= :inicio AND Data_Hora__c < :fim AND Status__c != \'Cancelado\'';
        if (profissionalId != null) {
            soql += ' AND Profissional__c = :profissionalId';
        }
        soql += ' WITH USER_MODE ORDER BY Data_Hora__c LIMIT 500';
        return Database.query(soql);
    }
}
