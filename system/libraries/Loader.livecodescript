script "Loader"

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
# revIgniter Loader Library
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Loader
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/loader.html
##

## ------------------------------------------------------------------------




global gRigA, gAutoload, gModuleAutoload, gModulesHandlersA, gData

local sLoaderA, sStackInUse





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-11
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
        rigLogMessage "debug", "Loader Library Loaded"
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
--| Version:  1.0
--| Created: 2019-01-04
--| Last Mod: 2019-01-04
--| Requires: rigFetchDirectory()
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
  # GET PATH TO VIEWS
  put rigFetchDirectory() into sLoaderA["controllerPath"]

  set the itemDel to "/"

  if item 1 of sLoaderA["controllerPath"] <> "modules" then
  	put gRigA["APPPATH"] & "views/" into sLoaderA["riViewPath"]
  else
    put gRigA["APPPATH"] & "modules/" & (item 2 of sLoaderA["controllerPath"]) &  "/views/" into sLoaderA["riViewPath"]
  end if
end _rigSetDefaultValues





/*----------------------------------------------------------------------
--| COMMAND rigLoaderLoadLibrary
--|
--| Author: rabit
--| Version:  1.4
--| Created: 30-06-09
--| Last Mod: 08-12-15
--| Requires: _rigLoadLibrary
--|
--| Summary: This handler lets users load libraries.
--|            It is designed to be called from a user's app / module controllers.
--|
--| Format:  rigLoaderLoadLibrary param1[, param2][, param3]
--|
--| Parameters: mixed <pLibrary> the names of the libraries to load as array or comma separated list
--|               array <pParams> the optional parameters, string <pModule> the module name (optional)
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigLoaderLoadLibrary pLibrary pParams pModule
  local tParams

	if (pLibrary is not an array) and (pLibrary is "") then
		return FALSE
	end if

	if pParams is not an array then
		put empty into tParams
	else
		put pParams into tParams
	end if

	if pLibrary is an array then
		repeat for each key tKey in pLibrary
			_rigLoadLibrary pLibrary[tKey], tParams, pModule
		end repeat

	else if comma is in pLibrary then
		repeat for each item thisItem in pLibrary
			_rigLoadLibrary thisItem, tParams, pModule
		end repeat

	else
		_rigLoadLibrary pLibrary, tParams, pModule
	end if
end rigLoaderLoadLibrary








/*----------------------------------------------------------------------
--| COMMAND rigLoadModel
--|
--| Author: rabit
--| Version:  1.7
--| Created: 04-07-09
--| Last Mod: 08-12-15
--| Requires: rigShowError, rigLoadDatabase()
--|
--| Summary: This handler lets users load models.
--|
--| Format:  rigLoadModel param1[, param2][, param3]
--|
--| Parameters: string <pModel> the names of the models to load as array or comma separated list,
--|                       bool <pDBconn> database connection (optional), string <pModule> the module name (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLoadModel pModel pDBconn pModule
  local tModelsKeyNum, tDBconn, tModel, tModulePath, tFilePrefix, tPath
  local tModelIsInArray, tModelToLoad, tNameLower, tFirstCharUpper

  if sLoaderA["riModels"] is an array then
    put the number of lines in the keys of sLoaderA["riModels"] into tModelsKeyNum
  else
    put 0 into tModelsKeyNum
  end if

  if pDBconn is empty then
    put FALSE into tDBconn
  else
    put pDBconn into tDBconn
  end if

  put pModel into tModel
  if tModel is an array then
    repeat for each key tKey in tModel
      rigLoadModel tModel[tKey], , pModule
    end repeat
    exit rigLoadModel

  else if comma is in pModel then
    repeat for each item thisItem in pModel
      rigLoadModel thisItem, , pModule
    end repeat
    exit rigLoadModel

  end if

  if tModel is "" then
    exit rigLoadModel
  end if

  put empty into tModulePath
  put empty into tFilePrefix

  # CHECK IF WE ARE DEALING WITH A REQUEST FROM A MODULE
  if pModule <> empty then
      # GET PATH TO models FOLDER OF MODULE RELATIVE TO gRigA["APPPATH"]
      put "modules/" & pModule & "/" into tModulePath
      put pModule & "/" into tFilePrefix
  end if

  set the itemDelimiter to "/"

  # IS THE MODEL IN A SUB-FOLDER? IF SO, PARSE OUT THE FILENAME AND PATH.
  if "/" is in tModel then
    put tModel into tPath

    put item -1 of tPath into tModel

    # GET PATH SANS FILENAME
    put (item 1 to (the number of items of tPath - 1) of tPath) & "/" into tPath
  else
    put "" into tPath
  end if

  # SAFETY:  WAS THE MODEL ALREADY LOADED BY A PREVIOUS CALL?
  if sLoaderA["riModels"] is an array then

    put FALSE into tModelIsInArray
    repeat for each element thisElement in sLoaderA["riModels"]
      if thisElement is (tFilePrefix & tModel) then
        put TRUE into tModelIsInArray
        exit repeat
      end if
    end repeat

    if tModelIsInArray is TRUE then
      rigShowError "The model you are loading is a resource that is already being used:" && tModel
      exit rigLoadModel
    end if
  end if

  put gRigA["APPPATH"] & tModulePath & "models/" & tPath & tModel & ".livecodescript" into tModelToLoad

  if there is a file tModelToLoad then
  else
    rigShowError "Unable to locate the model you have specified:" && tModel
  end if

  if tDBconn is not FALSE and sLoaderA["riDBlibLoaded"] is not TRUE then
    if tDBconn is TRUE then
      put "" into tDBconn
    end if

    get rigLoadDatabase(tDBconn, FALSE, TRUE)
  end if

  start using stack tModelToLoad

  put tolower(tModel) into tNameLower
  put toupper(char 1 of tNameLower) into tFirstCharUpper
  put tFirstCharUpper & (char 2 to -1 of tNameLower) into tModel

  add 1 to tModelsKeyNum
  put tFilePrefix & tModel into sLoaderA["riModels"][tModelsKeyNum]
end rigLoadModel








/*----------------------------------------------------------------------
--| FUNCTION rigLoadDatabase
--|
--| Author: rabit
--| Version:  1.2
--| Created: 04-07-09
--| Last Mod: 16-07-11
--| Requires: rigDB()
--|
--| Summary: Database Loader
--|
--| Format:  rigLoadDatabase(param1, param2, param3)
--|
--| Parameters: string <pParams> the DB credentials, bool <pReturn>,  bool <pActiveRecord> whether to
--|               enable active record (this allows us to override the config setting).
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigLoadDatabase pParams pReturn pActiveRecord
  local tActiveRecord, tDBresult

	if pActiveRecord is empty then
		put FALSE into tActiveRecord
	else
		put pActiveRecord into tActiveRecord
	end if

	# DO WE EVEN NEED TO LOAD THE DATABASE LIBRARY?
	if sLoaderA["riDBlibLoaded"] is  not True then
    start using stack (gRigA["BASEPATH"] & "database/DB.livecodescript")
	else
		return FALSE
	end if

	put TRUE into sLoaderA["riDBlibLoaded"]

	put rigDB(pParams, tActiveRecord) into tDBresult

	if pReturn is TRUE then
		return tDBresult
	end if

end rigLoadDatabase








/*----------------------------------------------------------------------
--| FUNCTION rigLoadView
--|
--| Author: rabit
--| Version:  1.3
--| Created: 19-06-09
--| Last Mod: 08-12-15
--| Requires: _rigLoad()
--|
--| Summary: This function is used to load views and files.
--|
--| Format:  rigLoadView(param1, param2)
--|
--| Parameters: string <pView>, bool <pReturn>
--|
--| Return: empty
----------------------------------------------------------------------*/

function rigLoadView pView pReturn
  local tReturn, tDataA

	if pReturn is empty then
    set the itemDel to "/"
    # SET TO TRUE FOR MODULES LOADED BY APPLICATION CONTROLLERS
    if ("modules" is among the items of sLoaderA["riViewPath"]) and (gModulesHandlersA is an array) then
      put TRUE into tReturn
    else
	    put FALSE into tReturn
    end if
	else
		put pReturn into tReturn
	end if

	put pView into tDataA["riView"]
	put tReturn into tDataA["riReturn"]
	get _rigLoad(tDataA)
end rigLoadView







/*----------------------------------------------------------------------
--| FUNCTION rigLoadFile
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-10-09
--| Last Mod: 10-10-09
--| Requires: _rigLoad()
--|
--| Summary: This is a generic file loader.
--|
--| Format:  rigLoadFile(param1, param2)
--|
--| Parameters: string <pPath>, bool <pReturn>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigLoadFile pPath pReturn
  local tReturn, tDataA, tOutput

	if pReturn is empty then
		put FALSE into tReturn
	else
		put pReturn into tReturn
	end if

	put pPath into tDataA["riPath"]
	put tReturn into tDataA["riReturn"]

	put _rigLoad(tDataA) into tOutput

	return tOutput
end rigLoadFile





/*----------------------------------------------------------------------
--| COMMAND rigLoadHelper
--|
--| Author: rabit
--| Version:  1.5
--| Created: 2009-06-19
--| Last Mod: 2019-01-08
--| Requires: rigShowError, rigLogMessage
--|
--| Summary: This function loads the specified helper file.
--|
--| Format:  rigLoadHelper param1, param2
--|
--| Parameters: mixed <pHelpers> helper names as array or a comma separated list, string <pModule> the module name (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLoadHelper pHelpers pModule
  local tHelpers, tModulePath, tFilePrefix, tTempHelpers, tExtHelper
  local tBaseHelper, tNumHelpers, tNewHelperKey

	put pHelpers into tHelpers
	if tHelpers is not an array then
		if comma is in tHelpers then
			split tHelpers using comma
		else
			# SINGLE NAME
			put tHelpers into tHelpers[1]
		end if
	end if

  put empty into tModulePath
  put empty into tFilePrefix

  # CHECK IF WE ARE DEALING WITH A REQUEST FROM A MODULE
  if pModule <> empty then
    # GET PATH TO helpers FOLDER OF MODULE RELATIVE TO gRigA["APPPATH"]
    put "modules/" & pModule & "/" into tModulePath
    put pModule & "/" into tFilePrefix
  end if

	repeat for each element tHelper in tHelpers
    put toLower(tHelper) into tHelper
    replace "helper" with "" in tHelper
    replace ".livecodescript" with "" in tHelper
    put tHelper & "Helper" into tHelper

    if sLoaderA["riHelpers"] is an array then
      put sLoaderA["riHelpers"] into tTempHelpers
      combine tTempHelpers using comma
      # IS HELPER ALREADY LOADED?
		 if (itemOffset((tFilePrefix & tHelper), tTempHelpers) > 0) or (itemOffset(tHelper, tTempHelpers) > 0) then
        next repeat
      end if
    end if

    put gRigA["APPPATH"] & tModulePath & "helpers/" & rigConfigItem("sublibraryPrefix") & tHelper & ".livecodescript" into tExtHelper

    # IS THIS A HELPER EXTENSION REQUEST?
    if there is a file tExtHelper then
      put gRigA["BASEPATH"] & "helpers/" & tHelper & ".livecodescript" into tBaseHelper
      if there is a file tBaseHelper then
        start using stack tBaseHelper
      else
        rigShowError "Unable to load the requested file: helpers/" & tHelper & ".livecodescript"
      end if
      start using stack tExtHelper

    else if there is a file (gRigA["APPPATH"] & tModulePath & "helpers/" & tHelper & ".livecodescript") then
      start using stack (gRigA["APPPATH"] & tModulePath & "helpers/" & tHelper & ".livecodescript")
    else
      if there is a file (gRigA["BASEPATH"] & "helpers/" & tHelper & ".livecodescript") then
        start using stack (gRigA["BASEPATH"] & "helpers/" & tHelper & ".livecodescript")
      else
        rigShowError "Unable to load the requested file: helpers/" & tHelper & ".livecodescript"
      end if
    end if

    put the number of lines in the keys of sLoaderA["riHelpers"] into tNumHelpers
    put tNumHelpers + 1 into tNewHelperKey
    put tFilePrefix & tHelper into sLoaderA["riHelpers"][tNewHelperKey]

    rigLogMessage "debug", "Helper loaded: " & tHelper
  end repeat
end rigLoadHelper







/*----------------------------------------------------------------------
--| COMMAND rigLoadHelpers
--|
--| Author: rabit
--| Version:  1.1
--| Created: 19-06-09
--| Last Mod: 08-12-15
--| Requires: rigLoadHelper
--|
--| Summary: This is simply an alias to the above handler in case the
--|             user has written the plural form of this handler.
--|
--| Format:  rigLoadHelpers param1, param2
--|
--| Parameters: mixed <pHelpers>, string <pModule> the module name (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLoadHelpers pHelpers pModule
	rigLoadHelper pHelpers, pModule
end rigLoadHelpers







/*----------------------------------------------------------------------
--| COMMAND rigLoadPlugin
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2009-07-02
--| Last Mod: 2019-01-10
--| Requires: rigLoadHelper
--|
--| Summary: This function redirects legacy rigLoadPlugin calls to handler rigLoadHelper.
--|
--| Format:  rigLoadPlugin param1, param2
--|
--| Parameters: mixed <pPlugins> plugin names as array or a comma separated list, string <pModule> the module name (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLoadPlugin pPlugins pModule
  rigLoadHelper pPlugins, pModule
end rigLoadPlugin






/*----------------------------------------------------------------------
--| COMMAND rigLoadPlugins
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-07-02
--| Last Mod: 2019-01-10
--| Requires: rigLoadHelper
--|
--| Summary: This is simply an alias to the above handler in case the
--|            user has written the plural form of this handler which
--|            redirects legacy rigLoadPlugin calls to handler rigLoadHelper.
--|
--| Format:  rigLoadPlugins param1, param2
--|
--| Parameters: mixed <pPlugins>, string <pModule> the module name (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLoadPlugins pPlugins pModule
	rigLoadHelper pPlugins, pModule
end rigLoadPlugins





/*----------------------------------------------------------------------
--| COMMAND rigLoadExtension
--|
--| Author: rabit
--| Version:  1.6
--| Created: 2016-07-10
--| Last Mod: 2019-01-08
--| Requires: rigShowError, rigLogMessage, _rigPrepareExtensionsArray,
--|           _rigExtensionsArrayToList()
--|
--| Summary: This function loads the specified LiveCode Builder extension (library).
--|
--| Format:  rigLoadExtension param1[, param2]
--|
--| Parameters: mixed <pExtensions> extension names (and optional resource paths relative to
--|               the extension folder) as array or a comma separated list, string <pModule>
--|               the module name (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLoadExtension pExtensions pModule
  local tExtensions, tModulePath, tFolderPrefix, tExtension, tExtExists
  local tExtensionsItem, tExtToLoad, tTempExtensions, tExtExtension
  local tSysExtension, tResourcePath, tNumExtensions, tNewExtensionKey

  put pExtensions into tExtensions
  if tExtensions is not an array then
    if comma is in tExtensions then
      split tExtensions using comma
    else
      # SINGLE NAME
      put tExtensions into tExtensions[1]
    end if
  end if

  _rigPrepareExtensionsArray tExtensions

  put empty into tModulePath
  put empty into tFolderPrefix

  # CHECK IF WE ARE DEALING WITH A REQUEST FROM A MODULE
  if pModule <> empty then
    put "modules/" & pModule & "/" into tModulePath
    put pModule & "/" into tFolderPrefix
  end if

  repeat for each element tExtension in tExtensions
    put TRUE into tExtExists
    put toLower(tExtension["extension"]) & tExtension["resourcePath"] into tExtensionsItem

    if sLoaderA["riExtensions"] is an array then
      put _rigExtensionsArrayToList(sLoaderA["riExtensions"]) into tTempExtensions
      # IS EXTENSION ALREADY LOADED?
     if (itemOffset((tFolderPrefix & tExtensionsItem), tTempExtensions) > 0) or (itemOffset(tExtensionsItem, tTempExtensions) > 0) then
        next repeat
      end if
    end if

    put gRigA["APPPATH"] & tModulePath & "extensions/" & tExtension["extension"] & "/module.lcm" into tExtExtension
    put gRigA["BASEPATH"] & "extensions/" & tExtension["extension"] & "/module.lcm" into tSysExtension

    # CHECK IF THIS FILE IS IN THE APP-FOLDER
    if there is a file tExtExtension then
      put gRigA["APPPATH"] & tModulePath & "extensions/" & tExtension["extension"] & tExtension["resourcePath"] into tResourcePath
      put tExtExtension into tExtToLoad

    else if there is a file tSysExtension then
      put gRigA["BASEPATH"] & "extensions/" & tExtension["extension"] & tExtension["resourcePath"] into tResourcePath
      put tSysExtension into tExtToLoad

    else
      put FALSE into tExtExists
      rigShowError "Unable to load the requested file:" && tFolderPrefix & "extensions/" & tExtension["extension"] & "/module.lcm"
    end if

    if tExtExists is TRUE then
      if tExtension["resourcePath"] is empty then
        load extension from file tExtToLoad
      else
        load extension from file tExtToLoad with resource path tResourcePath
      end if -- if tExtension["resourcePath"] is empty
    end if

    put the number of lines in the keys of sLoaderA["riExtensions"] into tNumExtensions
    put tNumExtensions + 1 into tNewExtensionKey
    put tFolderPrefix & tExtension["extension"] into sLoaderA["riExtensions"][tNewExtensionKey]["extension"]
    put tFolderPrefix & tExtension["resourcePath"] into sLoaderA["riExtensions"][tNewExtensionKey]["resourcePath"]

    rigLogMessage "debug", "Extension loaded: " & tExtension
  end repeat
end rigLoadExtension






/*----------------------------------------------------------------------
--| COMMAND rigLoadExtensions
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-07-10
--| Last Mod: 2016-07-10
--| Requires: rigLoadExtension
--|
--| Summary: This is simply an alias to the above handler in case the
--|            user has written the plural form of this handler.
--|
--| Format:  rigLoadExtensions param1[, param2]
--|
--| Parameters: mixed <pExtensions>, string <pModule> the module name (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLoadExtensions pExtensions pModule
	rigLoadExtension pExtensions, pModule
end rigLoadExtensions






/*----------------------------------------------------------------------
--| COMMAND _rigPrepareExtensionsArray
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2018-01-04
--| Last Mod: 2018-12-14
--| Requires: --
--|
--| Summary: Prepare array including extensions folder names and resource paths.
--|
--| Format:  _rigPrepareExtensionsArray param1
--|
--| Parameters: array <pExtensions>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigPrepareExtensionsArray @pExtensions
  local tKey, tArrayDataAtIndex

  set the itemDel to "/"

  repeat for each key tKey in pExtensions
    if "/" is in pExtensions[tKey] then
      put pExtensions[tKey] into tArrayDataAtIndex
      put item 1 of tArrayDataAtIndex into pExtensions[tKey]["extension"]
      put "/" & item 2 to -1 of tArrayDataAtIndex into pExtensions[tKey]["resourcePath"]
    else
      put pExtensions[tKey] into pExtensions[tKey]["extension"]
      put empty into pExtensions[tKey]["resourcePath"]
    end if
  end repeat
end _rigPrepareExtensionsArray





/*----------------------------------------------------------------------
--| FUNCTION _rigExtensionsArrayToList
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2018-01-04
--| Last Mod: 2018-01-04
--| Requires: --
--|
--| Summary: Convert extensions array to a comma delimited list.
--|
--| Format:  _rigExtensionsArrayToList(param1)
--|
--| Parameters: array <pExtensions>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigExtensionsArrayToList pExtensions
  local tExtensionsList

   repeat for each element tExtension in pExtensions
      put tExtension["extension"] & tExtension["resourcePath"] & comma after tExtensionsList
   end repeat

   delete char -1 of tExtensionsList

   return tExtensionsList
end _rigExtensionsArrayToList






/*----------------------------------------------------------------------
--| COMMAND rigLoadLanguage
--|
--| Author: rabit
--| Version:  1.3
--| Created: 02-07-09
--| Last Mod: 08-12-12
--| Requires: rigLangLoadLang()
--|
--| Summary: Loads a language file.
--|
--| Format:  rigLoadLanguage param1, param2, param3
--|
--| Parameters: mixed <pFiles>, string <pLang>, string <pModule> the module name (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLoadLanguage pFiles pLang pModule
  local tFiles

	put pFiles into tFiles
	if tFiles is not an array then
		if comma is in tFiles then
			split tFiles using comma
		else
			# SINGLE NAME
			put tFiles into tFiles[1]
		end if
	end if

	repeat for each key tKey in tFiles
		get rigLangLoadLang(tFiles[tKey], pLang, pModule)
	end repeat
end rigLoadLanguage








/*----------------------------------------------------------------------
--| FUNCTION rigLoadScaffoldingLanguage
--|
--| Author: rabit
--| Version:  1.2
--| Created: 10-10-09
--| Last Mod: 09-03-16
--| Requires: rigLangLoadLang()
--|
--| Summary: Loads language files for scaffolding.
--|
--| Format:  rigLoadScaffoldingLanguage(param1, param2, param3)
--|
--| Parameters: string <pFile>, string <pLang>, bool <pReturn>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigLoadScaffoldingLanguage pFile pLang pReturn
  local tReturn

	if pReturn is empty then
		put FALSE into tReturn
	else
		put pReturn into tReturn
	end if

  # THIRD PARAMETER IS A MODULE NAME (NOT NEEDED WITH SCAFFOLDING)
  get rigLangLoadLang(pFile, pLang, "", tReturn)
end rigLoadScaffoldingLanguage











/*----------------------------------------------------------------------
--| COMMAND rigLoadConfig
--|
--| Author: rabit
--| Version:  1.1
--| Created: 10-10-09
--| Last Mod: 08-12-15
--| Requires: rigLoadConfigFile()
--|
--| Summary: Loads a config file.
--|
--| Format:  rigLoadConfig param1, param2, param3, param4
--|
--| Parameters: string <pFile>, bool <pUseSections>, bool <pFailGracefully>, string <pModule> the module name (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLoadConfig pFile pUseSections pFailGracefully pModule
  local tUseSections, tFailGracefully

	if pUseSections is empty then
		put FALSE into tUseSections
	else
		put pUseSections into tUseSections
	end if

	if pFailGracefully is empty then
		put FALSE into tFailGracefully
	else
		put pFailGracefully into tFailGracefully
	end if

	get rigLoadConfigFile(pFile, pUseSections, pFailGracefully, pModule)
end rigLoadConfig







/*----------------------------------------------------------------------
--| COMMAND rigLoadScaffolding
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-07-09
--| Last Mod: 07-07-09
--| Requires: --
--|
--| Summary: This initializing handler works a bit different than the
--|                    others. It doesn't load the library.  Instead, it simply
--|                    sets a flag indicating that scaffolding is allowed to be
--|                    used.  The actual scaffolding function below is
--|                    called by the front controller based on whether the
--|                    second segment of the URL matches the "secret" scaffolding
--|                    word stored in the application/config/routes.lc.
--|
--| Format:  rigLoadScaffolding param1
--|
--| Parameters: string <pTable>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLoadScaffolding pTable
	if pTable is FALSE then
		rigShowError "You must include the name of the table you would like to access when you initialize scaffolding"
	end if

	_rigSetScaffolding TRUE

	if pTable is "" then
		_rigSetScaffoldingTable FALSE
	else
		_rigSetScaffoldingTable pTable
	end if
end rigLoadScaffolding




/*----------------------------------------------------------------------
--| COMMAND rigLoadstack
--|
--| Author: rabit
--| Version:  1.1
--| Created: 30-07-2011
--| Last Mod: 08-12-2015
--| Requires: _rigLoadStack
--|
--| Summary: Load stack files.
--|
--| Format:  rigLoadstack param1[, param2][, param3][, param4]
--|
--| Parameters: mixed <pStack> the names of the stacks to load as array or comma separated list
--|						 array <pParams> the optional parameters
--|						 string <pPosition> either "front" or "behind", defines whether the loaded stack
--|						 should sit behind or in front of the home stack (optional), string <pModule> the module name (optional)
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigLoadstack pStack pParams pPosition pModule
  local tParams, tPosition, tKey

	if (pStack is not an array) and (pStack is "") then
		return FALSE
	end if

	if pParams is not an array then
		put empty into tParams
	else
		put pParams into tParams
	end if

	if pPosition is empty then
		put "behind" into tPosition
	else if (pPosition is "front") or (pPosition is "behind") then
		put pPosition into tPosition
	else
		put "behind" into tPosition
	end if

	if pStack is an array then
		repeat for each key tKey in pStack
			_rigLoadStack pStack[tKey], tParams, tPosition
		end repeat

	else if comma is in pStack then
		repeat for each item thisItem in pStack
			_rigLoadStack thisItem, tParams, tPosition
		end repeat

	else
		_rigLoadStack pStack, tParams, tPosition, pModule
	end if
end rigLoadstack




/*----------------------------------------------------------------------
--| COMMAND rigLoadstacks
--|
--| Author: rabit
--| Version:  1.1
--| Created: 30-07-2011
--| Last Mod: 08-12-2015
--| Requires: rigLoadstack
--|
--| Summary: This is simply an alias to the above handler in case the
--|            user has written the plural form of this handler.
--|
--| Format:  rigLoadstacks param1, param2, param3, param4
--|
--| Parameters: mixed <pStack> the names of the stacks to load as array or comma separated list
--|						 array <pParams> the optional parameters
--|						 string <pPosition> either "front" or "behind", defines whether the loaded stack
--|						 should sit behind or in front of the home stack, string <pModule> the module name (optional)
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigLoadstacks  pStack pParams pPosition pModule
	rigLoadstack pStack, pParams, pPosition, pModule
end rigLoadstacks




/*----------------------------------------------------------------------
--| FUNCTION _rigLoad
--|
--| Author: rabit
--| Version:  1.6
--| Created: 2009-06-19
--| Last Mod: 2017-06-27
--| Requires: rigShowError, rigLogMessage, rigAppendOutput
--|
--| Summary: This function is used to load views and files.
--|
--| Format:  _rigLoad(param1)
--|
--| Parameters: array <pDataArray>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigLoad pDataArray
  local tRiView, tRiPath, tRiReturn, tExtension, tExtFound, tRiFile
  local tPageBuffer, tBuffer

	# SET THE DEFAULT DATA VARIABLES
	repeat for each line tKey in the keys of pDataArray
		if tKey is "riView" then
			put pDataArray["riView"] into tRiView
		end if

		if tKey is "riPath" then
			put pDataArray["riPath"] into tRiPath
		end if
		if tKey is "riReturn" then
			put pDataArray["riReturn"] into tRiReturn
		end if
	end repeat

	# SET THE PATH TO THE REQUESTED FILE
	if tRiPath is "" then
		put empty into tExtension -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
		put matchText(tRiView,".+(\.[^\.\/].+)$",tExtension) into tExtFound
		if tExtFound is TRUE then
			put tRiView into tRiFile
		else
			put tRiView & gRigA["EXT"] into tRiFile
		end if

		put sLoaderA["riViewPath"] & tRiFile into tRiPath
	else
		set the itemDelimiter to "/"
		put item -1 of tRiPath into tRiFile
	end if

	if there is a file tRiPath then
	else
		rigShowError "Unable to load the requested file: " & tRiFile
	end if

	##
	# MERGING VIEWS
	#
	# ALL VIEWS AND NESTED VIEWS ARE MERGED SEPARATELY INTO
	# THE FINAL OUTPUT DATA WHICH CAN THEN BE POST-PROCESSED
	# BY THE OUTPUT LIBRARY.  WHY DO WE NEED POST PROCESSING?
	# FOR ONE THING, IN ORDER TO SHOW THE ELAPSED PAGE LOAD TIME.
	# UNLESS WE CAN INTERCEPT THE CONTENT RIGHT BEFORE IT'S
	# SENT TO THE BROWSER AND THEN STOP THE TIMER IT WON'T
	# BE ACCURATE.
	##
	put URL format("binfile:%s", tRiPath) into tPageBuffer

  if the result <> empty then
		rigLogMessage "error", "Failed to read file! System error:" && the sysError
	else
		rigLogMessage "debug", "File loaded: " & tRiPath
  end if

	# RETURN THE FILE DATA IF REQUESTED
	if tRiReturn is TRUE then
		put merge(tPageBuffer) into tBuffer
		return tBuffer
	end if

	# CALL HANDLER IN OUTPUT.LC TO APPEND OUTPUT DATA
	rigAppendOutput merge(tPageBuffer)

end _rigLoad





/*----------------------------------------------------------------------
--| COMMAND _rigLoadLibrary
--|
--| Author: rabit
--| Version:  1.8
--| Created: 2009-07-07
--| Last Mod: 2019-09-01
--| Requires: rigFetchConfigItem(), rigLogMessage, rigShowError, _rigRiInitLibrary
--|
--| Summary: This handler loads the requested library.
--|
--| Format:  _rigLoadLibrary param1, param2, param3
--|
--| Parameters: string <pLibrary> the item that is being loaded, array <pParams> any additional parameters,
--|						 string <pModule> the module name (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigLoadLibrary pLibrary pParams pModule
  local tLoadedFilesKeyNum, tLibrary, tModulePath, tSubdir, tPath, tNameLower
  local tFirstCharUpper, tNameUCfirst, tNameVariants, tLib, tPrefix
  local tSubLib, tBaseLib, tLibInArray, tIsDuplicate, tPathVariants, tKey
  local tPathVar, tFilePath, tFileIsInArray, tPathNotSpecified

	if sLoaderA["riLoadedFiles"] is an array then
		put the number of lines in the keys of sLoaderA["riLoadedFiles"] into tLoadedFilesKeyNum
	else
		put 0 into tLoadedFilesKeyNum
	end if

	put pLibrary into tLibrary
	# GET THE LIBRARY NAME, AND WHILE WE'RE AT IT TRIM ANY SLASHES.
	# THE DIRECTORY PATH CAN BE INCLUDED AS PART OF THE LIBRARY NAME,
	# BUT WE DON'T WANT A LEADING SLASH
	if char 1 of tLibrary is "/" then
		put char 2 to -1 of tLibrary into tLibrary
	end if
	replace ".livecodescript" with "" in tLibrary

  put empty into tModulePath

  # CHECK IF WE ARE DEALING WITH A REQUEST FROM A MODULE
  if pModule <> empty then
      # GET PATH TO models FOLDER OF MODULE RELATIVE TO gRigA["APPPATH"]
      put "modules/" & pModule & "/" into tModulePath
  end if

	# WAS THE PATH INCLUDED WITH THE LIBRARY NAME?
	# WE LOOK FOR A SLASH TO DETERMINE THIS
	put "" into tSubdir
	if "/" is in tLibrary then
		put tLibrary into tPath
		set the itemDelimiter to "/"

		# RESET THE tLibrary VARIABLE
		put item -1 of tPath into tLibrary

		# GET PATH SANS FILENAME
		put (item 1 to (the number of items of tPath - 1) of tPath) & "/" into tSubdir
	end if

  # FIRST TEST THE FILE NAME AS PROVIDED
  put tLibrary into tNameVariants[1]

  # THEN WE'LL TEST FOR BOTH LOWERCASE AND CAPITALIZED VERSIONS OF THE FILE NAME
	put toLower(tLibrary) into tNameLower
	put toupper(char 1 of tNameLower) into tFirstCharUpper
	put tFirstCharUpper & (char 2 to -1 of tNameLower) into tNameUCfirst

	put tNameLower into tNameVariants[2]
	put tNameUCfirst into tNameVariants[3]

  # GET PREFIX
  put empty into tPrefix
  # CONSIDER MODULE SETTINGS TOO IF AVAILABLE
  if pModule <> empty then
    put rigFetchConfigItem("sublibraryPrefix", pModule) into tPrefix
  end if
  if (tPrefix is empty) or (tPrefix is FALSE) then
    put rigFetchConfigItem("sublibraryPrefix") into tPrefix
  end if

	repeat for each key tKey in tNameVariants
		put tNameVariants[tKey] into tLib

		put gRigA["APPPATH"] & tModulePath & "libraries/" & tSubdir & tPrefix & tLib & ".livecodescript" into tSubLib

		# IS THIS A LIBRARY EXTENSION REQUEST?
		if there is a file tSubLib then
			put gRigA["BASEPATH"] & "libraries/" & tNameUCfirst & ".livecodescript" into tBaseLib

			if there is a file tBaseLib then
			else
				rigLogMessage "error", "Unable to load the requested library:" && tLib
				rigShowError "Unable to load the requested library:" && tLib
			end if

			# SAFETY:  WAS THE LIBRARY ALREADY LOADED BY A PREVIOUS CALL?
			if sLoaderA["riLoadedFiles"] is an array then

				put FALSE into tLibInArray
				repeat for each element thisElement in sLoaderA["riLoadedFiles"]
					if (thisElement is tBaseLib) or (thisElement is tSubLib) then
						put TRUE into tLibInArray
						exit repeat
					end if
				end repeat

				if tLibInArray is TRUE then
					put TRUE into tIsDuplicate
					rigLogMessage "debug", tLib && "library already loaded. Second attempt ignored."
					exit _rigLoadLibrary
				end if
			end if

			start using stack tBaseLib
			start using stack tSubLib
			# ADD BOTH LIBRARY PATHS TO THE sLoaderA["riLoadedFiles"] ARRAY
			add 1 to tLoadedFilesKeyNum
			put tBaseLib into sLoaderA["riLoadedFiles"][tLoadedFilesKeyNum]
			add 1 to tLoadedFilesKeyNum
			put tSubLib into sLoaderA["riLoadedFiles"][tLoadedFilesKeyNum]

      # WE LEAVE THE PREFIX PARAMETER EMPTY BECAUSE WE SOLELY STORE BASE LIBRARIES IN THE sLoaderA["riLibs"] ARRAY
      _rigRiInitLibrary tLib, "", pParams, pModule
			exit _rigLoadLibrary

		end if -- if there is a file tSubLib then

		# LETS SEARCH FOR THE REQUESTED LIBRARY FILE AND LOAD IT.
		put FALSE into tIsDuplicate
		put gRigA["APPPATH"] into tPathVariants[1]
		put gRigA["BASEPATH"] into tPathVariants[2]

		repeat for each key tKey in tPathVariants
			put tPathVariants[tKey] into tPathVar

      if tKey is 1 then
        put tPathVar & tModulePath & "libraries/" & tSubdir & tLib & ".livecodescript" into tFilePath
      else
        put tPathVar & "libraries/" & tSubdir & tLib & ".livecodescript" into tFilePath
      end if

			if there is a file tFilePath then
			else
				next repeat
			end if

			# SAFETY:  WAS THE LIBRARY ALREADY LOADED BY A PREVIOUS CALL?
			if sLoaderA["riLoadedFiles"] is an array then

				put FALSE into tFileIsInArray
				repeat for each element thisElement in sLoaderA["riLoadedFiles"]
					if thisElement is tFilePath then
						put TRUE into tFileIsInArray
						exit repeat
					end if
				end repeat

				if tFileIsInArray is TRUE then
					put TRUE into tIsDuplicate
					rigLogMessage "debug", tLib && "library already loaded. Second attempt ignored."
					exit _rigLoadLibrary
				end if
			end if

			start using stack tFilePath
			add 1 to tLoadedFilesKeyNum
			put tFilePath into sLoaderA["riLoadedFiles"][tLoadedFilesKeyNum]
			_rigRiInitLibrary tLib, "", pParams, pModule
			exit _rigLoadLibrary

		end repeat
	end repeat -- for each key tKey in tNameVariants

	# ONE LAST ATTEMPT.  MAYBE THE LIBRARY IS IN A SUBDIRECTORY, BUT IT WASN'T SPECIFIED?
	if tSubdir is "" then
		put toLower(tLibrary) & "/" & tLib into tPathNotSpecified
		_rigLoadLibrary tPathNotSpecified, pParams, pModule
		exit _rigLoadLibrary
	end if

	# IF WE GOT THIS FAR WE WERE UNABLE TO FIND THE REQUESTED LIBRARY.
	# WE DO NOT ISSUE ERRORS IF THE LOAD CALL FAILED DUE TO A DUPLICATE REQUEST
	if tIsDuplicate is FALSE then
		rigLogMessage "error", "Unable to load the requested library:" & tLib
		rigShowError "Unable to load the requested library:" & tLib
	end if
end _rigLoadLibrary






/*----------------------------------------------------------------------
--| COMMAND _rigAutoloader
--|
--| Author: rabit
--| Version:  1.5
--| Created: 30-06-09
--| Last Mod: 10-07-16
--| Requires: rigLoadConfigFile(), rigLoadHelper, rigLoadLanguage, rigLoadDatabase(),
--|            rigLoadScaffolding(), rigLoaderLoadLibrary, rigLoadStack, rigLoadModel, rigLoadExtension
--|
--| Summary: The config/autoload.lc file contains an array that permits libraries, stacks, a database,
--|             helpers, extensions, config files, language files and modules to be loaded automatically.
--|
--| Format:  _rigAutoloader param1
--|
--| Parameters: string <pModule> the module name (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigAutoloader pModule
  local tAutoload, tConfigToLoad, tLibrariesList, tItemNum, tStacksList

 # DON'T LOAD config/autoload.lc file IF A MODULE CONTROLLER IS USED
 # AS APPLICATION CONTROLLER, INSTEAD THE MODULE'S OWN AUTOLOAD FILE WILL BE LOADED
 if (gRigA["module"] <> empty) and (pModule is empty) then
   exit _rigAutoloader
 end if

  if pModule is empty then
    -- start using stack (gRigA["APPPATH"] & "config/autoload.livecodescript")
    _rigRequire gRigA["APPPATH"] & "config/autoload" & gRigA["Ext"]
    put gAutoload into tAutoload
  else
    # THE MODULE'S AUTOLOAD FILE IS ALREADY LOADED
    put gModuleAutoload into tAutoload
  end if

	if tAutoload is not an array then
		return FALSE
	end if

	# LOAD ANY CUSTOM CONFIG FILE
	if the number of lines in the keys of tAutoload["config"] > 0 and tAutoload["config"][1] is not "" then
		repeat for each key tKey in tAutoload["config"]
      put tAutoload["config"][tKey] into tConfigToLoad

      if pModule is empty then
        get rigLoadConfigFile(tConfigToLoad)
      else
        get rigLoadConfigFile(tConfigToLoad, TRUE, TRUE, pModule)
      end if
		end repeat
	end if

	# AUTOLOAD HELPERS, EXTENSIONS AND LANGUAGES
	if tAutoload["helper"] is an array and tAutoload["helper"][1] is not "" then
		rigLoadHelper tAutoload["helper"], pModule
	end if

	if tAutoload["extension"] is an array and tAutoload["extension"][1] is not "" then
		rigLoadExtension tAutoload["extension"], pModule
	end if

	if tAutoload["language"] is an array and tAutoload["language"][1] is not "" then
    if pModule is empty then
      rigLoadLanguage tAutoload["language"]
    else
      rigLoadLanguage tAutoload["language"], rigFetchConfigItem("language"), pModule
    end if
	end if
  #

	# LOAD LIBRARIES
	if tAutoload["libraries"] is an array and tAutoload["libraries"][1] is not "" then

		# LOAD THE DATABASE DRIVER.
		put tAutoload["libraries"] into tLibrariesList
		combine tLibrariesList using comma
		put 1 into tItemNum
		repeat for each item thisItem in tLibrariesList
			if thisItem is "database" then
				get rigLoadDatabase()
				delete item tItemNum of tLibrariesList
				exit repeat
			end if
			add 1 to tItemNum
		end repeat

		# LOAD SCAFFOLDING
		put 1 into tItemNum
		repeat for each item thisItem in tLibrariesList
			if thisItem is "scaffolding" then
				rigLoadScaffolding
				delete item tItemNum of tLibrariesList
				exit repeat
			end if
			add 1 to tItemNum
		end repeat

		# LOAD ALL OTHER LIBRARIES
		repeat for each item thisItem in tLibrariesList
			rigLoaderLoadLibrary thisItem, , pModule
		end repeat

	end if

	# LOAD STACKS
	if tAutoload["stacks"] is an array and tAutoload["stacks"][1] is not "" then
		put tAutoload["stacks"] into tStacksList
		combine tStacksList using comma
		repeat for each item thisItem in tStacksList
			rigLoadStack thisItem, , , pModule
		end repeat
	end if

	# AUTOLOAD MODELS
	if tAutoload["model"] is an array and tAutoload["model"][1] is not "" then
		rigLoadModel tAutoload["model"], , pModule
	end if

end _rigAutoloader





/*----------------------------------------------------------------------
--| COMMAND _rigLoadStack
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2011-07-30
--| Last Mod: 2019-09-01
--| Requires: rigFetchConfigItem(), rigLogMessage, rigShowError, _rigRiInitStack
--|
--| Summary: This handler loads the requested stack.
--|
--| Format:  _rigLoadStack param1, param2, param3, param4
--|
--| Parameters: string <pStack> the stack that is being loaded,
--|						 array <pParams> the optional parameters
--|						 string <pPosition> either "front" or "behind", defines whether the loaded stack
--|						 should sit behind or in front of the home stack, string <pModule> the module name (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigLoadStack pStack pParams pPosition pModule
  local tNumLoadedStacks, tStack, tModulePath, tSubdir, tPath, tNameLower
  local tFirstCharUpper, tNameUCfirst, tNameVariants, tStackToLoad
  local tPrefix, tSubStack, tSubStackTempA, tSubStackTempB, tSubStackExists
  local tBaseStack, tStackInArray, tIsDuplicate, tPathVariants, tPathVar
  local tFilePath, tFilePathTempA, tFilePathTempB, tFilePathExists
  local tFileIsInArray, tPathNotSpecified

	if sLoaderA["riLoadedStackFiles"] is an array then
		put the number of lines in the keys of sLoaderA["riLoadedStackFiles"] into tNumLoadedStacks
	else
		put 0 into tNumLoadedStacks
	end if

	put pStack into tStack
	# GET THE STACK NAME, AND WHILE WE'RE AT IT TRIM ANY SLASHES.
	# THE DIRECTORY PATH CAN BE INCLUDED AS PART OF THE STACK NAME,
	# BUT WE DON'T WANT A LEADING SLASH
	if char 1 of tStack is "/" then
		put char 2 to -1 of tStack into tStack
	end if

  put empty into tModulePath

  # CHECK IF WE ARE DEALING WITH A REQUEST FROM A MODULE
  if pModule <> empty then
      # GET PATH TO stacks FOLDER OF MODULE RELATIVE TO gRigA["APPPATH"]
      put "modules/" & pModule & "/" into tModulePath
  end if

	# WAS THE PATH INCLUDED WITH THE STACK NAME?
	# WE LOOK FOR A SLASH TO DETERMINE THIS
	put "" into tSubdir
	if "/" is in tStack then
		put tStack into tPath
		set the itemDelimiter to "/"

		# RESET THE tStack VARIABLE
		put item -1 of tPath into tStack

		# GET PATH SANS FILENAME
		put (item 1 to (the number of items of tPath - 1) of tPath) & "/" into tSubdir
	end if

  # FIRST TEST THE FILE NAME AS PROVIDED
  put tStack into tNameVariants[1]

  # THEN WE'LL TEST FOR BOTH LOWERCASE AND CAPITALIZED VERSIONS OF THE FILE NAME
	put toLower(tStack) into tNameLower
	put toupper(char 1 of tNameLower) into tFirstCharUpper
	put tFirstCharUpper & (char 2 to -1 of tNameLower) into tNameUCfirst

	put tNameLower into tNameVariants[2]
	put tNameUCfirst into tNameVariants[3]

	repeat for each key tKey in tNameVariants
		put tNameVariants[tKey] into tStackToLoad

    # GET PREFIX
    put empty into tPrefix
    # CONSIDER MODULE SETTINGS TOO IF AVAILABLE
    if pModule <> empty then
      put rigFetchConfigItem("sublibraryPrefix", pModule) into tPrefix
    end if
    if (tPrefix is empty) or (tPrefix is FALSE) then
      put rigFetchConfigItem("sublibraryPrefix") into tPrefix
    end if

		put gRigA["APPPATH"] & tModulePath & "stacks/" & tSubdir & tPrefix & tStackToLoad into tSubStack

		if (char -9 to -1 of tSubStack <> ".livecode") and (char -4 to -1 of tSubStack <> ".rev") then
			put tSubStack & ".livecode" into tSubStackTempA
			put tSubStack & ".rev" into tSubStackTempB

			if there is a file tSubStackTempA then
				put tSubStackTempA into tSubStack
				put TRUE into tSubStackExists
			else if there is a file tSubStackTempB then
				put tSubStackTempB into tSubStack
				put TRUE into tSubStackExists
			end	if

		else if there is a file tSubStack then
			put TRUE into tSubStackExists
		end if

		# IS THIS A STACK EXTENSION REQUEST?
		if tSubStackExists is TRUE then

			# CHECK AND CHANGE FILE EXTENSION AS CORE STACKS SOLELY USE "livecode"
			if (char -4 to -1 of tNameUCfirst is ".rev") then
				put (char 1 to -5 of tNameUCfirst) & ".livecode" into tNameUCfirst
			else if (char -9 to -1 of tNameUCfirst <> ".livecode") then
				put tNameUCfirst & ".livecode" into tNameUCfirst
			end if

			put gRigA["BASEPATH"] & "stacks/" & tNameUCfirst into tBaseStack

			if there is a file tBaseStack then
			else
				rigLogMessage "error", "Unable to load the requested stack:" && tStackToLoad
				rigShowError "Unable to load the requested stack:" && tStackToLoad
			end if

			# SAFETY: WAS THE STACK ALREADY LOADED BY A PREVIOUS CALL?
			if sLoaderA["riLoadedStackFiles"] is an array then

				put FALSE into tStackInArray
				repeat for each element thisElement in sLoaderA["riLoadedStackFiles"]
					if thisElement is tStackToLoad then
						put TRUE into tStackInArray
						exit repeat
					end if
				end repeat

				if tStackInArray is TRUE then
					put TRUE into tIsDuplicate
					rigLogMessage "debug", tStackToLoad && "stack already loaded. Second attempt ignored."
					exit _rigLoadStack
				end if
			end if

			# LOAD BASE STACK AND BASE STACK EXTENSION
			start using stack tBaseStack

			if pPosition is "front" then
        -- go stack tSubStack
				# go stack IS CURRENTLY NOT WORKING PROPERLY, SO THIS
				# IS A WORKAROUND UNTIL THIS HAS CHANGED
        start using stack tSubStack
        set the defaultStack to tStackToLoad
			else
				start using stack tSubStack
			end if

			add 1 to tNumLoadedStacks
			put tSubStack into sLoaderA["riLoadedStackFiles"][tNumLoadedStacks]

			_rigRiInitStack tStackToLoad, tPrefix, pParams
			exit _rigLoadStack

		end if -- if there is a file tSubStack then


		# LETS SEARCH FOR THE REQUESTED STACK FILE AND LOAD IT.
		put FALSE into tIsDuplicate
		put gRigA["APPPATH"] into tPathVariants[1]
		put gRigA["BASEPATH"] into tPathVariants[2]

		repeat for each key tKey in tPathVariants
			put tPathVariants[tKey] into tPathVar

      if tKey is 1 then
        put tPathVar & tModulePath & "stacks/" & tSubdir & tStackToLoad into tFilePath
      else
        put tPathVar & "stacks/" & tSubdir & tStackToLoad into tFilePath
      end if

			if (char -9 to -1 of tFilePath <> ".livecode") and (char -4 to -1 of tFilePath <> ".rev") then
				put tFilePath & ".livecode" into tFilePathTempA
				put tFilePath & ".rev" into tFilePathTempB

				if there is a file tFilePathTempA then
					put tFilePathTempA into tFilePath
					put TRUE into tFilePathExists
				else if there is a file tFilePathTempB then
					put tFilePathTempB into tFilePath
					put TRUE into tFilePathExists
				end	if

			else if there is a file tFilePath then
				put TRUE into tFilePathExists
			end if

			if tFilePathExists <> TRUE then
				next repeat
			end if

			# SAFETY:  WAS THE STACK ALREADY LOADED BY A PREVIOUS CALL?
			if sLoaderA["riLoadedStackFiles"] is an array then

				put FALSE into tFileIsInArray
				repeat for each element thisElement in sLoaderA["riLoadedStackFiles"]
					if thisElement is tFilePath then
						put TRUE into tFileIsInArray
						exit repeat
					end if
				end repeat

				if tFileIsInArray is TRUE then
					put TRUE into tIsDuplicate
					rigLogMessage "debug", tStackToLoad && "stack already loaded. Second attempt ignored."
					exit _rigLoadStack
				end if
			end if

			if pPosition is "front" then
        -- go stack tFilePath
				# go stack IS CURRENTLY NOT WORKING PROPERLY, SO THIS
				# IS A WORKAROUND UNTIL THIS HAS CHANGED
        start using stack tFilePath
        set the defaultStack to tStackToLoad
			else
				start using stack tFilePath
			end if

			add 1 to tNumLoadedStacks
			put tFilePath into sLoaderA["riLoadedStackFiles"][tNumLoadedStacks]

			_rigRiInitStack tStackToLoad, "", pParams
			exit _rigLoadStack

		end repeat
	end repeat -- for each key tKey in tNameVariants

	# ONE LAST ATTEMPT.  MAYBE THE STACK IS IN A SUBDIRECTORY, BUT IT WASN'T SPECIFIED?
	if tSubdir is "" then
		put toLower(tStack) & "/" & tStackToLoad into tPathNotSpecified
		_rigLoadStack tPathNotSpecified, pPosition, pModule
		exit _rigLoadStack
	end if

	# IF WE GOT THIS FAR WE WERE UNABLE TO FIND THE REQUESTED STACK.
	# WE DO NOT ISSUE ERRORS IF THE LOAD CALL FAILED DUE TO A DUPLICATE REQUEST
	if tIsDuplicate is FALSE then
		rigLogMessage "error", "Unable to load the requested stack:" && tStackToLoad
		rigShowError "Unable to load the requested stack:" && tStackToLoad
	end if
end _rigLoadStack





/*----------------------------------------------------------------------
--| FUNCTION rigLibIsLoaded
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: --
--|
--| Summary: Check if a given library is loaded.
--|
--| Format:  rigLibIsLoaded(param1)
--|
--| Parameters: string <pName>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigLibIsLoaded pName
  local tLoadedLibs

	if sLoaderA["riLibs"] is not an array then
		return FALSE
	end if

	put sLoaderA["riLibs"] into tLoadedLibs

	combine tLoadedLibs using comma
	return (pName is among the items of tLoadedLibs)
end rigLibIsLoaded







/*----------------------------------------------------------------------
--| FUNCTION rigHelperIsLoaded
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: --
--|
--| Summary: Check if a given helper is loaded.
--|
--| Format:  rigHelperIsLoaded(param1)
--|
--| Parameters: string <pName>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigHelperIsLoaded pName
  local tLoadedHelpers

	if sLoaderA["riHelpers"] is not an array then
		return FALSE
	end if

	put sLoaderA["riHelpers"] into tLoadedHelpers

	combine tLoadedHelpers using comma
	return (pName is among the items of tLoadedHelpers)
end rigHelperIsLoaded







/*----------------------------------------------------------------------
--| COMMAND _rigRiInitLibrary
--|
--| Author: rabit
--| Version:  1.7
--| Created: 07-07-09
--| Last Mod: 12-12-15
--| Requires: --
--|
--| Summary: Load config file associated with loaded library.
--|
--| Format:  _rigRiInitLibrary param1, param2, param3
--|
--| Parameters: string <pLib> the item that is being loaded, string <pPrefix> (optional),
--|               array <pConfig> (optional), string <pModule> the module name (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigRiInitLibrary pLib pPrefix pConfig pModule
  local tConfigFileFound, tLibsKeyNum, tModulePath, tNameLower
  local tFirstCharUpper, tNameUCfirst, tPath, tLibName, tHandler

	put FALSE into tConfigFileFound

	if sLoaderA["riLibs"] is an array then
		put the number of lines in the keys of sLoaderA["riLibs"] into tLibsKeyNum
	else
		put 0 into tLibsKeyNum
	end if

  # CHECK IF WE ARE DEALING WITH A REQUEST FROM A MODULE
  if pModule <> empty then
      # GET PATH TO models FOLDER OF MODULE RELATIVE TO gRigA["APPPATH"]
      put "modules/" & pModule & "/" into tModulePath
  end if

	# IS THERE AN ASSOCIATED CONFIG FILE FOR THIS LIBRARY?
	if pConfig is not an array then
		# WE TEST FOR BOTH UPPERCASE AND LOWERCASE, FOR SERVERS THAT
		# ARE CASE-SENSITIVE WITH REGARD TO FILE NAMES
		put toLower(pLib) into tNameLower
		put toupper(char 1 of tNameLower) into tFirstCharUpper
		put tFirstCharUpper & (char 2 to -1 of tNameLower) into tNameUCfirst

    -- put gRigA["APPPATH"] & tModulePath & "config/" & tNameLower & ".livecodescript" into tPath
     put gRigA["APPPATH"] & tModulePath & "config/" & tNameLower & gRigA["EXT"] into tPath
		if there is a file tPath then
      -- start using stack tPath
      _rigRequire tPath
			put TRUE into tConfigFileFound
		else
			-- put gRigA["APPPATH"] & tModulePath & "config/" & tNameUCfirst & ".livecodescript" into tPath
      put gRigA["APPPATH"] & tModulePath & "config/" & tNameUCfirst & gRigA["EXT"] into tPath
			if there is a file tPath then
        -- start using stack tPath
        _rigRequire tPath
				put TRUE into tConfigFileFound
			end if
		end if
	end if

	if pPrefix is empty then
		put pLib into tLibName
	else
		put pPrefix & pLib into tLibName
	end if

	add 1 to tLibsKeyNum
	put tLibName into sLoaderA["riLibs"][tLibsKeyNum]

	# RUN THE CONFIGURATION HANDLER IF NO CONFIGURATION FILE WAS FOUND
	# OTHERWISE, THIS IS DONE BY THE CONFIGURATION FILE ITSELF
	if tConfigFileFound is not TRUE then
		put "rigRunInitial" & pLib & "Config" into tHandler
		combine pConfig using numToCodepoint(1) and numToCodepoint(2)

		do tHandler && quote & pConfig & quote
	end if
end _rigRiInitLibrary





/*----------------------------------------------------------------------
--| COMMAND _rigRiInitStack
--|
--| Author: rabit
--| Version:  1.1
--| Created: 31-07-2011
--| Last Mod: 22-12-2014
--| Requires: --
--|
--| Summary: Load config file associated with loaded stack.
--|
--| Format:  _rigRiInitStack param1, param2, param3
--|
--| Parameters: string <pStack> the item that is being loaded, string <pPrefix>, array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigRiInitStack pStack pPrefix pConfig
  local tConfigFileFound, tStacksKeyNum, tNameLower, tFirstCharUpper
  local tNameUCfirst, tPath, tStackName, tHandler

	put FALSE into tConfigFileFound

	if sLoaderA["riStacks"] is an array then
		put the number of lines in the keys of sLoaderA["riStacks"] into tStacksKeyNum
	else
		put 0 into tStacksKeyNum
	end if

	# IS THERE AN ASSOCIATED CONFIG FILE FOR THIS LIBRARY?
	if pConfig is not an array then
		# WE TEST FOR BOTH UPPERCASE AND LOWERCASE, FOR SERVERS THAT
		# ARE CASE-SENSITIVE WITH REGARD TO FILE NAMES
		put toLower(pStack) into tNameLower
		put toupper(char 1 of tNameLower) into tFirstCharUpper
		put tFirstCharUpper & (char 2 to -1 of tNameLower) into tNameUCfirst

    -- put gRigA["APPPATH"] & "config/" & tNameLower & ".livecodescript" into tPath
     put gRigA["APPPATH"] & "config/" & tNameLower & gRigA["EXT"] into tPath
		if there is a file tPath then
      -- start using stack tPath
      _rigRequire tPath
			put TRUE into tConfigFileFound
		else
			-- put gRigA["APPPATH"] & "config/" & tNameUCfirst & ".livecodescript" into tPath
      put gRigA["APPPATH"] & "config/" & tNameUCfirst & gRigA["EXT"] into tPath
			if there is a file tPath then
        -- start using stack tPath
        _rigRequire tPath
				put TRUE into tConfigFileFound
			end if
		end if
	end if

	put pPrefix & pStack into tStackName

	add 1 to tStacksKeyNum
	put tStackName into sLoaderA["riStacks"][tStacksKeyNum]

	# RUN THE CONFIGURATION HANDLER IF NO CONFIGURATION FILE WAS FOUND
	# OTHERWISE, THIS IS DONE BY THE CONFIGURATION FILE ITSELF
	if tConfigFileFound is not TRUE then
		put "rigRunInitial" & pStack & "StackConfig" into tHandler
		combine pConfig using numToCodepoint(1) and numToCodepoint(2)

		do tHandler && quote & pConfig & quote
	end if
end _rigRiInitStack






/*----------------------------------------------------------------------
--| FUNCTION rigFetchDBlibLoaded
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-07-09
--| Last Mod: 22-07-09
--| Requires: --
--|
--| Summary: This function checks if the database libraries are loaded.
--|
--| Format:  rigFetchDBlibLoaded()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigFetchDBlibLoaded
	if sLoaderA["riDBlibLoaded"] is TRUE then
		return TRUE
	else
		return FALSE
	end if
end rigFetchDBlibLoaded










/*----------------------------------------------------------------------
--| COMMAND _rigSetViewPath
--|
--| Author: rabit
--| Version:  1.0
--| Created: 26-01-10
--| Last Mod: 26-01-10
--| Requires: --
--|
--| Set path to view files (needed by Scaffolding.lc and modules).
--|
--| Format:  _rigSetViewPath param1
--|
--| Parameters: string <pPath>
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigSetViewPath pPath
	put pPath into sLoaderA["riViewPath"]
end _rigSetViewPath








/*----------------------------------------------------------------------
--| FUNCTION _rigGetViewPath
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-11-2015
--| Last Mod: 19-11-2015
--| Requires: --
--|
--| Summary: Get path to view files (needed by modules).
--|
--| Format:  _rigGetViewPath()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigGetViewPath
  return sLoaderA["riViewPath"]
end _rigGetViewPath







/*----------------------------------------------------------------------
--| COMMAND rigLoadAutoLoad
--|
--| Author: rabit
--| Version:  1.0
--| Created: 03-12-2015
--| Last Mod: 03-12-2015
--| Requires: rigShowError, rigLogMessage
--|
--| Summary: Load a modules autoload file.
--|
--| Format:  rigLoadAutoLoad param1, param2
--|
--| Parameters: string <pModule>, bool <pFailGracefully>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigLoadAutoLoad pModule pFailGracefully
  local tFailGracefully, tFilepath

  if pFailGracefully is empty then
    put FALSE into tFailGracefully
  else
    put pFailGracefully into tFailGracefully
  end if

  # CHECK IF autoload FILE EXISTS
  set the itemDel to "/"
  -- put gRigA["APPPATH"] & "modules/" & pModule & "/config/autoload" & ".livecodescript" into tFilepath
  put gRigA["APPPATH"] & "modules/" & pModule & "/config/autoload" & gRigA["EXT"] into tFilepath

  if there is a file tFilepath then
  else
    if pFailGracefully is TRUE then
      return FALSE
    else
      rigShowError "The autoload file of module" && pModule & "does not exist."
    end if
  end if

  -- start using stack tFilepath
  _rigRequire tFilepath

  rigLogMessage "debug", "Autoload file of module" && pModule && "loaded."

  -- _rigModuleAutoloader pModule
  _rigAutoloader pModule

  return the result
end rigLoadAutoLoad





/*----------------------------------------------------------------------
--| FUNCTION rigLoaderGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Get loader array variable value.
--|
--| Format:  rigLoaderGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigLoaderGet pWhat
  if pWhat is among the keys of sLoaderA then
    return sLoaderA[pWhat]
  end if

  return empty
end rigLoaderGet




/*----------------------------------------------------------------------
--| COMMAND rigLoaderSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Setter for loader variables.
--|
--| Format:  rigLoaderSet param1, param2
--|
--| Parameters: string <pKey> sLoaderA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigLoaderSet pKey pVal
  if pKey is among the keys of sLoaderA then
    put pVal into sLoaderA[pKey]
  end if
end rigLoaderSet








--| END OF Loader.livecodescript
--| Location:  ./system/libraries/Loader.livecodescript
----------------------------------------------------------------------