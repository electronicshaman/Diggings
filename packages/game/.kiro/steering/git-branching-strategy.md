# Git Branching Strategy

## Mandatory Workflow Rules

### FIRST TASK: Always Create a Branch
Before making ANY changes to the codebase, you MUST:

1. **Check current branch status**
   ```bash
   git status
   git branch
   ```

2. **Create and switch to a new feature branch**
   ```bash
   git checkout -b feature/descriptive-branch-name
   ```

3. **Branch naming conventions:**
   - `feature/` - New features or enhancements
   - `fix/` - Bug fixes
   - `refactor/` - Code refactoring without functional changes
   - `docs/` - Documentation updates
   - `test/` - Test additions or modifications

4. **Branch names should be:**
   - Descriptive and concise
   - Use kebab-case (lowercase with hyphens)
   - Include the type of work being done
   - Examples: `feature/card-effect-system`, `fix/duel-manager-memory-leak`, `refactor/combat-srp`

### LAST TASK: Commit and Push Changes
After the user has approved all changes, you MUST:

1. **Stage all changes**
   ```bash
   git add .
   ```

2. **Commit with a concise, descriptive message**
   ```bash
   git commit -m "Brief description of changes"
   ```

3. **Push the branch to remote**
   ```bash
   git push -u origin branch-name
   ```

## Commit Message Guidelines

### Format
```
Type: Brief description (50 chars max)

Optional longer explanation if needed (wrap at 72 chars)
```

### Types
- **feat:** New feature
- **fix:** Bug fix
- **refactor:** Code refactoring
- **docs:** Documentation changes
- **test:** Test additions/modifications
- **style:** Code formatting changes
- **perf:** Performance improvements

### Examples
```bash
git commit -m "feat: Add card effect resolution system"
git commit -m "fix: Resolve memory leak in DuelManager"
git commit -m "refactor: Split DuelManager into focused components"
git commit -m "docs: Update combat system architecture guide"
```

## Branch Management Rules

### Never Work Directly on Main
- **NEVER** make changes directly on `main` or `master` branch
- Always create a feature branch for any work
- Keep `main` branch stable and deployable

### Branch Lifecycle
1. Create branch from latest `main`
2. Make changes and commit regularly
3. Push branch when ready for review
4. Merge via pull request after approval
5. Delete branch after successful merge

### Before Starting Work
```bash
# Ensure you're on main and up to date
git checkout main
git pull origin main

# Create new branch
git checkout -b feature/your-feature-name
```

### Regular Commits
- Commit early and often with meaningful messages
- Each commit should represent a logical unit of work
- Don't commit broken or incomplete code to shared branches

## Integration with Development Workflow

### When Implementing Specs
- Branch name should match spec directory: `feature/duel-manager-srp-refactor`
- Reference spec in commit messages when relevant
- Ensure all spec requirements are met before final commit

### When Fixing Bugs
- Include issue number if available: `fix/issue-123-card-duplication`
- Describe the problem and solution in commit message
- Test thoroughly before committing

### When Refactoring
- Use `refactor/` prefix for code improvements without functional changes
- Explain the benefits in commit message
- Ensure all tests pass before committing

## Error Recovery

### If You Forget to Create a Branch
```bash
# Stash your changes
git stash

# Create and switch to new branch
git checkout -b feature/your-feature-name

# Apply your changes
git stash pop
```

### If You Need to Switch Branches Mid-Work
```bash
# Commit or stash current work
git add .
git commit -m "WIP: Work in progress"

# Switch to other branch
git checkout other-branch

# Return and continue
git checkout your-feature-branch
```

## Quality Assurance

### Before Final Commit
- [ ] All code compiles without errors
- [ ] All tests pass (if applicable)
- [ ] Code follows project style guidelines
- [ ] No debug code or temporary files included
- [ ] Commit message is clear and descriptive

### Pre-Push Checklist
- [ ] Branch is up to date with main
- [ ] All changes are committed
- [ ] Commit messages follow guidelines
- [ ] No sensitive information in commits
- [ ] Ready for code review

## Collaboration Guidelines

### Pull Request Process
1. Push feature branch to remote
2. Create pull request against `main`
3. Add descriptive title and summary
4. Request review from team members
5. Address feedback and update branch
6. Merge after approval

### Code Review Standards
- Review for functionality, style, and maintainability
- Test changes locally when possible
- Provide constructive feedback
- Approve only when confident in changes

This branching strategy ensures clean version control, proper change tracking, and collaborative development while maintaining code quality and project stability.