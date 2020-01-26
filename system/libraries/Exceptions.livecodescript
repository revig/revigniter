script "Exceptions"

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
# revIgniter Exceptions Library
#
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Exceptions
# @author		  rabit@revigniter.com
# @link		    --
##




global gRigA

local sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-11
 --| Last Mod: --
 --| Requires: --
 --|
 --| Summary:  Run security check.
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
    end if

  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack






/*----------------------------------------------------------------------
--| COMMAND rigLogException
--|
--| Author: rabit
--| Version:  1.1
--| Created: 28-06-09
--| Last Mod: 23-07-16
--| Requires: rigFetchControllerHandler(), rigLogMessage
--|
--| Summary:  This command logs Rev error messages.
--|
--| Format:  rigLogException param1, param2, param3, param4
--|
--| Parameters: string <pErrorData>, bool <pDisplayError>, string <pFile>, string <pHandler>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLogException pErrorData pDisplayError pFile pHandler
  local tFile, tHandler, tErrorData

	if pFile is empty then
		put gRigA["controller"] into tFile
	else
		put pFile into tFile
	end if
	if pHandler is empty then
		put rigFetchControllerHandler() into tHandler
	else
		put pHandler into tHandler
	end if

	put "RevError - Current File:" && tFile & ", Current Handler:" && tHandler & CR & pErrorData into tErrorData
	rigLogMessage "error", tErrorData, pDisplayError
end rigLogException








/*----------------------------------------------------------------------
--| COMMAND rigShow404Page
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-06-29
--| Last Mod: 2020-01-24
--| Requires: rigLogMessage, rigShowErrorPage
--|
--| Summary:  404 Page Not Found Handler.
--|
--| Format:  rigShow404Page param1
--|
--| Parameters: mixed <pPage>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigShow404Page pPage
  local tPage, tHeading, tMessage

	if pPage is an array then
		put pPage["page"] into tPage
	else
		put pPage into tPage
	end if

	put  "404 Page Not Found" into tHeading
	put "Sorry, but the page you were trying to view does not exist." into tMessage

	rigLogMessage "error", "404 Page Not Found --> " & tPage
	put rigShowErrorPage(tHeading, tMessage, "error404", 404)
	exit to top
end rigShow404Page







/*----------------------------------------------------------------------
--| FUNCTION rigShowErrorPage
--|
--| Author: rabit
--| Version:  1.2
--| Created: 29-06-09
--| Last Mod: 02-02-15
--| Requires: error files, rigSetStatusHeader, rigLogMessage
--|
--| Summary: General Error Page
--|            This function takes an error message as input
--|            (either as a string or an array) and displays
--|            it using the specified template.
--|
--| Format:  rigShowErrorPage(param1, param2, param3)
--|
--| Parameters: string <pHeading>, string <pMessage>, string <pTemplate>, integer <pStatusCode>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigShowErrorPage pHeading pMessage pTemplate pStatusCode
  local tMessage, tTemplate, tStatusCode, tErrorMsg, tErrorFilePath
  local tBuffer, tOutput

	put pHeading into gRigA["errorData"]["heading"]
	put pMessage into tMessage

	if pTemplate is empty then
		put "errorGeneral" into tTemplate
	else
		put pTemplate into tTemplate
	end if

	if pStatusCode is empty then
		put 500 into tStatusCode
	else
		put pStatusCode into tStatusCode
	end if

  rigSetStatusHeader tStatusCode

  if tMessage is an array then
    put "<p>" into tErrorMsg
    repeat for each key tKey in tMessage
      put tMessage[tKey] & "</p><p>" after tErrorMsg
    end repeat
    delete char -3 to -1 of tErrorMsg
  else
    put "<p>" & tMessage & "</p>" into tErrorMsg
  end if

  put tErrorMsg into gRigA["errorData"]["message"]

  put gRigA["APPPATH"] & "errors/" & tTemplate & gRigA["EXT"] into tErrorFilePath
  put URL format("binfile:%s", tErrorFilePath) into tBuffer

  if the result <> empty then
    rigLogMessage "error", "Failed to read file! System error:" && the sysError
    put "Failed to read error file." into tBuffer
  end if

  put merge(tBuffer) into tOutput
  return tOutput
end rigShowErrorPage









--| END OF Exceptions.livecodescript
--| Location:  ./system/libraries/Exceptions.livecodescript
----------------------------------------------------------------------
