script "DB"

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
# @link		    https://revigniter.com/
##

## ------------------------------------------------------------------------

##
# Initialize the database
#
#
# @package		revIgniter
# @subpackage	Database
# @category	  Database
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/database/
##




global gRigA

local sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-14
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
--| FUNCTION rigDB
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2009-07-04
--| Last Mod: 2015-09-17
--| Requires: rigFetchDBsettingsAll(), rigShowError, rigFetchActiveGroup(), _rigParseURL,
--| 					_rigParseQueryStr, rigDbDriver, rigFetchDBdriverSetting(), rigDbInitialize()
--|
--| Summary: Initialize the database.
--| 
--| Format:  rigDB(param1, param2)
--|
--| Parameters: string <pParams> the DB credentials, bool <pActiveRecordOverride> whether to enable
--|                       active record (this allows us to override the config setting).
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDB pParams pActiveRecordOverride
  local tDBsettings, tActiveGroup, tParams, tDSN, tPath, tPathToDecode, tPathDecoded
  local tExtra

	# LOAD THE DB CONFIG FILE IF A DSN STRING WASN'T PASSED
	if (pParams is not a boolean) and (pParams is not a number) and (pParams is not an array) and (offset("://", pParams) = 0) then
		_rigRequire (gRigA["APPPATH"] & "config/database" & gRigA["EXT"])

		put rigFetchDBsettingsAll() into tDBsettings

		if tDBsettings is not an array then
			rigShowError "No database connection settings were found in the database config file."
		end if

		if pParams <> "" then
			put pParams into tActiveGroup
		else
			put rigFetchActiveGroup() into tActiveGroup
		end if
	
		if tDBsettings[tActiveGroup] is not an array then
			rigShowError "You have specified an invalid database connection group."
		end if

		put tDBsettings[tActiveGroup] into tParams

	else if (pParams is not a boolean) and (pParams is not a number) and (pParams is not an array) then
		## 
		# PARSE THE URL FROM THE DSN STRING
		#  DATABASE SETTINGS CAN BE PASSED AS DISCREET
	 	#  PARAMETERS OR AS A DATA SOURCE NAME IN THE FIRST
	 	#  PARAMETER. DSNs MUST HAVE THIS PROTOTYPE:
	 	#  PUT "DRIVER://USERNAME:PASSWORD@HOSTNAME/DATABASE" INTO DSN
		##
		put _rigParseURL(pParams) into tDSN
		if tDSN is not an array then
			rigShowError "Invalid DB Connection String"
		end if

		put tDSN["scheme"] into tDSN["dbdriver"]
		put URLDecode(tDSN["host"]) into tDSN["host"]
		put URLDecode(tDSN["user"]) into tDSN["user"]
		put URLDecode(tDSN["pass"]) into tDSN["pass"]
		
		put tDSN["path"] into tPath
		put char 2 to -1 of tPath into tPathToDecode
		put URLDecode(tPathToDecode) into tPathDecoded
		put tPathDecoded into tDSN["path"]
		
		put tDSN["scheme"] into tParams["dbdriver"]
		put tDSN["host"] into tParams["hostname"]
		put tDSN["user"] into tParams["username"]
		put tDSN["pass"] into tParams["password"]
		put tDSN["path"] into tParams["database"]

		# WERE ADDITIONAL CONFIG ITEMS SET?
		if tDSN["query"] is not "" then
			put _rigParseQueryStr(tDSN["query"]) into tExtra
			
			 repeat for each key tKey in tExtra
				# BOOLEANS PLEASE
				if toUpper(tExtra[tKey]) is "TRUE" then
					put TRUE into tExtra[tKey]
				end if
				if toUpper(tExtra[tKey]) is "FALSE" then
					put FALSE into tExtra[tKey]
				end if

				put tExtra[tKey] into tParams[tKey]
			end repeat
		end if

	end if
	
  if tParams is empty then
    put pParams into tParams
  end if

	# NO DB SPECIFIED YET?  BEAT THEM SENSELESS...
	if tParams["dbdriver"] is "" then
		rigShowError "You have not selected a database type to connect to."
	end if

	# LOAD THE DB LIBRARIES.  NOTE: SINCE THE ACTIVE RECORD LIBRARY IS OPTIONAL
	# WE NEED TO DYNAMICALLY LOAD THE PROPER LIBRARIES
	# BASED ON WHETHER WE'RE USING THE ACTIVE RECORD LIBRARY OR NOT.
	IF pActiveRecordOverride is TRUE then
		put TRUE into gRigA["activeRecord"]
	end if
  if gRigA["activeRecord"] is empty then
    put TRUE into gRigA["activeRecord"]
  end if

	# LOAD DATABASE DRIVER LIBRARY
  start using stack (gRigA["BASEPATH"] & "database/DBdriver.livecodescript")

	# SET THE DATABASE DRIVER LIBRARY VARIABLES VALUES
	rigDbDriver tParams

	if gRigA["activeRecord"] is TRUE then
    start using stack (gRigA["BASEPATH"] & "database/DBactiveRec.livecodescript")
	end if

  start using stack (gRigA["BASEPATH"] & "database/drivers/" & tParams["dbdriver"] & "/" & tParams["dbdriver"] & "Driver.livecodescript")
	
	if rigFetchDBdriverSetting("autoinit") is TRUE then
		get rigDbInitialize()
	end if

	return gRigA["databaseID"]
end rigDB






--| END OF DB.livecodescript
--| Location:  ./system/database/DB.livecodescript
----------------------------------------------------------------------