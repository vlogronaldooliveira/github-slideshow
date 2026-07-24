# Plugin POSTE — Identificação Automática de Postes (AutoLISP / AutoCAD)

Rotina AutoLISP para automatizar a identificação de postes em projetos de rede elétrica no AutoCAD (versão comum, não requer Civil 3D). Compatível com AutoCAD 2018 ou superior.

## Conteúdo deste pacote

| Arquivo | Descrição |
|---|---|
| [`POSTE.LSP`](./POSTE.LSP) | Código-fonte do plugin |
| [`MANUAL_INSTALACAO.md`](./MANUAL_INSTALACAO.md) | Como carregar o plugin no AutoCAD |
| [`MANUAL_UTILIZACAO.md`](./MANUAL_UTILIZACAO.md) | Como usar o comando `POSTE` no dia a dia |
| [`DOCUMENTACAO_FUNCOES.md`](./DOCUMENTACAO_FUNCOES.md) | Explicação de cada função do código |
| [`MELHORIAS_FUTURAS.md`](./MELHORIAS_FUTURAS.md) | Roadmap e sugestões de evolução do módulo |

## Resumo rápido

1. Carregue `POSTE.LSP` no AutoCAD (`APPLOAD` ou `NETLOAD`/arraste o arquivo).
2. Digite `POSTE` na linha de comando.
3. Clique no centro do poste e depois no local da anotação.
4. O plugin cria automaticamente a layer `POSTES` (se necessário), numera o poste (`P-001`, `P-002`, ...) e insere um MLeader com a identificação e as coordenadas X/Y do ponto clicado, com 4 casas decimais.

Veja os manuais para detalhes completos.
