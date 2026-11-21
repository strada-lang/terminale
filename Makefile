# Terminale - web terminal module for Cannoli.
#
#   make          build terminale.so            (./build.sh)
#   make fast     quick unoptimized build
#   make test     build and run the tests
#   make run      build if needed and start it  (ARGS="-u me -p 8022 --ssl")
#   make clean

.PHONY: all fast test run clean

all:
	@./build.sh

fast:
	@./build.sh --fast

test:
	@./build.sh --fast --test

run:
	@./start.sh $(ARGS)

clean:
	@./build.sh --clean
