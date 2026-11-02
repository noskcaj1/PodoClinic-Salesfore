// Dados de exemplo do PodoClinic. Rode: sf apex run --file scripts/apex/dados-exemplo.apex
List<Profissional__c> profs = new List<Profissional__c>{
    new Profissional__c(Name = 'Dra. Ana Souza (Exemplo)', Especialidade__c = 'Podologia Clínica', Ativo__c = true),
    new Profissional__c(Name = 'Dr. Carlos Lima (Exemplo)', Especialidade__c = 'Podologia Esportiva', Ativo__c = true)
};
insert profs;

List<Servico__c> servs = new List<Servico__c>{
    new Servico__c(Name = 'Tratamento de unha encravada', Duracao_Minutos__c = 60, Valor__c = 180, Ativo__c = true),
    new Servico__c(Name = 'Podologia completa', Duracao_Minutos__c = 60, Valor__c = 120, Ativo__c = true),
    new Servico__c(Name = 'Avaliação biomecânica', Duracao_Minutos__c = 30, Valor__c = 90, Ativo__c = true)
};
insert servs;

List<Paciente__c> pacs = new List<Paciente__c>{
    new Paciente__c(Name = 'Maria Oliveira (Exemplo)', Telefone__c = '(11) 99999-1111', Cidade__c = 'São Paulo', UF__c = 'SP', Ativo__c = true),
    new Paciente__c(Name = 'João Pereira (Exemplo)', Telefone__c = '(11) 98888-2222', Cidade__c = 'Santo André', UF__c = 'SP', Ativo__c = true),
    new Paciente__c(Name = 'Helena Costa (Exemplo)', Telefone__c = '(21) 97777-3333', Cidade__c = 'Rio de Janeiro', UF__c = 'RJ', Ativo__c = true),
    new Paciente__c(Name = 'Roberto Alves (Exemplo)', Telefone__c = '(31) 96666-4444', Cidade__c = 'Belo Horizonte', UF__c = 'MG', Ativo__c = true)
};
insert pacs;

// Passados (serão concluídos) e futuros. Cada tupla: dias de diferença, hora, paciente, profissional, serviço
List<List<Integer>> plano = new List<List<Integer>>{
    new List<Integer>{ -6, 9, 0, 0, 0 }, new List<Integer>{ -4, 10, 1, 0, 1 }, new List<Integer>{ -3, 14, 2, 1, 2 },
    new List<Integer>{ -1, 11, 0, 1, 1 }, new List<Integer>{ 0, 15, 3, 0, 1 }, new List<Integer>{ 0, 16, 1, 1, 2 },
    new List<Integer>{ 1, 9, 2, 0, 0 }, new List<Integer>{ 1, 10, 0, 1, 1 }, new List<Integer>{ 2, 14, 3, 0, 1 },
    new List<Integer>{ 3, 11, 1, 1, 0 }, new List<Integer>{ 4, 9, 2, 0, 2 }
};
List<Agendamento__c> ags = new List<Agendamento__c>();
for (List<Integer> p : plano) {
    ags.add(new Agendamento__c(
        Data_Hora__c = Datetime.newInstance(Date.today().addDays(p[0]), Time.newInstance(p[1], 0, 0, 0)),
        Paciente__c = pacs[p[2]].Id, Profissional__c = profs[p[3]].Id, Servico__c = servs[p[4]].Id,
        Valor__c = servs[p[4]].Valor__c
    ));
}
insert ags;

// Passados viram "Concluído" (gera o Atendimento automaticamente); alguns futuros ficam "Confirmado"
for (Agendamento__c a : ags) {
    if (a.Data_Hora__c < Datetime.now().addHours(-2)) { a.Status__c = 'Concluido'; }
    else if (Math.mod(ags.indexOf(a), 2) == 0) { a.Status__c = 'Confirmado'; }
}
update ags;
System.debug('Criados: ' + ags.size() + ' agendamentos');
