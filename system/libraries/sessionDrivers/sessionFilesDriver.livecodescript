script "sessionFilesDriver"

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
# revIgniter Session Files Driver
#
#
# @package		  revIgniter
# @subpackage	Libraries
# @category		  Sessions
# @author			  rabit@revigniter.com
# @link				  https://revigniter.com/userGuide/libraries/sessions.html
##




global gRigA, gSessionA

local sSessionTmpFolderName, sSessionFilePath, sSessionSaveLocationValid






 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-13
 --| Last Mod: --
 --| Requires: _rigInitializeSessFilesDriver
 --|
 --| Summary:  Run security check and initial routines. Set initial values.
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
    # SET INITIAL VALUES
    put "ri_sessions" into sSessionTmpFolderName
    
    # CALL INITIAL HANDLERS
    _rigInitializeSessFilesDriver    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack







/*----------------------------------------------------------------------
--| COMMAND _rigInitializeSessFilesDriver
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2015-09-01
--| Last Mod: 2019-01-12
--| Requires: rigLogMessage, _rigCreateSessionFolder, rigRTrim(), rigCanWriteFileTo()
--|
--| Summary: Initialize session files driver.
--| 
--| Format:  _rigInitializeSessFilesDriver 
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigInitializeSessFilesDriver
  local tTempFolderPath
  
  put TRUE into sSessionSaveLocationValid
  
  # CHECK IF PATH TO SESSION FILES FOLDER IS SET
  # OTHERWISE USE TEMPORARY FOLDER PATH
  if gSessionA["sess_save_location"] is empty then
    set the itemDel to "/"
    put (item 1 to -2 of the tempname) into tTempFolderPath

    put tTempFolderPath & "/" & sSessionTmpFolderName into gSessionA["sess_save_location"]
    # WE USE THE SESSION COOKIE NAME AS PREFIX
    put tTempFolderPath & "/" & sSessionTmpFolderName & "/" & gSessionA["sess_cookie_name"] into sSessionFilePath

    if there is a folder gSessionA["sess_save_location"] then
    else
      # NO FOLDER, SO CREATE FOLDER
      _rigCreateSessionFolder
    end if
      
  else
    replace "\" with "/" in gSessionA["sess_save_location"]
    put rigRTrim(gSessionA["sess_save_location"], "/") into gSessionA["sess_save_location"]
    if not rigIsAbsolutePath(gSessionA["sess_save_location"]) then
      put the defaultfolder & "/" & gSessionA["sess_save_location"] into gSessionA["sess_save_location"]
    else
      put "/" & gSessionA["sess_save_location"] into gSessionA["sess_save_location"]
    end if
    
    # WE USE THE SESSION COOKIE NAME AS PREFIX
    put gSessionA["sess_save_location"] & "/" & gSessionA["sess_cookie_name"] into sSessionFilePath
    
    # CHECK IF PATH TO SESSION FILES FOLDER SET BY USER EXISTS
    # AND IF IT IS WRITABLE
    if there is a folder gSessionA["sess_save_location"] then
      if rigCanWriteFileTo(gSessionA["sess_save_location"]) is FALSE then
        rigLogMessage "error", "Session: Configured save location" && quote & gSessionA["sess_save_location"] & quote && "is not writable by revIgniter!"
        put FALSE into sSessionSaveLocationValid
      end if
    else
      
      _rigCreateSessionFolder
    end if
    
  end if
end _rigInitializeSessFilesDriver







/*----------------------------------------------------------------------
--| COMMAND _rigCreateSessionFolder
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2015-09-01
--| Last Mod: 2019-01-12
--| Requires: rigLogMessage
--|
--| Summary: Create folder for session data.
--| 
--| Format:  _rigCreateSessionFolder
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigCreateSessionFolder
  local tCurrentUmask
  
  set the convertOctals to true
  put the umask into tCurrentUmask
  set the umask to "0077"

  create folder gSessionA["sess_save_location"]
  
  if the result is not empty then
    set the itemDelimiter to "/"
    if (item 1 to -2 of the tempname) is in gSessionA["sess_save_location"] then
      # USING TEMPORARY FOLDER
      rigLogMessage "error", "Session: Folder name in tmp folder already taken! Please set a custom sess_save_location in config.lc. System error:" && the sysError
    else
      
      rigLogMessage "error", "Session: Configured save path" && quote & gSessionA["sess_save_location"] & quote && "is not a directory, doesn't exist or cannot be created. System error:" && the sysError
    end if
    put FALSE into sSessionSaveLocationValid
  end if

  set the umask to tCurrentUmask
end _rigCreateSessionFolder







/*----------------------------------------------------------------------
--| FUNCTION rigGetSessData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 02-09-2015
--| Last Mod: 02-09-2015
--| Requires: rigLogMessage, rigSessDestroy, trueFalseToDigit(), _rigUnserializeSess()
--|
--| Summary: Get custom session data from file.
--| 
--| Format:  rigGetSessData(param1, param2, param3, param4)
--|
--| Parameters: string <pSessID>, string <pSessIP>, string <pSessUserAgent>, array <pSessionA> default session data
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigGetSessData pSessID pSessIP pSessUserAgent pSessionA
  local tMatchCounter, tMatches, tSessionFile, tSessionFileData, tUserData
  local tCustomData, tKey, tVal
  
  if sSessionSaveLocationValid is TRUE then
    
    put 0 into tMatchCounter
    put 0 into tMatches
    
	  put sSessionFilePath & pSessID into tSessionFile

    if there is a file tSessionFile then
      put URL ("binfile:" & tSessionFile) into tSessionFileData
      
      if the result <> empty then
        rigLogMessage "error", "Session: Failed to read session file! System error:" && the sysError
    		 rigSessDestroy
    		 return FALSE
      end if
      
      # MATCH IP AND USER AGENT
      #
    	 if gSessionA["sess_match_ip"] is TRUE then
         add 1 to tMatchCounter
         add trueFalseToDigit(pSessIP is line 2 of tSessionFileData) to tMatches
    	 end if
       
    	 if gSessionA["sess_match_useragent"] is TRUE then
         add 1 to tMatchCounter
         add trueFalseToDigit(pSessUserAgent is line 3 of tSessionFileData) to tMatches
    	 end if
      
      # MISMATCH?  KILL IT!
      if tMatchCounter <> tMatches then
     	rigSessDestroy
     	return FALSE
      end if
       #
       
       # IS THERE CUSTOM DATA?  IF SO, ADD IT TO THE MAIN SESSION ARRAY
       put line 5 of tSessionFileData into tUserData
     	if tUserData is not empty then
         put base64Decode(urlDecode(tUserData)) into tCustomData
     		put _rigUnserializeSess(tCustomData) into tCustomData
     		if tCustomData is an array then
     			repeat for each key tKey in tCustomData
     				put tCustomData[tKey] into tVal

     				put tVal into pSessionA[tKey]
     			end repeat
     		end if
     	end if
  
      else -- if there is a file tSessionFile then
      
      # NO SESSION FILE? KILL IT!
  	  rigSessDestroy
  	  return FALSE
    end if
    
    return pSessionA
  end if
end rigGetSessData







/*----------------------------------------------------------------------
--| COMMAND rigUpdateSessData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-09-2015
--| Last Mod: 01-09-2015
--| Requires: rigLogMessage
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
  local tSessionFile, tSessionFileData
  
  if sSessionSaveLocationValid is TRUE then
    
	  put sSessionFilePath & gSessionA["userdata"]["session_id"] into tSessionFile

    if there is a file tSessionFile then
      put URL ("binfile:" & tSessionFile) into tSessionFileData
     
      if the result <> empty then
        rigLogMessage "error", "Session: Failed to read session file! System error:" && the sysError
        exit rigUpdateSessData
      end if
      
      put gSessionA["userdata"]["last_activity"] into line 4 of tSessionFileData
      put pUserData into line 5 of tSessionFileData
      
      put tSessionFileData into URL ("binfile:" & tSessionFile)
    end if
    
  end if
end rigUpdateSessData






/*----------------------------------------------------------------------
--| COMMAND rigCreateSessData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-09-2015
--| Last Mod: 01-09-2015
--| Requires: rigLogMessage
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
  local tSessionFile, tSessionUserData
  
  if sSessionSaveLocationValid is TRUE then
    
		# CREATE SESSION DATA FILE
  	put sSessionFilePath & gSessionA["userdata"]["session_id"] into tSessionFile

  	open file tSessionFile for binary write
		# ENGINE ≥ 7 VERSION
    -- put rigFetchConfigItem("defaultCharset") into tCharset
    -- open file tSessionFile for tCharset text write
    if the result is empty then -- success!
      
      put gSessionA["userdata"]["session_id"] & return & gSessionA["userdata"]["ip_address"] \
        & return & gSessionA["userdata"]["user_agent"] & return & gSessionA["userdata"]["last_activity"] & return into tSessionUserData
        
			write tSessionUserData to file tSessionFile
        
			close file tSessionFile

		else
      rigLogMessage "error", "Session: Failed to create session file! System error:" && the sysError
    end if -- if the result is empty then -- success!
  
  end if
end rigCreateSessData






/*----------------------------------------------------------------------
--| COMMAND rigUpdateCurrentSess
--|
--| Author: rabit
--| Version:  1.0
--| Created: 03-09-2015
--| Last Mod: 03-09-2015
--| Requires: rigLogMessage
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
  local tKeys, tCookieData, tOldSessionFile, tNewSessionData, tNewSessionFile
  
  # SET COOKIE EXPLICITLY TO ONLY HAVE OUR SESSION DATA
  put "session_id,ip_address,user_agent,last_activity" into tKeys
  repeat for each item tKey in tKeys
    put gSessionA["userdata"][tKey] into tCookieData[tKey]
  end repeat
  
  if sSessionSaveLocationValid is TRUE then
    
    # DELETE OLD SESSION FILE
	  put sSessionFilePath & pOldSessID into tOldSessionFile
    
    if there is a file tOldSessionFile then
      put URL ("binfile:" & tOldSessionFile) into tNewSessionData
     
      if the result <> empty then
        rigLogMessage "error", "Session: Failed to read old session file! System error:" && the sysError
      end if
      
      delete file tOldSessionFile
      if the result <> empty then
        rigLogMessage "error", "Session: Could not delete old session file! System error:" && the sysError
      end if
    end if
    
    # CREATE A NEW ONE
    put sSessionFilePath & pNewSessID into tNewSessionFile
    
  	open file tNewSessionFile for binary write
    # ENGINE ≥ 7 VERSION
    -- put rigFetchConfigItem("defaultCharset") into tCharset
    -- open file tNewSessionFile for tCharset text write
		
    if the result is empty then -- success!
      # session_id
      put pNewSessID into line 1 of tNewSessionData
      # last_activity
      put gSessionA["now"] into line 4 of tNewSessionData
      
      write tNewSessionData to file tNewSessionFile
      
      close file tNewSessionFile

    else
      rigLogMessage "error", "Session: Failed to create new session file! System error:" && the sysError
    end if

    return tCookieData
  
  end if
end rigUpdateCurrentSess







/*----------------------------------------------------------------------
--| COMMAND rigDestroySessData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-09-2015
--| Last Mod: 12-09-2015
--| Requires: --
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
  local tSessionFile
  
  if sSessionSaveLocationValid is TRUE then
    put sSessionFilePath & gSessionA["userdata"]["session_id"] into tSessionFile
    delete file tSessionFile
  end if
end rigDestroySessData






/*----------------------------------------------------------------------
--| COMMAND _rigGCexpiredSess
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2015-09-12
--| Last Mod: 2019-01-12
--| Requires: rigLogMessage
--|
--| Summary: This deletes expired session files if the probability percentage is met.
--| 
--| Format:  _rigGCexpiredSess 
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigGCexpiredSess
  local tRand, tUpperLimit, tSessionFilesList, tExpire
  local tFileToDelete
  
  if sSessionSaveLocationValid is TRUE then
    put empty into tRand
    repeat while (the length of tRand) < 8
      put 2147483647 into tUpperLimit
      put random(tUpperLimit) after tRand
    end repeat
  
    put (tRand mod 100) into tRand
  
    if tRand < gSessionA["gc_probability"] then
  
      # GET FILES LIST (NAMES AND MODIFICATION DATE)
      put files(gSessionA["sess_save_location"], "detailed") into tSessionFilesList
  	
      if tSessionFilesList is not empty then
        filter tSessionFilesList without "*.,*"
        filter tSessionFilesList without "*..,*"
        filter tSessionFilesList without "*.DS_Store,*" -- Mac only
        --------- ??????????
        filter tSessionFilesList without "Icon%0D*"
        filter tSessionFilesList without "*,MACSfdrp" -- remove folder aliases
        --------- ??????????
  
        put gSessionA["now"] - gSessionA["sess_expiration"] into tExpire
  	
        repeat for each line tFile in tSessionFilesList
          if item 5 of tFile < tExpire then
            put gSessionA["sess_save_location"] & "/" & URLDecode(item 1 of tFile) into tFileToDelete
            delete file tFileToDelete
          end if
        end repeat
  	
      end if -- if tSessionFilesList is not empty then

      rigLogMessage "debug", "Session garbage collection performed."
    end if -- if tRand < gSessionA["gc_probability"] then
  end if
end _rigGCexpiredSess








--| END OF sessionFilesDriver.livecodescript
--| Location:  ./system/libraries/sessionDrivers/sessionFilesDriver.livecodescript
----------------------------------------------------------------------