script "Log"

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
# revIgniter Logging Library
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Logging
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/general/errors.html
##

## ------------------------------------------------------------------------



global gRigA, gConfig

local sLogA, sStackInUse







 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-10
 --| Last Mod: --
 --| Requires: _rigSetDefaultValues
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
    end if
    
    # SET INITIAL VALUES
    _rigSetDefaultValues
    #
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
  put 1 into sLogA["logLevels"]["ERROR"]
  put 2 into sLogA["logLevels"]["DEBUG"]
  put 3 into sLogA["logLevels"]["INFO"]
  put 4 into sLogA["logLevels"]["ALL"]

  # GET LOG PATH
  if gConfig["log_path"] is not empty then
  	put gConfig["log_path"] into sLogA["logPath"]
  else
  	put gRigA["APPPATH"] & "logs/" into sLogA["logPath"]
  end if

  if there is a folder sLogA["logPath"] then
  	put TRUE into sLogA["logEnabled"]
  else
  	put FALSE into sLogA["logEnabled"]
  end if

  if gConfig["logThreshold"] is an integer then
  	put gConfig["logThreshold"] into sLogA["logThreshold"]
  else
  	put 1 into sLogA["logThreshold"]
  end if
end _rigSetDefaultValues





/*----------------------------------------------------------------------
--| COMMAND rigWriteLog
--|
--| Author: rabit
--| Version:  1.7
--| Created: 29-06-09
--| Last Mod: 02-02-15
--| Requires: rigFetchSegment(), rigShow404 in Common.lc, rigLoadLibrary, rigShowErrorPage(), rigLogMessage
--|
--| Summary: Write Log File. Generally this command will be called using the rigLogMessage command.
--| 
--| Format:  rigWriteLog param1, param2, param3
--|
--| Parameters: string <pLevel>, string <pMessage>, bool <pDisplayError>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigWriteLog pLevel, pMessage, pDisplayError
  local tLevel, tTimeZone, tOldTZ, tIntDate, tShortDate, tMonth, tDay
  local tCurrentLogFile, tLogFilePath, tCurrentLog, tSegmentOne
  local tSegmentTwo, tURI, tHeading
  
  if sLogA["logEnabled"] is FALSE then exit rigWriteLog
    
  put toUpper(pLevel) into tLevel

  if sLogA["logLevels"][tLevel] > sLogA["logThreshold"] then
    exit rigWriteLog
  end if

  if pDisplayError is not TRUE and "error404" is not in pMessage then

    # CONVERT DATE IF THERE IS A TIME ZONE SET IN THE CONFIG FILE
    put empty into tTimeZone
    if gConfig["timeZone"] is not "" then
      # A SIMPLE CHECK IF THE FORMAT IS CORRECT
      if "/" is in gConfig["timeZone"] then
        put gConfig["timeZone"] into tTimeZone
      end if
    end if

    if tTimeZone is not empty then
      # DON'T LEAVE PERMANENT CHANGES TO GLOBAL
      # STATE BY STORING THE CURRENT VALUE OF THE $TZ ENVIRONMENT VARIABLE
      put $TZ into tOldTZ

      put tTimeZone into $TZ

      put shell("date '+%a, %d %b %G %T %z'") into tIntDate
      filter tIntDate with "*" -- removes the linefeed

      # RESTORE THE PREVIOUS VALUE OF $TZ
      put tOldTZ into $TZ

    else
      put the internet date into tIntDate
    end if

    # LOG ERROR
    put the short date into tShortDate

    set the itemdelimiter to "/"
  
    put item 1 of tShortDate into tMonth
    if the length of tMonth = 1 then
      put "0" & tMonth into tMonth
    end if
  
    put item 2 of tShortDate into tDay
    if the length of tDay = 1 then
      put "0" & tDay into tDay
    end if
  
    put "log-20" & (item 3 of tShortDate) & "-" & tMonth & "-" & tDay & ".txt" into tCurrentLogFile

    put sLogA["logPath"] & tCurrentLogFile into tLogFilePath
    if there is a file tLogFilePath then
      put URL ("binfile:" & tLogFilePath) into tCurrentLog
        
      if the result <> empty then
        rigLogMessage "error", "Failed to read file! System error:" && the sysError
      end if
        
      put tLevel && "-" && tIntDate & ":" && pMessage & return after tCurrentLog
      put tCurrentLog into URL ("binfile:" & tLogFilePath)
        
      if the result <> empty then
        rigLogMessage "error", "Failed to write to file! System error:" && the sysError
      end if
    else
      put tLevel && "-" && tIntDate & ":" && pMessage & return into tCurrentLog
      put tCurrentLog into URL ("binfile:" & tLogFilePath)
        
      if the result <> empty then
        rigLogMessage "error", "Failed to write to file! System error:" && the sysError
      end if
    end if -- if there is a file tLogFilePath then
  else --if pDisplayError is not TRUE and "error404" is not in pMessage then
    if "error404" is in pMessage then
      # GET REQUESTED URI SEGMENTS
      put rigFetchSegment(1) into tSegmentOne
      if tSegmentOne is FALSE then
        put "default" into tSegmentOne
      end if

      put rigFetchSegment(2) into tSegmentTwo
      if tSegmentTwo is FALSE then
        put "index" into tSegmentTwo
      end if
      put tSegmentOne & "/" & tSegmentTwo into tURI

      # SHOW 404 ERROR PAGE
      rigShow404 tURI
    else
      # DISPLAY ERROR
      rigLoadLibrary "Exceptions"
      replace CR with "<br />" in pMessage
      put "Error" into tHeading
      put rigShowErrorPage(tHeading, pMessage, "errorGeneral")
      exit to top
    end if
  end if
end rigWriteLog





/*----------------------------------------------------------------------
--| FUNCTION rigLogGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Get log array variable value.
--| 
--| Format: rigLogGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigLogGet pWhat
  if pWhat is among the keys of sLogA then
    return sLogA[pWhat]
  end if
   
  return empty
end rigLogGet




/*----------------------------------------------------------------------
--| COMMAND rigLogSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Setter for log variables.
--| 
--| Format: rigLogSet param1, param2
--|
--| Parameters: string <pKey> sLogA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLogSet pKey pVal
  if pKey is among the keys of sLogA then
    put pVal into sLogA[pKey]
  end if
end rigLogSet







--| END OF Log.livecodescript
--| Location:  ./system/libraries/Log.livecodescript
----------------------------------------------------------------------