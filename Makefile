COBC ?= cobc
COBFLAGS ?= -free -Wall -I src/copybooks
SOURCES := $(shell find src -name '*.cob' | sort)
TESTS := core-test json-test http-test websocket-test rtp-test music-queue-test

.PHONY: all build test clean

all: build test

build:
	@mkdir -p build/obj
	@for src in $(SOURCES); do \
		obj="build/obj/$$(echo $$src | tr '/.' '__').o"; \
		echo "COBOL $$src"; \
		$(COBC) $(COBFLAGS) -c "$$src" -o "$$obj" || exit $$?; \
	done

build/test/%: tests/%.cob $(SOURCES)
	@mkdir -p build/test
	$(COBC) $(COBFLAGS) -x -o $@ $< $(SOURCES)

test: $(addprefix build/test/,$(TESTS))
	@for test in $(TESTS); do \
		echo "RUN $$test"; \
		"./build/test/$$test" || exit $$?; \
	done

clean:
	rm -rf build
