# Card Testing Feedback Template

Use this template to report card testing results. Copy and fill out for each testing session.

## Testing Session Info
- **Date**: [YYYY-MM-DD]
- **Game Version**: [git commit hash or description]
- **Testing Focus**: [What you're specifically testing - balance, new cards, mechanics, etc.]

---

## Card Performance Reports

### Card Name: [Card Name Here]
- **Card Type**: [Gold/Grit/Grog/Gamble]
- **Energy Cost**: [X]
- **Expected Effect**: [What the card should do]

#### ✅ What Works
- [List things that work as intended]

#### ❌ What's Broken
- [List bugs, errors, or completely broken behavior]
- [Include any error messages if available]

#### ⚠️ Balance Issues  
- [Too powerful/weak, feels unfun, etc.]
- [Suggested changes]

#### 🤔 Unclear Behavior
- [Things that work but feel confusing or unexpected]

---

## Gameplay Flow Issues

### Turn System
- **End Turn Button**: ✅ Working / ❌ Broken / ⚠️ Issues
- **Enemy AI**: ✅ Working / ❌ Broken / ⚠️ Issues
- **Turn Counter**: ✅ Working / ❌ Broken / ⚠️ Issues

### Resource Management
- **Health**: ✅ Working / ❌ Broken / ⚠️ Issues
- **Energy**: ✅ Working / ❌ Broken / ⚠️ Issues  
- **Cover**: ✅ Working / ❌ Broken / ⚠️ Issues
- **Sanity**: ✅ Working / ❌ Broken / ⚠️ Issues

### Hand Management
- **Card Drawing**: ✅ Working / ❌ Broken / ⚠️ Issues
- **Card Playing**: ✅ Working / ❌ Broken / ⚠️ Issues
- **Hand Display**: ✅ Working / ❌ Broken / ⚠️ Issues

---

## Debug Tools Test

### Page Up Debug Panel
- **Panel Toggle**: ✅ Working / ❌ Broken
- **Add Random Card**: ✅ Working / ❌ Broken  
- **Add Health (+10)**: ✅ Working / ❌ Broken
- **Add Energy (+10)**: ✅ Working / ❌ Broken
- **Reset Duel**: ✅ Working / ❌ Broken

---

## Priority Issues

### 🚨 Critical (Breaks Game)
1. [Issue that prevents playing]

### 🔥 High Priority (Major Impact)
1. [Issue that significantly affects gameplay]

### 📋 Medium Priority (Polish/Balance)
1. [Issue that affects game feel]

### 💡 Low Priority (Nice to Have)
1. [Quality of life improvements]

---

## Quick Test Results

**Cards Tested**: [X] total
- **Fully Working**: [X] cards
- **Partially Working**: [X] cards  
- **Completely Broken**: [X] cards

**Fun Factor**: [1-10] - How enjoyable was the testing session?

**Most Interesting Discovery**: [What surprised you?]

---

## Raw Notes

[Any additional observations, ideas, or stream-of-consciousness notes]

---

## For Developer (Claude)

**Files to Check**: 
- [ ] [specific script files if you know the issue location]

**Suspected Issues**:
- [ ] [your guess about what might be causing problems]

**Quick Fixes Needed**:
- [ ] [simple changes you'd like made]

**New Features Requested**:
- [ ] [new mechanics or improvements you want]