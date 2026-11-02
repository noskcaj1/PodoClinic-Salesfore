@IsTest
private class AgendaFichaTest {
    @IsTest
    static void agendaEFicha() {
        Paciente__c pac = new Paciente__c(Name = 'Pac', Ativo__c = true);
        insert pac;
        Profissional__c prof = new Profissional__c(Name = 'Prof', Ativo__c = true);
        insert prof;
        Datetime t = Datetime.now().addDays(1);
        Agendamento__c a = new Agendamento__c(Paciente__c = pac.Id, Profissional__c = prof.Id, Data_Hora__c = t);
        insert a;
        a.Status__c = 'Concluido';
        update a;
        insert new Agendamento__c(Paciente__c = pac.Id, Profissional__c = prof.Id, Data_Hora__c = t.addDays(1));

        System.assertEquals(1, AgendaController.getProfissionais().size());
        System.assertEquals(2, AgendaController.getAgendamentos(t.addDays(-1), t.addDays(5), null).size());
        System.assertEquals(2, AgendaController.getAgendamentos(t.addDays(-1), t.addDays(5), prof.Id).size());

        FichaController.Ficha f = FichaController.getFicha(pac.Id);
        System.assertEquals(1, f.totalAtendimentos);
        System.assertEquals(1, f.atendimentos.size());
        System.assertEquals(1, f.proximos.size());
    }
}
