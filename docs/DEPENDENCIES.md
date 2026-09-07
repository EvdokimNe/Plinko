# Dependencies

Every third-party library in this project, why it is here, and how to add another one.
The authoritative list is `game.project`; this file explains it.

## Libraries

| Library | Version | Author | License | Why | Notes |
|---|---|---|---|---|---|
| [defold-event](https://github.com/Insality/defold-event) | tag `16` | Insality | MIT | Required by Druid for all component callbacks | Not used directly by our code |
| [Druid](https://github.com/Insality/druid) | `1.3.0` | Insality | MIT | UI components over gui nodes | [notes](lib/druid.md) |
| [Monarch](https://github.com/britzl/monarch) | `6.0.2` | Björn Ritzl (Defold co-founder) | MIT | Screen stack and transitions | [notes](lib/monarch.md) |
| [deftest](https://github.com/britzl/deftest) | `2.8.0` | Björn Ritzl | MIT | Unit tests, mocks, coverage | [notes](lib/deftest.md) |

Each library was verified through the official [Defold asset portal](https://defold.com/assets/)
before being added — the portal's author and repository link is the check against typosquats.

Project folders they contribute: `event/`, `druid/`, `monarch/`, `deftest/` + `luacov/`.

## Order matters

Dependencies are listed as `dependencies#0..N` in `game.project`, and **the order is part of the
contract**: if two libraries ship a folder with the same name, Defold keeps only the one that
appears *last* in the list and silently ignores the rest.

Current order, base libraries before their dependents:

```
#0  defold-event      Druid needs it
#1  druid
#2  monarch
#3  deftest           test-only, last so it can never shadow runtime code
```

## Pinning

Every URL points at an exact tag archive, never at `master.zip` — an upstream commit must never
change our build. `.internal/lib/dependencies.json` records the resolved commit sha of each.

Pin the version the dependent library asks for, not the newest one: Druid 1.3.0's README asks
for defold-event `16` even though tag `21` exists.

## Adding a library

1. Find it on the official asset portal and confirm the author and repository it links to.
2. Read its README for extra required dependencies (Druid needed one).
3. Add `dependencies#N` with an exact tag, in the right position for the order rule above.
4. `Project ▸ Fetch Libraries` in the editor, or `bob.jar resolve`.
5. Write `docs/lib/<name>.md`: API, invariants, common pitfalls — from the library source under
   `.internal/lib/`, not from memory.
6. Add a row to the table above.

## Tooling

Not a dependency of the game, but of the workflow:

- `bob.jar` 1.13.1 (sha1 `574678c7...`, same as the editor) — command-line builds, bundles and
  headless test runs. Downloaded from the official
  [Defold release](https://github.com/defold/defold/releases/tag/1.13.1), kept out of the
  repository in `plans/tools/`.
- It needs **Java 25**; the JDK bundled with the editor works:
  `E:/dev/Defold/packages/jdk-25+36/bin/java`.
