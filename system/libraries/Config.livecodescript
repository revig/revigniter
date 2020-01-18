script "Config"

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
# revIgniter Config Library
#
# This library contains functions that enable config files to be managed
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Libraries
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/config.html
##




global gRigA, gConfig

local sConfigIsLoaded, sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-11-30
 --| Last Mod: --
 --| Requires: rigLogMessage, _setBaseURL
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
    if sStackInUse <> TRUE then
      put TRUE into sStackInUse

      # LOGGING
      if the environment is "server" then
        rigLogMessage "debug", "Config Library Loaded"
      end if

      # CALL INITIAL HANDLERS
      _setBaseURL
    end if

  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack





/*----------------------------------------------------------------------
--| COMMAND _setBaseURL
--|
--| Author: rabit
--| Version:  1.3
--| Created: 01-10-2012
--| Last Mod: 10-05-2015
--| Requires: rigFetchConfigItem(), rigSetConfigItem
--|
--| Summary: Set the base URL if none was provided in system/application/config.lc.
--|
--| Format:  _setBaseURL
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _setBaseURL
  local tHTTPhost, tHTTPs, tRequestURI, tBaseURL, tQueryString, tQueryOffset

	if rigFetchConfigItem("baseUrl") is empty then

		put $_SERVER["HTTP_HOST"] into tHTTPhost

		if tHTTPhost <> empty then
			put $_SERVER["HTTPS"] into tHTTPs
			put $_SERVER["REQUEST_URI"] into tRequestURI

			if (tHTTPs <> empty) and (tHTTPs <> "off") then
				put "https" into tBaseURL
			else
				put "http" into tBaseURL
			end if

			put "://" & tHTTPhost after tBaseURL

      if $_SERVER["QUERY_STRING"] <> empty then

        put $_SERVER["QUERY_STRING"] into tQueryString
        put replacetext(tQueryString,"[ ]+","%20") into tQueryString

        put offset(tQueryString, tRequestURI) into tQueryOffset
        put char 1 to tQueryOffset of tRequestURI after tBaseURL

      else
       put "/" after tBaseURL
     end if

		else
			put "http://localhost/" into tBaseURL
		end if -- if tHTTPhost <> empty then

		rigSetConfigItem "baseUrl", tBaseURL
	end if
end _setBaseURL






/*----------------------------------------------------------------------
--| FUNCTION rigLoadConfigFile
--|
--| Author: rabit
--| Version:  1.4
--| Created: 30-06-09
--| Last Mod: 08-12-15
--| Requires: rigIsMainConfigLoaded(), rigShowError, rigLogMessage
--|
--| Summary: Loads any configuration file.
--|
--| Format:  rigLoadConfigFile(param1, param2, param3, param4)
--|
--| Parameters: string <pConfigFile>, bool <pUseSections>, bool <pFailGracefully>, string <pModule> the module name (optional)
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigLoadConfigFile pConfigFile pUseSections pFailGracefully pModule
  local tConfigIsLoadedKeyNum, tConfigFileName, tIsInConfigArray, tModulePath, tFilepath
  local tCurrentConfigItemNum, tNewConfigItemNum, tSectionArray

	if sConfigIsLoaded is an array then
		put the number of lines in the keys of sConfigIsLoaded into tConfigIsLoadedKeyNum
	else
		put 0 into tConfigIsLoadedKeyNum
	end if

	if pConfigFile is empty then
    put "config" into tConfigFileName

    if pModule is empty then

		  if rigIsMainConfigLoaded() is TRUE then
			  add 1 to tConfigIsLoadedKeyNum
			  put "config" into sConfigIsLoaded[tConfigIsLoadedKeyNum]
		  end if

    else -- if pModule is empty then
      put pModule & "/config" into tConfigFileName
	  end if -- if pModule is empty then

  else -- if pConfigFile is empty then
    # REMOVE SUFFIX
    if pModule is empty then
      put pConfigFile into tConfigFileName
      replace ".livecodescript" with "" in tConfigFileName
    else
      put pModule & "/" & pConfigFile into tConfigFileName
      replace ".livecodescript" with "" in tConfigFileName
    end if
  end if -- if pConfigFile is empty then

	put FALSE into tIsInConfigArray
	repeat for each element thisElement in sConfigIsLoaded
		if thisElement is tConfigFileName then
			put TRUE into tIsInConfigArray
			exit repeat
		end if
	end repeat
	 if tIsInConfigArray is TRUE then
		return TRUE
	end if

  put empty into tModulePath

  # CHECK IF WE ARE DEALING WITH A CONFIG FILE OF A MODULE
  if pModule <> empty then
    # GET PATH TO config FOLDER OF MODULE RELATIVE TO gRigA["APPPATH"]
    put "modules/" & pModule & "/" into tModulePath
  end if

	# CHECK IF FILE EXISTS
  set the itemDel to "/"
	-- put gRigA["APPPATH"] & tModulePath & "config/" & item -1 of tConfigFileName & ".livecodescript" into tFilepath
  put gRigA["APPPATH"] & tModulePath & "config/" & item -1 of tConfigFileName & gRigA["EXT"] into tFilepath

	if there is a file tFilepath then
	else
		if pFailGracefully is TRUE then
			return FALSE
		else
			rigShowError "The configuration file" && item -1 of tConfigFileName & gRigA["EXT"] && "does not exist."
		end if
	end if

	if pUseSections is not TRUE then -- gConfig ARRAY IS USED FOR CONFIGURATION DATA
		# CHECK IF NEW CONFIGURATION FILE CONTAINS VALID CONFIGURATION DATA
    if pModule <> empty then
      put the number of lines in the keys of gConfig[pModule] into tCurrentConfigItemNum
      -- start using stack tFilepath
      _rigRequire tFilepath
      put the number of lines in the keys of gConfig[pModule] into tNewConfigItemNum
    else
      put the number of lines in the keys of gConfig into tCurrentConfigItemNum
      -- start using stack tFilepath
      _rigRequire tFilepath
      put the number of lines in the keys of gConfig into tNewConfigItemNum
    end if

		if tNewConfigItemNum = tCurrentConfigItemNum then
			if pFailGracefully is TRUE then
				return FALSE
			else
				rigShowError "Your" && item -1 of tConfigFileName & gRigA["EXT"] && "file does not appear to contain a valid configuration array."
			end if
		end if

	else -- ARRAY IS USED TO AVOID NAME COLLISIONS
		# CHECK IF NEW CONFIGURATION FILE CONTAINS VALID CONFIGURATION DATA
    -- start using stack tFilepath
    _rigRequire tFilepath

    if pModule <> empty then
      put gConfig[pModule] into tSectionArray
    else
      put gConfig[tConfigFileName] into tSectionArray
    end if

		if the number of lines in the keys of tSectionArray is 0 then
			if pFailGracefully is TRUE then
				return FALSE
			else
				rigShowError "Your" && item -1 of tConfigFileName & gRigA["EXT"] && "file does not appear to contain a valid configuration array."
			end if
		end if
	end if

	add 1 to tConfigIsLoadedKeyNum

  put tConfigFileName into sConfigIsLoaded[tConfigIsLoadedKeyNum]

  if pModule <> empty then
    rigLogMessage "debug", "Config file loaded:" & pModule & "/config/" & item -1 of tConfigFileName & gRigA["EXT"]
  else
    rigLogMessage "debug", "Config file loaded: config/" & tConfigFileName & gRigA["EXT"]
  end if

	return TRUE

end rigLoadConfigFile







/*----------------------------------------------------------------------
--| FUNCTION rigFetchConfigItem
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-06-09
--| Last Mod: 30-06-09
--| Requires: --
--|
--| Summary: Fetch a config file item.
--|
--| Format:  rigFetchConfigItem(param1, param2)
--|
--| Parameters: string <pItem> the config item name, string <pIndex> the index name
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFetchConfigItem pItem pIndex
  local tPref

	if pIndex is empty then
		if pItem is not among the keys of gConfig then
			return FALSE
		end if

		put gConfig[pItem] into tPref
	else
		if pIndex is not among the keys of gConfig then
			return FALSE
		end if

		if pItem is not among the keys of gConfig[pIndex] then
			return FALSE
		end if

		put gConfig[pIndex][pItem] into tPref
	end if

	return tPref
end rigFetchConfigItem







/*----------------------------------------------------------------------
--| FUNCTION rigSlashItem
--|
--| Author: rabit
--| Version:  1.1
--| Created: 28-07-09
--| Last Mod: 03-08-09
--| Requires: rigFetchConfigItem()
--|
--| Summary: Fetch a config file item - adds slash after item.
--|
--| Format:  rigSlashItem(param1)
--|
--| Parameters: string <pItem> the config item name
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSlashItem pItem
  local tPref

	put rigFetchConfigItem(pItem) into tPref

	if tPref is FALSE then
		return FALSE
	end if

	if (tPref <> "") and (char -1 of tPref <> "/") then
		put tPref & "/" into tPref
	end if

	return tPref
end rigSlashItem







/*----------------------------------------------------------------------
--| FUNCTION rigSiteURL
--|
--| Author: rabit
--| Version:  1.7
--| Created: 2009-07-28
--| Last Mod: 2019-02-08
--| Requires: rigSlashItem(), rigFetchConfigItem()
--|
--| Summary: Site URL
--|
--| Format:  rigSiteURL(param1)
--|
--| Parameters: string <pURI> the URI string
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSiteURL pURI
  local tURI, tStandardURLs, tConfigValue, tSuffix, tRegEx, tFoundString, tC, tH
  local tQueryString, tCurrentKeyNum, tSegment, tKeyNotUsed, tKey, tPrefix

  put pURI into tURI
  if tURI is an array then
    combine tURI using "/"
  end if

  # CHECK IF STANDARD QUERY STRING BASED URLs ARE ENABLED
  put rigFetchConfigItem("enableQueryStrings") into tStandardURLs -- variance

  if tURI is "" then
    return rigSlashItem("baseUrl") & rigFetchConfigItem("indexPage")
  else
    put rigFetchConfigItem("urlSuffix") into tConfigValue
    if tConfigValue is FALSE then
      put "" into tSuffix
    else
      put tConfigValue into tSuffix
    end if

    put "^/*(.+?)/*$" into tRegEx

	  put empty into tFoundString -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
    if matchText(tURI,tRegEx,tFoundString) is TRUE then
      put tFoundString into tURI
    end if

    -- variance
    # QUERY STRING BASED URLs
    if tStandardURLs is TRUE then
      # GET CONTROLLER TRIGGER
      put rigFetchConfigItem("controllerTrigger") into tC

      if "/" is in tURI then -- controller and handler
        # GET HANDLER TRIGGER
        put rigFetchConfigItem("handlerTrigger") into tH
        -- replace "/" with "&" & tH & "=" in tURI

        set the itemdel to "/"

        put item 1 of tURI into tQueryString

        # START WITH ASCII VALUE 97 = a (96 +1) FOR QUERY KEYS
        put 96 into tCurrentKeyNum

        put 0 into tSegment
        repeat for each item thisItem in tURI
          add 1 to tSegment

          if tSegment > 1 then
            # HANDLER SEGMENT
            if tSegment is 2 then
              put "&" & tH & "=" & thisItem after tQueryString
            else
              # OTHER SEGMENTS
              put tCurrentKeyNum + 1 into tCurrentKeyNum

              put FALSE into tKeyNotUsed

              repeat until tKeyNotUsed is TRUE
                put numToCodepoint(tCurrentKeyNum) into tKey
                if (tKey is not tC) and (tKey is not tH) then
                  put TRUE into tKeyNotUsed
                else
                  put tCurrentKeyNum + 1 into tCurrentKeyNum
                end if
              end repeat

              put "&" & tKey & "=" & thisItem after tQueryString
            end if
          end if
        end repeat

        put "?" & tC & "=" & tQueryString into tURI
      else
        put "?" & tC & "=" into tPrefix
        if tURI begins with tPrefix then
        else
          put "?" & tC & "=" & tURI into tURI
        end if

      end if

    end if
    --

    if tStandardURLs is TRUE then  -- variance
      return rigSlashItem("baseUrl") & rigFetchConfigItem("indexPage") & rigTrim(tURI, "/") & tSuffix  -- variance
    else  -- variance
      return rigSlashItem("baseUrl") & rigSlashItem("indexPage") & rigTrim(tURI, "/") & tSuffix
    end if  -- variance
  end if
end rigSiteURL







/*----------------------------------------------------------------------
--| FUNCTION rigSystemURL
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-10-09
--| Last Mod: 10-10-09
--| Requires: --
--|
--| Summary: Sytem URL
--|
--| Format:  rigSystemURL()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSystemURL
	set the itemDel to "/"

	return (item -1 of gRigA["BASEPATH"]) & "/"
end rigSystemURL







/*----------------------------------------------------------------------
--| COMMAND rigSetConfigItem
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-10-10
--| Last Mod: 2019-04-29
--| Requires: --
--|
--| Summary: Set the value of a config item.
--|
--| Format:  rigSetConfigItem param1, param2[, param3][, param4]
--|
--| Parameters: string <pItem> the config item key, string <pValue> the config item value
--|               string <pConfig> the custom config filename (optional)
--|               string <pModule> the module name (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetConfigItem pItem pValue pConfig pModule
  if pModule <> empty then
    put pValue into gConfig[pModule][pItem]
  else
    if pConfig is empty then
      put pValue into gConfig[pItem]
    else
      put pValue into gConfig[pConfig][pItem]
    end if
  end if
end rigSetConfigItem






--| END OF Config.livecodescript
--| Location:  ./system/libraries/Config.livecodescript
----------------------------------------------------------------------