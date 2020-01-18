script "Benchmark"

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
# revIgniter Benchmark Library
#
# This library enables you to mark points and calculate the time difference
# between them.
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Libraries
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/benchmark.html
##



global gRigA, gMarkerA, g_ElapsedTime_

# DECLARE MEMORY USAGE VARIABLE (CURRENTLY NOT USED)
-- global g_MemoryUsage_

local sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-06
 --| Last Mod: --
 --| Requires: rigLogMessage
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
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack




/*----------------------------------------------------------------------
--| COMMAND rigTimeMark
--|
--| Author: rabit
--| Version:  1.1
--| Created: 05-06-09
--| Last Mod: 17-04-12
--| Requires: --
--|
--| Summary: Set a benchmark marker. Multiple calls to this function can be made
--| 				so that several execution points can be timed.
--| 
--| Format:  rigTimeMark param1
--|
--| Parameters: string <pName>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigTimeMark pName
	put the long seconds into gMarkerA[pName]
end rigTimeMark






/*----------------------------------------------------------------------
--| FUNCTION rigElapsedTime
--|
--| Author: rabit
--| Version:  1.3
--| Created: 05-06-09
--| Last Mod: 17-04-12
--| Requires: --
--|
--| Summary: Calculates the time difference between two marked points.
--|  			   If the first parameter is empty this function instead returns the
--| 	 			 g_ElapsedTime_ variable to be merged. This permits the full system
--| 				 execution time to be shown in a template. The output library will
--| 				 swap the real value for this variable.
--| 
--| Format:  rigElapsedTime(param1, param2, param3)
--|
--| Parameters: string <pPoint1>, string <pPoint2>, integer <pDecimals>
--|
--| Return: float
----------------------------------------------------------------------*/

function rigElapsedTime pPoint1 pPoint2 pDecimals
  local tDecimals, tPoint1Time, tPoint2Time, tElapsedSeconds
  
	if pPoint1 is empty then
		return "[[g_ElapsedTime_]]"
	end if

	if gMarkerA[pPoint1] is empty then
		return ""
	end if

	if gMarkerA[pPoint2] is empty then
		put the long seconds into gMarkerA[pPoint2]
	end if

	if pDecimals is not empty then
		put pDecimals into tDecimals
	else
		put 6 into tDecimals
	end if

	put gMarkerA[pPoint1] into tPoint1Time
	put gMarkerA[pPoint2] into tPoint2Time

	put (tPoint2Time - tPoint1Time) into tElapsedSeconds
	put format("%." & tDecimals & "f", tElapsedSeconds) into tElapsedSeconds

	if pPoint1 is "totalExecutionTime_start" and pPoint2 is "totalExecutionTime_end" then
		put tElapsedSeconds into g_ElapsedTime_
	end if
	return tElapsedSeconds
end rigElapsedTime







/*----------------------------------------------------------------------
--| FUNCTION rigMemoryUsage
--|
--| Author: rabit
--| Version:  To do.
--| Created: --
--| Last Mod: --
--| Requires: --
--|
--| Summary: This function returns the g_MemoryUsage_  variable.
--| 				It can be called  anywhere in a template
--| 				without the memory being calculated until the end.
--| 				The output library will swap the real value for this variable.
--| 
--| Format:  rigMemoryUsage()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

-- function rigMemoryUsage
	-- put TRUE into g_MemoryUsage_
-- end rigMemoryUsage




/*----------------------------------------------------------------------
--| FUNCTION rigFetchMarkers
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-01-10
--| Last Mod: 21-01-10
--| Requires: --
--|
--| Summary: Get the gMarkerA array.
--| 
--| Format:  rigFetchMarkers()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigFetchMarkers
	return gMarkerA
end rigFetchMarkers








--| END OF Benchmark.livecodescript
--| Location:  ./system/libraries/Benchmark.livecodescript
----------------------------------------------------------------------