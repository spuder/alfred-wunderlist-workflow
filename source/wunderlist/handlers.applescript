(*!
	@header     Alfred Handlers
	@abstract   Provides the handlers that take input directly from Alfred.
	@discussion In order to use a handler within Alfred, it is necessary to
	            first load the workflow script. Alfred provides the user's
	            query by string substitution of the <code>{query}</code> text
	            in the script, which is also generally necessary to grab.

	            To load the workflow script and pass in the user's query,
	            follow this example:
	<pre><code>    set workflowFolder to do shell script "pwd"
    set wllib to load script POSIX file (workflowFolder & "/wunderlist.scpt")

    set task to "{query}" as text

    tell wllib
    	addTask(task)
    end tell</code></pre>
    It is important to note the text escaping options in Alfred. For this
    workflow, only the Double Quotes and Backslashes options should be
    checked. Excess escaping can cause problems handling simple characters
    such as spaces.
	@version    0.3
*)

(*!
	@abstract   Adds a task to Wunderlist with support for syntax determining to 
	which list it will be added.
	@discussion To support Script Filter inputs and keyboard entry, the task may
	be prefixed by a list identifier to insert it into a specific list using
	@link addTaskToList @/link. The prefix ensures that the task is added to a
	specific list. Without it, for example if <code>task</code> is simply
	<code>2% milk</code> the task will be added to whichever list is currently
	visible. 

	If Wunderlist is on a screen that does not allow task input, such as search
	results or the <em>Assigned to Me</em> screen, the task will be added in the
	Inbox.

	After calling this handler, the previous application is reactivated. However, if 
	<code>task</code> is not specified, Wunderlist will remain active with the 
	keyboard focus on the task input for the specified list.
	@attributeblock List Identifiers
	To identify a list by name, <code>task</code> should contain the list name
	or a portion of the list name and the text of the task separated by a colon.
	These formats are handled by the script filter; this handler expects only the
	following index-based format.
	<pre><code>    Grocery List:2% milk
	groc:2% milk</code></pre>

	To identify a list by index, <code>task</code> should contain the list index
	and the text of the task separated by two colons. This is primarily for 
	internal use.
	<pre><code>    4::2% milk</code></pre>
	@param task The text of the task, optionally prefixed with a numeric or textual
	list identifier.
*)
on addTask(task)

	requireAccessibilityControl()

	if task is not "" then
		# The format used to add a task to a specific list, e.g. 5::2% milk
		set components to q_split(task, "::")

		# If a list index is specified, add the task to it
		if count of components is 2 then
			set {listIndex, task} to components

			addTaskToList(listIndex as integer, task)
			return
		end if

		launchWunderlistIfNecessary()
		
		activateWunderlist()

		addNewTask(task)

		# Show that the task was added
		delay 1
		
		activatePreviousApplication()

	else 

		launchWunderlistIfNecessary()
		
		# If there is no task, just show the Wunderlist window and prepare
		# for task entry.
		activateWunderlist()
		
		focusTaskInput()

	end if

	cleanup()
	
end addTask

(*!
	@abstract   Adds a task to the specified list in Wunderlist
	@discussion Uses @link //apple_ref/applescript/func/focusListAtIndex @/link to 
	focus the specified list, then inserts the task.

	If the specified list does not allow task input, such as <em>Assigned to Me</em>
	or <em>Week</em>, the task will be added in the Inbox.

	After calling this handler, the previous application is reactivated. However, if 
	<code>task</code> is not specified, Wunderlist will remain active with the 
	keyboard focus on the task input for the specified list.

	@param listIndex The integer one-based index of the list as it appears in the 
	list table
	@param task The text of the task
*)
on addTaskToList(listIndex, task)

	requireAccessibilityControl()

	launchWunderlistIfNecessary()
	
	activateWunderlist()

	# Make sure that the list info is accurate
	invalidateListInfoCache()

	if listIndex >= 0 then
		focusListAtIndex(listIndex)
	end if
	
	focusTaskInput()
	
	# If a task is specified, add it then return to the previous application
	if task is not "" then
		addNewTask(task)

		# Show that the task was added
		delay 1
		
		activatePreviousApplication()
	end if

	cleanup()
	
end addTaskToList

(*!
	@abstract   Adds a new list to Wunderlist
	@discussion After calling this handler, Wunderlist remains activated with the keyboard focus 
	on the task input for the new list.

	@param listName The name of the new list
*)
on addList(listName)

	requireAccessibilityControl()

	launchWunderlistIfNecessary()

	activateWunderlist()
	
	addNewList(listName)

	focusTaskInput()

	cleanup()
	
end addList

(*!
	@abstract   A Script Filter input that shows the user's lists in Alfred, allowing
	a task to be added to a specific list.
	@discussion Queries the Wunderlist UI to provide all of the lists into which
	new tasks can be added. The response is formatted for Alfred to display in
	a way that allows the user to type their task, then action a specific list to
	insert the task there.

	After selecting one of these options, the final query will be a concatenation 
	of the list index and the user's task in a format suitable for 
	@link addTaskToList @/link:
	<pre><code>    5::2% milk</code></pre>
	@param task The text of the task
*)
on showListOptions(task)

	launchWunderlistIfNecessary()

	set wf to getCurrentWorkflow()
	set taskComponents to q_split(task, ":")
	set listFilter to ""
	set task to ""

	if count of taskComponents � 1 then
		set listFilter to item 1 of taskComponents
	end if

	if count of taskComponents is 2 then
		set task to item 2 of taskComponents
	end if

	set allLists to getListInfo()
	set writableLists to {}
	set matchingLists to {}
	set canAutocomplete to (task is "")

	# Get list names from Wunderlist in the current locale
	set list_all to wll10n("smart_list_all")
	set list_assignedToMe to wll10n("smart_list_assigned_to_me")
	set list_completed to wll10n("smart_list_completed")
	set list_week to wll10n("smart_list_week")
	set list_inbox to wll10n("smart_list_inbox")
	set list_today to wll10n("smart_list_today")
	set list_starred to wll10n("smart_list_starred")

	# These lists do not allow addition of new tasks
	set readonlyLists to {list_all, list_assignedToMe, list_completed, list_week}

	# Skip "smart lists" that do not allow creation of new tasks and
	# find lists matching the user's filter
	repeat with listInfo in allLists
		ignoring case and diacriticals
			if listName of listInfo is not in readonlyLists then 
				# If nothing matches the filter we need to have a 
				# record of all the lists that accept tasks
				set end of writableLists to listInfo

				if listName of listInfo contains listFilter then 
					# The list is an exact match and the user has typed
					# (or autocompleted) the : following the list name, 
					# look no further
					if listName of listInfo is listFilter and count of taskComponents is 2 then
						# Show only the matching list and add the task 
						# on return
						set matchingLists to {listInfo}
						set canAutocomplete to false
						exit repeat
					# The list filter is a substring of this list name
					else
						set end of matchingLists to listInfo
					end if 
				end if
			end if
		end ignoring
	end repeat

	# There are no matching lists, so just let the user type a
	# task and select a list later using the arrow keys
	if count of matchingLists is 0 then
		set matchingLists to writableLists

		# If no text has been entered, allow autocompletiong,
		# otherwise the user has begun to type a task. In
		# that case, actioning a list in Alfred should insert
		# the task into the list, not perform autocompletion.
		if listFilter is not "" then set canAutocomplete to false

		# Since autocomplete is disabled, set the first item to
		# the active list.
		addResultForInsertingTaskInActiveList(task)

		# If the user did not type a colon the listFilter will
		# contain the text of the task. We know it doesn't match
		# any of the lists so now we can just reassign this.
		if task is "" then
			set task to listFilter
		end if
	end if

	# Show "a task" as a placeholder in "Add [a task] to this list"
	if task is "" then
		set task to "a task"
	end if

	# Display all matching lists
	repeat with listInfo in matchingLists
		set listName to listName of listInfo

		set taskCount to taskCount of listInfo
		set listIndex to listIndex of listInfo
		# TODO: option to sort lists by most frequently used in Alfred
		# temporarily disabled by not providing a uid
		set theUid to missing value # "com.ipaterson.alfred.wunderlist.lists." & listName
		set theAutocomplete to missing value
		set theArg to listIndex as text & "::" & task
		set theSubtitle to "Add " & task & " to this list"
		set theIcon to "/generic.png"
		set isValid to true 

		# If autocompletion is possible, set isValid to false
		# to enable autocomplete on tab
		if canAutocomplete then
			set theAutocomplete to listName & ":"
			set isValid to false
		end if

		# TODO: find a way to determine whether the task count is
		# accurate. Currently the Wunderlist UI populates the label
		# with a random value if there are no tasks in a list.
		# Unfortunately it does not seem possible to distinguish
		# whether the number is visible or not based on the attributes
		# available to AppleScript.
		(*
		set theSubtitle to taskCount as text

		if taskCount is 1 then
			set theSubtitle to theSubtitle & " task"
		else
			set theSubtitle to theSubtitle & " tasks"
		end if
		*)

		# Choose the proper icon for each list
		if listName is list_inbox then
			set theIcon to "/inbox.png"
		else if listName is list_today then
			set theIcon to "/today.png"
		else if listName is list_starred then
			set theIcon to "/starred.png"
		end if

		# Load the icon based on the configured theme 
		set theIcon to "lists/" & iconTheme & theIcon
		
		tell wf to add_result given theUid:theUid, theArg:theArg, theTitle:listName, theSubtitle:theSubtitle, theAutocomplete:theAutocomplete, isValid:isValid, theIcon:theIcon, theType:missing value
	end repeat
	
	return to_xml("") of wf
	
end showListOptions

(*!
	@abstract Ensures that any state modified during execution of a handler,
	such as the clipboard contents, is cleaned up.
*)
on cleanup()
	
	if originalClipboard is not missing value then
		set the clipboard to originalClipboard
	end if

end cleanup

(*!
	@abstract Provides support for command line operations
	@attributelist Commands
	showListOptions See @link showListOptions @/link, returns 1
	updateListInfo See @link //apple_ref/applescript/func/getListInfo @/link, returns 1 if the lists could be loaded, otherwise 0 (which may occur if Wunderlist is not visible on the current desktop)
	forceUpdateListInfo Ensures that list info is loaded which may require switching to the desktop showing Wunderlist.
	@param argv The list of arguments from the command line
	@return 1 for success or 0 for error
*)
on run(argv)
	set status to 0

	if count of argv � 2 then
		set theCommand to item 1 of argv
		set theQuery to item 2 of argv

		if theCommand is "showListOptions" then
			showListOptions(theQuery)
			set status to 1
		end if
	else if count of argv = 1 then
		set theCommand to item 1 of argv

		if theCommand is "updateListInfo" then
			if count of getListInfo() > 0 then
				set status to 1
			end if
		else if theCommand is "forceUpdateListInfo" then
			set theQuery to getAlfredQuery()
			requireAccessibilityControl()

			# Wunderlist has to be running in order to get the list info
			launchWunderlistIfNecessary()

			invalidateListInfoCache()

			# List info was able to be loaded; restore the previous Alfred query
			if count of getListInfo() > 0 then
				activatePreviousApplication()
				setAlfredQuery(theQuery)
				set status to 1
			else
				# Switch to the desktop containing Wunderlist if necessary
				activateWunderlist()
				delay 0.5
				
				if count of getListInfo() > 0 then
					activatePreviousApplication()
					setAlfredQuery(theQuery)
					set status to 1
				end if
			end if
		end if
	end if

	return status
end run