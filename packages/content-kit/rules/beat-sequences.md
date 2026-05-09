# Beat Sequence Templates

Reusable beat structures referenced by node-type and act. Used as scaffolding for the Beat Outliner stage.

A beat sequence is a named ordered list of `(role, intent, required)` tuples. Sequences have weights (1–10) for selection probability, optional act constraints, and required tags.

## Sequence record shape

```yaml
sequenceKey: "combat_basic_setup_escalation_resolve"
nodeType: combat            # combat | choice | trade | rest | passage | state_check | transition
weight: 5                   # 1–10, selection bias
actConstraints:
  acts: [1, 2]              # null = any act
requiredTags: ["wildlife"]  # selection requires these tags on target node
beatStructure:
  - role: setup
    intent: "Introduce threat and environment"
    required: true
  - role: escalation
    intent: "Stakes raised, retreat impossible"
    required: true
  - role: consequence
    intent: "Resolution beat — victory or fall"
    required: true
  - role: button
    intent: "Transition prompt"
    required: false
```

## Beat role catalog

| Key | Display | Core? | Description |
|-----|---------|:----:|------------|
| setup        | Setup        | ✓ | Environmental context, character/threat introduction |
| escalation   | Escalation   | ✓ | Tension increases, stakes raised |
| reveal       | Reveal       | ✓ | Information disclosed, twist revealed |
| choice       | Choice       | ✓ | Player decision point |
| consequence  | Consequence  | ✓ | Result of action/choice |
| button       | Button       | ✓ | Final beat, transition prompt |
| tension      | Tension      |   | Sustained unease, slow dread |
| relief       | Relief       |   | Brief respite, false calm |
| foreshadow   | Foreshadow   |   | Hint at future events |
| reflection   | Reflection   |   | Character/player processing moment |

## Selection rules
- Filter sequences by `nodeType` matching target node
- Filter by act inclusion in `actConstraints.acts` (or any if null)
- Filter to those whose `requiredTags` are subset of target node tags
- Weighted random pick across remaining candidates
- Lower weight = rarer; weight 1 ≈ 10× rarer than weight 10

## Per-node-type guidance
- **combat** — typically setup → escalation → consequence → button (3–4 beats)
- **choice** — setup → reveal → choice → consequence (4 beats; choice required)
- **rest** — setup → tension or relief → reflection → button (3 beats)
- **passage** — setup → foreshadow → button (2–3 beats; minimal)
- **state_check** — setup → reveal → consequence (3 beats; branch text in consequence)
- **trade** — setup → choice → button (haggling implicit)
- **transition** — setup → reveal → reflection → button (act change resonance)
