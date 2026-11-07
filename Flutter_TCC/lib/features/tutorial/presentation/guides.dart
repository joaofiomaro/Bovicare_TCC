import 'package:flutter/material.dart';

import '../domain/tutorial_step.dart';

/// Ids dos elementos destacados pelos tutoriais (`TutorialTarget`).
abstract final class TutorialIds {
  static const navBar = 'nav.bar';

  static const dashboardKpis    = 'dashboard.kpis';
  static const dashboardAlerts  = 'dashboard.alerts';
  static const dashboardModules = 'dashboard.modules';

  static const herdSearch   = 'herd.search';
  static const herdFilters  = 'herd.filters';
  static const herdList     = 'herd.list';
  static const herdArchived = 'herd.archived';
  static const herdAdd      = 'herd.add';

  static const animalEdit    = 'animal.edit';
  static const animalTabs    = 'animal.tabs';
  static const animalActions = 'animal.actions';
  static const animalWeight  = 'animal.weight';

  static const formRfid    = 'form.rfid';
  static const formEarTag  = 'form.earTag';
  static const formBirth   = 'form.birth';
  static const formSave    = 'form.save';

  static const vaccineType       = 'vaccine.type';
  static const vaccineDate       = 'vaccine.date';
  static const vaccineQuarantine = 'vaccine.quarantine';
  static const vaccineSubmit     = 'vaccine.submit';

  static const breteConnection = 'brete.connection';
  static const breteDoors      = 'brete.doors';
  static const breteEmergency  = 'brete.emergency';
  static const breteRestart    = 'brete.restart';
  static const breteRfid       = 'brete.rfid';
  static const breteSensors    = 'brete.sensors';

  static const vetsSearch = 'vets.search';
  static const vetsFilter = 'vets.filter';
  static const vetsMap    = 'vets.map';
  static const vetsList   = 'vets.list';

  static const vetSpecialties = 'vet.specialties';
  static const vetLocation    = 'vet.location';
  static const vetContact     = 'vet.contact';

  static const reportsPeriod = 'reports.period';
  static const reportsTypes  = 'reports.types';
  static const reportsFormat = 'reports.format';

  static const profileHelp = 'profile.help';

  static const alertsSettings = 'alerts.settings';
  static const alertsList     = 'alerts.list';

  static const callsList = 'calls.list';
  static const callsNew  = 'calls.new';

  static const callReason  = 'call.reason';
  static const callUrgency = 'call.urgency';
  static const callSubmit  = 'call.submit';

  static const vetDashKpis = 'vetDash.kpis';
  static const vetDashPool = 'vetDash.pool';

  static const vetCallsTabs = 'vetCalls.tabs';

  static const vetProfileLocation  = 'vetProfile.location';
  static const vetProfileAvailable = 'vetProfile.available';
  static const vetProfilePublish   = 'vetProfile.publish';
}

/// Conteúdo dos tutoriais de cada tela, em linguagem simples.
abstract final class Guides {
  static const dashboard = ScreenGuide(
    id:    'dashboard',
    title: 'Início',
    steps: [
      TutorialStep(
        icon:  Icons.home_rounded,
        title: 'Esta é a tela inicial',
        body:  'Aqui você tem o resumo da fazenda assim que abre o app.',
      ),
      TutorialStep(
        icon:   Icons.insights_rounded,
        title:  'Números do rebanho',
        body:   'Total de animais, prenhas, alertas e vacinações, sempre atualizados. '
            'Puxe a tela para baixo para recarregar.',
        target: TutorialIds.dashboardKpis,
      ),
      TutorialStep(
        icon:   Icons.notifications_active_outlined,
        title:  'Próximos alertas',
        body:   'Vacinas a vencer, partos previstos e animais em carência. '
            'Toque em um alerta para ir direto ao animal.',
        target: TutorialIds.dashboardAlerts,
      ),
      TutorialStep(
        icon:   Icons.apps_rounded,
        title:  'Módulos',
        body:   'Atalhos para rebanho, brete, veterinários, chamados e relatórios.',
        target: TutorialIds.dashboardModules,
      ),
      TutorialStep(
        icon:   Icons.space_dashboard_outlined,
        title:  'Menu de baixo',
        body:   'Use estas abas para trocar entre Início, Rebanho, Brete, '
            'Vets e Perfil.',
        target: TutorialIds.navBar,
      ),
    ],
  );

  static const herd = ScreenGuide(
    id:    'herd',
    title: 'Rebanho',
    steps: [
      TutorialStep(
        icon:   Icons.add_rounded,
        title:  'Cadastre seus animais',
        body:   'Toque no + para adicionar um animal. Comece pelo brinco; o '
            'resto pode ser preenchido depois.',
        target: TutorialIds.herdAdd,
      ),
      TutorialStep(
        icon:   Icons.search_rounded,
        title:  'Busca',
        body:   'Procure pelo número do brinco, nome ou tag RFID.',
        target: TutorialIds.herdSearch,
      ),
      TutorialStep(
        icon:   Icons.filter_list_rounded,
        title:  'Filtros',
        body:   'Mostre só fêmeas, machos, prenhas ou animais com alerta.',
        target: TutorialIds.herdFilters,
      ),
      TutorialStep(
        icon:   Icons.touch_app_outlined,
        title:  'Lista de animais',
        body:   'Toque em um animal para abrir a ficha. Segure para selecionar '
            'vários, ou arraste para o lado para excluir.',
        target: TutorialIds.herdList,
      ),
      TutorialStep(
        icon:   Icons.inventory_2_outlined,
        title:  'Arquivados',
        body:   'Animais vendidos ou que saíram do rebanho ficam guardados aqui.',
        target: TutorialIds.herdArchived,
      ),
    ],
  );

  static const animalProfile = ScreenGuide(
    id:    'animal_profile',
    title: 'Ficha do animal',
    steps: [
      TutorialStep(
        icon:   Icons.edit_outlined,
        title:  'Editar dados',
        body:   'Corrija brinco, raça, peso ou tag RFID a qualquer momento.',
        target: TutorialIds.animalEdit,
      ),
      TutorialStep(
        icon:   Icons.tab_rounded,
        title:  'Abas da ficha',
        body:   'Resumo, sanitário, reprodução e histórico: tudo sobre o animal '
            'em um só lugar.',
        target: TutorialIds.animalTabs,
      ),
      TutorialStep(
        icon:   Icons.bolt_rounded,
        title:  'Ações rápidas',
        body:   'Registre vacina, vermífugo, medicação, pesagem ou prenhez com um toque.',
        target: TutorialIds.animalActions,
      ),
      TutorialStep(
        icon:   Icons.show_chart_rounded,
        title:  'Evolução do peso',
        body:   'O gráfico mostra como o peso mudou a cada pesagem.',
        target: TutorialIds.animalWeight,
      ),
    ],
  );

  static const animalForm = ScreenGuide(
    id:    'animal_form',
    title: 'Cadastro de animal',
    steps: [
      TutorialStep(
        icon:   Icons.nfc_rounded,
        title:  'Tag RFID',
        body:   'Se o animal tem tag eletrônica, leia pelo brete para vincular '
            'automaticamente.',
        target: TutorialIds.formRfid,
      ),
      TutorialStep(
        icon:   Icons.tag_rounded,
        title:  'Brinco',
        body:   'Use o mesmo número do brinco do animal. Campos com * são '
            'obrigatórios.',
        target: TutorialIds.formEarTag,
      ),
      TutorialStep(
        icon:   Icons.calendar_month_outlined,
        title:  'Datas',
        body:   'Toque no campo para abrir o calendário. Se não souber o dia '
            'exato, escolha um aproximado.',
        target: TutorialIds.formBirth,
      ),
      TutorialStep(
        icon:   Icons.check_circle_outline_rounded,
        title:  'Salvar',
        body:   'Confira os dados e salve. Dá para editar depois na ficha.',
        target: TutorialIds.formSave,
      ),
    ],
  );

  static const vaccination = ScreenGuide(
    id:    'vaccination',
    title: 'Vacinação',
    steps: [
      TutorialStep(
        icon:   Icons.vaccines_outlined,
        title:  'Escolha a vacina',
        body:   'Selecione a vacina aplicada na lista.',
        target: TutorialIds.vaccineType,
      ),
      TutorialStep(
        icon:   Icons.calendar_month_outlined,
        title:  'Data da aplicação',
        body:   'Já vem com o dia de hoje; toque para mudar se precisar.',
        target: TutorialIds.vaccineDate,
      ),
      TutorialStep(
        icon:   Icons.timer_outlined,
        title:  'Carência',
        body:   'O app calcula a próxima dose e até quando o animal fica em '
            'carência (sem abate nem venda de leite).',
        target: TutorialIds.vaccineQuarantine,
      ),
      TutorialStep(
        icon:   Icons.check_circle_outline_rounded,
        title:  'Registrar',
        body:   'Ao registrar, a próxima dose e a carência viram alertas '
            'automáticos.',
        target: TutorialIds.vaccineSubmit,
      ),
    ],
  );

  static const brete = ScreenGuide(
    id:    'brete',
    title: 'Brete eletrônico',
    steps: [
      TutorialStep(
        icon:   Icons.bluetooth_rounded,
        title:  'Conexão',
        body:   'Mostra se o celular está conectado ao brete pelo Bluetooth. '
            'Ligue o Bluetooth e fique perto do equipamento.',
        target: TutorialIds.breteConnection,
      ),
      TutorialStep(
        icon:   Icons.sensor_door_outlined,
        title:  'Portas',
        body:   'Abra e feche a porta de entrada e a de saída. A cor mostra o '
            'estado de cada uma.',
        target: TutorialIds.breteDoors,
      ),
      TutorialStep(
        icon:   Icons.report_rounded,
        title:  'Parada de emergência',
        body:   'Para as portas na hora. Depois use Rearmar para voltar a operar.',
        target: TutorialIds.breteEmergency,
      ),
      TutorialStep(
        icon:   Icons.power_settings_new_rounded,
        title:  'Reiniciar sistema',
        body:   'Se o brete travar ou uma porta indicar falha, toque aqui: o '
            'app para as portas, limpa as falhas e reconecta.',
        target: TutorialIds.breteRestart,
      ),
      TutorialStep(
        icon:   Icons.nfc_rounded,
        title:  'Leitura da tag',
        body:   'Quando o animal entra, a tag RFID é lida e o app mostra qual '
            'é. Se a tag for nova, toque em Cadastrar.',
        target: TutorialIds.breteRfid,
      ),
      TutorialStep(
        icon:   Icons.sensors_rounded,
        title:  'Sensores',
        body:   'Mostram em tempo real os sensores infravermelhos, os botões '
            'e os pedais do brete.',
        target: TutorialIds.breteSensors,
      ),
    ],
  );

  static const vetsList = ScreenGuide(
    id:    'vets_list',
    title: 'Veterinários',
    steps: [
      TutorialStep(
        icon:   Icons.search_rounded,
        title:  'Busca',
        body:   'Procure pelo nome ou especialidade.',
        target: TutorialIds.vetsSearch,
      ),
      TutorialStep(
        icon:   Icons.tune_rounded,
        title:  'Só disponíveis',
        body:   'Mostre apenas quem está aceitando novos atendimentos agora.',
        target: TutorialIds.vetsFilter,
      ),
      TutorialStep(
        icon:   Icons.map_outlined,
        title:  'Mapa',
        body:   'Veja onde cada veterinário atende em relação à sua fazenda.',
        target: TutorialIds.vetsMap,
      ),
      TutorialStep(
        icon:   Icons.person_search_outlined,
        title:  'Lista',
        body:   'Os mais próximos primeiro. Toque em um veterinário para ver o '
            'perfil; aqui também dá para esconder o mapa.',
        target: TutorialIds.vetsList,
      ),
    ],
  );

  static const vetDetail = ScreenGuide(
    id:    'vet_detail',
    title: 'Perfil do veterinário',
    steps: [
      TutorialStep(
        icon:   Icons.workspace_premium_outlined,
        title:  'Especialidades',
        body:   'As áreas em que este veterinário atende.',
        target: TutorialIds.vetSpecialties,
      ),
      TutorialStep(
        icon:   Icons.place_outlined,
        title:  'Região de atendimento',
        body:   'A cidade base e até quantos quilômetros ele se desloca.',
        target: TutorialIds.vetLocation,
      ),
      TutorialStep(
        icon:   Icons.call_outlined,
        title:  'Contato',
        body:   'Ligue, mande WhatsApp ou e-mail direto pelo app.',
        target: TutorialIds.vetContact,
      ),
    ],
  );

  static const reports = ScreenGuide(
    id:    'reports',
    title: 'Relatórios',
    steps: [
      TutorialStep(
        icon:   Icons.date_range_outlined,
        title:  'Período',
        body:   'Último mês, trimestre, ano ou um período livre.',
        target: TutorialIds.reportsPeriod,
      ),
      TutorialStep(
        icon:   Icons.picture_as_pdf_outlined,
        title:  'Formato',
        body:   'PDF para imprimir ou mostrar; CSV para abrir em planilha.',
        target: TutorialIds.reportsFormat,
      ),
      TutorialStep(
        icon:   Icons.description_outlined,
        title:  'Tipo de relatório',
        body:   'Toque no relatório que precisa (sanitário, reprodutivo, '
            'financeiro, vendas ou inventário) para gerar e compartilhar.',
        target: TutorialIds.reportsTypes,
      ),
    ],
  );

  static const profile = ScreenGuide(
    id:    'profile',
    title: 'Perfil',
    steps: [
      TutorialStep(
        icon:  Icons.person_outline_rounded,
        title: 'Sua conta',
        body:  'Edite seus dados, ajuste os alertas (ou o perfil profissional) '
            'e escolha o tema claro ou escuro.',
      ),
      TutorialStep(
        icon:  Icons.privacy_tip_outlined,
        title: 'Privacidade',
        body:  'Baixe uma cópia dos seus dados ou exclua a conta quando quiser.',
      ),
      TutorialStep(
        icon:   Icons.help_outline_rounded,
        title:  'Ajuda e tutoriais',
        body:   'Ligue ou desligue as dicas e reveja a apresentação do app.',
        target: TutorialIds.profileHelp,
      ),
    ],
  );

  static const alerts = ScreenGuide(
    id:    'alerts',
    title: 'Alertas',
    steps: [
      TutorialStep(
        icon:   Icons.list_alt_rounded,
        title:  'O que vem por aí',
        body:   'Vacinas a vencer, partos previstos e animais em carência. '
            'Toque em um alerta para abrir a ficha do animal.',
        target: TutorialIds.alertsList,
      ),
      TutorialStep(
        icon:   Icons.tune_rounded,
        title:  'Configurar',
        body:   'Escolha com quantos dias de antecedência quer ser avisado e '
            'quais tipos de alerta ver.',
        target: TutorialIds.alertsSettings,
      ),
    ],
  );

  static const producerCalls = ScreenGuide(
    id:    'producer_calls',
    title: 'Meus chamados',
    steps: [
      TutorialStep(
        icon:   Icons.add_rounded,
        title:  'Pedir atendimento',
        body:   'Abra um chamado para pedir a visita de um veterinário.',
        target: TutorialIds.callsNew,
      ),
      TutorialStep(
        icon:   Icons.history_rounded,
        title:  'Acompanhe',
        body:   'Veja aqui se o chamado foi aceito, agendado ou concluído.',
        target: TutorialIds.callsList,
      ),
    ],
  );

  static const openServiceCall = ScreenGuide(
    id:    'open_service_call',
    title: 'Novo chamado',
    steps: [
      TutorialStep(
        icon:   Icons.edit_note_rounded,
        title:  'Conte o que aconteceu',
        body:   'Escreva o motivo e descreva o problema com suas palavras. '
            'Quanto mais detalhes, melhor o veterinário se prepara.',
        target: TutorialIds.callReason,
      ),
      TutorialStep(
        icon:   Icons.priority_high_rounded,
        title:  'Urgência',
        body:   'Escolha Urgente só quando o animal precisa de atendimento '
            'no mesmo dia.',
        target: TutorialIds.callUrgency,
      ),
      TutorialStep(
        icon:   Icons.send_rounded,
        title:  'Enviar',
        body:   'O chamado fica visível para os veterinários do BoviCare, que '
            'podem aceitá-lo e agendar a visita.',
        target: TutorialIds.callSubmit,
      ),
    ],
  );

  static const vetDashboard = ScreenGuide(
    id:    'vet_dashboard',
    title: 'Início',
    steps: [
      TutorialStep(
        icon:   Icons.insights_rounded,
        title:  'Seu resumo',
        body:   'Chamados abertos na região, seus atendimentos e agendamentos.',
        target: TutorialIds.vetDashKpis,
      ),
      TutorialStep(
        icon:   Icons.inbox_outlined,
        title:  'Chamados abertos',
        body:   'Pedidos de produtores aguardando um veterinário. Toque para '
            'ver os detalhes e aceitar.',
        target: TutorialIds.vetDashPool,
      ),
      TutorialStep(
        icon:   Icons.space_dashboard_outlined,
        title:  'Menu de baixo',
        body:   'Troque entre Início, Chamados, Agenda e Perfil.',
        target: TutorialIds.navBar,
      ),
    ],
  );

  static const vetCalls = ScreenGuide(
    id:    'vet_calls',
    title: 'Chamados',
    steps: [
      TutorialStep(
        icon:   Icons.tab_rounded,
        title:  'Três listas',
        body:   'Abertos: pedidos novos. Meus ativos: os que você aceitou. '
            'Histórico: os concluídos.',
        target: TutorialIds.vetCallsTabs,
      ),
      TutorialStep(
        icon:  Icons.touch_app_outlined,
        title: 'Abrir um chamado',
        body:  'Toque em um chamado para ver os detalhes e as ações disponíveis.',
      ),
    ],
  );

  static const vetAgenda = ScreenGuide(
    id:    'vet_agenda',
    title: 'Agenda',
    steps: [
      TutorialStep(
        icon:  Icons.event_note_outlined,
        title: 'Seus agendamentos',
        body:  'As visitas com data marcada aparecem aqui. Você agenda ao '
            'aceitar um chamado.',
      ),
      TutorialStep(
        icon:  Icons.touch_app_outlined,
        title: 'Detalhes',
        body:  'Toque em uma visita para ver as opções do atendimento.',
      ),
    ],
  );

  static const vetProfessionalProfile = ScreenGuide(
    id:    'vet_professional_profile',
    title: 'Perfil profissional',
    steps: [
      TutorialStep(
        icon:  Icons.badge_outlined,
        title: 'Seus dados',
        body:  'Preencha CRMV, especialidades e contato. É o que os produtores veem.',
      ),
      TutorialStep(
        icon:   Icons.my_location_rounded,
        title:  'Base de atendimento',
        body:   'Marque sua localização para aparecer para fazendas próximas.',
        target: TutorialIds.vetProfileLocation,
      ),
      TutorialStep(
        icon:   Icons.toggle_on_outlined,
        title:  'Disponibilidade',
        body:   'Desligue quando não puder pegar novos atendimentos.',
        target: TutorialIds.vetProfileAvailable,
      ),
      TutorialStep(
        icon:   Icons.public_rounded,
        title:  'Publicar',
        body:   'Publique para entrar na lista de veterinários do app.',
        target: TutorialIds.vetProfilePublish,
      ),
    ],
  );
}
