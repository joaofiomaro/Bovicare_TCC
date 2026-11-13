# EC09 — Brete Eletrônico e Leitura RFID

## Objetivo
Demonstrar o controle do brete (porteira, emergência, sensores) e a
identificação automática do animal pela tag RFID, com cadastro direto quando a
tag ainda não existe no rebanho.

## Cenário
No manejo da manhã, o produtor passa os animais pelo brete. Cada animal é
identificado pela tag eletrônica; um bezerro recém-comprado tem tag mas ainda
não foi cadastrado.

## Pré-condições
- Produtor logado com animais que tenham RFID (cadastrados lendo a tag).
- **Com hardware:** ESP32 com o firmware 1.5.1 (`../BoviCare_Firmware/BoviCare_Brete_Final/BoviCare_Brete_Final.ino`), ligada e perto
  do celular (Bluetooth LE, `docs/PROTOCOLO_BLE.md`). **Sem hardware:** com
  `BRETE_CONEXAO=simulacao` (ou rodando na web/desktop), o painel abre em
  **modo simulação**. Declare isso no TCC.
- A leitura RFID depende do leitor no firmware. Com o firmware 1.1.0 (sem
  RFID), os passos 3 e 4 só funcionam na simulação.

## Fluxo

| Passo | Tela | Ação do usuário | Resposta do sistema |
|---|---|---|---|
| 1 | Brete | Abre a aba | Procura e conecta ao brete; selo "Conectado" (ou "Simulação"); duas portas fechadas |
| 2 | Brete | Toca **Abrir** na porta de entrada | Comando `ABRIR 1`; porta passa por "Em movimento" e fica "Aberta" |
| 3 | Brete | Toca **Ler tag** | Leitura RFID; se a tag pertence ao rebanho, mostra o animal e **Ver ficha** |
| 4 | Brete | Lê uma tag desconhecida | Mostra "Tag não cadastrada" e **Cadastrar**, que abre o formulário com o RFID preenchido |
| 5 | Brete | Toca **Abrir** na porta de saída | Recusado: "Feche a outra porta antes de abrir esta" (intertravamento) |
| 6 | Brete | Toca **Parada de emergência** e confirma | Motores travados; Abrir/Fechar bloqueados |
| 7 | Brete | Toca **Rearmar brete** | Sai da emergência; as portas ficam onde pararam |

```mermaid
sequenceDiagram
  actor P as Produtor
  participant App
  participant E as ESP32 (BLE)
  P->>App: Abrir (entrada)
  App->>E: comando "#5 ABRIR 1"
  E-->>App: evento RESP {"id":5,"res":"OK"}
  E-->>App: estado {"p1":"ABRINDO",...} → {"p1":"ABERTA",...}
  App-->>P: Porta de entrada aberta
```

## Regras aplicadas
- O estado mostrado vem do dispositivo; o app só envia comandos.
- Uma porta só abre com a outra fechada (intertravamento do firmware).
- A porta não fecha com o sensor infravermelho obstruído; se o obstáculo
  aparece no fechamento, o firmware freia e reabre.
- Emergência trava todos os comandos até o rearme; ambos pedem confirmação.
- A tag é associada ao animal com o mesmo RFID no rebanho ativo.

## Critérios de sucesso
- [ ] Abrir/fechar refletem o estado em até 2 s.
- [ ] Emergência bloqueia Abrir/Fechar até o rearme.
- [ ] Tag conhecida abre a ficha do animal correto.
- [ ] Tag desconhecida abre o cadastro com o RFID preenchido.

## Evidências (capturas reais)
1. Painel com porta fechada e selo de conexão.
2. Porta aberta.
3. Animal identificado pelo RFID.
4. Estado de emergência.
5. Formulário de cadastro com o RFID preenchido.

## Limitações observadas
- Sem o ESP32, a validação é feita em modo simulação (mesmas regras do firmware).
- A pesagem automática pela balança do brete não faz parte do protocolo atual.

## Imagens — prompts para IA
```
A modern cattle chute (squeeze chute) on a Brazilian farm with a small electronic box
mounted on the side, an antenna for RFID, a Nelore cow inside, the farmer holding a
smartphone showing an abstract control panel, morning light.
```
```
Conceptual diagram-style illustration: a cow ear tag emitting radio waves to a
reader, connected by a dotted line to a Wi-Fi router and a smartphone, flat style.
```
