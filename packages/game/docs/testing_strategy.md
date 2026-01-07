# Testing Strategy

This document outlines the testing strategy for the Card Battler Prototype, utilizing **GdUnit4** as the testing framework.

## Framework

We use [GdUnit4](https://github.com/MikeSchulze/gdUnit4) for unit and integration testing. It provides a robust set of assertions, mocking capabilities, and a dedicated runner within the Godot Editor.

## Directory Structure

Tests are located in the `res://test/` directory, mirroring the structure of the `res://scripts/` directory where possible.

- `res://test/unit/`: Contains unit tests that verify individual classes and functions in isolation.
  - Example: `res://test/unit/cards/` corresponds to `res://scripts/cards/`.
- `res://test/integration/`: (Future) Contains tests that verify interactions between multiple systems (e.g., specific Duel scenarios).

## Naming Conventions

- **Test Files**: Must be named `test_<ClassOrFeatureName>.gd` (e.g., `test_card_instance.gd`).
- **Test Suites**: Scripts must extend `GdUnitTestSuite`.
- **Test Functions**: Must start with `test_` (e.g., `func test_initialization():`).

## Writing Tests

### Basic Pattern

```gdscript
extends GdUnitTestSuite

var _instance: MyClass

func before_test():
    # Runs before each test function
    _instance = MyClass.new()

func test_feature_x():
    # Action
    var result = _instance.do_something()
    
    # Assertion
    assert_str(result).is_equal("Expected Value")
    assert_bool(_instance.is_valid).is_true()
```

### Best Practices

1. **Isolation**: Tests should not depend on each other. Use `before_test()` to reset state.
2. **Mocking**: Use GdUnit4's mocking features to simulate complex dependencies (like `DuelManager` or `EventBus`) when testing isolated components.
3. **Descriptive Names**: Test function names should clearly describe what is being verified (e.g., `test_damage_calculation_ignores_armor_on_piercing`).

## Running Tests

### In Godot Editor

1. Open the **GdUnit4** dock (usually at the bottom or specifically enabled via Project > Tools).
2. Right-click the `test` folder in the dock interactions or use the "Run All" button.
3. You can also right-click individual test files in the **FileSystem** dock and select **Run Test**.

### Command Line (CI/CD)

Tests can be run in headless mode, which is suitable for CI/CD pipelines.

```bash
# MacOS Example
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/
```

*Note: Some UI-heavy tests might require removal of `--headless` or use of `--ignoreHeadlessMode` if they rely on input handling that Godot suppresses in headless mode.*
