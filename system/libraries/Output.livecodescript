script "Output"

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
# revIgniter Output Library
#
# Responsible for sending final output to browser
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Output
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/output.html
##



global gRigA, gControllerHandlers, g_ElapsedTime_

local sStackInUse, sOutputA -- array keys are: cacheExpiration, enableProfiler, finalOutput, headers, profilerPrefs





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-06
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
        rigLogMessage "debug", "Output Library Loaded"
      end if

      # SET INITIAL VALUES
      _rigSetDefaultValues
      #
    end if

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
  put 0 into sOutputA["cacheExpiration"]
  put FALSE into sOutputA["enableProfiler"]
end _rigSetDefaultValues




----------------------------------------------------------------------
--| FUNCTION rigGetOutput
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-10-09
--| Last Mod: 10-10-09
--| Requires: --
--|
--| Summary:  Returns the current output string.
--|
--| Format:  rigGetOutput()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------

function rigGetOutput
	return sOutputA["finalOutput"]
end rigGetOutput








----------------------------------------------------------------------
--| COMMAND rigSetOutput
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-10-09
--| Last Mod: 10-10-09
--| Requires: --
--|
--| Summary:  Sets the output string.
--|
--| Format:  rigSetOutput param1
--|
--| Parameters: string <pOutput>
--|
--| Return: empty
----------------------------------------------------------------------

command rigSetOutput pOutput
	put pOutput into sOutputA["finalOutput"]
end rigSetOutput








----------------------------------------------------------------------
--| COMMAND rigAppendOutput
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-06-09
--| Last Mod: 19-06-09
--| Requires: --
--|
--| Summary:  Appends data onto the output string.
--|
--| Format:  rigAppendOutput param1
--|
--| Parameters: string <pOutput>
--|
--| Return: empty
----------------------------------------------------------------------

command rigAppendOutput pOutput
	if sOutputA["finalOutput"] is "" then
		put pOutput into sOutputA["finalOutput"]
	else
		put sOutputA["finalOutput"] & return & pOutput into sOutputA["finalOutput"]
	end if
end rigAppendOutput






----------------------------------------------------------------------
--| COMMAND rigSetHeader
--|
--| Author: rabit
--| Version:  1.1
--| Created: 19-06-09
--| Last Mod: 21-06-09
--| Requires: --
--|
--| Summary:  Lets you set a server header which will be outputted with the final display.
--|                    Note:  If a file is cached, headers will not be sent.
--|
--| Format:  rigSetHeader param1, param2
--|
--| Parameters: string <pHeader>, bool <pReplace> replace header
--|
--| Return: empty
----------------------------------------------------------------------

command rigSetHeader pHeader pReplace
  local tReplace, tNumHeaders, tNewHeaderKey

	if pReplace is empty then
		put TRUE into tReplace
	else
		put pReplace into tReplace
	end if

	if sOutputA["headers"] is an array then
		put the number of lines in the keys of sOutputA["headers"] into tNumHeaders
		put tNumHeaders + 1 into tNewHeaderKey
		-- put pHeader into sOutputA["headers"][tNewHeaderKey]
		put tReplace into sOutputA["headers"][tNewHeaderKey][pHeader]
	else
		-- put pHeader into sOutputA["headers"][1]
		put tReplace into sOutputA["headers"][1][pHeader]
	end if
end rigSetHeader







----------------------------------------------------------------------
--| COMMAND rigEnableProfiler
--|
--| Author: rabit
--| Version:  1.1
--| Created: 10-10-09
--| Last Mod: 22-01-10
--| Requires: --
--|
--| Summary:  Enable/disable Profiler.
--|
--| Format:  rigEnableProfiler param1 param2
--|
--| Parameters: bool <pVal>, array <pPrefs>
--|
--| Return: empty
----------------------------------------------------------------------

command rigEnableProfiler pVal pPrefs
  local tVal

	if pVal is empty then
		put TRUE into tVal
	else
		put pVal into tVal
	end if

	if tVal is a boolean then
		put tVal into sOutputA["enableProfiler"]
	else
		put TRUE into sOutputA["enableProfiler"]
	end if

	put pPrefs into sOutputA["profilerPrefs"]
end rigEnableProfiler







----------------------------------------------------------------------
--| COMMAND rigOutputCache
--|
--| Author: rabit
--| Version:  1.0
--| Created: 25-07-09
--| Last Mod: 25-07-09
--| Requires: --
--|
--| Summary:  Set cache.
--|
--| Format:  rigOutputCache param1
--|
--| Parameters: integer <pTime> duration as minutes
--|
--| Return: empty
----------------------------------------------------------------------

command rigOutputCache pTime
	if pTime is not an integer then
		put 0 into sOutputA["cacheExpiration"]
	else
		put pTime into sOutputA["cacheExpiration"]
	end if
end rigOutputCache







/*----------------------------------------------------------------------
--| COMMAND _rigDisplay
--|
--| Author: rabit
--| Version:  2.7
--| Created: 2009-06-19
--| Last Mod: 2018-10-16
--| Requires: Log, _writeCache, _output, rigLogMessage, rigFetchConfigItem()
--|
--| Summary:  All "view" data is automatically put into this variable by the
--|           	 Loader library: sOutputA["finalOutput"]
--|
--|           	 This handler sends the finalized output data to the browser along
--|           	 with any server headers and profile data. It also stops the
--|           	 benchmark timer so the page rendering speed can be shown.
--|
--| Format:  _rigDisplay param1, param2
--|
--| Parameters: string <pOutput>, bool <pCached>
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigDisplay pOutput, pCached
  local tOutput, tElapsed, tIsAuthCookie, tLastCookieHeaderWasAuthCookie
  local tLastCookieHeaderWasCSRFcookie, tIsCSRFcookie, tCookieHeadersSet, tContentHeaderSet
  local tKey, tHeader, tDoNotReplaceLastCookie, tCharset, tRegEx, tDoGzip, tOutputLength

	put FALSE into tContentHeaderSet

	# SET THE OUTPUT DATA
	if pOutput is "" then
		put sOutputA["finalOutput"] into tOutput
	else
		put pOutput into tOutput
	end if

	# DO WE NEED TO WRITE A CACHE FILE?
	if sOutputA["cacheExpiration"] > 0 then
		_rigWriteCache tOutput
	end if

	# PARSE OUT THE ELAPSED TIME
	put rigElapsedTime("totalExecutionTime_start", "totalExecutionTime_end", 4) into tElapsed

	# SWAP THE VARIABLES WITH THE DATA, WHICH NEED TO BE UPDATED IN CACHED PAGES
	put rigCacheVarsMerged(tOutput) into tOutput

	# ARE THERE ANY SERVER HEADERS TO SEND?
	if sOutputA["headers"] is an array then
		if (the number of lines in the keys of sOutputA["headers"]) > 0 then
      # AUTH COOKIES CONTROL VARIABLES
			put FALSE into tIsAuthCookie
			put FALSE into tLastCookieHeaderWasAuthCookie

			# CSRF CONTROL VARIABLES
			put FALSE into tIsCSRFcookie
			put FALSE into tLastCookieHeaderWasCSRFcookie

			put 0 into tCookieHeadersSet

			repeat for each key tKey in sOutputA["headers"]
				 repeat for each key tHeader in sOutputA["headers"][tKey]

					 if word 1 of tHeader is "Content-Type:" then
						 put TRUE into tContentHeaderSet
					 end if

           # CHECK IF HEADER CONTAINS AN AUTHENTICATION  COOKIE
           set the itemDel to "="
           if char 1 to 10 of tHeader is "Set-Cookie" then
             add 1 to tCookieHeadersSet

             if ("rememberCode" is in item 1 of tHeader) or ("identity" is in item 1 of tHeader) then
               put TRUE into tIsAuthCookie
             end if

             # CHECK IF HEADER CONTAINS A CSRF COOKIE
             if rigFetchConfigItem("csrf_protection") is TRUE then
               if rigFetchConfigItem("csrf_cookie_name") is in item 1 of tHeader then
                 put TRUE into tIsCSRFcookie
               end if
             end if
           end if -- if char 1 to 10 of tHeader is "Set-Cookie"

					if sOutputA["headers"][tKey][tHeader] is FALSE then
						# DON'T REPLACE HEADER
						put new header tHeader

            # SET THE APPROPRIATE VALUES FOR THE AUTHENTICATION COOKIE CONTROL VARIABLES
						if tIsAuthCookie is TRUE then
                put TRUE into tDoNotReplaceLastCookie
							put FALSE into tIsAuthCookie
						end if

						# SET THE APPROPRIATE VALUES FOR THE CSRF COOKIE CONTROL VARIABLES
						if tIsCSRFcookie is TRUE then
							put TRUE into tDoNotReplaceLastCookie
							put FALSE into tIsCSRFcookie
						end if


					else
						# REPLACE HEADER BUT DON'T REPLACE CSRF COOKIE
              if tCookieHeadersSet > 1 \
                and tDoNotReplaceLastCookie is TRUE \
                and tIsCSRFcookie is FALSE \
                and tIsAuthCookie is FALSE then

							# RESET CONTROL VARIABLES
							put 0 into tCookieHeadersSet
              	put FALSE into tDoNotReplaceLastCookie

							# SET NEW HEADER
							put new header tHeader
						else
							# REPLACE HEADER
							put header tHeader

              	# SET THE APPROPRIATE VALUES FOR THE AUTHENTICATION COOKIE CONTROL VARIABLES
                if tIsAuthCookie is TRUE or tIsCSRFcookie is TRUE then
                  put TRUE into tDoNotReplaceLastCookie
                  put FALSE into tIsAuthCookie
                  put FALSE into tIsCSRFcookie
  						end if

						end if

					end if -- if sOutputA["headers"][tKey][tHeader] is FALSE then
        end repeat -- repeat for each key tHeader in sOutputA["headers"][tKey]
			end repeat -- repeat for each key tKey in sOutputA["headers"]
		end if
	end if

	# IF CONFIG CHARSET IS SET WE OVERRIDE THE CHARSET HEADER
	# SENT BY THE ENGINE
	put rigFetchConfigItem("charset") into tCharset
  if (tCharset <> empty) and (tContentHeaderSet is FALSE) then
		put header "Content-Type: text/html; charset=" & tCharset
	end if


	# CHECK IF WE ARE DEALING WITH A CACHE FILE.
	# IF SO WE SIMPLY PUT THE DATA AND EXIT.
	if pCached is TRUE then
		# SEND CACHED PAGE TO THE BROWSER!
		rigLogMessage "debug", "Final output sent to browser. Total execution time:" && tElapsed
		put tOutput
		exit _rigDisplay
	end if

	# DO WE NEED TO GENERATE PROFILE DATA?
	# IF SO, LOAD THE PROFILE LIBRARY.
	if sOutputA["enableProfiler"] is TRUE then
		rigLoaderLoadLibrary "Profiler", sOutputA["profilerPrefs"]

		# IF THE OUTPUT DATA CONTAINS CLOSING </BODY> AND </HTML> TAGS
		# WE WILL REMOVE THEM AND ADD THEM BACK AFTER WE INSERT THE PROFILE DATA
		put "(?is)</body>.*?</html>" into tRegEx

		if matchChunk(tOutput, tRegEx) is TRUE then
			put replacetext(tOutput,tRegEx,"") into tOutput
			put rigProfilerOutput() after tOutput
			put "</body></html>" after tOutput
		else
			put rigProfilerOutput() after tOutput
		end if
	end if


	# DOES THE CONTROLLER CONTAIN A HANDLER NAMED _OUTPUT?
	# IF SO SEND THE OUTPUT THERE.  OTHERWISE, PUT IT.
	if "_output" is among the items of gControllerHandlers then
		_output tOutput
	else

		# IS COMPRESSION REQUESTED?
		put rigFetchConfigItem("compress_output") into tDoGzip

		if (tDoGzip is TRUE) and (tOutput <> "") then
			if ($_SERVER["HTTP_ACCEPT_ENCODING"] <> "") AND ("gzip" is in $_SERVER["HTTP_ACCEPT_ENCODING"]) then
				put compress(tOutput) into tOutput
				put the length of tOutput into tOutputLength

				put header "Content-Encoding: gzip"
				put header "Content-Length:" && tOutputLength
			end if

			put header "Vary: Accept-Encoding"

			# SEND IT TO THE BROWSER!
			put binary tOutput
		else
			put tOutput
		end if
	end if

	if tOutput <> "" then
		rigLogMessage "debug", "Final output sent to browser"
	else
		rigLogMessage "debug", "Final output sent to browser. There was no view data."
	end if
	rigLogMessage "debug", "Total execution time: " & tElapsed

	# CHECK IF THERE ARE OPEN DATABASE CONNECTIONS
	if gRigA["databaseID"] is an integer then
		get _rigCloseDB()
	end if
end _rigDisplay





/*----------------------------------------------------------------------
--| COMMAND _rigWriteCache
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2009-07-25
--| Last Mod: 2019-02-28
--| Requires: rigFetchConfigItem(), rigCanWriteFileTo(), rigHexDigest(), rigLogMessage
--|
--| Summary:  Write a cache file.
--|
--| Format:  _rigWriteCache param1
--|
--| Parameters: string <pOutput>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigWriteCache pOutput
  local tPath, tCachePath, tUri, tFlockPath, tLockedCacheFiles, tCounter, tExpire, tDataToWrite
  local tFoundString

	put rigFetchConfigItem("cache_path") into tPath

	if tPath is empty then
		put gRigA["APPPATH"] & "cache/" into tCachePath
	else
		put tPath into tCachePath
	end if

	if (there is not a folder tCachePath) or (rigCanWriteFileTo(tCachePath) is not TRUE) then
		exit _rigWriteCache
	end if

	put rigFetchConfigItem("baseUrl") & rigFetchConfigItem("indexPage") & rigUriString() into tUri

	put tCachePath & rigHexDigest(tUri) into tCachePath

	open file tCachePath for write
  # ENGINE ≥ 7 VERSION
  -- put rigFetchConfigItem("defaultCharset") into tCharset
  -- open file tCachePath for tCharset text write

	if the result is empty then -- success!
		put gRigA["APPPATH"] & "cache/flock.txt" into tFlockPath

		# CHECK IF CACHE FILE IS LOCKED BY ANOTHER CONNECTION
		if there is a file tFlockPath then
			put URL ("binfile:" & tFlockPath) into tLockedCacheFiles

			if the result <> empty then
				rigLogMessage "error", "Failed to read file! System error:" && the sysError
			end if

			put 0 into tCounter
			repeat for each line thisLine in tLockedCacheFiles
				add 1 to tCounter
				if item 2 of thisLine is tCachePath then
					if item 1 of thisLine is "writeLock" then
						# FILE IS LOCKED
						exit _rigWriteCache
					else
						# LOCK FILE
						-- put "writeLock" & "," & tCachePath after tLockedCacheFiles
						put "writeLock" & "," & tCachePath into line tCounter of tLockedCacheFiles
						put tLockedCacheFiles into URL ("binfile:" & tFlockPath)
						if the result is not empty then
							rigLogMessage "error", "Unable to secure a file lock for file at:" && tCachePath && "System error:" && the sysError
							exit _rigWriteCache
						end if
						exit repeat
					end if
				end if
			end repeat

		else
			# WRITE FLOCK FILE AND LOCK FILE
			put "writeLock" & "," & tCachePath & return into tLockedCacheFiles
			put tLockedCacheFiles into URL ("binfile:" & tFlockPath)

      if the result <> empty then
        rigLogMessage "error", "Failed to write to file! System error:" && the sysError
      end if
		end if

		# WRITE CACHE
		put the seconds + (sOutputA["cacheExpiration"] * 60) into tExpire
		put tExpire & "TS--->" & pOutput into tDataToWrite
		write tDataToWrite to file tCachePath

		# SET FILE UNLOCKED
		put URL ("binfile:" & tFlockPath) into tLockedCacheFiles

    if the result <> empty then
      rigLogMessage "error", "Failed to read file! System error:" && the sysError
    end if

		put 0 into tCounter
		repeat for each line thisLine in tLockedCacheFiles
			add 1 to tCounter
			if item 2 of thisLine is tCachePath then
				put thisLine into tFoundString
				put "unlocked" into item 1 of  tFoundString
				put tFoundString into line tCounter of tLockedCacheFiles
				put tLockedCacheFiles into URL ("binfile:" & tFlockPath)

	      if the result <> empty then
	        rigLogMessage "error", "Failed to write to file! System error:" && the sysError
	      end if

				exit repeat
			end if
		end repeat

		close file tCachePath
	else
		exit _rigWriteCache
	end if
end _rigWriteCache




/*----------------------------------------------------------------------
--| FUNCTION _rigOutDisplayCache
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2009-07-25
--| Last Mod: 2019-02-11
--| Requires: rigFetchConfigItem(), rigCanWriteFileTo(), rigHexDigest(), rigLogMessage, _rigDisplay
--|
--| Summary:  Update/serve a cached file.
--|
--| Format:  _rigOutDisplayCache()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function _rigOutDisplayCache
  local tCachePath, tUri, tFilePath, tCache, tRegEx, tCachedTime, tCachedStringOffset
  local tCachedString, tCached

	put rigFetchConfigItem("cache_path") into tCachePath

	if tCachePath is empty then
		put gRigA["APPPATH"] & "cache/" into tCachePath
	end if

	if (there is not a folder tCachePath) or (rigCanWriteFileTo(tCachePath) is not TRUE) then
		return FALSE
	end if

	# BUILD THE FILE PATH.  THE FILE NAME IS AN Md5 HASH OF THE FULL URI
	put rigFetchConfigItem("baseUrl") & rigFetchConfigItem("indexPage") & rigUriString() into tUri

	put tCachePath & rigHexDigest(tUri) into tFilePath

	if there is not a file tFilePath then
		return FALSE
	end if

	open file tFilePath for read
  # ENGINE ≥ 7 VERSION
  -- put rigFetchConfigItem("defaultCharset") into tCharset
  -- open file tFilePath for tCharset text read

	if the result is not empty then
		return FALSE
	end if

	read from file tFilePath until EOF
	put it into tCache
	close file tFilePath
	if the number of chars of tCache = 0 then
		return FALSE
	end if

	# STRIP OUT THE EMBEDDED TIMESTAMP
	--put "(\d+)TS--->(.+)" into tRegEx
	--get matchtext(tCache,tRegEx,tCachedTime,tCachedString)
	put "(\d+)TS--->.+" into tRegEx
	put empty into tCachedTime -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	get matchText(tCache,tRegEx,tCachedTime)

	# HAS THE FILE EXPIRED? IF SO WE'LL DELETE IT.
	if the seconds >= tCachedTime then
		delete file tFilePath

		rigLogMessage "debug", "Cache file has expired. File deleted"
		return FALSE
	end if

	# DISPLAY THE CACHE
	put (the number of chars of tCachedTime) + 7 into tCachedStringOffset
	put char tCachedStringOffset to -1 of tCache into tCachedString

	put TRUE into tCached
	rigLogMessage "debug", "Cache file is current. Sending it to browser."
	_rigDisplay tCachedString, tCached
	return TRUE
end _rigOutDisplayCache




----------------------------------------------------------------------
--| FUNCTION rigCacheVarsMerged
--|
--| Author: rabit
--| Version:  1.0
--| Created: 25-07-09
--| Last Mod: 25-07-09
--| Requires: --
--|
--| Summary:  Merge pseudo variables in cached file.
--|
--| Format:  rigCacheVarsMerged(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------

function rigCacheVarsMerged pStr
  local tStr, tMergedStr

	put pStr into tStr
	replace "{{" with "[[" in tStr
	replace "}}" with "]]" in tStr

	put merge(tStr) into tMergedStr

	return tMergedStr
end rigCacheVarsMerged





/*----------------------------------------------------------------------
--| FUNCTION rigOutputGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Get output array variable value.
--|
--| Format: rigOutputGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigOutputGet pWhat
  if pWhat is among the keys of sOutputA then
    return sOutputA[pWhat]
  end if

  return empty
end rigOutputGet




/*----------------------------------------------------------------------
--| COMMAND rigOutputSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Setter for output variables.
--|
--| Format: rigOutputSet param1, param2
--|
--| Parameters: string <pKey> sOutputA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigOutputSet pKey pVal
  if pKey is among the keys of sOutputA then
    put pVal into sOutputA[pKey]
  end if
end rigOutputSet








--| END OF Output.livecodescript
--| Location:  ./system/libraries/Output.livecodescript
----------------------------------------------------------------------