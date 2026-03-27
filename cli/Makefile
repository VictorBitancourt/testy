VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
LDFLAGS  = -ldflags "-s -w -X github.com/victorbitancourt/testy-cli/internal/version.Version=$(VERSION)"
BINARY   = bin/testy

.PHONY: build clean test lint check fmt

build:
	@mkdir -p bin
	go build $(LDFLAGS) -o $(BINARY) ./cmd/testy

clean:
	rm -rf bin/

test:
	go test ./...

lint:
	@command -v golangci-lint >/dev/null 2>&1 && golangci-lint run ./... || echo "golangci-lint not installed, skipping"

fmt:
	gofmt -w .

check: fmt test lint
	@echo "All checks passed."
