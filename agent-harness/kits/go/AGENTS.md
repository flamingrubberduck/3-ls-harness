# Stack kit: Go

Version: 0.1.0 · Owner: Engineering practice group

Sample kit: review and adapt before use. Rules for every Go service or library. The project's AGENTS.md lists exact commands and anything that differs.

## Commands

- Build: `go build ./...`
- Tests: `go test ./...` (use `go test -race ./...` when touching concurrent code)
- Vet: `go vet ./...`
- Format check: `gofmt -l .` (must print nothing)
- Lint: `golangci-lint run` (if the project uses it)

## Structure

- Follow the project's existing package layout; keep `main` packages thin and put logic in internal packages.
- Pass `context.Context` as the first parameter of functions that do I/O or may block, and respect cancellation.
- Define interfaces where they are used, not where they are implemented.

## Rules agents often break

- Never discard errors with `_`. Return them, or handle them explicitly.
- Wrap errors with context using `fmt.Errorf("...: %w", err)` so callers can still inspect them.
- Every goroutine needs a clear way to stop (context cancellation or a closed channel); do not leak goroutines.
- Protect shared state with the project's chosen mechanism (mutex or channels) and run the race detector on concurrent code.
- Do not `panic` in library or request-handling code; return an error.
- On Go versions before 1.22, loop variables are shared across iterations; copy them before capturing in goroutines or closures.
- Do not change `go.mod` (new modules, upgrades, `go` version) without approval (company baseline).

## Checks this kit provides

Ready-made files are in this kit's `checks/` folder; projects get a copy in `.harness/kit/checks/`.

- [ ] golangci-lint with `errcheck` and `govet` enabled; `gofmt` check
- [ ] Import restrictions (e.g. depguard): handlers do not import the storage layer directly
- [ ] CI steps: build, vet, tests with `-race`, protected-test check from the company baseline

## Changelog

| Version | Change |
| --- | --- |
| 0.1.0 | Sample kit |
