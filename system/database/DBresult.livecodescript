script "DBresult"

##
# revIgniter
#
# An application development framework for LiveCode
# modeled on CodeIgniter
#
# @package		revIgniter
# @author		  rabit@revigniter.com
# @copyright	Copyright (c) 2009 - 2020, dimensionB Bitter u. Bitter GmbH
# @license		https://revigniter.com/userGuide/license.html
# @link		    https://revigniter.com
##

## ------------------------------------------------------------------------

##
# Database Result Library
#
# This is the platform-independent result library.
# This library will not be called directly. Rather, the adapter
# library for the specific database will extend it.
#
# @category	Database
# @author		rabit@revigniter.com
# @link		  https://revigniter.com/userGuide/database/
##



global gRigA

local sDBresult, sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-17
 --| Last Mod: --
 --| Requires: _rigSetDefaultValues
 --|
 --| Summary:  Run security check and set initial values.
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

      # SET INITIAL VALUES
      _rigSetDefaultValues
      #
    end if

  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack




/*----------------------------------------------------------------------
--| COMMAND _rigSetDefaultValues
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-04
--| Last Mod: 2019-01-04
--| Requires: --
--|
--| Summary: Set default values for library variables.
--|
--| Format:  _rigSetDefaultValues
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetDefaultValues
  -- put empty into sDBresult["connid"] -- not used, use global gRigA["databaseID"] instead
  put empty into gRigA["databaseID"]
  put empty into sDBresult["resultarray"]
  put 0 into sDBresult["currentrow"]
  put 0 into sDBresult["numrows"]
  put empty into sDBresult["rowdata"]

  put empty into sDBresult["fieldNames"]
  put empty into sDBresult["fieldNumbers"]
end _rigSetDefaultValues





/*----------------------------------------------------------------------
--| FUNCTION rigDBresult
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2009-09-29
--| Last Mod: 2018-04-30
--| Requires: rigFetchDBdriverSetting(), _rigDataSeek(), _rigFetchResultArray,
--|            rigListFields(), rigLogMessage
--|
--| Summary: Query result as array.
--|
--| Format:  rigDBresult(param1)
--|
--| Parameters: bool <pChangeFieldNamesListDelimiter>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDBresult pChangeFieldNamesListDelimiter
  local tResultID, tTemp, tError

	if sDBresult["resultarray"] is an array then
		return sDBresult["resultarray"]
	end if

	# IN THE EVENT THAT QUERY CACHING IS ON THE RESULT_ID VARIABLE
	# WILL RETURN FALSE SINCE THERE ISN'T A VALID SQL RESOURCE SO
	# WE'LL SIMPLY RETURN EMPTY.
	-- if sDBresult["resultid"] is FALSE or sDBresult["numrows"] is 0 then
		-- return ""
	-- end if

	# GET THE RECORD SET ID
	put rigFetchDBdriverSetting("resultid") into tResultID

	# WHEN CACHING IS ENABLED THE PLATFORM-SPECIFIC DRIVER IS NOT LOADED.
	--put rigFetchActiveGroup() into tSettingsGroup
	--put rigFetchDBsetting(tSettingsGroup,  "cacheon") into tCacheOn
	--if tCacheOn is not TRUE then
		get _rigDataSeek(tResultID, 0)
		put empty into tTemp
		_rigFetchResultArray tResultID, tTemp, pChangeFieldNamesListDelimiter
		put the result into tError
		put tTemp into sDBresult["resultarray"]

		put rigListFields(tResultID) into sDBresult["fieldNames"] -- variance
		put rigFieldNumbers(sDBresult["fieldNames"]) into sDBresult["fieldNumbers"] -- variance

	--else
		--put empty into sDBresult["resultarray"]
	--end if

	if tError is not empty then
		rigLogMessage "error", "Unable to build a query result array!"
	end if

	return sDBresult["resultarray"]
end rigDBresult









/*----------------------------------------------------------------------
--| FUNCTION rigDbRow
--|
--| Author: rabit
--| Version:  1.2
--| Created: 28-09-09
--| Last Mod: 02-11-09
--| Requires: _rigDbRowArray()
--|
--| Summary: Get row data.
--|
--| Format:  rigDbRow(param1)
--|
--| Parameters: string <pN>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbRow pN
  local tN

	if pN is empty then
		put 1 into tN
	else
		put pN into tN
	end if

	if tN is not an integer then
		# WE CACHE THE ROW DATA FOR SUBSEQUENT USES
		if sDBresult["rowdata"] is not an array then
			put _rigDbRowArray(1) into sDBresult["rowdata"]
		end if

		if tN is among the keys of sDBresult["rowdata"] then
			return sDBresult["rowdata"][tN]
		end if

		# RESET THE pN VARIABLE IF THE RESULT WAS NOT ACHIEVED
		put 1 into tN
	end if

	return _rigDbRowArray(tN)
end rigDbRow







/*----------------------------------------------------------------------
--| COMMAND rigDbSetRow
--|
--| Author: rabit
--| Version:  1.0
--| Created: 02-10-09
--| Last Mod: 02-10-09
--| Requires: _rigDbRowArray()
--|
--| Summary: Assigns an item into a particular column slot. Needs documentation!!!!!!!!!!
--|
--| Format:  rigDbSetRow param1, param2
--|
--| Parameters: mixed <pKey>, string <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbSetRow pKey pValue
  local tK, tV

	# WE CACHE THE ROW DATA FOR SUBSEQUENT USES
	if sDBresult["rowdata"] is not an array then
		put _rigDbRowArray(0) into sDBresult["rowdata"]
	end if

	if pKey is an array then
		repeat for each key tK in pKey
			put pKey[tK] into tV
			put tV into sDBresult["rowdata"][tK]
		end repeat

		exit rigDbSetRow
	end if

	if (pKey is not empty) and (pValue is not empty) then
		put pValue into sDBresult["rowdata"][pKey]
	end if
end rigDbSetRow









/*----------------------------------------------------------------------
--| FUNCTION _rigDbRowArray
--|
--| Author: rabit
--| Version:  1.4
--| Created: 28-09-09
--| Last Mod: 09-09-11
--| Requires: rigFetchDBdriverSetting()
--|
--| Summary: Returns a single result row.
--|
--| Format:  _rigDbRowArray(param1)
--|
--| Parameters: integer <pN>
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigDbRowArray pN
  local tN, tResult, tRowArray, tResultID, tFieldnamesList
  local tField, tVal, tRowAsocArray

	if pN is empty then
		put 1 into tN
	else
		put pN into tN
	end if

	put sDBresult["resultarray"] into tResult

	if the number of lines in the keys of tResult is 0 then
		return tResult
	end if

	if (tN <> sDBresult["currentrow"]) and (tResult[tN] is an array) then
		put tN into sDBresult["currentrow"]
	end if

	-- return tResult[tN] -- variance
	-- variance
	# REPLACE NUMBERS WITH FIELD NAMES
	put tResult[tN] into tRowArray

	# WE DONT'T USE combine sDBresult["fieldNames"] TO BUILD THE LIST OF FIELD NAMES,
	# OTHERWISE THE ORDER OF FIELD NAMES GET SCREWED
	put rigFetchDBdriverSetting("resultid") into tResultID
	put revDatabaseColumnNames(tResultID) into tFieldnamesList

	repeat with i = 1 to the number of items in tFieldnamesList
		put item i of tFieldnamesList into tField
		put tRowArray[i] into tVal
		put tVal into tRowAsocArray[tField]
	end repeat

	return tRowAsocArray
end _rigDbRowArray








/*----------------------------------------------------------------------
--| FUNCTION rigDbFirstRow
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-10-09
--| Last Mod: 02-11-09
--| Requires: --
--|
--| Summary: Returns the "first" row.
--|
--| Format:  rigDbFirstRow()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbFirstRow
	if sDBresult["resultarray"] is not an array then
		return sDBresult["resultarray"]
	end if

	put 1 into sDBresult["currentrow"]

	return sDBresult["resultarray"][1]
end rigDbFirstRow








/*----------------------------------------------------------------------
--| FUNCTION rigDbLastRow
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-10-09
--| Last Mod: 02-11-09
--| Requires: --
--|
--| Summary: Returns the "last" row.
--|
--| Format:  rigDbLastRow()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbLastRow
  local tLastRow

	if sDBresult["resultarray"] is not an array then
		return sDBresult["resultarray"]
	end if

	put line -1 in the keys of sDBresult["resultarray"] into tLastRow
	put tLastRow into sDBresult["currentrow"]

	return sDBresult["resultarray"][tLastRow]
end rigDbLastRow








/*----------------------------------------------------------------------
--| FUNCTION rigDbNextRow
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-10-09
--| Last Mod: 02-11-09
--| Requires: --
--|
--| Summary: Returns the "next" row.
--|
--| Format:  rigDbNextRow()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbNextRow
  local tCurrentRow, tNextRow

	if sDBresult["resultarray"] is not an array then
		return sDBresult["resultarray"]
	end if

	put sDBresult["currentrow"] into tCurrentRow
	put tCurrentRow + 1 into tNextRow

	-- if sDBresult["resultarray"][tNextRow] is not empty then
	if sDBresult["resultarray"][tNextRow] is an array then
		put tNextRow into tCurrentRow
		put tCurrentRow into sDBresult["currentrow"]
	end if

	return sDBresult["resultarray"][tCurrentRow]
end rigDbNextRow








/*----------------------------------------------------------------------
--| FUNCTION rigDbPreviousRow
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-10-09
--| Last Mod: 02-11-09
--| Requires: --
--|
--| Summary: Returns the "previous" row.
--|
--| Format:  rigDbPreviousRow()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbPreviousRow
  local tCurrentRow, tPrevRow

	if sDBresult["resultarray"] is not an array then
		return sDBresult["resultarray"]
	end if

	put sDBresult["currentrow"] into tCurrentRow
	put tCurrentRow - 1 into tPrevRow

	if the number of lines in the keys of sDBresult["resultarray"] > 1 then
		-- if sDBresult["resultarray"][tPrevRow] is not empty then
		if sDBresult["resultarray"][tPrevRow] is an array then
			put tPrevRow into tCurrentRow
			put tCurrentRow into sDBresult["currentrow"]
		end if
	end if

	return sDBresult["resultarray"][tCurrentRow]
end rigDbPreviousRow








/*----------------------------------------------------------------------
--| FUNCTION rigDbCurrentRow
--|
--| Author: rabit
--| Version:  1.0
--| Created: 02-11-09
--| Last Mod: 02-11-09
--| Requires: --
--|
--| Summary: Returns the "current" row.
--|
--| Format:  rigDbCurrentRow()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbCurrentRow
  local tCurrentRow

	if sDBresult["resultarray"] is not an array then
		return sDBresult["resultarray"]
	end if

	put sDBresult["currentrow"] into tCurrentRow

	return sDBresult["resultarray"][tCurrentRow]
end rigDbCurrentRow








/*----------------------------------------------------------------------
--| COMMAND rigDbResetResultValue
--|
--| Author: rabit
--| Version:  1.0
--| Created: 28-09-09
--| Last Mod: 28-09-09
--| Requires: --
--|
--| Summary: Reset sDBresult value.
--|
--| Format:  rigDbResetResultValue param1
--|
--| Parameters: string <pKey>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbResetResultValue pKey
  switch pKey
    case "currentrow"
      put 0 into sDBresult["currentrow"]
    break
    case "numrows"
      put 0 into sDBresult["numrows"]
    break
    default
    put empty into sDBresult[pKey]
  end switch
end rigDbResetResultValue








/*----------------------------------------------------------------------
--| COMMAND rigDbSetResultFromCache
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-10-09
--| Last Mod: 15-02-14
--| Requires: --
--|
--| Summary: Set sDBresult values to cached values.
--|
--| Format:  rigDbSetResultFromCache param1 param2 param3
--|
--| Parameters: array <pResult>, integer <pNumRows>, array <pFieldNames>,
--|             array <pFieldNumbers>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbSetResultFromCache pResult pNumRows pFieldNames pFieldNumbers
	put pResult into sDBresult["resultarray"]
	put pNumRows into sDBresult["numrows"]
	put pFieldNames into sDBresult["fieldNames"]
	put pFieldNumbers into sDBresult["fieldNumbers"]
end rigDbSetResultFromCache






/*----------------------------------------------------------------------
--| FUNCTION rigFieldNumbers
--|
--| Author: rabit
--| Version:  1.0
--| Created: 15-02-2014
--| Last Mod: 15-02-2014
--| Requires: --
--|
--| Summary: Returns an array containing field names as keys
--|            and field numbers as values.
--|
--| Format:  rigFieldNumbers(param1)
--|
--| Parameters: array <pFieldNames>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigFieldNumbers pFieldNames
  local tFieldNumbers

  repeat for each key tKey in  pFieldNames
    put tKey into tFieldNumbers[pFieldNames[tKey]]
  end repeat

  return tFieldNumbers
end rigFieldNumbers







/*----------------------------------------------------------------------
--| COMMAND _rigFetchResultArray
--|
--| Author: Trevor DeVore
--| Modification: rabit
--| Version:  1.3
--| Created: 2009-07-17
--| Last Mod: 2018-04-30
--| Requires: --
--|
--| Summary: Returns the result set as a numeric array. May be this will be changed
--|            to return optionally an associative array in a future version.
--|            This will break the feedjson module!
--|
--| Format: _rigFetchResultArray param1, param2, param3
--|
--| Parameters: integer <pRecordSetID>, reference array <@pRefArray>,
--|               bool <pChangeFieldNamesListDelimiter>
--|
--| Return: string
----------------------------------------------------------------------*/

private command _rigFetchResultArray pRecordSetID, @pRefArray, pChangeFieldNamesListDelimiter
  local tFieldNames, tError, tCounter, tFieldCounter

	 put revDatabaseColumnNames(pRecordSetID) into tFieldNames

	if tFieldNames begins with "revdberr," then
		put item 2 to -1 of tFieldNames into tError
	end if

	if tError is "" then
    # "SELECT IF" and "SELECT GREATEST" QUERIES USE COMMAS TO SEPARATE VALUES TO BE COMPARED
    # FIELD NAMES LISTS USE COMMAS TOO, SO CHANGE THE ITEM DELIMITER
    if pChangeFieldNamesListDelimiter is TRUE then
      set the itemDelimiter to numToCodepoint(0)
    end if

		put 0 into tCounter
		repeat until revQueryIsAtEnd(pRecordSetID)
			add 1 to tCounter

			put 0 into tFieldCounter

			repeat for each item theField in tFieldNames
				add 1 to tFieldCounter
				-- put revDatabaseColumnNamed(pRecordSetID, theField) into pRefArray[tCounter][theField]
				put revDatabaseColumnNamed(pRecordSetID, theField) into pRefArray[tCounter][tFieldCounter]
				-- put revDatabaseColumnNamed(pRecordSetID, theField) into pRefArray[tCounter][tFieldCounter & "," & theField]
			end repeat

			revMoveToNextRecord pRecordSetID
		end repeat
	end if

	return tError
end _rigFetchResultArray







--| END OF DBresult.livecodescript
--| Location:  ./system/database/DBresult.livecodescript
----------------------------------------------------------------------