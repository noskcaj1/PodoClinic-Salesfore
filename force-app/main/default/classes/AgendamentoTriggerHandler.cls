public with sharing class AgendamentoTriggerHandler {
    private static final Integer DURACAO_PADRAO = 60;
    private static final Set<String> STATUS_ATIVOS = new Set<String>{ 'Agendado', 'Confirmado' };

    public static void validarConflito(List<Agendamento__c> novos, Map<Id, Agendamento__c> antigos) {
        Map<Id, Integer> duracoes = carregarDuracoes(novos);
        List<Agendamento__c> alvo = new List<Agendamento__c>();
        Datetime min;
        Datetime max;

        for (Agendamento__c a : novos) {
            if (a.Profissional__c == null || a.Data_Hora__c == null || !STATUS_ATIVOS.contains(a.Status__c)) {
                continue;
            }
            Agendamento__c old = antigos == null ? null : antigos.get(a.Id);
            if (old != null && old.Data_Hora__c == a.Data_Hora__c && old.Profissional__c == a.Profissional__c
                && old.Servico__c == a.Servico__c && old.Status__c == a.Status__c) {
                continue;
            }
            alvo.add(a);
            Datetime fim = fimDe(a, duracoes);
            min = (min == null || a.Data_Hora__c < min) ? a.Data_Hora__c : min;
            max = (max == null || fim > max) ? fim : max;
        }
        if (alvo.isEmpty()) {
            return;
        }

        // Janela ampliada em 24h para pegar agendamentos longos que começam antes.
        List<Agendamento__c> existentes = [
            SELECT Id, Profissional__c, Data_Hora__c, Servico__c
            FROM Agendamento__c
            WHERE Status__c IN :STATUS_ATIVOS
              AND Data_Hora__c >= :min.addDays(-1) AND Data_Hora__c < :max
              AND Id NOT IN :novos
        ];
        Map<Id, Integer> duracoesExistentes = carregarDuracoes(existentes);

        for (Integer i = 0; i < alvo.size(); i++) {
            Agendamento__c a = alvo[i];
            Datetime ini = a.Data_Hora__c;
            Datetime fim = fimDe(a, duracoes);
            for (Agendamento__c e : existentes) {
                if (e.Profissional__c == a.Profissional__c && ini < fimDe(e, duracoesExistentes) && e.Data_Hora__c < fim) {
                    a.addError('Profissional__c', 'O profissional já possui um agendamento nesse horário.');
                    break;
                }
            }
            // Conflito com registros anteriores do mesmo lote
            for (Integer j = 0; j < i; j++) {
                Agendamento__c b = alvo[j];
                if (b.Profissional__c == a.Profissional__c && ini < fimDe(b, duracoes) && b.Data_Hora__c < fim) {
                    a.addError('Profissional__c', 'O profissional já possui um agendamento nesse horário.');
                    break;
                }
            }
        }
    }

    public static void criarAtendimentos(List<Agendamento__c> novos, Map<Id, Agendamento__c> antigos) {
        Set<Id> concluidos = new Set<Id>();
        for (Agendamento__c a : novos) {
            if (a.Status__c == 'Concluido' && antigos.get(a.Id).Status__c != 'Concluido') {
                concluidos.add(a.Id);
            }
        }
        if (concluidos.isEmpty()) {
            return;
        }
        for (Atendimento__c at : [SELECT Agendamento__c FROM Atendimento__c WHERE Agendamento__c IN :concluidos]) {
            concluidos.remove(at.Agendamento__c);
        }
        List<Atendimento__c> criar = new List<Atendimento__c>();
        for (Agendamento__c a : novos) {
            if (concluidos.contains(a.Id)) {
                criar.add(new Atendimento__c(
                    Agendamento__c = a.Id,
                    Paciente__c = a.Paciente__c,
                    Profissional__c = a.Profissional__c,
                    Servico__c = a.Servico__c,
                    Data_Atendimento__c = a.Data_Hora__c
                ));
            }
        }
        insert criar;
    }

    private static Datetime fimDe(Agendamento__c a, Map<Id, Integer> duracoes) {
        Integer min = a.Servico__c != null && duracoes.containsKey(a.Servico__c) ? duracoes.get(a.Servico__c) : DURACAO_PADRAO;
        return a.Data_Hora__c.addMinutes(min);
    }

    private static Map<Id, Integer> carregarDuracoes(List<Agendamento__c> lista) {
        Set<Id> ids = new Set<Id>();
        for (Agendamento__c a : lista) {
            if (a.Servico__c != null) {
                ids.add(a.Servico__c);
            }
        }
        Map<Id, Integer> r = new Map<Id, Integer>();
        for (Servico__c s : [SELECT Id, Duracao_Minutos__c FROM Servico__c WHERE Id IN :ids]) {
            if (s.Duracao_Minutos__c != null) {
                r.put(s.Id, Integer.valueOf(s.Duracao_Minutos__c));
            }
        }
        return r;
    }
}
