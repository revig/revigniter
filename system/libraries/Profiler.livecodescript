script "Profiler"

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
# revIgniter Profiler Library
#
# This library enables you to display benchmark, query, and other data
# in order to help with debugging and optimization.
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Profiler
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/uri.html
##



global gRigA, gMarkerA

local sProfilerTemplateA, sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-06
 --| Last Mod: --
 --| Requires: rigLangLoadLang()
 --|
 --| Summary:  Run security check, set initial values and load language file.
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

      get rigLangLoadLang("profiler")
    end if

  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack





/*----------------------------------------------------------------------
--| COMMAND rigRunInitialProfilerConfig
--|
--| Author: rabit
--| Version:  1.1
--| Created: 21-01-10
--| Last Mod: 22-12-14
--| Requires: rigSetProfilerTableTemplate
--|
--| Summary: Run initial configuration procedures. Don't remove, even if it does nothing.
--|
--| Format:  rigRunInitialProfilerConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialProfilerConfig pConfig
  local tName, tItem, tTableTemplate, tTemplateData

  if pConfig is not an array then
    if pConfig is not empty then

      # BUILD TEMPLATE ARRAYS
      split pConfig using numToCodepoint(1) and numToCodepoint(2)

      repeat for each key tKey in pConfig
        put item 1 of tKey into tName
        put item 2 of tKey into tItem
        put pConfig[tKey] into tTableTemplate[tName][tItem]

        put tTableTemplate[tName] into tTableTemplate[tName]
      end repeat

    end if
  end if

  # SET TABLE TEMPLATES
  if tTableTemplate is an array then
    repeat for each key tName in tTableTemplate
      put tTableTemplate[tName] into tTemplateData
      rigSetProfilerTableTemplate tName, tTemplateData
    end repeat
  end if
end rigRunInitialProfilerConfig








/*----------------------------------------------------------------------
--| FUNCTION _rigCompileBenchmarks
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2010-01-21
--| Last Mod: 2017-06-27
--| Requires: rigCompileProfilerTemplate, rigFetchMarkers(), rigElapsedTime(), rigLangLangLine()
--|
--| Summary: This function cycles through the entire array of mark points and
--|                    matches any two points that are named identically (ending in "_start"
--|                    and "_end" respectively).  It then compiles the execution times for
--|                    all points and returns it as an array.
--|
--| Format:  _rigCompileBenchmarks()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCompileBenchmarks
  local tMarkers, tRegEx, tMatch, tKey, tVal, tProfile, tOutput, tTableBody, tTempTableBody

	# COMPILE BENCHMARKS PROFILE TEMPLATE
	rigCompileProfilerTemplate "benchmark"

	# GET MARKER ARRAY
	put rigFetchMarkers() into tMarkers

	put "(?i)(.+?)_end" into tRegEx

	put empty into tMatch -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	repeat for each key tKey in tMarkers
		put tMarkers[tKey] into tVal

		# WE MATCH THE "END" MARKER SO THAT THE LIST ENDS
		# UP IN THE ORDER THAT IT WAS DEFINED
		 get matchText(tKey, tRegEx, tMatch)
      		if it is TRUe then
         		if (gMarkerA[tMatch & "_end"] is not empty) and (gMarkerA[tMatch & "_start"] is not empty) then
            			put rigElapsedTime(tMatch & "_start", tKey) into tProfile[tMatch]
         		end if
      		end if

	end repeat

	# BUILD A TABLE CONTAINING THE PROFILE DATA
	put sProfilerTemplateA["benchmark"]["legend"] into tOutput
	replace "'" with quote in tOutput

replace "{langBenchmarks}" with rigLangLangLine("profiler_benchmarks") in tOutput

	put sProfilerTemplateA["benchmark"]["body"] into tTableBody
	replace "'" with quote in tTableBody

	repeat for each key tKey in tProfile
		put tProfile[tKey] into tVal
		put tTableBody into tTempTableBody

		replace "_" with space in tKey
		replace "-" with space in tKey
		put rigUcwords(tKey) into tKey

		# REPLACE PSEUDO VARIABLES IN TEMPLATE
		replace "{key}" with tKey in tTempTableBody
		replace "{val}" with tVal in tTempTableBody

		put tTempTableBody after tOutput
	end repeat

	put "</table>" & return & "</fieldset>" after tOutput

	return tOutput
end _rigCompileBenchmarks





/*----------------------------------------------------------------------
--| FUNCTION _rigCompileQueries
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2010-01-21
--| Last Mod: 2017-04-24
--| Requires: rigCompileProfilerTemplate, rigFetchDBlibLoaded, rigFetchDBdriverSetting(), rigLangLangLine()
--|
--| Summary: Compile queries.
--|
--| Format:  _rigCompileQueries()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCompileQueries
  local tDatabaseID, tOutput, tDatabase, tQueries, tQueriesNum, tTotalElapsedTime
  local tQueryTimes, tVal, tTime, tBody

	# COMPILE BENCHMARKS PROFILE TEMPLATE
	rigCompileProfilerTemplate "queries"

	# CURRENTLY WE ARE DEALING WITH ONLY ONE DATABASE AT A TIME
	# IF THIS WILL CHANGE IN THE FUTURE, WE WILL HAVE TO DETERMINE WHICH DATABASES
	# ARE CURRENTLY CONNECTED TO

	# IF WE ARE CONNECTED THERE IS ONLY ONE CONNECTION ID
	if rigFetchDBlibLoaded() is TRUE then
		put rigFetchDBdriverSetting("connid") into tDatabaseID
	else
		put FALSE into tDatabaseID
	end if

	if tDatabaseID is not an integer then
		put sProfilerTemplateA["queries"]["noResult"] into tOutput

		replace "{langQueries}" with rigLangLangLine("profiler_queries") in tOutput
		replace "{langNoDB}" with rigLangLangLine("profiler_no_db") in tOutput
		replace "'" with quote in tOutput

		return tOutput
	end if

	# THERE IS A DATABASE CONNECTION, SO BUILD THE PROFILE TABLE
	put return & return into tOutput

	# DO THE FOLLOWING FOR EACH CONNECTED DATABASE
	put rigFetchDBdriverSetting("database") into tDatabase

	put rigFetchDBdriverSetting("queries") into tQueries
	if tQueries is an array then
		put the number of lines in the keys of tQueries into tQueriesNum
	else
		put 0 into tQueriesNum
	end if

	put rigFetchDBdriverSetting("benchmark") into tTotalElapsedTime

	put sProfilerTemplateA["queries"]["legend"] after tOutput
	replace "{langQueries}" with rigLangLangLine("profiler_queries") in tOutput
	replace "{database}" with tDatabase in tOutput
	replace "{queriesNum}" with tQueriesNum in tOutput

	if tQueriesNum = 0 then
		put sProfilerTemplateA["queries"]["noQueries"] after tOutput
		replace "{langNoQueries}" with rigLangLangLine("profiler_no_queries") in tOutput

	else
		put rigFetchDBdriverSetting("querytimes") into tQueryTimes

		repeat for each key tKey in tQueries
			put tQueries[tKey] into tVal

			put tQueryTimes[tKey] into tTime

			put sProfilerTemplateA["queries"]["body"] into tBody
			replace "{time}" with format("%1.6f", tTime) in tBody
			replace "{val}" with tVal in tBody

			put tBody after tOutput
		end repeat

		put sProfilerTemplateA["queries"]["body"] into tBody
		replace "{time}" with tTotalElapsedTime in tBody
		replace "{val}" with rigLangLangLine("profiler_db_elapsed") in tBody

		put tBody after tOutput

	end if

	put "</table>" & return & "</fieldset>" after tOutput

	replace "'" with quote in tOutput

	return tOutput
end _rigCompileQueries




/*----------------------------------------------------------------------
--| FUNCTION _rigCompileGet
--|
--| Author: rabit
--| Version:  1.3
--| Created: 22-01-10
--| Last Mod: 22-12-14
--| Requires: rigCompileProfilerTemplate, rigStripSlashes(), rigHtmlSpecialChars(),
--|            rigLangLangLine()
--|
--| Summary: Compile $_GET Data.
--|
--| Format:  _rigCompileGet()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCompileGet
  local tOutput, tKey, tVal, tTemp, tValVal, tNewKey, tNewVal

	# COMPILE BENCHMARKS PROFILE TEMPLATE
	rigCompileProfilerTemplate "get"

	put sProfilerTemplateA["get"]["legend"] into tOutput
	replace "{langGetData}" with rigLangLangLine("profiler_get_data") in tOutput

	if $_GET is not an array then
		put sProfilerTemplateA["get"]["noGet"] after tOutput
		replace "{langNoGet}" with rigLangLangLine("profiler_no_get") in tOutput
		replace "'" with quote in tOutput

	else
		put return & return & "<table cellpadding='4' cellspacing='1' border='0' width='100%'>" & return after tOutput
		replace "'" with quote in tOutput

		repeat for each key tKey in $_GET
			put $_GET[tKey] into tVal

			if tKey is not a number then
				put "'" & tKey & "'" into tKey
			end if

			put sProfilerTemplateA["get"]["body"] into tTemp
			replace "'" with quote in tTemp
			put tTemp after tOutput
			replace "{key}" with tKey in tOutput

			if tVal is an array then
				repeat for each key tValKey in tVal
					put tVal[tValKey] into tValVal
					put "[" & tValKey & "]" into tNewKey
					put tValVal into tNewVal[tNewKey]
				end repeat
				combine tNewVal using numToCodepoint(1) and numToCodepoint(2)
				replace numToCodepoint(1) with ", " in tNewVal
				replace numToCodepoint(2) with " => " in tNewVal

				put rigStripSlashes(tNewVal) into tNewVal
				put rigHtmlSpecialChars(tNewVal) into tNewVal

				put "<pre>" & tNewVal & "</pre>" after tOutput

			else
				put rigStripSlashes(tVal) into tVal
				put rigHtmlSpecialChars(tVal) into tVal

				put tVal after tOutput
			end if

		end repeat

		put "</table>" & return after tOutput

	end if

	put "</fieldset>" after tOutput

	return tOutput
end _rigCompileGet





/*----------------------------------------------------------------------
--| FUNCTION _rigCompilePost
--|
--| Author: rabit
--| Version:  1.3
--| Created: 22-01-10
--| Last Mod: 22-12-14
--| Requires: rigCompileProfilerTemplate, rigStripSlashes(), rigHtmlSpecialChars(),
--|            rigLangLangLine()
--|
--| Summary: Compile $_POST Data.
--|
--| Format:  _rigCompilePost()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCompilePost
  local tOutput, tKey, tVal, tTemp, tValKey, tValVal, tNewKey, tNewVal

	# COMPILE BENCHMARKS PROFILE TEMPLATE
	rigCompileProfilerTemplate "post"

	put sProfilerTemplateA["post"]["legend"] into tOutput
	replace "{langPostData}" with rigLangLangLine("profiler_post_data") in tOutput

	if $_POST is not an array then
		put sProfilerTemplateA["post"]["noPost"] after tOutput
		replace "{langNoPost}" with rigLangLangLine("profiler_no_post") in tOutput
		replace "'" with quote in tOutput

	else
		put return & return & "<table cellpadding='4' cellspacing='1' border='0' width='100%'>" & return after tOutput
		replace "'" with quote in tOutput

		repeat for each key tKey in $_POST
			put $_POST[tKey] into tVal

			if tKey is not a number then
				put "'" & tKey & "'" into tKey
			end if

			put sProfilerTemplateA["post"]["body"] into tTemp
			replace "'" with quote in tTemp
			put tTemp after tOutput
			replace "{key}" with tKey in tOutput

			if tVal is an array then
				repeat for each key tValKey in tVal
					put tVal[tValKey] into tValVal
					put "[" & tValKey & "]" into tNewKey
					put tValVal into tNewVal[tNewKey]
				end repeat
				combine tNewVal using numToCodepoint(1) and numToCodepoint(2)
				replace numToCodepoint(1) with ", " in tNewVal
				replace numToCodepoint(2) with " => " in tNewVal

				put rigStripSlashes(tNewVal) into tNewVal
				put rigHtmlSpecialChars(tNewVal) into tNewVal

				put "<pre>" & tNewVal & "</pre>" after tOutput

			else
				put rigStripSlashes(tVal) into tVal
				put rigHtmlSpecialChars(tVal) into tVal

				put tVal after tOutput
			end if

		end repeat

		put "</table>" & return after tOutput

	end if

	put "</fieldset>" after tOutput

	return tOutput
end _rigCompilePost






/*----------------------------------------------------------------------
--| FUNCTION _rigCompileURIstring
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-01-10
--| Last Mod: 22-01-10
--| Requires: rigCompileProfilerTemplate, rigUriString(), rigLangLangLine()
--|
--| Summary: Show query string.
--|
--| Format:  _rigCompileURIstring()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCompileURIstring
  local tOutput, tURIstring

	# COMPILE BENCHMARKS PROFILE TEMPLATE
	rigCompileProfilerTemplate "uri"

	put sProfilerTemplateA["uri"]["legend"] into tOutput
	replace "{langURIstring}" with rigLangLangLine("profiler_uri_string") in tOutput

	put rigUriString() into tURIstring

	if tURIstring is empty then
		put sProfilerTemplateA["uri"]["noURI"] after tOutput
		replace "{langNoURI}" with rigLangLangLine("profiler_no_uri") in tOutput
	else
		put sProfilerTemplateA["uri"]["body"] after tOutput
		replace "{uriString}" with tURIstring in tOutput
	end if

	replace "'" with quote in tOutput
	put "</fieldset>" after tOutput

	return tOutput
end _rigCompileURIstring





/*----------------------------------------------------------------------
--| FUNCTION _rigCompileControllerInfo
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-01-10
--| Last Mod: 22-01-10
--| Requires: rigCompileProfilerTemplate, rigLangLangLine()
--|
--| Summary: Show the controller and handler that were called.
--|
--| Format:  _rigCompileControllerInfo()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCompileControllerInfo
  local tOutput

	# COMPILE BENCHMARKS PROFILE TEMPLATE
	rigCompileProfilerTemplate "info"

	put sProfilerTemplateA["info"]["legend"] into tOutput
	replace "{langControllerInfo}" with rigLangLangLine("profiler_controller_info") in tOutput

	put sProfilerTemplateA["info"]["body"] after tOutput

	replace "{controller}" with gRigA["controller"] in tOutput
	replace "{handler}" with gRigA["handler"] in tOutput

	replace "'" with quote in tOutput
	put "</fieldset>" after tOutput

	return tOutput
end _rigCompileControllerInfo






/*----------------------------------------------------------------------
--| COMMAND rigSetProfilerTableTemplate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-01-10
--| Last Mod: 21-01-10
--| Requires: --
--|
--| Summary: Set the template.
--|
--| Format:  rigSetProfilerTableTemplate param1
--|
--| Parameters: string <pName>, array <pTemplate>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetProfilerTableTemplate pName pTemplate
	if (pTemplate is not an array) or (pName is empty) then
		exit rigSetProfilerTableTemplate
	end if

	put pTemplate into sProfilerTemplateA[pName]
end rigSetProfilerTableTemplate








/*----------------------------------------------------------------------
--| COMMAND rigCompileProfilerTemplate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-01-10
--| Last Mod: 21-01-10
--| Requires: _rigDefaultProfilerTemplate
--|
--| Summary: Compile template.
--|
--| Format:  rigCompileProfilerTemplate
--|
--| Parameters: string <pName>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigCompileProfilerTemplate pName
	if sProfilerTemplateA[pName] is not an array then
		put _rigDefaultProfilerTemplate(pName) into sProfilerTemplateA[pName]
	end if
end rigCompileProfilerTemplate







/*----------------------------------------------------------------------
--| FUNCTION _rigDefaultProfilerTemplate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-01-10
--| Last Mod: 21-01-10
--| Requires: --
--|
--| Summary: Default template.
--|
--| Format:  _rigDefaultProfilerTemplate()
--|
--| Parameters: string <pName>
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigDefaultProfilerTemplate pName
  local tTemplate

	# BENCHMARK TABLE
	if pName is "benchmark" then
		# LEGEND
		put return & "<fieldset style='border:1px solid #8498B4;padding:6px 10px 10px 10px;margin:0 0 20px 0;background-color:#F2F2F2'>" & return & \
		\
		"<legend style='color:#8498B4;'>&nbsp;&nbsp;{langBenchmarks}&nbsp;&nbsp;</legend>" & return & \
		\
		return & return & "<table cellpadding='4' cellspacing='1' border='0' width='100%'>" & return into tTemplate["legend"]

		# BODY
		put "<tr>" & return & \
			"<td width='50%' style='color:#2B4662;font-weight:bold;background-color:#ddd;'>{key}&nbsp;&nbsp;</td>" & return & \
			"<td width='50%' style='color:#FF0E00;font-weight:normal;background-color:#ddd;'>{val}</td></tr>" & return into tTemplate["body"]
	end if

	# QUERIES TABLE
	if pName is "queries" then
		# NO RESULT TEMPLATE
		put return & return & "<fieldset style='border:1px solid #8498B4;padding:6px 10px 10px 10px;margin:20px 0 20px 0;background-color:#F2F2F2'>" & return & \
		\
		"<legend style='color:#8498B4;'>&nbsp;&nbsp;{langQueries}&nbsp;&nbsp;</legend>" & return & \
		\
		return & return & "<table cellpadding='4' cellspacing='1' border='0' width='100%'>" & return & \
		"<tr><td width='100%' style='color:#2B4662;font-weight:normal;background-color:#ddd;'>{langNoDB}</td></tr>" & return & \
		"</table>" & return & "</fieldset>" into tTemplate["noResult"]

		# LEGEND
		put "<fieldset style='border:1px solid #8498B4;padding:6px 10px 10px 10px;margin:20px 0 20px 0;background-color:#F2F2F2'>" & return & \
		\
		"<legend style='color:#8498B4;'>&nbsp;&nbsp;" & rigLangLangLine("profiler_database") & ":&nbsp; {database}&nbsp;&nbsp;&nbsp;{langQueries}: {queriesNum}&nbsp;&nbsp;&nbsp;</legend>" & return & \
		\
		return & return & "<table cellpadding='4' cellspacing='1' border='0' width='100%'>" & return into tTemplate["legend"]

		# NO QUERIES
		put "<tr><td width='100%' style='color:#2B4662;font-weight:normal;background-color:#ddd;'>{langNoQueries}</td></tr>" & return into tTemplate["noQueries"]

		# BODY
		put "<tr><td width='1%' valign='top' style='color:#FF0E00;font-weight:normal;background-color:#ddd;'>{time}&nbsp;&nbsp;</td><td style='color:#2B4662;font-weight:normal;background-color:#ddd;'>{val}</td></tr>" & return into tTemplate["body"]
	end if


	# GET TABLE
	if pName is "get" then
		# LEGEND
		put return & return & "<fieldset style='border:1px solid #8498B4;padding:6px 10px 10px 10px;margin:20px 0 20px 0;background-color:#F2F2F2'>" & return & \
		\
		"<legend style='color:#8498B4;'>&nbsp;&nbsp;{langGetData}&nbsp;&nbsp;</legend>" & return into tTemplate["legend"]

		# NO GET DATA
		put "<div style='color:#2B4662;font-weight:normal;padding:4px 0 4px 0'>{langNoGet}</div>" into tTemplate["noGet"]

		# BODY
		put "<tr><td width='50%' style='color:#2B4662;background-color:#ddd;'>&#36;_GET[{key}]&nbsp;&nbsp; </td><td width='50%' style='color:#FF0E00;font-weight:normal;background-color:#ddd;'>" into tTemplate["body"]

	end if


	# POST TABLE
	if pName is "post" then
		# LEGEND
		put return & return & "<fieldset style='border:1px solid #8498B4;padding:6px 10px 10px 10px;margin:20px 0 20px 0;background-color:#F2F2F2'>" & return & \
		\
		"<legend style='color:#8498B4;'>&nbsp;&nbsp;{langPostData}&nbsp;&nbsp;</legend>" & return into tTemplate["legend"]

		# NO GET DATA
		put "<div style='color:#2B4662;font-weight:normal;padding:4px 0 4px 0'>{langNoPost}</div>" into tTemplate["noPost"]

		# BODY
		put "<tr><td width='50%' style='color:#2B4662;background-color:#ddd;'>&#36;_POST[{key}]&nbsp;&nbsp; </td><td width='50%' style='color:#FF0E00;font-weight:normal;background-color:#ddd;'>" into tTemplate["body"]

	end if


	# URI TABLE
	if pName is "uri" then
		# LEGEND
		put return & return & "<fieldset style='border:1px solid #8498B4;padding:6px 10px 10px 10px;margin:20px 0 20px 0;background-color:#F2F2F2'>" & return & \
		\
		"<legend style='color:#8498B4;'>&nbsp;&nbsp;{langURIstring}&nbsp;&nbsp;</legend>" & return into tTemplate["legend"]

		# NO URI
		put "<div style='color:#2B4662;font-weight:normal;padding:4px 0 4px 0'>{langNoURI}</div>" into tTemplate["noURI"]

		# BODY
		put "<div style='color:#2B4662;font-weight:normal;padding:4px 0 4px 0'>{uriString}</div>" into tTemplate["body"]

	end if


	# CONTROLLER INFO TABLE
	if pName is "info" then
		# LEGEND
		put return & return & "<fieldset style='border:1px solid #8498B4;padding:6px 10px 10px 10px;margin:20px 0 20px 0;background-color:#F2F2F2'>" & return & \
		\
		"<legend style='color:#8498B4;'>&nbsp;&nbsp;{langControllerInfo}&nbsp;&nbsp;</legend>" & return into tTemplate["legend"]

		# BODY
		put "<div style='color:#2B4662;font-weight:normal;padding:4px 0 4px 0'>{controller}/{handler}</div>" into tTemplate["body"]

	end if

	return tTemplate
end _rigDefaultProfilerTemplate





/*----------------------------------------------------------------------
--| FUNCTION rigProfilerOutput
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-01-10
--| Last Mod: 21-01-10
--| Requires: --
--|
--| Summary: Run the profiler.
--|
--| Format:  rigProfilerOutput()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigProfilerOutput
  local tOutput

	put "<div id=" & quote & "revIgniterProfiler" & quote && "style=" & quote & "clear:both;background-color:#fff;padding:10px;" & quote & ">" into tOutput

	put _rigCompileBenchmarks() after tOutput
	put _rigCompileQueries() after tOutput
	put _rigCompileGet() after tOutput
	put _rigCompilePost() after tOutput
	put _rigCompileURIstring() after tOutput
	put _rigCompileControllerInfo() after tOutput
	put "</div>" after tOutput

	return tOutput
end rigProfilerOutput






/*----------------------------------------------------------------------
--| FUNCTION rigProfilerGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Get profiler array variable value.
--|
--| Format: rigProfilerGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigProfilerGet pWhat
  if pWhat is among the keys of sProfilerTemplateA then
    return sProfilerTemplateA[pWhat]
  end if

  return empty
end rigProfilerGet




/*----------------------------------------------------------------------
--| COMMAND rigProfilerSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Setter for profiler variable.
--|
--| Format: rigProfilerSet param1, param2
--|
--| Parameters: string <pKey>, sProfilerTemplateA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigProfilerSet pKey pVal
  if pKey is among the keys of sProfilerTemplateA then
    put pVal into sProfilerTemplateA[pKey]
  end if
end rigProfilerSet










--| END OF Profiler.livecodescript
--| Location:  ./system/libraries/Profiler.livecodescript
----------------------------------------------------------------------