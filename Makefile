COBC ?= cobc
COBFLAGS ?= -free -Wall -I src/copybooks
SODIUM_LIBS ?= $(shell pkg-config --libs libsodium 2>/dev/null || echo -lsodium)
SOURCES := $(shell find src -name '*.cob' | sort)
TESTS := core-test json-test http-test url-test transport-test websocket-test ws-handshake-test gateway-test voice-test rtp-test crypto-test command-router-test interaction-test opus-test music-queue-test music-playback-test

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
	$(COBC) $(COBFLAGS) -x -o $@ $< $(SOURCES) $(SODIUM_LIBS)

test: $(addprefix build/test/,$(TESTS))
	@for test in $(TESTS); do \
		echo "RUN $$test"; \
		"./build/test/$$test" || exit $$?; \
	done

clean:
	rm -rf build
