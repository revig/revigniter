script "sqliteDriver"

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
# SQLite Database Adapter Library
#
# This is the platform-independent base DB implementation library.
# This library will not be called directly. Rather, the adapter
# library for the specific database will extend it.
#
# @package		revIgniter
# @subpackage	Drivers
# @category	  Database
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/database/
##





global gRigA

local sDBdriver, _sEscapeChar, _sCountString, _sRandomKeyword
local _sLikeEscapeStr, _sLikeEscapeChr, sStackInUse






 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-18
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
  put "sqlite" into sDBdriver

  # THE CHARACTER USED FOR ESCAPING
  put quote into _sEscapeChar

  # CLAUSE AND CHARACTER USED FOR LIKE ESCAPE SEQUENCES
  put " ESCAPE '%s' " into _sLikeEscapeStr
  put "!" into _sLikeEscapeChr

  ##
  # THE SYNTAX TO COUNT ROWS IS SLIGHTLY DIFFERENT ACROSS DIFFERENT
  # DATABASE ENGINES, SO THIS STRING APPEARS IN EACH DRIVER AND IS
  # USED FOR THE COUNT_ALL() AND COUNT_ALL_RESULTS() FUNCTIONS.
  ##
  put "SELECT COUNT(*) AS " into _sCountString
  put " Random()" into _sRandomKeyword -- database specific random keyword
end _rigSetDefaultValues






/*----------------------------------------------------------------------
--| FUNCTION rigDbConnect
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2014-04-10
--| Last Mod: 2020-03-04
--| Requires: rigFetchDBdriverSetting(), rigLogMessage
--|
--| Summary: Non-persistent database connection.
--|          Set the path to the database file in application/config/database.lc like:
--|          put gRigA["APPPATH"] & "db/myDatabase.sqlite" into sDB["default"]["hostname"]
--|
--| Format:  rigDbConnect()
--|
--| Parameters: --
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbConnect
  local tSettingsKeys, tSettingsA, tDatabaseID

  put "hostname,database,options" into tSettingsKeys
  put rigFetchDBdriverSetting(tSettingsKeys) into tSettingsA

	put FALSE into tDatabaseID

	try
		# FOR BACKWARD COMPATIBILITY REASONS THE FOLLOWING LINE
		# IS LEGACY SYNTAX OF ENGINE VERSIONS PRIOR TO 6.6.0
		get revOpenDatabase("sqlite", tSettingsA["hostname"], tSettingsA["options"], , )
		put it into tDatabaseID
	catch err
		rigLogMessage "error", "An error occured while trying to open database:" && tSettingsA["database"]
	end try

	if tDatabaseID is an integer then
		return tDatabaseID
	else
		return FALSE
	end if
end rigDbConnect






/*----------------------------------------------------------------------
--| FUNCTION _rigDbSetCharset
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Set client character set.
--|
--| Format:  _rigDbSetCharset(param1, param2)
--|
--| Parameters: string <pCharset>, string <pCollation>
--|
--| Return: bool
----------------------------------------------------------------------*/

function _rigDbSetCharset pCharset pCollation
	# NOT IMPLEMENTED AS IT IS NOT POSSIBLE TO CHANGE
  # THE TEXT ENCODING OF A DATABASE AFTER IT HAS BEEN
  # CREATED AND ANY ATTEMPT TO DO SO WILL BE SILENTLY IGNORED.

  return TRUE
end _rigDbSetCharset





/*----------------------------------------------------------------------
--| FUNCTION _rigDbVersion
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-09-09
--| Last Mod: 29-09-09
--| Requires: --
--|
--| Summary: Version number query string.
--|
--| Format:  _rigDbVersion()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigDbVersion
  return "SELECT sqlite_version() AS ver"
end _rigDbVersion




/*----------------------------------------------------------------------
--| FUNCTION _rigDbExecute
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-04-14
--| Last Mod: --
--| Requires: _rigPrepQuery(), rigFetchDBdriverSetting(), rigLogMessage
--|
--| Summary: Called by the base library (driver).
--|
--| Format:  _rigDbExecute(param1, param2)
--|
--| Parameters: string <pSQL> the sql statement, integer <pConnectionID>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function _rigDbExecute pSQL pConnectionID
  local tSQL, tIsWriteType, tRecordSetID, tAffectedRows

	put _rigPrepQuery(pSQL) into tSQL

	put rigFetchDBdriverSetting("iswritetype") into tIsWriteType

	# IS THERE A RECORD SET
	if tIsWriteType is not TRUE then
		# RETURN A RECORD SET

		put revQueryDatabase ( pConnectionID, tSQL ) into tRecordSetID

		# QUERIES LIKE COMMIT RETURN EMPTY (NO RECORD SET ID)
		# SO CHECK FOR EMPTY TOO
		if (tRecordSetID is not empty) and (tRecordSetID is not an integer) then
			rigLogMessage "error", "Database query error:" && tRecordSetID
			return FALSE
		end if

		return tRecordSetID
	else
		# THERE IS NO RECORD SET, WE RETURN THE NUMBER OF AFFECTED ROWS
		revExecuteSQL pConnectionID, tSQL
		put the result into tAffectedRows

		if tAffectedRows is not an integer then
			return FALSE
		end if

		return tAffectedRows
	end if
end _rigDbExecute





/*----------------------------------------------------------------------
--| FUNCTION _rigPrepQuery
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Prep the query. If needed, each database adapter can prep the query string.
--|
--| Format:  _rigPrepQuery(param1)
--|
--| Parameters: string <pSQL> the sql statement
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigPrepQuery pSQL
	return pSQL
end _rigPrepQuery





/*----------------------------------------------------------------------
--| FUNCTION rigTransBegin
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-04-14
--| Last Mod: --
--| Requires: rigFetchDBdriverSetting(), rigSetDBdriverSetting, rigDbSimpleQuery()
--|
--| Summary: Begin transaction.
--|
--| Format:  rigTransBegin(param1)
--|
--| Parameters: bool <pTestMode>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigTransBegin pTestMode
  local tVal, tResult

	if rigFetchDBdriverSetting("transenabled") is not TRUE then
		return TRUE
	end if

	# WHEN TRANSACTIONS ARE NESTED WE ONLY BEGIN/COMMIT/ROLLBACK THE OUTERMOST ONES
	if rigFetchDBdriverSetting("transdepth") > 0 then
		return TRUE
	end if

	# RESET THE TRANSACTION FAILURE FLAG.
	# IF THE pTestMode FLAG IS SET TO TRUE TRANSACTIONS WILL BE ROLLED BACK
	# EVEN IF THE QUERIES PRODUCE A SUCCESSFUL RESULT.
	if pTestMode is TRUE then
		put TRUE into tVal
	else
		put FALSE into tVal
	end if
	rigSetDBdriverSetting "transfailure", tVal

	put rigDbSimpleQuery("BEGIN TRANSACTION") into tResult

	return tResult
end rigTransBegin








/*----------------------------------------------------------------------
--| COMMAND rigTransCommit
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-04-14
--| Last Mod: --
--| Requires: rigFetchDBdriverSetting(), rigDbSimpleQuery()
--|
--| Summary: Commit transaction.
--|
--| Format:  rigTransCommit
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigTransCommit
  local tTransEnabled, tTransDepth, tResult

	put rigFetchDBdriverSetting("transenabled") into tTransEnabled
	if tTransEnabled is not TRUE then
		exit rigTransCommit
	end if

	# WHEN TRANSACTIONS ARE NESTED WE ONLY BEGIN/COMMIT/ROLLBACK THE OUTERMOST ONES
	put rigFetchDBdriverSetting("transdepth") into tTransDepth
	if tTransDepth > 0 then
		exit rigTransCommit
	end if

	put rigDbSimpleQuery("COMMIT") into tResult

	return tResult
end rigTransCommit







/*----------------------------------------------------------------------
--| COMMAND rigTransRollback
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-04-14
--| Last Mod: --
--| Requires: rigFetchDBdriverSetting(), rigDbSimpleQuery()
--|
--| Summary: Rollback transaction.
--|
--| Format:  rigTransRollback
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigTransRollback
  local tTransEnabled, tTransDepth, tConnectionID

	put rigFetchDBdriverSetting("transenabled") into tTransEnabled
	if tTransEnabled is not TRUE then
		exit rigTransRollback
	end if

	# WHEN TRANSACTIONS ARE NESTED WE ONLY BEGIN/COMMIT/ROLLBACK THE OUTERMOST ONES
	put rigFetchDBdriverSetting("transdepth") into tTransDepth
	if tTransDepth > 0 then
		exit rigTransRollback
	end if

	# ROLLBACK USING BUILT-IN FUNCTION
	if gRigA["databaseID"] is "" then
		put rigFetchDBdriverSetting("connid") into tConnectionID
		get revdb_rollback(tConnectionID)
	else
		get revdb_rollback(gRigA["databaseID"])
	end if

	if it is not empty then
		# ROLLBACK USING QUERY
		get rigDbSimpleQuery("ROLLBACK")
	end if
end rigTransRollback







/*----------------------------------------------------------------------
--| FUNCTION rigEscapeStr
--|
--| Author: rabit
--| Version:  1.3
--| Created: 10-04-14
--| Last Mod: 06-10-15
--| Requires: rigEscapeStr()
--|
--| Summary: Escapes string.
--|
--| Format:  rigEscapeStr(param1, param2)
--|
--| Parameters: string <pStr> , bool <pLike> whether or not the string
--| 						will be used in a LIKE condition
--|
--| Return: string
----------------------------------------------------------------------*/

function rigEscapeStr pStr pLike
  local tStr, tLike, tKey

	put pStr into tStr
	if pLike is empty then
		put FALSE into tLike
	else
		put pLike into tLike
	end if

	if tStr is an array then
		repeat for each key tKey in tStr
			put rigEscapeStr(tStr[tKey]) into tStr
		end repeat

		return tStr
	end if

  # ' to ''
  replace numToCodepoint(39) with numToCodepoint(39) & numToCodepoint(39) in tStr

	# ESCAPE LIKE CONDITION WILDCARDS
	if tLike is TRUE then
		replace _sLikeEscapeChr with _sLikeEscapeChr & _sLikeEscapeChr in tStr
		replace "%" with _sLikeEscapeChr & "%" in tStr
		replace "_" with _sLikeEscapeChr & "_" in tStr
	end if

	return tStr
end rigEscapeStr







/*----------------------------------------------------------------------
--| FUNCTION rigDbCountAll
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-04-14
--| Last Mod: _rigProtectIdentifiers(), rigDbQuery(), rigDbRow()
--| Requires: --
--|
--| Summary: Generates a platform-specific query string that counts all records in
--|          the specified table.
--|
--| Format:  rigDbCountAll(param1)
--|
--| Parameters: string <pTable>
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigDbCountAll pTable
  local tNumrows, tTable, tSql, tQuery, tRow

	if pTable is empty then
		return 0
	end if

	put _rigProtectIdentifiers("numrows") into tNumrows
	put _rigProtectIdentifiers(pTable, TRUE, NULL, FALSE) into tTable

	put _sCountString & tNumrows && "FROM" && tTable into tSql

	put rigDbQuery(tSql) into tQuery

	if tQuery["numrows"] is 0 then
		return 0
	end if

	put rigDbRow() into tRow

	return tRow["numrows"]
end rigDbCountAll







/*----------------------------------------------------------------------
--| FUNCTION _rigDbListTables
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-04-14
--| Last Mod: --
--| Requires: rigFetchDBdriverSetting(), rigEscapeLikeStr()
--|
--| Summary: Generates a platform-specific query string so that the table names can be fetched.
--|
--| Format:  _rigDbListTables(param1)
--|
--| Parameters: bool <pPrefixLimit>
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigDbListTables pPrefixLimit
  local tPrefixLimit, tSql, tPrefix, tEscape

	if pPrefixLimit is empty then
		put FALSE into tPrefixLimit
	else
		put pPrefixLimit into tPrefixLimit
	end if

  put "SELECT name FROM sqlite_master WHERE type IN ('table','view') AND name NOT LIKE 'sqlite_%'"  into tSql

	put rigFetchDBdriverSetting("dbprefix") into tPrefix
	if (tPrefixLimit is not FALSE) and (tPrefix is not empty) then
		put rigEscapeLikeStr(tPrefix) into tPrefix
		put format(_sLikeEscapeStr, _sLikeEscapeChr) into tEscape
    put " AND name LIKE '" & tPrefix & "%' " & tEscape after tSql
	end if

  put " UNION ALL SELECT name FROM sqlite_temp_master WHERE type IN ('table','view') ORDER BY 1" after tSql

	return tSql
end _rigDbListTables




/*----------------------------------------------------------------------
--| FUNCTION _rigDbListColumns
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Generates a platform-specific query string so that the column names can be fetched.
--|
--| Format:  _rigDbListColumns(param1)
--|
--| Parameters: string <pTable>
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigDbListColumns pTable
  return "PRAGMA table_info('" &  pTable & "')"
end _rigDbListColumns




/*----------------------------------------------------------------------
--| FUNCTION _rigDbFieldData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Generates a platform-specific query so that the column data can be retrieved.
--|
--| Format:  _rigDbFieldData(param1)
--|
--| Parameters: string <pTable> the table name
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigDbFieldData pTable
	return "SELECT * FROM" && pTable && "LIMIT 1"
end _rigDbFieldData




/*----------------------------------------------------------------------
--| FUNCTION rigDbErrorMessage
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: rigFetchDBdriverSetting()
--|
--| Summary: The error message string.
--|
--| Format:  rigDbErrorMessage()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbErrorMessage
  local tConnectionID

	if gRigA["databaseID"] is "" then
		put rigFetchDBdriverSetting("connid") into tConnectionID
		if (tConnectionID <> "") and (tConnectionID is an integer) then
			return revDatabaseConnectResult(tConnectionID)
		else
			return "There is no database connection."
		end if
	end if

	return revDatabaseConnectResult(gRigA["databaseID"])
end rigDbErrorMessage







/*----------------------------------------------------------------------
--| FUNCTION _rigEscapeIdentifiers
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: rigFetchDBdriverSetting()
--|
--| Summary: This function escapes column and table names.
--|
--| Format:  _rigEscapeIdentifiers(param1)
--|
--| Parameters: string <pItem>
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigEscapeIdentifiers pItem
  local tReservedIdent, tKey, tStr, tRegEx

	if _sEscapeChar is "" then
		return pItem
	end if

	put rigFetchDBdriverSetting("reservedIdentifiers") into tReservedIdent
	repeat for each key tKey in tReservedIdent
		if "." & tReservedIdent[tKey] is in pItem then
			put pItem into tStr
			replace "." with (_sEscapeChar & ".") in tStr
			put _sEscapeChar & tStr into tStr

			# REMOVE DUPLICATES IF THE USER ALREADY INCLUDED THE ESCAPE
			put "[" & _sEscapeChar & "]+" into tRegEx
			return replacetext(tStr,tRegEx,_sEscapeChar)
		end if
	end repeat

	if "." is in pItem then
		put pItem into tStr
		replace "." with (_sEscapeChar & "." & _sEscapeChar) in tStr
		put _sEscapeChar & tStr & _sEscapeChar into tStr
	else
		put _sEscapeChar & pItem & _sEscapeChar into tStr
	end if

	# REMOVE DUPLICATES IF THE USER ALREADY INCLUDED THE ESCAPE
	put "[" & _sEscapeChar & "]+" into tRegEx
	return replacetext(tStr,tRegEx,_sEscapeChar)
end _rigEscapeIdentifiers




/*----------------------------------------------------------------------
--| FUNCTION _rigFromTables
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: This function implicitly groups FROM tables so there is no confusion
--|            about operator precedence in harmony with SQL standards.
--|
--| Format:  _rigFromTables(param1)
--|
--| Parameters: type <pTables>
--|
--| Return: type
----------------------------------------------------------------------*/

function _rigFromTables pTables
  local tTablesArray

	if pTables is not an array then
		put pTables into tTablesArray[1]
	else
		put pTables into tTablesArray
	end if

	combine tTablesArray using ","
	replace "," with ", " in tTablesArray

	return "(" & tTablesArray & ")"
end _rigFromTables




/*----------------------------------------------------------------------
--| FUNCTION _rigInsert
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Generates a platform-specific insert string from the supplied data.
--|
--| Format:  _rigInsert(param1, param2, param3)
--|
--| Parameters: string <pTable> the table name, array <pKeys> the insert keys,
--|               array <pValues> the insert values
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigInsert pTable pKeys pValues
	combine pKeys using comma
	combine pValues using comma

	return "INSERT INTO " & pTable & " (" & pKeys & ") VALUES (" & pValues & ")"
end _rigInsert




/*----------------------------------------------------------------------
--| FUNCTION _rigUpdate
--|
--| Author: rabit
--| Version:  1.1
--| Created: 11-04-14
--| Last Mod: 21-12-14
--| Requires: --
--|
--| Summary: Generates a platform-specific update string from the supplied data.
--|
--| Format:  _rigUpdate(param1, param2, param3, param4, param5)
--|
--| Parameters: string <pTable> the table name, array <pValues> the update data,
--|               array <pWhere> the where clause, array <pOrderBy> the orderby clause,
--|               array <pLimit>the limit clause
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigUpdate pTable pValues pWhere pOrderBy pLimit
  local tOrderBy, tWhere, tLimit, tKeyNum, tKey, tVal, tValstr, tSql

	put pOrderBy into tOrderBy
	put pWhere into tWhere
	if pLimit is empty then
		put FALSE into tLimit
	else
		put pLimit into tLimit
	end if

	put 0 into tKeyNum
	repeat for each key tKey in pValues
		put pValues[tKey] into tVal
		add 1 to tKeyNum

		put tKey && "=" && tVal into tValstr[tKeyNum]
	end repeat

	if tLimit is FALSE then
		put "" into tLimit
	else
		put " LIMIT " & tLimit into tLimit
	end if

	if the number of lines in the keys of tOrderBy >= 1 then
		combine tOrderBy using numToCodepoint(2)
		replace numToCodepoint(2) with ", " in tOrderBy
		put " ORDER BY" && tOrderBy into tOrderBy
	else
		put "" into tOrderBy
	end if

	combine tValstr using numToCodepoint(2)
	replace numToCodepoint(2) with ", " in tValstr

	put "UPDATE" && pTable && "SET" && tValstr into tSql

	if tWhere is an array then
		combine tWhere using comma
		replace comma with space in tWhere
		put " WHERE" && tWhere after tSql
	else
		put "" after tSql
	end if

	put tOrderBy & tLimit after tSql

	return tSql
end _rigUpdate




/*----------------------------------------------------------------------
--| FUNCTION _rigTruncate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: _rigDelete()
--|
--| Summary: Generates a platform-specific truncate string from the supplied data
--|             If the database does not support the truncate() command
--|             This function maps to "DELETE FROM table".
--|
--| Format:  _rigTruncate(param1)
--|
--| Parameters: string <pTable> the table name
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigTruncate pTable
	return _rigDelete(pTable)
end _rigTruncate




/*----------------------------------------------------------------------
--| FUNCTION _rigDelete
--|
--| Author: rabit
--| Version:  1.1
--| Created: 11-04-14
--| Last Mod: 03-12-15
--| Requires: rigFetchDBactiveRecSetting()
--|
--| Summary: Generates a platform-specific delete string from the supplied data.
--|
--| Format:  _rigDelete(param1, param2, param3, param4)
--|
--| Parameters: string <pTable> the table name, array <pWhere> the where clause, array <pLike>
--|               array <pLimit>the limit clause
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigDelete pTable pWhere pLike pLimit
  local tLike, tLimit, tConditions, tARwhere, tSeparator

	put pLike into tLike
	if pLimit is empty then
		put FALSE into tLimit
	else
		put pLimit into tLimit
	end if

	if (the number of lines in the keys of pWhere > 0) or (the number of lines in the keys of tLike > 0) then
		put LF & "WHERE " into tConditions
		put rigFetchDBactiveRecSetting("where") into tARwhere
		put numToCodepoint(1) into tSeparator
		combine tARwhere using tSeparator
		replace tSeparator with LF in tARwhere
		put tARwhere after tConditions

		if (the number of lines in the keys of pWhere > 0) and (the number of lines in the keys of tLike > 0) then
			put " AND " after tConditions
		end if

		combine tLike using comma
		replace comma with LF in tLike
		put tLike after tConditions

	end if

	if tLimit is FALSE then
		put "" into tLimit
	else
		put " LIMIT" && tLimit into tLimit
	end if

	return "DELETE FROM" && pTable & tConditions & tLimit
end _rigDelete




/*----------------------------------------------------------------------
--| FUNCTION _rigLimit
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Generates a platform-specific LIMIT clause.
--|
--| Format:  _rigLimit(param1, param2, param3)
--|
--| Parameters: string <pSQL> the sql query string, integer <pLimit> the number of rows
--|               to limit the query to, integer <pOffset>
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigLimit pSQL pLimit pOffset
  local tOffset

	if (pOffset is 0) or (pOffset is FALSE) then
		put "" into tOffset
	else
		put pOffset & ", " into tOffset
	end if

	return pSQL & "LIMIT" && tOffset & pLimit
end _rigLimit




/*----------------------------------------------------------------------
--| FUNCTION _rigDbClose
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: rigSetDBdriverSetting
--|
--| Summary: Close DB Connection.
--|
--| Format:  _rigDbClose(param1)
--|
--| Parameters: integer <pConnectionID>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function _rigDbClose pConnectionID
  local tError

	revCloseDatabase pConnectionID

	if item 1 of the result is "revdberr" then
		put the result into tError
		delete item 1 of tError

		return tError
	end if

	# RESET VARIABLES
	put empty into gRigA["databaseID"]
	rigSetDBdriverSetting "connid", FALSE
	rigSetDBdriverSetting "resultid", FALSE

	return TRUE
end _rigDbClose





/*----------------------------------------------------------------------
--| FUNCTION rigFetchDriverSpecificSetting
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Fetch setting from sqlite driver settings.
--|
--| Format:  rigFetchDriverSpecificSetting(param1)
--|
--| Parameters: string<pSetting>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigFetchDriverSpecificSetting pSetting
	switch pSetting
		case "_sEscapeChar"
        		return _sEscapeChar
        		break
    		case "_sLikeEscapeStr"
        		return _sLikeEscapeStr
        		break
		case "_sLikeEscapeChr"
        		return _sLikeEscapeChr
        		break
		case "_sRandomKeyword"
        		return _sRandomKeyword
        		break
		case "_sCountString"
        		return _sCountString
        		break
    		default
        		return ""
    end switch
end rigFetchDriverSpecificSetting







/*----------------------------------------------------------------------
--| FUNCTION rigSqlDateTimeToIntDate
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2014-04-11
--| Last Mod: 2017-06-27
--| Requires: --
--|
--| Summary: Convert SQL datetime format to Internet date format (RFC 2822).
--|
--| Format:  rigSqlDateTimeToIntDate(param1)
--|
--| Parameters: string <pDateTime>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSqlDateTimeToIntDate pDateTime
  local tRegEx, tY, tM, tD, tT, tDateTime, tConvertedDate

	put "([0-9]+)-([0-9]+)-([0-9]+)\s([0-9]+\:[0-9]+\:[0-9]+)" into tRegEx

	put empty into tY -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	put empty into tM
	put empty into tD
	put empty into tT
	get matchText(pDateTime,tRegEx,tY,tM,tD,tT)

	put tM & "/" & tD & "/" & tY && tT into tDateTime

	convert (tDateTime) to internet date
	put it into tConvertedDate

	return tConvertedDate
end rigSqlDateTimeToIntDate






/*----------------------------------------------------------------------
--| FUNCTION rigDbGetPragma
--|
--| Author: rabit
--| Version:  1.2
--| Created: 09-04-14
--| Last Mod: 16-04-14
--| Requires: rigCurrentConnectionID()
--|
--| Summary: Get pragma value.
--|
--| Format:  rigDbGetPragma(param1)
--|
--| Parameters: string <pPragma>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbGetPragma pPragma
  local tConnectionID, tSQL, tPragmaValue

  put rigCurrentConnectionID() into tConnectionID

  put "PRAGMA" && pPragma & ";" into tSQL
  get revDataFromQuery(comma, return, tConnectionID, tSQL)

  put it into tPragmaValue

  # RETURN ERROR
  if item 1 of tPragmaValue is "revdberr" then
     return "Error:" && item 2 of tPragmaValue
  end if

  return tPragmaValue
end rigDbGetPragma





/*----------------------------------------------------------------------
--| COMMAND rigDbSetPragma
--|
--| Author: rabit
--| Version:  1.1
--| Created: 09-04-14
--| Last Mod: 15-04-14
--| Requires: rigCurrentConnectionID()
--|
--| Summary: Set a pragma value.
--|
--| Format:  rigDbSetPragma param1, param2
--|
--| Parameters: string <pPragma>, mixed <pValue>
--|
--| Return: mixed
----------------------------------------------------------------------*/

command rigDbSetPragma pPragma pValue
  local tConnectionID, tSQL, tResult

  put rigCurrentConnectionID() into tConnectionID

  # RUN QUERY
  put "PRAGMA" && pPragma && "=" && pValue &";" into tSQL
  revExecuteSQL tConnectionID, tSQL

  put the result into tResult

  # RETURN ERROR
  if tResult <> 0 then
    return "Error:" && tResult
  end if

  return 0
end rigDbSetPragma









--| END OF sqliteDriver.livecodescript
--| Location:  ./system/database/drivers/sqlite/sqliteDriver.livecodescript
----------------------------------------------------------------------
