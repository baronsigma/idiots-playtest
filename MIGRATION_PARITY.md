# IDIOTS! Godot ↔ HTML parity tracker

Source reference: the continuous-play HTML **v0.0.7-alpha.6.1** (under reference/ in this repository) and earlier v0.7.3. Do not port the rejected v0.7.1b five-shift or v0.7.2 lab experiments.

This branch contains the alpha.3 foundation and an **alpha.4 engineering parity pass**; it is not full HTML feature parity. Do not merge until the Godot CI smoke test runs and a browser export is played.

| Area | Original HTML | Godot alpha.2 | Godot parity branch |
|---|---|---|---|
| Jimothy / Kram / Bog | yes | yes | retained |
| Continuous roaming combat | yes | short slice | longer (~6.5-minute preliminary curve) |
| Live six-slot wiring and independent circuits | yes | basic | retained; smoke-tested layout |
| Deterministic procedural rider/mount grammar | yes | basic | retained |
| Independent inventions / bees / fire / poison / mushrooms | yes | basic | animated swarms, propagating bounded fire/poison/spores, frost and lightning effects (visual parity still incomplete) |
| Meaningful mid-run loot discovery | yes | missing | **first playable implementation** |
| Two signature-weapon evolutions | yes | missing | **first playable implementation** |
| Local Concern / specialist responses | yes | limited | first archer/flanker logic, further types missing |
| Renown persist across runs | yes | missing | **capped HP/gold meta starters** |
| Full 76-node between-run meta tree | yes | missing | **not yet ported** |
| 18+ elemental parts and special recipes | yes | 8 basic | **20 tagged parts** and 20+ named signatures; remaining recipes procedural, art parity still incomplete |
| Dynamic merchants and events | yes | missing | **not yet ported** |
| Layered high-impact pixel VFX and sprites | yes | minimal | **not yet ported** |
| Crash recovery, mobile polish, journal | yes | missing | **not yet ported** |
| Real balance and browser test coverage | yes (HTML) | limited | Godot CI test added; browser playtest required |

## Migration order after this branch
1. Stabilize the Godot scene, reward-flow transitions, and Web export; CI now runs engine-side effects tests and exports a browser artifact.
2. Finish pixel-art identities, bespoke combination behaviors, invention inspection and discovery journal without changing live wiring UX.
3. Port the 76-node meta tree as **between-run progression**, with limited active pre-run perks.
4. Restore world situations, merchants, weapon mutations, better enemy behaviors and escalating Concern.
5. Art/audio polish, mobile UX, metrics, balance, and a full playable continuous expedition.

## Core invariants
- One invention per explicitly connected component group; separate 2+2+2 / 3+3 / 4+2 circuits work.
- A machine's deterministic grammar result is independent of component enumeration order.
- No always-open shop that lets the player buy every legendary.
- Meta unlocks possibilities; permanent combat stat bonuses remain capped.
- Combat can still kill the player and defeating the Mayor is an actual win.
- Renown is only awarded once when an expedition finishes.
