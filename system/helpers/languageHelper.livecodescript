script "languageHelper"

##
# revIgniter
#
# An application development framework for LiveCode
# modeled on CodeIgniter.
#
# @package   revIgniter
# @author     rabit@revigniter.com
# @copyright  Copyright (c) 2009 - 2020, dimensionB Bitter u. Bitter GmbH
# @license    https://revigniter.com/userGuide/license.html
# @link        https://revigniter.com
##

## ------------------------------------------------------------------------

##
# Revigniter Language Helpers
#
# @package      revIgniter
# @subpackage  Helpers
# @category     Helpers
# @author       rabit@revigniter.com
# @link          https://revigniter.com/userGuide/helpers/languageHelper.html
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
--| FUNCTION rigLangLine
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-08-14
--| Last Mod: 2010-01-07
--| Requires: --
--|
--| Summary: Fetches a language variable and optionally outputs a form label.
--| 
--| Format: rigLangLine(param1, param2)
--|
--| Parameters: string <pLine> the language line, string <pID> the id of the form element
--|
--| Return: string
----------------------------------------------------------------------*/

function rigLangLine pLine pID
  local tLine
  
	put rigLangLangLine(pLine) into tLine

	if pID is not empty then
		put "<label for=" & quote & pID & quote & ">" & tLine & "</label>" into tLine
	end if

	return tLine
end rigLangLine






--| END OF languageHelper.livecodescript
--| Location:  ./system/helpers/languageHelper.livecodescript
----------------------------------------------------------------------