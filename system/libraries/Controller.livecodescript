script "Controller"

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
# revIgniter Application Controller Library
#
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Libraries
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/general/controllers.html
##




global gRigA

local sRiScaffolding, sRiScaffTable, sControllerLibHandlers, sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-11
 --| Last Mod: --
 --| Requires: rigLogMessage, _rigSetDefaultValues, _rigInitialize
 --|
 --| Summary:  Run security check and initial routines. Set initial values.
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
        rigLogMessage "debug", "Controller Library Loaded"
      end if
      
      # SET INITIAL VALUES
      _rigSetDefaultValues
      #
      
      # CALL INITIAL HANDLERS
      _rigInitialize
    end if -- if sStackInUse <> TRUE
    
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
  put FALSE into sRiScaffolding
  put FALSE into sRiScaffTable

  put "_rigInitialize,rigFetchScaffolding,rigFetchScaffoldingTable,_rigSetScaffolding,_rigSetScaffoldingTable" into sControllerLibHandlers
end _rigSetDefaultValues






/*----------------------------------------------------------------------
--| COMMAND _rigInitialize
--|
--| Author: rabit
--| Version:  1.0
--| Created: 05-07-09
--| Last Mod: 05-07-09
--| Requires: --
--|
--| Summary: Calls the autoload routine.
--| 
--| Format:  _rigInitialize
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigInitialize
  _rigAutoloader
end _rigInitialize




/*----------------------------------------------------------------------
--| FUNCTION rigFetchScaffolding
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-07-09
--| Last Mod: 07-07-09
--| Requires: --
--|
--| Summary: Fetch rigScaffolding flag.
--| 
--| Format:  rigFetchScaffolding()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigFetchScaffolding
	return sRiScaffolding
end rigFetchScaffolding








/*----------------------------------------------------------------------
--| FUNCTION rigFetchScaffoldingTable
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-07-09
--| Last Mod: 07-07-09
--| Requires: --
--|
--| Summary: Fetch rigScaffolding table name.
--| 
--| Format:  rigFetchScaffoldingTable()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFetchScaffoldingTable
	return sRiScaffTable
end rigFetchScaffoldingTable







/*----------------------------------------------------------------------
--| COMMAND _rigSetScaffolding
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-07-09
--| Last Mod: 07-07-09
--| Requires: --
--|
--| Summary: Set rigScaffolding flag.
--| 
--| Format:  _rigSetScaffolding param1
--|
--| Parameters: bool <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigSetScaffolding pVal
	put pVal into sRiScaffolding
end _rigSetScaffolding




/*----------------------------------------------------------------------
--| COMMAND _rigSetScaffoldingTable
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-07-09
--| Last Mod: 07-07-09
--| Requires: --
--|
--| Summary: Set scaffolding table name.
--| 
--| Format:  _rigSetScaffoldingTable param1
--|
--| Parameters: string <pTable>
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigSetScaffoldingTable pTable
	put pTable into sRiScaffTable
end _rigSetScaffoldingTable




/*----------------------------------------------------------------------
--| FUNCTION rigFetchControllerLibHandlers
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-08-15
--| Last Mod: 18-08-15
--| Requires: --
--|
--| Summary: Fetch controller library handlers.
--| 
--| Format:  rigFetchControllerLibHandlers()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFetchControllerLibHandlers
	return sControllerLibHandlers
end rigFetchControllerLibHandlers









/*----------------------------------------------------------------------
--| COMMAND _rigScaffolding
--|
--| Author: rabit
--| Version:  1.0
--| Created: 26-01-10
--| Last Mod: 26-01-10
--| Requires: --
--|
--| Summary: Run scaffolding.
--| 
--| Format:  _rigScaffolding
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigScaffolding
  local tHandlerSegment, tScaffHandlers, tMethod
  
	if (sRiScaffolding is FALSE) or (sRiScaffTable is FALSE) then
		rigShow404 "rigScaffolding unavailable"
	end if

	put rigFetchSegment(3) into tHandlerSegment

	put "rigScaffAdd,rigScaffInsert,rigScaffEdit,rigScaffUpdate,rigScaffView,rigScaffDelete,rigScaffDoDelete" into tScaffHandlers
	if tHandlerSegment is not among the items of tScaffHandlers then
		put "rigScaffView" into tMethod
	else
		put tHandlerSegment into tMethod
	end if

  start using stack (gRigA["BASEPATH"] & "scaffolding/Scaffolding.livecodescript")

	rigScaffolding sRiScaffTable

	do tMethod
end _rigScaffolding







--| END OF Controller.livecodescript
--| Location:  ./system/libraries/Controller.livecodescript
----------------------------------------------------------------------