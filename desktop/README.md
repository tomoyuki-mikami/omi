# OMI Desktop

macOS app for OMI — always-on AI companion. Swift/SwiftUI frontend, Rust backend.

## Structure

```
Desktop/          Swift/SwiftUI macOS app (SPM package)
Backend-Rust/     Rust API server (Firestore, Redis, auth, LLM)
agent/            Agent runtime for multi-provider chat (TypeScript)
agent-cloud/      Cloud agent service
dmg-assets/       DMG installer resources
```

## Development

Requires macOS 14.0+, Rust toolchain, and code signing with an Apple Developer ID.

```bash
# Run (builds Swift app, starts Rust backend, launches app)
./run.sh

# Run with the prod backend (skips local Rust + tunnel)
./run.sh --yolo
```

`run.sh` auto-detects an `Apple Development` or `Developer ID Application` signing identity from your login keychain. Override with `OMI_SIGN_IDENTITY="..." ./run.sh`.

## Self-hosted launch

For a self-hosted fork, copy `self-hosted.env.example` to `self-hosted.env` and replace the endpoint values with infrastructure you control.

Docker is not required for the default local path. Run the Python backend from `../backend` with `uvicorn`, then launch the desktop app through the self-hosted wrapper. The wrapper starts the Rust desktop backend from `Backend-Rust` by default.

See `SELF_HOSTED_LOCAL.md` for the required local `.env` and credential checklist.

```bash
cp self-hosted.env.example self-hosted.env

cd ../backend
uvicorn main:app --reload --env-file .env

cd ../desktop
OMI_SELF_HOSTED_PREFLIGHT_ONLY=1 ./run-self-hosted.sh
./run-self-hosted.sh
```

`run-self-hosted.sh` refuses to launch if `OMI_PYTHON_API_URL` or `OMI_DESKTOP_API_URL` is empty or points to a known Omi-managed backend. Set `OMI_SKIP_BACKEND=1` only when `OMI_DESKTOP_API_URL` points to a Rust desktop backend you operate outside this checkout.

## License

MIT
