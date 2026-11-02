public with sharing class PainelController {
    private static final Set<String> STATUS_ATIVOS = new Set<String>{ 'Agendado', 'Confirmado' };

    public class Resumo {
        @AuraEnabled public Integer agendamentosHoje;
        @AuraEnabled public Integer aConfirmar;
        @AuraEnabled public Integer pacientesAtivos;
        @AuraEnabled public Integer atendimentosMes;
        @AuraEnabled public Decimal receitaMes;
    }

    @AuraEnabled(cacheable=true)
    public static Resumo getResumo() {
        Datetime inicioDia = Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        Datetime fimDia = inicioDia.addDays(1);
        Datetime inicioMes = Datetime.newInstance(Date.today().toStartOfMonth(), Time.newInstance(0, 0, 0, 0));

        Resumo r = new Resumo();
        r.agendamentosHoje = [
            SELECT COUNT() FROM Agendamento__c
            WHERE Data_Hora__c >= :inicioDia AND Data_Hora__c < :fimDia
              AND Status__c != 'Cancelado'
        ];
        r.aConfirmar = [
            SELECT COUNT() FROM Agendamento__c
            WHERE Status__c = 'Agendado' AND Data_Hora__c >= :Datetime.now()
        ];
        r.pacientesAtivos = [SELECT COUNT() FROM Paciente__c WHERE Ativo__c = true];

        AggregateResult ar = [
            SELECT COUNT(Id) qtd, SUM(Valor__c) total
            FROM Agendamento__c
            WHERE Status__c = 'Concluido' AND Data_Hora__c >= :inicioMes AND Data_Hora__c < :fimDia
        ];
        r.atendimentosMes = (Integer) ar.get('qtd');
        r.receitaMes = (Decimal) ar.get('total');
        if (r.receitaMes == null) {
            r.receitaMes = 0;
        }
        return r;
    }

    @AuraEnabled(cacheable=true)
    public static List<Agendamento__c> getProximos() {
        return [
            SELECT Id, Name, Data_Hora__c, Status__c, Paciente__r.Name, Profissional__r.Name, Servico__r.Name
            FROM Agendamento__c
            WHERE Status__c IN :STATUS_ATIVOS AND Data_Hora__c >= :Datetime.now()
            ORDER BY Data_Hora__c
            LIMIT 8
        ];
    }
}
