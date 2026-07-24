# Manual de Instalação — POSTE.LSP

## Requisitos

- AutoCAD 2018 ou superior (versão "comum"; não requer Civil 3D nem verticais).
- Não são necessárias bibliotecas ou dependências externas: o arquivo usa apenas AutoLISP nativo e ActiveX (`vla-*`) padrão do AutoCAD.

## Opção 1 — Carregamento manual (uso pontual, sessão atual)

1. Abra o AutoCAD e o desenho onde deseja identificar os postes.
2. Digite `APPLOAD` na linha de comando e pressione Enter.
3. Na caixa de diálogo, clique em **Load** (Carregar), navegue até o arquivo `POSTE.LSP` e selecione-o.
4. Clique em **Load** e depois em **Close**.
5. Digite `POSTE` na linha de comando para começar a usar.

> Esse carregamento vale apenas para a sessão atual do AutoCAD. Ao fechar e reabrir o programa, será necessário repetir o processo — a menos que você configure o carregamento automático (Opção 2).

## Opção 2 — Arrastar e soltar

Com o AutoCAD aberto, arraste o arquivo `POSTE.LSP` do Windows Explorer para dentro da área gráfica do AutoCAD. O arquivo será carregado automaticamente na sessão atual.

## Opção 3 — Carregamento automático a cada abertura do AutoCAD (recomendado para uso contínuo)

1. Copie `POSTE.LSP` para uma pasta fixa no computador, por exemplo:
   `C:\LISP\POSTE.LSP`
2. Digite `APPLOAD` na linha de comando.
3. Na caixa de diálogo, vá até a aba **Startup Suite**.
4. Clique em **Contents...** e depois em **Add...**.
5. Selecione o arquivo `POSTE.LSP` e confirme.
6. Feche a caixa de diálogo.

A partir de agora, o comando `POSTE` estará disponível automaticamente toda vez que o AutoCAD for aberto, em qualquer desenho.

## Opção 4 — Carregamento via arquivo `acaddoc.lsp` (padronização em escritório/equipe)

Para garantir que todos os usuários da rede/escritório tenham o comando disponível sem precisar configurar individualmente:

1. Localize (ou crie) o arquivo `acaddoc.lsp` na pasta de suporte do AutoCAD (geralmente definida em `OPTIONS` → aba **Files** → **Support File Search Path**).
2. Adicione a seguinte linha ao final do `acaddoc.lsp`:

   ```lisp
   (load "C:/LISP/POSTE.LSP")
   ```

3. Certifique-se de que todos os usuários tenham acesso ao caminho informado (idealmente uma pasta de rede compartilhada).

## Verificando a instalação

Após carregar o arquivo, a linha de comando deve exibir:

```
POSTE.LSP carregado. Digite POSTE para identificar um novo poste.
```

Se essa mensagem aparecer, o plugin está pronto para uso. Consulte o [Manual de Utilização](./MANUAL_UTILIZACAO.md) para o passo a passo do comando.

## Solução de problemas

| Problema | Causa provável | Solução |
|---|---|---|
| `Unknown command "POSTE"` | Arquivo não foi carregado nesta sessão | Repita a Opção 1 ou 2, ou configure a Opção 3/4 |
| Erro ao carregar (`; error: ...`) | Arquivo corrompido ou editado incorretamente | Baixe/copie novamente o arquivo original `POSTE.LSP` |
| MLeader não aparece com o texto esperado | Estilo de MLeader atual configurado como "Block" em vez de "Mtext" | Veja a observação na seção *Limitações conhecidas* do [Manual de Utilização](./MANUAL_UTILIZACAO.md) |
