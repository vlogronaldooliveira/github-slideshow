# Documentação das Funções — POSTE.LSP

Este documento detalha cada função definida em `POSTE.LSP`, sua finalidade, parâmetros e valor de retorno.

## Convenções

- Todas as funções auxiliares usam o prefixo `RVR:` para evitar colisão de nomes com outras rotinas LISP carregadas no mesmo desenho.
- Variáveis locais são sempre declaradas na lista de parâmetros da função (após `/`), evitando o vazamento de variáveis globais desnecessárias.
- Funções que interagem com o modelo de objetos ActiveX do AutoCAD (`vla-*`) são protegidas com `vl-catch-all-apply`, evitando que uma falha pontual (ex.: propriedade não suportada em uma versão específica) interrompa o comando inteiro.

---

## Funções auxiliares

### `RVR:CreateLayer (layerName colorIndex)`

Cria a layer informada via `entmake` (inserção direta na tabela de layers do desenho) caso ela ainda não exista. Se a layer já existir, a função não faz nada — preservando eventuais customizações de cor/linetype feitas manualmente pelo usuário.

- **Parâmetros:** `layerName` (string), `colorIndex` (inteiro, índice de cor ACI).
- **Retorno:** nenhum (efeito colateral: cria a layer no desenho).

### `RVR:GetEntityText (vlaObj)`

Lê a propriedade `TextString` de um objeto ActiveX, funcionando de forma uniforme para `TEXT`, `MTEXT` e `MULTILEADER` (todas essas entidades expõem essa propriedade). Protegida com `vl-catch-all-apply` para nunca lançar erro.

- **Parâmetros:** `vlaObj` (objeto ActiveX).
- **Retorno:** string com o texto, ou `nil` se a leitura falhar.

### `RVR:ExtractPostNumber (text)`

Procura, dentro de uma string qualquer, a primeira ocorrência do padrão `POSTE P-` (prefixo configurável) seguido de dígitos, e retorna o número encontrado como inteiro.

- **Parâmetros:** `text` (string a ser analisada).
- **Retorno:** inteiro com o número do poste, ou `nil` se o padrão não for encontrado no texto.
- **Observação:** a busca é feita por correspondência literal de substring (`vl-string-search`), o que é seguro mesmo quando o texto contém códigos de formatação do MTEXT (como `\P`) em outras partes da string.

### `RVR:GetNextPostNumber ()`

Varre **todas** as entidades `TEXT`, `MTEXT` e `MULTILEADER` do desenho atual (via `ssget "_X"`), extrai o número de poste de cada uma (usando `RVR:ExtractPostNumber`) e determina o maior valor encontrado.

- **Parâmetros:** nenhum.
- **Retorno:** inteiro — o maior número encontrado + 1 (ou `1` se nenhum poste existir ainda no desenho).

### `RVR:FormatPostId (num)`

Formata um número inteiro no padrão de identificação do poste (ex.: `P-001`), aplicando zeros à esquerda conforme `*POSTE-NUM-DIGITS*`.

- **Parâmetros:** `num` (inteiro).
- **Retorno:** string formatada (ex.: `"P-001"`). Números que excedem a quantidade configurada de dígitos crescem naturalmente (ex.: `P-1000`) sem truncamento.

### `RVR:FormatCoordinate (value)`

Formata um valor numérico (coordenada X ou Y) como string decimal com exatamente `*POSTE-COORD-DECIMALS*` casas decimais, usando `rtos` em modo decimal explícito — independente da precisão de unidades configurada no desenho (`LUPREC`).

- **Parâmetros:** `value` (real).
- **Retorno:** string (ex.: `"777381.0708"`).

### `RVR:GetPoint (promptMsg)`

Encapsula `getpoint`, padronizando a mensagem exibida ao usuário. Caso o usuário pressione ESC, o próprio AutoLISP interrompe a execução e aciona o `*error*` handler ativo no comando chamador — não é necessário tratamento adicional de cancelamento dentro desta função.

- **Parâmetros:** `promptMsg` (string, sem `": "` no final — adicionado automaticamente).
- **Retorno:** ponto (lista de reais) clicado pelo usuário.

### `RVR:BuildLeaderContent (postId x y)`

Monta a string completa de conteúdo do MLeader, com a identificação do poste seguida das coordenadas X e Y, separadas por quebras de parágrafo (`\P`, código de formatação de texto multilinha do AutoCAD).

- **Parâmetros:** `postId` (string), `x` e `y` (reais).
- **Retorno:** string pronta para ser atribuída à propriedade `TextString` de um MTEXT/MLEADER.

### `RVR:CreateLeader (arrowPt landingPt firstLine fullContent)`

Cria o MLeader nativo do AutoCAD ligando `arrowPt` (centro do poste) a `landingPt` (local da anotação). Por robustez entre versões do AutoCAD, o MLeader é criado inicialmente apenas com `firstLine` (evitando depender do editor de texto interativo do comando `MLEADER` para múltiplas linhas) e, em seguida, o conteúdo final (`fullContent`), a layer e a altura de texto são aplicados diretamente via propriedades ActiveX do objeto já criado.

- **Parâmetros:** `arrowPt` e `landingPt` (pontos), `firstLine` (string curta usada na criação), `fullContent` (string completa final).
- **Retorno:** objeto ActiveX do MLeader criado, ou `nil` em caso de falha na criação da geometria.

### `RVR:RestoreEnvironment (savedCmdEcho)`

Restaura as variáveis de sistema do AutoCAD alteradas durante a execução do comando (atualmente, `CMDECHO`). Centralizar essa lógica em uma única função facilita adicionar outras variáveis no futuro sem espalhar chamadas `setvar` pelo código.

- **Parâmetros:** `savedCmdEcho` (valor original de `CMDECHO`).
- **Retorno:** nenhum (efeito colateral: `setvar`).

---

## Comando principal

### `C:POSTE ()`

Função de comando (`C:` torna a função invocável diretamente pelo nome `POSTE` na linha de comando). Orquestra todas as funções auxiliares acima na seguinte ordem:

1. Salva o `*error*` handler anterior e define um handler próprio, que trata cancelamento (ESC) de forma amigável e sempre restaura o ambiente antes de encerrar.
2. Salva `CMDECHO` e desativa o eco de comandos (`CMDECHO = 0`) para uma execução limpa.
3. Garante a existência da layer `POSTES` (`RVR:CreateLayer`) e a torna atual (`CLAYER`).
4. Calcula o próximo número de poste (`RVR:GetNextPostNumber` + `RVR:FormatPostId`).
5. Solicita o ponto do centro do poste e o ponto da anotação (`RVR:GetPoint`).
6. Monta o conteúdo do MLeader (`RVR:BuildLeaderContent`) a partir das coordenadas do centro do poste.
7. Cria o MLeader (`RVR:CreateLeader`).
8. Restaura o `*error*` handler anterior e as variáveis de sistema (`RVR:RestoreEnvironment`), e informa o resultado ao usuário.

**Por que salvar/restaurar o `*error*` handler?** Em AutoLISP, `(defun *error* ...)` redefine a função **globalmente** — não existe escopo local para `defun`. Se o handler anterior não for salvo e restaurado, o comportamento de tratamento de erro definido por `POSTE` passaria a valer também para outros comandos/rotinas carregadas na mesma sessão, o que é indesejado. Salvar `oldError` antes e restaurá-lo ao final (tanto no fluxo normal quanto dentro do próprio `*error*`) evita esse efeito colateral.
