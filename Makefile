.PHONY: test repl

test:
	swipl -q -g run_tests -t halt tests/UnitTests.pl

repl:
	cd src && swipl -q TendasEArvores.pl
