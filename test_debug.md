# Debug Test Instructions

Run the SnapApp and try creating these shortcuts:

## Test 1: Working Number Shortcut
1. Add shortcut: Cmd+Shift+Ctrl+Alt+5
2. Command: `echo "Number shortcut works"`
3. Test the shortcut globally

## Test 2: Non-working Letter Shortcut  
1. Add shortcut: Cmd+Shift+Ctrl+Alt+A
2. Command: `echo "Letter shortcut works"`
3. Test the shortcut globally

## Debug Output to Look For
- Check Console.app or Xcode debug output for:
  - Recording shortcut keyCode values
  - Registration keyCode and carbonModifiers values  
  - Hotkey triggered messages

## Expected Issue
The letter shortcut (A) should record a different keyCode when Shift is pressed, but we need to see what values are being captured vs. registered.