script "queryvaluesHelper"

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
# RevIgniter Query Key Value Pairs Helper
#
# @package		  revIgniter
# @subpackage  Helpers
# @category     Helpers
# @author		    rabit@revigniter.com
# @link		      https://revigniter.com/userGuide/helpers/queryvaluesHelper.html
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
--| FUNCTION rigQueryValues
--|
--| Author: rabit
--| Version:  1.4
--| Created: 25-07-09
--| Last Mod: 03-11-12
--| Requires: rigIsNumberedArray()
--|
--| Summary: Return values or key value pairs of database query result.
--| 
--| Format:  rigQueryValues(param1, param2, param3, param4)
--|
--| Parameters: array <pResult> the query result, string <pKeyValueDelim> key value delimiter,
--|               string <pRecordDelim> record delimiter, array <pFieldnames> the table field names
--|
--| Return: string
----------------------------------------------------------------------*/

function rigQueryValues pResult pKeyValueDelim pRecordDelim pFieldnames
  local tResult, tKeyValueDelim, tRecordDelim, tArrayInfo, tConsecutive
  local tNumbered, tCounter, tRow, tRowData, tRowConsecutive
  local tRowArrayInfo, tRowNumbered, tRowCounter, tResultData
  
	if pResult is not an array then
		return FALSE
	else
		put pResult into tResult
	end if

	if pKeyValueDelim is "" then
		put " => " into tKeyValueDelim
	else
		put pKeyValueDelim into tKeyValueDelim
	end if

	if pRecordDelim is "" then
		put ", " into tRecordDelim
	else
		put pRecordDelim into tRecordDelim
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

	repeat for each key tRecord in tResult
		if tRecord is an integer then
			if tNumbered is TRUE then
				put tCounter into tRecord
			end if

			put tResult[tRecord] into tRow

			put empty into tRowData

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
		
				if tKeyValueDelim is "<>" then
					# DON'T WRITE KEYS
					put tRow[tKey] & tRecordDelim after tRowData
				else

					if pFieldnames is an array then
						put pFieldnames[tKey] & tKeyValueDelim & tRow[tKey] & tRecordDelim after tRowData
					else
						put tKey & tKeyValueDelim & tRow[tKey] & tRecordDelim after tRowData
					end if
				end if

				add 1 to tRowCounter
	
			end repeat
			delete char -2  to -1 of tRowData

			put tRowData & "<br />" & return after tResultData

			add 1 to tCounter

		end if
	end repeat

	delete char -7  to -1 of tResultData

	return tResultData
end rigQueryValues










--| END OF queryvaluesHelper.livecodescript
--| Location:  ./system/helpers/queryvaluesHelper.livecodescript
----------------------------------------------------------------------