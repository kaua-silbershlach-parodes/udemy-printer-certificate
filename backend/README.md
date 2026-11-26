# Backend — Elixir sidecar

This template follows the architecture of the house's NativeBeam
project: a small native shell (here, Rust + the system WebView)
around a local **Elixir/BEAM backend** that does the real work.

This folder now carries a **minimal, working skeleton** — pure OTP,
zero dependencies:

| Path | Contents |
|---|---|
| `mix.exs` | The Mix project (`:udemy_printer_certificate_backend`, version 1.0.0, no deps) |
| `lib/udemy_printer_certificate_backend/application.ex` | The OTP application: a supervisor with one child |
| `lib/udemy_printer_certificate_backend/health_server.ex` | A supervised `:gen_tcp` HTTP health server on **127.0.0.1:45900** (port override: `UDEMY_PRINTER_CERTIFICATE_BACKEND_PORT`) that answers any request with `{"status":"ok","service":"udemy_printer_certificate_backend","version":"1.0.0"}` |

Run it:

```text
cd backend
mix run --no-halt
rem then, in another terminal:
curl http://127.0.0.1:45900/health
```

## The contract a real backend plugs into

- The backend is an independent Elixir application (OTP),
  packaged separately and placed beside the shell executable, or
  started by the shell as a child process.
- The shell and the backend talk over **localhost only**
  (HTTP/WebSocket on 127.0.0.1). Nothing is exposed to the network
  by the backend itself.
- The backend owns its own lifecycle: the shell starts it, health-
  checks it (the endpoint above), and restarts it when it dies —
  the OTP supervision model applied across the process boundary.
- Versioning is independent: the shell shows its own version in
  the Updates panel; the backend reports its version on its
  health endpoint.

Why Elixir stays, even though the shell moved from C++ to Rust:
the BEAM gives supervision, distribution between machines and hot
loading of modules — the properties the platform design is built
on. Rust replaces the native shell, not the brain.
