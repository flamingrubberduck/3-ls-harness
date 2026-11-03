# Checks: Go

| File | Put it in | Needs | Run |
| --- | --- | --- | --- |
| `.golangci.yml` | Repository root | golangci-lint v2 | `golangci-lint run` |

It fails on ignored errors (including unchecked type assertions), errors compared without `errors.Is` or `errors.As`, functions that drop the caller's context, HTTP requests without a context, unformatted code, and handlers that import `database/sql` directly.

Also run `go test -race ./...` in CI so data races fail the build. Projects still on golangci-lint v1 can run `golangci-lint migrate` to convert their old config, then merge these settings in.
