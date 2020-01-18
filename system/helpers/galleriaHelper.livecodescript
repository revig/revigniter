script "galleriaHelper"

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
# RevIgniter Galleria Helper
#
# @package      revIgniter
# @subpackage  Helpers
# @category     Helpers
# @author       rabit@revigniter.com
# @link          https://revigniter.com/userGuide/helpers/galleriaHelper.html
##

## ------------------------------------------------------------------------




global gRigA




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-27
 --| Last Mod: --
 --| Requires: rigLogMessage
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

  if the short name of the target <> the short name of me then
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack





/*----------------------------------------------------------------------
--| FUNCTION rigGalleriaData
--|
--| Author: rabit
--| Version:  1.10
--| Created: 2011-12-11
--| Last Mod: 2020-01-13
--| Requires: rigTrim(), rigFetchConfigItem(), rigGetFileNames(), rigLogMessage,
--| 					rigGetFileInfo(), rigWriteFile()
--|
--| Summary: Write Galleria image and initialization data, return a reference to it or the data itself.
--| 				  The Galleria version currently supported is 1.6.1, see https://galleria.io/.
--|
--| Format:  rigGalleriaData(param1[, param2][, param3][, param4][, param5][, param6][, parmam7][, param8])
--|
--| Parameters: mixed <pGalleryPath> root relative path to Galleria folder,
--| 						array <pOptions> Galleria options array (optional),
--| 						string <pContainerID> ID of gallery container (optional),
--| 						string <pDataVariableName> name of JavaScript variable (optional),
--| 						bool <pCacheBuster> compose cache buster file names (optional),
--| 						bool <pReplaceDataFile> flag for replacing the data file every
--| 						time the function is called (optional), bool <pReturnReference> flag
--| 						for either returning a reference to the data file or for returning the
--| 						the data itself (optional), string <pNonce> CSP nonce (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigGalleriaData pGalleryPath pOptions pContainerID pDataVariableName pCacheBuster pReplaceDataFile pReturnReference pNonce
  local tGalleriaParams, tGalleryPath, tOptions, tContainerID
  local tDataVariableName, tCacheBuster, tReplaceDataFile
  local tReturnReference, tPathTranslated, tDoCacheBusting
  local tURLbase, tFileNamesArray, tFileNamesList, tJSONfile
  local tCurrentVal, tJSONfileContent, tCbJSONfile, tCreationDate
  local tJSONurl, tThumbNamesArray, tBigNamesArray, tMetaDataFile
  local tMetaData, tGalleriaData, tCurrentImagePath, tCurrentImage
  local tCurrentImageName, tCurrentImageSuffix, tInfoArray, tLastMod
  local tCurrentImageCB, tThumb, tThumbURL, tImageURL, tBig, tBigURL
  local tCurrentMetaLineNum, tGalleriaDataOptions, tNonce

	# GET PARAMS FROM FIRST PARAM IF IT IS AN ARRAY
	if pGalleryPath is an array then
		put pGalleryPath into tGalleriaParams
		put tGalleriaParams["galleriaPath"] into pGalleryPath
		put tGalleriaParams["options"] into pOptions
		put tGalleriaParams["containerID"] into pContainerID
		put tGalleriaParams["dataVariableName"] into pDataVariableName
		put tGalleriaParams["cacheBuster"] into pCacheBuster
		put tGalleriaParams["replaceDataFile"] into pReplaceDataFile
		put tGalleriaParams["returnReference"] into pReturnReference
	end if

	# PREPARE PARAMETER VALUES
	# GALLERIA FOLDER PATH
	put rigTrim(pGalleryPath, "/") into tGalleryPath

	# GALLERIA OPTIONS
	# SET DEFAULT VALUE FOR HEIGHT
	if pOptions is not an array then
		put "420" into tOptions["height"]
	else
		put pOptions into tOptions
		if tOptions["height"] is empty then
			put "420" into tOptions["height"]
		end if
	end if

	# ID
	# SET DEFAULT VALUE
	if pContainerID <> empty then
		put pContainerID into tContainerID
	else
		put "galleria" into tContainerID
	end if

	# DATA VARIABLE NAME
	# SET DEFAULT VALUE
	if pDataVariableName <> empty then
		put pDataVariableName into tDataVariableName
	else
		put "galleriaData" into tDataVariableName
	end if

	# CACHE BUSTING
	# SET DEFAULT VALUE
	if pCacheBuster <> "" then
		put pCacheBuster into tCacheBuster
	else
		put TRUE into tCacheBuster
	end if

	# REPLACE DATA FILE FLAG
	# SET DEFAULT VALUE
	if pReplaceDataFile <> "" then
		put pReplaceDataFile into tReplaceDataFile
	else
		put FALSE into tReplaceDataFile
	end if

	# RETURN REFERENCE FLAG
	if pReturnReference <> "" then
		put pReturnReference into tReturnReference
	else
		put TRUE into tReturnReference
	end if

  # CSP
  if pNonce <> empty then
    put "nonce='" & pNonce & "' " into tNonce
  end if

	# GET PATH TRANSLATED - NEEDED TO GET FILE INFO
	put $_SERVER["PATH_TRANSLATED"] into tPathTranslated

	set the itemDel to "/"

  # FIX FOR RARE CASES WHERE THE SERVER GLOBAL GIVES
  # THE WRONG PATH TO THE CURRENT SCRIPT (index.lc)
  if "index" is not in item -1 of tPathTranslated then
    put gRigA["pathTranslated"] into tPathTranslated
  end if

  # REMOVE index.lc
	put (item 1 to - 2 of tPathTranslated) & "/" into tPathTranslated

	# IS A CACHE BUSTER REQUESTED?
	put rigFetchConfigItem("use_cacheBusters") into tDoCacheBusting
	if (tDoCacheBusting is TRUE) and (tCacheBuster is TRUE) then
		put TRUE into tDoCacheBusting
	else
		put FALSE into tDoCacheBusting
	end if

	# GET BASE URL
	put rigFetchConfigItem("baseUrl") into tURLbase

	# GET FULL PATHS TO FILES
	rigLoadHelper "file"
	if there is a folder (tPathTranslated & tGalleryPath) then
		put rigGetFileNames((tPathTranslated & tGalleryPath), TRUE,) into tFileNamesArray
	else
		rigLogMessage "error", "Missing galleria folder."
		return FALSE
	end if

	# GET SORTED LIST OF FILES
	repeat for each key tKey in tFileNamesArray
		put tFileNamesArray[tKey] & return after tFileNamesList
	end repeat
	delete char -1 of tFileNamesList
	sort lines of tFileNamesList ascending text by item -1 of each

	# CHECK IF JSON FILE EXISTS ALREADY
	put tDataVariableName & ".js" into tJSONfile
	repeat for each key tKey in tFileNamesArray
		put tFileNamesArray[tKey] into tCurrentVal
		if item -1 of tCurrentVal is tJSONfile then

			# CHECK FOR CACHE BUSTING ON LAST SAVE
			put URL format("file:%s", tCurrentVal) into tJSONfileContent

      	if the result <> empty then
        	rigLogMessage "error", "Failed to read file! System error:" && the sysError
      	end if

			if "creationDate" is among the words of line 1 of tJSONfileContent then
				put TRUE into tCbJSONfile
				set the itemDel to "="
				put char 1 to -2 of (item -1 of line 1 of tJSONfileContent) into tCreationDate
			else
				put FALSE into tCbJSONfile
				put the secs into tCreationDate
			end if

			# ADD TIMESTAMP TO NAME
			if tDoCacheBusting is TRUE then
				put tDataVariableName & "-cb" & tCreationDate & "." & "js" into tJSONfile
			end if

			# DELETE FILE IF CACHE BUSTING SETTING HAS CHANGED
			# OR REPLACE FILE IF FLAG IS TRUE
			# OTHERWISE RETURN EXISTING SOURCE
			if (tReplaceDataFile is TRUE) or (tCbJSONfile is not tDoCacheBusting) then
				try
					delete file tCurrentVal
				catch err
					rigLogMessage "error", "An error occured while deleting file:" && tCurrentVal
				end try

			else
				# RETURN SOURCE
				put tURLbase & tGalleryPath & "/" & tJSONfile into tJSONurl
				return "<script" && tNonce & "src=" & quote & tJSONurl & quote & "></script>"
			end if

			exit repeat
		end if
	end repeat

	# GET FULL PATHS TO THUMBS
	if there is a folder (tPathTranslated & tGalleryPath & "/thumb") then
		put rigGetFileNames(tPathTranslated & tGalleryPath & "/thumb", TRUE,) into tThumbNamesArray
	end if

	# GET FULL PATH TO BIG IMAGES
	if there is a folder (tPathTranslated & tGalleryPath & "/big") then
		put rigGetFileNames(tPathTranslated & tGalleryPath & "/big", TRUE,) into tBigNamesArray
	end if

	#GET GALLERIA META DATA
	set the itemDel to "."
	repeat for each key tKey in tFileNamesArray
		put tFileNamesArray[tKey] into tCurrentVal
		if item -1 of tCurrentVal is "tsv" then
			put tCurrentVal into tMetaDataFile
			put URL format("file:%s", tMetaDataFile) into tMetaData

      	if the result <> empty then
        	rigLogMessage "error", "Failed to read file! System error:" && the sysError
      	end if

			# ESCAPE CHARACTERS
			put rigGalleriaDataEscape(tMetaData) into tMetaData

			exit repeat
		end if
	end repeat

	# START BUILDING GALLERIA JSON DATA
	if tDoCacheBusting is TRUE then
		# STORE TIMESTAMP FOR CACHE BUSTING IN JSON FILE
		put "var creationDate =" & the secs & ";" & return into tGalleriaData
	end if
	put "var" &&  tDataVariableName && "= [" & return & "{" & return after tGalleriaData

	repeat for each line thisLine in tFileNamesList
		set the itemDel to "/"
		# GET IMAGE NAME AND SUFFIX
		put thisLine into tCurrentImagePath
		put item -1 of tCurrentImagePath into tCurrentImage
		set the itemDel to "."
		put item 1 to -2 of tCurrentImage into tCurrentImageName
		put item -1 of tCurrentImage into tCurrentImageSuffix


		# IGNORE META DATA TEXT FILE AND JSON FILE
		if tCurrentImageSuffix is among the words of "jpg jpeg png gif" then

			# CACHE BUSTING
			# GET MODIFICATION DATE	OF IMAGE
			# NOTE: THIS MODIFICATION DATE IS USED FOR THUMBS AND BIG IMAGES TOO
			if tDoCacheBusting is TRUE then
				put rigGetFileInfo(tCurrentImagePath, "lastModified") into tInfoArray
				put tInfoArray["lastModified"] into tLastMod
				put tCurrentImageName & "-cb" & tLastMod & "." & tCurrentImageSuffix into tCurrentImageCB
			else
				put tCurrentImage into tCurrentImageCB
			end if


			# THUMB
			# CHECK IF THERE IS A THUMBNAIL OF THE IMAGE
			put FALSE into tThumb
			if tThumbNamesArray is an array then
				repeat for each element thisElement in tThumbNamesArray
					if tCurrentImage is in thisElement then
						put TRUE into tThumb
						exit repeat
					end if
				end repeat
			end if

			if tThumb is TRUE then
				put tURLbase & tGalleryPath & "/thumb/" & tCurrentImageCB into tThumbURL
			else
				put tURLbase & tGalleryPath & "/" & tCurrentImageCB into tThumbURL
			end if
			replace "/" with ("\/" ) in tThumbURL
			put "thumb: '" & tThumbURL & "'," & return after tGalleriaData


			#IMAGE
			put tURLbase & tGalleryPath & "/" & tCurrentImageCB into tImageURL
			replace "/" with ("\/" ) in tImageURL
			put "image: '" & tImageURL & "'," & return after tGalleriaData

			# BIG
			# CHECK IF THERE IS A BIG VERSION OF THE IMAGE
			put FALSE into tBig
			if tBigNamesArray is an array then
				repeat for each element thisElement in tBigNamesArray
					if tCurrentImage is in thisElement then
						put TRUE into tBig
						exit repeat
					end if
				end repeat
			end if

			if tBig is TRUE then
				put tURLbase & tGalleryPath & "/big/" & tCurrentImageCB into tBigURL
			else
				put tURLbase & tGalleryPath & "/" & tCurrentImageCB into tBigURL
			end if
			replace "/" with ("\/" ) in tBigURL
			put "big: '" & tBigURL & "'," & return after tGalleriaData


			# META DATA
			put lineOffset(tCurrentImage, tMetaData) into tCurrentMetaLineNum
			if tCurrentMetaLineNum <> 0 then
				# GET DATA FOR CURRENT ITEM
				put rigGalleriaItemData(line tCurrentMetaLineNum of tMetaData) after tGalleriaData
			end if

			if char -2 of tGalleriaData is comma then
				delete char -2 of tGalleriaData
			end if

			put "}," & return & "{" & return after tGalleriaData

		end if -- if tCurrentImageSuffix is among the words of "jpg jpeg png gif" then
	end repeat


	# ADD VIDEO AND IFRAME DATA
	put rigGalleriaVideoIframeData(tMetaData, tGalleriaData, tURLbase, tGalleryPath) into tGalleriaData


	delete char -4 to -1 of tGalleriaData

	# BUILD GALLERIA OPTIONS DATA
	put rigGalleriaOptions(tOptions) into tGalleriaDataOptions

	# BUILD INITIALIZATION CODE
	put tGalleriaData & return & "];" & return & "Galleria.run('#" & tContainerID & "', {" & return & "dataSource:" && \
			tDataVariableName & "," & tGalleriaDataOptions & return & "});" into tGalleriaData

	# WRITE JSON FILE
	get rigWriteFile((tPathTranslated & tGalleryPath & "/" & tDataVariableName & ".js"), tGalleriaData)

	# RETURN SOURCE / DATA
	if tReturnReference is TRUE then
		put (tURLbase & tGalleryPath & "/" & tJSONfile) into tJSONurl
		return "<script" && tNonce & "src=" & quote & tJSONurl & quote & "></script>"
	end if

	return tGalleriaData

end rigGalleriaData






/*----------------------------------------------------------------------
--| FUNCTION rigDynamicGalleriaData
--|
--| Author: rabit
--| Version:  1.7
--| Created: 2011-12-27
--| Last Mod: 2020-01-13
--| Requires: rigTrim(), rigFetchConfigItem(), rigGetFileNames(), rigLogMessage,
--| 					rigGetFileInfo()
--|
--| Summary: Return Galleria initialisation code and JSON data based on dynamically generated meta data.
--| 				 The Galleria version currently supported is 1.6.1, see https://galleria.io/.
--|
--| Format:  rigDynamicGalleriaData(param1[, param2][, param3][, param4][, param5][, param6])
--|
--| Parameters: mixed <pMetaData> tab delimeted list of Galleria meta data,
--| 						array <pOptions> Galleria options array (optional),
--| 						string <pContainerID> ID of gallery container (optional),
--| 						string <pDataVariableName> name of JavaScript variable (optional),
--| 						bool <pCacheBuster> compose cache buster file names (optional),
--|             string <pNonce> CSP nonce (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDynamicGalleriaData pMetaData pOptions pContainerID pDataVariableName pCacheBuster pNonce
  local tGalleriaParams, tOptions, tContainerID, tDataVariableName
  local tCacheBuster, tPathTranslated, tDoCacheBusting, tURLbase
  local tGalleriaData, tCurrentImagePath, tGalleryPath, tThumbNamesArray
  local tBigNamesArray, tCurrentImage, tCurrentImageName, tCurrentImageSuffix
  local tInfoArray, tLastMod, tCurrentImageCB, tThumb, tThumbURL, tImageURL
  local tBig, tBigURL, tGalleriaDataOptions, tNonce

	# GET PARAMS FROM FIRST PARAM IF IT IS AN ARRAY
	if pMetaData is an array then
		put pMetaData into tGalleriaParams
		put tGalleriaParams["metaData"] into pMetaData
		put tGalleriaParams["options"] into pOptions
		put tGalleriaParams["containerID"] into pContainerID
		put tGalleriaParams["dataVariableName"] into pDataVariableName
		put tGalleriaParams["cacheBuster"] into pCacheBuster
	end if

	if pMetaData is empty then
		rigLogMessage "error", "No Galleria meta data specified."
		return FALSE
	end if

	# PREPARE PARAMETER VALUES
	# GALLERIA OPTIONS
	# SET DEFAULT VALUE FOR HEIGHT
	if pOptions is not an array then
		put "420" into tOptions["height"]
	else
		put pOptions into tOptions
		if tOptions["height"] is empty then
			put "420" into tOptions["height"]
		end if
	end if

	# ID
	# SET DEFAULT VALUE
	if pContainerID <> empty then
		put pContainerID into tContainerID
	else
		put "galleria" into tContainerID
	end if

	# DATA VARIABLE NAME
	# SET DEFAULT VALUE
	if pDataVariableName <> empty then
		put pDataVariableName into tDataVariableName
	else
		put "galleriaData" into tDataVariableName
	end if

	# CACHE BUSTING
	# SET DEFAULT VALUE
	if pCacheBuster <> "" then
		put pCacheBuster into tCacheBuster
	else
		put TRUE into tCacheBuster
	end if

  # CSP
  if pNonce <> empty then
    put " nonce='" & pNonce & "' " into tNonce
  end if

	# GET PATH TRANSLATED - NEEDED TO GET FILE INFO
	put $_SERVER["PATH_TRANSLATED"] into tPathTranslated

	set the itemDel to "/"

  # FIX FOR RARE CASES WHERE THE SERVER GLOBAL GIVES
  # THE WRONG PATH TO THE CURRENT SCRIPT (index.lc)
  if "index" is not in item -1 of tPathTranslated then
    put gRigA["pathTranslated"] into tPathTranslated
  end if

  # REMOVE index.lc
	put (item 1 to - 2 of tPathTranslated) & "/" into tPathTranslated

	# IS A CACHE BUSTER REQUESTED?
	put rigFetchConfigItem("use_cacheBusters") into tDoCacheBusting
	if (tDoCacheBusting is TRUE) and (tCacheBuster is TRUE) then
		put TRUE into tDoCacheBusting
	else
		put FALSE into tDoCacheBusting
	end if

	# GET BASE URL
	put rigFetchConfigItem("baseUrl") into tURLbase

	# START BUILDING GALLERIA JSON DATA
	put "var" &&  tDataVariableName && "= [" & return & "{" & return into tGalleriaData

	rigLoadHelper "file"

	repeat for each line dataLine in pMetaData

		set the itemDel to "."

		# DON'T PROCESS LINE IF IT IS VIDEO OR IFRAME DATA
		if (item 2 of dataLine <> "youtube") and (item 2 of dataLine <> "dailymotion") and (char -5 to -1 of item 1 of dataLine <> "vimeo") then

			set the itemDel to tab
			put item 1 of dataLine into tCurrentImagePath
			put rigTrim(tCurrentImagePath) into tCurrentImagePath

			if there is not a file (tPathTranslated & tCurrentImagePath) then
				rigLogMessage "error", "Missing Galleria image:" && tCurrentImagePath
				next repeat
			end if

			# GET PATH TO IMAGE FOLDER
			set the itemDel to "/"
			put item 1 to -2 of tCurrentImagePath into tGalleryPath

			# GET FULL PATHS TO THUMBS
			if there is a folder (tGalleryPath & "/thumb") then
				put rigGetFileNames(tGalleryPath & "/thumb", TRUE,) into tThumbNamesArray
			end if

			# GET FULL PATH TO BIG IMAGES
			if there is a folder (tGalleryPath & "/big") then
				put rigGetFileNames(tGalleryPath & "/big", TRUE,) into tBigNamesArray
			end if

			# GET IMAGE NAME AND SUFFIX
			put item -1 of tCurrentImagePath into tCurrentImage
			set the itemDel to "."
			put item 1 to -2 of tCurrentImage into tCurrentImageName
			put item -1 of tCurrentImage into tCurrentImageSuffix

			# CHECK SUFFIX
			if tCurrentImageSuffix is among the words of "jpg jpeg png gif" then

				# CACHE BUSTING
				# GET MODIFICATION DATE	OF IMAGE
				# NOTE: THIS MODIFICATION DATE IS USED FOR THUMBS AND BIG IMAGES TOO
				if tDoCacheBusting is TRUE then
					put rigGetFileInfo(tCurrentImagePath, "lastModified") into tInfoArray
					put tInfoArray["lastModified"] into tLastMod
					put tCurrentImageName & "-cb" & tLastMod & "." & tCurrentImageSuffix into tCurrentImageCB
				else
					put tCurrentImage into tCurrentImageCB
				end if


				# THUMB
				# CHECK IF THERE IS A THUMBNAIL OF THE IMAGE
				put FALSE into tThumb
				if tThumbNamesArray is an array then
					repeat for each element thisElement in tThumbNamesArray
						if tCurrentImage is in thisElement then
							put TRUE into tThumb
							exit repeat
						end if
					end repeat
				end if

				if tThumb is TRUE then
					put tURLbase & tGalleryPath & "/thumb/" & tCurrentImageCB into tThumbURL
				else
					put tURLbase & tGalleryPath & "/" & tCurrentImageCB into tThumbURL
				end if
				replace "/" with ("\/" ) in tThumbURL
				put "thumb: '" & tThumbURL & "'," & return after tGalleriaData


				#IMAGE
				put tURLbase & tGalleryPath & "/" & tCurrentImageCB into tImageURL
				replace "/" with ("\/" ) in tImageURL
				put "image: '" & tImageURL & "'," & return after tGalleriaData


				# BIG
				# CHECK IF THERE IS A BIG VERSION OF THE IMAGE
				put FALSE into tBig
				if tBigNamesArray is an array then
					repeat for each element thisElement in tBigNamesArray
						if tCurrentImage is in thisElement then
							put TRUE into tBig
							exit repeat
						end if
					end repeat
				end if

				if tBig is TRUE then
					put tURLbase & tGalleryPath & "/big/" & tCurrentImageCB into tBigURL
				else
					put tURLbase & tGalleryPath & "/" & tCurrentImageCB into tBigURL
				end if
				replace "/" with ("\/" ) in tBigURL
				put "big: '" & tBigURL & "'," & return after tGalleriaData


				# META DATA
				# GET DATA FOR CURRENT ITEM
				put rigGalleriaDataEscape(dataLine) into dataLine
				put rigGalleriaItemData(dataLine) after tGalleriaData


				if char -2 of tGalleriaData is comma then
					delete char -2 of tGalleriaData
				end if

				put "}," & return & "{" & return after tGalleriaData

			end if -- if tCurrentImageSuffix is among the words of "jpg jpeg png gif" then

		end if -- if (item 2 of dataLine <> "youtube") and

	end repeat -- repeat for each line dataLine in pMetaData


	# ADD VIDEO AND IFRAME DATA
	put rigGalleriaVideoIframeData(pMetaData, tGalleriaData, tURLbase, tGalleryPath, TRUE) into tGalleriaData


	delete char -4 to -1 of tGalleriaData


	# BUILD GALLERIA OPTIONS DATA
	put rigGalleriaOptions(tOptions) into tGalleriaDataOptions

	# BUILD INITIALIZATION CODE
	put tGalleriaData & return & "];" & return & "Galleria.run('#" & tContainerID & "', {" & return & "dataSource:" && \
			tDataVariableName & "," & tGalleriaDataOptions & return & "});" into tGalleriaData

	# RETURN JSON DATA AND INITIALIZATION CODE
	return "<script" & tNonce & ">" & tGalleriaData & "</script>"
end rigDynamicGalleriaData





/*----------------------------------------------------------------------
--| FUNCTION rigGalleriaItemData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 15-04-2012
--| Last Mod: --
--| Requires: --
--|
--| Summary: Build JSON data for a given line of the tsv file.
--|
--| Format:  rigGalleriaItemData(param1)
--|
--| Parameters: string <pDatastring>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigGalleriaItemData pDatastring
  local tTitle, tGalleriaData, tDescription, tLink, tLayer, tOriginal

	set the itemDel to tab

	# TITLE
	put item 2 of pDatastring into tTitle
	if tTitle <> empty then
		put "title:" && "'" & tTitle & "'," & return after tGalleriaData
	end if

	# DESCRIPTION
	put item 3 of pDatastring into tDescription
	if tDescription <> empty then
		put "description:" && "'" & tDescription & "'," & return after tGalleriaData
	end if

	# LINK
	put item 4 of pDatastring into tLink
	if tLink <> empty then
		put "link:" && "'" & tLink & "'," & return after tGalleriaData
	end if

	# LAYER
	put item 5 of pDatastring into tLayer
	if tLayer <> empty then
		put "layer:" && "'" & tLayer & "'," & return after tGalleriaData
	end if

	# ORIGINAL
	put item 6 of pDatastring into tOriginal
	if tOriginal <> empty then
		put "original:" && "'" & tOriginal & "'" & return after tGalleriaData
	end if

	return tGalleriaData
end rigGalleriaItemData







/*----------------------------------------------------------------------
--| FUNCTION rigGalleriaOptions
--|
--| Author: rabit
--| Version:  1.1
--| Created: 14-04-2012
--| Last Mod: 21-03-14
--| Requires: --
--|
--| Summary: Build Galleria options data.
--|
--| Format:  rigGalleriaOptions(param1)
--|
--| Parameters: array <pOptions>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigGalleriaOptions pOptions
  local tKey, tVal, tGalleriaDataOptions

	repeat for each key tKey in pOptions
		put pOptions[tKey] into tVal
		put return & tKey & ":" && tVal & "," after tGalleriaDataOptions
	end repeat

	delete char -1 of tGalleriaDataOptions

	return tGalleriaDataOptions
end rigGalleriaOptions






/*----------------------------------------------------------------------
--| FUNCTION rigGalleriaVideoIframeData
--|
--| Author: rabit
--| Version:  1.1
--| Created: 15-04-2012
--| Last Mod: 21-03-14
--| Requires: rigGalleriaItemData()
--|
--| Summary: Get video and iFrame data from tsv file.
--|
--| Format:  rigGalleriaVideoIframeData(param1, param2, param3, param4)
--|
--| Parameters: string <pMetadata>, string <pGalleriaData>, string <pURLbase>,
--| 						string <pGalleryPath>, bool <pDynamicData>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigGalleriaVideoIframeData pMetadata pGalleriaData pURLbase pGalleryPath pDynamicData
  local tImageDataExists, tLineCount, tItemType, tCurrentDataSection
  local tSectionStartLineNum, tOffsetLineNum, tTotalOffsetLines, tTempGalleriaData
  local tItemThumb, tThumbURL

	# CHECK IF THERE IS IMAGE DATA OR IF THE DATA IS DYNAMICALLY GENERATED
	if (the number of lines of pGalleriaData > 3) or (pDynamicData is TRUE) then
		put TRUE into tImageDataExists
	end if

	# PROCESS VIDEO AND IFRAME URLs
	put 1 into tLineCount
	repeat for each line thisLine in pMetaData
		set the itemDel to "."

		# CHECK IF THERE IS VIDEO OR IFRAME DATA
		if (item 2 of thisLine is "youtube") or (item 2 of thisLine is "dailymotion") or (char -5 to -1 of item 1 of thisLine is "vimeo") then
			put "video" into tItemType
		else if char 1 to 4 of thisLine is "http" then
			put "iframe" into tItemType
		else
			put "image" into tItemType
		end if

		if (tItemType is "video") or (tItemType is "iFrame") then

			# GET THE LINE NUMBER TO APPEND THE DATA TO
			if tImageDataExists then
				put 0 into tCurrentDataSection
				put 0 into tSectionStartLineNum
				put 0 into tOffsetLineNum
			  put 0 into tTotalOffsetLines
				repeat until tCurrentDataSection is (tLineCount)
					put lineOffset("{", pGalleriaData, tSectionStartLineNum) into tOffsetLineNum

					add tOffsetLineNum to tTotalOffsetLines
		      put tTotalOffsetLines into tSectionStartLineNum

					if tOffsetLineNum <> 0 then
						add 1 to tCurrentDataSection
					else
						exit repeat
					end if
				end repeat
			end if

			# META DATA
			set the itemDel to tab
			put tItemType & ": '" & item 1 of thisLine & "'," & return into tTempGalleriaData

			# ADDITIONAL META DATA FOR CURRENT ITEM
			put rigGalleriaItemData(thisLine) after tTempGalleriaData

			# THUMB DATA
			set the itemDel to tab
			put item 7 of thisLine into tItemThumb
			if tItemThumb <> empty then
				if "/" is in tItemThumb then
					# DYNAMICALLY CREATED DATA HAS ROOT RELATIVE PATHS FOR THUMBNAILS
					put pURLbase & tItemThumb into tThumbURL
				else
					put pURLbase & pGalleryPath & "/thumb/" & tItemThumb into tThumbURL
				end if
				replace "/" with ("\/" ) in tThumbURL
				put "thumb: '" & tThumbURL & "'," & return after tTempGalleriaData
			end if

			if char -2 of tTempGalleriaData is comma then
				delete char -2 of tTempGalleriaData
			end if

			put "}," & return & "{" & return after tTempGalleriaData

			# APPEND OR INSERT DATA
			if tImageDataExists then
				# REMOVE RETURN CHARACTER
				delete char -1 of tTempGalleriaData
				put return & tTempGalleriaData after line tTotalOffsetLines of pGalleriaData
			else
				put tTempGalleriaData after pGalleriaData
			end if


		end if
		add 1 to tLineCount
	end repeat

	return pGalleriaData
end rigGalleriaVideoIframeData





/*----------------------------------------------------------------------
--| FUNCTION rigGalleriaDataEscape
--|
--| Author: rabit
--| Version:  1.0
--| Created: 16-04-2012
--| Last Mod: --
--| Requires: --
--|
--| Summary: Return JSON compatible escaped string.
--|
--| Format:  rigGalleriaDataEscape(param1)
--|
--| Parameters: string <pData>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigGalleriaDataEscape pData
	# ESCAPE CHARACTERS
	replace "\" with ("\\" ) in pData
	replace "/" with ("\/" ) in pData
	replace "'" with ("\'" ) in pData

	return pData
end rigGalleriaDataEscape










--| END OF galleriaHelper.livecodescript
--| Location:  ./system/helpers/galleriaHelper.livecodescript
----------------------------------------------------------------------
