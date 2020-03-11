script "URI"

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
# revIgniter URI Library
#
# Parses URIs and determines routing
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  URI
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/uri.html
##




global gRigA, gConfig

local sUriString, sKeyVal, sStackInUse





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-06
 --| Last Mod: --
 --| Requires: rigLogMessage, rigLoadLibrary
 --|
 --| Summary:  Run security check, set initial values and load Config library.
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
        rigLogMessage "debug", "URI Library Loaded"
      end if

      rigLoadLibrary "Config"
    end if

  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack





/*----------------------------------------------------------------------
--| FUNCTION _rigFetchUriString
--|
--| Author: rabit
--| Version:  1.7
--| Created: 2009-06-19
--| Last Mod: 2020-03-11
--| Requires: rigFetchConfigItem(), rigUriAdjusted(), rigParseRequestUri()
--|
--| Summary: Get the URI String.
--|
--| Format:  _rigFetchUriString()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigFetchUriString
  local tArgs, tArgsNum, tUriString, tPath, tUri

  # IN CASE THE APPLICATION IS LOADED VIA THE CLI
  if gRigA["CLI"] is TRUE then
    put the commandArguments into tArgs
    put the number of lines in the keys of tArgs into tArgsNum

    # commandArguments IS A 1-BASED NUMERIC ARRAY,
    # THE VALUE OF THE FIRST ARGUMENT IS THE FRONT CONTROLLER (index.lc)
    # SO, WE ONLY NEED VALUES OF KEY 2 AND ABOVE TO BUILD THE URI STRING
    repeat with tIndex = 2 to tArgsNum
      put tArgs[tIndex] & "/" after sUriString
    end repeat
    delete char -1 of sUriString

    return sUriString
  else -- if gRigA["CLI"] is TRUE

    if toUpper(rigFetchConfigItem("uriProtocol")) is "AUTO" then
      # IF index.lc IS NOT INCLUDED IN THE URL OR IF THE URL
      # HAS A QUESTION MARK THEN IT'S SIMPLEST TO JUST
      # BUILD THE URI STRING FROM INDEX 1 OF THE $_GET ARRAY.
      # THIS AVOIDS HAVING TO DEAL WITH $_SERVER VARIABLES,
      # WHICH CAN BE UNRELIABLE IN SOME ENVIRONMENTS
      if ($_GET is an array) and (the number of lines in the keys of $_GET is 1) then
        put line 1 of the keys of $_GET into tUriString

        if tUriString is "/" then
          put "" into tUriString
          return tUriString
        end if

        # TRIM SLASHES
        put replacetext(tUriString,"(^\/+)|(\/+$)",empty) into tUriString

        if tUriString <> "" then
          -- put line 1 of the keys of $_GET into sUriString -- -------------- this is Codeigniter

          -- this is revigniter
          if rigFetchConfigItem("enableQueryStrings") is TRUE AND $_GET[rigFetchConfigItem("controllerTrigger")] is not empty then
            # QUERY STRINGS ARE ENABLED

            put $_GET into sUriString
            if sUriString is an array then
              combine sUriString using "&" and "="
            end if
            put "?" & sUriString into sUriString

          else
            put line 1 of the keys of $_GET into sUriString
          end if
          --

          return sUriString
        end if
      end if

      # IS THERE A PATH_INFO VARIABLE?
      if $_SERVER["PATH_INFO"] is not empty then
        put $_SERVER["PATH_INFO"] into tPath
        # TRIM SLASHES
        put replacetext(tPath,"(^\/+)|(\/+$)",empty) into tPath
        if tPath <> "" and tPath <> ("/" & gRigA["SELF"]) then
          put tPath into sUriString

          # NEEDED IF REVIGNITER IS PLACED IN A SUBFOLDER OF ROOT
          # THIS NEEDS TO BE FIXED IN CODEIGNITER TOO, WHERE THIS FUNCTION MAY FAIL DEPENDING ON THE URI PROTOCOL
          put rigUriAdjusted(sUriString) into sUriString

          return sUriString
        end if
      end if

      # No PATH_INFO?... What about QUERY_STRING?
      if $_SERVER["QUERY_STRING"] is not empty then
        put $_SERVER["QUERY_STRING"] into tPath
        # TRIM SLASHES
        put replacetext(tPath,"(^\/+)|(\/+$)",empty) into tPath
        if tPath <> "" then

          -- this is revigniter
          if rigFetchConfigItem("enableQueryStrings") is TRUE then
            put "?" & tPath into tPath
          end if
          --

          put tPath into sUriString

          put rigUriAdjusted(sUriString) into sUriString

          return sUriString
        end if
      end if

      # No QUERY_STRING?... Maybe the ORIG_PATH_INFO variable exists?
      if $_SERVER["ORIG_PATH_INFO"] is not empty then
        put $_SERVER["ORIG_PATH_INFO"] into tPath
        # TRIM SLASHES
        put replacetext(tPath,"(^\/+)|(\/+$)",empty) into tPath
        if tPath <> "" and tPath <> ("/" & gRigA["SELF"]) then
          replace $_SERVER["SCRIPT_NAME"] with "" in tPath
          put tPath into sUriString

          put rigUriAdjusted(sUriString) into sUriString

          return sUriString
        end if
      end if

      # TRY REQUEST_URI
      if ($_SERVER["REQUEST_URI"] is not empty) and ("~" is not in $_SERVER["REQUEST_URI"]) then
        put rigParseRequestUri() into sUriString

        put rigUriAdjusted(sUriString) into sUriString

        # IF THE URI CONTAINS ONLY A SLASH WE'LL KILL IT
        if sUriString is "/" then
          put "" into sUriString
        end if

        return sUriString
      end if


      # WE'VE EXHAUSTED ALL OUR OPTIONS...
      put "" into sUriString
      return sUriString

    else -- if toUpper(rigFetchConfigItem("uriProtocol")) is "AUTO"
      put toUpper(rigFetchConfigItem("uriProtocol")) into tUri
      if tUri is "REQUEST_URI" then
        put rigParseRequestUri() into sUriString
        # IF THE URI CONTAINS ONLY A SLASH WE'LL KILL IT
        if sUriString is "/" then
          put "" into sUriString
        end if
        put rigUriAdjusted(sUriString) into sUriString
        return sUriString
      end if

      if tUri is "PATH_TRANSLATED" then
        put $_SERVER["PATH_TRANSLATED"] into sUriString

        if the platform is "Win32" then
          replace "\" with "/" in sUriString
        end if

        put char offset("index" & gRigA["EXT"], sUriString) to -1 of sUriString into sUriString

        set the itemDel to "/"
        put item 2 to -1 of sUriString into sUriString
        # IF THE URI CONTAINS ONLY A SLASH WE'LL KILL IT
        if sUriString is "/" then
          put "" into sUriString
        end if
        put rigUriAdjusted(sUriString) into sUriString
        return sUriString
      end if

      put $_SERVER[tUri] into sUriString
      # IF THE URI CONTAINS ONLY A SLASH WE'LL KILL IT
      if sUriString is "/" then
        put "" into sUriString
      end if
      put rigUriAdjusted(sUriString) into sUriString
      return sUriString
    end if -- if toUpper(rigFetchConfigItem("uriProtocol")) is "AUTO"
  end if -- if gRigA["CLI"] is TRUE
end _rigFetchUriString




/*----------------------------------------------------------------------
--| FUNCTION rigParseRequestUri
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-06-09
--| Last Mod: 19-06-09
--| Requires: --
--|
--| Summary: Parse the REQUEST_URI
--|
--|                   Due to the way REQUEST_URI works it usually contains path info
--|                   that makes it unusable as URI data.  We'll trim off the unnecessary
--|                   data, hopefully arriving at a valid URI that we can use.
--|
--| Format:  rigParseRequestUri()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigParseRequestUri
  local tRequestUri, tFcpath, tParsedUri, tCount, i

	if $_SERVER["REQUEST_URI"] is empty then
		return ""
	end if

	put $_SERVER["REQUEST_URI"] into tRequestUri
	replace "\\" with "/" in tRequestUri
	if char 1 of tRequestUri is "/" then
		put char 2 to -1 of tRequestUri into tRequestUri
	end if

	if tRequestUri is "" or tRequestUri is gRigA["SELF"] then
		return ""
	end if

	put gRigA["FCPATH"] into tFcpath
	if tRequestUri contains "?" then
		put tFcpath & "?" into tFcpath
	end if

	put tRequestUri into tParsedUri
	split tParsedUri by "/"

	split tFcpath by "/"
	put 0 into tCount
	repeat with i = 1 to the number of lines in the keys of tParsedUri
		if tParsedUri[i] is not empty and tFcpath[i] = tParsedUri[i] then
			add 1 to tCount
		end if
	end repeat

	combine tParsedUri using "/"
	set the itemDelimiter to "/"
	put item tCount to -1 of tParsedUri into tParsedUri

	if tParsedUri <> "" then
		put "/" & tParsedUri into tParsedUri
	end if
	return tParsedUri
end rigParseRequestUri









/*----------------------------------------------------------------------
--| FUNCTION rigUriAdjusted
--|
--| Author: rabit
--| Version:  1.1
--| Created: 19-06-09
--| Last Mod: 21-03-14
--| Requires: --
--|
--| Summary: Truncate URI in case revIgniter is placed in a subfolder of root.
--|
--| Format:  rigUriAdjusted(param1)
--|
--| Parameters: string <pURIstring>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigUriAdjusted pURIstring
  local tURIstring, tBaseURL, tRegEx, tMatchStart, tMatchEnd, tBytesToRemoveFromURI
  local tIndexPage

	put pURIstring into tURIstring

	# GET BASE URL
    put rigFetchConfigItem("baseUrl") into tBaseURL

    # GET CHAR POSITION OF TOP LEVEL DOMAIN
    put "(?i)(\.[a-z]+/)" into tRegEx
    get matchchunk(tBaseURL,tRegEx,tMatchStart,tMatchEnd)

    # IS THE SYSTEM IN A SUBFOLDER
    # GET URI RELATIV TO SYSTEM ROOT
    if the number of chars of tBaseURL > tMatchEnd then
        put char tMatchEnd to (the number of chars of tBaseURL) of tBaseURL into tBytesToRemoveFromURI


        if the number of chars of tURIstring >= the number of chars of tBytesToRemoveFromURI then
            if (char 1 to (the number of chars of tBytesToRemoveFromURI) of tURIstring) is tBytesToRemoveFromURI then
                put char (the number of chars of tBytesToRemoveFromURI) to -1 of tURIstring into tURIstring
            end if

        else

            if (char 1 to ((the number of chars of tBytesToRemoveFromURI) -1) of tURIstring) is (char 1 to ((the number of chars of tBytesToRemoveFromURI) -1) of tBytesToRemoveFromURI) then
                put char (the number of chars of tBytesToRemoveFromURI) to -1 of tURIstring into tURIstring
            end if
        end if

    end if

	# GET NAME OF INDEX PAGE
	put rigFetchConfigItem("indexPage") into tIndexPage
	if tIndexPage is empty then
		put "index" & gRigA["EXT"] into tIndexPage
	end if

	if (tURIstring is "/" & tIndexPage) or (tURIstring is "/" & tIndexPage & "/") then
		return ""
	end if

    return tURIstring
end rigUriAdjusted









/*----------------------------------------------------------------------
--| FUNCTION _rigFilterUri
--|
--| Author: rabit
--| Version:  1.1
--| Created: 19-06-09
--| Last Mod: 01-12-15
--| Requires: rigShowError
--|
--| Summary: Filter segments for malicious characters.
--|
--| Format:  _rigFilterUri(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigFilterUri pStr
  local tBad, tGood, i, tStr

	if pStr <> "" and rigFetchConfigItem("permittedUriChars") <> "" and rigFetchConfigItem("enableQueryStrings") is FALSE then
		if matchchunk(pStr, "(?i)^[" & rigFetchConfigItem("permittedUriChars") & "]+$") is FALSE then
			# CHARS NOT PERMITTED FOUND
			put new header "HTTP/1.1 400 Bad Request"
			rigShowError "The URI you submitted has disallowed characters."
		end if
	end if

	# CONVERT PROGRAMATIC CHARACTERS TO ENTITIES
	put "$,(,),%28,%29" into tBad
	put "&#36;,&#40;,&#41;,&#40;,&#41;" into tGood

	put pStr into tStr
	repeat with i = 1 to the number of items of tBad
		replace item i of tBad with item i of tGood in tStr
	end repeat
	return tStr
end _rigFilterUri




/*----------------------------------------------------------------------
--| COMMAND _rigRemoveUrlSuffix
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-06-09
--| Last Mod: 19-06-09
--| Requires: --
--|
--| Summary:  Remove the suffix from the URL if needed.
--|
--| Format:  _rigRemoveUrlSuffix
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigRemoveUrlSuffix
  local tCharCount

	if rigFetchConfigItem("urlSuffix") <> "" then
		 if matchchunk(sUriString, (rigFetchConfigItem("urlSuffix") & "$")) then
         		put the number of chars of rigFetchConfigItem("urlSuffix") into tCharCount
         		put char 1 to -(tCharCount + 1) of sUriString into sUriString
		end if
    end if
end _rigRemoveUrlSuffix




/*----------------------------------------------------------------------
--| COMMAND _rigExplodeSegments
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2009-06-19
--| Last Mod: 2019-03-01
--| Requires: rigTrim(), _rigFilterUri(), rigUriString()
--|
--| Summary:  Explode the URI Segments. The individual segments will
--|             be stored in the gRigA["segments"] array.
--|
--| Format:  _rigExplodeSegments
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command _rigExplodeSegments
  local tNumKeys, tTempStr, tTempStr1, tTempStr2

	put the number of lines in the keys of gRigA["segments"] into tNumKeys

	# SEGMENT BASED URLs
	if gConfig["enableQueryStrings"] is not TRUE then
		replace "\\" with "/" in sUriString
		if char 1 of sUriString is "/" then
			put char 2 to -1 of sUriString into sUriString
		end if
		set the itemDelimiter to "/"
		repeat with i = 1 to the number of items of sUriString
			put item i of sUriString into tTempStr

			# TRIM WHITESPACE
			put rigTrim(tTempStr) into tTempStr

			# FILTER SEGMENTS FOR SECURITY
			put _rigFilterUri(tTempStr) into tTempStr

			# IF index.lc IS INCLUDED IN THE URL THEN sUriString IS
			# DERIVED FROM A $_SERVER VARIABLE. AS THIS CAN BE
			# UNRELIABLE IN SOME ENVIRONMENTS tTempStr (item i of sUriString)
			# MAY INCLUDE index.lc. SO WE ADD tTempStr TO gRigA["segments"]
			# ONLY IF tTempStr IS NOT index.lc.
			if tTempStr <> "" and tTempStr <> gConfig["indexPage"] then
				add 1 to tNumKeys
				put tTempStr into gRigA["segments"][tNumKeys]
			end if
		end repeat

		exit _rigExplodeSegments
	end if

	# QUERY STRING BASED URLs
	get rigUriString()
	if char 1 of sUriString is "?" then
		put char 2 to -1 of sUriString into sUriString
	end if

	set the itemdel to "&"
	repeat with i = 1 to the number of items of sUriString
		put item i of sUriString into tTempStr
		set the itemdel to "="
		# TRIM WHITESPACE
		put rigTrim(item 1 of tTempStr) into tTempStr1
		put rigTrim(item 2 of tTempStr) into tTempStr2

		set the itemdel to "&"

		# FILTER SEGMENTS FOR SECURITY
		put _rigFilterUri(tTempStr1) into tTempStr1
		put _rigFilterUri(tTempStr2) into tTempStr2

		put tTempStr1 & "=" & tTempStr2 into tTempStr

		if tTempStr <> "" then
			add 1 to tNumKeys
			put tTempStr into gRigA["segments"][tNumKeys]
		end if
	end repeat
end _rigExplodeSegments




/*----------------------------------------------------------------------
--| FUNCTION rigFetchSegment
--|
--| Author: rabit
--| Version:  1.3
--| Created: 13-07-09
--| Last Mod: 05-11-09
--| Requires: --
--|
--| Summary: This function returns the URI segment, or URI value based on the number provided.
--|
--| Format:  rigFetchSegment(param1, param2)
--|
--| Parameters: integer <pSegmentNum>, string <pNoResult>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigFetchSegment pSegmentNum pNoResult
  local tNoResult, tURIstring, tKeyVal, tVal

	if pNoResult is "" then
		put FALSE into tNoResult
	else
		put pNoResult into tNoResult
	end if

	if gConfig["enableQueryStrings"] is not TRUE then
		# SEGMENT BASED URLs
		--if gRigA["segments"][pSegmentNum] is not empty then
		if pSegmentNum is among the keys of gRigA["segments"] then
			return gRigA["segments"][pSegmentNum]
		else
			return tNoResult
		end if
	end if

	# QUERY STRING BASED URLs
	put rigUriString() into tURIstring

	set the itemdel to "&"

	if pSegmentNum <= the number of items of tURIstring then
    		put item pSegmentNum of tURIstring into tKeyVal
    		set the itemdel to "="
    		put item -1 of tKeyVal into tVal
	else
		put FALSE into tVal
	end if

    	return tVal
end rigFetchSegment







/*----------------------------------------------------------------------
--| FUNCTION rigFetchRsegment
--|
--| Author: rabit
--| Version:  1.3
--| Created: 13-07-09
--| Last Mod: 04-01-10
--| Requires: --
--|
--| Summary: This function returns the re-routed URI segment (assuming routing rules are used)
--|                    based on the number provided.  If there is no routing this function returns the
--|                    same result as rigFetchSegment().
--|
--| Format:  rigFetchRsegment(param1, param2)
--|
--| Parameters: integer <pSegmentNum>, string <pNoResult>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigFetchRsegment pSegmentNum pNoResult
  local tNoResult, tURIstring, tKeyVal, tVal

	if pNoResult is "" then
		put FALSE into tNoResult
	else
		put pNoResult into tNoResult
	end if

	if gConfig["enableQueryStrings"] is not TRUE then
		# SEGMENT BASED URLs
		if gRigA["rSegments"][pSegmentNum] is not empty then
			return gRigA["rSegments"][pSegmentNum]
		else
			return tNoResult
		end if
	end if

	# QUERY STRING BASED URLs
	put rigUriString() into tURIstring

	set the itemdel to "&"

	if pSegmentNum <= the number of items of tURIstring then
    		put item pSegmentNum of tURIstring into tKeyVal
    		set the itemdel to "="
    		put item -1 of tKeyVal into tVal
	else
		put FALSE into tVal
	end if

    	return tVal
end rigFetchRsegment








/*----------------------------------------------------------------------
--| FUNCTION rigUriToAssoc
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-10-09
--| Last Mod: 11-10-09
--| Requires: _rigUriToAssoc()
--|
--| Summary: Generate a key value pair from the URI string.
--|
--|                   This function generates an associative array of URI data starting
--|                   at the supplied segment. For example, if this is your URI:
--|
--|                   example.com/user/search/name/joe/location/UK/gender/male
--|                   query string based URI:
--|                   example.com/?c=user&m=search&name=joe&location=UK&gender=male
--|
--|                  You can use this function to generate an array with this prototype:
--|
--|                  tArray["name] =>value = "joe"
--|                  tArray["location] =>value = "UK"
--|                  tArray["gender] =>value = "male"
--|
--| Format:  rigUriToAssoc(param1, param2)
--|
--| Parameters: integer <pN> the starting segment number, array <pDefault> an array of default values
--|
--| Return: array
----------------------------------------------------------------------*/

function rigUriToAssoc pN pDefault
  local tN

	if pN is empty then
		put 3 into tN
	else
		put pN into tN
	end if

	return _rigUriToAssoc(tN, pDefault, "segment")
end rigUriToAssoc









/*----------------------------------------------------------------------
--| FUNCTION rigRuriToAssoc
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-10-09
--| Last Mod: 11-10-09
--| Requires: _rigUriToAssoc()
--|
--| Summary: Identical to above only it uses the re-routed segment array.
--|
--| Format:  rigRuriToAssoc(param1, param2)
--|
--| Parameters: integer <pN> the starting segment number, array <pDefault> an array of default values
--|
--| Return: array
----------------------------------------------------------------------*/

function rigRuriToAssoc pN pDefault
  local tN

	if pN is empty then
		put 3 into tN
	else
		put pN into tN
	end if

	return _rigUriToAssoc(tN, pDefault, "rsegment")
end rigRuriToAssoc








/*----------------------------------------------------------------------
--| FUNCTION _rigUriToAssoc
--|
--| Author: rabit
--| Version:  1.4
--| Created: 11-10-09
--| Last Mod: 08-12-15
--| Requires: rigTotalSegments(), rigSegmentArray(), rigTotalRsegments(), rigRSegmentArray()
--|
--| Summary: Generate a key value pair from the URI string or Re-routed URI string.
--|
--| Format:  _rigUriToAssoc(param1, param2, param3)
--|
--| Parameters: integer <pN> the starting segment number, array <pDefault> an array of default values
--|                       string <pWhich> which array we should use
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigUriToAssoc pN pDefault pWhich
  local tN, tWhich, tTotalSegments, tSegmentArray, tVal, tRetval, tSegmNum, tK
  local tSlicedArray, tIncr, tI, tLastVal, tKeyValPair

	if pN is empty then
		put 3 into tN
	else
		put pN into tN
	end if

	if pWhich is empty then
		put "segment" into tWhich
	else
		put pWhich into tWhich
	end if

	if tWhich is "segment" then
		put rigTotalSegments() into tTotalSegments
		put rigSegmentArray() into tSegmentArray
	else
		put rigTotalRsegments() into tTotalSegments
		put rigRSegmentArray() into tSegmentArray
	end if

	if tN is not an integer then
		return pDefault
	end if

	if tN is among the keys of sKeyVal then
		return sKeyVal[tN]
	end if

	# SEGMENT BASED URLs
	if gConfig["enableQueryStrings"] is not TRUE then

		if tTotalSegments < tN then
			if pDefault is not an array then
				return ""
			end if

			repeat for each key tKey in pDefault
				put pDefault[tKey] into tVal

				put FALSE into tRetval[tVal]
			end repeat

			return tRetval
		end if

		# SLICE ARRAY
		put the number of lines in the keys of tSegmentArray into tSegmNum
		repeat with i = tN to tSegmNum
			put i - (tN - 1) into tK
			put tSegmentArray[i] into tSlicedArray[tK]
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

		if (the number of lines in the keys of pDefault) > 0 then
			repeat for each key tKey in pDefault
				put pDefault[tKey] into tVal

				if tVal is not among the keys of tRetval then
					put FALSE into tRetval[tVal]
				end if
			end repeat
		end if

		# CACHE THE ARRAY FOR REUSE
		put tRetval into sKeyVal[tN]

		return tRetval
	end if

	# QUERY STRING BASED URLs
	if tTotalSegments < tN then
		if pDefault is not an array then
			return ""
		end if

		set the itemDel to "="
		repeat for each key tKey in pDefault
			put pDefault[tKey] into tKeyValPair

			put FALSE into item 2 of tKeyValPair
			put tKeyValPair into tRetval[tKey]
		end repeat

		return tRetval
	end if

	set the itemDel to "="
	put the number of lines in the keys of tSegmentArray into tSegmNum
	repeat with i = tN to tSegmNum
		put i - (tN - 1) into tK
		put tSegmentArray[tN] into tKeyValPair
		put item 1 of tKeyValPair into tK
		put item 2 of tKeyValPair into tRetval[tK]
	end repeat

	if (the number of lines in the keys of pDefault) > 0 then
		repeat for each key tKey in pDefault
			put pDefault[tKey] into tVal

			if tVal is not among the keys of tRetval then
				put FALSE into tRetval[tVal]
			end if
		end repeat
	end if

	# CACHE THE ARRAY FOR REUSE
	put tRetval into sKeyVal[tN]

	return tRetval
end _rigUriToAssoc





/*----------------------------------------------------------------------
--| FUNCTION rigAssocToURI
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-10-09
--| Last Mod: 11-10-09
--| Requires: --
--|
--| Summary: Generate an URI string from an associative array.
--|
--| Format:  rigAssocToURI(param1)
--|
--| Parameters: array <pArray> an associative array of key/values
--|
--| Return: string
----------------------------------------------------------------------*/

function rigAssocToURI pArray
  local tVal, tKey, tURI

	repeat for each key tKey in pArray
         	put pArray[tKey] into tVal

		if gConfig["enableQueryStrings"] is not TRUE then
			# SEGMENT BASED URLs
         		put tKey & "/" & tVal & "/" after tURI
		else
			# QUERY STRING BASED URLs
			put tKey & "=" & tVal & "&" after tURI
		end if
    	end repeat

    	delete char -1 of tURI

    	return tURI
end rigAssocToURI









/*----------------------------------------------------------------------
--| FUNCTION rigSlashSegment
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-10-09
--| Last Mod: 11-10-09
--| Requires: --
--|
--| Summary: Fetch a URI Segment and add a trailing slash.
--|
--| Format:  rigSlashSegment(param1, param2)
--|
--| Parameters: integer <pN>, string <pWhere>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSlashSegment pN pWhere
  local tWhere

	if pWhere is empty then
		put "trailing" into tWhere
	else
		put pWhere into tWhere
	end if

	return _rigSlashSegment(pN, tWhere, "segment")
end rigSlashSegment








/*----------------------------------------------------------------------
--| FUNCTION rigSlashRsegment
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-10-09
--| Last Mod: 11-10-09
--| Requires: --
--|
--| Summary: Fetch a URI Segment and add a trailing slash.
--|
--| Format:  rigSlashRsegment(param1, param2)
--|
--| Parameters: integer <pN>, string <pWhere>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSlashRsegment pN pWhere
  local tWhere

	if pWhere is empty then
		put "trailing" into tWhere
	else
		put pWhere into tWhere
	end if

	return _rigSlashSegment(pN, tWhere, "rsegment")
end rigSlashRsegment








/*----------------------------------------------------------------------
--| FUNCTION _rigSlashSegment
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-10-09
--| Last Mod: 11-10-09
--| Requires: --
--|
--| Summary: Fetch a URI Segment and add a trailing slash - helper function.
--|
--| Format:  _rigSlashSegment(param1, param2)
--|
--| Parameters: integer <pN>, string <pWhere>, string <pWhich>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigSlashSegment pN pWhere pWhich
  local tWhere, tWhich, tTrailing, tLeading, tSegment

	if pWhere is empty then
		put "trailing" into tWhere
	else
		put pWhere into tWhere
	end if

	if pWhich is empty then
		put "segment" into tWhich
	else
		put pWhich into tWhich
	end if

	if pWhere is "trailing" then
		put "/" into tTrailing
		put "" into tLeading
	else if pWhere is "leading" then
		put "" into tTrailing
		put "/" into tLeading
	else
		put "/" into tTrailing
		put "/" into tLeading
	end if

	switch pWhich
		case "segment"
             		put rigFetchSegment(pN) into tSegment
			break
		case "rsegment"
             		put rigFetchRsegment(pN) into tSegment
			break
        	default
            		put rigFetchSegment(pN) into tSegment
	end switch

	return tLeading & tSegment & tTrailing
end _rigSlashSegment





/*----------------------------------------------------------------------
--| FUNCTION rigSegmentArray
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-10-09
--| Last Mod: 10-10-09
--| Requires: --
--|
--| Summary: Segment array
--|
--| Format:  rigSegmentArray()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSegmentArray
	return gRigA["segments"]
end rigSegmentArray








/*----------------------------------------------------------------------
--| FUNCTION rigRSegmentArray
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-10-09
--| Last Mod: 10-10-09
--| Requires: --
--|
--| Summary: Routed segment array
--|
--| Format:  rigRSegmentArray()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigRSegmentArray
	return gRigA["rSegments"]
end rigRSegmentArray







/*----------------------------------------------------------------------
--| FUNCTION rigTotalSegments
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-10-09
--| Last Mod: 10-10-09
--| Requires: --
--|
--| Summary: Total number of segments
--|
--| Format:  rigTotalSegments()
--|
--| Parameters: --
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigTotalSegments
	return the number of lines in the keys of gRigA["segments"]
end rigTotalSegments







/*----------------------------------------------------------------------
--| FUNCTION rigTotalRsegments
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-10-09
--| Last Mod: 10-10-09
--| Requires: --
--|
--| Summary: Total number of routed segments
--|
--| Format:  rigTotalRsegments()
--|
--| Parameters: --
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigTotalRsegments
	return the number of lines in the keys of gRigA["rSegments"]
end rigTotalRsegments







/*----------------------------------------------------------------------
--| FUNCTION rigUriString
--|
--| Author: rabit
--| Version:  1.1
--| Created: 25-07-09
--| Last Mod: 30-09-09
--| Requires: --
--|
--| Summary: Fetch the entire URI string.
--|
--| Format:  rigUriString()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigUriString
	if sUriString is empty then
		get _rigFetchUriString()
	end if

	return sUriString
end rigUriString







/*----------------------------------------------------------------------
--| FUNCTION rigRuriString
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-10-09
--| Last Mod: 10-10-09
--| Requires: --
--|
--| Summary: Fetch the entire Re-routed URI string.
--|
--| Format:  rigRuriString()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigRuriString
  local tRsegments

	put rigRSegmentArray() into tRsegments
	combine tRsegments using "/"

	return "/" & tRsegments & "/"
end rigRuriString








--| END OF URI.livecodescript
--| Location:  ./system/libraries/URI.livecodescript
----------------------------------------------------------------------
