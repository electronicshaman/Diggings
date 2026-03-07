---
description: Run GdUnit4 tests in headless mode
---
To run unit tests using GdUnit4 in headless mode, use the following command structure.

Note: `--ignoreHeadlessMode` is required because GdUnit4 by default blocks headless mode for UI tests, even if the tests are logic-only.

```bash
cd src
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/[path_to_test_script] --ignoreHeadlessMode
```

Example for a specific test file:

```bash
cd src
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/cards/test_card_data.gd --ignoreHeadlessMode
```

Example for running a directory of tests:

```bash
cd src
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/ --ignoreHeadlessMode
```
