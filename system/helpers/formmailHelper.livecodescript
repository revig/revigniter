script "formmailHelper"

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
# Revigniter FormMail Helpers
#
# @package		RevIgniter
# @subpackage	Helpers
# @category	  Helpers
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/helpers/formmail_helper.html
##

## ------------------------------------------------------------------------




global gRigA

local sRawText, sFMtextComplete, sFMprefix, sFMsuffix, sFMvars





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
--| FUNCTION rigFormMail
--|
--| Author: rabit
--| Version:  1.1
--| Created: 03-03-10
--| Last Mod: 02-02-15
--| Requires: rigLogMessage
--|
--| Summary: Fetch form mail template.
--| 
--| Format:  rigFormMail(param1, param2, param3)
--|
--| Parameters: string <pFilePath> path to template relative to root, array <pFormMailVars> data to replace
--|               the placeholders with, string <pPrefix>, string <pSuffix>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigFormMail pFilePath pFormMailVars pPrefix pSuffix
  put pFormMailVars into sFMvars

  if pPrefix is empty then
    put "<#" into sFMprefix
  else
    put pPrefix into sFMprefix
  end if

  if pSuffix is empty then
    put ">" into sFMsuffix
  else
    put pSuffix into sFMsuffix
  end if

  if there is a file pFilePath then
    put URL format("binfile:%s", pFilePath) into sRawText
    
    if the result is empty then
      return TRUE
    else
      rigLogMessage "error", "Failed to read file! System error:" && the sysError
    end if
    
  end if

  rigLogMessage "error", "The form mail template was not found!"

  return FALSE
end rigFormMail








/*----------------------------------------------------------------------
--| FUNCTION rigFormMailReplace
--|
--| Author: rabit
--| Version:  1.1
--| Created: 03-03-10
--| Last Mod: 23-05-10
--| Requires: rigPregReplace(), rigFmSubstitute
--|
--| Summary: Replace placeholders.
--| 
--| Format:  rigFormMailReplace()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormMailReplace
  local tRegEx, tReplacement
  
	put "(" & sFMprefix & "[A-Za-z1-9]+" & sFMsuffix & ")" into tRegEx
	put "_callback_rigFmSubstitute" into tReplacement

	return rigPregReplace(sRawText, tRegEx, , tReplacement)
end rigFormMailReplace







/*----------------------------------------------------------------------
--| COMMAND rigFmSubstitute
--|
--| Author: rabit
--| Version:  1.1
--| Created: 03-03-10
--| Last Mod: 21-03-14
--| Requires: --
--|
--| Summary: Callback handler for rigPregReplace(). Uses sFMvars array for replacements.
--| 
--| Format:  rigFmSubstitute param1
--|
--| Parameters: string <pTags>
--|
--| Return: string
----------------------------------------------------------------------*/

command rigFmSubstitute pTags
  local tPrefixNum, tSuffixNum, tKey
  
	put 1 + (the number of chars of sFMprefix) into tPrefixNum
	put -1 - (the number of chars of sFMsuffix) into tSuffixNum
	put char tPrefixNum to tSuffixNum of pTags into tKey

	return sFMvars[tKey]
end rigFmSubstitute









--| END OF formmailHelper.livecodescript
--| Location:  ./system/helpers/formmailHelper.livecodescript
----------------------------------------------------------------------