# Sugestões de Melhorias Futuras — Pacote POSTE

O arquivo `POSTE.LSP` foi estruturado de forma modular (funções `RVR:*` reutilizáveis) justamente para servir de base a um pacote maior de ferramentas de projeto de rede elétrica. Sugestões organizadas por prioridade:

## Curto prazo

- **`RENPOSTE`** — Renumerar postes existentes em sequência (por ordem de seleção manual ou por critério espacial, ex.: da esquerda para a direita / de cima para baixo). Reaproveita `RVR:ExtractPostNumber`, `RVR:FormatPostId` e `RVR:GetEntityText`.
- **Verificação automática do estilo de MLeader atual** — antes de criar o leader, checar se o `MLEADERSTYLE` corrente está configurado para conteúdo de texto (Mtext) e não bloco, avisando o usuário (ou trocando automaticamente para um estilo dedicado `POSTES`) quando não estiver.
- **Bloco de símbolo do poste** — opção de inserir automaticamente um bloco (círculo, símbolo padrão de concessionária, etc.) no ponto central do poste, além do MLeader, com atributo vinculado ao número do poste.
- **Validação de duplicidade** — checar se o ponto clicado como centro do poste já possui uma identificação muito próxima (tolerância configurável) e alertar o usuário antes de criar uma nova.

## Médio prazo

- **`EXPORTAPOSTES`** — Exportar todos os postes do desenho (número, X, Y, layer, handle) para CSV/planilha, útil para memoriais descritivos e conferência de campo.
- **`IMPORTAPOSTES`** — Importar uma lista de postes (CSV/planilha) e gerar automaticamente as anotações correspondentes, sem interação ponto a ponto.
- **Numeração por trecho/circuito** — suporte a prefixos diferentes por trecho de rede (ex.: `A-P-001`, `B-P-001`), com detecção automática por layer, bloco ou seleção prévia de área.
- **Undo integrado em lote** — ao criar múltiplos postes em sequência (loop opcional dentro do próprio comando `POSTE`, tipo "Enter para novo poste"), permitir desfazer o último poste criado sem cancelar a sessão inteira.

## Longo prazo — demais elementos da rede

Seguindo o mesmo padrão de `POSTE` (layer própria, numeração automática, MLeader com coordenadas, funções `RVR:*` reaproveitadas):

- **`TRAFO`** — identificação de transformadores.
- **`CAIXA`** — identificação de caixas de passagem/emenda.
- **`ATERRAMENTO`** — identificação de pontos de aterramento.

## Infraestrutura do próprio código

- **Testes automatizados** — script de verificação de sintaxe/carregamento do `.LSP` (ex.: rodar `APPLOAD` silencioso em um desenho de teste via script do AutoCAD, verificando ausência de erros).
- **Arquivo de configuração externo** — mover as constantes de `*POSTE-*` para um pequeno arquivo `.LSP` ou `.INI` separado, permitindo customização por escritório sem editar o código-fonte principal.
- **Internacionalização de mensagens** — separar as strings de prompt/mensagens em uma tabela, facilitando tradução para outros idiomas caso o pacote seja usado fora do Brasil.
- **Distribuição como pacote `.BUNDLE`** — empacotar `POSTE.LSP` (e os comandos futuros) como um AutoCAD App Bundle (`.bundle`), com carregamento automático via `PackageContents.xml`, dispensando a configuração manual do `Startup Suite` em cada máquina.
