# 001 — Log Parser

| Difficulty | Suggested time | Topics |
| --- | --- | --- |
| Beginner | 60 minutes | String manipulation, pattern matching, parsing, data aggregation |

## Overview

You are building a log parsing engine. It reads raw server log lines, turns them into structured records, and computes operational metrics from them.

The challenge has three levels. Each level builds on the previous one, so solve them in order.

---

## Level 1 — Basic extraction and filtering

Each log line follows this format:

```
[<timestamp>] <LEVEL>: <message>
```

- `timestamp` is an ISO 8601 UTC date-time, such as `2026-06-06T10:00:00Z`.
- `LEVEL` is one of `INFO`, `WARN` or `ERROR`.
- `message` is free text that runs to the end of the line.

### Tasks

1. **Parse a line.** Given one raw line, produce a log entry with three fields:
   - `timestamp`: the time as Unix epoch milliseconds
   - `level`: the log level
   - `message`: the message text

   If the line is malformed, report that it could not be parsed instead of returning an entry. A line is malformed if it does not match the format, has an invalid timestamp, or has a level other than the three above.

2. **Filter by level.** Given a list of entries and a level, return only the entries with that level, in their original order.

### Example

Input:

```
[2026-06-06T10:00:00Z] INFO: Server started
[2026-06-06T10:00:05Z] ERROR: Connection timeout
this line is garbage
[2026-06-06T10:00:07Z] DEBUG: Unknown level
```

Parsing each line:

| Line | Result |
| --- | --- |
| 1 | `{ timestamp: 1780740000000, level: INFO, message: "Server started" }` |
| 2 | `{ timestamp: 1780740005000, level: ERROR, message: "Connection timeout" }` |
| 3 | malformed |
| 4 | malformed (unsupported level) |

Filtering the valid entries by `ERROR` returns only the entry from line 2.

---

## Level 2 — Field extraction and grouping

Messages may contain structured attributes in either of two forms:

- `key=value`: the value ends at the next whitespace or at the end of the message.
- `[key: value]`: the value ends at the closing `]`, so it may contain spaces.

### Tasks

1. **Extract a field.** Given an entry and a field key, return the value of that attribute. If the message does not contain the attribute, report that it was not found.

2. **Group by field.** Given a list of entries and a field key, count how many entries have each distinct value of that field. Skip entries that do not contain the field.

### Example

Input:

```
[2026-06-06T10:00:00Z] ERROR: Request failed status_code=500 path=/api/users
[2026-06-06T10:00:01Z] ERROR: Request failed [status_code: 503] [path: /api/orders]
[2026-06-06T10:00:02Z] ERROR: Request failed status_code=500 path=/api/orders
[2026-06-06T10:00:03Z] WARN: Slow response [user: John Doe]
```

- Extracting `path` from line 2 returns `/api/orders`.
- Extracting `user` from line 4 returns `John Doe`.
- Extracting `status_code` from line 4 returns not found.
- Grouping all entries by `status_code` returns:

  ```
  500 -> 2
  503 -> 1
  ```

---

## Level 3 — Session correlation and metrics

Some entries carry a `session_id` attribute, in either form from Level 2. Use it to correlate entries that belong to the same session.

### Task

**Analyze sessions.** Given a list of entries, produce one summary per session with:

- `session_id`: the session identifier
- `duration_ms`: the time between the session's earliest and latest entries, in milliseconds (`0` if the session has a single entry)
- `error_count`: the number of `ERROR` entries in that session

Rules:

- Ignore entries without a `session_id`.
- Entries may arrive in any order. Do not assume they are sorted by timestamp.
- Sort the summaries by `duration_ms`, longest first. Break ties by `session_id` in ascending order.

### Example

Input:

```
[2026-06-06T10:00:00Z] INFO: Login session_id=abc
[2026-06-06T10:00:02Z] INFO: Login session_id=xyz
[2026-06-06T10:00:03Z] ERROR: Payment declined session_id=abc
[2026-06-06T10:00:04Z] INFO: Health check ok
[2026-06-06T10:00:10Z] ERROR: Timeout [session_id: abc]
[2026-06-06T10:00:01Z] WARN: Retrying session_id=xyz
[2026-06-06T10:00:05Z] INFO: Logout session_id=qwe
```

Output:

| session_id | duration_ms | error_count |
| --- | --- | --- |
| abc | 10000 | 2 |
| xyz | 1000 | 0 |
| qwe | 0 | 0 |

---

## Going further (optional)

- Treat malformed lines as data: count how many were skipped and why.
- Process a very large log file by streaming it, without loading it all into memory.
- Accept log lines from several sources at once and merge them in timestamp order.
