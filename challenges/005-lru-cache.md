# 005 — LRU Cache

| Difficulty | Suggested time | Topics |
| --- | --- | --- |
| Intermediate | 75 minutes | Hash maps, doubly linked lists, eviction policies |

## Overview

You are building an in-memory cache with a limited capacity. When the cache is full, it evicts the least recently used (LRU) item to make room for new ones.

The challenge has three levels. Each level builds on the previous one, so solve them in order.

---

## Level 1 — LRU eviction

The cache is created with a `capacity`: the maximum number of items it holds.

### Tasks

1. **Get.** Given a `key`, return its value, or report not found. A successful get marks the item as the most recently used.
2. **Put.** Given a `key` and a `value`, insert the item or update its value, and mark it as the most recently used. If this makes the cache hold more than `capacity` items, evict the least recently used one.

Both operations must run in constant time on average.

### Example

`capacity = 2`:

| Operation | Result | Items, least to most recently used |
| --- | --- | --- |
| Put `a = 1` | — | `a` |
| Put `b = 2` | — | `a, b` |
| Get `a` | `1` | `b, a` |
| Put `c = 3` | — (evicts `b`) | `a, c` |
| Get `b` | not found | `a, c` |
| Put `a = 10` | — | `c, a` |
| Put `d = 4` | — (evicts `c`) | `a, d` |
| Get `c` | not found | `a, d` |
| Get `a` | `10` | `d, a` |
| Get `d` | `4` | `a, d` |

---

## Level 2 — Expiration

Every operation now also receives a `timestamp` in milliseconds. Timestamps never decrease between calls.

### Tasks

1. **Put with TTL.** `put` accepts an optional `ttl_ms`. An item put at `timestamp` with a TTL expires at `timestamp + ttl_ms`. An item without a TTL never expires. Putting an existing key replaces both its value and its TTL.
2. **Respect expiration.** From its expiration time on, an item behaves as if it does not exist: `get` reports not found.

Rules:

- `get` does not extend an item's TTL.
- When a `put` needs room, first remove every expired item. Only if the cache is still full, evict the least recently used item.

### Example

`capacity = 2`:

| Operation | Result |
| --- | --- |
| At `0`: put `a = 1` with `ttl_ms = 100` | — |
| At `10`: put `b = 2` | — |
| At `50`: get `a` | `1` (`a` is now the most recently used) |
| At `120`: put `c = 3` | — (`a` expired at 100 and is removed, so `b` stays) |
| At `130`: get `b` | `2` |
| At `130`: get `a` | not found |

Without expiration, putting `c` would have evicted `b`, since `b` was the least recently used.

---

## Level 3 — Items with sizes

Items now have different sizes. The `capacity` becomes the maximum total size of all items in the cache.

### Tasks

**Put with a size.** `put` also receives a positive integer `size`. Then:

1. If `size` is larger than `capacity`, reject the put and leave the cache unchanged.
2. If the key already exists, remove its old version first.
3. While the new item does not fit, free space: remove expired items first, then evict the least recently used items one by one.
4. Insert the item as the most recently used.

### Example

`capacity = 10`, no TTLs:

| Operation | Result | Items, least to most recently used (size) | Used |
| --- | --- | --- | --- |
| Put `a = 1`, size 4 | — | `a(4)` | 4 |
| Put `b = 2`, size 3 | — | `a(4), b(3)` | 7 |
| Put `c = 3`, size 2 | — | `a(4), b(3), c(2)` | 9 |
| Get `a` | `1` | `b(3), c(2), a(4)` | 9 |
| Put `d = 4`, size 5 | — (evicts `b`, then `c`) | `a(4), d(5)` | 9 |
| Put `e = 5`, size 11 | rejected | `a(4), d(5)` | 9 |
| Put `a = 6`, size 7 | — (old `a` removed, then evicts `d`) | `a(7)` | 7 |

---

## Going further (optional)

- Make the cache safe to use from many concurrent callers.
- Add hit and miss counters and report the hit rate.
- Implement an LFU (least frequently used) policy and compare it with LRU.
