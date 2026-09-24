# 006 — Task Scheduler

| Difficulty | Suggested time | Topics |
| --- | --- | --- |
| Advanced | 90 minutes | Priority queues (heaps), dependency ordering, simulation |

## Overview

You are building the core of a task scheduler, like the one inside a CI system or a job queue. It decides which task runs next based on priority, dependencies between tasks and the number of available workers.

The challenge has three levels. Each level builds on the previous one, so solve them in order.

---

## Level 1 — Priority queue

### Tasks

1. **Add a task.** Given a `task_id` and an integer `priority`, add the task to the queue. Reject the operation if a task with that ID was ever added before.
2. **Next task.** Remove and return the task with the highest priority. Break ties by the order the tasks were added, earliest first. Report that the queue is empty if there is no task.

### Example

| Operation | Result |
| --- | --- |
| Add `a` with priority `2` | added |
| Add `b` with priority `5` | added |
| Add `c` with priority `5` | added |
| Add `d` with priority `1` | added |
| Add `a` with priority `9` | rejected (`a` already exists) |
| Next | `b` |
| Next | `c` |
| Next | `a` |
| Next | `d` |
| Next | empty |

---

## Level 2 — Dependencies

Tasks can now depend on other tasks. A task is **ready** once every task it depends on is completed.

### Tasks

1. **Add a task with dependencies.** `add` accepts an optional list of task IDs the new task depends on. Reject the operation if any of them was never added. Since dependencies must already exist, cycles cannot happen.
2. **Next task.** Return the highest priority task among the **ready** ones, with the same tie-break as Level 1. The returned task is now running. Report that no task is ready if there is none, even if tasks are still waiting.
3. **Complete a task.** Given a `task_id`, mark a running task as completed. Return `false` if the task is not running.

### Example

| Operation | Result |
| --- | --- |
| Add `a` with priority `1` | added |
| Add `b` with priority `5`, depends on `a` | added |
| Add `c` with priority `3` | added |
| Add `d` with priority `2`, depends on `x` | rejected (`x` does not exist) |
| Next | `c` (`b` is not ready) |
| Next | `a` |
| Next | no task is ready (`b` waits for `a`) |
| Complete `b` | `false` (`b` is not running) |
| Complete `a` | `true` |
| Next | `b` |

---

## Level 3 — Parallel workers

### Task

**Simulate a run.** Given a list of tasks, each with an ID, a priority, a positive integer `duration` and a list of dependencies, and a number of identical `workers`, simulate the run starting at time `0`. Return the time when the last task finishes and the start time of each task.

Rules:

- A worker runs one task at a time, from start to finish.
- At each point in time, first complete every task that finishes at that time. Then give ready tasks to free workers, using the same order as Level 2.
- A task that starts at time `t` finishes at `t + duration`.
- The list order is the order tasks were added, and it is used to break priority ties. Dependencies always refer to tasks earlier in the list.

### Example

`workers = 2`:

| Task | Priority | Duration | Depends on |
| --- | --- | --- | --- |
| `a` | 1 | 3 | — |
| `b` | 5 | 2 | — |
| `c` | 4 | 4 | `b` |
| `d` | 2 | 1 | `a`, `b` |
| `e` | 3 | 2 | — |

Timeline:

| Time | What happens |
| --- | --- |
| 0 | Ready: `a`, `b`, `e`. Start `b` and `e`. |
| 2 | `b` and `e` finish. Ready: `a`, `c`. Start `c` and `a`. |
| 5 | `a` finishes. Ready: `d`. Start `d`. |
| 6 | `c` and `d` finish. |

Result: total time `6`. Start times: `a = 2`, `b = 0`, `c = 2`, `d = 5`, `e = 0`.

---

## Test data

Test cases for each level are in [`testdata/006-task-scheduler/`](../testdata/006-task-scheduler/). See [`testdata/README.md`](../testdata/README.md) for the file format.

| Level | Operation | Arguments | Result |
| --- | --- | --- | --- |
| 1 | `add_task` | `task_id`, `priority` | `true` or `false` |
| 1 | `next_task` | — | task ID, or `null` |
| 2 | `add_task` | `task_id`, `priority`, optional `depends_on` | `true` or `false` |
| 2 | `complete_task` | `task_id` | `true` or `false` |
| 3 | `simulate` | `workers`, `tasks` (each with `task_id`, `priority`, `duration`, `depends_on`) | `{total_time, start_times}` |

## Going further (optional)

- Allow tasks to be added in any order and detect dependency cycles.
- Retry a failed task up to N times, with a delay between attempts.
- Find the critical path: the chain of tasks that sets the minimum total time with unlimited workers.
