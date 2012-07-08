- Looking up textareas, or any input element for that matter, by index

- Be more attached to the Safari window.
  - Currently, if a different window is selected, the AppleScript executes against it.
- Verify onclick is working for buttons and links
- TextFields should not respond to button method, etc.

- Unsupported Elements:
  - Test that P/Div/Span/TD handle link, button, etc.,
  - Javascript confirm [OK/CANCEL], Javascript prompt, Javascript popup windows

- Need to find a better way to distinguish between a submit button and a checkbox, re: page_load

- Safari issues
  - Labels are not clickable
  - No known way to programatically click a <button>
  - Links with href="javascript:foo()"
