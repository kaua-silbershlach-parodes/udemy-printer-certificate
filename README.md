# Udemy Printer Certificate - desktop base by A Elite Estrangeira

Udemy Printer Certificate is a desktop base built by A Elite Estrangeira on the Machinery template: a Tauri (Rust) shell with an Elixir/OTP backend sidecar and signed auto-updates.

## What is inside

- Tauri 2 desktop app for Windows with an NSIS installer
- Elixir/OTP backend sidecar with a local health endpoint on 127.0.0.1:45900
- Signed auto-updates through the GitHub release feed (latest.json)
- English interface with Updates and Backend panels

## Development

Run the numbered scripts in `scripts/` to set up, build, and smoke-test the base. The backend compiles with `mix compile` inside `backend/`.

## License

Copyright A Elite Estrangeira. See LICENSE.
