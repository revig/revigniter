script "sqliteResult"

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
# SQLite Result Library
#
# This library extends DBresult.
#
# @category	Database
# @author		rabit@revigniter.com
# @link		  https://revigniter.com/userGuide/database/
##





global gRigA

local sTableInfo, sStackInUse





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-19
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
--| Version:  1.1
--| Created: 11-04-14
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
--| Created: 11-04-14
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
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: rigFetchDBdriverSetting()
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

	put revDatabaseColumnNames(tResultID) into tFieldNames
	split tFieldNames using comma

	return tFieldNames
end rigListFields








/*----------------------------------------------------------------------
--| FUNCTION rigFieldData
--|
--| Author: rabit
--| Version:  1.1
--| Created: 11-04-14
--| Last Mod: 14-04-14
--| Requires: rigFetchDBdriverSetting(), _rigPragmaTableInfo, rigDbColumnTypes(),
--| 					rigDbPrimaryField(), rigDbDefaults()
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
  local tTableInfoQuerySuccess, tTypes, tPrimaryField, tDefaults, tResultID
  local tFieldNames, tMaxLengths, tCounter, tFieldData
  
  put TRUE into tTableInfoQuerySuccess
  put empty into tTypes
  put empty into tPrimaryField
  put empty into tDefaults
  
	put rigFetchDBdriverSetting("resultid") into tResultID
	put revDatabaseColumnNames(tResultID) into tFieldNames
	
  # STORE TABLE META DATA IN A VARIABLE
  _rigPragmaTableInfo pTable
  if item 1 of sTableInfo is "revdberr" then
    rigLogMessage "error", "An error occured while trying to query table info data for table:" && pTable
    put FALSE into tTableInfoQuerySuccess
  end if
  
  # GET DATA TYPES ONLY IF TABLE INFO QUERY WAS SUCCESSFULL
  if tTableInfoQuerySuccess is TRUE then
    put rigDbColumnTypes(pTable) into tTypes
  end if
  
	put revDatabaseColumnLengths(tResultID) into tMaxLengths
  
	# GET PRIMARY FIELD AND DEFAULT VALUE ONLY IF
  # TABLE INFO QUERY WAS SUCCESSFULL
	if pTable is not empty then
    if tTableInfoQuerySuccess is TRUE then
		  put rigDbPrimaryField() into tPrimaryField
    
      put rigDbDefaults() into tDefaults
    end if
	end if

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
--| COMMAND _rigPragmaTableInfo
--|
--| Author: rabit
--| Version:  1.2
--| Created: 12-04-2014
--| Last Mod: 15-04-14
--| Requires: rigDbGetPragma()
--|
--| Summary: Store table meta data in a variable.
--| 
--| Format:  _rigPragmaTableInfo param1
--|
--| Parameters: string <pTable>
--|
--| Return: string
----------------------------------------------------------------------*/

command _rigPragmaTableInfo pTable
  local tPragma
  
  # GET TABLE META DATA
  put "table_info(" &  pTable & ")" into tPragma

  put rigDbGetPragma(tPragma) into sTableInfo
end _rigPragmaTableInfo





/*----------------------------------------------------------------------
--| FUNCTION rigDbColumnTypes
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Get the defined data types of each field instead of SQLite
--|					storage classes as a comma separated list. _rigPragmaTableInfo
--|            needs to be called beforehand.
--| 
--| Format:  rigDbColumnTypes()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbColumnTypes
  local tLine, tColumnType, tColumnTypes
  
  if sTableInfo <> empty then
    # EACH LINE OF sTableInfo CONTAINS FIELD META DATA
    repeat for each line tLine in sTableInfo
      # REMOVE INFO ABOUT LENGTH
      if "(" is in tLine then
        put replaceText(tLine, "\(.+\)", "") into tLine
      end if
      # ITEM 3 IS NOT THE STORAGE CLASS, IT IS THE DEFINED DATA TYPE
      put item 3 of tLine into tColumnType
      
      # BUILD TYPES LIST
      put toUpper(tColumnType) & comma after tColumnTypes
    end repeat
   
    delete char -1 of tColumnTypes
   
    return tColumnTypes
  end if
 
  return ""
end rigDbColumnTypes







/*----------------------------------------------------------------------
--| FUNCTION rigDbPrimaryField
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Get the name of the primary field. _rigPragmaTableInfo
--|            needs to be called beforehand.
--| 
--| Format:  rigDbPrimaryField()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbPrimaryField
  local tPrimaryField
  
  if sTableInfo <> empty then
    put empty into tPrimaryField
   
    # EACH LINE OF sTableInfo CONTAINS  FIELD META DATA
    repeat for each line tLine in sTableInfo
      if last item of tLine is "1" then
        put item 2 of tLine into tPrimaryField
        exit repeat
      end if
    end repeat
   
    return tPrimaryField
  end if

  return ""
end rigDbPrimaryField






/*----------------------------------------------------------------------
--| FUNCTION rigDbDefaults
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Get the default values of each field as a comma separated list.
--|          _rigPragmaTableInfo needs to be called beforehand.
--| 
--| Format:  rigDbDefaults()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbDefaults
  local tLine, tDefault, tDefaults
  
  if sTableInfo <> empty then
    # EACH LINE OF sTableInfo CONTAINS FIELD META DATA
    repeat for each line tLine in sTableInfo
      # REMOVE INFO ABOUT LENGTH
      if "(" is in tLine then
        put replaceText(tLine, "\(.+\)", "") into tLine
      end if

      put item -2 of tLine into tDefault
      
      # BUILD DEFAULTS LIST
      put tDefault & comma after tDefaults
    end repeat
   
    delete char -1 of tDefaults
   
    return tDefaults
  end if
  
  return ""
end rigDbDefaults







/*----------------------------------------------------------------------
--| FUNCTION _rigDataSeek
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Moves the internal pointer to the desired offset. We call
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
--| Last Mod: 14-04-14
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
  
  put rigDBQuery("SELECT last_insert_rowid()") into tQuery
	
	if tQuery["numrows"] = 1 then
		put rigDbRow(1) into tRow
		return tRow["last_insert_rowid()"]
	else
		return FALSE
	end if
end _rigDbLastInsertID







/*----------------------------------------------------------------------
--| FUNCTION rigCurrentConnectionID
--|
--| Author: rabit
--| Version:  1.0
--| Created: 15-04-2014
--| Last Mod: --
--| Requires: rigFetchDBdriverSetting()
--|
--| Summary: Get database connection id.
--| 
--| Format:  rigCurrentConnectionID()
--|
--| Parameters: --
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigCurrentConnectionID
  if gRigA["databaseID"] is "" then
    return rigFetchDBdriverSetting("connid")
  end if
  
  return gRigA["databaseID"]
end rigCurrentConnectionID






--| END OF sqliteResult.livecodescript
--| Location:  ./system/database/drivers/sqlite/sqliteResult.livecodescript
----------------------------------------------------------------------