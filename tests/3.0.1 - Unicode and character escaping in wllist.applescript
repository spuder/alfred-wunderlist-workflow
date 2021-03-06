set testId to "3.0.1"
set listName to "Sámple \\/][;$ \"list\" " & testId
set command to "wllist " & listName
set precondition to "Wunderlist should be running on the current desktop"
set postcondition to "New list " & listName & " added to Wunderlist"

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
