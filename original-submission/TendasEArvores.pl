
%  109520 Mariana Almeida
:- use_module(library(clpfd)).
:- set_prolog_flag(answer_write_options,[max_depth(0)]).
:- ['puzzlesAcampar.pl'].

/*  O predicado vizinhanca((L, C), Vizinhanca) devolve uma lista com as
 coordenadas dos elementos do tabuleiro que se encontrem nos lados,
em cima e em baixo do elemento de coordenadas (L,C). */


vizinhanca((L, C), Vizinhanca) :-
    L1 is L-1,
    L2 is L+1,
    C1 is C-1,
    C2 is C+1,
    setof((L3,C3),
        (between(L1,L2,L3),
        between(C1,C2,C3),
        (abs(L-L3)+abs(C-C3))=:=1),
        Vizinhanca).


/* O predicado vizinhancaAlargada((L, C), VizinhancaAlargada) devolve uma
lista com as coordenadas dos elementos do tabuleiro que se encontrem nos lados,
em cima, em baixo e nas diagonais do elemento de coordenadas (L,C). */

vizinhancaAlargada((L, C), Vizinhanca) :-
    L1 is L-1,
    L2 is L+1,
    C1 is C-1,
    C2 is C+1,
    setof((L3,C3),
        (between(L1,L2,L3),
        between(C1,C2,C3),
        (abs(L-L3)=:=1;abs(C-C3)=:=1)),
        Vizinhanca).

/* O predicado TodasCelulas(Tabuleiro, TodasCelulas) devolve uma lista
ordenada e sem elementos repetidos de todas as coordenadas do tabuleiro. */

todasCelulas(Tabuleiro, TodasCelulas) :-
    nth1(1, Tabuleiro, Linha1),
    length(Linha1, Tamanho),
    setof((X,Y),(between(1,Tamanho,X),between(1,Tamanho,Y)),TodasCelulas).

/* O predicado TodasCelulas(Tabuleiro, TodasCelulas, Objecto) devolve uma lista
ordenada e sem elementos repetidos de todas as coordenadas do tabuleiro que
correspondam a elementos com um objeto dado. */

% elementodacelula e um predicado auxiliar que permite aceder ao Objecto da 
% celula (L,C).

elementodacelula(Tabuleiro, (L, C), Objecto):-
    nth1(L,Tabuleiro,Linha),
    nth1(C,Linha,Objecto).

todasCelulas(Tabuleiro, TodasCelulas, Objecto):-
    var(Objecto),!,
    findall((L,C),
    (elementodacelula(Tabuleiro,(L,C),Elemento),
    var(Elemento)),
    TodasCelulas).

todasCelulas(Tabuleiro, TodasCelulas, Objecto):-
    setof((L,C),
    (elementodacelula(Tabuleiro,(L,C),Elemento),
    Elemento == Objecto),
    TodasCelulas),!.

todasCelulas(_, [], _).

/* O predicado calculaObjectosTabuleiro(Tabuleiro, ContagemLinhas,
ContagemColunas, Objecto) devolve as listas ContagemLinhas e ContagemColunas
que contem o numero que um determinado objeto dado aparece em cada linha e
coluna, respetivamente.*/

mesmaprimeiracoordenada(L1,(L,_)):-
    L==L1.

calculaObjectosTabuleiro(Tabuleiro, ContagemLinhas, ContagemColunas, Objecto):-
    length(Tabuleiro, Tamanho),
	todasCelulas(Tabuleiro, TodasCelulas, Objecto),!,
    % findall ira contar a quantidade de objetos que estao em cada linha.
    findall(Linha,
        (between(1,Tamanho,L),
        include(mesmaprimeiracoordenada(L),
        TodasCelulas,
        Porlinha),
        length(Porlinha,Linha)),
        ContagemLinhas),
    transpose(Tabuleiro,TabuleiroNovo),
    todasCelulas(TabuleiroNovo, TodasCelulasTranspostas, Objecto),
    %findall ira contar a quantidade de objetos que estao em cada linha do 
    %tabuleiro transposto, corresponendo as colunas do tabuleiro regular.
    findall(Coluna,
        (between(1,Tamanho,L),
        include(mesmaprimeiracoordenada(L),
        TodasCelulasTranspostas,PorColuna),
        length(PorColuna,Coluna)),
        ContagemColunas).

/* O predicado celulaVazia(Tabuleiro, (L, C)) gere o resultado "true." quando
o elemento do tabuleiro com coordenadas (L, C) e um espaco vazio ou esta
ocupado por relva. */

celulaVazia(Tabuleiro, (L, C)) :-
    length(Tabuleiro,Tamanho),
    between(1, Tamanho,L),
    between(1, Tamanho,C),
    elementodacelula(Tabuleiro,(L, C),Elemento),
    var(Elemento),!.

celulaVazia(Tabuleiro, (L, C)) :-
    length(Tabuleiro,Tamanho),
    between(1, Tamanho,L),
    between(1, Tamanho,C),
    elementodacelula(Tabuleiro,(L, C),Elemento),
    Elemento == r.

/* O predicado insereObjectoCelula(Tabuleiro, TendaOuRelva, (L, C)) coloca um
objeto dado no elemento do tabuleiro com coordenadas (L, C). */

insereObjectoCelula(Tabuleiro, TendaOuRelva, (L, C)) :-
    elementodacelula(Tabuleiro,(L, C), Objecto),
    var(Objecto),
    Objecto = TendaOuRelva.

insereObjectoCelula(_, _, _).

/* O predicado insereObjectoEntrePosicoes(Tabuleiro, TendaOuRelva, (L, C1),
(L, C2)) coloca um objeto dado nos elementos do tabuleiro que tenham
coordenadas (L,C), sendo C um qualquer valor entre C1 e C2. */

insereObjectoEntrePosicoes(Tabuleiro, TendaOuRelva, (L, C1), (L, C2)):-
    findall((L,Y),between(C1,C2,Y),Posicoes),
    inserir(Posicoes,TendaOuRelva,Tabuleiro).

inserir([],_,_) :- !.
inserir([P|Resto],TendaOuRelva,Tabuleiro):-
    % insere recursivamente TendaOuRelva em todos os elementos da lista.
    insereObjectoCelula(Tabuleiro, TendaOuRelva, P),
    inserir(Resto,TendaOuRelva,Tabuleiro).

/* O predicado relva(Puzzle) coloca relva "r" nos elementos do tabuleiro
que estejam em linhas ou colunas que tenham o numero de tendas requisitado. */

relva_aux(_,[],_):-!.
relva_aux(Tabuleiro,[L|Resto],Tamanho):-
    % insere relva em todas as linhas recebidas como parametro.
    insereObjectoEntrePosicoes(Tabuleiro, r, (L, 1), (L, Tamanho)),
    relva_aux(Tabuleiro,Resto,Tamanho).


relva((Tabuleiro,Linhas,Colunas)):-
    length(Tabuleiro,Tamanho),
    calculaObjectosTabuleiro(Tabuleiro, ContagemLinhas, ContagemColunas, t),
    % os findall devolvem lista que contem as linhas e colunas por ocupar.
    findall(L,
        (between(1,Tamanho,L),
        nth1(L,ContagemLinhas,E),
        nth1(L,Linhas,E1),E=:=E1),
        Linhasporocupar),
    findall(C,
        (between(1,Tamanho,C),
        nth1(C,ContagemColunas,E),
        nth1(C,Colunas,E1),E=:=E1),
        Colunasporocupar),
    relva_aux(Tabuleiro,Linhasporocupar,Tamanho),
    transpose(Tabuleiro,TabuleiroNovo),
    relva_aux(TabuleiroNovo,Colunasporocupar,Tamanho).


/* O predicado inacessiveis(Tabuleiro) coloca relva "r" nas coordenadas dos
elementos do tabuleiro que nao estao na vizinhanca de nenhuma arvore,
uma vez que estes nao poderao ter nenhuma tenda. */


inacessiveis(Tabuleiro):-
    todasCelulas(Tabuleiro, TodasCelulas),
    todasCelulas(Tabuleiro, TodasArvores, a),
    maplist(vizinhanca, TodasArvores, Vizinhancas),
    append(Vizinhancas,Acessiveis),
    sort(Acessiveis,ListaAcessiveis),
    findall(L,
        (member(L,TodasCelulas),
        \+member(L,ListaAcessiveis),
        member(L,TodasCelulas)),
        ListaInacessiveis),
    inserir(ListaInacessiveis,r,Tabuleiro).

/* O predicado aproveita(Puzzle) coloca tendas "t" no tabuleiro de forma a
preencher as linhas e colunas as quais faltam um determinado numero de
tendas e nas quais ha esse numero exato de espacos vazios. */


inserelinha([],_):-!.
inserelinha([P|Resto],Tabuleiro):-
    % insere relva em todas as linhas recebidas como parametro.
    length(Tabuleiro,Tamanho),
    insereObjectoEntrePosicoes(Tabuleiro, t, (P, 1), (P, Tamanho)),
    inserelinha(Resto,Tabuleiro).

aproveita((Tabuleiro,Linhas,Colunas)):-
    length(Tabuleiro,Tamanho),
    calculaObjectosTabuleiro(Tabuleiro, ContagemLinha, _, t),
    calculaObjectosTabuleiro(Tabuleiro, VaziaLinhas, _, _),
    findall(Linha,
            (between(1,Tamanho,Linha),
            nth1(Linha,Linhas,A),
            nth1(Linha,ContagemLinha,B),
            nth1(Linha,VaziaLinhas,C),
            C1 is C+B,
            C1=:=A),
            Apreencher),
    inserelinha(Apreencher,Tabuleiro),
    transpose(Tabuleiro,TabuleiroNovo),
    calculaObjectosTabuleiro(Tabuleiro, _, ContagemColuna, t),
    calculaObjectosTabuleiro(Tabuleiro,_, VaziaColunas, _),
    findall(Coluna,
        (between(1,Tamanho,Coluna),
        nth1(Coluna,Colunas,D),
        nth1(Coluna,ContagemColuna,E),
        nth1(Coluna,VaziaColunas,F),
        F1 is F+E,F1=:=D),
        Apreencher2),
    inserelinha(Apreencher2,TabuleiroNovo).

/* O predicado limpaVizinhancas(Puzzle) vai colocar relva "r" em todas as
coordenadas que fazem parte da vizinhanca alargada de todas as tendas, com
o objetivo de nao haver tendas que se toquem. */

limpaVizinhancas((Tabuleiro,_,_)):-
    todasCelulas(Tabuleiro, Tendas, t),
    limpezaportenda(Tabuleiro,Tendas).

% O predicado limpezaportenda(Tabuleiro,Tendas) insere relva "r" recursivamente 
% nas coordenadas da vizinhanca alargada de cada Tenda da lista Tendas.

limpezaportenda(_,[]).
limpezaportenda(Tabuleiro,[Tenda|Resto]):-
    vizinhancaAlargada(Tenda,Vizinhanca),
    inserir(Vizinhanca,r,Tabuleiro),
    limpezaportenda(Tabuleiro,Resto).


/* O predicado unicaHipotese(Puzzle) e utilizado para colocar uma tenda "t" na
unica coordenada da vizinhanca que corresponde a um espaco vazio para
todas as arvores que apenas tem um elemento da sua vizinhanca vazio. */

unicaHipotese((Tabuleiro,_,_)):-
    todasCelulas(Tabuleiro, Arvores, a),
    vervizinhanca(Tabuleiro,Arvores).

vervizinhanca(_,[]).

vervizinhanca(Tabuleiro,[Arvore|Resto]):-
    vizinhanca(Arvore,Vizinhanca),
    findall(X,(between(1,4,X),nth1(X,Vizinhanca,H),elementodacelula(Tabuleiro,H,Objecto),Objecto==t),Tendas),
    findall(X,(between(1,4,X),nth1(X,Vizinhanca,H),elementodacelula(Tabuleiro,H,Objecto),var(Objecto)),Vazio),
    length(Tendas,T),
    T=:=0,
    length(Vazio,V),
    V=:=1,
    inserir(Vizinhanca,t,Tabuleiro),
    vervizinhanca(Tabuleiro,Resto).

vervizinhanca(Tabuleiro,[_|Resto]):-
    vervizinhanca(Tabuleiro,Resto).


/* O predicado valida(LArv, LTen) gere o resultado "true" se LArv e LTen
forem, respetivamente, listas que contenham todas as coordenadas de elementos
com arvores e com tendas */

% predicado auxiliar resolve que devolve uma lista sem os elementos da primeira 
% lista dada como parametro que se encontram na segunda lista dada como parametro.

remove(_, [], []).
remove(X, [X | Resto], Lista) :-
    remove(X, Resto, Lista).
remove(X, [H | Resto], [H | Lista]) :-
    dif(X, H),
    remove(X, Resto, Lista).

valida([],[]).

valida([Arvore | Resto1], Tendas):-
    vizinhanca(Arvore, Vizinhanca),
    findall(X,(between(1,4,X),nth1(X,Vizinhanca,H),member(H,Tendas)),Vazio),
    length(Vazio,Quantidade),
    Quantidade =:= 1,!,
    nth1(1,Vazio,P),
    nth1(P,Vizinhanca,Tenda),
    remove(Tenda,Tendas,TendasNova),
    valida(Resto1, TendasNova).

valida([Arvore | Resto], Tendas):-
    vizinhanca(Arvore, Vizinhanca),
    findall(X,(between(1,4,X),nth1(X,Vizinhanca,H),member(H,Tendas)),Vazio),
    length(Vazio,Quantidade),
    Quantidade &gt;= 1 ,
    append([Resto,[Arvore]],RestoNovo),
    valida(RestoNovo,Tendas).



/*O predicado resolve(Puzzle) devolve o puzzle resolvido.*/

resolve((Tabuleiro,_,_)):-
    todasCelulas(Tabuleiro, CelulasLivres, _),
    length( CelulasLivres,Tamanho),
    Tamanho =:=0,!,
    todasCelulas(Tabuleiro, Tendas, t),
    todasCelulas(Tabuleiro, Arvores, a),
    valida(Arvores,Tendas).

resolve((Tabuleiro,_,_)):-
    todasCelulas(Tabuleiro, Tendas, t),
    todasCelulas(Tabuleiro, Arvores, a),
    length(Tendas,TTendas),
    length(Arvores,TArvores),
    \+ dif(TTendas,TArvores),!,
    valida(Arvores,Tendas),
    todasCelulas(Tabuleiro, CelulasLivres, _),
    inserir(CelulasLivres,r,Tabuleiro).

resolve((Tabuleiro,_,_)):-
    todasCelulas(Tabuleiro, Tendas, t),
    todasCelulas(Tabuleiro, Arvores, a),
    valida(Arvores,Tendas).


resolve((Tabuleiro,Linhas,Colunas)):-
    todasCelulas(Tabuleiro, Livreinicial, X),
    length(Livreinicial,Tamanhoinicial),
    relva((Tabuleiro,Linhas,Colunas)),
    inacessiveis(Tabuleiro),
    limpaVizinhancas((Tabuleiro,Linhas,Colunas)),
    aproveita((Tabuleiro,Linhas,Colunas)),
    unicaHipotese((Tabuleiro,Linhas,Colunas)),
    todasCelulas(Tabuleiro, Livrefinal, X),
    length(Livrefinal,Tamanhofinal),
    dif(Tamanhoinicial,Tamanhofinal),!,
    resolve((Tabuleiro,Linhas,Colunas)).

resolve((Tabuleiro,Linhas,Colunas)):-
    todasCelulas(Tabuleiro,CelulasLivres,_),!,
    resolveporcelula((Tabuleiro,Linhas,Colunas), CelulasLivres).

inserirobjetopermante(Tabuleiro, t, Inicial):- 
    insereObjectoCelula(Tabuleiro, t, Inicial),!.

% resolve por celula e um predicado que coloca aleatoriamente uma tenda de modo 
% a perceber se assim e possivel resolver o puzzle. Caso nao resulte coloca 
% outra tenda ate ser possivel resolver o puzzle.

resolveporcelula((Tabuleiro,Linhas,Colunas),[Inicial|_]):-
    inserirobjetopermante(Tabuleiro, t, Inicial),
    resolve((Tabuleiro,Linhas,Colunas)).

resolveporcelula((Tabuleiro,Linhas,Colunas),[_|Resto]):-
    resolveporcelula((Tabuleiro,Linhas,Colunas),Resto).