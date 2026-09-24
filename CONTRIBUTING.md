# Contributing a solution

Solve any challenge from [`challenges/`](challenges/) in any language, then share your solution through a pull request.

## Steps

1. Fork this repository.
2. Create your solution folder:

   ```
   solutions/<github-username>/<challenge-name>/
   ```

   `<challenge-name>` is the challenge file name without `.md`, including its number. For example, a solution to `challenges/001-log-parser.md` goes in `solutions/guiferpa/001-log-parser/`.

3. Add your code, a `README.md` (see the template below) and a `manifest.json` with the command that runs your solution. See [`testdata/README.md`](testdata/README.md) for the manifest and the input/output protocol.
4. Run the tests from the repository root:

   ```sh
   scripts/run-tests.sh solutions/<github-username>/<challenge-name>
   ```

5. Open a pull request with one challenge per pull request.

## Rules

- **Only touch your own folder.** A solution pull request must not change `challenges/`, other people's solutions or any other file.
- **Partial solutions are welcome.** You can submit after finishing only some levels. Say which ones in your `README.md`, and update the same folder later as you finish more.
- **Pass the tests.** `scripts/run-tests.sh` must pass for every level you solved. You can add your own tests too.
- **Any language, any tools.** Explain how to install and run everything in your `README.md`.

## Solution README template

```markdown
# <Challenge name>

- **Language:** <language and version>
- **Levels completed:** 1, 2, 3
- **Time spent:** <how long it took you>

## How to run

<commands to run the solution and the tests>

## Approach

<the data structures you chose and why, trade-offs, what you would improve>
```
