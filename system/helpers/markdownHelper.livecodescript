script "markdownHelper"

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
# revIgniter Markdown Helper
#
# More information about Markdown: http://daringfireball.net/projects/markdown/
#
# @package       revIgniter
# @subpackage   Helpers
# @category      Helpers
# @author        Andre Alves Garzia (andre@andregarzia.com)
# @link           https://revigniter.com/userGuide/helpers/markdownHelper.html
##

## ------------------------------------------------------------------------



global gRigA




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-27
 --| Last Mod: --
 --| Requires: rigLogMessage
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
--| FUNCTION rigMarkdownVersion
--|
--| Author: Andre Alves Garzia
--| Version:  1.0
--| Created: 30-01-12
--| Last Mod: 30-01-12
--| Requires: --
--|
--| Summary: Get version of Markdown.pl.
--| 
--| Format:  rigMarkdownVersion()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigMarkdownVersion
	return shell("Markdown.pl --shortversion")
end rigMarkdownVersion




/*----------------------------------------------------------------------
--| FUNCTION rigMarkdownAvailable
--|
--| Author: Andre Alves Garzia
--| Version:  1.1
--| Created: 30-01-12
--| Last Mod: 21-03-14
--| Requires: rigMarkdownVersion()
--|
--| Summary: Check if Markown.pl is available.
--| 
--| Format:  rigMarkdownAvailable()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigMarkdownAvailable
	get  rigMarkdownVersion()
	
	if char 1 of it is a number then
		return TRUE
	else
		return FALSE
	end if
end rigMarkdownAvailable





/*----------------------------------------------------------------------
--| FUNCTION rigMarkdown
--|
--| Author: Andre Alves Garzia, modifications rabit
--| Version:  1.1
--| Created: 30-01-12
--| Last Mod: 02-02-15
--| Requires: rigLogMessage
--|
--| Summary: Wrapper for the Markdown engine to convert text to structurally
--| 				  valid XHTML (or HTML).
--| 
--| Format:  rigMarkdown(param1, param2)
--|
--| Parameters: string <pText> the string to be converted, bool <pHTML4> flag
--| 						to determine if text should be converted to HTML instead of XHTML (optional,
--| 						default is FALSE)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigMarkdown pText pHTML4
  local tHTML4, tTextFile, tResult
  
	if pHTML4 is TRUE then
		put " --html4tags" into tHTML4
	else
		put "" into tHTML4
	end if
	
	put tempname() into tTextFile
	put pText into URL ("binfile:" & tTextFile)
	
  if the result <> empty then
    rigLogMessage "error", "Failed to write file! System error:" && the sysError
  end if
	
	put shell("Markdown.pl" & tHTML4 && tTextFile) into tResult
	delete file tTextFile
	
	return tResult
end rigMarkdown







--| END OF markdownHelper.livecodescript
--| Location:  ./system/helpers/markdownHelper.livecodescript
----------------------------------------------------------------------