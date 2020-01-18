script "Common"

##
# revIgniter
#
# An application development framework for LiveCode
# modeled onCodeIgniter.
#
# @package		revIgniter
# @author		  rabit@revigniter.com
# @copyright	Copyright (c) 2009 - 2020, dimensionB Bitter u. Bitter GmbH
# @license		https://revigniter.com/userGuide/license.html
# @link		    https://revigniter.com
##

## ------------------------------------------------------------------------

##
# Common Functions / Handlers
#
# Loads the base scripts and executes the request.
#
# @package		  revIgniter
# @subpackage  revigniter
# @category	    Common Handlers
# @author		    rabit@revigniter.com
# @link		      https://revigniter.com/userGuide
##

## ------------------------------------------------------------------------


global gRigA, gConfig

# DECLARE INCLUDED LIBRARIES ARRAY VARIABLE
# DECLARE MAIN CONFIGURATION  ARRAY VARIABLE
local sLoadedLibs, sMainConf, sNonce, sStackInUse





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-10
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
--| COMMAND rigLoadLibrary
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-05-30
--| Last Mod: 2019-05-07
--| Requires: rigAddToLibArray
--|
--| Summary: Library registry.
--| 				   Loads the requested library or sublibrary, if it was not included previously.
--|
--| Format:  rigLoadLibrary param1
--|
--| Parameters: string <pLibName> the library being requested
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLoadLibrary pLibName
  local tLoadedLibs

	put sLoadedLibs into tLoadedLibs
	combine tLoadedLibs using comma
	set the wholematches to TRUE

	if itemOffset(pLibName, tLoadedLibs) > 0 then
		# LIBRARY IS ALREADY LOADED
		exit rigLoadLibrary
	else
		if there is a file (gRigA["APPPATH"] & "libraries/" & rigConfigItem("sublibraryPrefix") & pLibName & ".livecodescript") then
      start using stack (gRigA["BASEPATH"] & "libraries/" & pLibName & ".livecodescript")
      start using stack (gRigA["APPPATH"] & "libraries/" & rigConfigItem("sublibraryPrefix") & pLibName & ".livecodescript")
		else
			if there is a file (gRigA["APPPATH"] & "libraries/" & pLibName & ".livecodescript") then
				start using stack (gRigA["APPPATH"] & "libraries/" & pLibName & ".livecodescript")
			else
        start using stack (gRigA["BASEPATH"] & "libraries/" & pLibName & ".livecodescript")
			end if
		end if
		rigAddToLibArray pLibName

	end if
end rigLoadLibrary






/*----------------------------------------------------------------------
--| FUNCTION rigGetConfig
--|
--| Author: rabit
--| Version:  1.1
--| Created: 30-05-09
--| Last Mod: 17-09-15
--| Requires: --
--|
--| Summary: Includes the main config file.
--|
--| Format:  rigGetConfig()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigGetConfig
	if sMainConf[1] is not an array then
	# FIRST CALL TO rigGetConfig
		if there is a file (gRigA["APPPATH"] & "config/config" & gRigA["EXT"]) then
      _rigRequire gRigA["APPPATH"] & "config/config" & gRigA["EXT"]

			if line 1 of the keys of gConfig is empty then
				put "Your config file does not appear to be formatted correctly." & "<br>" & gRigA["APPPATH"] & "config/config" & gRigA["EXT"]
				exit to top
			else
				put gConfig into sMainConf[1]
				return gConfig
			end if
		else
			put "The configuration file config" & gRigA["EXT"] && "does not exist."
			exit to top
		end if
	else
		return gConfig
	end if
end rigGetConfig







/*----------------------------------------------------------------------
--| FUNCTION rigIsMainConfigLoaded
--|
--| Author: rabit
--| Version:  1.0
--| Created: 05-07-09
--| Last Mod: 05-07-09
--| Requires: --
--|
--| Summary: Returns true, if main config file is loaded.
--|
--| Format:  rigIsMainConfigLoaded()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigIsMainConfigLoaded
	return sMainConf[1] is an array
end rigIsMainConfigLoaded






/*----------------------------------------------------------------------
--| FUNCTION rigConfigItem
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-05-09
--| Last Mod: 30-05-09
--| Requires: rigGetConfig()
--|
--| Summary: Gets a config item.
--|
--| Format:  rigConfigItem(param1)
--|
--| Parameters: string <pItem>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigConfigItem pItem
  local tTempConfig

	if pItem is not among the keys of gConfig then
		put rigGetConfig() into tTempConfig
		if pItem is not among the keys of tTempConfig then
			return FALSE
		else
			return tTempConfig[pItem]
		end if
	else
		return gConfig[pItem]
	end if
end rigConfigItem








/*----------------------------------------------------------------------
--| COMMAND rigShowError
--|
--| Author: rabit
--| Version:  1.1
--| Created: 29-06-09
--| Last Mod: 13-09-09
--| Requires: rigShowErrorPage
--|
--| Summary: Error Handler. This function lets us invoke the exception library and
--|                   display errors using the standard error template located
--|                   in application/errors/errors.lc
--|                   This function will send the error page directly to the
--|                   browser and exit.
--|
--| Format:  rigShowError param1
--|
--| Parameters: string <pMessage>, integer <pStatusCode>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigShowError pMessage pStatusCode
  local tStatusCode, tHeading

	rigLoadLibrary "Exceptions"

	if pStatusCode is empty then
		put 500 into tStatusCode
	else
		put pStatusCode into tStatusCode
	end if

	put "An Error Was Encountered" into tHeading

	# SEND ERROR PAGE TO THE BROWSER!
	put rigShowErrorPage(tHeading, pMessage, "errorGeneral", tStatusCode)
	exit to top
end rigShowError








/*----------------------------------------------------------------------
--| COMMAND rigShow404
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-06-09
--| Last Mod: 29-06-09
--| Requires: rigShow404Page
--|
--| Summary: This function is similar to the rigShowError command above
--|                    However, instead of the standard error template it displays
--|                    404 errors.
--|
--| Format:  rigShow404 param1
--|
--| Parameters: mixed <pPage>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigShow404 pPage
	rigLoadLibrary "Exceptions"

	rigShow404Page pPage
end rigShow404







/*----------------------------------------------------------------------
--| COMMAND rigLogMessage
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-05-09
--| Last Mod: 30-05-09
--| Requires: rigWriteLog in Log.lc
--|
--| Summary: Error Logging Interface, we use this as a simple mechanism to send messages to be logged.
--|
--| Format:  rigLogMessage param1, param2, param3
--|
--| Parameters: string <pLevel>, string <pMessage>, bool <pDisplayError>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLogMessage pLevel, pMessage, pDisplayError
  local tConfig

	put rigGetConfig() into tConfig
	if tConfig["logThreshold"] is 0 then
		exit rigLogMessage
	end if
	rigLoadLibrary "Log"
	rigWriteLog pLevel, pMessage, pDisplayError
end rigLogMessage






/*----------------------------------------------------------------------
--| COMMAND rigAddToLibArray
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-06-09
--| Last Mod: 17-06-09
--| Requires: --
--|
--| Summary: Add name of loaded library to the library array.
--|
--|
--| Format:  rigAddToLibArray param1
--|
--| Parameters: string<pLibName>
--|
--| Return: empty
----------------------------------------------------------------------*/
command rigAddToLibArray pLibName
  local tLibCount

	put the number of lines in the keys of sLoadedLibs into tLibCount
	add 1 to tLibCount
	put pLibName into sLoadedLibs[tLibCount]
end rigAddToLibArray









/*----------------------------------------------------------------------
--| COMMAND rigSetStatusHeader
--|
--| Author: rabit
--| Version:  1.2
--| Created: 23-07-09
--| Last Mod: 13-09-09
--| Requires: --
--|
--| Summary:  Set HTTP status header.
--|
--| Format:  rigSetStatusHeader param1, param2
--|
--| Parameters: int <pCode> the status code, string <pText>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetStatusHeader pCode, pText
  local tCode, tText, tStatiA

	if pCode is empty then
		put "200" into tCode
	else
		put pCode into tCode
	end if

	put pText into tText

	put "OK" into tStatiA["200"]
	put "Created" into tStatiA["201"]
	put "Accepted" into tStatiA["202"]
	put "Non-Authoritative Information" into tStatiA["203"]
	put "No Content" into tStatiA["204"]
	put "Reset Content" into tStatiA["205"]
	put "Partial Content" into tStatiA["206"]

	put "Multiple Choices" into tStatiA["300"]
	put "Moved Permanently" into tStatiA["301"]
	put "Found" into tStatiA["302"]
	put "Not Modified" into tStatiA["304"]
	put "Use Proxy" into tStatiA["305"]
	put "Temporary Redirect" into tStatiA["307"]

	put "Bad Request" into tStatiA["400"]
	put "Unauthorized" into tStatiA["401"]
	put "Forbidden" into tStatiA["403"]
	put "Not Found" into tStatiA["404"]
	put "Method Not Allowed" into tStatiA["405"]
	put "Not Acceptable" into tStatiA["406"]
	put "Proxy Authentication Required" into tStatiA["407"]
	put "Request Timeout" into tStatiA["408"]
	put "Conflict" into tStatiA["409"]
	put "Gone" into tStatiA["410"]
	put "Length Required" into tStatiA["411"]
	put "Precondition Failed" into tStatiA["412"]
	put "Request Entity Too Large" into tStatiA["413"]
	put "Request-URI Too Long" into tStatiA["414"]
	put "Unsupported Media Type" into tStatiA["415"]
	put "Requested Range Not Satisfiable" into tStatiA["416"]
	put "Expectation Failed" into tStatiA["417"]

	put "Internal Server Error" into tStatiA["500"]
	put "Not Implemented" into tStatiA["501"]
	put "Bad Gateway" into tStatiA["502"]
	put "Service Unavailable" into tStatiA["503"]
	put "Gateway Timeout" into tStatiA["504"]
	put "HTTP Version Not Supported" into tStatiA["505"]

	if tCode is not an integer then
		rigShowError "Status codes must be numeric.", 500
	end if

	if tCode is among the keys of tStatiA and tText is empty then
		put tStatiA[tCode] into tText
	end if

	if tText is empty then
		rigShowError "No status text available.  Please check your status code number or supply your own message text.", 500
	end if

	-- put $_SERVER["SERVER_PROTOCOL"] into tServerProtocol

	put header "Status:" && tCode && tText
end rigSetStatusHeader









/*----------------------------------------------------------------------
--| FUNCTION _rigExceptionHandler
--|
--| Author: Andre Garcia, modifications rabit
--| Version:  1.4
--| Created: 29-06-09
--| Last Mod: 23-07-16
--| Requires: rigLoadLibrary
--|
--| Summary: This function is used to log Rev errors, called by catch statements, in our log file.
--|            It also intercepts 404 errors.
--|
--| Format:  _rigExceptionHandler(param1)
--|
--| Parameters: string <pContexts>
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigExceptionHandler pContexts
  local tContextsKeysNum, tErrorNames, tTotalErrorListLines, tLineNumToGet
  local tErrMsg, tObject, tObjectName, tLinenr, tColumn, tProcToken, tErrorString

	rigLoadLibrary "Exceptions"

  split pContexts by return
  put the number of lines in the keys of pContexts into tContextsKeysNum

  if tContextsKeysNum > 100 then
    repeat with tIndex = 100 to tContextsKeysNum
      delete variable pContexts[tIndex]
    end repeat
    put 99 into tContextsKeysNum
	end if

  put the scriptExecutionErrors into tErrorNames

  split tErrorNames by return
  put the number of lines in the keys of tErrorNames into tTotalErrorListLines

  repeat with i = tContextsKeysNum down to 1
	  put item 1 of pContexts[i] into tLineNumToGet

      if tLineNumToGet > tTotalErrorListLines then
			next repeat
		end if

    put tErrorNames[tLineNumToGet] into tErrMsg

		if tErrMsg is "Object Name:" then
			put item 4 of pContexts[i] into tObject
			put tObject into tObjectName
		else
			if item 2 of pContexts[i] is not 0 then
				put item 2 of pContexts[i] into tLinenr
				put item 3 of pContexts[i] into tColumn
			end if

			put item 4 of pContexts[i] into tProcToken

			# CHECK IF IT IS A 404 ERROR
			# BUILD ERROR STRING
			if tErrMsg is empty and "/" is in tProcToken then
				put CR & tab & "error404" && "Processing Token:" & tProcToken & CR before tErrorString
			else
				put CR & tab & "Error description:" && tErrMsg & CR & tab & \
				"Object:" && tObjectName & CR & tab & \
				"Line:" && tLinenr && "Column:" && tColumn && \
				"Processing Token: " & tProcToken & CR  before tErrorString
			end if
		end if
	end repeat
	if first char of tErrorString = CR then
		delete first char of tErrorString
	end if
	if last char of tErrorString = CR then
		delete last char of tErrorString
	end if

	return tErrorString
end _rigExceptionHandler






/*----------------------------------------------------------------------
--| FUNCTION rigCanWriteFileTo
--|
--| Author: rabit
--| Version:  1.0
--| Created:  12-10-07
--| Last Mod: 12-10-07
--| Requires: --
--|
--| Summary: Tests for file writability.
--|
--| Format:  rigCanWriteFileTo(param1)
--|
--| Parameters: string <pLocation>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigCanWriteFileTo pLocation
  local tRandomFileName

    put pLocation & "/temp" & random(9999) into tRandomFileName
	# TRY CREATING A FILE
    open file tRandomFileName for write
    if the result is empty then -- success!
        close file tRandomFileName
	# GET RID OF THE TEST FILE
        delete file tRandomFileName
        return TRUE
    end if

    # FAILED - COULDN'T CREATE A FILE THERE
    return FALSE
end rigCanWriteFileTo








/*----------------------------------------------------------------------
--| FUNCTION rigHexDigest
--|
--| Author: Dave Cragg
--| Modification: rabit
--| Version:  1.2
--| Created:  --
--| Last Mod: 2019-08-18
--| Requires: --
--|
--| Summary: This will convert the 128-bit value that md5digest() returns, or the 256-bit
--|            value that SHA3-256 returns to a hex format (a string with 32 / 64 characters)
--|            similiar to that returned by PHP and other languages.
--|
--| Format:  rigHexDigest(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigHexDigest pStr
  local tDigestStr, tBinDecodedDigestStr

	set the itemDel to "."

  if (item 1 of the version < 9) or (gRigA["useLegacyCode"] is TRUE) then
    put md5digest(pStr) into tDigestStr
  else
    put messageDigest(pStr, "SHA3-256") into tDigestStr
  end if

  get binarydecode("H*",tDigestStr,tBinDecodedDigestStr)

  return tBinDecodedDigestStr
end rigHexDigest






/*----------------------------------------------------------------------
--| FUNCTION rigPregReplace
--|
--| Author: rabit
--| Version:  1.5
--| Created: 28-07-09
--| Last Mod: 21-03-14
--| Requires: --
--|
--| Summary: Find and replace multiple occurrences of a substring.
--|
--| Format:  rigPregReplace(param1, param2, param3, param4)
--|
--| Parameters: string <pStr>, string <pRegEx>, string <pStrToReplaceInFoundStr>, string <pReplacement> replacement string or name of callback handler
--|
--| Return: string
----------------------------------------------------------------------*/

function rigPregReplace pStr pRegEx pStrToReplaceInFoundStr pReplacement
  local tStrToCheck, tStrToReplaceInFoundStr, tCallback, tReplacement
  local tMatchFound, tStrToReturn, tStrOffset, tSearchStartNum, tFoundStr
  local tFoundStrLength, tStrLength, tStrFragment

	put pStr into tStrToCheck
	put pStrToReplaceInFoundStr into tStrToReplaceInFoundStr

	# GET NAME OF CALLBACK HANDLER
	if pReplacement is not empty then
		if char 1 to 10 of pReplacement is "_callback_" then
			put char 11 to -1 of pReplacement into tCallback
			put empty into tReplacement
		else
			put empty into tCallback
			put pReplacement into tReplacement
		end if

	else
		put empty into tCallback
		put empty into tReplacement
	end if

	put TRUE into tMatchFound

	put "" into tStrToReturn

	repeat until tMatchFound is FALSE
		get matchChunk(tStrToCheck,pRegEx,tStrOffset,tSearchStartNum)

		if it is TRUE then
			put char tStrOffset to tSearchStartNum of tStrToCheck into tFoundStr
			put (tSearchStartNum + 1) - tStrOffset into tFoundStrLength
			put the length of tStrToCheck into tStrLength

			# THE PART OF THE STRING WITH THE FIRST MATCH
			put char tStrOffset to (tStrOffset + (tFoundStrLength - 1)) of tStrToCheck into tStrFragment

			# REPLACE STRING
			if pStrToReplaceInFoundStr is empty then
				put tFoundStr into tStrToReplaceInFoundStr
			end if

			if tCallback is empty then
				replace tStrToReplaceInFoundStr with tReplacement in tStrFragment
			else
				do tCallback && quote & tStrToReplaceInFoundStr & quote
				replace tStrToReplaceInFoundStr with the result in tStrFragment
			end if

			# BUILD THE STRING TO RETURN
			put (char 1 to (tStrOffset -1) of tStrToCheck) & tStrFragment after tStrToReturn

			put char (tSearchStartNum + 1) to tStrLength of tStrToCheck into tStrToCheck

		else
			# NO MATCH FOUND
			if tStrToReturn is "" then
				put pStr into tStrToReturn
			else
				# ADD THE REMAINING PART TO THE STRING TO RETURN
				put tStrToCheck after tStrToReturn
			end if

			put FALSE into tMatchFound
		end if
	end repeat

	return tStrToReturn
end rigPregReplace








/*----------------------------------------------------------------------
--| FUNCTION rigPregQuote
--|
--| Author: rabit
--| Version:  1.1
--| Created: 07-10-09
--| Last Mod: 11-10-09
--| Requires: --
--|
--| Summary: Quote regular expression characters.
--|
--| Format:  rigPregQuote(param1)
--|
--| Parameters: string <pStr>, string <pDelimiter>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigPregQuote pStr pDelimiter
  local tRegExChars, tQuotedStr

    put "\+*?[^]$(){}=!<>|:" into tRegExChars
	if pDelimiter is not empty then
         put pDelimiter after tRegExChars
    end if

    repeat for each char thisChar in pStr
        if thisChar is in tRegExChars then
            put "\" & thisChar after tQuotedStr
        else
            put thisChar after tQuotedStr
        end if
    end repeat

    return tQuotedStr
end rigPregQuote









/*----------------------------------------------------------------------
--| FUNCTION rigHtmlSpecialChars
--|
--| Author: rabit
--| Version:  1.0
--| Created: 28-07-09
--| Last Mod: 28-07-09
--| Requires: --
--|
--| Summary: Convert special characters to HTML entities.
--|
--| Format:  rigHtmlSpecialChars(param1, param2)
--|
--| Parameters: string <pStr>, string <pQuoteStyle> is either empty to convert double quotes only or
--|               "ENT_QUOTES" to convert single and double, or "ENT_NOQUOTES"
--|
--| Return: string
----------------------------------------------------------------------*/

function rigHtmlSpecialChars pStr pQuoteStyle
  local tStr

	put pStr into tStr

	replace "&" with "&amp;" in tStr

	if pQuoteStyle is not "ENT_NOQUOTES" then
		if pQuoteStyle is "" then
			replace quote with "&quot;" in tStr
		else if pQuoteStyle is "ENT_QUOTES" then
			replace quote with "&quot;" in tStr
		replace "'" with "&#039;" in tStr
		end if
	end if

	replace "<" with "&lt;" in tStr
	replace ">" with "&gt;" in tStr

	return tStr
end rigHtmlSpecialChars







/*----------------------------------------------------------------------
--| FUNCTION rigTrim
--|
--| Author: rabit
--| Version:  1.5
--| Created: 2009-07-30
--| Last Mod: 2017-06-27
--| Requires: --
--|
--| Summary: Trim whitespace at the start and at the end of a string.
--|
--| Format:  rigTrim(param1[, param2])
--|
--| Parameters: string <pStr>, string <pCharsList>  an optional comma delimited list of chars to remove
--|
--| Return: string
----------------------------------------------------------------------*/

function rigTrim pStr pCharsList
  local tStrToReturn, tCharsToDeleteFound, tRegExWS, tSpecialChars, tStringIsClean
  local tCounter, tRegEx, tWhiteSpaceFound

  put pStr into tStrToReturn

   if pCharsList is empty then
      put FALSE into tCharsToDeleteFound
   else if pCharsList is comma then
      replace comma with numToCodepoint(2) in pCharsList
   else if ",," is in pCharsList then
      replace ",," with (numToCodepoint(2) & comma) in pCharsList
   end if

   put "(^\s+)|(\s+$)" into tRegExWS

   put "^,.,\,*,+,?,|,$" into tSpecialChars

   put False into tStringIsClean

   put 0 into tCounter

   repeat until tStringIsClean is TRUE
      add 1 to tCounter
      put replacetext(tStrToReturn,tRegExWS,empty) into tStrToReturn

      if pCharsList is not empty then
         repeat for each item tChar in pCharsList

            if codepointToNum(tChar) is 2 then
               put "," into tChar
            end if

            if tChar is among the items of tSpecialChars then
               put "\" & tChar into tChar
            end if

            put "(^" & tChar & "+)|(" & tChar & "+$)" into tRegEx
            put replacetext(tStrToReturn,tRegEx,empty) into tStrToReturn
         end repeat

         # CHECK IF STRING IS CLEAN NOW
         repeat for each item tChar in pCharsList

            if codepointToNum(tChar) is 2 then
               put "," into tChar
            end if

            if tChar is among the items of tSpecialChars then
               put "\" & tChar into tChar
            end if

            put "(^" & tChar & "+)|(" & tChar & "+$)" into tRegEx
            put matchText(tStrToReturn,tRegEx) into tCharsToDeleteFound
            if tCharsToDeleteFound is TRUE then
               exit repeat
            end if
         end repeat
      end if

      # CHECK IF STRING IS CLEAN NOW
      put matchtext(tStrToReturn,tRegExWS) into tWhiteSpaceFound

      if (tWhiteSpaceFound is FALSE) and (tCharsToDeleteFound is FALSE) then
         put TRUE into tStringIsClean
      end if

      # STOP HERE IN CASE SOMETHING WENT WRONG AND THE LOOP IS RUNNING FOR EVER
      if tCounter > 999 then
         put TRUE into tStringIsClean
      end if
   end repeat

   return tStrToReturn
end rigTrim







/*----------------------------------------------------------------------
--| FUNCTION rigRTrim
--|
--| Author: rabit
--| Version:  1.1
--| Created: 16-08-09
--| Last Mod: 22-09-09
--| Requires: --
--|
--| Summary: Trim whitespace at the end of a string.
--|
--| Format:  rigRTrim(param1, param2)
--|
--| Parameters: string <pStr>, string <pTrimChar>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigRTrim pStr pTrimChar
  local tStrToReturn, tRegExWS, tStringIsClean, tCounter, tWhiteSpaceFound

  put pStr into tStrToReturn

  if pTrimChar is empty then
    put "(\s+$)" into tRegExWS
  else
    if pTrimChar is not in "\/+-.<>" then
      put "(" & pTrimChar & "+$)" into tRegExWS
    else
      put "(\" & pTrimChar & "+$)" into tRegExWS
    end if
  end if

  put False into tStringIsClean

  put 0 into tCounter

  repeat until tStringIsClean is TRUE
    add 1 to tCounter
    put replacetext(tStrToReturn,tRegExWS,empty) into tStrToReturn

    # CHECK IF STRING IS CLEAN NOW
    put matchtext(tStrToReturn,tRegExWS) into tWhiteSpaceFound

    if tWhiteSpaceFound is FALSE then
      put TRUE into tStringIsClean
    end if

    # STOP HERE IN CASE SOMETHING WENT WRONG AND THE LOOP IS RUNNING FOR EVER
    if tCounter > 999 then
      put TRUE into tStringIsClean
    end if
  end repeat

  return tStrToReturn
end rigRTrim







/*----------------------------------------------------------------------
--| FUNCTION rigStripSlashes
--|
--| Author: rabit
--| Version:  1.0
--| Created: 02-08-09
--| Last Mod: 02-08-09
--| Requires: --
--|
--| Summary: Un-quotes a quoted string.
--|
--| Format:  rigStripSlashes(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigStripSlashes pStr
  local tStr

	put pStr into tStr

	replace "\\" with "+++|r---b|+++" in tStr
	replace "\" with "" in tStr
	replace "+++|r---b|+++" with "\" in tStr

	return tStr
end rigStripSlashes







/*----------------------------------------------------------------------
--| FUNCTION rigAddCslashes
--|
--| Author: rabit
--| Version:  1.1
--| Created: 15-08-09
--| Last Mod: 22-12-14
--| Requires: --
--|
--| Summary: Quote string with slashes in a C style. Keep in mind, that octal escape values are used
--|            in parameters of this function.
--|
--| Format:  rigAddCslashes(param1, param2, param3)
--|
--| Parameters: string <pStr>, string <pCharList> like "\0..\37,\177,'," & quote & ",\", string <pItemDel>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigAddCslashes pStr pCharList pItemDel
  local tRangeValues, tFromVal, tToVal, tCharRange, tCharNum, tStrWithSlashes

  if pItemDel is not empty then
    set the itemdelimiter to pItemDel
  else
    set the itemdelimiter to comma
  end if

  repeat for each item thisItem in pCharList

    if ".." is in thisItem then
      put thisItem into tRangeValues
      replace ".." with "," in tRangeValues
      put item 1 of tRangeValues into tFromVal
      put item 2 of tRangeValues into tToVal

      # CHECK IF WE ARE DEALING WITH ASCII NUMBERS
      # LIKE: \0..\37
      if (char 1 of tFromVal is "\") and (char 2 of tFromVal is an integer) then
        delete char 1 of tFromVal
        # CONVERT TO DECIMAL VALUES
        put baseconvert(tFromVal,8,10) into tFromVal
        delete char 1 of tToVal
        # CONVERT TO DECIMAL VALUES
        put baseconvert(tToVal,8,10) into tToVal

      else
        # CHARACTER RANGE LIKE: A..z
        put codepointToNum(tFromVal) into tFromVal
        put codepointToNum(tToVal) into tToVal
      end if

      if tToVal > tFromVal then
        repeat with tCurrentNum = tFromVal to tToVal
          put numToCodepoint(tCurrentNum) after tCharRange
        end repeat
      end if
    end if

    # ASCII NUMBER LIKE: \177
    if (".." is not in thisItem) and (char 1 of thisItem is "\") and (char 2 of thisItem is an integer) then
      put char 2 to -1 of thisItem into tCharNum
      # CONVERT TO DECIMAL VALUES
      put baseconvert(tCharNum,8,10) into tCharNum
      put numToCodepoint(tCharNum) after tCharRange
    end if

    # SINGEL CHARACTER
    if the number of chars of thisItem is 1 then
      put thisItem after tCharRange
    end if
  end repeat

  # CHECK EACH CHARACTER IN STRING
  # ADD SLASH IF NEEDED
  repeat for each char thisChar in pStr
    if thisChar is in tCharRange then
      put "\" & thisChar after tStrWithSlashes
    else
      put thisChar after tStrWithSlashes
    end if
  end repeat

  return tStrWithSlashes
end rigAddCslashes








/*----------------------------------------------------------------------
--| FUNCTION rigInArray
--|
--| Author: rabit
--| Version:  1.0
--| Created: 16-08-09
--| Last Mod: 16-08-09
--| Requires: --
--|
--| Summary: Checks if a value exists in an array.
--|
--| Format:  rigInArray(param1, param2)
--|
--| Parameters: array <pArray>, string <pVal>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigInArray pArray pVal
    repeat for each element thisElement in pArray
        if thisElement is pVal then
             return TRUE
        end if
    end repeat

    return FALSE
end rigInArray






/*----------------------------------------------------------------------
--| FUNCTION rigStripHTML
--|
--| Author: sts, modification by rabit
--| Version:  1.2
--| Created:  2009-08-17
--| Last Mod: 2018-04-23
--| Requires:  --
--|
--| Summary: Strips html tags.
--|
--| Format:  rigStripHTML(param1)
--|
--| Parameters: string <pHTML>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigStripHTML pHTML
  local tStrippedText

  put pHTML into tStrippedText
  put replacetext(tStrippedText,"(?si)<script.*?/script>","") into tStrippedText
  put replacetext(tStrippedText,"(?si)<style.*?/style>","") into tStrippedText
  put replacetext(tStrippedText,tab,"") into tStrippedText
  put replacetext(tStrippedText,"(?sm)<.*?>","") into tStrippedText
  put replacetext(tStrippedText,CR & "{3,}","") into tStrippedText

  return tStrippedText
end rigStripHTML









/*----------------------------------------------------------------------
--| FUNCTION rigWordWrap
--|
--| Author: rabit
--| Version:  1.1
--| Created:  19-08-09
--| Last Mod: 21-09-09
--| Requires:  --
--|
--| Summary: Wraps a string to a given number of characters.
--|
--| Format:  rigWordWrap(param1, param2, param3, param4)
--|
--| Parameters: string <pStr>, integer <pLength> the column width (defaults to 75), string <pBreak> defaults to LF, bool <pCut> if TRUE breaks words apart
--|
--| Return: string
----------------------------------------------------------------------*/

function rigWordWrap pStr pLength pBreak pCut
  local tStr, tOverrun, tLineLength, tOverrunExeedsPlength, tWrapedStr
  local tLineToAdd, tWord1Length, tNextLineToAdd

	if pLength is empty then
		put 75 into pLength
	end if

	if pBreak is empty then
		put LF into pBreak
	end if

	if pCut is empty then
		put FALSE into pCut
	end if

    put pStr into tStr

    replace pBreak with return in tStr

    put "" into tOverrun

    repeat for each line thisLine in tStr
        if (char 1 of thisLine is " ") or (char 1 of thisLine is tab) then
            delete char 1 of thisLine
        end if

        if tOverrun is not empty then
            if pCut is TRUE then
                if (char -1 of tOverrun <> " ") or (char 1 of thisLine <> " ") then
                    put tOverrun && thisLine into thisLine
                else
                    put tOverrun & thisLine into thisLine
                end if
            else
                put tOverrun & thisLine into thisLine
            end if
            put "" into tOverrun
        end if

        put the length of thisLine into tLineLength
        if tLineLength > pLength then
            if pCut is TRUE then

                put TRUE into tOverrunExeedsPlength

                repeat until tOverrunExeedsPlength is FALSE

                    if (char 1 of thisLine is " ") or (char 1 of thisLine is tab) then
                        delete char 1 of thisLine
                    end if

                    put the length of thisLine into tLineLength
                    put char (pLength + 1) to tLineLength of thisLine into tOverrun

                    if (the length of tOverrun) <= pLength then


                        if (char -1 of tOverrun is " ") or (char -1 of tOverrun is tab) then
                            delete char -1 of tOverrun
                        end if
                        put (char 1 to pLength of thisLine) & return after tWrapedStr


                        put FALSE into tOverrunExeedsPlength
                    else
                        put (char 1 to pLength of thisLine) & return after tWrapedStr
                        if (char -1 of tOverrun is " ") or (char -1 of tOverrun is tab) then
                            delete char -1 of tOverrun
                        end if
                        put (char 1 to pLength of tOverrun) & return after tWrapedStr

                        put char ((pLength * 2)+ 1) to (the length of thisLine) of thisLine into thisLine
                    end if

                end repeat

            else -- if pCut is TRUE then


                put TRUE into tOverrunExeedsPlength

                repeat until tOverrunExeedsPlength is FALSE

                    if (char 1 of thisLine is " ") or (char 1 of thisLine is tab) then
                        delete char 1 of thisLine
                    end if

                    put the length of thisLine into tLineLength
                    put char (pLength + 1) to tLineLength of thisLine into tOverrun

                    if (the length of tOverrun) <= pLength then

                        put (char 1 to pLength of thisLine) into tLineToAdd
                        put char (pLength + 1) to tLineLength of thisLine into tOverrun

                        if char 1 of tOverrun is not " " then
                            put word 1 of tOverrun after tLineToAdd

                            put the length of (word 1 of tOverrun) into tWord1Length
                            put char (tWord1Length + 2) to (the length of tOverrun) of tOverrun into tOverrun
                        else
                            delete char 1 of tOverrun
                        end if

                        put tLineToAdd & return after tWrapedStr

                        put FALSE into tOverrunExeedsPlength

                    else -- if (the length of tOverrun) <= pLength then

                        put (char 1 to pLength of thisLine) into tLineToAdd
                        put char (pLength + 1) to tLineLength of thisLine into tOverrun

                        if char 1 of tOverrun is not " " then
                            put word 1 of tOverrun after tLineToAdd

                            put the length of (word 1 of tOverrun) into tWord1Length
                            put char (tWord1Length + 2) to (the length of tOverrun) of tOverrun into tOverrun
                        else
                            delete char 1 of tOverrun
                        end if

                        put tLineToAdd & return after tWrapedStr

                        if (the length of tOverrun) > pLength then
                            put (char 1 to pLength of tOverrun) into tNextLineToAdd
                            put char ((the length of tNextLineToAdd) + 1) to (the length of tOverrun) of tOverrun into tOverrun

                            if char 1 of tOverrun is not " " then
                                put word 1 of tOverrun after tNextLineToAdd

                                put the length of (word 1 of tOverrun) into tWord1Length
                                put char (tWord1Length + 2) to (the length of tOverrun) of tOverrun into tOverrun
                            else
                                delete char 1 of tOverrun
                            end if

                            put tNextLineToAdd & return after tWrapedStr
                            put tOverrun into thisLine
                        else

                            put tOverrun into thisLine
                        end if --  if (the length of tOverrun) > pLength then

                    end if -- if (the length of tOverrun) <= pLength then

                end repeat

            end if  -- if pCut is TRUE then

        else
            put thisLine & return after tWrapedStr
        end if
    end repeat

    delete char -1 of tWrapedStr

    if tOverrun is not empty then
        if (char 1 of tOverrun is " ") or (char 1 of tOverrun is tab) then
            delete char 1 of tOverrun
        end if

        put return & tOverrun after tWrapedStr
    end if

    replace return with pBreak in tWrapedStr

    return tWrapedStr
end rigWordWrap







/*----------------------------------------------------------------------
--| FUNCTION rigShellEscape
--|
--| Author: splash21
--| Version:  1.0
--| Created:  11-09-09
--| Last Mod: 11-09-09
--| Requires:  --
--|
--| Summary: Escape shell characters.
--|
--| Format:  rigShellEscape(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigShellEscape pStr
    repeat for each char tChar in "\`!$" & quote
        replace tChar with "\" & tChar in pStr
    end repeat
    return pStr
end rigShellEscape







/*----------------------------------------------------------------------
--| FUNCTION _rigTempMailPath
--|
--| Author: rabit
--| Version:  1.1
--| Created: 17-09-09
--| Last Mod: 13-11-14
--| Requires: rigFetchConfigItem()
--|
--| Summary: Build path to temporary mail data to be piped into shell commands mail or sendmail.
--|
--| Format:  _rigTempMailPath()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigTempMailPath
  local tPreviousUmask, tTempFolderPath, tMessageId, tTempMailPath

	set the convertOctals to true
	put the umask into tPreviousUmask
	set the umask to "0077"

	repeat forever
		try
			put the tempName into tTempFolderPath
			create folder tTempFolderPath
			exit repeat
		catch e
			if there is a folder tTempFolderPath then next repeat
			if there is a file tTempFolderPath then next repeat
		end try
	end repeat

	put the milliseconds into tMessageId

	repeat 10
		put any char of "abcdefghijklmnopqrstuvwxyz" after tMessageId
	end repeat

	put (tTempFolderPath & "/tempMail" & tMessageId & ".txt") into tTempMailPath

	set the umask to tPreviousUmask

	return tTempMailPath
end _rigTempMailPath





/*----------------------------------------------------------------------
--| FUNCTION rigCeil
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-09-09
--| Last Mod: 2016-11-24
--| Requires: --
--|
--| Summary: Returns the next highest integer value by rounding up if necessary.
--|
--| Format:  rigCeil(param1)
--|
--| Parameters: number <pNum>
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigCeil pNum
   if trunc(pNum) <> pNum then
      if pNum > 0 then
         return trunc(pNum) + 1
      else
         return trunc(pNum)
      end if
   end if

   return pNum
end rigCeil








/*----------------------------------------------------------------------
--| FUNCTION rigNumber_format
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-09-09
--| Last Mod: 30-09-09
--| Requires: --
--|
--| Summary: Format a number with grouped thousands.
--|
--| Format:  rigNumber_format(param1, param2, param3)
--|
--| Parameters: number <pNum>, integer <pDecimals>, string <pSeparator>
--|
--| Return: float
----------------------------------------------------------------------*/

function rigNumber_format pNum pDecimals, pSeparator
  local tDecimals, tSeparator, tPrefix, tNum, tDecNum

	if (pDecimals is empty) or (pDecimals is not a integer) then
		put 2 into tDecimals
	else
		put pDecimals into tDecimals
	end if

	if pSeparator is empty then
		put "," into tSeparator
	else
		put pSeparator into tSeparator
	end if

	 if char 1 of pNum = "-" then
    		put "-" into tPrefix
    		put char 2 to -1 of pNum into tNum
	else
		put "" into tPrefix
		put pNum into tNum
  	end if

	put format("%1." & tDecimals & "f",pNum) into tNum

    	set the itemdel to "."
    	put "." & item 2 of tNum into tDecNum
    	put item 1 of tNum into tNum

    	repeat with i = length(tNum)-3 to 3 step -3
        	put tSeparator before char i+1 of tNum
    	end repeat

    	return tPrefix & tNum & tDecNum
end rigNumber_format







/*----------------------------------------------------------------------
--| FUNCTION rigArrayReverse
--|
--| Author: rabit
--| Version:  1.0
--| Created: 05-10-09
--| Last Mod: 05-10-09
--| Requires: --
--|
--| Summary: Return an array with elements in reverse order.
--|               Works with numbered arrays only!!!!!!
--|
--| Format: rigArrayReverse(param1)
--|
--| Parameters: array <pArray>, char <pItemDelimiter>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigArrayReverse pArray pItemDelimiter
  local tArray, tReversedArray

  if pItemDelimiter is empty then
    set the itemdel to "="
  else
    set the itemdel to pItemDelimiter
  end if

  put pArray into tArray

  # CONVERT ARRAY TO LIST
  combine tArray using return and the itemdel

  # SORT LINES
  sort lines of tArray descending numeric by item 1 of each

  repeat with i = 1 to (the number of lines in tArray)
    put item 2 of line i of tArray into tReversedArray[i]
  end repeat

  return tReversedArray
end rigArrayReverse








/*----------------------------------------------------------------------
--| FUNCTION rigFile_get_contents
--|
--| Author: rabit
--| Version:  1.1
--| Created: 08-10-09
--| Last Mod: 02-02-15
--| Requires: rigLogMessage
--|
--| Summary: Reads entire file into a string.
--|
--| Format:  rigFile_get_contents(param1)
--|
--| Parameters: string <pFilePath>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigFile_get_contents pFilePath
  local tFileData

  if there is a file pFilePath then
    put URL format("binfile:%s", pFilePath) into tFileData

    if the result is empty then
      return tFileData
    else
      rigLogMessage "error", "Failed to read file! System error:" && the sysError
    end if
  end if

  return FALSE
end rigFile_get_contents








/*----------------------------------------------------------------------
--| FUNCTION rigCheckType
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-10-09
--| Last Mod: 12-10-09
--| Requires: --
--|
--| Summary: Get the data type.
--|
--| Format:  rigCheckType(param1)
--|
--| Parameters: string, integer, float, bool <pData>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigCheckType pData
    if pData is not an array then
        if pData is a number then
            if pData is not an integer then
                return "f"
            end if
            return "i"
        end if

        if pData is a boolean then
            return "b"
        end if

        return "s"
    else
         return "a"
    end if
end rigCheckType








/*----------------------------------------------------------------------
--| FUNCTION rigRandomNum
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2009-10-14
--| Last Mod: 2019-07-31
--| Requires: --
--|
--| Summary: Get the random number used for encryption and to build a session id.
--|
--| Format:  rigRandomNum()
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

function rigRandomNum
  local tSessID, tCounter, tSeed, tUpperLimit, tLowerLimit

  put "" into tSessID

  put 2147483647 into tUpperLimit
  put 0 into tLowerLimit

  put 1 into tCounter

  repeat while (the length of tSessID) < 32
    put (char -8 to -1 of the millisecs) + tCounter into tSeed
    set the randomSeed to tSeed

    put random(tUpperLimit - tLowerLimit + 1) + tLowerLimit -1 after tSessID

    add 1 to tCounter
  end repeat

  return tSessID
end rigRandomNum









/*----------------------------------------------------------------------
--| FUNCTION rigSubstr
--|
--| Author: rabit
--| Version:  1.1
--| Created: 16-10-09
--| Last Mod: 21-03-14
--| Requires: --
--|
--| Summary: Return part of a string.
--|
--| Format:  rigSubstr(param1, param2, param3)
--|
--| Parameters: string <pString>, integer <pStart>, integer <pLength>
--|
--| Return: empty
----------------------------------------------------------------------*/

function rigSubstr pString pStart pLength
  local tLastChar

  put pStart + (pLength - 1) into tLastChar
  return char pStart to tLastChar of pString
end rigSubstr









/*----------------------------------------------------------------------
--| FUNCTION rigSubstrToNum
--|
--| Author: rabit
--| Version:  1.2
--| Created: 16-10-09
--| Last Mod: 23-12-14
--| Requires: --
--|
--| Summary: Return part of a string as ascii values.
--|
--| Format:  rigSubstrToNum(param1, param2, param3, param4)
--|
--| Parameters: string <pString>, integer <pStart>, integer <pLength>, bool <pNative>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSubstrToNum pString pStart pLength pNative
  local tLastChar, tStr, tSubstr

  put pStart + (pLength - 1) into tLastChar
  put char pStart to tLastChar of pString into tStr

  repeat for each char thisChar in tStr
    if pNative then
      put nativeCharToNum(thisChar) after tSubstr
    else
      put codepointToNum(thisChar) after tSubstr
    end if
  end repeat

  return tSubstr
end rigSubstrToNum








/*----------------------------------------------------------------------
--| COMMAND rigDoException
--|
--| Author: rabit
--| Version:  1.2
--| Created: 17-10-09
--| Last Mod: 23-07-16
--| Requires: rigConfigItem(), _rigExceptionHandler(), rigLogException
--|
--| Summary: Display or log exceptions of try catch statements.
--|
--| Format:  rigDoException param1, param2, param3
--|
--| Parameters: string <pContexts> a list of error numbers, string <pCurrentFile>, string <pCurrentHandler>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDoException pContexts pCurrentFile pCurrentHandler
  local tDisplayError, tErrorData

	if rigConfigItem("logThreshold") > 0 then
		put TRUE into tDisplayError
	else
		put FALSE into tDisplayError
	end if

	put _rigExceptionHandler(pContexts) into tErrorData

	rigLogException tErrorData, tDisplayError, pCurrentFile, pCurrentHandler
end rigDoException







/*----------------------------------------------------------------------
--| FUNCTION rigIsNumberedArray
--|
--| Author: rabit
--| Version:  1.0
--| Created: 16-12-09
--| Last Mod: 16-12-09
--| Requires: --
--|
--| Summary: Check if array is numbered.
--|
--| Format:  rigIsNumberedArray(param1, param2)
--|
--| Parameters: array <pArray>, bool <pConsecutive> flag for checking if numbers are consecutive
--|
--| Return: list (bool,integer)
----------------------------------------------------------------------*/

function rigIsNumberedArray pArray pConsecutive
  local tConsecutive, tNumbered, tArrayKeys, tControlValue
  local tStartValue

	if pConsecutive is "" then
		put FALSE into tConsecutive
	else
		put pConsecutive into tConsecutive
	end if

	# CHECK IF ARRAY IS NUMBERED
	# SET DEFAULT RETURN VALUE
	put TRUE into tNumbered
	put the keys of pArray into tArrayKeys

	if tConsecutive is true then
		sort lines of tArrayKeys numeric

		put 2 into tControlValue

		repeat for each line thisLine in tArrayKeys
			if (thisLine is not an integer) or (thisLine + 1 <> tControlValue) then
				put FALSE into tNumbered
				exit repeat
			end if
			add 1 to tControlValue
		end repeat
	else
		repeat for each line thisLine in tArrayKeys
			if thisLine is not an integer then
				put FALSE into tNumbered
				exit repeat
			end if
		end repeat
	end if

	put line 1 of tArrayKeys into tStartValue

	return tNumbered & "," & tStartValue
end rigIsNumberedArray










/*----------------------------------------------------------------------
--| FUNCTION rigUcwords
--|
--| Author: rabit
--| Version:  1.2
--| Created: 21-01-10
--| Last Mod: 08-01-15
--| Requires: --
--|
--| Summary: Uppercase the first character of each word in a string.
--|
--| Format:  rigUcwords(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigUcwords pStr
  local tUCstr, tCounter

	put pStr into tUCstr

	put 0 into tCounter
	repeat for each word thisWord in pStr
		add 1 to tCounter

		if ((codepointToNum(char 1 of thisWord) >= 97) and (codepointToNum(char 1 of thisWord) <= 122)) or \
			((codepointToNum(char 1 of thisWord) >= 135) and (codepointToNum(char 1 of thisWord) <= 159)) then

			put toUpper(char 1 of thisWord) into char 1 of thisWord

			replace word tCounter of tUCstr with thisWord in tUCstr
		end if
	end repeat

	return tUCstr
end rigUcwords







/*----------------------------------------------------------------------
--| FUNCTION rigNl2br
--|
--| Author: rabit
--| Version:  1.0
--| Created: 03-03-10
--| Last Mod: 03-03-10
--| Requires: --
--|
--| Summary: Inserts HTML line breaks before all newlines in a string.
--|
--| Format:  rigNl2br(param1, param2)
--|
--| Parameters: string <pStr>, bool <pIsXHTML>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigNl2br pStr pIsXHTML
  local tIsXHTML

  if pIsXHTML is empty then
    put TRUE into tIsXHTML
  else
    put pIsXHTML into tIsXHTML
  end if

  if tIsXHTML is TRUe then
    replace return with "<br />" & return in pStr
  else
    replace return with "<br>" & return in pStr
  end if

  return pStr
end rigNl2br







/*----------------------------------------------------------------------
--| FUNCTION rigGetHTTPheader
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-07-11
--| Last Mod: 2016-07-11
--| Requires: --
--|
--| Summary: Return value of any HTTP header.
--|
--| Format:  rigGetHTTPheader(param1)
--|
--| Parameters: string <pHeader>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigGetHTTPheader pHeader
  replace "-" with "_" in pHeader
  put "HTTP_" & pHeader into pHeader
  return $_SERVER[pHeader]
end rigGetHTTPheader






/*----------------------------------------------------------------------
--| FUNCTION rigRawURLdecode
--|
--| Author: rabit
--| Version:  1.2
--| Created: 29-06-10
--| Last Mod: 22-12-14
--| Requires: --
--|
--| Summary: Returns the decoded URL as string.
--|            Does not decode plus symbols ('+') into spaces.
--|
--| Format:  rigRawURLdecode(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigRawURLdecode pStr
  local tStrDecoded

  replace "+" with "-r" & numToCodepoint(1) & "b-" in pStr
  put URLDecode(pStr) into tStrDecoded
  replace "-r" & numToCodepoint(1) & "b-" with "+" in tStrDecoded

  return tStrDecoded
end rigRawURLdecode




/*----------------------------------------------------------------------
--| FUNCTION rigUniqid
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2011-09-04
--| Last Mod: 2019-01-06
--| Requires: --
--|
--| Summary: Build a unique identifier.
--|
--| Format:  rigUniqid(param1)
--|
--| Parameters: integer <pLength>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigUniqid pLength
  local tUUID

  if pLength <> empty then
	  repeat pLength
  	  put any char of "-1234567890abcdefghijklmnopqrstuvwxyz" after tUUID
    end repeat

    return tUUID
  end if

  put uuid() into tUUID

	return tUUID
end rigUniqid





/*----------------------------------------------------------------------
--| FUNCTION rigNonce
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2018-10-24
--| Last Mod: 2018-10-24
--| Requires: rigHexDigest(), rigUniqid()
--|
--| Summary: Generate a random string unique for each request
--|            as used by Content-Security-Policy response headers.
--|
--| Format:  rigNonce()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigNonce
  if sNonce is empty then
    put rigHexDigest(rigUniqid()) into sNonce
  end if

  return sNonce
end rigNonce





/*----------------------------------------------------------------------
--| FUNCTION rigMasterNow
--|
--| Author: rabit
--| Version:  1.0
--| Created: 15-07-2012
--| Last Mod: --
--| Requires: rigFetchConfigItem()
--|
--| Summary: Returns the current time as timestamp (seconds) referenced, either
--|            to your server's local time or GMT, based on the "timeReference"
--|            setting in your config file.
--|
--| Format:  rigMasterNow()
--|
--| Parameters: --
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigMasterNow
  local tNow, tGMToffset, tPrefix, tMinutesOffset, tHoursOffset, tGMToffsetSecs, tTime

	if toLower(rigFetchConfigItem("timeReference")) is "gmt" then
		# GET THE DATETIME IN SECONDS
		convert the internet date to seconds
		put it into tNow

		# GET GMT OFFSET
		put the last word of the internet date into tGMToffset

		if char 1 of tGMToffset is "-" then
			put "-" into tPrefix
		else
			put "" into tPrefix
		end if

		# MINUTES
		put char -2 to -1 of tGMToffset into tMinutesOffset
		# HOURS
		put char 2 to 3 of tGMToffset into tHoursOffset
		# CONVERT OFFSET TO SECONDS
		put tPrefix & ((tHoursOffset * 3600) + (tMinutesOffset * 60)) into tGMToffsetSecs

		# GET GMT IN SECONDS
		put tNow - tGMToffsetSecs into tTime
	else
		convert the internet date to seconds
		put it into tTime
	end if

	return tTime
end rigMasterNow





/*----------------------------------------------------------------------
--| FUNCTION _rigStrToArray
--|
--| Author: rabit
--| Version:  1.3
--| Created: 16-08-09
--| Last Mod: 18-10-16
--| Requires: rigTrim()
--|
--| Summary: Convert a string ( for example a comma delimited list like
--|           "item1, item2, item3") to a numbered or associative array.
--|
--| Format:  _rigStrToArray(param1[, param2][, param3][, param4])
--|
--| Parameters: mixed <pString>, char <pDelimiter> (optional), bool <pAssoc> (optional),
--|               bool <pKeepSpace> (optional) keep space in keys and values
--|
--| Return: array
----------------------------------------------------------------------*/

function _rigStrToArray pString pDelimiter pAssoc pKeepSpace
  local tDelimiter, tStrToArray, tNumItems

  # SET DELIMITER
  if pDelimiter is empty then
    put "," into tDelimiter
  else
    put char 1 of pDelimiter into tDelimiter
  end if

  # MAKE SURE WE ARE DEALING WITH A STRING
  # OTHERWISE JUST RETURN THE FIRST PARAMETER
  if pString is not an array then
    # CHECK IF THE LIST CONSISTS OF MORE THAN ONE ITEM
    if tDelimiter is in pString then

      # REMOVE WHITESPACE
      if tDelimiter <> space then
        if pKeepSpace is TRUE then
          put replacetext( pString, tDelimiter & "[ ]+", tDelimiter) into pString
        else
          put replacetext( pString,"[ ]+","") into pString
        end if
      end if

      # BUILD NUMBERED ARRAY
      if pAssoc <> TRUE then
        put pString into tStrToArray
        split tStrToArray using tDelimiter

        repeat for each key tKey in tStrToArray
          if tStrToArray[tKey] is empty then
            delete variable tStrToArray[tKey]
          end if
        end repeat

      else
        # BUILD ASSOCIATIVE ARRAY
        set the itemDel to tDelimiter

        put the number of items of pString into tNumItems
        # THE NUMBER OF STRINGS MUST BE EVEN, IF NOT DISREGARD THE LAST ONE
        if tNumItems mod 2 <> 0 then
          put tNumItems -1 into tNumItems
        end if

        repeat with tItem = 1 to (tNumItems - 1) step 2
          put item (tItem + 1) of pString into tStrToArray[item tItem of pString]
        end repeat
      end if

    else -- if tDelimiter is in pString then
      # ONLY ONE ITEM FOUND, REMOVE WHITESPACE
      put rigTrim(pString) into tStrToArray
      put tStrToArray into tStrToArray[1]
    end if -- if tDelimiter is in pString then

  else -- if pString is not an array then
    return pString
  end if -- if pString is not an array then

  return tStrToArray
end _rigStrToArray






/*----------------------------------------------------------------------
--| FUNCTION rigFileSize
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2014-02-12
--| Last Mod: 2019-03-16
--| Requires: rigIsAbsolutePath()
--|
--| Summary: Gets the file size of a given file.
--|
--| Format:  rigFileSize(param1)
--|
--| Parameters: string <pFilePath>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigFileSize pFilePath
  local tFolderName, tFileName, tFileList, tInfo

  if there is a file pFilePath then
  else
    return FALSE
  end if

  # USE ABSOLUTE PATH
  put rigTrim(pFilePath, "/") into pFilePath
  if not rigIsAbsolutePath(pFilePath, TRUE) then
     put the defaultfolder & "/" & pFilePath into pFilePath
  else
     put "/" & pFilePath into pFilePath
  end if

  # GET FOLDER AND FILE NAME
  set the itemDel to "/"
  put item 1 to -2 of pFilePath & "/" into tFolderName
  put item -1 of pFilePath into tFileName

  put urldecode(files(tFolderName, "detailed")) into tFileList

  # GET INFO FOR FILE
  filter tFileList with tFileName & "*"
  put tFileList into tInfo

  # RETURN FILE SIZE
  return item 2 of tInfo
end rigFileSize





/*----------------------------------------------------------------------
--| FUNCTION trueFalseToDigit
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-09-2015
--| Last Mod: 04-09-2015
--| Requires: --
--|
--| Summary: Converts true, false to digits 1, 0.
--|
--| Format:  trueFalseToDigit(param1)
--|
--| Parameters: string <pEval> can be something like "tX > tY" or "tStr is line 5 of tList", etc.
--|
--| Return: integer
----------------------------------------------------------------------*/

function trueFalseToDigit pEval
  if pEval is TRUE then return 1
  return 0
end trueFalseToDigit





/*----------------------------------------------------------------------
--| COMMAND rigSort
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-07-26
--| Last Mod: 2016-07-26
--| Requires: --
--|
--| Summary: Helper for sorting data using variable sort types.
--|
--| Format: rigSort param1, param2
--|
--| Parameters: string <pData>, string <pSortType>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSort @pData pSortType
  switch pSortType
  	case "ascnum"
  		sort pData ascending numeric
  		break
  	case "descnum"
  		sort pData descending numeric
  		break
  	case "asctext"
  		sort pData ascending text
  		break
  	case "desctext"
  		sort pData descending text
  		break
  	case "ascinter"
  		sort pData ascending international
  		break
  	case "descinter"
  		sort pData descending international
  		break
  	case "ascdate"
  		sort pData ascending datetime
  		break
  	case "descdate"
  		sort pData descending datetime
  		break
  	case "ascbin"
  		sort pData ascending binary
  		break
  	case "descbin"
  		sort pData descending binary
  		break
  	default
      sort pData ascending text
  end switch
end rigSort





/*----------------------------------------------------------------------
--| FUNCTION rigConvertEncoding
--|
--| Author: rabit
--| Version:  1.0
--| Created: 05-06-2015
--| Last Mod: 05-06-2015
--| Requires: --
--|
--| Summary: Converts the character encoding of binary data.
--|
--| Format:  rigConvertEncoding(param1, param2, param3)
--|
--| Parameters: string <pData>, string <pToEncoding>, string <pFromEncoding>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigConvertEncoding pData pToEncoding pFromEncoding
  local tEncodings

  put "ASCII,ISO-8859-1,MacRoman,Native,UTF-16,UTF16,UTF-16BE,UTF-16LE,UTF-32,UTF-32BE,UTF-32LE,UTF-8,UTF8,CP1252" into tEncodings

  if (pToEncoding is not among the items of tEncodings) or (pFromEncoding is not among the items of tEncodings) then
    return FALSE
  end if

  return textEncode(textDecode(pData, pFromEncoding), pToEncoding)
end rigConvertEncoding





/*----------------------------------------------------------------------
--| FUNCTION rigDefaultCharset
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-01
--| Last Mod: 2019-01-01
--| Requires: --
--|
--| Summary: Get character set used by default in handlers that require a character set to be provided.
--|
--| Format:  rigDefaultCharset()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDefaultCharset
  local tCharset

  put rigFetchConfigItem("defaultCharset") into tCharset

  if tCharset is empty then
    put "UTF-8" into tCharset
  end if

  return tCharset
end rigDefaultCharset





/*----------------------------------------------------------------------
--| FUNCTION rigIsAbsolutePath
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-11
--| Last Mod: 2019-01-11
--| Requires: --
--|
--| Summary: Check if the provided path is absolute.
--|
--| Format:  rigIsAbsolutePath(param1[, param2])
--|
--| Parameters: string <pPath>, bool <pFile> (optional)
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigIsAbsolutePath pPath pFile
  if char 1 of pPath <> "/" then
    put "/" & pPath into pPath
  end if

  # CHECK IF PATH IS RELATIVE TO defaultFolder
  if pFile is TRUE then
    if (there is a file (the defaultFolder & pPath)) then
      return FALSE
    end if
  else
    if (there is a folder (the defaultFolder & pPath)) then
      return FALSE
    end if
  end if

  if pFile is TRUE then
    return (there is a file pPath)
  else
    return (there is a folder pPath)
  end if
end rigIsAbsolutePath





/*----------------------------------------------------------------------
--| FUNCTION rigUrlEncodeRFC
--|
--| Author: LiveCode Ltd.
--| Version:  1.1
--| Created: 2019-06-18
--| Last Mod: 2019-08-22
--| Requires: --
--|
--| Summary: URL encoding that does conform to RFC3986.
--|
--| Format:  rigUrlEncodeRFC(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigUrlEncodeRFC pStr
   if pStr is strictly a string then
      put textEncode(pStr,"UTF-8") into pStr
   end if
   put URLEncode(pStr) into pStr
   replace "+" with "%20" in pStr

   return pStr
end rigUrlEncodeRFC




/*----------------------------------------------------------------------
--| FUNCTION rigUrlDecodeRFC
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-08-01
--| Last Mod: 2019-08-01
--| Requires: --
--|
--| Summary: URL decoding that does conform to RFC3986.
--|
--| Format:  rigUrlDecodeRFC(params1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigUrlDecodeRFC pStr
    replace "%20" with "+" in pStr
    put URLDecode(pStr) into pStr
    put textDecode(pStr,"UTF-8") into pStr

    return pStr
end rigUrlDecodeRFC




function rigQ pText
    return quote & pText & quote
end rigQ








--| END OF common.livecodescript
--| Location:  ./system/revigniter/Common.livecodescript
----------------------------------------------------------------------