# Estudos de Caso — BoviCare

Estudos de caso que demonstram o BoviCare em cenários realistas de uso. Cada arquivo
descreve um cenário, a persona, o passo a passo no app, as regras de negócio aplicadas,
um exemplo numérico, os critérios de sucesso e as evidências a coletar.

> **Natureza dos cenários:** todos são **simulados**, com personas e dados fictícios,
> executados no app real (Firebase de desenvolvimento). Isso deve ser declarado no texto
> do TCC. Não há validação em campo com produtores reais.

## Índice

| # | Estudo de caso | Perfil | Módulos |
|---|---|---|---|
| [EC01](EC01_gestao_do_rebanho.md) | Cadastro e gestão do rebanho | Produtor | Auth, Rebanho |
| [EC02](EC02_manejo_sanitario.md) | Manejo sanitário e carência | Produtor | Vacinação, Dashboard |
| [EC03](EC03_ganho_de_peso.md) | Controle de peso e GMD | Produtor | Pesagens |
| [EC04](EC04_baixa_do_rebanho.md) | Venda em lote e óbito | Produtor | Baixa, Arquivados |
| [EC05](EC05_atendimento_veterinario.md) | Chamado de atendimento veterinário | Produtor + Vet | Chamados |
| [EC06](EC06_localizacao_de_veterinarios.md) | Localização de veterinários | Produtor | Mapa, Contato |
| [EC07](EC07_relatorios_gerenciais.md) | Relatórios gerenciais | Produtor | Relatórios |
| [EC08](EC08_seguranca_e_lgpd.md) | Segurança, papéis e LGPD | Ambos | Regras, Perfil |
| [EC09](EC09_brete_eletronico.md) | Brete eletrônico e leitura RFID | Produtor | Brete, Rebanho |

**Brete IoT:** o app implementa o protocolo MQTT (`docs/BRETE_MQTT_PROTOCOLO.md`). Sem o
ESP32, o EC09 é executado em modo simulação — declare isso no TCC.

## Como usar as imagens

Cada arquivo tem uma seção **Imagens** com dois tipos de item:

1. **Capturas de tela reais** — tire do app rodando no emulador. Nunca substitua por
   imagem gerada por IA: a banca vai comparar com o app.
2. **Prompts para IA** — ilustrações de contexto (cenário rural, persona). Use para a
   abertura do estudo de caso, nunca para representar telas do sistema.

Para manter as ilustrações consistentes, acrescente este estilo a todos os prompts:

```
Style: clean flat vector illustration, soft shadows, brand palette dark green #1C6B3A,
light green #E8F3EC, warm amber accents, white background, no text, no logos,
Brazilian countryside setting, 16:9.
```

Os fluxos estão em diagramas Mermaid (renderizam no GitHub, VS Code e Typora). Para o
documento Word/PDF, exporte o diagrama como imagem em https://mermaid.live.
