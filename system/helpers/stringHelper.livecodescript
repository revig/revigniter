script "stringHelper"

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
# revIgniter String Helpers
#
# @package		revIgniter
# @subpackage	Helpers
# @category	  Helpers
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/helpers/stringHelper.html
##

## ------------------------------------------------------------------------





global gRigA

local sAlternatorNum, sStackInUse




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
--| FUNCTION rigTrimSlashes
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-10-09
--| Last Mod: 11-10-09
--| Requires: rigTrim()
--|
--| Summary: Removes any leading/traling slashes from a string:
--|                    /this/that/theother/
--| 
--| Format:  rigTrimSlashes(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigTrimSlashes pStr
	return rigTrim(pStr, "/")
end rigTrimSlashes







/*----------------------------------------------------------------------
--| FUNCTION rigStrip_slashes
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-10-09
--| Last Mod: 11-10-09
--| Requires: rigStripSlashes()
--|
--| Summary: Removes slashes contained in a string or in an array.
--| 
--| Format:  rigStrip_slashes(param1)
--|
--| Parameters: mixed <pStr> string or array
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigStrip_slashes pStr
  local tKey, tVal
  
	if pStr is an array then
		repeat for each key tKey in pStr
			put pStr[tKey] into tVal

			put rigStrip_slashes(tVal) into pStr[tKey]
		end repeat
	else
		put rigStripSlashes(pStr) into pStr
	end if

	return pStr
end rigStrip_slashes








/*----------------------------------------------------------------------
--| FUNCTION rigStripQuotes
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-10-09
--| Last Mod: 11-10-09
--| Requires: --
--|
--| Summary: Removes single and double quotes from a string.
--| 
--| Format:  rigStripQuotes(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigStripQuotes pStr
	replace quote with "" in pStr
	replace "'" with "" in pStr

	return pStr
end rigStripQuotes








/*----------------------------------------------------------------------
--| FUNCTION rigQuotesToEntities
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-10-09
--| Last Mod: 11-10-09
--| Requires: --
--|
--| Summary: Converts single and double quotes to entities.
--| 
--| Format:  rigQuotesToEntities(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigQuotesToEntities pStr
	replace "\'" with "&#39;" in pStr
	replace ("\" & quote) with "&quot;" in pStr
	replace "'" with "&#39;" in pStr
	replace quote with "&quot;" in pStr

	return pStr
end rigQuotesToEntities







/*----------------------------------------------------------------------
--| FUNCTION rigReduceDoubleSlashes
--|
--| Author: rabit
--| Version:  1.1
--| Created: 11-10-09
--| Last Mod: 07-01-10
--| Requires: rigPregReplace()
--|
--| Summary: Converts double slashes in a string to a single slash,
--|                   except those found in http://
--|
--|                   http://www.some-site.com//index.lc
--|
--|                   becomes:
--|
--|                   http://www.some-site.com/index.lc
--| 
--| Format:  rigReduceDoubleSlashes(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigReduceDoubleSlashes pStr
  local tRegEx
  
	put "([^:]//+)" into tRegEx
    
  return rigPregReplace(pStr, tRegEx, "//", "/")
end rigReduceDoubleSlashes








/*----------------------------------------------------------------------
--| FUNCTION rigReduceMultiples
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-10-09
--| Last Mod: 11-10-09
--| Requires: rigPregQuote(), rigPregReplace(), rigTrim()
--|
--| Summary: Reduces multiple instances of a particular character.  Example:
--|
--|                   Fred, Bill,, Joe, Jimmy
--|
--|                   becomes:
--|
--|                   Fred, Bill, Joe, Jimmy
--| 
--| Format:  rigReduceMultiples(param1, param2, param3)
--|
--| Parameters: string <pStr>, string <pCharacter> the character you wish to reduce,
--|                       bool <pTrim> TRUE/FALSE - whether to trim the character from the beginning/end
--|
--| Return: string
----------------------------------------------------------------------*/

function rigReduceMultiples pStr pCharacter pTrim
  local tCharacter, tTrim, tPregQuoted, tRegEx, tStr
  
	if pCharacter is empty then
		put "," into tCharacter
	else
		put pCharacter into tCharacter
	end if
	
	if pTrim is empty then
		put FALSE into tTrim
	else
		put pTrim into tTrim
	end if

	put rigPregQuote(tCharacter, "#") into tPregQuoted

	put "(" & tPregQuoted & "{2,})" into tRegEx

	put rigPregReplace(pStr, tRegEx, "", tCharacter) into tStr

	if tTrim is TRUE then
		put rigTrim(tStr, tCharacter) into tStr
	end if

	return tStr
end rigReduceMultiples








/*----------------------------------------------------------------------
--| FUNCTION rigRandomString
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-10-12
--| Last Mod: 2018-10-24
--| Requires: rigUniqid()
--|
--| Summary: Create a random string. Useful for generating passwords or hashes.
--| 
--| Format:  rigRandomString(param1, param2)
--|
--| Parameters: string <pType> type of random string, options: alnum, numeric, nozero, unique, 
--|                       integer <pLen> number of characters
--|
--| Return: string
----------------------------------------------------------------------*/

function rigRandomString pType pLen
  local tType, tLen, tPool, tStr
  
	if pType is empty then
		put "alnum" into tType
	else
		put pType into tType
	end if

	if pLen is empty then
		put 8 into tLen
	else
		put pLen into tLen
	end if

	switch tType
		case "alnum"
		case "numeric"
		case "nozero"

		switch tType
			case "alnum"
				put "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" into tPool					
				break
			case "numeric"
				put "0123456789" into tPool
				break
			case "nozero"
				put "123456789" into tPool
				break
		end switch

		repeat tLen
			put any char of tPool after tStr
		end repeat

		return tStr
		break
	case "unique"
		return rigUniqid()
		break     
	end switch
end rigRandomString







/*----------------------------------------------------------------------
--| FUNCTION rigAlternator
--|
--| Author: rabit
--| Version:  1.1
--| Created: 12-10-09
--| Last Mod: 07-11-09
--| Requires: --
--|
--| Summary: Allows strings to be alternated.  See docs...
--| 
--| Format:  rigAlternator(param1, param2, ...)
--|
--| Parameters: integer <pItem> the item number, as many parameters as needed
--|
--| Return: string
----------------------------------------------------------------------*/

function rigAlternator
  local tParamNum, tParams, tParamsOffset, tItemNum, tItem
  
  put the paramcount into tParamNum
    
  if tParamNum = 0 then
    rigResetAlternator
    return ""
  end if
    
  if sAlternatorNum is empty then
    put 1 into sAlternatorNum
  end if
    
  # REMOVE HANDLER NAME FROM PARAMS
  put the params into tParams
  put offset("(",tParams) into tParamsOffset
  put char (tParamsOffset + 1) to -2 of tParams into tParams

  put sAlternatorNum mod tParamNum into tItemNum
  if tItemNum is 0 then
    put tParamNum into tItemNum
  end if
    
  # INCREMENT THE COUNTER
  add 1 to sAlternatorNum

  put item tItemNum of tParams into tItem
  # REMOVE QUOTATION MARKS
  delete char 1 of tItem
  delete char -1 of tItem

  return tItem
end rigAlternator







/*----------------------------------------------------------------------
--| COMMAND rigResetAlternator
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-11-09
--| Last Mod: 07-11-09
--| Requires: --
--|
--| Summary: Resets the alternator counter.
--| 
--| Format:  rigResetAlternator
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigResetAlternator
	put "" into sAlternatorNum
end rigResetAlternator








/*----------------------------------------------------------------------
--| FUNCTION rigRepeater
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-10-09
--| Last Mod: 12-10-09
--| Requires: --
--|
--| Summary: rigRepeater function
--| 
--| Format:  rigRepeater(param1, param2)
--|
--| Parameters: string <pData>, integer <pNum> number of repeats
--|
--| Return: string
----------------------------------------------------------------------*/

function rigRepeater pData pNum
  local tNum, tStr
  
  if pNum is empty then
    put 1 into tNum
  else
    put pNum into tNum
  end if
    
  if tNum > 0 then
    repeat tNum
      put pData after tStr
    end repeat
        
    return tStr
  end if
    
	return ""
end rigRepeater









--| END OF stringHelper.livecodescript
--| Location:  ./system/helpers/stringHelper.livecodescript
----------------------------------------------------------------------