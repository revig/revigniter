script "sessionDatabaseDriver"

##
# revIgniter
#
# An application development framework for LiveCode
# modeled on CodeIgniter.
#
# @package     revIgniter
# @author       rabit@revigniter.com
# @copyright    Copyright (c) 2009 - 2020, dimensionB Bitter u. Bitter GmbH
# @license      https://revigniter.com/userGuide/license.html
# @link          https://revigniter.com
##

## ------------------------------------------------------------------------

##
# revIgniter Session Database Driver
#
#
# @package		  revIgniter
# @subpackage	Libraries
# @category		  Sessions
# @author			  rabit@revigniter.com
# @link				  https://revigniter.com/userGuide/libraries/sessions.html
##




global gRigA, gSessionA




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-13
 --| Last Mod: --
 --| Requires: _rigInitializeSessDatabaseDriver
 --|
 --| Summary:  Run security check and initial routines.
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
    # CALL INITIAL HANDLERS
    _rigInitializeSessDatabaseDriver    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack






/*----------------------------------------------------------------------
--| COMMAND _rigInitializeSessDatabaseDriver
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-08-2015
--| Last Mod: 21-08-2015
--| Requires: rigLoadDatabase()
--|
--| Summary: Initialize session database driver.
--| 
--| Format:  _rigInitializeSessDatabaseDriver 
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigInitializeSessDatabaseDriver
	# LOAD THE DATABASE
  if gSessionA["sess_save_location"] is empty then
    # USE DEFAULT TABLE NAME
    put "ri_sessions" into gSessionA["sess_save_location"]
	end if
  
  get rigLoadDatabase()
end _rigInitializeSessDatabaseDriver





/*----------------------------------------------------------------------
--| FUNCTION rigGetSessData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-08-2015
--| Last Mod: 22-08-2015
--| Requires: rigDbWhere, rigSessDestroy, rigDbRow(), _rigUnserializeSess()
--|
--| Summary: Get custom session data from database.
--| 
--| Format:  rigGetSessData(param1, param2, param3, param4)
--|
--| Parameters: string <pSessID>, string <pSessIP>, string <pSessUserAgent>, array <pSessionA> default session data
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigGetSessData pSessID pSessIP pSessUserAgent pSessionA
  local tQuery, tRow, tCustomData, tKey, tVal
  
	rigDbWhere "session_id", pSessID

	if gSessionA["sess_match_ip"] is TRUE then
		rigDbWhere "ip_address", pSessIP
	end if

	if gSessionA["sess_match_useragent"] is TRUE then
		rigDbWhere "user_agent", pSessUserAgent
	end if
	
	put rigDbGet(gSessionA["sess_save_location"]) into tQuery
	# NO RESULT?  KILL IT!
	if tQuery["numrows"] = 0 then
		rigSessDestroy
		return FALSE
	end if

	# IS THERE CUSTOM DATA?  IF SO, ADD IT TO THE MAIN SESSION ARRAY
	put rigDbRow() into tRow
	if tRow["user_data"] is not empty then
    put base64Decode(urlDecode(tRow["user_data"])) into tCustomData
		put _rigUnserializeSess(tCustomData) into tCustomData
		if tCustomData is an array then
			repeat for each key tKey in tCustomData
				put tCustomData[tKey] into tVal

				put tVal into pSessionA[tKey]
			end repeat
		end if
	end if
  
  return pSessionA
end rigGetSessData






/*----------------------------------------------------------------------
--| COMMAND rigUpdateSessData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-08-2015
--| Last Mod: 22-08-2015
--| Requires: rigDbWhere, rigDbUpdate()
--|
--| Summary: Update custom session data.
--| 
--| Format:  rigUpdateSessData param1
--|
--| Parameters: string <pUserData>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigUpdateSessData pUserData
  local tArray
  
	# RUN THE UPDATE QUERY
	rigDbWhere "session_id", gSessionA["userdata"]["session_id"]
	put gSessionA["userdata"]["last_activity"] into tArray["last_activity"]
	put pUserData into tArray["user_data"]

	get rigDbUpdate(gSessionA["sess_save_location"], tArray)
end rigUpdateSessData






/*----------------------------------------------------------------------
--| COMMAND rigCreateSessData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-08-2015
--| Last Mod: 22-08-2015
--| Requires: rigDbInsertString(), rigDbQuery()
--|
--| Summary: Create custom session data.
--| 
--| Format:  rigCreateSessData 
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigCreateSessData
  local tSQL
  
	put rigDbInsertString(gSessionA["sess_save_location"], gSessionA["userdata"]) into tSQL
	get rigDbQuery(tSQL)
end rigCreateSessData






/*----------------------------------------------------------------------
--| COMMAND rigUpdateCurrentSess
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-08-2015
--| Last Mod: 22-08-2015
--| Requires: rigDbUpdateString(), rigDbQuery()
--|
--| Summary: Update an existing session.
--| 
--| Format:  rigUpdateCurrentSess param1, param2
--|
--| Parameters: string <pOldSessID>, string <pNewSessID>
--|
--| Return: array
----------------------------------------------------------------------*/

command rigUpdateCurrentSess pOldSessID pNewSessID
  local tKeys, tCookieData, tUpdateArray, tWhereArray, tSQL
  
	# SET COOKIE EXPLICITLY TO ONLY HAVE OUR SESSION DATA
	put "session_id,ip_address,user_agent,last_activity" into tKeys
	repeat for each item tKey in tKeys
		put gSessionA["userdata"][tKey] into tCookieData[tKey]
	end repeat

	put gSessionA["now"] into tUpdateArray["last_activity"]
	put pNewSessID into tUpdateArray["session_id"]

	put pOldSessID into tWhereArray["session_id"]

	put rigDbUpdateString(gSessionA["sess_save_location"], tUpdateArray, tWhereArray) into tSQL
	if tSQL is not FALSE then
		get rigDbQuery(tSQL)
	end if
  
  return tCookieData
end rigUpdateCurrentSess







/*----------------------------------------------------------------------
--| COMMAND rigDestroySessData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-08-2015
--| Last Mod: 22-08-2015
--| Requires: rigDbWhere, rigDbDelete()
--|
--| Summary: Destroy current session data.
--| 
--| Format:  rigDestroySessData 
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDestroySessData
	rigDbWhere "session_id", gSessionA["userdata"]["session_id"]
	get rigDbDelete(gSessionA["sess_save_location"])
end rigDestroySessData






/*----------------------------------------------------------------------
--| COMMAND _rigGCexpiredSess
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-08-2015
--| Last Mod: 22-08-2015
--| Requires: rigDbWhere, rigDbDelete(), rigLogMessage
--|
--| Summary: This deletes expired session rows from database
--|            if the probability percentage is met.
--| 
--| Format:  _rigGCexpiredSess 
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigGCexpiredSess
  local tRand, tUpperLimit, tExpire, tWhere
  
  put empty into tRand
  repeat while (the length of tRand) < 8
    put 2147483647 into tUpperLimit
    put random(tUpperLimit) after tRand
  end repeat

  put (tRand mod 100) into tRand
	
  if tRand < gSessionA["gc_probability"] then
    put gSessionA["now"] - gSessionA["sess_expiration"] into tExpire
    put "last_activity < " & tExpire into tWhere
    rigDbWhere tWhere
    get rigDbDelete(gSessionA["sess_save_location"])

    rigLogMessage "debug", "Session garbage collection performed."
  end if
end _rigGCexpiredSess










--| END OF sessionDatabaseDriver.livecodescript
--| Location:  ./system/libraries/sessionDrivers/sessionDatabaseDriver.livecodescript
----------------------------------------------------------------------