script "urlHelper"

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
# revIgniter URL Helpers
#
# @package		revIgniter
# @subpackage	Helpers
# @category	  Helpers
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/helpers/urlHelper.html
##

## ------------------------------------------------------------------------




global gRigA

local sStackInUse




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
--| FUNCTION rigASiteURL
--|
--| Author: rabit
--| Version:  1.0
--| Created: 05-10-09
--| Last Mod: 05-10-09
--| Requires: rigSiteURL()
--|
--| Summary: Create a local URL based on your basepath. Segments can be passed via the
--|            first parameter either as a string or an array.
--|
--| Format: rigASiteURL(param1)
--|
--| Parameters: string <pURI>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigASiteURL pURI
	return rigSiteURL(pURI)
end rigASiteURL







/*----------------------------------------------------------------------
--| FUNCTION rigBaseURL
--|
--| Author: rabit
--| Version:  1.0
--| Created: 05-10-09
--| Last Mod: 05-10-09
--| Requires: rigFetchConfigItem()
--|
--| Summary: Returns the "base_url" item from your config file.
--|
--| Format: rigBaseURL()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigBaseURL
	return rigConfigItem("baseUrl")
end rigBaseURL








/*----------------------------------------------------------------------
--| FUNCTION rigCurrentURL
--|
--| Author: rabit
--| Version:  1.0
--| Created: 05-10-09
--| Last Mod: 05-10-09
--| Requires: rigUriString()
--|
--| Summary: Returns the full URL (including segments) of the page where this
--|            function is placed.
--|
--| Format: rigCurrentURL()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigCurrentURL
  local tUriStr

	put rigUriString() into tUriStr

	return rigSiteURL(tUriStr)
end rigCurrentURL







/*----------------------------------------------------------------------
--| FUNCTION rigCurrentURIstring
--|
--| Author: rabit
--| Version:  1.0
--| Created: 05-10-09
--| Last Mod: 05-10-09
--| Requires: rigUriString()
--|
--| Summary: Returns the URI segments.
--|
--| Format: rigCurrentURIstring()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigCurrentURIstring
	return rigUriString()
end rigCurrentURIstring







/*----------------------------------------------------------------------
--| FUNCTION rigIndexPage
--|
--| Author: rabit
--| Version:  1.0
--| Created: 05-10-09
--| Last Mod: 05-10-09
--| Requires: rigFetchConfigItem()
--|
--| Summary: Returns the "indexPage" item from your config file.
--|
--| Format: rigIndexPage()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigIndexPage
	return rigConfigItem("indexPage")
end rigIndexPage







/*----------------------------------------------------------------------
--| FUNCTION rigAnchor
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-08-09
--| Last Mod: 04-08-09
--| Requires: rigSiteURL(), _rigParseAttributes()
--|
--| Summary: Creates an anchor based on the local URL.
--|
--| Format: rigAnchor(param1, param2, param3)
--|
--| Parameters: mixed <pURI>, string <pTitle> the link title, mixed <pAttributes> any attributes
--|
--| Return: string
----------------------------------------------------------------------*/

function rigAnchor pURI pTitle pAttributes
  local tRegEx, tSiteURL, tTitle, tAttributes

	if pURI is not an array then
		put "^\w+://" into tRegEx

    		get matchtext(pURI,tRegEx)

		if it is TRUE then
			put pURI into tSiteURL
		else
			put rigSiteURL(pURI) into tSiteURL
		end if
	else
		put rigSiteURL(pURI) into tSiteURL
	end if

	if pTitle is empty then
		put tSiteURL into tTitle
	else
		put pTitle into tTitle
	end if

	if (pAttributes is an array) or ((pAttributes is not an array) and (pAttributes is not empty)) then
		put _rigParseAttributes(pAttributes) into tAttributes
	else
		put empty into tAttributes
	end if

	return "<a href=" & quote & tSiteURL & quote & tAttributes & ">" & tTitle & "</a>"
end rigAnchor








/*----------------------------------------------------------------------
--| FUNCTION rigAnchorPopUp
--|
--| Author: rabit
--| Version:  1.2
--| Created: 05-10-09
--| Last Mod: 19-06-16
--| Requires: rigSiteURL(), _rigParseAttributes()
--|
--| Summary: Creates an anchor based on the local URL. The link
--|            opens a new window based on the attributes specified.
--|
--| Format: rigAnchorPopUp(param1, param2, param3)
--|
--| Parameters: mixed <pURI>, string <pTitle> the link title, mixed <pAttributes> any attributes
--|
--| Return: string
----------------------------------------------------------------------*/

function rigAnchorPopUp pURI pTitle pAttributes
  local tAttributes, tRegEx, tSiteURL, tTitle, tAtts, tKey

	if pAttributes is not an array then
		put FALSE into tAttributes
	else
		put pAttributes into tAttributes
	end if

	put "^\w+://" into tRegEx
    	get matchtext(pURI,tRegEx)

	if it is TRUE then
		put pURI into tSiteURL
	else
		put rigSiteURL(pURI) into tSiteURL
	end if

	if pTitle is empty then
		put tSiteURL into tTitle
	else
		put pTitle into tTitle
	end if

	if tAttributes is FALSE then
		# USE noopener AND noreferrer AND RESET THE opener PROPERTY TO ADDRESS SECURITY ISSUES OF _blank TARGETS
		return "<a href=" & quote & tSiteURL & quote && "rel=" & quote & "noopener noreferrer" & quote &&  "target=" & quote & "_blank" & quote && "onclick=" & quote & "var nW = window.open(); nW.opener = null; nW.location = href; return false;" & quote & ">" & tTitle & "</a>"
	end if

	if tAttributes is not an array then
		put empty into tAttributes
	end if

	put 800 into tAtts["width"]
	put 600 into tAtts["height"]
	put "yes" into tAtts["scrollbars"]
	put "yes" into tAtts["status"]
	put "yes" into tAtts["resizable"]
	put 0 into tAtts["screenx"]
	put 0 into tAtts["screeny"]

	repeat for each key tKey in tAtts
		if tAttributes[tKey] is not empty then
			put tAttributes[tKey] into tAtts[tKey]
			delete variable tAttributes[tKey]
		end if
	end repeat

	if tAttributes is an array then
		put _rigParseAttributes(tAttributes) into tAttributes
	end if

	put _rigParseAttributes(tAtts, TRUE) into tAtts

	# RESET THE opener PROPERTY TO ADDRESS SECURITY ISSUES OF _blank TARGETS
	return "<a href=" & quote & tSiteURL & quote && "onclick=" & quote & "var nW = window.open('" & tSiteURL & "', '_blank', '" & tAtts & "'); nW.opener = null; return false;" & quote & ">" & tTitle & "</a>"
end rigAnchorPopUp







/*----------------------------------------------------------------------
--| FUNCTION rigMailToLink
--|
--| Author: rabit
--| Version:  1.0
--| Created: 05-10-09
--| Last Mod: 05-10-09
--| Requires: _rigParseAttributes()
--|
--| Summary: rigMailTo link
--|
--| Format: rigMailToLink(param1, param2, param3)
--|
--| Parameters: string <pEmail>, string <pTitle> the link title, mixed <pAttributes> any attributes
--|
--| Return: string
----------------------------------------------------------------------*/

function rigMailToLink pEmail pTitle pAttributes
  local tTitle, tAttributes

	if pTitle is empty then
		put pEmail into tTitle
	else
		put pTitle into tTitle
	end if

	put _rigParseAttributes(pAttributes) into tAttributes

	return "<a href=" & quote & "mailto:" & pEmail & quote & tAttributes & ">" & tTitle & "</a>"
end rigMailToLink









/*----------------------------------------------------------------------
--| FUNCTION rigSafeMailToLink
--|
--| Author: rabit
--| Version:  1.2
--| Created: 05-10-09
--| Last Mod: 27-04-15
--| Requires: rigArrayReverse()
--|
--| Summary: Create a spam-protected mailTo link written in Javascript.
--|
--| Format: rigSafeMailToLink(param1, param2, param3)
--|
--| Parameters: string <pEmail>, string <pTitle> the link title, mixed <pAttributes> any attributes
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSafeMailToLink pEmail pTitle pAttributes
  local tTitle, tStr, tCharsNum, tChar, tX, tKey, tVal, tTemp
  local tTempCounter, tOrdinal, tCount, tNumber, tItemDelimiter
  local tOutput, tNum, tV

  if pTitle is empty then
    put pEmail into tTitle
  else
    put pTitle into tTitle
  end if

  put "<a href=" & quote & "mailto:" into tStr
  repeat with i = 1 to 16
    put char i of tStr into tX[i]
  end repeat

  put 16 into tCharsNum
  repeat with i = 1 to (the number of chars in pEmail)
    add 1 to tCharsNum
    put char i of pEmail into tChar
    put "|" & codepointToNum(tChar) into tX[tCharsNum]
  end repeat

  add 1 to tCharsNum
  put quote into tX[tCharsNum]

  if pAttributes is not empty then
    if pAttributes is an array then
      repeat for each key tKey in pAttributes
        put pAttributes[tKey] into tVal

        add 1 to tCharsNum
        put " " & tKey & "=" & quote into tX[tCharsNum]

        repeat with i = 1 to (the number of chars in tVal)
          add 1 to tCharsNum
          put char i of tVal into tChar
          put "|" & codepointToNum(tChar) into tX[tCharsNum]
        end repeat

        add 1 to tCharsNum
        put quote into tX[tCharsNum]
      end repeat

    else

      repeat with i = 1 to (the number of chars in pAttributes)
        add 1 to tCharsNum
        put char i of pAttributes into tChar
        put "|" & codepointToNum(tChar) into tX[tCharsNum]
      end repeat
    end if
  end if

  add 1 to tCharsNum
  put ">" into tX[tCharsNum]

  put empty into tTemp
  put 0 into tTempCounter
  repeat with i = 1 to (the number of chars in tTitle)
    add 1 to tCharsNum
    put char i of tTitle into tChar
    put codepointToNum(tChar) into tOrdinal


    if tOrdinal < 128 then
      put "|" & tOrdinal into tX[tCharsNum]
    else
      if tTemp is not an array then
        if tOrdinal < 224 then
          put 2 into tCount
        else
          put 3 into tCount
        end if

        add 1 to tTempCounter
        put tOrdinal into tTemp[tTempCounter]

        if the number of lines in the keys of tTemp is tCount then
          if tCount = 3 then
            put ((tTemp[1] mod 16) * 4096) + ((tTemp[2] mod 64) * 64) + (tTemp[3] mod 64) into tNumber
          else
            put ((tTemp[1] mod 32) * 64) + (tTemp[2] mod 64) into tNumber
          end if

          add 1 to tCharsNum
          put "|" & tNumber into tX[tCharsNum]
          put 1 into tCount
          put empty into tTemp
        end if
      end if
    end if
  end repeat

  add 1 to tCharsNum
  put "<" into tX[tCharsNum]

  add 1 to tCharsNum
  put "/" into tX[tCharsNum]

  add 1 to tCharsNum
  put "a" into tX[tCharsNum]

  add 1 to tCharsNum
  put ">" into tX[tCharsNum]

  # REVERSE ARRAY
  put numToCodepoint(1) into tItemDelimiter
  put rigArrayReverse(tX, tItemDelimiter) into tX

  # WRITE HTML CODE
  put "<script type=" & quote & "text/javascript" & quote & ">" & return & \
  "var l=new Array();" & return into tOutput

  put 0 into tNum
  repeat with i = 1 to tCharsNum
    put tX[i] into tV

    put "l[" & tNum & "]='" & tV & "';" after tOutput
    add 1 to tNum
  end repeat

  put return & "for (var i = l.length-1; i >= 0; i=i-1)" & return & \
  "{" & return & \
  "if (l[i].substring(0, 1) == '|') document.write(" & quote & "&#" & quote & "+unescape(l[i].substring(1))+" & quote & ";" & quote & ");" & return & \
  "else document.write(unescape(l[i]));" & return & \
    "}" & return & \
    "</script>" after tOutput

    return tOutput
  end rigSafeMailToLink









/*----------------------------------------------------------------------
--| FUNCTION rigAutoLink
--|
--| Author: rabit
--| Version:  1.2
--| Created: 05-10-09
--| Last Mod: 19-06-16
--| Requires: rigSafeMailToLink()
--|
--| Summary: Automatically links URL and Email addresses.
--|            Note: There's a bit of extra code here to deal with
--|            URLs or emails that end in a period. We'll strip these
--|            off and add them after the link.
--|
--| Format: rigAutoLink(param1, param2, param3)
--|
--| Parameters: string <pStr>, string <pType> the type: email, url, or both, bool <pPopUp> whether to create pop-up links
--|
--| Return: string
----------------------------------------------------------------------*/

function rigAutoLink pStr pType pPopUp
  local tStr, tType, tPopUp, tRegEx, tMatchFound, tMS1, tME1
  local tMS2, tME2, tMS3, tME3, tMS4, tME4, tMS5, tME5, tMS6, tME6
  local tLink, tReplacement, tEmail

  put pStr into tStr
  if pType is empty then
    put "both" into tType
  else
    put pType into tType
  end if

  if pPopUp is TRUE then
    # USE noopener AND noreferrer TO ADDRESS SECURITY ISSUES OF _blank TARGETS
    put " rel=" & quote & "noopener noreferrer" & quote && "target=" & quote & "_blank" & quote into tPopUp
  else
    put "" into tPopUp
  end if

  if tType is not "email" then
    put "(?i)(^|\s|\()((http(s?)://)|(www\.))(\w+[^\s\)\<]+)" into tRegEx

    put TRUE into tMatchFound

    repeat until tMatchFound is FALSE

      get matchchunk(tStr,tRegEx,tMS1,tME1,tMS2,tME2,tMS3,tME3,tMS4,tME4,tMS5,tME5,tMS6,tME6)

      if it is TRUE then
        put char tMS2 to tME6 of tStr into tLink

        if char -1 of tLink is "." then
          delete char -1 of tLink
        end if

        put tLink into tReplacement

        if (char 1 of tLink is "w") or (char 1 of tLink is "W") then
          put "<a href=" & quote & "http://" before tReplacement
        else
          put "<a href=" & quote before tReplacement
        end if

        put quote & tPopUp & ">" & tLink & "</a>" after tReplacement

        replace tLink with tReplacement in tStr

      else
        put FALSE into tMatchFound
      end if
    end repeat
  end if

  if tType is not "url" then
    put "(?i)([a-zA-Z0-9_\.\-\+]+)@([a-zA-Z0-9\-]+)\.([a-zA-Z0-9\-\.]*)" into tRegEx

    put TRUE into tMatchFound

    repeat until tMatchFound is FALSE

      get matchchunk(tStr,tRegEx,tMS1,tME1,tMS2,tME2,tMS3,tME3)

      if it is TRUE then
        put char tMS1 to tME3 of tStr into tEmail

        if char -1 of tEmail is "." then
          delete char -1 of tEmail
        end if

        put rigSafeMailToLink(tEmail) into tReplacement

        replace tEmail with tReplacement in tStr

      else
        put FALSE into tMatchFound
      end if
    end repeat
  end if

  return tStr
end rigAutoLink







/*----------------------------------------------------------------------
--| FUNCTION rigUrlPrep
--|
--| Author: rabit
--| Version:  1.1
--| Created: 05-10-09
--| Last Mod: 29-06-15
--| Requires: --
--|
--| Summary: Simply adds the http:// or https:// part if missing.
--|
--| Format: rigUrlPrep(param1[, param2])
--|
--| Parameters: string <pStr> the URL, bool <pSecure> use https (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigUrlPrep pStr pSecure
  local tStr

	if (pStr is "http://") or (pStr is "https://") or (pStr is empty) then
		return ""
	end if

	if (char 1 to 7 of pStr is not "http://") and (char 1 to 8 of pStr is not "https://") then
		if pSecure then
			put "https://" & pStr into tStr
		else
			put "http://" & pStr into tStr
		end if
	else
		return pStr
	end if

	return tStr
end rigUrlPrep







/*----------------------------------------------------------------------
--| FUNCTION rigUrlTitle
--|
--| Author: rabit
--| Version:  1.2
--| Created: 05-10-09
--| Last Mod: 03-08-15
--| Requires: rigStripHTML(), rigPregReplace(), rigStripSlashes()
--|
--| Summary: Takes a "title" string as input and creates a
--|             human-friendly URL string with either a dash
--|             or an underscore as the word separator.
--|
--| Format: rigUrlTitle(param1, param2, param3)
--|
--| Parameters: string <pStr>, char <pSeparator> the separator: dash, underscore, -, or _, bool <pLowercase>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigUrlTitle pStr pSeparator pLowercase
  local tSeparator, tReplace, tLowercase, tTransA, tTemp, tStr
  local tTransAitemNum, tCounter, tTransItemA, tKey, tVal, tRegEx

   if pSeparator is among the items of "dash,underscore,-,_" then
      put pSeparator into tSeparator
   end if

   if tSeparator is "dash" then
      put "-" into tSeparator
   end if
   if tSeparator is "underscore" then
      put "_" into tSeparator
   end if

   if tSeparator is empty then
      put "-" into tReplace
   else
      put tSeparator into tReplace
   end if

   if pLowercase is empty then
      put FALSE into tLowercase
   else
      put pLowercase into tLowercase
   end if

   # BUILD REGULAR EXPRESSIONS
   put "" into tTransA[1]["(&\#\d+?;)"]
   put "" into tTransA[2]["(&\S+?;)"]
   put tReplace into tTransA[3]["(\s+)"]
   put "" into tTransA[4]["([^a-z0-9\-\._])"]
   put "(" & tReplace & "+)" into tTemp
   put tReplace into tTransA[5][tTemp]
   put "(" & tReplace & "$)" into tTemp
   put tReplace into tTransA[6][tTemp]
   put "(^" & tReplace & ")" into tTemp
   put tReplace into tTransA[7][tTemp]
   put "" into tTransA[8]["(\.+$)"]

   # STRIP HTML TAGS
   put rigStripHTML(pStr) into tStr

   put the number of lines in the keys of tTransA into tTransAitemNum

   put 0 into tCounter

   # REPLACE SPACES AND OTHER CHARACTERS
   repeat forever
      add 1 to tCounter

      put tTransA[tCounter] into tTransItemA
      put line 1 in the keys of tTransItemA into tKey

      put tTransItemA[tKey] into tVal

      put "(?i)" & tKey into tRegEx
      put rigPregReplace(tStr, tRegEx, "", tVal) into tStr
      if tCounter is tTransAitemNum then
         exit repeat
      end if
   end repeat

   if tLowercase is TRUE then
      put toLower(tStr) into tStr
   end if

   put rigStripSlashes(tStr) into tStr

   return rigTrim(tStr)
end rigUrlTitle








/*----------------------------------------------------------------------
--| COMMAND rigRedirect
--|
--| Author: rabit
--| Version:  1.0
--| Created: 03-10-09
--| Last Mod: 03-10-09
--| Requires: rigSiteURL()
--|
--| Summary: Header redirect in two flavors.
--|            For very fine grained control over headers, you could use the Output
--|            library's rigSetHeader command.
--|
--| Format: rigRedirect param1, param2, param3
--|
--| Parameters: string <pUri>, string <pMethod> the method: location or redirect, integer <pHttpResponseCode>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRedirect pUri pMethod pHttpResponseCode
  local tMethod, tHttpResponseCode, tUri, tRegEx

	if pMethod is empty then
		put "location" into tMethod
	else
		put pMethod into tMethod
	end if

	if pHttpResponseCode is empty then
		put 302 into tHttpResponseCode
	else
		put pHttpResponseCode into tHttpResponseCode
	end if

	put pUri into tUri

	put "(?i)^https?://" into tRegEx
	if matchtext(tUri,tRegEx) is FALSE then
		put rigSiteURL(tUri) into tUri
	end if

	 switch pMethod
        	case "refresh"
             		put header "Refresh:0;url=" & tUri
		break
        	default
			put header "Status:" && tHttpResponseCode
			put header "Location:" && tUri
    	end switch

	-- exit to top
end rigRedirect







/*----------------------------------------------------------------------
--| FUNCTION _rigParseAttributes
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-08-09
--| Last Mod: 04-08-09
--| Requires: --
--|
--| Summary: Parse out the attributes.
--|
--| Format: _rigParseAttributes(param1, param2)
--|
--| Parameters: array <pAttributes>, bool <pJavascript>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigParseAttributes pAttributes pJavascript
  local tAttributes, tJavascript, tAtt, tKey, tVal

	put pAttributes into tAttributes

	if pJavascript is empty then
		put FALSE into tJavascript
	else
		put pJavascript into tJavascript
	end if

	if tAttributes is not an array then
		if tAttributes is empty then
			return ""
		else
			return " " & tAttributes
		end if
	end if

	put empty into tAtt

	repeat for each key tKey in tAttributes
		put tAttributes[tKey] into tVal

		if tJavascript is TRUE then
			put tKey & "=" & tVal & "," after tAtt
		else
			put " " & tKey & "=" & quote & tVal & quote after tAtt
		end if
	end repeat

	if (tJavascript is TRUE) and (tAtt is not empty) then
		put char 1 to -2 of tAtt into tAtt
	end if

	return tAtt
end _rigParseAttributes






/*----------------------------------------------------------------------
--| FUNCTION rigURLstripSpace
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2015-05-11
--| Last Mod: 2017-06-27
--| Requires: --
--|
--| Summary: Remove or replace whitespace in URLs.
--|
--| Format:  rigURLstripSpace(param1[, param2])
--|
--| Parameters: string <pURL>, string <pSeparator> (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigURLstripSpace pURL pSeparator
  local tRegExWS, tCleanURL, tTopLevel, tTopLevelOffset, tDomain, tSegments

  if pURL <> empty then
    # TRIM WHITESPACE AT THE START AND AT THE END
    put "(^\s+)|(\s+$)" into tRegExWS
    put replacetext(pURL,tRegExWS,empty) into tCleanURL

    # GET DOMAIN, DON'T APPLY SEPARATORS TO DOMAIN
	  put empty into tTopLevel -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
    get matchText(tCleanURL,"(\.[a-zA-Z\s]*/)",tTopLevel)
    put (offset(tTopLevel, tCleanURL)) + (the number of chars of tTopLevel) into tTopLevelOffset
    put char 1 to tTopLevelOffset of tCleanURL into tDomain
    put char tTopLevelOffset to -1 of tCleanURL into tSegments

    # REMOVE WHITESPACE IN DOMAIN
    put replacetext(tDomain,"[ ]+", "") into tDomain

    # REPLACE WHITESPACE
    put replacetext(tSegments,"[ ]+", pSeparator) into tSegments

    return tDomain & tSegments
  end if

  return false
end rigURLstripSpace





--| END OF urlHelper.livecodescript
--| Location:  ./system/helpers/urlHelper.livecodescript
----------------------------------------------------------------------