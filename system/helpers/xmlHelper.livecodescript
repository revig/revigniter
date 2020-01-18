script "xmlHelper"

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
# revIgniter XML Helpers
#
# @package		revIgniter
# @subpackage	Helpers
# @category	  Helpers
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/helpers/xmlHelper.html
##

## ------------------------------------------------------------------------




global gRigA

local sStackInUse





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-25
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
--| FUNCTION rigXmlConvert
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-10-09
--| Last Mod: 2010-01-07
--| Requires: rigPregReplace()
--|
--| Summary: Convert reserved XML characters to Entities.
--| 
--| Format:  rigXmlConvert(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigXmlConvert pStr
  local tTemp, tRegEx, tStr
  
  put "__TEMP_AMPERSANDS__" into tTemp

  # REPLACE ENTITIES TO TEMPORARY MARKERS SO THAT 
  # AMPERSANDS WON'T GET MESSED UP
  put "(&#\d+);" into tRegEx
  put rigPregReplace(pStr, tRegEx, "&#", tTemp) into tStr

  put "(&\w+);" into tRegEx
  put rigPregReplace(tStr, tRegEx, "&", tTemp) into tStr

  replace "&" with "&amp;" in tStr
  replace "<" with "&lt;" in tStr
  replace ">" with "&gt;" in tStr
  replace "'" with "&#39;" in tStr
  replace quote with "&quot;" in tStr
  replace "-" with "&#45;" in tStr

  # DECODE THE TEMP MARKERS BACK TO ENTITIES
  put "(" & tTemp & "\d+);" into tRegEx
  put rigPregReplace(tStr, tRegEx, tTemp, "&#") into tStr

  put "(" & tTemp & "\w+);" into tRegEx
  put rigPregReplace(tStr, tRegEx, tTemp, "&") into tStr

  return tStr
end rigXmlConvert












--| END OF xmlHelper.livecodescript
--| Location:  ./system/helpers/xmlHelper.livecodescript
----------------------------------------------------------------------