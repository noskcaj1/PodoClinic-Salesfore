import { LightningElement, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/bootstrap_podo';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getProfissionais from '@salesforce/apex/AgendaController.getProfissionais';
import getAgendamentos from '@salesforce/apex/AgendaController.getAgendamentos';

const HORA_INICIAL = 7;
const HORA_FINAL = 20;
const DIAS_SEMANA = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

function inicioDaSemana(data) {
    const d = new Date(data.getFullYear(), data.getMonth(), data.getDate());
    const deslocamento = (d.getDay() + 6) % 7; // segunda = 0
    d.setDate(d.getDate() - deslocamento);
    return d;
}

function mesmoDia(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

export default class PodoAgenda extends NavigationMixin(LightningElement) {
    semanaInicio = inicioDaSemana(new Date());
    profissionalId = null;
    profissionais = [];
    agendamentos = [];
    erro;

    connectedCallback() {
        loadStyle(this, BOOTSTRAP).catch(() => {});
    }

    @wire(getProfissionais)
    wiredProfissionais({ data }) {
        if (data) {
            this.profissionais = [{ value: '', label: 'Todos os profissionais' }, ...data];
        }
    }

    get inicioIso() {
        return this.semanaInicio.toISOString();
    }

    get fimIso() {
        const fim = new Date(this.semanaInicio);
        fim.setDate(fim.getDate() + 7);
        return fim.toISOString();
    }

    @wire(getAgendamentos, { inicio: '$inicioIso', fim: '$fimIso', profissionalId: '$profissionalId' })
    wiredAgendamentos({ data, error }) {
        if (data) {
            this.agendamentos = data;
            this.erro = undefined;
        } else if (error) {
            this.erro = 'Não foi possível carregar a agenda.';
        }
    }

    get tituloSemana() {
        const fim = new Date(this.semanaInicio);
        fim.setDate(fim.getDate() + 6);
        const fmt = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: 'short' });
        return fmt.format(this.semanaInicio) + ' – ' + fmt.format(fim) + ' de ' + fim.getFullYear();
    }

    get dias() {
        const hoje = new Date();
        return DIAS_SEMANA.map((nome, i) => {
            const d = new Date(this.semanaInicio);
            d.setDate(d.getDate() + i);
            return {
                key: nome,
                nome,
                numero: d.getDate(),
                classe: 'dia-topo' + (mesmoDia(d, hoje) ? ' dia-hoje' : '')
            };
        });
    }

    get linhas() {
        const porCelula = {};
        this.agendamentos.forEach((a) => {
            const d = new Date(a.Data_Hora__c);
            const chave = d.getDay() + '-' + d.getHours();
            (porCelula[chave] = porCelula[chave] || []).push({
                id: a.Id,
                hora: new Intl.DateTimeFormat('pt-BR', { hour: '2-digit', minute: '2-digit' }).format(d),
                paciente: a.Paciente__r ? a.Paciente__r.Name : 'Sem paciente',
                detalhe: a.Servico__r ? a.Servico__r.Name : '',
                classe: 'evento evento-' + (a.Status__c || '').toLowerCase()
            });
        });

        const linhas = [];
        for (let h = HORA_INICIAL; h <= HORA_FINAL; h++) {
            const celulas = DIAS_SEMANA.map((nome, i) => {
                const dia = new Date(this.semanaInicio);
                dia.setDate(dia.getDate() + i);
                dia.setHours(h, 0, 0, 0);
                return {
                    key: nome + h,
                    iso: dia.toISOString(),
                    itens: porCelula[dia.getDay() + '-' + h] || []
                };
            });
            linhas.push({ key: h, rotulo: String(h).padStart(2, '0') + ':00', celulas });
        }
        return linhas;
    }

    anterior() {
        this.mudarSemana(-7);
    }

    proxima() {
        this.mudarSemana(7);
    }

    hoje() {
        this.semanaInicio = inicioDaSemana(new Date());
    }

    mudarSemana(dias) {
        const d = new Date(this.semanaInicio);
        d.setDate(d.getDate() + dias);
        this.semanaInicio = d;
    }

    mudarProfissional(event) {
        this.profissionalId = event.target.value || null;
    }

    novoNaCelula(event) {
        const valores = { Data_Hora__c: event.currentTarget.dataset.iso };
        if (this.profissionalId) {
            valores.Profissional__c = this.profissionalId;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Agendamento__c', actionName: 'new' },
            state: { defaultFieldValues: encodeDefaultFieldValues(valores) }
        });
    }

    abrirEvento(event) {
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: event.currentTarget.dataset.id, actionName: 'view' }
        });
    }
}
