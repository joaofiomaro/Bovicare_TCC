# BoviCare — Documentação do Funcionamento e Organização do Projeto

Este documento detalha o funcionamento geral, a arquitetura de arquivos e a modularização do projeto **BoviCare**, bem como a catalogação de todas as telas em termos de suas funções e lógica associada.

---

## 📂 1. Estrutura de Pastas e Organização

O projeto foi construído seguindo o padrão de **SPA (Single Page Application)** com HTML5, CSS Vanilla e Javascript nativo. A arquitetura está organizada de modo a separar a base do sistema (**Core**) das lógicas e estilos contextuais (**Features** ou **Components**).

```text
Bovicare_TCC/
├── index.html                  # Arquivo único HTML contendo a estrutura de todas as telas
├── js/
│   ├── core/                   # Inicialização e fluxo de controle principal do App
│   │   ├── app.js              # Inicialização global do sistema, Splash Screen e eventos de inicialização
│   │   └── navigation.js       # Gerenciamento da pilha de navegação, transições fluidas e ganchos de tela
│   └── features/               # Lógicas isoladas e específicas do aplicativo
│       ├── assets.js           # Injeção dinâmica do ícone de vaca
│       ├── bottom_sheet.js     # Modal de confirmação deslizante reutilizável
│       ├── brete.js            # Simulação do controle do brete (ESP32)
│       ├── counter.js          # Animação de subida dos números (KPIs)
│       ├── form_validation.js  # Validação visual de formulários
│       ├── pull_refresh.js     # Efeito de puxar para atualizar (Pull-to-refresh)
│       ├── theme.js            # Controle de mudança de tema (Modo Escuro / Claro)
│       ├── toast.js            # Notificações temporárias suspensas
│       └── ui_handlers.js      # Manipuladores de abas, chips e seleção de perfis
└── css/
    ├── core/                   # Estilos globais e configurações de temas
    │   ├── reset.css           # Padronização de tags nativas do navegador
    │   └── tokens.css          # Paleta de cores HSL, variáveis de fontes e tokens de Dark Mode
    ├── components/             # Peças gráficas modulares e reutilizáveis
    │   ├── badge-notification.css
    │   ├── bottom-sheet.css
    │   ├── buttons.css
    │   ├── cards.css
    │   ├── forms.css
    │   ├── navigation.css
    │   ├── pull-refresh.css
    │   ├── skeleton.css
    │   ├── toast.css
    │   ├── toggle.css
    │   └── utils.css
    └── features/               # Estilizações dedicadas a telas específicas
        ├── animal_profile.css
        ├── brete.css
        ├── login.css
        ├── profile.css
        ├── splash.css
        └── vets.css
```

---

## ⚙️ 2. Como o Projeto Funciona

### 🔄 Lógica de SPA (Single Page Application)
Todas as telas do aplicativo estão declaradas dentro do arquivo [index.html](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/index.html) como blocos `<div class="screen" id="s-...">`. 
*   **Transição de Telas**: O controle de qual tela está visível é intermediado pelo arquivo [navigation.js](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/js/core/navigation.js) através da função `go(screenId)`.
*   **Pilha de Histórico (`navStack`)**: O script mantém uma pilha com o histórico de navegação. Isso permite descobrir se o usuário está avançando (`push` — transição de entrada pela direita) ou voltando (`pop` — transição de saída pela direita, revelando a tela anterior em efeito paralaxe).
*   **Aba Compartilhada (`Bottom Nav`)**: A barra de navegação inferior ([navigation.css](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/css/components/navigation.css)) é injetada globalmente e atualizada dinamicamente. Ao navegar para abas associadas (como Dashboard, Rebanho, Brete, Vets ou Perfil), a barra torna-se visível e marca a aba atual como ativa. Para fluxos de login, splash ou cadastro, ela é ocultada automaticamente por `updateSharedNav()`.
*   **Transição Física**: O navegador executa animações aceleradas por hardware usando classes de transição (`transitioning-in-right`, `transitioning-out-left`, etc.) que demoram 400ms para concluir.

### 🎨 Design System e Dark Mode
O app utiliza tokens baseados em HSL no arquivo [tokens.css](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/css/core/tokens.css). Ao ativar a propriedade `data-theme="dark"` no elemento HTML principal via função `toggleTheme()`, as variáveis HSL sofrem alteração, aplicando instantaneamente a interface escura no aplicativo com transições graduais.

---

## 📱 3. Descrição de Todas as Telas e suas Funções

Abaixo estão listadas todas as telas presentes em [index.html](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/index.html), identificadas pelos seus respectivos IDs de contêiner, e suas atribuições de lógica e comportamento.

### 🎬 A. Tela de Splash (`#s-splash`)
*   **Objetivo**: Tela de carregamento exibida na inicialização do aplicativo.
*   **Interface**: Logotipo do BoviCare em fundo verde da marca com um spinner circular de progresso.
*   **Lógica associada**:
    *   No carregamento da janela (evento `DOMContentLoaded` em [app.js](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/js/core/app.js)), inicia-se uma contagem de 1,8 segundos (1800ms).
    *   Aplica a classe de esmaecimento `fade-out` por 400ms.
    *   Redireciona para a tela de login (`s-login`) chamando `go('s-login')`.

### 🔑 B. Tela de Login (`#s-login`)
*   **Objetivo**: Autenticação de usuários cadastrados.
*   **Interface**: Painel de login contendo campos de e-mail e senha, botão de entrar, e botão de criação de conta ("Criar conta").
*   **Lógica associada**:
    *   **Validação de Formulário**: Dispara a função `validateForm()` contida em [form_validation.js](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/js/features/form_validation.js). Caso os campos sejam preenchidos incorretamente, sinaliza visualmente com a classe `input-error` e emite um Toast de erro.
    *   **Login bem-sucedido**: Ao validar, emite uma mensagem Toast (`showToast('Login realizado com sucesso!', 'success')`) e avança para a dashboard principal (`s-dash`).

### 📝 C. Tela de Cadastro (`#s-cadastro`)
*   **Objetivo**: Registro de novos usuários na plataforma.
*   **Interface**: Botões de alternância de perfil (Produtor / Veterinário), formulário com campos de nome, e-mail, telefone, nome da propriedade rural e senha.
*   **Lógica associada**:
    *   **Seleção de Perfil (`selPerfil(tipo)`)** em [ui_handlers.js](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/js/features/ui_handlers.js): Altera as cores de fundo e borda dos botões de Produtor/Veterinário para dar destaque ao perfil selecionado.
    *   **Validação**: Valida a senha (mínimo de 8 caracteres) e formatação de e-mail. Salva com sucesso e redireciona para a dashboard principal (`s-dash`).

### 📊 D. Tela de Dashboard (`#s-dash`)
*   **Objetivo**: Visão geral e atalhos de monitoramento rápido da fazenda.
*   **Interface**:
    *   Cabeçalho personalizado com saudação automática com base na hora ("Bom dia", "Boa tarde" ou "Boa noite").
    *   Indicador de sincronização local e aviso sobre vencimento de vacinas.
    *   Cards de KPI: Efetivo Total (127), Animais Prenhas (18), Alertas (5) e Vacinações Próximas (12).
    *   Linha de módulos rápidos: Rebanho, Brete, Veterinários e Relatórios.
    *   Timeline de atividades recentes ocorridas na fazenda.
*   **Lógica associada**:
    *   **Contadores Animados (`animateCounters()`)** em [counter.js](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/js/features/counter.js): Toda vez que o usuário acessa a Dashboard, os números dos KPIs sobem de `0` até o valor final (`data-target`) em uma animação de 800ms com desaceleração suave (ease-out cubic).
    *   **Pull-to-refresh (`initPullToRefresh()`)** em [pull_refresh.js](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/js/features/pull_refresh.js): Deslizar para baixo ativa o estado de recarga, simulando uma atualização de dados que dura 1,2s e mostra um Toast confirmando o sucesso.

### 🐄 E. Tela de Rebanho (`#s-rebanho`)
*   **Objetivo**: Listagem completa, busca e filtragem do gado da propriedade.
*   **Interface**: Barra de busca de brinco, nome ou RFID, chips de filtro rápido (Todos, Fêmeas, Machos, Prenhas, Alertas, Carência), listagem dos animais com tags coloridas de status.
*   **Lógica associada**:
    *   **Skeleton Loading**: Ao entrar na aba Rebanho, um componente esqueleto simulado (`rebanho-skeleton`) é renderizado por 600ms antes de revelar os animais reais (`rebanho-content`) com transição de opacidade (`opacity 0.25s ease`), promovendo uma experiência visual premium de carregamento assíncrono.
    *   **Navegação detalhada**: Clicar em qualquer linha de animal redireciona o usuário para a ficha de detalhes específica (`s-animal`).

### 📇 F. Ficha de Detalhe do Animal (`#s-animal`)
*   **Objetivo**: Prontuário individual do bovino.
*   **Interface**: Foto ilustrativa, brinco, raça, idade, peso e código único de tag RFID. Contém uma barra de progresso da gestação, grade de botões de atalho rápido para registrar manejo (Vacinação, Vermifugação, Medicação, Observação, Pesar e Prenhez) e histórico sanitário individual.
*   **Lógica associada**:
    *   Aba ativa de controle interno de sessões (Resumo, Sanitário, Reprodução, Histórico).
    *   Redirecionamento rápido para registro de manejos como vacinação (`s-vacinacao`).

### ➕ G. Cadastro de Novo Animal (`#s-animal-novo`)
*   **Objetivo**: Incluir um novo animal no efetivo da fazenda.
*   **Interface**: Atalho visual simulado para ler RFID a partir da antena do brete e formulário (Brinco/ID, Nome, Raça, Sexo, Data de Nascimento e Peso atual).
*   **Lógica associada**:
    *   **Simulação de leitura de TAG**: Mostra informações para aproximar o animal do sensor.
    *   **Confirmação**: Valida o formulário, aciona Toast de sucesso e recarrega a lista de gado.

### 💉 H. Tela de Registrar Vacinação (`#s-vacinacao`)
*   **Objetivo**: Adicionar um registro médico de imunização ao animal em questão.
*   **Interface**: Seletor de vacinas (Febre Aftosa, Brucelose, Raiva, IBR/BVD, Carbúnculo), inserção de lote de fabricação, tipo de dose (Dose única, 1ª dose, 2ª dose, Reforço), data da aplicação e veterinário CRMV responsável.
*   **Lógica associada**:
    *   Apresentação de cálculo de carência automática/agendamento de retorno (calcula automaticamente 1 ano à frente para a próxima dose).
    *   Aciona o Toast e redireciona de volta para a ficha do gado (`s-animal`).

### ⚙️ I. Painel do Brete (`#s-brete`)
*   **Objetivo**: Central de controle da porteira eletrônica inteligente e monitoramento de sensores.
*   **Interface**: Indicador de conexão bluetooth/Wi-Fi (simulação ESP32), display dinâmico da porta do brete, botões de comando (Abrir, Fechar e Emergência), status do leitor RFID acoplado (mostrando o animal posicionado no brete) e situação dos sensores IR (infravermelhos) e pedais de ação física.
*   **Lógica associada** (definida em [brete.js](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/js/features/brete.js)):
    *   `doorOpen()`: Modifica a classe da porta visual para `open pulse`, atualizando a mensagem de status da porteira para "Porta aberta" na cor verde.
    *   `doorClose()`: Remove a classe de aberta, aciona a animação de pulso e muda o status para "Porta fechada" (mecanismo travado).
    *   `doorEmergency()`: Disparado pela confirmação no Bottom Sheet. Aplica bordas e textos vermelhos de emergência ("Motor parado - obstáculo detectado").
    *   **Pedais e Sensores**: Feedback visual do estado dos sensores infravermelhos.

### 🩺 J. Tela de Veterinários (`#s-vets`)
*   **Objetivo**: Encontrar profissionais de medicina veterinária na região.
*   **Interface**: Campo de busca, grade simulando um mapa local e cards informativos de veterinários cadastrados com distância e indicação de disponibilidade ("Disponível" / "Ocupado").
*   **Lógica associada**:
    *   **Skeleton**: Possui um fluxo de esqueleto (`vets-skeleton`) semelhante ao da lista de gado, simulando a busca assíncrona por profissionais no banco de dados.

### 📞 K. Perfil de Detalhes do Veterinário (`#s-vet-det`)
*   **Objetivo**: Contatar o profissional veterinário.
*   **Interface**: Foto, nome completo, CRMV, especialidades cadastradas, raio de atendimento e botões de chamada rápida (Ligar agora, WhatsApp e E-mail).

### 📈 L. Central de Relatórios (`#s-rel`)
*   **Objetivo**: Exportação de dados consolidados do rebanho.
*   **Interface**: Filtro de data por chips e botões para download de relatórios nas categorias: Sanitário, Reprodutivo, Financeiro e Inventário Completo. Permite alternar o formato final entre PDF e CSV.
*   **Lógica associada**:
    *   Configuração do download por chamada simples ao clicar em cada card.

### 👤 M. Perfil de Usuário (`#s-perfil`)
*   **Objetivo**: Gestão de dados pessoais da conta, termos de privacidade e preferências do app.
*   **Interface**: Avatar do produtor/fazenda, atalhos de configuração de alertas, botão liga/desliga do Dark Mode, área de portabilidade de dados pessoais (Lei Geral de Proteção de Dados - LGPD) e opção de exclusão definitiva ou logout da conta.
*   **Lógica associada**:
    *   **Interruptor de Tema (`toggleTheme()`)** em [theme.js](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/js/features/theme.js): Interage com o interruptor `.toggle-switch` e gerencia a persistência no `localStorage`.
    *   **Ações Críticas via Bottom Sheet**: As ações de exclusão de conta e logout da aplicação acionam o modal de confirmação deslizante (`openSheet()`) para prevenir cliques acidentais.

---

## 🛠️ 4. Componentes Globais Compartilhados

*   **1. Notificações Toasts ([toast.js](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/js/features/toast.js))**:
    Gerador dinâmico de avisos rápidos suspensos no topo do aplicativo. Utiliza a função `showToast(message, type)`. Suporta tipos `success`, `error` e `info`.
*   **2. Painel Deslizante Bottom Sheet ([bottom_sheet.js](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/js/features/bottom_sheet.js))**:
    Modal que desliza da base da tela para confirmações destrutivas ou avisos de emergência. A função `openSheet(config)` recebe um objeto contendo título, descrição, ícone, texto do botão e a função de callback `onConfirm` executada apenas caso o usuário aprove a ação.
*   **3. Pull-To-Refresh ([pull_refresh.js](file:///c:/Users/jp_lo/OneDrive/Documentos/Projetos/Bovicare_TCC/js/features/pull_refresh.js))**:
    Ouve eventos de gestos (`touchstart`, `touchmove`, `touchend`) nos painéis roláveis da Dashboard e do Rebanho, atualizando a UI quando o usuário puxa a página além do limite superior.
