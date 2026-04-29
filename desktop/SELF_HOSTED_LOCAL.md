# Self-hosted local backend checklist

This guide is for running the macOS desktop app against backend services you operate from this checkout.

Docker is not required for the default local path.

## Target local endpoints

```env
OMI_PYTHON_API_URL=http://localhost:8000
OMI_DESKTOP_API_URL=http://localhost:10201
```

- `OMI_PYTHON_API_URL` points to `backend/`, the FastAPI backend.
- `OMI_DESKTOP_API_URL` points to `desktop/Backend-Rust/`, the Rust desktop backend.

## Files to create

Do not commit these files.

```text
backend/.env
backend/google-credentials.json
desktop/Backend-Rust/.env
desktop/Backend-Rust/google-credentials.json
desktop/self-hosted.env
```

`backend/google-credentials.json` and `desktop/Backend-Rust/google-credentials.json` can both be symlinks to the same Firebase Admin SDK service account JSON when both backends use the same Firebase project.

## Local Redis

Run Redis locally with Docker:

```bash
cd desktop
docker compose -f docker-compose.self-hosted.yml up -d redis
docker compose -f docker-compose.self-hosted.yml ps
```

Both backends should use:

```env
REDIS_DB_HOST=localhost
REDIS_DB_PORT=6379
REDIS_DB_PASSWORD=
```

## Firebase / GCP

Required before either backend can talk to your own Firestore:

- A Firebase project you control.
- Firestore enabled in that project.
- A service account JSON for that project.
- `FIREBASE_PROJECT_ID` set to that project id.
- `FIREBASE_API_KEY` from that Firebase project.

Use the same project for both backends at first. Split `FIREBASE_AUTH_PROJECT_ID` later only if auth tokens and Firestore must come from different projects.

## Python backend env

Create:

```bash
cd backend
cp .env.template .env
```

Minimum values to fill first:

```env
GOOGLE_APPLICATION_CREDENTIALS=google-credentials.json
FIREBASE_PROJECT_ID=<your-firebase-project-id>
FIREBASE_API_KEY=<your-firebase-web-api-key>
FIREBASE_AUTH_DOMAIN=<your-firebase-project-id>.firebaseapp.com
BASE_API_URL=http://localhost:8000
API_BASE_URL=http://localhost:8000
ADMIN_KEY=<local-admin-key>
ENCRYPTION_SECRET=<32+ character secret>
REDIS_DB_HOST=localhost
REDIS_DB_PORT=6379
REDIS_DB_PASSWORD=
```

Needed for core AI / transcription features:

```env
OPENAI_API_KEY=<your-openai-api-key>
DEEPGRAM_API_KEY=<your-deepgram-api-key>
```

Can stay empty until the corresponding feature is used:

```env
PINECONE_API_KEY=
PINECONE_INDEX_NAME=
STRIPE_API_KEY=
STRIPE_WEBHOOK_SECRET=
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
APPLE_CLIENT_ID=
APPLE_TEAM_ID=
APPLE_KEY_ID=
APPLE_PRIVATE_KEY=
PERPLEXITY_API_KEY=
ELEVENLABS_API_KEY=
TYPESENSE_HOST=
TYPESENSE_HOST_PORT=
TYPESENSE_API_KEY=
```

Start it with:

```bash
cd backend
uvicorn main:app --reload --env-file .env
```

## Rust desktop backend env

Create:

```bash
cd desktop/Backend-Rust
cp .env.example .env
```

Minimum values to fill first:

```env
PORT=10201
FIREBASE_PROJECT_ID=<your-firebase-project-id>
GOOGLE_APPLICATION_CREDENTIALS=google-credentials.json
FIREBASE_API_KEY=<your-firebase-web-api-key>
BASE_API_URL=http://localhost:8000
ENCRYPTION_SECRET=<same or compatible 32+ character secret>
REDIS_DB_HOST=localhost
REDIS_DB_PORT=6379
REDIS_DB_PASSWORD=
```

Needed for desktop AI / transcription proxy features:

```env
GEMINI_API_KEY=<your-gemini-api-key>
DEEPGRAM_API_KEY=<your-deepgram-api-key>
ANTHROPIC_API_KEY=<your-anthropic-api-key>
```

Can stay empty until the corresponding feature is used:

```env
PINECONE_API_KEY=
PINECONE_HOST=
GCE_PROJECT_ID=
GCE_SOURCE_IMAGE=
AGENT_GCS_BUCKET=
GOOGLE_CALENDAR_API_KEY=
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
APPLE_CLIENT_ID=
APPLE_TEAM_ID=
APPLE_KEY_ID=
APPLE_PRIVATE_KEY=
POSTHOG_PERSONAL_API_KEY=
SENTRY_WEBHOOK_SECRET=
SENTRY_AUTH_TOKEN=
SENTRY_ADMIN_UID=
CRISP_PLUGIN_IDENTIFIER=
CRISP_PLUGIN_KEY=
CRISP_WEBSITE_ID=
```

`desktop/run-self-hosted.sh` starts the Rust desktop backend through `desktop/run.sh` by default.

## Desktop wrapper env

Create:

```bash
cd desktop
cp self-hosted.env.example self-hosted.env
```

Keep the local values unless you intentionally run one of the backends elsewhere:

```env
OMI_PYTHON_API_URL=http://localhost:8000
OMI_DESKTOP_API_URL=http://localhost:10201
```

## Verification order

1. Start the Python backend:

   ```bash
   cd backend
   uvicorn main:app --reload --env-file .env
   ```

2. In another terminal, start Redis:

   ```bash
   cd desktop
   docker compose -f docker-compose.self-hosted.yml up -d redis
   ```

3. Run the desktop preflight:

   ```bash
   cd desktop
   OMI_SELF_HOSTED_PREFLIGHT_ONLY=1 ./run-self-hosted.sh
   ```

4. If preflight passes, launch the desktop app:

   ```bash
   ./run-self-hosted.sh
   ```

5. Verify the dev app, not the production app:

   ```bash
   agent-swift connect --bundle-id com.omi.desktop-dev
   agent-swift snapshot -i
   ```
