script "fileHelper"

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
# revIgniter File Helpers
#
# @package		  revIgniter
# @subpackage	Helpers
# @category	    Helpers
# @author		    rabit@revigniter.com
# @link		      https://revigniter.com/userGuide/helpers/fileHelper.html
##

## ------------------------------------------------------------------------



global gRigA

local sMimesFileLoaded, sStackInUse





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-17
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
--| FUNCTION rigReadFile
--|
--| Author: rabit
--| Version:  1.2
--| Created: 09-07-09
--| Last Mod: 02-02-15
--| Requires: rigLogMessage
--|
--| Summary: Opens the file specfied in the path and returns it as a string
--|            with translated end-of-line markers.
--|
--| Format:  rigReadFile(param1)
--|
--| Parameters: string <pFilePath>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigReadFile pFilePath
  local tFileData

  if there is a file pFilePath then
    put URL format("file:%s", pFilePath) into tFileData

    if the result is empty then
      return tFileData
    else
      rigLogMessage "error", "Failed to read file! System error:" && the sysError
    end if
  end if

  return FALSE
end rigReadFile







/*----------------------------------------------------------------------
--| FUNCTION rigReadBinFile
--|
--| Author: rabit
--| Version:  1.1
--| Created: 09-11-09
--| Last Mod: 02-02-15
--| Requires: rigFile_get_contents()
--|
--| Summary: Opens the file specfied in the path and returns it as a string
--|            without translating end-of-line markers.
--|
--| Format:  rigReadBinFile(param1)
--|
--| Parameters: string <pFilePath>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigReadBinFile pFilePath
  return rigFile_get_contents(pFilePath)
end rigReadBinFile







/*----------------------------------------------------------------------
--| FUNCTION rigWriteFile
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-07-09
--| Last Mod: 09-07-09
--| Requires: rigLogMessage
--|
--| Summary: Writes data to the file specified in the path.
--|            Creates a new file if non-existent.
--|
--| Format:  rigWriteFile(param1, param2)
--|
--| Parameters: string <pFile> path to file, string <pData> file data
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigWriteFile pFile pData
  try
    put pData into URL ("binfile:" & pFile)
  catch err
    rigLogMessage "error", "An error occured while trying to save file:" && pFile
    return FALSE
  end try
  return TRUE
end rigWriteFile







/*----------------------------------------------------------------------
--| COMMAND rigDeleteFiles
--|
--| Author: rabit
--| Version:  1.1
--| Created: 09-07-09
--| Last Mod: 31-12-09
--| Requires: rigListFilesWithPaths(), _rigListFoldersWithPaths(), rigLogMessage
--|
--| Summary: Deletes all files contained in the supplied directory path.
--|            Files must be writable or owned by the system in order to be deleted.
--|            If the second parameter is set to TRUE, any directories contained
--|            within the supplied base directory will be nuked as well.
--|
--| Format:  rigDeleteFiles param1, param2, param3
--|
--| Parameters: string <pPath> path to file, bool <pDelDir> whether to delete any
--|                      directories found in the path, string <pExclusion> file name to exclude (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDeleteFiles pPath pDelDir pExclusion
  local tDelDir, tExclusion, tFilesList, tFoldersList, tNumLines, tFolderToDelete

	if pDelDir is not TRUE then
		put FALSE into tDelDir
	else
		put TRUE into tDelDir
	end if

	if pExclusion is not empty then
		put pExclusion into tExclusion
	else
		put "" into tExclusion
	end if

	put empty into tFilesList
	put empty into tFoldersList

	#BUILD LISTS
	put rigListFilesWithPaths(pPath, tDelDir) into tFilesList

	if tDelDir is TRUE then
		put _rigListFoldersWithPaths(pPath, tDelDir, FALSE) into tFoldersList
	end if

	if tExclusion is not empty then
		set the itemDelimiter to "/"
	end if

	# DELETE FILES
	if tFilesList is not empty then
		repeat for each line thisLine in tFilesList
			if item -1 of thisLine <> tExclusion then
				try
					delete file thisLine
				catch err
					rigLogMessage "error", "An error occured while deleting file:" && thisLine
				end try
			end if
		end repeat
	end if

	# DELETE FOLDERS
	 if tFoldersList is not empty then
		put the number of lines of tFoldersList into tNumLines
		repeat with i = tNumLines down to 1
			put line i of tFoldersList into tFolderToDelete
			try
				delete folder tFolderToDelete
			catch err
				rigLogMessage "error", "An error occured while deleting folder:" && tFolderToDelete
			end try
		end repeat
	end if
end rigDeleteFiles







/*----------------------------------------------------------------------
--| FUNCTION rigGetFileNames
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-07-09
--| Last Mod: 09-07-09
--| Requires: rigListFilesWithPaths(), rigListFiles()
--|
--| Summary: Reads the specified directory and builds an array containing the filenames.
--|            Any sub-folders contained within the specified path are read as well if desired.
--|
--| Format:  rigGetFileNames(param1, param2, param3)
--|
--| Parameters: string <pSourceDir> path to source, bool <pIncludePath> whether to include
--|               the path as part of the filename, bool <pRecursion>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigGetFileNames pSourceDir pIncludePath pRecursion
  local tRecursion, tFilesList, tCount, tFilesListArray

	if pRecursion is TRUE then
		put TRUE into tRecursion
	else
		put FALSE into tRecursion
	end if

	# BUILD FILES LIST
	if pIncludePath is TRUE then
		put rigListFilesWithPaths(pSourceDir, tRecursion) into tFilesList
	else
		put rigListFiles(pSourceDir, tRecursion) into tFilesList
	end if

	# BUILD ARRAY
	put 0 into tCount
	repeat for each line thisLine in tFilesList
		add 1 to tCount
		put thisLine into tFilesListArray[tCount]
	end repeat

	return tFilesListArray
end rigGetFileNames







/*----------------------------------------------------------------------
--| FUNCTION rigGetDirFileInfo
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-07-09
--| Last Mod: 09-07-09
--| Requires: rigListFilesWithPaths(), rigListFiles
--|
--| Summary: Reads the specified directory and builds an array containing the filenames,
--|            filesize, dates, and permissions.
--|
--| Format:  rigGetDirFileInfo(param1, param2, param3)
--|
--| Parameters: string <pSourceDir> path to source, bool <pIncludePath> whether to include
--|               the path as part of the filename, bool <pRecursion>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigGetDirFileInfo pSourceDir pIncludePath pRecursion
  local tRecursion, tFilesList, tCount, tFilesListArray

	if pRecursion is TRUE then
		put TRUE into tRecursion
	else
		put FALSE into tRecursion
	end if

	# BUILD FILES LIST
	if pIncludePath is TRUE then
		put rigListFilesWithPaths(pSourceDir, pRecursion, TRUE) into tFilesList
	else
		put rigListFiles(pSourceDir, pRecursion, TRUE) into tFilesList
	end if

	# BUILD ARRAY
	put 0 into tCount
	repeat for each line thisLine in tFilesList
		add 1 to tCount
		put thisLine into tFilesListArray[tCount]
	end repeat

	return tFilesListArray
end rigGetDirFileInfo








/*----------------------------------------------------------------------
--| FUNCTION rigGetFileInfo
--|
--| Author: rabit
--| Version:  1.2
--| Created: 09-07-09
--| Last Mod: 05-01-10
--| Requires: rigPathWithoutFileName(), rigFileInfo()
--|
--| Summary: Given a file and path, returns the name, serverPath, size, date modified
--|            Second parameter allows you to explicitly declare what information you want returned
--|            Options are: fileName, serverPath, fileSize, resourceSize, created, lastModified, lastAccessed,
--|            lastBackedUp, owner, groupOwner, permissions, fileType
--|            Returns FALSE if the file cannot be found.
--|
--| Format:  rigGetFileInfo(param1, param2)
--|
--| Parameters: string <pFile> path to source, string <pReturnedValues> array or comma
--|               separated string of information returned
--|
--| Return: array
----------------------------------------------------------------------*/

function rigGetFileInfo pFile pReturnedValues
  local tReturnedValues, tServerPath, tFileData, tRequestedData

  put pReturnedValues into tReturnedValues

  if there is a file pFile then
  else
    return FALSE
  end if

  if tReturnedValues is an array then
    combine tReturnedValues using ","
  end if

  put rigPathWithoutFileName(pFile) into tServerPath

  put rigFileInfo(pFile) into tFileData

  if tReturnedValues is empty then
    put tFileData["fileName"] into tRequestedData["fileName"]
    put tServerPath into tRequestedData["serverPath"]
    put tFileData["fileSize"] into tRequestedData["fileSize"]
    put tFileData["lastModified"] into tRequestedData["lastModified"]

  else
    repeat for each item tVal in pReturnedValues
      switch tVal
        case "fileName"
          put tFileData["fileName"] into tRequestedData["fileName"]
        break
        case "fileName"
          put tFileData["serverPath"] into tRequestedData["serverPath"]
        break
        case "fileSize"
          put tFileData["fileSize"] into tRequestedData["fileSize"]
        break
        case "resourceSize"
          put tFileData["resourceSize"] into tRequestedData["resourceSize"]
        break
        case "created"
          put tFileData["created"] into tRequestedData["created"]
        break
        case "lastModified"
          put tFileData["lastModified"] into tRequestedData["lastModified"]
        break
        case "lastAccessed"
          put tFileData["lastAccessed"] into tRequestedData["lastAccessed"]
        break
        case "lastBackedUp"
          put tFileData["lastBackedUp"] into tRequestedData["lastBackedUp"]
        break
        case "owner"
          put tFileData["owner"] into tRequestedData["owner"]
        break
        case "groupOwner"
          put tFileData["groupOwner"] into tRequestedData["groupOwner"]
        break
        case "permissions"
          put tFileData["permissions"] into tRequestedData["permissions"]
        break
        case "fileType"
          put tFileData["fileType"] into tRequestedData["fileType"]
        break
      end switch
    end repeat
  end if

  return tRequestedData
end rigGetFileInfo








/*----------------------------------------------------------------------
--| FUNCTION rigGetMimeByExtension
--|
--| Author: rabit
--| Version:  1.1
--| Created: 10-07-09
--| Last Mod: 17-09-15
--| Requires: rigLogMessage, rigFetchMimeType()
--|
--| Summary: Translates a file extension into a mime type based on config/mimes.lc.
--|             Returns FALSE if it can't determine the type, or open the mime config file.
--|
--| Format:  rigGetMimeByExtension(param1)
--|
--| Parameters: string <pFile> path to file
--|
--| Return: string
----------------------------------------------------------------------*/

function rigGetMimeByExtension pFile
  local tExtension, tMimeType

  set the itemDelimiter to "."
  put item -1 of pFile into tExtension

  if sMimesFileLoaded is not TRUE then
    try
      _rigRequire gRigA["APPPATH"] & "config/mimes" & gRigA["EXT"]
    catch err
      rigLogMessage "error", "An error occured while trying to include file:" && "mimes" & gRigA["EXT"]
      return FALSE

    end try
    put TRUE into sMimesFileLoaded
  end if

  # GET MIME TYPE
  put rigFetchMimeType(tExtension) into tMimeType
  if tMimeType is not FALSE then
    if tMimeType is an array then
      # MULTIPLE MIME TYPES, JUST GIVE THE FIRST ONE
      return tMimeType[1]
    else
      return tMimeType
    end if
  else
    return FALSE
  end if

end rigGetMimeByExtension








/*----------------------------------------------------------------------
--| FUNCTION rigSymbolicPermissions
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-07-09
--| Last Mod: 12-07-09
--| Requires: --
--|
--| Summary: Takes an octal value representing a file's permissions and returns
--|             standard symbolic notation representing that value.
--|
--| Format:  rigSymbolicPermissions(param1)
--|
--| Parameters: integer <pNumericPerm> numeric permission
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigSymbolicPermissions pNumericPerm
  local tSymbolic

  if pNumericPerm is a number and (the number of chars of pNumericPerm is 3) then
    repeat for each char thisNum in pNumericPerm
      switch thisNum
        case 0
          put "---" after tSymbolic
        break
        case 1
          put "--x" after tSymbolic
        break
        case 2
          put "-w-" after tSymbolic
        break
        case 4
          put "r--" after tSymbolic
        break
        case 3
          put "-wx" after tSymbolic
        break
        case 5
          put "r-x" after tSymbolic
        break
        case 6
          put "rw-" after tSymbolic
        break
        case 7
          put "rwx" after tSymbolic
        break
      default
      put "---" after tSymbolic
    end switch
  end repeat
  return tSymbolic
else
  return FALSE
end if
end rigSymbolicPermissions







/*----------------------------------------------------------------------
--| FUNCTION rigFileNameFromPath
--|
--| Author: libURL
--| Version:  1.0
--| Created:  01-05-08
--| Last Mod: 09-07-09
--| Requires:  --
--|
--| Summary:  Get file name from a given file path.
--|
--| Format:  rigFileNameFromPath(param1)
--|
--| Parameters: string <pPath>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFileNameFromPath pPath
  set the itemdelimiter to "/"
  return item -1 of pPath
end rigFileNameFromPath






/*----------------------------------------------------------------------
--| FUNCTION rigPathWithoutFileName
--|
--| Author: libURL
--| Version:  1.0
--| Created:  01-05-08
--| Last Mod: 09-07-09
--| Requires:  --
--|
--| Summary:  Get path of a given file without file name.
--|
--| Format:  rigPathWithoutFileName(param1)
--|
--| Parameters: string <pPath>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigPathWithoutFileName pPath
  set the itemdelimiter to "/"
  return item 1 to -2 of pPath & "/"
end rigPathWithoutFileName





/*----------------------------------------------------------------------
--| FUNCTION rigFileInfo
--|
--| Author: libURL
--| Version:  1.2
--| Created:  2008-05-01
--| Last Mod: 2019-01-12
--| Requires:  rigPathWithoutFileName, rigFileNameFromPath
--|
--| Summary:  Get all available information of a given file.
--|
--| Format:  rigFileInfo(param1)
--|
--| Parameters: string<pFileName>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFileInfo pFileName
  local tFolderName, tFileName, tFileList, tInfo, tFileInfo

  put rigPathWithoutFileName(pFileName) into tFolderName
  put rigFileNameFromPath(pFileName) into tFileName
  put urldecode(files(tFolderName, "detailed")) into tFileList

  filter tFileList with tFileName & "*"
  put tFileList into tInfo

  put item 1 of tInfo into tFileInfo["fileName"]
  put item 2 of tInfo into tFileInfo["fileSize"]
  put item 3 of tInfo into tFileInfo["resourceSize"]
  put item 4 of tInfo into tFileInfo["created"]
  put item 5 of tInfo into tFileInfo["lastModified"]
  put item 6 of tInfo into tFileInfo["lastAccessed"]
  put item 7 of tInfo into tFileInfo["lastBackedUp"]
  put item 8 of tInfo into tFileInfo["owner"]
  put item 9 of tInfo into tFileInfo["groupOwner"]
  put item 10 of tInfo into tFileInfo["permissions"]
  put item 11 of tInfo into tFileInfo["fileType"]

  return tFileInfo
end rigFileInfo







/*----------------------------------------------------------------------
--| FUNCTION _rigFilterDots
--|
--| Author: rabit, Oliver Kenyon (revArticles)
--| Version:  1.1
--| Created:  --
--| Last Mod: 25-09-15
--| Requires:  --
--|
--| Summary: Filters the strings "." and ".." from a list.
--|
--| Format:  _rigFilterDots(param1, param2)
--|
--| Parameters: string <pList>, bool <pDetailed>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigFilterDots pList pDetailed
  if pDetailed is not true then
    filter pList without "."
    filter pList without ".."
    filter pList without ".DS_Store" -- Mac only

    -----????????????????????
    filter pList without "Icon%0D"
    filter pList without "MACSfdrp" -- remove folder aliases
    -----????????????????????
  else
    filter pList without "*.,*"
    filter pList without "*..,*"
    filter pList without "*.DS_Store,*" -- Mac only
    filter pList without "Icon%0D*"
    filter pList without "*,MACSfdrp" -- remove folder aliases
  end if
  return pList
end _rigFilterDots







/*----------------------------------------------------------------------
--| FUNCTION _rigFilteredFiles
--|
--| Author: rabit, Oliver Kenyon (revArticles)
--| Version:  1.1
--| Created:  --
--| Last Mod: 2019-01-12
--| Requires:  _rigFilterDots()
--|
--| Summary: Returns a filtered list of files in the current directory.
--|
--| Format:  _rigFilteredFiles(param1)
--|
--| Parameters: string <pPath>, bool <pDetailed>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigFilteredFiles pPath pDetailed
  if pDetailed is true then
    return _rigFilterDots(files(pPath, "detailed"), pDetailed)
  end if

  return _rigFilterDots(files(pPath), pDetailed)
end _rigFilteredFiles







/*----------------------------------------------------------------------
--| FUNCTION _rigFilterFolderDots
--|
--| Author: rabit
--| Version:  1.0
--| Created:  09-07-09
--| Last Mod: 09-07-09
--| Requires:  --
--|
--| Summary: Filters the strings "." and ".." from a list of folders.
--|
--| Format:  _rigFilterFolderDots(param1)
--|
--| Parameters: string <pList>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigFilterFolderDots pList
  local tList

  put pList into tList

  filter tList without "."
  filter tList without ".."

  return tList
end _rigFilterFolderDots






/*----------------------------------------------------------------------
--| FUNCTION rigFilteredFolders
--|
--| Author: Oliver Kenyon (revArticles)
--| Modification: rabit
--| Version:  1.1
--| Created:  --
--| Last Mod: 2009-07-09
--| Requires:  _rigFilterFolderDots()
--|
--| Summary: Returns a filtered list of folders in the current directory.
--|
--| Format:  rigFilteredFolders(param1)
--|
--| Parameters: string <pPath>, bool <pDetailed>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFilteredFolders pPath pDetailed
  if pDetailed is true then
    return _rigFilterFolderDots(folders(pPath, "detailed"))
  end if

  return _rigFilterFolderDots(folders(pPath))
end rigFilteredFolders






/*----------------------------------------------------------------------
--| FUNCTION _rigFilteredFilesWithPaths
--|
--| Author: Oliver Kenyon (revArticles)
--| Modification: rabit
--| Version:  1.0
--| Created:  --
--| Last Mod: 2019-01-12
--| Requires:  _rigFilteredFiles()
--|
--| Summary: Returns a list of files (optional "the detailed files") in the current directory
--|            including each file's full path.
--|
--| Format:  _rigFilteredFilesWithPaths()
--|
--| Parameters: string <pPath>, bool <pDetailed>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigFilteredFilesWithPaths pPath pDetailed
  local tFiles, tFilesWithPaths

  put _rigFilteredFiles(pPath, pDetailed) into tFiles

  repeat for each line tFile in tFiles
    put pPath & slash & tFile & return after tFilesWithPaths
  end repeat
  delete the last char of tFilesWithPaths

  return tFilesWithPaths
end _rigFilteredFilesWithPaths







/*----------------------------------------------------------------------
--| FUNCTION rigListFiles
--|
--| Author: rabit
--| Version:  1.3
--| Created:  2009-07-09
--| Last Mod: 2019-01-12
--| Requires:  rigTrim(), rigIsAbsolutePath(), _rigFilteredFiles(), rigFilteredFolders()
--|
--| Summary: Returns a list of files in a given folder, using recursion to include
--|            files in subfolders if desired.
--|
--| Format:  rigListFiles(param1, param2, param3, param4, param5)
--|
--| Parameters: string<pFolder>, bool<pRecurse>, bool<pDetailedFil>, bool<pModDate>,
--|               bool<pRelPath>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigListFiles pFolder pRecurse pDetailedFil pModDate pRelPath
  local tDetailed, tCurrentFiles, tCurrentFilesWithDate, tTotalFiles
  local tFolders, tCurrentFilesPath

  if pDetailedFil is TRUE then
    put TRUE into tDetailed
  else
    put FALSE into tDetailed
  end if

  # USE ABSOLUTE PATH
  replace "\" with "/" in pFolder
   put rigTrim(pFolder, "/") into pFolder
   if not rigIsAbsolutePath(pFolder) then
      put the defaultfolder & "/" & pFolder into pFolder
   else
      put "/" & pFolder into pFolder
   end if

   put _rigFilteredFiles(pFolder, tDetailed) into tCurrentFiles

  # ADD MODIFICATION DATES (SECS) TO FILE NAMES
  if tDetailed is true and pModDate is true then
    if tCurrentFiles is not empty then
      set the itemdelimiter to comma
      repeat for each line tFile in tCurrentFiles
        put item 1 of tFile & "," & item 5 of tFile & cr after tCurrentFilesWithDate
      end repeat
      delete the last char of tCurrentFilesWithDate
    end if
    put tCurrentFilesWithDate into tCurrentFiles
  end if

  if not pRecurse then
    if tDetailed is not true then
      return tCurrentFiles
    else
      return urldecode(tCurrentFiles) -- decode detailed list
    end if
  end if

  if tCurrentFiles is not empty then put tCurrentFiles & return after tTotalFiles

  put rigFilteredFolders(pFolder) into tFolders
  repeat for each line tFolder in tFolders

    put URLDecode(tFolder) into tFolder

    if char -1 of pFolder <> "/" then
      put rigListFiles((pFolder & slash & tFolder), pRecurse, pDetailedFil, pModDate, pRelPath) into tCurrentFiles
    else
      put rigListFiles((pFolder & tFolder), pRecurse, pDetailedFil, pModDate, pRelPath) into tCurrentFiles
    end if

    if tCurrentFiles is not empty then

      if pRelPath is true then
        put empty into tCurrentFilesPath
        repeat for each line tFile in tCurrentFiles
          put tFolder & slash & tFile & cr after tCurrentFilesPath
        end repeat

        delete the last char of tCurrentFilesPath
        put tCurrentFilesPath & return after tTotalFiles

      else
        put tCurrentFiles & return after tTotalFiles
      end if
    end if
  end repeat
  delete the last char of tTotalFiles

  if tDetailed is not true then
    return tTotalFiles
  else
    return urldecode(tTotalFiles) -- decode detailed list
  end if
end rigListFiles






/*----------------------------------------------------------------------
--| FUNCTION rigListFilesWithPaths
--|
--| Author: rabit, Oliver Kenyon (revArticles)
--| Version:  1.4
--| Created:  2009-07-09
--| Last Mod: 2019-01-12
--| Requires: rigTrim(), rigIsAbsolutePath(), _rigFilteredFilesWithPaths(), rigFilteredFolders()
--|
--| Summary: Returns a list of files with the full paths.
--|
--| Format:  rigListFilesWithPaths(param1, param2)
--|
--| Parameters: string <pFolder>, bool <pRecurse>, bool<pDetailedFil>, bool<pModDate>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigListFilesWithPaths pFolder pRecurse pDetailedFil pModDate
  local tDetailed, tCurrentFiles, tItemNums, tFilePart1, tFilePart2
  local tCurrentFilesWithDate, tTotalFiles, tFolders

  if pDetailedFil is TRUE then
    put TRUE into tDetailed
  else
    put FALSE into tDetailed
  end if

  # USE ABSOLUTE PATH
  replace "\" with "/" in pFolder
   put rigTrim(pFolder, "/") into pFolder
   if not rigIsAbsolutePath(pFolder) then
      put the defaultfolder & "/" & pFolder into pFolder
   else
      put "/" & pFolder into pFolder
   end if

   put _rigFilteredFilesWithPaths(pFolder, tDetailed) into tCurrentFiles

  # ADD MODIFICATION DATES (SECS) TO FILE NAMES
  if tDetailed is true and pModDate is true then
    if tCurrentFiles is not empty then

      repeat for each line tFile in tCurrentFiles

        set the itemdelimiter to "/"
        put the number of items of tFile into tItemNums
        put item 1 to (tItemNums -1) of tFile into tFilePart1
        put item -1 of tFile into tFilePart2

        set the itemdelimiter to comma
        put item 1 of tFilePart2 & "," & item 5 of tFilePart2 & cr into tFilePart2
        put tFilePart1 & "/" & tFilePart2 after tCurrentFilesWithDate
      end repeat
      delete the last char of tCurrentFilesWithDate
    end if
    put tCurrentFilesWithDate into tCurrentFiles
  end if

  --if not pRecurse then return tCurrentFiles

  if not pRecurse then
    if tDetailed is not true then
      return tCurrentFiles
    else
      return urldecode(tCurrentFiles) -- decode detailed list
    end if
  end if

  if tCurrentFiles is not empty then put tCurrentFiles & return after tTotalFiles

  put rigFilteredFolders(pFolder) into tFolders

  repeat for each line tFolder in tFolders
    put URLDecode(tFolder) into tFolder
    if char -1 of pFolder <> "/" then
      put rigListFilesWithPaths((pFolder & slash & tFolder), pRecurse, pDetailedFil, pModDate) into tCurrentFiles
    else
      put rigListFilesWithPaths((pFolder & tFolder), pRecurse, pDetailedFil, pModDate) into tCurrentFiles
    end if
    if tCurrentFiles is not empty then put tCurrentFiles & return after tTotalFiles
  end repeat
  delete the last char of tTotalFiles

  if tDetailed is not true then
    return tTotalFiles
  else
    return urldecode(tTotalFiles) -- decode detailed list
  end if
end rigListFilesWithPaths






/*----------------------------------------------------------------------
--| FUNCTION _rigFilteredFoldersWithPaths
--|
--| Author: rabit
--| Version:  1.1
--| Created:  2009-07-09
--| Last Mod: 2019-01-12
--| Requires:  rigFilteredFolders()
--|
--| Summary: Returns a list of folders in the current directory including each folder's full path.
--|
--| Format:  _rigFilteredFoldersWithPaths()
--|
--| Parameters: string <pPath>, bool <pDetailed>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigFilteredFoldersWithPaths pPath pDetailed
  local tFolders, tFoldersWithPaths

  put rigFilteredFolders(pPath, pDetailed) into tFolders

  repeat for each line tFolder in tFolders
    put pPath & slash & tFolder & return after tFoldersWithPaths
  end repeat
  delete the last char of tFoldersWithPaths

  return tFoldersWithPaths
end _rigFilteredFoldersWithPaths





/*----------------------------------------------------------------------
--| FUNCTION _rigListFoldersWithPaths
--|
--| Author: rabit
--| Version:  1.3
--| Created:  2009-07-09
--| Last Mod: 2019-01-12
--| Requires: rigFilteredFolders(), _rigFilteredFoldersWithPaths()
--|
--| Summary: Returns a list of folders with the full paths, using recursion to include
--|            subfolders if desired.
--|
--| Format:  _rigListFoldersWithPaths(param1, param2, param3)
--|
--| Parameters: string <pFolder>, bool <pRecurse>, bool <pDetailed>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigListFoldersWithPaths pFolder pRecurse pDetailed
  local tCurrentFolders, tTotalFolders, tFolders, tFolder

  put _rigFilteredFoldersWithPaths(pFolder, pDetailed) into tCurrentFolders

  put URLDecode(tCurrentFolders) into tCurrentFolders

  if not pRecurse then
    if pDetailed is not true then
      return tCurrentFolders
    else
      return urldecode(tCurrentFolders) -- decode DETAILED LIST
    end if
  end if

  if tCurrentFolders is not empty then put tCurrentFolders & return after tTotalFolders

  put rigFilteredFolders(pFolder, false) into tFolders
  repeat for each line tFolder in tFolders

    put URLDecode(tFolder) into tFolder
    if char -1 of pFolder <> "/" then
      put _rigListFoldersWithPaths((pFolder & slash & tFolder), pRecurse, pDetailed) into tCurrentFolders
    else
      put _rigListFoldersWithPaths((pFolder & tFolder), pRecurse, pDetailed) into tCurrentFolders
    end if
    if tCurrentFolders is not empty then put tCurrentFolders & return after tTotalFolders
  end repeat
  delete the last char of tTotalFolders

  if pDetailed is not true then
    return tTotalFolders
  else
    return urldecode(tTotalFolders) -- decode DETAILED LIST
  end if
end _rigListFoldersWithPaths






/*----------------------------------------------------------------------
--| FUNCTION rigAddTrailingSlash
--|
--| Author: rabit
--| Version:  1.2
--| Created:  2009-07-21
--| Last Mod: 2019-01-11
--| Requires: --
--|
--| Summary: Add trailing slash to path if there is none.
--|
--| Format:  rigAddTrailingSlash(param1)
--|
--| Parameters: string <pPath>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigAddTrailingSlash pPath
  local tRegEx, tFoundText

	put "(.+?)\/*$" into tRegEx
	put empty into tFoundText -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	get matchText(pPath,tRegEx,tFoundText)
	if it is TRUE then
		return tFoundText & "/"
	end if

  return pPath
end rigAddTrailingSlash






--| END OF fileHelper.livecodescript
--| Location:  ./system/helpers/fileHelper.livecodescript
----------------------------------------------------------------------