script "querytojsonHelper"

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
# RevIgniter Query Result to JSON Helper
#
# @package       revIgniter
# @subpackage   Helpers
# @category      Helpers
# @author        rabit@revigniter.com
# @link           https://revigniter.com/userGuide/helpers/querytojsonHelper.html
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
--| FUNCTION rigQueryToJSON
--|
--| Author: rabit
--| Version:  1.3
--| Created: 18-07-10
--| Last Mod: 21-03-14
--| Requires: rigIsNumberedArray()
--|
--| Summary: Convert database query result to JSON.
--| 
--| Format:  rigQueryToJSON(param1, param2)
--|
--| Parameters: array <pResult> the query result, array <pFieldnames> the table field names
--|
--| Return: string
----------------------------------------------------------------------*/

function rigQueryToJSON pResult pFieldnames
  local tResult, tConsecutive, tArrayInfo, tNumbered, tCounter
  local tResultData, tRow, tRowData, tRowConsecutive
  local tRowArrayInfo, tRowNumbered, tRowCounter
  
	if pResult is not an array then
		return FALSE
	else
		put pResult into tResult
	end if
	
	# CHECK IF ARRAY IS NUMBERED CONSECUTIVELY
	put TRUE into tConsecutive
	put rigIsNumberedArray(pResult, tConsecutive) into tArrayInfo

	put item 1 of tArrayInfo into tNumbered

	if tNumbered is TRUE then
		# USE VALUE OF FIRST LINE OF ARRAY KEYS AS STARTING NUMBER
		put item 2 of tArrayInfo into tCounter
	else
		put 1 into tCounter
	end if

	put "{" & quote & "queryToJSON" & quote & ":[" into tResultData

	repeat for each key tRecord in tResult
		if tRecord is an integer then
			if tNumbered is TRUE then
				put tCounter into tRecord
			end if

			put tResult[tRecord] into tRow

			put empty into tRowData
			
			put "{" into tRowData

			# CHECK IF ARRAY IS NUMBERED CONSECUTIVELY
			put TRUE into tRowConsecutive
			put rigIsNumberedArray(tRow, tRowConsecutive) into tRowArrayInfo

			put item 1 of tRowArrayInfo into tRowNumbered

			if tRowNumbered is TRUE then
				# USE VALUE OF FIRST LINE OF ARRAY KEYS AS STARTING NUMBER
				put item 2 of tRowArrayInfo into tRowCounter
			else
				put 1 into tRowCounter
			end if

			repeat for each key tKey in tRow

				if tRowNumbered is TRUE then
					put tRowCounter into tKey
				end if

				if pFieldnames is an array then
					put quote & pFieldnames[tKey] & quote & ":" && quote & tRow[tKey] & quote & "," after tRowData
				else
					put quote & "field" & tKey & quote & ":" && quote & tRow[tKey] & quote & "," after tRowData
				end if

				add 1 to tRowCounter

			end repeat
			delete char -1 of tRowData

			put tRowData & "}," after tResultData

			add 1 to tCounter

		end if
	end repeat

	delete char -1 of tResultData
	
	put "]}" after tResultData

	return tResultData
end rigQueryToJSON






--| END OF querytojsonHelper.livecodescript
--| Location:  ./system/helpers/querytojsonHelper.livecodescript
----------------------------------------------------------------------