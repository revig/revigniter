script "DBcache"

##
# revIgniter
#
# An application development framework for LiveCode
# modeled on CodeIgniter
#
# @package		revIgniter
# @author		  rabit@revigniter.com
# @copyright	Copyright (c) 2009 - 2020, dimensionB Bitter u. Bitter GmbH
# @license		https://revigniter.com/userGuide/license.html
# @link		    https://revigniter.com
##

## ------------------------------------------------------------------------

##
# Database Cache Library
#
#
# @package		revIgniter
# @category	  Database
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/database/
##




global gRigA

local sStackInUse





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-17
 --| Last Mod: --
 --| Requires: _rigDBcache
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
   
      # CALL INITIAL HANDLERS
      _rigDBcache
    end if
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack






/*----------------------------------------------------------------------
--| COMMAND _rigDBcache
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-07-09
--| Last Mod: 12-07-09
--| Requires: rigLoadHelper
--|
--| Summary: Load the file helper since we use it a lot.
--| 
--| Format:  _rigDBcache
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/
private command _rigDBcache
	rigLoadHelper "file"
end _rigDBcache








/*----------------------------------------------------------------------
--| FUNCTION _rigCheckCachePath
--|
--| Author: rabit
--| Version:  1.1
--| Created: 12-07-09
--| Last Mod: 02-10-09
--| Requires: rigFetchDBdriverSetting(), rigDbDriver, rigAddTrailingSlash()
--|
--| Summary: Set cache directory path.
--| 
--| Format:  _rigCheckCachePath(param1)
--|
--| Parameters: string <pPath> the path to the cache directory
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigCheckCachePath pPath
  local tPath, tCacheDir
  
	put pPath into tPath
	put rigFetchDBdriverSetting("cachedir") into tCacheDir

	if tPath is "" then
		if tCacheDir is "" then
			return rigDbCacheOff()
		end if

		put tCacheDir into tPath
	end if

	# ADD A TRAILING SLASH TO THE PATH IF NEEDED
	put rigAddTrailingSlash(tPath) into tPath

	if (there is not a folder tPath) or (rigCanWriteFileTo(tPath) is FALSE) then
		# IF THE PATH IS WRONG WE'LL TURN OFF CACHING
		return rigDbCacheOff()
	end if

	--put tPath into tDBdriverSettings["cachedir"]
	--rigDbDriver tDBdriverSettings["cachedir"]
	rigSetDBdriverSetting "cachedir", tPath

	return TRUE
end _rigCheckCachePath







/*----------------------------------------------------------------------
--| FUNCTION rigReadSQLcache
--|
--| Author: rabit
--| Version:  1.3
--| Created: 13-07-09
--| Last Mod: 02-02-15
--| Requires: _rigCheckCachePath(), rigFetchSegment(), rigFetchDBdriverSetting(),
--|            rigAddTrailingSlash(), rigHexDigest(), rigLogMessage
--|
--| Summary: The URI being requested will become the name of the cache sub-folder.
--|             An rigHexDigest hash of the SQL statement will become the cache file name.
--| 
--| Format:  rigReadSQLcache(param1)
--|
--| Parameters: string <pSQL>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigReadSQLcache pSQL
  local tSegmentOne, tSegmentTwo, tCacheDir, tFilepath, tCacheData
  
	if _rigCheckCachePath() is not TRUE then
		return rigDbCacheOff()
	end if

	put rigFetchSegment(1) into tSegmentOne
	if tSegmentOne is FALSE then
		put "default" into tSegmentOne
	end if

	put rigFetchSegment(2) into tSegmentTwo
	if tSegmentTwo is FALSE then
		put "index" into tSegmentTwo
	end if

	put rigFetchDBdriverSetting("cachedir") into tCacheDir

	# ADD A TRAILING SLASH TO THE PATH IF NEEDED
	put rigAddTrailingSlash(tCacheDir) into tCacheDir

	-- put tCacheDir & tSegmentOne & "+" & tSegmentTwo & "/" & md5Digest(pSQL) into tFilepath
	put tCacheDir & tSegmentOne & "+" & tSegmentTwo & "/" & rigHexDigest(pSQL) into tFilepath

	if there is a file tFilepath then
		put URL format("binfile:%s", tFilepath) into tCacheData
		
    if the result <> empty then
      rigLogMessage "error", "Failed to read file! System error:" && the sysError
      return FALSE
    end if
		
	else
		return FALSE
	end if

	if tCacheData is empty then
		return FALSE
	end if

	return tCacheData
end rigReadSQLcache







/*----------------------------------------------------------------------
--| FUNCTION rigWriteSQLcache
--|
--| Author: rabit
--| Version:  1.5
--| Created: 2009-07-13
--| Last Mod: 2018-12-17
--| Requires: _rigCheckCachePath(), rigFetchSegment(), rigFetchDBdriverSetting(),
--|            rigAddTrailingSlash(), rigHexDigest(), rigLogMessage
--|
--| Summary: Write a query to a cache file.
--| 
--| Format:  rigWriteSQLcache(param1)
--|
--| Parameters: string <pSQL>, string <pSQLdata>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigWriteSQLcache pSQL pSQLdata
  local tSegmentOne, tSegmentTwo, tCacheDir, tFileName, tCurrentUmask
  
	if _rigCheckCachePath() is not TRUE then
		return rigDbCacheOff()
	end if

	put rigFetchSegment(1) into tSegmentOne
	if tSegmentOne is FALSE then
		put "default" into tSegmentOne
	end if

	put rigFetchSegment(2) into tSegmentTwo
	if tSegmentTwo is FALSE then
		put "index" into tSegmentTwo
	end if

	put rigFetchDBdriverSetting("cachedir") into tCacheDir

	# ADD A TRAILING SLASH TO THE PATH IF NEEDED
	put rigAddTrailingSlash(tCacheDir) into tCacheDir

	put tCacheDir & tSegmentOne & "+" & tSegmentTwo & "/" into tCacheDir

	put rigHexDigest(pSQL) into tFileName

  set the convertOctals to true
  put the umask into tCurrentUmask
  set the umask to rigConstant("DIR_WRITE_UMASK")
	create folder tCacheDir

	if there is not a folder tCacheDir then
		set the umask to tCurrentUmask
		return FALSE
	end if

  set the umask to rigConstant("FILE_WRITE_UMASK")
	put pSQLdata into URL ("binfile:" & tCacheDir & tFileName)
	
  if the result <> empty then
    rigLogMessage "error", "Failed to write file! System error:" && the sysError
  end if

	set the umask to tCurrentUmask

	if there is not a file (tCacheDir & tFileName) then
		return FALSE
	else
		return TRUE
	end if

end rigWriteSQLcache







/*----------------------------------------------------------------------
--| COMMAND rigDeleteDBcacheFiles
--|
--| Author: rabit
--| Version:  1.2
--| Created: 13-07-09
--| Last Mod: 01-01-10
--| Requires: rigFetchDBdriverSetting(), rigDeleteFiles, rigAddTrailingSlash()
--|
--| Summary: Delete cache files within a particular directory.
--| 
--| Format:  rigDeleteDBcacheFiles param1, param2
--|
--| Parameters: string <pSegmentOne> uri segment, string <pSegmentTwo> uri segment
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDeleteDBcacheFiles pSegmentOne pSegmentTwo
  local tSegmentOne, tSegmentTwo, tCacheDir
  
	if pSegmentOne is "" then
		put "default" into tSegmentOne
	else
		put pSegmentOne into tSegmentOne
	end if

	if pSegmentTwo is "" then
		put "index" into tSegmentTwo
	else
		put pSegmentTwo into tSegmentTwo
	end if

	put rigFetchDBdriverSetting("cachedir") into tCacheDir

	# ADD A TRAILING SLASH TO THE PATH IF NEEDED
	put rigAddTrailingSlash(tCacheDir) into tCacheDir

	put tCacheDir & tSegmentOne & "+" & tSegmentTwo & "/" into tCacheDir

	rigDeleteFiles tCacheDir, TRUE
end rigDeleteDBcacheFiles







/*----------------------------------------------------------------------
--| COMMAND rigDeleteAllDBcacheFiles
--|
--| Author: rabit
--| Version:  1.1
--| Created: 13-07-09
--| Last Mod: 31-12-09
--| Requires: rigFetchDBdriverSetting(), rigAddTrailingSlash(), rigDeleteFiles
--|
--| Summary: Delete all existing sql cache files.
--| 
--| Format:  rigDeleteAllDBcacheFiles param1
--|
--| Parameters: string <pExclusion> file name to exclude (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDeleteAllDBcacheFiles pExclusion
  local tCacheDir
  
	put rigFetchDBdriverSetting("cachedir") into tCacheDir

	# ADD A TRAILING SLASH TO THE PATH IF NEEDED
	put rigAddTrailingSlash(tCacheDir) into tCacheDir

	rigDeleteFiles tCacheDir, TRUE, pExclusion
end rigDeleteAllDBcacheFiles






--| END OF DBcache.livecodescript
--| Location:  ./system/database/DBcache.livecodescript
----------------------------------------------------------------------