script "Useragent"

##
# RevIgniter
#
# A web development framework for LiveCode
# modeled on CodeIgniter.
#
# @package		RevIgniter
# @author			rabit@revigniter.com
# @copyright	Copyright (c) 2009 - 2020, dimensionB Bitter u. Bitter GmbH
# @license		https://revigniter.com/userGuide/license.html
# @link				https://revigniter.com
##

## ------------------------------------------------------------------------

##
# revIgniter User Agent Library
#
#
# @package		revIgniter
# @subpackage	Libraries
# @category		User Agent
# @author			rabit@revigniter.com
# @link				https://revigniter.com/userGuide/libraries/useragent.html
##

## ------------------------------------------------------------------------




global gRigA

local sStackInUse, sUseragentA -- array keys are: agent, isBrowser, isRobot, isMobile, languagesA
                                    -- charsetsA, platformsA, browsersA, mobilesA, robotsA, platform
                                    -- browser, version, mobile, robot, useragentsFileLoaded






 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-27
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
        rigLogMessage "debug", "UserAgent Library Loaded"
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
  put FALSE into sUseragentA["isBrowser"]
  put FALSE into sUseragentA["isRobot"]
  put FALSE into sUseragentA["isMobile"]
end _rigSetDefaultValues





/*----------------------------------------------------------------------
--| COMMAND rigRunInitialUseragentConfig
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-10-09
--| Last Mod: 27-10-09
--| Requires: _rigAgentData
--|
--| Summary: Run initial configuration procedures. Don't remove, even if it does nothing.
--|
--| Format:  rigRunInitialUseragentConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialUseragentConfig pConfig
	_rigAgentData
end rigRunInitialUseragentConfig







/*----------------------------------------------------------------------
--| COMMAND _rigAgentData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: rigTrim(), _rigLoadAgentFile(), _rigCompileData
--|
--| Summary: Sets the user agent and runs the compilation routine.
--|
--| Format:  _rigAgentData
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigAgentData
	if $_SERVER["HTTP_USER_AGENT"] is not empty then
		put rigTrim($_SERVER["HTTP_USER_AGENT"]) into sUseragentA["agent"]
	end if

	if sUseragentA["agent"] is not "" then
		if _rigLoadAgentFile() is TRUE then
			_rigCompileData
		end if
	end if
end _rigAgentData





/*----------------------------------------------------------------------
--| FUNCTION _rigLoadAgentFile
--|
--| Author: rabit
--| Version:  1.1
--| Created: 07-10-09
--| Last Mod: 17-09-15
--| Requires: rigLogMessage, rigFetchAgentsData(), rigDeleteAgentsVar
--|
--| Summary: Compile the user agent data.
--|
--| Format:  _rigLoadAgentFile()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigLoadAgentFile
  local tReturn

	if sUseragentA["useragentsFileLoaded"] is not TRUE then
		try
      _rigRequire gRigA["APPPATH"] & "config/useragents" & gRigA["EXT"]
		catch err
			rigLogMessage "error", "An error occured while trying to include file:" && "mimes" & gRigA["EXT"]
			return FALSE

		end try
		put TRUE into sUseragentA["useragentsFileLoaded"]
	end if

	put FALSE into tReturn

	put rigFetchAgentsData("platforms") into sUseragentA["platformsA"]
	if sUseragentA["platformsA"] is an array then
		rigDeleteAgentsVar "platforms"
		put TRUE into tReturn
	end if

	put rigFetchAgentsData("browsers") into sUseragentA["browsersA"]
	if sUseragentA["browsersA"] is an array then
		rigDeleteAgentsVar "browsers"
		put TRUE into tReturn
	end if

	put rigFetchAgentsData("mobiles") into sUseragentA["mobilesA"]
	if sUseragentA["mobilesA"] is an array then
		rigDeleteAgentsVar "mobiles"
		put TRUE into tReturn
	end if

	put rigFetchAgentsData("robots") into sUseragentA["robotsA"]
	if sUseragentA["robotsA"] is an array then
		rigDeleteAgentsVar "robots"
		put TRUE into tReturn
	end if

	return tReturn
end _rigLoadAgentFile






/*----------------------------------------------------------------------
--| COMMAND _rigCompileData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: _rigSetPlatform(), _rigSetBrowser(), _rigSetRobot(), _rigSetMobile()
--|
--| Summary: Compile the user agent data.
--|
--| Format:  _rigCompileData
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigCompileData
  local tFunctions

	get _rigSetPlatform()

	if sUseragentA["platformsA"] is an array then
		put "_setBrowser,_setRobot,_setMobile" into tFunctions

		repeat for each item thisItem in tFunctions
			switch thisItem
        			case "_setBrowser"
             				get _rigSetBrowser()
					if it is TRUE then
						exit _rigCompileData
					end if
					break
				case "_setRobot"
             				get _rigSetRobot()
					if it is TRUE then
						exit _rigCompileData
					end if
					break
				case "_setMobile"
             				get _rigSetMobile()
					if it is TRUE then
						exit _rigCompileData
					end if
					break
    			end switch
		end repeat
	end if
end _rigCompileData






/*----------------------------------------------------------------------
--| FUNCTION _rigSetPlatform
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: --
--|
--| Summary: Set the platform.
--|
--| Format:  _rigSetPlatform()
--|
--| Parameters: --
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigSetPlatform
  local tKey, tVal, tPregQuotedStr

	if sUseragentA["platformsA"] is an array then

	repeat with i = 1 to (item 2 of the extents of sUseragentA["platformsA"])
		put line 1 in the keys of sUseragentA["platformsA"][i] into tKey
		put sUseragentA["platformsA"][i][tKey] into tVal

		-- repeat for each key tKey in sUseragentA["platformsA"]
			--put sUseragentA["platformsA"][tKey] into tVal

			put rigPregQuote(tKey) into tPregQuotedStr

			get matchText(sUseragentA["agent"], "(?i)" & tPregQuotedStr)
			if it is TRUE then
				put tVal into sUseragentA["platform"]

				return TRUE
			end if
		end repeat
	end if

	put "Unknown Platform" into sUseragentA["platform"]
end _rigSetPlatform





/*----------------------------------------------------------------------
--| FUNCTION _rigSetBrowser
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-10-07
--| Last Mod: 2019-01-07
--| Requires: rigPregQuote(), _rigSetMobile()
--|
--| Summary: Set the browser.
--|
--| Format:  _rigSetBrowser()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigSetBrowser
  local tMatch1, tKey, tVal, tPregQuotedStr, tRegex, tSafariOffset

	if sUseragentA["browsersA"] is an array then

    put empty into tMatch1 -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
    repeat with i = 1 to (item 2 of the extents of sUseragentA["browsersA"])
      put line 1 in the keys of sUseragentA["browsersA"][i] into tKey
      put sUseragentA["browsersA"][i][tKey] into tVal

      -- repeat for each key tKey in sUseragentA["browsersA"]
      -- put sUseragentA["browsersA"][tKey] into tVal

      put rigPregQuote(tKey) into tPregQuotedStr


      put ".*?([0-9\.]+)" into tRegex
      -- get matchText(sAgentAgent, "(?i)" & tPregQuotedStr & ".*?([0-9\.]+)", tMatch1)
      get matchText(sUseragentA["agent"], "(?i)" & tPregQuotedStr & tRegex, tMatch1)

      if it is TRUE then
        put TRUE into sUseragentA["isBrowser"]

        if "Safari" is in sUseragentA["agent"] then
          put offset("Safari/",sUseragentA["agent"]) into tSafariOffset
          put char (tSafariOffset + 7) to (the number of chars in sUseragentA["agent"]) of sUseragentA["agent"] into sUseragentA["version"]
        else

          put tMatch1 into sUseragentA["version"]
        end if

        put tVal into sUseragentA["browser"]
        get _rigSetMobile()

        return TRUE
      end if
    end repeat
  end if

  return FALSE
end _rigSetBrowser





/*----------------------------------------------------------------------
--| FUNCTION _rigSetRobot
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: --
--|
--| Summary: Set the robot.
--|
--| Format:  _rigSetRobot()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigSetRobot
  local tKey, tVal, tPregQuotedStr

	if sUseragentA["robotsA"] is an array then

    repeat with i = 1 to (item 2 of the extents of sUseragentA["robotsA"])
      put line 1 in the keys of sUseragentA["robotsA"][i] into tKey
      put sUseragentA["robotsA"][i][tKey] into tVal

      -- repeat for each key tKey in sUseragentA["robotsA"]
      -- put sUseragentA["robotsA"][tKey] into tVal

      put rigPregQuote(tKey) into tPregQuotedStr

      get matchText(sUseragentA["agent"], "(?i)" & tPregQuotedStr)
      if it is TRUE then
        put TRUE into sUseragentA["isRobot"]
        put tVal into sUseragentA["robot"]

        return TRUE
      end if
    end repeat
  end if

  return FALSE
end _rigSetRobot





/*----------------------------------------------------------------------
--| FUNCTION _rigSetMobile
--|
--| Author: rabit
--| Version:  1.2
--| Created: 07-10-09
--| Last Mod: 11-05-10
--| Requires: rigPregQuote()
--|
--| Summary: Set the mobile device.
--|
--| Format:  _rigSetMobile()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigSetMobile
  local tLowerAgent, tKey, tVal, tPregQuotedStr

	if sUseragentA["mobilesA"] is an array then
		put toLower(sUseragentA["agent"]) into tLowerAgent

		repeat with i = 1 to (item 2 of the extents of sUseragentA["mobilesA"])
			put line 1 in the keys of sUseragentA["mobilesA"][i] into tKey
			put sUseragentA["mobilesA"][i][tKey] into tVal

		--repeat for each key tKey in sUseragentA["mobilesA"]
			--put sUseragentA["mobilesA"][tKey] into tVal

			put rigPregQuote(tKey) into tPregQuotedStr

			if tKey is in tLowerAgent then

				-- variant
				if (tKey is "os x") or (tKey is "Safari") then
					if ("iphone" is in tLowerAgent) or ("ipod" is in tLowerAgent) or ("ipad" is in tLowerAgent) then
						put TRUE into sUseragentA["isMobile"]
						put tVal into sUseragentA["mobile"]

						return TRUE
					else
						next repeat
					end if
				end if

				put TRUE into sUseragentA["isMobile"]
				put tVal into sUseragentA["mobile"]

				return TRUE
			end if
		end repeat
	end if

	return FALSE
end _rigSetMobile





/*----------------------------------------------------------------------
--| COMMAND _rigSetLanguages
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: rigTrim(), rigPregReplace()
--|
--| Summary: Set the accepted languages.
--|
--| Format:  _rigSetLanguages
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetLanguages
  local tAcceptLang, tRegEx

	put $_SERVER["HTTP_ACCEPT_LANGUAGE"] into tAcceptLang

	if (sUseragentA["languagesA"] is not an array) and (tAcceptLang is not empty) then
		put rigTrim(tAcceptLang) into tAcceptLang
		put toLower(tAcceptLang) into tAcceptLang

		put "(?i)(;q=[0-9\.]+)" into tRegEx
		put rigPregReplace(tAcceptLang, tRegEx, "", "") into sUseragentA["languagesA"]

		split sUseragentA["languagesA"] using comma

		if sUseragentA["languagesA"] is not an array then
			put "Undefined" into sUseragentA["languagesA"][1]
		end if

	end if
end _rigSetLanguages




/*----------------------------------------------------------------------
--| COMMAND _rigSetCharsets
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: rigTrim(), rigPregReplace()
--|
--| Summary: Set the accepted character sets.
--|
--| Format:  _rigSetCharsets
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetCharsets
  local tAcceptCharset, tRegEx

	put $_SERVER["HTTP_ACCEPT_CHARSET"] into tAcceptCharset

	if (sUseragentA["languagesA"] is not an array) and (tAcceptCharset is not empty) then
		put rigTrim(tAcceptCharset) into tAcceptCharset
		put toLower(tAcceptCharset) into tAcceptCharset

		put "(?i)(;q=.+)" into tRegEx
		put rigPregReplace(tAcceptCharset, tRegEx, "", "") into sUseragentA["charsetsA"]

		split sUseragentA["charsetsA"] using comma

		if sUseragentA["charsetsA"] is not an array then
			put "Undefined" into sUseragentA["charsetsA"][1]
		end if

	end if
end _rigSetCharsets





/*----------------------------------------------------------------------
--| FUNCTION rigIsBrowser
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: --
--|
--| Summary: Is browser
--|
--| Format:  rigIsBrowser()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigIsBrowser
	return sUseragentA["isBrowser"]
end rigIsBrowser







/*----------------------------------------------------------------------
--| FUNCTION rigIsRobot
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: --
--|
--| Summary: Is robot
--|
--| Format:  rigIsRobot()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigIsRobot
	return sUseragentA["isRobot"]
end rigIsRobot








/*----------------------------------------------------------------------
--| FUNCTION rigIsMobile
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: --
--|
--| Summary: Is mobile
--|
--| Format:  rigIsMobile()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigIsMobile
	return sUseragentA["isMobile"]
end rigIsMobile







/*----------------------------------------------------------------------
--| FUNCTION rigIsReferral
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: --
--|
--| Summary: Is this a referral from another site?
--|
--| Format:  rigIsReferral()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigIsReferral
	if $_SERVER["HTTP_REFERER"] is not empty then
		return TRUE
	end if

	return FALSE
end rigIsReferral








/*----------------------------------------------------------------------
--| FUNCTION rigAgentString
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: --
--|
--| Summary: Agent string
--|
--| Format:  rigAgentString()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigAgentString
	return sUseragentA["agent"]
end rigAgentString







/*----------------------------------------------------------------------
--| FUNCTION rigAgentPlatform
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: --
--|
--| Summary: Get platform
--|
--| Format:  rigAgentPlatform()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigAgentPlatform
	return sUseragentA["platform"]
end rigAgentPlatform







/*----------------------------------------------------------------------
--| FUNCTION rigBrowser
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: --
--|
--| Summary: Get browser name
--|
--| Format:  rigBrowser()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigBrowser
	if sUseragentA["browser"] is "Mozilla" then
		if "Safari" is in sUseragentA["agent"] then
			put "Safari" into sUseragentA["browser"]
		end if
	end if

	return sUseragentA["browser"]
end rigBrowser








/*----------------------------------------------------------------------
--| FUNCTION rigBrowserVersion
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: --
--|
--| Summary: Get browser version
--|
--| Format:  rigBrowserVersion()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigBrowserVersion
	return sUseragentA["version"]
end rigBrowserVersion








/*----------------------------------------------------------------------
--| FUNCTION rigRobot
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: --
--|
--| Summary: Get robot name
--|
--| Format:  rigRobot()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigRobot
	return sUseragentA["robot"]
end rigRobot








/*----------------------------------------------------------------------
--| FUNCTION rigMobile
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: --
--|
--| Summary: Get the mobile device
--|
--| Format:  rigMobile()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigMobile
	return sUseragentA["mobile"]
end rigMobile








/*----------------------------------------------------------------------
--| FUNCTION rigReferrer
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: --
--|
--| Summary: Get the referrer
--|
--| Format:  rigReferrer()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigReferrer
  local tReferrer

	if $_SERVER["HTTP_REFERER"] is not empty then
		put rigTrim($_SERVER["HTTP_REFERER"]) into tReferrer
		return tReferrer
	end if

	return ""
end rigReferrer







/*----------------------------------------------------------------------
--| FUNCTION rigAgentLanguages
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: _rigSetLanguages
--|
--| Summary: Get the accepted languages (undocumented).
--|
--| Format:  rigAgentLanguages()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigAgentLanguages
	if sUseragentA["languagesA"] is not an array then
		_rigSetLanguages
	end if

	return sUseragentA["languagesA"]
end rigAgentLanguages







/*----------------------------------------------------------------------
--| FUNCTION rigAgentCharSets
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: _rigSetCharsets
--|
--| Summary: Get the accepted charsets (undocumented).
--|
--| Format:  rigAgentCharSets()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigAgentCharSets
	if sUseragentA["charsetsA"] is not an array then
		_rigSetCharsets
	end if

	return sUseragentA["charsetsA"]
end rigAgentCharSets








/*----------------------------------------------------------------------
--| FUNCTION rigAcceptLang
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: _rigSetLanguages
--|
--| Summary: Test for a particular language.
--|
--| Format:  rigAcceptLang()
--|
--| Parameters: string <pLang>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAcceptLang pLang
  local tLang, tK, tV, tCounter, tAgentLanguages

	if pLang is empty then
		put "en" into tLang
	else
		put pLang into tLang
	end if

	put toLower(tLang) into tLang

	if sUseragentA["languagesA"] is not an array then
		_rigSetLanguages
	end if

	set the itemDelimiter to "-"
	put 0 into tCounter
	repeat for each key tK in sUseragentA["languagesA"]
		put sUseragentA["languagesA"][tK] into tV
		add 1 to tCounter

		# IGNORE ITEM 2 OF LANG LIKE IN "en-US"
		if "-" is in tV then
			put item 1 of tV into tAgentLanguages[tCounter]
		else
			put tV into tAgentLanguages[tCounter]
		end if
	end repeat

	get rigInArray(tAgentLanguages, tLang)

	return it
end rigAcceptLang








/*----------------------------------------------------------------------
--| FUNCTION rigAcceptCharset
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-10-09
--| Last Mod: 07-10-09
--| Requires: _rigSetCharsets
--|
--| Summary: Test for a particular charset.
--|
--| Format:  rigAcceptCharset()
--|
--| Parameters: string <pCharset>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAcceptCharset pCharset
  local tCharset

	if pCharset is empty then
		put "utf-8" into tCharset
	else
		put pCharset into tCharset
	end if

	put toLower(tCharset) into tCharset

	if sUseragentA["charsetsA"] is not an array then
		_rigSetCharsets
	end if

	get rigInArray(sUseragentA["charsetsA"], tCharset)

	return it
end rigAcceptCharset





/*----------------------------------------------------------------------
--| FUNCTION rigUseragentGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Get useragent array variable values.
--|
--| Format: rigUseragentGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigUseragentGet pWhat
  if pWhat is among the keys of sUseragentA then
    return sUseragentA[pWhat]
  end if

  return empty
end rigUseragentGet




/*----------------------------------------------------------------------
--| COMMAND rigUseragentSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Setter for table variables.
--|
--| Format: rigUseragentSet param1, param2
--|
--| Parameters: string <pKey>, sUseragentA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigUseragentSet pKey pVal
  if pKey is among the keys of sUseragentA then
    put pVal into sUseragentA[pKey]
  end if
end rigUseragentSet










--| END OF Useragent.livecodescript
--| Location:  ./system/libraries/Useragent.livecodescript
----------------------------------------------------------------------