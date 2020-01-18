script "downloadHelper"

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
# revIgniter Download Helpers
#
# @package		revIgniter
# @subpackage	Helpers
# @category	  Helpers
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/helpers/downloadHelper.html
##

## ------------------------------------------------------------------------




global gRigA




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-28
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

  if the short name of the target <> the short name of me then
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack






/*----------------------------------------------------------------------
--| COMMAND rigForceDownload
--|
--| Author: rabit
--| Version:  1.2
--| Created: 08-10-09
--| Last Mod: 17-09-15
--| Requires: rigLogMessage, rigFetchMimeType()
--|
--| Summary: Generates headers that force a download to happen.
--| 
--| Format:  rigForceDownload param1, param2
--|
--| Parameters: string <pFileName>, mixed <pData> the data to be downloaded
--|
--| Return: mixed
----------------------------------------------------------------------*/

command rigForceDownload pFileName pData
  local tExtension, tMime, tDataLength
  
	if (pFileName is empty) or (pData is empty) then
		return FALSE
	end if

	# TRY TO DETERMINE IF THE FILENAME INCLUDES A FILE EXTENSION.
	# WE NEED IT IN ORDER TO SET THE MIME TYPE
	if "." is not in pFileName then
		return FALSE
	end if

	# GRAB THE FILE EXTENSION
	set the itemDel to "."
	put item -1 of pFileName into tExtension

	# LOAD THE MIME TYPES
	try
		_rigRequire gRigA["APPPATH"] & "config/mimes" & gRigA["EXT"]
	catch err
		rigLogMessage "error", "An error occured while trying to include file:" && "mimes" & gRigA["EXT"]
		return FALSE
	end try

	# SET A DEFAULT MIME IF WE CAN'T FIND IT
	put rigFetchMimeType(tExtension) into tMime
	if (tMime is empty) or (tMime is FALSE) then
		put "application/octet-stream" into tMime
	else
		if tMime is an array then
			put tMime[1] into tMime
		end if
	end if

	# GENERATE THE SERVER HEADERS
	put the length of pData into tDataLength
	if "MSIE" is in $_SERVER["HTTP_USER_AGENT"] then
		put header "Content-Type:" && quote & tMime & quote
		put header "Content-Disposition: attachment; filename=" & quote & pFileName & quote
		put header "Expires: 0"
		put header "Cache-Control: must-revalidate, post-check=0, pre-check=0"
		put header "Content-Transfer-Encoding: binary"
		put header "Pragma: public"
		put header "Content-Length:" && tDataLength
	else
		put header "Content-Type:" && quote & tMime & quote
		put header "Content-Disposition: attachment; filename=" & quote & pFileName & quote
		put header "Content-Transfer-Encoding: binary"
		put header "Expires: 0"
		put header "Pragma: no-cache"
		put header "Content-Length:" && tDataLength
	end if

	put pData
end rigForceDownload











--| END OF downloadHelper.livecodescript
--| Location:  ./system/helpers/downloadHelper.livecodescript
----------------------------------------------------------------------