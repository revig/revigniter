script "arrayHelper"

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
# revIgniter Array Helpers
#
# @package		revIgniter
# @subpackage	Helpers
# @category	  Helpers
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/helpers/arrayHelper.html
##

## ------------------------------------------------------------------------




global gRigA

local sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-20
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
--| FUNCTION rigArrayElement
--|
--| Author: rabit
--| Version:  1.2
--| Created: 06-10-09
--| Last Mod: 04-01-10
--| Requires: --
--|
--| Summary: Lets you determine whether an array index is set and whether it has a value.
--|            if the value does not exist it returns FALSE (or whatever you specify as the default value).
--| 
--| Format:  rigArrayElement(param1, param2, param3)
--|
--| Parameters: string <pItem>, array <pArray>, mixed <pDefault> 
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigArrayElement pItem pArray pDefault
  local tDefault
  
	if pDefault is empty then
		put FALSE into tDefault
	else
		put pDefault into tDefault
	end if

	if pArray[pItem] is empty then
	--if pItem is not among the keys of pArray then
		return tDefault
	end if

	return pArray[pItem]
end rigArrayElement









/*----------------------------------------------------------------------
--| FUNCTION rigArrayRandElement
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-10-09
--| Last Mod: 06-10-09
--| Requires: --
--|
--| Summary: Takes an array as input and returns a random element.
--|            Works with one-dimensional arrays only
--| 
--| Format:  rigArrayRandElement(param1)
--|
--| Parameters: array <pArray>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigArrayRandElement pArray
  local tKey
  
  if pArray is not an array then
    return pArray
  end if
    
  put any line in the keys of pArray into tKey
  
  return pArray[tKey]
end rigArrayRandElement







/*----------------------------------------------------------------------
--| FUNCTION rigArrayKeys
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-07-09
--| Last Mod: 21-07-09
--| Requires: --
--|
--| Summary: Returns the keys, numeric and string, from the input array.
--| 
--| Format:  rigArrayKeys(param1)
--|
--| Parameters: array <pAssocArray>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigArrayKeys pAssocArray
  local tCounter, tKey, tKeysArray
  
	put 0 into tCounter
	repeat for each key tKey in pAssocArray
		add 1 to tCounter
		put tKey into tKeysArray[tCounter]
	end repeat

	return tKeysArray
end rigArrayKeys






/*----------------------------------------------------------------------
--| FUNCTION rigArrayValues
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-07-09
--| Last Mod: 21-07-09
--| Requires: --
--|
--| Summary: Returns all the values from the input array and indexes numerically the array.
--| 
--| Format:  rigArrayValues(param1)
--|
--| Parameters: array <pAssocArray>, bool <pUseApostrophe>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigArrayValues pAssocArray pUseApostrophe
  local tCounter, tKey, tValuesArray
  
	put 0 into tCounter
	repeat for each key tKey in pAssocArray
		add 1 to tCounter
			if pUseApostrophe is TRUE then
				put "'" & pAssocArray[tKey] & "'" into tValuesArray[tCounter]
			else
				put pAssocArray[tKey] into tValuesArray[tCounter]
			end if
	end repeat

	return tValuesArray
end rigArrayValues







/*----------------------------------------------------------------------
--| FUNCTION rigArraySplice
--|
--| Author: rabit
--| Version:  1.1
--| Created: 22-07-09
--| Last Mod: 05-11-09
--| Requires: --
--|
--| Summary: Retrieve a portion of an array. Works with numbered arrays only.
--| 
--| Format:  rigArraySplice(param1, param2, param3)
--|
--| Parameters: array <pArray>, integer <pOffset>, integer <pLength>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigArraySplice pArray pOffset pLength
  local tKeysNum, tKeysList, tStartLine, tEndLine, tNewKeysList
  local tCounter, tNewArray
  
	 if (pLength is not an integer) or (pLength < 1) or (pOffset is not an integer) then
		return pArray
	end if

    put the number of lines in the keys of pArray into tKeysNum
    put the keys of pArray into tKeysList
    
    put 1 + pOffset into tStartLine
    put (tStartLine + pLength) -1 into tEndLine

	sort lines of tKeysList numeric
    
    put line tStartLine to tEndLine of tKeysList into tNewKeysList
    
    put 0 into tCounter
    repeat for each line thisLine in tNewKeysList
        add 1 to tCounter
        if tCounter <= tKeysNum then
            put pArray[thisLine] into tNewArray[tCounter]
        else
             exit repeat
        end if
    end repeat
    
    return tNewArray
end rigArraySplice







/*----------------------------------------------------------------------
--| FUNCTION rigImplode
--|
--| Author: rabit
--| Version:  1.4
--| Created: 09-07-09
--| Last Mod: 21-12-14
--| Requires: rigIsNumberedArray()
--|
--| Summary: Joins array elements with a string.
--| 
--| Format:  rigImplode(param1, param2)
--|
--| Parameters: array <pArray>, string <pGlue> the string to join the array elements with
--|
--| Return: string
----------------------------------------------------------------------*/

function rigImplode pArray pGlue
  local tKeys, tBuf
  
	if item 1 of rigIsNumberedArray(pArray) is "true" then
		# SORT ARRAY KEYS
		put the keys of pArray into tKeys
		sort tKeys numeric

		# BUILD STRING
		repeat for each line k in tKeys
			put pArray[k] & pGlue after tBuf
		end repeat

		# REMOVE LAST GLUE
		get the len of pGlue
		delete char - it to -1 of tBuf
	else
		# ARRAY IS NOT NUMBERED
		put pArray into tBuf
		combine tBuf using numToCodepoint(1)
		replace numToCodepoint(1) with pGlue in tBuf
	end if

	return tBuf
end rigImplode







/*----------------------------------------------------------------------
--| FUNCTION rigElementsList
--|
--| Author: rabit
--| Version:  1.3
--| Created: 09-07-09
--| Last Mod: 11-08-16
--| Requires: --
--|
--| Summary: Returns a list of array elements, each on a seperate line.
--| 
--| Format:  rigElementsList(param1)
--|
--| Parameters: array <pArray>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigElementsList pArray
  local tElementsList
  
   repeat for each element thisElement in pArray
      if thisElement is an array then
         put rigElementsList(thisElement) & return after tElementsList
      else
         put thisElement & return after tElementsList
      end if
   end repeat
   delete char -1 of tElementsList
   
   return tElementsList
end rigElementsList










--| END OF arrayHelper.livecodescript
--| Location:  ./system/helpers/arrayHelper.livecodescript
----------------------------------------------------------------------