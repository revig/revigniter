script "overrideOutput"


global gRigA

local sStackInUse


 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-09
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
--| COMMAND rigMinifyOutput
--|
--| Author: rabit
--| Version:  1.1
--| Created: 13-05-2011
--| Last Mod: 29-06-2011
--| Requires: rigGetOutput(), rigPregReplace(), rigSetOutput, _rigDisplay
--|
--| Summary: Minifies HTML output.
--| 
--| Format:  rigMinifyOutput	
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigMinifyOutput
  local tRawHTML, tRegEx, tReplacement, tMinifiedHTML
  
	put rigGetOutput() into tRawHTML
	
	# REMOVE COMMENTS
	put "(?s)(\<!--\s*[^\s\[\>\<].*?--\>)" into tRegEx
	put " " into tReplacement
	put rigPregReplace(tRawHTML, tRegEx, , tReplacement) into tMinifiedHTML

	# REMOVE WHITESPACE
	put "(?s)(\>\s+\<)" into tRegEx
	put "><" into tReplacement
	put rigPregReplace(tMinifiedHTML, tRegEx, , tReplacement) into tMinifiedHTML

	put "(?s)((\s)+)" into tRegEx
	put " " into tReplacement
	put rigPregReplace(tMinifiedHTML, tRegEx, , tReplacement) into tMinifiedHTML

	# DISPLAY HTML
	rigSetOutput tMinifiedHTML	
	_rigDisplay
end rigMinifyOutput




--| END OF overrideOutput.livecodescript
--| Location:  ./application/hooks/overrideOutput.livecodescript
----------------------------------------------------------------------