script "Router"

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
# revIgniter Router Library
#
# Parses URIs and determines routing
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Libraries
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/routing.html
##



global gRigA, gRoute, gModulesHandlersA

local sStackInUse, sRouterA -- array keys are: routes, defaultController, directory, scaffoldingRequest, moduleRoutes, moduleMainController




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-11-30
 --| Last Mod: --
 --| Requires: rigLogMessage, _rigSetRouting
 --|
 --| Summary:  Run security check and initial routines.
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
        rigLogMessage "debug", "Router Library Loaded"
      end if

      # CALL INITIAL HANDLERS
      _rigSetRouting
    end if

  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack




 /*----------------------------------------------------------------------
 --| COMMAND releaseStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-11-30
 --| Last Mod: --
 --| Requires: --
 --|
 --| Summary:  Run farewell routines.
 --|
 --| Parameters: --
 --|
 --| Return: empty
 ----------------------------------------------------------------------*/

-- on releaseStack
--   if the short name of the target = the short name of me then
--     -- PUT CLEANUP STUFF HERE
--
--   else
--     pass releaseStack
--   end if
-- end releaseStack




 /*----------------------------------------------------------------------
 --| COMMAND _rigSetRouting
 --|
 --| Author: rabit
 --| Version:  1.9
 --| Created: 2009-06-19
 --| Last Mod: 2020-03-11
 --| Requires: rigFetchConfigItem(), _rigFilterUri, rigTrim(), rigSetController, rigSetHandler, _rigExplodeSegments,
 --|           _rigSetRouting, _rigValidateQueryRequest(), _rigFetchUriString, rigShowError, _rigSetRequest,
 --|					 rigLogMessage, _rigRemoveUrlSuffix, _rigParseRoutes
 --|
 --| Summary:  Set the route mapping
 --|           This command determines what should be served based on the URI request,
 --|           as well as any "routes" that have been set in the routing config file.
 --|
 --| Format:  _rigSetRouting
 --|
 --| Parameters: --
 --|
 --| Return: empty
 ----------------------------------------------------------------------*/

private command _rigSetRouting
  local tFilteredStrippedString, tUriString, tModule, tX, tController, tTempArray
  local tRoutesFilePath

  ## ARE QUERY STRINGS ENABLED IN THE CONFIG FILE?
  ## IF SO, WE'RE DONE SINCE SEGMENT BASED URIS ARE NOT USED WITH QUERY STRINGS.
  if (rigFetchConfigItem("enableQueryStrings") is TRUE) \
    and ($_GET[rigFetchConfigItem("controllerTrigger")] is not empty) \
    and (gRigA["CLI"] <> TRUE) then
    put _rigFilterUri($_GET[rigFetchConfigItem("controllerTrigger")]) into tFilteredStrippedString

    # TRIM WHITESPACE
    put rigTrim(tFilteredStrippedString) into tFilteredStrippedString

    rigSetController tFilteredStrippedString

    if $_GET[rigFetchConfigItem("handlerTrigger")] is not empty then
      put _rigFilterUri($_GET[rigFetchConfigItem("handlerTrigger")]) into tFilteredStrippedString
      # TRIM WHITESPACE
      put rigTrim(tFilteredStrippedString) into tFilteredStrippedString
      rigSetHandler tFilteredStrippedString
    else
      rigSetHandler "index"
    end if

    get _rigValidateQueryRequest(gRigA["controller"], gRigA["handler"])

    # COMPILE THE URI KEY VALUE PAIRS INTO AN ARRAY -- variance
    _rigExplodeSegments

    exit _rigSetRouting
  end if

  # FETCH THE COMPLETE URI STRING
  put _rigFetchUriString() into tUriString
  put rigTrim(tUriString, "/") into tUriString

  put empty into gRigA["module"]
  put empty into tModule
  set the itemDelimiter to "/"

   # ARE WE DEALING WITH A MODULE?
   if there is a folder (gRigA["APPPATH"] & "modules/" & item 1 of tUriString) then
     put item 1 of tUriString into tModule
     put tModule into gRigA["module"]
   end if

  # LOAD THE routes.lc FILE.
  if tModule <> empty then
    -- if there is a file (gRigA["APPPATH"] & "modules/" & tModule & "/config/routes.livecodescript") then
    put gRigA["APPPATH"] & "modules/" & tModule & "/config/routes" & gRigA["EXT"] into tRoutesFilePath
    if there is a file tRoutesFilePath then
      -- start using stack (gRigA["APPPATH"] & "modules/" & tModule & "/config/routes.livecodescript")
      _rigRequire tRoutesFilePath
      put gRoute[tModule] into sRouterA["moduleRoutes"]
    end if
  else
    -- start using stack (gRigA["APPPATH"] & "config/routes.livecodescript")
    _rigRequire (gRigA["APPPATH"] & "config/routes" & gRigA["EXT"])
    put gRoute into sRouterA["routes"]
  end if

  # SET THE DEFAULT CONTROLLER SO WE CAN DISPLAY IT IN THE EVENT
  # THE URI DOESN'T CORRELATE TO A VALID CONTROLLER.
  if tModule <> empty then
    if sRouterA["moduleRoutes"] is an array then
      if sRouterA["moduleRoutes"][1]["defaultController"] is "" then

        if item -1 of tUriString is tModule then
          put tUriString into sRouterA["defaultController"]
        else
          put FALSE into sRouterA["defaultController"]
        end if
      else
        put sRouterA["moduleRoutes"][1]["defaultController"] into sRouterA["defaultController"]
      end if
    else
      put FALSE into sRouterA["defaultController"]
    end if
  else
   	if sRouterA["routes"][1]["defaultController"] is "" then
   		put FALSE into sRouterA["defaultController"]
   	else
      put sRouterA["routes"][1]["defaultController"] into sRouterA["defaultController"]
   	end if
  end if -- if tModule <> empty then

  # IS THERE AN URI STRING? IF NOT, THE DEFAULT CONTROLLER SPECIFIED IN THE "ROUTES" FILE WILL BE SHOWN.
  if (tUriString is "") or ((item -1 of tUriString is tModule) and (sRouterA["defaultController"] <> tUriString)) then
  	if sRouterA["defaultController"] is FALSE then
  		rigShowError "Unable to determine what should be displayed. A default route has not been specified in the routing file."
  	end if

    if sRouterA["defaultController"] contains "/" then
      put sRouterA["defaultController"] into tX
      put item -1 of tX into tController
      rigSetController tController
      rigSetHandler tModule & "Index"
      split tX by "/"
      _rigSetRequest tX
  	else
      rigSetController sRouterA["defaultController"]
      rigSetHandler tModule & "Index"
      put sRouterA["defaultController"] into tTempArray[1]
      put tModule & "Index" into tTempArray[2]
      _rigSetRequest tTempArray
  	end if

  	rigLogMessage "debug", "No URI present. Default controller set."
  	exit _rigSetRouting
  end if

  if tModule <> empty then
    delete variable sRouterA["moduleRoutes"][1]["defaultController"]
  else
    delete variable sRouterA["routes"][1]["defaultController"]
  end if

  # DO WE NEED TO REMOVE THE URL SUFFIX?
  _rigRemoveUrlSuffix

  # COMPILE THE SEGMENTS INTO AN ARRAY
  _rigExplodeSegments

  # PARSE ANY CUSTOM ROUTING THAT MAY EXIST
  _rigParseRoutes

end _rigSetRouting





/*----------------------------------------------------------------------
--| FUNCTION rigScaffoldingRequest
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-10-09
--| Last Mod: 27-10-09
--| Requires: --
--|
--| Summary: Return rigScaffolding request flag.
--|
--| Format:  rigScaffoldingRequest()
--|
--| Parameters: --
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigScaffoldingRequest
	return sRouterA["scaffoldingRequest"]
end rigScaffoldingRequest








/*----------------------------------------------------------------------
--| COMMAND _rigSetRequest
--|
--| Author: rabit
--| Version:  1.4
--| Created: 19-06-09
--| Last Mod: 08-12-15
--| Requires: _rigValidateRequest(), rigSetController, rigSetHandler
--|
--| Summary:  Set the Route.
--|             This handler takes an array of URI segments as
--|             input, and sets the current controller/handler
--|
--| Format:  _rigSetRequest param1
--|
--| Parameters: array <pSegmentsArray>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetRequest pSegmentsArray
  local tSegmentsArray

	put _rigValidateRequest(pSegmentsArray) into tSegmentsArray

	if (the number of lines in the keys of tSegmentsArray) = 0 then
		exit _rigSetRequest
	end if

  set the itemDel to "/"

	rigSetController tSegmentsArray[1]

	if tSegmentsArray[2] <> empty then
    # IS THIS A SCAFFOLDING REQUEST? NO FUNNY BUSINESS WITH THE URL
    # DON'T ALLOW SCAFFOLDING USING MODULES
    if (sRouterA["routes"][1]["scaffoldingTrigger"] = tSegmentsArray[2]) and (sRouterA["moduleRoutes"] is not an array) then
      put TRUE into sRouterA["scaffoldingRequest"]
      delete variable sRouterA["routes"][1]["scaffoldingTrigger"]
		else

      # MAYBE A MODULE CONTROLLER IS USED AS AN APPLICATION CONTROLLER
      if (item 1 of sRouterA["directory"] is "modules") and (gModulesHandlersA is not an array) and (the number of items of sRouterA["directory"] < 4) then
        # AND CONTROLLER IS LOCATED AT THE ROOT OF THE CONTROLLERS FOLDER
        if sRouterA["moduleMainController"] <> TRUE then
          # CONTROLLER NAME IS NOT IDENTICAL WITH MODULE NAME
          rigSetController tSegmentsArray[2]
        else
          # CONTROLLER NAME IS IDENTICAL WITH MODULE NAME
          rigSetController tSegmentsArray[1]
        end if

        if tSegmentsArray[3] is empty then
          if sRouterA["moduleMainController"] <> TRUE then
            # NO HANDLER SPECIFIED, USE DEFAULT CONTROLLER, PREFIX index WITH CONTROLLER NAME
            rigSetHandler tSegmentsArray[2] & "Index"
          else
            # HANDLER SPECIFIED
            rigSetHandler tSegmentsArray[2]
          end if

        else
          # HANDLER SPECIFIED
          rigSetHandler tSegmentsArray[3]
        end if

      else
      	# A STANDARD CONTROLLER REQUEST
				rigSetHandler tSegmentsArray[2]
		  end if -- if (item 1 of sRouterA["directory"] is "modules") and (gModulesHandlersA is not an array) and (the number of items of sRouterA["directory"] < 4) then
      ##
    end if -- if sRouterA["routes"][1]["scaffoldingTrigger"] = tSegmentsArray[2] then

    else -- if tSegmentsArray[2] <> empty then
		# THIS LETS THE "ROUTED" SEGMENT ARRAY IDENTIFY THAT THE DEFAULT
		# INDEX HANDLER IS BEING USED.

    # IF A MODULE CONTROLLER IS USED AS AN APPLICATION CONTROLLER
    # PREFIX index WITH CONTROLLER NAME
    if (item 1 of sRouterA["directory"] is "modules") and (gModulesHandlersA is not an array) then
  		put tSegmentsArray[1] & "Index" into tSegmentsArray[2]
  		put tSegmentsArray[1] & "Index" into gRigA["handler"]
    else

		  put "index" into tSegmentsArray[2]
		  put "index" into gRigA["handler"]
    end if
	end if -- if tSegmentsArray[2] <> empty then

	# UPDATE OUR "ROUTED" SEGMENT ARRAY TO CONTAIN THE SEGMENTS.
	# NOTE: IF THERE IS NO CUSTOM ROUTING, THIS ARRAY WILL BE
	# IDENTICAL TO gRigA["segments"]
	put tSegmentsArray into gRigA["rSegments"]
end _rigSetRequest






/*----------------------------------------------------------------------
--| FUNCTION _rigValidateRequest
--|
--| Author: rabit
--| Version:  1.5
--| Created: 2009-06-19
--| Last Mod: 2018-11-01
--| Requires: rigSetDirectory, rigShow404, rigSetController, rigSetHandler, _rigValidateModuleRequest()
--|
--| Summary: Validates the supplied segments. Attempts to determine the path
--|          	to the controller.
--|
--| Format:  _rigValidateRequest(param1)
--|
--| Parameters: array <pSegmentsArray>
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigValidateRequest pSegmentsArray
  local tDirectory, tSegments, t404ErrorSegments, tErrMsg, tTemp, tModule, tSegmentTwo

	# DOES THE REQUESTED CONTROLLER EXIST IN THE ROOT FOLDER?
	if there is a file (gRigA["APPPATH"] & "controllers/" & pSegmentsArray[1] & gRigA["EXT"]) then
    rigSetDirectory "controllers"
    return pSegmentsArray
	end if

	# IS THE CONTROLLER IN A SUB-FOLDER?
	if there is a folder (gRigA["APPPATH"] & "controllers/" & pSegmentsArray[1]) then
		# SET THE DIRECTORY AND REMOVE IT FROM THE SEGMENT ARRAY
		put "controllers/" & pSegmentsArray[1] into tDirectory
		rigSetDirectory tDirectory
		put pSegmentsArray into tSegments

		combine tSegments using "/"
		set the itemdelimiter to "/"
		put item 2 to -1 of tSegments into tSegments
		split tSegments by "/"

		if (the number of lines in the keys of tSegments) > 0 then
			# DOES THE REQUESTED CONTROLLER EXIST IN THE SUB-FOLDER?
			if there is a file (gRigA["APPPATH"] & rigFetchDirectory() & tSegments[1] & gRigA["EXT"]) then
			else

				# CHECK IF THERE IS A ROUTING RULE FOR 404 ERRORS OTHERWISE SEND THE DEFAULT 404 ERROR PAGE
				if gRoute[1]["404Override"] <> empty then
					put gRoute[1]["404Override"] into t404ErrorSegments

					split t404ErrorSegments by "/"

					rigSetDirectory "controllers"
					rigLogMessage "error", "404 Page Not Found -->" && tSegments[1]

					rigSetStatusHeader "404"

					return t404ErrorSegments
				else

					put rigFetchDirectory() & tSegments[1] into tErrMsg
					rigShow404 tErrMsg

				end if

			end if
		else
			rigSetController sRouterA["defaultController"]
			rigSetHandler "index"
			# DOES THE DEFAULT CONTROLLER EXIST IN THE SUB-FOLDER?
			if there is a file (gRigA["APPPATH"] & rigFetchDirectory() & sRouterA["defaultController"] & gRigA["EXT"]) then
				put "" into sRouterA["directory"]
				put "" into tTemp[1]
				return tTemp
			end if

		end if

		return tSegments
	end if

  # ARE WE DEALING WITH A MODULE CONTROLLER?
  put _rigValidateModuleRequest(pSegmentsArray) into tSegments
  if tSegments is an array then
      return tSegments
  end if

	# THE URI DOES NOT CORRELATE TO A VALID CONTROLLER
	# CHECK IF THERE IS A ROUTING RULE FOR 404 ERRORS BEFORE SENDING THE DEFAULT 404 ERROR PAGE
  put empty into tModule
  if there is a folder (gRigA["APPPATH"] & "modules/" & pSegmentsArray[1]) then
    put pSegmentsArray[1] into tModule
  end if

 	put empty into t404ErrorSegments
	if (gRoute[1]["404Override"] <> empty) and (tModule is empty) then
		put gRoute[1]["404Override"] into t404ErrorSegments
	else
		if tModule <> empty then
			if gRoute[tModule][1]["404Override"] <> empty then
				put gRoute[tModule][1]["404Override"] into t404ErrorSegments
			end if
		end if
	end if

  if t404ErrorSegments <> empty then
		split t404ErrorSegments by "/"

		if tModule <> empty then
			rigSetDirectory "modules/" & tModule & "/controllers"
		end if

		# ACTUALLY THIS IS A HACK TO GET THE CORRECT PATH TO THE ROUTED ERROR CONTROLLER
		put TRUE into sRouterA["moduleMainController"]
		#
		rigLogMessage "error", "404 Page Not Found -->" && pSegmentsArray[1]

		rigSetStatusHeader "404"

		return t404ErrorSegments
  end if

	# CAN'T FIND THE REQUESTED CONTROLLER...
	# SEND THE 404 ERROR TEMPLATE TO THE BROWSER
	if pSegmentsArray[2] is empty then
		put "index" into tSegmentTwo
	else
		put pSegmentsArray[2] into tSegmentTwo
	end if

	rigShow404 pSegmentsArray[1] & "/" & tSegmentTwo

end _rigValidateRequest






/*----------------------------------------------------------------------
--| FUNCTION _rigValidateModuleRequest
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-11-2015
--| Last Mod: 19-11-2015
--| Requires: rigSetDirectory, rigFetchDirectory()
--|
--| Summary: Validates the supplied module segments. Attempts to determine the path
--|             to the module controller.
--|
--| Format:  _rigValidateModuleRequest(param1)
--|
--| Parameters: array <pSegmentsArray>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function _rigValidateModuleRequest pSegmentsArray
  local tSubfolder, tControllerFound, tDirectory, tSegments

  put FALSE into tSubfolder

  # IS THE CONTROLLER IN A SUB-FOLDER?
  if ((the number of lines in the keys of pSegmentsArray) > 1) and \
    (there is a folder (gRigA["APPPATH"] & "modules/" & pSegmentsArray[1] & "/controllers/" & pSegmentsArray[2])) then
    put TRUE into tSubfolder
  end if

 	# DOES THE REQUESTED CONTROLLER EXIST IN THE MODULES CONTROLLERS FOLDER?
  if tSubfolder is FALSE then
    put FALSE into sRouterA["moduleMainController"]
    put FALSE into tControllerFound

    if (the number of lines in the keys of pSegmentsArray) > 1 then
      if there is a file (gRigA["APPPATH"] & "modules/" & pSegmentsArray[1] & "/controllers/" & pSegmentsArray[2] & gRigA["EXT"]) then
        put TRUE into tControllerFound
      else if there is a file (gRigA["APPPATH"] & "modules/" & pSegmentsArray[1] & "/controllers/" & pSegmentsArray[1] & gRigA["EXT"]) then
        put TRUE into sRouterA["moduleMainController"]
        put TRUE into tControllerFound
      end if

    else if there is a file (gRigA["APPPATH"] & "modules/" & pSegmentsArray[1] & "/controllers/" & pSegmentsArray[1] & gRigA["EXT"]) then
      put TRUE into sRouterA["moduleMainController"]
      put TRUE into tControllerFound
    end if

    if tControllerFound is TRUE then
      # SET THE DIRECTORY
      put "modules/" & pSegmentsArray[1] & "/controllers" into tDirectory
      rigSetDirectory tDirectory
	    return pSegmentsArray
	  end if

    else -- if tSubfolder is FALSE then
    # SET THE DIRECTORY AND REMOVE IT FROM THE SEGMENT ARRAY
    put "modules/" & pSegmentsArray[1] & "/controllers/" & pSegmentsArray[2] into tDirectory
    rigSetDirectory tDirectory
    put pSegmentsArray into tSegments

    combine tSegments using "/"
    set the itemdelimiter to "/"
    put item 3 to -1 of tSegments into tSegments

    split tSegments by "/"

    if (the number of lines in the keys of tSegments) > 0 then
      # DOES THE REQUESTED CONTROLLER EXIST IN THE SUB-FOLDER?
      if there is a file (gRigA["APPPATH"] & rigFetchDirectory() & tSegments[1] & gRigA["EXT"]) then
      else
        return FALSE
      end if

    end if -- if (the number of lines in the keys of tSegments) > 0 then

    return tSegments
  end if -- if tSubfolder is FALSE then

  return FALSE
end _rigValidateModuleRequest







/*----------------------------------------------------------------------
--| COMMAND _rigParseRoutes
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2009-06-19
--| Last Mod: 2017-06-27
--| Requires: _rigSetRequest
--|
--| Summary:  This handler matches any routes that may exist in
--|             the config/routes.lc file against the URI to
--|             determine if the controller/handler needs to be remapped.
--|
--| Format:  _rigParseRoutes
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigParseRoutes
  local tRoutes, tUri, tRoutesKeys, tNewRoute, tReplacement1, tReplacement2, tReplacement3
  local tReplacement4, tReplacement5, tReplacement6, tReplacement7, tReplacement8
  local tReplacement9, tReplacement10, tRouteString, tRegEx

  if sRouterA["moduleRoutes"] is an array then
    put sRouterA["moduleRoutes"] into tRoutes
  else
    put sRouterA["routes"] into tRoutes
  end if
  # DO WE EVEN HAVE ANY CUSTOM ROUTING TO DEAL WITH?
  # THERE IS A DEFAULT  SCAFFOLDING TRIGGER, SO WE'LL LOOK JUST FOR 1
  if (the number of lines in the keys of tRoutes) = 1 then
    _rigSetRequest gRigA["segments"]
    exit _rigParseRoutes
  end if

  # TURN THE SEGMENT ARRAY INTO AN URI STRING
  put gRigA["segments"] into tUri
  combine tUri using "/"

  # IS THERE A LITERAL MATCH?  IF SO WE'RE DONE
  put the keys of tRoutes into tRoutesKeys
  sort lines of tRoutesKeys ascending
  replace return with comma in tRoutesKeys

  repeat for each item keyNum in tRoutesKeys
    if (keyNum is an integer) and (keyNum > 1) then

      if tRoutes[keyNum][tUri] <> "" then
        put tRoutes[keyNum][tUri] into tNewRoute
        split tNewRoute by "/"
        _rigSetRequest tNewRoute
        exit _rigParseRoutes
      end if

    end if
  end repeat

  # LOOP THROUGH THE ROUTE ARRAY LOOKING FOR WILD-CARDS
	put empty into tReplacement1 -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	put empty into tReplacement2
	put empty into tReplacement3
	put empty into tReplacement4
	put empty into tReplacement5
	put empty into tReplacement6
	put empty into tReplacement7
	put empty into tReplacement8
	put empty into tReplacement9
	put empty into tReplacement10
  repeat for each item keyNum in tRoutesKeys
    if (keyNum is an integer) and (keyNum > 1) then
      repeat for each line tKey in the keys of  tRoutes[keyNum]
        put tRoutes[keyNum][tKey] into tRouteString

        # CONVERT WILD-CARDS TO REGEX
        replace ":num" with "[0-9]+" in tKey
        replace ":any" with ".+" in tKey

        put "^" & tKey & "$" into tRegEx

        # DOES THE REGEX MATCH?
        if matchChunk(tUri, tRegEx) then
          # DO WE HAVE A BACK-REFERENCE?
          if ("$" is in tRouteString) and ("(" is in tKey) then
            get matchText(tUri,tRegEx,tReplacement1,tReplacement2,tReplacement3,\
            tReplacement4,tReplacement5,tReplacement6,tReplacement7,tReplacement8,tReplacement9,tReplacement10)

            if "$1" is in tRouteString then
              replace "$1" with tReplacement1 in tRouteString
            end if
            if "$2" is in tRouteString then
              replace "$2" with tReplacement2 in tRouteString
            end if
            if "$3" is in tRouteString then
              replace "$3" with tReplacement3 in tRouteString
            end if
            if "$4" is in tRouteString then
              replace "$4" with tReplacement4 in tRouteString
            end if
            if "$5" is in tRouteString then
              replace "$5" with tReplacement5 in tRouteString
            end if
            if "$6" is in tRouteString then
              replace "$6" with tReplacement6 in tRouteString
            end if
            if "$7" is in tRouteString then
              replace "$7" with tReplacement7 in tRouteString
            end if
            if "$8" is in tRouteString then
              replace "$8" with tReplacement8 in tRouteString
            end if
            if "$9" is in tRouteString then
              replace "$9" with tReplacement9 in tRouteString
            end if
            if "$10" is in tRouteString then
              replace "$10" with tReplacement10 in tRouteString
            end if

          end if

          split tRouteString by "/"
          _rigSetRequest tRouteString
          exit _rigParseRoutes
        end if
      end repeat

    end if
  end repeat

  # IF WE GOT THIS FAR IT MEANS WE DIDN'T ENCOUNTER A
  # MATCHING ROUTE SO WE'LL SET THE SITE DEFAULT ROUTE
  _rigSetRequest gRigA["segments"]
end _rigParseRoutes





----------------------------------------------------------------------
--| COMMAND rigSetController
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-06-09
--| Last Mod: 19-06-09
--| Requires: --
--|
--| Summary:  Store controller name in global.
--|
--| Format:  rigSetController param1
--|
--| Parameters: string <pController>
--|
--| Return: empty
----------------------------------------------------------------------

command rigSetController pController
	put pController into gRigA["controller"]
end rigSetController








----------------------------------------------------------------------
--| FUNCTION rigFetchController
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-10-09
--| Last Mod: 10-10-09
--| Requires: --
--|
--| Summary: Fetch the current controller.
--|
--| Format:  rigFetchController()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------

function rigFetchController
	return gRigA["controller"]
end rigFetchController







----------------------------------------------------------------------
--| COMMAND rigSetHandler
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-06-09
--| Last Mod: 19-06-09
--| Requires: --
--|
--| Summary:  Set the handler name.
--|
--| Format:  rigSetHandler param1
--|
--| Parameters: string <pHandler>
--|
--| Return: empty
----------------------------------------------------------------------

command rigSetHandler pHandler
	put pHandler into gRigA["handler"]
end rigSetHandler







----------------------------------------------------------------------
--| FUNCTION rigFetchControllerHandler
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-06-09
--| Last Mod: 19-06-09
--| Requires: --
--|
--| Summary: Fetch the current controller handler.
--|
--| Format:  rigFetchControllerHandler()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------

function rigFetchControllerHandler
	if gRigA["handler"] is gRigA["controller"] then
		return "index"
	else
		return gRigA["handler"]
	end if
end rigFetchControllerHandler








----------------------------------------------------------------------
--| COMMAND rigSetDirectory
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-06-09
--| Last Mod: 19-06-09
--| Requires: --
--|
--| Summary:  Set the directory name.
--|
--| Format:  rigSetDirectory param1
--|
--| Parameters: string <pDir>
--|
--| Return: empty
----------------------------------------------------------------------

command rigSetDirectory pDir
	put pDir & "/" into sRouterA["directory"]
end rigSetDirectory






----------------------------------------------------------------------
--| FUNCTION rigFetchDirectory
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-06-09
--| Last Mod: 19-06-09
--| Requires: --
--|
--| Summary: Fetch the sub-directory (if any) that contains the requested controller library.
--|
--| Format:  rigFetchDirectory()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------

function rigFetchDirectory
	return sRouterA["directory"]
end rigFetchDirectory








----------------------------------------------------------------------
--| FUNCTION _rigValidateQueryRequest
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-06-09
--| Last Mod: 29-06-09
--| Requires: --
--|
--| Summary: Validates the supplied query request.  Attempts to determine the path to
--|                    the controller.
--|
--| Format:  _rigValidateQueryRequest(param1, param2)
--|
--| Parameters: string <pController>, string <pHandler>
--|
--| Return: bool
----------------------------------------------------------------------

private function _rigValidateQueryRequest pController pHandler
  local tErrMsg

	# DOES THE REQUESTED CONTROLLER EXIST IN THE ROOT FOLDER?
	if there is a file (gRigA["APPPATH"] & "controllers/" & pController & gRigA["EXT"]) then
		return TRUE
	else
		rigSetController sRouterA["defaultController"]
		rigSetHandler "index"
		#DOES THE DEFAULT CONTROLLER EXIST IN THE ROOT FOLDER?
		if there is a file (gRigA["APPPATH"] & "controllers/" & sRouterA["defaultController"] & gRigA["EXT"]) then
			return TRUE
		end if
	end if

	# CAN'T FIND THE REQUESTED CONTROLLER...
	put pController & "/" & pHandler into tErrMsg
	rigShow404 tErrMsg

end _rigValidateQueryRequest




/*----------------------------------------------------------------------
--| FUNCTION _rigParseURL
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-07-09
--| Last Mod: 14-06-15
--| Requires: --
--|
--| Summary: Parse an URL and return its components.
--|
--| Format:  _rigParseURL(param1)
--|
--| Parameters: string <pURL>
--|
--| Return: array
----------------------------------------------------------------------*/

function _rigParseURL pURL
  local tURL, tSchemeOffset, tScheme, tSchemeLength, tURLarray, tHostnameOffsetStart, tHostnameOffsetEnd
  local tHostname, tUsernameOffsetEnd, tUsername, tPasswordOffsetStart, tPasswordOffsetEnd, tPassword
  local tPathOffsetStart, tPathOffsetEnd, tPath, tQueryOffset, tQueryString, tFragmentOffset, tQuery
  local tFragment

    put pURL into tURL
    ##
    # DSNs MUST HAVE THIS PROTOTYPE:
    # DSN = 'DRIVER://USERNAME:PASSWORD@HOSTNAME/DATABASE';
    ##

    # GET SCHEME
    put offset("://",tURL) into tSchemeOffset

    if tSchemeOffset is 0 then
        put "" into tScheme
    else
        put char 1 to (tSchemeOffset - 1) of tURL into tScheme

        # REMOVE SCHEME PART
        put the number of chars of tScheme into tSchemeLength
        put tSchemeLength + 3 into tSchemeLength
        put char (tSchemeLength + 1) to -1 of tURL into tURL
    end if
    put tScheme into tURLarray["scheme"]

    # GET HOSTNAME
    put offset("@",tURL) into tHostnameOffsetStart
    put offset("/",tURL) into tHostnameOffsetEnd

    if tHostnameOffsetStart is 0 or tHostnameOffsetEnd is 0 then
        put "" into tHostname
    else
        put char (tHostnameOffsetStart + 1) to (tHostnameOffsetEnd - 1) of tURL into tHostname
    end if

    # THIS IS NOT A DSN, SECOND TRY TO GET THE HOSTNAME
    if tHostname <> "" then
      put tHostname into tURLarray["host"]

      # GET USER NAME
      put offset(":",tURL) into tUsernameOffsetEnd

      if tUsernameOffsetEnd is 0 then
        put "" into tUsername
      else
        put char 1 to (tUsernameOffsetEnd - 1) of tURL into tUsername
      end if
      put tUsername into tURLarray["user"]

      # GET PASSWORD
      put offset(":",tURL) into tPasswordOffsetStart
      put offset("@",tURL) into tPasswordOffsetEnd

      if tPasswordOffsetStart is 0 or tPasswordOffsetEnd is 0 then
        put "" into tPassword
      else
        put char (tPasswordOffsetStart + 1) to (tPasswordOffsetEnd - 1) of tURL into tPassword
      end if
      put tPassword into tURLarray["pass"]

    else -- if tHostname <> "" then
      put char 1 to (offset("/",tURL) - 1) of tURL into tURLarray["host"]
    end if -- if tHostname <> "" then

    # GET PATH
    put offset("/",tURL) into tPathOffsetStart
    put offset("?",tURL) into tPathOffsetEnd

    if tPathOffsetStart is 0 or tPathOffsetEnd is 0 then
        put "" into tPath
    else
        put char tPathOffsetStart to (tPathOffsetEnd - 1) of tURL into tPath
    end if
    put tPath into tURLarray["path"]

    # GET QUERY
    put offset("?",tURL) into tQueryOffset

    if tQueryOffset is 0 then
        put "" into tQueryString
    else
        put char (tQueryOffset + 1) to -1 of tURL into tQueryString
        if tQueryString contains "#" then
            put offset("#",tQueryString) into tFragmentOffset
            put char 1 to (tFragmentOffset -1) of tQueryString into tQuery
        end if
    end if
    put tQuery into tURLarray["query"]

    # GET FRAGMENT
    if tFragmentOffset is 0 then
        put "" into tFragment
    else
        put char (tFragmentOffset + 1) to -1 of tQueryString into tFragment
    end if
    put tFragment into tURLarray["fragment"]

    return tURLarray
end _rigParseURL




----------------------------------------------------------------------
--| FUNCTION _rigParseQueryStr
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-07-09
--| Last Mod: 06-07-09
--| Requires: --
--|
--| Summary: Parse an URL query string and return its components as array.
--|
--| Format:  _rigParseQueryStr(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: array
----------------------------------------------------------------------

function _rigParseQueryStr pStr
  local tStr

  put pStr into tStr
  split tStr by "&" and "="
  return tStr
end _rigParseQueryStr





/*----------------------------------------------------------------------
--| FUNCTION rigRouterGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Get router array variable value.
--|
--| Format: rigRouterGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigRouterGet pWhat
  if pWhat is among the keys of sRouterA then
    return sRouterA[pWhat]
  end if

  return empty
end rigRouterGet




/*----------------------------------------------------------------------
--| COMMAND rigRouterSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Setter for router variables.
--|
--| Format: rigRouterSet param1, param2
--|
--| Parameters: string <pKey> sRouterA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRouterSet pKey pVal
  if pKey is among the keys of sRouterA then
    put pVal into sRouterA[pKey]
  end if
end rigRouterSet









--| END OF Router.livecodescript
--| Location:  ./system/libraries/Router.livecodescript
----------------------------------------------------------------------
