import { LightningElement, api, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/bootstrap_podo';
import { NavigationMixin } from 'lightning/navigation';
import getFicha from '@salesforce/apex/FichaController.getFicha';

const fmtData = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' });
const fmtDataHora = new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit'
});

export default class PodoFichaPaciente extends NavigationMixin(LightningElement) {
    @api recordId;
    ficha;
    erro;

    connectedCallback() {
        loadStyle(this, BOOTSTRAP).catch(() => {});
    }

    @wire(getFicha, { pacienteId: '$recordId' })
    wiredFicha({ data, error }) {
        if (data) {
            this.ficha = data;
            this.erro = undefined;
        } else if (error) {
            this.erro = 'Não foi possível carregar a ficha.';
        }
    }

    get paciente() {
        return this.ficha ? this.ficha.paciente : {};
    }

    get iniciais() {
        const nome = this.paciente.Name || '?';
        return nome
            .split(' ')
            .filter(Boolean)
            .slice(0, 2)
            .map((p) => p[0].toUpperCase())
            .join('');
    }

    get idade() {
        const n = this.paciente.Data_Nascimento__c;
        if (!n) return null;
        const hoje = new Date();
        const nasc = new Date(n + 'T00:00:00');
        let anos = hoje.getFullYear() - nasc.getFullYear();
        if (hoje < new Date(hoje.getFullYear(), nasc.getMonth(), nasc.getDate())) anos--;
        return anos + ' anos';
    }

    get local() {
        return [this.paciente.Cidade__c, this.paciente.UF__c].filter(Boolean).join(' / ');
    }

    get statusTexto() {
        return this.paciente.Ativo__c ? 'Ativo' : 'Inativo';
    }

    get statusClasse() {
        return 'badge rounded-pill mb-1 ' + (this.paciente.Ativo__c ? 'text-bg-success' : 'text-bg-danger');
    }

    get total() {
        return this.ficha ? this.ficha.totalAtendimentos : 0;
    }

    get proximos() {
        return ((this.ficha && this.ficha.proximos) || []).map((a) => ({
            id: a.Id,
            quando: fmtDataHora.format(new Date(a.Data_Hora__c)),
            detalhe: [a.Servico__r && a.Servico__r.Name, a.Profissional__r && a.Profissional__r.Name]
                .filter(Boolean)
                .join(' • '),
            status: a.Status__c
        }));
    }

    get temProximos() {
        return this.proximos.length > 0;
    }

    get atendimentos() {
        return ((this.ficha && this.ficha.atendimentos) || []).map((a) => ({
            id: a.Id,
            numero: a.Name,
            data: a.Data_Atendimento__c ? fmtData.format(new Date(a.Data_Atendimento__c)) : 'Sem data',
            servico: a.Servico__r ? a.Servico__r.Name : 'Atendimento',
            profissional: a.Profissional__r ? a.Profissional__r.Name : '',
            queixa: a.Queixa_Principal__c,
            procedimento: a.Procedimento_Realizado__c,
            orientacoes: a.Orientacoes__c
        }));
    }

    get semAtendimentos() {
        return this.ficha && this.atendimentos.length === 0;
    }

    abrirAtendimento(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: event.currentTarget.dataset.id, actionName: 'view' }
        });
    }
}
