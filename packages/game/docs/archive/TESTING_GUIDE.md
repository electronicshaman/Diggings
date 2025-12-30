# Card Testing Prototype Guide

## Quick Start

1. Open Godot 4.5
2. Run the project (F5 or Play button)
3. The game will automatically start with a test duel

## Available Test Cards

### Gold (Attack)
- **Pickaxe Strike** - 1 Energy: Deal 3 damage
- **Dynamite Blast** - 2 Energy: Deal 2 damage 3 times

### Grit (Skill)  
- **Bush Cover** - 1 Energy: Gain 5 defense

### Grog (Power)
- **Pub Brawl** - 2 Energy: Draw 2 cards, Deal 2 damage

### Gamble (Fortune)
- **Strike It Rich** - 1 Energy: Next card has 50% chance to double effects or do nothing

## Test Enemies

- **Claim Jumper** - 30 HP, basic attack pattern
- **Mad Dog Morgan** - 50 HP, escalating damage

## Controls

- **Click cards** in hand to play them
- **End Turn button** to pass turn to enemy
- **Page Up key** to toggle debug panel

## Debug Panel Options

- **Add Random Card** - Adds a random test card to hand
- **Set Health 10** - Sets player health to 10
- **Set Energy 10** - Sets player energy to 10  
- **Reset Duel** - Starts a new test duel

## Game Flow

1. Player starts with 5 cards in hand
2. Each turn player has 3 energy
3. Play cards by clicking them (costs energy)
4. Click "End Turn" when done
5. Enemy attacks automatically
6. Win by reducing enemy health to 0
7. Lose if your health or sanity reaches 0

## What to Test

- Card effect combinations
- Energy management
- Defense vs damage balance
- Card draw mechanics
- Gambling risk/reward
- Turn flow smoothness
- UI responsiveness

## Known Limitations

This is a minimal prototype focused on card mechanics testing:
- No animations
- Basic enemy AI (just damage scaling)
- No sound effects
- Minimal visual polish
- No deck building UI

## Next Steps

Based on testing feedback:
1. Tweak card costs and effects
2. Add more complex enemy patterns
3. Implement status effects
4. Add card animations
5. Create deck builder UI