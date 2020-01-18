script "assetHelper"

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
# revIgniter Asset Helper
# modeled on asset_helpers from Philip Sturgeon
#
# @package		revIgniter
# @subpackage	Helpers
# @category	  Helpers
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/helpers/assetHelper.html
##

## ------------------------------------------------------------------------




global gRigA

local sImageFolder, sJavascriptFolder, sCSSfolder, sCacheBusterList, sStackInUse





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-19
 --| Last Mod: --
 --| Requires: --
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
      put "img" into sImageFolder
      put "js" into sJavascriptFolder
      put "css" into sCSSfolder
      #
    end if

  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack






/*----------------------------------------------------------------------
--| FUNCTION _rigOtherAssetURL
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-10-09
--| Last Mod: 11-07-10
--| Requires: rigFetchConfigItem(), _rigCbName()
--|
--| Summary: General Asset Helper - Helps generate links to asset files of any sort.
--|            Asset type should be the name of the folder they are stored in.
--|
--| Format:  _rigOtherAssetURL(param1, param2, param3, param4)
--|
--| Parameters: string <pAsset> the name of the file or asset, string <pType> the asset type (name of folder),
--|               string <pModule> optional module name,
--|               bool <pCacheBuster> compose cache buster file names (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigOtherAssetURL pAsset pType pModule pCacheBuster
  local tCacheBuster, tModulesPath, tBaseURL, tAssetsLoc, tDoCacheBusting
  local tTempAssetsLoc, tAsset

	if pCacheBuster <> "" then
		put pCacheBuster into tCacheBuster
	else
		put TRUE into tCacheBuster
	end if

	if pModule is not empty then
		put "modules/" & pModule into tModulesPath
	else
		put "" into tModulesPath
	end if

	put rigFetchConfigItem("baseUrl") into tBaseURL
	put rigFetchConfigItem("assetsLocation") into tAssetsLoc

	if tAssetsLoc is empty then
		put "assets" into tAssetsLoc
	end if

	# IS A CACHE BUSTER REQUESTED?
	put rigFetchConfigItem("use_cacheBusters") into tDoCacheBusting
	if (tDoCacheBusting is TRUE) and (tCacheBuster is TRUE) then
		if tModulesPath is not empty then
			put tAssetsLoc & "/" & tModulesPath into tTempAssetsLoc
		else
			put tAssetsLoc into tTempAssetsLoc
		end if

		put _rigCbName(pAsset, pType, tTempAssetsLoc) into tAsset
	else
		put pAsset into tAsset
	end if

	put tBaseURL & tAssetsLoc & "/" into tAssetsLoc

	if tModulesPath is not empty then
		put tModulesPath & "/" after tAssetsLoc
	end if

	put pType & "/" & tAsset after tAssetsLoc

	return tAssetsLoc
end _rigOtherAssetURL









/*----------------------------------------------------------------------
--| FUNCTION _rigParseAssetHTML
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-10-09
--| Last Mod: 06-10-09
--| Requires: --
--|
--| Summary: Turns an array of attributes into a string.
--|
--| Format:  _rigParseAssetHTML(param1)
--|
--| Parameters: array <pAttributes> attributes to be parsed
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigParseAssetHTML pAttributes
  local tKey, tVal, tAttributeStr

	if pAttributes is an array then
		repeat for each key tKey in pAttributes
			put pAttributes[tKey] into tVal

			put " " & tKey & "=" & quote & tVal & quote after tAttributeStr
		end repeat

		return tAttributeStr
	end if

	return ""
end _rigParseAssetHTML




/*----------------------------------------------------------------------
--| FUNCTION _rigCssAssetURL
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-10-09
--| Last Mod: 11-07-10
--| Requires: _rigOtherAssetURL()
--|
--| Summary: Helps generate CSS asset locations.
--|
--| Format:  _rigCssAssetURL(param1, param2)
--|
--| Parameters: string <pAsset> the name of the file or asset, string <pModule> optional module name
--|               bool <pCacheBuster> compose cache buster file names (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCssAssetURL pAsset pModule pCacheBuster
	return _rigOtherAssetURL(pAsset, sCSSfolder, pModule, pCacheBuster)
end _rigCssAssetURL








/*----------------------------------------------------------------------
--| FUNCTION rigCssAsset
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-10-09
--| Last Mod: 11-07-10
--| Requires: _rigParseAssetHTML(), _rigCssAssetURL()
--|
--| Summary: Generate css asset location html code.
--|
--| Format:  rigCssAsset(param1, param2, param3, param4)
--|
--| Parameters: string <pAsset> the name of the file or asset, array <pAttributes> optional extra attributes
--|             string <pModule> optional module name
--|             bool <pCacheBuster> compose cache buster file names (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigCssAsset pAsset pAttributes pModule pCacheBuster
  local tAttributeStr, tAssetUrl

	put _rigParseAssetHTML(pAttributes) into tAttributeStr
	put _rigCssAssetURL(pAsset, pModule, pCacheBuster) into tAssetUrl

	return "<link href=" & quote & tAssetUrl & quote && "rel=" & quote & "stylesheet" & quote && "type=" & quote & "text/css" & quote && tAttributeStr && "/>"
end rigCssAsset






/*----------------------------------------------------------------------
--| FUNCTION rigDynamicCssAsset
--|
--| Author: rabit
--| Version:  1.2
--| Created: 09-06-2011
--| Last Mod: 02-02-2015
--| Requires: _rigParseAssetHTML(), rigFetchConfigItem, rigLogMessage, _rigCssAssetURL
--|
--| Summary: Simple CSS preprocessor which dynamically generates CSS files using the
--|            gData array variable and a raw css file. File name prototype: <filename>.css.lc
--|
--| Format:  rigDynamicCssAsset(param1, param2, param3, param4)
--|
--| Parameters: string <pRawCSS> the name of the raw css file to be processed,
--|               array <pAttributes> optional extra attributes, string <pModule> optional module name
--|               bool <pCacheBuster> compose cache buster file names (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDynamicCssAsset pRawCSS pAttributes pModule pCacheBuster
  local tAttributeStr, tCurrentItemDel, tCSS, tModulesPath, tBasePath
  local tAssetsLoc, tRawCssPath, tCssPath, tCSSdata, tAssetUrl

	put _rigParseAssetHTML(pAttributes) into tAttributeStr

	# SET NAME OF CSS FILE TO BE GENERATED
	put the itemDel into tCurrentItemDel
	set the itemDel to "."
	put item 1 to -2 of pRawCSS into tCSS
	set the itemDel to tCurrentItemDel

	# BUILD PATHS TO ASSETS (RAW CSS AND CSS TO BE GENERATED)
	if pModule is not empty then
		put "modules/" & pModule into tModulesPath
	else
		put "" into tModulesPath
	end if

	put item 1 to -2 of gRigA["BASEPATH"] into tBasePath
	put rigFetchConfigItem("assetsLocation") into tAssetsLoc

	if tAssetsLoc is empty then
		put "assets" into tAssetsLoc
	end if

	put tBasePath & tAssetsLoc & "/" into tAssetsLoc

	if tModulesPath is not empty then
		put tModulesPath & "/" after tAssetsLoc
	end if

	put sCSSfolder & "/" after tAssetsLoc

	put tAssetsLoc & pRawCSS into tRawCssPath
	put tAssetsLoc & tCSS into tCssPath

	# MERGE RAW FILE AND SAVE CSS TO BE LINKED TO
	if there is a file tRawCssPath then
  	put URL ("binfile:" & tRawCssPath) into tCSSdata

    if the result is empty then
      put merge(tCSSdata) into tCSSdata
      put tCSSdata into URL ("binfile:" & tCssPath)

		  if the result <> empty then
		    rigLogMessage "error", "Failed to write file! System error:" && the sysError
		  end if

    else
      rigLogMessage "error", "Failed to read file! System error:" && the sysError
    end if

	else
		rigLogMessage "error", "Raw CSS file" && quote & tRawCssPath & quote && "missing!"
	end if

	put _rigCssAssetURL(tCSS, pModule, pCacheBuster) into tAssetUrl

	return "<link href=" & quote & tAssetUrl & quote && "rel=" & quote & "stylesheet" & quote && "type=" & quote & "text/css" & quote && tAttributeStr && "/>"
end rigDynamicCssAsset






/*----------------------------------------------------------------------
--| FUNCTION rigImgAssetURL
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-10-09
--| Last Mod: 11-07-10
--| Requires: _rigOtherAssetURL()
--|
--| Summary: Helps generate image asset locations.
--|
--| Format:  rigImgAssetURL(param1, param2, param3)
--|
--| Parameters: string <pAsset> the name of the file or asset, string <pModule> optional module name,
--|               bool <pCacheBuster> compose cache buster file names (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigImgAssetURL pAsset pModule pCacheBuster
	return _rigOtherAssetURL(pAsset, sImageFolder, pModule, pCacheBuster)
end rigImgAssetURL








/*----------------------------------------------------------------------
--| FUNCTION rigImageAsset
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-10-09
--| Last Mod: 11-07-10
--| Requires: _rigParseAssetHTML(), rigImgAssetURL()
--|
--| Summary: Generate image asset location html code.
--|
--| Format:  rigImageAsset(param1, param2, param3, param4)
--|
--| Parameters: string <pAsset> the name of the file or asset, array <pAttributes> optional extra attributes
--|               string <pModule> optional module name,
--|               bool <pCacheBuster> compose cache buster file names (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigImageAsset pAsset pAttributes pModule pCacheBuster
  local tAttributeStr, tAssetUrl

	put _rigParseAssetHTML(pAttributes) into tAttributeStr
	put rigImgAssetURL(pAsset, pModule, pCacheBuster) into tAssetUrl

	return "<img src=" & quote & tAssetUrl & quote && tAttributeStr && "/>"
end rigImageAsset








/*----------------------------------------------------------------------
--| FUNCTION rigJsAssetURL
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-10-06
--| Last Mod: 2018-01-25
--| Requires: _rigOtherAssetURL()
--|
--| Summary: Helps generate JavaScript asset locations.
--|
--| Format:  rigJsAssetURL(param1, param2, param3)
--|
--| Parameters: string <pAsset> the name of the file or asset,
--|               string <pModule> optional module name
--|               bool <pCacheBuster> compose cache buster file names (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJsAssetURL pAsset pModule pCacheBuster
  local tURL

	put _rigOtherAssetURL(pAsset, sJavascriptFolder, pModule, pCacheBuster) into tURL

	if char 1 to 4 of tURL is "http" then
		set the itemDel to "/"
		put "//" & item 3 to -1 of tURL into tURL
	end if

	return tURL
end rigJsAssetURL









/*----------------------------------------------------------------------
--| FUNCTION rigJsAsset
--|
--| Author: rabit
--| Version:  1.8
--| Created: 2009-10-06
--| Last Mod: 2020-01-14
--| Requires: rigJsAssetURL()
--|
--| Summary: Generate JavaScript asset location html code. If you want to use
--|          the Google Apis CDN to serve an open-source JavaScript library you
--|          can do so by naming the asset (the first parameter) like: jsGoogleapis-<name>-<version>
--|          Example: rigJsAsset("jsGoogleapis-jquery-1.4.2") or rigJsAsset("jsGoogleapis-dojo-1.5")
--|          For a list of available libraries see:
--|          http://code.google.com/apis/libraries/devguide.html
--|
--| Format:  rigJsAsset(param1[, param2][, param3][, param4][, param5])
--|
--| Parameters: string <pAsset> the name of the file or asset,
--|             string <pModule> optional module name,
--|             bool or string <pCacheBusterOrFallbackAsset> compose cache buster file names
--|             (optional) / fallback asset in case a request to jsGoogleapis is not possible (optional),
--|					    string <pAttribute> async and / or defer attribute (optional)
--|             string <pNonce> CSP nonce (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJsAsset pAsset pModule pCacheBusterOrFallbackAsset pAttribute pNonce
  local tAttribute, tAssetUrl, tLib, tVersion
  local tLibName, tObject, tScriptReference, tNonce

	if (pAttribute is "async") or (pAttribute is "defer") or (pAttribute is "async defer") then
		put " " & pAttribute into tAttribute
	end if

  if pNonce <> empty then
    put " nonce='" & pNonce & "'" into tNonce
  end if

   if char 1 to 12 of pAsset <> "jsGoogleapis" then
      put rigJsAssetURL(pAsset, pModule, pCacheBusterOrFallbackAsset) into tAssetUrl

      return "<script" & tAttribute & tNonce && "src=" & quote & tAssetUrl & quote & "></script>"
   else
      set the itemDelimiter to "-"
      put item 2 of pAsset into tLib
      put item 3 of pAsset into tVersion

      switch tLib
         case "dojo"
            put "dojo.xd.js" into tLibName
						put "dojo" into tObject
            break
         case "ext-core"
            put "ext-core.js" into tLibName
						put "Ext" into tObject
            break
         case "jquery"
            put "jquery.min.js" into tLibName
						put "jQuery" into tObject
            break
         case "jqueryui"
            put "jquery-ui.min.js" into tLibName
						put "jQuery.ui" into tObject
            break
         case "mootools"
            put "mootools-yui-compressed.js" into tLibName
						put "MooTools" into tObject
            break
         case "prototype"
            put "prototype.js" into tLibName
						put "prototype" into tObject
            break
         case "scriptaculous"
            put "scriptaculous.js" into tLibName
						put "Scriptaculous" into tObject
            break
         case "swfobject"
            put "swfobject.js" into tLibName
						put "swfobject" into tObject
            break
         case "yui"
            put "yuiloader-min.js" into tLibName
						put "YUI" into tObject
            break
         case "webfont"
            put "webfont.js" into tLibName
						put "WebFont" into tObject
            break
         default
            put "NA" into tLibName
      end switch

			if pCacheBusterOrFallbackAsset is empty then
  			return "<script" & tAttribute & tNonce && "src=" & quote & "//ajax.googleapis.com/ajax/libs/" & tLib & "/" & tVersion & "/" & tLibName & quote && tAttribute & "></script>"
			end if

			put rigJsAssetURL(pCacheBusterOrFallbackAsset, pModule) into tAssetUrl

						put "<script" & tAttribute & tNonce && "src='//ajax.googleapis.com/ajax/libs/" & tLib & "/" & tVersion & "/" & tLibName & "'></script>" & return \
			& "<script>window." & tObject && "|| document.write(" & quote & "<script" & tAttribute & tNonce && "src='" & tAssetUrl & "'>\x3C/script>" & quote & ")</script>" into tScriptReference

			return tScriptReference
		end if
end rigJsAsset








/*----------------------------------------------------------------------
--| FUNCTION rigAddFavicon
--|
--| Author: rabit
--| Version:  1.1
--| Created: 11-11-09
--| Last Mod: 11-07-10
--| Requires: rigFetchConfigItem(), _rigCbName()
--|
--| Summary: Generates a link tag using the base url that points to favicon.
--|
--| Format:  rigAddFavicon(param1, param2)
--|
--| Parameters: string <pModule> optional module name,
--|               bool <pCacheBuster> compose cache buster file names (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigAddFavicon pModule pCacheBuster
  local tCacheBuster, tAsset, tBase, tAssetsLoc, tModulesPath, tDoCacheBusting
  local tTempAssetsLoc

	if pCacheBuster <> "" then
		put pCacheBuster into tCacheBuster
	else
		put TRUE into tCacheBuster
	end if

	put "favicon.ico" into tAsset
	put rigFetchConfigItem("baseUrl") into tBase
	put rigFetchConfigItem("assetsLocation") into tAssetsLoc

	if pModule is not empty then
		put "modules/" & pModule into tModulesPath
	else
		put "" into tModulesPath
	end if

	if tAssetsLoc is empty then
		put "assets" into tAssetsLoc
	end if

	# IS A CACHE BUSTER REQUESTED?
	put rigFetchConfigItem("use_cacheBusters") into tDoCacheBusting
	if tDoCacheBusting is TRUE then
		if tModulesPath is not empty then
			put tAssetsLoc & "/" & tModulesPath into tTempAssetsLoc
		else
			put tAssetsLoc into tTempAssetsLoc
		end if

		put _rigCbName(tAsset, sImageFolder, tTempAssetsLoc) into tAsset
	end if

	if tModulesPath is not empty then
		put "/" & tModulesPath & "/" after tAssetsLoc
	else
		put "/" after tAssetsLoc
	end if

	return "<link rel=" & quote & "shortcut icon" & quote && "href=" & quote & tBase & tAssetsLoc & sImageFolder & "/" & tAsset & quote && "/>" & return
end rigAddFavicon








/*----------------------------------------------------------------------
--| FUNCTION _rigCbName
--|
--| Author: rabit
--| Version:  1.3
--| Created:  2010-07-11
--| Last Mod: 2019-01-12
--| Requires: --
--|
--| Summary: Includes the modification time with the name of a given file
--|            <name>-cb<lastModified>.<suffix>
--|            Note: A mod_rewrite RewriteRule is needed to redirect to the original file!
--|
--| Format:  _rigCbName(param1, param2, param3)
--|
--| Parameters: string <pAsset>, string <pType>, string <pAssetsLoc>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCbName pAsset pType pAssetsLoc
  local tRootPath, tAssetFilter, tAssetPath, tFolder, tFileList, tInfo
  local tLastMod, tAssetName, tAssetSuffix, tAssetCB

	# GET SERVER PATH TO THE ROOT DIRECTORY
	set the itemDelimiter to "/"
	put (item 1 to -2 of gRigA["BASEPATH"]) & "/" into tRootPath

	# CHECK IF FILE IS NESTED IN FOLDERS
	put "" into tAssetFilter
	put "" into tAssetPath
	if "/" is in pAsset then
		put item -1 of pAsset into tAssetFilter
		put (item 1 to -2 of pAsset) & "/" into tAssetPath
	end if

	# COMPOSE SERVER PATH TO LOCATION OF ASSET
	put tRootPath & pAssetsLoc & "/" & pType & "/" & tAssetPath into tFolder

	# GET FILE LIST OF FOLDER
  put urldecode(files(tFolder, "detailed")) into tFileList

	# GET FILE INFORMATION
	if tAssetFilter <> "" then
		filter tFileList with tAssetFilter & "*"
	else
		filter tFileList with pAsset & "*"
	end if
	put tFileList into tInfo

	set the itemDelimiter to comma

	# GET TIME OF LAST MODIFICATION
	put item 5 of tInfo into tLastMod

	set the itemDelimiter to "."

	# BUILD NEW FILE NAME
	put item 1 to -2 of pAsset into tAssetName
	put item -1 of pAsset into tAssetSuffix
	put tAssetName & "-cb" & tLastMod & "." & tAssetSuffix into tAssetCB

	# ADD NAME TO CACHE BUSTER LIST (USED BY rigWriteManifest)
	put tAssetCB & "," after sCacheBusterList

	return tAssetCB
end _rigCbName





/*----------------------------------------------------------------------
--| COMMAND rigWriteManifest
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2011-10-05
--| Last Mod: 2019-08-28
--| Requires: rigTrim() (in Common.lc), rigLoadHelper, rigGetFileNames(),
--|					rigWriteFile(), rigHexDigest() (in Common.lc), rigGetFileInfo()
--|
--| Summary: Write a manifest file used to store resources in the HTML5 application cache.
--|
--| Format:  rigWriteManifest param1, param2, param3, param4, param5, param6
--|
--| Parameters: string <pResourcesDir> root relative path to resources to be cached,
--| 						 string <pManifestName> name of manifest file, bool <pUseAbsoluteURI>
--| 						 whether to write absolute URIs (optional), mixed <pResourcesOnlineOnly> the NETWORK
--| 						 section (optional), array <pFallbackResources> the FALLBACK section (optional),
--| 						 string <pDirToIgnore> the directory containing files to be excluded from caching (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigWriteManifest pResourcesDir pManifestName pUseAbsoluteURI pResourcesOnlineOnly pFallbackResources pDirToIgnore
  local tResourcesDir, tDirToIgnore, tUseAbsoluteURI, tKey, tResourcesOnlineOnly
  local tFallbackResources, tFallbackOnlineResourcesList, tPathTranslated
  local tDoCacheBusting, tURLbase, tFileNamesArray, tDirNameOffset
  local tManifest, tNETWORKitems, tCurrentVal, tFile, tAbsoulteFilePath
  local tInfoArray, tLastMod, tAsset, tIsFallbackOnlineResource
  local tAssetName, tAssetSuffix, tAssetCB, tAddToCacheList, tOfflineResource
  local tOnlineResource, tOnlineAsset, tOnlineResourceInfoArray, tOnlineAssetLastMod
  local tOnlineAssetName, tOnlineAssetSuffix, tOnlineAssetCB, tModDates
  local tProcessedFallbackItems, tNetworkWildcardSet

	# PREPARE PARAMETER VALUES
	put rigTrim(pResourcesDir, "/") into tResourcesDir
	put rigTrim(pDirToIgnore, "/") into tDirToIgnore

	if pUseAbsoluteURI is empty then
		put FALSE into tUseAbsoluteURI
	else
		put pUseAbsoluteURI into tUseAbsoluteURI
	end if

	if pResourcesOnlineOnly is an array then
		repeat for each key tKey in pResourcesOnlineOnly
			put pResourcesOnlineOnly[tKey] & "," after tResourcesOnlineOnly
		end repeat
	else
		put pResourcesOnlineOnly into tResourcesOnlineOnly
	end if

	# GET LIST OF FALLBACK ONLINE RESOURCES
	set the itemDel to "/"
	if pFallbackResources is an array then
		put return & "FALLBACK:" & return into tFallbackResources
		repeat for each key tKey in pFallbackResources
			if tKey <> "/" then
				put (item -1 of tKey) & "," after tFallbackOnlineResourcesList
			else
				put tKey & "," after tFallbackOnlineResourcesList
			end if
		end repeat
	end if

	# GET PATH TRANSLATED - NEEDED TO GET FILE INFO
	put $_SERVER["PATH_TRANSLATED"] into tPathTranslated

  # FIX FOR RARE CASES WHERE THE SERVER GLOBAL GIVES
  # THE WRONG PATH TO THE CURRENT SCRIPT (index.lc)
  if "index" is not in item -1 of tPathTranslated then
    put gRigA["pathTranslated"] into tPathTranslated
  end if

	# REMOVE index.lc
	put (item 1 to - 2 of tPathTranslated) & "/" into tPathTranslated

	# IS A CACHE BUSTER REQUESTED?
	put rigFetchConfigItem("use_cacheBusters") into tDoCacheBusting

	# GET BASE URL
	put rigFetchConfigItem("baseUrl") into tURLbase

	# GET FULL PATHS TO FILES
	rigLoadHelper "file"
	put rigGetFileNames(tResourcesDir, TRUE, TRUE) into tFileNamesArray

	# GET OFFSET OF NAME OF RESOURCES DIRECTORY TO WRITE ROOT RELATIVE FILE PATHS
	set the wholeMatches to true
	put itemOffset(tResourcesDir, tFileNamesArray[1]) into tDirNameOffset

	# START BUILDING MANIFEST
	put "CACHE MANIFEST" & return into tManifest
	put "" into tNETWORKitems
  put "" into tNetworkWildcardSet

	repeat for each key tKey in tFileNamesArray
		put tFileNamesArray[tKey] into tCurrentVal

		# DON'T LIST FILES IN DIRECTORIES DEFINED TO BE IGNORED
		if (tDirToIgnore is empty) or ((tDirToIgnore is not empty) and (tDirToIgnore is not among the items of tCurrentVal)) then
			# GET FILE PATH AND MODIFICATION DATE
			if tUseAbsoluteURI is TRUE then
				put tURLbase & (item tDirNameOffset to -1 of tCurrentVal) into tFile
			else
				put item tDirNameOffset to -1 of tCurrentVal into tFile
			end if

			# GET MODIFICATION DATE
			put tPathTranslated & (item tDirNameOffset to -1 of tCurrentVal) into tAbsoulteFilePath
			put rigGetFileInfo(tAbsoulteFilePath, "lastModified") into tInfoArray

			put tInfoArray["lastModified"] into tLastMod

			put item -1 of tFile into tAsset

			# CHECK IF CURRENT ITEM IS A FALLBACK ONLINE RESOURCE
			put FALSE into tIsFallbackOnlineResource
			set the itemDelimiter to ","
			if tAsset is among the items of tFallbackOnlineResourcesList then
				put TRUE into tIsFallbackOnlineResource
			end if

			# BUILD CACHE BUSTER FILE NAME
			if (tDoCacheBusting is TRUE) and (tIsFallbackOnlineResource is FALSE) then
				set the itemDelimiter to "."
				put item 1 to -2 of tAsset into tAssetName
				put item -1 of tAsset into tAssetSuffix
				put tAssetName & "-cb" & tLastMod & "." & tAssetSuffix into tAssetCB
				set the itemDel to ","

				# DON'T USE CACHE BUSTER NAME IF ASSET WAS EXCLUDED FROM BEING CACHE BUSTED
				if tAssetCB is among the items of sCacheBusterList then
					set the itemDel to "/"
					replace (item -1 of tFile) with tAssetCB in tFile
				end if

			end if

			set the itemDel to ","
			if (tResourcesOnlineOnly is empty) or ((tResourcesOnlineOnly is not empty) and (tAsset is not among the items of tResourcesOnlineOnly)) then

				# FALLBACK SECTION
				# CHECK IF CURRENT ITEM IS A FALLBACK OFFLINE RESOURCE
				put TRUE into tAddToCacheList
				if pFallbackResources is an array then
					repeat for each key tKey in pFallbackResources
						put pFallbackResources[tKey] into tOfflineResource
						put tKey into tOnlineResource

						set the itemDel to "/"
						if item -1 of tOfflineResource is tAsset then
							put FALSE into tAddToCacheList

							# BUILD FALLBACK ONLINE FILE PATH
							if tKey <> "/" then
								if char 1 to 4 of tOnlineResource is not "http" then
									if char 1 of tOnlineResource is "/" then
										put char 2 to -1 of tOnlineResource into tOnlineResource
										else if (char 1 of tOnlineResource is ".") and (char 2 of tOnlineResource is "/") then
											put char 3 to -1 of tOnlineResource into tOnlineResource
										end if
									end if

								else
									put tKey into tOnlineResource
								end if


							# BUILD CACHE BUSTER FILE NAME
							if ("." is in tOnlineResource) and (tDoCacheBusting is TRUE) then
								put item -1 of tOnlineResource into tOnlineAsset

								put rigGetFileInfo(tOnlineResource, "lastModified") into tOnlineResourceInfoArray
								put tOnlineResourceInfoArray["lastModified"] into tOnlineAssetLastMod

								set the itemDelimiter to "."
								put item 1 to -2 of tOnlineAsset into tOnlineAssetName

								put item -1 of tOnlineAsset into tOnlineAssetSuffix
								put tOnlineAssetName & "-cb" & tOnlineAssetLastMod & "." & tOnlineAssetSuffix into tOnlineAssetCB
								set the itemDel to ","

								# DON'T USE CACHE BUSTER NAME IF ASSET WAS EXCLUDED FROM BEING CACHE BUSTED
								if tOnlineAssetCB is among the items of sCacheBusterList then
									set the itemDel to "/"
									replace (item -1 of tOnlineResource) with tOnlineAssetCB in tOnlineResource
								end if

							end if -- if ("." is in tOnlineResource) and (tDoCacheBusting is TRUE)

							# COMPLEMENT FALLBACK LIST AND MODIFICATION DATES
							if (tUseAbsoluteURI is TRUE) and (char 1 to 4 of tOnlineResource is not "http") then
								if tOnlineResource <> "/" then
									put tURLbase & tOnlineResource && tFile & return after tFallbackResources
								else
									put tURLbase && tFile & return after tFallbackResources
								end if
							else
								put tOnlineResource && tFile & return after tFallbackResources
							end if

							put tLastMod after tModDates

							put tKey & "," after tProcessedFallbackItems

							exit repeat

						end if -- if item -1 of tOfflineResource is tAsset

					end repeat -- repeat for each key tKey in pFallbackResources

					set the itemDel to ","
				end if -- if pFallbackResources is an array
				#

				# ADD FILE PATH TO MANIFEST AND ADD MODIFICATION DATE
				if (tAddToCacheList is TRUE) and (tIsFallbackOnlineResource is FALSE) then
					put tFile & return after tManifest
					put tLastMod after tModDates
				end if
			end if -- if (tResourcesOnlineOnly is empty) or . . .

			# NETWORK SECTION
			# ADD FILE PATH TO NETWORK SECTION
			if (tResourcesOnlineOnly is not empty) and (tAsset is among the items of tResourcesOnlineOnly) then
				if tNETWORKitems is empty then
					put return & "NETWORK:" & return & tFile & return into tNETWORKitems
				else
					put tFile & return after tNETWORKitems
				end if
			else if tResourcesOnlineOnly is "*" then
				if tNetworkWildcardSet is not TRUE then
					if tNETWORKitems is empty then
						put return & "NETWORK:" & return & "*" & return into tNETWORKitems
					else
						put "*" & return after tNETWORKitems
					end if
					put TRUE into tNetworkWildcardSet
				end if
			end if
			#

			set the itemDel to "/"
		end if
	end repeat

	# COMPLEMENT FALLBACK LIST
	if pFallbackResources is an array then
		if tProcessedFallbackItems is not empty then
			delete char -1 of tProcessedFallbackItems
		end if

		set the itemDel to ","

		repeat for each key tKey in pFallbackResources

			if tKey is not among the items of tProcessedFallbackItems then
				put pFallbackResources[tKey] into tOfflineResource

				if char 1 of tOfflineResource is "/" then
					delete char 1 of tOfflineResource
				end if

				put tKey into tOnlineResource

				if tKey <> "/" then
					if char 1 to 4 of tOnlineResource is not "http" then
						if char 1 of tOnlineResource is "/" then
							put char 2 to -1 of tOnlineResource into tOnlineResource
							else if (char 1 of tOnlineResource is ".") and (char 2 of tOnlineResource is "/") then
								put char 3 to -1 of tOnlineResource into tOnlineResource
							end if
						end if
					else
						put tKey into tOnlineResource
					end if

					if (tUseAbsoluteURI is TRUE) and (char 1 to 4 of tOnlineResource is not "http") then
						if tOnlineResource <> "/" then
							put tURLbase & tOnlineResource && tURLbase & tOfflineResource & return after tFallbackResources
						else
							put tURLbase && tURLbase & tOfflineResource & return after tFallbackResources
						end if
					else
						put tOnlineResource && tOfflineResource & return after tFallbackResources
					end if

				end if -- if tKey is not among the items of tProcessedFallbackItems
			end repeat
		end if -- if pFallbackResources is an array


	# APPAND NETWORK AND FALLBACK RESOURCES TO MANIFEST
	put tManifest & tNETWORKitems & tFallbackResources into tManifest

	# BUILD AND APPEND HASH OF MODIFICATION DATES STRING
	put "# Hash:" && rigHexDigest(tModDates) & return after tManifest

	# ALL DONE, MANIFEST IS READY TO BE USED
	get rigWriteFile("./" & pManifestName & ".manifest", tManifest)
end rigWriteManifest







--| END OF assetHelper.livecodescript
--| Location:  ./system/helpers/assetHelper.livecodescript
----------------------------------------------------------------------
