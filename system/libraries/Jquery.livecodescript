script "Jquery"

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
# revIgniter jQuery Library
#
#
# @package		revIgniter
# @subpackage	Libraries
# @category		jQuery
# @author			rabit@revigniter.com
# @link				https://revigniter.com/userGuide/libraries/jquery.html
##

## ------------------------------------------------------------------------



global gRigA

local sUseJQremotely, sJqueryCurrentVersion, sJqueryPath, sJqueryScript, sValidJquerySetMethods
local sCloseEventStatements, sCurrentAnimSelector, sCurrentAnimTarget, sStackInUse






 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2019-01-02
 --| Last Mod: --
 --| Requires: rigLogMessage, _rigSetDefaultValues
 --|
 --| Summary:  Run security check and set initial values.
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
        rigLogMessage "debug", "jQuery Library Loaded"
      end if

      # SET INITIAL VALUES
      _rigSetDefaultValues
      #
    end if -- if sStackInUse <> TRUE

  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack





/*----------------------------------------------------------------------
--| COMMAND _rigSetDefaultValues
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-04
--| Last Mod: 2019-01-04
--| Requires: --
--|
--| Summary: Set default values for library variables.
--|
--| Format:  _rigSetDefaultValues
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetDefaultValues
  put TRUE into sUseJQremotely
  put "assets/js/jquery.js" into sJqueryPath

  # SHOULD NOT BE CHANGED BY USER
  put TRUE into sCloseEventStatements

  put "" into sValidJquerySetMethods
end _rigSetDefaultValues






/*----------------------------------------------------------------------
--| COMMAND rigRunInitialJqueryConfig
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2010-01-22
--| Last Mod: 31-05-2019
--| Requires: _rigInitializeJquery
--|
--| Summary: Run initial configuration procedures.
--|
--| Format:  rigRunInitialJqueryConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialJqueryConfig pConfig
  local tConfig

	put pConfig into tConfig

	if tConfig is not an array then
		if tConfig is not empty then
			split tConfig using numToCodepoint(1) and numToCodepoint(2)
		end if
	end if

	if tConfig is an array then
		_rigInitializeJquery tConfig
	end if
end rigRunInitialJqueryConfig









/*----------------------------------------------------------------------
--| COMMAND _rigInitializeJquery
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-02-10
--| Last Mod: 22-02-10
--| Requires: _rigSetInitialJqueryValue
--|
--| Summary: Initialize preferences.
--|
--| Format: _rigInitializeJquery param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigInitializeJquery pConfig
  local tKey, tVal, tMethod

	if pConfig is an array then
		repeat for each key tKey in pConfig
			put pConfig[tKey] into tVal

			## CHECK IF VARIABLE WITH NAME tKey IS SET
			#
			put "rigSet_s" & tKey into tMethod
			if tMethod is among the items of sValidJquerySetMethods then
				do tMethod && tVal
			else
				_rigSetInitialJqueryValue tKey, tVal
			end if
		end repeat

	end if
end _rigInitializeJquery








/*----------------------------------------------------------------------
--| COMMAND _rigSetInitialJqueryValue
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-02-10
--| Last Mod: 22-02-10
--| Requires: --
--|
--| Summary: Set initial values.
--|
--| Format: _rigSetInitialJqueryValue param1, param2
--|
--| Parameters: string <pVarName>, mixed <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetInitialJqueryValue pVarName pValue
  local tVarName

	put "s" & pVarName into tVarName

	switch tVarName
		case "sJqueryPath"
			put pValue into sJqueryPath
		break
		case "sUseJQremotely"
			put pValue into sUseJQremotely
		break
		case "sJqueryCurrentVersion"
			put pValue into sJqueryCurrentVersion
		break
	end switch
end _rigSetInitialJqueryValue









/*----------------------------------------------------------------------
--| FUNCTION rigJQuerySource
--|
--| Author: rabit
--| Version:  1.3
--| Created: 22-02-10
--| Last Mod: 13-05-16
--| Requires: --
--|
--| Summary: Return html string embedding jQuery.
--|
--| Format:  rigJQuerySource()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJQuerySource
  local tJqueryPath, tSiteURL

	if sUseJQremotely is not TRUE then
		if char 1 of sJqueryPath is "/" then
			put char 2 to (the number of chars of sJqueryPath) of sJqueryPath into tJqueryPath
		else
			put sJqueryPath into tJqueryPath
		end if

		put rigSiteURL() into tSiteURL

    if char -8 to -1 of tSiteURL is "index.lc" then
      put char 1 to -9 of tSiteURL into tSiteURL
    end if

		return "<script type=" & quote & "text/javascript" & quote && "src=" & quote & tSiteURL & tJqueryPath & quote & "></script>"
	else
		if sJqueryCurrentVersion is empty then
			# LATEST VERSION FROM JQUERY.COM
			return "<script src=" & quote & "//code.jquery.com/jquery-latest.js" & quote & "></script>"
		else
			# JQUERY FROM AJAX.GOOGLEAPIS
			return "<script src=" & quote & "//ajax.googleapis.com/ajax/libs/jquery/" & sJqueryCurrentVersion & "/jquery.min.js" & quote && "type=" & quote & "text/javascript" & quote & "></script>"
		end if
	end if
end rigJQuerySource







/*----------------------------------------------------------------------
--| COMMAND rigJQopen
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-03-10
--| Last Mod: 07-03-10
--| Requires: _rigJsScriptOpen(), _rigJQreadyOpen
--|
--| Summary: Start building jQuery script.
--|
--| Format:  rigJQopen
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQopen
	put _rigJsScriptOpen() & _rigJQreadyOpen() into sJqueryScript
end rigJQopen







/*----------------------------------------------------------------------
--| COMMAND rigJQclose
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-03-10
--| Last Mod: 07-03-10
--| Requires: _rigJQreadyClose(), _rigJsScriptClose
--|
--| Summary: Close jQuery script.
--|
--| Format:  rigJQclose
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

command rigJQclose
	put _rigJQreadyClose() & _rigJsScriptClose() after sJqueryScript

	return sJqueryScript
end rigJQclose








/*----------------------------------------------------------------------
--| FUNCTION _rigJsScriptOpen
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-02-10
--| Last Mod: 22-02-10
--| Requires: --
--|
--| Summary: Return javascript open tag.
--|
--| Format: _rigJsScriptOpen()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigJsScriptOpen
	return "<script type=" & quote & "text/javascript" & quote & ">" & return
end _rigJsScriptOpen






/*----------------------------------------------------------------------
--| FUNCTION _rigJsScriptClose
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-02-10
--| Last Mod: 22-02-10
--| Requires: --
--|
--| Summary: Return javascript close tag.
--|
--| Format: _rigJsScriptClose()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigJsScriptClose
	return "</script>" & return
end _rigJsScriptClose








/*----------------------------------------------------------------------
--| FUNCTION _rigJQreadyOpen
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-02-10
--| Last Mod: 22-02-10
--| Requires: --
--|
--| Summary: Return JQ document ready statement open.
--|
--| Format: _rigJQreadyOpen()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigJQreadyOpen
	-- return "$(document).ready(function(){" & return
	# ALTERNATIVE
	return "$(function() {" & return
end _rigJQreadyOpen






/*----------------------------------------------------------------------
--| FUNCTION _rigJQreadyClose
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-02-10
--| Last Mod: 22-02-10
--| Requires: --
--|
--| Summary: Return JQ document ready statement close.
--|
--| Format: _rigJQreadyClose()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigJQreadyClose
	return "});" & return
end _rigJQreadyClose








/*----------------------------------------------------------------------
--| COMMAND rigJQajaxForm
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2010-02-22
--| Last Mod: 2019-06-03
--| Requires: rigTrim()
--|
--| Summary: Process form data using a xmlHTTPrequest.
--|
--| Format:  rigJQajaxForm param1, param2, param3, param4, param5, param6
--|
--| Parameters: string <pSubmitBtn>, comma delimited selectors list <pFields>, string <pPostURI>,
--|               bool <pPreventDefault> optional, string <pDataToLoadURI> optional,
--|               string <pDataContainer> optional
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQajaxForm pSubmitBtn pFields pPostURI pPreventDefault pDataToLoadURI pDataContainer
  local tPostURI, tPreventDefault, tDataToLoadURI, tFieldName, tCounter
  local tField, tRegEx, tMatch1, tPostKeyValuePairs, tValuesReset

	# PREPARE pPostURI
	put rigTrim(pPostURI, "'") into tPostURI
	put rigTrim(tPostURI, "/") into tPostURI

	# PREVENT DEFAULT BEHAVIOR
	if pPreventDefault is empty then
		put TRUE into tPreventDefault
	else
		put pPreventDefault into tPreventDefault
	end if

	# PREPARE pDataToLoadURI
	if pDataToLoadURI is not empty then
		put rigTrim(pDataToLoadURI, "'") into tDataToLoadURI
		put rigTrim(tDataToLoadURI, "/") into tDataToLoadURI
	end if

	# SUBMIT BUTTON CLICK FUNCTION
	put "$(" & pSubmitBtn & ").click(function(event) {" & return after sJqueryScript

	# GET FORM KEY VALUE PAIRS
	put empty into tFieldName -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
  put empty into tMatch1
	put 1 into tCounter
	repeat for each item tField in pFields
    put "'(#|\.)?(.+)'" into tRegEx
    get matchText(tField, tRegEx, tMatch1, tFieldName)

    if tMatch1 is empty then
      # NO ID OR CLASS SPECIFIED, WE ARE DEALING WITH AN ELEMENT NAME
      put "'input[name=" & tFieldName & "]'" into tField
    end if

    put "var fld" & tCounter && "= $(" & tField & ").val();" & return after sJqueryScript
    put tFieldName & ":" && "fld" & tCounter & comma after tPostKeyValuePairs
    put "$(" & tField & ").val('');" & return after tValuesReset

    add 1 to tCounter
	end repeat

	delete char -1 of tPostKeyValuePairs

	# POST DATA
	put "$.post('" & rigSiteURL(tPostURI) & "', {" & tPostKeyValuePairs & "}, function() {" & return after sJqueryScript

	# REQUEST FOR NEW CONTENT
	if (pDataToLoadURI is not empty) and (pDataContainer is not empty) then
		put "$(" & pDataContainer & ").load('" & rigSiteURL(tDataToLoadURI) & "');" & return after sJqueryScript
	end if

	# RESET VALUES
	put tValuesReset & "});" & return after sJqueryScript

	if tPreventDefault is TRUE then
		put "event.preventDefault();" & return after sJqueryScript
	end if

	put "});" & return after sJqueryScript
end rigJQajaxForm








/*----------------------------------------------------------------------
--| COMMAND rigJQeventAlert
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-03-10
--| Last Mod: 07-03-10
--| Requires: --
--|
--| Summary: Alert on various events.
--|
--| Format:  rigJQeventAlert param1, param2, param3, param4
--|
--| Parameters: string <pSelector>, string <pEvent>, string <pAlert>,
--|             bool <pPreventDefault> optional, map <pEventData> a Key/Value pair like "msg: message", optional
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQeventAlert pSelector pEvent pAlert pPreventDefault pEventData
  local tEventData

	if pEventData <> "" then
		put " {" & pEventData & "}," into tEventData
	else
		put "" into tEventData
	end if

	put "$(" & pSelector & ").bind(" & pEvent & "," & tEventData && "function(event){" & return & \
				rigJQalertR(pAlert) & return after sJqueryScript

	if pPreventDefault is TRUE then
     		put "event.preventDefault();" & return after sJqueryScript
	end if

	put "});" & return after sJqueryScript
end rigJQeventAlert








/*----------------------------------------------------------------------
--| COMMAND rigJQalert
--|
--| Author: rabit
--| Version:  1.0
--| Created: 03-04-2010
--| Last Mod: 03-04-2010
--| Requires: rigJQalertR()
--|
--| Summary: Write alert statement.
--|
--| Format:  rigJQalert param1
--|
--| Parameters: string <pAlert>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQalert pAlert
	put rigJQalertR(pAlert) & return after sJqueryScript
end rigJQalert








/*----------------------------------------------------------------------
--| FUNCTION rigJQalertR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 03-04-2010
--| Last Mod: 03-04-2010
--| Requires: --
--|
--| Summary: Return alert statement.
--|
--| Format:  rigJQalertR(param1)
--|
--| Parameters: string <pAlert>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJQalertR pAlert
	return "alert(" & pAlert & ");"
end rigJQalertR







/*----------------------------------------------------------------------
--| COMMAND rigJQconfirm
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-04-2010
--| Last Mod: 14-04-2010
--| Requires: rigJQconfirmR()
--|
--| Summary: Write confirmation box statement.
--|
--| Format:  rigJQconfirm param1, param2, param3
--|
--| Parameters: string <pVarName>, string <pString>, bool <pGlobal> optional
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQconfirm pVarName pString pGlobal
	put rigJQconfirmR(pVarName, pString, pGlobal) & return after sJqueryScript
end rigJQconfirm







/*----------------------------------------------------------------------
--| FUNCTION rigJQconfirmR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-04-2010
--| Last Mod: 14-04-2010
--| Requires: --
--|
--| Summary: Return confirmation box statement.
--|
--| Format:  rigJQconfirmR(param1, param2, param3)
--|
--| Parameters: string <pVarName>, string <pString>, bool <pGlobal> optional
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJQconfirmR  pVarName pString pGlobal
  local tGlobal, tScript

	if pGlobal is empty then
		put FALSE into tGlobal
	else
		put pGlobal into tGlobal
	end if

	if tGlobal is FALSE then
		put "var " into tScript
	else
		put "" into tScript
	end if

	put pVarName && "= confirm(" & pString & ");" & return after tScript

	return tScript
end rigJQconfirmR








/*----------------------------------------------------------------------
--| COMMAND rigJQprompt
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-04-2010
--| Last Mod: 14-04-2010
--| Requires: rigJQpromptR()
--|
--| Summary: Write prompt box statement.
--|
--| Format:  rigJQprompt param1, param2, param3, param4
--|
--| Parameters: string <pVarName>, string <pPrompt>, string <pDefault> optional, bool <pGlobal> optional
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQprompt pVarName pPrompt pDefault pGlobal
	put rigJQconfirmR(pVarName, pPrompt, pDefault, pGlobal) & return after sJqueryScript
end rigJQprompt







/*----------------------------------------------------------------------
--| FUNCTION rigJQpromptR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-04-2010
--| Last Mod: 14-04-2010
--| Requires: --
--|
--| Summary: Return prompt box statement.
--|
--| Format:  rigJQpromptR(param1, param2, param3, param4)
--|
--| Parameters: string <pVarName>, string <pPrompt>, string <pDefault> optional, bool <pGlobal> optional
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJQpromptR  pVarName pPrompt pDefault pGlobal
  local tDefault, tGlobal, tScript

	if pDefault is "" then
		put "" into tDefault
	else
		put "," && pDefault into tDefault
	end if

	if pGlobal is empty then
		put FALSE into tGlobal
	else
		put pGlobal into tGlobal
	end if

	if tGlobal is FALSE then
		put "var " into tScript
	else
		put "" into tScript
	end if

	put pVarName && "= confirm(" & pPrompt & tDefault & ");" & return after tScript

	return tScript
end rigJQpromptR








/*----------------------------------------------------------------------
--| COMMAND rigJQset
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-04-2010
--| Last Mod: 06-04-2010
--| Requires: rigJQsetR()
--|
--| Summary: Write jQuery setter statements.
--|
--| Format:  rigJQset param1, param2, param3, param4, param5
--|
--| Parameters: string <pSelector>, string <pMethod>, string <pPropertyvalues>, bool <pFunction> optional
--|               bool <pToggleClassSwitch> optional
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQset pSelector pMethod pPropertyvalues pFunction pToggleClassSwitch
	put rigJQsetR(pSelector, pMethod, pPropertyvalues, pFunction, pToggleClassSwitch) after sJqueryScript
end rigJQset








/*----------------------------------------------------------------------
--| FUNCTION rigJQsetR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-04-2010
--| Last Mod: 21-03-2014
--| Requires: rigTrim()
--|
--| Summary: Return jQuery setter statements.
--|
--| Format:  rigJQsetR(param1, param2, param3, param4, param5)
--|
--| Parameters: string <pSelector>, string <pMethod>, mixed <pPropertyvalues>, bool <pFunction> optional
--|             bool <pToggleClassSwitch> optional
--|
--| Return: returnType
----------------------------------------------------------------------*/

function rigJQsetR pSelector pMethod pPropertyvalues pFunction pToggleClassSwitch
  local tMethod, tFunction, tToggleClassSwitch, tPropertyvalues, tKey, tVal
  local tAttributeName, tAttributeValueFunction, tScript

	# PREPARE pMethod
	put rigTrim(pMethod, "'") into tMethod

	if pFunction is empty then
		put FALSE into tFunction
	else
		put pFunction into tFunction
	end if

	if pToggleClassSwitch is empty then
		put "" into tToggleClassSwitch
	else
		put "," && pToggleClassSwitch into tToggleClassSwitch
	end if


	# KEY VALUE PAIRS
	if pPropertyvalues is an array then
		put "{" into tPropertyvalues
		repeat for each key tKey in pPropertyvalues
			put pPropertyvalues["tKey"] into tVal
			if tVal is empty then
				put "''" into tVal
			end if

			put space & tKey & ":" & tVal & "," after tPropertyvalues
		end repeat
		delete char -1 of tPropertyvalues
		put " }" after tPropertyvalues

	else
		if (comma is in pPropertyvalues) and (tFunction is TRUE) then
			put item 1 of pPropertyvalues into tAttributeName
			put item 2 of pPropertyvalues into tAttributeValueFunction
		else
			put pPropertyvalues into tPropertyvalues
		end if
	end if

	if tFunction is FALSE then
		put "$(" & pSelector & ")." & tMethod & "(" & tPropertyvalues & tToggleClassSwitch & ");" & return into tScript
	else
		if comma is in pPropertyvalues then
			# FUNCTION ARGUMENTS: THE INDEX POSITION OF THE ELEMENT IN THE SET AND
			# THE OLD ATTRIBUTE/CLASS/HEIGHT/HTML/COORDS/CSS/WIDTH VALUE.
			put "$(" & pSelector & ")." & tMethod & "(" & tAttributeName & ", function(index, oldVal) {" & return & \
			tAttributeValueFunction & return & \
			"}" & tToggleClassSwitch & ");" & return into tScript
		else
			put "$(" & pSelector & ")." & tMethod & "(function(index, oldVal) {" & return & \
			tPropertyvalues & return & \
			"}" & tToggleClassSwitch & ");" & return into tScript
		end if
	end if

	return tScript
end rigJQsetR









/*----------------------------------------------------------------------
--| FUNCTION rigJQgetR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-04-2010
--| Last Mod: 07-03-2014
--| Requires: rigTrim()
--|
--| Summary: Return information from DOM elements.
--|
--| Format:  rigJQgetR(param1, param2, param3)
--|
--| Parameters: string <pSelector>, string <pMethod>, string <pGetterProp> optional
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJQgetR pSelector pMethod pGetterProp
  local tMethod, tGetterProp

	# PREPARE pMethod
	put rigTrim(pMethod, "'") into tMethod

	if pGetterProp <> "" then
		if (char 1 of pGetterProp <> "'") and (char -1 of pGetterProp <> "'") then
			put "'" & pGetterProp & "'" into tGetterProp
		else
			put pGetterProp into tGetterProp
		end if
	else
		put "" into tGetterProp
	end if

	# STATEMENT
	return "$(" & pSelector & ")." & tMethod & "(" & tGetterProp & ");"
end rigJQgetR









/*----------------------------------------------------------------------
--| COMMAND rigJQeventOpen
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-04-2010
--| Last Mod: 06-04-2010
--| Requires: _rigJQdelegateLiveOneToggleUnbind, _rigJQdieUndelegate, _rigJQhover, _rigJQtriggerTriggerhandler
--|
--| Summary: Event open statement.
--|
--| Format:  rigJQeventOpen param1, param2, param3, param4, param5
--|
--| Parameters: string <pSelector>, string <pEvent>, bool <pPreventDefault> optional, string <pEventData> optional,
--|               string <pEventObject> optional, string <pFunctionArguments> a comma delimited list of
--|               params to add to the function, optional
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQeventOpen pSelector pEvent pPreventDefault pEventData pEventObject pFunctionArguments
  local tEventData, tFunctionArguments

	# CHECK IF EVENT IS ONE OF THOSE, WHICH HAVE A DEDICATED LIBRARY HANDLER
	switch pEvent
		case "delegate"
			_rigJQdelegateLiveOneToggleUnbind pSelector, "delegate", pPreventDefault, pEventData, pEventObject, pFunctionArguments
			exit rigJQeventOpen
		break
		case "'delegate'"
			_rigJQdelegateLiveOneToggleUnbind pSelector, "delegate", pPreventDefault, pEventData, pEventObject, pFunctionArguments
			exit rigJQeventOpen
		break
		case "die"
			_rigJQdieUndelegate pSelector, "die", pPreventDefault, pEventData, pEventObject
			exit rigJQeventOpen
		break
		case "'die'"
			_rigJQdieUndelegate pSelector, "die", pPreventDefault, pEventData, pEventObject
			exit rigJQeventOpen
		break
		case "hover"
			_rigJQhover pSelector, "hover", pPreventDefault, pEventData
			exit rigJQeventOpen
		break
		case "'hover'"
			_rigJQhover pSelector, "hover", pPreventDefault, pEventData
			exit rigJQeventOpen
		break
		case "live"
			_rigJQdelegateLiveOneToggleUnbind pSelector, "live", pPreventDefault, pEventData, pEventObject, pFunctionArguments
			exit rigJQeventOpen
		break
		case "'live'"
			_rigJQdelegateLiveOneToggleUnbind pSelector, "live", pPreventDefault, pEventData, pEventObject, pFunctionArguments
			exit rigJQeventOpen
		break
		case "one"
			_rigJQdelegateLiveOneToggleUnbind pSelector, "one", pPreventDefault, pEventData, pEventObject, pFunctionArguments
			exit rigJQeventOpen
		break
		case "'one'"
			_rigJQdelegateLiveOneToggleUnbind pSelector, "one", pPreventDefault, pEventData, pEventObject, pFunctionArguments
			exit rigJQeventOpen
		break
		case "toggle"
			_rigJQdelegateLiveOneToggleUnbind pSelector, "toggle", pPreventDefault, pEventData, pEventObject, pFunctionArguments
			exit rigJQeventOpen
		break
		case "'toggle'"
			_rigJQdelegateLiveOneToggleUnbind pSelector, "toggle", pPreventDefault, pEventData, pEventObject, pFunctionArguments
			exit rigJQeventOpen
		break
		case "trigger"
			_rigJQtriggerTriggerhandler pSelector, "trigger", pPreventDefault, pEventData
			exit rigJQeventOpen
		break
		case "'trigger'"
			_rigJQtriggerTriggerhandler pSelector, "trigger", pPreventDefault, pEventData
			exit rigJQeventOpen
		break
		case "triggerHandler"
			_rigJQtriggerTriggerhandler pSelector, "triggerHandler", pPreventDefault, pEventData
			exit rigJQeventOpen
		break
		case "'triggerHandler'"
			_rigJQtriggerTriggerhandler pSelector, "triggerHandler", pPreventDefault, pEventData
			exit rigJQeventOpen
		break
		case "unbind"
			_rigJQdelegateLiveOneToggleUnbind pSelector, "unbind", pPreventDefault, pEventData, pEventObject, pFunctionArguments
			exit rigJQeventOpen
		break
		case "'unbind'"
			_rigJQdelegateLiveOneToggleUnbind pSelector, "unbind", pPreventDefault, pEventData, pEventObject, pFunctionArguments
			exit rigJQeventOpen
		break
		case "undelegate"
			_rigJQdieUndelegate pSelector, "undelegate", pPreventDefault, pEventData, pEventObject
			exit rigJQeventOpen
		break
		case "'undelegate'"
			_rigJQdieUndelegate pSelector, "undelegate", pPreventDefault, pEventData, pEventObject
			exit rigJQeventOpen
		break
	end switch

	# PREPARE EVENT DATA
	if pEventData <> "" then
		put " {" & pEventData & "}," into tEventData
	else
		put "" into tEventData
	end if

	# PREPARE FUNCTION PARAMETERS
	if pFunctionArguments is empty then
		put "" into tFunctionArguments
	else
		put "," && pFunctionArguments into tFunctionArguments
	end if

	# WRITE STATEMENT
	if pEventObject is empty then
		put "$(" & pSelector & ").bind(" & pEvent & "," & tEventData && "function(event" & tFunctionArguments & "){" & return after sJqueryScript
	else
		put "$(" & pSelector & ").bind(" & pEvent & "," & tEventData && "," && pEventObject & ");" & return after sJqueryScript
		# IGNORE THE NEXT rigJQeventClose COMMAND
		put FALSE into sCloseEventStatements
	end if

	# PREVENT DEFAULT BEHAVIOR
	if pPreventDefault is TRUE then
     		put "event.preventDefault();" & return after sJqueryScript
	end if
end rigJQeventOpen









/*----------------------------------------------------------------------
--| COMMAND rigJQeventClose
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-04-2010
--| Last Mod: 06-04-2010
--| Requires: --
--|
--| Summary: Event close statement.
--|
--| Format:  rigJQeventClose
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

command rigJQeventClose
	if sCloseEventStatements is TRUE then
		put "});" & return after sJqueryScript
	else
		# IGNORE THIS rigJQeventClose COMMAND AND RESET THE VARIABLE
		put TRUE into sCloseEventStatements
	end if
end rigJQeventClose








/*----------------------------------------------------------------------
--| COMMAND _rigJQdelegateLiveOneToggleUnbind
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-04-2010
--| Last Mod: 07-04-2010
--| Requires: --
--|
--| Summary: Delegate: Write statement to attach a handler to one or more events
--|            for all elements that match the selector, now or in the future,
--|            based on a specific set of root elements.
--|
--|            Live: Write statement to attach a handler to the event for
--|            all elements which match the current selector,
--|            now or in the future.
--|
--|				  One: Write statement to attach a handler to an event for the elements.
--|            The handler is executed at most once per element.
--|
--|            Toggle: Write statement to bind two or more handlers to the matched
--|            elements, to be executed on alternate clicks.
--|
--|            Unbind: Write statement to remove a previously-attached event handler
--|            from the elements.
--|
--| Format:  _rigJQdelegateLiveOneToggleUnbind param1, param2, param3, param4, param5
--|
--| Parameters: string <pSelector>, string <pEvent>, bool <pPreventDefault> optional, string <pEventData> optional,
--|               string <pEventObject> optional, string <pFunctionArguments> params to add to the function, optional
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigJQdelegateLiveOneToggleUnbind pSelector pEvent pPreventDefault pEventData pEventObject pFunctionArguments
  local tEventData, tFunctionArguments

	# PREPARE EVENT DATA
	if pEventData <> "" then
		put pEventData & "," into tEventData
	else
		put "" into tEventData
	end if

	# PREPARE FUNCTION PARAMETERS
	if pFunctionArguments is empty then
		put "" into tFunctionArguments
	else
		put "," && pFunctionArguments into tFunctionArguments
	end if

	if pEventObject is empty then
		put "$(" & pSelector & ")." & pEvent & "(" & tEventData && "function(event" & tFunctionArguments & "){" & return after sJqueryScript
	else
		put "$(" & pSelector & ")." & pEvent & "(" & tEventData && pEventObject & ");" & return after sJqueryScript
		# IGNORE THE NEXT rigJQeventClose COMMAND
		put FALSE into sCloseEventStatements
	end if

	# PREVENT DEFAULT BEHAVIOR
	if pPreventDefault is TRUE then
     		put "event.preventDefault();" & return after sJqueryScript
	end if
end _rigJQdelegateLiveOneToggleUnbind








/*----------------------------------------------------------------------
--| COMMAND _rigJQdieUndelegate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-04-2010
--| Last Mod: 07-04-2010
--| Requires: --
--|
--| Summary: Write statement to emove an event handler previously attached
--|            using .live() from the elements.
--|
--|            Undelegate: Write statement to remove a handler from the
--|            event for all elements which match the current selector,
--|            now or in the future, based upon a specific set of root elements.
--|
--| Format:  _rigJQdieUndelegate param1, param2, param3, param4
--|
--| Parameters: string <pSelector>, string <pEvent>, bool <pPreventDefault> optional,
--|               string <pEventData> optional, string <pEventObject> optional
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigJQdieUndelegate pSelector pEvent pPreventDefault pEventData pEventObject
	if pEventObject is empty then
		put "$(" & pSelector & ")." & pEvent & "(" & pEventData & ");" & return after sJqueryScript
	else
		put "$(" & pSelector & ")." & pEvent & "(" & pEventData && "," && pEventObject & ");" & return after sJqueryScript
	end if

	# IGNORE THE NEXT rigJQeventClose COMMAND
	put FALSE into sCloseEventStatements

	# PREVENT DEFAULT BEHAVIOR
	if pPreventDefault is TRUE then
     		put "event.preventDefault();" & return after sJqueryScript
	end if
end _rigJQdieUndelegate







/*----------------------------------------------------------------------
--| COMMAND _rigJQhover
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-04-2010
--| Last Mod: 07-04-2010
--| Requires: --
--|
--| Summary: Write statement to bind two handlers to the matched
--|            elements, to be executed when the mouse pointer enters
--|            and leaves the elements.
--|
--| Format:  _rigJQhover param1, param2, param3
--|
--| Parameters: string <pSelector>, string <pEvent>, bool <pPreventDefault> optional, string <pEventData>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigJQhover pSelector pEvent pPreventDefault pEventData
	put "$(" & pSelector & ")." & pEvent & "(" & pEventData & ");" & return after sJqueryScript

	# IGNORE THE NEXT rigJQeventClose COMMAND
	put FALSE into sCloseEventStatements

	# PREVENT DEFAULT BEHAVIOR
	if pPreventDefault is TRUE then
     		put "event.preventDefault();" & return after sJqueryScript
	end if
end _rigJQhover







/*----------------------------------------------------------------------
--| COMMAND _rigJQtriggerTriggerhandler
--|
--| Author: rabit
--| Version:  1.1
--| Created: 07-04-2010
--| Last Mod: 21-03-2014
--| Requires: --
--|
--| Summary: Trigger: Write statement to execute all handlers and behaviors
--|            attached to the matched elements for the given event type.
--|
--|            TriggerHandler: Write statement to execute all handlers attached
--|            to an element for an event.
--|
--| Format:  _rigJQtriggerTriggerhandler param1, param2, param3
--|
--| Parameters: string <pSelector>, string <pEvent>, bool <pPreventDefault> optional, string <pEventData>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigJQtriggerTriggerhandler pSelector pEvent pPreventDefault pEventData
  local tEventData

	# PREPARE EVENT DATA
		if comma is in pEventData then
			put (item 1 of pEventData) & ", [" into tEventData
			repeat with i = 2 to (the number of items of pEventData)
				put (item i of pEventData) & "," after tEventData
			end repeat
			delete char -1 of tEventData
			put "]" after tEventData
		else
			put pEventData into tEventData
		end if

		put "$(" & pSelector & ")." & pEvent & "(" & tEventData & ");" & return after sJqueryScript

		# IGNORE THE NEXT rigJQeventClose COMMAND
		put FALSE into sCloseEventStatements

		# PREVENT DEFAULT BEHAVIOR
		if pPreventDefault is TRUE then
	     		put "event.preventDefault();" & return after sJqueryScript
		end if
end _rigJQtriggerTriggerhandler









/*----------------------------------------------------------------------
--| COMMAND rigJQeventEffect
--|
--| Author: rabit
--| Version:  1.0
--| Created: 31-03-2010
--| Last Mod: 31-03-2010
--| Requires: rigJQeffectR()
--|
--| Summary: Set special effects on various events.
--|
--| Format:  rigJQeventEffect param1, param2, param3, param4, param5, param6
--|
--| Parameters: string <pSelector>, string <pTarget>, string <pEvent>, string <pEffect>, string <pParameter> optional,
--|               bool <pPreventDefault> optional, string <pCallback> optional
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQeventEffect pSelector pTarget pEvent pEffect pParameter pPreventDefault pCallback
	put "$(" & pSelector & ").bind(" & pEvent & ", function(event){" & return after sJqueryScript

	# PREVENT DEFAULT BEHAVIOR
	if pPreventDefault is TRUE then
     		put "event.preventDefault();" & return after sJqueryScript
	end if

	# WRITE EFFECT STATEMENT
	put rigJQeffectR(pTarget, pEffect, pParameter, pCallback) & return after sJqueryScript

	put "});" & return after sJqueryScript
end rigJQeventEffect









/*----------------------------------------------------------------------
--| COMMAND rigJQeffect
--|
--| Author: rabit
--| Version:  1.0
--| Created: 02-04-2010
--| Last Mod: 02-04-2010
--| Requires: rigJQeffectR()
--|
--| Summary: Write statement for various effects.
--|
--| Format:  rigJQeffect param1 param2 param3 param 4
--|
--| Parameters: string <pSelector>, string <pEffect>, mixed <pDuration> optional,
--|               string <pCallback> optional
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQeffect pSelector pEffect pDuration pCallback
	put rigJQeffectR(pSelector, pEffect, pDuration, pCallback) & return after sJqueryScript
end rigJQeffect









/*----------------------------------------------------------------------
--| FUNCTION rigJQeffectR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-04-2010
--| Last Mod: 01-04-2010
--| Requires: --
--|
--| Summary: Return statement for various effects.
--|
--| Format:  rigJQeffectR(param1, param2, param3, param4)
--|
--| Parameters: string <pSelector>, string <pEffect>, mixed <pEffectData> optional,
--|               string <pCallback> optional
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJQeffectR pSelector pEffect pEffectData pCallback
  local tEffectData, tScript

  # GET EFFECT DURATION
  if pEffectData is empty then
    put "" into tEffectData
  else
    put pEffectData into tEffectData
  end if

  # ADD EFFECT CALLBACK FUNCTION
  if pCallback is empty then
    put "$(" & pSelector & ")." & pEffect & "(" & tEffectData & ");" into tScript
  else
    if tEffectData <> "" then
      put tEffectData & "," into tEffectData
    end if
    put "$(" & pSelector & ")." & pEffect & "(" & tEffectData && "function(event) {" & return & \
    pCallback & return & \
    "});" into tScript
  end if

  return tScript
end rigJQeffectR







/*----------------------------------------------------------------------
--| COMMAND rigJQeventAnim
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-04-2010
--| Last Mod: 09-04-2010
--| Requires: rigJQanimateR()
--|
--| Summary: Write statements to perform a custom animation of a set of CSS properties
--|            on various events.
--|
--| Format:  rigJQeventAnim param1, param2, param3, param4, param5, param6
--|
--| Parameters: string <pSelector>, string <pTarget>, string <pEvent>, array <pProperties>,
--|               mixed <pDuration> optional, string <pEasing> optional, string <pCallback> optional
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQeventAnim pSelector pTarget pEvent pProperties pDuration pEasing pCallback
	# WRITE THIS STATEMENT FOR SUBSEQUENT CALLS ONLY ONCE
	if pSelector <> sCurrentAnimSelector then
		put "$(" & pSelector & ")." & pEvent & "(function(event) {" & return after sJqueryScript
		put pSelector into sCurrentAnimSelector
		put empty into sCurrentAnimTarget
	else
		# REMOVE "});"
		delete line -1 of sJqueryScript
	end if

	# WRITE ANIMATION STATEMENT
	put rigJQanimateR(pTarget, pProperties, pDuration, pEasing, pCallback) & return after sJqueryScript

	put "});" & return after sJqueryScript
end rigJQeventAnim









/*----------------------------------------------------------------------
--| COMMAND rigJQanimate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 08-04-2010
--| Last Mod: 08-04-2010
--| Requires: rigJQanimateR
--|
--| Summary: Write statement to perform a custom animation of a set of CSS properties.
--|
--| Format:  rigJQanimate param1, param2, param3, param4, param5
--|
--| Parameters: string<pSelector>, mixed <pProperties> if you don't use an array use the
--|               following form: "key1: value1, key2: value2, . . ." , mixed <pDuration> integer
--|               or string or array, optional,
--|               string <pEasing> optional, string <pCallback> optional
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQanimate pSelector pProperties pDuration pEasing pCallback
	put rigJQanimateR(pSelector, pProperties, pDuration, pEasing, pCallback) & return after sJqueryScript
end rigJQanimate








/*----------------------------------------------------------------------
--| FUNCTION rigJQanimateR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 08-04-2010
--| Last Mod: 21-03-2014
--| Requires: --
--|
--| Summary: Return statement to perform a custom animation of a set of CSS properties.
--|
--| Format:  rigJQanimateR(param1, param2, param3, param4, param5)
--|
--| Parameters: string<pSelector>, mixed <pProperties> if you don't use an array use the
--|               following form: "key1: value1, key2: value2, . . ." , mixed <pDuration> integer
--|               or string or array, optional,
--|               string <pEasing> optional, string <pCallback> optional
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJQanimateR pSelector pProperties pDuration pEasing pCallback
  local tDuration, tKey, tVal, tEasing, tScript

	# PREPARE DURATION

	# DURATION AS KEY VALUE PAIRS
	if pDuration is an array then
		put "{" into tDuration
		repeat for each key tKey in pDuration
			put pDuration[tKey] into tVal
			put tKey & ":" && tVal & "," after tDuration
		end repeat
		delete char -1 of tDuration
		put "}" after tDuration
	else
		if pDuration <> "" then
			put pDuration into tDuration
		else
			put "" into tDuration
		end if
	end if

	# PREPARE EASING
	if pEasing is empty then
		put "" into tEasing
	else
		put "," && pEasing into tEasing
	end if

	# WRITE THIS STATEMENT FOR SUBSEQUENT CALLS ONLY ONCE
	if pSelector <> sCurrentAnimTarget then
		put "$(" & pSelector & ").animate({" into tScript
		put pSelector into sCurrentAnimTarget
	else
		# REMOVE LAST SEMICOLON
		delete char -2 to -1 of sJqueryScript
		put ".animate({" into tScript
	end if

	# GET PROPERTIES TO ANIMATE
	if pProperties is an array then
		repeat for each key tKey in pProperties
			put pProperties[tKey] into tVal
			put return & tKey & ":" && tVal & "," after tScript
		end repeat
		delete char -1 of tScript

	else
		put pProperties after tScript
	end if

	if pCallback is empty then
		put return & "}," && tDuration & tEasing && ");" after tScript
	else
		put return & "}," && tDuration & tEasing & "," && "function(event) {" & return & \
				pCallback & return & \
				"});" after tScript
	end if

	return tScript
end rigJQanimateR








/*----------------------------------------------------------------------
--| COMMAND rigJQajax
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-04-2010
--| Last Mod: 10-04-2010
--| Requires: rigJQajaxR()
--|
--| Summary: Write statement to perform an asynchronous HTTP (Ajax) request.
--|            Write statement for ajax options.
--|
--| Format:  rigJQajax param1, param2
--|
--| Parameters: array <pAjaxOptions>, bool <pSetUpOnly> optional
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQajax pAjaxOptions pSetUpOnly
	put rigJQajaxR(pAjaxOptions, pSetUpOnly) after sJqueryScript
end rigJQajax







/*----------------------------------------------------------------------
--| FUNCTION rigJQajaxR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 10-04-2010
--| Last Mod: 21-03-2014
--| Requires: rigTrim()
--|
--| Summary: Return statement to perform an asynchronous HTTP (Ajax) request.
--|
--| Format:  rigJQajaxR(param1, param2)
--|
--| Parameters: array <pAjaxOptions>, bool <pSetUpOnly> optional
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJQajaxR pAjaxOptions pSetUpOnly
  local tSetUpOnly, tScript, tKey, tVal

	if pSetUpOnly is "" then
		put FALSE into tSetUpOnly
	else
		put pSetUpOnly into tSetUpOnly
	end if

	if tSetUpOnly is TRUE then
		put "$.ajaxSetup({" into tScript
	else
		put "$.ajax({" into tScript
	end if

	# IF REQUEST TYPE IS NOT SPECIFIED USE POST IF QUERY STRINGS ARE NOT ENABLED
	if "type" is not among the keys of pAjaxOptions then
		if rigFetchConfigItem("enableQueryStrings") is not TRUE then
			put return & "type: 'POST'," after tScript
		end if
	end if

	# GET AJAX OPTIONS
	repeat for each key tKey in pAjaxOptions
		put pAjaxOptions[tKey] into tVal

		if tKey is "url" then
			put rigTrim(tVal, "/") into tVal
			put rigTrim(tVal, "'") into tVal
			put "'" & rigSiteURL(tVal) & "'" into tVal
		end if

		if tKey is "success" then
			put return & "success: function(data, textStatus, XMLHttpRequest) {" & return & tVal & "}," after tScript
		else if (tKey is "data") and (":" is in tVal) then
			if ";" is in tVal then
				replace ";" with "" in tVal
			end if
			put return & tKey & ": {" & tVal & "}," after tScript
		else
			put return & tKey & ":" && tVal after tScript
			if char -1 of tScript is ";" then
				delete char -1 of tScript
			end if
			put "," after tScript
		end if

	end repeat
	delete char -1 of tScript

	put return & "});" & return after tScript

	return tScript
end rigJQajaxR









/*----------------------------------------------------------------------
--| COMMAND rigJQxhRequest
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-04-2010
--| Last Mod: 12-04-2010
--| Requires: rigJQxhRequestR()
--|
--| Summary: Write statement to load data from the server.
--|
--| Format:  rigJQxhRequest param1, param2, param3, param4, param5, param6
--|
--| Parameters: string <pType> possible values: get post load getJSON,
--|               string <pURL> optional, map or string <pData> optional,
--|               string <pCallback> optional, string <pDataType> optional,
--|               string <pSelector> optional for all types but "load"
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQxhRequest pType pURL pData pCallback pDataType pSelector
	put rigJQxhRequestR(pType, pURL, pData, pCallback, pDataType, pSelector) & return after sJqueryScript
end rigJQxhRequest








/*----------------------------------------------------------------------
--| FUNCTION rigJQxhRequestR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-04-2010
--| Last Mod: 12-04-2010
--| Requires: rigTrim()
--|
--| Summary: Return statement to load data from the server.
--|
--| Format:  rigJQxhRequestR(param1, param2, param3, param4, param5, param6)
--|
--| Parameters: string <pType> possible values: get post load getJSON,
--|               string <pURL> optional, map or string <pData> optional,
--|               string <pCallback> optional, string <pDataType> optional,
--|               string <pSelector> optional for all types but "load"
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJQxhRequestR pType pURL pData pCallback pDataType pSelector
  local tURL, tData, tDataType, tScript

	# GET URL
	put rigTrim(pURL, "/") into tURL
	put "'" & rigSiteURL(tURL) & "'" into tURL

	# GET DATA
	if pData is empty then
		put "" into tData
	else
		put pData into tData
	end if
	if ":" is in tData then
		if ";" is in tData then
			replace ";" with "" in tData
		end if
		put "{" & tData & "}" into tData
	end if
	if tData <> "" then
		put "," && tData into tData
	end if

	# GET DATA TYPE
	if pDataType is empty then
		put "" into tDataType
	else
		put "," && pDataType into tDataType
	end if


	if pType is "load" then
		if pCallback is empty then
			put "$(" & pSelector & ").load(" & tURL & tData & tDataType & ");" into tScript
		else
			put "$(" & pSelector & ").load(" & tURL & tData & ", function(data, textStatus, XMLHttpRequest){" & return & \
			pCallback & return & \
			"}" & tDataType &");" into tScript
		end if
	else
		if pCallback is empty then
			put "$." & pType & "(" & tURL & tData & tDataType & ");" into tScript
		else
			put "$." & pType & "(" & tURL & tData & ", function(data, textStatus, XMLHttpRequest){" & return & \
			pCallback & return & \
			"}" & tDataType &");" into tScript
		end if
	end if

	return tScript
end rigJQxhRequestR









/*----------------------------------------------------------------------
--| COMMAND rigJQcallFunction
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-04-2010
--| Last Mod: 09-04-2010
--| Requires: --
--|
--| Summary: Write statement to call any jQuery or any custom function.
--|
--| Format:  rigJQcallFunction param1, param2
--|
--| Parameters: string <pSelector> use a comma delimited list if you want
--|               to deal with more than one element, string <pFunctionName>, string <pFuntionArguments> optional
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQcallFunction pSelector pFunctionName pFuntionArguments
  local tScript

	if pSelector <> "" then
		put "$(" into tScript

		# CHECK IF pSelector IS A LIST
		if comma is in pSelector then
			put item 1 of pSelector & ")" after tScript
			repeat with i = 2 to (the number of items in pSelector)
				put ".add(" & item i of pSelector & ")" after tScript
			end repeat

		else
			put pSelector & ")" after tScript
		end if

		put "." & pFunctionName & "(" & pFuntionArguments & ");" after tScript

	else
		put pFunctionName & "(" & pFuntionArguments & ");" into tScript
	end if

	put tScript & return after sJqueryScript
end rigJQcallFunction







/*----------------------------------------------------------------------
--| COMMAND rigJQfunctionOpen
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-04-2010
--| Last Mod: 14-04-2010
--| Requires: --
--|
--| Summary: Write custom function statement.
--|
--| Format:  rigJQfunctionOpen param1, param2
--|
--| Parameters: string <pName>, string <pArguments> comma delimited list
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQfunctionOpen pName pArguments
	put "function" && pName & "(" & pArguments & "){" & return  after sJqueryScript
end rigJQfunctionOpen






/*----------------------------------------------------------------------
--| COMMAND rigJQfunctionClose
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-04-2010
--| Last Mod: 14-04-2010
--| Requires: --
--|
--| Summary: Write closing statement.
--|
--| Format:  rigJQfunctionClose
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQfunctionClose
	put "}" & return after sJqueryScript
end rigJQfunctionClose







/*----------------------------------------------------------------------
--| COMMAND rigJQcondition
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-04-2010
--| Last Mod: 12-04-2010
--| Requires: rigJQconditionR()
--|
--| Summary: Write conditional statement.
--|
--| Format:  rigJQcondition param1, param2, param3
--|
--| Parameters: string <pCondition>, string <pIfAction>, string <pElseAction> optional
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQcondition pCondition pIfAction pElseAction
	put rigJQconditionR(pCondition, pIfAction, pElseAction) after sJqueryScript
end rigJQcondition







/*----------------------------------------------------------------------
--| FUNCTION rigJQconditionR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-04-2010
--| Last Mod: 12-04-2010
--| Requires: --
--|
--| Summary: Return conditional statement.
--|
--| Format:  rigJQconditionR(param1, param2, param3)
--|
--| Parameters: string <pCondition>, string <pIfAction>, string <pElseAction> optional
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJQconditionR pCondition pIfAction pElseAction
  local tScript

	if pElseAction is "" then
		put "if (" & pCondition & ") {" & return & \
			pIfAction & return & \
			"}" & return into tScript
	else
		put "if (" & pCondition & ") {" & return & \
			pIfAction & return & \
			"}" & return & \
			"else{" & return & \
			pElseAction	 & return & \
			"}" & return into tScript
	end if

	return tScript
end rigJQconditionR









/*----------------------------------------------------------------------
--| COMMAND rigJQcb
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-04-2010
--| Last Mod: 12-04-2010
--| Requires: --
--|
--| Summary: Write closing curly brace.
--|
--| Format:  rigJQcb
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQcb
	put "}" & return after sJqueryScript
end rigJQcb







/*----------------------------------------------------------------------
--| COMMAND rigJQeachOpen
--|
--| Author: rabit
--| Version:  1.0
--| Created: 13-04-2010
--| Last Mod: 13-04-2010
--| Requires: rigJQeachOpenR()
--|
--| Summary: Write iteration statement.
--|
--| Format:  rigJQeachOpen param1, param2, param3
--|
--| Parameters: string <pSelector>, string <pCollection>, string <pCallback>
--|               use eather pSelector or pCollection
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQeachOpen pSelector pCollection pCallback
	put rigJQeachOpenR(pSelector, pCollection, pCallback) after sJqueryScript
end rigJQeachOpen







/*----------------------------------------------------------------------
--| FUNCTION rigJQeachOpenR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 13-04-2010
--| Last Mod: 13-04-2010
--| Requires: --
--|
--| Summary: Return iteration statement.
--|
--| Format:  rigJQeachOpenR(param1, param2, param3)
--|
--| Parameters: string <pSelector>, string <pCollection>, string <pCallback>
--|               use eather pSelector or pCollection
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJQeachOpenR pSelector pCollection pCallback
  local tCollection, tScript

	if pSelector is empty then
		# ITERATE OVER BOTH OBJECTS AND ARRAYS
	if ":" is in pCollection then
		put "{" & pCollection & "}" into tCollection
	else
		put pCollection into tCollection
	end if

	put "$.each(" & tCollection & ", function(index, value){" & return & \
	   pCallback & return into tScript
	else
		# ITERATE OVER A JQUERY OBJECT
		put "$(" & pSelector & ").each(function(index, element) {" & return & \
		   pCallback & return into tScript
	end if

	return tScript
end rigJQeachOpenR







/*----------------------------------------------------------------------
--| COMMAND rigJQeachClose
--|
--| Author: rabit
--| Version:  1.0
--| Created: 13-04-2010
--| Last Mod: 13-04-2010
--| Requires: --
--|
--| Summary: Write closing statement for JQeach.
--|
--| Format:  rigJQeachClose
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQeachClose
	rigJQcloseStatement
end rigJQeachClose







/*----------------------------------------------------------------------
--| FUNCTION rigJQeachCloseR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 20-07-2010
--| Last Mod: 20-07-2010
--| Requires: rigJQcloseStatementR()
--|
--| Summary: Return closing statement for JQeach.
--|
--| Format:  rigJQeachCloseR()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJQeachCloseR
	return rigJQcloseStatementR()
end rigJQeachCloseR






/*----------------------------------------------------------------------
--| COMMAND rigJQvar
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-04-2010
--| Last Mod: 14-04-2010
--| Requires: rigJQvarR
--|
--| Summary: Write variable statements.
--|
--| Format:  rigJQvar param1
--|
--| Parameters: mixed <pVars> use the following form: put "name,value;" into tVarsArray[n]
--|             where n is an integer starting with 1, you can set variables one at a time
--|             with the following form: rigJQvar "name,value;"
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQvar pVars
		put rigJQvarR(pVars) after sJqueryScript
end rigJQvar








/*----------------------------------------------------------------------
--| FUNCTION rigJQvarR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 15-04-2010
--| Last Mod: 19-07-2010
--| Requires: --
--|
--| Summary: Return variable statements.
--|
--| Format:  rigJQvarR(param1)
--|
--| Parameters: mixed <pVars> use the following form: put "name,value;" into tVarsArray[n]
--|               where n is an integer starting with 1, you can set variables one at a time
--|               with the following form: rigJQvar "name,value;"
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJQvarR pVars
  local tVars, tNumVars, tVal, tScript

	put pVars into tVars
	if tVars is an array then
		put the number of lines in the keys of tVars into tNumVars

		repeat with i = 1 to tNumVars
			put tVars[i] into tVal
			put "var" && item 1 of tVal && "=" && item 2 to -1 of tVal & return after tScript
		end repeat
	else
		put "var" && item 1 of tVars && "=" && item 2 to -1 of tVars & return into tScript
	end if

	return tScript
end rigJQvarR









/*----------------------------------------------------------------------
--| COMMAND rigJQaddStatement
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-04-2010
--| Last Mod: 04-04-2010
--| Requires: rigJQaddStatementR()
--|
--| Summary: Adds custom jQuery statement.
--|
--| Format:  rigJQaddStatement param1
--|
--| Parameters: string <pStatement>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQaddStatement pStatement
	put pStatement & return after sJqueryScript
end rigJQaddStatement






/*----------------------------------------------------------------------
--| COMMAND rigJQcloseStatement
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-04-2010
--| Last Mod: 14-04-2010
--| Requires: --
--|
--| Summary: Write closing statement.
--|
--| Format:  rigJQcloseStatement
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigJQcloseStatement
	put "});" & return after sJqueryScript
end rigJQcloseStatement







/*----------------------------------------------------------------------
--| FUNCTION rigJQcloseStatementR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 20-07-2010
--| Last Mod: 20-07-2010
--| Requires: --
--|
--| Summary: Return closing statement.
--|
--| Format:  rigJQcloseStatementR()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJQcloseStatementR
	return "});"
end rigJQcloseStatementR








--| END OF Jquery.livecodescript
--| Location:  ./system/libraries/Jquery.livecodescript
----------------------------------------------------------------------