set testId to "1.3.0"
set task to "Sample task #workflowtest " & testId
set command to "wl " & task
set precondition to "Wunderlist should be running on the current desktop"
set postcondition to "New task " & task & " added in the Today list"

display dialog precondition buttons {"Go", "Cancel"} default button 1 cancel button 2 with title "Test " & testId & " Preconditions"

tell application "Alfred 2" 
	search command

	delay 1
end tell

delay 1

tell application "System Events" 
	# Down arrow to "Today" list
	key code 125
	key code 125
	
	delay 0.5

	keystroke return

	delay 4

	set result to button returned of (display dialog postcondition buttons {"Pass", "Fail"} default button 1 with title "Please verify")
	if result is "Pass" then
		1
	else
		0
	end if

end tell