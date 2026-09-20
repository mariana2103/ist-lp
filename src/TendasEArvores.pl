% 109520 Mariana Almeida
:- use_module(library(clpfd)). % para poder usar transpose/2
:- set_prolog_flag(answer_write_options,[max_depth(0)]). % ver listas completas
:- ['puzzlesAcampar.pl']. % ficheiro dado (no Mooshak tem mais puzzles)

/*
    Tendas e Arvores
    ================

    Um puzzle e um triplo (Tabuleiro, TendasPorLinha, TendasPorColuna):

      - Tabuleiro: lista de listas (uma por linha) com os objectos
                   a (arvore), t (tenda), r (relva) ou uma variavel
                   livre (celula ainda por preencher);
      - TendasPorLinha / TendasPorColuna: numero exacto de tendas que
                   cada linha / coluna deve ter no fim.

    As coordenadas (L, C) comecam em (1, 1), no canto superior esquerdo.
    O tabuleiro e sempre alterado "in place", por unificacao das variaveis.

    Indice
      1. Consultas .................. vizinhanca, vizinhancaAlargada,
                                      todasCelulas/2,3,
                                      calculaObjectosTabuleiro, celulaVazia
      2. Insercao ................... insereObjectoCelula,
                                      insereObjectoEntrePosicoes
      3. Estrategias ................ relva, inacessiveis, aproveita,
                                      limpaVizinhancas, unicaHipotese
      4. Tentativa e erro ........... valida, resolve
*/


%-----------------------------------------------------------------------
% 1. Consultas
%-----------------------------------------------------------------------

/*  vizinhanca((L, C), Vizinhanca)
    Vizinhanca e a lista ordenada (de cima para baixo e da esquerda para
    a direita) das posicoes imediatamente acima, a esquerda, a direita e
    abaixo de (L, C). Nao se retiram as posicoes fora do tabuleiro. */

vizinhanca((L, C), [(Acima, C), (L, Esq), (L, Dir), (Abaixo, C)]) :-
    Acima  is L - 1,
    Abaixo is L + 1,
    Esq    is C - 1,
    Dir    is C + 1.


/*  vizinhancaAlargada((L, C), Vizinhanca)
    Como vizinhanca/2, mas inclui tambem as quatro diagonais. */

vizinhancaAlargada((L, C), Vizinhanca) :-
    L1 is L - 1, L2 is L + 1,
    C1 is C - 1, C2 is C + 1,
    findall((X, Y),
            ( between(L1, L2, X),
              between(C1, C2, Y),
              \+ ( X == L, Y == C ) ),
            Vizinhanca).


/*  todasCelulas(Tabuleiro, TodasCelulas)
    TodasCelulas e a lista ordenada, sem repeticoes, de todas as
    coordenadas do tabuleiro. */

todasCelulas(Tabuleiro, TodasCelulas) :-
    findall((L, C),
            ( nth1(L, Tabuleiro, Linha),
              nth1(C, Linha, _) ),
            TodasCelulas).


/*  todasCelulas(Tabuleiro, TodasCelulas, Objecto)
    TodasCelulas e a lista ordenada das coordenadas cujo conteudo e
    Objecto. Se Objecto for uma variavel livre, devolve as celulas ainda
    por preencher. */

todasCelulas(Tabuleiro, TodasCelulas, Objecto) :-
    findall((L, C),
            ( nth1(L, Tabuleiro, Linha),
              nth1(C, Linha, Elemento),
              mesmoObjecto(Objecto, Elemento) ),
            TodasCelulas).


% mesmoObjecto(Procurado, Elemento): Elemento e do tipo Procurado.
% Uma variavel livre so corresponde a outra variavel livre.

mesmoObjecto(Procurado, Elemento) :-
    (   var(Procurado)
    ->  var(Elemento)
    ;   Elemento == Procurado ).


/*  calculaObjectosTabuleiro(Tabuleiro, ContagemLinhas, ContagemColunas,
                             Objecto)
    Contagem do numero de celulas do tipo Objecto por linha e por coluna. */

calculaObjectosTabuleiro(Tabuleiro, ContagemLinhas, ContagemColunas,
                         Objecto) :-
    contaPorLinha(Tabuleiro, Objecto, ContagemLinhas),
    transposta(Tabuleiro, Transposto),
    contaPorLinha(Transposto, Objecto, ContagemColunas).

% transposta(Tabuleiro, Transposto): transpose/2 sem pontos de escolha.
% Como a transposta partilha as variaveis do tabuleiro, inserir objectos
% nela e o mesmo que inserir nas colunas do tabuleiro original.

transposta(Tabuleiro, Transposto) :-
    transpose(Tabuleiro, Transposto),
    !.

contaPorLinha(Tabuleiro, Objecto, Contagens) :-
    maplist(contaObjectos(Objecto), Tabuleiro, Contagens).

contaObjectos(Objecto, Linha, Total) :-
    include(mesmoObjecto(Objecto), Linha, Encontrados),
    length(Encontrados, Total).


/*  celulaVazia(Tabuleiro, (L, C))
    Verdade se a celula esta livre ou tem relva. Coordenadas fora do
    tabuleiro nao fazem o predicado falhar. */

celulaVazia(Tabuleiro, Coordenada) :-
    (   objectoDaCelula(Tabuleiro, Coordenada, Objecto)
    ->  livreOuRelva(Objecto)
    ;   true ).

livreOuRelva(Objecto) :- var(Objecto), !.
livreOuRelva(r).


% objectoDaCelula(Tabuleiro, (L, C), Objecto): falha se (L, C) estiver
% fora do tabuleiro.

objectoDaCelula(Tabuleiro, (L, C), Objecto) :-
    integer(L), integer(C), L >= 1, C >= 1,
    nth1(L, Tabuleiro, Linha),
    nth1(C, Linha, Objecto).


%-----------------------------------------------------------------------
% 2. Insercao de tendas e relva
%-----------------------------------------------------------------------

/*  insereObjectoCelula(Tabuleiro, TendaOuRelva, (L, C))
    Coloca o objecto em (L, C) se a celula estiver livre. Se estiver
    ocupada (ou fora do tabuleiro) deixa-a como esta. */

insereObjectoCelula(Tabuleiro, TendaOuRelva, Coordenada) :-
    (   objectoDaCelula(Tabuleiro, Coordenada, Objecto),
        var(Objecto)
    ->  Objecto = TendaOuRelva
    ;   true ).


/*  insereObjectoEntrePosicoes(Tabuleiro, TendaOuRelva, (L, C1), (L, C2))
    Coloca o objecto em todas as celulas livres da linha L entre as
    colunas C1 e C2 (inclusive). */

insereObjectoEntrePosicoes(Tabuleiro, TendaOuRelva, (L, C1), (L, C2)) :-
    findall((L, C), between(C1, C2, C), Posicoes),
    maplist(insereObjectoCelula(Tabuleiro, TendaOuRelva), Posicoes).


% preencheLinha(Tabuleiro, Objecto, N): preenche a linha N inteira.

preencheLinha(Tabuleiro, Objecto, N) :-
    nth1(N, Tabuleiro, Linha),
    length(Linha, Largura),
    insereObjectoEntrePosicoes(Tabuleiro, Objecto, (N, 1), (N, Largura)).


% preencheLinhasQue(Condicao, Tabuleiro, Objecto, Alvos, Contagens):
% percorre as linhas do tabuleiro (por ordem) e preenche com Objecto
% aquelas para as quais Condicao(Alvo, Contagem) e verdade. Para
% actuar sobre colunas passa-se o tabuleiro transposto.

preencheLinhasQue(Condicao, Tabuleiro, Objecto, Alvos, Contagens) :-
    preencheLinhasQue(Condicao, Tabuleiro, Objecto, Alvos, Contagens, 1).

preencheLinhasQue(_, _, _, [], [], _) :- !.
preencheLinhasQue(Condicao, Tabuleiro, Objecto, [Alvo|Alvos],
                  [Contagem|Contagens], N) :-
    (   call(Condicao, Alvo, Contagem)
    ->  preencheLinha(Tabuleiro, Objecto, N)
    ;   true ),
    Proxima is N + 1,
    preencheLinhasQue(Condicao, Tabuleiro, Objecto, Alvos, Contagens,
                      Proxima).


%-----------------------------------------------------------------------
% 3. Estrategias
%-----------------------------------------------------------------------

/*  relva(Puzzle)
    Enche de relva as linhas e colunas que ja tem todas as tendas. */

relva((Tabuleiro, Linhas, Colunas)) :-
    calculaObjectosTabuleiro(Tabuleiro, TendasLinhas, TendasColunas, t),
    transposta(Tabuleiro, Transposto),
    preencheLinhasQue(=:=, Tabuleiro, r, Linhas, TendasLinhas),
    preencheLinhasQue(=:=, Transposto, r, Colunas, TendasColunas).


/*  inacessiveis(Tabuleiro)
    Poe relva nas celulas que nao estao na vizinhanca de nenhuma arvore
    (portanto nunca podem ter tenda). */

inacessiveis(Tabuleiro) :-
    todasCelulas(Tabuleiro, Todas),
    todasCelulas(Tabuleiro, Arvores, a),
    findall(Vizinha,
            ( member(Arvore, Arvores),
              vizinhanca(Arvore, Vizinhas),
              member(Vizinha, Vizinhas) ),
            ComRepeticoes),
    sort(ComRepeticoes, Acessiveis),
    ord_subtract(Todas, Acessiveis, Inacessiveis),
    maplist(insereObjectoCelula(Tabuleiro, r), Inacessiveis).


/*  aproveita(Puzzle)
    Se a uma linha (ou coluna) faltam N tendas e ela tem exactamente N
    celulas livres, essas celulas so podem ser tendas. Resolve primeiro as
    linhas, volta a contar e resolve depois as colunas. */

aproveita((Tabuleiro, Linhas, Colunas)) :-
    aproveitaLinhas(Tabuleiro, Linhas),
    transposta(Tabuleiro, Transposto),
    aproveitaLinhas(Transposto, Colunas).

aproveitaLinhas(Tabuleiro, Alvos) :-
    contaPorLinha(Tabuleiro, t, Tendas),
    contaPorLinha(Tabuleiro, _, Livres),
    maplist(tendasEmFalta, Alvos, Tendas, EmFalta),
    preencheLinhasQue(=:=, Tabuleiro, t, EmFalta, Livres).

% tendasEmFalta(Alvo, Colocadas, EmFalta)

tendasEmFalta(Alvo, Colocadas, EmFalta) :-
    EmFalta is Alvo - Colocadas.


/*  limpaVizinhancas(Puzzle)
    Poe relva em torno de cada tenda (incluindo diagonais), porque duas
    tendas nunca se podem tocar. */

limpaVizinhancas((Tabuleiro, _, _)) :-
    todasCelulas(Tabuleiro, Tendas, t),
    maplist(limpaTenda(Tabuleiro), Tendas).

limpaTenda(Tabuleiro, Tenda) :-
    vizinhancaAlargada(Tenda, Vizinhas),
    maplist(insereObjectoCelula(Tabuleiro, r), Vizinhas).


/*  unicaHipotese(Puzzle)
    Se uma arvore ainda nao tem tenda e so tem uma celula livre na sua
    vizinhanca, a tenda tem de ficar nessa celula. */

unicaHipotese((Tabuleiro, _, _)) :-
    todasCelulas(Tabuleiro, Arvores, a),
    maplist(colocaTendaUnica(Tabuleiro), Arvores).

colocaTendaUnica(Tabuleiro, Arvore) :-
    vizinhanca(Arvore, Vizinhas),
    include(temObjecto(Tabuleiro, t), Vizinhas, ComTenda),
    include(estaLivre(Tabuleiro), Vizinhas, Livres),
    (   ComTenda == [], Livres = [Unica]
    ->  insereObjectoCelula(Tabuleiro, t, Unica)
    ;   true ).

temObjecto(Tabuleiro, Objecto, Coordenada) :-
    objectoDaCelula(Tabuleiro, Coordenada, Elemento),
    Elemento == Objecto.

estaLivre(Tabuleiro, Coordenada) :-
    objectoDaCelula(Tabuleiro, Coordenada, Elemento),
    var(Elemento).


%-----------------------------------------------------------------------
% 4. Tentativa e erro
%-----------------------------------------------------------------------

/*  valida(LArv, LTen)
    Verdade se nenhuma tenda esta em cima de uma arvore e e possivel dar
    a cada arvore uma tenda so sua, na sua vizinhanca. */

valida(Arvores, Tendas) :-
    length(Arvores, N),
    length(Tendas, N),
    semTendasSobreArvores(Arvores, Tendas),
    emparelha(Arvores, Tendas),
    !.

semTendasSobreArvores(Arvores, Tendas) :-
    \+ ( member(Tenda, Tendas),
         memberchk(Tenda, Arvores) ).

% emparelha(Arvores, Tendas): a cada arvore corresponde uma tenda distinta
% da sua vizinhanca (relacao bijectiva; explora alternativas por
% retrocesso).

emparelha([], []).
emparelha([Arvore|Arvores], Tendas) :-
    vizinhanca(Arvore, Vizinhas),
    member(Tenda, Vizinhas),
    select(Tenda, Tendas, Restantes),
    emparelha(Arvores, Restantes).


/*  resolve(Puzzle)
    Resolve o puzzle: aplica as estrategias ate ja nao haver progresso;
    se ainda houver celulas livres, tenta uma tenda ou relva na primeira
    delas e continua (retrocedendo se chegar a uma contradicao). */

resolve(Puzzle) :-
    resolveAte(Puzzle),
    !.

resolveAte(Puzzle) :-
    Puzzle = (Tabuleiro, _, _),
    propaga(Puzzle),
    todasCelulas(Tabuleiro, Livres, _),
    (   Livres == []
    ->  solucao(Puzzle)
    ;   Livres = [Celula|_],
        tenta(Tabuleiro, Celula),
        resolveAte(Puzzle) ).

% propaga(Puzzle): repete as estrategias enquanto forem preenchendo
% celulas. Falha se o tabuleiro ficar impossivel.

propaga(Puzzle) :-
    Puzzle = (Tabuleiro, _, _),
    todasCelulas(Tabuleiro, Antes, _),
    aplicaEstrategias(Puzzle),
    consistente(Puzzle),
    todasCelulas(Tabuleiro, Depois, _),
    (   Antes == Depois
    ->  true
    ;   propaga(Puzzle) ).

aplicaEstrategias(Puzzle) :-
    Puzzle = (Tabuleiro, _, _),
    relva(Puzzle),
    inacessiveis(Tabuleiro),
    limpaVizinhancas(Puzzle),
    aproveita(Puzzle),
    unicaHipotese(Puzzle).

% tenta(Tabuleiro, (L, C)): primeiro uma tenda; se nao der, relva.

tenta(Tabuleiro, Coordenada) :-
    objectoDaCelula(Tabuleiro, Coordenada, Objecto),
    (   Objecto = t
    ;   Objecto = r ).

% consistente(Puzzle): nenhuma linha/coluna tem tendas a mais nem
% celulas livres a menos para alcancar o numero pedido.

consistente((Tabuleiro, Linhas, Colunas)) :-
    calculaObjectosTabuleiro(Tabuleiro, TendasL, TendasC, t),
    calculaObjectosTabuleiro(Tabuleiro, LivresL, LivresC, _),
    maplist(cabe, Linhas, TendasL, LivresL),
    maplist(cabe, Colunas, TendasC, LivresC).

cabe(Alvo, Tendas, Livres) :-
    Tendas =< Alvo,
    Alvo =< Tendas + Livres.

% solucao(Puzzle): tabuleiro completo com as contagens pedidas e uma
% tenda para cada arvore.

solucao((Tabuleiro, Linhas, Colunas)) :-
    calculaObjectosTabuleiro(Tabuleiro, TendasL, TendasC, t),
    TendasL == Linhas,
    TendasC == Colunas,
    todasCelulas(Tabuleiro, Arvores, a),
    todasCelulas(Tabuleiro, Tendas, t),
    valida(Arvores, Tendas).
