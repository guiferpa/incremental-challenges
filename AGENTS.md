# Agent Guidelines

This repository holds coding challenges for study. Challenges are written in English as Markdown files.

## Challenge rules

Every challenge must follow these rules:

1. **No language.** Do not name or assume a programming language. Describe the problem and the expected behavior: inputs, outputs, rules and examples. Never use language-specific signatures, types or code, even if the source material has them.
2. **Estimated time.** State how long the challenge should take to solve (for example, `60 minutes`).
3. **At least 3 levels.** Split the challenge into 3 or more levels (`Level 1`, `Level 2`, `Level 3`, ...). Each level builds on the previous one and has at least one example with its expected output.
4. **Difficulty.** Rate the challenge with one of the difficulties below. The difficulty decides where the challenge goes in the order.

## Difficulty scale

| Difficulty | Typical time | What it asks for |
| --- | --- | --- |
| Beginner | 60 minutes | One core structure (strings, hash maps, stacks) and direct rules. |
| Intermediate | 75 minutes | Several structures working together, or state that changes over time (windows, TTLs, scheduled events). |
| Advanced | 90 minutes | Graphs, heaps or simulations, with features that interact across levels. |
| Expert | 120 minutes | Complex modeling with many rules and edge cases, where the choice of data structures decides performance. |

Within the same difficulty, order challenges by how much they combine: fewer concepts first.

## Layout

- Challenges live in `challenges/NNN-challenge-name.md`. `NNN` is a three-digit prefix that orders challenges from easiest to hardest.
- When a new challenge fits between existing ones, renumber the challenges after it so the order stays correct.
- `README.md` holds the ordered index of challenges. Update it whenever a challenge is added, renamed or renumbered.
- Solutions live in `solutions/<github-username>/<challenge-name>/`.

## Challenge template

Use `challenges/001-log-parser.md` as the reference. Each challenge has:

- A title with its number: `# NNN — Challenge Name`
- A table with difficulty, suggested time and topics
- An overview of the problem
- The levels, each with its tasks, rules and an example
- An optional "Going further" section with extra ideas
