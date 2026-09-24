# 007 — Artifact Registry

| Difficulty | Suggested time | Topics |
| --- | --- | --- |
| Advanced | 90 minutes | Directed graphs, dependency resolution, cycle detection, TTL, snapshots |

## Overview

You are building the in-memory core of an artifact registry: the service a build system uses to publish and fetch compiled packages.

An artifact is identified by a package name and a version, written as `name@version`. Every operation receives a `timestamp` in milliseconds. Timestamps never decrease between calls.

The challenge has four levels. Each level builds on the previous one, and everything from earlier levels must keep working.

---

## Level 1 — Publish and fetch

### Tasks

1. **Publish.** Given a `package`, a `version` and a `size_kb`, store the artifact. Publishes are immutable: return `false` if that exact `package@version` already exists, `true` otherwise.
2. **Fetch.** Given a `package` and a `version`, return the artifact's size in kilobytes, or report not found.
3. **List versions.** Given a `package`, return all of its versions, most recently published first. If two versions were published at the same timestamp, the one published later comes first. Return an empty list if the package is unknown.

### Example

| Operation | Result |
| --- | --- |
| At `100`: publish `core@1.0.0`, 500 KB | `true` |
| At `150`: publish `core@1.0.0`, 900 KB | `false` (already exists) |
| At `200`: publish `core@1.1.0`, 640 KB | `true` |
| At `250`: fetch `core@1.1.0` | `640` |
| At `250`: fetch `core@2.0.0` | not found |
| At `300`: list versions of `core` | `1.1.0, 1.0.0` |

---

## Level 2 — Dependencies

Artifacts can depend on other artifacts. Dependencies form a directed graph with no cycles.

### Tasks

1. **Add a dependency.** Given an artifact and a dependency artifact, record that the first depends on the second. Return `false` if either artifact does not exist, or if the new edge would create a cycle (including an artifact depending on itself). Adding an edge that already exists returns `true` and changes nothing.
2. **Resolve the closure.** Given an artifact, return every artifact reachable from it through dependencies, not including itself, as `name@version` strings sorted in ascending lexicographic order. Report not found if the artifact does not exist.
3. **Total size.** Given an artifact, return its size plus the size of every artifact in its closure. Count each artifact once, even if it is reached through several paths. Report not found if the artifact does not exist.

### Example

| Operation | Result |
| --- | --- |
| At `100`: publish `app@1.0.0`, 100 KB | `true` |
| At `100`: publish `core@1.0.0`, 500 KB | `true` |
| At `100`: publish `utils@1.0.0`, 50 KB | `true` |
| At `110`: `app@1.0.0` depends on `core@1.0.0` | `true` |
| At `110`: `app@1.0.0` depends on `utils@1.0.0` | `true` |
| At `110`: `core@1.0.0` depends on `utils@1.0.0` | `true` |
| At `120`: `utils@1.0.0` depends on `app@1.0.0` | `false` (cycle) |
| At `130`: closure of `app@1.0.0` | `core@1.0.0, utils@1.0.0` |
| At `130`: total size of `app@1.0.0` | `650` (`utils` counted once) |

---

## Level 3 — Retention

### Tasks

1. **Publish with a TTL.** Same as publish, plus a `ttl_ms`. The artifact is alive during `[timestamp, timestamp + ttl_ms)` and expires at `timestamp + ttl_ms`. Artifacts published without a TTL never expire.

2. **Ignore expired artifacts.** Every operation from Levels 1 and 2 treats an expired artifact as if it does not exist:
   - fetch reports not found,
   - list versions leaves it out,
   - add dependency returns `false`,
   - closure and total size skip it, and do not follow its dependencies either.

3. **Publish over an expired slot.** An expired `package@version` can be published again. The new artifact starts fresh: no dependencies, and no other artifact depends on it.

4. **Clean up.** Given a `timestamp`, remove every artifact expired at that time, along with its dependency edges. Return the number of artifacts removed.

### Example

| Operation | Result |
| --- | --- |
| At `100`: publish `core@1.0.0`, 500 KB, `ttl_ms = 50` | `true` (alive during `[100, 150)`) |
| At `100`: publish `app@1.0.0`, 100 KB | `true` |
| At `110`: `app@1.0.0` depends on `core@1.0.0` | `true` |
| At `120`: total size of `app@1.0.0` | `600` |
| At `150`: fetch `core@1.0.0` | not found (expired at 150) |
| At `150`: total size of `app@1.0.0` | `100` |
| At `160`: clean up | `1` |
| At `170`: publish `core@1.0.0`, 700 KB | `true` (the slot is free again) |

---

## Level 4 — Snapshots

### Tasks

1. **Take a snapshot.** Given a `timestamp`, capture the full state of the registry: artifacts, sizes, publish order, dependency edges and remaining TTLs. Return a snapshot ID. IDs are `snapshot1`, `snapshot2`, and so on, in the order snapshots are taken.

2. **Restore a snapshot.** Given a `timestamp` and a snapshot ID, replace the whole registry state with the captured one. Return `false` if the snapshot ID is unknown.

Rules:

- An artifact with `r` milliseconds of life left when the snapshot was taken stays alive for `r` milliseconds from the restore's timestamp.
- Artifacts already expired when the snapshot was taken are not restored.
- Artifacts without a TTL are restored without a TTL.
- Snapshots never expire. Restoring a snapshot does not consume it, so it can be restored again later.

### Example

| Operation | Result |
| --- | --- |
| At `100`: publish `core@1.0.0`, 500 KB, `ttl_ms = 100` | `true` (alive until 200) |
| At `150`: take a snapshot | `snapshot1` (`core` has 50 ms left) |
| At `160`: publish `app@1.0.0`, 100 KB | `true` |
| At `210`: fetch `core@1.0.0` | not found (expired) |
| At `300`: restore `snapshot1` | `true` (`core` is alive until 350; `app` is gone) |
| At `305`: fetch `app@1.0.0` | not found |
| At `340`: fetch `core@1.0.0` | `500` |
| At `360`: fetch `core@1.0.0` | not found |
| At `400`: restore `snapshot9` | `false` |

---

## Test data

Test cases for each level are in [`testdata/007-artifact-registry/`](../testdata/007-artifact-registry/). See [`testdata/README.md`](../testdata/README.md) for the file format.

| Level | Operation | Arguments | Result |
| --- | --- | --- | --- |
| 1 | `publish` | `timestamp`, `package`, `version`, `size_kb` | `true` or `false` |
| 1 | `fetch` | `timestamp`, `package`, `version` | size, or `null` |
| 1 | `list_versions` | `timestamp`, `package` | list of versions |
| 2 | `add_dependency` | `timestamp`, `package`, `version`, `dep_package`, `dep_version` | `true` or `false` |
| 2 | `resolve_closure` | `timestamp`, `package`, `version` | list of `name@version`, or `null` |
| 2 | `total_size` | `timestamp`, `package`, `version` | size, or `null` |
| 3 | `publish_with_ttl` | `timestamp`, `package`, `version`, `size_kb`, `ttl_ms` | `true` or `false` |
| 3 | `cleanup` | `timestamp` | number of artifacts removed |
| 4 | `snapshot` | `timestamp` | snapshot ID |
| 4 | `restore` | `timestamp`, `snapshot_id` | `true` or `false` |

## What is evaluated

- **Correctness:** every level works, and earlier levels keep working after later ones are added.
- **Design:** clear separation of concerns and well-chosen data structures.
- **Performance:** graph traversals and state changes stay efficient under many calls per second.

## Going further (optional)

- Accept version ranges in dependencies (for example `core@^1.0.0`) and resolve them to the newest matching version.
- Protect artifacts that others depend on from being removed by cleanup.
- Make snapshots cheap: avoid copying the whole state on every snapshot.
