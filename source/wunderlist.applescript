(*!
	@framework  Wunderlist for Alfred
	@abstract   Control Wunderlist 2 from Alfred
	@discussion This workflow provides a means to control the Wunderlist 2 Mac app from Alfred.
	            As Wunderlist 2 does not yet provide AppleScript support, the features are limited
	            to those that are keyboard and mouse accessible. Regardless, it saves a lot of 
	            keystrokes!
	@author     Ian Paterson
	@version    0.3
*)

#include "../lib/qWorkflow/uncompiled source/q_workflow"
#include "wunderlist/config"
#include "wunderlist/utilities"
#include "wunderlist/ui"
#include "wunderlist/ui/lists"
#include "wunderlist/ui/tasks"
#include "wunderlist/results"
#include "wunderlist/handlers"