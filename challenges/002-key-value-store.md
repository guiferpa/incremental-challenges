# 002 — Key-Value Store

| Difficulty | Suggested time | Topics |
| --- | --- | --- |
| Beginner | 60 minutes | Hash maps, stacks, nested transactions, versioning |

## Overview

You are building an in-memory key-value store, the kind of engine that sits behind a cache or a configuration service. Keys and values are strings.

The challenge has three levels. Each level builds on the previous one, so solve them in order.

---

## Level 1 — Basic operations

### Tasks

1. **Set.** Given a `key` and a `value`, store the value. If the key already exists, replace its value.
2. **Get.** Given a `key`, return its value, or report not found.
3. **Delete.** Given a `key`, remove it. Return whether the key existed.
4. **Count.** Given a `value`, return how many keys currently hold exactly that value.

### Example

| Operation | Result |
| --- | --- |
| Set `a = 10` | — |
| Set `b = 10` | — |
| Set `c = 20` | — |
| Get `a` | `10` |
| Count `10` | `2` |
| Delete `b` | `true` |
| Delete `b` | `false` |
| Get `b` | not found |
| Count `10` | `1` |

---

## Level 2 — Nested transactions

### Tasks

1. **Begin.** Open a new transaction. Transactions can be nested: a `begin` inside an open transaction opens an inner one.
2. **Rollback.** Discard every change made in the innermost open transaction and close it. If no transaction is open, report an error.
3. **Commit.** Close the innermost open transaction and keep its changes. If it is nested, its changes become part of the enclosing transaction, and a later rollback of that enclosing transaction discards them too. If it is the outermost one, its changes become permanent. If no transaction is open, report an error.

Rules:

- `get`, `delete` and `count` always see the current state, including changes from open transactions.
- A delete inside a transaction is a change like any other: rolling back brings the key back.

### Example

| Step | Operation | Result |
| --- | --- | --- |
| 1 | Set `a = 10` | — |
| 2 | Begin | — |
| 3 | Set `a = 20` | — |
| 4 | Get `a` | `20` |
| 5 | Begin | — |
| 6 | Delete `a` | `true` |
| 7 | Get `a` | not found |
| 8 | Rollback | — (undoes step 6) |
| 9 | Get `a` | `20` |
| 10 | Commit | — (step 3 is now permanent) |
| 11 | Get `a` | `20` |
| 12 | Rollback | error: no open transaction |
| 13 | Begin | — |
| 14 | Set `b = 20` | — |
| 15 | Count `20` | `2` |
| 16 | Rollback | — |
| 17 | Count `20` | `1` |

---

## Level 3 — Expiration and history

Every operation now also receives a `timestamp` in milliseconds. Timestamps never decrease between calls. Level 3 operations run outside transactions, so you do not need to combine them with Level 2.

### Tasks

1. **Set with TTL.** `set` accepts an optional `ttl_ms`. A key set at `timestamp` with a TTL is alive during `[timestamp, timestamp + ttl_ms)` and behaves as if it does not exist from `timestamp + ttl_ms` on. A key set without a TTL never expires. Setting a key again replaces both its value and its TTL.

2. **Respect expiration.** `get`, `delete` and `count` ignore expired keys. Deleting an expired key returns `false`.

3. **Get at a point in time.** Given a `key` and a past timestamp `at`, return the value that `get` would have returned at `at`, or not found. `at` is never later than the latest timestamp the store has seen. If several operations happened at the same timestamp, the last one wins.

### Example

| Operation | Result |
| --- | --- |
| At `0`: set `a = 1` | — |
| At `10`: set `b = 2` with `ttl_ms = 100` | — (alive during `[10, 110)`) |
| At `50`: get `b` | `2` |
| At `60`: set `a = 3` | — |
| At `120`: get `b` | not found (expired at 110) |
| At `130`: delete `a` | `true` |
| Get `a` at `30` | `1` |
| Get `a` at `60` | `3` |
| Get `a` at `130` | not found |
| Get `b` at `109` | `2` |
| Get `b` at `110` | not found |

---

## Test data

Test cases for each level are in [`testdata/002-key-value-store/`](../testdata/002-key-value-store/). See [`testdata/README.md`](../testdata/README.md) for the file format.

| Level | Operation | Arguments | Result |
| --- | --- | --- | --- |
| 1 | `set` | `key`, `value` | — |
| 1 | `get` | `key` | value, or `null` |
| 1 | `delete` | `key` | `true` or `false` |
| 1 | `count` | `value` | number of keys |
| 2 | `begin` | — | — |
| 2 | `rollback`, `commit` | — | —, or `{"error": "no_transaction"}` |
| 3 | `set` | `timestamp`, `key`, `value`, optional `ttl_ms` | — |
| 3 | `get`, `delete` | `timestamp`, `key` | same as Level 1 |
| 3 | `count` | `timestamp`, `value` | same as Level 1 |
| 3 | `get_at` | `key`, `at` | value, or `null` |

## Going further (optional)

- Combine Level 3 with transactions: which timestamp should a committed change carry in the history?
- Save the store to a file and load it back.
- Limit how much history is kept per key without breaking recent lookups.
