script "Upload"

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
# revIgniter File Uploading Library
#
#
# @package		revIgniter
# @subpackage	Libraries
# @category		Uploads
# @author			rabit@revigniter.com
# @link				https://revigniter.com/userGuide/libraries/file_uploading.html
##

## ------------------------------------------------------------------------




global gRigA

local sFileTemp, sOrigName, sFileType, sFileSize, sFileExt
local sImageWidth, sImageHeight, sImageType, sImageSizeStr, sErrorMsg, sMimes
local sClientName, sFileNameOverride, sValidSetHandlers, sUplaodDataA, sUploadErrorsNum
local sMaxUploadFilesExceeded, sStackInUse, sInitialVarKeys, sUploadA -- array keys are: maxSize, maxWidth, maxHeight, maxFilename, maxUploadFiles,
                                                                                -- overwrite, encryptName, isImage, removeSpaces, xssClean, tempPrefix, fileName,
                                                                                -- allowedTypes, uploadPath, fileName, overwrite, encryptName, removeSpaces





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-26
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
        rigLogMessage "debug", "Upload Library Loaded"
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
  put 0 into sUploadA["maxSize"]
  put 0 into sUploadA["maxWidth"]
  put 0 into sUploadA["maxHeight"]
  put 0 into sUploadA["maxFilename"]
  put 0 into sUploadA["maxUploadFiles"]
  put FALSE into sUploadA["overwrite"]
  put FALSE into sUploadA["encryptName"]
  put FALSE into sUploadA["isImage"]
  put TRUE into sUploadA["removeSpaces"]
  put FALSE into sUploadA["xssClean"]
  put "temp_file_" into sUploadA["tempPrefix"]
  put "_rigSet_uploadPath,_rigSet_allowedTypes,_rigSet_maxSize,_rigSet_maxWidth,_rigSet_maxHeight,_rigSet_maxFilename,_rigSet_maxUploadFiles,_rigSet_xssClean" into sValidSetHandlers

  put "fileName,overwrite,encryptName,removeSpaces" into sInitialVarKeys
end _rigSetDefaultValues





/*----------------------------------------------------------------------
--| COMMAND rigRunInitialUploadConfig
--|
--| Author: rabit
--| Version:  1.1
--| Created: 30-08-2011
--| Last Mod: 22-12-2014
--| Requires: _rigInitializeUpload
--|
--| Summary: Run initial configuration procedures.
--|
--| Format:  rigRunInitialUploadConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialUploadConfig pConfig
  local tConfig

	put pConfig into tConfig

	if tConfig is not an array then
		if tConfig is not empty then
			split tConfig using numToCodepoint(1) and numToCodepoint(2)
		end if
	end if

	if tConfig is an array then
		_rigInitializeUpload tConfig
	end if
end rigRunInitialUploadConfig





/*----------------------------------------------------------------------
--| COMMAND _rigInitializeUpload
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-08-2011
--| Last Mod: 30-08-2011
--| Requires: _rigSetInitialUploadValue
--|
--| Summary: Initialize preferences.
--|
--| Format:  _rigInitializeUpload param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigInitializeUpload pConfig
  local tKey, tVal, tHandler

	if pConfig is an array then
		repeat for each key tKey in pConfig
			put pConfig[tKey] into tVal

			## SET VARIABLE WITH NAME TKEY
			#
			put "_rigSet_" & tKey into tHandler
			if tHandler is among the items of sValidSetHandlers then
				do tHandler && quote & tVal & quote
			else
				_rigSetInitialUploadValue tKey, tVal
			end if

		end repeat

		# IF A FileName WAS PROVIDED IN pConfig, USE IT INSTEAD OF
		# THE USER INPUT SUPPLIED FILE NAME FOR ALL UPLOADS UNTIL
		# INITIALIZED AGAIN
		put sUploadA["fileName"] into sFileNameOverride
	end if
end _rigInitializeUpload






/*----------------------------------------------------------------------
--| COMMAND _rigSetInitialUploadValue
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2011-08-31
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Set initial values.
--|
--| Format:  _rigSetInitialUploadValue param1, param2
--|
--| Parameters: string <pKey>, mixed <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetInitialUploadValue pKey pValue
  if pKey is among the items of sInitialVarKeys then
    put pValue into sUploadA[pKey]
  end if
end _rigSetInitialUploadValue





/*----------------------------------------------------------------------
--| COMMAND _rigSet_uploadPath
--|
--| Author: rabit
--| Version:  1.0
--| Created: 31-08-2011
--| Last Mod: 31-08-2011
--| Requires: rigTrim() (in Common)
--|
--| Summary: Set upload path.
--|
--| Format:  _rigSet_uploadPath param1
--|
--| Parameters: string <pPath>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSet_uploadPath pPath
	# MAKE SURE IT HAS A TRAILING SLASH
	put rigTrim(pPath, ".,/") & "/" into sUploadA["uploadPath"]
end _rigSet_uploadPath






/*----------------------------------------------------------------------
--| COMMAND _rigSet_allowedTypes
--|
--| Author: rabit
--| Version:  1.1
--| Created: 31-08-2011
--| Last Mod: 09-09-2011
--| Requires: --
--|
--| Summary: Set allowed file types.
--|
--| Format: _rigSet_allowedTypes param1
--|
--| Parameters: string <pTypes>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSet_allowedTypes pTypes
	if (pTypes is not an array) and (pTypes is "*") then
		put "*" into sUploadA["allowedTypes"]
		exit _rigSet_allowedTypes
	end if

	split pTypes by "|"
	put pTypes into sUploadA["allowedTypes"]
end _rigSet_allowedTypes






/*----------------------------------------------------------------------
--| COMMAND _rigSet_maxSize
--|
--| Author: rabit
--| Version:  1.0
--| Created: 31-08-2011
--| Last Mod: 31-08-2011
--| Requires: --
--|
--| Summary: Set maximum file size.
--|
--| Format:  _rigSet_maxSize param1
--|
--| Parameters: integer<pN>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSet_maxSize pN
	if pN is an integer then
		if pN < 0 then
			put 0 into sUploadA["maxSize"]
		else
			put pN into sUploadA["maxSize"]
		end if
	end if
end _rigSet_maxSize






/*----------------------------------------------------------------------
--| COMMAND _rigSet_maxWidth
--|
--| Author: rabit
--| Version:  1.0
--| Created: 31-08-2011
--| Last Mod: 31-08-2011
--| Requires: --
--|
--| Summary: Set maximum image width.
--|
--| Format:  _rigSet_maxWidth param1
--|
--| Parameters: integer<pN>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSet_maxWidth pN
	if pN is an integer then
		if pN < 0 then
			put 0 into sUploadA["maxWidth"]
		else
			put pN into sUploadA["maxWidth"]
		end if
	end if
end _rigSet_maxWidth






/*----------------------------------------------------------------------
--| COMMAND _rigSet_maxHeight
--|
--| Author: rabit
--| Version:  1.0
--| Created: 31-08-2011
--| Last Mod: 31-08-2011
--| Requires: --
--|
--| Summary: Set maximum image height.
--|
--| Format:  _rigSet_maxHeight param1
--|
--| Parameters: integer<pN>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSet_maxHeight pN
	if pN is an integer then
		if pN < 0 then
			put 0 into sUploadA["maxHeight"]
		else
			put pN into sUploadA["maxHeight"]
		end if
	end if
end _rigSet_maxHeight





/*----------------------------------------------------------------------
--| COMMAND _rigSet_maxUploadFiles
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-08-02
--| Last Mod: 2016-08-02
--| Requires: --
--|
--| Summary: Set maximum number of files allowed to upload.
--|
--| Format:  _rigSet_maxUploadFiles param1
--|
--| Parameters: integer <pN>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSet_maxUploadFiles pN
	if pN is an integer then
		if pN < 0 then
			put 0 into sUploadA["maxUploadFiles"]
		else
			put pN into sUploadA["maxUploadFiles"]
		end if
	end if
end _rigSet_maxUploadFiles






/*----------------------------------------------------------------------
--| COMMAND _rigSet_maxFilename
--|
--| Author: rabit
--| Version:  1.0
--| Created: 31-08-2011
--| Last Mod: 31-08-2011
--| Requires: --
--|
--| Summary: Set Maximum File Name Length
--|
--| Format:  _rigSet_maxFilename param1
--|
--| Parameters: integer<pN>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSet_maxFilename pN
	if pN is an integer then
		if pN < 0 then
			put 0 into sUploadA["maxFilename"]
		else
			put pN into sUploadA["maxFilename"]
		end if
	end if
end _rigSet_maxFilename






/*----------------------------------------------------------------------
--| COMMAND _rigSet_xssClean
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-09-2011
--| Last Mod: 01-09-2011
--| Requires: --
--|
--| Summary: Set XSS Clean
--|
--| Enables the XSS flag so that the file that
--| was uploaded will be run through the XSS filter.
--|
--| Format: _rigSet_xssClean param1
--|
--| Parameters: bool<pFlag>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSet_xssClean pFlag
	if pFlag <> TRUE then
		put FALSE into pFlag
	end if
	put pFlag into sUploadA["xssClean"]
end _rigSet_xssClean






/*----------------------------------------------------------------------
--| COMMAND rigDoUpload
--|
--| Author: rabit
--| Version:  2.0
--| Created: 01-09-2011
--| Last Mod: 03-08-2016
--| Requires: _rigSetUploadError, _rigValidateUploadPath(),rigSort, _rigProcessUpload
--|
--| Summary: Perform file upload(s).
--|
--| Format:  rigDoUpload param1
--|
--| Parameters: string <pField> name of form field
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigDoUpload pField
  local tField, tFilesDataKeys, tKey, tFiles

	if pField is empty then
		put "userfile" into tField
	else
		put pField into tField
	end if

	# IF $_FILES[tField] IS NOT AN ARRAY THERE IS NO REASON TO CONTINUE
	if $_FILES[tField] is not an array then
		_rigSetUploadError "upload_no_file_selected"
		return FALSE
	end if

	# IS THE UPLOAD PATH VALID?
	if _rigValidateUploadPath() is FALSE then
		# ERRORS WILL ALREADY BE SET BY _rigValidateUploadPath() SO JUST RETURN FALSE
		return FALSE
	end if

  put the keys of $_FILES[tField] into tFilesDataKeys

  # ARE WE DEALING WITH AN UPLOAD OF MULTIPLE FILES
  if line 1 of tFilesDataKeys is an integer then
    rigSort tFilesDataKeys, "ascnum"

    put 0 into sUploadErrorsNum
    repeat for each line tKey in tFilesDataKeys

      put $_FILES[tField] into tFiles
      _rigProcessUpload tFiles, tKey, TRUE

      if the result is FALSE then
        add 1 to sUploadErrorsNum
      end if

      # STOP IT IN CASE WE HAVE REACHED THE ALLOWED MAX NUMBER OF FILES
      if sMaxUploadFilesExceeded is TRUE then
        exit repeat
      end if
    end repeat

    # ALL FILES WERE PROCESSED WITHOUT FAILURE
    if sUploadErrorsNum < the number of lines of tFilesDataKeys then
      return TRUE
    end if
    # ELSE THE RESULT OF _rigProcessUpload INDICATES A FAILURE

  else
    # SINGLE FILE UPLOAD
    put $_FILES[tField] into tFiles[1]
    _rigProcessUpload tFiles, 1, FALSE

  end if
end rigDoUpload





/*----------------------------------------------------------------------
--| COMMAND _rigProcessUpload
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2016-08-03
--| Last Mod: 2017-06-27
--| Requires: _rigSetUploadError, _rigMaxFilesNumReached(), _rigFileMimeType, _rigPrepFilename(),
--|					_rigGetExtension(), _rigIsAllowedFileType(), _rigIsAllowedFileSize(),
--|					_rigIsAllowedDimensions(), _rigCleanFilename(), _rigLimitFilenameLength(),
--|					rigPregReplace() (in Common), _rigSetFilename(), _rigDoXSSclean, _rigSetImageProperties, rigUploadData()
--|
--| Summary: Process the uploaded files.
--|
--| Format:  _rigProcessUpload param1, param2, param3
--|
--| Parameters: array <pFiles> information related to the upload(s), integer <pItemNum> file number to be processed,
--|               bool <pMultiUpload> are we dealing with multiple files
--|
--| Return: bool
----------------------------------------------------------------------*/

private command _rigProcessUpload pFiles pItemNum pMultiUpload
  local tRegex, tType, tResult, tPath

	if pFiles[pItemNum]["error"] is not empty then
		switch pFiles[pItemNum]["error"]
			case "upload stopped"
				_rigSetUploadError "upload_file_partial"
			break
			case "upload failed"
				_rigSetUploadError "upload_failed"
			break
			case "no upload folder"
				_rigSetUploadError "upload_no_temp_directory"
			break
			case "i/o error"
				_rigSetUploadError "upload_unable_to_write_file"
			break
			default
			_rigSetUploadError "upload_no_file_selected"
		end switch
		return FALSE
	end if

  # CHECK IF THE MAXIMUM NUMBER OF ALLOWED UPLOADS IS REACHED
  if _rigMaxFilesNumReached(pItemNum) is TRUE then
    _rigSetUploadError "upload_max_files_exceeded"
    put TRUE into sMaxUploadFilesExceeded
    return FALSE
  end if

	# SET THE UPLOADED DATA AS LIBRARY VARIABLES
	put pFiles[pItemNum]["filename"] into sFileTemp
	put pFiles[pItemNum]["size"] into sFileSize

	_rigFileMimeType pFiles[pItemNum]

  put "^(.+?);.*$" into tRegex
	put empty into tType -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
  if matchText(pFiles[pItemNum]["type"], tRegex, tType) is TRUE then
	  put tType into sFileType
  end if
  replace "\" with "" in sFileType
  put toLower(rigTrim(sFileType, quote)) into sFileType

	put _rigPrepFilename(pFiles[pItemNum]["name"]) into sUploadA["fileName"]
	put _rigGetExtension(sUploadA["fileName"]) into sFileExt
	put sUploadA["fileName"] into sClientName

	# IS THE FILE TYPE ALLOWED TO BE UPLOADED?
	if _rigIsAllowedFileType() is FALSE then
		_rigSetUploadError "upload_invalid_filetype"
		return FALSE
	end if

	# IF WE'RE OVERRIDING, LET'S NOW MAKE SURE THE NEW NAME AND TYPE IS ALLOWED
	if sFileNameOverride is not empty then
		put _rigPrepFilename(sFileNameOverride) into sUploadA["fileName"]
		put _rigGetExtension(sUploadA["fileName"]) into sFileExt

		if _rigIsAllowedFileType() is not TRUE then
			_rigSetUploadError "upload_invalid_filetype"
			return FALSE
		end if
	end if

	# CONVERT THE FILE SIZE TO KILOBYTES
	if sFileSize > 0 then
		put round((sFileSize/1024),2) into sFileSize
	end if

	# IS THE FILE SIZE WITHIN THE ALLOWED MAXIMUM?
	if _rigIsAllowedFileSize() is not TRUE then
		_rigSetUploadError "upload_invalid_filesize"
		return FALSE
	end if

	# ARE THE IMAGE DIMENSIONS WITHIN THE ALLOWED SIZE?
	if _rigIsAllowedDimensions() is not TRUE then
		_rigSetUploadError "upload_invalid_dimensions"
		return FALSE
	end if

	# SANITIZE THE FILE NAME FOR SECURITY
	put _rigCleanFilename(sUploadA["fileName"]) into sUploadA["fileName"]

	# TRUNCATE THE FILE NAME IF IT'S TOO LONG
	if sUploadA["maxFilename"] > 0 then
		put _rigLimitFilenameLength(sUploadA["fileName"], sUploadA["maxFilename"]) into sUploadA["fileName"]
	end if

	# REMOVE WHITE SPACES IN THE NAME
	if sUploadA["removeSpaces"] is TRUE then
		put "(\s+)" into tRegEx
		put rigPregReplace(sUploadA["fileName"], tRegEx, , "_") into sUploadA["fileName"]
	end if

	# VALIDATE THE FILE NAME
	# THIS FUNCTION APPENDS AN NUMBER ONTO THE END OF
	# THE FILE IF ONE WITH THE SAME NAME ALREADY EXISTS.
	# IF IT RETURNS FALSE THERE WAS A PROBLEM.
	put sUploadA["fileName"] into sOrigName
	if sUploadA["overwrite"] is FALSE then
		put _rigSetFilename(sUploadA["uploadPath"], sUploadA["fileName"]) into sUploadA["fileName"]

		if sUploadA["fileName"] IS FALSE then
			return FALSE
		end if
	end if

	# MOVE THE FILE TO THE FINAL DESTINATION
	put URL format("binfile:%s", sFileTemp) into URL format("binfile:%s", (sUploadA["uploadPath"] & sUploadA["fileName"]))
	put the result into tResult
	if tResult is not empty then
		_rigSetUploadError "upload_destination_error"
		return FALSE
	end if

	# RUN THE FILE THROUGH THE XSS HACKING FILTER
	# THIS HELPS PREVENT MALICIOUS CODE FROM BEING
	# EMBEDDED WITHIN A FILE.  SCRIPTS CAN EASILY
	# BE DISGUISED AS IMAGES OR OTHER FILE TYPES.
	if sUploadA["xssClean"] is TRUE then
		_rigDoXSSclean
	end if

	# SET THE FINALIZED IMAGE DIMENSIONS
	# THIS SETS THE IMAGE WIDTH/HEIGHT (ASSUMING THE
	# FILE WAS AN IMAGE).  WE USE THIS INFORMATION
	# IN THE "DATA" FUNCTION.
	put sUploadA["uploadPath"] & sUploadA["fileName"] into tPath
	_rigSetImageProperties tPath

  if pMultiUpload is TRUE then
    put rigUploadData(TRUE) into sUplaodDataA[pItemNum]
  else
    put rigUploadData(TRUE) into sUplaodDataA
  end if

	return TRUE
end _rigProcessUpload






/*----------------------------------------------------------------------
--| FUNCTION _rigSetFilename
--|
--| Author: rabit
--| Version:  1.0
--| Created: 31-08-2011
--| Last Mod: 31-08-2011
--| Requires: rigHexDigest() (in Common), _rigSetUploadError
--|
--| Summary: Set the file name.
--| 				  This function takes a filename/path as input and looks for the
--| 				  existence of a file with the same name. If found, it will append a
--| 				  number to the end of the filename to avoid overwriting a pre-existing file.
--|
--| Format: _rigSetFilename(param1, param2)
--|
--| Parameters: string <pPath>, string <pFileName>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigSetFilename pPath pFileName
  local tFilename, tNewFilename, tNum

	if sUploadA["encryptName"] is TRUE then
		put rigHexDigest(rigUniqid(25)) & sFileExt into tFilename
	else
		put pFileName into tFilename
	end if

	if there is a file (pPath & tFilename) then
	else
		return tFilename
	end if

	replace sFileExt with "" in tFilename
	put "" into tNewFilename

	repeat with tNum = 1 to 99
		if there is a file (pPath & tFilename & tNum & sFileExt) then
		else
			put tFilename & tNum & sFileExt into tNewFilename
			exit repeat
		end if
	end repeat

	if tNewFilename is "" then
		_rigSetUploadError "upload_bad_filename"
		return FALSE
	else
		return tNewFilename
	end if

end _rigSetFilename






/*----------------------------------------------------------------------
--| FUNCTION rigDisplayUploadErrors
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-09-2011
--| Last Mod: 01-09-2011
--| Requires: --
--|
--| Summary: Display the error message.
--|
--| Format:  rigDisplayUploadErrors(param1, param2)
--|
--| Parameters: string<pOpen> the open tag, string<pClose> the close tag
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDisplayUploadErrors pOpen pClose
  local tOpen, tClose, tKey, tVal, tErrorStr

	if pOpen is empty then
		put "<p>" into tOpen
	else
		put pOpen into tOpen
	end if

	if pClose is empty then
		put "</p>" into tClose
	else
		put pClose into tClose
	end if

	repeat for each key tKey in sErrorMsg
		put sErrorMsg[tKey] into tVal
		put tOpen & tVal & tClose after tErrorStr
	end repeat

	return tErrorStr
end rigDisplayUploadErrors






/*----------------------------------------------------------------------
--| FUNCTION rigUploadData
--|
--| Author: rabit
--| Version:  1.1
--| Created: 01-09-2011
--| Last Mod: 03-08-2016
--| Requires: _rigIsImage()
--|
--| Summary: Finalized data array.
--|
--| Returns an associative array containing all of the information related
--| to the upload, allowing the developer easy access in one array.
--|
--| Format:  rigUploadData([param])
--|
--| Parameters: bool <pLibInternalCall> (optional)
--|
--| Return: array
----------------------------------------------------------------------*/

function rigUploadData pLibInternalCall
  local tData, tFileName

	put sUploadA["fileName"] into tData["FileName"]
	put sFileType into tData["FileType"]
	put sUploadA["uploadPath"] into tData["FilePath"]
	put sUploadA["uploadPath"] & sUploadA["fileName"] into tData["FullPath"]

	put sUploadA["fileName"] into tFileName
	replace sFileExt with "" in tFileName

	put tFileName into tData["RawName"]
	put sOrigName into tData["OrigName"]
	put sClientName into tData["ClientName"]
	put sFileExt into tData["FileExt"]
	put sFileSize into tData["FileSize"]
	put _rigIsImage() into tData["IsImage"]
	put sImageWidth into tData["ImageWidth"]
	put sImageHeight into tData["ImageHeight"]
	put sImageType into tData["ImageType"]
	put sImageSizeStr into tData["ImageSizeStr"]

  if pLibInternalCall is empty then
    return sUplaodDataA
  end if

	return tData
end rigUploadData






/*----------------------------------------------------------------------
--| FUNCTION _rigIsImage
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-09-2011
--| Last Mod: 01-09-2011
--| Requires: --
--|
--| Summary: Validate the image.
--|
--| Format: _rigIsImage()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigIsImage
  local tPNGmimes, tJPGmimes, tImgMimes

	# IE WILL SOMETIMES RETURN ODD MIME-TYPES DURING UPLOAD, SO HERE WE
	# JUST STANDARDIZE ALL JPEGS OR PNGS TO THE SAME FILE TYPE.
	put "image/x-png,image/png" into tPNGmimes
	put "image/jpg,image/jpe,image/jpeg,image/pjpeg" into tJPGmimes

	if sFileType is among the items of tPNGmimes then
		put "image/png" into sFileType
	end if

	if sFileType is among the items of tJPGmimes then
		put "image/jpeg" into sFileType
	end if

	put "image/gif,image/jpeg,image/png" into tImgMimes

	if sFileType is among the items of tImgMimes then
		return TRUE
	end if

	return FALSE
end _rigIsImage






/*----------------------------------------------------------------------
--| COMMAND _rigSetUploadError
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-09-2011
--| Last Mod: 01-09-2011
--| Requires: rigLangLoadLang(), rigLangLangLine(), rigLogMessage
--|
--| Summary: Set an error message.
--|
--| Format:  _rigSetUploadError param1
--|
--| Parameters: string<pMsg>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetUploadError pMsg
  local tKey, tVal, tLangLine, tMsg, tNumErrors, tNewErrorKey

	get rigLangLoadLang("upload")

	if pMsg is an array then
		repeat for each key tKey in pMsg
			put pMsg[tKey] into tVal
			get rigLangLangLine(tVal)
			put it into tLangLine

			if tLangLine is FALSE then
				put tVal into tMsg
			else
				put tLangLine into tMsg
			end if

			if sErrorMsg is an array then
				put the number of lines in the keys of sErrorMsg into tNumErrors
				put tNumErrors + 1 into tNewErrorKey
				put tMsg into sErrorMsg[tNewErrorKey]
			else
				put tMsg into sErrorMsg[1]
			end if
			rigLogMessage "error", tMsg
		end repeat
	else
		get rigLangLangLine(pMsg)
		put it into tLangLine

		if tLangLine is FALSE then
			put pMsg into tMsg
		else
			put tLangLine into tMsg
		end if

		if sErrorMsg is an array then
			put the number of lines in the keys of sErrorMsg into tNumErrors
			put tNumErrors + 1 into tNewErrorKey
			put tMsg into sErrorMsg[tNewErrorKey]
		else
			put tMsg into sErrorMsg[1]
		end if
		rigLogMessage "error", tMsg
	end if

end _rigSetUploadError





/*----------------------------------------------------------------------
--| FUNCTION _rigValidateUploadPath
--|
--| Author: rabit
--| Version:  1.0
--| Created: 02-09-2011
--| Last Mod: 02-09-2011
--| Requires: _rigSetUploadError
--|
--| Summary: Validate Upload Path. Verifies that it is a
--|					valid upload path with proper permissions.
--|
--| Format: _rigValidateUploadPath()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigValidateUploadPath
  local tRoot, tUploadPath

	if sUploadA["uploadPath"] is empty then
		_rigSetUploadError "upload_no_filepath"
		return FALSE
	end if

	# BUILD PATH TO UPLOAD FOLDER
	set the itemDel to "/"
	put (item 1 to -2 of gRigA["BASEPATH"]) & "/" into tRoot
	put tRoot & sUploadA["uploadPath"] into tUploadPath

	if there is not a folder tUploadPath then
		_rigSetUploadError "upload_no_filepath"
		return FALSE
	end if

	if rigCanWriteFileTo(tUploadPath) is FALSE then
		_rigSetUploadError "upload_not_writable"
		return FALSE
	end if

	put tUploadPath into sUploadA["uploadPath"]

	return TRUE
end _rigValidateUploadPath





/*----------------------------------------------------------------------
--| FUNCTION _rigPrepFilename
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2011-09-03
--| Last Mod: 2018-12-27
--| Requires: _rigUploadMimesTypes()
--|
--| Summary: Prep filename.
--| 				  Prevents possible script execution from Apache's handling of files multiple
--| 				  extensions http://httpd.apache.org/docs/1.3/mod/mod_mime.html#multipleext
--|
--| Format:  _rigPrepFilename(param1)
--|
--| Parameters: string<pFilename>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigPrepFilename pFilename
  local tParts, tExtension, tFilename, tAllowedTypes

	if ("." is not in pFilename) or (sUploadA["allowedTypes"] is "*") then
		return pFilename
	end if

	put pFilename into tParts
	set the itemDel to "."
	put item -1 of tParts into tExtension
	put item 1 of tParts into tFilename

	put item 2 to -2 of tParts into tParts

	put sUploadA["allowedTypes"] into tAllowedTypes
	combine tAllowedTypes using comma

	repeat for each item thisItem in tParts
		put toLower(thisItem) into thisItem
		if (thisItem is not among the items of tAllowedTypes) or (_rigUploadMimesTypes(thisItem) is FALSE) then
			put tFilename & "." & thisItem & "_" into tFilename
		end if
			put tFilename & "." & thisItem into tFilename
	end repeat

	put tFilename & "." & tExtension into tFilename

	return tFilename

end _rigPrepFilename





/*----------------------------------------------------------------------
--| FUNCTION _rigUploadMimesTypes
--|
--| Author: rabit
--| Version:  1.1
--| Created: 03-09-2011
--| Last Mod: 03-02-2014
--| Requires: _rigRequire, rigFetchAllMimeTypes()
--|
--| Summary: List of mime types.
--| 				  This is a list of mime types.  We use it to validate
--| 			 	  the "allowed types" set by the developer.
--|
--| Format: _rigUploadMimesTypes(param1)
--|
--| Parameters: string<pMime>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigUploadMimesTypes pMime
  local tArrayLvels

	if sMimes is not an array then
		_rigRequire gRigA["APPPATH"] & "config/mimes" & gRigA["EXT"]
		put rigFetchAllMimeTypes() into sMimes
	end if

	if sMimes[pMime] is an array then
		put "1,2,3,4,5,6,7,8" into tArrayLvels
		repeat for each item thisItem in tArrayLvels
			if sMimes[pMime][thisItem] is not empty then
				return sMimes[pMime][thisItem]
			end if
		end repeat
		return FALSE
	else
		return sMimes[pMime]
	end if
end _rigUploadMimesTypes





/*----------------------------------------------------------------------
--| FUNCTION _rigGetExtension
--|
--| Author: rabit
--| Version:  1.0
--| Created: 03-09-2011
--| Last Mod: 03-09-2011
--| Requires: --
--|
--| Summary: Extract the file extension.
--|
--| Format:  _rigGetExtension(param1)
--|
--| Parameters: string<pFilename>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigGetExtension pFilename
	set the itemDel to "."
	return "." & item -1 of pFilename
end _rigGetExtension






/*----------------------------------------------------------------------
--| FUNCTION _rigIsAllowedFileType
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2011-09-03
--| Last Mod: 2018-12-27
--| Requires: _rigSetUploadError, _rigGetImageSize(), _rigUploadMimesTypes()
--|
--| Summary: Verify that the filetype is allowed.
--|
--| Format: _rigIsAllowedFileType(param1)
--|
--| Parameters: bool<pIgnoreMime>
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigIsAllowedFileType pIgnoreMime
  local tIgnoreMime, tAllowedTypes, tImageTypes, tExtension, tMime

	if sUploadA["allowedTypes"] is "*" then
		return TRUE
	end if

	if (sUploadA["allowedTypes"] is not an array) or (sUploadA["allowedTypes"][1] is empty) then
		_rigSetUploadError "upload_no_file_types"
		return FALSE
	end if

	if pIgnoreMime is empty then
		put FALSE into tIgnoreMime
	else
		put pIgnoreMime into tIgnoreMime
	end if


	put sUploadA["allowedTypes"] into tAllowedTypes
	combine tAllowedTypes using ","

	put toLower(sFileExt) into tExtension
	if char 1 of tExtension is "." then
		put char 2 to -1 of tExtension into tExtension
	end if

	if tExtension is not among the items of tAllowedTypes then
		return FALSE
	end if

	# IMAGES GET SOME ADDITIONAL CHECKS
	put "gif,jpg,jpeg,png,jpe" into tImageTypes
	if tExtension is among the items of tImageTypes then
		if _rigGetImageSize(sFileTemp) is not an array then
			return FALSE
		end if

	end if

	if tIgnoreMime is TRUE then
		return TRUE
	end if

	put _rigUploadMimesTypes(tExtension) into tMime

	if tMime is sFileType then
		return TRUE
	end if

	return FALSE

end _rigIsAllowedFileType






/*----------------------------------------------------------------------
--| FUNCTION _rigGetImageSize
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2011-11-03
--| Last Mod: 2018-12-27
--| Requires: _rigSetUploadError, rigFileSize()
--|
--| Summary: A helper function that gets info about an image file.
--|
--| Format: _rigGetImageSize(param1)
--|
--| Parameters: string <pFilepath>
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigGetImageSize pFilepath
  local tFilepath, tVals, tMime, tTypes, tV

  if pFilepath is empty then
    put sFileTemp into tFilepath
  else
    put pFilepath into tFilepath
  end if

  if there is a file tFilepath then
  else
    _rigSetUploadError "upload_invalid_path"
    return FALSE
  end if

  # GET WIDTH, HEIGHT, FORMAT
  import paint from file tFilepath
  put the width of last image into tVals
  put "," & the height of last image after tVals
  put "," & toUpper(the paintCompression of last image) after tVals
  put "," & rigFileSize(tFilepath) after tVals
  delete last image

  # GET MIME TYPE
  put empty into tMime
  put "gif,jpeg,png,rle" into tTypes
  repeat for each item thisItem in tTypes
    if thisItem is toLower(item 3 of tVals) then
      put "image/" & thisItem into tMime
      exit repeat
    end if
  end repeat
  if tMime is empty then
    put "image/jpg" into tMime
  end if

  if tVals is not empty then
    put item 1 of tVals into tV["width"]
    put item 2 of tVals into tV["height"]
    put item 3 of tVals into tV["imageType"]
    put item 4 of tVals into tV["sizeStr"]
    put tMime into tV["mimeType"]

    return tV
  else
    return FALSE
  end if
end _rigGetImageSize





/*----------------------------------------------------------------------
--| FUNCTION _rigMaxFilesNumReached
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-08-02
--| Last Mod: 2016-08-02
--| Requires: --
--|
--| Summary: Verify that the number of files uploaded doesn't excel the allowed maximum.
--|
--| Format: _rigMaxFilesNumReached(param1)
--|
--| Parameters: integer <pFileNum>
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigMaxFilesNumReached pFileNum
	if (sUploadA["maxUploadFiles"] <> 0) and (pFileNum > sUploadA["maxUploadFiles"]) then
		return TRUE
	else
		return FALSE
	end if
end _rigMaxFilesNumReached






/*----------------------------------------------------------------------
--| FUNCTION _rigIsAllowedFileSize
--|
--| Author: rabit
--| Version:  1.0
--| Created: 03-09-2011
--| Last Mod: 03-09-2011
--| Requires: --
--|
--| Summary: Verify that the file is within the allowed size.
--|
--| Format: _rigIsAllowedFileSize()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigIsAllowedFileSize
	if (sUploadA["maxSize"] <> 0) and (sFileSize > sUploadA["maxSize"]) then
		return FALSE
	else
		return TRUE
	end if

end _rigIsAllowedFileSize






/*----------------------------------------------------------------------
--| FUNCTION _rigIsAllowedDimensions
--|
--| Author: rabit
--| Version:  1.0
--| Created: 03-09-2011
--| Last Mod: 03-09-2011
--| Requires: _rigIsImage(), _rigGetImageSize()
--|
--| Summary: Verify that the image is within the allowed width/height.
--|
--| Format:  _rigIsAllowedDimensions()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigIsAllowedDimensions
  local tImgProps

	if _rigIsImage() is not TRUE then
		return TRUE
	end if

	put _rigGetImageSize(sFileTemp) into tImgProps

	if (sUploadA["maxWidth"] > 0) and (tImgProps["width"] > sUploadA["maxWidth"]) then
		return FALSE
	end if

	if (sUploadA["maxHeight"] > 0) and (tImgProps["height"] > sUploadA["maxHeight"]) then
		return FALSE
	end if

	return TRUE

end _rigIsAllowedDimensions






/*----------------------------------------------------------------------
--| FUNCTION _rigCleanFilename
--|
--| Author: rabit
--| Version:  1.0
--| Created: 03-09-2011
--| Last Mod: 03-09-2011
--| Requires: rigStripSlashes() (in Common)
--|
--| Summary: Remove special characters, encoded and double encoded.
--|
--| Format: _rigCleanFilename(pFilename)
--|
--| Parameters: string<pFilename>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCleanFilename pFilename
  local tBad

	# CHARS <,>,(,),&,$,?,;,= URL ENCODED
	put "<!--,-->,',<,>," & quote & ",&,$,=,;,?,/,%20,%22,%3c,%253c,%3e,%0e,%28,%29,%2528,%26,%24,%3f,%3b,%3d" into tBad

	repeat for each item thisItem in tBad
		replace thisItem with "" in pFilename
	end repeat

	return rigStripSlashes(pFilename)
end _rigCleanFilename





/*----------------------------------------------------------------------
--| FUNCTION _rigLimitFilenameLength
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2011-09-03
--| Last Mod: 2018-12-27
--| Requires: --
--|
--| Summary: Limit the File Name Length.
--|
--| Format:  _rigLimitFilenameLength(params1, param2)
--|
--| Parameters: string<pFilename>, integer<pLength>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigLimitFilenameLength pFilename pLength
  local tExtension, tExtLength, tTruncName

	if (the length of pFilename) < pLength then
		return pFilename
	end if

	put "" into tExtension
	if "." is in pFilename then
		set the itemDel to "."
		put "." & (item -1 of pFilename) into tExtension
		put the length of tExtension into tExtLength
		put char 1 to ((the length of pFilename) - (tExtLength +1)) of pFilename into pFilename
	end if

	put (char 1 to (pLength - (the length of tExtension)) of pFilename) & tExtension into tTruncName

	return tTruncName
end _rigLimitFilenameLength






/*----------------------------------------------------------------------
--| COMMAND _rigDoXSSclean
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-09-2011
--| Last Mod: 04-09-2011
--| Requires: rigFileSize(), rigXssClean() (in Input)
--|
--| Summary: Runs the file through the XSS clean function.
--|					This prevents people from embedding malicious code in their files.
--|					Be careful, this might negatively affect certain files in unexpected ways.
--|
--| Format:  _rigDoXSSclean
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigDoXSSclean
  local tFile, tFileSize, tData

	put sUploadA["uploadPath"] & sUploadA["fileName"] into tFile

	put rigFileSize(tFile) into tFileSize
	if (tFileSize is FALSE) or (tFileSize is 0) then
		return FALSE
	end if

	get URL format("binfile:%s", tFile)
	put it into tData
	if tData is empty then
		return FALSE
	end if

	put rigXssClean(tData) into tData

	open file tFile for binary write
	if the result is not empty then
		return FALSE
	end if

	write tData to file tFile
	if the result is not empty then
		return FALSE
	end if

	close file tFile

end _rigDoXSSclean





/*----------------------------------------------------------------------
--| COMMAND _rigSetImageProperties
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-09-2011
--| Last Mod: 04-09-2011
--| Requires: _rigIsImage(), _rigGetImageSize()
--|
--| Summary: Set Image Properties.
--|
--| Format: _rigSetImageProperties param1
--|
--| Parameters: string <pPath>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetImageProperties pPath
  local tImgProps, tTypes

	if _rigIsImage() is FALSE then
		exit _rigSetImageProperties
	end if

	put _rigGetImageSize(pPath) into tImgProps

	if tImgProps is an array then
		put "gif,jpeg,png" into tTypes

		put tImgProps["width"] into sImageWidth
		put tImgProps["height"] into sImageHeight

		# GET IMAGE TYPE
		if (tImgProps["imageType"] is "") or (tImgProps["imageType"] is not among the items of tTypes) then
			put "unknown" into sImageType
		else
			put tImgProps["imageType"] into sImageType
		end if

		# BUILD STRING CONTAINING HEIGHT AND WIDTH
		put "height=" & quote & sImageHeight & quote && "width=" & quote & sImageWidth & quote into sImageSizeStr
	end if

end _rigSetImageProperties





/*----------------------------------------------------------------------
--| COMMAND _rigFileMimeType
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2015-01-30
--| Last Mod: 2017-06-27
--| Requires: --
--|
--| Summary: Detects the (actual) MIME type of the uploaded file, if possible.
--|            The input array is expected to be $_FILES[tField] (see rigDoUpload).
--|
--| Format:  _rigFileMimeType param1
--|
--| Parameters: array <pFile>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigFileMimeType pFile
  local tRegexp, tMime, tCharset

  # EXPRESSION TO VALIDATE THE MIME INFO STRING (e.g. image/jpeg; charset=binary)
  put "^([a-z\-]+\/[a-z0-9\-\.\+]+)(;\s.+)?$" into tRegexp

  # UNIX-TYPE SYSTEMS PROVIDE A "NATIVE" WAY TO DETECT THE FILE TYPE, WHICH
  # IS MORE SECURE THAN DEPENDING ON THE VALUE OF $_FILES[tField]["type"]
  if the platform <> "Win32" then
    put shell("file --brief --mime" && pFile["filename"] && "2>&1") into tMime

	  put empty into tCharset -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
    get matchText(tMime,tRegexp,sFileType,tCharset)
    if it is TRUE then
      exit _rigFileMimeType
    end if
  end if

  put pFile["type"] into sFileType
end _rigFileMimeType





/*----------------------------------------------------------------------
--| FUNCTION rigUploadGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Get upload array variable value.
--|
--| Format:  rigUploadGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigUploadGet pWhat
  if pWhat is among the keys of sUploadA then
    return sUploadA[pWhat]
  end if

  return empty
end rigUploadGet




/*----------------------------------------------------------------------
--| COMMAND rigUploadSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Setter for upload variables.
--|
--| Format:  rigUploadSet param1, param2
--|
--| Parameters: string <pKey> sUploadA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigUploadSet pKey pVal
  local tHandler

  if pKey is among the keys of sUploadA then

    put "_rigSet_" & pKey into tHandler
    if tHandler is among the items of sValidSetHandlers then
      do tHandler && quote & pVal & quote
    else
      if pKey is among the items of sInitialVarKeys then
        put pVal into sUploadA[pKey]
      end if
    end if -- if tHandler is among the items of sValidSetHandlers

  end if -- if pKey is among the keys of sUploadA
end rigUploadSet








--| END OF Upload.livecodescript
--| Location:  ./system/libraries/Upload.livecodescript
----------------------------------------------------------------------