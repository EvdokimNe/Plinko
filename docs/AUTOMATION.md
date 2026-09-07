# Automation

How this project is built, run and tested without clicking in the editor. Three interfaces,
each for a different job. All of them are official Defold interfaces — there is no Defold MCP
server, and the Defold Foundation states it does not intend to write one, because these
interfaces already cover the ground.

Sources: [Editor HTTP API](https://defold.com/manuals/editor-http-api/),
[Engine service](https://defold.com/manuals/engine-service/),
[Bob](https://defold.com/manuals/bob/),
[Using AI coding agents with Defold](https://defold.com/manuals/ai-agents/).

## 1. Bob — reproducible builds

Command-line build tool. Use it for anything that must produce the same result twice: CI, the
HTML5 bundle, a clean compile check.

Bob needs **Java 25** and **must run from PowerShell** — under Git Bash it cannot create the
selector pipe its internal HTTP client needs and dies before building.

```powershell
$java = "E:\dev\Defold\packages\jdk-25+36\bin\java.exe"
& $java -jar plans\tools\bob.jar resolve                       # fetch dependencies
& $java -jar plans\tools\bob.jar --archive build               # compile, report errors
& $java -jar plans\tools\bob.jar --archive --platform wasm-web --bundle-output dist\bundle build bundle
```

HTML5 is `wasm-web`; `js-web` was removed and bob rejects it. Bob itself is not in the
repository — download it from the [Defold release](https://github.com/defold/defold/releases)
matching the editor version and keep it in `plans/tools/`.

## 2. Editor HTTP API — the open editor

While a project is open the editor serves a local HTTP API. The port is written to
`.internal/editor.port`, the session token to `.internal/editor.token`; `/openapi.json` is the
authoritative list of operations for the running version.

```sh
PORT=$(cat .internal/editor.port)
TOKEN=$(cat .internal/editor.token)
BASE="http://127.0.0.1:$PORT"
curl -s -H "Authorization: Bearer $TOKEN" "$BASE/openapi.json"
```

| Endpoint | Use |
|---|---|
| `POST /command/build` | build and run the project |
| `POST /command/build-html5` | build for HTML5 and open a browser |
| `POST /command/clean-build` | clear caches and rebuild, when builds behave oddly |
| `GET /console` | everything the editor console printed |
| `GET /console/stream` | the same, streamed (`curl -N`) |
| `GET /preview/{path}` | render a scene resource as PNG — look at a collection without opening it |
| `GET /ref?q=<term>` | search the engine API reference offline |
| `POST /eval` | run Lua in the editor extension runtime |
| `GET|POST /prefs/{path}` | read or write an editor preference |

The API is marked experimental and can change between Defold versions — read `/openapi.json`
rather than trusting a hard-coded list.

## 3. Engine service — the running game

A running debug build serves its own HTTP API and prints its port at startup
(`Engine service started on port 8001`). For driving a running game — input, screenshots, live
state — the official [Automation Bridge](https://github.com/defold/extension-automation-bridge)
extension adds a versioned API on top of it. It is debug-only and absent from release builds.
Not used in this project yet.

## Running the tests

**Locally — through the open editor.** The editor launches its own engine, already installed and
trusted by the OS, so nothing extra has to be downloaded:

```sh
PORT=$(cat .internal/editor.port); TOKEN=$(cat .internal/editor.token)
curl -s -X POST -H "Authorization: Bearer $TOKEN" "http://127.0.0.1:$PORT/command/build"
curl -s      -H "Authorization: Bearer $TOKEN" "http://127.0.0.1:$PORT/console"
```

The test runner collection prints results to the console and exits the engine with a status
code; `/console` is where those results are read.

**In CI — headless.** GitHub Actions has no editor, so the runner downloads `bob.jar` and
`dmengine_headless` for the engine sha1 in use, builds, and runs the binary. Its exit code is
the test result. `dmengine_headless` lives at
`http://d.defold.com/archive/<sha1>/engine/<platform>/dmengine_headless`; the sha1 of the
editor's engine is in the editor's `config` file. It is signed by the Defold Foundation
(GlobalSign EV) — verify the signature rather than the download page.
