;;; ============================================================================
;;; POSTE.LSP
;;; ----------------------------------------------------------------------------
;;; Modulo de identificacao automatica de postes para projetos de rede eletrica.
;;;
;;; Comando principal:
;;;   POSTE   -> Cria a identificacao (numeracao + anotacao com coordenadas)
;;;              de um novo poste no desenho.
;;;
;;; Compativel com AutoCAD 2018 ou superior (versao "comum", nao requer
;;; Civil 3D). Utiliza apenas AutoLISP + ActiveX (vla-*) nativos do AutoCAD.
;;;
;;; Convencao de nomes:
;;;   Todas as funcoes internas do modulo usam o prefixo "RVR:" para evitar
;;;   colisao de nomes com outras rotinas LISP carregadas no mesmo desenho.
;;;
;;; Este arquivo foi escrito para ser a base de uma familia maior de
;;; comandos de projeto (ver secao "EXPANSAO FUTURA" ao final do arquivo).
;;; ============================================================================


;; ----------------------------------------------------------------------------
;; Necessario para usar as funcoes ActiveX (vla-*, vlax-*) deste modulo.
;; Chamar (vl-load-com) e seguro mesmo se ja tiver sido carregado antes.
;; ----------------------------------------------------------------------------
(vl-load-com)


;; ============================================================================
;; SECAO 1 - CONFIGURACOES GLOBAIS
;; ----------------------------------------------------------------------------
;; Constantes de configuracao do modulo. Concentradas aqui para facilitar
;; ajustes futuros sem precisar alterar a logica das funcoes.
;; ============================================================================

;; Nome da layer onde todos os objetos de poste sao criados.
(setq *POSTE-LAYER-NAME* "POSTES")

;; Cor da layer POSTES (indice de cor ACI). 4 = Ciano.
(setq *POSTE-LAYER-COLOR* 4)

;; Altura do texto da anotacao (unidades de desenho). Ajuste aqui conforme
;; a escala/padrao do projeto.
(setq *POSTE-TEXT-HEIGHT* 2.5)

;; Prefixo utilizado na identificacao de cada poste (ex.: "P-001").
(setq *POSTE-PREFIX* "P-")

;; Quantidade minima de digitos do numero sequencial (com zeros a esquerda).
;; Se a contagem ultrapassar esse numero de digitos, a numeracao cresce
;; naturalmente (ex.: P-999 -> P-1000) sem truncar o valor.
(setq *POSTE-NUM-DIGITS* 3)

;; Quantidade de casas decimais exibidas nas coordenadas X/Y da anotacao.
(setq *POSTE-COORD-DECIMALS* 4)


;; ============================================================================
;; SECAO 2 - FUNCOES AUXILIARES (UTILITARIAS)
;; ----------------------------------------------------------------------------
;; Funcoes de proposito geral, reutilizaveis por outros comandos do futuro
;; conjunto de ferramentas (RENPOSTE, TRAFO, CAIXA, ATERRAMENTO, etc.).
;; ============================================================================

;; ----------------------------------------------------------------------------
;; RVR:CreateLayer
;; Cria a layer informada caso ela ainda nao exista no desenho.
;; Nao altera a layer caso ela ja exista (preserva cor/linetype definidos
;; manualmente pelo usuario).
;;
;; Parametros:
;;   layerName   - string com o nome da layer
;;   colorIndex  - inteiro com o indice de cor ACI (1-255)
;; ----------------------------------------------------------------------------
(defun RVR:CreateLayer (layerName colorIndex / )
  (if (not (tblsearch "LAYER" layerName))
    (entmake
      (list
        '(0 . "LAYER")
        '(100 . "AcDbSymbolTableRecord")
        '(100 . "AcDbLayerTableRecord")
        (cons 2 layerName)
        '(70 . 0)
        (cons 62 colorIndex)
        '(6 . "Continuous")
      )
    )
  )
  (princ)
)

;; ----------------------------------------------------------------------------
;; RVR:GetEntityText
;; Retorna o conteudo de texto (TextString) de um objeto ActiveX, cobrindo
;; TEXT, MTEXT e MULTILEADER de forma uniforme. Retorna nil se o objeto
;; nao possuir a propriedade ou se ocorrer qualquer erro na leitura.
;;
;; Parametros:
;;   vlaObj - objeto ActiveX (obtido via vlax-ename->vla-object)
;; ----------------------------------------------------------------------------
(defun RVR:GetEntityText (vlaObj / result)
  (setq result (vl-catch-all-apply 'vla-get-TextString (list vlaObj)))
  (if (vl-catch-all-error-p result)
    nil
    result
  )
)

;; ----------------------------------------------------------------------------
;; RVR:ExtractPostNumber
;; Procura, dentro de uma string, o padrao "POSTE <prefixo><numero>"
;; (ex.: "POSTE P-001") e retorna o numero encontrado como inteiro.
;; Retorna nil se o padrao nao for encontrado.
;;
;; Parametros:
;;   text - string onde sera feita a busca
;; ----------------------------------------------------------------------------
(defun RVR:ExtractPostNumber (text / searchStr pos startPos numStr i ch)
  (setq searchStr (strcat "POSTE " *POSTE-PREFIX*))
  (setq pos (vl-string-search searchStr text))
  (if pos
    (progn
      (setq startPos (+ pos (strlen searchStr)))
      (setq numStr "")
      (setq i startPos)
      (while (and (< i (strlen text))
                  (setq ch (substr text (1+ i) 1))
                  (wcmatch ch "#")
             )
        (setq numStr (strcat numStr ch))
        (setq i (1+ i))
      )
      (if (> (strlen numStr) 0)
        (atoi numStr)
        nil
      )
    )
    nil
  )
)

;; ----------------------------------------------------------------------------
;; RVR:GetNextPostNumber
;; Varre todo o desenho (TEXT, MTEXT e MULTILEADER) procurando ocorrencias
;; do padrao "POSTE P-###", determina o maior numero ja utilizado e
;; devolve o proximo numero disponivel. Nao faz nenhuma pergunta ao usuario.
;;
;; Retorna: inteiro (1 caso nao exista nenhum poste no desenho ainda).
;; ----------------------------------------------------------------------------
(defun RVR:GetNextPostNumber ( / ss i ent obj txt num maxNum)
  (setq maxNum 0)
  (setq ss (ssget "_X" '((0 . "TEXT,MTEXT,MULTILEADER"))))
  (if ss
    (progn
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq obj (vlax-ename->vla-object ent))
        (setq txt (RVR:GetEntityText obj))
        (if txt
          (progn
            (setq num (RVR:ExtractPostNumber txt))
            (if (and num (> num maxNum))
              (setq maxNum num)
            )
          )
        )
        (setq i (1+ i))
      )
    )
  )
  (1+ maxNum)
)

;; ----------------------------------------------------------------------------
;; RVR:FormatPostId
;; Formata um numero inteiro no padrao "P-001", respeitando o prefixo e a
;; quantidade minima de digitos configurados em *POSTE-PREFIX* e
;; *POSTE-NUM-DIGITS*.
;;
;; Parametros:
;;   num - numero inteiro do poste
;; ----------------------------------------------------------------------------
(defun RVR:FormatPostId (num / numStr)
  (setq numStr (itoa num))
  (while (< (strlen numStr) *POSTE-NUM-DIGITS*)
    (setq numStr (strcat "0" numStr))
  )
  (strcat *POSTE-PREFIX* numStr)
)

;; ----------------------------------------------------------------------------
;; RVR:FormatCoordinate
;; Formata um valor numerico de coordenada com o numero fixo de casas
;; decimais definido em *POSTE-COORD-DECIMALS*, independente das
;; configuracoes de unidades (LUPREC) do desenho atual.
;;
;; Parametros:
;;   value - real (coordenada X ou Y)
;; ----------------------------------------------------------------------------
(defun RVR:FormatCoordinate (value / )
  (rtos value 2 *POSTE-COORD-DECIMALS*)
)

;; ----------------------------------------------------------------------------
;; RVR:GetPoint
;; Solicita ao usuario um ponto na tela, com mensagem customizada.
;; Se o usuario cancelar (ESC), o AutoLISP interrompe a execucao e aciona
;; o *error* handler ativo no comando que chamou esta funcao.
;;
;; Parametros:
;;   promptMsg - string com a mensagem a ser exibida (sem ": " final)
;; ----------------------------------------------------------------------------
(defun RVR:GetPoint (promptMsg / )
  (getpoint (strcat promptMsg ": "))
)

;; ----------------------------------------------------------------------------
;; RVR:BuildLeaderContent
;; Monta o texto completo (com quebras de paragrafo) que sera atribuido ao
;; MLeader: identificacao do poste seguida das coordenadas X/Y.
;;
;; Parametros:
;;   postId - string com a identificacao do poste (ex.: "P-001")
;;   x, y   - coordenadas reais do ponto central do poste
;; ----------------------------------------------------------------------------
(defun RVR:BuildLeaderContent (postId x y / line1 line3 line4)
  (setq line1 (strcat "POSTE " postId))
  (setq line3 (strcat "X: " (RVR:FormatCoordinate x)))
  (setq line4 (strcat "Y: " (RVR:FormatCoordinate y)))
  ;; "\\P" insere uma quebra de paragrafo dentro do texto do MLeader
  ;; (equivalente ao codigo de formatacao \P usado internamente pelo MTEXT).
  (strcat line1 "\\P" "\\P" line3 "\\P" line4)
)

;; ----------------------------------------------------------------------------
;; RVR:CreateLeader
;; Cria um MLeader nativo do AutoCAD ligando o ponto central do poste
;; (seta) ao ponto de anotacao (texto), e em seguida ajusta o conteudo de
;; texto final, a layer e a altura de texto via propriedades ActiveX.
;;
;; O MLeader e criado inicialmente apenas com a primeira linha do texto
;; (via linha de comando) para evitar dependencia do editor de texto
;; interativo do MLEADER; o conteudo final (com as coordenadas) e aplicado
;; depois, diretamente na propriedade TextString do objeto ja criado -
;; abordagem mais robusta entre versoes do AutoCAD.
;;
;; Parametros:
;;   arrowPt    - ponto de insercao da seta (centro do poste)
;;   landingPt  - ponto de ancoragem do texto (local da anotacao)
;;   firstLine  - texto inicial minimo usado durante a criacao
;;   fullContent- texto final completo (com quebras de paragrafo)
;;
;; Retorna: objeto ActiveX do MLeader criado, ou nil em caso de falha.
;; ----------------------------------------------------------------------------
(defun RVR:CreateLeader (arrowPt landingPt firstLine fullContent / mlEnt mlObj curStyle)
  (command "_.MLEADER" arrowPt landingPt firstLine "")
  (setq mlEnt (entlast))
  (if mlEnt
    (progn
      (setq mlObj (vlax-ename->vla-object mlEnt))
      (vl-catch-all-apply 'vla-put-TextString (list mlObj fullContent))
      (vl-catch-all-apply 'vla-put-Layer (list mlObj *POSTE-LAYER-NAME*))
      (vl-catch-all-apply 'vla-put-TextHeight (list mlObj *POSTE-TEXT-HEIGHT*))
      ;; Aplica o estilo de texto atual do desenho, se disponivel.
      (setq curStyle (getvar "TEXTSTYLE"))
      (if (and curStyle (/= curStyle ""))
        (vl-catch-all-apply 'vla-put-TextStyle (list mlObj curStyle))
      )
      mlObj
    )
    nil
  )
)

;; ----------------------------------------------------------------------------
;; RVR:RestoreEnvironment
;; Restaura as variaveis de sistema do AutoCAD alteradas durante a
;; execucao do comando. Centralizar aqui facilita adicionar novas
;; variaveis no futuro sem espalhar setvar's pelo codigo.
;;
;; Parametros:
;;   savedCmdEcho - valor original da variavel CMDECHO
;; ----------------------------------------------------------------------------
(defun RVR:RestoreEnvironment (savedCmdEcho / )
  (if savedCmdEcho
    (setvar "CMDECHO" savedCmdEcho)
  )
  (princ)
)


;; ============================================================================
;; SECAO 3 - COMANDO PRINCIPAL
;; ============================================================================

;; ----------------------------------------------------------------------------
;; C:POSTE
;; Comando principal do modulo. Identifica automaticamente o proximo
;; numero de poste disponivel, solicita dois pontos ao usuario (centro do
;; poste e local da anotacao) e cria um MLeader com a identificacao e as
;; coordenadas do poste na layer POSTES.
;; ----------------------------------------------------------------------------
(defun c:POSTE ( / oldError oldCmdEcho nextNum postId centerPt annotPt
                    coordX coordY firstLine fullContent mlObj)

  ;; Guarda o *error* handler anterior para restaura-lo ao final, evitando
  ;; que esta rotina "vaze" seu tratamento de erro para o restante da sessao.
  (setq oldError *error*)
  (defun *error* (msg)
    (setq *error* oldError)
    (if (and msg
             (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*,*EXIT*"))
        )
      (princ (strcat "\nPOSTE - Erro: " msg))
      (princ "\nComando POSTE cancelado pelo usuario.")
    )
    (RVR:RestoreEnvironment oldCmdEcho)
    (princ)
  )

  ;; --- Salva o estado atual do ambiente ---
  (setq oldCmdEcho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)

  ;; --- Garante a existencia e ativa a layer POSTES (sem perguntar nada) ---
  (RVR:CreateLayer *POSTE-LAYER-NAME* *POSTE-LAYER-COLOR*)
  (setvar "CLAYER" *POSTE-LAYER-NAME*)

  ;; --- Calcula automaticamente o proximo numero de poste ---
  (setq nextNum (RVR:GetNextPostNumber))
  (setq postId (RVR:FormatPostId nextNum))
  (princ (strcat "\nProximo poste identificado automaticamente: " postId))

  ;; --- Solicita os pontos ao usuario ---
  (setq centerPt (RVR:GetPoint (strcat "\nClique no centro do poste " postId)))
  (setq annotPt  (RVR:GetPoint "\nClique no local da anotacao"))

  ;; --- As coordenadas da anotacao vem do ponto central do poste ---
  (setq coordX (car centerPt))
  (setq coordY (cadr centerPt))

  ;; --- Monta os textos do MLeader ---
  (setq firstLine (strcat "POSTE " postId))
  (setq fullContent (RVR:BuildLeaderContent postId coordX coordY))

  ;; --- Cria a anotacao (MLeader) do poste ---
  (setq mlObj (RVR:CreateLeader centerPt annotPt firstLine fullContent))

  (if mlObj
    (princ (strcat "\nPoste " postId " criado com sucesso na layer "
                    *POSTE-LAYER-NAME* "."))
    (princ "\nFalha ao criar a anotacao do poste.")
  )

  ;; --- Restaura o ambiente e finaliza ---
  (setq *error* oldError)
  (RVR:RestoreEnvironment oldCmdEcho)
  (princ)
)


;; ============================================================================
;; SECAO 4 - EXPANSAO FUTURA
;; ----------------------------------------------------------------------------
;; Este arquivo foi estruturado para servir de base a novos comandos do
;; mesmo pacote de rede eletrica, reaproveitando as funcoes auxiliares
;; RVR:* ja existentes (RVR:CreateLayer, RVR:GetPoint, RVR:FormatCoordinate,
;; RVR:GetEntityText, etc.). Comandos planejados:
;;
;;   RENPOSTE       - renumera postes existentes em sequencia, preservando
;;                    a ordem de selecao ou uma ordem espacial definida.
;;   EXPORTAPOSTES  - exporta a lista de postes (numero, X, Y) do desenho
;;                    atual para CSV/planilha.
;;   IMPORTAPOSTES  - importa uma lista de postes de CSV/planilha e cria
;;                    automaticamente as anotacoes correspondentes.
;;   TRAFO          - identificacao de transformadores (mesmo padrao de
;;                    numeracao e anotacao usado em POSTE).
;;   CAIXA          - identificacao de caixas de passagem/emenda.
;;   ATERRAMENTO    - identificacao de pontos de aterramento.
;;
;; Cada novo comando deve seguir a mesma convencao: prefixo RVR: para
;; funcoes internas, layer propria, *error* handler com salvamento/
;; restauracao do handler anterior, e restauracao das variaveis de
;; sistema alteradas.
;; ============================================================================

(princ "\nPOSTE.LSP carregado. Digite POSTE para identificar um novo poste.")
(princ)
