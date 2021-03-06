set testId to "3.1.0"
set listName to "Sample list " & testId
set command to "wllist " & listName
set precondition to "Wunderlist should be running on the current desktop. Alfred will appear after adding the list; confirm that the new list appears in Alfred"
set postcondition to "New list " & listName & " added to Wunderlist and the list appears in Alfred for the wl command"

display dialog precondition buttons {"Go", "Cancel"} default button 1 cancel button 2 with title "Test " & testId & " Preconditions"

tell application "Alfred 2" 
	search command

	delay 1
end tell

delay 1

tell application "System Events" 
	keystroke return

	delay 4

end tell

tell application "Alfred 2"
	search "wl"

	delay 6
end tell

tell application "System Events"
	set result to button returned of (display dialog postcondition buttons {"Pass", "Fail"} default button 1 with title "Please verify")
	if result is "Pass" then
		1
	else
		0
	end if

end tell
