# Current Cards Reference

Quick reference for what each card should do. Use this to check if cards are working as intended.

## Test Cards Available

### Gold Cards (Attack)
#### **Pickaxe Strike**
- **Cost**: 1 Energy
- **Effect**: Deal 3 damage
- **Expected**: Reduces enemy health by 3 (minus defense)

#### **Dynamite Blast** 
- **Cost**: 2 Energy
- **Effect**: Deal 2 damage 3 times (6 total damage)
- **Expected**: Three separate damage instances, each reduced by defense

### Grit Cards (Skill)
#### **Bush Defense**
- **Cost**: 1 Energy  
- **Effect**: Gain 5 defense
- **Expected**: Adds 5 to player's Defense stat

### Grog Cards (Power)  
#### **Pub Brawl**
- **Cost**: 2 Energy
- **Effect**: Draw 2 cards, Deal 2 damage
- **Expected**: Hand gains 2 cards, enemy takes 2 damage

### Gamble Cards (Fortune)
#### **Strike It Rich**
- **Cost**: 1 Energy
- **Effect**: 50% chance to double all effects on next card OR do nothing
- **Expected**: Sets gambling state, affects next card played

---

## Test Enemies Available

### **Claim Jumper**
- **Health**: 30
- **Behavior**: Basic attacker (should attack each turn)

### **Mad Dog Morgan** 
- **Health**: [Check in-game]
- **Behavior**: [Test to see what it does]

---

## Expected Game Flow

1. **Start Turn**: Draw 1 card (up to 5 in hand)
2. **Player Phase**: Play cards by clicking them
3. **End Turn**: Click "End Turn" button  
4. **Enemy Phase**: Enemy automatically attacks
5. **Next Turn**: Repeat

---

## Debug Controls

- **Page Up**: Toggle debug panel
- **Add Random Card**: Adds one of the 5 test cards to hand
- **Set Health 10**: Adds +10 to current health  
- **Set Energy 10**: Adds +10 to current energy
- **Reset Duel**: Restarts the fight with fresh stats

---

## Known Working Features

✅ **Card clicking** (invisible button workaround)
✅ **Hand display** (cards properly spaced)
✅ **Turn cycling** (End Turn button)
✅ **Basic UI updates** (health, energy display)
✅ **Debug panel** (Page Up toggle)

---

## Testing Priority Order

1. **Basic Functionality**: Can you click cards and end turns?
2. **Simple Effects**: Do Pickaxe Strike and Bush Defense work?
3. **Complex Effects**: Does Dynamite Blast hit 3 times?
4. **Multi-Effect Cards**: Does Pub Brawl draw AND damage?
5. **RNG Effects**: Does Strike It Rich gambling work?
6. **Resource Management**: Do health/energy/defense update correctly?
7. **Enemy AI**: Does the enemy attack and take damage?

---

## Common Issues to Watch For

- **Cards not clickable**: Check if button workaround is working
- **Effects not applying**: Look for error messages in logs
- **UI not updating**: Resources might change but display doesn't
- **Hand management**: Cards not being drawn/discarded properly
- **Turn flow**: Game getting stuck between turns
- **Debug tools**: Panel not showing or buttons not working