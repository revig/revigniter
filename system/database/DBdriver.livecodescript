script "DBdriver"

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
# Database Driver Library
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

local sDBdriverSettings, sCacheLibLoaded, sResultDriversLoaded, sStackInUse





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
  put "" into sDBdriverSettings["username"]
  put "" into sDBdriverSettings["password"]
  put "" into sDBdriverSettings["hostname"]
  put "" into sDBdriverSettings["database"]

  put "mysql" into sDBdriverSettings["dbdriver"]
  put "" into sDBdriverSettings["dbprefix"]
  put "utf8" into sDBdriverSettings["charset"]
  put "utf8_general_ci" into sDBdriverSettings["dbcollat"]
  put TRUE into sDBdriverSettings["autoinit"] -- Whether to automatically initialize the DB
  put "" into sDBdriverSettings["swappre"]
  put "" into sDBdriverSettings["port"]
  put FALSE into sDBdriverSettings["pconnect"]
  put FALSE into sDBdriverSettings["connid"]
  put FALSE into sDBdriverSettings["resultid"]
  put FALSE into sDBdriverSettings["dbdebug"]
  put "" into sDBdriverSettings["dbRedirectOnError"]
  put 0 into sDBdriverSettings["benchmark"]
  put 0 into sDBdriverSettings["querycount"]
  put "?" into sDBdriverSettings["bindmarker"] -- not used
  put TRUE into sDBdriverSettings["savequeries"]
  put "" into sDBdriverSettings["queries"]
  put "" into sDBdriverSettings["querytimes"]
  put "" into sDBdriverSettings["datacache"]
  put TRUE into sDBdriverSettings["transenabled"]
  put TRUE into sDBdriverSettings["transstrict"]
  put 0 into sDBdriverSettings["transdepth"]
  put TRUE into sDBdriverSettings["transstatus"]
  put FALSE into sDBdriverSettings["transfailure"]
  put FALSE into sDBdriverSettings["cacheon"]
  put "" into sDBdriverSettings["cachedir"]
  put FALSE into sDBdriverSettings["cacheautodel"]
  put TRUE into sDBdriverSettings["protectIdentifiers"]
  put "*" into sDBdriverSettings["reservedIdentifiers"][1]

  put FALSE into sDBdriverSettings["iswritetype"]
  put FALSE into sDBdriverSettings["affectedrows"]

  # THESE ARE USED WITH ORACLE
  put "" into sDBdriverSettings["stmtid"]
  put "" into sDBdriverSettings["cursid"]
  put "" into sDBdriverSettings["limitused"]
end _rigSetDefaultValues







/*----------------------------------------------------------------------
--| COMMAND rigDbDriver
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-07-09
--| Last Mod: 06-07-09
--| Requires: rigLogMessage
--|
--| Summary: Sets the library variables values. Accepts one parameter
--|            containing the database connection settings.
--|
--| Format:  rigDbDriver param1
--|
--| Parameters: array <pParams>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbDriver pParams
	if pParams is an array then
		 repeat for each key tKey in pParams
			put pParams[tKey] into sDBdriverSettings[tKey]

			if tKey is "connid" then
				put pParams[tKey] into gRigA["databaseID"]
			end if
		end repeat
	end if

	rigLogMessage "debug", "Database Driver Library Loaded"
end rigDbDriver







/*----------------------------------------------------------------------
--| FUNCTION rigFetchDBdriverSetting
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-07-06
--| Last Mod: 2020-03-04
--| Requires: --
--|
--| Summary: Fetch setting(s) from DB driver settings.
--|
--| Format:  rigFetchDBdriverSetting(param1)
--|
--| Parameters: string <pSettingsKey>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigFetchDBdriverSetting pSettingsKey
  local tKey, tSettingsA

  if comma is in pSettingsKey then
    repeat for each item tKey in pSettingsKey
      put sDBdriverSettings[tKey] into tSettingsA[tKey]
    end repeat

  	return tSettingsA
  end if

  return sDBdriverSettings[pSettingsKey]
end rigFetchDBdriverSetting







/*----------------------------------------------------------------------
--| COMMAND rigSetDBdriverSetting
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-07-09
--| Last Mod: 06-07-09
--| Requires: --
--|
--| Summary: Set driver values.
--|
--| Format:  rigSetDBdriverSetting param1, param2
--|
--| Parameters: string <pKey>, mixed <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetDBdriverSetting pKey pValue
	put pValue into sDBdriverSettings[pKey]
end rigSetDBdriverSetting









/*----------------------------------------------------------------------
--| FUNCTION rigDbInitialize
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-07-09
--| Last Mod: 04-05-13
--| Requires:  rigLogMessage, rigDbDisplayError, rigDbRedirectOnError
--|
--| Summary: Initialize Database Settings.
--|
--| Format:  rigDbInitialize()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigDbInitialize
	# IF AN EXISTING CONNECTION RESOURCE IS AVAILABLE
	# THERE IS NO NEED TO CONNECT AND SELECT THE DATABASE
	if sDBdriverSettings["connid"] is an integer then
		return TRUE
	end if

	# ----------------------------------------------------------------

	# CONNECT TO THE DATABASE AND SET THE CONNECTION ID
	if sDBdriverSettings["pconnect"] is TRUE then
		-- currently not implemented
	else
		put rigDbConnect() into sDBdriverSettings["connid"]
		put sDBdriverSettings["connid"] into gRigA["databaseID"]
	end if

	# NO CONNECTION RESOURCE?  THROW AN ERROR
	if sDBdriverSettings["connid"] is not an integer then
		rigLogMessage "error", "Unable to connect to the database:" && sDBdriverSettings["database"]
		# ERROR HANDLING
		if sDBdriverSettings["dbdebug"] is TRUE then
			rigDbDisplayError "db_unable_to_connect"

			else if sDBdriverSettings["dbRedirectOnError"] <> empty then
				rigDbRedirectOnError
		end if

		return FALSE

		else
			# WE'VE SELECTED THE DB. Now WE SET THE CHARACTER SET
			if rigDbSetCharset(sDBdriverSettings["charset"],  sDBdriverSettings["dbcollat"]) is not TRUE then
				return FALSE
			else
				return TRUE
			end if
	end if

	return TRUE
end rigDbInitialize







/*----------------------------------------------------------------------
--| FUNCTION rigDbSetCharset
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-07-09
--| Last Mod: 04-05-13
--| Requires:  _rigDbSetCharset, rigLogMessage, rigDbDisplayError, rigDbRedirectOnError
--|
--| Summary: Set client character set.
--|
--| Format:  rigDbSetCharset(param1, param2)
--|
--| Parameters: string <pCharset>, string <pCollation>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigDbSetCharset pCharset pCollation
	if _rigDbSetCharset(pCharset, pCollation) is not TRUE then
		# ERROR HANDLING
		rigLogMessage "error", "Unable to set database connection charset:" && sDBdriverSettings["charset"]

		if sDBdriverSettings["dbdebug"] is TRUE then
			rigDbDisplayError "db_unable_to_set_charset", sDBdriverSettings["charset"]

			else if sDBdriverSettings["dbRedirectOnError"] <> empty then
				rigDbRedirectOnError
		end if
		return FALSE
	end if

	return TRUE
end rigDbSetCharset








/*----------------------------------------------------------------------
--| FUNCTION rigDbPlatform
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-09-09
--| Last Mod: 29-09-09
--| Requires: --
--|
--| Summary: The name of the platform in use (mysql, postgresql, etc...).
--|
--| Format:  rigDbPlatform()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbPlatform
	return sDBdriverSettings["dbdriver"]
end rigDbPlatform








/*----------------------------------------------------------------------
--| FUNCTION rigDbVersion
--|
--| Author: rabit
--| Version:  1.2
--| Created: 29-09-09
--| Last Mod: 27-09-15
--| Requires: _rigDbVersion(), rigFetchDBdriverSetting(), rigDbDisplayError,
--|            rigDbRedirectOnError, rigDbQuery(), rigDbRow()
--|
--| Summary: Database Version Number.  Returns a string containing the
--|            version of the database being used.
--|
--| Format:  rigDbVersion()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbVersion
  local tSql, tQuery

	put _rigDbVersion() into tSql

	if tSql is FALSE then
		# ERROR HANDLING
		if rigFetchDBdriverSetting("dbdebug") is TRUE then
			rigDbDisplayError "db_unsupported_function"

			else if rigFetchDBdriverSetting("dbRedirectOnError") <> empty then
				rigDbRedirectOnError
		end if

		return FALSE
	end if

	if sDBdriverSettings["dbdriver"] is "oci8" then
		return tSql
	end if

	put rigDbQuery(tSql) into tQuery

	return rigDbRow("ver")
end rigDbVersion







/*----------------------------------------------------------------------
--| FUNCTION rigDbQuery
--|
--| Author: rabit
--| Version:  1.11
--| Created: 2009-07-09
--| Last Mod: 2018-04-30
--| Requires: rigLogMessage, rigDbDisplayError, _rigLoadRdriver, rigCompileBinds, rigSimpleQuery(),
--|            rigDbErrorMessage(), rigListFields(), rigTransComplete(), rigIsWriteType(), _rigCacheInit(),
--|            rigDeleteDBcacheFiles, rigNumRows(), rigWriteSQLcache(), rigDbRedirectOnError
--|
--| Summary: Accepts an SQL string as input and returns the result upon
--|            successful execution of a "read" type query.  Returns boolean TRUE
--|            upon successful execution of a "write" type query. Returns boolean
--|            FALSE upon failure, and if the dbdebug variable in the database config file is set to TRUE
--|            will raise an error.
--|
--| Format:  rigDbQuery(param1, param2)
--|
--| Parameters: string <pSQL> the sql query string, array <pBinds> array of binding data
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbQuery pSQL pBinds
  local tBinds, tSQL, tStrFound, tFoundVar1, tFoundVar2, tRegEx, tStrToSwap
  local tReplacementStr, tSQLcache, tQueriesNum, tNewQueriesNum, tTimeStart
  local tQueryResult, tQueryTimesNum, tNewQueryTimesNum, tErrorMessage
  local tErrorArray, tTimeEnd, tCacheInit, tRES, tChangeFieldNamesListDelimiter
  local tCR, tSerializedResultArray

	if pBinds is not an array and pBinds is "" then
		put FALSE into tBinds
	else
		put pBinds into tBinds
	end if

	put pSQL into tSQL
	if tSQL is "" then
		# ERROR HANDLING
		if sDBdriverSettings["dbdebug"] is TRUE then
			rigLogMessage "error", "Invalid query:" && tSQL
			rigDbDisplayError "db_invalid_query"

			else if sDBdriverSettings["dbRedirectOnError"] <> empty then
				rigLogMessage "error", "Invalid query:" && tSQL
				rigDbRedirectOnError
		end if
		return FALSE
	end if

	# VERIFY TABLE PREFIX AND REPLACE IF NECESSARY
	if ((sDBdriverSettings["dbprefix"]) <> "" and (sDBdriverSettings["swappre"] <> "")) and (sDBdriverSettings["dbprefix"] <> sDBdriverSettings["swappre"]) then
		put TRUE into tStrFound

		put empty into tFoundVar1 -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
		put empty into tFoundVar2
		repeat until tStrFound is not TRUE
        		put "(\W)" & sDBdriverSettings["swappre"] & "(\S+?)" into tRegEx
        		get matchText(tSQL,tRegEx, tFoundVar1, tFoundVar2)

        		if it is TRUE then
            			put tFoundVar1 & sDBdriverSettings["swappre"] & tFoundVar2 into tStrToSwap
            			put tFoundVar1 & sDBdriverSettings["dbprefix"] & tFoundVar2 into tReplacementStr
            			replace tStrToSwap with tReplacementStr in tSQL
        		else
            			put FALSE into tStrFound
        		end if
    		end repeat
	end if

	# IS QUERY CACHING ENABLED?  IF THE QUERY IS A "READ TYPE"
	# WE WILL LOAD THE CACHING Library AND RETURN THE PREVIOUSLY
	# CACHED QUERY IF IT EXISTS
	if (sDBdriverSettings["cacheon"] is TRUE) and (word 1 of tSQL is "SELECT") then
		if _rigCacheInit() is TRUE then
			# LOAD RESULT DRIVER
			_rigLoadRdriver

			put rigReadSQLcache(tSQL) into tSQLcache
			if tSQLcache is not FALSE then

				--rigLoadHelper "array"
				-- put unserialize(tSQLcache) into tSQLcache

				# UNSERIALIZE THE CACHED DATA
				put arrayDecode(tSQLcache) into tSQLcache

				# SET THE sDBresult VARIABLE IN DBresult.lc
				rigDbSetResultFromCache tSQLcache["resultarray"], tSQLcache["numrows"], tSQLcache["fieldnames"], tSQLcache["fieldnumbers"]

				return tSQLcache
			end if
		end if
	end if

	# COMPILE BINDS IF NEEDED
	if tBinds is not FALSE then
		put rigCompileBinds(tSQL, tBinds) into tSQL
	end if

	# SAVE THE  QUERY FOR DEBUGGING
	if sDBdriverSettings["savequeries"] is TRUE then
		if sDBdriverSettings["queries"] is an array then
			put the number of lines in the keys of sDBdriverSettings["queries"] into tQueriesNum
			put tQueriesNum + 1 into tNewQueriesNum
			put tSQL into sDBdriverSettings["queries"][tNewQueriesNum]
		else
			put tSQL into sDBdriverSettings["queries"][1]
		end if
	end if


	# CHECK IF QUERY IS OF TYPE WRITE TO CHOOSE THE APPROPRIATE QUERY COMMAND
	# IN THE _rigDbExecute COMMAND
	put rigIsWriteType(tSQL) into sDBdriverSettings["iswritetype"]

	# START THE QUERY TIMER
	put the long seconds into tTimeStart

	# RUN THE QUERY
	-- put rigDbSimpleQuery(tSQL) into sDBdriverSettings["resultid"]
	put rigDbSimpleQuery(tSQL) into tQueryResult

	# STORE RECORD SET ID OR AFFECTED ROWS
	if sDBdriverSettings["iswritetype"] is TRUE then
		put tQueryResult into sDBdriverSettings["affectedrows"]
		put FALSE into sDBdriverSettings["resultid"]
	else
		put tQueryResult into sDBdriverSettings["resultid"]
		put FALSE into sDBdriverSettings["affectedrows"]
	end if

	# CHECK FOR ERROR IN RESULT
	-- if sDBdriverSettings["resultid"] is FALSE then
	if tQueryResult is FALSE then
		if sDBdriverSettings["savequeries"] is TRUE then
			put the number of lines in the keys of sDBdriverSettings["querytimes"] into tQueryTimesNum
			put tQueryTimesNum + 1 into tNewQueryTimesNum
			put 0 into sDBdriverSettings["querytimes"][tNewQueryTimesNum]
		end if

		# THIS WILL TRIGGER A ROLLBACK IF TRANSACTIONS ARE BEING USED
		put FALSE into sDBdriverSettings["transstatus"]

		# ERROR HANDLING
		if sDBdriverSettings["dbdebug"] is TRUE then
			# GRAB THE ERROR MESSAGE NOW, AS WE MIGHT RUN SOME
			# ADDITIONAL QUERIES BEFORE DISPLAYING THE ERROR
			put rigDbErrorMessage() into tErrorMessage

			# WE CALL THIS FUNCTION IN ORDER TO ROLL-BACK QUERIES
			# IF TRANSACTIONS ARE ENABLED.  IF WE DON'T CALL THIS HERE
			# THE ERROR MESSAGE WILL TRIGGER AN EXIT, CAUSING THE
			# TRANSACTIONS TO REMAIN IN LIMBO.
			get rigTransComplete()

			# LOG AND DISPLAY ERRORS
			rigLogMessage "error", "Query error:" & tErrorMessage

			put tErrorMessage into tErrorArray[1]
			put tSQL into tErrorArray[2]
			rigDbDisplayError tErrorArray

			else if sDBdriverSettings["dbRedirectOnError"] <> empty then
				rigDbRedirectOnError
		end if

		return FALSE
	end if

	# STOP AND AGGREGATE THE QUERY TIME RESULTS
	put the long seconds into tTimeEnd
	add (tTimeEnd - tTimeStart) to sDBdriverSettings["benchmark"]

	if sDBdriverSettings["savequeries"] is TRUE then
		put the number of lines in the keys of sDBdriverSettings["querytimes"] into tQueryTimesNum
		put tQueryTimesNum + 1 into tNewQueryTimesNum
		put (tTimeEnd - tTimeStart) into sDBdriverSettings["querytimes"][tNewQueryTimesNum]
	end if

	# INCREMENT THE QUERY COUNTER
	add 1 to sDBdriverSettings["querycount"]

	# WAS THE QUERY A "WRITE" TYPE?
	# IF SO WE'LL SIMPLY RETURN TRUE
	-- if rigIsWriteType(tSQL) is TRUE then
	if sDBdriverSettings["iswritetype"] is TRUE then
		# IF CACHING IS ENABLED WE'LL AUTO-CLEANUP ANY
		# EXISTING FILES RELATED TO THIS PARTICULAR URI
		put _rigCacheInit() into tCacheInit
		if (sDBdriverSettings["cacheon"] is TRUE) and (sDBdriverSettings["cacheautodel"] is TRUE) and (tCacheInit is TRUE) then
			rigDeleteDBcacheFiles
		end if

		return TRUE
	end if

	# LOAD RESULT DRIVER
	_rigLoadRdriver

	# STORE THE RESULT DATA IN AN ARRAY
	#
	put sDBdriverSettings["connid"] into tRES["connid"]
	put sDBdriverSettings["resultid"] into tRES["resultid"]
	# CLEAR RESULT ARRAY
	rigDbResetResultValue "resultarray"

  # CHECK IF IT IS A "SELECT IF" OR A "SELECT GREATEST" QUERY
  put FALSE into tChangeFieldNamesListDelimiter
  if ("SELECT GREATEST" is in tSQL) or ("SELECT IF" is in tSQL) then
    put TRUE into tChangeFieldNamesListDelimiter
  end if

	put rigDBresult(tChangeFieldNamesListDelimiter) into tRES["resultarray"]

	if sDBdriverSettings["dbdriver"] is "oci8" then
		put sDBdriverSettings["stmtid"] into tRES["stmtid"]
		put numToCodepoint(0) into sDBdriverSettings["cursid"] -- NULL
		put sDBdriverSettings["limitused"] into tRES["limitused"]
		put FALSE into sDBdriverSettings["stmtid"]
	end if

	# OCI8 VARS MUST BE SET BEFORE CALLING THIS
	put rigNumRows(sDBdriverSettings["resultid"]) into tRES["numrows"]


	# EXTRA BONUS
	put rigListFields(sDBdriverSettings["resultid"]) into tRES["fieldnames"]
	put rigFieldNumbers(tRES["fieldnames"]) into tRES["fieldnumbers"]


	# IS QUERY CACHING ENABLED?  IF SO, WE'LL SERIALIZE THE
	# RESULT ARRAY AND SAVE IT TO A CACHE FILE.
	put _rigCacheInit() into tCacheInit
	if (sDBdriverSettings["cacheon"] is TRUE) and (tCacheInit is TRUE) then
		put tRES["numrows"] into tCR["numrows"]
		put tRES["fieldnames"] into tCR["fieldnames"]
		put tRES["fieldnumbers"] into tCR["fieldnumbers"]
		put tRES["resultarray"] into tCR["resultarray"]

		--rigLoadHelper "array"
		--put serialize(tCR, "tRES") into tSerializedResultArray

		# SERIALIZE THE RESULT ARRAY
		put arrayEncode(tCR) into tSerializedResultArray

		# WRITE THE DATA TO DISK
		get rigWriteSQLcache(tSQL, tSerializedResultArray)
	end if

	return tRES
end rigDbQuery








/*----------------------------------------------------------------------
--| COMMAND _rigLoadRdriver
--|
--| Author: rabit
--| Version:  1.1
--| Created: 17-07-09
--| Last Mod: 17-09-15
--| Requires: --
--|
--| Summary: Load the result drivers.
--|
--| Format:  _rigLoadRdriver
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigLoadRdriver
	if sResultDriversLoaded is not TRUE then
		start using stack (gRigA["BASEPATH"] & "database/DBresult.livecodescript")
		start using stack (gRigA["BASEPATH"] & "database/drivers/" & sDBdriverSettings["dbdriver"] & "/" & sDBdriverSettings["dbdriver"] & "Result.livecodescript")

		put TRUE into sResultDriversLoaded
	end if
end _rigLoadRdriver








/*----------------------------------------------------------------------
--| FUNCTION rigDbSimpleQuery
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-07-09
--| Last Mod: 19-07-09
--| Requires: --
--|
--| Summary: This is a simplified version of the rigDbQuery() function.  Internally
--|             we only use it when running transaction commands since they do
--|             not require all the features of the main query() function.
--|
--| Format:  rigDbSimpleQuery(param1)
--|
--| Parameters: string <pSQL> the sql statement
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbSimpleQuery pSQL
	if sDBdriverSettings["connid"] is FALSE then
		get rigDbInitialize()
	end if

	return _rigDbExecute(pSQL, sDBdriverSettings["connid"])
end rigDbSimpleQuery








/*----------------------------------------------------------------------
--| COMMAND rigDbTransOff
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-09-09
--| Last Mod: 30-09-09
--| Requires: --
--|
--| Summary: This permits transactions to be disabled at run-time.
--|
--| Format:  rigDbTransOff
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbTransOff
	put FALSE into sDBdriverSettings["transenabled"]
end rigDbTransOff







/*----------------------------------------------------------------------
--| COMMAND rigDbTransStrict
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-09-09
--| Last Mod: 30-09-09
--| Requires: --
--|
--| Summary: When strict mode is enabled, if you are running multiple groups of
--|            transactions, if one group fails all groups will be rolled back.
--|            If strict mode is disabled, each group is treated autonomously, meaning
--|            a failure of one group will not affect any others.
--|
--| Format:  rigDbTransStrict param1
--|
--| Parameters: bool <pMode>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbTransStrict pMode
  local tMode

	if pMode is empty then
		put TRUE into tMode
	else
		put pMode into tMode
	end if

	if tMode is a boolean then
		put tMode into sDBdriverSettings["transstrict"]
	else
		put TRUE into sDBdriverSettings["transstrict"]
	end if
end rigDbTransStrict








/*----------------------------------------------------------------------
--| COMMAND rigDbTransStart
--|
--| Author: rabit
--| Version:  1.1
--| Created: 30-09-09
--| Last Mod: 01-01-10
--| Requires: rigTransBegin()
--|
--| Summary: Start transaction.
--|
--| Format:  rigDbTransStart param1
--|
--| Parameters: bool <pTestMode>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigDbTransStart pTestMode
  local tTestMode, tResult

	if pTestMode is empty then
		put FALSE into tTestMode
	else
		put pTestMode into tTestMode
	end if

	if sDBdriverSettings["transenabled"] is FALSE then
		return FALSE
	end if

	# WHEN TRANSACTIONS ARE NESTED WE ONLY BEGIN/COMMIT/ROLLBACK THE OUTERMOST ONES
	if sDBdriverSettings["transdepth"] > 0 then
		add 1 to sDBdriverSettings["transdepth"]
		return ""
	end if

	put rigTransBegin(tTestMode) into tResult
	if tResult is FALSE then
		return tResult
	end if

	return TRUE
end rigDbTransStart







/*----------------------------------------------------------------------
--| FUNCTION rigTransComplete
--|
--| Author: rabit
--| Version:  1.1
--| Created: 20-07-09
--| Last Mod: 01-01-10
--| Requires: rigTransRollback, rigLogMessage, rigTransCommit
--|
--| Summary: Complete transaction.
--|
--| Format:  rigTransComplete()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigTransComplete
	if sDBdriverSettings["transenabled"] is not TRUE then
		return FALSE
	end if

	# WHEN TRANSACTIONS ARE NESTED WE ONLY BEGIN/COMMIT/ROLLBACK THE OUTERMOST ONES
	if sDBdriverSettings["transdepth"] > 1 then
		put sDBdriverSettings["transdepth"] -1 into sDBdriverSettings["transdepth"]
		return TRUE
	end if

	# THE rigDbQuery() FUNCTION WILL SET THIS FLAG (transstatus) TO FALSE IN THE EVENT THAT A QUERY FAILED
	# transfailure FLAG IS SET TO TRUE IN TEST MODE
	if (sDBdriverSettings["transstatus"] is FALSE) or (sDBdriverSettings["transfailure"] is TRUE) then

		rigTransRollback

		# IF WE ARE NOT RUNNING IN STRICT MODE, WE WILL RESET
		# THE _TRANSSTATUS FLAG SO THAT SUBSEQUENT GROUPS OF TRANSACTIONS
		# WILL BE PERMITTED.
		if sDBdriverSettings["transstrict"] is FALSE then
			put TRUE into sDBdriverSettings["transstatus"]
		end if

		rigLogMessage "debug", "DB Transaction Failure"
		return FALSE
	end if

	rigTransCommit
	if the result is FALSE then
		return FALSE
	end if

	return TRUE
end rigTransComplete







/*----------------------------------------------------------------------
--| FUNCTION rigDbTransStatus
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-09-09
--| Last Mod: 30-09-09
--| Requires: --
--|
--| Summary: Lets you retrieve the transaction flag to determine if it has failed.
--|
--| Format:  rigDbTransStatus()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigDbTransStatus
	return sDBdriverSettings["transstatus"]
end rigDbTransStatus







/*----------------------------------------------------------------------
--| FUNCTION rigCompileBinds
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2009-07-18
--| Last Mod: 2017-04-04
--| Requires: rigDbEscape()
--|
--| Summary: Compile bindings. pBinds must be a comma separated list or a numbered array.
--|
--| Format:  rigCompileBinds(param1, param2)
--|
--| Parameters: string <pSQL> the sql statement, mixed <pBinds> an array or a
--|             comma separated list of bind data
--|
--| Return: string
----------------------------------------------------------------------*/

function rigCompileBinds pSQL pBinds
  local tSQl, tBinds, tNumOfBinds, tBindsEscaped

	if ":1" is not in pSQL then
		return pSQL
	end if

	put pSQL into tSQl
	put pBinds into tBinds

	# GET LIST OF ESCAPED BIND VALUES
	# WE DON'T USE COMBINE TO KEEP THE CORRECT ARRAY VALUE ORDER
	if tBinds is an array then
		put the number of lines of the keys of tBinds into tNumOfBinds
		repeat with i = 1 to tNumOfBinds
			put rigDbEscape(tBinds[i]) into tBindsEscaped[i]
		end repeat
	else
		put 0 into tNumOfBinds

		repeat for each item tItem in tBinds
			add 1 to tNumOfBinds
			put rigDbEscape(tItem) into tBindsEscaped[tNumOfBinds]
		end repeat
	end if

	# SUBSTITUTE BIND MARKERS
	repeat with i = tNumOfBinds down to 1
		replace ":" & i with tBindsEscaped[i] in tSQl
	end repeat

	return tSQl
end rigCompileBinds







/*----------------------------------------------------------------------
--| FUNCTION rigIsWriteType
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-07-20
--| Last Mod: 2017-06-27
--| Requires: --
--|
--| Summary: Determines if a query is a "write" type.
--|
--| Format:  rigIsWriteType()
--|
--| Parameters: string <pSQL> the sql statement
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigIsWriteType pSQL
  local tRegEx

	put "(?i)^\s*" & quote & "?(SET|INSERT|UPDATE|DELETE|REPLACE|CREATE|DROP|TRUNCATE|LOAD DATA|COPY|ALTER|GRANT|REVOKE|LOCK|UNLOCK)\s+" into tRegEx

	get matchText(pSQL,tRegEx)

	return it
end rigIsWriteType








/*----------------------------------------------------------------------
--| FUNCTION rigDbElapsedTime
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-09-09
--| Last Mod: 30-09-09
--| Requires: rigNumber_format()
--|
--| Summary: Calculate the aggregate query elapsed time.
--|
--| Format:  rigDbElapsedTime(param1)
--|
--| Parameters: integer <pDecimals> the number of decimal places
--|
--| Return: float
----------------------------------------------------------------------*/

function rigDbElapsedTime pDecimals
  local tDecimals

	if pDecimals is empty then
		put 6 into tDecimals
	else
		put pDecimals into tDecimals
	end if

	return rigNumber_format(sDBdriverSettings["benchmark"], tDecimals)
end rigDbElapsedTime







/*----------------------------------------------------------------------
--| FUNCTION rigDbTotalQueries
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-09-09
--| Last Mod: 30-09-09
--| Requires: --
--|
--| Summary: Returns the total number of queries.
--|
--| Format:  rigDbTotalQueries()
--|
--| Parameters: --
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigDbTotalQueries
	return sDBdriverSettings["querycount"]
end rigDbTotalQueries







/*----------------------------------------------------------------------
--| FUNCTION rigDbLastQuery
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-09-09
--| Last Mod: 30-09-09
--| Requires: --
--|
--| Summary: Returns the last query that was executed.
--|
--| Format:  rigDbLastQuery()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbLastQuery
  local tKey

	put line -1 in the keys of sDBdriverSettings["queries"] into tKey

	return sDBdriverSettings["queries"][tKey]
end rigDbLastQuery







/*----------------------------------------------------------------------
--| FUNCTION rigDbEscape
--|
--| Author: rabit
--| Version:  1.2
--| Created: 18-07-09
--| Last Mod: 21-12-14
--| Requires: --
--|
--| Summary: Escapes data based on type. Sets boolean and null types.
--|
--| Format:  rigDbEscape(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbEscape pStr
	if pStr is a boolean then
		if pStr is TRUE then
			return 1
		else
			return 0
		end if
	end if

	if pStr is numToCodepoint(0) then
		-- return "'" & "NULL" & "'"
		return "NULL"
	end if

	return "'" & rigEscapeStr(pStr) & "'"
end rigDbEscape







/*----------------------------------------------------------------------
--| FUNCTION rigEscapeLikeStr
--|
--| Author: rabit
--| Version:  1.0
--| Created: 26-09-09
--| Last Mod: 26-09-09
--| Requires: rigEscapeStr()
--|
--| Summary: Calls the individual driver for platform
--|                   specific escaping for LIKE conditions.
--|
--| Format:  rigEscapeLikeStr(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigEscapeLikeStr pStr
    	return rigEscapeStr(pStr, TRUE)
end rigEscapeLikeStr








/*----------------------------------------------------------------------
--| FUNCTION rigPrimary
--|
--| Author: rabit
--| Version:  1.1
--| Created: 30-09-09
--| Last Mod: 03-08-12
--| Requires: rigDbListFields()
--|
--| Summary: Retrieves the primary key.  It assumes that the row in the first
--|            position is the primary key.
--|
--| Format:  rigPrimary(param1)
--|
--| Parameters: string <pTable>	the table name
--|
--| Return: string
----------------------------------------------------------------------*/

function rigPrimary pTable
  local tFields

	put rigDbListFields(pTable) into tFields

	if tFields is not an array then
		return FALSE
	end if

	return tFields[1]
end rigPrimary








/*----------------------------------------------------------------------
--| FUNCTION rigDbListTables
--|
--| Author: rabit
--| Version:  1.1
--| Created: 30-09-09
--| Last Mod: 04-05-13
--| Requires: _rigDbListTables(), rigFetchDBdriverSetting(), rigDbDisplayError,
--|           rigDbQuery(), rigDbRedirectOnError
--|
--| Summary: Returns an array of table names.
--|
--| Format:  rigDbListTables(param1)
--|
--| Parameters: bool <pConstrainByPrefix>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbListTables pConstrainByPrefix
  local tConstrainByPrefix, tRetval, tGetFailed, tSql, tQuery
  local tCounter, tKey, tRow, tK, tVal

	if pConstrainByPrefix is empty then
		put FALSE into tConstrainByPrefix
	else
		put pConstrainByPrefix into tConstrainByPrefix
	end if

	# IS THERE A CACHED RESULT?
	if sDBdriverSettings["datacache"]["table_names"] is an array then
		return sDBdriverSettings["datacache"]["table_names"]
	end if

	# GET TABLE NAMES USING REV BUILT-IN FUNCTION
	put revDatabaseTableNames(sDBdriverSettings["connid"]) into tRetval
	if "revdberr" is in tRetval then
		put TRUE into tGetFailed
	else
		put FALSE into tGetFailed
		split tRetval using LF
	end if

	# GET TABLE NAMES USING QUERY
	if tGetFailed is TRUE then
		put _rigDbListTables(tConstrainByPrefix) into tSql
		if tSql is FALSE then
			# ERROR HANDLING
			if rigFetchDBdriverSetting("dbdebug") is TRUE then
				rigDbDisplayError "db_unsupported_function"

				else if rigFetchDBdriverSetting("dbRedirectOnError") <> empty then
					rigDbRedirectOnError
			end if

			return FALSE
		end if

		put empty into tRetval
		put rigDbQuery(tSql) into tQuery

		if tQuery["numrows"] > 0 then
			put 0 into tCounter
			repeat for each key tKey in tQuery["resultarray"]
				add 1 to tCounter
				put tQuery["resultarray"][tKey] into tRow
				put line 1 in the keys of tRow into tK
				put tRow[tK] into tVal

				put tVal into tRetval[tCounter]
			end repeat
		end if
	end if

	put tRetval into sDBdriverSettings["datacache"]["tableNames"]

	return sDBdriverSettings["datacache"]["tableNames"]
end rigDbListTables








/*----------------------------------------------------------------------
--| FUNCTION rigDbTableExists
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-10-09
--| Last Mod: 01-10-09
--| Requires: _rigProtectIdentifiers(), rigDbListTables(), rigInArray()
--|
--| Summary: Determine if a particular table exists.
--|
--| Format:  rigDbTableExists(param1)
--|
--| Parameters: string <pTableName>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigDbTableExists pTableName
  local tTableName, tTables

	put _rigProtectIdentifiers(pTableName, TRUE, FALSE, FALSE) into tTableName
	put rigDbListTables() into tTables

	return rigInArray(tTables, tTableName)
end rigDbTableExists







/*----------------------------------------------------------------------
--| FUNCTION rigDbListFields
--|
--| Author: rabit
--| Version:  1.2
--| Created: 01-10-09
--| Last Mod: 18-04-14
--| Requires: rigFetchDBdriverSetting(), rigDbDisplayError, _rigProtectIdentifiers(),
--|           _rigDbListColumns(), rigDbRedirectOnError
--|
--| Summary: Fetch MySQL Field Names.
--|
--| Format:  rigDbListFields(param1)
--|
--| Parameters: string <pTable> the table name
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbListFields pTable
  local tTable, tRetval, tGetFailed, tSql, tDriver, tQuery, tCounter
  local tKey, tRow, tVal, tK

	# IS THERE A CACHED RESULT?
	if sDBdriverSettings["datacache"]["fieldnames"][pTable] is an array then
		return sDBdriverSettings["datacache"]["fieldnames"][pTable]
	end if

	if pTable is empty then
		# ERROR HANDLING
		if rigFetchDBdriverSetting("dbdebug") is TRUE then
			rigDbDisplayError "db_field_param_missing"

			else if rigFetchDBdriverSetting("dbRedirectOnError") <> empty then
				rigDbRedirectOnError
		end if

		return FALSE
	end if

	put _rigProtectIdentifiers(pTable, TRUE, NULL, FALSE) into tTable

	# GET COLUMN NAMES USING REV BUILT-IN FUNCTION
	put revDatabaseColumnNames(sDBdriverSettings["connid"], tTable) into tRetval
	if "revdberr" is in tRetval then
		put TRUE into tGetFailed
	else
		put FALSE into tGetFailed
		split tRetval using comma
	end if

	# GET COLUMN NAMES USING QUERY
	if tGetFailed is TRUE then
		put empty into tRetval
		put _rigDbListColumns(tTable) into tSql

		if tSql is FALSE then
			# ERROR HANDLING
			if rigFetchDBdriverSetting("dbdebug") is TRUE then
				rigDbDisplayError "db_unsupported_function"

				else if rigFetchDBdriverSetting("dbRedirectOnError") <> empty then
					rigDbRedirectOnError
			end if

			return FALSE
		end if

    # CHECK IF DRIVER IS SQLITE
    put rigFetchDBdriverSetting("dbdriver") into tDriver

		put rigDbQuery(tSql) into tQuery

		put 0 into tCounter
		repeat for each key tKey in tQuery["resultarray"]
			add 1 to tCounter
			put tQuery["resultarray"][tKey] into tRow

      # THE SQLITE QUERY RETURNS A COMPREHENSIVE TABLE INFO
      # SO, WE JUST PICK THE VALUE OF THE COLUMN NAME FIELD
      if tDriver is "sqlite" then
        put tRow[tQuery["fieldnumbers"]["name"]] into tVal
      else

        # THIS IS THE PostgreSQL / MySQL VERSION
				put line 1 in the keys of tRow into tK
				put tRow[tK] into tVal
			end if

			put tVal into tRetval[tCounter]
		end repeat
	end if

	put tRetval into sDBdriverSettings["datacache"]["fieldnames"][tTable]

	return sDBdriverSettings["datacache"]["fieldnames"][tTable]
end rigDbListFields








/*----------------------------------------------------------------------
--| FUNCTION rigDbFieldExists
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-10-09
--| Last Mod: 01-10-09
--| Requires: rigDbListFields(), rigInArray()
--|
--| Summary: Determine if a particular field exists.
--|
--| Format:  rigDbFieldExists(param1, param2)
--|
--| Parameters: string <pFieldName> string <pTableName>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigDbFieldExists pFieldName pTableName
  local tFields

	put rigDbListFields(pTableName) into tFields

	return rigInArray(tFields, pFieldName)
end rigDbFieldExists








/*----------------------------------------------------------------------
--| FUNCTION rigDbFieldData
--|
--| Author: rabit
--| Version:  1.3
--| Created: 01-10-09
--| Last Mod: 04-05-13
--| Requires: rigFetchDBdriverSetting(), rigDbDisplayError, _rigProtectIdentifiers(),
--|           _rigDbFieldData(), rigDbQuery(), rigDbRedirectOnError
--|
--| Summary: Returns an array with field data.
--|
--| Format:  rigDbFieldData(param1)
--|
--| Parameters: string <pTable> the table name
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbFieldData pTable
  local tTable, tSql

	if pTable is empty then
		# ERROR HANDLING
		if rigFetchDBdriverSetting("dbdebug") is TRUE then
			rigDbDisplayError "db_field_param_missing"

			else if rigFetchDBdriverSetting("dbRedirectOnError") <> empty then
				rigDbRedirectOnError
		end if

		return FALSE
	end if

	put _rigProtectIdentifiers(pTable, TRUE, NULL, FALSE) into tTable
	put _rigDbFieldData(tTable) into tSql

	get rigDbQuery(tSql)

	return rigFieldData(tTable)
end rigDbFieldData








/*----------------------------------------------------------------------
--| FUNCTION rigDbInsertString
--|
--| Author: rabit
--| Version:  1.1
--| Created: 01-10-09
--| Last Mod: 14-10-09
--| Requires: _rigEscapeIdentifiers(), rigDbEscape(), _rigProtectIdentifiers(), _rigInsert()
--|
--| Summary: Generate an insert string.
--|
--| Format:  rigDbInsertString(param1, param2)
--|
--| Parameters: string <pTable> the table upon which the query will be performed,
--|                       array <pData> an associative array data of key/values
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbInsertString pTable pData
  local tCounter, tKey, tVal, tFields, tValues, tTable

	put 0 into tCounter
	repeat for each key tKey in pData
		add 1 to tCounter
		put pData[tKey] into tVal

		put _rigEscapeIdentifiers(tKey) into tFields[tCounter]
		put rigDbEscape(tVal) into tValues[tCounter]
	end repeat

	put _rigProtectIdentifiers(pTable, TRUE, NULL, FALSE) into tTable

	return _rigInsert(tTable, tFields, tValues)
end rigDbInsertString








/*----------------------------------------------------------------------
--| FUNCTION rigDbUpdateString
--|
--| Author: rabit
--| Version:  1.1
--| Created: 01-10-09
--| Last Mod: 15-10-09
--| Requires: _rigProtectIdentifiers(), rigDbEscape(), _rigHasOperator(), rigDbEscape(), _rigUpdate()
--|
--| Summary: Generate an update string.
--|
--| Format:  rigDbUpdateString(param1, param2)
--|
--| Parameters: string <pTable> the table upon which the query will be performed,
--|               array <pData> an associative array data of key/values,
--|               mixed <pWhere> the "where" statement
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbUpdateString pTable pData pWhere
  local tKey, tVal, tK, tFields, tDest, tCounter, tPrefix, tTable

	if (pWhere is not an array) and (pWhere is empty) then
		return FALSE
	end if

	repeat for each key tKey in pData
		put pData[tKey] into tVal

		put _rigProtectIdentifiers(tKey) into tK
		put rigDbEscape(tVal) into tFields[tK]
	end repeat

	if pWhere is not an array then
		put pWhere into tDest[1]
	else
		put empty into tDest

		put 0 into tCounter
		repeat for each key tKey in pWhere
			add  1 to tCounter
			put pWhere[tKey] into tVal

			if tDest is not an array then
				put empty into tPrefix
			else
				put " AND " into tPrefix
			end if

			if tVal is not empty then
				if _rigHasOperator(tKey) is FALSE then
					put " =" after tKey
				end if

				put " " & rigDbEscape(tVal) into tVal
			end if

			put tPrefix & tKey & tVal into tDest[tCounter]
		end repeat
	end if

	put _rigProtectIdentifiers(pTable, TRUE, NULL, FALSE) into tTable

	return _rigUpdate(tTable, tFields, tDest)
end rigDbUpdateString








/*----------------------------------------------------------------------
--| FUNCTION _rigHasOperator
--|
--| Author: rabit
--| Version:  1.2
--| Created: 25-09-09
--| Last Mod: 12-11-15
--| Requires: rigTrim()
--|
--| Summary: Tests whether the string has an SQL operator.
--|
--| Format:  _rigHasOperator(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

function _rigHasOperator pStr
  get matchtext(rigTrim(pStr), "(?i)(<|>|!|=|\sIS NULL|\sIS NOT NULL|\sEXISTS|\sBETWEEN|\sLIKE|\sIN\s*\(?)")

	return it
end _rigHasOperator





/*----------------------------------------------------------------------
--| COMMAND rigDbCacheSetPath
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-10-09
--| Last Mod: 01-10-09
--| Requires: --
--|
--| Summary: Set cache directory path.
--|
--| Format:  rigDbCacheSetPath param1
--|
--| Parameters: string <pPath> the path to the cache directory
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbCacheSetPath pPath
	put pPath into sDBdriverSettings["cachedir"]
end rigDbCacheSetPath







/*----------------------------------------------------------------------
--| FUNCTION rigDbCacheOn
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-10-09
--| Last Mod: 01-10-09
--| Requires: --
--|
--| Summary: Enable query caching.
--|
--| Format:  rigDbCacheOn()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigDbCacheOn
	put TRUE into sDBdriverSettings["cacheon"]

	return TRUE
end rigDbCacheOn








/*----------------------------------------------------------------------
--| FUNCTION rigDbCacheOff
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-07-09
--| Last Mod: 09-07-09
--| Requires: --
--|
--| Summary: Disable query caching.
--|
--| Format:  rigDbCacheOff()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigDbCacheOff
	put FALSE into sDBdriverSettings["cacheon"]
	return FALSE
end rigDbCacheOff









/*----------------------------------------------------------------------
--| COMMAND rigDbCacheDelete
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-10-09
--| Last Mod: 01-10-09
--| Requires: _rigCacheInit(), rigDeleteDBcacheFiles
--|
--| Summary: Delete the cache files associated with a particular URI.
--|
--| Format:  rigDbCacheDelete param1, param2
--|
--| Parameters: string <pSegmentOne>, string <pSegmentTwo>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbCacheDelete pSegmentOne pSegmentTwo
	if _rigCacheInit() is FALSE then
		return FALSE
	end if

	rigDeleteDBcacheFiles pSegmentOne, pSegmentTwo
end rigDbCacheDelete







/*----------------------------------------------------------------------
--| COMMAND rigDbCacheDeleteAll
--|
--| Author: rabit
--| Version:  1.1
--| Created: 01-10-09
--| Last Mod: 01-01-10
--| Requires: _rigCacheInit(), rigDeleteAllDBcacheFiles
--|
--| Summary: Delete all cache files.
--|
--| Format:  rigDbCacheDeleteAll param1
--|
--| Parameters: string <pExclusion> file name to exclude (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbCacheDeleteAll pExclusion
	if _rigCacheInit() is FALSE then
		return FALSE
	end if

	rigDeleteAllDBcacheFiles pExclusion
end rigDbCacheDeleteAll







/*----------------------------------------------------------------------
--| FUNCTION _rigCacheInit
--|
--| Author: rabit
--| Version:  1.1
--| Created: 09-07-09
--| Last Mod: 17-09-15
--| Requires: rigLogMessage, rigDbCacheOff()
--|
--| Summary: Initialize the cache library.
--|
--| Format:  _rigCacheInit()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigCacheInit
	if sCacheLibLoaded is TRUE then
		return TRUE
	else
		try
			start using stack (gRigA["BASEPATH"] & "database/DBcache.livecodescript")
		catch err
			rigLogMessage "error", "An error occured while trying to start using database library:" && "DBcache"
			return rigDbCacheOff()
		end try
	end if

	put TRUE into sCacheLibLoaded

	return TRUE
end _rigCacheInit




/*----------------------------------------------------------------------
--| FUNCTION _rigCloseDB
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-07-09
--| Last Mod: 22-07-09
--| Requires: _rigDbClose()
--|
--| Summary: This handler closes the database connection.
--|
--| Format:  _rigCloseDB()
--|
--| Parameters: --
--|
--| Return: mixed
----------------------------------------------------------------------*/

function _rigCloseDB
  local tResult

	if sDBdriverSettings["connid"] is an integer then
		put _rigDbClose(sDBdriverSettings["connid"]) into tResult
	end if
	put FALSE into sDBdriverSettings["connid"]
	put empty into gRigA["databaseID"]

	return tResult
end _rigCloseDB




/*----------------------------------------------------------------------
--| COMMAND rigDbDisplayError
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2009-07-06
--| Last Mod: 2018-12-17
--| Requires: rigLoadLibrary, rigLangLoadLang, rigLangLangLine(), rigShowErrorPage()
--|
--| Summary: Display an error message.
--|
--| Format:  rigDbDisplayError param1, param2, param3
--|
--| Parameters: string <pError> the error message, string <pSwap> any "swap" values,
--|               bool <pNative> whether to localize the message
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbDisplayError pError pSwap pNative
  local tResult, tMessage, tError, tHeading

	rigLoadLibrary "Language"
	get rigLangLoadLang("dbLang")

	put rigLangLangLine("db_error_heading") into tResult

	if pNative is TRUE then
		put pError into tMessage
	else
		if pError is not an array then
			put rigLangLangLine(pError) into tError
			replace "%s" with pSwap in tError
			put tError into tError[1]
			put tError into tMessage
		else
			put pError into tMessage
		end if
	end if

  put "Database Error" into tHeading

	rigLoadLibrary "Exceptions"
	put rigShowErrorPage(tHeading, tMessage, "errorDB")
	exit to top
end rigDbDisplayError







/*----------------------------------------------------------------------
--| COMMAND rigDbRedirectOnError
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-05-2013
--| Last Mod: 04-05-2013
--| Requires: rigLoadHelper, rigRedirect
--|
--| Summary: Redirect to an URI of your choice in case a database error occurs.
--|            Specify the controller/handler to redirect to in your database configuration.
--|
--| Format:  rigDbRedirectOnError
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbRedirectOnError
	rigLoadHelper "url"
	rigRedirect sDBdriverSettings["dbRedirectOnError"]
end rigDbRedirectOnError







/*----------------------------------------------------------------------
--| FUNCTION rigDbAffectedRows
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-07-09
--| Last Mod: 21-07-09
--| Requires: --
--|
--| Summary: The number of affected rows.
--|
--| Format:  rigDbAffectedRows()
--|
--| Parameters: --
--|
--| Return: integer or bool
----------------------------------------------------------------------*/

function rigDbAffectedRows
	return sDBdriverSettings["affectedrows"]
end rigDbAffectedRows








/*----------------------------------------------------------------------
--| FUNCTION rigProtectIdentifiers
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-10-09
--| Last Mod: 01-10-09
--| Requires: _rigProtectIdentifiers()
--|
--| Summary: This function adds backticks if appropriate based on DB type.
--|
--| Format:  rigProtectIdentifiers(param1, param2)
--|
--| Parameters: mixed <pItem> the item to escape, bool <pPrefixSingle>
--|
--| Return: mixed the item with backticks
----------------------------------------------------------------------*/

function rigProtectIdentifiers pItem pPrefixSingle
  local tPrefixSingle

	if pPrefixSingle is empty then
		put FALSE into tPrefixSingle
	else
		put pPrefixSingle into tPrefixSingle
	end if

	return _rigProtectIdentifiers(pItem, tPrefixSingle)
end rigProtectIdentifiers








/*----------------------------------------------------------------------
--| FUNCTION _rigProtectIdentifiers
--|
--| Author: rabit
--| Version:  1.2
--| Created: 07-07-09
--| Last Mod: 28-12-09
--| Requires: --
--|
--| Summary: This function is used extensively by the Active Record library, and by
--|             a couple handlers in this library.
--|             It takes a column or table name (optionally with an alias) and inserts
--|             the table prefix onto it.  Some logic is necessary in order to deal with
--|             column names that include the path.  Consider a query like this:
--|
--|             SELECT * FROM hostname.database.table.column AS c FROM hostname.database.table
--|
--|             Or a query with aliasing:
--|
--|             SELECT m.member_id, m.member_name FROM members AS m
--|
--|             Since the column name can include up to four segments (host, DB, table, column)
--|             or also have an alias prefix, we need to do a bit of work to figure this out and
--|             insert the table prefix (if it exists) in the proper position, and escape only
--|             the correct identifiers.
--|
--| Format:  _rigProtectIdentifiers(param1, param2, param3, param4)
--|
--| Parameters: mixed <pItem>, bool <pPrefixsingle>,  mixed <pProtectidentifiers>, bool <pFieldexists>
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigProtectIdentifiers pItem pPrefixsingle pProtectidentifiers pFieldexists
  local tItem, tProtectidentifiers, tKey, tEscapedKey, tEscapedVal, tEscapedArray
  local tRegEx, tAlias, tParts, tAliasedTables, tPartIsInArray, tReservedIdent
  local tEscapedPart, ti, tPrefixCharsNum

	put pItem into tItem
	put pProtectidentifiers into tProtectidentifiers
	if tProtectidentifiers is not a boolean then
		put sDBdriverSettings["protectIdentifiers"] into tProtectidentifiers
	end if

	if tItem is an array then
		repeat for each key tKey in tItem
			put _rigProtectIdentifiers(tKey) into tEscapedKey
			put _rigProtectIdentifiers(tItem[tKey]) into tEscapedVal
			put tEscapedVal into tEscapedArray[tEscapedKey]
		end repeat

		return tEscapedArray
	end if

	# CONVERT TABS OR MULTIPLE SPACES INTO SINGLE SPACES
	put "[\t ]+" into tRegEx
	put replacetext(tItem,tRegEx," ") into tItem

/*
 if "=" is in tItem then
if tProtectidentifiers is TRUE then
        split tItem using "="
        put the number of lines in the keys of tItem into tKeysNum

        put 0 into tCounter
        repeat for each key tKey in tItem
            add 1 to tCounter

            if tCounter is 1 then
			put _rigEscapeIdentifiers(tItem[tKey]) & "=" into tEscapedStr
            end if

            if (tCounter <> 1) and (tCounter < tKeysNum) then
                put word 1 to ((the number of words of tItem[tKey]) - 1) of tItem[tKey] after tEscapedStr
			put space & _rigEscapeIdentifiers(word -1 of tItem[tKey]) & "=" after tEscapedStr
            end if

            if tCounter = tKeysNum then
                put tItem[tKey] after tEscapedStr
            end if

        end repeat
return tEscapedStr
end if
else
return tItem
    end if
*/

	# IF THE ITEM HAS AN ALIAS DECLARATION WE REMOVE IT AND SET IT ASIDE.
	# BASICALLY WE REMOVE EVERYTHING TO THE RIGHT OF THE FIRST SPACE
	put "" into tAlias
	if space is in tItem then
		set the itemdelimiter to space
		put space & item 2 to (the number of items of tItem) of tItem into tAlias
		put item 1 of tItem into tItem
	end if

	# THIS IS BASICALLY A BUG FIX FOR QUERIES THAT USE MAX, MIN, ETC.
	# IF A PARENTHESIS IS FOUND WE KNOW THAT WE DO NOT NEED TO
	# ESCAPE THE DATA OR ADD A PREFIX.
	if "(" is in tItem then
		return tItem & tAlias
	end if

	# BREAK THE STRING APART IF IT CONTAINS PERIODS, THEN INSERT THE TABLE PREFIX
	# IN THE CORRECT LOCATION, ASSUMING THE PERIOD DOESN'T INDICATE THAT WE'RE DEALING
	# WITH AN ALIAS. WHILE WE'RE AT IT, WE WILL ESCAPE THE COMPONENTS
	if "." is in tItem then
		put tItem into tParts
		split tParts using "."

		# DOES THE FIRST SEGMENT OF THE EXPLODED ITEM MATCH
		# ONE OF THE ALIASES PREVIOUSLY IDENTIFIED?  IF SO,
		# WE HAVE NOTHING MORE TO DO OTHER THAN ESCAPE THE ITEM
		put rigFetchDBactiveRecSetting("aliasedtables") into tAliasedTables
		if tAliasedTables is an array then

			put FALSE into tPartIsInArray
			repeat for each element thisElement in tAliasedTables
				if thisElement is tParts[1] then
					put TRUE into tPartIsInArray
					exit repeat
				end if
			end repeat

    			if tPartIsInArray is TRUE then
				if tProtectidentifiers is TRUE then
					put sDBdriverSettings["reservedIdentifiers"] into tReservedIdent
					combine tReservedIdent using space

					 repeat for each key tKey in tParts

							if tParts[tKey] is not among the words of tReservedIdent then
								put _rigEscapeIdentifiers(tParts[tKey]) into tEscapedPart
								put tEscapedPart into tParts[tKey]
							end if

					end repeat

					combine tParts using "."
					put tParts into tItem
				end if

				return tItem & tAlias
			end if
		end if

		# IS THERE A TABLE PREFIX DEFINED IN THE CONFIG FILE?  IF NOT, NO NEED TO DO ANYTHING
		if sDBdriverSettings["dbprefix"] is not "" then
			# WE Now ADD THE TABLE PREFIX BASED ON SOME LOGIC.
			# DO WE HAVE 4 SEGMENTS (HOSTNAME.DATABASE.TABLE.COLUMN)?
			# IF SO, WE ADD THE TABLE PREFIX TO THE COLUMN NAME IN THE 3RD SEGMENT.
			if the number of lines in the keys of tParts = 4 then
				put 3 into ti
				# DO WE HAVE 3 SEGMENTS (DATABASE.TABLE.COLUMN)?
				# IF SO, WE ADD THE TABLE PREFIX TO THE COLUMN NAME IN 2ND POSITION
			else if the number of lines in the keys of tParts = 3 then
				put 2 into ti
				# DO WE HAVE 2 SEGMENTS (TABLE.COLUMN)?
				# IF SO, WE ADD THE TABLE PREFIX TO THE COLUMN NAME IN 1ST SEGMENT
			else
				put 1 into ti
			end if

			# THIS FLAG IS SET WHEN THE SUPPLIED $ITEM DOES NOT CONTAIN A FIELD NAME.
			# THIS CAN HAPPEN WHEN THIS FUNCTION IS BEING CALLED FROM A JOIN.
			if pFieldexists is FALSE then
				add 1 to ti
			end if

			# WE ONLY ADD THE TABLE PREFIX IF IT DOES NOT ALREADY EXIST
			put the number of chars of sDBdriverSettings["dbprefix"] into tPrefixCharsNum
			if char 1 to tPrefixCharsNum of tParts[ti] is not sDBdriverSettings["dbprefix"] then
				put sDBdriverSettings["dbprefix"] & tParts[ti] into tParts[ti]
			end if

			# PUT THE PARTS BACK TOGETHER
			combine tParts using "."
			put tParts into tItem

		end if

		if tProtectidentifiers is TRUE then
			put _rigEscapeIdentifiers(tItem) into tItem
		end if

		return tItem & tAlias
	end if

	# IS THERE A TABLE PREFIX?  IF NOT, NO NEED TO INSERT IT
	if sDBdriverSettings["dbprefix"] is not "" then
		# DO WE PREFIX AN ITEM WITH NO SEGMENTS?
		put the number of chars of sDBdriverSettings["dbprefix"] into tPrefixCharsNum
		if (pPrefixsingle is TRUE) and (char 1 to tPrefixCharsNum of tItem is not sDBdriverSettings["dbprefix"]) then
			put sDBdriverSettings["dbprefix"] & tItem into tItem
		end if
	end if

	put sDBdriverSettings["reservedIdentifiers"] into tReservedIdent
	combine tReservedIdent using space
	if (tProtectidentifiers is TRUE) and (tItem is not among the words of tReservedIdent) then
		put _rigEscapeIdentifiers(tItem) into tItem
	end if

	return tItem & tAlias
end _rigProtectIdentifiers





/*----------------------------------------------------------------------
--| FUNCTION rigDbEscapeString
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-07-09
--| Last Mod: 06-07-09
--| Requires:  --
--|
--| Summary: Escapes special characters in a string for use in a SQL statement.
--|
--| Format:  rigDbEscapeString(param1)
--|
--| Parameters: string <pString>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbEscapeString pString
  local tString

	put pString into tString
	replace "\" with "\\" in tString
	replace "NUL" with "\NUL" in tString
	replace "\n" with "\\n" in tString
	replace "\r" with "\\r" in tString
	replace quote with "\" & quote in tString

	return tString
end rigDbEscapeString






--| END OF DBdriver.livecodescript
--| Location:  ./system/database/DBdriver.livecodescript
----------------------------------------------------------------------
