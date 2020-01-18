script "sitelinksHelper"

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
# revIgniter Site Links Helper
#
# @package			revIgniter
# @subpackage	Helpers
# @category	  	Helpers
# @author		  	rabit@revigniter.com
# @link		    		https://revigniter.com/userGuide/helpers/sitelinksHelper.html
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
--| FUNCTION rigSiteLinks
--|
--| Author: rabit
--| Version:  1.3
--| Created: 07-10-09
--| Last Mod: 23-06-16
--| Requires: rigAnchor() -> urlHelper function
--|
--| Summary: Use to write links like footer navigation links or breadcrumbs navigation links.
--| 
--| Format:  rigSiteLinks(param1, param2, param3, param4, param5)
--|
--| Parameters: array <pLinks> links to be parsed, prototype: put "URIsegment" into tLinksArray[integer][linkText],
--|               alternative prototype: put "URIsegment,IDselector" into tLinksArray[integer][linkText]
--|               string <pCurrentPage> name of current page, string <pSep> separator,
--|               string <pDivSel> the div id selector, string <pPsel> the paragraph class selector (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSiteLinks pLinks pCurrentPage pSep pDivSel pPsel
  local tSep, tPsel, tArrayCount, tLinksCode, tLink, tLinkURI
  local tAddID, tLinkID
  
	if pSep is empty then
		put " - " into tSep
	else
		put pSep into tSep
	end if
	
	if pPsel is empty then
		put pDivSel into tPsel
	else
		put pPsel into tPsel
	end if
	
	# LOAD URL HELPER IF NEEDED
	if rigHelperIsLoaded("url") is FALSE then
		rigLoadHelper "url"
	end if

	# BUILD HTML CODE
	if pLinks is an array then
		put the number of lines in the keys of pLinks into tArrayCount

		put "<div id=" & quote & pDivSel & quote & ">" & return & \
				"<p class=" & quote & tPsel & quote & ">" & return into tLinksCode

		repeat with i = 1 to tArrayCount
			put line 1 of the keys of pLinks[i] into tLink
			put pLinks[i][tLink] into tLinkURI

			put FALSE into tAddID
			
			# CHECK IF URI INCLUDES A SELECTOR
			if the number of items of tLinkURI is 2 then
				put TRUE into tAddID
				put item 2 of tLinkURI into tLinkID
				put item 1 of tLinkURI into tLinkURI
			end if
			
		
			if tLink is pCurrentPage then
				if tAddID is TRUE then
					# ADD ID SELECTOR
					put "<span class=" & quote & "currentpage" & quote && "id=" & quote & tLinkID & quote & ">" & pCurrentPage & "</span>" after tLinksCode
				else
					put "<span class=" & quote & "currentpage" & quote & ">" & pCurrentPage & "</span>" after tLinksCode
				end if
			else	
				if tAddID is TRUE then
					# ADD ID SELECTOR
					put rigAnchor(tLinkURI, tLink, "id=" & quote & tLinkID & quote) after tLinksCode
				else
					put rigAnchor(tLinkURI, tLink) after tLinksCode
				end if
			end if

			if i <> tArrayCount then
				put "<span class=" & quote & "separator" & quote & ">" & tSep & "</span>" after tLinksCode
			end if

			put return after tLinksCode
		end repeat

	else
		if pLinks is pCurrentPage then
			put "<span class=" & quote & "currentpage" & quote & ">" & pCurrentPage & "</span>" after tLinksCode
		else		
			put rigAnchor(pLinks, pLinks) after tLinksCode
		end if
	end if

	put "</p>" & return & "</div>" after tLinksCode

	return tLinksCode
end rigSiteLinks










--| END OF sitelinksHelper.livecodescript
--| Location:  ./system/helpers/sitelinksHelper.livecodescript
----------------------------------------------------------------------