@IsTest
private class PainelControllerTest {
    @IsTest
    static void resumoEProximos() {
        Paciente__c pac = new Paciente__c(Name = 'Pac', Ativo__c = true);
        insert pac;
        Profissional__c prof = new Profissional__c(Name = 'Prof');
        insert prof;
        Datetime amanha = Datetime.now().addDays(1);
        insert new Agendamento__c(Paciente__c = pac.Id, Profissional__c = prof.Id, Data_Hora__c = amanha, Valor__c = 100);

        Test.startTest();
        PainelController.Resumo r = PainelController.getResumo();
        List<Agendamento__c> proximos = PainelController.getProximos();
        Test.stopTest();

        System.assertEquals(1, r.pacientesAtivos);
        System.assertEquals(1, r.aConfirmar);
        System.assertEquals(0, r.receitaMes);
        System.assertEquals(1, proximos.size());
    }
}
