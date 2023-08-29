script "Pagination"

##
# revIgniter
#
# An application development framework for LiveCode
# modeled on CodeIgniter.
#
# @package		revIgniter
# @author		  rabit@revigniter.com
# @copyright	Copyright (c) 2009 - 2023, Ralf Bitter
# @license		https://revigniter.com/userGuide/license.html
# @link		    https://revigniter.com
##

## ------------------------------------------------------------------------

##
# revIgniter Pagination Library
#
#
# @package		  revIgniter
# @subpackage	Libraries
# @category	    Pagination
# @author		    rabit@revigniter.com
# @link		      https://revigniter.com/userGuide/libraries/pagination.html
##

## ------------------------------------------------------------------------




global gRigA, gConfig

local sVarsNoDefaults
local sStackInUse, sPagArrayKeys, sPaginationA -- array keys are: perPage, numLinks, curPage, firstLink, nextLink, prevLink, lastLink, uriSegment, firstTagClose,
                                                      -- lastTagOpen, curTagOpen, curTagClose, nextTagOpen, nextTagClose, prevTagOpen, numTagOpen, pageQueryString,
                                                      -- queryStringSegment, linksElementID, dataElementID, ajaxServerTimeout, widgetName, baseUrl, totalRows, ajax,
                                                      -- fullTagOpen, fullTagClose, firstTagOpen, lastTagClose, prevTagClose, numTagClose



 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-26
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
        rigLogMessage "debug", "Pagination Library Loaded"
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
--| Version:  1.1
--| Created: 2019-01-04
--| Last Mod: 2023-08-26
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
  ---------------- no default values ----------------
  -- baseUrl -- The page including controller and handler we are linking to (option 1)
  -- totalRows -- Total number of items (database results)
  -- fullTagOpen
  -- fullTagClose
  -- firstTagOpen
  -- lastTagClose
  -- prevTagClose
  -- numTagClose
  ---------------------------------------------
  put "index" into sPaginationA["paginationHandler"] -- The controller handler dealing with pagination (option 2)
  put 10 into sPaginationA["perPage"]					-- Max number of items you want shown per page
  put 2 into sPaginationA["numLinks"]					-- Number of "digit" links to show before/after the currently viewed page
  put 0 into sPaginationA["curPage"]					-- The current page being viewed
  put "&lsaquo; First" into sPaginationA["firstLink"]
  put "&gt;" into sPaginationA["nextLink"]
  put "&lt;" into sPaginationA["prevLink"]
  put "Last &raquo;" into sPaginationA["lastLink"]
  put 3 into sPaginationA["uriSegment"]
  put "&nbsp;" into sPaginationA["firstTagClose"]
  put "&nbsp;" into sPaginationA["lastTagOpen"]
  put "&nbsp;<strong>" into sPaginationA["curTagOpen"]
  put "</strong>" into sPaginationA["curTagClose"]
  put "&nbsp;" into sPaginationA["nextTagOpen"]
  put "&nbsp;" into sPaginationA["nextTagClose"]
  put "&nbsp;" into sPaginationA["prevTagOpen"]
  put "&nbsp;" into sPaginationA["numTagOpen"]
  put FALSE into sPaginationA["pageQueryString"]
  put "per_page" into sPaginationA["queryStringSegment"]
  put "pagination" into sPaginationA["linksElementID"]        -- The ID of the HTML element containing the pagination links (used for XMLHTTP requests only)
  put "paginationData" into sPaginationA["dataElementID"]    -- The ID of the HTML element containing the paginated data (used for XMLHTTP requests only)
  put 10000 into sPaginationA["ajaxServerTimeout"]           -- Delay to trigger an error while making an AJAX request (milliseconds)
  put "PaginationWidget" into sPaginationA["widgetName"]    -- Name of Ajax pagination JavaScript object
	
	put ("ASYNergy" is among the lines of the stacksInUse) into sPaginationA["asynergyPagination"]

  put "perPage,numLinks,curPage,firstLink,nextLink,prevLink,lastLink,uriSegment,firstTagClose,lastTagOpen,curTagOpen,curTagClose,nextTagOpen,nextTagClose,prevTagOpen,numTagOpen,pageQueryString,queryStringSegment,linksElementID,dataElementID,ajaxServerTimeout,widgetName,paginationHandler,baseUrl,totalRows,fullTagOpen,fullTagClose,firstTagOpen,lastTagClose,prevTagClose,numTagClose,asynergyPagination" into sPagArrayKeys

  put "baseUrl,totalRows,fullTagOpen,fullTagClose,firstTagOpen,lastTagClose,prevTagClose,numTagClose" into sVarsNoDefaults
end _rigSetDefaultValues





/*----------------------------------------------------------------------
--| COMMAND rigRunInitialPaginationConfig
--|
--| Author: rabit
--| Version:  1.2
--| Created: 22-09-09
--| Last Mod: 22-12-14
--| Requires: rigInitializePagination
--|
--| Summary: Run initial configuration procedures.
--|
--| Format:  rigRunInitialPaginationConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialPaginationConfig pConfig
  local tConfig

	put pConfig into tConfig

	if tConfig is not an array then
		if tConfig is not empty then
			split tConfig using numToCodepoint(1) and numToCodepoint(2)
		end if
	end if

	if tConfig is an array then
		rigInitializePagination tConfig
	end if

end rigRunInitialPaginationConfig







/*----------------------------------------------------------------------
--| COMMAND rigInitializePagination
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2022-09-09
--| Last Mod: 2023-07-12
--| Requires: rigSetInitialPaginationValue, rigSiteURL(), rigFetchSegment()
--|
--| Summary: Initialize preferences.
--|
--| Format:  rigInitializePagination param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigInitializePagination pConfig
  local tKey, tVal

	if pConfig is an array then
		repeat for each key tKey in pConfig
			put pConfig[tKey] into tVal

			rigSetInitialPaginationValue tKey, tVal

		end repeat
	end if

  if sPaginationA["baseUrl"] is empty then
  	if gConfig["enableQueryStrings"] is TRUE then
      put rigSiteURL() & "?c=" & rigFetchSegment(1) & "&h=" & sPaginationA["paginationHandler"] into sPaginationA["baseUrl"]
  	else
      put rigSiteURL() & rigFetchSegment(1) & "/" & sPaginationA["paginationHandler"] into sPaginationA["baseUrl"]
  	end if
  end if
end rigInitializePagination







/*----------------------------------------------------------------------
--| COMMAND rigSetInitialPaginationValue
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-09-22
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Set initial values.
--|
--| Format:  rigSetInitialPaginationValue param1, param2
--|
--| Parameters: string <pKey>, mixed <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetInitialPaginationValue pKey pValue
  if pKey is among the items of sPagArrayKeys then
    put pValue into sPaginationA[pKey]
  end if
end rigSetInitialPaginationValue








/*----------------------------------------------------------------------
--| FUNCTION rigCreatePaginationLinks
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2009-09-22
--| Last Mod: 2023-07-19
--| Requires: rigFetchConfigItem(), rigVarGet(), rigShowError, rigRTrim, _rigFirstLink(),
--|            _rigPreviousLink(), _rigDigitLinks(), _rigNextLink(), _rigLastLink(), rigPregReplace()
--|
--| Summary: Generate the pagination links.
--|
--| Format:  rigCreatePaginationLinks([param1])
--|
--| Parameters: integer <pRecordsOffset> current page (optional), needed if ASYNergy is used
--|
--| Return: string
----------------------------------------------------------------------*/

function rigCreatePaginationLinks pRecordsOffset
  local tNumPages, tQuerySeg, tUriSeg, tUriPageNumber, tStart, tEnd
  local tAriaLabel, tOutput, tCounter, tI, tN, tJ, tRegEx
  local tReplacementtStrToReplaceInFoundStr, tReplacement, tStrToReplaceInFoundStr

	# IF OUR ITEM COUNT OR PER-PAGE TOTAL IS ZERO THERE IS NO NEED TO CONTINUE
	if (sPaginationA["totalRows"] = 0) or (sPaginationA["perPage"] = 0) then
		return ""
	end if

	# CALCULATE THE TOTAL NUMBER OF PAGES
	put ceil(sPaginationA["totalRows"] / sPaginationA["perPage"]) into tNumPages

	# IS THERE ONLY ONE PAGE? HM... NOTHING MORE TO DO HERE THEN.
	if tNumPages = 1 then
		return ""
	end if

	# DETERMINE THE CURRENT PAGE NUMBER.
  # IN CASE ASYNergy IS USED GET THE CURRENT PAGE FROM THE
  # MODEL OR ACTION PARAMETER AND PASS IT TO THIS FUNCTION.
  if (pRecordsOffset is empty) or (pRecordsOffset is not an integer) then
    if (gConfig["enableQueryStrings"] is TRUE) or (sPaginationA["pageQueryString"] is TRUE) then
    
      put rigVarGet(sPaginationA["queryStringSegment"]) into tQuerySeg
      if tQuerySeg is not 0 then
        put tQuerySeg into sPaginationA["curPage"]
      end if
    else
      put rigFetchSegment(sPaginationA["uriSegment"]) into tUriSeg
      if tUriSeg is not 0 then
        put tUriSeg into sPaginationA["curPage"]
      end if
    end if
    
  else
    if pRecordsOffset is not 0 then
      put pRecordsOffset into sPaginationA["curPage"]
    end if
  end if

	if sPaginationA["numLinks"] < 1 then
		rigShowError "Your number of links must be a positive number."
	end if

	if sPaginationA["curPage"] is not a number then
		put 0 into sPaginationA["curPage"]
	end if

	# IS THE PAGE NUMBER BEYOND THE RESULT RANGE?
	# IF SO WE SHOW THE LAST PAGE
	if sPaginationA["curPage"] > sPaginationA["totalRows"] then
		put (tNumPages - 1) * sPaginationA["perPage"] into sPaginationA["curPage"]
	end if

	put sPaginationA["curPage"] into tUriPageNumber
	put trunc((sPaginationA["curPage"] / sPaginationA["perPage"]) + 1) into sPaginationA["curPage"]

	# CALCULATE THE START AND END NUMBERS. THESE DETERMINE
	# WHICH NUMBER TO START AND END THE DIGIT LINKS WITH
	if (sPaginationA["curPage"] - sPaginationA["numLinks"]) > 0 then
		put sPaginationA["curPage"] - (sPaginationA["numLinks"] - 1) into tStart
	else
		put 1 into tStart
	end if

	if ((sPaginationA["curPage"] + sPaginationA["numLinks"]) < tNumPages) then
		put sPaginationA["curPage"] + sPaginationA["numLinks"] into tEnd
	else
		put tNumPages into tEnd
	end if

	# IS PAGINATION BEING USED OVER GET OR POST?  IF GET, ADD A PER_PAGE QUERY
	# STRING. IF POST, ADD A TRAILING SLASH TO THE BASE URL IF NEEDED
  if (gConfig["enableQueryStrings"] is TRUE) or (sPaginationA["pageQueryString"] is TRUE) then
    put rigRTrim(sPaginationA["baseUrl"]) & "&" & sPaginationA["queryStringSegment"] & "=" into sPaginationA["baseUrl"]
	else
		put rigRTrim(sPaginationA["baseUrl"], "/") & "/" into sPaginationA["baseUrl"]
	end if

	# AND HERE WE GO...
	# RENDER THE "FIRST" LINK
  put _rigFirstLink() into tOutput
  #

	# RENDER THE "PREVIOUS" LINK
  put _rigPreviousLink(tUriPageNumber) after tOutput
  #

	# WRITE THE DIGIT LINKS
  put _rigDigitLinks(tStart, tEnd, tOutput) into tOutput
  #

	# RENDER THE "NEXT" LINK
  put _rigNextLink(tNumPages) after tOutput
  #

	# RENDER THE "LAST" LINK  
  put _rigLastLink(tNumPages) after tOutput
  #

  # KILL DOUBLE SLASHES.  NOTE: SOMETIMES WE CAN END UP WITH A DOUBLE SLASH
  # IN THE PENULTIMATE LINK SO WE'LL KILL ALL DOUBLE SLASHES.
  put "([^:]//+)" into tRegEx
  put "//" into tStrToReplaceInFoundStr
  put "/" into tReplacement

  put rigPregReplace(tOutput, tRegEx, tStrToReplaceInFoundStr, tReplacement) into tOutput

  # ADD THE WRAPPER HTML IF EXISTS
  put sPaginationA["fullTagOpen"] & tOutput & sPaginationA["fullTagClose"] into tOutput

  return tOutput
end rigCreatePaginationLinks





/*----------------------------------------------------------------------
--| FUNCTION _rigFirstLink
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2023-07-17
--| Last Mod:
--| Requires: --
--|
--| Summary: Render the "FIRST" link.
--| 
--| Format:  _rigFirstLink()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigFirstLink
  local tAriaLabel, tURL, tHandlerOffset, tFirstLink
  
  if  sPaginationA["curPage"] > (sPaginationA["numLinks"] + 1) then
		# ARIA
		if sPaginationA["firstLink"] contains "&lsaquo;" then
      put "aria-label='First'" into tAriaLabel
		else
			put empty into tAriaLabel
		end if
		#

    # ASYNergy
    # REMOVE THE HANDLER FROM THE URI
    put sPaginationA["baseUrl"] into tURL

    if sPaginationA["asynergyPagination"] is TRUE then
      if (gConfig["enableQueryStrings"] is TRUE) or (sPaginationA["pageQueryString"] is TRUE) then
        put offset("&h=", tURL ) into tHandlerOffset
        put char 1 to (tHandlerOffset - 1) of tURL into tURL
      
      else
        set the itemDel to "/"
        if char -1 of tURL is "/" then
          put char 1 to -2 of tURL into tURL
        end if
        delete item -1 of tURL
      end if -- if (gConfig["enableQueryStrings"] is TRUE) or (sPaginationA["pageQueryString"] is TRUE)
    end if -- if sPaginationA["asynergyPagination"] is TRUE
    #

    put sPaginationA["firstTagOpen"] & "<a href='" & tURL & "'" \
    && tAriaLabel & ">" & sPaginationA["firstLink"] & "</a>" & \
    sPaginationA["firstTagClose"] into tFirstLink
	end if
  
  return tFirstLink
end _rigFirstLink





/*----------------------------------------------------------------------
--| FUNCTION _rigPreviousLink
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2023-07-17
--| Last Mod: --
--| Requires: --
--|
--| Summary: Render the "PREVIOUS" link
--|  
--| Format:  _rigPreviousLink(param1)
--|
--| Parameters: integer <pUriPageNumber>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigPreviousLink pUriPageNumber
  local tAriaLabel, tCounter, tAsynMarkup, tPreviousLink
  
  if sPaginationA["curPage"] <> 1 then
    # ARIA
    if sPaginationA["prevLink"] contains "&lt;" then
      put "aria-label='Previous'" into tAriaLabel
    else
      put empty into tAriaLabel
    end if
    #

    put pUriPageNumber - sPaginationA["perPage"] into tCounter
    if tCounter = 0 then
      put empty into tCounter
      
    else
      # ASYNergy
      if sPaginationA["asynergyPagination"] is TRUE then
        put "asyn:click.prevent=" & quote & sPaginationA["paginationHandler"] & "('" & tCounter & "')" & quote into tAsynMarkup
      end if
      #
    end if

    put sPaginationA["prevTagOpen"] & "<a" && tAsynMarkup && "href='" & sPaginationA["baseUrl"] & \
    tCounter & "'" && tAriaLabel & ">" & sPaginationA["prevLink"] & "</a>" & \
    sPaginationA["prevTagClose"] into tPreviousLink
  end if
  
  return tPreviousLink
end _rigPreviousLink





/*----------------------------------------------------------------------
--| FUNCTION _rigDigitLinks
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2023-07-17
--| Last Mod: --
--| Requires: --
--|
--| Summary: Render the digit links.
--| 
--| Format:  _rigDigitLinks(param1, param2, param3)
--|
--| Parameters: integer <pStart> the pagination start number, integer <pEnd>
--|               the pagination end number, string <pPaginationLinks> incomplete pagination markup
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigDigitLinks pStart pEnd pPaginationLinks
  local tLoopCounter, tStart, tEnd, tI, tN, tAsynMarkup
  
  repeat with tLoopCounter = (pStart - 1) to pEnd
    put (tLoopCounter * sPaginationA["perPage"]) - sPaginationA["perPage"] into tI

    if tI >= 0 then
      if sPaginationA["curPage"] = tLoopCounter then
        put sPaginationA["curTagOpen"] & tLoopCounter & \
        sPaginationA["curTagClose"] after pPaginationLinks -- current page
      else
        if tI = 0 then
          put empty into tN
        else
          put tI into tN
        end if
        
        # ASYNergy
        if sPaginationA["asynergyPagination"] is TRUE then
          put "asyn:click.prevent=" & quote & sPaginationA["paginationHandler"] & "('" & tN & "')" & quote into tAsynMarkup
        end if
        #

        put sPaginationA["numTagOpen"] & "<a" && tAsynMarkup && "href='" & sPaginationA["baseUrl"] & tN & "'>" & \
        tLoopCounter & "</a>" & sPaginationA["numTagClose"] after pPaginationLinks
      end if
    end if
  end repeat
  
  return pPaginationLinks
end _rigDigitLinks





/*----------------------------------------------------------------------
--| FUNCTION _rigNextLink
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2023-07-18
--| Last Mod: --
--| Requires: --
--|
--| Summary: Render the "NEXT" link.
--| 
--| Format:  _rigNextLink(param1)
--|
--| Parameters: integer <pNumPages>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigNextLink pNumPages
  local tAriaLabel, tJ, tAsynMarkup, tNextLink
  
  if sPaginationA["curPage"] < pNumPages then
    # ARIA
    if sPaginationA["nextLink"] contains "&gt;" then
      put "aria-label='Next'" into tAriaLabel
    else
      put empty into tAriaLabel
    end if
    #
    put sPaginationA["curPage"] * sPaginationA["perPage"] into tJ
    
    # ASYNergy
    if sPaginationA["asynergyPagination"] is TRUE then
      put "asyn:click.prevent=" & quote & sPaginationA["paginationHandler"] & "('" & tJ & "')" & quote into tAsynMarkup
    end if
    #

    put sPaginationA["nextTagOpen"] & "<a" && tAsynMarkup && "href='" & sPaginationA["baseUrl"] & \
    tJ & "'" && tAriaLabel & ">" & sPaginationA["nextLink"] & \
    "</a>" & sPaginationA["nextTagClose"] into tNextLink
	end if
  
  return tNextLink
end _rigNextLink





/*----------------------------------------------------------------------
--| FUNCTION _rigLastLink
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2023-07-18
--| Last Mod: --
--| Requires: --
--|
--| Summary: Render the "LAST" link.
--| 
--| Format:  _rigLastLink(param1)
--|
--| Parameters: integer <pNumPages>
--|
--| Return: returnType
----------------------------------------------------------------------*/

private function _rigLastLink pNumPages
  local tAriaLabel, tI, tAsynMarkup, tLastLink
  
  if (sPaginationA["curPage"] + sPaginationA["numLinks"]) < pNumPages then
    # ARIA
    if sPaginationA["lastLink"] contains "&raquo;" then
      put "aria-label='Last'" into tAriaLabel
    else
      put empty into tAriaLabel
    end if
    #
    put (pNumPages * sPaginationA["perPage"]) - sPaginationA["perPage"] into tI
    
    # ASYNergy
    if sPaginationA["asynergyPagination"] is TRUE then
      put "asyn:click.prevent=" & quote & sPaginationA["paginationHandler"] & "('" & tI & "')" & quote into tAsynMarkup
    end if
    #

    put sPaginationA["lastTagOpen"] & "<a" && tAsynMarkup && "href='" & sPaginationA["baseUrl"] & \
    tI & "'" && tAriaLabel & ">" & sPaginationA["lastLink"] & "</a>" & \
    sPaginationA["lastTagClose"] into tLastLink
  end if
  
  return tLastLink
end _rigLastLink






/*----------------------------------------------------------------------
--| COMMAND rigAjaxPagination
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2014-02-28
--| Last Mod: 2021-03-03
--| Requires: rigLogMessage, rigElapsedTime()
--|
--| Summary: Build and send JSON data used by AJAX pagination script.
--|
--| Format:  rigAjaxPagination param1, param2
--|
--| Parameters: string <pPaginationData>, string <pPaginationLinks>
--|
--| Return: string
----------------------------------------------------------------------*/

command rigAjaxPagination pPaginationData pPaginationLinks
  local tAjax, tJSONpaginationData, tElapsed

  # CHECK IF PAGE REQUEST IS AN XMLHTTP REQUEST
  put rigGetHTTPheader("X-Requested-With") is "XMLHttpRequest" into tAjax

  if tAjax is TRUE then
    # PREPARE QUOTES TO CONFORM WITH JSON
    replace quote with "'" in pPaginationData

    replace quote with "'" in pPaginationLinks
    replace "&quot;" with "\" & quote in pPaginationLinks

    # REMOVE LINEFEEDS / CARRIAGE RETURNS
    put replaceText(pPaginationData,"[\n\r]","") into pPaginationData

    # BUILD JSON OBJECT
    put "{" & quote & "paginationData" & quote & ":" & quote & pPaginationData & quote & comma & quote & "paginationLinks" & quote & ":" & quote & pPaginationLinks & quote & "}" into tJSONpaginationData

    # SEND JSON OBJECT TO BROWSER
    put header "Content-Type: application/json"
    put tJSONpaginationData

    rigLogMessage "debug", "Final AJAX pagination output sent to browser."

  	# PARSE OUT THE ELAPSED TIME AND WE ARE DONE
  	put rigElapsedTime("totalExecutionTime_start", "totalExecutionTime_end", 4) into tElapsed
    rigLogMessage "debug", "Total execution time: " & tElapsed
    exit to top
  end if
end rigAjaxPagination





/*----------------------------------------------------------------------
--| FUNCTION rigAjaxPaginationCode
--|
--| Author: rabit
--| Version:  1.5
--| Created: 2014-02-28
--| Last Mod: 2021-11-06
--| Requires: --
--|
--| Summary: Return AJAX pagination JavaScript code.
--|
--| Format:  rigAjaxPaginationCode([param1])
--|
--| Parameters: string <pNonce> used by CSP headers (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigAjaxPaginationCode pNonce
  local tNonce

  if pNonce <> empty then
    put " nonce=" & quote & pNonce & quote into tNonce
  else if "Contentsecuritypolicy" is among the lines of the stacksInUse then
    put " {{g_ScriptNonce_}}" into tNonce
  end if

	return "<script" & tNonce & ">/* @license magnet:?xt=urn:btih:8e4f440f4c65981c5bf93c76d35135ba5064d8b7&dn=apache-2.0.txt */function switchPage(t){" & quote & "use strict" & quote & ";" & quote & "A" & quote & "!==(t=t||window.event).target.nodeName&&" & quote & "A" & quote & "!==t.target.parentNode.nodeName||" & sPaginationA["widgetName"] & ".clickListener(t," & quote & sPaginationA["linksElementID"] & quote & "," & quote & sPaginationA["dataElementID"] & quote & ")}document.addEventListener(" & quote & "DOMContentLoaded" & quote & ",(function(){" & quote & "use strict" & quote & ";var t=document.getElementById(" & quote & sPaginationA["linksElementID"] & quote & ");t.addEventListener?t.addEventListener(" & quote & "click" & quote & ",switchPage,!1):t.attachEvent&&t.attachEvent(" & quote & "onclick" & quote & ",switchPage)}));var" && sPaginationA["widgetName"] & "={paginationWidget:null,paginationData:null,preventDefault:function(e){" & quote & "use strict" & quote & ";e=e||window.event;document.addEventListener?e.preventDefault():document.attachEvent&&(e.returnValue=!1)},clickListener:function(e,t,n){" & quote & "use strict" & quote & ";e=e||window.event;this.paginationWidget=document.getElementById(t);this.paginationData=document.getElementById(n);if(this.paginationWidget!==null&&this.paginationData!==null){this.preventDefault(e);try{var r=new XMLHttpRequest}catch(i){try{var r=new ActiveXObject(" & quote & "Microsoft.XMLHTTP" & quote & ")}catch(s){var r=null} } if(r!==null){var o=e.target?e.target:e.srcElement;if(o.nodeName!==" & quote & "A" & quote & "){o=o.parentNode;}o.requestTimer=setTimeout(function(){r.abort();" & sPaginationA["widgetName"] & ".writeError(" & quote & "The server timed out while making your request." & quote & ")}," & sPaginationA["ajaxServerTimeout"] & ");r.open(" & quote & "POST" & quote & ",o.href,!0);r.onreadystatechange=function(){if(r.readyState===4){clearTimeout(o.requestTimer);r.status===200||r.status===304?" & sPaginationA["widgetName"] & ".writeData(r.responseText):" & sPaginationA["widgetName"] & ".writeError(" & quote & "The server was unable to be contacted." & quote & ")} }; r.setRequestHeader(" & quote & "Content-Type" & quote & "," & quote & "application/json" & quote & ");r.setRequestHeader(" & quote & "X-Requested-With" & quote & "," & quote & "XMLHttpRequest" & quote & "); r.send(null)} } }, writeData:function(e){" & quote & "use strict" & quote & ";var t=JSON.parse(e);" & sPaginationA["widgetName"] & ".paginationData.innerHTML=t.paginationData;" & sPaginationA["widgetName"] & ".paginationWidget.innerHTML=t.paginationLinks}, writeError:function(e){" & quote & "use strict" & quote & ";alert(e)} };/* @license-end */</script>"
end rigAjaxPaginationCode





/*----------------------------------------------------------------------
--| FUNCTION rigPaginationGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Get pagination array variable value.
--|
--| Format: rigPaginationGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigPaginationGet pWhat
  if pWhat is among the keys of sPaginationA then
    return sPaginationA[pWhat]
  end if

  return empty
end rigPaginationGet




/*----------------------------------------------------------------------
--| COMMAND rigPaginationSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Setter for pagination variables.
--|
--| Format: rigPaginationSet param1, param2
--|
--| Parameters: string <pKey> sPaginationA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigPaginationSet pKey pVal
  if (pKey is among the keys of sPaginationA) or (pKey is among the items of sVarsNoDefaults) then
    put pVal into sPaginationA[pKey]
  end if
end rigPaginationSet








--| END OF Pagination.livecodescript
--| Location:  ./system/libraries/Pagination.livecodescript
----------------------------------------------------------------------
