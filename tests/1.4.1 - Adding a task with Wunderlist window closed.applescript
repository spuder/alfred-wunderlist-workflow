set testId to "1.4.1"
set task to "Sample task #workflowtest " & testId
set command to "wl to:" & task
set precondition to "Press Cmd+W in Wunderlist to close the main window, then activate a different app on the same desktop before pressing Go. Wunderlist should be running on the same desktop but with no visible windows."
set postcondition to "New task " & task & " added in the \"Today\" list and previous application reactivated"

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
