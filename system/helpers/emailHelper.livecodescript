script "emailHelper"

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
# revIgniter Email Helpers
#
# @package		revIgniter
# @subpackage	Helpers
# @category	  Helpers
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/helpers/emailHelper.html
##

## ------------------------------------------------------------------------




global gRigA




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-28
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

  if the short name of the target <> the short name of me then
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack





/*----------------------------------------------------------------------
--| FUNCTION rigValidEmail
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-09-09
--| Last Mod: 18-09-09
--| Requires: --
--|
--| Summary: Email validation.
--|
--| Format:  rigValidEmail(param1)
--|
--| Parameters: string <pAddress>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigValidEmail pAddress
  local tRegEx

	if rigLibIsLoaded("Email") is not TRUE then
		put "(?ix)^([a-z0-9\+_\-]+)(\.[a-z0-9\+_\-]+)*@([a-z0-9\-]+\.)+[a-z]{2,6}$" into tRegEx

		return matchtext(pAddress,tRegEx)
	end if

	return rigMailValidEmail(pAddress)
end rigValidEmail







/*----------------------------------------------------------------------
--| FUNCTION rigSendEmail
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2009-09-18
--| Last Mod: 2019-01-13
--| Requires: _rigCleanMailAddress(), rigShellEscape(), _rigTempMailPath(), rigLogMessage
--|
--| Summary: Send an email.
--|
--| Format:  rigSendEmail(param1, param2, param3[, param4][, param5][, param6])
--|
--| Parameters: string <pRecipient>, string <pSubject>, string <pMessage>,
--|               string <pCC> (optional), string <pBCC> (optional), string <pSender> (optional)
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigSendEmail pRecipient pSubject pMessage pCC pBCC pSender
  local tFrom, tRecipient, tBody, tSubject, tCC, tBCC
  local tTempMailPath, tCmd, tResult

	if pSender is not empty then
		put _rigCleanMailAddress(pSender) into tFrom
	end if
	put _rigCleanMailAddress(pRecipient) into tRecipient

	# PREPARE HEADER DATA FOR SHELL COMMAND
	put pMessage into tBody
	put rigShellEscape(pSubject) into tSubject
	put rigShellEscape(tRecipient) into tRecipient
	put rigShellEscape(pCC) into tCC
	put rigShellEscape(pBCC) into tBCC
	put rigShellEscape(tFrom) into tFrom

	# TEMPORARILY SAVE BODY TO DISK
	#
	#GET PATH TO TEMP DIRECTORY
	put _rigTempMailPath() into tTempMailPath
	put tBody into url ("binfile:" & tTempMailPath)

	if the result <> empty then
		rigLogMessage "error", "Error on saving temporary eMail data:" && tTempMailPath && "System error:" && the sysError
	end if

	# BUILD SHELL COMMAND
	put "cat" && rigQ(tTempMailPath) && "| mail -s" && rigQ(tSubject) into tCmd

	if tCC is not empty then
		put " -c" && rigQ(tCC) after tCmd
	end if
	if tBCC is not empty then
		put " -b" && rigQ(tBCC) after tCmd
	end if

	if tFrom is not empty then
		# THE DOUBLE DASH STOPS MAIL FROM PARSING THE -f OPTION AND PASSES IT TO SENDMAIL.
		# THE -f OPTION SETS THE ENVELOPE SENDER ADDRESS IN SENDMAIL.
		put space & rigQ(tRecipient) && "-- -f" && rigQ(tFrom) after tCmd
		# HOWEVER THE BEHAVIOR FOR -- HAS CHANGED AND IT SEEMS THAT THERE IS NO WAY
		# TO SPECIFY THE SENDER ADDRESS USING MAIL THROUGH THE COMMAND LINE ANYMORE.
		# SO, THIS IS WHY THE pSender PARAMETER IS OPTIONAL SINCE HANDLER VERSION 1.3
	else
		# IF NO SENDER ADDRESS IS PROVIDED THE SENDER FIELD APPEARS AS "<username@domain.com>"
		# IN DEFAULT CONFIGURATIONS, IT'S THE ACCOUNT NAME AND HOST NAME OF THE SENDING USER.
		put space & rigQ(tRecipient) after tCmd
	end if

	# SEND SHELL COMMAND
	put shell(tCmd) into tResult

	# REMOVE TEMP MAIL FILE
	delete file tTempMailPath
	if the result is not empty then
		rigLogMessage "error", "Temporary eMail data could not be deleted:" && tTempMailPath
	end if

	# CHECK MAIL RESULT
	if tResult is empty then
		return TRUE
	else
		rigLogMessage "error", "Error on sending eMail:" && tResult
		return FALSE
	end if
end rigSendEmail







/*----------------------------------------------------------------------
--| FUNCTION _rigCleanMailAddress
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-09-18
--| Last Mod: 2017-06-27
--| Requires: --
--|
--| Summary: Clean extended email address: Joe Smith <joe@smith.com>.
--|
--| Format:  _rigCleanMailAddress(param1)
--|
--| Parameters: string <pEmail>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCleanMailAddress pEmail
  local tRegEx, tFoundTextVar

	put "\<(.*)\>" into tRegEx
	put empty into tFoundTextVar -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	get matchText(pEmail,tRegEx,tFoundTextVar)

    	if it is TRUE then
		return tFoundTextVar
	else
		return pEmail
	end if

end _rigCleanMailAddress






--| END OF emailHelper.livecodescript
--| Location:  ./system/helpers/emailHelper.livecodescript
----------------------------------------------------------------------