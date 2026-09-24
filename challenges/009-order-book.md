# 009 — Order Book

| Difficulty | Suggested time | Topics |
| --- | --- | --- |
| Expert | 120 minutes | Heaps, ordered structures, matching engines, edge cases |

## Overview

You are building the matching engine of a stock exchange. It keeps an order book of buy orders (bids) and sell orders (asks) for a single stock, and it matches them into trades.

Order IDs are unique strings. Prices and quantities are positive integers.

The challenge has three levels. Each level builds on the previous one, so solve them in order.

---

## Level 1 — The book

### Tasks

1. **Place a limit order.** Given an `order_id`, a side (`BUY` or `SELL`), a `price` and a `quantity`, add the order to the book. Reject it if an order with that ID was ever placed before. In this level, assume orders never cross: every buy price is lower than every sell price.

   Return the list of trades the order caused, which is always empty in this level (Level 2 fills it), or report that the order was rejected.

2. **Best bid.** Return the highest buy price and the total quantity of all buy orders at that price. Report that the side is empty if there are no buy orders.
3. **Best ask.** Return the lowest sell price and the total quantity of all sell orders at that price. Report that the side is empty if there are no sell orders.

### Example

| Operation | Result |
| --- | --- |
| Place `1`: BUY 10 at 100 | no trades |
| Place `2`: BUY 5 at 101 | no trades |
| Place `3`: BUY 7 at 101 | no trades |
| Place `4`: SELL 3 at 105 | no trades |
| Place `5`: SELL 4 at 103 | no trades |
| Place `1`: SELL 2 at 110 | rejected (`1` already exists) |
| Best bid | `101` with quantity `12` |
| Best ask | `103` with quantity `4` |

---

## Level 2 — Matching

Orders can now cross. When a new order arrives, match it against the other side of the book before it rests.

### Task

**Place a limit order with matching.** Return the list of trades it caused. Each trade has the buy order ID, the sell order ID, the price and the quantity.

Rules:

- A new buy order matches sell orders priced at or below its price. A new sell order matches buy orders priced at or above its price.
- Match the best price first: the lowest ask for a buy, the highest bid for a sell. At the same price, match the oldest order first.
- Every trade happens at the price of the order that was already in the book.
- An order can be partially filled. Keep matching until the new order is filled or nothing else crosses. Any quantity left rests in the book.
- A resting order that is fully filled leaves the book.

### Example

Starting with an empty book:

| Operation | Trades |
| --- | --- |
| Place `S1`: SELL 5 at 101 | none |
| Place `S2`: SELL 3 at 100 | none |
| Place `S3`: SELL 4 at 101 | none |
| Place `B1`: BUY 2 at 99 | none |
| Place `B2`: BUY 10 at 101 | `B2/S2` 3 at 100, `B2/S1` 5 at 101, `B2/S3` 2 at 101 |
| Best ask | `101` with quantity `2` (what is left of `S3`) |
| Best bid | `99` with quantity `2` |
| Place `S4`: SELL 5 at 98 | `B1/S4` 2 at 99 |
| Best ask | `98` with quantity `3` (what is left of `S4`) |

`B2` fills `S2` first because it has the best price, then `S1` before `S3` because `S1` is older. The `S4` trade happens at 99, the price of the resting order `B1`.

---

## Level 3 — Cancellations, market orders and depth

### Tasks

1. **Cancel an order.** Given an `order_id`, remove what is left of that order from the book. Return `false` if the order is not in the book anymore, or never was.
2. **Place a market order.** Given an `order_id`, a side and a `quantity`, match it at any price, following the same rules as Level 2. A market order never rests: any quantity left unfilled is discarded. Return the trades.
3. **Market depth.** Given a side and `n`, return up to `n` price levels on that side, best price first, each with its total quantity.

Market orders share the same ID space as limit orders: reject a market order whose ID was ever used before.

### Example

Continuing from Level 2. The book has no bids, and asks `S4` 3 at 98 and `S3` 2 at 101.

| Operation | Result |
| --- | --- |
| Place `S5`: SELL 6 at 101 | no trades |
| Depth of SELL, 5 levels | `98: 3`, `101: 8` |
| Cancel `S3` | `true` |
| Depth of SELL, 5 levels | `98: 3`, `101: 6` |
| Cancel `S3` | `false` (already cancelled) |
| Cancel `B1` | `false` (already filled) |
| Market `M1`: BUY 5 | `M1/S4` 3 at 98, `M1/S5` 2 at 101 |
| Market `M2`: BUY 10 | `M2/S5` 4 at 101 (the other 6 are discarded) |
| Best ask | the side is empty |

---

## Test data

Test cases for each level are in [`testdata/009-order-book/`](../testdata/009-order-book/). See [`testdata/README.md`](../testdata/README.md) for the file format.

| Level | Operation | Arguments | Result |
| --- | --- | --- | --- |
| 1 | `place_limit_order` | `order_id`, `side`, `price`, `quantity` | list of trades, or `null` if rejected |
| 1 | `best_bid`, `best_ask` | — | `{price, quantity}`, or `null` |
| 3 | `cancel_order` | `order_id` | `true` or `false` |
| 3 | `place_market_order` | `order_id`, `side`, `quantity` | list of trades, or `null` if rejected |
| 3 | `market_depth` | `side`, `n` | list of `{price, quantity}` |

A trade is `{buy_order_id, sell_order_id, price, quantity}`.

## Going further (optional)

- Support several stocks, each with its own book.
- Add orders that must fill completely right away or be discarded (fill-or-kill).
- Measure how many orders per second your engine handles and find the bottleneck.
