COBC ?= cobc
COBFLAGS ?= -free -Wall -I src/copybooks
SODIUM_LIBS ?= $(shell pkg-config --libs libsodium 2>/dev/null || echo -lsodium)
SOURCES := $(shell find src -name '*.cob' | sort)
TESTS := core-test json-test http-test url-test transport-test websocket-test ws-handshake-test gateway-test voice-test rtp-test crypto-test command-router-test interaction-test slash-command-test opus-test music-queue-test music-playback-test
EXAMPLES := 00-core-test 01-rest-message 02-gateway-ready 03-slash-command 04-voice-join 05-udp-discovery 06-rtp-silence 07-encrypted-rtp 08-play-opus-file 09-music-bot

.PHONY: all build test examples clean

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

build/examples/%: examples/%/main.cob $(SOURCES)
	@mkdir -p build/examples
	$(COBC) $(COBFLAGS) -x -o $@ $< $(SOURCES) $(SODIUM_LIBS)

examples: $(addprefix build/examples/,$(EXAMPLES))

clean:
	rm -rf build
