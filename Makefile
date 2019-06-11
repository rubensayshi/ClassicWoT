.PHONY: tests

TESTS ?= tests/* tests/*/*

setup-dev:
	luarocks install luacheck
	luarocks install busted

hr:
	@echo "======================================================================================"
	@echo "======================================================================================"

lint:
	luacheck ./src

tests:
	busted -m './src/?.lua;./src/?/?.lua;./src/?/init.lua;./libs/?.lua;./libs/?/?.lua;./tests/?.lua;./tests/?/?.lua' $(TESTS)

reflex-tests:
	reflex -r '.*\.lua' -s  -- sh -c 'make hr lint tests'

bundle:
