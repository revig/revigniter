script "Calendar"

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
# revIgniter Calendar Library
#
# This library enables the creation of calendars
#
# @package		revIgniter
# @subpackage	Libraries
# @category		Calendar
# @author			rabit@revigniter.com
# @link				https://revigniter.com/userGuide/libraries/calendar.html
##

## ------------------------------------------------------------------------




global gRigA

local sCalendarA, sCalTemp, sStackInUse





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-21
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
        rigLogMessage "debug", "Calendar Library Loaded"
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
  put "sunday" into sCalendarA["startDay"]
  put "long" into sCalendarA["monthType"]
  put "abr" into sCalendarA["dayType"]
  put FALSE into sCalendarA["showNextPrev"]
end _rigSetDefaultValues







/*----------------------------------------------------------------------
--| COMMAND rigRunInitialCalendarConfig
--|
--| Author: rabit
--| Version:  1.1
--| Created: 18-01-10
--| Last Mod: 22-12-14
--| Requires: rigLangLoadLang(), _rigInitializeCalendar
--|
--| Summary: Run initial configuration procedures.
--|
--| Format:  rigRunInitialCalendarConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialCalendarConfig pConfig
  local tConfig

	put pConfig into tConfig

	get rigLangLoadLang("calendar")

	put the seconds into sCalendarA["localTime"]

	if tConfig is not an array then
		if tConfig is not empty then
			split tConfig using numToCodepoint(1) and numToCodepoint(2)
		end if
	end if

	if tConfig is an array then
		_rigInitializeCalendar tConfig
	end if
end rigRunInitialCalendarConfig








/*----------------------------------------------------------------------
--| COMMAND _rigInitializeCalendar
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-01-10
--| Last Mod: 18-01-10
--| Requires: _rigSetInitialCalendarValue
--|
--| Summary: Initialize preferences.
--|
--| Format:  _rigInitializeCalendar param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigInitializeCalendar pConfig
  local tKey, tVal

	if pConfig is an array then
		repeat for each key tKey in pConfig
			put pConfig[tKey] into tVal

			_rigSetInitialCalendarValue tKey, tVal

		end repeat
	end if

end _rigInitializeCalendar









/*----------------------------------------------------------------------
--| COMMAND _rigSetInitialCalendarValue
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2010-01-18
--| Last Mod: 2019-01-02
--| Requires: --
--|
--| Summary: Set initial values.
--|
--| Format:  _rigSetInitialCalendarValue param1, param2
--|
--| Parameters: string <pKey>, mixed <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetInitialCalendarValue pKey pVal
  # VALUES ARE: template,localTime,startDay,monthType,dayType,showNextPrev,nextPrevURL
  if pKey is "template" then
    put pVal into sCalendarA["template"]
    replace "'" with quote in sCalendarA["template"]
    exit _rigSetInitialCalendarValue
  end if -- if pKey is "template"

  put pVal into sCalendarA[pKey]
end _rigSetInitialCalendarValue









/*----------------------------------------------------------------------
--| FUNCTION rigCalGenerate
--|
--| Author: rabit
--| Version:  1.1
--| Created: 18-01-10
--| Last Mod: 21-03-14
--| Requires: _rigAdjustDate(), _rigGetTotalDays(), _rigParseCalTemplate, _rigGetMonthName(),
--|            _rigGetDayNames(), rigLangLangLine()
--|
--| Summary: Generate the calendar.
--|
--| Format:  rigCalGenerate(param1, param2, param3)
--|
--| Parameters: integer <pYear>, integer <pMonth>, array <pData> the data to be shown
--|               in the calendar cells
--|
--| Return: string
----------------------------------------------------------------------*/

function rigCalGenerate pYear pMonth pData
  local tLocalTime, tYear, tMonth, tAdjustedDate, tTotalDays
  local tStartDays, tStartDay, tDate, tDay, tCurYear, tCurMonth
  local tCurDay, tIsCurrentMonth, tOut, tStandardURLs, tTempHeadingPrevCell
  local tColSpan, tMonthName, tTempHeadingNextCell, tDayNames
  local tTempWeekDayCell, tDayNum, tTemp

	# SET AND VALIDATE THE SUPPLIED MONTH/YEAR
	put sCalendarA["localTime"] into tLocalTime
   	convert tLocalTime to dateItems

	if (pYear is empty) or (pYear is FALSE) then
		put item 1 of tLocalTime into tYear
	else
		put pYear into tYear
	end if

	if (pMonth is empty) or (pMonth is FALSE) then
		put item 2 of tLocalTime into tMonth
	else
		put pMonth into tMonth
	end if

	if the number of chars of tYear is 1 then
		put "200" & tYear into tYear
	end if

	if the number of chars of tYear is 2 then
		put "20" & tYear into tYear
	end if

	if the number of chars of tMonth is 1 then
		put "0" & tMonth into tMonth
	end if

	put _rigAdjustDate(tMonth, tYear) into tAdjustedDate
	put tAdjustedDate["month"] into tMonth
	put tAdjustedDate["year"] into tYear

	# DETERMINE THE TOTAL DAYS IN THE MONTH
	put _rigGetTotalDays(tMonth, tYear) into tTotalDays

	# SET THE STARTING DAY OF THE WEEK
	put the english weekdayNames into tStartDays
   	put toLower(tStartDays) into tStartDays
   	split tStartDays using return

	if sCalendarA["startDay"] is among the keys of tStartDays then
		put tStartDays[sCalendarA["startDay"]] into tStartDay
	else
		put "1" into tStartDay
	end if

	# SET THE STARTING DAY NUMBER
	put tMonth & "/1/" & tYear into tDate
	convert tDate to dateItems
	put tStartDay + 1 - (item -1 of tDate) into tDay

	repeat while tDay > 1
		put tDay - 7 into tDay
	end repeat

	# SET THE CURRENT MONTH/YEAR/DAY
	# WE USE THIS TO DETERMINE THE "TODAY" DATE
	put item 1 of tLocalTime into tCurYear
	put item 2 of tLocalTime into tCurMonth
	put item 3 of tLocalTime into tCurDay

	if (tCurYear is tYear) and (tCurMonth is tMonth) then
		put TRUE into tIsCurrentMonth
	else
		put FALSE into tIsCurrentMonth
	end if

	# GENERATE THE TEMPLATE DATA ARRAY
	_rigParseCalTemplate

	# BEGIN BUILDING THE CALENDAR OUTPUT
	put sCalTemp["table_open"] & return & return into tOut

	put sCalTemp["heading_row_start"] & return after tOut

	# "PREVIOUS" MONTH LINK
	if sCalendarA["showNextPrev"] is TRUE then

		# CHECK IF QUERY STRING BASED URLs ARE ENABLED
		put rigFetchConfigItem("enableQueryStrings") into tStandardURLs

		# ADD A TRAILING SLASH TO THE  URL IF NEEDED
		if tStandardURLs is not TRUE then
			if char -1 of sCalendarA["nextPrevURL"] <> "/" then
				put sCalendarA["nextPrevURL"] & "/" into sCalendarA["nextPrevURL"]
			end if
		end if

		put _rigAdjustDate((tMonth - 1), tYear) into tAdjustedDate

		put sCalTemp["heading_previous_cell"] into tTempHeadingPrevCell

		if tStandardURLs is not TRUE then
			replace "{previous_url}" with sCalendarA["nextPrevURL"] & tAdjustedDate["year"] & "/" & tAdjustedDate["month"] in tTempHeadingPrevCell
		else
			replace "{previous_url}" with sCalendarA["nextPrevURL"] & "&cy=" & tAdjustedDate["year"] & "&cy=" & tAdjustedDate["month"] in tTempHeadingPrevCell
		end if

		put tTempHeadingPrevCell & return after tOut
	end if

	# HEADING CONTAINING THE MONTH/YEAR
	if sCalendarA["showNextPrev"] is TRUE then
		put "5" into tColSpan
	else
		put "7" into tColspan
	end if

	replace "{colspan}" with tColspan in sCalTemp["heading_title_cell"]
	put _rigGetMonthName(tMonth) into tMonthName
	replace "{heading}" with tMonthName & "&nbsp;" & tYear in sCalTemp["heading_title_cell"]

	put sCalTemp["heading_title_cell"] & return after tOut

	# "NEXT" MONTH LINK
	if sCalendarA["showNextPrev"] is TRUE then
		put _rigAdjustDate((tMonth + 1), tYear) into tAdjustedDate
		put sCalTemp["heading_next_cell"] into tTempHeadingNextCell


		if tStandardURLs is not TRUE then
			replace "{next_url}" with sCalendarA["nextPrevURL"] & tAdjustedDate["year"] & "/" & tAdjustedDate["month"] in tTempHeadingNextCell
		else
			replace "{next_url}" with sCalendarA["nextPrevURL"] & "&cy=" & tAdjustedDate["year"] & "&cy=" & tAdjustedDate["month"] in tTempHeadingNextCell
		end if

		put tTempHeadingNextCell & return after tOut
	end if

	put sCalTemp["heading_row_end"] & return & return after tOut

	# WRITE THE CELLS CONTAINING THE DAYS OF THE WEEK
	put sCalTemp["week_row_start"] & return after tOut

	put _rigGetDayNames() into tDayNames

	repeat with i = 0 to 6
		put sCalTemp["week_day_cell"] into tTempWeekDayCell

		put ((tStartDay + i) mod 7) into tDayNum
      		if tDayNum = 0 then
         		put 7 into tDayNum
      		end if

		replace "{week_day}" with tDayNames[tDayNum] in tTempWeekDayCell
		put tTempWeekDayCell after tOut
	end repeat

	put return & sCalTemp["week_row_end"] & return after tOut

	# BUILD THE MAIN BODY OF THE CALENDAR
	repeat while tDay <= tTotalDays
		put return & sCalTemp["cal_row_start"] & return after tOut

		repeat for 7 times
			if (tIsCurrentMonth is TRUE) and (tDay is tCurDay) then
				put sCalTemp["cal_cell_start_today"] after tOut
			else
				put sCalTemp["cal_cell_start"] after tOut
			end if

			if (tDay > 0) and (tDay <= tTotalDays) then

				if pData[tDay] is not empty then
					# CELLS WITH CONTENT
					if (tIsCurrentMonth is TRUE) and (tDay is tCurDay) then
						put sCalTemp["cal_cell_content_today"] into tTemp
					else
						put sCalTemp["cal_cell_content"] into tTemp
					end if

					replace "{content}" with pData[tDay] in tTemp
					replace "{day}" with tDay in tTemp
					put tTemp after tOut

				else
					# CELLS WITH NO CONTENT
					if (tIsCurrentMonth is TRUE) and (tDay is tCurDay) then
						put sCalTemp["cal_cell_no_content_today"] into tTemp
					else
						put sCalTemp["cal_cell_no_content"] into tTemp
					end if

					replace "{day}" with tDay in tTemp
					put tTemp after tOut
				end if

			else
				# BLANK CELLS
				put sCalTemp["cal_cell_blank"] after tOut
			end if

			if (tIsCurrentMonth is TRUE) and (tDay is tCurDay) then
				put sCalTemp["cal_cell_end_today"] after tOut
			else
				put sCalTemp["cal_cell_end"] after tOut
			end if

			add 1 to tDay
		end repeat

		put return & sCalTemp["cal_row_end"] & return after tOut

	end repeat

	put return & sCalTemp["table_close"] after tOut

	return tOut
end rigCalGenerate







/*----------------------------------------------------------------------
--| FUNCTION _rigGetMonthName
--|
--| Author: rabit
--| Version:  1.1
--| Created: 18-01-10
--| Last Mod: 21-03-14
--| Requires: rigLangLangLine()
--|
--| Summary: Generates a textual month name based on the numeric
--|            month provided.
--|
--| Format:  _rigGetMonthName(param1)
--|
--| Parameters: integer <pMonth>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigGetMonthName pMonth
  local tAbbrMonthsList, tCounter, tMonthNames, tLongMonthsList
  local tMonth, tLangLineMonth, tFirstCharUpper

	if sCalendarA["monthType"] is "short" then
		put the abbreviated english monthNames into tAbbrMonthsList

		put 0 into tCounter

		repeat for each line thisLine in tAbbrMonthsList
			add 1 to tCounter
			if the number of chars of tCounter is 1 then
				put "0" & tCounter into tCounter
			end if

			put "cal_" & toLower(thisLine) into tMonthNames[tCounter]
		end repeat
	else

		put the long english monthNames into tLongMonthsList

		put 0 into tCounter

		repeat for each line thisLine in tLongMonthsList
			add 1 to tCounter
			if the number of chars of tCounter is 1 then
				put "0" & tCounter into tCounter
			end if

			put "cal_" & toLower(thisLine) into tMonthNames[tCounter]
		end repeat
	end if

	put tMonthNames[pMonth] into tMonth
	put rigLangLangLine(tMonth) into tLangLineMonth
	if tLangLineMonth is FALSE then
		put char 5 to (the number of chars in tMonth) of tMonth into tMonth
		put toupper(char 1 of tMonth) into tFirstCharUpper
		put tFirstCharUpper & (char 2 to -1 of tMonth) into tMonth

		return tMonth
	end if

	return tLangLineMonth
end _rigGetMonthName








/*----------------------------------------------------------------------
--| FUNCTION _rigGetDayNames
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-01-10
--| Last Mod: 18-01-10
--| Requires: rigLangLangLine()
--|
--| Summary: Returns an array of day names (Sunday, Monday, etc.) based
--|            on the type.  Options: long, short, abbrev.
--|
--| Format:  _rigGetDayNames(param1)
--|
--| Parameters: string <pDayType
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigGetDayNames pDayType
  local tDayNames, tCounter, tLangLine, tFirstCharUpper, tName, tDays

	if pDayType is not empty then
		put pDayType into sCalendarA["dayType"]
	end if

	if sCalendarA["dayType"] is "long" then
		put "sunday,monday,tuesday,wednesday,thursday,friday,saturday" into tDayNames
	else if sCalendarA["dayType"] is "short" then
		put "sun,mon,tue,wed,thu,fri,sat" into tDayNames
	else
		put "su,mo,tu,we,th,fr,sa"into tDayNames
	end if

	put 0 into tCounter
	repeat for each item thisItem in tDayNames
		add 1 to tCounter

		put rigLangLangLine("cal_" & thisItem) into tLangLine
		if tLangLine is FALSE then
			put toupper(char 1 of thisItem) into tFirstCharUpper
			put tFirstCharUpper & (char 2 to -1 of thisItem) into tName
			put tName into tDays[tCounter]
		else
			put tLangLine into tDays[tCounter]
		end if
	end repeat

	return tDays
end _rigGetDayNames








/*----------------------------------------------------------------------
--| FUNCTION _rigAdjustDate
--|
--| Author: rabit
--| Version:  1.1
--| Created: 18-01-10
--| Last Mod: 21-03-14
--| Requires: --
--|
--| Summary: This function makes sure that we have a valid month/year.
--|            For example, if you submit 13 as the month, the year will
--|            increment and the month will become January.
--|
--| Format:  _rigAdjustDate(param1, param2)
--|
--| Parameters: integer <pMonth>, integer <pYear>
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigAdjustDate pMonth, pYear
  local tDateA

	put pMonth into tDateA["month"]
	put pYear into tDateA["year"]

	repeat while tDateA["month"] > 12
		subtract 12 from tDateA["month"]
		add 1 to tDateA["year"]
	end repeat

	repeat while tDateA["month"] <= 0
		add 12 to tDateA["month"]
		subtract 1 from tDateA["year"]
	end repeat

	if the number of chars of tDateA["month"] = 1 then
		put "0" & tDateA["month"] into tDateA["month"]
	end if

	return tDateA
end _rigAdjustDate








/*----------------------------------------------------------------------
--| FUNCTION _rigGetTotalDays
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-01-10
--| Last Mod: 18-01-10
--| Requires: --
--|
--| Summary: Total days in a given month.
--|
--| Format:  _rigGetTotalDays(param1, param2)
--|
--| Parameters: integer <pMonth>, integer <pYear>
--|
--| Return: integer
----------------------------------------------------------------------*/

private function _rigGetTotalDays pMonth pYear
  local tDaysInMonth

	if pMonth is not an integer then
		return 0
	else
		if (pMonth < 0) or (pMonth > 12) then
			return 0
		end if
	end if

	put "31,28,31,30,31,30,31,31,30,31,30,31" into tDaysInMonth

	# IS THE YEAR A LEAP YEAR?
	if pMonth = 2 then
		if ((pYear mod 400) = 0) or (((pYear mod 4) = 0) and ((pYear mod 100) <> 0)) then
			return 29
		end if
	end if

	return item  pMonth of tDaysInMonth
end _rigGetTotalDays








/*----------------------------------------------------------------------
--| FUNCTION _rigDefaultCalTemplate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-01-10
--| Last Mod: 18-01-10
--| Requires: --
--|
--| Summary: Set Default Template Data.
--|            This is used in the event that the user
--|            has not created their own template.
--|
--| Format:  _rigDefaultCalTemplate()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigDefaultCalTemplate
  local tTemplateArray

	put "<table border=" & quote & "0" & quote && "cellpadding=" & quote & "4" & quote && "cellspacing=" & quote & "0" & quote & ">" into tTemplateArray["table_open"]
	put "<tr>" into tTemplateArray["heading_row_start"]
	put "<th><a href=" & quote & "{previous_url}" & quote & ">&lt;&lt;</a></th>" into tTemplateArray["heading_previous_cell"]
	put "<th colspan=" & quote & "{colspan}" & quote & ">{heading}</th>" into tTemplateArray["heading_title_cell"]
	put "<th><a href=" & quote & "{next_url}" & quote & ">&gt;&gt;</a></th>" into tTemplateArray["heading_next_cell"]
	put "</tr>" into tTemplateArray["heading_row_end"]
	put "<tr>" into tTemplateArray["week_row_start"]
	put "<td>{week_day}</td>" into tTemplateArray["week_day_cell"]
	put "</tr>" into tTemplateArray["week_row_end"]
	put "<tr>" into tTemplateArray["cal_row_start"]
	put "<td>" into tTemplateArray["cal_cell_start"]
	put "<td>" into tTemplateArray["cal_cell_start_today"]
	put "<a href=" & quote & "{content}" & quote & ">{day}</a>" into tTemplateArray["cal_cell_content"]
	put "<a href=" & quote & "{content}" & quote & "><strong>{day}</strong></a>" into tTemplateArray["cal_cell_content_today"]
	put "{day}" into tTemplateArray["cal_cell_no_content"]
	put "<strong>{day}</strong>" into tTemplateArray["cal_cell_no_content_today"]
	put "&nbsp;" into tTemplateArray["cal_cell_blank"]
	put "</td>" into tTemplateArray["cal_cell_end"]
	put "</td>" into tTemplateArray["cal_cell_end_today"]
	put "</tr>" into tTemplateArray["cal_row_end"]
	put "</table>" into tTemplateArray["table_close"]

	return tTemplateArray
end _rigDefaultCalTemplate








/*----------------------------------------------------------------------
--| COMMAND _rigParseCalTemplate
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2010-01-18
--| Last Mod: 2017-06-27
--| Requires: _rigDefaultCalTemplate()
--|
--| Summary: Harvests the data within the template {pseudo-variables}
--|            used to display the calendar.
--|
--| Format:  _rigParseCalTemplate
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigParseCalTemplate
  local tToday, tPseudoVars, tMatch, tRegEx, tTempPseudoVar

	put _rigDefaultCalTemplate() into sCalTemp

	if sCalendarA["template"] is empty then
		exit _rigParseCalTemplate
	end if

	put "cal_cell_start_today,cal_cell_content_today,cal_cell_no_content_today,cal_cell_end_today" into tToday

	put "table_open,table_close,heading_row_start,heading_previous_cell,heading_title_cell,heading_next_cell,heading_row_end,week_row_start,week_day_cell,week_row_end,cal_row_start,cal_cell_start,cal_cell_content,cal_cell_no_content,cal_cell_blank,cal_cell_end,cal_row_end,cal_cell_start_today,cal_cell_content_today,cal_cell_no_content_today,cal_cell_end_today" into tPseudoVars

	put empty into tMatch -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	repeat for each item pseudoVar in tPseudoVars
		put "(?i)\{" & pseudoVar & "\}(.*?)\{\/" & pseudoVar & "\}" into tRegEx
		get matchText(sCalendarA["template"], tRegEx, tMatch)
		if it is TRUE then
			put tMatch into sCalTemp[pseudoVar]
		else
			if pseudoVar is among the items of tToday then
				# REMOVE _today
				put char 1 to -7 of pseudoVar into tTempPseudoVar
				put sCalTemp[tTempPseudoVar] into sCalTemp[pseudoVar]
			end if
		end if
	end repeat
end _rigParseCalTemplate





/*----------------------------------------------------------------------
--| FUNCTION rigCalendarGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-02
--| Last Mod: 2019-01-02
--| Requires: --
--|
--| Summary: Get calendar variable value.
--|
--| Format:  rigCalendarGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigCalendarGet pWhat
  if pWhat is among the keys of sCalendarA then
    return sCalendarA[pWhat]
  end if

  return empty
end rigCalendarGet




/*----------------------------------------------------------------------
--| COMMAND rigCalendarSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-02
--| Last Mod: 2019-01-02
--| Requires: --
--|
--| Summary: Setter for calendar variables.
--|
--| Format:  rigCalendarSet param1, param2
--|
--| Parameters: string <pKey> sCalendarA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigCalendarSet pKey pVal
  if pKey is among the keys of sCalendarA then
    put pVal into sCalendarA[pKey]
  end if
end rigCalendarSet









--| END OF Calendar.livecodescript
--| Location:  ./system/libraries/Calendar.livecodescript
----------------------------------------------------------------------