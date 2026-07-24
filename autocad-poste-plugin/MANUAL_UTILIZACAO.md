# Manual de Utilização — Comando POSTE

## Visão geral

O comando `POSTE` identifica um poste no desenho de forma padronizada: cria (se necessário) a layer `POSTES`, calcula automaticamente o próximo número sequencial disponível e cria uma anotação (MLeader) com a identificação do poste e suas coordenadas.

## Passo a passo

1. Na linha de comando do AutoCAD, digite:

   ```
   POSTE
   ```

2. O programa executa automaticamente, **sem perguntar nada**:
   - Verifica se a layer `POSTES` existe; se não existir, cria.
   - Torna `POSTES` a layer atual.
   - Varre o desenho inteiro em busca de textos/MLeaders no padrão `POSTE P-###` e calcula o próximo número disponível (ex.: se o maior já existente é `P-007`, o próximo será `P-008`).

3. O AutoCAD solicita o primeiro ponto:

   ```
   Clique no centro do poste P-008:
   ```

   Clique no ponto exato que representa o centro do poste no desenho (por exemplo, o centro do símbolo/bloco do poste).

4. Em seguida, o AutoCAD solicita o segundo ponto:

   ```
   Clique no local da anotacao:
   ```

   Clique no local onde o texto da identificação deve ficar (a "ponta de chamada" do leader é desenhada automaticamente do centro do poste até esse ponto).

5. O plugin cria um **MLeader nativo** do AutoCAD, ligado ao ponto do centro do poste, com o seguinte conteúdo:

   ```
   POSTE P-008

   X: 777381.0708
   Y: 8257038.7800
   ```

   - As coordenadas **X** e **Y** são as coordenadas reais do ponto clicado como centro do poste (não do ponto de anotação), sempre formatadas com **exatamente 4 casas decimais**.
   - Não há qualquer conversão para latitude/longitude — as coordenadas são exibidas exatamente no sistema de coordenadas do desenho (ex.: UTM/SIRGAS, conforme o projeto).
   - O texto usa o **estilo de texto atual do desenho** (variável `TEXTSTYLE`) e altura de **2.5** unidades (configurável no código — veja abaixo).
   - Todos os objetos criados ficam na layer **POSTES**.

6. Ao final, a linha de comando confirma:

   ```
   Poste P-008 criado com sucesso na layer POSTES.
   ```

## Numeração automática — como funciona

Toda vez que `POSTE` é executado, ele varre **todo o desenho** (textos simples, textos multilinha e MLeaders) procurando pelo padrão:

```
POSTE P-###
```

O maior número encontrado define a numeração seguinte. Isso significa que:

- Não é necessário numerar manualmente.
- Não importa a ordem em que os postes foram criados ou se algum poste foi apagado no meio da sequência — o próximo número é sempre "maior número existente + 1".
- Se **nenhum** poste existir ainda no desenho, o primeiro criado será `P-001`.

## Cancelando o comando

Pressione **ESC** a qualquer momento durante a solicitação dos pontos para cancelar. O comando exibe `Comando POSTE cancelado pelo usuario.` e nenhuma alteração é deixada pendente (a layer `POSTES`, se tiver sido criada nessa execução, permanece no desenho — isso é esperado e não causa problema caso o comando seja executado novamente).

## Personalizando o comportamento

Os parâmetros mais comuns de ajuste ficam concentrados no topo do arquivo `POSTE.LSP`, na seção **SEÇÃO 1 - CONFIGURAÇÕES GLOBAIS**:

| Variável | Padrão | O que controla |
|---|---|---|
| `*POSTE-LAYER-NAME*` | `"POSTES"` | Nome da layer usada |
| `*POSTE-LAYER-COLOR*` | `4` (ciano) | Cor ACI da layer, se criada pelo plugin |
| `*POSTE-TEXT-HEIGHT*` | `2.5` | Altura do texto da anotação |
| `*POSTE-PREFIX*` | `"P-"` | Prefixo da numeração |
| `*POSTE-NUM-DIGITS*` | `3` | Quantidade mínima de dígitos (zeros à esquerda) |
| `*POSTE-COORD-DECIMALS*` | `4` | Casas decimais exibidas nas coordenadas |

Basta editar o valor desejado e recarregar o arquivo (`APPLOAD`).

## Limitações conhecidas

- **Estilo de MLeader (`MLEADERSTYLE`) do tipo "Block"**: o comando `POSTE` assume que o estilo de MLeader atual do desenho utiliza conteúdo de texto (Mtext) — que é o padrão da maioria dos templates. Se o estilo de MLeader atual estiver configurado para inserir um **bloco** em vez de texto, a criação do leader pode não se comportar como esperado. Nesse caso, troque o `MLEADERSTYLE` atual para um estilo baseado em Mtext antes de rodar `POSTE` (veja também as sugestões em [MELHORIAS_FUTURAS.md](./MELHORIAS_FUTURAS.md)).
- A detecção de numeração é sensível ao padrão exato `POSTE P-###` (mesmo formato gerado pelo próprio plugin). Postes identificados manualmente com um texto diferente não serão considerados no cálculo do próximo número.
