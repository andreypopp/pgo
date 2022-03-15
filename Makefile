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

INSTALLDIR = $(PWD)/_build/install/default/lib/pgo

define PSQLRC_DATA
set client_min_messages to warning;
set dynamic_library_path = '$(INSTALLDIR):$libdir';
begin;
\\i $(INSTALLDIR)/pgo_fdw.sql
commit;
load 'pgo_fdw.so';
set client_min_messages to notice;
endef
export PSQLRC_DATA

psql: build
	@$(eval TMP := $(shell mktemp -d))
	@echo "$$PSQLRC_DATA" > $(TMP)/psqlrc
	@PSQLRC=$(TMP)/psqlrc psql -q
