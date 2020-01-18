script "dateHelper"

##
# RevIgniter
#
# An application development framework for LiveCode
# modeled on CodeIgniter
#
# @package		RevIgniter
# @author		  rabit@revigniter.com
# @copyright	Copyright (c) 2009 - 2020, dimensionB Bitter u. Bitter GmbH
# @license		https://revigniter.com/userGuide/license.html
# @link		    https://revigniter.com
##

## ------------------------------------------------------------------------

##
# RevIgniter Date Helpers
#
# @package		RevIgniter
# @subpackage	Helpers
# @category	  Helpers
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/helpers/date_helper.html
##

## ------------------------------------------------------------------------





global gRigA

local sDateItems, sLongTime, sInternetDate, sStackInUse





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-25
 --| Last Mod: --
 --| Requires: --
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
    end if
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack






/*----------------------------------------------------------------------
--| FUNCTION rigNow
--|
--| Author: rabit
--| Version:  1.1
--| Created: 03-05-2010
--| Last Mod: 15-07-2012
--| Requires: rigMasterNow()
--|
--| Summary: Returns the current time as timestamp (seconds) referenced, either
--|            to your server's local time or GMT, based on the "timeReference"
--|            setting in your config file.
--| 
--| Format:  rigNow()
--|
--| Parameters: --
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigNow
	return rigMasterNow()
end rigNow









/*----------------------------------------------------------------------
--| FUNCTION rigMdate
--|
--| Author: rabit
--| Version:  1.1
--| Created: 04-05-2010
--| Last Mod: 21-03-2014
--| Requires: _rigFragmentDate, _rigTranslatedDateItem()
--|
--| Summary: This functon converts date codes formatted using the MySQL style.
--| 
--| Format:  rigMdate(param1, param2)
--|
--| Parameters: string <pDateString>, integer <pTime>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigMdate pDateString, pTime
  local tTime, tFormatedDate, tCounter, tDateStringItems
  
	set the caseSensitive to TRUE

	if pTime is empty then
		put the seconds into tTime
	else
		put pTime into tTime
	end if

	# STORE DATE FRAGMENTS IN LOCAL VARIABLES
	_rigFragmentDate tTime

	put pDateString into tFormatedDate

	# GET DATE ITEMS OF THE DATE STRING, PUT THESE INTO A COMMA SEPARATED LIST
	put 1 into tCounter
	repeat for each char thisByte in pDateString
		if thisByte is "%" then
			put "%" & char (tCounter + 1) of pDateString & comma after tDateStringItems
		end if

		add 1 to tCounter
	end repeat

	delete char -1 of tDateStringItems

	# FORMAT DATE STRING ITERATING OVER THE DATE ITEMS LIST
	repeat for each item thisItem in tDateStringItems
		replace thisItem with _rigTranslatedDateItem(thisItem, tTime) in tFormatedDate
	end repeat

	return tFormatedDate
end rigMdate







/*----------------------------------------------------------------------
--| FUNCTION _rigTranslatedDateItem
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2010-05-04
--| Last Mod: 2018-04-23
--| Requires: rigLangLoadLang(), rigLangLangLine(), rigDayOfYear(), rigWeekOfYear()
--|
--| Summary: Translates MySQL date codes.
--| 
--| Format:  _rigTranslatedDateItem(param1, param2)
--|
--| Parameters: integer <pYear>
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigTranslatedDateItem pItem, pTime
  local tWeekdays, tTranslatedItem, tMonthnames, tItemSuffix, tYear
  local tMonth, tDay, tHour
  
	set the caseSensitive to TRUE
	switch pItem
		# ABBREVIATED NAME OF DAY
		case "%a"
			get rigLangLoadLang("date")
			put rigLangLangLine("date_abbrWeekdays") into tWeekdays
			put item (item 7 of sDateItems) of tWeekdays into tTranslatedItem
		break
		# ABBREVIATED NAME OF MONTH
		case "%b"
			get rigLangLoadLang("date")
			put rigLangLangLine("date_abbrMonthnames") into tMonthnames
			put item (item 2 of sDateItems) of tMonthnames into tTranslatedItem
		break
		# ONE AND TWO DIGITS MONTH
		case "%c"
			put item 2 of sDateItems into tTranslatedItem
		break
		# DAY WITH ENGLISH SUFFIX
		case "%D"
			put item 3 of sDateItems into tTranslatedItem
			put "th" into tItemSuffix
			if tTranslatedItem <= 3 or (tTranslatedItem >= 21 and tTranslatedItem <= 23) or tTranslatedItem = 31 then
				put item tTranslatedItem mod 10 of "st,nd,rd" into tItemSuffix
			end if
			put tItemSuffix after tTranslatedItem
		break
		# TWO DIGITS DAY
		case "%d"
			put item 3 of sDateItems into tTranslatedItem
			if the number of chars of tTranslatedItem is 1 then
				put "0" before tTranslatedItem
			end if
		break
		# ONE AND TWO DIGITS DAY
		case "%e"
			put item 3 of sDateItems into tTranslatedItem
		break
		# TWO DIGITS HOUR 00 - 24
		case "%H"
			put char 1 to 2 of item 5 of sInternetDate into tTranslatedItem
		break
		# TWO DIGITS HOURS 00 - 12
		case "%h"
			put item 1 of sLongTime into tTranslatedItem
			if the number of chars of tTranslatedItem is 1 then
				put "0" before tTranslatedItem
			end if
		break
		# TWO DIGITS HOURS 00 - 12
		case "%I"
			put item 1 of sLongTime into tTranslatedItem
			if the number of chars of tTranslatedItem is 1 then
				put "0" before tTranslatedItem
			end if
		break
		# TWO DIGITS MINUTES
		case "%i"
			put item 2 of sLongTime into tTranslatedItem
			if the number of chars of tTranslatedItem is 1 then
				put "0" before tTranslatedItem
			end if
		break
		# DAY IN YEAR 001 - 366
		# 
		case "%j"
			put item 1 of sDateItems into tYear
			put item 2 of sDateItems into tMonth
			put item 3 of sDateItems into tDay
			put rigDayOfYear(tYear, tMonth, tDay) into tTranslatedItem
		break
		# ONE AND TWO DIGITS HOUR 0 - 23
		case "%k"
			put item 4 of sDateItems into tTranslatedItem
		break
		# ONE DIGIT HOUR 0 - 12
		case "%l"
			put item 1 of sLongTime into tTranslatedItem
		break
		# MONTH NAME
		case "%M"
			get rigLangLoadLang("date")
			put rigLangLangLine("date_Monthnames") into tMonthnames
			put item (item 2 of sDateItems) of tMonthnames into tTranslatedItem
		break
		# TWO DIGITS MONTH
		case "%m"
			put item 2 of sDateItems into tTranslatedItem
			if the number of chars of tTranslatedItem is 1 then
				put "0" before tTranslatedItem
			end if
		break
		# DIFFERENCE TO GREENWICH TIME (GMT) IN HOURS
		case "%O"
		 put item 6 of sInternetDate into tTranslatedItem
		break
		# PM OR AM
		case "%p"
			put item 4 of sLongTime into tTranslatedItem
		break
		# TIME hh:mm:ss FOLLOWED BY AM OR PM
		case "%r"
			put item 1 of sLongTime into tHour
			if the number of chars of tHour is 1 then
				put "0" before tHour
			end if
			put tHour & ":" & (item 2 of sLongTime) & ":" & (item 3 of sLongTime) && (item 4 of sLongTime) into tTranslatedItem
		break
		# SECONDS 00 - 59
		case "%S"
			put item 3 of sLongTime into tTranslatedItem
		break
		# SECONDS 00 - 59
		case "%s"
			put item 3 of sLongTime into tTranslatedItem
		break
		# TIME 24h hh:mm:ss
		case "%T"
			put item 5 of sInternetDate into tTranslatedItem
		break
		# NUMBER OF WEEK WHERE SUNDAY IS THE FIRST DAY IN WEEK 00 - 53
		case "%U"
			put _rigWeekOfYear( , TRUE) into tTranslatedItem
		break
		# NUMBER OF WEEK WHERE MONDAY IS THE FIRST DAY IN WEEK 00 - 53
		case "%u"
			put _rigWeekOfYear() into tTranslatedItem
		break
		# DAY NAME
		case "%W"
			get rigLangLoadLang("date")
			put rigLangLangLine("date_Weekdays") into tWeekdays
			put item (item 7 of sDateItems) of tWeekdays into tTranslatedItem
		break
		# DAY IN WEEK 0 - 6
		case "%w"
			put (item 7 of sDateItems) - 1 into tTranslatedItem
		break
		# TWO DIGITS YEAR
		case "%y"
			put char 3 to 4 of (item 1 of sDateItems) into tTranslatedItem
		break
		# FOUR DIGITS YEAR
		case "%Y"
			put item 1 of sDateItems into tTranslatedItem
		break
    # OFFSET TO UTC (hh:mm)
    case "%Q"
      put item 6 of sInternetDate into tTranslatedItem
      put char 1 to -3 of tTranslatedItem & ":" & char -2 to -1 of tTranslatedItem into tTranslatedItem
    break
		# LITERAL '%'
		case "%%"
			put "%" into tTranslatedItem
		break
		default
		if (char 1 of pItem is "%") and (the number of chars of pItem is 2) then
			put char 2 of pItem into tTranslatedItem
		else
			put "?" into tTranslatedItem
		end if
	end switch

	return tTranslatedItem
end _rigTranslatedDateItem







/*----------------------------------------------------------------------
--| COMMAND _rigFragmentDate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-05-2010
--| Last Mod: 04-05-2010
--| Requires: --
--|
--| Summary: Store date fragments in local variables.
--| 
--| Format:  _rigFragmentDate param1
--|
--| Parameters: integer <pTimestamp>
--|
--| Return: boolean
----------------------------------------------------------------------*/

private command _rigFragmentDate pTimestamp
  local tTime
  
	# STORE DATE ITEMS
	put pTimestamp into tTime
	convert (tTime) from seconds to dateItems
	put it into sDateItems

	# STORE THE LONG TIME
	put pTimestamp into tTime
	convert (tTime) from seconds to long time
	put it into sLongTime

	replace ":" with comma in sLongTime
	replace space with comma in sLongTime

	# STORE THE INTERNET DATE
	put pTimestamp into tTime
	convert (tTime) from seconds to internet date
	put it into sInternetDate

	replace "," with "" in sInternetDate
	replace space with comma in sInternetDate
end _rigFragmentDate







/*----------------------------------------------------------------------
--| FUNCTION rigDayOfYear
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-05-2010
--| Last Mod: 04-05-2010
--| Requires: _rigIsLeapYear()
--|
--| Summary: Returns the day in a given year as integer.
--| 
--| Format:  rigDayOfYear(param1)
--|
--| Parameters: integer <pYear>, integer <pMonth>, integer <pDay>
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigDayOfYear pYear pMonth pDay
  local tDayNums, tNumDays
  
	# IS THE YEAR A LEAP YEAR
	if _rigIsLeapYear(pYear) is TRUE then
		put "31,29,31,30,31,30,31,31,30,31,30,31" into tDayNums
	else
		put "31,28,31,30,31,30,31,31,30,31,30,31" into tDayNums
	end if

	repeat with i = 1 to (pMonth - 1)
		add item i of tDayNums to tNumDays
	end repeat

	add pDay to tNumDays

	put format("%3d", tNumDays) into tNumDays
	replace space with "0" in tNumDays

	return tNumDays
end rigDayOfYear








/*----------------------------------------------------------------------
--| FUNCTION _rigIsLeapYear
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-05-2010
--| Last Mod: 04-05-2010
--| Requires: --
--|
--| Summary: Checks if year is leap year.
--| 
--| Format:  _rigIsLeapYear(param1)
--|
--| Parameters: integer <pYear>
--|
--| Return: boolean
----------------------------------------------------------------------*/

private function _rigIsLeapYear pYear
	if ((pYear mod 400) = 0) or (((pYear mod 4) = 0) and ((pYear mod 100) <> 0)) then
		return TRUE
	end if
	
	return FALSE
end _rigIsLeapYear








/*----------------------------------------------------------------------
--| FUNCTION _rigWeekOfYear
--|
--| Author: rabit
--| Version:  1.0
--| Created: 05-05-2010
--| Last Mod: 05-05-2010
--| Requires: --
--|
--| Summary: This function returns the week number of a given timestamp.
--| 
--| Format:  _rigWeekOfYear(param1, param2)
--|
--| Parameters: integer <pTime>, bool <pSundayFirst>
--|
--| Return: integer
----------------------------------------------------------------------*/

private function _rigWeekOfYear pTime pSundayFirst
  local tSundayFirst, tDateItems, tYear, tMonth, tDay, tNumberDays
  local tDateItemsFirstOfYear, tFirstDayNum, tDaysToSubtract
  
	if pSundayFirst is empty then
		put FALSE into tSundayFirst
	else
		put pSundayFirst into tSundayFirst
	end if

	if pTime is not empty then
		convert (pTime) from seconds to dateItems
		put it into tDateItems
	else
		put sDateItems into tDateItems
	end if

	if tDateItems <> empty then
		# GET NUMBER OF DAYS
		put item 1 of tDateItems into tYear
		put item 2 of tDateItems into tMonth
		put item 3 of tDateItems into tDay
		put rigDayOfYear(tYear, tMonth, tDay) into tNumberDays

		# GET DAY NUMBER OF FIRST DAY OF YEAR
		convert "01/01/" & tYear to dateItems
		put it into tDateItemsFirstOfYear
		put item 7 of tDateItemsFirstOfYear into tFirstDayNum

		# FIRST DAY IN WEEK IS MONDAY
		put (7 mod tFirstDayNum) + 2 into tDaysToSubtract

		if tSundayFirst is TRUE then
			# FIRST DAY IN WEEK IS SUNDAY
			put (7 mod tFirstDayNum) + 1 into tDaysToSubtract
		else
			# FIRST DAY IN WEEK IS MONDAY
			put (7 mod tFirstDayNum) + 2 into tDaysToSubtract
		end if

		return ceil((tNumberDays - tDaysToSubtract) / 7)
	end if

	return "?"
end _rigWeekOfYear







/*----------------------------------------------------------------------
--| FUNCTION rigStandardDate
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2010-05-06
--| Last Mod: 2018-04-24
--| Requires: rigMdate()
--|
--| Summary: Returns a date formatted according to the submitted standard.
--| 
--| Format:  rigStandardDate(param1, param2)
--|
--| Parameters: string <pFormat>, integer <pTime>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigStandardDate pFormat pTime
  local tFormat, tFormatArray
  
	if pFormat is empty then
		put "DATE_RFC822" into tFormat
	else
		put pFormat into tFormat
	end if

	# BUILD ARRAY OF STANDARD FORMATS
	put "%Y-%m-%dT%H:%i:%s%Q" into tFormatArray["DATE_ATOM"]
	put "%W, %d-%b-%y %H:%i:%s UTC" into tFormatArray["DATE_COOKIE"]
	put "%Y-%m-%dT%H:%i:%s%O" into tFormatArray["DATE_ISO8601"]
	put "%a, %d %b %y %H:%i:%s %O" into tFormatArray["DATE_RFC822"]
	put "%W, %d-%b-%y %H:%i:%s UTC" into tFormatArray["DATE_RFC850"]
	put "%a, %d %b %y %H:%i:%s %O" into tFormatArray["DATE_RFC1036"]
	put "%a, %d %b %Y %H:%i:%s %O" into tFormatArray["DATE_RFC1123"]
	put "%a, %d %b %Y %H:%i:%s %O" into tFormatArray["DATE_RFC2822"]
	put "%a, %d %b %Y %H:%i:%s %O" into tFormatArray["DATE_RSS"]
	put "%Y-%m-%dT%H:%i:%s%Q" into tFormatArray["DATE_W3C"]

	if tFormatArray[tFormat] is empty then
		return FALSE
	end if

	return rigMdate(tFormatArray[tFormat], pTime)
end rigStandardDate









/*----------------------------------------------------------------------
--| FUNCTION rigLocalToGMT
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-05-2010
--| Last Mod: 06-05-2010
--| Requires: --
--|
--| Summary: Converts a local timestamp (the seconds) to GMT (as seconds).
--| 
--| Format:  rigLocalToGMT(param1)
--|
--| Parameters: integer <pTime>
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigLocalToGMT pTime
  local tTime, tSeconds, tInternetDate, tGMToffset, tPrefix, tMinutesOffset
  local tHoursOffset, tGMToffsetSecs, tGMT
  
	if pTime is empty then
		put the seconds into tTime
	else
		put pTime into tTime
	end if

	put tTime into tSeconds

	# GET THE DATETIME IN SECONDS
	convert (tTime) from seconds to internet date
	put it into tInternetDate

	# GET GMT OFFSET
	put the last word of tInternetDate into tGMToffset

	if char 1 of tGMToffset is "-" then
		put "-" into tPrefix
	else
		put "" into tPrefix
	end if

	# MINUTES
	put char -2 to -1 of tGMToffset into tMinutesOffset
	# HOURS
	put char 2 to 3 of tGMToffset into tHoursOffset

	put tPrefix & ((tHoursOffset * 3600) + (tMinutesOffset * 60)) into tGMToffsetSecs

	# GET GMT IN SECONDS
	put tSeconds - tGMToffsetSecs into tGMT

	return tGMT
end rigLocalToGMT







/*----------------------------------------------------------------------
--| FUNCTION rigGmtToLocal
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-05-2010
--| Last Mod: 06-05-2010
--| Requires: rigNow(), rigTimezones()
--|
--| Summary: Takes a timestamp (the seconds) (in GMT) as input, and returns
--|            at the local value based on the timezone and DST setting submitted.
--| 
--| Format:  rigGmtToLocal(param1, param2, param3)
--|
--| Parameters: integer <pTime>, string <pTimeZone>, bool <pDST> daylight savings time
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigGmtToLocal pTime pTimeZone pDST
  local tTimeZone, tTime
  
	if pTime is empty then
		return rigNow()
	end if

	if pTimeZone is empty then
		put "UTC" into tTimeZone
	else
		put pTimeZone into tTimeZone
	end if

	put pTime + (rigTimezones(tTimeZone) * 3600) into tTime

	if pDST is TRUE then
		put tTime + 3600 into tTime
	end if

	return tTime
end rigGmtToLocal







/*----------------------------------------------------------------------
--| FUNCTION rigMysqlTimeToSeconds
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-05-2010
--| Last Mod: 21-03-2014
--| Requires: --
--|
--| Summary: Converts a MySQL Datetime / Timestamp to seconds.
--| 
--| Format:  rigMysqlTimeToSeconds(param1)
--|
--| Parameters: string <pMysqlTime>
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigMysqlTimeToSeconds pMysqlTime
  local tMysqlTime, tYear, tMonth, tDay, tShortDate, tDateItems
  
	put pMysqlTime into tMysqlTime

	if ("-" is in tMysqlTime) and (":" is in tMysqlTime) then
		# FORMAT: YYYY-MM-DD HH:MM:SS
		replace "-" with comma in tMysqlTime
		replace space with comma in tMysqlTime
		replace ":" with comma in tMysqlTime
	else
		# FORMAT: YYYYMMDDHHMMSS
		put comma after char 4 of tMysqlTime
		put comma after char 7 of tMysqlTime
		put comma after char 10 of tMysqlTime
		put comma after char 13 of tMysqlTime
		put comma after char 16 of tMysqlTime
	end if

	# BUILD THE SHORT DATE
	put char 3 to 4 of item 1 of tMysqlTime into tYear

	if char 1 of item 2 of tMysqlTime is 0 then
		put char 2 of item 2 of tMysqlTime into tMonth
	else
		put item 2 of  tMysqlTime into tMonth
	end if

	if char 1 of item 3 of tMysqlTime is 0 then
		put char 2 of item 3 of tMysqlTime into tDay
	else
		put item 3 of  tMysqlTime into tDay
	end if

	put tMonth & "/" & tDay & "/" & tYear into tShortDate
	
	# BUILD THE DATE ITEMS
	convert (tShortDate) from short date to dateItems
	put it into tDateItems

	put item 4 of tMysqlTime into item 4 of tDateItems
	put item 5 of tMysqlTime into item 5 of tDateItems
	put item 6 of tMysqlTime into item 6 of tDateItems

	convert (tDateItems) from dateItems to seconds
	return it
end rigMysqlTimeToSeconds







/*----------------------------------------------------------------------
--| FUNCTION rigTimestampToHuman
--|
--| Author: rabit
--| Version:  1.1
--| Created: 07-05-2010
--| Last Mod: 21-03-2014
--| Requires: --
--|
--| Summary: Formats timestamp (seconds) to the following prototype: 2010-08-21 11:35 PM
--| 
--| Format:  rigTimestampToHuman(param1, param2, param3)
--|
--| Parameters: integer <pTime>, bool <pShowSecs>, string <pFormat>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigTimestampToHuman pTime pShowSecs pFormat
  local tTime, tShowSecs, tFormat, tDateItems, tLongTime, tDate
  
	if pTime is empty then
		put the seconds into tTime
	else
		put pTime into tTime
	end if

	if pShowSecs is empty then
		put FALSE into tShowSecs
	else
		put pShowSecs into tShowSecs
	end if

	if pFormat is empty then
		put "us" into tFormat
	else
		put pFormat into tFormat
	end if

	convert (tTime) from seconds to dateItems
	put it into tDateItems

	convert (tTime) from seconds to long time
	put it into tLongTime
	replace ":" with comma in tLongTime
	replace space with comma in tLongTime

	repeat with i = 2 to 6
		if the number of chars of item i of tDateItems is 1 then
			put "0" & item i of tDateItems into item i of tDateItems
		else
			put item i of tDateItems into item i of tDateItems
		end if
	end repeat

	# YYYY-MM-DD
	put (item 1 of tDateItems) & "-" & (item 2 of tDateItems) & "-" & (item 3 of tDateItems) into tDate

	# ADD HH:MM:SS AM / PM
	if pFormat is "us" then
		put " " & (item 1 of tLongTime) & ":" & (item 2 of tLongTime) after tDate
		if pShowSecs is TRUE then
			put ":" & (item 3 of tLongTime) && (item 4 of tLongTime) after tDate
		else
			put " " & (item 4 of tLongTime) after tDate
		end if
	else
		put " " & (item 4 of tDateItems) & ":" & (item 5 of tDateItems) after tDate
		if pShowSecs is TRUE then
			put ":" & (item 6 of tDateItems) after tDate
		end if
	end if

	return tDate
end rigTimestampToHuman







/*----------------------------------------------------------------------
--| FUNCTION rigHumanToTimestamp
--|
--| Author: rabit
--| Version:  1.1
--| Created: 07-05-2010
--| Last Mod: 21-03-2014
--| Requires: rigTrim(), rigPregReplace()
--|
--| Summary: Convert "human" date to timestamp (seconds).
--| 
--| Format:  rigHumanToTimestamp(param1)
--|
--| Parameters: string <pDatestring>
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigHumanToTimestamp pDatestring
  local tDatestring, tRegEx, tHour, tSecs, tTempDate, tDateItems
  
	if pDatestring is empty then
		return FALSE
	end if

	put rigTrim(pDatestring) into tDatestring

	put "(\s+)" into tRegEx
	put rigPregReplace(tDatestring, tRegEx, , " ") into tDatestring

	if matchText(tDatestring, "(?i)^[0-9]{2,4}\-[0-9]{1,2}\-[0-9]{1,2}\s[0-9]{1,2}:[0-9]{1,2}(?::[0-9]{1,2})?(?:\s[AP]M)?$") is FALSE then
		return FALSE
	end if

	replace space with comma in tDatestring
	replace "-" with comma in tDatestring
	replace ":" with comma in tDatestring

	repeat with i = 2 to 6
		if item i of tDatestring <> "" then
			if (the number of chars of item i of tDatestring = 2) and (char 1 of item i of tDatestring is "0") then
				delete char 1 of item i of tDatestring
			end if
		end if
	end repeat

	# CHECK IF us FORMAT IS USED
	if the last item of tDatestring is "pm" then
		put item 4 of tDatestring + 12 into tHour
		if tHour is 24 then
			put 0 into tHour
		end if
	end if

	# CHECK IF THERE ARE SECONDS
	if (the number of items of tDatestring = 5) or ((the number of items of tDatestring = 6) and (item 6 of tDatestring is not a number)) then
		put 0 into tSecs
	end if

	# GET DATE ITEMS
	put item 2 of tDatestring & "/" & item 3 of tDatestring & "/" & item 1 of tDatestring into tTempDate
	convert (tTempDate) from short date to dateItems
	put it into tDateItems
	put item 4 of tDatestring into item 4 of tDateItems
	put item 5 of tDatestring into item 5 of tDateItems
	if (item 6 of tDatestring <> "") and (item 6 of tDatestring is a number) then
		put item 6 of tDatestring into item 6 of tDateItems
	end if

	# GET SECONDS
	convert (tDateItems) from dateItems to seconds

	return it
end rigHumanToTimestamp









/*----------------------------------------------------------------------
--| FUNCTION rigTimespan
--|
--| Author: rabit
--| Version:  1.1
--| Created: 07-05-2010
--| Last Mod: 21-03-2014
--| Requires: rigLangLoadLang(), rigLangLangLine()
--|
--| Summary: Returns a span of seconds in this format:
--|            10 days 14 hours 36 minutes 47 seconds.
--| 
--| Format:  rigTimespan(param1, param2)
--|
--| Parameters: integer <pSeconds>, integer <pTime>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigTimespan pSeconds pTime
  local tSeconds, tTime, tSecs, tDatestring, tYears
  local tMonths, tWeeks, tDays, tHours, tMinutes
  
	get rigLangLoadLang("date")

	if (pSeconds is empty) or (pSeconds is not a number) then
		put 1 into tSeconds
	else
		put pSeconds into tSeconds
	end if

	if (pTime is empty) or (pTime is not a number) then
		put the seconds into tTime
	else
		put pTime into tTime
	end if


	if tTime < tSeconds then
		put 1 into tSeconds
	end if

	put tTime - tSeconds into tSecs

	put empty into tDatestring

	# YEARS
	put trunc(tSecs / 31536000) into tYears

	if tYears > 0 then
		if tYears > 1 then
			put tYears && rigLangLangLine("date_years") & ", " into tDatestring
		else
			put tYears && rigLangLangLine("date_year") & ", " into tDatestring
		end if
	end if

	put tSecs - (tYears * 31536000) into tSecs

	# MONTHS
	put trunc(tSecs / 2628000) into tMonths

	if (tYears > 0) or ( tMonths > 0) then
		if tMonths > 0 then
			if tMonths > 1 then
				put tMonths && rigLangLangLine("date_months") & ", " after tDatestring
			else
				put tMonths && rigLangLangLine("date_month") & ", " after tDatestring
			end if
		end if

		put tSecs - (tMonths * 2628000) into tSecs
	end if

	# WEEKS
	put trunc(tSecs / 604800) into tWeeks

	if (tYears > 0) or ( tMonths > 0) or (tWeeks > 0) then
		if tWeeks > 0 then
			if tWeeks > 1 then
				put tWeeks && rigLangLangLine("date_weeks") & ", " after tDatestring
			else
				put tWeeks && rigLangLangLine("date_week") & ", " after tDatestring
			end if
		end if

		put tSecs - (tWeeks * 604800) into tSecs
	end if

	# DAYS
	put trunc(tSecs / 86400) into tDays

	if (tMonths > 0) or ( tWeeks > 0) or (tDays > 0) then
		if tDays > 0 then
			if tDays > 1 then
				put tDays && rigLangLangLine("date_days") & ", " after tDatestring
			else
				put tDays && rigLangLangLine("date_day") & ", " after tDatestring
			end if
		end if

		put tSecs - (tDays * 86400) into tSecs
	end if

	# HOURS
	put trunc(tSecs / 3600) into tHours

	if (tDays > 0) or (tHours > 0) then
		if tHours > 0 then
			if tHours > 1 then
				put tHours && rigLangLangLine("date_hours") & ", " after tDatestring
			else
				put tHours && rigLangLangLine("date_hour") & ", " after tDatestring
			end if
		end if

		put tSecs - (tHours * 3600) into tSecs
	end if

	# MINUTES
	put trunc(tSecs / 60) into tMinutes

	if (tDays > 0) or (tHours > 0) or (tMinutes > 0) then
		if tMinutes > 0 then
			if tMinutes > 1 then
				put tMinutes && rigLangLangLine("date_minutes") & ", " after tDatestring
			else
				put tMinutes && rigLangLangLine("date_minute") & ", " after tDatestring
			end if
		end if

		put tSecs - (tMinutes * 60) into tSecs
	end if

	# SECONDS
	if tDatestring is "" then
		if tSecs > 1 then
			put tSecs && rigLangLangLine("date_seconds") & ", " after tDatestring
		else
			put tSecs && rigLangLangLine("date_second") & ", " after tDatestring
		end if
	end if

	return char 1 to -3 of tDatestring
end rigTimespan







/*----------------------------------------------------------------------
--| FUNCTION rigDaysInMonth
--|
--| Author: rabit
--| Version:  1.1
--| Created: 07-05-2010
--| Last Mod: 21-03-2014
--| Requires: _rigIsLeapYear()
--|
--| Summary: Takes a month/year as input and returns the number of days
--|            for the given month/year. Takes leap years into consideration.
--| 
--| Format:  rigDaysInMonth(param1, param2)
--|
--| Parameters: integer <pMonth>, integer <pYear>
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigDaysInMonth pMonth pYear
  local tMonth, tYear, tDaysInMonth
  
	if (pMonth is not a number) or (pMonth < 1) or (pMonth > 12) then
	      return 0
	   else
	      put pMonth into tMonth
	   end if

	   if (the number of chars of pYear <> 4) or (pYear is not a number) then
	      put the last item of the long date into tYear
	   else
	      put pYear into tYear
	   end if

	   if tMonth = 2 then
	      if _rigIsLeapYear(tYear) is TRUE then
	         return 29
	      end if
	   end if

	   put "31,28,31,30,31,30,31,31,30,31,30,31" into tDaysInMonth

	   return item tMonth of tDaysInMonth
end rigDaysInMonth








/*----------------------------------------------------------------------
--| FUNCTION rigTimezoneMenu
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-05-2010
--| Last Mod: 07-05-2010
--| Requires: rigTimezones()
--|
--| Summary: Generates a drop-down menu of timezones.
--| 
--| Format:  rigTimezoneMenu(param1, param2, param3)
--|
--| Parameters: string <pDefault>, string <pClass>, string <pName>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigTimezoneMenu pDefault pClass pName
  local tDefault, tName, tMenu, tTimeZonesList, tCounter
  
	get rigLangLoadLang("date")

	if pDefault is "GMT" then
		put "UTC" into tDefault
	else
		put pDefault into tDefault
	end if

	if pName is empty then
		put "timezones" into tName
	else
		put pName into tName
	end if

	put "<select name=" & quote & tName & quote into tMenu

	if pClass <> "" then
		put " class=" & quote & pClass & quote && ">" & return after tMenu
	end if

	put rigTimezones() into tTimeZonesList

	put 1 into tCounter

	repeat for each item thisItem in tTimeZonesList
		if tCounter mod 2 <> 0 then
			if tDefault is thisItem then
				put "<option value=" & quote & thisItem & quote && "selected=" & quote & "selected" & quote & ">" & rigLangLangLine(thisItem) & "</option>" & return after tMenu
			else
				put "<option value=" & quote & thisItem & quote & ">" & rigLangLangLine(thisItem) & "</option>" & return after tMenu
			end if
		end if
		add 1 to tCounter
	end repeat

	put "</select>" after tMenu

	return tMenu
end rigTimezoneMenu








/*----------------------------------------------------------------------
--| FUNCTION rigTimezones
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-05-2010
--| Last Mod: 06-05-2010
--| Requires: --
--|
--| Summary: Returns a list of timezones.  This is a helper function
--|            for various other ones in this library.
--| 
--| Format:  rigTimezones(param1)
--|
--| Parameters: string <pTimeZone>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigTimezones pTimeZone
  local tZones, tTimeZone, tCounter, tValue
  
	put "UM12,-12,UM11,-11,UM10,-10,UM95,-9.5,UM9,-9,UM8,-8,UM7,-7,UM6,-6,UM5,-5,UM45,-4.5,UM4,-4,UM35,-3.5,UM3,-3,UM2,-2,UM1,-1,UTC,0,UP1,+1,UP2,+2,UP3,+3,UP35,+3.5,UP4,+4,UP45,+4.5,UP5,+5,UP55,+5.5,UP575,+5.75,UP6,+6,UP65,+6.5,UP7,+7,UP8,+8,UP875,+8.75,UP9,+9,UP95,+9.5,UP10,+10,UP105,+10.5,UP11,+11,UP115,+11.5,UP12,+12,UP1275,+12.75,UP13,+13,UP14,+14" into tZones

	if pTimeZone is empty then
		return tZones
	end if

	if pTimeZone is "GMT" then
		put "UTC" into tTimeZone
	else
		put pTimeZone into tTimeZone
	end if

	# GET DIFFERENCE TO GREENWICH TIME
	put 1 into tCounter
	repeat for each item thisItem in tZones
		if tTimeZone is thisItem then
			put item (tCounter + 1) of tZones into tValue
			return tValue
		else
			add 1 to tCounter
		end if
	end repeat

	return 0
end rigTimezones










--| END OF dateHelper.livecodescript
--| Location:  ./system/helpers/dateHelper.livecodescript
----------------------------------------------------------------------