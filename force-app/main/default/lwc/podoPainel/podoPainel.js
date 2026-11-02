import { LightningElement, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/bootstrap_podo';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getResumo from '@salesforce/apex/PainelController.getResumo';
import getProximos from '@salesforce/apex/PainelController.getProximos';

export default class PodoPainel extends NavigationMixin(LightningElement) {
    resumo;
    proximos = [];
    carregando = true;
    erro;
    _resumoWire;
    _proximosWire;

    connectedCallback() {
        loadStyle(this, BOOTSTRAP).catch(() => {});
    }

    @wire(getResumo)
    wiredResumo(result) {
        this._resumoWire = result;
        if (result.data) {
            this.resumo = result.data;
            this.carregando = false;
        } else if (result.error) {
            this.erro = 'Não foi possível carregar o resumo.';
            this.carregando = false;
        }
    }

    @wire(getProximos)
    wiredProximos(result) {
        this._proximosWire = result;
        if (result.data) {
            this.proximos = result.data.map((a) => ({
                id: a.Id,
                hora: this.formatarHora(a.Data_Hora__c),
                dia: this.formatarDia(a.Data_Hora__c),
                paciente: a.Paciente__r ? a.Paciente__r.Name : 'Sem paciente',
                detalhe: [a.Servico__r && a.Servico__r.Name, a.Profissional__r && a.Profissional__r.Name]
                    .filter(Boolean)
                    .join(' • '),
                status: a.Status__c,
                badgeClass: 'badge rounded-pill ' + (a.Status__c === 'Confirmado' ? 'text-bg-success' : 'text-bg-warning')
            }));
        }
    }

    get saudacao() {
        const h = new Date().getHours();
        if (h < 12) return 'Bom dia';
        if (h < 18) return 'Boa tarde';
        return 'Boa noite';
    }

    get dataHoje() {
        return new Intl.DateTimeFormat('pt-BR', { weekday: 'long', day: 'numeric', month: 'long' }).format(new Date());
    }

    get receitaFormatada() {
        const v = this.resumo ? this.resumo.receitaMes : 0;
        return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(v);
    }

    get semProximos() {
        return !this.carregando && this.proximos.length === 0;
    }

    formatarHora(valor) {
        return new Intl.DateTimeFormat('pt-BR', { hour: '2-digit', minute: '2-digit' }).format(new Date(valor));
    }

    formatarDia(valor) {
        return new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: 'short' }).format(new Date(valor));
    }

    atualizar() {
        this.carregando = true;
        Promise.all([refreshApex(this._resumoWire), refreshApex(this._proximosWire)]).finally(() => {
            this.carregando = false;
        });
    }

    novoAgendamento() {
        this.novo('Agendamento__c');
    }

    novoPaciente() {
        this.novo('Paciente__c');
    }

    verAgenda() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Agendamento__c', actionName: 'list' },
            state: { filterName: 'Recent' }
        });
    }

    abrirAgendamento(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: event.currentTarget.dataset.id, actionName: 'view' }
        });
    }

    novo(objeto) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: objeto, actionName: 'new' }
        });
    }
}
