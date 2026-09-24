# 008 — Map Game Engine

| Difficulty | Suggested time | Topics |
| --- | --- | --- |
| Expert | 120 minutes | Trees, hierarchical scene graphs, traversal, state inheritance |

## Overview

You are building the world-management core of an RPG game. The game map is a tree of zones: realms contain areas, areas contain dungeons, and so on. Entities live inside zones, and zones inherit environmental properties from the zones above them.

The challenge has three levels. Each level builds on the previous one, so solve them in order.

---

## Level 1 — Zone tree

### Tasks

1. **Add a zone.** Given a `zone_id` and a `parent_id`, add the zone as a child of the parent. An empty `parent_id` makes it a top-level zone. There can be many top-level zones.

   Reject the operation if:
   - `zone_id` is empty or already exists, or
   - `parent_id` is not empty and does not exist.

2. **Get the path.** Given a `zone_id`, return the IDs from its top-level zone down to the zone itself, joined by `/`. Report not found if the zone does not exist.

3. **Get the descendants.** Given a `zone_id`, return every zone nested below it, not including the zone itself. Use depth-first pre-order: visit a zone, then each of its children in the order they were added. Report not found if the zone does not exist.

### Example

| Operation | Result |
| --- | --- |
| Add `north_realm` under `""` | added |
| Add `south_realm` under `""` | added |
| Add `forest` under `north_realm` | added |
| Add `dungeon_1` under `north_realm` | added |
| Add `dungeon_2` under `dungeon_1` | added |
| Add `cave` under `forest` | added |
| Add `forest` under `south_realm` | rejected (`forest` already exists) |
| Add `tower` under `castle` | rejected (`castle` does not exist) |
| Path of `dungeon_2` | `north_realm/dungeon_1/dungeon_2` |
| Descendants of `north_realm` | `forest, cave, dungeon_1, dungeon_2` |
| Descendants of `cave` | empty list |

The resulting tree:

```
north_realm
├── forest
│   └── cave
└── dungeon_1
    └── dungeon_2
south_realm
```

---

## Level 2 — Entities and subtree queries

### Tasks

1. **Place an entity.** Given a `zone_id`, an `entity_id` and a positive integer `weight`, place the entity in that zone. Reject the operation if the zone does not exist, the weight is not positive, or an entity with that ID was already placed anywhere in the world.

2. **Query a subtree.** Given a `zone_id` and a `max_weight`, look at every entity in that zone and in all of its descendants. Select as many of them as possible while their total weight stays at or below `max_weight`:
   1. Sort the entities by weight, lightest first. Break ties by `entity_id` in ascending order.
   2. Take entities in that order while the running total stays at or below `max_weight`. Stop at the first entity that does not fit.
   3. Return the selected `entity_id`s sorted in ascending lexicographic order.

   Report not found if the zone does not exist.

### Example

Using the tree from Level 1:

| Operation | Result |
| --- | --- |
| Place `merchant` (weight 10) in `north_realm` | placed |
| Place `wolf` (weight 30) in `forest` | placed |
| Place `bat` (weight 5) in `cave` | placed |
| Place `skeleton` (weight 20) in `dungeon_1` | placed |
| Place `dragon` (weight 100) in `dungeon_2` | placed |
| Place `bat` (weight 1) in `forest` | rejected (`bat` already exists) |
| Query `north_realm` with `max_weight = 50` | `bat, merchant, skeleton` |
| Query `dungeon_1` with `max_weight = 50` | `skeleton` |
| Query `forest` with `max_weight = 4` | empty list |

In the first query, the order by weight is `bat (5)`, `merchant (10)`, `skeleton (20)`, `wolf (30)`, `dragon (100)`. The running total is 5, 15, 35, and adding `wolf` would reach 65, so the selection stops there.

---

## Level 3 — Property inheritance

Zones have environmental properties, such as `temperature` or `lighting`. A zone inherits every property from its ancestors unless it sets its own value.

### Tasks

1. **Set a property.** Given a `zone_id`, a `key` and a `value`, set the property on that zone. Setting the same key again replaces its value. Reject the operation if the zone does not exist.

2. **Get a property.** Given a `zone_id` and a `key`, return the effective value: the zone's own value if it has one, or else the value from the nearest ancestor that has one. Report not found if no zone on the way up to the top level defines the key, or if the zone does not exist.

### Example

Using the tree from Level 1:

| Operation | Result |
| --- | --- |
| Set `lighting = daylight` on `north_realm` | set |
| Set `temperature = mild` on `north_realm` | set |
| Set `lighting = dark` on `dungeon_1` | set |
| Set `temperature = cold` on `cave` | set |
| Set `lighting = dim` on `castle` | rejected (`castle` does not exist) |
| Get `lighting` of `dungeon_2` | `dark` (from `dungeon_1`) |
| Get `temperature` of `dungeon_2` | `mild` (from `north_realm`) |
| Get `lighting` of `cave` | `daylight` (from `north_realm`) |
| Get `temperature` of `cave` | `cold` (its own value) |
| Get `lighting` of `south_realm` | not found |

---

## Going further (optional)

- Move a zone, with its whole subtree, under a new parent. Reject moves that would create a cycle.
- Remove a zone and decide what happens to its children and entities.
- Answer property lookups in constant time, even after properties change high up in the tree.
