script "cookieHelper"

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
# revIgniter Cookie Helpers
#
# @package		revIgniter
# @subpackage	Helpers
# @category	  Helpers
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/helpers/cookieHelper.html
##

## ------------------------------------------------------------------------



global gRigA

local sStackInUse



 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-13
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
--| COMMAND rigSetCookie
--|
--| Author: rabit
--| Version:  1.5
--| Created: 2009-05-30
--| Last Mod: 2019-10-17
--| Requires: Input.lc, _rigInputSetCookie
--|
--| Summary: Wrapper for _rigInputSetCookie in Input library. Accepts ten parameters, or you
--| 	         can submit an associative array in the first parameter containing all the values.
--| 				   Please see the User Guide for key names or _rigInputSetCookie in Input.lc.
--|
--| Format:  rigSetCookie param1, param2[, param3][, param4][, param5][, param6][, param7][, param8][, param9][, param10]
--|
--| Parameters: string <pName>, mixed <pValue> can be a string or an array, integer <pExp> (optional), string <pDomain> usually: .yourdomain.com (optional),
--|               string <pPath> (optional), string <pPrefix> (optional), bool <pReplace> (optional), bool <pSecure> (optional), bool <pHttpOnly> (optional),
--|               string <pSameSite> "Strict", "Lax" or "None" (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetCookie pName, pValue, pExp, pDomain, pPath, pPrefix, pReplace, pSecure, pHttpOnly, pSameSite
	_rigInputSetCookie pName, pValue, pExp, pDomain, pPath, pPrefix, pReplace, pSecure, pHttpOnly, pSameSite
end rigSetCookie








/*----------------------------------------------------------------------
--| FUNCTION rigGetCookie
--|
--| Author: rabit
--| Version:  1.6
--| Created: 30-05-09
--| Last Mod: 03-07-16
--| Requires: Input.lc, _rigGetCookies(), rigConfigItem(), rigVarCookie()
--|
--| Summary: Fetch an item from the COOKIE array.
--|
--| Format:  rigGetCookie(param1, param2)
--|
--| Parameters: string <pName>, bool <pXssFlag>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigGetCookie pName pXssFlag
  local tXssFlag, tPrefix, tCookiesArray, tCookieVal, tURLdecodedCookieVal
  local tDecodedCookieVal

	if pXssFlag is empty then
		put FALSE into tXssFlag
	else
		put pXssFlag into tXssFlag
	end if

	put empty into tPrefix
	put _rigGetCookies() into tCookiesArray

	if (pName is not among the keys of tCookiesArray) and (rigConfigItem("cookiePrefix") is not empty) then
		put rigConfigItem("cookiePrefix") into tPrefix
	end if

	put rigVarCookie(tPrefix & pName, pXssFlag) into tCookieVal

  put urlDecode(tCookieVal) into tURLdecodedCookieVal
  if tURLdecodedCookieVal <> false then
    put base64Decode(tURLdecodedCookieVal) into tDecodedCookieVal
		# IF THE VALUE IS MARKED AS ARRAY DECODE IT
    if char 1 to 2 of tDecodedCookieVal is "!a" then
      if (char 1 to 3 of tDecodedCookieVal is ("!a" & numToCodepoint(1))) and (char -3 to -1 of tDecodedCookieVal is (numToCodepoint(1) & "a!")) then
        put arrayDecode(char 4 to -4 of tDecodedCookieVal) into tDecodedCookieVal
      end if
    end if
    return tDecodedCookieVal
  end if

  return false
end rigGetCookie







/*----------------------------------------------------------------------
--| FUNCTION _rigGetCookies
--|
--| Author: Sarah Reichelt
--| Modification: rabit
--| Version:  1.2
--| Created: 30-05-09
--| Last Mod: 13-01-15
--| Requires: --
--|
--| Summary: Fetch all cookies stored for this site / page.
--|
--| Format:  _rigGetCookies()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigGetCookies
  local tCookiesRaw, tCookieName, tCookiesA

	if gRigA["COOKIE"] is not empty then
		put gRigA["COOKIE"] into tCookiesRaw
	else
		put $_SERVER["HTTP_COOKIE"] into tCookiesRaw
	end if

	set the itemDel to "="
	if tCookiesRaw contains ";" then
		set the lineDel to ";"
		repeat for each line cookie in tCookiesRaw
		  put item 1 of cookie into tCookieName
			if char 1 of tCookieName = space then delete char 1 of tCookieName
        put base64Decode(urlDecode(item 2 of cookie)) into tCookiesA[tCookieName]

		end repeat
	else
		put item 1 of tCookiesRaw into tCookieName
		if char 1 of tCookieName = space then delete char 1 of tCookieName
      put base64Decode(urlDecode(item 2 of tCookiesRaw)) into tCookiesA[tCookieName]
	end if

	return tCookiesA
end _rigGetCookies








/*----------------------------------------------------------------------
--| COMMAND rigDeleteCookie
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-05-09
--| Last Mod: 30-05-09
--| Requires: --
--|
--| Summary: Same as rigSetCookie with value and expiration set to empty
--|
--| Format:  rigDeleteCookie param1, param2, param3, param4
--|
--| Parameters: string <pName>, string <pDomain> usually: .yourdomain.com, string <pPath>, string <pPrefix>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDeleteCookie pName, pDomain, pPath, pPrefix
	rigSetCookie pName, "", "", pDomain, pPath, pPrefix
end rigDeleteCookie








--| END OF cookieHelper.livecodescript
--| Location:  ./system/helpers/cookieHelper.livecodescript
----------------------------------------------------------------------