PGDATABASE ?= pgo_test
export PGDATABASE

OCAML_VERSION ?= 4.12.1

OPAMSWITCH ?= $(PWD)
export OPAMSWITCH

BEAR =
BEARCMD := $(shell command -v bear 2> /dev/null)
ifdef BEARCMD
	BEAR = $(BEARCMD) --
endif

init:
	opam switch create . $(OCAML_VERSION) --deps-only -y

.PHONY: clean
clean:
	@opam exec -- dune $(@)
	@rm -f compile_commands.json

.PHONY: build b
build b:
	@$(BEAR) opam exec -- dune build

test-db:
	@dropdb --if-exists $(PGDATABASE)
	@createdb $(PGDATABASE)

EXAMPLE_INSTALLDIR = $(PWD)/_build/install/default/lib/pgo_example

psql-func: build
	@$(eval TMP := $(shell mktemp -d))
	@echo " \
	set client_min_messages to warning; \
	set dynamic_library_path = '$(EXAMPLE_INSTALLDIR):$libdir'; \
	begin; \\i $(EXAMPLE_INSTALLDIR)/func.sql;\ncommit; \
	load 'func.so'; \
	set client_min_messages to notice; \
	select pg_backend_pid(); \
	" > $(TMP)/psqlrc
	@PSQLRC=$(TMP)/psqlrc psql 

psql-ps_fdw: build
	@$(eval TMP := $(shell mktemp -d))
	@echo " \
	set client_min_messages to warning; \
	set dynamic_library_path = '$(EXAMPLE_INSTALLDIR):$libdir'; \
	begin; \\i $(EXAMPLE_INSTALLDIR)/ps_fdw.sql;\ncommit; \
	load 'ps_fdw.so'; \
	set client_min_messages to notice; \
	select pg_backend_pid(); \
	" > $(TMP)/psqlrc
	@PSQLRC=$(TMP)/psqlrc psql 
