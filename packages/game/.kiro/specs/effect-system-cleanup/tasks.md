# Implementation Plan: Effect System Cleanup

## Overview

This implementation plan systematically cleans up the effect system by removing legacy components, consolidating processing pipelines, and optimizing performance while maintaining full backward compatibility. The approach follows a phased migration strategy to minimize risk and ensure continuous functionality.

## Tasks

- [x] 1. Create unified effect processor
  - Create new EffectProcessor class to replace CardEffects
  - Implement methods for processing effects from all sources (cards, encounters, curios)
  - Add comprehensive logging and error handling
  - _Requirements: 1.1, 4.1, 4.4_

- [ ]* 1.1 Write property test for unified processing pipeline
  - **Property 2: Unified Processing Pipeline Usage**
  - **Validates: Requirements 1.2, 4.1, 4.2, 4.3**

- [ ] 2. Implement context optimization system
  - Enhance EffectContext with caching and reuse capabilities
  - Add performance monitoring for context creation
  - Implement object pooling for frequently used contexts
  - _Requirements: 5.1, 5.3_

- [ ]* 2.1 Write property test for performance optimization
  - **Property 5: Performance Optimization**
  - **Validates: Requirements 5.1, 5.2, 5.3, 5.4**

- [x] 3. Migrate DuelManager to use EffectProcessor
  - Replace CardEffects usage with new EffectProcessor
  - Update all card effect processing calls
  - Maintain parallel operation during transition
  - _Requirements: 1.2, 1.3_

- [ ]* 3.1 Write property test for behavioral equivalence
  - **Property 1: Behavioral Equivalence After Cleanup**
  - **Validates: Requirements 1.1, 1.3, 6.2, 6.4**

- [ ] 4. Checkpoint - Verify parallel operation
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Evaluate and remove redundant wrapper classes
  - Analyze CardEffectWrapper, CurioEffectWrapper, EncounterEffectWrapper usage
  - Migrate functionality to enhanced GameEffect base class
  - Remove wrapper classes that are no longer needed
  - _Requirements: 2.2, 2.3_

- [ ]* 5.1 Write property test for direct GameEffect processing
  - **Property 3: Direct GameEffect Processing**
  - **Validates: Requirements 2.3, 3.3**

- [ ]* 5.2 Write property test for wrapper removal equivalence
  - **Property 6: Wrapper Removal Equivalence**
  - **Validates: Requirements 2.2**

- [x] 6. Remove legacy adapter classes
  - Delete LegacyCurioAdapter and LegacyEncounterAdapter files
  - Remove any references to adapter classes
  - Verify no adapter code paths are executed
  - _Requirements: 3.2, 3.3_

- [ ]* 6.1 Write property test for data compatibility
  - **Property 4: Data Compatibility Preservation**
  - **Validates: Requirements 3.2, 6.1, 6.3**

- [x] 7. Remove legacy CardEffects system
  - Delete CardEffects class file
  - Remove card_effects_processor from DuelManager
  - Update any remaining references to use EffectProcessor
  - _Requirements: 1.1, 1.4_

- [ ]* 7.1 Write unit test for legacy system removal
  - Test that CardEffects class is completely removed
  - Verify no legacy method calls remain in codebase

- [x] 8. Implement enhanced logging and debugging
  - Add comprehensive logging to EffectProcessor
  - Implement debugging capabilities for effect processing
  - Add performance monitoring and metrics
  - _Requirements: 7.3_

- [ ]* 8.1 Write property test for logging capabilities
  - **Property 7: Logging and Debugging Capability**
  - **Validates: Requirements 7.3**

- [x] 9. Add error handling and edge case management
  - Implement graceful error handling for invalid effects
  - Add validation for edge cases and malformed data
  - Ensure system stability under error conditions
  - _Requirements: 8.3_

- [ ]* 9.1 Write property test for error handling
  - **Property 9: Graceful Error Handling**
  - **Validates: Requirements 8.3**

- [x] 10. Implement deterministic processing guarantees
  - Ensure consistent results for identical inputs
  - Add validation for deterministic behavior
  - Remove any sources of randomness in core processing
  - _Requirements: 8.2_

- [x]* 10.1 Write property test for deterministic processing
  - **Property 8: Deterministic Processing**
  - **Validates: Requirements 8.2**

- [ ] 11. Optimize batch processing performance
  - Implement efficient batch processing for multiple effects
  - Add performance benchmarks and monitoring
  - Optimize memory allocation patterns
  - _Requirements: 5.2, 5.4_

- [ ]* 11.1 Write unit tests for batch processing
  - Test batch processing efficiency and correctness
  - Verify performance improvements over individual processing

- [ ] 12. Final integration and validation
  - Run comprehensive integration tests across all game systems
  - Verify backward compatibility with existing data files
  - Validate performance improvements and stability
  - _Requirements: 6.1, 6.3, 6.4, 8.1_

- [ ]* 12.1 Write integration tests for cross-system compatibility
  - Test card effects in combat scenarios
  - Test encounter effects in exploration
  - Test curio effects across different game states

- [ ] 13. Final checkpoint - Comprehensive validation
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- The phased approach minimizes risk by maintaining parallel operation during critical transitions