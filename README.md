# Tents and Trees (Tendas e Árvores) in Prolog

Prolog solver for the **Tents and Trees** puzzle, built for the *Lógica para
Programação* (Logic for Programming) course at IST, 2023/24.

Given a board with some trees and how many tents each row and column must
contain, the program finds where every tent goes. It combines a handful of
human-style deduction strategies with a small trial-and-error search.

```
 initial puzzle (6-14)              solved
 2 1 1 1 2 0                        2 1 1 1 2 0
 . a . a . .   3                    t a t a t r   3
 a . . . . .   0                    a r r r r r   0
 . . . . . .   1                    r r r t r r   1
 . . a a . .   1                    r t a a r r   1
 . . . . . .   1                    r r r r t r   1
 . a . . a .   1                    t a r r a r   1
```

`a` = tree · `t` = tent · `r` = grass · unbound variable = still unknown.

## Run it

Requires [SWI-Prolog](https://www.swi-prolog.org/).

```bash
make test        # run the 33 unit tests
make repl        # open a REPL with the solver loaded
```

```prolog
?- puzzle(6-14, P), resolve(P).
P = ([[t,a,t,a,t,r],[a,r,r,r,r,r],[r,r,r,t,r,r],
      [r,t,a,a,r,r],[r,r,r,r,t,r],[t,a,r,r,a,r]],
     [3,0,1,1,1,1], [2,1,1,1,2,0]).
```

Numbers above the board are tents per column, numbers on the right are tents per row. A puzzle is a triple `(Board, TentsPerRow, TentsPerColumn)`. Puzzles `6-13`,
`6-14` and `8-1` ship with the project in [`src/puzzlesAcampar.pl`](src/puzzlesAcampar.pl).

## How it works

`resolve/1` repeats the strategies below until they stop making progress,
checking after every round that no row or column can still be satisfied
(otherwise it fails and backtracks). If cells are still free, it places a
tent, or grass, on the first free cell and carries on. Only a complete board
with the right counts and a valid tree-to-tent matching is accepted.

| Predicate | What it does |
|---|---|
| `vizinhanca/2`, `vizinhancaAlargada/2` | Orthogonal neighbours, and neighbours including diagonals |
| `todasCelulas/2,3` | All coordinates, or those holding a given object |
| `calculaObjectosTabuleiro/4` | Count of an object per row and per column |
| `celulaVazia/2` | Cell is free or grass (out-of-board coordinates don't fail) |
| `insereObjectoCelula/3`, `insereObjectoEntrePosicoes/4` | Place an object in a cell, or across a row segment |
| `relva/1` | Fill rows/columns that already have all their tents with grass |
| `inacessiveis/1` | Grass on every cell not next to a tree |
| `aproveita/1` | If a line needs N tents and has exactly N free cells, fill them |
| `limpaVizinhancas/1` | Grass around each tent (tents may not touch, even diagonally) |
| `unicaHipotese/1` | A tree with a single free neighbour must get its tent there |
| `valida/2` | Every tree can be paired with its own distinct adjacent tent |
| `resolve/1` | Strategies to a fixed point, then trial and error |

## Project layout

```
src/
  TendasEArvores.pl     the solver
  puzzlesAcampar.pl     puzzles and solutions provided by the course
tests/
  UnitTests.pl          33 plunit tests
  MooshakExamples.pl    example queries used by the course's judge
docs/
  enunciado.pdf         the project statement (in Portuguese)
Makefile
```

## Tests

```
% 33 tests passed, 0 warnings
```

The tests cover every predicate above plus full solves of the three
provided puzzles and an extra 8×8 one.

## Original submission

[`original-submission/`](original-submission/TendasEArvores.pl) keeps the solver as it
was first written (it passes 23 of the 33 tests). The version in `src/` is the
rewritten, fixed one.

---

*Code comments are written in Portuguese, without accents, as the assignment required.*
