script "Language"

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
# revIgniter Language Library
#
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Language
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/language.html
##




global gRigA, gLang

local sLangIsLoaded, sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-11
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
        rigLogMessage "debug", "Language Library Loaded"
      end if
    end if
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack






/*----------------------------------------------------------------------
--| FUNCTION rigLangLoadLang
--|
--| Author: rabit
--| Version:  1.5
--| Created: 02-07-09
--| Last Mod: 09-03-16
--| Requires: rigFetchConfigItem(), rigShowError, rigLogMessage
--|
--| Summary: Load a language file.
--| 
--| Format:  rigLangLoadLang(param1, param2, param3)
--|
--| Parameters: mixed <pLangFiles> the name of the language file to be loaded (can be an array),
--|               string <pIdiom> the language , string <pModule> module (folder) name
--|               <pReturn> boolean used to return the language array (this is not documented but
--|               needed by the Scaffolding library)
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigLangLoadLang pLangFiles pIdiom pModule pReturn
  local tLangIsLoadedKeyNum, tLangFiles, tModulePath, tFilePrefix
  local tLangFile, tLangFileIsInArray, tDefaultLang, tIdiom, tExtLang
  local tSysLang
  
	if sLangIsLoaded is an array then
		put the number of lines in the keys of sLangIsLoaded into tLangIsLoadedKeyNum
	else
		put 0 into tLangIsLoadedKeyNum
	end if

	put pLangFiles into tLangFiles
	if tLangFiles is not an array then
		put tLangFiles into tLangFiles[1]
	end if
  
  put empty into tModulePath
  put empty into tFilePrefix
  
  # CHECK IF WE ARE DEALING WITH A REQUEST OF A MODULE
  if pModule <> empty then
    # GET PATH TO models FOLDER OF MODULE RELATIVE TO gRigA["APPPATH"]
    put "modules/" & pModule & "/" into tModulePath
    put pModule & "/" into tFilePrefix
  end if

  repeat for each element tLangFile in tLangFiles
    put toLower(tLangFile) into tLangFile
    replace "Lang" with "" in tLangFile
    replace gRigA["EXT"] with "" in tLangFile
    put tLangFile & "Lang" into tLangFile

    # IS THE LANG FILE ALREADY LOADED
    if sLangIsLoaded is an array then
      put FALSE into tLangFileIsInArray
      repeat for each element thisElement in sLangIsLoaded
        if thisElement is (tFilePrefix & tLangFile) then
          put TRUE into tLangFileIsInArray
          exit repeat
        end if
      end repeat
      if tLangFileIsInArray is TRUE then
        exit rigLangLoadLang
      end if
    end if

    # CHECK IDIOM
    if pIdiom is empty then
      # CONSIDER MODULE SETTINGS TOO IF AVAILABLE
      put rigFetchConfigItem("language", pModule) into tDefaultLang
      if tDefaultLang is empty then
        put "english" into tDefaultLang
      end if
      put tDefaultLang into tIdiom
    else
      put pIdiom into tIdiom
    end if

    put gRigA["APPPATH"] & tModulePath & "language/" & tIdiom & "/" & tLangFile & gRigA["EXT"] into tExtLang
    put gRigA["BASEPATH"] & "language/" & tIdiom & "/" & tLangFile & gRigA["EXT"] into tSysLang

    # DETERMINE WHERE THE LANGUAGE FILE IS AND LOAD IT
    if there is a file tExtLang then
      _rigRequire tExtLang
    else if there is a file tSysLang then
      _rigRequire tSysLang
    else
      rigShowError "Unable to load the requested language file: language/" & tIdiom & "/" & tLangFile
    end if
  end repeat

	if the number of lines in the keys of gLang is 0 then
		rigLogMessage "error", "Language file contains no data: language/" & tIdiom & "/" & tLangFile
		exit rigLangLoadLang
	end if

  # THIS IS NOT DOCUMENTED BUT NEEDED BY THE SCAFFOLDING LIBRARY
	if (pReturn is a boolean) and (pReturn is TRUE) then
		return gLang
	end if

	add 1 to tLangIsLoadedKeyNum
	put tFilePrefix & tLangFile into sLangIsLoaded[tLangIsLoadedKeyNum]

	rigLogMessage "debug", "Language file loaded: language/" & tIdiom & "/" & tLangFile
	return TRUE

end rigLangLoadLang






/*----------------------------------------------------------------------
--| FUNCTION rigLangLangLine
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-07-09
--| Last Mod: 14-08-09
--| Requires: --
--|
--| Summary: Fetch a single line of text from the language array.
--| 
--| Format:  rigLangLangLine(param1)
--|
--| Parameters: string <pLine> the language line
--|
--| Return: string
----------------------------------------------------------------------*/

function rigLangLangLine pLine
  local tLine
  
	if pLine is empty or gLang[pLine] is empty then
		put FALSE into tLine
		return tLine
	else
		put gLang[pLine] into tLine
	end if

	return tLine
end rigLangLangLine






--| END OF Language.livecodescript
--| Location:  ./system/libraries/Language.livecodescript
----------------------------------------------------------------------