script "Hooks"

##
# revIgniter
#
# An application development framework for LiveCode
# modeled on CodeIgniter.
#
# @package		revIgniter
# @author		  rabit@revigniter.com
# @copyright	Copyright (c) 2009 - 2020, dimensionB Bitter u. Bitter GmbH
# @license		https://revigniter.com/userGuide/license.html
# @link		    https://revigniter.com
##

## ------------------------------------------------------------------------

##
# revIgniter Hooks Library
#
# Provides a mechanism to extend the base system without hacking.
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Libraries
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/encryption.html
##





global gRigA, gHooksA

local sHooksEnabled, sInProgress, sLoadedHooks, sHooksHandlers, sStackInUse, sHooksfiles




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-08
 --| Last Mod: --
 --| Requires: rigLogMessage, _rigInitHooksPrefs
 --|
 --| Summary:  Run security check and initial routines.
 --| 
 --| Parameters: --
 --|
 --| Return: empty
 ----------------------------------------------------------------------*/
 
on libraryStack
  if (gRigA is not an array) and (the environment is "server") then
    put "No direct script access allowed."
    exit to top
  end if

  if the short name of the target = the short name of me then
    if sStackInUse <> TRUE then
      put TRUE into sStackInUse

      # LOGGING
      if the environment is "server" then
        rigLogMessage "debug", "Hooks Library Loaded"
      end if
   
      # CALL INITIAL HANDLERS
      _rigInitHooksPrefs
    end if
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack






/*----------------------------------------------------------------------
--| COMMAND _rigInitHooksPrefs
--|
--| Author: rabit
--| Version:  1.3
--| Created: 17-06-09
--| Last Mod: 17-09-15
--| Requires: Config library, rigFetchConfigItem(), rigLogMessage
--|
--| Summary: Initialize the Hooks Preferences
--| 	    
--| 
--| Format:  _rigInitHooksPrefs
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigInitHooksPrefs
  start using stack (gRigA["BASEPATH"] & "libraries/Config.livecodescript")
	# IF HOOKS ARE NOT ENABLED IN THE CONFIG FILE
	# THERE IS NOTHING ELSE TO DO
	if rigFetchConfigItem("enableHooks") is FALSE then
		exit _rigInitHooksPrefs
	end if

	# GRAB THE "HOOKS" DEFINITION FILE.
	# IF THERE ARE NO HOOKS, WE'RE DONE.

	try
    _rigRequire gRigA["APPPATH"] & "config/hooks" & gRigA["EXT"]
	catch err
    rigLogMessage "error", "An error occured while trying to include configuration file:" && "hooks" & gRigA["EXT"]
	end try

	if gHooksA is not an array then
		exit _rigInitHooksPrefs
	end if

	put TRUE into sHooksEnabled
end _rigInitHooksPrefs





/*----------------------------------------------------------------------
--| FUNCTION _rigCallHook
--|
--| Author: rabit
--| Version:  1.1
--| Created: 17-06-09
--| Last Mod: 03-01-10
--| Requires: _rigRunHook()
--|
--| Summary: Calls a particular hook
--| 
--| Format:  _rigCallHook(param1)
--|
--| Parameters: string <pWhich>the hook name
--|
--| Return: bool
----------------------------------------------------------------------*/

function _rigCallHook pWhich
  local tHookResultTemp, tHookResult

	if sHooksEnabled is not TRUE or (gHooksA is empty and gHooksA is not an array) then
		return FALSE
	end if

	put "" into tHookResultTemp
	
	if gHooksA[pWhich][1] is an array then
		repeat for each key tKey in gHooksA[pWhich]
			put _rigRunHook(gHooksA[pWhich][tKey]) into tHookResult
			if tHookResult is FALSE then
				put FALSE into tHookResultTemp
			end if
		end repeat
	else
		put _rigRunHook(gHooksA[pWhich]) into tHookResult
	end if

	if tHookResultTemp is not empty then
		return FALSE
	end if	

	return tHookResult
end _rigCallHook




/*----------------------------------------------------------------------
--| FUNCTION _rigRunHook
--|
--| Author: rabit
--| Version:  1.3
--| Created: 17-06-09
--| Last Mod: 17-09-15
--| Requires: --
--|
--| Summary: Runs a particular hook
--| 
--| Format:  _rigRunHook(param1)
--|
--| Parameters: array <pData>the hook details
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigRunHook pData
  local tFilename, tFilepath, tLib, tHandler, tParams, tIsFunction

	if pData is not an array then
		return FALSE
	end if 

	# SAFETY - PREVENTS RUN-AWAY LOOPS
	#
	# IF THE SCRIPT BEING CALLED HAPPENS TO HAVE THE SAME
	# HOOK CALL WITHIN IT A LOOP CAN HAPPEN
	if sInProgress is TRUE then
		exit _rigRunHook
	end if

	# SET FILE PATH
	if pData["filepath"] is empty or pData["filename"] is empty then
		return FALSE
	end if

	put pData["filename"] into tFilename

	put gRigA["APPPATH"] & pData["filepath"] & "/" & pData["filename"] into tFilepath

	if there is a file tFilepath then
	else
		return FALSE
	end if

	# SET LIBRARY/HANDLER NAME
	put FALSE into tLib
	put FALSE into tHandler
	put "" into tParams

	if pData["library"] is not empty then
		put pData["library"] into tLib
	end if

	if pData["handler"] is not empty then
		put pData["handler"] into tHandler
	end if

	if (pData["params"] is an array) or ((pData["params"] is not an array) and (pData["params"] is not empty)) then
		put pData["params"] into tParams
	end if

	if tLib is FALSE and tHandler is FALSE then
		return FALSE
	end if

	# SET THE sInProgress FLAG
	put TRUE into sInProgress

	# CALL THE REQUESTED LIBRARY AND/OR HANDLER
	if tLib <> FALSE then
		if itemOffset(tLib, sLoadedHooks) is 0 then

			if itemOffset(tFilename, sHooksfiles) is 0 then
         start using stack tFilepath

				if sHooksfiles is empty then
					put tFilename into sHooksfiles
				else
					put comma & tFilename after sHooksfiles
				end if
			end if


			if sLoadedHooks is empty then
				put tLib into sLoadedHooks
			else
				put comma & tLib after sLoadedHooks
			end if
		end if
	else
		if itemOffset(tHandler, sHooksHandlers) is 0 then

			if itemOffset(tFilename, sHooksfiles) is 0 then
         start using stack tFilepath

				if sHooksfiles is empty then
					put tFilename into sHooksfiles
				else
					put comma & tFilename after sHooksfiles
				end if
			end if

			if sHooksHandlers is empty then
				put tHandler into sHooksHandlers
			else
				put comma & tHandler after sHooksHandlers
			end if
		end if
	end if

	combine tParams using comma

	# CHECK IF HANDLER IS A FUNCTION
	if char -2 to -1 of tHandler is "()" then
		put TRUE into tIsFunction
	end if

	if tIsFunction is TRUE then
		put "get" && (char 1 to -2 of tHandler)  & tParams & ")" into tHandler
	else
		put tHandler && tParams into tHandler
	end if

	do tHandler

	put FALSE into sInProgress

	return TRUE
end _rigRunHook






--| END OF Hooks.livecodescript
--| Location:  ./system/libraries/Hooks.livecodescript
----------------------------------------------------------------------