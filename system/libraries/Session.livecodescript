script "Session"

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
# revIgniter Session Library
#
#
# @package		revIgniter
# @subpackage	Libraries
# @category		Sessions
# @author			rabit@revigniter.com
# @link				https://revigniter.com/userGuide/libraries/uri.html
##




global gRigA, gSessionA

local sStackInUse, sSessionA -- array keys are: encryption_key, sess_hash_type, cookie_secure, sess_encrypt_cookie





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-13
 --| Last Mod: --
 --| Requires: rigLogMessage, _rigSetDefaultValues
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

      # LOGGING
      if the environment is "server" then
        rigLogMessage "debug", "Session Library Loaded"
      end if
      
      # SET INITIAL VALUES
      _rigSetDefaultValues
      #
    end if -- if sStackInUse <> TRUE
    
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
  put "" into gSessionA["sess_driver"]
  put "" into gSessionA["sess_save_location"]
  put 28800 into gSessionA["sess_expiration"]
  put FALSE into gSessionA["sess_expire_on_close"]
  put FALSE into gSessionA["sess_match_ip"]
  put TRUE into gSessionA["sess_match_useragent"]
  put "ri_session" into gSessionA["sess_cookie_name"]
  put "" into gSessionA["cookie_prefix"]
  put "" into gSessionA["cookie_path"]
  put "" into gSessionA["cookie_domain"]
  put 300 into gSessionA["sess_time_to_update"]
  put "flash" into gSessionA["flashdata_key"]
  put "temp" into gSessionA["tempdata_key"]
  put 5 into gSessionA["gc_probability"]
  put "" into gSessionA["userdata"]
  
  put FALSE into sSessionA["sess_encrypt_cookie"]
  put FALSE into sSessionA["cookie_secure"]
  put "" into sSessionA["sess_hash_type"]
  put "" into sSessionA["encryption_key"]
end _rigSetDefaultValues





/*----------------------------------------------------------------------
--| COMMAND rigRunInitialSessionConfig
--|
--| Author: rabit
--| Version:  1.6
--| Created: 2009-10-12
--| Last Mod: 2017-06-27
--| Requires: rigFetchConfigItem(), rigLoadHelper, rigLoaderLoadLibrary, rigUcwords(),
--|            _rigGetTime(), _rigFlashdataSweep, _rigFlashdataMark, _rigSessGC, rigLogMessage
--|
--| Summary: The session routines are run automatically
--|                    whenever the library is loaded.
--| 
--| Format:  rigRunInitialSessionConfig param1
--|
--| Parameters: array <pParams>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialSessionConfig pParams
  local tSettingNames, tSessDriver
  
	if pParams is not an array then
		if pParams is not empty then
			split pParams using numToCodepoint(1) and numToCodepoint(2)
		end if
	end if

	# SET ALL THE SESSION PREFERENCES, WHICH CAN EITHER BE SET
	# MANUALLY VIA THE pParams ARRAY ABOVE OR VIA THE CONFIG FILE
	put "sess_encrypt_cookie,sess_driver,sess_save_location,sess_expiration,sess_expire_on_close,sess_match_ip,sess_match_useragent,sess_cookie_name,cookie_path,cookie_domain,cookie_secure,sess_time_to_update,cookie_prefix,encryption_key,sess_hash_type" into tSettingNames
	
	repeat for each item thisItem in tSettingNames
		if pParams is an array then
			if (pParams[thisItem] is not an array) and (pParams[thisItem] is empty) then
				# pParams[thisItem] IS EMPTY
				put rigFetchConfigItem(thisItem) into gSessionA[thisItem]
    		else
				put pParams[thisItem] into gSessionA[thisItem]
    		end if
		else
			put rigFetchConfigItem(thisItem) into gSessionA[thisItem]
		end if
	end repeat

	# LOAD THE STRING HELPER SO WE CAN USE THE rigStrip_slashes() FUNCTION
	rigLoadHelper "string"

	# DO WE NEED ENCRYPTION? IF SO, LOAD THE ENCRYPTION LIBRARY
	if sSessionA["sess_encrypt_cookie"] is TRUE then
		rigLoaderLoadLibrary "Encrypt"
	end if
  
  # LOAD DRIVER
  if gSessionA["sess_driver"] <> empty then
    put rigUcwords(gSessionA["sess_driver"]) into tSessDriver
    if tSessDriver is not among the items of "Files,Database" then
      rigLogMessage "error", "Failed to load session driver. Invalid setting for sess_driver."
      put empty into gSessionA["sess_driver"]
    else
      start using stack (gRigA["BASEPATH"] & "libraries/sessionDrivers/session" & tSessDriver & "Driver.livecodescript")
    end if
  end if

	# SET THE "NOW" TIME.  CAN EITHER BE GMT OR SERVER TIME, BASED ON THE
	# CONFIG PREFS.  WE USE THIS TO SET THE "LAST ACTIVITY" TIME
	put _rigGetTime() into gSessionA["now"]

	# SET THE SESSION LENGTH. IF THE SESSION EXPIRATION IS
	# SET TO ZERO WE'LL SET THE EXPIRATION TWO YEARS FROM NOW
	if gSessionA["sess_expiration"] = 0 then
		put (60*60*24*365*2) into gSessionA["sess_expiration"]
	end if

	# SET THE COOKIE NAME
	put gSessionA["cookie_prefix"] & gSessionA["sess_cookie_name"] into gSessionA["sess_cookie_name"]

	# RUN THE SESSION ROUTINE. IF A SESSION DOESN'T EXIST WE'LL
	# CREATE A NEW ONE.  IF IT DOES, WE'LL UPDATE IT
	if rigSessRead() is FALSE then
		rigSessCreate
	else
		rigSessUpdate
	end if

	# DELETE 'OLD' FLASHDATA (FROM LAST REQUEST)
	_rigFlashdataSweep

	# MARK ALL NEW FLASHDATA AS OLD (DATA WILL BE DELETED BEFORE NEXT REQUEST)
	_rigFlashdataMark
  
	# DELETE EXPIRED TEMPDATA
	_rigTempdataSweep
	
	# DELETE EXPIRED SESSIONS IF NECESSARY
	_rigSessGC

	rigLogMessage "debug", "Session routines successfully run."
end rigRunInitialSessionConfig







/*----------------------------------------------------------------------
--| FUNCTION rigSessRead
--|
--| Author: rabit
--| Version:  1.5
--| Created: 2009-10-12
--| Last Mod: 2019-01-06
--| Requires: rigVarCookie(), rigLogMessage, rigSetHash, rigDecode(), rigSessDestroy, _rigUnserializeSess(),
--|            rigIpAddress(), rigTrim(), rigGetSessData()
--|
--| Summary: Fetch the current session data if it exists.
--| 
--| Format:  rigSessRead()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigSessRead
  local tSession, tHash, tTempStr, tIPaddress, tSessIP, tUserAgent

	# FETCH THE COOKIE
	put rigVarCookie(gSessionA["sess_cookie_name"]) into tSession
 
	# NO COOKIE?  GOODBYE CRUEL WORLD!...
	if tSession is FALSE then
		rigLogMessage "debug", "A session cookie was not found."
		return FALSE
	end if

	# DECRYPT THE COOKIE DATA
	if sSessionA["sess_encrypt_cookie"] is TRUE then
    put base64Decode(urlDecode(tSession)) into tSession
		rigSetHash sSessionA["sess_hash_type"]
	  put rigDecode(tSession) into tSession
	else
    # ENCRYPTION WAS NOT USED, SO WE NEED TO CHECK THE 
    # SHA3-256 DIGEST OF THE rigHexDigest HASH FUNCTION
    # (Md5 DIGEST IF LC SERVER VERSION < 9 IS USED)
    put base64Decode(urlDecode(tSession)) into tSession
    set the itemDel to "."
    if (item 1 of the version < 9) or (gRigA["useLegacyCode"] is TRUE) then
      put char -32 to -1 of tSession into tHash -- get last 32 chars
      put char 1 to -33 of tSession into tSession
    else
      put char -64 to -1 of tSession into tHash -- get last 64 chars
      put char 1 to -65 of tSession into tSession
    end if

    # DOES THE SHA3-256 DIGEST OF THE rigHexDigest HASH FUNCTION
    # (Md5 DIGEST IF LC SERVER VERSION < 9 IS USED) MATCH?
    # THIS IS TO PREVENT MANIPULATION OF SESSION DATA IN USERSPACE
		put tSession & sSessionA["encryption_key"] into tTempStr
		if tHash <> rigHexDigest(tTempStr) then
			rigLogMessage "error", "The session cookie data did not match what was expected. This could be a possible hacking attempt."
			rigSessDestroy
			return FALSE
		end if
	end if

	# UNSERIALIZE THE SESSION ARRAY
	put _rigUnserializeSess(tSession) into tSession

	# IS THE SESSION DATA WE UNSERIALIZED AN ARRAY WITH THE CORRECT FORMAT?
	if (tSession is not an array) or (tSession["session_id"] is empty) or (tSession["ip_address"] is empty) or (tSession["user_agent"] is empty) \
	or (tSession["last_activity"] is empty) then
		rigSessDestroy
		return FALSE
	end if

	# IS THE SESSION CURRENT?
	if (tSession["last_activity"] + gSessionA["sess_expiration"]) < gSessionA["now"] then
		rigSessDestroy
		return FALSE
	end if

	# DOES THE IP MATCH?
	put rigIpAddress() into tIPaddress 
	put tSession["ip_address"] into tSessIP
  replace "___" with "." in tSessIP -- we replaced the dots with three underscores because otherwise, depending on the combination of numbers, arrayDecode of an urlDecoded ip address does not work (seems to be a LiveCode bug)
	if (gSessionA["sess_match_ip"] is TRUE) and (tSessIP <> tIPaddress) then
		rigSessDestroy
		return FALSE
	end if

	# DOES THE USER AGENT MATCH?
	put rigUserAgent() into tUserAgent
	put char 1 to 50 of tUserAgent into tUserAgent
	put rigTrim(tUserAgent) into tUserAgent
	put rigTrim(tSession["user_agent"]) into tSession["user_agent"]
	if (gSessionA["sess_match_useragent"] is TRUE) and (tSession["user_agent"] <> tUserAgent) then
		rigSessDestroy
		return FALSE
	end if

	# IS THERE A CORRESPONDING SESSION IN THE SAVE LOCATION?
	if gSessionA["sess_driver"] <> empty then
  	put rigGetSessData(tSession["session_id"], tSession["ip_address"], tSession["user_agent"], tSession) into tSession
  	if tSession is FALSE then
    		return FALSE
  	end if
	end if

	# SESSION IS VALID!
	put tSession into gSessionA["userdata"]
	delete variable tSession

	return TRUE
end rigSessRead









/*----------------------------------------------------------------------
--| COMMAND rigSessWrite
--|
--| Author: rabit
--| Version:  1.2
--| Created: 12-10-09
--| Last Mod: 30-09-15
--| Requires: _rigSetCookie, _rigSerializeSess(), rigUpdateSessData
--|
--| Summary: Write the session data.
--| 
--| Format:  rigSessWrite
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSessWrite
  local tCustomUserdata, tCookieUserdata, tKeys
  
	# ARE WE SAVING CUSTOM DATA TO A FILE OR DB?  IF NOT, ALL WE DO IS UPDATE THE COOKIE
  if gSessionA["sess_driver"] is empty then
		_rigSetCookie
		exit rigSessWrite
	end if

	# SET THE CUSTOM USERDATA, THE SESSION DATA WE WILL SET IN A SECOND
	put gSessionA["userdata"] into tCustomUserdata
	put "" into tCookieUserdata

	# BEFORE CONTINUING, WE NEED TO DETERMINE IF THERE IS ANY CUSTOM DATA TO DEAL WITH.
	# LET'S DETERMINE THIS BY REMOVING THE DEFAULT INDEXES TO SEE IF THERE'S ANYTHING LEFT IN THE ARRAY
	# AND SET THE SESSION DATA WHILE WE'RE AT IT
	put "session_id,ip_address,user_agent,last_activity" into tKeys
	repeat for each item thisItem in tKeys
		delete variable tCustomUserdata[thisItem]
		put gSessionA["userdata"][thisItem] into tCookieUserdata[thisItem]
	end repeat

	# DID WE FIND ANY CUSTOM DATA?  IF NOT, WE TURN THE EMPTY ARRAY INTO A STRING
	# SINCE THERE'S NO REASON TO SERIALIZE AND STORE AN EMPTY ARRAY IN THE DB
	if the number of lines in the keys of tCustomUserdata = 0 then
	else
		# SERIALIZE THE CUSTOM DATA ARRAY SO WE CAN STORE IT
	  put _rigSerializeSess(tCustomUserdata) into tCustomUserdata
    put urlEncode(base64Encode(tCustomUserdata)) into tCustomUserdata
	end if
  
	# RUN THE UPDATE HANDLER
  rigUpdateSessData tCustomUserdata

	# WRITE THE COOKIE.  NOTICE THAT WE MANUALLY PASS THE COOKIE DATA ARRAY TO THE
	# _rigSetCookie COMMAND. NORMALLY THAT COMMAND WILL STORE gSessionA["userdata"], BUT
	# IN THIS CASE THAT ARRAY CONTAINS CUSTOM DATA, WHICH WE DO NOT WANT IN THE COOKIE
	_rigSetCookie tCookieUserdata
end rigSessWrite








/*----------------------------------------------------------------------
--| COMMAND rigSessCreate
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2009-10-14
--| Last Mod: 2019-01-06
--| Requires: rigRandomNum(), rigIpAddress(), rigHexDigest(), rigUserAgent(), rigCreateSessData, _rigSetCookie
--|
--| Summary: Create a new session.
--| 
--| Format:  rigSessCreate
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSessCreate
  local tSessID, tIPaddress, tUUID, tUserAgent

	put rigRandomNum() into tSessID
 
	# TO MAKE THE SESSION ID EVEN MORE SECURE WE'LL COMBINE IT WITH THE USER'S IP
	put rigIpAddress() into tIPaddress
	replace "." with "___" in tIPaddress -- we replace the dots with three underscores because otherwise, depending on the combination of numbers, arrayDecode of an urlDecoded ip address does not work (seems to be a LiveCode bug)
	put tSessID & tIPaddress into tSessID

	# TURN SESSION ID INTO A HASH
  put uuid() into tUUID
  put tSessID & tUUID into tSessID
  put rigHexDigest(tSessID) into tSessID

	put tSessID into gSessionA["userdata"]["session_id"]
	put tIPaddress into gSessionA["userdata"]["ip_address"]
	
	put rigUserAgent() into tUserAgent
	put char 1 to 50 of tUserAgent into tUserAgent

	put tUserAgent into gSessionA["userdata"]["user_agent"]
	put gSessionA["now"] into gSessionA["userdata"]["last_activity"]

	# SAVE THE DATA TO A FILE OR DB IF NEEDED
  if gSessionA["sess_driver"] <> empty then
    rigCreateSessData
  end if

	# WRITE THE COOKIE
	_rigSetCookie
end rigSessCreate








/*----------------------------------------------------------------------
--| COMMAND rigSessUpdate
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2009-10-14
--| Last Mod: 2019-01-06
--| Requires: rigRandomNum(), rigIpAddress(), rigHexDigest(), rigUpdateCurrentSess, _rigSetCookie
--|
--| Summary: Update an existing session.
--| 
--| Format:  rigSessUpdate
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSessUpdate
  local tOldSessID, tNewSessID, tIPaddress, tUUID, tCookieData
  
	# WE ONLY UPDATE THE SESSION EVERY FIVE MINUTES BY DEFAULT
	if (gSessionA["userdata"]["last_activity"] + gSessionA["sess_time_to_update"]) >= gSessionA["now"] then
		exit rigSessUpdate
	end if

	# SAVE THE OLD SESSION ID SO WE KNOW WHICH
	# DATABASE RECORD / FILE TO UPDATE IF WE NEED IT
	put gSessionA["userdata"]["session_id"] into tOldSessID

	put rigRandomNum() into tNewSessID
	
	# TO MAKE THE SESSION ID EVEN MORE SECURE WE'LL COMBINE IT WITH THE USER'S IP
	put rigIpAddress() into tIPaddress
	replace "." with "___" in tIPaddress -- we replace the dots with three underscores because otherwise, depending on the combination of numbers, arrayDecode of an urlDecoded ip address does not work (seems to be a LiveCode bug)
	put tNewSessID & tIPaddress into tNewSessID

	# TURN NEW SESSION ID INTO A HASH
  put uuid() into tUUID
		
	put tNewSessID & tUUID into tNewSessID
	put rigHexDigest(tNewSessID) into tNewSessID

	# UPDATE THE SESSION DATA IN THE SESSION DATA ARRAY
	put tNewSessID into gSessionA["userdata"]["session_id"]
	put gSessionA["now"] into gSessionA["userdata"]["last_activity"]

	# _rigSetCookie WILL HANDLE THIS FOR US IF WE AREN'T USING FILE OR DATABASE SESSIONS
	# BY PUSHING ALL USERDATA TO THE COOKIE.
	put empty into tCookieData

	# UPDATE THE SESSION ID AND LAST_ACTIVITY IN FILE OR DB IF NEEDED  
  if gSessionA["sess_driver"] <> empty then
    rigUpdateCurrentSess tOldSessID, tNewSessID
    put the result into tCookieData
  end if

	# WRITE THE COOKIE
	_rigSetCookie tCookieData
end rigSessUpdate








/*----------------------------------------------------------------------
--| COMMAND rigSessDestroy
--|
--| Author: rabit
--| Version:  1.4
--| Created: 14-10-09
--| Last Mod: 30-09-15
--| Requires: rigDestroySessData, _rigInputSetCookie
--|
--| Summary: Destroy the current session.
--| 
--| Format:  rigSessDestroy
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSessDestroy
  local tExp, tArrayData
  
	# KILL THE SESSION FILE OR DB ROW
  if (gSessionA["sess_driver"] <> empty) and (gSessionA["userdata"]["session_id"] is not empty) then  
    rigDestroySessData
	end if
	
	# CLEAR userdata
	put empty into gSessionA["userdata"]

	# KILL THE COOKIE
	--put gSessionA["now"] - 31500000 into tExp
	put - 31500000 into tExp
	put "" into tArrayData[1]
	put arrayEncode(tArrayData) into tArrayData
 
	_rigInputSetCookie gSessionA["sess_cookie_name"], tArrayData, tExp, gSessionA["cookie_domain"], gSessionA["cookie_path"], "", TRUE, sSessionA["cookie_secure"]
end rigSessDestroy








/*----------------------------------------------------------------------
--| FUNCTION rigSessUserdata
--|
--| Author: rabit
--| Version:  1.2
--| Created: 14-10-09
--| Last Mod: 30-09-15
--| Requires: --
--|
--| Summary: Fetch a specific item from the session array.
--| 
--| Format:  rigSessUserdata(param1)
--|
--| Parameters: string <pItem>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigSessUserdata pItem
	if pItem is among the keys of gSessionA["userdata"] then
		return gSessionA["userdata"][pItem]
	end if

	return FALSE
end rigSessUserdata








/*----------------------------------------------------------------------
--| FUNCTION rigSessAllUserdata
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-10-09
--| Last Mod: 14-10-09
--| Requires: --
--|
--| Summary: Fetch all session data.
--| 
--| Format:  rigSessAllUserdata()
--|
--| Parameters: --
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigSessAllUserdata
	if gSessionA["userdata"] is an array then
		return gSessionA["userdata"]
	end if

	return FALSE
end rigSessAllUserdata








/*----------------------------------------------------------------------
--| COMMAND rigSetSessUserdata
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-10-09
--| Last Mod: 14-10-09
--| Requires: rigSessWrite
--|
--| Summary: Add or change data in the "userdata" array.
--| 
--| Format:  rigSetSessUserdata param1, param2
--|
--| Parameters: mixed <pNewData>, string <pNewVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetSessUserdata pNewData pNewVal
  local tArray, tNewData, tKey, tVal
  
	if pNewData is not an array then
		put pNewVal into tArray[pNewData]
		put tArray into tNewData
	else
		put pNewData into tNewData
	end if

	repeat for each key tKey in tNewData
		put tNewData[tKey] into tVal

		put tVal into gSessionA["userdata"][tKey]
	end repeat

	rigSessWrite
end rigSetSessUserdata








/*----------------------------------------------------------------------
--| COMMAND rigUnsetSessUserdata
--|
--| Author: rabit
--| Version:  1.2
--| Created: 14-10-09
--| Last Mod: 30-09-15
--| Requires: rigSessAllUserdata(), rigSessWrite
--|
--| Summary: Delete a session variable from the "userdata" array.
--| 
--| Format:  rigUnsetSessUserdata param1
--|
--| Parameters: mixed <pKey>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigUnsetSessUserdata pKey
  local tUserData, tUserdataKeys, tRegEx, tTempDataArrayKey, tUnsetA
  local tTempdataA, tTempDataArrayKeys, tTempDataKeyFragment
  
  put rigSessAllUserdata() into tUserData
  put the keys of tUserData into tUserdataKeys
  
  if tUserData <> FALSE then
	  if pKey is not an array then
      # CHECK IF IT IS TEMP DATA
      put "^" & gSessionA["tempdata_key"] & ":\d+:" & pKey & "$" into tRegEx
      filter tUserdataKeys matching regex pattern tRegEx into tTempDataArrayKey
      if tTempDataArrayKey <> empty then
        put "" into tUnsetA[tTempDataArrayKey]
      else
		    put "" into tUnsetA[pKey]
      end if
      
	  else -- if pKey is not an array then
      put pKey into tUnsetA
      
      # GET ALL TEMP DATA ITEMS
      set the itemDel to ":"
      put empty into tTempdataA
      put "^" & gSessionA["tempdata_key"] & ":\d+:.+$" into tRegEx
      filter tUserdataKeys matching regex pattern tRegEx into tTempDataArrayKeys
      
      repeat for each line tLine in tTempDataArrayKeys
        put item 3 of tLine into tTempDataKeyFragment
        if tTempDataKeyFragment is among the keys of tUnsetA then
          delete variable tUnsetA[tTempDataKeyFragment]
          put "" into tUnsetA[tLine]
        end if
      end repeat

	  end if -- if pKey is not an array then

	  repeat for each key tKey in tUnsetA
		  delete variable gSessionA["userdata"][tKey]
	  end repeat

	  rigSessWrite
  end if -- if tUserData <> FALSE then
end rigUnsetSessUserdata








/*----------------------------------------------------------------------
--| COMMAND rigSetSessFlashdata
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-10-09
--| Last Mod: 14-10-09
--| Requires: rigSetSessUserdata
--|
--| Summary: Add or change flashdata, only available until the next request.
--| 
--| Format:  rigSetSessFlashdata param1, param2
--|
--| Parameters: mixed <pNewData>, string <pNewVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetSessFlashdata pNewData pNewVal
  local tArray, tNewData, tFlashdataKey, tVal
  
	if pNewData is not an array then
		put pNewVal into tArray[pNewData]
		put tArray into tNewData
	else
		put pNewData into tNewData
	end if

	repeat for each key tKey in tNewData
		put tNewData[tKey] into tVal

		put gSessionA["flashdata_key"] & ":new:" & tKey into tFlashdataKey
		rigSetSessUserdata tFlashdataKey, tVal
	end repeat
end rigSetSessFlashdata






/*----------------------------------------------------------------------
--| COMMAND rigSessMarkAsFlash
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-09-2015
--| Last Mod: 29-09-2015
--| Requires: rigSessAllUserdata(), rigSetSessUserdata
--|
--| Summary: Mark an existing item as flashdata.
--| 
--| Format:  rigSessMarkAsFlash param1
--|
--| Parameters: mixed <pKey>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigSessMarkAsFlash pKey
  local tUserData, tKeyExists, tKey, tVal, tFlashdataKey
  
  put rigSessAllUserdata() into tUserData
  
  if tUserData <> FALSE then
    
    if pKey is an array then
      put FALSE into tKeyExists
      
      repeat for each key tKey in pKey
        if tKey is among the keys of tUserData then
          put TRUE into tKeyExists
          put pKey[tKey] into tVal
          delete variable gSessionA["userdata"][tKey]
          put gSessionA["flashdata_key"] & ":new:" & tKey into tFlashdataKey
          rigSetSessUserdata tFlashdataKey, tVal
        end if
      end repeat
      
      if tKeyExists is TRUE then
        return TRUE
      end if
    
    else
      if pKey is among the keys of tUserData then
        put tUserData[pKey] into tVal
        delete variable gSessionA["userdata"][pKey]
        put gSessionA["flashdata_key"] & ":new:" & pKey into tFlashdataKey
        rigSetSessUserdata tFlashdataKey, tVal
      
        return TRUE
      end if
      
    end if -- if pKey is an array then
  end if -- if tUserData <> FALSE then
    
  return FALSE
end rigSessMarkAsFlash






/*----------------------------------------------------------------------
--| COMMAND rigKeepSessFlashdata
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-10-09
--| Last Mod: 14-10-09
--| Requires: rigSessUserdata(), rigSetSessUserdata
--|
--| Summary: Keeps existing flashdata available to next request.
--| 
--| Format:  rigKeepSessFlashdata param1
--|
--| Parameters: string <pKey>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigKeepSessFlashdata pKey
  local tOldFlashDataKey, tValue, tNewFlashDataKey
  
	# 'OLD' FLASHDATA GETS REMOVED.  HERE WE MARK ALL
	# FLASHDATA AS 'NEW' TO PRESERVE IT FROM _rigFlashdataSweep
	# NOTE THE FUNCTION WILL RETURN FALSE IF THE pKey
	# PROVIDED CANNOT BE FOUND
	put gSessionA["flashdata_key"] & ":old:" & pKey into tOldFlashDataKey
	put rigSessUserdata(tOldFlashDataKey) into tValue

	put gSessionA["flashdata_key"] & ":new:" & pKey into tNewFlashDataKey
	rigSetSessUserdata tNewFlashDataKey, tValue
end rigKeepSessFlashdata








/*----------------------------------------------------------------------
--| FUNCTION rigSessFlashdata
--|
--| Author: rabit
--| Version:  1.1
--| Created: 14-10-09
--| Last Mod: 29-09-15
--| Requires: rigSessUserdata(), rigSessAllUserdata()
--|
--| Summary: Fetch a specific flashdata item or all flashdata items from the session array.
--| 
--| Format:  rigSessFlashdata([param1])
--|
--| Parameters: string <pKey> optional
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigSessFlashdata pKey
  local tFlashdatakey, tFlashdataA, tUserData, tKey, tVal
  
  if pKey <> empty then
	  put gSessionA["flashdata_key"] & ":old:" & pKey into tFlashdatakey
	  return rigSessUserdata(tFlashdatakey)
    
  else
    put empty into tFlashdataA
    put rigSessAllUserdata() into tUserData

    if tUserData <> FALSE then
  	  repeat for each key tKey in tUserData
        if ":old:" is in tKey then
          put tUserData[tKey] into tVal
          put tVal into tFlashdataA[tKey]
        end if
      end repeat
    
      return tFlashdataA
    end if
  end if
  
  return ""
end rigSessFlashdata






/*----------------------------------------------------------------------
--| COMMAND _rigFlashdataMark
--|
--| Author: rabit
--| Version:  1.1
--| Created: 14-10-09
--| Last Mod: 30-09-15
--| Requires: rigSetSessUserdata, rigUnsetSessUserdata
--|
--| Summary: Identifies flashdata as 'old' for removal when _rigFlashdataSweep runs.
--| 
--| Format:  _rigFlashdataMark
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigFlashdataMark
  local tUserData, tUserdataKeys, tRegEx, tFlashDataArrayKeys, tLine, tVal
  local tName, tNewKey
  
	put rigSessAllUserdata() into tUserData
	
  put the keys of tUserData into tUserdataKeys
  put "^" & gSessionA["flashdata_key"] & ":new:.+$" into tRegEx
  filter tUserdataKeys matching regex pattern tRegEx into tFlashDataArrayKeys
  
  set the itemDel to ":"
  repeat for each line tLine in tFlashDataArrayKeys
    put tUserData[tLine] into tVal
    
    put item 3 of tLine into tName
    put gSessionA["flashdata_key"] & ":old:" & tName into tNewKey
    rigSetSessUserdata tNewKey, tVal
    rigUnsetSessUserdata tLine
  end repeat
end _rigFlashdataMark






/*----------------------------------------------------------------------
--| COMMAND _rigFlashdataSweep
--|
--| Author: rabit
--| Version:  1.1
--| Created: 14-10-09
--| Last Mod: 29-09-15
--| Requires: rigSessAllUserdata(), rigUnsetSessUserdata
--|
--| Summary: Removes all flashdata marked as 'old'.
--| 
--| Format:  _rigFlashdataSweep
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigFlashdataSweep
  local tUserData, tKey
  
	put rigSessAllUserdata() into tUserData
	
	repeat for each key tKey in tUserData
		
		if ":old:" is in tKey then
			rigUnsetSessUserdata tKey
		end if
	end repeat
end _rigFlashdataSweep










/*----------------------------------------------------------------------
--| COMMAND rigSetSessTempdata
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-09-2015
--| Last Mod: 29-09-2015
--| Requires: rigSetSessUserdata
--|
--| Summary: Add or change tempdata, only available until TTL has expired.
--| 
--| Format:  rigSetSessTempdata param1, param2[, param3]
--|
--| Parameters: mixed <pNewData>, string <pNewVal>, integer <pTTL> Time-To-Live in seconds (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetSessTempdata pNewData pNewVal pTTL
  local tArray, tNewData, tTTL, tUserData, tUserdataKeys, tRegEx
  local tTempDataArrayKeys, tKey, tLine, tVal, tTempdataKey
  
	if pNewData is not an array then
		put pNewVal into tArray[pNewData]
		put tArray into tNewData
	else
		put pNewData into tNewData
	end if
  
  # SET EXPIRATION TIME IN SECONDS
  if (pTTL is empty) or (pTTL is not an integer) then
    put the seconds + 300 into tTTL
  else
    put the seconds + pTTL into tTTL
  end if
  
  # GET ALL TEMP DATA ARRAY KEYS
  put rigSessAllUserdata() into tUserData
  if tUserData <> FALSE then
    put the keys of tUserData into tUserdataKeys
    put "^" & gSessionA["tempdata_key"] & ":\d+:.+$" into tRegEx
    filter tUserdataKeys matching regex pattern tRegEx into tTempDataArrayKeys
    set the itemDel to ":"

    # ADD TO USERDATA
	  repeat for each key tKey in tNewData
    
      # CHECK IF KEY EXISTS, IF YES DELETE ARRAY VARIABLE
      if tTempDataArrayKeys <> empty then
        repeat for each line tLine in tTempDataArrayKeys
          if item 3 of tLine is tKey then
            delete variable gSessionA["userdata"][tLine]
            exit repeat
          end if
        end repeat
      end if
    
      put tNewData[tKey] into tVal

      put gSessionA["tempdata_key"] & ":" & tTTL & ":" & tKey into tTempdataKey
      rigSetSessUserdata tTempdataKey, tVal
	  end repeat
  end if -- if tUserData <> FALSE then
end rigSetSessTempdata








/*----------------------------------------------------------------------
--| COMMAND rigSessMarkAsTemp
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-09-2015
--| Last Mod: 29-09-2015
--| Requires: rigSessAllUserdata(), rigSetSessUserdata
--|
--| Summary: Mark an existing item as tempdata.
--| 
--| Format:  rigSessMarkAsTemp param1[, param2]
--|
--| Parameters: mixed <pKey>, integer <pTTL> Time-To-Live in seconds (optional)
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigSessMarkAsTemp pKey pTTL
  local tTTL, tUserData, tKeyExists, tKey, tVal, tTempdataKey
  
  # SET EXPIRATION TIME IN SECONDS
  if (pTTL is empty) or (pTTL is not an integer) then
    put the seconds + 300 into tTTL
  else
    put the seconds + pTTL into tTTL
  end if
  
  put rigSessAllUserdata() into tUserData
  
  if tUserData <> FALSE then
    
    if pKey is an array then
      put FALSE into tKeyExists
      
      repeat for each key tKey in pKey
        if tKey is among the keys of tUserData then
          put TRUE into tKeyExists
          put gSessionA["userdata"][tKey] into tVal
          delete variable gSessionA["userdata"][tKey]
          put gSessionA["tempdata_key"] & ":" & tTTL & ":" & tKey into tTempdataKey
          rigSetSessUserdata tTempdataKey, tVal
        end if
      end repeat
      
      if tKeyExists is TRUE then
        return TRUE
      end if
    
    else
      if pKey is among the keys of tUserData then
        put tUserData[pKey] into tVal
        delete variable gSessionA["userdata"][pKey]
        put gSessionA["tempdata_key"] & ":" & tTTL & ":" & pKey into tTempdataKey
        rigSetSessUserdata tTempdataKey, tVal
      
        return TRUE
      end if
      
    end if -- if pKey is an array then
  end if -- if tUserData <> FALSE then
    
  return FALSE
end rigSessMarkAsTemp









/*----------------------------------------------------------------------
--| FUNCTION rigSessTempdata
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-09-2015
--| Last Mod: 29-09-2015
--| Requires: rigSessAllUserdata(), rigSessUserdata()
--|
--| Summary: Fetch a specific tempdata item or all tempdata items from the session array.
--| 
--| Format:  rigSessTempdata([param1])
--|
--| Parameters: string <pKey> (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigSessTempdata pKey
  local tUserData, tUserdataKeys, tRegEx, tTempDataArrayKey, tTempdataA
  local tTempDataArrayKeys, tLine, tVal, tKey
  
  put rigSessAllUserdata() into tUserData
  put the keys of tUserData into tUserdataKeys
  
  if tUserData <> FALSE then
    if pKey <> empty then
      
      put "^" & gSessionA["tempdata_key"] & ":\d+:" & pKey & "$" into tRegEx
      filter tUserdataKeys matching regex pattern tRegEx into tTempDataArrayKey
      return rigSessUserdata(tTempDataArrayKey)
    
    else
      # GET ALL TEMP DATA ITEMS AS ARRAY
      set the itemDel to ":"
      put empty into tTempdataA
      put "^" & gSessionA["tempdata_key"] & ":\d+:.+$" into tRegEx
      filter tUserdataKeys matching regex pattern tRegEx into tTempDataArrayKeys
      
      repeat for each line tLine in tTempDataArrayKeys
        put gSessionA["userdata"][tLine] into tVal
        put item 3 of tLine into tKey
        put tVal into tTempdataA[tKey]
      end repeat
      
      return tTempdataA
    end if
  end if
  
  return ""
end rigSessTempdata








/*----------------------------------------------------------------------
--| COMMAND _rigTempdataSweep
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-09-2015
--| Last Mod: 29-09-2015
--| Requires: --
--|
--| Summary: Removes all expired tempdata.
--| 
--| Format:  _rigTempdataSweep
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigTempdataSweep
  local tTime, tUserData, tUserDataKeys, tTempDataArrayKeys, tLine
  
  put the seconds into tTime
  put rigSessAllUserdata() into tUserData
  
  if tUserData <> FALSE then
    put the keys of tUserData into tUserDataKeys
  
    filter tUserDataKeys matching regex pattern "^temp:\d+:.+$" into tTempDataArrayKeys
  
    set the itemDel to ":"
  
    repeat for each line tLine in tTempDataArrayKeys
		
      if item 2 of tLine < tTime then
        rigUnsetSessUserdata tLine
      end if
    end repeat
  end if
end _rigTempdataSweep








----------------------------------------------------------------------
--| FUNCTION _rigGetTime
--|
--| Author: rabit
--| Version:  1.2
--| Created: 12-10-09
--| Last Mod: 15-07-12
--| Requires: rigMasterNow()
--|
--| Summary: Get the "now" time.
--| 
--| Format:  _rigGetTime()
--|
--| Parameters: --
--|
--| Return: integer
----------------------------------------------------------------------

private function _rigGetTime
	return rigMasterNow()
end _rigGetTime





/*----------------------------------------------------------------------
--| COMMAND _rigSetCookie
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2009-10-14
--| Last Mod: 2017-06-27
--| Requires: _rigSerializeSess(), rigSetHash, rigEncode(), rigHexDigest(), _rigInputSetCookie
--|
--| Summary: Write the session cookie.
--| 
--| Format:  _rigSetCookie
--|
--| Parameters: array <pCookieData>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetCookie pCookieData
  local tCookieData, tHash, tExp

	if pCookieData is not an array then
		put gSessionA["userdata"] into tCookieData
	else
		put pCookieData into tCookieData
	end if

	# SERIALIZE THE USERDATA FOR THE COOKIE
	put _rigSerializeSess(tCookieData) into tCookieData

	if sSessionA["sess_encrypt_cookie"] is TRUE then
		rigSetHash sSessionA["sess_hash_type"]
		put rigEncode(tCookieData) into tCookieData
	else
    # IF ENCRYPTION IS NOT USED, WE PROVIDE A SHA3-256 DIGEST OF THE rigHexDigest
    # HASH FUNCTION (Md5 DIGEST IF LC SERVER VERSION < 9 IS USED) TO PREVENT
    # USERSIDE TAMPERING
		put tCookieData & sSessionA["encryption_key"] into tHash
		put rigHexDigest(tHash) into tHash
		put tCookieData & tHash into tCookieData
	end if

	# SET THE COOKIE
	if gSessionA["sess_expire_on_close"] is TRUE then
		put "" into tExp
	else
		put gSessionA["sess_expiration"] into tExp
	end if
  
	_rigInputSetCookie gSessionA["sess_cookie_name"], tCookieData, tExp, gSessionA["cookie_domain"], gSessionA["cookie_path"], "", TRUE, sSessionA["cookie_secure"]
end _rigSetCookie





/*----------------------------------------------------------------------
--| FUNCTION _rigSerializeSess
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-10-09
--| Last Mod: 12-10-09
--| Requires: --
--|
--| Summary: This function first converts any slashes found in the array to a temporary
--|                    marker, so when it gets unserialized the slashes will be preserved.
--| 
--| Format:  _rigSerializeSess(param1)
--|
--| Parameters: array <pData>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigSerializeSess pData
  local tData, tKey, tVal
  
	put pData into tData

	if tData is an array then
		repeat for each key tKey in tData
			put tData[tKey] into tVal

			replace "\" with "{{slash}}" in tVal
			put tVal into tData[tKey]
		end repeat
	else
		replace "\" with "{{slash}}" in tData
	end if

	return arrayEncode(tData)
end _rigSerializeSess





/*----------------------------------------------------------------------
--| FUNCTION _rigUnserializeSess
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2009-10-12
--| Last Mod: 2018-12-13
--| Requires: rigStripSlashes()
--|
--| Summary: This function unserializes a data string, then converts any
--|            temporary slash markers back to actual slashes.
--| 
--| Format:  _rigUnserializeSess(param1)
--|
--| Parameters: array <pData>
--|
--| Return: array
----------------------------------------------------------------------*/

function _rigUnserializeSess pData
  local tData, tArrayEncodedMarker, tKey, tVal
  
  put rigStripSlashes(pData) into tData
 
  # CHECK IF TDATA IS ARRAYENCODED
  put 6 into tArrayEncodedMarker

  if codepointToNum(char 1 of tData) = tArrayEncodedMarker then
    # OK, THEN DECODE TDATA
    put arrayDecode(tData) into tData
  end if

  if tData is an array then
    repeat for each key tKey in tData
      put tData[tKey] into tVal

      replace "{{slash}}" with "\" in tVal
      put tVal into tData[tKey]
    end repeat

    return tData
  end if

  replace "{{slash}}" with "\" in tData

  return tData
end _rigUnserializeSess






/*----------------------------------------------------------------------
--| COMMAND _rigSessGC
--|
--| Author: rabit
--| Version:  1.1
--| Created: 14-10-09
--| Last Mod: 30-09-15
--| Requires: _rigGCexpiredSess
--|
--| Summary: This deletes expired session files or session rows from database
--|            if the probability percentage is met.
--| 
--| Format:  _rigSessGC
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSessGC
  if gSessionA["sess_driver"] <> empty then  
    _rigGCexpiredSess
	end if
end _rigSessGC









--| END OF Session.livecodescript
--| Location:  ./system/libraries/Session.livecodescript
----------------------------------------------------------------------