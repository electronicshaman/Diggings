# Requirements Document

## Introduction

The game has successfully migrated from a legacy card-specific effect system to a modern generic GameEffect system. However, the migration has left behind redundant code, legacy adapters, and inconsistent usage patterns that need to be cleaned up to optimize the codebase and reduce confusion.

## Glossary

- **GameEffect**: The new generic effect system that handles effects from any source (cards, encounters, curios, etc.)
- **CardEffects**: The legacy card-specific effect processing system that should be phased out
- **Effect_Wrapper**: Legacy wrapper classes that bridge old and new systems
- **Legacy_Adapter**: Temporary adapter classes used during migration
- **Effect_Processor**: The centralized system for processing GameEffects
- **Codebase**: The entire game project's source code

## Requirements

### Requirement 1: Remove Legacy Card Effect System

**User Story:** As a developer, I want to remove the legacy CardEffects system, so that the codebase uses only the modern GameEffect architecture.

#### Acceptance Criteria

1. WHEN the legacy CardEffects class is removed, THE System SHALL continue to process card effects through the GameEffect system
2. WHEN card effect processing occurs, THE System SHALL use only GameEffect-based processing methods
3. WHEN legacy CardEffects references are removed, THE System SHALL maintain all existing card functionality
4. THE System SHALL remove all unused CardEffects methods and dependencies

### Requirement 2: Eliminate Redundant Wrapper Classes

**User Story:** As a developer, I want to remove unnecessary wrapper classes, so that the effect system has a cleaner architecture without redundant abstraction layers.

#### Acceptance Criteria

1. WHEN wrapper classes are evaluated, THE System SHALL identify which wrappers are no longer needed
2. WHEN redundant wrappers are removed, THE System SHALL maintain all existing functionality
3. WHEN effect processing occurs, THE System SHALL use direct GameEffect instances instead of wrapped effects
4. THE System SHALL preserve only essential wrapper classes that serve a clear purpose

### Requirement 3: Remove Migration Adapters

**User Story:** As a developer, I want to remove temporary migration adapters, so that the codebase no longer contains transitional code.

#### Acceptance Criteria

1. WHEN legacy adapters are identified, THE System SHALL verify they are no longer needed
2. WHEN adapters are removed, THE System SHALL maintain compatibility with existing data files
3. WHEN effect processing occurs, THE System SHALL use native GameEffect processing without adapter layers
4. THE System SHALL remove all legacy_*_adapter.gd files that are no longer required

### Requirement 4: Consolidate Effect Processing

**User Story:** As a developer, I want a single, consistent effect processing system, so that all effects are handled uniformly regardless of their source.

#### Acceptance Criteria

1. WHEN effects are processed from any source, THE System SHALL use the same GameEffect processing pipeline
2. WHEN card effects are applied, THE System SHALL use the same methods as encounter and curio effects
3. WHEN effect results are generated, THE System SHALL use consistent EffectResult structures
4. THE System SHALL have one centralized effect processor for all effect types

### Requirement 5: Optimize Effect System Performance

**User Story:** As a developer, I want an optimized effect system, so that effect processing is efficient and doesn't impact game performance.

#### Acceptance Criteria

1. WHEN effects are processed, THE System SHALL minimize object allocations and method calls
2. WHEN multiple effects are applied, THE System SHALL batch process them efficiently
3. WHEN effect contexts are created, THE System SHALL reuse context objects where possible
4. THE System SHALL remove redundant validation and processing steps

### Requirement 6: Maintain Backward Compatibility

**User Story:** As a developer, I want to preserve existing game data, so that all current cards, encounters, and curios continue to work after cleanup.

#### Acceptance Criteria

1. WHEN legacy code is removed, THE System SHALL maintain compatibility with existing .tres resource files
2. WHEN effect processing changes, THE System SHALL produce identical gameplay results
3. WHEN data structures are modified, THE System SHALL handle existing save files correctly
4. THE System SHALL preserve all current game mechanics and balance

### Requirement 7: Improve Code Documentation

**User Story:** As a developer, I want clear documentation of the cleaned-up effect system, so that future development is easier and more consistent.

#### Acceptance Criteria

1. WHEN cleanup is complete, THE System SHALL have updated documentation reflecting the new architecture
2. WHEN developers need to create new effects, THE System SHALL provide clear examples and patterns
3. WHEN effect processing occurs, THE System SHALL have clear logging and debugging capabilities
4. THE System SHALL include inline documentation for all public effect system APIs

### Requirement 8: Validate System Integrity

**User Story:** As a developer, I want comprehensive testing of the cleaned-up system, so that I can be confident the cleanup didn't break existing functionality.

#### Acceptance Criteria

1. WHEN cleanup is complete, THE System SHALL pass all existing gameplay tests
2. WHEN effects are processed, THE System SHALL produce consistent and predictable results
3. WHEN edge cases are tested, THE System SHALL handle them gracefully without errors
4. THE System SHALL have automated tests covering all major effect processing scenarios