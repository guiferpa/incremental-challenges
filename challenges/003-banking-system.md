# 003 — Banking System

| Difficulty | Suggested time | Topics |
| --- | --- | --- |
| Intermediate | 75 minutes | Data modeling, sorting with tie-breaks, scheduled events |

## Overview

You are building the in-memory core of a simple banking system. It manages accounts, moves money between them, ranks customers by spending and pays cashback over time.

Every operation receives a `timestamp` in milliseconds. Timestamps strictly increase between calls. Amounts are positive integers.

The challenge has three levels. Each level builds on the previous one, so solve them in order.

---

## Level 1 — Accounts and transfers

### Tasks

1. **Create an account.** Given an `account_id`, create an account with balance `0`. Return `false` if the account already exists, `true` otherwise.

2. **Deposit.** Given an `account_id` and an `amount`, add the amount to the account and return the new balance. Report not found if the account does not exist.

3. **Transfer.** Given a `source_id`, a `target_id` and an `amount`, move the money and return the source's new balance. The transfer fails, and nothing changes, if:
   - either account does not exist,
   - the source and the target are the same account, or
   - the source's balance is lower than the amount.

### Example

| Operation | Result |
| --- | --- |
| At `1`: create `A` | `true` |
| At `2`: create `B` | `true` |
| At `3`: create `A` | `false` |
| At `4`: deposit `1000` to `A` | `1000` |
| At `5`: deposit `10` to `C` | not found |
| At `6`: transfer `300` from `A` to `B` | `700` |
| At `7`: transfer `500` from `B` to `A` | fails (`B` has only `300`) |
| At `8`: transfer `10` from `A` to `A` | fails (same account) |

---

## Level 2 — Top spenders

### Task

**Rank the top spenders.** Given `n`, return the `n` accounts with the highest total outgoing amount, formatted as `account_id(total)`. The outgoing total is the sum of every successful transfer the account sent.

- Sort by outgoing total, highest first. Break ties by `account_id` in ascending order.
- Accounts that never sent money count with a total of `0`.
- If there are fewer than `n` accounts, return all of them.

### Example

Continuing from Level 1:

| Operation | Result |
| --- | --- |
| At `9`: create `C` | `true` |
| At `10`: deposit `200` to `B` | `500` |
| At `11`: transfer `400` from `B` to `C` | `100` |
| At `12`: top `3` spenders | `B(400), A(300), C(0)` |
| At `13`: top `2` spenders | `B(400), A(300)` |

---

## Level 3 — Payments with cashback

### Tasks

1. **Pay.** Given an `account_id` and an `amount`, withdraw the amount from the account and return a payment ID. Payment IDs are `payment1`, `payment2`, and so on, numbered in the order payments are made across the whole system. The payment fails if the account does not exist or the balance is lower than the amount.

   Each payment earns a cashback of 2% of the amount, rounded down. The cashback is credited to the account exactly 24 hours (`86400000` ms) after the payment. Payments count toward the account's outgoing total from Level 2. Cashback does not reduce it.

2. **Get the payment status.** Given an `account_id` and a `payment_id`, return `IN_PROGRESS` if the cashback has not been credited yet, or `CASHBACK_RECEIVED` if it has. Report not found if the account does not exist or the payment does not belong to that account.

Rules:

- Before handling any operation, credit every cashback due at or before its timestamp.
- If several cashbacks are due at the same time, credit them in the order the payments were made.

### Example

Continuing from Level 2. `A` has a balance of `700`.

| Operation | Result |
| --- | --- |
| At `20`: `A` pays `250` | `payment1` (`A` now has `450`; cashback `5` due at `86400020`) |
| At `30`: status of `payment1` for `A` | `IN_PROGRESS` |
| At `40`: status of `payment1` for `B` | not found |
| At `86400020`: deposit `100` to `A` | `555` (cashback `5` is credited first) |
| At `86400021`: status of `payment1` for `A` | `CASHBACK_RECEIVED` |
| At `86400022`: top `3` spenders | `A(550), B(400), C(0)` |

---

## Going further (optional)

- Merge two accounts into one, keeping balances, outgoing totals and pending cashbacks.
- Return an account's balance at any past timestamp.
- Schedule payments that run in the future and can be cancelled before they run.
