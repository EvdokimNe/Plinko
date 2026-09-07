# deftest 2.8.0

> Unit tests inside the Defold runtime: a Telescope wrapper with luacov coverage and mocks for
> time, gui and fs. Björn Ritzl, MIT. Verified current: Druid 1.3.0 (Aug 2026) tests with it.

## Runner
```lua
local deftest = require("deftest.deftest")
function init(self)
    deftest.add(require("features.board.tests.board_test"))
    deftest.run({ coverage = { enabled = true } })   -- exits the engine with a status code
end
```
Run headless: `bob.jar build` then `dmengine_headless` — the exit code is the test result, which
is what CI reads.

## Test file shape
```lua
return function()
    describe("Board", function()
        before(function() ... end)
        after(function() ... end)
        it("drops a ball into a slot", function()
            assert(actual == expected)
        end)
    end)
end
```
A suite is a function returning nothing; `deftest.add` takes the function itself.

## Assertions
Plain `assert` plus Telescope's: `assert_equal`, `assert_same`, `assert_unique`, `assert_nil`,
`assert_error`, `assert_greater_than`, `assert_type`, and the `assert_not_*` mirrors.

## Mocks
- `deftest.mock.time` — `mock()`, `set(t)`, `elapse(dt)`, `unmock()`. Makes `socket.gettime`
  and timers deterministic.
- `deftest.mock.gui` — gui node stubs, so gui logic runs outside a real gui scene.
- `deftest.mock.fs` — file system stub.
- `deftest.mock.mock` — general function mocking and call recording.

## Invariants
- Tests run in a coroutine, so async tests are possible, but pure logic tests should stay
  synchronous.
- `deftest.util.unload` clears `package.loaded` between suites — needed because a module keeps
  its state for the whole process.

## Common pitfalls
- **A test passes alone and fails in the suite.** Module-level state leaked from the previous
  test. Use a stateless module, or unload it.
- **Timing test flakes.** Real time used instead of `mock.time`.
- **Coverage report empty.** `coverage.enabled` not passed to `deftest.run`.
