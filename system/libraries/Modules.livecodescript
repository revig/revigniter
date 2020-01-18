script "Modules"

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
# revIgniter Modules Library
#
# This library is needed to provide HMVC functionality.
#
#
# @package		  revIgniter
# @subpackage	Libraries
# @category	     Libraries
# @author		     rabit@revigniter.com
# @link		       https://revigniter.com/userGuide/libraries/modules.html
##




global gRigA, gModuleHandlers, gModulesHandlersA

local sModuleSegments, sStackInUse





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-22
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

  if the short name of the target = the short name of me then
    if sStackInUse <> TRUE then
      put TRUE into sStackInUse

      # LOGGING
      if the environment is "server" then
        rigLogMessage "debug", "Modules Library Loaded"
      end if
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack







/*----------------------------------------------------------------------
--| COMMAND rigRunInitialModulesConfig
--|
--| Author: rabit
--| Version:  1.0
--| Created: 16-11-15
--| Last Mod: 16-11-15
--| Requires: rigInitModules
--|
--| Summary: Run initial configuration procedures. Don't remove, even if it does nothing.
--| 
--| Format:  rigRunInitialModulesConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialModulesConfig pConfig
	# Code...
end rigRunInitialModulesConfig






/*----------------------------------------------------------------------
--| COMMAND _rigRegisterModuleHandlers
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-11-2015
--| Last Mod: 18-11-2015
--| Requires: --
--|
--| Summary: Remove whitespace from handlers list and store it in an array.
--| 
--| Format:  _rigRegisterModuleHandlers param1, param2
--|
--| Parameters: string <pModule>, string <pHandlers> a comma delimited list
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigRegisterModuleHandlers pModule pHandlers
	put replacetext(pHandlers,"[ ]+","") into gModulesHandlersA[pModule]
end _rigRegisterModuleHandlers






/*----------------------------------------------------------------------
--| COMMAND rigLoadModule
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-11-2015
--| Last Mod: 26-12-2015
--| Requires: rigTrim(), _rigValidateModuleRequest(), rigLogMessage, rigLoadConfigFile(),
--|            rigLoadAutoLoad, rigFetchDirectory(), _rigRegisterModuleHandlers, _rigDo
--|
--| Summary: Used to load a module controller within an application controller or within a module.
--| 
--| Format:  rigLoadModule param1
--|
--| Parameters: string <pModuleSegments>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigLoadModule pModuleSegments
  local tSegmentsArray, tModule, tController, tControllerPath
  
  put rigTrim(pModuleSegments, "/") into pModuleSegments
  put pModuleSegments into tSegmentsArray
  split tSegmentsArray by "/"
  put _rigValidateModuleRequest(tSegmentsArray) into tSegmentsArray
  
  if tSegmentsArray is FALSE then
  	# THE SEGMENTS DO NOT CORRELATE TO A VALID MODULE
    put "404" into gModulesHandlersA[pModuleSegments]["error"]
    rigLogMessage "error", "Segments did not correlate to a valid module. Could not load module: " & pModuleSegments

    return FALSE
    
  else -- if tSegmentsArray is FALSE then
    set the itemDel to "/"
    
    put item 1 of pModuleSegments into tModule
    
    # LOAD ASSOCIATED CONFIG FILE IF AVAILABLE
    get rigLoadConfigFile(, TRUE, TRUE, tModule)

    # LOAD ASSOCIATED AUTOLOAD FILE IF AVAILABLE
    rigLoadAutoLoad tModule, TRUE
    
    put item -1 of pModuleSegments into tController
    
    # LOAD MODULE CONTROLLER AND STORE CONTROLLER HANDLER NAMES IN AN ARRAY
    put rigFetchDirectory() & tController & gRigA["EXT"] into tControllerPath
    _rigRequire gRigA["APPPATH"] & tControllerPath

    rigLogMessage "debug", "Module loaded: " & pModuleSegments

    _rigRegisterModuleHandlers pModuleSegments, gModuleHandlers
    
    # RUN THE CONTROLLER'S MAIN HANDLER PROVIDED THAT IT EXISTS
    _rigDo tController, pModuleSegments
  end if
  
  return TRUE
end rigLoadModule






/*----------------------------------------------------------------------
--| FUNCTION rigRunModule
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-11-2015
--| Last Mod: 26-12-2015
--| Requires: rigTrim(), _rigModuleError(), _rigGetViewPath(), _rigSetViewPath, _rigDo
--|
--| Summary: Return output (a view) or a return value from a module controller.
--| 
--| Format:  rigRunModule(param1[, param2])
--|
--| Parameters: string <pModuleSegments>, array <pParamsA> (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigRunModule pModuleSegments pParamsA
  local tCallIndex, tModule, tNumSegments, tHandler, tError
  local tCurrentViewPath, tTempViewPath, tModuleData
  
  put rigTrim(pModuleSegments, "/") into sModuleSegments

  set the itemDel to "/"

  # CHECK IF A CONTROLLER HANDLER IS SPECIFIED
  # IF NOT CALL THE DEFAULT (index) HANDLER
  if sModuleSegments is among the keys of gModulesHandlersA then
    put TRUE into tCallIndex
    put sModuleSegments into tModule
    
  else
    put FALSE into tCallIndex
  end if

  # GET MODULE AND CONTROLLER HANDLER TO BE CALLED
  if tCallIndex is FALSE then
    put the number of items of sModuleSegments into tNumSegments
    
    switch tNumSegments
      case 2
        # CONTROLLER IS IN controllers ROOT AND NAME OF FILE IS IDENTICAL TO MODULE FOLDER NAME
        put item 2 of sModuleSegments into tHandler
        put item 1 of sModuleSegments into tModule
      break
      
      case 3
        if (item 1 of sModuleSegments & "/" & item 2 of sModuleSegments) is among the keys of gModulesHandlersA then
          # CONTROLLER IS IN controllers ROOT AND NAME OF FILE IS NOT IDENTICAL TO MODULE FOLDER NAME
          put item 3 of sModuleSegments into tHandler
          put item 1 to 2 of sModuleSegments into tModule
        else
          # CONTROLLER IS IN controllers ROOT AND NAME OF FILE IS IDENTICAL TO MODULE FOLDER NAME
          put item 2 of sModuleSegments into tHandler
          -- put item 3 of sModuleSegments into sModuleParamSegments
          put item 1 of sModuleSegments into tModule
        end if
      break
      
      default
      # tNumSegments > 3
      if (item 1 of sModuleSegments & "/" & item 2 of sModuleSegments & "/" & item 3 of sModuleSegments) is among the keys of gModulesHandlersA then
        # CONTROLLER IS IN A SUB-FOLDER
        put item 4 of sModuleSegments into tHandler
        put item 1 to 3 of sModuleSegments into tModule
        -- if tNumSegments > 4 then
        --   put item 5 to tNumSegments of sModuleSegments into sModuleParamSegments
        -- end if
        
        else if (item 1 of sModuleSegments & "/" & item 2 of sModuleSegments) is among the keys of gModulesHandlersA then
          # CONTROLLER IS IN controllers ROOT AND NAME OF FILE IS NOT IDENTICAL TO MODULE FOLDER NAME
          put item 3 of sModuleSegments into tHandler
          -- put item 4 to tNumSegments of sModuleSegments into sModuleParamSegments
          put item 1 to 2 of sModuleSegments into tModule
          
        else
          # CONTROLLER IS IN controllers ROOT AND NAME OF FILE IS IDENTICAL TO MODULE FOLDER NAME
          put item 2 of sModuleSegments into tHandler
          -- put item 3 to tNumSegments of sModuleSegments into sModuleParamSegments
          put item 1 of sModuleSegments into tModule
      end if
    end switch
    
  else -- if tCallIndex is FALSE then
    put (item -1 of sModuleSegments) & "Index" into tHandler
  end if -- if tCallIndex is FALSE then
    
  # BEFORE CALLING ANY MODULE HANDLER CHECK IF THERE WAS AN ERROR WHILE LOADING THE MODULE
  put _rigModuleError(tModule) into tError
  if tError <> FALSE then
    return tError
  end if

  # CHANGE VIEW PATH TO MODULE VIEW PATH
  put _rigGetViewPath() into tCurrentViewPath
  put gRigA["APPPATH"] & "modules/" & (item 1 of sModuleSegments) & "/views/" into tTempViewPath
  _rigSetViewPath tTempViewPath

  # CALL MODULE HANDLER AND RESET VIEW PATH
  _rigDo tHandler, tModule, pParamsA
  
  put the result into tModuleData
  _rigSetViewPath tCurrentViewPath
  
  return tModuleData
end rigRunModule





/*----------------------------------------------------------------------
--| FUNCTION _rigModuleError
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-11-2015
--| Last Mod: 22-11-2015
--| Requires: rigLogMessage
--|
--| Summary: Get error data in case module failed to load.
--| 
--| Format: _rigModuleError(param1)
--|
--| Parameters: string <pModule>
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigModuleError pModule
  local tErrorStr
  
  if gModulesHandlersA[pModule]["error"] is "404" then
  	# THE SEGMENTS DO NOT CORRELATE TO A VALID MODULE
    put "Segments did not correlate to a valid module. Could not run module: " & pModule into tErrorStr
    rigLogMessage "error", tErrorStr
    return tErrorStr
  end if
  
  return FALSE
end _rigModuleError





/*----------------------------------------------------------------------
--| FUNCTION rigFetchModuleSegment
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-11-15
--| Last Mod: 26-12-15
--| Requires: --
--|
--| Summary: This function returns the URI segment, or URI value based on the number provided.
--| 
--| Format: rigFetchModuleSegment(param1[, param2])
--|
--| Parameters: integer <pSegmentNum>, string <pNoResult> (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigFetchModuleSegment pSegmentNum pNoResult
  local tNoResult, tModuleSegments
  
  if pNoResult is "" then
    put FALSE into tNoResult
  else
    put pNoResult into tNoResult
  end if
  
  put sModuleSegments into tModuleSegments
  split tModuleSegments by "/"

  if pSegmentNum is among the keys of tModuleSegments then
    return tModuleSegments[pSegmentNum]
  end if
  
  return tNoResult
end rigFetchModuleSegment




/*----------------------------------------------------------------------
--| FUNCTION rigModuleUriToAssoc
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-12-15
--| Last Mod: 26-12-015
--| Requires: _rigModuleUriToAssoc()
--|
--| Summary: Generate a key value pair from the URI string.
--|
--|            This function generates an associative array of module URI data starting
--|            at the supplied segment. For example, if this is your URI:
--|
--|            myModule/myModuleHandler/name/joe/location/UK/gender/male
--|
--|            You can use this function to generate an array with this prototype:
--|
--|            tArray["name] =>value = "joe"
--|            tArray["location] =>value = "UK"
--|            tArray["gender] =>value = "male"
--| 
--| Format:  rigModuleUriToAssoc(param1[, param2])
--|
--| Parameters: integer <pN> the starting segment number, array <pDefaultA> an array of default values (optional)
--|
--| Return: array
----------------------------------------------------------------------*/

function rigModuleUriToAssoc pN pDefaultA
  local tN
  
	if pN is empty then
		put 3 into tN
	else
		put pN into tN
	end if

	return _rigModuleUriToAssoc(tN, pDefaultA)
end rigModuleUriToAssoc






/*----------------------------------------------------------------------
--| FUNCTION _rigModuleUriToAssoc
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-12-15
--| Last Mod: 26-12-15
--| Requires: _rigModuleSegmentsArray()
--|
--| Summary: Generate key value pairs from the module URI string.
--| 
--| Format:  _rigModuleUriToAssoc(param1[, param2])
--|
--| Parameters: integer <pN> the starting segment number, array <pDefaultA> an array of default values (optional)
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigModuleUriToAssoc pN pDefaultA
  local tN, tTotalSegments, tSegmentsArray, tKey, tVal, tRetval
  local tSegmNum, tK, tSlicedArray, tIncr, tI, tLastVal
  
  if pN is empty then
    put 3 into tN
  else
    put pN into tN
  end if

  set the itemDel to "/"
  
  put the number of items of sModuleSegments into tTotalSegments
  put _rigModuleSegmentsArray() into tSegmentsArray

  if tN is not an integer then
    return pDefaultA
  end if

  # WRONG SEGMENT NUMBER
  if tTotalSegments < tN then
    if pDefaultA is not an array then
      return ""
    end if

    repeat for each key tKey in pDefaultA
      put pDefaultA[tKey] into tVal

      put FALSE into tRetval[tVal]
    end repeat

    return tRetval
  end if

  # SLICE ARRAY
  put the number of lines in the keys of tSegmentsArray into tSegmNum
  repeat with i = tN to tSegmNum
    put i - (tN - 1) into tK
    put tSegmentsArray[i] into tSlicedArray[tK]
  end repeat

  put 0 into tIncr
  put 0 into tI
  put "" into tLastVal
	
  repeat for each key tKey in tSlicedArray
    add 1 to tIncr

    put tSlicedArray[tIncr] into tVal

    if (tI mod 2) is not 0 then
      put tVal into tRetval[tLastVal]
    else
      put FALSE into tRetval[tVal]
      put tVal into tLastVal
    end if
    add 1 to tI
  end repeat	

  if (the number of lines in the keys of pDefaultA) > 0 then
    repeat for each key tKey in pDefaultA
      put pDefaultA[tKey] into tVal

      if tVal is not among the keys of tRetval then
        put FALSE into tRetval[tVal]
      end if
    end repeat
  end if

  return tRetval
end _rigModuleUriToAssoc






/*----------------------------------------------------------------------
--| FUNCTION _rigModuleSegmentsArray
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-12-15
--| Last Mod: 01-12-15
--| Requires: rigTrim()
--|
--| Summary:  Explode the module URI segments.
--| 
--| Format:  _rigModuleSegmentsArray
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigModuleSegmentsArray
  local tIncr, tNumKeys, tItem, tTempStr, tSegmentsA
  
  put 0 into tIncr
  put 0 into tNumKeys
  set the itemDelimiter to "/"
  
  repeat for each item tItem in sModuleSegments
    add 1 to tIncr

    put item tIncr of sModuleSegments into tTempStr

    # TRIM WHITESPACE
    put rigTrim(tTempStr) into tTempStr
    
    if tTempStr <> "" then
      add 1 to tNumKeys
      put tTempStr into tSegmentsA[tNumKeys]
    end if
  end repeat
  
  return tSegmentsA
end _rigModuleSegmentsArray





/*----------------------------------------------------------------------
--| FUNCTION rigModulesGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Get sModuleSegments variable value.
--| 
--| Format: rigModulesGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigModulesGet pWhat
  if (pWhat is "moduleSegments") or (pWhat is "sModuleSegments") then
    return sModuleSegments
  end if
   
  return empty
end rigModulesGet




/*----------------------------------------------------------------------
--| COMMAND rigModulesSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Setter for sModuleSegments variable.
--| 
--| Format: rigModulesSet param1, param2
--|
--| Parameters: string <pKey>, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigModulesSet pKey pVal
  if (pKey is "moduleSegments") or (pKey is "sModuleSegments") then
    put pVal into sModuleSegments
  end if
end rigModulesSet








--| END OF Modules.livecodescript
--| Location:  ./system/libraries/Modules.livecodescript
----------------------------------------------------------------------