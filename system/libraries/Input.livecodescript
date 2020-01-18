script "Input"

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
# revIgniter Input Library
#
# Pre-processes global input data for security
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Input
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/input.html
##

## ------------------------------------------------------------------------




global gRigA

local sInputA, sPrivateVars, sStackInUse





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-08
 --| Last Mod: --
 --| Requires: rigLogMessage, _rigSetDefaultValues, rigLoadLibrary, _rigSanitizeGlobals
 --|
 --| Summary:  Run security check and initial routines. Set default values.
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
      If the environment is "server" then
        rigLogMessage "debug", "Input Library Loaded"
      end if

      _rigSetDefaultValues

      # CALL INITIAL HANDLERS
      rigLoadLibrary "Config"
      _rigSanitizeGlobals
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
--| Created: 2018-12-14
--| Last Mod: 2018-12-14
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
  put FALSE into sInputA["IPaddress"]
  put FALSE into sInputA["userAgent"]
  put FALSE into sInputA["allowGetArray"]
  put FALSE into sInputA["useXssClean"]
  put FALSE into sInputA["enableCSRF"]
  put 7200 into sInputA["CSRFexpire"]
  put "rig_csrf_token" into sInputA["CSRFtokenName"]
  put "rig_csrf_cookie" into sInputA["CSRFcookieName"]

  put "[removed]" into sInputA["neverAllowedStr"]["gRigA"]

  put "[removed]" into sInputA["neverAllowedStr"]["document.cookie"]
  put "[removed]" into sInputA["neverAllowedStr"]["document.write"]
  put "[removed]" into sInputA["neverAllowedStr"][".parentNode"]
  put "[removed]" into sInputA["neverAllowedStr"][".innerHTML"]
  put "[removed]" into sInputA["neverAllowedStr"]["window.location"]
  put "[removed]" into sInputA["neverAllowedStr"]["-moz-binding"]
  put "&lt;!--" into sInputA["neverAllowedStr"]["<!--"]
  put "--&gt;" into sInputA["neverAllowedStr"]["-->"]
  put "&lt;![CDATA[" into sInputA["neverAllowedStr"]["<![CDATA["]


  put "[removed]" into sInputA["neverAllowedRegex"]["javascript\s*:"]
  put "[removed]" into sInputA["neverAllowedRegex"]["expression\s*(\(|&\#40;)"]
  put "[removed]" into sInputA["neverAllowedRegex"]["vbscript\s*:"]
  put "[removed]" into sInputA["neverAllowedRegex"]["Redirect\s+302"]

  put $_SERVER["CONTENT_TYPE"] into sInputA["contentType"]

  put "useXssClean,allowGetArray,enableCSRF,CSRFexpire,CSRFtokenName,CSRFcookieName,CSRFhash,XSShash,neverAllowedStr,neverAllowedRegex" into sPrivateVars
end _rigSetDefaultValues





/*----------------------------------------------------------------------
--| COMMAND _rigSanitizeGlobals
--|
--| Author: rabit
--| Version:  1.8
--| Created: 2009-06-17
--| Last Mod: 2019-02-08
--| Requires: Log library, _rigInputConfig, _rigSerializedPOSTtoArray, _rigCleanInputData()
--|           	_rigVarPostFallback(), rigLogMessage, _rigCSRFconfig, _rigCSRFverify
--|
--| Summary: This command does the following:
--| 	          Cleans $_GET data (if query strings are enabled)
--|             Cleans $_POST data
--|             Cleans special cookie data
--|             Standardizes newline characters to LF
--|
--| Format:  _rigSanitizeGlobals
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSanitizeGlobals
  local tInputSettings, tPOSTrawVariableKey, tPOSTrawVariableValue, tCOOKIETemp
  local tTrimmedKey, tCSRFsettings

	# INPUT CONFIGURATION
	put "useXssClean,allowGetArray,enableCSRF" into tInputSettings
	repeat for each item tItem in tInputSettings
		_rigInputConfig tItem
	end repeat

	# IS $_GET DATA ALLOWED? IF NOT WE'LL SET THE $_GET TO EMPTY
	if sInputA["allowGetArray"] is FALSE then
		put empty into $_GET
	else
		put _rigCleanInputData($_GET) into $_GET
	end if


	# THIS SEEMS STRANGE, BUT WE SAVE THE GET ARRAY IN THE POST ARRAY TO SIMPLIFY FURTHER INPUT VALIDATION
	# ALL VALIDATION IS THEN DONE WITH THE POST ARRAY
	if $_GET is an array then
		if (the number of lines in the keys of $_GET > 1) then
			if (the number of lines in the keys of $_GET = 2) then
				if (line 2 of the keys of $_GET) is not rigFetchConfigItem("handlerTrigger") then
					put $_GET into $_POST
				end if
			else
				put $_GET into $_POST
			end if
		end if
	end if

	# IF $_POST IS NOT AN ARRAY MAY BE WE ARE DEALING WITH AN AJAX REQUEST
	# SO WE CALL A FALLBACK FUNCTION (A WORK AROUND FOR AN ENGINE ISSUE
	# WHERE THE $_POST VARIABLE IS EMPTY) TO RETRIEVE THE POST ARRAY.
	if ($_SERVER["REQUEST_METHOD"] = "POST") and ($_POST is not an array) then

		# FIRST CHECK IF POST DATA IS JSON
		if sInputA["contentType"] is "application/json" then
			set the itemdelimiter to "="
			put item 1 of $_POST_RAW into tPOSTrawVariableKey
			put item 2 of $_POST_RAW into tPOSTrawVariableValue

			if tPOSTrawVariableValue is empty then
				# SHOULD WE FILTER THE DATA?
				if sInputA["useXssClean"] is TRUE then
					put rigXssClean(tPOSTrawVariableKey) into item 1 of $_POST_RAW
				end if

				put $_POST_RAW into $_POST
			end if

		else
		# WE ARE NOT DEALING WITH JSON, SO CALL THE FALLBACK FUNCTION
			put _rigVarPostFallback() into $_POST
		end if
	end if -- if ($_SERVER["REQUEST_METHOD"] = "POST") and ($_POST is not an array) then


	# CLEAN $_POST DATA
	if $_POST is an array then  -- variance
		# CHECK THE CONTENT TYPE HEADER TO BE ABLE TO DETERMINE
		# IF WE ARE DEALING WITH LIVECODE ARRAYS
		if (sInputA["contentType"] is "application/lc.array") or (sInputA["contentType"] is "application/lc.array.compressed") then
			put _rigSerializedPOSTtoArray($_POST) into $_POST
		else
			put _rigCleanInputData($_POST) into $_POST
		end if
	end if  -- variance


	# CLEAN $_COOKIE DATA
	# ALSO GET RID OF SPECIALLY TREATED COOKIES THAT MIGHT BE SET BY A SERVER
	# OR SILLY APPLICATION, THAT ARE OF NO USE TO A RI APPLICATION ANYWAY
	# BUT THAT WHEN PRESENT WILL TRIP OUR 'DISALLOWED KEY CHARACTERS' ALARM
	# http://datatracker.ietf.org/doc/rfc2965/

	put $_SERVER["HTTP_COOKIE"] into tCOOKIETemp

	split tCOOKIETemp using ";" and "="

	# REMOVE WHITE SPACE FROM ARRAY KEYS
	repeat for each key tKey in tCOOKIETemp
		put rigTrim(tKey) into tTrimmedKey
		put tCOOKIETemp[tKey] into gRigA["COOKIE"][tTrimmedKey]
	end repeat

	delete variable gRigA["COOKIE"]["$Version"]
	delete variable gRigA["COOKIE"]["$Path"]
	delete variable gRigA["COOKIE"]["$Domain"]

	put _rigCleanInputData(gRigA["COOKIE"], "cookie") into gRigA["COOKIE"]

	combine gRigA["COOKIE"] using ";" and "="

	# CSRF PROTECTION CHECK
	if sInputA["enableCSRF"] is TRUE then
		put "CSRFexpire,CSRFtokenName,CSRFcookieName" into tCSRFsettings
		repeat for each item tItem in tCSRFsettings
			_rigCSRFconfig tItem
		end repeat

		_rigCSRFverify
	end if

	rigLogMessage "debug", "Global POST and COOKIE data sanitized"
end _rigSanitizeGlobals






/*----------------------------------------------------------------------
--| COMMAND _rigInputConfig
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2012-07-14
--| Last Mod: 2019-01-07
--| Requires: rigFetchConfigItem()
--|
--| Summary: Input library configuration.
--|
--| Format: _rigInputConfig param1
--|
--| Parameters: string <pVarName>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigInputConfig pVarName
  local tSetting

	switch pVarName
		case "useXssClean"
			put rigFetchConfigItem("globalXssFiltering") into tSetting
			if tSetting is TRUE then
				put tSetting into sInputA["useXssClean"]
			end if
		break
		case "allowGetArray"
			put rigFetchConfigItem("enableQueryStrings") into tSetting
			if tSetting is TRUE then
				put tSetting into sInputA["allowGetArray"]
			end if
		break
		case "enableCSRF"
			put rigFetchConfigItem("csrf_protection") into tSetting
			if tSetting is TRUE then
				put tSetting into sInputA["enableCSRF"]
			end if
	end switch
end _rigInputConfig






/*----------------------------------------------------------------------
--| COMMAND _rigCSRFconfig
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2012-07-14
--| Last Mod: 2019-01-07
--| Requires: rigFetchConfigItem(), _rigCSRFsetHash
--|
--| Summary: CSRF configuration.
--|
--| Format:  _rigCSRFconfig param1
--|
--| Parameters: string <pVarName>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigCSRFconfig pVarName
  local tSetting, tCookiePrefix

	switch pVarName
		case "CSRFexpire"
			put rigFetchConfigItem("csrf_expire") into tSetting
			if (tSetting is not empty) and (tSetting is a number) then
				put tSetting into sInputA["CSRFexpire"]
			end if
		break
		case "CSRFtokenName"
			put rigFetchConfigItem("csrf_token_name") into tSetting
			if tSetting is not empty then
				put tSetting into sInputA["CSRFtokenName"]
			end if
		break
		case "CSRFcookieName"
			put rigFetchConfigItem("csrf_cookie_name") into tSetting
			if tSetting is not empty then
				put tSetting into sInputA["CSRFcookieName"]
			end if
	end switch

	# APPEND APPLICATION SPECIFIC COOKIE PREFIX
	put rigFetchConfigItem("cookie_prefix") into tCookiePrefix
	if tCookiePrefix <> empty then
		put tCookiePrefix & sInputA["CSRFcookieName"] into sInputA["CSRFcookieName"]
	end if

	# SET THE CSRF HASH
	_rigCSRFsetHash
end _rigCSRFconfig






/*----------------------------------------------------------------------
--| COMMAND _rigCSRFsetHash
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2012-07-14
--| Last Mod: 2018-10-24
--| Requires: rigVarCookie(), rigUniqid()
--|
--| Summary: Set Cross Site Request Forgery protection cookie.
--|
--| Format:  _rigCSRFsetHash
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigCSRFsetHash
  local tCSRFcookie, tRegEx

	if sInputA["CSRFhash"] is empty then
		# IF THE COOKIE EXISTS WE WILL USE IT'S VALUE.
		# WE DON'T NECESSARILY WANT TO REGENERATE IT WITH
		# EACH PAGE LOAD SINCE A PAGE COULD CONTAIN EMBEDDED
		# SUB-PAGES CAUSING THIS FEATURE TO FAIL
		put rigVarCookie(sInputA["CSRFcookieName"]) into tCSRFcookie

		if tCSRFcookie <> FALSE then
			put "(?is)^[0-9a-f\-]{36}$" into tRegEx

			get matchText(tCSRFcookie, tRegEx)

			if it is TRUE then
				put tCSRFcookie into sInputA["CSRFhash"]
				exit _rigCSRFsetHash
			end if

		end if

		put rigUniqid() into sInputA["CSRFhash"]
	end if
end _rigCSRFsetHash






/*----------------------------------------------------------------------
--| COMMAND _rigCSRFverify
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2012-07-15
--| Last Mod: 2016-09-10
--| Requires: _rigCSRFsetCookie, rigVarPost(), rigVarCookie(), _rigCSRFshowError,
--| 					_rigInputSetCookie, _rigCSRFsetHash, rigLogMessage
--|
--| Summary: Verify Cross Site Request Forgery protection.
--|
--| Format:  _rigCSRFverify
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigCSRFverify
  local tCSRFtoken, tCSRFcookie

	# IF NO POST DATA EXISTS WE WILL SET THE CSRF COOKIE
	if $_POST is not an array then
		_rigCSRFsetCookie
		exit _rigCSRFverify
	end if

	put rigVarPost(sInputA["CSRFtokenName"]) into tCSRFtoken
	put rigVarCookie(sInputA["CSRFcookieName"]) into tCSRFcookie

	# DO THE TOKENS EXIST IN BOTH THE _POST AND _COOKIE ARRAYS?
	if (tCSRFtoken is FALSE) or (tCSRFcookie is FALSE) then
		_rigCSRFshowError
	end if

	# DO THE TOKENS MATCH?
	put base64Decode(urlDecode(tCSRFcookie)) into tCSRFcookie
	if tCSRFtoken <> tCSRFcookie then
		_rigCSRFshowError
	end if

	# WE KILL THIS SINCE WE'RE DONE AND WE DON'T WANT TO
	# POLUTE THE _POST ARRAY
	put empty into $_POST[sInputA["CSRFtokenName"]]

	# NOTHING SHOULD LAST FOREVER, DELETE COOKIE
	_rigInputSetCookie sInputA["CSRFcookieName"]
	_rigCSRFsetHash
	_rigCSRFsetCookie

	rigLogMessage "debug", "CSRF token verified"
end _rigCSRFverify






/*----------------------------------------------------------------------
--| COMMAND _rigCSRFsetCookie
--|
--| Author: rabit
--| Version:  1.1
--| Created: 15-07-2012
--| Last Mod: 12-10-2013
--| Requires: rigFetchConfigItem(), _rigInputSetCookie, rigLogMessage
--|
--| Summary: Set Cross Site Request Forgery protection cookie.
--|
--| Format:  _rigCSRFsetCookie
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigCSRFsetCookie
  local tSecureCookie, tReq, tCookieDomain, tCookiePath

	put rigFetchConfigItem("cookie_secure") into tSecureCookie

	if tSecureCookie is TRUE then
		if $_SERVER["HTTPS"] <> empty then
			put $_SERVER["HTTPS"] into tReq
		else
			put FALSE into tReq
		end if

		if (tReq is FALSE) or (tReq is "off") then
			exit _rigCSRFsetCookie
		end if
	end if

	put rigFetchConfigItem("cookie_domain") into tCookieDomain
	put rigFetchConfigItem("cookie_path") into tCookiePath
	_rigInputSetCookie sInputA["CSRFcookieName"], sInputA["CSRFhash"], sInputA["CSRFexpire"], tCookieDomain, tCookiePath, "", FALSE, tSecureCookie, TRUE

	rigLogMessage "debug", "CSRF cookie Set"
end _rigCSRFsetCookie





/*----------------------------------------------------------------------
--| COMMAND _rigCSRFshowError
--|
--| Author: rabit
--| Version:  1.1
--| Created: 14-07-2012
--| Last Mod: 29-01-2015
--| Requires: rigShowError
--|
--| Summary: Show CSRF error.
--|
--| Format:  _rigCSRFshowError
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigCSRFshowError
	rigShowError "The action you have requested is not allowed.", 200
end _rigCSRFshowError






/*----------------------------------------------------------------------
--| FUNCTION rigGetCSRFhash
--|
--| Author: rabit
--| Version:  1.0
--| Created: 15-07-2012
--| Last Mod: --
--| Requires: --
--|
--| Summary: Get CSRF hash.
--|
--| Format:  rigGetCSRFhash()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigGetCSRFhash
	return sInputA["CSRFhash"]
end rigGetCSRFhash






/*----------------------------------------------------------------------
--| FUNCTION rigGetCSRFtokenName
--|
--| Author: rabit
--| Version:  1.0
--| Created: 15-07-2012
--| Last Mod: --
--| Requires: --
--|
--| Summary: Get CSRF token name.
--|
--| Format:  rigGetCSRFtokenName()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigGetCSRFtokenName
	return sInputA["CSRFtokenName"]
end rigGetCSRFtokenName







/*----------------------------------------------------------------------
--| FUNCTION _rigCleanInputData
--|
--| Author: rabit
--| Version:  1.3
--| Created: 17-06-09
--| Last Mod: 21-12-14
--| Requires: _rigCleanInputKeys(), _rigCleanInputData(), rigXssClean()
--|
--| Summary: This is a helper function. It escapes data and
--|            standardizes newline characters to LF.
--|
--| Format:  _rigCleanInputData(param1[, param2])
--|
--| Parameters: mixed <pStr>, string <pType> (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCleanInputData pStr pType
  local tType, tKey, tVal, tCleanArray, tStr

	if pType is empty then
		put "" into tType
	else
		put pType into tType
	end if

	if pStr is an array then
		repeat for each line tKey in the keys of  pStr
			put _rigCleanInputKeys(tKey) into tKey
			put _rigCleanInputData(pStr[tKey], tType) into tVal
			put tVal into tCleanArray[tKey]
		end repeat

		return tCleanArray
	end if

	# WE STRIP SLASHES
	put pStr into tStr
	replace "\\" with "+++|r---b|+++" in tStr
	replace "\" with "" in tStr
	replace "+++|r---b|+++" with "\" in tStr

	# SHOULD WE FILTER THE INPUT DATA?
	if sInputA["useXssClean"] is TRUE then
		put rigXssClean(tStr, "", tType) into tStr
	end if

	# STANDARDIZE NEWLINES
	# CONVERT CR AND CRLF TO LF
	if tStr contains numToCodepoint(13) then
		replace numToCodepoint(13) & numToCodepoint(10) with numToCodepoint(10) in tStr
		replace numToCodepoint(13) with numToCodepoint(10) in tStr
	end if

	return tStr
end _rigCleanInputData




/*----------------------------------------------------------------------
--| FUNCTION _rigCleanInputKeys
--|
--| Author: rabit
--| Version:  1.2
--| Created: 17-06-09
--| Last Mod: 15-10-15
--| Requires: --
--|
--| Summary: This is a helper function. To prevent malicious users
--|            from trying to exploit keys we make sure that keys are
--|            only named with alpha-numeric text and a few other items.
--|
--| Format:  _rigCleanInputKeys(param1)
--|
--| Parameters: string <pKey>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCleanInputKeys pKey
  if matchchunk(pKey, "(?i)^[a-z0-9:_\/-]+$") is FALSE then
		put "Disallowed Key Characters."
		exit to top
	end if

	return pKey
end _rigCleanInputKeys




/*----------------------------------------------------------------------
--| FUNCTION _rigFetchFromArray
--|
--| Author: rabit
--| Version:  1.3
--| Created: 30-05-09
--| Last Mod: 27-06-13
--| Requires: rigXssClean(), _rigXssCleanArray()
--|
--| Summary: This is a helper function to retrieve values from global arrays.
--|
--| Format:  _rigFetchFromArray(param1, param2, param3)
--|
--| Parameters: array <pArray>, string <pIndex>, bool <pXssFlag>, string <pType> (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigFetchFromArray pArray pIndex pXssClean pType
  local tXSSclean, tType

	if pXSSclean is empty then
		put FALSE into tXSSclean
	else
		put pXSSclean into tXSSclean
	end if

	if pType is empty then
		put "" into tType
	else
		put pType into tType
	end if

	 if pIndex is not among the keys of pArray then
        	return FALSE
    	end if

	if tXSSclean is TRUE then
		if pArray[pIndex] is not an array then
			return rigXssClean(pArray[pIndex], "", tType)
		else
			return _rigXssCleanArray(pArray[pIndex])
		end if
	end if

	return pArray[pIndex]
end _rigFetchFromArray




----------------------------------------------------------------------
--| FUNCTION rigVarGet
--|
--| Author: rabit
--| Version:  1.2
--| Created: 20-06-09
--| Last Mod: 17-07-11
--| Requires: _rigFetchFromArray()
--|
--| Summary: Fetch an item from the GET array.
--|
--| Format:  rigVarGet(param1, param2)
--|
--| Parameters: string <pIndex>, bool <pXSSclean>
--|
--| Return: string
----------------------------------------------------------------------

function rigVarGet pIndex pXSSclean
  local tXSSclean

	if pXSSclean is empty then
		put FALSE into tXSSclean
	else
		put pXSSclean into tXSSclean
	end if

	if $_GET is an array then
		return _rigFetchFromArray($_GET, pIndex, tXSSclean)
	end if

	return FALSE
end rigVarGet







/*----------------------------------------------------------------------
--| FUNCTION rigVarPost
--|
--| Author: rabit
--| Version:  1.5
--| Created: 20-06-09
--| Last Mod: 10-09-15
--| Requires: _rigFetchFromArray(), rigXssClean()
--|
--| Summary: Fetch an item from the POST array.
--|
--| Format:  rigVarPost(param1, param2)
--|
--| Parameters: string <pIndex>, bool <pXSSclean>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigVarPost pIndex pXSSclean
  local tXSSclean

	if pXSSclean is empty then
		put FALSE into tXSSclean
	else
		put pXSSclean into tXSSclean
	end if

	if $_POST is an array then
		return _rigFetchFromArray($_POST, pIndex, tXSSclean)

	else
		if $_POST <> empty then
			if pXSSclean is TRUE then
				return rigXssClean($_POST)
			end if
			return $_POST
		end if
	end if

	return FALSE
end rigVarPost








/*----------------------------------------------------------------------
--| FUNCTION _rigVarPostFallback
--|
--| Author: rabit
--| Version:  1.1
--| Created: 16-05-2010
--| Last Mod: 18-03-2016
--| Requires: --
--|
--| Summary: This function is used to address an engine issue where
--|          the $_POST variable of an Ajax request is not present / is empty
--|          if FireFox is used. In addition it takes into account, that apperently
--|          there are different server engines installed on the On-Rev servers.
--|
--| Format:  _rigVarPostFallback()
--|
--| Parameters: --
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigVarPostFallback
  local tPOSTdata

  # DON'T DEAL WITH MULTIPART FORM-DATA, BOUNDARIES ETC.
  if "multipart/form-data" is not in $_SERVER["CONTENT_TYPE"] then
    # READ RAW DATA FROM STANDARD IN
    if $_SERVER["CONTENT_LENGTH"] > 0 then
      read from stdin for $_SERVER["CONTENT_LENGTH"] chars
      put it into tPOSTdata
    else
      # ALTERNATIVELY CHECK $_POST_RAW
      put $_POST_RAW into tPOSTdata
    end if

    if tPOSTdata is empty then
      # THERE IS DEFINITELY NO POST DATA
      return FALSE
    end if

    # AS POST DATA IS EXPECTED TO BE AN ARRAY CONVERT THE STRING
    split tPOSTdata with "&" and "="

    # DECODE THE ARRAY VALUES TO GET THE ORIGINAL DATA
    repeat for each key tKey in tPOSTdata
      put urlDecode(tPOSTdata[tKey]) into tPOSTdata[tKey]
    end repeat

  else
    return FALSE
  end if -- if "multipart/form-data" is not in $_SERVER["CONTENT_TYPE"] then

  return tPOSTdata
end _rigVarPostFallback




----------------------------------------------------------------------
--| FUNCTION rigVarGetPost
--|
--| Author: rabit
--| Version:  1.1
--| Created: 10-10-09
--| Last Mod: 04-11-09
--| Requires: rigVarGet(), rigVarPost()
--|
--| Summary: Fetch an item from either the GET array or the POST array.
--|
--| Format:  rigVarGetPost(param1, param2)
--|
--| Parameters: string <pIndex>, bool <pXSSclean>
--|
--| Return: string
----------------------------------------------------------------------

function rigVarGetPost pIndex pXSSclean
  local tXSSclean

	if pXSSclean is empty then
		put FALSE into tXSSclean
	else
		put pXSSclean into tXSSclean
	end if

	--if ($_POST[pIndex] is not an array) and ($_POST[pIndex] is empty) then
	if pIndex is not among the keys of $_POST then
		return rigVarGet(pIndex, tXSSclean)
	else
		return rigVarPost(pIndex, tXSSclean)
	end if
end rigVarGetPost








----------------------------------------------------------------------
--| FUNCTION rigVarCookie
--|
--| Author: rabit
--| Version:  1.4
--| Created: 30-05-09
--| Last Mod: 30-06-10
--| Requires: _rigFetchFromArray()
--|
--| Summary: Fetch an item from the COOKIE array.
--|
--| Format:  rigVarCookie(param1, param2)
--|
--| Parameters: string <pName>, bool <pXssFlag>
--|
--| Return: string
----------------------------------------------------------------------

function rigVarCookie pName pXssFlag
  local tXssFlag, tCookie

	if pXssFlag is empty then
		put FALSE into tXssFlag
	else
		put pXssFlag into tXssFlag
	end if

	if gRigA["COOKIE"] is not empty then
		put gRigA["COOKIE"] into tCookie
		split tCookie using ";" and "="
		return _rigFetchFromArray(tCookie, pName, tXssFlag, "cookie")

	else
		if $_SERVER["HTTP_COOKIE"] is not empty then
			split $_SERVER["HTTP_COOKIE"] using ";" and "="
			return _rigFetchFromArray($_SERVER["HTTP_COOKIE"], pName, tXssFlag, "cookie")

		end if
	end if

	return FALSE
end rigVarCookie








----------------------------------------------------------------------
--| FUNCTION rigVarServer
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-10-09
--| Last Mod: 10-10-09
--| Requires: _rigFetchFromArray()
--|
--| Summary: Fetch an item from either the SERVER array.
--|
--| Format:  rigVarServer(param1, param2)
--|
--| Parameters: string <pIndex>, bool <pXSSclean>
--|
--| Return: string
----------------------------------------------------------------------

function rigVarServer pIndex pXSSclean
  local tXSSclean

	if pXSSclean is empty then
		put FALSE into tXSSclean
	else
		put pXSSclean into tXSSclean
	end if

	return _rigFetchFromArray($_SERVER, pIndex, tXSSclean)
end rigVarServer








/*----------------------------------------------------------------------
--| FUNCTION rigIpAddress
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-10-09
--| Last Mod: 10-10-09
--| Requires: rigFetchConfigItem(), rigVarServer(), rigValidIP()
--|
--| Summary: Fetch the IP address.
--|
--| Format:  rigIpAddress()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigIpAddress
  local tProxyIPs, tXforwarded, tRemoteAddr, tClientIP

	if sInputA["IPaddress"] is not FALSE then
		return sInputA["IPaddress"]
	end if

	put rigFetchConfigItem("proxyIPs") into tProxyIPs
	put rigVarServer("HTTP_X_FORWARDED_FOR") into tXforwarded
	put rigVarServer("REMOTE_ADDR") into tRemoteAddr

	put rigVarServer("HTTP_CLIENT_IP") into tClientIP

	if (tProxyIPs is not "") and (tXforwarded is not FALSE) and (tRemoteAddr is not FALSE) then
		if $_SERVER["REMOTE_ADDR"] is among the items of tProxyIPs then
			put $_SERVER["HTTP_X_FORWARDED_FOR"] into sInputA["IPaddress"]
		else
			put $_SERVER["REMOTE_ADDR"] into sInputA["IPaddress"]
		end if

	else if (tRemoteAddr is not FALSE) and (tClientIP is not FALSE) then
		put $_SERVER["HTTP_CLIENT_IP"] into sInputA["IPaddress"]

	else if tRemoteAddr is not FALSE then
		put $_SERVER["REMOTE_ADDR"] into sInputA["IPaddress"]

	else if tClientIP is not FALSE then
		put $_SERVER["HTTP_CLIENT_IP"] into sInputA["IPaddress"]

	else if tXforwarded is not FALSE then
		put $_SERVER["HTTP_X_FORWARDED_FOR"] into sInputA["IPaddress"]
	end if

	if sInputA["IPaddress"] is FALSE then
		put "0.0.0.0" into sInputA["IPaddress"]

		return sInputA["IPaddress"]
	end if

	if comma is in sInputA["IPaddress"] then
		put item -1 of sInputA["IPaddress"] into sInputA["IPaddress"]
	end if

	if rigValidIP(sInputA["IPaddress"]) is not TRUE then
		put "0.0.0.0" into sInputA["IPaddress"]
	end if

	return sInputA["IPaddress"]
end rigIpAddress








/*----------------------------------------------------------------------
--| FUNCTION rigValidIP
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 02-07-12
--| Requires: _rigValid_ipv4(), _rigValid_ipv6()
--|
--| Summary: Validate IP address.
--|
--| Format:  rigValidIP(param1, param2)
--|
--| Parameters: string <pIP>, string <pWhich> ipv4 or ipv6
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigValidIP pIP pWhich
  local tWhich, tFunctionToCall

  put "" into tWhich
  if pWhich <> empty then
    put toLower(pWhich) into tWhich
  end if

  if (tWhich <> "ipv6") and (tWhich <> "ipv4") then
    if ":" is in pIP then
      put "ipv6" into tWhich
    else if "." is in pIP then
      put "ipv4" into tWhich
    else
      return FALSE
    end if
  end if

  put "_rigValid_" & tWhich & "(" & quote & pIP & quote & ")" into tFunctionToCall
  do "return" && tFunctionToCall
end rigValidIP






/*----------------------------------------------------------------------
--| FUNCTION _rigValid_ipv4
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-07-12
--| Last Mod: 29-09-15
--| Requires: --
--|
--| Summary: Validate ipv4 address.
--|
--| Format:  _rigValid_ipv4(param1)
--|
--| Parameters: string <pIP>
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigValid_ipv4 pIP
  local tIPsegments, tRegEx, tMatchFound, tSegmentLength

	put pIP into tIPsegments

	set the itemDelimiter to "."

	# ALWAYS 4 SEGMENTS NEEDED
	if the number of items of tIPsegments <> 4 then
		return FALSE
	end if

	# IP CAN NOT START WITH 0
	if char 1 of item 1 of tIPsegments is "0" then
		return FALSE
	end if

	# CHECK EACH SEGMENT
	repeat for each item tSegment in tIPsegments
		# IP SEGMENTS MUST BE DIGITS AND CAN NOT BE
		# LONGER THAN 3 DIGITS OR GREATER THEN 255
		put "[^0-9]" into tRegEx
		put matchText(tSegment, tRegEx) into tMatchFound

		put the length of tSegment into tSegmentLength

		if (tSegment is empty) or (tMatchFound is TRUE) or (tSegment > 255) or (tSegmentLength > 3) then
			return FALSE
		end if
	end repeat

	return TRUE
end _rigValid_ipv4







/*----------------------------------------------------------------------
--| FUNCTION _rigValid_ipv6
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-07-12
--| Last Mod: 21-03-14
--| Requires: _rigValid_ipv4()
--|
--| Summary: Validate ipv6 address.
--|
--| Format:  _rigValid_ipv6(param1)
--|
--| Parameters: string <pIP>
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigValid_ipv6 pIP
  local tGroups, tCollapsed, tCounter, tItem, tChunks, tIPv4

   # 8 GROUPS, SEPARATED BY :
   # 0-ffff PER GROUP
   # ONE SET OF CONSECUTIVE 0 GROUPS CAN BE COLLAPSED TO ::

   put 8 into tGroups
   put FALSE into tCollapsed

   set the itemDel to ":"

   put 0 into tCounter
   repeat for each item tItem in pIP
      add 1 to tCounter

      if tItem <> empty then
         put tItem into tChunks[tCounter]
         add 1 to tCounter

         put ":" into tChunks[tCounter]

      else

         # COLLAPSED
         if tCounter > 1 then
            subtract 1 from tCounter
         end if

         put ":" after tChunks[tCounter]
      end if
   end repeat

   delete local tChunks[tCounter]
   put tCounter - 1 into tCounter

   # RULE OUT EASY NONSENSE
   if (tChunks[1] is ":") or (tChunks[tCounter] is ":") then
      return FALSE
   end if

   # CHECK FOR IPv4-MAPPED IPV6 ADDRESSES
   if "." is in tChunks[tCounter] then
      put tChunks[tCounter] into tIPv4

      if _rigValid_ipv4(tIPv4) <> TRUE then
         return FALSE
      end if

      delete local tChunks[tCounter]
      put tCounter - 1 into tCounter

      put tGroups - 1 into tGroups
   end if

   repeat with d = tCounter down to 1
      if char 1 of tChunks[d] is ":" then
         if tGroups - 1 is 0 then
            # TOO MANY GROUPS
            return FALSE
         end if
         put tGroups -1 into tGroups

         if the length of tChunks[d] > 2 then
            # LONG SEPARATOR
            return FALSE
         end if

         if tChunks[d]  is "::" then
            if tCollapsed is TRUE then
               # MULTIPLE COLLAPSED
               return FALSE
            end if
            put TRUE into tCollapsed
         end if

      else if (matchText(tChunks[d], "(?i)[^0-9a-f]")) or (the length of tChunks[d] > 4) then
         # INVALID SEGMENT
         return FALSE
      end if
   end repeat

   return tCollapsed or (tGroups is 1)
end _rigValid_ipv6








/*----------------------------------------------------------------------
--| FUNCTION rigUserAgent
--|
--| Author: rabit
--| Version:  1.1
--| Created: 10-10-09
--| Last Mod: 04-11-09
--| Requires: --
--|
--| Summary: Fetch user agent from the SERVER array.
--|
--| Format:  rigUserAgent()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigUserAgent
	if sInputA["userAgent"] is not FALSE then
		return sInputA["userAgent"]
	end if

	--if $_SERVER["HTTP_USER_AGENT"] is empty then
	if "HTTP_USER_AGENT" is not among the keys of $_SERVER then
		put FALSE into sInputA["userAgent"]
	else
		put $_SERVER["HTTP_USER_AGENT"] into sInputA["userAgent"]
	end if

	return sInputA["userAgent"]
end rigUserAgent









/*----------------------------------------------------------------------
--| FUNCTION rigSanitizeFilename
--|
--| Author: rabit
--| Version:  1.0
--| Created: 13-07-12
--| Last Mod: --
--| Requires: _rigRemoveInvisibleCharacters(), rigStripSlashes()
--|
--| Summary: Filename security
--|
--| Format:  rigSanitizeFilename(param1, param2)
--|
--| Parameters: string <pFileName>, bool <pRelativePath>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSanitizeFilename pFileName pRelativePath
  local tRelativePath, tBad, tFileName

  if pRelativePath is empty then
    put FALSE into tRelativePath
  else
    put pRelativePath into tRelativePath
  end if

  put "../,<!--,-->,<,>,'," & quote & ",&,$,#,{,},[,],=,;,?,%20,%22,%3c,%253c,%3e,%0e,%28,%29,%2528,%26,%24,%3f,%3b,%3d" into tBad

  if tRelativePath is FALSE then
    put ",./,/" after tBad
  end if

  put _rigRemoveInvisibleCharacters(pFileName) into tFileName

  repeat for each item tItem in tBad
    replace tItem with "" in tFileName
  end repeat

  return rigStripSlashes(tFileName)
end rigSanitizeFilename








/*----------------------------------------------------------------------
--| FUNCTION rigXssClean
--|
--| Author: rabit
--| Version:  1.7
--| Created: 2009-05-23
--| Last Mod: 2017-06-27
--| Requires: _rigRemoveInvisibleCharacters(), _rigConvertAttribute, _rigHtmlEntityDecode, _rigCompactExplodedWords
--|            _rigJsLinkRemoval, _rigJsImgRemoval, _rigSanitizeNaughtyHtml, _rigXssHash(), rigLogMessage
--|
--| Summary: Sanitizes data so that Cross Site Scripting Hacks can be prevented.
--|
--|                    This function does a fair amount of work but
--|                    it is extremely thorough, designed to prevent even the
--|                    most obscure XSS attempts. Nothing is ever 100% foolproof, of course.
--|
--|                    Note: This function should only be used to deal with data
--|                    upon submission.  It's not something that should
--|                    be used for general runtime processing.
--|
--|                    This function was based in part on some code and ideas
--|                    from Bitflux: http://blog.bitflux.ch/wiki/XSS_Prevention
--|                    and http://ha.ckers.org/xss.html
--|
--| Format:  rigXssClean(param1, param2)
--|
--| Parameters: string <pString>, boolean <pImage> (optional), string <pType> (optional, needed to distinguish cookies)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigXssClean pString pImage pType
  local tStringToClean, tType, tGetVarsFound, tTempStr, tSplitChar
  local tFoundStr1, tFoundStr2, tFoundStr3, tFoundStr4, tFoundStr5
  local tStringToCleanHashed, tStringToCleanValidated, tStringPartConverted
  local tStringToCleanP1, tOffsetP3, tStringToCleanP3, tStringToDecode
  local tConvertedString, tRegEx, tLCtagnames, tWords, tCheckExploded
  local tFoundStr, tTemp, tOriginal, tLinkCheckStr, tMatchFound, tFoundStrLength
  local tStrOffset, tSearchStartNum, tStrLength, tStrPart1, tStrPart4
  local tLength, tStrOffsetStart, tStrOffsetEnd, tNaughty, tCheckNaughtyStr
  local tFullFoundString

	put pString into tStringToClean

	if pType is empty then
		put "" into tType
	else
		put pType into tType
	end if

	# REPLACE QUOTES. THIS IS NEEDED AS THE FUNCTION MAY BE CALLED DIRECTLY,
	# SO THE REPLACEMENT CAN NOT BE DONE BY THE FORMVALIDATION LIBRARY
	if quote is in tStringToClean then
		replace quote with numToCodepoint(2) in tStringToClean
	end if

	## IS THE STRING AN ARRAY?
	if tStringToClean is an array then
		repeat for each key tKey in tStringToClean
			put rigXssClean(tStringToClean[tKey]) into tStringToClean[tKey]
		end repeat

		## RETURN ARRAY
		return tStringToClean
	end if

	## REMOVE INVISIBLE CHARACTERS
	# DON'T DO THIS WITH COOKIES, AS SERIALIZED COOKIE ARRAYS USE INVISIBLE CHARACTERS
	if tType <> "cookie" then
		put _rigRemoveInvisibleCharacters(pString) into tStringToClean
	end if

	##
	# PROTECT GET VARIABLES IN URLs
	##
	put FALSE into tGetVarsFound

	set the itemdelimiter to "&"
	put empty into tTempStr

	# CHARACTER TO BE REPLACED BY HASH = ASCII 1
	put numToCodepoint(1) into tSplitChar

	# REPLACE & WITH LINEFEED, BUT LEAVE CHARACTER ENTITIES
  put empty into tFoundStr1 -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
  put empty into tFoundStr2
	repeat for each item thisItem in tStringToClean
		get matchText("&" & thisItem,"(?i)\&([a-z\_0-9]+)\=([a-z\_0-9]+)",tFoundStr1,tFoundStr2)
		if it is TRUE then
			put TRUE into tGetVarsFound

			if tTempStr is not empty and char -1 of tTempStr is not tSplitChar then
				put tSplitChar after tTempStr
			end if
			put tFoundStr1 & "=" & tFoundStr2 & tSplitChar after tTempStr
		else
			if char -1 of tTempStr is tSplitChar then
				delete char -1 of tTempStr
			end if

			if tTempStr is not empty then
				put "&" & thisItem after tTempStr
			else
				put thisItem into tTempStr
			end if
		end if
	end repeat

	 if char -1 of tTempStr is tSplitChar then
		delete char -1 of tTempStr
	end if

	if char 1 of tStringToClean is "&" then
		put "&" before tTempStr
	end if

	# REPLACE ASCII 1 WITH HASH
	put tTempStr into tStringToCleanHashed
	replace tSplitChar with _rigXssHash() in tStringToCleanHashed

	put tStringToCleanHashed into tStringToClean

	##
	# VALIDATE STANDARD CHARACTER ENTITIES
	#
	# ADD A SEMICOLON IF MISSING.  WE DO THIS TO ENABLE
	# THE CONVERSION OF ENTITIES TO ASCII LATER.
	#
	##
	if tGetVarsFound is TRUE then

		put empty into tFoundStr1
		put empty into tFoundStr2
		repeat for each item thisItem in tStringToClean
			get matchText("&" & thisItem,"((?i)&\#?[0-9a-z]{2,})([\x00-\x20])*;?",tFoundStr1,tFoundStr2)
			if it is TRUE then
				put tFoundStr1 & ";" & tFoundStr2 after tStringToCleanValidated
			end if
		end repeat

		if tStringToCleanValidated is not empty then
			put tStringToCleanValidated into tStringToClean
		end if
	end if

	##
	# VALIDATE UTF16 TWO BYTE ENCODING (X00)
	#
	# JUST AS ABOVE, ADDS A SEMICOLON IF MISSING.
	#
	##
	if tGetVarsFound is TRUE then
		put empty into tFoundStr1
		put empty into tFoundStr2
		put empty into tStringToCleanValidated
		repeat for each item thisItem in tStringToClean
			get matchText("&" & thisItem,"(&\#x?)((?i)[0-9A-F]+);?",tFoundStr1,tFoundStr2)
			if it is TRUE then
				put tFoundStr1 & tFoundStr2 & ";" after tStringToCleanValidated
			end if
		end repeat

		if tStringToCleanValidated is not empty then
			put tStringToCleanValidated into tStringToClean
		end if
	end if

	##
	# UN-PROTECT GET VARIABLES IN URLS
	##
	replace sInputA["XSShash"] with "&" in tStringToClean

	##
	# URL DECODE
	#
	# JUST IN CASE STUFF LIKE THIS IS SUBMITTED:
	#
	# <a href="http://%77%77%77%2E%67%6F%6F%67%6C%65%2E%63%6F%6D">Google</a>
	#
	# NOTE: USE rigRawURLdecode() SO IT DOES NOT REMOVE PLUS SIGNS
	##
	# DON'T DO THIS WITH COOKIES, AS COOKIES ARE URLENCODED
	if tType <> "cookie" then
		put rigRawURLdecode(tStringToClean) into tStringToClean
	end if

	##
	# CONVERT CHARACTER ENTITIES TO ASCII
	#
	# THIS PERMITS OUR TESTS BELOW TO WORK RELIABLY.
	# WE ONLY CONVERT ENTITIES THAT ARE WITHIN TAGS SINCE
	# THESE ARE THE ONES THAT WILL POSE SECURITY PROBLEMS.
	#
	##
  put empty into tFoundStr1
  put empty into tFoundStr2
  put empty into tFoundStr3
	-- get matchText(tStringToClean,"(?i)[a-z]+=([\'\"]).*?([\'\"])")
	-- get matchText(tStringToClean,"(?i)[a-z]+=([\'\"])(.*?)([\'\"])", tFoundStr1, tFoundStr2, tFoundStr3)
	get matchText(tStringToClean,"(?i)[a-z]+=([\'" & numToCodepoint(2) & "])(.*?)([\'" & numToCodepoint(2) & "])", tFoundStr1, tFoundStr2, tFoundStr3)
	if it is TRUE then
		-- put _rigConvertAttribute(tStringToClean) into tStringToClean
		 put _rigConvertAttribute(tFoundStr2) into tStringPartConverted

        	put char 1 to (offset(tFoundStr1,tStringToClean)) of tStringToClean into tStringToCleanP1

        	put (the number of chars of tStringToCleanP1) + (the number of chars of tFoundStr2) + 1 into tOffsetP3

        	put char tOffsetP3 to (the number of chars of tStringToClean) of tStringToClean into tStringToCleanP3

        	put tStringToCleanP1 & tStringPartConverted & tStringToCleanP3 into tStringToClean
	end if

  put empty into tStringToDecode -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	--get matchText(tStringToClean,"(?i)(<\w+.*?)(?=>|<|$)",tStringToDecode)
	get matchText(tStringToClean,"(?i)<\w+.*?(?=>|<|$)",tStringToDecode)
	put _rigHtmlEntityDecode(tStringToDecode) into tStringToDecode

	if tStringToDecode is not empty then
		put tStringToDecode into tStringToClean
	end if

	##
	# REMOVE INVISIBLE CHARACTERS AGAIN!
	# DON'T DO THIS WITH COOKIES, AS SERIALIZED COOKIE ARRAYS USE INVISIBLE CHARACTERS
	if tType <> "cookie" then
		put _rigRemoveInvisibleCharacters(tStringToClean) into tStringToClean
	end if

	##
	# CONVERT ALL TABS TO SPACES
	#
	# THIS PREVENTS STRINGS LIKE THIS: JA	VASCRIPT
	# NOTE: WE DEAL WITH SPACES BETWEEN CHARACTERS LATER.
	#
	##
	replace tab with space in tStringToClean

	##
	# CAPTURE CONVERTED STRING FOR LATER COMPARISON
	##
	put tStringToClean into tConvertedString

	##
	# NOT ALLOWED UNDER ANY CONDITIONS
	##
	repeat for each key tKey in sInputA["neverAllowedStr"]
		replace tKey with sInputA["neverAllowedStr"][tKey] in tStringToClean
	end repeat

	repeat for each key tKey in sInputA["neverAllowedRegex"]
		put "(?i)" & tKey into tRegEx
		put replacetext(tStringToClean,tRegEx,sInputA["neverAllowedRegex"][tKey]) into tStringToClean
	end repeat

	##
	# MAKES LIVECODE TAGS SAFE
	##
  put "rev&lc&livecode" into tLCtagnames

   repeat for each item tTagname in tLCtagnames
      if ("<?" & tTagname) is in tStringToClean then
         replace ("<?" & tTagname) with ("&lt;?" & tTagname) in tStringToClean
      end if
   end repeat
   # IMAGES HAVE A TENDENCY TO HAVE THE CLOSING TAGS EVERY SO OFTEN
   # SO WE SKIP THOSE AND ONLY DO THE OPENING TAGS.
   if pImage <> TRUE then
      replace "?>" with "?&gt;" in tStringToClean
   end if

	##
	# COMPACT ANY EXPLODED WORDS
	#
	# THIS CORRECTS WORDS LIKE:  J A V A S C R I P T
	# THESE WORDS ARE COMPACTED BACK TO THEIR CORRECT STATE.
	#
	##
	put "javascript,expression,vbscript,script,applet,alert,document,write,cookie,window" into tWords

	split tWords by comma

	put tStringToClean into tCheckExploded

  put empty into tFoundStr
	repeat for each key tKey in tWords
		put empty into tTemp
		repeat for each char thisChar in tWords[tKey]
			put thisChar & "\s*" after tTemp
		end repeat
		put char 1 to -4 of tTemp into tTemp

		put "(?i)(" & tTemp & ")(\W)" into tRegEx

		get matchText(tCheckExploded,tRegEx,tFoundStr)
		if it is TRUE then
			replace tFoundStr with _rigCompactExplodedWords(tFoundStr) in tCheckExploded
		end if
	end repeat

	put tCheckExploded into tStringToClean

	##
	# REMOVE DISALLOWED JAVASCRIPT IN LINKS OR IMG TAGS
	##
	put empty into tOriginal

	repeat until tOriginal is tStringToClean
		put tStringToClean into tOriginal

		# LINKS
		 if matchText(tStringToClean,"(?i)<a") is true then
			put tStringToClean into tTemp
			put tStringToClean into tLinkCheckStr
			put "(?i)<a\s+([^>]*?)(>|$)" into tRegEx

			put TRUE into tMatchFound

       put empty into tFoundStr
			repeat until tMatchFound is FALSE
				get matchText(tLinkCheckStr,tRegEx,tFoundStr)
				if it is TRUE then
					put the length of tFoundStr into tFoundStrLength
					put offset(tFoundStr,tLinkCheckStr) into tStrOffset
					put tStrOffset + tFoundStrLength into tSearchStartNum
					put the length of tLinkCheckStr into tStrLength
					put char tSearchStartNum to tStrLength of tLinkCheckStr into tLinkCheckStr

					replace tFoundStr with _rigJsLinkRemoval(tFoundStr) in tTemp
					put tTemp into tStringToClean
				else
					put FALSE into tMatchFound
				end if
			end repeat
		end if

		# IMGS
		 if matchText(tStringToClean,"(?i)<img") is true then
			put tStringToClean into tTemp
			put tStringToClean into tLinkCheckStr
			put "(?i)<img\s+([^>]*?)(\s?/?>|$)" into tRegEx

			put TRUE into tMatchFound

       put empty into tFoundStr
			repeat until tMatchFound is FALSE
				get matchText(tLinkCheckStr,tRegEx,tFoundStr)
				if it is TRUE then
					put the length of tFoundStr into tFoundStrLength
					put offset(tFoundStr,tLinkCheckStr) into tStrOffset
					put tStrOffset + tFoundStrLength into tSearchStartNum
					put the length of tLinkCheckStr into tStrLength
					put char tSearchStartNum to tStrLength of tLinkCheckStr into tLinkCheckStr

					replace tFoundStr with _rigJsImgRemoval(tFoundStr) in tTemp
                    		put tTemp into tStringToClean
				else
					put FALSE into tMatchFound
				end if
			end repeat
		 end if

		#SCRIPT
		if matchText(tStringToClean,"(?i)script") is true or matchText(tStringToClean,"(?i)xss") is true then
			put replacetext(tStringToClean,"(?i)<(/*)(script|xss)(.*?)\>","[removed]") into tStringToClean
		end if

	end repeat

	##
	# REMOVE JAVASCRIPT EVENT HANDLERS
	#
	# NOTE: THIS CODE IS A LITTLE BLUNT.  IT REMOVES
	# THE EVENT HANDLER AND ANYTHING UP TO THE CLOSING >,
	# BUT IT'S UNLIKELY TO BE A PROBLEM.
	#
	##
  put empty into tFoundStr1
  put empty into tFoundStr2
  put empty into tFoundStr3
  put empty into tFoundStr4
	get matchText(tStringToClean,"(?i)<([^><]+?)([^a-z_\-]on\w*|xmlns)(\s*=\s*[^><]*)([><]*)",tFoundStr1,tFoundStr2,tFoundStr3,tFoundStr4)

	if it is TRUE then
		put empty into tStrPart1
		put empty into tStrPart4

		put the length of tStringToClean into tLength
		put offset(tFoundStr1,tStringToClean) into tStrOffsetStart
		put offset(tFoundStr4,tStringToClean) into tStrOffsetEnd

		if tStrOffsetStart > 1 then
			put char 1 to (tStrOffsetStart -1) of tStringToClean into tStrPart1
		end if

		if tLength > tStrOffsetEnd then
			put char (tStrOffsetEnd + 1) to tLength of tStringToClean into tStrPart4
		end if
		put tStrPart1 & tFoundStr1 & tFoundStr4 & tStrPart4 into tStringToClean
	end if

	##
	# SANITIZE NAUGHTY HTML ELEMENTS
	#
	# IF A TAG CONTAINING ANY OF THE WORDS IN THE LIST
	# BELOW IS FOUND, THE TAG GETS CONVERTED TO ENTITIES.
	#
	# SO THIS: <BLINK>
	# BECOMES: &LT;BLINK&GT;
	#
	##
	put "alert|applet|audio|basefont|base|behavior|bgsound|blink|body|embed|expression|form|frameset|frame|head|html|ilayer|iframe|input|isindex|layer|link|meta|object|plaintext|style|script|textarea|title|video|xml|xss" into tNaughty

	 put "(?i)(<)(/*\s*)(" & tNaughty & ")([^><]*)([><]*)" into tRegEx

	put tStringToClean into tTemp
	put tStringToClean into tCheckNaughtyStr

	put TRUE into tMatchFound

  put empty into tFoundStr1
  put empty into tFoundStr2
  put empty into tFoundStr3
  put empty into tFoundStr4
  put empty into tFoundStr5
	repeat until tMatchFound is FALSE
		get matchText(tCheckNaughtyStr,tRegEx,tFoundStr1,tFoundStr2,tFoundStr3,tFoundStr4,tFoundStr5)

		if it is TRUE then
			put tFoundStr1 & tFoundStr2 & tFoundStr3 & tFoundStr4 & tFoundStr5 into tFullFoundString

			put the length of tFullFoundString into tFoundStrLength
			put offset(tFullFoundString,tCheckNaughtyStr) into tStrOffset
			put tStrOffset + tFoundStrLength into tSearchStartNum
			put the length of tCheckNaughtyStr into tStrLength
			put char tSearchStartNum to tStrLength of tCheckNaughtyStr into tCheckNaughtyStr

			replace tFullFoundString with _rigSanitizeNaughtyHtml(tFullFoundString) in tTemp

			put tTemp into tStringToClean

		else
			put FALSE into tMatchFound
		end if

	end repeat

	##
	# SANITIZE NAUGHTY SCRIPTING ELEMENTS
	#
	# SIMILAR TO ABOVE, ONLY INSTEAD OF LOOKING FOR
	# TAGS IT LOOKS FOR PHP AND JAVASCRIPT COMMANDS
	# THAT ARE DISALLOWED.  RATHER THAN REMOVING THE
	# CODE, IT SIMPLY CONVERTS THE PARENTHESIS TO ENTITIES
	# RENDERING THE CODE UN-EXECUTABLE.
	#
	# FOR EXAMPLE:	EVAL('SOME CODE')
	# BECOMES:		EVAL&#40;'SOME CODE'&#41;
	#
	##
	put "(alert|cmd|passthru|eval|exec|expression|system|fopen|fsockopen|file|rigFile_get_contents|rigReadFile|unlink)(\s*)\((.*?)\)" into tNaughty

	 put tStringToClean into tTemp

  put empty into tFoundStr1
  put empty into tFoundStr2
  put empty into tFoundStr3
	get matchText(tTemp,tNaughty,tFoundStr1,tFoundStr2,tFoundStr3)
	if it is TRUE then
		put tFoundStr1 & tFoundStr2 & "&#40;" & tFoundStr3 & "&#41;" into tTemp
		put tTemp into tStringToClean
	end if

	##
	# FINAL CLEAN UP
	#
	# THIS ADDS A BIT OF EXTRA PRECAUTION IN CASE
	# SOMETHING GOT THROUGH THE ABOVE FILTERS
	#
	##
	repeat for each key tKey in sInputA["neverAllowedStr"]
		replace tKey with sInputA["neverAllowedStr"][tKey] in tStringToClean
	end repeat

	repeat for each key tKey in sInputA["neverAllowedRegex"]
		put "(?i)" & tKey into tRegEx
		put replacetext(tStringToClean,tRegEx,sInputA["neverAllowedRegex"][tKey]) into tStringToClean
	end repeat

	##
	# IMAGES ARE HANDLED IN A SPECIAL WAY
	# - ESSENTIALLY, WE WANT TO KNOW THAT AFTER ALL OF THE CHARACTER CONVERSION IS DONE WHETHER
	# ANY UNWANTED, LIKELY XSS, CODE WAS FOUND.  IF NOT, WE RETURN TRUE, AS THE IMAGE IS CLEAN.
	# HOWEVER, IF THE STRING POST-CONVERSION DOES NOT MATCHED THE STRING POST-REMOVAL OF XSS,
	# THEN IT FAILS, AS THERE WAS UNWANTED XSS CODE FOUND AND REMOVED/CHANGED DURING PROCESSING.
	##
	rigLogMessage "debug", "XSS Filtering completed"

	if pImage is TRUE then
		if tStringToClean is tConvertedString then
			return TRUE
		else
			return FALSE
		end if
	end if

	# SET QUOTES
	if numToCodepoint(2) is in tStringToClean then
		replace numToCodepoint(2) with quote in tStringToClean
	end if

	return tStringToClean
end rigXssClean







/*----------------------------------------------------------------------
--| FUNCTION _rigXssCleanArray
--|
--| Author: rabit
--| Version:  1.0
--| Created: 26-06-2013
--| Last Mod: 26-06-2013
--| Requires: rigXssClean()
--|
--| Summary: Traverses arrays in POST data and sanitizes the array
--|          values using rigXssClean.
--|
--| Format:  _rigXssCleanArray(param1)
--|
--| Parameters: array <pArray>
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigXssCleanArray pArray
	if pArray is an array then
		repeat for each key tKey in pArray
			if pArray[tKey] is an array then
				put _rigXssCleanArray(pArray[tKey]) into pArray[tKey]
			else
				put rigXssClean(pArray[tKey]) into pArray[tKey]
			end if
		end repeat
		return pArray
	end if

	return FALSE
end _rigXssCleanArray







/*----------------------------------------------------------------------
--| FUNCTION _rigXssHash
--|
--| Author: rabit
--| Version:  2.2
--| Created: 2009-06-21
--| Last Mod: 2019-01-06
--| Requires: --
--|
--| Summary: Random hash for protecting URLs.
--|
--| Format: _rigXssHash([param1])
--|
--| Parameters: integer <pNumBytes> (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigXssHash pNumBytes
  local tMD5str, tBinDecodeMD5str

  if pNumBytes is empty then
    put 8 into pNumBytes
  end if

	if sInputA["XSShash"] is "" then
		put randomBytes(pNumBytes) into sInputA["XSShash"]

    put md5digest(sInputA["XSShash"]) into tMD5str
    get binarydecode("H*",tMD5str,tBinDecodeMD5str)
    put tBinDecodeMD5str into sInputA["XSShash"]
	end if

	put base64encode(sInputA["XSShash"]) into sInputA["XSShash"]
	return sInputA["XSShash"]
end _rigXssHash








/*----------------------------------------------------------------------
--| FUNCTION _rigRemoveInvisibleCharacters
--|
--| Author: rabit
--| Version:  1.1
--| Created: 30-05-09
--| Last Mod: 21-12-14
--| Requires: --
--|
--| Summary: This prevents sandwiching null characters between ascii characters, like Java\0script.
--|
--| Format:  _rigRemoveInvisibleCharacters(param1)
--|
--| Parameters: string <pString>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigRemoveInvisibleCharacters pString
  local tString, tSearchChunc

  put pString into tString
  ## EVERY CONTROL CHARACTER EXCEPT NEWLINE (DEC 10),
  ## CARRIAGE RETURN (DEC 13), AND HORIZONTAL TAB (DEC 09)

  ## URLENCODED CHARS 1 - 8
  repeat with i = 1 to 8
    put replacetext(tString, urlencode(numToCodepoint(i)), "") into tString
  end repeat

  ## URLENCODED CHARS 11 - 12
  repeat with i = 11 to 12
    put replacetext(tString, urlencode(numToCodepoint(i)), "") into tString
  end repeat

  ## URLENCODED CHARS 14 - 31
  repeat with i = 14 to 31
    put replacetext(tString, urlencode(numToCodepoint(i)), "") into tString
  end repeat

  ## CHARS 1 - 8
  put "[" & numToCodepoint(1) & "-" & numToCodepoint(8) & "]" into tSearchChunc
  put replacetext(tString, tSearchChunc, "") into tString

  ## CHARS 11 - 12
  put "[" & numToCodepoint(11) & numToCodepoint(12) & "]" into tSearchChunc
  put replacetext(tString, tSearchChunc, "") into tString

  ## CHARS 14 - 31
  put "[" & numToCodepoint(14) & "-" & numToCodepoint(31) & "]" into tSearchChunc
  put replacetext(tString, tSearchChunc, "") into tString
  return tString
end _rigRemoveInvisibleCharacters








/*----------------------------------------------------------------------
--| FUNCTION _rigCompactExplodedWords
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-06-09
--| Last Mod: 24-06-09
--| Requires: --
--|
--| Summary: Remove whitespace from things like j a v a s c r i p t.
--|
--| Format:  _rigCompactExplodedWords(param1)
--|
--| Parameters: string <pWord>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCompactExplodedWords pWord
  local tWord

	put pWord into tWord
	replace space with "" in tWord
	return tWord
end _rigCompactExplodedWords




/*----------------------------------------------------------------------
--| FUNCTION _rigSanitizeNaughtyHtml
--|
--| Author: rabit
--| Version:  1.0
--| Created: 25-06-09
--| Last Mod: 25-06-09
--| Requires: --
--|
--| Summary: Function for rigXssClean() to remove naughty HTML elements
--|
--| Format:  _rigSanitizeNaughtyHtml(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigSanitizeNaughtyHtml pStr
  local tStr

  put pStr into tStr
  replace "<" with "&lt;" in tStr
  replace ">" with "&gt;" in tStr
  return tStr
end _rigSanitizeNaughtyHtml





/*----------------------------------------------------------------------
--| FUNCTION _rigJsLinkRemoval
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-06-09
--| Last Mod: 24-06-09
--| Requires: _rigFilterAttributes()
--|
--| Summary: Function for xss_clean() to sanitize links.
--|
--| Format:  _rigJsLinkRemoval(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigJsLinkRemoval pStr
  local tStr

  put pStr into tStr
  replace "<" with "" in tStr
  replace ">" with "" in tStr

  put _rigFilterAttributes(tStr) into tStr

  put replacetext(tStr,"(?i)href=.*?(alert\(|alert&\#40;|javascript\:|charset\=|window\.|document\.|\.cookie|<script|<xss|base64\s*,)","") into tStr

  return tStr
end _rigJsLinkRemoval




/*----------------------------------------------------------------------
--| FUNCTION _rigJsImgRemoval
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-06-09
--| Last Mod: 24-06-09
--| Requires: _rigFilterAttributes()
--|
--| Summary: Function for xss_clean() to sanitize image tags.
--|
--| Format:  _rigJsImgRemoval(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigJsImgRemoval pStr
  local tStr

  put pStr into tStr
  replace "<" with "" in tStr
  replace ">" with "" in tStr

  put _rigFilterAttributes(tStr) into tStr

  put replacetext(tStr,"(?i)src=.*?(alert\(|alert&\#40;|javascript\:|charset\=|window\.|document\.|\.cookie|<script|<xss|base64\s*,)","") into tStr

  return tStr
end _rigJsImgRemoval




/*----------------------------------------------------------------------
--| FUNCTION _rigConvertAttribute
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-06-09
--| Last Mod: 22-06-09
--| Requires: --
--|
--| Summary: Attribute Conversion.
--|
--| Format:  _rigConvertAttribute(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigConvertAttribute pStr
  local tStringToConvert

  put pStr into tStringToConvert
  replace ">" with "&gt;" in tStringToConvert
  replace "<" with "&lt;" in tStringToConvert
  replace "\\" with "\\\\" in tStringToConvert
  return tStringToConvert
end _rigConvertAttribute





/*----------------------------------------------------------------------
--| FUNCTION _rigHtmlEntityDecode
--|
--| Author: rabit
--| Version:  1.5
--| Created: 2009-06-23
--| Last Mod: 2019-01-01
--| Requires: rigFetchConfigItem(), rigLogMessage
--|
--| Summary: Converts character entities.
--|
--| Format:  _rigHtmlEntityDecode(param1, param2)
--|
--| Parameters: string <pStr>, string <pCharset>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigHtmlEntityDecode pStr pCharset
  local tStringToDecode, tFoundNum, tDecodedStringDeci, tNumConverted
  local tDecodedStringHexa, tDecodedString

  put pStr into tStringToDecode

  # DEFAULT CHARSET CONFIG SETTING USED FOR SERVER VERSION 7 AND ABOVE
  if pCharset is empty then
    put rigDefaultCharset() into pCharset
  end if

  set the itemdelimiter to ";"

  # NUMERIC CHARACTER ENTITIES (DECIMAL)
	put empty into tFoundNum -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
  repeat for each item thisItem in tStringToDecode
    get matchText(thisItem,"&#([0-9]{2,4})",tFoundNum)
    if it is TRUE then
      replace ("&#" & tFoundNum) with numToCodepoint(tFoundNum) in thisItem
      put thisItem after tDecodedStringDeci

    else
      put thisItem & ";" after tDecodedStringDeci
    end if
  end repeat

  # NUMERIC CHARACTER ENTITIES (HEXADECIMAL)
	put empty into tFoundNum
  repeat for each item thisItem in tDecodedStringDeci
    get matchText(thisItem,"(?i)&#x(0*[0-9a-f]{2,5})",tFoundNum)
    if it is TRUE then
      put baseconvert(tFoundNum,16,10) into tNumConverted
      replace ("&#x" & tFoundNum) with numToCodepoint(tNumConverted) in thisItem
      put thisItem after tDecodedStringHexa
    else
      put thisItem & ";" after tDecodedStringHexa
    end if
  end repeat

  # LITERAL ENTITIES
  put tDecodedStringHexa into tDecodedString
  if sInputA["entityChart"] is empty then
    put URL ("binfile:" & gRigA["BASEPATH"] & "revigniter/htmlEntityChart.txt") into sInputA["entityChart"]

    if the result is empty then
      put textDecode(sInputA["entityChart"], pCharset) into sInputA["entityChart"]
    else
      rigLogMessage "error", "Failed to read file! System error:" && the sysError
    end if

  end if
  set the itemdelimiter to tab
  repeat for each line thisLine in sInputA["entityChart"]
    if item 3 of thisLine is not empty then
      if item 3 of thisLine is in tDecodedString then
        replace (item 3 of thisLine) with (char 1 of thisLine) in tDecodedString
      end if
    end if
  end repeat

  return tDecodedString
end _rigHtmlEntityDecode





/*----------------------------------------------------------------------
--| FUNCTION _rigFilterAttributes
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-06-24
--| Last Mod: 2017-06-27
--| Requires: --
--|
--| Summary: Filters tag attributes for consistency and safety
--|
--| Format:  _rigFilterAttributes(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigFilterAttributes pStr
  local tStr, tRegEx, tFoundStr1, tFoundStr2, tFoundStr3, tFilteredFoundStr
  local tStrOffset

  put pStr into tStr

  put "(?i)\s*[a-z\-]+\s*=\s*(\042|\047)([^\\1]*?)(\042|\047)" into tRegEx

  put empty into tFoundStr1 -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
  put empty into tFoundStr2
  put empty into tFoundStr3
  get matchText(tStr,tRegEx,tFoundStr1,tFoundStr2,tFoundStr3)
  if it is TRUE then
    put replacetext(tFoundStr2,"/\*.*?\*/","") into tFilteredFoundStr
    replace tFoundStr2 with tFilteredFoundStr in tStr
  end if

  if "href" is in tStr then
    put offset("href",tStr) into tStrOffset
    if tStrOffset <> 1 then
      delete char 1 to (tStrOffset - 1) in tStr
    end if
  end if
  return tStr
end _rigFilterAttributes





/*----------------------------------------------------------------------
--| FUNCTION rigStripImgTags
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2009-08-02
--| Last Mod: 2017-06-27
--| Requires: --
--|
--| Summary: Strip image tags.
--|
--| Format: rigStripImgTags(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigStripImgTags pStr
  local tStr, tRegEx, tFoundTextVar, tStrippedStr

	--put "<img\s+.*?src\s*=\s*[\" & quote & "'](.+?)[\" & quote & "'].*?\>" into tRegEx

	put pStr into tStr

	# REPLACE QUOTES. THIS IS NEEDED AS THE FUNCTION MAY BE CALLED DIRECTLY,
	# SO THE REPLACEMENT CAN NOT BE DONE BY THE FORMVALIDATION LIBRARY
	if quote is in tStr then
		replace quote with numToCodepoint(2) in tStr
	end if

	put "<img\s+.*?src\s*=\s*[" & numToCodepoint(2) & "'](.+?)[" & numToCodepoint(2) & "'].*?\>" into tRegEx

	put empty into tFoundTextVar -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	get matchText(tStr,tRegEx,tFoundTextVar)

	if it is TRUE then
		put tFoundTextVar into tStr
	end if

	put "<img\s+.*?src\s*=\s*(.+?).*?\>" into tRegEx

	put empty into tFoundTextVar
	get matchText(tStr,tRegEx,tFoundTextVar)

	if it is TRUE then
		put tFoundTextVar into tStrippedStr
	else
		put tStr into tStrippedStr
	end if

	# SET QUOTES
	if numToCodepoint(2) is in tStrippedStr then
		replace numToCodepoint(2) with quote in tStrippedStr
	end if

	return tStrippedStr
end rigStripImgTags







/*----------------------------------------------------------------------
--| COMMAND _rigInputSetCookie
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2012-07-15
--| Last Mod: 2019-10-17
--| Requires: rigFetchConfigItem(), _rigCookieExpirationDate(), rigSetHeader
--|
--| Summary: Accepts ten parameters, or you can submit an associative
--| 	         array in the first parameter containing all the values.
--|
--| Format:  _rigInputSetCookie param1, param2[, param3][, param4][, param5][, param6][, param7][, param8][, param9][, param10]
--|
--| Parameters: string <pName>, mixed <pValue> can be a string or an array, integer <pExp> (optional), string <pDomain> usually: .yourdomain.com (optional),
--|               string <pPath> (optional), string <pPrefix> (optional), bool <pReplace> (optional), bool <pSecure> (optional), bool <pHttpOnly> (optional),
--|               string <pSameSite> "Strict", "Lax" or "None" (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigInputSetCookie pName, pValue, pExp, pDomain, pPath, pPrefix, pReplace, pSecure, pHttpOnly, pSameSite
  local tCookieArray, tConfigCookieSecure, tSecure, tReq, tHeaderString, tConfigCookieSamesite

	if pName is an array then
		put pName into tCookieArray

		put tCookieArray["name"] into pName
		put tCookieArray["value"] into pValue
		put tCookieArray["expire"] into pExp
		put tCookieArray["domain"] into pDomain
		put tCookieArray["path"] into pPath
		put tCookieArray["prefix"] into pPrefix
		put tCookieArray["replace"] into pReplace
		put tCookieArray["secure"] into pSecure
		put tCookieArray["httponly"] into pHttpOnly
    put tCookieArray["samesite"] into pSameSite
	end if

	# ARRAYS NEED TO BE MARKED SO THAT THEY CAN BE RECOGNIZED
	# AND DECODED BY THE rigGetCookie FUNCTION
  if pValue is an array then
    put "!a" & numToCodepoint(1) & arrayEncode(pValue) & numToCodepoint(1) & "a!" into pValue
  end if

	if pDomain is not empty then
		put  "; domain=" & pDomain into pDomain
	end if

	if pPath is not empty then
		put  "; path=" & pPath into pPath
	else
		put  "; path=/" into pPath
	end if

	if pPrefix is not empty then
		put pPrefix & pName into pName
	end if

	if pReplace is empty then
		# DON'T REPLACE COOKIE HEADERS
		put FALSE into pReplace
	end if

	if pSecure is not empty then
		put rigFetchConfigItem("cookie_secure") into tConfigCookieSecure
		if (pSecure is FALSE) and (tConfigCookieSecure <> FALSE) then
			put tConfigCookieSecure into tSecure
		else
			put pSecure into tSecure
		end if
	else
		put FALSE into tSecure
	end if

	# DON'T SEND COOKIE IF cookie_secure IS SET TO TRUE AND THERE IS NO HTTPS CONNECTION
	if tSecure is TRUE then
		if $_SERVER["HTTPS"] <> empty then
			put $_SERVER["HTTPS"] into tReq
		else
			put FALSE into tReq
		end if

		if (tReq is FALSE) or (tReq is "off") then
			exit _rigInputSetCookie
		end if
	end if

	if (pHttpOnly is empty) or (pHttpOnly is TRUE) then
		# SET THE HttpOnly FLAG
		put  "; HttpOnly" into pHttpOnly
	else
		put empty into pHttpOnly
	end if

  if (pSameSite is not empty) and (pSameSite is among the items of "Strict,Lax,None") then
    # USE pSameSite
	else
    put empty into pSameSite
    put rigFetchConfigItem("cookie_samesite") into tConfigCookieSamesite
    if (tConfigCookieSamesite is not empty) and (tConfigCookieSamesite is among the items of "Strict,Lax,None") then
      put tConfigCookieSamesite into pSameSite
    end if
	end if
  if pSameSite is not empty then
    # SET THE SameSite VALUE
    put  "; SameSite=" & pSameSite into pSameSite
  end if

	if pExp is not empty then
    put "Set-Cookie: " && pName & "=" & urlEncode(base64Encode(pValue)) & pPath & "; expires=" & _rigCookieExpirationDate(pExp) & pDomain & pHttpOnly & pSameSite into tHeaderString
	  rigSetHeader tHeaderString, pReplace

	else
    put "Set-Cookie: " && pName & "=" & urlEncode(base64Encode(pValue)) & pPath & pDomain & pHttpOnly & pSameSite into tHeaderString
	  rigSetHeader tHeaderString, pReplace
	end if
end _rigInputSetCookie







/*----------------------------------------------------------------------
--| FUNCTION _rigCookieExpirationDate
--|
--| Author: Sarah Reichelt
--| Version:  1.0
--| Created: 15-07-12
--| Last Mod: --
--| Requires: rigMasterNow()
--|
--| Summary: Build cookie expiration date.
--|
--| Format:  _rigCookieExpirationDate(param1)
--|
--| Parameters: integer <pSecondsToAdd>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCookieExpirationDate pSecondsToAdd
  local tExpirationDate, tYear, tDay, tDayName, tDate, tMonthNum
  local tMonth, tHour, tMinute, tSecond

	put rigMasterNow() into tExpirationDate
    ## ADD TIME IN SECONDS
    ## 86400 = ONE DAY
    ## 2592000 = THIRTY DAYS
    ## 31536000 = ONE YEAR
    if pSecondsToAdd is an integer then
        add pSecondsToAdd to tExpirationDate
    end if

    convert tExpirationDate to dateItems

    put item 1 of tExpirationDate into tYear

    ## BUILD EXPIRATION STRING
    put item 7 of tExpirationDate into tDay
    put line tDay of the weekdaynames into tDayName

    put item 3 of tExpirationDate into tDate
    if tDate < 10 then put "0" before tDate

    put item 2 of tExpirationDate into tMonthNum
    put line tMonthNum of the abbrev monthnames into tMonth

    put item 4 of tExpirationDate into tHour
    if tHour < 10 then put "0" before tHour

    put item 5 of tExpirationDate into tMinute
    if tMinute < 10 then put "0" before tMinute

    put item 6 of tExpirationDate into tSecond
    if tSecond < 10 then put "0" before tSecond

    put tDayName & comma && tDate & "-" & tMonth & "-" & tYear && tHour & ":" & tMinute & ":" & tSecond into tExpirationDate
    return tExpirationDate
end _rigCookieExpirationDate







/*----------------------------------------------------------------------
--| FUNCTION _rigSerializedPOSTtoArray
--|
--| Author: rabit
--| Version:  1.1
--| Created: 26-06-2013
--| Last Mod: 13-01-2015
--| Requires: _rigCleanInputKeys(), _rigCleanInputData()
--|
--| Summary: Clean, decode and decompress $_POST data including
--|            encoded / compressed LiveCode arrays.
--|
--| Format:  _rigSerializedPOSTtoArray(param1)
--|
--| Parameters: array <pPOSTdata>
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigSerializedPOSTtoArray pPOSTdata
	# TRAVERSE THE POST ARRAY, DECODE / DECOMPRESS ENCODED ARRAYS
	# AND SANITIZE ALL KEYS AND VALUES
	if pPOSTdata is an array then

		repeat for each key tDataKey in pPOSTdata

			put _rigCleanInputKeys(tDataKey) into tDataKey

			if pPOSTdata[tDataKey] is an array then
				put _rigSerializedPOSTtoArray(pPOSTdata[tDataKey], tDataKey) into pPOSTdata[tDataKey]
			else

				# IF THE STRING IS AN ENCODED ARRAY WE NEED TO DECODE OR DECODE AND DECOMPRESS
				# THE POST DATA DEPENDING ON THE CONTENT TYPE
				if sInputA["contentType"] is "application/lc.array" then
			  	try
              put arrayDecode(base64Decode(pPOSTdata[tDataKey])) into pPOSTdata[tDataKey]
			    	  put _rigSerializedPOSTtoArray(pPOSTdata[tDataKey]) into pPOSTdata[tDataKey]
			  	catch err
			    	-- rigLogMessage "info", "Failed to decode POST data of type application/lc.array."

			    	  put _rigCleanInputData(pPOSTdata[tDataKey]) into pPOSTdata[tDataKey]
			  	end try
				else if sInputA["contentType"] is "application/lc.array.compressed" then
					try
						 put arrayDecode(decompress(base64Decode(pPOSTdata[tDataKey]))) into pPOSTdata[tDataKey]
						 put _rigSerializedPOSTtoArray(pPOSTdata[tDataKey]) into pPOSTdata[tDataKey]
		 			catch err
						-- rigLogMessage "info", "Failed to decode POST data of type application/lc.array.compressed."

						put _rigCleanInputData(pPOSTdata[tDataKey]) into pPOSTdata[tDataKey]
		 			end try
				end if

			end if
		end repeat
		return pPOSTdata
	end if

	return FALSE
end _rigSerializedPOSTtoArray






/*----------------------------------------------------------------------
--| FUNCTION rigInputGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Get input array variable value.
--|
--| Format:  rigInputGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigInputGet pWhat
  if pWhat is among the keys of sInputA then
    return sInputA[pWhat]
  end if

  return empty
end rigInputGet





/*----------------------------------------------------------------------
--| COMMAND rigInputSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Setter for input variables.
--|
--| Format:  rigInputSet param1, param2
--|
--| Parameters: string <pKey> sInputA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigInputSet pKey pVal
  if (pKey is among the keys of sInputA) and (pKey is not among the items of sPrivateVars) then
    put pVal into sInputA[pKey]
  end if
end rigInputSet









--| END OF Input.livecodescript
--| Location:  ./system/libraries/Input.livecodescript
----------------------------------------------------------------------