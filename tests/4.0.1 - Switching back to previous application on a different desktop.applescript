set testId to "4.0.1"
set task to "Sample task #workflowtest " & testId
set command to "wlin " & task
set precondition to "Activate an app on a different desktop than Wunderlist before pressing Go. Wunderlist should be running on a different desktop.\n\nIf Wunderlist appears on every desktop, right click Wunderlist in the dock and select Options > Assign To > None."
set postcondition to "New task " & task & " added in the Inbox and previous application reactivated"

display dialog precondition buttons {"Go", "Cancel"} default button 1 cancel button 2 with title "Test " & testId & " Preconditions"

tell application "Alfred 2" 
	search command

	delay 1
end tell

delay 1

tell application "System Events" 
	keystroke return

	delay 4

	set result to button returned of (display dialog postcondition buttons {"Pass", "Fail"} default button 1 with title "Please verify")
	if result is "Pass" then
		1
	else
		0
	end if

end tell
