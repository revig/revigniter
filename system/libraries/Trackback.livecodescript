script "Trackback"

##
# revIgniter
#
# An application development framework for LiveCode
# modeled on CodeIgniter.
#
# @package		revIgniter
# @author		  rabit@revigniter.com
# @copyright  Copyright (c) 2009 - 2020, dimensionB Bitter u. Bitter GmbH
# @license	  https://revigniter.com/userGuide/license.html
# @link		    https://revigniter.com
##

## ------------------------------------------------------------------------

##
# revIgniter Trackback Sending/Receiving Library
#
#
# @package		  revIgniter
# @subpackage	Libraries
# @category		  Trackbacks
# @author			  rabit@revigniter.com
# @link				  https://revigniter.com/userGuide/libraries/trackback.html
##

## ------------------------------------------------------------------------




global gRigA

local sStackInUse, sTrackbackA -- array keys are: timeFormat, charset, dataA, convertAscii, response, errorMsgA




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-26
 --| Last Mod: --
 --| Requires: rigLogMessage, _rigSetDefaultValues, rigLoadHelper
 --|
 --| Summary:  Run security check, set initial values and load additional scripts.
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
        rigLogMessage "debug", "Trackback Library Loaded"
      end if

      # SET INITIAL VALUES
      _rigSetDefaultValues

      # AUTOMATICALLY LOAD XML Helper
      rigLoadHelper "xml"
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
  put "local" into sTrackbackA["timeFormat"] -- currently not used
  put "UTF-8" into sTrackbackA["charset"]
  put "" into sTrackbackA["dataA"]["url"]
  put "" into sTrackbackA["dataA"]["title"]
  put "" into sTrackbackA["dataA"]["excerpt"]
  put "" into sTrackbackA["dataA"]["blog_name"]
  put "" into sTrackbackA["dataA"]["charset"]
  put TRUE into sTrackbackA["convertAscii"]
  put "" into sTrackbackA["response"] -- currently not used
end _rigSetDefaultValues




/*----------------------------------------------------------------------
--| COMMAND rigRunInitialTrackbackConfig
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-05-15
--| Last Mod: 18-05-2015
--| Requires: --
--|
--| Summary: Run initial configuration procedures. Don't remove, even if it does nothing.
--|
--| Format:  rigRunInitialTrackbackConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialTrackbackConfig pConfig

end rigRunInitialTrackbackConfig





/*----------------------------------------------------------------------
--| FUNCTION rigTrackbackSend
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-05-2015
--| Last Mod: 18-05-2015
--| Requires: _rigTrackbackSetError, _rigTrackbackExtractURLs(), rigStripHTML(), rigStripSlashes()
--|            rigXmlConvert(), _rigTrackbackLimitChars(), _rigTrackbackConvertAscii(), _rigTrackbackProcess()
--|
--| Summary: Send trackback.
--|
--| Format:  rigTrackbackSend(param1)
--|
--| Parameters: array <pTBdataA>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigTrackbackSend pTBdataA
  local tKey, tPingURLA, tExerpt, tURL, tTitle, tBlogName, tCharset, tData
  local tReturn

  if  pTBdataA is not an array then
    _rigTrackbackSetError "The rigTrackbackSend() function must be passed an array."
    return FALSE
  end if

  # PRE-PROCESS THE TRACKBACK DATA
  repeat for each key tKey in pTBdataA
    if pTBdataA[tKey] is empty then
      _rigTrackbackSetError "Trackback required item missing:" && tKey
      return FALSE
    end if

    switch tKey
      case "ping_url"
        put _rigTrackbackExtractURLs(pTBdataA[tKey]) into tPingURLA
      break

      case "excerpt"
        put rigStripHTML(rigStripSlashes(pTBdataA[tKey])) into tExerpt
        put rigXmlConvert(replacetext(tExerpt,tab, "")) into tExerpt
        put _rigTrackbackLimitChars(tExerpt) into tExerpt
      break

      case "url"
        put rigStripHTML(rigStripSlashes(pTBdataA[tKey])) into tURL
        put rigXmlConvert(replacetext(tURL,tab, "")) into tURL
        put replacetext(tURL,"&#45;", "-") into tURL
      break

      default
        do "put rigStripHTML(rigStripSlashes(" & quote & pTBdataA[tKey] & quote & ")) into t" & tKey
        do "put rigXmlConvert(replacetext(t" & tKey & ",tab," & quote & quote & ")) into t" & tKey
    end switch

    # CONVERT HIGH ASCII CHARACTERS
    if sTrackbackA["convertAscii"] is TRUE then
      if tKey is "excerpt" then
          put _rigTrackbackConvertAscii(tExerpt) into tExerpt
        else if tKey is "title" then
          put _rigTrackbackConvertAscii(pTBdataA["title"]) into tTitle
        else if tKey is "blog_name" then
          put _rigTrackbackConvertAscii(pTBdataA["blog_name"]) into tBlogName
      end if

    end if
  end repeat

  # BUILD THE TRACKBACK DATA STRING
  if pTBdataA["charset"] is empty then
    put sTrackbackA["charset"] into tCharset
  else
    put pTBdataA["charset"] into tCharset
  end if

	put "url=" & URLencode(tURL) & "&title=" & URLencode(tTitle) & "&blog_name=" & URLencode(tBlogName) & "&excerpt=" & URLencode(tExerpt) & "&charset=" & URLencode(tCharset) into tData

  # SEND TRACKBACK(S)
  put TRUE into tReturn

  if the number of lines in the keys of tPingURLA > 0 then
    repeat for each key tKey in tPingURLA
      if _rigTrackbackProcess(tPingURLA[tKey], tData) is FALSE then
        put FALSE into tReturn
      end if

    end repeat
  end if

  return tReturn
end rigTrackbackSend






/*----------------------------------------------------------------------
--| FUNCTION rigTrackbackReceive
--|
--| Author: rabit
--| Version:  1.0
--| Created: 05-06-2015
--| Last Mod: 05-06-2015
--| Requires: rigVarPost(), rigTrim(), _rigTrackbackSetError, rigConvertEncoding(),
--|            rigXmlConvert(), rigStripHTML(), _rigTrackbackLimitChars()
--|
--| Summary: Receive trackback data. This function simply validates the incoming TB data.
--|            It returns FALSE on failure and TRUE on success. If the data is valid it is set
--|            to the sTrackbackA["dataA"] array so that it can be inserted into a database.
--|
--| Format:  rigTrackbackReceive()
--|
--| Parameters: --
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigTrackbackReceive
  local tTBdataItems, tCharset, tItemVal

  put "url,title,blog_name,excerpt" into tTBdataItems

  put rigVarPost("charset", TRUE) into tCharset
  if tCharset is FALSE then
    # NO CHARSET PROVIDED. SO, WE ASSUME IT IS UTF-8.
    put "UTF-8" into sTrackbackA["dataA"]["charset"]
  else
    put toUpper(rigTrim(tCharset)) into sTrackbackA["dataA"]["charset"]
  end if

  repeat for each item tItem in tTBdataItems
    put rigVarPost(tItem, TRUE) into tItemVal

    if tItemVal is FALSE then
	    _rigTrackbackSetError "The following required POST variable is missing:" && tItem & "."
		  return FALSE
    end if

    if tItem <> "url" then
      if sTrackbackA["dataA"]["charset"] <> sTrackbackA["charset"] then
        get rigConvertEncoding(tItemVal, sTrackbackA["charset"], sTrackbackA["dataA"]["charset"])
        if it <> FALSE then
          put it into tItemVal
        end if

      end if

      put rigXmlConvert(rigStripHTML(tItemVal)) into tItemVal

    else
      put rigStripHTML(tItemVal) into tItemVal
    end if

    if tItem is "excerpt" then
      put _rigTrackbackLimitChars(tItemVal) into tItemVal
    end if

    put tItemVal into sTrackbackA["dataA"][tItem]

  end repeat

  return sTrackbackA["dataA"]
end rigTrackbackReceive






/*----------------------------------------------------------------------
--| COMMAND _rigTrackbackSetError
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-05-2015
--| Last Mod: 18-05-2015
--| Requires: rigLogMessage
--|
--| Summary: Set error message.
--|
--| Format:  _rigTrackbackSetError param1
--|
--| Parameters: string <pMsg>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigTrackbackSetError pMsg
  rigLogMessage "error", pMsg

  if sTrackbackA["errorMsgA"] is an array then
    put pMsg into sTrackbackA["errorMsgA"][(the number of lines in the keys of sTrackbackA["errorMsgA"]) + 1]
  else
    put pMsg into sTrackbackA["errorMsgA"][1]
  end if
end _rigTrackbackSetError






/*----------------------------------------------------------------------
--| FUNCTION rigTrackbackDisplayErrors
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-06-2015
--| Last Mod: 07-06-2015
--| Requires: --
--|
--| Summary: Show error messages.
--|
--| Format:  rigTrackbackDisplayErrors([param1][, param2])
--|
--| Parameters: string <pOpenTag> (optional), string <pCloseTag> (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigTrackbackDisplayErrors pOpenTag pCloseTag
  local tStr, tErrorsKeysList

  if sTrackbackA["errorMsgA"] is an array then
    if pOpenTag is empty then
      put "<p>" into pOpenTag
    end if
    if pCloseTag is empty then
      put "</p>" into pCloseTag
    end if

    put empty into tStr

    put the keys of sTrackbackA["errorMsgA"] into tErrorsKeysList
    sort lines of tErrorsKeysList numeric

    repeat for each line thisLine in tErrorsKeysList
      put pOpenTag & sTrackbackA["errorMsgA"][thisLine] & pCloseTag after tStr
    end repeat

    return tStr
  end if

  return FALSE
end rigTrackbackDisplayErrors







/*----------------------------------------------------------------------
--| FUNCTION _rigTrackbackExtractURLs
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-05-2015
--| Last Mod: 18-05-2015
--| Requires: _rigTrackbackValidateURL
--|
--| Summary: Extract trackback URLs. This function lets multiple trackbacks be sent.
--|            It takes a string of URLs (separated by comma or space) and puts
--|            each URL into an array
--|
--| Format:  _rigTrackbackExtractURLs(param1)
--|
--| Parameters: string <pURLs>
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigTrackbackExtractURLs pURLs
  local tURLs, tURLsA, tKey, tItem

  # REMOVE THE PESKY WHITE SPACE AND REPLACE WITH A COMMA
  put replacetext( pURLs,"[ ]+", ",") into tURLs

  # IF THEY USE COMMAS GET RID OF THE DOUBLES
  put replacetext(tURLs,",,", ",") into tURLs

  # REMOVE ANY COMMA THAT MIGHT BE AT THE END
  if char -1 of tURLs is "," then
    put char 1 to -2 of tURLs into tURLs
  end if

  put empty into tURLsA
  put 0 into tKey
  # REMOVES DUPLICATES
  repeat for each item tItem in tURLs
    if tItem is not among the items of tURLsA then
      # SIMPLE VALIDATION
      _rigTrackbackValidateURL tItem

      put tItem & comma after tURLsA
    end if
  end repeat

  delete char -1 of tURLsA

  split tURLsA by comma

  return tURLsA
end _rigTrackbackExtractURLs







/*----------------------------------------------------------------------
--| COMMAND _rigTrackbackValidateURL
--|
--| Author: rabit
--| Version:  1.0
--| Created: 20-05-2015
--| Last Mod: 20-05-2015
--| Requires: rigTrim()
--|
--| Summary: Simply adds "http://" if missing.
--|
--| Format:  _rigTrackbackValidateURL param1
--|
--| Parameters: string <pURL>
--|
--| Return: string
----------------------------------------------------------------------*/

private command _rigTrackbackValidateURL @pURL
  put rigTrim(pURL) into pURL

  if char 1 to 4 of pURL <> "http" then
    put "http://" & pURL into pURL
  end if
end _rigTrackbackValidateURL







/*----------------------------------------------------------------------
--| FUNCTION _rigTrackbackLimitChars
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-05-2015
--| Last Mod: 22-05-2015
--| Requires: --
--|
--| Summary: Character limiter. Limits the string based on the character count.
--|            Will preserve complete words.
--|
--| Format:  _rigTrackbackLimitChars(param1[, param2][, param3])
--|
--| Parameters: string <pStr>, integer <pN> (optional), string <pEndChar> (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigTrackbackLimitChars pStr pN pEndChar
  local tRegExWS, tNumWords

  if (pN is empty) or (pN is not a number) then
    put 500 into pN
  end if

  # REMOVE NEWLINE CHARS
  if numToCodepoint(13) is in pStr then
    replace CRLF with " " in pStr
    replace numToCodepoint(13) with " " in pStr
  end if
  replace numToCodepoint(10) with " " in pStr

  # REPLACE MULTIPLE SPACE CHARS
  put replacetext(pStr,"[ ]+", " ") into pStr

  # TRIM WHITESPACE AT THE START AND AT THE END
  put "(^\s+)|(\s+$)" into tRegExWS
  put replacetext(pStr,tRegExWS,empty) into pStr

  # NOW CHECK THE REMAINING NUMBER OF CHARS
  if the number of chars of pStr <= pN then
    return pStr
  end if

  if pEndChar is empty then
    put "&#8230;" into pEndChar
  end if

  # TRUNCATE THE STRING
  put char 1 to pN of pStr into pStr

  # CHECK IF LAST WORD IS NOT TRUNCATED
  if char (pN + 1) of pStr is " " then
    return pStr & pEndChar
    # NEEDS INTERNATIONALIZATION
  else if char (pN + 1) of pStr is among the items of ".,!,?" then
    return pStr & char (pN + 1) of pStr
  end if

  # REMOVE TRUNCATED LAST WORD
  put (the number of words of pStr) - 1 into tNumWords
  put word 1 to tNumWords of pStr into pStr

  return pStr & pEndChar
end _rigTrackbackLimitChars






/*----------------------------------------------------------------------
--| FUNCTION _rigTrackbackConvertAscii
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-05-2015
--| Last Mod: 22-05-2015
--| Requires: --
--|
--| Summary: High ASCII to Entities. Converts Hight ascii text and MS Word
--|            special chars to character entities
--|
--| Format:  _rigTrackbackConvertAscii(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigTrackbackConvertAscii pStr
  local tCount, tOut, tTempA, tAscii

  put 1 into tCount
  put "" into tOut
  put empty into tTempA

  repeat with i = 1 to the number of chars in pStr
    put codepointToNum(char i of pStr) into tAscii

    if tAscii < 128 then
      put char i of pStr after tOut
    else
      put "&#" & tAscii & ";" after tOut
    end if
  end repeat

  return tOut
end _rigTrackbackConvertAscii






/*----------------------------------------------------------------------
--| FUNCTION _rigTrackbackProcess
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2015-05-23
--| Last Mod: 2017-06-27
--| Requires: _rigParseURL(), _rigTrackbackSetError, _rigTrackbackGetID(), rigTrim(), _rigTrackbackSetError
--|
--| Summary: Process trackback. Opens a socket connection and passes the data
--|            to the server.  Returns TRUE on success, FALSE on failure.
--|
--| Format:  _rigTrackbackProcess(param1, param2)
--|
--| Parameters: string <pURL>, string <pData>
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigTrackbackProcess pURL pData
  local tTargetA, tPPath, tID, tPath, tDataLength, tResponse, tEndOfResponse
  local tMessage, theMessage

  put _rigParseURL(pURL) into tTargetA

  # OPEN THE SOCKET
  open socket tTargetA["host"] & ":80"

  if the result is not empty then
		_rigTrackbackSetError "Invalid connection:" && pURL & "." && the result
		return FALSE
  end if

  # BUILD THE PATH
  if tTargetA["path"] <> empty then
    put tTargetA["path"] into tPPath
  else
    put pURL into tPPath
  end if

  if tTargetA["query"] <> empty then
    put tPPath & "?" & tTargetA["query"] into tPath
  else
    put tPPath into tPath
  end if

  # ADD THE TRACKBACK ID TO THE DATA STRING
  put _rigTrackbackGetID(pURL) into tID

  if tID <> FALSE then
    put "tb_id=" & tID & "&" & pData into pData
  end if

  # TRANSFER THE DATA
  put the length of pData into tDataLength
  write "POST" && tPath && "HTTP/1.0" & CRLF to socket tTargetA["host"] & ":80"
  write "Host:" && tTargetA["host"] & CRLF to socket tTargetA["host"] & ":80"
  write "Content-type: application/x-www-form-urlencoded" & CRLF to socket tTargetA["host"] & ":80"
  write "Content-length:" && tDataLength & CRLF to socket tTargetA["host"] & ":80"
  write "Connection: close" & CRLF & CRLF to socket tTargetA["host"] & ":80"
  write pData to socket tTargetA["host"] & ":80"

  put empty into tResponse
  put FALSE into tEndOfResponse
  repeat until tEndOfResponse is TRUE
    read from socket tTargetA["host"] & ":80" for 128
    if it <> empty then
      put it after tResponse
    else
      put TRUE into tEndOfResponse
    end if
  end repeat

  close socket tTargetA["host"] & ":80"

  if "<error>0</error>" is not in tResponse then
    put "An unknown error was encountered" into tMessage

		put empty into theMessage -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
    if matchText(tResponse, "(?is)<message>(.*?)<\/message>", theMessage) then
      put rigTrim(theMessage) into tMessage
    end if

    _rigTrackbackSetError tMessage
    return FALSE
  end if


  return TRUE
end _rigTrackbackProcess






/*----------------------------------------------------------------------
--| FUNCTION _rigTrackbackGetID
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-06-2015
--| Last Mod: 06-06-2015
--| Requires: rigRTrim()
--|
--| Summary: Find the Trackback URL's ID.
--|
--| Format:  _rigTrackbackGetID(param1)
--|
--| Parameters: string <pURL>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function _rigTrackbackGetID pURL
  local tTBid, tTBend

  put empty into tTBid

  if "?" is in pURL then
    set the itemDel to "/"
    put item -1 of pURL into tTBend

    if tTBend is not a number then
      put item -2 of pURL into tTBend
    end if

    set the itemDel to "="
    put item -1 of tTBend into tTBid

  else
    put rigRTrim(pURL, "/") into pURL

    set the itemDel to "/"
    put item -1 of pURL into tTBid

    if tTBid is not a number then
      put item -2 of pURL into tTBid
    end if
  end if

  if not matchText(tTBid, "^([0-9]+)$") then
    return FALSE
  end if

  return tTBid
end _rigTrackbackGetID





/*----------------------------------------------------------------------
--| COMMAND rigTrackbackSendError
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-06-2015
--| Last Mod: 06-06-2015
--| Requires: --
--|
--| Summary: Send trackback error message. Allows custom errors to be set. By default it
--|            sends the "incomplete information" error, as that's the most common one.
--|
--| Format:  rigTrackbackSendError [param1]
--|
--| Parameters: string <pMessage> (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigTrackbackSendError pMessage
  if pMessage is empty then
    put "Incomplete Information" into pMessage
  end if

  put "<?xml version=" & quote & "1.0" & quote && "encoding=" & quote & "utf-8" & quote & "?>" & LF & "<response>" & LF & "<error>1</error>" & LF & "<message>" & pMessage & "</message>" & LF & "</response>"
  exit to top
end rigTrackbackSendError





/*----------------------------------------------------------------------
--| COMMAND rigTrackbackSendSuccess
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-06-2015
--| Last Mod: 06-06-2015
--| Requires: --
--|
--| Summary: Send trackback success message.
--|
--| Format:  rigTrackbackSendSuccess
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigTrackbackSendSuccess
  put "<?xml version=" & quote & "1.0" & quote && "encoding=" & quote & "utf-8" & quote & "?>" & LF & "<response>" & LF & "<error>0</error>" & LF & "</response>"
  exit to top
end rigTrackbackSendSuccess






/*----------------------------------------------------------------------
--| FUNCTION rigTrackbackData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-06-2015
--| Last Mod: 07-06-2015
--| Requires: --
--|
--| Summary: Fetch a particular item.
--|
--| Format:  rigTrackbackData(param1)
--|
--| Parameters: string <pItem>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigTrackbackData pItem
  return sTrackbackA["dataA"][pItem]
end rigTrackbackData







/*----------------------------------------------------------------------
--| FUNCTION rigTrackbackHasLink
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-06-2015
--| Last Mod: 07-06-2015
--| Requires: --
--|
--| Summary: Check if trackback page has a link to the corresponding blog entry.
--|
--| Format:  rigTrackbackHasLink(param1, param2)
--|
--| Parameters: string <pTrackbackURL>, string <pURL> your weblog entry URL
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigTrackbackHasLink pTrackbackURL pURL
  local tWWWoffset, tLinkVariant, tProtocolOffset, tPageData

  # ALLOW URLs OMITTING "www"
  put offset("www", pURL) into tWWWoffset
  if it is not empty then
    put (char 1 to (tWWWoffset - 1) of pURL) & (char (tWWWoffset + 4) to -1 of pURL) into tLinkVariant
  else if "localhost" is not in pURL then
    put offset("://", pURL) into tProtocolOffset
    put (char 1 to tProtocolOffset of pURL) & "//www." & (char (tProtocolOffset + 3) to - 1 of pURL) into tLinkVariant

  else
    put pURL into tLinkVariant
  end if

  # GET TRACKBACK PAGE AND CHECK IF THERE IS A LINK TO YOUR WEBLOG ENTRY
  put URL pTrackbackURL into tPageData

  if ("href=" & quote & pURL & quote is in tPageData) or ("href=" & quote & tLinkVariant & quote is in tPageData) then
    return TRUE
  end if

  return FALSE
end rigTrackbackHasLink








on socketError pID, pError
  _rigTrackbackSetError "Socket error:" && pID & "." && pError
  close socket pID
end socketError





/*----------------------------------------------------------------------
--| FUNCTION rigTrackbackGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Get trackback array variable values.
--|
--| Format: rigTrackbackGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigTrackbackGet pWhat
  if pWhat is among the keys of sTrackbackA then
    return sTrackbackA[pWhat]
  end if

  return empty
end rigTrackbackGet




/*----------------------------------------------------------------------
--| COMMAND rigTrackbackSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Setter for trackback variables.
--|
--| Format: rigTrackbackSet param1, param2
--|
--| Parameters: string <pKey>, sTrackbackA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigTrackbackSet pKey pVal
  if pKey is among the keys of sTrackbackA then
    put pVal into sTrackbackA[pKey]
  end if
end rigTrackbackSet








--| END OF Trackback.livecodescript
--| Location:  ./system/libraries/Trackback.livecodescript
----------------------------------------------------------------------