# 004 — Rate Limiter

| Difficulty | Suggested time | Topics |
| --- | --- | --- |
| Intermediate | 75 minutes | Hash maps, time windows, sliding windows, state cleanup |

## Overview

You are building the in-memory core of an API rate limiter. It decides whether each incoming client request is allowed or throttled, based on a request limit and a time window.

All timestamps are integers in milliseconds. Requests arrive in non-decreasing timestamp order.

The challenge has three levels. Each level builds on the previous one, so solve them in order.

---

## Level 1 — Fixed window counter

Time is split into fixed windows of `window_ms` milliseconds, aligned to zero: `[0, window_ms)`, `[window_ms, 2 × window_ms)`, and so on. A request at `timestamp` belongs to the window that starts at `floor(timestamp / window_ms) × window_ms`.

### Task

**Allow a request.** Given a `timestamp`, a `client_id`, a `limit` and a `window_ms`, decide whether the request is allowed:

- Allow it if the client has made fewer than `limit` allowed requests in the current window. The request then counts toward that window.
- Otherwise reject it. Rejected requests do not count toward the limit.

Each client has its own counter. You may assume a client is always called with the same `limit` and `window_ms`.

### Example

`limit = 2`, `window_ms = 1000`:

| timestamp | client | result | why |
| --- | --- | --- | --- |
| 0 | A | allowed | 1st request in window `[0, 1000)` |
| 500 | A | allowed | 2nd request in window `[0, 1000)` |
| 999 | A | rejected | limit reached in window `[0, 1000)` |
| 1000 | A | allowed | new window `[1000, 2000)` |
| 1200 | B | allowed | B has its own counter |

---

## Level 2 — Sliding window log

Fixed windows let a client send up to twice the limit around a window boundary. A sliding window fixes that.

### Task

**Allow a request with a sliding window.** Same inputs as Level 1. For each client, keep a log of the timestamps of its allowed requests:

1. Remove from the log every timestamp outside `[timestamp − window_ms, timestamp]`. Both ends are inclusive.
2. Allow the request if the log has fewer than `limit` entries, and add `timestamp` to the log.
3. Otherwise reject it. Rejected requests are not added to the log.

The sliding window keeps its own state, separate from the fixed window counters of Level 1.

### Example

`limit = 2`, `window_ms = 1000`:

| timestamp | client | log before the decision | result |
| --- | --- | --- | --- |
| 0 | A | `[]` | allowed |
| 500 | A | `[0]` | allowed |
| 999 | A | `[0, 500]` | rejected |
| 1000 | A | `[0, 500]` (0 is still inside `[0, 1000]`) | rejected |
| 1001 | A | `[500]` (0 was removed) | allowed |
| 1500 | A | `[500, 1001]` | rejected |

Compare with Level 1: at `timestamp = 1000`, the fixed window allows the request but the sliding window rejects it.

---

## Level 3 — Client tiers and cleanup

### Tasks

1. **Set a tier.** Given a `client_id`, a `limit` and a `window_ms`, store a custom limit for that client. From then on, requests from that client use the tier's `limit` and `window_ms` instead of the values passed with the request, in both the fixed and sliding window strategies. Setting a tier again replaces the previous one.

2. **Clean up expired state.** Given a `timestamp`, remove the stored request history of every client whose history can no longer affect any future decision. Return the number of clients removed.

   A client's history is expired when all of the following are true:
   - Its fixed window, if any, has ended: `window_start + window_ms <= timestamp`.
   - Its sliding window log, if any, has no entries inside `[timestamp − window_ms, timestamp]`.

   Use the client's tier window if it has one, or the window from its most recent request otherwise. Tiers are configuration, not history, so cleanup never removes them.

### Example

Using the sliding window strategy:

| Step | Operation | Result |
| --- | --- | --- |
| 1 | Set tier for A: `limit = 1`, `window_ms = 1000` | — |
| 2 | Request at `0` from A, with `limit = 10`, `window_ms = 60000` | allowed (tier applies: limit 1) |
| 3 | Request at `100` from A, with `limit = 10`, `window_ms = 60000` | rejected (tier limit reached) |
| 4 | Request at `0` from B, with `limit = 10`, `window_ms = 1000` | allowed |
| 5 | Request at `1200` from C, with `limit = 10`, `window_ms = 1000` | allowed |
| 6 | Clean up at `1500` | `2` (A and B are expired; C's request at 1200 is still inside `[500, 1500]`) |
| 7 | Request at `1600` from A, with `limit = 10`, `window_ms = 60000` | allowed (history is gone, the tier is kept) |

---

## Going further (optional)

- Make the rate limiter safe to use from many concurrent requests at once.
- Add a token bucket strategy and compare its behavior with the two windows.
- Reduce the memory used by the sliding window log for clients with a very high limit.
