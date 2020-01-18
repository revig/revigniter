script "mysqlResult"

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
# MySQL Result Library
#
# This library extends DBresult.
#
# @category	Database
# @author		rabit@revigniter.com
# @link		  https://revigniter.com/userGuide/database/
##




global gRigA

local sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-18
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
--| FUNCTION rigNumRows
--|
--| Author: rabit
--| Version:  1.2
--| Created: 20-07-09
--| Last Mod: 18-04-14
--| Requires: rigFetchDBdriverSetting(), rigLogMessage
--|
--| Summary: Number of rows in the result set.
--| 
--| Format:  rigNumRows(param1)
--|
--| Parameters: integer <pResultID>
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigNumRows pResultID
  local tResultID, tNumRows
  
	if pResultID is empty then
		put rigFetchDBdriverSetting("resultid") into tResultID
	else
		put pResultID into tResultID
	end if

	put revNumberOfRecords(tResultID) into tNumRows

	if item 1 of tNumRows is "revdberr" then
		delete item 1 of tNumRows
		rigLogMessage "error", tNumRows
	end if

	return tNumRows
end rigNumRows







/*----------------------------------------------------------------------
--| FUNCTION rigNumFields
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-10-09
--| Last Mod: 18-04-14
--| Requires: rigFetchDBdriverSetting(), rigLogMessage
--|
--| Summary: Number of fields in the result set.
--| 
--| Format:  rigNumFields(param1)
--|
--| Parameters: integer <pResultID>
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigNumFields pResultID
  local tResultID, tNumFields
  
	if pResultID is empty then
		put rigFetchDBdriverSetting("resultid") into tResultID
	else
		put pResultID into tResultID
	end if

	put revDatabaseColumnCount(tResultID) into tNumFields

	if item 1 of tNumFields is "revdberr" then
		delete item 1 of tNumFields
		rigLogMessage "error", tNumFields
	end if

	return tNumFields
end rigNumFields






/*----------------------------------------------------------------------
--| FUNCTION rigListFields
--|
--| Author: rabit
--| Version:  1.2
--| Created: 22-07-09
--| Last Mod: 02-10-09
--| Requires: --
--|
--| Summary: Generates an array of column names.
--| 
--| Format:  rigListFields(param1)
--|
--| Parameters: integer <pResultID>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigListFields pResultID
  local tResultID, tFieldNames
  
	if pResultID is empty then
		put rigFetchDBdriverSetting("resultid") into tResultID
	else
		put pResultID into tResultID
	end if

	/*
	put revDatabaseColumnNames(pResultID) into tFieldNamesString
	
	put 0 into tCounter
	repeat for each item thisItem in tFieldNamesString
		add 1 to tCounter

		put thisItem into tFieldNamesArray[tCounter]
	end repeat
	
	return tFieldNamesArray
	*/

	put revDatabaseColumnNames(tResultID) into tFieldNames
	split tFieldNames using comma

	return tFieldNames
end rigListFields








/*----------------------------------------------------------------------
--| FUNCTION rigFieldData
--|
--| Author: rabit
--| Version:  1.5
--| Created: 01-10-09
--| Last Mod: 21-03-14
--| Requires: rigFetchDBdriverSetting(), revDatabaseColumnNames(), revDatabaseColumnTypes(),
--| 					revDatabaseColumnLengths(), rigDbQuery()
--|
--| Summary: Generates an array of arrays containing field meta-data 
--|					(name, type, maxlength, default, primary).
--| 
--| Format:  rigFieldData(param1)
--|
--| Parameters: string <pTable>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigFieldData pTable
  local tResultID, tFieldNames, tTypes, tMaxLengths, tTableDesc
  local tPrimaryField, tDefaults, tCounter, tFieldData
  
	put rigFetchDBdriverSetting("resultid") into tResultID
	put revDatabaseColumnNames(tResultID) into tFieldNames
	put revDatabaseColumnTypes(tResultID) into tTypes
	put revDatabaseColumnLengths(tResultID) into tMaxLengths

	# GET primary FIELD AND DEFAULT VALUE
	if pTable is not empty then
		put rigDbQuery("DESCRIBE" && pTable) into tTableDesc

		repeat with tField = 1 to the number of lines in the keys of tTableDesc["resultarray"]
			if tTableDesc["resultarray"][tField][4] is "PRI" then
				put tTableDesc["resultarray"][tField][1] into tPrimaryField
			end if
			put tTableDesc["resultarray"][tField][5] & comma after tDefaults
		end repeat

	else
		put "" into tPrimaryField
		put comma into tDefaults
	end if

	delete char -1 of  tDefaults

	put 0 into tCounter
	repeat for each item thisItem in tFieldNames
		add 1 to tCounter

		put thisItem into tFieldData[tCounter]["name"]
		put item tCounter of tTypes into tFieldData[tCounter]["type"]
		put item tCounter of tMaxLengths into tFieldData[tCounter]["maxlength"]
		put item tCounter of tDefaults into tFieldData[tCounter]["default"]
		if thisItem is tPrimaryField then
			put 1 into tFieldData[tCounter]["primarykey"]
		else
			put "" into tFieldData[tCounter]["primarykey"]
		end if
	end repeat

	return tFieldData
end rigFieldData







/*----------------------------------------------------------------------
--| FUNCTION _rigDataSeek
--|
--| Author: rabit
--| Version:  1.2
--| Created: 17-07-09
--| Last Mod: 12-10-09
--| Requires: --
--|
--| Summary: Moves the internal pointer to the desired offset.  We call
--|            this internally before fetching results to make sure the
--|            result set starts at zero.
--| 
--| Format:  _rigDataSeek(param1, param2)
--|
--| Parameters: integer <pRecordsetID>, integer <pN> record number
--|
--| Return: bool
----------------------------------------------------------------------*/

function _rigDataSeek pRecordsetID pN
  local tN
  
	if pN is empty then
		put 1 into tN
	else
		put pN into tN
	end if

	revMoveToRecord pRecordsetID, tN

	return the result
end _rigDataSeek









/*----------------------------------------------------------------------
--| FUNCTION _rigDbLastInsertID
--|
--| Author: Monte Goulding
--| Modification: rabit
--| Version:  1.0
--| Created: 24-02-12
--| Last Mod: --
--| Requires: rigDBQuery(), rigDbRow()
--|
--| Summary: Returns the last automatically generated value successfully
--| 				  inserted for an AUTO_INCREMENT column as a result of the most
--| 				  recently executed INSERT statement.
--| 
--| Format:	_rigDbLastInsertID(param1)
--|
--| Parameters: string <pTable>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function _rigDbLastInsertID pTable
  local tQuery, tRow
  
	put rigDBQuery("SELECT LAST_INSERT_ID()") into tQuery
	
	if tQuery["numrows"] = 1 then
		put rigDbRow(1) into tRow
		return tRow["LAST_INSERT_ID()"]
	else
		return FALSE
	end if
end _rigDbLastInsertID






--| END OF mysqlResult.livecodescript
--| Location:  ./system/database/drivers/mysql/mysqlResult.livecodescript
----------------------------------------------------------------------