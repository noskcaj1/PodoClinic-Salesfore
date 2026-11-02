@IsTest
private class PodoClinicTest {
    private static final String CPF_VALIDO = '529.982.247-25';

    @IsTest
    static void cpfValidator() {
        System.assert(CpfValidator.isValid(CPF_VALIDO));
        System.assert(!CpfValidator.isValid('111.111.111-11'));
        System.assert(!CpfValidator.isValid('123'));
        System.assert(!CpfValidator.isValid(null));
        System.assert(!CpfValidator.isValid('529.982.247-24'));
    }

    @IsTest
    static void cpfTriggers() {
        insert new Paciente__c(Name = 'Ok', CPF__c = CPF_VALIDO);
        Database.SaveResult sr = Database.insert(new Paciente__c(Name = 'Ruim', CPF__c = '111.111.111-11'), false);
        System.assert(!sr.isSuccess());
        Database.SaveResult sp = Database.insert(new Profissional__c(Name = 'Prof', CPF__c = '123'), false);
        System.assert(!sp.isSuccess());
    }

    @IsTest
    static void conflitoDeHorario() {
        Profissional__c p = new Profissional__c(Name = 'Prof');
        insert p;
        Servico__c s = new Servico__c(Name = 'Podia', Duracao_Minutos__c = 60);
        insert s;
        Datetime t = Datetime.now().addDays(1);
        insert new Agendamento__c(Profissional__c = p.Id, Servico__c = s.Id, Data_Hora__c = t);

        Database.SaveResult conflito = Database.insert(
            new Agendamento__c(Profissional__c = p.Id, Servico__c = s.Id, Data_Hora__c = t.addMinutes(30)), false);
        System.assert(!conflito.isSuccess());

        Database.SaveResult livre = Database.insert(
            new Agendamento__c(Profissional__c = p.Id, Servico__c = s.Id, Data_Hora__c = t.addMinutes(60)), false);
        System.assert(livre.isSuccess());

        Agendamento__c a1 = new Agendamento__c(Profissional__c = p.Id, Servico__c = s.Id, Data_Hora__c = t.addDays(2));
        Agendamento__c a2 = new Agendamento__c(Profissional__c = p.Id, Servico__c = s.Id, Data_Hora__c = t.addDays(2));
        List<Database.SaveResult> lote = Database.insert(new List<Agendamento__c>{ a1, a2 }, false);
        System.assertEquals(1, (lote[0].isSuccess() ? 1 : 0) + (lote[1].isSuccess() ? 1 : 0));
    }

    @IsTest
    static void conclusaoCriaAtendimento() {
        Paciente__c pac = new Paciente__c(Name = 'Pac');
        insert pac;
        Profissional__c p = new Profissional__c(Name = 'Prof');
        insert p;
        Agendamento__c a = new Agendamento__c(Paciente__c = pac.Id, Profissional__c = p.Id, Data_Hora__c = Datetime.now().addDays(1));
        insert a;
        a.Status__c = 'Concluido';
        update a;
        update a;
        System.assertEquals(1, [SELECT COUNT() FROM Atendimento__c WHERE Agendamento__c = :a.Id]);
    }
}
