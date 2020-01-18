script "htmlHelper"

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
# revIgniter HTML Helpers
#
# @package		revIgniter
# @subpackage	Helpers
# @category	  Helpers
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/helpers/htmlHelper.html
##

## ------------------------------------------------------------------------




global gRigA

local sNumberedListArray 		-- used by function _rigHtmlList()
local sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-21
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
--| FUNCTION rigHtmlHeading
--|
--| Author: rabit
--| Version:  1.0
--| Created: 08-10-09
--| Last Mod: 08-10-09
--| Requires: --
--|
--| Summary: Generates an HTML heading tag.  First param is the data.
--|            Second param is the size of the heading tag.
--| 
--| Format:  rigHtmlHeading(param1, 2)
--|
--| Parameters: string <pData>, integer <pH>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigHtmlHeading pData pH
  local tH
  
	if pH is empty then
		put 1 into tH
	else
		put pH into tH
	end if

	return "<h" & tH & ">" & pData & "</h" & tH & ">"
end rigHtmlHeading








/*----------------------------------------------------------------------
--| FUNCTION rigHtmlUL
--|
--| Author: rabit
--| Version:  1.1
--| Created: 08-10-09
--| Last Mod: 07-01-10
--| Requires: _rigHtmlList()
--|
--| Summary: Generates an HTML unordered list from
--|            a comma delimited list or from a multi-dimensional array.
--|			    The first dimension must be numbered, otherweise the order
--|            of the list may be changed.
--| 
--| Format:  rigHtmlUL(param1, param2)
--|
--| Parameters: mixed <pList>, mixed <pAttributes>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigHtmlUL pList pAttributes
  local tList, tI, tTemp
  
  put pList into tList
  if tList is not an array then
    if comma is in tList then
      put 0 into tI
      repeat for each item thisItem in tList
        add 1 to tI
        put thisItem into tTemp[tI]
      end repeat

      put tTemp into tList

    else
      # SINGLE WORD
      put tList into tList[1]
    end if
  end if
	
  put empty into sNumberedListArray
	
  return _rigHtmlList("ul", tList, pAttributes)
end rigHtmlUL








/*----------------------------------------------------------------------
--| FUNCTION rigHtmlOL
--|
--| Author: rabit
--| Version:  1.1
--| Created: 08-10-09
--| Last Mod: 07-01-10
--| Requires: _rigHtmlList()
--|
--| Summary: Generates an HTML ordered list from
--|            a comma delimited list or from a multi-dimensional array.
--|			    The first dimension must be numbered, otherweise the order
--|            of the list may be changed.
--| 
--| Format:  rigHtmlOL(param1, param2)
--|
--| Parameters: mixed <pList>, mixed <pAttributes>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigHtmlOL pList pAttributes
  local tList, tI, tTemp
  
  put pList into tList
  if tList is not an array then
    if comma is in tList then
      put 0 into tI
      repeat for each item thisItem in tList
        add 1 to tI
        put thisItem into tTemp[tI]
      end repeat

      put tTemp into tList

    else
      # SINGLE WORD
      put tList into tList[1]
    end if
  end if

  put empty into sNumberedListArray

  return _rigHtmlList("ol", tList, pAttributes)
end rigHtmlOL








/*----------------------------------------------------------------------
--| FUNCTION _rigHtmlList
--|
--| Author: rabit
--| Version:  1.2
--| Created: 08-10-09
--| Last Mod: 21-03-14
--| Requires: --
--|
--| Summary: Generates an HTML ordered or unordered list from
--|            a comma delimited list or from a multi-dimensional array.
--|			    The first dimension must be numbered, otherweise the order
--|            of the list may be changed.
--| 
--| Format:  _rigHtmlList(param1, param2, param3, param4)
--|
--| Parameters: string <pType>, mixed <pList>, mixed <pAttributes>, integer <pDepth>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigHtmlList pType pList pAttributes pDepth pCurrentOut pOmitClosingTag
  local tAttributes, tList, tI, tTemp, tDepth, tOut, tKey
  local tVal, tAtts, tRegEx, tMatch, tMatch2, tWriteOpenList
  local tOmitClosingTag, tLastListItem
  
  # CHECK IF THE ARRAY IS NUMBERED (LOOK AT FIRST KEY ONLY)
  if sNumberedListArray is empty then
    if (line 1 in the keys of pList) is a number then
      put TRUE into sNumberedListArray
    else
      put FALSE into sNumberedListArray
    end if
  end if	

  put pAttributes into tAttributes
  put pList into tList
  if tList is not an array then
    if comma is in tList then
      put 0 into tI
      repeat for each item thisItem in tList
        add 1 to tI
        put thisItem into tTemp[tI]
      end repeat

      put tTemp into tList

    else
      # SINGLE WORD
      put tList into tList[1]
    end if
  end if

  # INDENTATION DEPTH
  if pDepth is empty then
    put 0 into tDepth
  else
    put pDepth into tDepth
  end if

  # SET THE INDENTATION BASED ON THE DEPTH
  repeat tDepth
    put " " after tOut
  end repeat

  # WERE ANY ATTRIBUTES SUBMITTED?  IF SO GENERATE A STRING
  if tAttributes is an array then
    repeat for each key tKey in tAttributes
      put tAttributes[tKey] into tVal

      put " " & tKey & "=" & quote & tVal & quote after tAtts
    end repeat

    put tAtts into tAttributes
  end if

  put "<li>.+</li>" into tRegEx   
  put matchText((line -2 of pCurrentOut), tRegEx) into tMatch

  put "<" & pType & ".*>" into tRegEx   
  put matchText((line -2 of pCurrentOut), tRegEx) into tMatch2

  # CHECK IF AN OPENING LIST TAG SHOULD BE ADDED TO THE OUTPUT
  if sNumberedListArray is TRUE then
    if ("</li>" is not in (line -2 of pCurrentOut)) and (tMatch2 is not TRUE) then
      put TRUE into tWriteOpenList
    else
      put FALSE into tWriteOpenList
    end if
      
  else
    if (tMatch is not TRUE) and ((tMatch2 is not TRUE) or (("<" & pType & ">") is not in (line -2 of pCurrentOut))) then
      put TRUE into tWriteOpenList
    else
      put FALSE into tWriteOpenList
    end if 
  end if
   
  if tWriteOpenList is TRUE then

    # WRITE THE OPENING LIST TAG
    put "<" & pType & tAttributes & ">" & return after tOut

  else
    put TRUE into tOmitClosingTag
    put empty into line -1 of tOut
  end if

  # CYCLE THROUGH THE LIST ELEMENTS.  IF AN ARRAY IS
  # ENCOUNTERED WE WILL RECURSIVELY CALL _rigHtmlList
  if (line 1 in the keys of tList) is a number then
    repeat with i = 1 to (the number of lines in the keys of tList)
      put tList[i] into tVal

      put i into tLastListItem

      if "<" is in line -1 of tOut then

        repeat (tDepth + 2)
          put " " after tOut
        end repeat

      else
        put empty into line -1 of tOut
        put "  " after tOut
      end if

      put "<li>" after tOut

      if tVal is not an array then
        put tVal after tOut
      else

        if tLastListItem is not a number then
          put tLastListItem & return after tOut
        else
          put char 1 to -5 of tOut into tOut
        end if

        put _rigHtmlList(pType, tVal, , (tDepth + 4), tOut, tOmitClosingTag) after tOut

        if tOmitClosingTag is not TRUE then

          repeat (tDepth + 2)
            put " " after tOut
          end repeat
        else
          put empty into line -1 of tOut
          put "  " after tOut
        end if
      end if

      if ("<li>" is not in (line -1 of tOut)) and  ("</li>" is in (line -2 of tOut)) then
      else
        put "</li>" & return after tOut
      end if

    end repeat

  else

    repeat for each key tKey in tList
      put tList[tKey] into tVal

      put tKey into tLastListItem

      if "<" is in line -1 of tOut then

        repeat (tDepth + 2)
          put " " after tOut
        end repeat
      else
        put empty into line -1 of tOut
        put "  " after tOut
      end if

      put "<li>" after tOut

      if tVal is not an array then
        put tVal after tOut
      else
        if tLastListItem is not a number then
          put tLastListItem & return after tOut
        else
          put char 1 to -5 of tOut into tOut
        end if

        put _rigHtmlList(pType, tVal, , (tDepth + 4), tOut, tOmitClosingTag) after tOut

        if tOmitClosingTag is not TRUE then

          repeat (tDepth + 2)
            put " " after tOut
          end repeat
        else
          put empty into line -1 of tOut
          put "  " after tOut
        end if

      end if

      if ("<li>" is not in (line -1 of tOut)) and  ("</li>" is in (line -2 of tOut)) then
      else
        put "</li>" & return after tOut
      end if

    end repeat

  end if

  # SET THE INDENTATION FOR THE CLOSING TAG
  repeat tDepth
    put " " after tOut
  end repeat

  if pOmitClosingTag is not TRUE then
    # WRITE THE CLOSING LIST TAG
    put "</" & pType & ">" & return after tOut
  end if

  return tOut
end _rigHtmlList




/*----------------------------------------------------------------------
--| FUNCTION rigHtmlBr
--|
--| Author: rabit
--| Version:  1.0
--| Created: 08-10-09
--| Last Mod: 08-10-09
--| Requires: --
--|
--| Summary: Generates HTML BR tags based on number supplied.
--| 
--| Format:  rigHtmlBr(param1)
--|
--| Parameters: integer <pNum>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigHtmlBr pNum
  local tNum, tBrTags
  
	if pNum is empty then
		put 1 into tNum
	else
		put pNum into tNum
	end if

	repeat tNum
		put "<br />" after tBrTags
	end repeat

	return tBrTags
end rigHtmlBr








/*----------------------------------------------------------------------
--| FUNCTION rigHtmlImg
--|
--| Author: rabit
--| Version:  1.1
--| Created: 08-10-09
--| Last Mod: 05-01-10
--| Requires: rigSiteURL(), rigSlashItem()
--|
--| Summary: Generates an <img /> element.
--| 
--| Format:  rigHtmlImg(param1, param2)
--|
--| Parameters: mixed <pSrc>, bool <pIndexPage>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigHtmlImg pSrc pIndexPage
  local tIndexPage, tKey, tSrc, tImg, tK, tV, tURL
  local tBaseURL
  
	if pIndexPage is empty then
		put FALSE into tIndexPage
	else
		put pIndexPage into tIndexPage
	end if

	if pSrc is not an array then
		put "src" into tKey
		put pSrc into tSrc[tKey]
	else
		put pSrc into tSrc
	end if

	put "<img" into tImg

	repeat for each key tK in tSrc
		put tSrc[tK] into tV

		if (tK is "src") and ("://" is not in tV) then
			if tIndexPage is TRUE then
				put rigSiteURL(tV) into tURL
				put " src=" & quote & tURL & quote after tImg
			else
				put rigSlashItem("baseUrl") into tBaseURL
				put " src=" & quote & tBaseURL & tV & quote  after tImg
			end if
		else
			put " " & tK & "=" & quote & tV & quote after tImg
		end if
	end repeat

	put "/>" after tImg

	return tImg
end rigHtmlImg








/*----------------------------------------------------------------------
--| FUNCTION rigHtmlDocType
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-10-09
--| Last Mod: 2019-01-03
--| Requires: _rigRequire, rigLogMessage
--|
--| Summary: Generates a page document type declaration.
--|
--|             Valid options are xhtml11, xhtml1-strict, xhtml1-trans, xhtml1-frame, html5,
--|             html4-strict, html4-trans, and html4-frame.  Values are saved in the
--|             doctypes config file.
--| 
--| Format:  rigHtmlDocType(param1)
--|
--| Parameters: string <pType> the doctype to be generated
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigHtmlDocType pType
  local tType
  
	if pType is empty then
		put "html5" into tType
	else
		put pType into tType
	end if

	if gRigA["docTypes"] is not an array then
		# LOAD THE DOC TYPES
		try
			_rigRequire gRigA["APPPATH"] & "config/doctypes" & gRigA["EXT"]
		catch err
			rigLogMessage "error", "An error occured while trying to include file:" && "doctypes" & gRigA["EXT"]
			return FALSE
		end try

	end if

	if gRigA["docTypes"][tType] is not empty then
		return gRigA["docTypes"][tType]
	end if

	return FALSE
end rigHtmlDocType







/*----------------------------------------------------------------------
--| FUNCTION rigHtmlLinkTag
--|
--| Author: rabit
--| Version:  1.2
--| Created: 09-10-09
--| Last Mod: 21-09-11
--| Requires: rigSiteURL(), rigSlashItem()
--|
--| Summary: Generates HTML <link /> tags.
--| 
--| Format:  rigHtmlLinkTag(param1, param2, param3, param4, param5, param6)
--|
--| Parameters: mixed <pHref> stylesheet hrefs or an array, string <pRel>, string <pType>, string <pTitle>,
--|               string <pMedia>, bool <pIndexPage> should indexPage be added to the css path
--|
--| Return: string
----------------------------------------------------------------------*/

function rigHtmlLinkTag pHref pRel pType pTitle pMedia pIndexPage
  local tRel, tType, tIndexPage, tLink, tK, tV, tURL, tBaseURL
  
	if pRel is empty then
		put "stylesheet" into tRel
	else
		put pRel into tRel
	end if

	if pType is empty then
		if (pRel <> "apple-touch-startup-image") and (pRel <> "apple-touch-icon") and (pRel <> "apple-touch-icon-precomposed") then
			put "text/css" into tType
		else
			put "" into tType
		end if
	else
		put pType into tType
	end if

	if pIndexPage is empty then
		put FALSE into tIndexPage
	else
		put pIndexPage into tIndexPage
	end if

	put "<link " into tLink

	if pHref is an array then
		repeat for each key tK in pHref
			put pHref[tK] into tV

			if (tK is "href") and ("://" is not in tV) then
				if tIndexPage is TRUE then
					put rigSiteURL(tV) into tURL
					put " href=" & quote & tURL & quote & " " after tLink
				else
					put rigSlashItem("baseUrl") into tBaseURL
					put " href=" & quote & tBaseURL & tV & quote & " " after tLink
				end if
			else
				put tK & "=" & quote & tV & quote & " " after tLink
			end if
		end repeat

		put "/>" after tLink
	else
		if "://" is in pHref then
			put " href=" & quote & pHref & quote & " " after tLink
		else if tIndexPage is TRUE then
			put rigSiteURL(pHref) into tURL
			put " href=" & quote & tURL & quote & " " after tLink
		else
			put rigSlashItem("baseUrl") into tBaseURL
			put " href=" & quote & tBaseURL & pHref & quote & " " after tLink
		end if

		if tType <> "" then
			put "rel=" & quote & tRel & quote && "type=" & quote & tType & quote & " " after tLink
		else
			put "rel=" & quote & tRel & quote & " " after tLink
		end if

		if pTitle is not empty then
			put "title=" & quote & pTitle & quote & " " after tLink
		end if

		if pMedia is not empty then
			put "media=" & quote & pMedia & quote & " " after tLink
		end if

		put "/>" after tLink
	end if

	return tLink
end rigHtmlLinkTag








/*----------------------------------------------------------------------
--| FUNCTION rigHtmlJsLink
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-10-09
--| Last Mod: 09-10-09
--| Requires: rigSiteURL(), rigSlashItem()
--|
--| Summary: Generates link to a JavaScript file.
--| 
--| Format:  rigHtmlJsLink(param1, param2)
--|
--| Parameters: mixed <pSrc>, bool <pIndexPage> should indexPage be added to the css path,
--|               string <pNewLine>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigHtmlJsLink pSrc pIndexPage pNewLine
  local tIndexPage, tNewLine, tK, tV, tLink, tURL, tBaseURL
  
	if pIndexPage is empty then
		put FALSE into tIndexPage
	else
		put pIndexPage into tIndexPage
	end if

	if pNewLine is empty then
		put return into tNewLine
	else
		put pNewLine into tNewLine
	end if	

	if pSrc is an array then
		repeat for each key tK in pSrc
			put pSrc[tK] into tV

			put "<script type=" & quote & "text/javascript" & quote & " " after tLink

			if tIndexPage is TRUE then
				put rigSiteURL(tV) into tURL
				put "src=" & quote & tURL & quote after tLink
			else
				put rigSlashItem("baseUrl") into tBaseURL
				put "src=" & quote & tBaseURL & tV & quote after tLink
			end if

			put "></script>" & tNewLine after tLink
		end repeat
		
	else
		put "<script type=" & quote & "text/javascript" & quote & " " after tLink

		if "://" is in pSrc then
			put "src=" & quote & pSrc & quote after tLink
		else if tIndexPage is TRUE then
			put rigSiteURL(pSrc) into tURL
			put "src=" & quote & tURL & quote after tLink
		else
			put rigSlashItem("baseUrl") into tBaseURL
			put "src=" & quote & tBaseURL & pSrc & quote after tLink
		end if

		put "></script>" & tNewLine after tLink
	end if

	return tLink
end rigHtmlJsLink








/*----------------------------------------------------------------------
--| FUNCTION rigHtmlMeta
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-10-09
--| Last Mod: 09-10-09
--| Requires: --
--|
--| Summary: Generates meta tags from an array of key/values.
--| 
--| Format:  rigHtmlMeta(param1, param2, param3, param4)
--|
--| Parameters: mixed <pName>, string <pContent>, string <pType>, string <pNewLine>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigHtmlMeta pName pContent pType pNewLine
  local tType, tNewLine, tNameA, tKey, tMeta, tMetaName
  local tContent, tStr
  
	if pType is empty then
		put "name" into tType
	else
		put pType into tType
	end if

	if pNewLine is empty then
		put return into tNewLine
	else
		put pNewLine into tNewLine
	end if

	# SINCE WE ALLOW THE DATA TO BE PASSED AS A STRING, A SIMPLE ARRAY
	# OR A MULTIDIMENSIONAL ONE, WE NEED TO DO A LITTLE PREPPING.
	if pName is not an array then
		put pName into tNameA[1]["name"]
		put pContent into tNameA[1]["content"]
		put tType into tNameA[1]["type"]
		put tNewLine into tNameA[1]["newline"]
	else
		# TURN SINGLE ARRAY INTO MULTIDIMENSIONAL
		if pName["name"] is not empty then
			put pName into tNameA[1]
		else
			put pName into tNameA
		end if
	end if

	repeat for each key tKey in tNameA
		put tNameA[tKey] into tMeta

		if (tMeta["type"] is empty) or (tMeta["type"] is "name") then
			put "name" into tType
		else
			put "http-equiv" into tType
		end if

		if tMeta["name"] is empty then
			put "" into tMetaName
		else
			put tMeta["name"] into tMetaName
		end if

		if tMeta["content"] is empty then
			put "" into tContent
		else
			put tMeta["content"] into tContent
		end if

		if tMeta["newline"] is empty then
			put return into tNewline
		else
			put tMeta["newline"] into tNewline
		end if

		put "<meta" && tType & "=" & quote & tMetaName & quote && "content=" & quote & tContent & quote && "/>" & tNewline after tStr
	end repeat

	return tStr
end rigHtmlMeta







/*----------------------------------------------------------------------
--| FUNCTION rigHtmlNbs
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-10-09
--| Last Mod: 09-10-09
--| Requires: --
--|
--| Summary: Generates non-breaking space entities based on number supplied.
--| 
--| Format:  rigHtmlNbs(param1)
--|
--| Parameters: integer <pNum>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigHtmlNbs pNum
  local tNum, tNbsTags
  
	if pNum is empty then
		put 1 into tNum
	else
		put pNum into tNum
	end if

	repeat tNum
		put "&nbsp;" after tNbsTags
	end repeat

	return tNbsTags
end rigHtmlNbs










--| END OF htmlHelper.livecodescript
--| Location:  ./system/helpers/htmlHelper.livecodescript
----------------------------------------------------------------------