script "Ftp"

##
# revIgniter
#
# An application development framework for LiveCode
# modeled on CodeIgniter.
#
# @package      revIgniter
# @author       rabit@revigniter.com
# @copyright    Copyright (c) 2009 - 2020, dimensionB Bitter u. Bitter GmbH
# @license      https://revigniter.com/userGuide/license.html
# @link		      https://revigniter.com
##

## ------------------------------------------------------------------------

##
# revIgniter FTP Library
#
# @package      revIgniter
# @subpackage   Libraries
# @category      FTP
# @author		     rabit@revigniter.com
# @link		       https://revigniter.com/userGuide/libraries/ftp.html
##

## ------------------------------------------------------------------------



global gRigA

local sFtpA, sFtpSettingsItems, sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-21
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
        rigLogMessage "debug", "FTP Library Loaded"
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
  put empty into sFtpA["tsNetEdition"]
  put "ftp" into sFtpA["flavor"]
  put 21 into sFtpA["port"]
  put "passive" into sFtpA["mode"]
  put "rigFtp" into sFtpA["connID"]
  put FALSE into sFtpA["asyncRequest"]
  -- put TRUE into sFtpA["secure"]
  put FALSE into sFtpA["verifySSL"]
  put "" into sFtpA["request"]
  put "" into sFtpA["response"]
  put "" into sFtpA["transferResult"]
  put "" into sFtpA["callbackError"]
  put "" into sFtpA["statusMsg"]
  put FALSE into sFtpA["debug"]
  put "" into sFtpA["debugMsg"]
  put 100 into sFtpA["initWait"]                     -- Milliseconds to wait after initializing the tsNet external
  put "" into sFtpA["transferType"]
  put TRUE into sFtpA["displayErrors"]
  put TRUE into sFtpA["noErrors"]
  put FALSE into sFtpA["setFilePermissions"]
  put empty into sFtpA["filePermissions"]
  put 0700 into sFtpA["settings"]["defaultPermissions"]
  put empty into sFtpA["remotePath"]

  put "" into sFtpA["settings"]["hostname"]        -- Can be a hostname or an IP address
  put "anonymous" into sFtpA["settings"]["username"]
  put "" into sFtpA["settings"]["password"]
  put FALSE into sFtpA["settings"]["use_ssl"]
  put FALSE into sFtpA["settings"]["no_reuse"]

  put "" into sFtpA["settings"]["ssh_passphrase"]
  put "" into sFtpA["settings"]["ssh_host_public_key"]
  put "" into sFtpA["settings"]["ssh_private_key"]

  put "hostname,username,password,use_ssl,no_reuse,ssh_passphrase,ssh_host_public_key,ssh_private_key" into sFtpSettingsItems
end _rigSetDefaultValues






/*----------------------------------------------------------------------
--| COMMAND rigRunInitialFtpConfig
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-08-18
--| Last Mod: 2016-08-18
--| Requires: rigInitializeFTP, rigTrim()
--|
--| Summary: Run initial configuration procedures. Don't remove, even if it does nothing.
--|
--| Format:  rigRunInitialFtpConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialFtpConfig pConfig
  local tTsNetEdition, tRegEx
  
  if pConfig is not an array then
    if pConfig is not empty then
      split pConfig using numToCodepoint(1) and numToCodepoint(2)
    end if
  end if

  if pConfig is an array then
    # CHECK IF THERE IS AN INDY OR BUSSINESS tsNet EXTENSION
    try
       put tsNetVersion() into tTsNetEdition
       if "Indy" is in tTsNetEdition then
         put "Indy" into sFtpA["tsNetEdition"]
       else
         put "Business" into sFtpA["tsNetEdition"]
      end if
    catch e
       put empty into sFtpA["tsNetEdition"]
    end try
    #

    rigInitializeFTP pConfig
    
    # PREP THE HOSTNAME
    put rigTrim(sFtpA["settings"]["hostname"], "/") into sFtpA["settings"]["hostname"]
    put ".+?://" into tRegEx
    put replacetext(sFtpA["settings"]["hostname"], tRegEx, "") into sFtpA["settings"]["hostname"]
  end if
end rigRunInitialFtpConfig





/*----------------------------------------------------------------------
--| COMMAND rigInitializeFTP
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-08-18
--| Last Mod: 2016-08-18
--| Requires: rigSetInitialFtpValue, rigFtpError
--|
--| Summary: Initialize preferences.
--| 
--| Format:  rigInitializeFTP param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigInitializeFTP pConfig
  local tKey, tVal, tTsNetInitResult, tHost
  
  if pConfig is an array then
    repeat for each key tKey in pConfig

      put pConfig[tKey] into tVal

      rigSetInitialFtpValue tKey, tVal

    end repeat
  end if
  
  #
  if sFtpA["tsNetEdition"] <> empty then
    tsNetInit
    wait sFtpA["initWait"] millisecs
    
    put the result into tTsNetInitResult
    if (tTsNetInitResult <> empty) and ("Already initialised" is not in tTsNetInitResult) then
      rigFtpError "ftp_tsNet_initialisation_failed"
    end if

    if sFtpA["mode"] <> "passive" then
      put sFtpA["settings"]["hostname"] & ":" & sFtpA["port"] into tHost
    else
      put "" into tHost
    end if
    tsNetSetFTPPort tHost
  
  else
    rigFtpError "ftp_tsNet_initialisation_failed"
  end if -- if sFtpA["tsNetEdition"] <> empty
end rigInitializeFTP






/*----------------------------------------------------------------------
--| COMMAND rigSetInitialFtpValue
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2016-08-18
--| Last Mod: 2019-01-06
--| Requires: --
--|
--| Summary: Set initial values.
--| 
--| Format:  rigSetInitialFtpValue param1 param2
--|
--| Parameters: string <pVarName>, mixed <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetInitialFtpValue pVarName pValue
  rigFtpSet pVarName, pValue
end rigSetInitialFtpValue






/*----------------------------------------------------------------------
--| COMMAND rigFtpError
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-08-19
--| Last Mod: 2016-08-19
--| Requires: rigLangLoadLang(), rigLangLangLine(), rigLogMessage
--|
--| Summary: Display FTP error message.
--| 
--| Format:  rigFtpError param1
--|
--| Parameters: string <pLine>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigFtpError pLine
  local tShowErrorPage, tErrorMessage
  
  if (sFtpA["displayErrors"] is empty) or (sFtpA["displayErrors"] is not a boolean) then
    put FALSE into tShowErrorPage
  else
    put sFtpA["displayErrors"] into tShowErrorPage
  end if
  
  get rigLangLoadLang("ftp")
  put rigLangLangLine(pLine) into tErrorMessage

  if tErrorMessage <> FALSE then
    rigLogMessage "error", tErrorMessage, tShowErrorPage
  else
    rigLogMessage "error", pLine, tShowErrorPage
  end if
  
  put FALSE into sFtpA["noErrors"]
end rigFtpError






/*----------------------------------------------------------------------
--| FUNCTION rigFtpPrintDebugger
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-10-12
--| Last Mod: 2016-10-12
--| Requires: --
--|
--| Summary: Get FTP debug message.
--| 
--| Format:  rigFtpPrintDebugger([param])
--|
--| Parameters: string <pWhichMsg> "status" or "debug" (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFtpPrintDebugger pWhichMsg
  local tVersions
  
	put "<h3>Versions</h3>" & cr & \
	"<p>LC Server:" && the version && the editionType & "</p>" & cr & \
	"<p>tsNet:" && tsNetVersion() & "</p>" & cr & \
	"<p>revIgniter:" && rigVersion() & "</p>" into tVersions
	
  switch pWhichMsg
    case "status"
      replace return with "<br>" in sFtpA["statusMsg"]
      return "<p>" & sFtpA["statusMsg"] & "</p>" & cr & tVersions
  
    case "debug"
      replace return with "<br>" in sFtpA["debugMsg"]
      return "<p>" & sFtpA["debugMsg"] & "</p>" & cr & tVersions
  
    default
      replace return with "<br>" in sFtpA["statusMsg"]
      replace return with "<br>" in sFtpA["debugMsg"]
  
      return "<h3>Status Information</h3>" & cr & "<p>" & sFtpA["statusMsg"] & "</p>" & cr \
      & "<h3>Debug information</h3>" & cr & "<p>" & sFtpA["debugMsg"] & "</p>" & cr & tVersions
  end switch
end rigFtpPrintDebugger





/*----------------------------------------------------------------------
--| COMMAND rigFtpListFiles
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-10-13
--| Last Mod: 2016-10-13
--| Requires: rigTrim(), _rigFtpPrepareTransfer, _rigFtpCheckResult,
--|            _rigFtpTransferComplete
--|
--| Summary: Get directory listing.
--|            Note: Asynchronous SFTP and SFTP using public key authentication need LC Business Edition.
--| 
--| Format:  rigFtpListFiles [param1][, param2][, param3]
--|
--| Parameters: string <pPath> (optional), bool <pSimpleList> (optional), bool <pTransferPrepared> (internal)
--|
--| Return: mixed
----------------------------------------------------------------------*/

command rigFtpListFiles pPath pSimpleList pTransferPrepared
  local tConnID, tEmptyHeaderVar, tResultHeaders, tResult, tBytes, tResponse
  local tError
  
	if pPath <> empty then
		replace "\" with "/" in pPath
		put rigTrim(pPath, "/") into pPath
		put pPath & "/" into pPath
	end if

	if (pSimpleList is empty) or (pSimpleList is FALSE) then
		tsNetSetDirNLST FALSE

	else if pSimpleList is TRUE then
	  tsNetSetDirNLST TRUE
	end if

	if pTransferPrepared <> TRUE then
		_rigFtpPrepareTransfer
	end if
  
	# RESET RESULT DATA OF PREVIOUS REQUESTS
	put "" into sFtpA["transferResult"]
    
	put sFtpA["connID"] into tConnID
	put sFtpA["flavor"] & "://" & sFtpA["settings"]["hostname"] & "/" & pPath into sFtpA["request"][tConnID]

	put empty into tEmptyHeaderVar

	if sFtpA["asyncRequest"] is FALSE then
		# SYNCHRONOUS REQUEST
		if tsNetIsSyncBlocked() is FALSE then
			put tsNetGetSync(sFtpA["request"][tConnID], tEmptyHeaderVar, tResultHeaders, tResult, tBytes, sFtpA["settings"]) into tResponse
			if the first word of tResponse is not "tsneterr:" then
				put tResponse into sFtpA["response"][tConnID]
			else
				_rigFtpCheckResult tResponse, "tsNetGetSync", "ftp_unable_to_list"
			end if

			_rigFtpTransferComplete
		else -- if tsNetIsSyncBlocked() is FALSE
			_rigFtpCheckResult "A synchronous network call is already in progress.", "tsNetGetSync", "ftp_sync_blocked"
		end if -- if tsNetIsSyncBlocked() is FALSE

  else
    # ASYNCHRONOUS REQUEST
    put tsNetGet(tConnID, sFtpA["request"][tConnID], tEmptyHeaderVar, "_rigFtpCallback", sFtpA["settings"]) into tError
    if tError <> empty then
      _rigFtpCheckResult tError, "tsNetGet", "ftp_unable_to_list", TRUE
    end if

  end if -- if sFtpA["asyncRequest"] is FALSE
      
  if sFtpA["noErrors"] is FALSE then
    return FALSE
  end if
  
  set the itemDel to numToCodepoint(0)
  return item 1 of sFtpA["transferResult"]
end rigFtpListFiles


-- function rigFtpResponseData
--   return "rigFtpResponseData:" && sFtpA["transferResult"]
-- end rigFtpResponseData





/*----------------------------------------------------------------------
--| COMMAND rigFtpUpload
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-12-14
--| Last Mod: 2016-12-14
--| Requires: rigTrim(), _rigFtpPrepareTransfer, _rigFtpCheckResult,
--|            _rigFtpTransferComplete
--|
--| Summary: Upload a file to the server.
--|            Note: Asynchronous SFTP and SFTP using public key authentication need LC Business Edition.
--| 
--| Format:  rigFtpUpload param1, param2[, param3][, param4]
--|
--| Parameters: mixed <pLocalPath>, string <pRemotePath>, bool <pData> (optional),
--|               bool <pCreateMissingDirs> (optional), integer <pPermissions> file permissions (optional, octal)
--|
--| Return: mixed
----------------------------------------------------------------------*/

command rigFtpUpload pLocalPath pRemotePath pData pCreateMissingDirs pPermissions
  local tExitWithError, tConnID, tEmptyHeaderVar, tOutHeaders, tStatusCode, tBytes
  local tResult, tHandler
  
  if (pData is empty) or (pData is not a boolean) then
    put FALSE into pData
  end if
  
  put FALSE into tExitWithError
  
  if pData is FALSE then
    if there is not a file pLocalPath then
      put TRUE into tExitWithError
    end if -- if there is not a file pLocalPath
    
  else -- if pData is FALSE
    if pLocalPath is empty then
      put TRUE into tExitWithError
    end if -- if pLocalPath is empty 
  end if -- if pData is FALSE
  
  if tExitWithError is TRUE then
    rigFtpError "ftp_no_source_file"
    exit rigFtpUpload
  end if -- if tExitWithError is TRUE
  
  if (pCreateMissingDirs is empty) or (pCreateMissingDirs is not a boolean) then
    put FALSE into pCreateMissingDirs
  end if
	  
  put sFtpA["connID"] into tConnID
  
  # THIS IS ALREADY DONE IN rigFTPmirror
  if sFtpA["multipleUploads"] <> TRUE then
    replace "\" with "/" in pRemotePath
    put rigTrim(pRemotePath, "/") into pRemotePath

    _rigFtpPrepareTransfer

    put sFtpA["flavor"] & "://" & sFtpA["settings"]["hostname"] into sFtpA["request"][tConnID]
  end if
  #
	
	if (pPermissions <> empty) and (pPermissions is a integer) then
		put pPermissions into sFtpA["filePermissions"]
		put pRemotePath into sFtpA["remotePath"]
	end if
  
  # RESET RESULT DATA OF PREVIOUS REQUESTS
  put "" into sFtpA["transferResult"]
  
  tsNetCreateMissingDirs pCreateMissingDirs
  
  put "upload" into sFtpA["transferType"]

  put empty into tEmptyHeaderVar

	# tsNetUploadFileSync DOES NOT WORK WITH INDY USING SFTP
	# SO, GET THE FILE DATA AND USE tsNetUploadSync
  if sFtpA["flavor"] is "sftp" then
    if sFtpA["tsNetEdition"] is "Indy" then
	    put URL("binfile:" & pLocalPath) into pLocalPath
	    put TRUE into pData
    end if
  end if -- if sFtpA["flavor"] is "sftp"

  if sFtpA["asyncRequest"] is FALSE then
		# SYNCHRONOUS REQUEST
		if tsNetIsSyncBlocked() is FALSE then
	    if pData is FALSE then
	      # FILE
			  put tsNetUploadFileSync(pLocalPath, sFtpA["request"][tConnID] & "/" & pRemotePath, tEmptyHeaderVar, tOutHeaders, tStatusCode, tBytes, sFtpA["settings"]) into tResult
	    else -- if pData is FALSE
	      # DATA
	      put tsNetUploadSync(sFtpA["request"][tConnID] & "/" & pRemotePath, tEmptyHeaderVar, pLocalPath, tOutHeaders, tStatusCode, tBytes, sFtpA["settings"]) into tResult
	    end if -- if pData is FALSE
		
			if tResult <> empty then
	       if pData is FALSE then
	         put "tsNetUploadFileSync" into tHandler
	       else
	         put "tsNetUploadSync" into tHandler
	       end if
	       _rigFtpCheckResult tResult, tHandler, "ftp_unable_to_upload", TRUE
			end if -- if tResult <> empty

	    _rigFtpTransferComplete tBytes
		else -- if tsNetIsSyncBlocked() is FALSE
			_rigFtpCheckResult "A synchronous network call is already in progress.", "tsNetGetSync", "ftp_sync_blocked"
		end if -- if tsNetIsSyncBlocked() is FALSE
    
  else -- if sFtpA["asyncRequest"] is FALSE
    # ASYNCHRONOUS REQUEST
    if pData is FALSE then
      # FILE
      put tsNetUploadFile(tConnID, pLocalPath, sFtpA["request"][tConnID] & "/" & pRemotePath, tEmptyHeaderVar, "_rigFtpCallback", sFtpA["settings"]) into tResult
    else -- if pData is FALSE
      # DATA
      put tsNetUpload(tConnID, sFtpA["request"][tConnID] & "/" & pRemotePath, tEmptyHeaderVar, "_rigFtpCallback", pLocalPath, sFtpA["settings"]) into tResult
    end if -- if pData is FALSE
		
    if tResult <> empty then
       if pData is FALSE then
         put "tsNetUploadFile" into tHandler
       else
         put "tsNetUpload" into tHandler
       end if
       _rigFtpCheckResult tResult, tHandler, "ftp_unable_to_upload", TRUE
    end if -- if tResult <> empty
  end if -- if sFtpA["asyncRequest"] is FALSE
  
  if sFtpA["noErrors"] is FALSE then
    return FALSE
  end if
  
  return sFtpA["transferResult"]
end rigFtpUpload





/*----------------------------------------------------------------------
--| COMMAND rigFtpMirror
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2017-09-18
--| Last Mod: 2019-01-12
--| Requires: rigTrim(), rigIsAbsolutePath(), _rigFtpPrepareTransfer, _rigFtpMirrorFilesFolders
--|
--| Summary: Recursively reads local folder including sub-folders and creates a mirror on the remote server.
--|            Note: SFTP needs LC Business Edition.
--| 
--| Format:  rigFtpMirror param1, param2
--|
--| Parameters: string <pLocalPath>, string <pRemotePath>
--|
--| Return: mixed
----------------------------------------------------------------------*/

command rigFtpMirror pLocalPath pRemotePath
  local tConnID
  
  # PREPARE pLocalPath
  # USE ABSOLUTE PATH
  replace "\" with "/" in pLocalPath
  put rigTrim(pLocalPath, "/") into pLocalPath
  if not rigIsAbsolutePath(pLocalPath) then
    put the defaultfolder & "/" & pLocalPath into pLocalPath
  else
    put "/" & pLocalPath into pLocalPath
  end if
  
  # PREPARE pRemotePath
  replace "\" with "/" in pRemotePath
  put rigTrim(pRemotePath, "/") into pRemotePath
  
  put TRUE into sFtpA["multipleUploads"]
  
  _rigFtpPrepareTransfer
  
  put sFtpA["connID"] into tConnID
  put sFtpA["flavor"] & "://" & sFtpA["settings"]["hostname"] into sFtpA["request"][tConnID]
  put sFtpA["request"][tConnID] into sFtpA["request"]["transactionRoot"]
  
  _rigFtpMirrorFilesFolders pLocalPath, pRemotePath
  
  put FALSE into sFtpA["multipleUploads"]
  
  if sFtpA["asyncRequest"] <> TRUE then
    rigLogMessage "info", "All synchronous uploads done."
  end if
  
  if sFtpA["noErrors"] is FALSE then
    return FALSE
  end if
  
  return sFtpA["transferResult"]
end rigFtpMirror





/*----------------------------------------------------------------------
--| COMMAND _rigFtpMirrorFilesFolders
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2017-09-18
--| Last Mod: 2019-01-12
--| Requires: _rigFtpCreateAllMissingDirs, rigFtpUpload
--|
--| Summary: Uploads multiple files and / or folders.
--| 
--| Format:  _rigFTPMirrorFilesFolders param1, param2
--|
--| Parameters: string <pLocalPath>, string <pRemotePath>
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigFtpMirrorFilesFolders pLocalPath pRemotePath
  local tNumUploadsToProcess, tID, tIDsuffix, tFolders
  local tSubPath, tCurrentFolder, tCurrentRemoteFolder, tNumUploadsToProcesss
  local tFilePath, tRemoteFilePath
  
  # CREATE MISSING DIRECTORIES
  # AUTOMATIC CREATION OF MISSING DIRECTORIES SEEMS
  # NOT TO WORK RELIABLE WITH ASYNCHRONOUS REQUESTS!!!!
  if sFtpA["asyncRequest"] is TRUE then
    put FALSE into sFtpA["asyncRequest"]

    _rigFtpCreateAllMissingDirs pLocalPath, pRemotePath
    
    put TRUE into sFtpA["asyncRequest"]

    tsNetSetStatusCallBack ""
  end if
  #

  if sFtpA["asyncRequest"] then
    put 0 into sFtpA["numUploadsToProcess"]
    put 0 into tNumUploadsToProcess
    put sFtpA["connID"] into tID
    put 0 into tIDsuffix
  end if

  put return into tFolders

  # GET FILES AND FOLDERS TO BE PROCESSED
  repeat until tFolders = empty
    add 1 to tIDsuffix

    put line 1 of tFolders into tSubPath
    delete line 1 of tFolders

    if tSubPath <> empty then
      put pLocalPath & tSubPath into tCurrentFolder
      put pRemotePath & tSubPath into tCurrentRemoteFolder
    else
      put pLocalPath into tCurrentFolder
      put pRemotePath into tCurrentRemoteFolder
    end if

    repeat for each line tFolder in folders(tCurrentFolder)
      if char 1 of tFolder is "." then
        next repeat
      end if

      put tSubPath & "/" & tFolder & return before tFolders
    end repeat

    repeat for each line tFile in files(tCurrentFolder)
      if tFile <> ".DS_Store" then
        # CREATE NEW CONNECTION ID, COUNT NUMBER OF FILES TO BE UPLOADED
        # AND UPLOAD FILE
        if sFtpA["asyncRequest"] then
          add 1 to tIDsuffix
          put tID & tIDsuffix into sFtpA["connID"]
          add 1 to tNumUploadsToProcesss
        end if

        put tCurrentFolder & "/" & tFile into tFilePath
        put tCurrentRemoteFolder & "/" & tFile into tRemoteFilePath

        rigFtpUpload tFilePath, tRemoteFilePath, "", TRUE
      end if -- if tFile <> ".DS_Store"
    end repeat
  end repeat

  # STORE TOTAL NUMBER OF FILES TO BE PROCESSED TO BE ABLE TO CHECK IF ALL UPLOADS ARE DONE
  if sFtpA["asyncRequest"] is TRUE then
    put tNumUploadsToProcesss into sFtpA["numUploadsToProcess"]
  end if
end _rigFtpMirrorFilesFolders






/*----------------------------------------------------------------------
--| COMMAND _rigFtpCreateAllMissingDirs
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2017-09-19
--| Last Mod: 2019-01-12
--| Requires: _rigFtpDoRawCommands
--|
--| Summary: Recursively reads all sub-folders of a local folder and creates a mirror on the remote server.
--|            Note: Asynchronous SFTP commands and SFTP using public key authentication
--|            is only supported in the LC Business Edition.
--| 
--| Format:  _rigFtpCreateAllMissingDirs param1, param2
--|
--| Parameters: string <pLocalPath>, string <pRemotePath>
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigFtpCreateAllMissingDirs pLocalPath pRemotePath
  local tCommand, tFolders, tSubPath
  local tCurrentFolder
  
  # AUTOMATIC CREATION OF MISSING DIRECTORIES SEEMS
  # NOT TO WORK RELIABLY WITH ASYNCHRONOUS REQUESTS.
  # SO, BEFORE UPLOADING A DIRECTORY CREATE ALL THOSE
  # MISSING DIRECTORIES ON THE REMOTE SERVER

  # CREATE ROOT FOLDER
  if pRemotePath <> empty then
    put "MKD" && pRemotePath into tCommand
    _rigFtpDoRawCommands tCommand
  end if

  # CREATE SUB-FOLDERS
  put return into tFolders
  repeat until tFolders = empty
    put line 1 of tFolders into tSubPath
    delete line 1 of tFolders

    if tSubPath <> empty then
      put pLocalPath & tSubPath into tCurrentFolder
    else
      put pLocalPath into tCurrentFolder
    end if

    repeat for each line tFolder in folders(tCurrentFolder)
      if char 1 of tFolder is "." then
        next repeat
      end if

      put tSubPath & "/" & tFolder & return before tFolders

      put "MKD" && pRemotePath & "/" & (char 2 to -1 of line 1 of tFolders) into tCommand
      _rigFtpDoRawCommands tCommand
    end repeat
  end repeat
end _rigFtpCreateAllMissingDirs







/*----------------------------------------------------------------------
--| COMMAND rigFtpDownload
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-12-15
--| Last Mod: 2016-12-15
--| Requires: rigTrim(), _rigFtpPrepareTransfer, _rigFtpCheckResult,
--|            _rigFtpTransferComplete
--|
--| Summary: Download a file from a remote server to the local server.
--|            Note: SFTP needs LC Business Edition.
--| 
--| Format:  rigFtpDownload param1, param2
--|
--| Parameters: string <pRemotePath>, string <pLocalPath>
--|
--| Return: mixed
----------------------------------------------------------------------*/

command rigFtpDownload pRemotePath pLocalPath
  local tConnID, tEmptyHeaderVar, tStatus, tResult, tOutHeaders
  local tBytes
  
  replace "\" with "/" in pRemotePath
  put rigTrim(pRemotePath, "/") into pRemotePath
  
  # RESET RESULT DATA OF PREVIOUS REQUESTS
  put "" into sFtpA["transferResult"]
  
  _rigFtpPrepareTransfer
  
  put "download" into sFtpA["transferType"]
  
  put sFtpA["connID"] into tConnID
  put sFtpA["flavor"] & "://" & sFtpA["settings"]["hostname"] into sFtpA["request"][tConnID]

  put empty into tEmptyHeaderVar
  
  if sFtpA["asyncRequest"] is FALSE then
		# SYNCHRONOUS REQUEST
		if tsNetIsSyncBlocked() is FALSE then
			put empty into tStatus
			put empty into tResult
			put tsNetGetFileSync(pLocalPath, sFtpA["request"][tConnID] & "/" & pRemotePath, tEmptyHeaderVar, tOutHeaders, tBytes, sFtpA["settings"]) into tResult
			_rigFtpCheckResult tResult, "tsNetGetFileSync", "ftp_unable_to_download"

			_rigFtpTransferComplete tBytes, tStatus, tResult
		else -- if tsNetIsSyncBlocked() is FALSE
			_rigFtpCheckResult "A synchronous network call is already in progress.", "tsNetGetSync", "ftp_sync_blocked"
		end if -- if tsNetIsSyncBlocked() is FALSE

  else -- if sFtpA["asyncRequest"] is FALSE
    # ASYNCHRONOUS REQUEST
    put tsNetGetFile(tConnID, pLocalPath, sFtpA["request"][tConnID] & "/" & pRemotePath, tEmptyHeaderVar, "_rigFtpCallback", sFtpA["settings"]) into tResult
    _rigFtpCheckResult tResult, "tsNetGetFile", "ftp_unable_to_download"

  end if -- if sFtpA["asyncRequest"] is FALSE
  
  if sFtpA["noErrors"] is FALSE then
    return FALSE
  end if
  
  return sFtpA["transferResult"]
end rigFtpDownload







/*----------------------------------------------------------------------
--| COMMAND rigFtpRenameMove
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-12-15
--| Last Mod: 2016-12-15
--| Requires: rigTrim(), _rigFtpPrepareTransfer, _rigFtpDoRawCommands
--|
--| Summary: Rename or move a file.
--|            Note: Asynchronous SFTP and SFTP using public key authentication need LC Business Edition.
--| 
--| Format:  rigFtpRenameMove param1, param2[, param3]
--|
--| Parameters: string <pOldFile>, string <pNewFile>, bool <pMissingDirs> (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

command rigFtpRenameMove pOldFile pNewFile pMissingDirs
  local tMissingDir, tCommandsList
  
  if (pMissingDirs is empty) or (pMissingDirs is not a boolean) then
    put FALSE into pMissingDirs
  end if

  replace "\" with "/" in pOldFile
  replace "\" with "/" in pNewFile
  put rigTrim(pOldFile, "/") into pOldFile
  put rigTrim(pNewFile, "/") into pNewFile

  _rigFtpPrepareTransfer
  
  if pMissingDirs is TRUE then
    set the itemDel to "/"
    put item 1 to -2 of pNewFile into tMissingDir
  end if

  if sFtpA["flavor"] is "sftp" then
    # SFTP
    if pMissingDirs is TRUE then
      put "mkdir" && tMissingDir & return & "rename" && pOldFile && pNewFile into tCommandsList
    else
      put "rename" && pOldFile && pNewFile into tCommandsList
    end if
  else --   if sFtpA["flavor"] is "sftp"
    # FTP / FTPS
    if pMissingDirs is TRUE then
      put "MKD" && tMissingDir & return & "RNFR" && pOldFile & return & "RNTO" && pNewFile into tCommandsList
    else
      put "RNFR" && pOldFile & return & "RNTO" && pNewFile into tCommandsList
    end if
  end if --   if sFtpA["flavor"] is "sftp"
  
  _rigFtpDoRawCommands tCommandsList

  if sFtpA["noErrors"] is FALSE then
    return FALSE
  end if
  
  return sFtpA["transferResult"]
end rigFtpRenameMove






/*----------------------------------------------------------------------
--| COMMAND rigFtpDeleteFile
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2017-01-05
--| Last Mod: 2017-01-05
--| Requires: rigTrim(), _rigFtpPrepareTransfer, _rigFtpDoRawCommands
--|
--| Summary: Delete a file.
--|            Note: Asynchronous SFTP and SFTP using public key authentication need LC Business Edition.
--| 
--| Format:  rigFtpDeleteFile param1[, param2]
--|
--| Parameters: string <pPath>
--|
--| Return: mixed
----------------------------------------------------------------------*/

command rigFtpDeleteFile pPath
  local tCommandsList
  
  replace "\" with "/" in pPath
  put rigTrim(pPath, "/") into pPath

  _rigFtpPrepareTransfer
  
  if sFtpA["flavor"] is "sftp" then
    # SFTP
    put "rm" && pPath into tCommandsList
  else
    # FTP / FTPS
    put "DELE" && pPath into tCommandsList
  end if -- if sFtpA["flavor"] is "sftp"
	
	_rigFtpDoRawCommands tCommandsList

  if sFtpA["noErrors"] is FALSE then
    return FALSE
  end if
  
  return sFtpA["transferResult"]
end rigFtpDeleteFile





/*----------------------------------------------------------------------
--| COMMAND rigFtpDeleteFolder
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2017-09-11
--| Last Mod: 2017-09-11
--| Requires: rigTrim(), _rigFtpPrepareTransfer, _rigFtpDeleteFilesFolders
--|
--| Summary: Delete a folder and / or sub-folders.
--|            Note: SFTP using public key authentication needs LC Business Edition.
--| 
--| Format:  rigFtpDeleteFolder param1[, param2][, param3]
--|
--| Parameters: string <pPath>, bool <pRecursive> delete folder recursively (optional),
--|               bool <pPurgeOnly> empty folder without deleting it (optional)
--|
--| Return: boolean
----------------------------------------------------------------------*/

command rigFtpDeleteFolder pPath pRecursive pPurgeOnly
  local tNoReuse, tAsyncRequest
  
  # THIS COMMAND IS IMPLEMENTED AS SYNCHRONOUS REQUEST ONLY!!!!!!!!!!!!!!!!
  # THE INITIAL CONNECTION NEEDS TO BE REUSED
  put sFtpA["settings"]["no_reuse"] into tNoReuse
  put FALSE into sFtpA["settings"]["no_reuse"]
  
  put sFtpA["asyncRequest"] into tAsyncRequest
  put FALSE into sFtpA["asyncRequest"]
  
  replace "\" with "/" in pPath
  put rigTrim(pPath, "/") into pPath

  _rigFtpPrepareTransfer
  
  _rigFtpDeleteFilesFolders pPath, pRecursive, pPurgeOnly
  
  # RESET VARS
  put tAsyncRequest into sFtpA["asyncRequest"]
  put tNoReuse into sFtpA["settings"]["no_reuse"]
  
  return sFtpA["noErrors"]
end rigFtpDeleteFolder






/*----------------------------------------------------------------------
--| COMMAND _rigFtpDeleteFilesFolders
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2017-09-11
--| Last Mod: 2017-09-11
--| Requires: rigFtpListFiles, rigFtpChangeDir, _rigFtpDoRawCommands
--|
--| Summary: Delete multiple files and / or folders.
--|            Note: SFTP using public key authentication needs LC Business Edition.
--| 
--| Format:  _rigFtpDeleteFilesFolders param1
--|
--| Parameters: string <pPath>, bool <pRecursive> delete folder recursively (optional),
--|               bool <pPurgeOnly> empty folder without deleting it (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigFtpDeleteFilesFolders pPath pRecursive pPurgeOnly
  local tDele, tRmd, tList, tSubList, tFolders, tSubPath, tCurrentFolder
  local tDirectoryListing, tDirectories, tFiles, tFilePath, tDelFilesCommands
  local tNumFolders, tDelFoldersCommands
  
  if (pRecursive is empty) or (pRecursive is not a boolean) then
    put FALSE into pRecursive
  end if

  if (pPurgeOnly is empty) or (pPurgeOnly is not a boolean) then
    put FALSE into pPurgeOnly
  end if

  # SET RAW COMMANDS
  if sFtpA["flavor"] is "sftp" then
	 # SFTP
	 put "rm" into tDele
	 put "rmdir" into tRmd
  else
	 # FTP / FTPS
	 put "DELE" into tDele
	 put "RMD" into tRmd
  end if -- if sFtpA["flavor"] is "sftp"

  put empty into tList
  put empty into tSubList

  put return into tFolders

  repeat until tFolders = empty
    put line 1 of tFolders into tSubPath
    delete line 1 of tFolders

    if tSubPath <> empty then
      put pPath & "/" & tSubPath & "/" into tCurrentFolder
    else
      put pPath & "/" into tCurrentFolder
    end if

    rigFtpListFiles tCurrentFolder, FALSE, TRUE
    put the result into tDirectoryListing

    filter lines of tDirectoryListing with regex pattern "^d.*[^.]$" into tDirectories
    filter lines of tDirectoryListing with regex pattern "^[^d].*[^\n\r]$" into tFiles

    if tSubPath <> empty then
      put pPath & "/" & tSubPath & return after tSubList
    else
      put pPath & return after tSubList
    end if

    # GET LIST OF FOLDERS IN CURRENT FOLDER
    if pRecursive then
      repeat for each line tFolder in tDirectories

        # THERE MAY BE EMPTY LINES
        if the number of chars of tFolder > 1 then
          if tSubPath <> empty then
            put tSubPath & "/" & (word -1 of tFolder) & return after tFolders
          else
            put (word -1 of tFolder) & return after tFolders
          end if
        end if -- if the number of chars of tFolder > 1
      end repeat
    end if

    # DELETE ALL FILES IN CURRENT FOLDER
    repeat for each line tFile in tFiles
      if the number of chars of tFile > 1 then
        if tSubPath <> empty then
          put pPath & "/" & tSubPath & "/" & (word -1 of tFile) into tFilePath
        else
          put pPath & "/" & (word -1 of tFile) into tFilePath
        end if
      end if -- if the number of chars of tFile > 1

      if sFtpA["flavor"] is "sftp" then
        # SFTP (HAS NO CONCEPT OF "CURRENT DIRECTORY", SO WE USE THE FILE PATH)
		    put tDele && tFilePath & return after tDelFilesCommands
      else
        # FTP / FTPS, USE FILE NAME
        put tDele && (word -1 of tFile) & return after tDelFilesCommands
      end if -- if sFtpA["flavor"] is "sftp"
    end repeat

    delete char -1 of tDelFilesCommands

    if tDelFilesCommands <> empty then
      if sFtpA["flavor"] is not "sftp" then
        # FTP / FTPS ONLY
        rigFtpChangeDir tCurrentFolder
      end if
      _rigFtpDoRawCommands tDelFilesCommands

      # RESET RAW COMMANDS LIST
      put empty into tDelFilesCommands
    end if -- if tDelFilesCommands <> empty
  end repeat -- repeat until tFolders = empty

  # LASTLY REMOVE FOLDER AND ALL NESTED FOLDERS
  delete char -1 of tSubList
  put the number of lines of tSubList into tNumFolders
  if sFtpA["flavor"] is not "sftp" then
    # FTP / FTPS ONLY
    put "CWD /" & return after tDelFoldersCommands
  end if

  repeat with d = tNumFolders down to 1
    put tRmd && (line d of tSubList) & return after tDelFoldersCommands
  end repeat

  delete char -1 of tDelFoldersCommands

  if pPurgeOnly then
    if pRecursive then
      # REMOVE ROOT FOLDER FROM FOLDERS LIST
      put line 1 to -2 of tDelFoldersCommands into tDelFoldersCommands
    else -- if pRecursive
      put empty into tDelFoldersCommands
    end if -- if pRecursive

  else -- if pPurgeOnly
    if (pRecursive is FALSE) and (tDirectories <> empty) then
      # FOLDER DELETION NOT POSSIBLE BECAUSE IT CONTAINS OTHER FOLDERS
      put empty into tDelFoldersCommands
    end if
  end if -- if pPurgeOnly

  if tDelFoldersCommands <> empty then
    _rigFtpDoRawCommands tDelFoldersCommands
  end if
end _rigFtpDeleteFilesFolders






/*----------------------------------------------------------------------
--| COMMAND rigFtpCreateFolder
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2017-09-12
--| Last Mod: 2017-09-12
--| Requires: rigTrim(), _rigFtpDoRawCommands
--|
--| Summary: Create a directory on the server.
--|            Note: Asynchronous SFTP and SFTP using public key authentication needs LC Business Edition.
--| 
--| Format:  rigFtpCreateFolder param1[, param2]
--|
--| Parameters: string <pPath> path to folder to create, integer (octal) <pPermissions> (optional) 
--|
--| Return: boolean
----------------------------------------------------------------------*/

command rigFtpCreateFolder pPath pPermissions
  local tCommandsList
  
  replace "\" with "/" in pPath
  put rigTrim(pPath, "/") into pPath
  
  if pPermissions <> empty then
    if pPermissions is not an integer then
      put empty into pPermissions
    end if   
  end if
  
  if pPermissions is empty then
    if sFtpA["flavor"] is "sftp" then
      put "mkdir" && pPath into tCommandsList
    else
      put "MKD" && pPath into tCommandsList
    end if
    
  else -- if pPermissions is empty
    if sFtpA["flavor"] is "sftp" then
      put "mkdir" && pPath & return & "chmod" && pPermissions && pPath into tCommandsList
    else
      put "MKD" && pPath & return & "SITE CHMOD" && pPermissions && pPath into tCommandsList
    end if
  end if -- if pPermissions is empty
  
  _rigFtpPrepareTransfer
  
  _rigFtpDoRawCommands tCommandsList
  
  return sFtpA["noErrors"]
end rigFtpCreateFolder






/*----------------------------------------------------------------------
--| COMMAND rigFtpSetPermissions
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2017-09-13
--| Last Mod: 2017-09-13
--| Requires: rigTrim(), _rigFtpDoRawCommands
--|
--| Summary: Set file / folder permissions.
--|            Note: Asynchronous SFTP and SFTP using public key authentication need LC Business Edition.
--| 
--| Format:  rigFtpSetPermissions param1, param2[, param3]
--|
--| Parameters: string <pPath>, integer (octal) <pPermissions>, bool <pTransferPrepared> (internal)
--|
--| Return: boolean
----------------------------------------------------------------------*/

command rigFtpSetPermissions pPath pPermissions pTransferPrepared
  local tCommandsList
  
  replace "\" with "/" in pPath
  put rigTrim(pPath, "/") into pPath
  
  if pPermissions is not an integer then
    put sFtpA["settings"]["defaultPermissions"] into pPermissions  
  end if
	
	if pTransferPrepared <> TRUE then
		_rigFtpPrepareTransfer
	end if
  
  if sFtpA["flavor"] is "sftp" then
    put "chmod" && pPermissions && pPath into tCommandsList
  else
    put "SITE CHMOD" && pPermissions && pPath into tCommandsList
  end if
  
  _rigFtpDoRawCommands tCommandsList
  
  return sFtpA["noErrors"]
end rigFtpSetPermissions





/*----------------------------------------------------------------------
--| COMMAND rigFtpChangeDir
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2017-09-14
--| Last Mod: 2017-09-14
--| Requires: rigTrim(), _rigFtpDoRawCommands
--|
--| Summary: Change the current working directory to the specified path, FTP and FTPS only.
--| 
--| Format:  rigFtpChangeDir param1
--|
--| Parameters: string <pPath>
--|
--| Return: boolean
----------------------------------------------------------------------*/

command rigFtpChangeDir pPath
  local tCommandsList
  
  replace "\" with "/" in pPath
  put rigTrim(pPath, "/") into pPath
  
  # FTP / FTPS, THERE IS NO ACTUAL SFTP COMMAND TO CHANGE
  # A REMOTE DIRECTORY AS SFTP IS NOT STATEFUL LIKE FTP / FTPS
  # AND HAS NO CONCEPT OF "CURRENT DIRECTORY"
  put "CWD" && pPath into tCommandsList
  
  _rigFtpDoRawCommands tCommandsList
  
  return sFtpA["noErrors"]
end rigFtpChangeDir






/*----------------------------------------------------------------------
--| COMMAND _rigFtpDoRawCommands
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2017-09-12
--| Last Mod: 2017-09-12
--| Requires: _rigFtpCheckResult, _rigFtpTransferComplete
--|
--| Summary: Execute raw FTP commands.
--|            Note: Asynchronous SFTP commands and SFTP commands using public key authentication
--|            are only supported in the LC Business Edition.
--| 
--| Format:  _rigFtpDoRawCommands param1
--|
--| Parameters: string <pCommandslist> list of raw FTP commands
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigFtpDoRawCommands pCommandslist
  local tCommand, tConnID, tErrorLangKey, tStatus, tBytes, tResult
  
  put word 1 of pCommandslist into tCommand
  
  # RESET RESULT DATA OF PREVIOUS REQUESTS
	if sFtpA["setFilePermissions"] <> TRUE then
  	put "" into sFtpA["transferResult"]
	else
		# KEEP TRANSFER RESULT OF UPLOAD
		put FALSE into sFtpA["setFilePermissions"]
	end if
  
  put sFtpA["connID"] into tConnID
  put sFtpA["flavor"] & "://" & sFtpA["settings"]["hostname"] into sFtpA["request"][tConnID]
  
  # GET ERROR KEY IN LANGUAGE ARRAY
  switch
    case (tCommand is "DELE") or (tCommand is "rm")
      put "ftp_unable_to_delete" into tErrorLangKey
    break
    
    case (tCommand is "MKD") or (tCommand is "mkdir")
      put "ftp_unable_to_makdir" into tErrorLangKey
    break
    
    case (tCommand is "RNFR") or (tCommand is "rename")
      put "ftp_unable_to_rename" into tErrorLangKey
    break
    
    case (tCommand is "SITE") or (tCommand is "chmod")
      put "ftp_unable_to_chmod" into tErrorLangKey
    break
    
    case (tCommand is "CWD") or (tCommand is "cd")
      put "ftp_unable_to_changedir" into tErrorLangKey
  end switch
  #
  
  if sFtpA["asyncRequest"] is FALSE then
    # SYNCHRONOUS REQUEST
		if tsNetIsSyncBlocked() is FALSE then
	    put tsNetSendCmdSync(sFtpA["request"][tConnID], pCommandsList, tStatus, tBytes, sFtpA["settings"]) into tResult
	    if char 1 to 9 of tStatus is "tsneterr:" then
	      _rigFtpCheckResult tResult, "tsNetSendCmdSync", tErrorLangKey, TRUE
	    end if

	    _rigFtpTransferComplete  "", tStatus, tResult
		else -- if tsNetIsSyncBlocked() is FALSE
			_rigFtpCheckResult "A synchronous network call is already in progress.", "tsNetGetSync", "ftp_sync_blocked"
		end if -- if tsNetIsSyncBlocked() is FALSE
     
  else -- if sFtpA["asyncRequest"] is FALSE
		# ASYNCHRONOUS REQUEST
		put tsNetSendCmd(tConnID, sFtpA["request"][tConnID], pCommandsList, "_rigFtpCallback", sFtpA["settings"]) into tResult
		_rigFtpCheckResult tResult, "tsNetSendCmd", tErrorLangKey
  end if -- if sFtpA["asyncRequest"] is FALSE
end _rigFtpDoRawCommands








/*----------------------------------------------------------------------
--| COMMAND _rigFtpCheckResult
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2017-01-08
--| Last Mod: 2017-01-08
--| Requires: rigLogMessage, rigFtpError, rigFtpClose
--|
--| Summary: Check if result of request contains an error.
--| 
--| Format:  _rigFtpCheckResult param1, param2, param3[, param4]
--|
--| Parameters: string <pResult>, string <pHandler>, string <pMessageName>, bool <pError> (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigFtpCheckResult pResult pHandler pMessageName pError
  if (char 1 to 9 of pResult is "tsneterr:") or (pError is TRUE) then
    rigLogMessage "error", pHandler && pResult    
    rigFtpError pMessageName
  end if
  
  if sFtpA["asyncRequest"] then
    rigFtpClose sFtpA["connID"]
  end if
end _rigFtpCheckResult









/*----------------------------------------------------------------------
--| COMMAND _rigFtpPrepareTransfer
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-12-14
--| Last Mod: 2016-12-14
--| Requires: --
--|
--| Summary: Initiate preparatory measures.
--| 
--| Format:  _rigFtpPrepareTransfer
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigFtpPrepareTransfer
  if sFtpA["debug"] is TRUE then
    tsNetSetDebugCallback "_rigFtpDebugCallback"
    tsNetSetStatusCallBack "_rigFtpStatusCallback"
  end if

-- 	if (sFtpA["secure"] is TRUE) and (sFtpA["flavor"] <> "sftp") then
--     # ENABLE TLS FOR EXPLICIT FTPS
--     put TRUE into sFtpA["settings"]["use_ssl"]
--     tsNetVerifySSLPeer sFtpA["verifySSL"]
--   end if

  # TLS FOR EXPLICIT FTPS
  if (sFtpA["settings"]["use_ssl"] is TRUE) and (sFtpA["flavor"] <> "sftp") then
    tsNetVerifySSLPeer sFtpA["verifySSL"]
  end if
end _rigFtpPrepareTransfer







/*----------------------------------------------------------------------
--| COMMAND _rigFtpCallback
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-10-13
--| Last Mod: 2016-10-13
--| Requires: _rigFtpTransferComplete
--|
--| Summary: Transfer callback handler.
--| 
--| Format:  _rigFtpCallback param1, param2, param3, param4
--|
--| Parameters: string <pConnID>, integer <pStatus>, integer <pNumBytes>, mixed <pResult>
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigFtpCallback pConnID pStatus pNumBytes pResult
  local tError, tData, tAllTransfersDone
  
  if pResult is not 0 then
    put tsNetRetrError(pConnID) into tError
    put "Error:" && tError && "while retrieving data for entry" && pConnID & return after sFtpA["callbackError"]
  else
     
  put tsNetRetrData(pConnID, tError) into tData
   
    if tError is not empty then
      # THIS SHOULD ONLY HAPPEN IF THE EXTERNAL RAN OUT OF MEMORY RETRIEVING THE DATA,
      # OR THE CONNECTION WAS ALREADY CLOSED
      put "Received FTP response code" && pStatus && "while retreiving data for entry" && pConnID & return after sFtpA["callbackError"]
    end if
  end if
   
  put tData into sFtpA["response"][pConnID]
  
  # CHECK IF ALL UPLOADS ARE DONE
  if sFtpA["multipleUploads"] then
    if (sFtpA["asyncRequest"]) and ((pStatus is 226) or (pStatus is 221)) then
      put sFtpA["numUploadsToProcess"] - 1 into sFtpA["numUploadsToProcess"]

      if sFtpA["numUploadsToProcess"] is 0 then
        put TRUE into tAllTransfersDone
      end if
    end if
  end if

  _rigFtpTransferComplete pNumBytes, pStatus, pResult, pConnID, tAllTransfersDone
end _rigFtpCallback






/*----------------------------------------------------------------------
--| COMMAND _rigFtpTransferComplete
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-10-13
--| Last Mod: 2016-10-13
--| Requires: rigFtpClose, rigLogMessage
--|
--| Summary: Process the transfer result.
--| 
--| Format:  _rigFtpTransferComplete param1[, param2][, param3][, param4][, param5]
--|
--| Parameters: integer <pNumBytes>, string <pStatus> (optional), string <pResult> (optional),
--|               string <pConnID> (optional), bool <pAllTransfersDone> (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigFtpTransferComplete pNumBytes pStatus pResult pConnID pAllTransfersDone
  local tKey, tResults, tPermissions
  
  if pConnID <> empty then
    rigFtpClose pConnID
  end if
  
	if sFtpA["callbackError"] is empty then 
		# IF NO ERROR OCCURRED STORE THE RESULTS OF THE TRANSFERS
		repeat for each key tKey in sFtpA["response"]
			put sFtpA["response"][tKey] & cr after tResults
		end repeat
    
		# RESULT ITEMS DELIMITER
		put numToCodepoint(0) after tResults
    
		if pNumBytes <> empty then
			put "Transfer complete. Transfered" && pNumBytes && "bytes." & cr after tResults
		end if
    
		if pStatus <> empty then
			put "Status:" && pStatus && "Result:" && pResult & cr after tResults
		end if
    
		put tResults after sFtpA["transferResult"]
		
		# CHECK IF PERMISSIONS SHOULD BE SET FOR UPLOADED FILES
		if sFtpA["filePermissions"] <> empty then
			put sFtpA["filePermissions"] into tPermissions
			put empty into sFtpA["filePermissions"]
			put TRUE into sFtpA["setFilePermissions"]
			rigFtpSetPermissions sFtpA["remotePath"], tPermissions, TRUE
		end if -- if sFtpA["filePermissions"] <> empty
		#
		
	else
    rigLogMessage "error", sFtpA["callbackError"] 
  end if -- if sFtpA["callbackError"] is empty
  
  if pAllTransfersDone is TRUE then
    rigLogMessage "info", "All asynchronous uploads done."
  end if
end _rigFtpTransferComplete





/*----------------------------------------------------------------------
--| COMMAND _rigFtpStatusCallback
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-12-14
--| Last Mod: 2016-12-14
--| Requires: --
--|
--| Summary: Get status messages.
--| 
--| Format:  _rigFtpStatusCallback param1, param2, param3, param4, param5, param6
--|
--| Parameters: string <pConnID>, integer <pStatus>, integer <pNumBytesDownloaded>, integer <pDownloadTotalNumBytes>,
--|               integer <pNumBytesUploaded>, integer <pUploadTotalNumBytes>
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigFtpStatusCallback pConnID pStatus pNumBytesDownloaded pDownloadTotalNumBytes pNumBytesUploaded pUploadTotalNumBytes
  switch sFtpA["transferType"]
    case "upload"
      put "ID:" && pConnID && "status:" && pStatus && "NumBytesUploaded:" && pNumBytesUploaded && "UploadTotalNumBytes:" && pUploadTotalNumBytes & cr after sFtpA["statusMsg"]
    break
  
    case "download"
      put "ID:" && pConnID && "status:" && pStatus && "NumBytesDownloaded:" && pNumBytesDownloaded && "DownloadTotalNumBytes:" && pDownloadTotalNumBytes & cr after sFtpA["statusMsg"]
    break
    
  default
      put "ID:" && pConnID && "status:" && pStatus & cr after sFtpA["statusMsg"]
  end switch
end _rigFtpStatusCallback






/*----------------------------------------------------------------------
--| COMMAND _rigFtpDebugCallback
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-10-13
--| Last Mod: 2016-10-13
--| Requires: --
--|
--| Summary: Get connection messages.
--| 
--| Format:  _rigFtpDebugCallback param1, param2
--|
--| Parameters: string <pID>, string <pMsg>
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigFtpDebugCallback pID pMsg
  put pMsg after sFtpA["debugMsg"]
end _rigFtpDebugCallback








/*----------------------------------------------------------------------
--| COMMAND rigFtpClose
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-10-13
--| Last Mod: 2016-10-13
--| Requires: rigLogMessage, rigFtpError
--|
--| Summary: Remove the specified connection from memory.
--| 
--| Format:  rigFtpClose param1
--|
--| Parameters: string <pConnID>
--|
--| Return: boolean
----------------------------------------------------------------------*/

command rigFtpClose pConnID
  local tConnID, tResult
  
	if pConnID is empty then
		put sFtpA["connID"] into tConnID
	else
		put pConnID into tConnID
	end if
	
  tsNetCloseConn tConnID
  
  put the result into tResult
	
	if tResult is empty then
		return TRUE
	end if
  
  if char 1 to 9 of tResult is "tsneterr:" then
    rigLogMessage "error", "Unable to remove the connection from memory." && tResult   
    rigFtpError "ftp_unable_to_close"
  end if
	
	return FALSE
end rigFtpClose





/*----------------------------------------------------------------------
--| FUNCTION rigFtpGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-02
--| Last Mod: 2019-01-02
--| Requires: --
--|
--| Summary: Get ftp array variable value.
--| 
--| Format:  rigFtpGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigFtpGet pWhat
  if pWhat is among the items of sFtpSettingsItems then
    return sFtpA["settings"][pWhat]
  else
    return sFtpA[pWhat]
  end if
   
  return empty
end rigFtpGet




/*----------------------------------------------------------------------
--| COMMAND rigFtpSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-02
--| Last Mod: 2019-01-02
--| Requires: --
--|
--| Summary: Setter for ftp variables.
--| 
--| Format:  rigFtpSet param1, param2
--|
--| Parameters: string <pKey> sFtpA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigFtpSet pKey pVal
  if pKey is among the items of sFtpSettingsItems then
    put pVal into sFtpA["settings"][pKey]
  else
    put pVal into sFtpA[pKey]
  end if
end rigFtpSet








--| END OF Ftp.livecodescript
--| Location:  ./system/libraries/Ftp.livecodescript
----------------------------------------------------------------------