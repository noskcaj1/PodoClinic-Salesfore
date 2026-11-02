public with sharing class FichaController {
    public class Ficha {
        @AuraEnabled public Paciente__c paciente;
        @AuraEnabled public List<Atendimento__c> atendimentos;
        @AuraEnabled public List<Agendamento__c> proximos;
        @AuraEnabled public Integer totalAtendimentos;
    }

    @AuraEnabled(cacheable=true)
    public static Ficha getFicha(Id pacienteId) {
        Ficha f = new Ficha();
        f.paciente = [
            SELECT Id, Name, Telefone__c, Email__c, Data_Nascimento__c, Ativo__c, Cidade__c, UF__c, Observacoes__c
            FROM Paciente__c WHERE Id = :pacienteId WITH USER_MODE LIMIT 1
        ];
        f.atendimentos = [
            SELECT Id, Name, Data_Atendimento__c, Queixa_Principal__c, Procedimento_Realizado__c, Orientacoes__c,
                   Servico__r.Name, Profissional__r.Name
            FROM Atendimento__c WHERE Paciente__c = :pacienteId
            WITH USER_MODE ORDER BY Data_Atendimento__c DESC NULLS LAST LIMIT 20
        ];
        f.proximos = [
            SELECT Id, Data_Hora__c, Status__c, Servico__r.Name, Profissional__r.Name
            FROM Agendamento__c
            WHERE Paciente__c = :pacienteId AND Status__c IN ('Agendado', 'Confirmado') AND Data_Hora__c >= :Datetime.now()
            WITH USER_MODE ORDER BY Data_Hora__c LIMIT 5
        ];
        f.totalAtendimentos = [SELECT COUNT() FROM Atendimento__c WHERE Paciente__c = :pacienteId WITH USER_MODE];
        return f;
    }
}
