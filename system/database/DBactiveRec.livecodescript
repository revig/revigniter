script "DBactiveRec"

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
# Active Record Library
#
# This is the platform-independent base Active Record implementation library.
#
# @package		revIgniter
# @subpackage	Drivers
# @category	  Database
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/database/
##




global gRigA

local sActiveRecord, sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-17
 --| Last Mod: --
 --| Requires: _rigSetDefaultValues
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
  put "" into sActiveRecord["select"]
  put FALSE into sActiveRecord["distinct"]
  put "" into sActiveRecord["from"]
  put "" into sActiveRecord["join"]
  put "" into sActiveRecord["where"]
  put "" into sActiveRecord["like"]
  put "" into sActiveRecord["groupby"]
  put "" into sActiveRecord["having"]
  put FALSE into sActiveRecord["limit"]
  put FALSE into sActiveRecord["offset"]
  put FALSE into sActiveRecord["order"]
  put "" into sActiveRecord["orderby"]
  put "" into sActiveRecord["set"]
  put "" into sActiveRecord["wherein"]
  put "" into sActiveRecord["aliasedtables"]
  put "" into sActiveRecord["storearray"]

  # ACTIVE RECORD CACHING VARIABLES
  put FALSE into sActiveRecord["caching"]
  put "" into sActiveRecord["cacheexists"]
  put "" into sActiveRecord["cacheselect"]
  put "" into sActiveRecord["cachefrom"]
  put "" into sActiveRecord["cachejoin"]
  put "" into sActiveRecord["cachewhere"]
  put "" into sActiveRecord["cachelike"]
  put "" into sActiveRecord["cachegroupby"]
  put "" into sActiveRecord["cachehaving"]
  put "" into sActiveRecord["cacheorderby"]
  put "" into sActiveRecord["cacheset"]
end _rigSetDefaultValues







/*----------------------------------------------------------------------
--| COMMAND rigDbSelect
--|
--| Author: rabit
--| Version:  1.1
--| Created: 23-09-09
--| Last Mod: 17-12-14
--| Requires: rigSetDBdriverSetting, rigTrim()
--|
--| Summary: Generates the SELECT portion of the query.
--|
--| Format:  rigDbSelect param1, param2
--|
--| Parameters: mixed <pSelect>, bool <pEscape> should field or table names be protected with backticks
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbSelect pSelect pEscape
  local tSelect, tKey, tIncr, tVal, tSelectsNum, tNewSelectsNum
  local tCacheSelectsNum, tNewCacheSelectsNum, tCacheExistsNum
  local tNewCacheExistsNum

	if pSelect is empty then
		put "*" into tSelect
	else
		put pSelect into tSelect
	end if

	# SET THE GLOBAL VALUE IF THIS WAS SEPECIFIED
	if pEscape is a boolean then
		rigSetDBdriverSetting "protectIdentifiers", pEscape
	end if

	if tSelect is not an array then
		split tSelect using comma
	end if

	put 0 into tIncr
	repeat for each key tKey in tSelect
		add 1 to tIncr
		put tSelect[tIncr] into tVal

		put rigTrim(tVal) into tVal

		if tVal is not empty then
			put the number of lines in the keys of sActiveRecord["select"] into tSelectsNum
			put tSelectsNum + 1 into tNewSelectsNum
			put tVal into sActiveRecord["select"][tNewSelectsNum]

			if sActiveRecord["caching"] is TRUE then
				put the number of lines in the keys of sActiveRecord["cacheselect"] into tCacheSelectsNum
				put tCacheSelectsNum + 1 into tNewCacheSelectsNum
				put tVal into sActiveRecord["cacheselect"][tNewCacheSelectsNum]

				put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
				put tCacheExistsNum + 1 into tNewCacheExistsNum
				put "select" into sActiveRecord["cacheexists"][tNewCacheExistsNum]
			end if
		end if
	end repeat
end rigDbSelect








/*----------------------------------------------------------------------
--| COMMAND rigSelectMax
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-09-09
--| Last Mod: 24-09-09
--| Requires: _rigMaxMinAvgSum
--|
--| Summary: Generates a SELECT MAX(field) portion of a query.
--|
--| Format:  rigSelectMax param1, param2
--|
--| Parameters: string<pSelect> the field, string<pAlias> an alias
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSelectMax pSelect pAlias
	_rigMaxMinAvgSum pSelect, pAlias, "MAX"
end rigSelectMax







/*----------------------------------------------------------------------
--| COMMAND rigSelectMin
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-09-09
--| Last Mod: 24-09-09
--| Requires: _rigMaxMinAvgSum
--|
--| Summary: Generates a SELECT MIN(field) portion of a query.
--|
--| Format:  rigSelectMin param1, param2
--|
--| Parameters: string<pSelect> the field, string<pAlias> an alias
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSelectMin pSelect pAlias
	_rigMaxMinAvgSum pSelect, pAlias, "MIN"
end rigSelectMin







/*----------------------------------------------------------------------
--| COMMAND rigSelectAvg
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-09-09
--| Last Mod: 24-09-09
--| Requires: _rigMaxMinAvgSum
--|
--| Summary: Generates a SELECT AVG(field) portion of a query.
--|
--| Format:  rigSelectAvg param1, param2
--|
--| Parameters: string<pSelect> the field, string<pAlias> an alias
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSelectAvg pSelect pAlias
	_rigMaxMinAvgSum pSelect, pAlias, "AVG"
end rigSelectAvg








/*----------------------------------------------------------------------
--| COMMAND rigSelectSum
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-09-09
--| Last Mod: 24-09-09
--| Requires: _rigMaxMinAvgSum
--|
--| Summary: Generates a SELECT SUM(field) portion of a query.
--|
--| Format:  rigSelectSum param1, param2
--|
--| Parameters: string<pSelect> the field, string<pAlias> an alias
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSelectSum pSelect pAlias
	_rigMaxMinAvgSum pSelect, pAlias, "SUM"
end rigSelectSum







/*----------------------------------------------------------------------
--| COMMAND _rigMaxMinAvgSum
--|
--| Author: rabit
--| Version:  1.0
--| Created: 23-09-09
--| Last Mod: 23-09-09
--| Requires: rigDbDisplayError, rigShowError, rigTrim(), _rigCreateAliasFromTable(), _rigProtectIdentifiers()
--|
--| Summary: Processing command for the four commands above:
--|
--|                    rigSelectMax
--|                    rigSelectMin
--|                    rigSelectAvg
--|                    rigSelectSum
--|
--| Format:  _rigMaxMinAvgSum param1, param2, param3
--|
--| Parameters: string<pSelect> the field, string<pAlias> an alias, string <pType>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigMaxMinAvgSum pSelect pAlias pType
  local tSelect, tAlias, tType, tTempStr, tSQL, tSelectsNum, tNewSelectsNum
  local tCacheSelectsNum, tNewCacheSelectsNum, tCacheExistsNum
  local tNewCacheExistsNum

	put pSelect into tSelect
	put pAlias into tAlias
	if pType is empty then
		put "MAX" into tType
	else
		put pType into tType
	end if

	if (isNumber(tSelect) is TRUE) or (tSelect is a boolean) or (tSelect is an array) or (tSelect is empty) then
		rigDbDisplayError "db_invalid_query"
	end if

	put toUpper(tType) into tType

	put "MAX,MIN,AVG,SUM" into tTempStr
	if tType is not among the items of tTempStr then
		rigShowError "Invalid function type:" && tType
	end if

	if tAlias is empty then
		put rigTrim(tSelect) into tSelect
		put _rigCreateAliasFromTable(tSelect) into tAlias
	end if

	put tType & "(" & _rigProtectIdentifiers(tSelect) & ") AS" && tAlias into tSQL

	put the number of lines in the keys of sActiveRecord["select"] into tSelectsNum
	put tSelectsNum + 1 into tNewSelectsNum
	put tSQL into sActiveRecord["select"][tNewSelectsNum]

	if sActiveRecord["caching"] is TRUE then
		put the number of lines in the keys of sActiveRecord["cacheselect"] into tCacheSelectsNum
		put tCacheSelectsNum + 1 into tNewCacheSelectsNum
		put tSQL into sActiveRecord["cacheselect"][tNewCacheSelectsNum]

		put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
		put tCacheExistsNum + 1 into tNewCacheExistsNum
		put "select" into sActiveRecord["cacheexists"][tNewCacheExistsNum]
	end if
end _rigMaxMinAvgSum




/*----------------------------------------------------------------------
--| FUNCTION _rigCreateAliasFromTable
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-09-09
--| Last Mod: 24-09-09
--| Requires: --
--|
--| Summary: Determines the alias name based on the table.
--|
--| Format:  _rigCreateAliasFromTable(param1)
--|
--| Parameters: string<pItem>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCreateAliasFromTable pItem
	if "." is in pItem then
		set the itemdelimiter to "."
		return item -1 of pItem
	end if

		return pItem
end _rigCreateAliasFromTable





/*----------------------------------------------------------------------
--| COMMAND rigDbDistinct
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-09-09
--| Last Mod: 24-09-09
--| Requires: --
--|
--| Summary: Sets a flag which tells the query string compiler to add DISTINCT.
--|
--| Format:  rigDbDistinct param1
--|
--| Parameters: string<pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbDistinct pVal
  local tVal

	if pVal is empty then
		put TRUE into tVal
	else
		put pVal into tVal
	end if

	if tVal is a boolean then
		put tVal into sActiveRecord["distinct"]
	else
		put TRUE into sActiveRecord["distinct"]
	end if
end rigDbDistinct








/*----------------------------------------------------------------------
--| COMMAND rigDbFrom
--|
--| Author: rabit
--| Version:  1.2
--| Created: 07-07-09
--| Last Mod: 27-01-10
--| Requires: _rigTrackAliases(),  _rigProtectIdentifiers(), rigTrim()
--|
--| Summary: Generates the FROM portion of the query.
--|
--| Format:  rigDbFrom param1
--|
--| Parameters: mixed <pFrom> can be a string or array
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbFrom pFrom
  local tFrom, tFromKeyNum, tCachedFromKeyNum, tKey, tVal, tV, tTempFrom

	if pFrom is not an array then
		put pFrom into tFrom[1]
	else
		put pFrom into tFrom
	end if

	if sActiveRecord["from"] is an array then
		put the number of lines in the keys of sActiveRecord["from"] into tFromKeyNum
	else
		put 0 into tFromKeyNum
	end if

	if sActiveRecord["caching"] is TRUE then
		if sActiveRecord["cachefrom"] is an array then
			put the number of lines in the keys of sActiveRecord["cachefrom"] into tCachedFromKeyNum
		else
			put 0 into tCachedFromKeyNum
		end if
	end if

	repeat for each key tKey in tFrom
		put tFrom[tKey] into tVal
		if comma is in tVal then
			split tVal using comma

			repeat for each key tValKey in tVal
				put tVal[tValKey] into tV

				# Trim WHITESPACE
				-- put replacetext(tV,"(^\s+)|(\s+$)",empty) into tV
				put rigTrim(tV) into tV
				get _rigTrackAliases(tV)

				put _rigProtectIdentifiers(tV, TRUE, "", FALSE) into tTempFrom
				add 1 to tFromKeyNum
				put tTempFrom into sActiveRecord["from"][tFromKeyNum]

				if sActiveRecord["caching"] is TRUE then
					add 1 to tCachedFromKeyNum
					put tTempFrom into sActiveRecord["cachefrom"][tCachedFromKeyNum]
					put "from" into sActiveRecord["cacheexists"][tCachedFromKeyNum]
				end if
			end repeat

		else
			# Trim WHITESPACE
			-- put replacetext(tVal,"(^\s+)|(\s+$)",empty) into tVal
			put rigTrim(tVal) into tVal

			# EXTRACT ANY ALIASES THAT MIGHT EXIST.  WE USE THIS INFORMATION
			# IN THE _rigProtectIdentifiers TO KNOW WHETHER TO ADD A TABLE PREFIX
			get _rigTrackAliases(tVal)

			put _rigProtectIdentifiers(tVal, TRUE, "", FALSE) into tTempFrom
			add 1 to tFromKeyNum
			put tTempFrom into sActiveRecord["from"][tFromKeyNum]

			if sActiveRecord["caching"] is TRUE then
				add 1 to tCachedFromKeyNum
				put tTempFrom into sActiveRecord["cachefrom"][tCachedFromKeyNum]
				put "from" into sActiveRecord["cacheexists"][tCachedFromKeyNum]
			end if

		end if
	end repeat

end rigDbFrom








/*----------------------------------------------------------------------
--| COMMAND rigDbJoin
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2009-09-24
--| Last Mod: 2017-06-27
--| Requires: rigTrim(), _rigTrackAliases(), _rigProtectIdentifiers(),
--|            _rigDbJoinConditionsArray(), _rigEscapeIdentifiers()
--|
--| Summary: Generates the JOIN portion of the query.
--|
--| Format:  rigDbJoin param1, param2[, param3][, param4]
--|
--| Parameters: string<pTable>, string <pCond>the join condition,
--|               string <pType> the type of join (optional), bool <pEscape> (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbJoin pTable pCond pType pEscape
  local tCond, tType, tEscape, tRegEx, tMatch1, tMatch2, tMatch3, tCondA
  local tCounter, tNewCond, tTable, tJoin, tJoinsNum, tNewJoinsNum
  local tCacheJoinsNum, tNewCacheJoinsNum, tCacheExistsNum, tNewCacheExistsNum

  put pCond into tCond
  put pType into tType

  if tType is not empty then
    put rigTrim(tType) into tType
    put toUpper(tType) into tType
    if tType is not among the items of "LEFT,RIGHT,OUTER,INNER,LEFT OUTER,RIGHT OUTER" then
      put empty into tType
    else
      put space after tType
    end if
  end if

  # EXTRACT ANY ALIASES THAT MIGHT EXIST.  WE USE THIS INFORMATION
  # IN THE _rigProtectIdentifiers FUNCTION TO KNOW WHETHER TO ADD A TABLE PREFIX
  get _rigTrackAliases(pTable)

  # IF THE ESCAPE VALUE WAS NOT SET WE WILL BASE IT ON THE GLOBAL SETTING
  if pEscape is not a boolean then
    put rigFetchDBdriverSetting("protectIdentifiers") into tEscape
  else
    put pEscape into tEscape
  end if

  # SPLIT MULTIPLE CONDITIONS
  # REGEX TO CHECK FOR MULTIPLE CONDITIONS
  put "(?i)(\sAND\s|\sOR\s)" into tRegEx
  get matchText(tCond,tRegEx)
  # REGEX TO STRIP APART SINGLE CONDITIONS
  put "([\[\]\w\.'-]+)(\s*[^\" & quote & "\[`'\w]+\s*)(.+)" into tRegEx

 	put empty into tMatch1 -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
 	put empty into tMatch2
 	put empty into tMatch3
  if (it is true) and (tEscape is true) then
    # STORE MULTIPLE CONDITIONS IN AN ARRAY
    put _rigDbJoinConditionsArray(tCond) into tCondA

    put 0 into tCounter
    repeat the number of lines in the keys of tCondA
      add 1 to tCounter
      if tCondA[tCounter]["op"] <> empty then
        if matchText(tCondA[tCounter]["cond"],tRegEx,tMatch1, tMatch2, tMatch3) is true then
          put _rigProtectIdentifiers(tMatch1) into tMatch1
          put _rigProtectIdentifiers(tMatch3) into tMatch3

          put tMatch1 & tMatch2 & tMatch3 && tCondA[tCounter]["op"] & " " after tNewCond
        else
          put tCondA[tCounter]["cond"] && tCondA[tCounter]["op"] & " " after tNewCond
        end if

      else
        if matchText(tCondA[tCounter]["cond"],tRegEx,tMatch1, tMatch2, tMatch3) is true then
          put _rigProtectIdentifiers(tMatch1) into tMatch1
          put _rigProtectIdentifiers(tMatch3) into tMatch3

          put tMatch1 & tMatch2 & tMatch3 after tNewCond
        else
          put tCondA[tCounter]["cond"] after tNewCond
        end if

      end if
    end repeat

    put "ON" && tNewCond into tCond

  # SINGLE CONDITION
  # STRIP APART THE CONDITION AND PROTECT THE IDENTIFIERS
  else if (matchText(tCond,tRegEx,tMatch1, tMatch2, tMatch3) is true) and (tEscape is true) then
    put _rigProtectIdentifiers(tMatch1) into tMatch1
    put _rigProtectIdentifiers(tMatch3) into tMatch3

    put "ON" && tMatch1 & tMatch2 & tMatch3 into tCond

    # MISSING OPERATOR, USE USING CLAUSE
  else if _rigHasOperator(tCond) is false then
    if tEscape is true then
      put _rigEscapeIdentifiers(tCond) into tCond
    end if
      put "USING (" & tCond & ")" into tCond

  else
    put "ON" && tCond into tCond
  end if

  # DO WE WANT TO ESCAPE THE TABLE NAME?
  if tEscape is true then
    put _rigProtectIdentifiers(pTable, TRUE, "", FALSE) into tTable
  else
    put pTable into tTable
  end if

  # ASSEMBLE THE JOIN STATEMENT
  put tType & "JOIN" && tTable && tCond into tJoin

  put the number of lines in the keys of sActiveRecord["join"] into tJoinsNum
  put tJoinsNum + 1 into tNewJoinsNum
  put tJoin into sActiveRecord["join"][tNewJoinsNum]

  if sActiveRecord["caching"] is TRUE then
    put the number of lines in the keys of sActiveRecord["cachejoin"] into tCacheJoinsNum
    put tCacheJoinsNum + 1 into tNewCacheJoinsNum
    put tJoin into sActiveRecord["cachejoin"][tNewCacheJoinsNum]

    put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
    put tCacheExistsNum + 1 into tNewCacheExistsNum
    put "join" into sActiveRecord["cacheexists"][tNewCacheExistsNum]
  end if
end rigDbJoin








/*----------------------------------------------------------------------
--| COMMAND rigDbWhere
--|
--| Author: rabit
--| Version:  1.1
--| Created: 25-09-09
--| Last Mod: 12-11-15
--| Requires: _rigWhere
--|
--| Summary: Generates the WHERE portion of the query. Separates multiple calls with AND.
--|            Set the third parameter to FALSE with manually written where clauses.
--|
--| Format:  rigDbWhere param1, param2, param3
--|
--| Parameters: mixed<pKey>, mixed <pValue>, bool <pEscape>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbWhere pKey pValue pEscape
  local tValue, tEscape

	if pValue is empty then
		put NULL into tValue
	else
		put pValue into tValue
	end if

  # CHECK IF WE ARE DEALING WITH A SUBQUERY
  # IF SO SET THE ESCAPE PARAMETER TO FALSE
  if word 1 of pValue is among the items of "(SELECT,(INSERT,(UPDATE,(DELETE" then
    put FALSE into tEscape
  else
	  if pEscape is empty then
		  put TRUE into tEscape
	  else
		  put pEscape into tEscape
	  end if
  end if

	_rigWhere pKey, tValue, "AND ", tEscape
end rigDbWhere








/*----------------------------------------------------------------------
--| COMMAND rigDbOrWhere
--|
--| Author: rabit
--| Version:  1.0
--| Created: 25-09-09
--| Last Mod: 25-09-09
--| Requires: _rigWhere
--|
--| Summary: Generates the WHERE portion of the query. Separates
--|                    multiple calls with OR.
--|
--| Format:  rigDbOrWhere param1, param2, param3
--|
--| Parameters: mixed<pKey>, mixed <pValue>, bool <pEscape>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOrWhere pKey pValue pEscape
  local tValue, tEscape

	if pValue is empty then
		put NULL into tValue
	else
		put pValue into tValue
	end if

	if pEscape is empty then
		put TRUE into tEscape
	else
		put pEscape into tEscape
	end if

	_rigWhere pKey, tValue, "Or ", tEscape
end rigDbOrWhere









/*----------------------------------------------------------------------
--| COMMAND _rigWhere
--|
--| Author: rabit
--| Version:  1.3
--| Created: 25-09-09
--| Last Mod: 04-11-12
--| Requires: rigFetchDBdriverSetting(), _rigProtectIdentifiers(), _rigHasOperator(), rigDbEscape()
--|
--| Summary: Generates the WHERE portion of the query. Separates
--|          multiple calls with OR. Set the third parameter to FALSE with
--|          manually wrtitten where clauses.
--|
--| Format:  _rigWhere param1, param2, param3
--|
--| Parameters: mixed<pKey>, mixed <pValue>, string <pType>, bool <pEscape>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigWhere pKey pValue pType pEscape
  local tKey, tValue, tType, tTemp, tEscape, tK, tV, tPrefix, tWheresNum
  local tNewWheresNum, tLikesNum, tCacheWheresNum, tNewCacheWheresNum
  local tCacheExistsNum, tNewCacheExistsNum

	put pKey into tKey

	if pValue is empty then
		put NULL into tValue
	else
		put pValue into tValue
	end if

	if pType is empty then
		put "AND " into tType
	else
		put pType into tType
	end if

	if tKey is not an array then
		put tKey into tTemp
		put empty into tKey
		put tValue into tKey[tTemp]
		--put tValue into tKey[tKey]
	end if

	# IF THE ESCAPE VALUE WAS NOT SET WE WILL BASE IT ON THE GLOBAL SETTING
	if pEscape is not a boolean then
		put rigFetchDBdriverSetting("protectIdentifiers") into tEscape
	else
		put pEscape into tEscape
	end if

	repeat for each key tK in tKey
		put tKey[tK] into tV

		if (the number of lines in the keys of sActiveRecord["where"] = 0) and (the number of lines in the keys of sActiveRecord["cachewhere"] = 0) then
			put empty into tPrefix
		else
			put tType into tPrefix
		end if

		if (tV is NULL) and (_rigHasOperator(tK) is FALSE)  then
			# VALUE APPEARS NOT TO HAVE BEEN SET, ASSIGN THE TEST TO IS NULL
			put " IS NULL" after tK
		end if

		if tV is not NULL then
			if tEscape is TRUE then
				put _rigProtectIdentifiers(tK, FALSE, tEscape) into tK
				put " " & rigDbEscape(tV) into tV
			end if

			if _rigHasOperator(tK) is FALSE then
				put " =" after tK
			end if
		else
			put _rigProtectIdentifiers(tK, FALSE, tEscape) into tK
		end if

		put the number of lines in the keys of sActiveRecord["where"] into tWheresNum
		put tWheresNum + 1 into tNewWheresNum

		# SET PARENTHESES
		#
		# CHECK IF AN OPEN PARENTHESIS SHOULD BE WRITTEN AND IF THERE IS CURRENTLY NO OPEN PARENTHESIS WHICH NEEDS TO BE CLOSED
		if (sActiveRecord["openParenthesis"] is "(") and (sActiveRecord["closeParenthesisWhere"] <> ")") then
			put tPrefix & "(" & tK & tV  into sActiveRecord["where"][tNewWheresNum]
			put empty into sActiveRecord["openParenthesis"]
			put "Where" into sActiveRecord["openParenthesisSet"]

		# IF THERE IS AN OPEN PARENTHESIS WHICH NEEDS TO BE CLOSED ADD A CLOSE PARENTHESIS BEFORE ADDING AN OPEN PARENTHESIS
		else if (sActiveRecord["openParenthesis"] is "(") and (sActiveRecord["closeParenthesisWhere"] is ")") then
			put ")" && tPrefix & "(" & tK & tV  into sActiveRecord["where"][tNewWheresNum]
			put empty into sActiveRecord["openParenthesis"]
			put empty into sActiveRecord["closeParenthesisWhere"]
			put "Where" into sActiveRecord["openParenthesisSet"]
			put "Where" into sActiveRecord["closeParenthesisSet"]

		# CHECK IF A CLOSE PARENTHESIS SHOULD BE ADDED
		else if sActiveRecord["closeParenthesisWhere"] is ")" then
			put ")" && tPrefix & tK & tV  into sActiveRecord["where"][tNewWheresNum]
			put empty into sActiveRecord["closeParenthesisWhere"]
			put "Where" into sActiveRecord["closeParenthesisSet"]

		# IF THERE IS AN OPEN PARENTHESIS SET IN FRONT OF A LIKE CLAUSE MOVE IT TO THE WHERE CLAUSE AS THE WHERE PORTION
		# IS WRITTEN BEFORE THE LIKE PORTION WHEN THE SELECT QUERY IS BUILT
		else if (sActiveRecord["openParenthesisSet"] is "Like") and (sActiveRecord["closeParenthesisSet"] is empty) \
			and (sActiveRecord["closeParenthesisLike"] <> ")") then

			# REPLACE THE OPEN PARENTHESIS WITH EMPTY
			put the number of lines in the keys of sActiveRecord["like"] into tLikesNum
			repeat with tCurrentLikesNum = tLikesNum down to 1
				if "(" is in sActiveRecord["like"][tCurrentLikesNum] then
					replace "(" with "" in sActiveRecord["like"][tCurrentLikesNum]
					exit repeat
				end if
			end repeat

			# ADD THE OPEN PARENTHESIS TO THE CURRENT WHERE CLAUSE
			put tPrefix & "(" & tK & tV  into sActiveRecord["where"][tNewWheresNum]
			put "LikeToWhere" into sActiveRecord["openParenthesisSet"]

		else
			# DO NOT ADD PARENTHESES
			put tPrefix & tK & tV  into sActiveRecord["where"][tNewWheresNum]
		end if
		# # #

		if sActiveRecord["caching"] is TRUE then
			put the number of lines in the keys of sActiveRecord["cachewhere"] into tCacheWheresNum
			put tCacheWheresNum + 1 into tNewCacheWheresNum
			put sActiveRecord["where"][tNewWheresNum] into sActiveRecord["cachewhere"][tNewCacheWheresNum]

			put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
			put tCacheExistsNum + 1 into tNewCacheExistsNum
			put "where" into sActiveRecord["cacheexists"][tNewCacheExistsNum]
		end if
	end repeat

	# THIS IS USED FOR PARENTHESES
	put "Where" into sActiveRecord["currentClause"]
end _rigWhere





/*----------------------------------------------------------------------
--| COMMAND rigDbWhereIn
--|
--| Author: rabit
--| Version:  1.1
--| Created: 25-09-09
--| Last Mod: 29-12-09
--| Requires: _rigWhereIn
--|
--| Summary: Generates a WHERE field IN ('item', 'item') SQL query joined with
--|                    AND if appropriate.
--|
--| Format:  rigDbWhereIn param1, param2
--|
--| Parameters: string<pKey> the field to search, array <pValues> the values searched on
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbWhereIn pKey pValues
  local tKey, tValues

	if pKey is empty then
		put NULL into tKey
	else
		put pKey into tKey
	end if

	if (pValues is not an array) and (pValues is empty) then
		put NULL into tValues
	else
		put pValues into tValues
	end if

	_rigWhereIn tKey, tValues
end rigDbWhereIn









/*----------------------------------------------------------------------
--| COMMAND rigDbOrWhereIn
--|
--| Author: rabit
--| Version:  1.1
--| Created: 25-09-09
--| Last Mod: 29-12-09
--| Requires: _rigWhereIn
--|
--| Summary: Generates a WHERE field IN ('item', 'item') SQL query joined with
--|                    OR if appropriate.
--|
--| Format:  rigDbOrWhereIn param1, param2
--|
--| Parameters: string<pKey> the field to search, array <pValues> the values searched on
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOrWhereIn pKey pValues
  local tKey, tValues

	if pKey is empty then
		put NULL into tKey
	else
		put pKey into tKey
	end if

	if (pValues is not an array) and (pValues is empty) then
		put NULL into tValues
	else
		put pValues into tValues
	end if

	_rigWhereIn tKey, tValues, FALSE, "OR "
end rigDbOrWhereIn









/*----------------------------------------------------------------------
--| COMMAND rigDbWhereNotIn
--|
--| Author: rabit
--| Version:  1.1
--| Created: 25-09-09
--| Last Mod: 29-12-09
--| Requires: _rigWhereIn
--|
--| Summary: Generates a WHERE field NOT IN ('item', 'item') SQL query joined with
--|                    AND if appropriate.
--|
--| Format:  rigDbWhereNotIn param1, param2
--|
--| Parameters: string<pKey> the field to search, array <pValues> the values searched on
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbWhereNotIn pKey pValues
  local tKey, tValues

	if pKey is empty then
		put NULL into tKey
	else
		put pKey into tKey
	end if

	if (pValues is not an array) and (pValues is empty) then
		put NULL into tValues
	else
		put pValues into tValues
	end if

	_rigWhereIn tKey, tValues, TRUE
end rigDbWhereNotIn








/*----------------------------------------------------------------------
--| COMMAND rigDbOrWhereNotIn
--|
--| Author: rabit
--| Version:  1.2
--| Created: 25-09-09
--| Last Mod: 29-12-09
--| Requires: _rigWhereIn
--|
--| Summary: Generates a WHERE field NOT IN ('item', 'item') SQL query joined with
--|                    OR if appropriate.
--|
--| Format:  rigDbOrWhereNotIn param1, param2
--|
--| Parameters: string<pKey> the field to search, array <pValues> the values searched on
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOrWhereNotIn pKey pValues
  local tKey, tValues

	if pKey is empty then
		put NULL into tKey
	else
		put pKey into tKey
	end if

	if (pValues is not an array) and (pValues is empty) then
		put NULL into tValues
	else
		put pValues into tValues
	end if

	_rigWhereIn tKey, tValues, TRUE, "OR "
end rigDbOrWhereNotIn








/*----------------------------------------------------------------------
--| COMMAND _rigWhereIn
--|
--| Author: rabit
--| Version:  1.2
--| Created: 25-09-09
--| Last Mod: 04-11-12
--| Requires: rigDbEscape(), _rigProtectIdentifiers()
--|
--| Summary: Called by rigDbWhereIn, rigDbWhereInOr, rigDbWhereNotIn, rigDbOrWhereNotIn.
--|
--| Format:  _rigWhereIn param1, param2
--|
--| Parameters: string <pKey> the field to search, array <pValue> the values searched on,
--|                        bool <pNot> if the statement would be IN or NOT IN, string <pType>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigWhereIn pKey pValues pNot pType
  local tKey, tValues, tNot, tType, tWhereInsNum, tK, tVal, tPrefix, tWhereIn
  local tLikesNum, tWheresNum, tCacheWheresNum, tCacheExistsNum

	if pKey is empty then
		put NULL into tKey
	else
		put pKey into tKey
	end if

	if (pValues is not an array) and (pValues is empty) then
		put NULL into tValues
	else
		put pValues into tValues
	end if

	if pNot is empty then
		put FALSE into tNot
	else
		put pNot into tNot
	end if

	if pType is empty then
		put "AND " into tType
	else
		put pType into tType
	end if

	if (tKey is NULL) or (tValues is NULL) then
		exit _rigWhereIn
	end if

	if tValues is not an array then
		put tValues into tValues[1]
	end if

	if tNot is TRUE then
		put " NOT" into tNot
	else
		put "" into tNot
	end if

	put the number of lines in the keys of sActiveRecord["wherein"] into tWhereInsNum
	repeat for each key tK in tValues
		add 1 to tWhereInsNum
		put tValues[tK] into tVal
		put rigDbEscape(tVal) into sActiveRecord["wherein"][tWhereInsNum]
	end repeat

	if the number of lines in the keys of sActiveRecord["where"] is 0 then
		put "" into tPrefix
	else
		put tType into tPrefix
	end if

	combine sActiveRecord["wherein"] using ","
  replace "," with ", " in sActiveRecord["wherein"]

	# SET PARENTHESES
	#
	# CHECK IF AN OPEN PARENTHESIS SHOULD BE WRITTEN AND IF THERE IS CURRENTLY NO OPEN PARENTHESIS WHICH NEEDS TO BE CLOSED
	if (sActiveRecord["openParenthesis"] is "(") and (sActiveRecord["closeParenthesisWhere"] <> ")") then
		put tPrefix & "(" & _rigProtectIdentifiers(tKey) & tNot && "IN (" & sActiveRecord["wherein"] & ") " into tWhereIn
		put empty into sActiveRecord["openParenthesis"]
		put "Where" into sActiveRecord["openParenthesisSet"]

	# IF THERE IS AN OPEN PARENTHESIS WHICH NEEDS TO BE CLOSED ADD A CLOSE PARENTHESIS BEFORE ADDING AN OPEN PARENTHESIS
	else if (sActiveRecord["openParenthesis"] is "(") and (sActiveRecord["closeParenthesisWhere"] is ")") then
		put ")" && tPrefix & "(" & _rigProtectIdentifiers(tKey) & tNot && "IN (" & sActiveRecord["wherein"] & ") " into tWhereIn
		put empty into sActiveRecord["openParenthesis"]
		put empty into sActiveRecord["closeParenthesisWhere"]
		put "Where" into sActiveRecord["openParenthesisSet"]
		put "Where" into sActiveRecord["closeParenthesisSet"]

	# CHECK IF A CLOSE PARENTHESIS SHOULD BE ADDED
	else if sActiveRecord["closeParenthesisWhere"] is ")" then
		put ")" && tPrefix & _rigProtectIdentifiers(tKey) & tNot && "IN (" & sActiveRecord["wherein"] & ") " into tWhereIn
		put empty into sActiveRecord["closeParenthesisWhere"]
		put "Where" into sActiveRecord["closeParenthesisSet"]

	# IF THERE IS AN OPEN PARENTHESIS SET IN FRONT OF A LIKE CLAUSE MOVE IT TO THE WHERE CLAUSE AS THE WHERE PORTION
	# IS WRITTEN BEFORE THE LIKE PORTION WHEN THE SELECT QUERY IS BUILT
	else if (sActiveRecord["openParenthesisSet"] is "Like") and (sActiveRecord["closeParenthesisSet"] is empty) \
		and (sActiveRecord["closeParenthesisLike"] <> ")") then

	# REPLACE THE OPEN PARENTHESIS WITH EMPTY
		put the number of lines in the keys of sActiveRecord["like"] into tLikesNum
		repeat with tCurrentLikesNum = tLikesNum down to 1
			if "(" is in sActiveRecord["like"][tCurrentLikesNum] then
				replace "(" with "" in sActiveRecord["like"][tCurrentLikesNum]
				exit repeat
			end if
		end repeat

		# ADD THE OPEN PARENTHESIS TO THE CURRENT WHERE CLAUSE
		put tPrefix & "(" & _rigProtectIdentifiers(tKey) & tNot && "IN (" & sActiveRecord["wherein"] & ") " into tWhereIn
		put "LikeToWhere" into sActiveRecord["openParenthesisSet"]

	else
		# DO NOT ADD PARENTHESES
		put tPrefix & _rigProtectIdentifiers(tKey) & tNot && "IN (" & sActiveRecord["wherein"] & ") " into tWhereIn
	end if
	# # #

	put the number of lines in the keys of sActiveRecord["where"] into tWheresNum
	add 1 to tWheresNum
	put tWhereIn into sActiveRecord["where"][tWheresNum]

	if sActiveRecord["caching"] is TRUE then
		put the number of lines in the keys of sActiveRecord["cachewhere"] into tCacheWheresNum
		add 1 to  tCacheWheresNum
		put tWhereIn into sActiveRecord["cachewhere"][tCacheWheresNum]

		put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
		add 1 to tCacheExistsNum
		put "where" into sActiveRecord["cacheexists"][tCacheExistsNum]
	end if

	# RESET THE ARRAY FOR MULTIPLE CALLS
	put empty into sActiveRecord["wherein"]

	# THIS IS USED FOR PARENTHESES
	put "Where" into sActiveRecord["currentClause"]
end _rigWhereIn





/*----------------------------------------------------------------------
--| COMMAND rigDbLike
--|
--| Author: rabit
--| Version:  1.0
--| Created: 26-09-09
--| Last Mod: 26-09-09
--| Requires: _rigLike
--|
--| Summary: Generates a %LIKE% portion of the query. Separates
--|                    multiple calls with AND.
--|
--| Format:  rigDbLike param1, param2, param3
--|
--| Parameters: mixed<pField>, mixed <pMatch>, string <pSide>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbLike pField pMatch pSide
  local tSide

	if pSide is empty then
		put "both" into tSide
	else
		put pSide into tSide
	end if

	_rigLike pField, pMatch, "AND ", tSide
end rigDbLike








/*----------------------------------------------------------------------
--| COMMAND rigDbNotLike
--|
--| Author: rabit
--| Version:  1.0
--| Created: 26-09-09
--| Last Mod: 26-09-09
--| Requires: _rigLike
--|
--| Summary: Generates a NOT LIKE portion of the query. Separates
--|                    multiple calls with AND.
--|
--| Format:  rigDbNotLike param1, param2, param3
--|
--| Parameters: mixed<pField>, mixed <pMatch>, string <pSide>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbNotLike pField pMatch pSide
  local tSide

	if pSide is empty then
		put "both" into tSide
	else
		put pSide into tSide
	end if

	_rigLike pField, pMatch, "AND ", tSide, "NOT"
end rigDbNotLike








/*----------------------------------------------------------------------
--| COMMAND rigDbOrLike
--|
--| Author: rabit
--| Version:  1.0
--| Created: 26-09-09
--| Last Mod: 26-09-09
--| Requires: _rigLike
--|
--| Summary: Generates a %LIKE% portion of the query. Separates
--|                    multiple calls with OR.
--|
--| Format:  rigDbOrLike param1, param2, param3
--|
--| Parameters: mixed<pField>, mixed <pMatch>, string <pSide>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOrLike pField pMatch pSide
  local tSide

	if pSide is empty then
		put "both" into tSide
	else
		put pSide into tSide
	end if

	_rigLike pField, pMatch, "OR ", tSide
end rigDbOrLike








/*----------------------------------------------------------------------
--| COMMAND rigDbOrNotLike
--|
--| Author: rabit
--| Version:  1.0
--| Created: 26-09-09
--| Last Mod: 26-09-09
--| Requires: _rigLike
--|
--| Summary: Generates a NOT LIKE portion of the query. Separates
--|                    multiple calls with OR.
--|
--| Format:  rigDbOrNotLike param1, param2, param3
--|
--| Parameters: mixed<pField>, mixed <pMatch>, string <pSide>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOrNotLike pField pMatch pSide
  local tSide

	if pSide is empty then
		put "both" into tSide
	else
		put pSide into tSide
	end if

	_rigLike pField, pMatch, "OR ", tSide, "NOT"
end rigDbOrNotLike








/*----------------------------------------------------------------------
--| COMMAND _rigLike
--|
--| Author: rabit
--| Version:  1.3
--| Created: 26-09-09
--| Last Mod: 04-11-12
--| Requires: rigEscapeLikeStr(), rigFetchDriverSpecificSetting(), _rigProtectIdentifiers()
--|
--| Summary: Generates a %LIKE% portion of the query.
--|
--| Format:  _rigLike param1, param2, param3, param4
--|
--| Parameters: mixed<pField>, mixed <pMatch>, string <pType>, string <pSide>, string <pNot>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigLike pField pMatch pType pSide pNot
  local tField, tType, tSide, tTemp, tK, tV, tPrefix, tOpenParenthesis, tCloseParenthesis
  local tLikeStatement, tLikeEscapeStr, tLikesNum, tNewLikesNum, tCacheLikesNum
  local tCacheExistsNum

	put pField into tField

	if pType is empty then
		put "AND " into tType
	else
		put pType into tType
	end if

	if pSide is empty then
		put "both" into tSide
	else
		put pSide into tSide
	end if

	if tField is not an array then
		put tField into tTemp
		delete variable tField
		put pMatch into tField[tTemp]
	end if

	repeat for each key tK in tField
		put tField[tK] into tV

		put _rigProtectIdentifiers(tK) into tK
		if the number of lines in the keys of sActiveRecord["like"] is 0 then
			put "" into tPrefix
		else
			put tType into tPrefix
		end if

		put rigEscapeLikeStr(tV) into tV

		# SET PARENTHESES
		#
		# CHECK IF AN OPEN PARENTHESIS SHOULD BE WRITTEN AND IF THERE IS CURRENTLY NO OPEN PARENTHESIS WHICH NEEDS TO BE CLOSED
		if sActiveRecord["openParenthesis"] is "(" and (sActiveRecord["closeParenthesisLike"] <> ")") then
			put "(" into tOpenParenthesis
			put empty into sActiveRecord["openParenthesis"]
			put "Like" into sActiveRecord["openParenthesisSet"]

		# IF THERE IS AN OPEN PARENTHESIS WHICH NEEDS TO BE CLOSED ADD A CLOSE PARENTHESIS BEFORE ADDING AN OPEN PARENTHESIS
		else if (sActiveRecord["openParenthesis"] is "(") and (sActiveRecord["closeParenthesisLike"] is ")") then
			put "(" into tOpenParenthesis
			put ") " into tCloseParenthesis
			put empty into sActiveRecord["openParenthesis"]
			put empty into sActiveRecord["closeParenthesisLike"]
			put "Like" into sActiveRecord["openParenthesisSet"]
			put "Like" into sActiveRecord["closeParenthesisSet"]

		# CHECK IF A CLOSE PARENTHESIS SHOULD BE ADDED
		else if sActiveRecord["closeParenthesisLike"] is ")" then
			put ") " into tCloseParenthesis
			put empty into sActiveRecord["closeParenthesisLike"]
			put "Like" into sActiveRecord["closeParenthesisSet"]
		else

		# IF THERE IS AN OPEN PARENTHESIS SET IN FRONT OF A WHERE CLAUSE MOVE IT TO THE LIKE CLAUSE AS THE LIKE PORTION
		# IS WRITTEN AFTER THE WHERE PORTION WHEN THE SELECT QUERY IS BUILT
			if (sActiveRecord["openParenthesisSet"] is "Where") and (sActiveRecord["closeParenthesisWhere"] <> ")") then
				put "WhereToLike" into sActiveRecord["closeParenthesisSet"]
			end if

			put empty into tOpenParenthesis
			put empty into tCloseParenthesis
		end if

		if tSide is "before" then
			put tCloseParenthesis & tPrefix && tOpenParenthesis & tK && pNot && "LIKE '%" & tV & "'" into tLikeStatement
		else if tSide is "after" then
			put tCloseParenthesis & tPrefix && tOpenParenthesis & tK && pNot && "LIKE '" & tV & "%'" into tLikeStatement
		else
			put tCloseParenthesis & tPrefix && tOpenParenthesis & tK && pNot && "LIKE '%" & tV & "%'" into tLikeStatement
		end if
		# # #

		# SOME PLATFORMS REQUIRE AN ESCAPE SEQUENCE DEFINITION FOR LIKE WILDCARDS
		put rigFetchDriverSpecificSetting("_sLikeEscapeStr") into tLikeEscapeStr
			if tLikeEscapeStr <> "" then
			put tLikeStatement & format(tLikeEscapeStr, rigFetchDriverSpecificSetting("_sLikeEscapeChr")) into tLikeStatement
		end if

		put the number of lines in the keys of sActiveRecord["like"] into tLikesNum
		put tLikesNum + 1 into tNewLikesNum
		put tLikeStatement into sActiveRecord["like"][tNewLikesNum]

		if sActiveRecord["caching"] is TRUE then
			put the number of lines in the keys of sActiveRecord["cachelike"] into tCacheLikesNum
			add 1 to  tCacheLikesNum
			put tLikeStatement into sActiveRecord["cachewhere"][tCacheLikesNum]

			put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
			add 1 to tCacheExistsNum
			put "like" into sActiveRecord["cacheexists"][tCacheExistsNum]
		end if
	end repeat

	# THIS IS USED FOR PARENTHESES
	put "Like" into sActiveRecord["currentClause"]
end _rigLike






/*----------------------------------------------------------------------
--| COMMAND rigDbGroupBy
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-09-09
--| Last Mod: 27-09-09
--| Requires: rigTrim(), _rigProtectIdentifiers()
--|
--| Summary: Group by.
--|
--| Format:  rigDbGroupBy param1
--|
--| Parameters: string<pBy>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbGroupBy pBy
  local tBy, tKey, tVal, tGroupBysNum, tCacheGroupBysNum, tCacheExistsNum

	put pBy into tBy
	if (tBy is not a boolean) and (tBy is not a number) and (tBy is not an array) then
		split tBy using comma
	end if

	repeat for each key tKey in tBy
		put tBy[tKey] into tVal
		put rigTrim(tVal) into tVal

		if tVal is not empty then
			put the number of lines in the keys of sActiveRecord["groupby"] into tGroupBysNum
			add 1 to  tGroupBysNum
			put _rigProtectIdentifiers(tVal) into sActiveRecord["groupby"][tGroupBysNum]

			if sActiveRecord["caching"] is TRUE then
				put the number of lines in the keys of sActiveRecord["cachegroupby"] into tCacheGroupBysNum
				add 1 to tCacheGroupBysNum
				put _rigProtectIdentifiers(tVal) into sActiveRecord["cachegroupby"][tCacheGroupBysNum]

				put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
				add 1 to tCacheExistsNum
				put "groupby" into sActiveRecord["cacheexists"][tCacheExistsNum]
			end if
		end if
	end repeat
end rigDbGroupBy








/*----------------------------------------------------------------------
--| COMMAND rigDbHaving
--|
--| Author: rabit
--| Version:  1.1
--| Created: 27-09-09
--| Last Mod: 30-12-09
--| Requires: _rigHaving
--|
--| Summary: Sets the HAVING value. Separates multiple calls with AND.
--|
--| Format:  rigDbHaving param1, param2, param3
--|
--| Parameters: string<pKey>, string <pValue>, bool <pEscape>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbHaving pKey pValue pEscape
  local tEscape

	if pEscape is empty then
		put TRUE into tEscape
	else
		put pEscape into tEscape
	end if

	_rigHaving pKey, pValue, "AND ", tEscape
end rigDbHaving








/*----------------------------------------------------------------------
--| COMMAND rigDbOrHaving
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-09-09
--| Last Mod: 27-09-09
--| Requires: _rigHaving
--|
--| Summary: Sets the OR HAVING value. Separates multiple calls with OR.
--|
--| Format:  rigDbOrHaving param1, param2, param3
--|
--| Parameters: string<pKey>, string <pValue>, bool <pEscape>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOrHaving pKey pValue pEscape
  local tEscape

	if pEscape is empty then
		put TRUE into tEscape
	else
		put pEscape into tEscape
	end if

	_rigHaving pKey, pValue, "OR ", pEscape
end rigDbOrHaving









/*----------------------------------------------------------------------
--| COMMAND _rigHaving
--|
--| Author: rabit
--| Version:  1.3
--| Created: 27-09-09
--| Last Mod: 21-03-14
--| Requires: _rigProtectIdentifiers(), _rigHasOperator(), rigEscapeStr()
--|
--| Summary: Sets the HAVING values. Called by rigDbHaving or rigDbOrHaving.
--|
--| Format:  _rigHaving param1, param2, param3, param4
--|
--| Parameters: string<pKey>, string <pValue>, string <pType>, bool <pEscape>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigHaving pKey pValue pType pEscape
  local tKey, tValue, tType, tEscape, tTemp, tK, tV, tHavingNum, tPrefix
  local tNewHavingNum, tCacheHavingsNum, tCacheExistsNum

	put pKey into tKey
	put pValue into tValue

	if pType is empty then
		put "AND " into tType
	else
		put pType into tType
	end if

	if pEscape is empty then
		put TRUE into tEscape
	else
		put pEscape into tEscape
	end if

	if tKey is not an array then
		put tKey into tTemp
		put empty into tKey
		put tValue into tKey[tTemp]
	end if

	repeat for each key tK in tKey
		put tKey[tK] into tV
		put the number of lines in the keys of sActiveRecord["having"] into tHavingNum

		if tHavingNum = 0 then
			put empty into tPrefix
		else
			put tType into tPrefix
		end if

		if tEscape is TRUE then
			put _rigProtectIdentifiers(tK) into tK
		end if

		if _rigHasOperator(tK) is FALSE then
			put " = " after tK
		end if

		if tV is not empty then
			put rigEscapeStr(tV) into tV
		end if

		-- ci bug
		if (tV is not a number) and (char 1 of tV is not "\") and (char -2 of tV is not "\") then
			put space & "'" & tV & "'" into tV
		else
			put space & tV into tV
		end if
		--

		put tHavingNum + 1 into tNewHavingNum
		put tPrefix & tK & tV into sActiveRecord["having"][tNewHavingNum]

		if sActiveRecord["caching"] is TRUE then
			put the number of lines in the keys of sActiveRecord["cachehaving"] into tCacheHavingsNum
			add 1 to tCacheHavingsNum
			put tPrefix & tK & tV into sActiveRecord["cachegroupby"][tCacheHavingsNum]

			put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
			add 1 to tCacheExistsNum
			put "having" into sActiveRecord["cacheexists"][tCacheExistsNum]
		end if
	end repeat
end _rigHaving






/*----------------------------------------------------------------------
--| COMMAND rigDbOrderBy
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-09-09
--| Last Mod: 27-09-09
--| Requires: rigFetchDriverSpecificSetting(), rigTrim(), _rigProtectIdentifiers()
--|
--| Summary: Sets the ORDER BY value.
--|
--| Format:  rigDbOrderBy param1, param2
--|
--| Parameters: string<pOrderby>, string <pDirection> direction: asc or desc
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOrderBy pOrderby pDirection
  local tOrderby, tDirection, tRandomKeyword, tPart, tTemp, tOrderbyStatement
  local tOrderBysNum, tCacheOrderbysNum, tCacheExistsNum

	put pOrderby into tOrderby
	put pDirection into tDirection
	put rigFetchDriverSpecificSetting("_sRandomKeyword") into tRandomKeyword

	if toLower(tDirection) is "random" then
		put empty into tOrderby -- random results want or don't need a field name
		put tRandomKeyword into tDirection
	else if rigTrim(tDirection) is not empty then
		put toUpper(rigTrim(tDirection)) into tDirection
		if tDirection is among the items of "ASC,DESC" then
			put " " & tDirection into tDirection
		else
			put " ASC" into tDirection
		end if
	end if

	if comma is in tOrderby then

		repeat for each item thisItem in tOrderby
			put rigTrim(thisItem) into tPart
			if tPart is not among the items of sActiveRecord["aliasedtables"] then
				put _rigProtectIdentifiers(rigTrim(tPart)) into tPart
			end if

			put tPart & ", " after tTemp
		end repeat

		delete char -2 to -1 of tTemp
		put tTemp into tOrderby
	else if tDirection <> tRandomKeyword then
		put _rigProtectIdentifiers(tOrderby) into tOrderby
	end if

	put tOrderby & tDirection into tOrderbyStatement

	put the number of lines in the keys of sActiveRecord["orderby"] into tOrderBysNum
	add 1 to tOrderBysNum
	put tOrderbyStatement into sActiveRecord["orderby"][tOrderBysNum]

	if sActiveRecord["caching"] is TRUE then
		put the number of lines in the keys of sActiveRecord["cacheorderby"] into tCacheOrderbysNum
		add 1 to tCacheOrderbysNum
		put tOrderbyStatement into sActiveRecord["cacheorderby"][tCacheOrderbysNum]

		put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
		add 1 to tCacheExistsNum
		put "orderby" into sActiveRecord["cacheexists"][tCacheExistsNum]
	end if
end rigDbOrderBy








/*----------------------------------------------------------------------
--| COMMAND rigDbLimit
--|
--| Author: rabit
--| Version:  1.0
--| Created: 08-07-09
--| Last Mod: 08-07-09
--| Requires: --
--|
--| Summary: Sets the LIMIT value.
--|
--| Format:  rigDbLimit param1, param2
--|
--| Parameters: integer <pLimit>, integer <pOffset>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbLimit pLimit pOffset
	put pLimit into sActiveRecord["limit"]
	if pOffset is not "" then
		put pOffset into sActiveRecord["offset"]
	end if
end rigDbLimit








/*----------------------------------------------------------------------
--| COMMAND rigDbOffset
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-09-09
--| Last Mod: 27-09-09
--| Requires: --
--|
--| Summary: Sets the OFFSET value.
--|
--| Format:  rigDbOffset param1
--|
--| Parameters: integer<pOffset> the offset value
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOffset pOffset
	put pOffset into sActiveRecord["offset"]
end rigDbOffset








/*----------------------------------------------------------------------
--| FUNCTION rigDbValuesSet
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2009-07-21
--| Last Mod: 2019-09-10
--| Requires: rigFetchConfigItem(), rigGetCSRFtokenName(), _rigProtectIdentifiers(), rigDbEscape()
--|
--| Summary: Allows key/value pairs to be set for inserting or updating.
--|
--| Format:  rigDbValuesSet(param1, param2, param3)
--|
--| Parameters: mixed <pKey>, string <pValue>, bool <pEscape>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbValuesSet pKey pValue pEscape
  local tEscape, tKeyArray, tCSRFprotection, tCSRFtokenName, tK, tKprotected

	if pEscape is empty then
		put TRUE into tEscape
	else
		put FALSE into tEscape
	end if

	if pKey is not an array then
		put pValue into tKeyArray[pKey]
	else
		put pKey into tKeyArray
	end if

	# GET CSRFtokenName
	put rigFetchConfigItem("csrf_protection") into tCSRFprotection
	if tCSRFprotection is TRUE then
		put rigGetCSRFtokenName() into tCSRFtokenName
	end if

	repeat for each key tK in tKeyArray

    if tKeyArray[tK] <> empty then

		  if tCSRFprotection is TRUE then
			  # IGNORE VALUE OF CSRF FIELD
			  if tK <> tCSRFtokenName then

				  if tEscape is not TRUE then
					  put _rigProtectIdentifiers(tK) into tKprotected
					  put tKeyArray[tK] into sActiveRecord["set"][tKprotected]
				  else
					  put _rigProtectIdentifiers(tK) into tKprotected
					  put rigDbEscape(tKeyArray[tK]) into sActiveRecord["set"][tKprotected]
				  end if

			  end if -- if tK <> tCSRFtokenName

		  else -- if tCSRFprotection is TRUE

			  if tEscape is not TRUE then
				  put _rigProtectIdentifiers(tK) into tKprotected
				  put tKeyArray[tK] into sActiveRecord["set"][tKprotected]
			  else
				  put _rigProtectIdentifiers(tK) into tKprotected
				  put rigDbEscape(tKeyArray[tK]) into sActiveRecord["set"][tKprotected]
			  end if

		  end if -- if tCSRFprotection is TRUE

    end if -- if tKeyArray[tK] <> empty

	end repeat

	return sActiveRecord["set"]
end rigDbValuesSet







/*----------------------------------------------------------------------
--| FUNCTION rigDbGet
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-07-07
--| Last Mod: 2019-04-19
--| Requires: _rigTrackAliases(), rigDbFrom, rigDbLimit, _rigCompileSelect(), rigDbQuery(), _rigResetSelect
--|
--| Summary: Compiles the select statement based on the other handlers called,
--|            runs the query or returns the query string if requested.
--|
--| Format:  rigDbGet(param1, param2, param3, param4, param5)
--|
--| Parameters: string <pTable> the table, integer <pLimit> the limit clause,
--|						integer <pOffset> the offset clause, bool <pReturnSubqueryString>,
--|           bool <pReturnQueryString>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbGet pTable pLimit pOffset pReturnSubqueryString pReturnQueryString
  local tSQL, tResult

	if pTable <> "" then
		get _rigTrackAliases(pTable)
		rigDbFrom pTable
	end if

	if pLimit is not "" then
		rigDbLimit pLimit, pOffset
	end if

	put _rigCompileSelect() into tSQL

  if pReturnSubqueryString is TRUE then
    _rigResetSelect
    return " (" & tSQL & ")"
  end if

  if pReturnQueryString is TRUE then
    return tSQL
  end if

	put rigDbQuery(tSQL) into tResult
	_rigResetSelect

	return tResult
end rigDbGet






/*----------------------------------------------------------------------
--| FUNCTION rigDbCountAllResults
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-09-09
--| Last Mod: 27-09-09
--| Requires: _rigTrackAliases(), rigDbFrom, rigFetchDriverSpecificSetting(), _rigCompileSelect(), _rigProtectIdentifiers()
--|                  _rigResetSelect, rigDbRow()
--|
--| Summary: Generates a platform-specific query string that counts all records
--|                   returned by an Active Record query.
--|
--| Format:  rigDbCountAllResults(param1)
--|
--| Parameters: string<pTable>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbCountAllResults pTable
  local tCountStr, tSql, tQuery, tRow

	if pTable is not empty then
		get _rigTrackAliases(pTable)
		rigDbFrom pTable
	end if

	put rigFetchDriverSpecificSetting("_sCountString") into tCountStr
	put _rigCompileSelect(tCountStr & _rigProtectIdentifiers("numrows")) into tSql

	put rigDbQuery(tSql) into tQuery
	_rigResetSelect

	if tQuery["numrows"] is 0 then
		return 0
	end if

	put rigDbRow() into tRow

	return tRow["numrows"]
end rigDbCountAllResults








/*----------------------------------------------------------------------
--| FUNCTION rigDbGetWhere
--|
--| Author: rabit
--| Version:  1.1
--| Created: 27-09-09
--| Last Mod: 02-11-09
--| Requires: rigDbFrom, rigDbWhere, rigDbLimit, _rigCompileSelect(), rigDbQuery(), _rigResetSelect
--|
--| Summary: Allows the where clause, limit and offset to be added directly.
--|
--| Format:  rigDbGetWhere(param1, param2, param3, param4)
--|
--| Parameters: string<pTable>, string <pWhere> the where clause, string <pLimit> the limit clause, string <pOffset> the offset clause
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbGetWhere pTable pWhere pLimit pOffset
  local tSql, tResult

	if pTable is not "" then
		rigDbFrom pTable
	end if

	if (pWhere is an array) or ((pWhere is not an array) and (pWhere is not "")) then
		rigDbWhere pWhere
	end if

	if pLimit is not "" then
		rigDbLimit pLimit, pOffset
	end if

	put _rigCompileSelect() into tSql

	put rigDbQuery(tSql) into tResult
	_rigResetSelect

	return tResult
end rigDbGetWhere







/*----------------------------------------------------------------------
--| FUNCTION rigDbInsert
--|
--| Author: rabit
--| Version:  1.4
--| Created: 21-07-09
--| Last Mod: 04-05-13
--| Requires: rigDbValuesSet(), rigFetchDBdriverSetting(), rigDbDisplayError, _rigProtectIdentifiers(), rigLoadHelper,
--|           rigArrayKeys(), rigArrayValues(), _rigInsert(), _rigResetWrite, rigDbQuery(), _rigDbLastInsertID(), rigDbRedirectOnError
--|
--| Summary: Compiles an insert string and runs the query.
--|
--| Format:  rigDbInsert(param1, param2, param3)
--|
--| Parameters: string <pTable> the table to retrieve the results from, array <pInsertVals>
--| 						an associative array of insert values, bool <pLastInsertID> flag which determines
--| 						if the last automatically generated ID value of an AUTO_INCREMENT column should be returned
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbInsert pTable pInsertVals pLastInsertID
  local tInsertVals, tLastInsertID, tTable, tArrayKeys
  local tSQL, tArrayValues, tResultVal

	if pInsertVals is an array then
		put rigDbValuesSet(pInsertVals) into tInsertVals
	end if

	if pLastInsertID is empty then
		put FALSE into tLastInsertID
	else
		put pLastInsertID into tLastInsertID
	end if

	if the number of lines in the keys of sActiveRecord["set"] is 0 then
		# ERROR HANDLING
		if rigFetchDBdriverSetting("dbdebug") is TRUE then
			rigDbDisplayError "db_must_use_set"

			else if rigFetchDBdriverSetting("dbRedirectOnError") <> empty then
				rigDbRedirectOnError
		end if

		return FALSE
	end if

	if pTable is empty then
		if sActiveRecord["from"][1] is empty then
			# ERROR HANDLING
			if rigFetchDBdriverSetting("dbdebug") is TRUE then
				rigDbDisplayError "db_must_set_table"

				else if rigFetchDBdriverSetting("dbRedirectOnError") <> empty then
					rigDbRedirectOnError
			end if

			return FALSE
		end if

		put sActiveRecord["from"][1] into tTable
	else
		put pTable into tTable
	end if

	put _rigProtectIdentifiers(tTable, TRUE, "", FALSE) into tTable

	rigLoadHelper "array"
	put rigArrayKeys(sActiveRecord["set"]) into tArrayKeys
	put rigArrayValues(sActiveRecord["set"], FALSE) into tArrayValues -- use apostrophes (false) is already done by rigDbValuesSet(pInsertVals)

	put _rigInsert(tTable, tArrayKeys, tArrayValues) into tSQL

	_rigResetWrite

	put rigDbQuery(tSQL) into tResultVal

	if tLastInsertID is TRUE then
		return _rigDbLastInsertID( pTable )
	end if

	return tResultVal
end rigDbInsert







/*----------------------------------------------------------------------
--| FUNCTION rigDbUpdate
--|
--| Author: rabit
--| Version:  1.3
--| Created: 27-09-09
--| Last Mod: 04-05-13
--| Requires: _rigMergeCache, rigDbValuesSet(), rigFetchDBdriverSetting(),
--|           rigDbDisplayError, rigDbWhere, rigDbLimit, _rigProtectIdentifiers(),
--|           _rigUpdate(), _rigResetWrite, rigDbQuery(), rigDbRedirectOnError
--|
--| Summary: Compiles an update string and runs the query.
--|
--| Format:  rigDbUpdate(param1, param2, param3, param4)
--|
--| Parameters: string<pTable> the table to retrieve the results from, array <pSet> an associative array of update values,
--|             mixed <pWhere> the where clause, integer <pLimit>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbUpdate pTable pSet pWhere pLimit
  local tTable, tSql

	# COMBINE ANY CACHED COMPONENTS WITH THE CURRENT STATEMENTS
	_rigMergeCache

	if pSet is an array then
		get rigDbValuesSet(pSet)
	end if

	if the number of lines in the keys of sActiveRecord["set"] is 0 then
		# ERROR HANDLING
		if rigFetchDBdriverSetting("dbdebug") is TRUE then
			rigDbDisplayError "db_must_use_set"

			else if rigFetchDBdriverSetting("dbRedirectOnError") <> empty then
				rigDbRedirectOnError
		end if

		return FALSE
	end if

	if pTable is "" then
		 if (sActiveRecord["from"][1] is not an array) and (sActiveRecord["from"][1] is empty) then
			# ERROR HANDLING
			if rigFetchDBdriverSetting("dbdebug") is TRUE then
				rigDbDisplayError "db_must_set_table"

				else if rigFetchDBdriverSetting("dbRedirectOnError") <> empty then
					rigDbRedirectOnError
			end if

			return FALSE
		end if

		put pTable into sActiveRecord["from"][1]
	end if

	if (pWhere is an array) or ((pWhere is not an array) and (pWhere is not empty)) then
		rigDbWhere pWhere
	end if

	if pLimit is not "" then
		rigDbLimit pLimit
	end if

	put _rigProtectIdentifiers(pTable, TRUE, "", FALSE) into tTable
	put _rigUpdate(tTable, sActiveRecord["set"] , sActiveRecord["where"], sActiveRecord["orderby"], sActiveRecord["limit"]) into tSql

	_rigResetWrite

	return rigDbQuery(tSQL)
end rigDbUpdate








/*----------------------------------------------------------------------
--| FUNCTION rigDbEmptyTable
--|
--| Author: rabit
--| Version:  1.1
--| Created: 28-09-09
--| Last Mod: 04-05-13
--| Requires: rigFetchDBdriverSetting(), rigDbDisplayError, _rigProtectIdentifiers(),
--|           _rigDelete(), _rigResetWrite, rigDbQuery(), rigDbRedirectOnError
--|
--| Summary: Compiles a delete string and runs "DELETE FROM table".
--|
--| Format:  rigDbEmptyTable(param1)
--|
--| Parameters: string<pTable> the table to empty
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbEmptyTable pTable
  local tTable, tSql

	if pTable is empty then
		if sActiveRecord["from"] is not an array then
			# ERROR HANDLING
			if rigFetchDBdriverSetting("dbdebug") is TRUE then
				rigDbDisplayError "db_must_set_table"

				else if rigFetchDBdriverSetting("dbRedirectOnError") <> empty then
					rigDbRedirectOnError
			end if

			return FALSE
		end if

		put sActiveRecord["from"][1] into tTable
	else
		put _rigProtectIdentifiers(pTable, TRUE, "", FALSE) into tTable
	end if

	put _rigDelete(tTable) into tSql

	_rigResetWrite

	return rigDbQuery(tSQL)
end rigDbEmptyTable








/*----------------------------------------------------------------------
--| FUNCTION rigDbTruncate
--|
--| Author: rabit
--| Version:  1.1
--| Created: 28-09-09
--| Last Mod: 04-05-13
--| Requires: rigFetchDBdriverSetting(), rigDbDisplayError, _rigProtectIdentifiers(),
--|           _rigTruncate(), _rigResetWrite, rigDbQuery(), rigDbRedirectOnError
--|
--| Summary: Compiles a delete string and runs "DELETE FROM table".
--|
--| Format:  rigDbTruncate(param1)
--|
--| Parameters: string<pTable> the table to empty
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbTruncate pTable
  local tTable, tSql

	if pTable is empty then
		if sActiveRecord["from"] is not an array then
			# ERROR HANDLING
			if rigFetchDBdriverSetting("dbdebug") is TRUE then
				rigDbDisplayError "db_must_set_table"

				else if rigFetchDBdriverSetting("dbRedirectOnError") <> empty then
					rigDbRedirectOnError
			end if

			return FALSE
		end if

		put sActiveRecord["from"][1] into tTable
	else
		put _rigProtectIdentifiers(pTable, TRUE, "", FALSE) into tTable
	end if

	put _rigTruncate(tTable) into tSql

	_rigResetWrite

	return rigDbQuery(tSQL)
end rigDbTruncate








/*----------------------------------------------------------------------
--| FUNCTION rigDbDelete
--|
--| Author: rabit
--| Version:  1.2
--| Created: 28-09-09
--| Last Mod: 04-05-13
--| Requires: _rigMergeCache, rigFetchDBdriverSetting(), rigDbDisplayError, _rigResetWrite,
--|           _rigProtectIdentifiers(), rigDbWhere, rigDbLimit, _rigDelete(), rigDbQuery(), rigDbRedirectOnError
--|
--| Summary: Compiles a delete string and runs the query.
--|
--| Format:  rigDbDelete(param1, param2, param3, param4)
--|
--| Parameters: mixed<pTable> the table(s) to delete from. String or array, mixed <pWhere> the where clause
--|                       mixed <pLimit> the limit clause, boolean <pResetData>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbDelete pTable pWhere pLimit pResetData
  local tTable, tResetData, tSingleTable, tSql

	put pTable into tTable
	if pResetData is empty then
		put TRUE into tResetData
	else
		put pResetData into tResetData
	end if

	# COMBINE ANY CACHED COMPONENTS WITH THE CURRENT STATEMENTS
	_rigMergeCache

	if ((tTable is not an array) and (tTable is empty)) then
		if sActiveRecord["from"] is not an array then
			# ERROR HANDLING
			if rigFetchDBdriverSetting("dbdebug") is TRUE then
				rigDbDisplayError "db_must_set_table"

				else if rigFetchDBdriverSetting("dbRedirectOnError") <> empty then
					rigDbRedirectOnError
			end if

			return FALSE
		end if

		put sActiveRecord["from"][1] into tTable
	else if tTable is an array then
		repeat for each key tKey in tTable
			put tTable[tKey] into tSingleTable

			get rigDbDelete(tSingleTable, pWhere, pLimit, FALSE)
		end repeat

		_rigResetWrite

		return ""
	else
		put _rigProtectIdentifiers(tTable, TRUE, "", FALSE) into tTable
	end if

	if (pWhere is an array) or ((pWhere is not an array) and (pWhere is not empty)) then
		rigDbWhere pWhere
	end if

	if pLimit is not empty then
		rigDbLimit pLimit
	end if

	if (the number of lines in the keys of sActiveRecord["where"] is 0) and (the number of lines in the keys of sActiveRecord["wherein"] is 0) and (the number of lines in the keys of sActiveRecord["like"] is 0) then
		# ERROR HANDLING
		if rigFetchDBdriverSetting("dbdebug") is TRUE then
			rigDbDisplayError "db_del_must_use_where"

			else if rigFetchDBdriverSetting("dbRedirectOnError") <> empty then
				rigDbRedirectOnError
		end if

		return FALSE
	end if

	put _rigDelete(tTable, sActiveRecord["where"], sActiveRecord["like"], sActiveRecord["limit"]) into tSql
	if tResetData is TRUE then
		_rigResetWrite
	end if

	return rigDbQuery(tSQL)
end rigDbDelete








/*----------------------------------------------------------------------
--| FUNCTION rigDbPrefix
--|
--| Author: rabit
--| Version:  1.0
--| Created: 28-09-09
--| Last Mod: 28-09-09
--| Requires: rigDbDisplayError, rigFetchDBdriverSetting()
--|
--| Summary: Prepends a database prefix if one exists in configuration.
--|
--| Format:  rigDbPrefix(param1)
--|
--| Parameters: string<pTable> the table
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbPrefix pTable
	if pTable is empty then
		rigDbDisplayError "db_table_name_required"
	end if

  return (rigFetchDBdriverSetting("dbprefix") & pTable)
end rigDbPrefix








/*----------------------------------------------------------------------
--| FUNCTION _rigTrackAliases
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-07-07
--| Last Mod: 2019-04-18
--| Requires: --
--|
--| Summary: Used to track SQL statements written with aliased tables.
--|
--| Format:  _rigTrackAliases(param1)
--|
--| Parameters: string <pTable> the table
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigTrackAliases pTable
  local tTable, tKey, tRegEx, tTableIsInArray, tKeyNum

	put pTable into tTable
	if tTable is an array then
		repeat for each key tKey in tTable
			get _rigTrackAliases(tTable[tKey])
		end repeat
		return ""
	end if

	# DOES THE STRING CONTAIN A COMMA?  IF SO, WE NEED TO SEPARATE
	# THE STRING INTO DISCREET STATEMENTS
	if "," is in tTable then
		split tTable using comma
		return _rigTrackAliases(tTable)
	end if

	# IF A TABLE ALIAS IS USED WE CAN RECOGNIZE IT BY A SPACE
  if space is in tTable then
    # IF THE ALIAS IS WRITTEN WITH THE AS KEYWORD, REMOVE IT
    put "(?i) AS " into tRegEx
    put replacetext(tTable,tRegEx," ") into tTable

    # GRAB THE ALIAS
    put last word of tTable into tTable

    # STORE THE ALIAS, IF IT DOESN'T ALREADY EXIST
    if sActiveRecord["aliasedtables"] is an array then
      put FALSE into tTableIsInArray
      repeat for each element thisElement in sActiveRecord["aliasedtables"]
        if thisElement is tTable then
          put TRUE into tTableIsInArray
          exit repeat
        end if
      end repeat
      if tTableIsInArray is TRUE then
        put (the number of lines in the keys of sActiveRecord["aliasedtables"]) + 1 into tKeyNum
        put tTable into sActiveRecord["aliasedtables"][tKeyNum]
      end if
    else
		  put tTable into sActiveRecord["aliasedtables"][1]
    end if -- if sActiveRecord["aliasedtables"] is an array
  end if -- if space is in tTable
end _rigTrackAliases






/*----------------------------------------------------------------------
--| FUNCTION _rigCompileSelect
--|
--| Author: rabit
--| Version:  1.6
--| Created: 08-07-09
--| Last Mod: 17-12-14
--| Requires: _rigMergeCache, rigImplode(), _rigLimit(), _rigProtectIdentifiers(),
--|           	_rigFromTables, rigLoadHelper
--|
--| Summary: Generates a query string based on which handlers were used.
--|          	Should not be called directly. The rigDbGet() function calls it.
--|
--| Format:  _rigCompileSelect(param1)
--|
--| Parameters: string <pSelectOverride>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCompileSelect pSelectOverride
  local tSelectOverride, tSQL, tIncr, tColNames, tJoin

	if pSelectOverride is empty then
		put FALSE into tSelectOverride
	else
		put pSelectOverride into tSelectOverride
	end if

	# COMBINE ANY CACHED COMPONENTS WITH THE CURRENT STATEMENTS
	_rigMergeCache

	# WRITE THE "SELECT" PORTION OF THE QUERY
	if tSelectOverride <> FALSE then
		put tSelectOverride into tSQL
	else
		if sActiveRecord["distinct"] is TRUE then
			put "SELECT DISTINCT" into tSQL
		else
			put "SELECT" into tSQL
		end if

		if sActiveRecord["select"] is not an array then
			put tSQL && "*" into tSQL
		else
			# CYCLE THROUGH THE "SELECT" PORTION OF THE QUERY AND PREP EACH COLUMN NAME.
			# THE REASON WE PROTECT IDENTIFIERS HERE RATHER THEN IN THE SELECT() FUNCTION
			# IS BECAUSE UNTIL THE USER CALLS THE FROM() FUNCTION WE DON'T KNOW IF THERE ARE ALIASES
			put 0 into tIncr
			repeat for each key tKey in sActiveRecord["select"]
				add 1 to tIncr
				put _rigProtectIdentifiers(sActiveRecord["select"][tIncr]) into sActiveRecord["select"][tIncr]
				put sActiveRecord["select"][tIncr] & ", " after tColNames
			end repeat

			put char 1 to -3 of tColNames into tColNames
			put tSQL && tColNames into tSQL
		end if
	end if

	# WRITE THE "FROM" PORTION OF THE QUERY
	if sActiveRecord["from"] is an array then
		put space & LF & "FROM" after tSQL
		put tSQL && _rigFromTables(sActiveRecord["from"]) into tSQL
	end if

	# WRITE THE "JOIN" PORTION OF THE QUERY
	if sActiveRecord["join"] is an array then
		put space & LF after tSQL
		put sActiveRecord["join"] into tJoin
		combine tJoin using ","
		replace "," with LF in tJoin
		put tJoin after tSQL

	else if sActiveRecord["join"] <> "" then
		put space & sActiveRecord["join"]  after tSQL
	end if

	# WRITE THE "WHERE" PORTION OF THE QUERY
	if (sActiveRecord["where"] is an array) or (sActiveRecord["like"] is an array) then
		put space & LF & "WHERE" after tSQL
		rigLoadHelper "array"
		put tSQL && rigImplode(sActiveRecord["where"], LF) into tSQL

		# IF THERE IS AN OPEN PARENTHESIS ADD A CLOSE PARENTHESIS
		if sActiveRecord["closeParenthesisWhere"] <> empty then
			put tSQL & ")" into tSQL
			put empty into sActiveRecord["closeParenthesisWhere"]
		end if
	end if

	# WRITE THE "LIKE" PORTION OF THE QUERY
	if sActiveRecord["like"] is an array then
		if sActiveRecord["where"] is an array then
			put space & LF & "AND" after tSQL
		end if
		rigLoadHelper "array"
		put tSQL && rigImplode(sActiveRecord["like"], LF) into tSQL

		# IF THERE IS AN OPEN PARENTHESIS ADD A CLOSE PARENTHESIS
		if sActiveRecord["closeParenthesisLike"] <> empty then
			put tSQL & ")" into tSQL
			put empty into sActiveRecord["closeParenthesisLike"]
		end if
	end if

	# WRITE THE "GROUP BY" PORTION OF THE QUERY
	if sActiveRecord["groupby"] is an array then
		put space & LF & "GROUP BY" after tSQL
		rigLoadHelper "array"
		put tSQL && rigImplode(sActiveRecord["groupby"], ", ") into tSQL
	end if

	# WRITE THE "HAVING" PORTION OF THE QUERY
	if sActiveRecord["having"] is an array then
		put space & LF & "HAVING" after tSQL
		rigLoadHelper "array"
		put tSQL && rigImplode(sActiveRecord["having"], LF) into tSQL
	end if

	# WRITE THE "ORDER BY" PORTION OF THE QUERY
	if sActiveRecord["orderby"] is an array then
		put space & LF & "ORDER BY" after tSQL
		rigLoadHelper "array"
		put tSQL && rigImplode(sActiveRecord["orderby"], ", ") into tSQL

		if sActiveRecord["order"] is not FALSE then
			if sActiveRecord["order"] is "desc" then
				put tSQL && "DESC" into tSQL
			else
				put tSQL && "ASC" into tSQL
			end if
		end if
	end if

	# WRITE THE "LIMIT" PORTION OF THE QUERY
	if sActiveRecord["limit"] is an integer then
		put space & LF after tSQL
		put _rigLimit(tSQL, sActiveRecord["limit"], sActiveRecord["offset"]) into tSQL
	end if

	# RESET VARIABLES USED FOR PARENTHESES
	put empty into sActiveRecord["openParenthesisSet"]
	put empty into sActiveRecord["closeParenthesisSet"]

	return tSQL
end _rigCompileSelect





/*----------------------------------------------------------------------
--| COMMAND rigDbStartCache
--|
--| Author: rabit
--| Version:  1.0
--| Created: 28-09-09
--| Last Mod: 28-09-09
--| Requires: --
--|
--| Summary: Starts AR caching.
--|
--| Format:  rigDbStartCache
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbStartCache
	put TRUE into sActiveRecord["caching"]
end rigDbStartCache







/*----------------------------------------------------------------------
--| COMMAND rigDbStopCache
--|
--| Author: rabit
--| Version:  1.0
--| Created: 28-09-09
--| Last Mod: 28-09-09
--| Requires: --
--|
--| Summary: Stops AR caching.
--|
--| Format:  rigDbStopCache
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbStopCache
	put FALSE into sActiveRecord["caching"]
end rigDbStopCache









/*----------------------------------------------------------------------
--| COMMAND rigDbFlushCache
--|
--| Author: rabit
--| Version:  1.0
--| Created: 28-09-09
--| Last Mod: 28-09-09
--| Requires: --
--|
--| Summary: Empties the AR cache.
--|
--| Format:  rigDbFlushCache
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbFlushCache
	put "" into sActiveRecord["cacheselect"]
	put "" into sActiveRecord["cachefrom"]
	put "" into sActiveRecord["cachejoin"]
	put "" into sActiveRecord["cachewhere"]
	put "" into sActiveRecord["cachelike"]
	put "" into sActiveRecord["cachegroupby"]
	put "" into sActiveRecord["cachehaving"]
	put "" into sActiveRecord["cacheorderby"]
	put "" into sActiveRecord["cacheset"]
	put "" into sActiveRecord["cacheexists"]
end rigDbFlushCache









/*----------------------------------------------------------------------
--| COMMAND _rigMergeCache
--|
--| Author: rabit
--| Version:  1.1
--| Created: 08-07-09
--| Last Mod: 31-12-09
--| Requires: _rigARarrayMerge(), rigFetchDBdriverSetting(), _rigTrackAliases()
--|
--| Summary: When called, this handler merges any cached AR arrays with
--|                    locally called ones.
--|
--| Format:  _rigMergeCache
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigMergeCache
  local tKey, tLocalKey, tCachedKey, tProtectIdentifiers

	if sActiveRecord["cacheexists"] is not an array then
		exit _rigMergeCache
	end if

	repeat for each key tKey in sActiveRecord["cacheexists"]
		put sActiveRecord["cacheexists"][tKey] into tLocalKey

		put "cache" & tLocalKey into tCachedKey

		-------------------
		if sActiveRecord[tCachedKey] is not an array then next repeat

		if sActiveRecord[tLocalKey] is not an array then
			repeat for each key tKey in sActiveRecord[tCachedKey]
				put sActiveRecord[tCachedKey][tKey] into sActiveRecord[tLocalKey][tKey]
			end repeat
		else
			put _rigARarrayMerge(sActiveRecord[tCachedKey], sActiveRecord[tLocalKey]) into sActiveRecord[tLocalKey]
		end if
		------------------
	end repeat

	# IF WE ARE "PROTECTING IDENTIFIERS" WE NEED TO EXAMINE THE "FROM"
	# PORTION OF THE QUERY TO DETERMINE IF THERE ARE ANY ALIASES
	put rigFetchDBdriverSetting("protectIdentifiers") into tProtectIdentifiers
	if tProtectIdentifiers is TRUE and sActiveRecord["cachefrom"] is an array then
		get _rigTrackAliases(sActiveRecord["from"])
	end if
end _rigMergeCache




/*----------------------------------------------------------------------
--| FUNCTION _rigARarrayMerge
--|
--| Author: rabit
--| Version:  1.1
--| Created: 08-07-09
--| Last Mod: 31-12-09
--| Requires: rigLoadHelper, rigElementsList()
--|
--| Summary: Merge active record arrays with caching arrays.
--|
--| Format:  _rigARarrayMerge(param1, param2)
--|
--| Parameters: array <pArrayA>, array <pArrayB>
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigARarrayMerge pArrayA pArrayB
  local tElementsList, tElementsToAddList, tKeyNum, tMergedArray

	# CONVERT ARRAYS TO LISTS
	rigLoadHelper "array"
	put rigElementsList(pArrayA) into tElementsList
	put rigElementsList(pArrayB) into tElementsToAddList

	# MERGE KEYS LISTS
	repeat for each line thisLine in tElementsToAddList
		if thisLine is not among the lines of tElementsList then
			put return & thisLine after tElementsList
		end if
	end repeat

	# BUILD MERGED ARRAY
	put 0 into tKeyNum
	repeat for each line thisLine in tElementsList

		add 1 to tKeyNum
		put thisLine into tMergedArray[tKeyNum]
	end repeat

	return tMergedArray
end _rigARarrayMerge





/*----------------------------------------------------------------------
--| COMMAND _rigResetSelect
--|
--| Author: rabit
--| Version:  1.0
--| Created: 20-07-09
--| Last Mod: 20-07-09
--| Requires: --
--|
--| Summary: Resets the active record values.  Called by the rigDbGet() function.
--|
--| Format:  _rigResetSelect
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigResetSelect
	put empty into sActiveRecord["select"]
	put empty into sActiveRecord["from"]
	put empty into sActiveRecord["join"]
	put empty into sActiveRecord["where"]
	put empty into sActiveRecord["like"]
	put empty into sActiveRecord["groupby"]
	put empty into sActiveRecord["having"]
	put empty into sActiveRecord["orderby"]
	put empty into sActiveRecord["wherein"]
	put empty into sActiveRecord["aliasedtables"]
	put FALSE into sActiveRecord["distinct"]
	put FALSE into sActiveRecord["limit"]
	put FALSE into sActiveRecord["offset"]
	put FALSE into sActiveRecord["order"]
end _rigResetSelect




/*----------------------------------------------------------------------
--| COMMAND _rigResetWrite
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-07-09
--| Last Mod: 21-07-09
--| Requires: --
--|
--| Summary: Resets the active record "write" values.
--|                   Called by the rigDbInsert() rigDbUpdate() and rigDbDelete() functions
--|
--| Format:  _rigResetWrite
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigResetWrite
	put empty into sActiveRecord["set"]
	put empty into sActiveRecord["from"]
	put empty into sActiveRecord["where"]
	put empty into sActiveRecord["like"]
	put empty into sActiveRecord["orderby"]
	put FALSE into sActiveRecord["limit"]
	put FALSE into sActiveRecord["order"]
end _rigResetWrite





/*----------------------------------------------------------------------
--| FUNCTION rigFetchDBactiveRecSetting
--|
--| Author: rabit
--| Version:  1.0
--| Created: 08-07-09
--| Last Mod: 08-07-09
--| Requires: --
--|
--| Summary: Fetch setting from active record settings.
--|
--| Format:  rigFetchDBactiveRecSetting(param1)
--|
--| Parameters: string<pSettingsKey>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigFetchDBactiveRecSetting pSettingsKey
	return sActiveRecord[pSettingsKey]
end rigFetchDBactiveRecSetting






/*----------------------------------------------------------------------
--| COMMAND rigDbOpenParenthesis
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2012
--| Last Mod: 04-11-2012
--| Requires: --
--|
--| Summary: Define a variable so that an open parenthesis will be added to the
--|          next SQL portion.
--|
--| Format:  rigDbOpenParenthesis
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOpenParenthesis
	put empty into sActiveRecord["closeParenthesisSet"]
	put "(" into sActiveRecord["openParenthesis"]
end rigDbOpenParenthesis






/*----------------------------------------------------------------------
--| COMMAND rigDbCloseParenthesis
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2012
--| Last Mod: 04-11-2012
--| Requires: --
--|
--| Summary: Define a variable so that a close parenthesis will be added to the
--|          next SQL portion.
--|
--| Format:  rigDbCloseParenthesis
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbCloseParenthesis
  local tCloseParenthesisType

	# CHECK IF A PARENTHESIS WAS MOVED
	if (sActiveRecord["openParenthesisSet"] is "LikeToWhere") or (sActiveRecord["closeParenthesisSet"] is "WhereToLike") then
		put "closeParenthesisLike" into tCloseParenthesisType
	else
		put "closeParenthesis" & sActiveRecord["currentClause"] into tCloseParenthesisType
	end if

	put ")" into sActiveRecord[tCloseParenthesisType]
end rigDbCloseParenthesis







/*----------------------------------------------------------------------
--| FUNCTION _rigDbJoinConditionsArray
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-08-2015
--| Last Mod: 09-08-2015
--| Requires: --
--|
--| Summary: Split multiple join conditions and store conditions and operators in an array.
--|
--| Format:  _rigDbJoinConditionsArray(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigDbJoinConditionsArray pStr
  local tStrStart, tCounter, tConditionsA, tAndOffset, tOrOffset, tStrCharsNum
  local tOrBeforeAnd

  put 1 into tStrStart
  put 0 into tCounter
  put empty into tConditionsA

  put offset("AND", pStr) into tAndOffset
  put offset("OR", pStr) into tOrOffset


  repeat until (tAndOffset + tOrOffset) = 0
		add 1 to tCounter

		put the number of chars of pStr into tStrCharsNum

		# CHECK IF THERE ARE BOTH OPERATORS AND WHICH ONE IS NEXT
		if (tAndOffset > 1) and (tOrOffset > 1) then
			put tAndOffset > tOrOffset into tOrBeforeAnd

			# GET CONDITION AN OPERATOR
			switch tOrBeforeAnd
				case true
					put char 1 to (tOrOffset - 1) of pStr into tConditionsA[tCounter]["cond"]
					put "OR" into tConditionsA[tCounter]["op"]
					put tOrOffset + 3 into tStrStart
				case false
					put char 1 to (tAndOffset - 1) of pStr into tConditionsA[tCounter]["cond"]
					put "AND" into tConditionsA[tCounter]["op"]
					put tAndOffset + 4 into tStrStart
     	 end switch

			 put char tStrStart to tStrCharsNum of pStr into pStr

			 put offset("AND", pStr) into tAndOffset
			 put offset("OR", pStr) into tOrOffset
			 next repeat
		 end if

		 # GET CONDITION AN OPERATOR
		 if tAndOffset > 1 then
			put char 1 to (tAndOffset - 2) of pStr into tConditionsA[tCounter]["cond"]
			put "AND" into tConditionsA[tCounter]["op"]
			put tAndOffset + 4 into tStrStart
		else if tOrOffset > 1 then
			put char 1 to (tOrOffset - 2) of pStr into tConditionsA[tCounter]["cond"]
			put "OR" into tConditionsA[tCounter]["op"]
			put tOrOffset + 3 into tStrStart
		end if

		put char tStrStart to tStrCharsNum of pStr into pStr

		put offset("AND", pStr) into tAndOffset
		put offset("OR", pStr) into tOrOffset
	end repeat

  # GET LAST CONDITION WHICH HAS NO OPERATOR
  add 1 to tCounter
  put the number of chars of pStr into tStrCharsNum
  put char 1 to tStrCharsNum of pStr into tConditionsA[tCounter]["cond"]
  put empty into tConditionsA[tCounter]["op"]

  return tConditionsA
end _rigDbJoinConditionsArray






--| END OF DBactiveRecord.livecodescript
--| Location:  ./system/database/DBactiveRecord.livecodescript
----------------------------------------------------------------------