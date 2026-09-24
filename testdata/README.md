# Test data

Language-neutral test cases for every challenge. Run them against your solution with `scripts/run-tests.sh`, in any language.

## Running the tests

1. Add a `manifest.json` to your solution folder with the command that runs your program:

   ```json
   {
     "build": "go build -o .bin/solution .",
     "command": "./.bin/solution"
   }
   ```

   `build` is optional and runs once before the tests. `command` runs once per case, from inside your solution folder. Both are shell commands, so any language works: `python3 main.py`, `node index.js`, `cargo run -q` and so on.

2. Run the tests from the repository root. You need [`jq`](https://jqlang.org/download/) installed.

   ```sh
   scripts/run-tests.sh solutions/<github-username>/<challenge-name>      # every level
   scripts/run-tests.sh solutions/<github-username>/<challenge-name> 1    # only level 1
   ```

   The script prints `PASS` or `FAIL` for each case, with the expected and actual values of every wrong result. It exits with `0` when every case passes and `1` otherwise.

## Protocol

For each case, the runner starts your program once and talks to it through standard input and output:

- **Input:** one JSON object per line, `{"op": "<operation>", "args": {...}}`, in the order of the case's `operations`. When the case has a `setup`, the first line is `{"op": "setup", "args": {...setup}}`.
- **Output:** exactly one line of JSON per input line, with the operation's result. Print `null` for operations that return nothing, including `setup`.
- **Logs:** write any debug output to standard error. Standard output must contain only the results.
- **Errors:** exit with a non-zero status if something goes wrong, such as an unknown operation. The runner shows the last lines of standard error.

Each case runs in a new process, so every case starts from an empty state.

Example for `002-key-value-store`, level 1:

```
stdin                                          stdout
{"op":"set","args":{"key":"a","value":"10"}}   null
{"op":"get","args":{"key":"a"}}                "10"
{"op":"delete","args":{"key":"b"}}             false
```

## Layout

```
testdata/<challenge-name>/level-<N>.json
```

Each challenge's `## Test data` section lists its operations, their arguments and what they return.

## File format

```json
{
  "challenge": "005-lru-cache",
  "level": 1,
  "cases": [
    {
      "name": "spec example",
      "setup": {"capacity": 2},
      "operations": [
        {"op": "put", "args": {"key": "a", "value": 1}},
        {"op": "get", "args": {"key": "a"}, "expected": 1}
      ]
    }
  ]
}
```

- **`cases`:** each case is independent. Start every case from a new, empty instance.
- **`setup`:** optional values needed to create the instance, such as a capacity. The runner sends it as a `setup` operation before the others.
- **`operations`:** run them in order, calling the operation named by `op` with the named `args`.
- **`expected`:** compare it with what the operation returned. When `expected` is missing, the operation returns nothing and you only need to run it.

## Conventions

| Value in `expected` | Meaning |
| --- | --- |
| `null` | Not found, empty, failed or rejected, for operations that otherwise return a value |
| `true` / `false` | The result of operations that succeed or fail |
| `{"error": "<reason>"}` | The operation reported an error |
| a list | The exact result, in order |
| an object | Compare keys and values; key order does not matter |

Operation and argument names use `snake_case`. Rename them to fit your language as you like.

The first case of every level is the example from the challenge text. The other cases cover edge cases.
