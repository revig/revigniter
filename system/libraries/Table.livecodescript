script "Table"

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
# revIgniter HTML Table Generating Library
#
# Lets you create tables manually or from database result arrays or from other arrays.
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  HTML Tables
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/uri.html
##




global gRigA

local sStackInUse, sTableA -- array keys are: rows, heading, autoHeading, caption, template, newline, emptyCells






 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-20
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
        rigLogMessage "debug", "Table Library Loaded"
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
  put TRUE into sTableA["autoHeading"]
  put return into sTableA["newline"]
end _rigSetDefaultValues





/*----------------------------------------------------------------------
--| COMMAND rigRunInitialTableConfig
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-10-09
--| Last Mod: 27-10-09
--| Requires: --
--|
--| Summary: Run initial configuration procedures. Don't remove, even if it does nothing.
--| 
--| Format:  rigRunInitialTableConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialTableConfig pConfig

end rigRunInitialTableConfig







/*----------------------------------------------------------------------
--| COMMAND rigSetTableTemplate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-07-09
--| Last Mod: 21-07-09
--| Requires: --
--|
--| Summary: Set the template.
--| 
--| Format:  rigSetTableTemplate param1
--|
--| Parameters: array <pTemplate>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetTableTemplate pTemplate
	if pTemplate is not an array then
		exit rigSetTableTemplate
	end if

	put pTemplate into sTableA["template"]
end rigSetTableTemplate






/*----------------------------------------------------------------------
--| COMMAND rigSetTableHeading
--|
--| Author: rabit
--| Version:  1.2
--| Created: 22-07-09
--| Last Mod: 11-04-10
--| Requires: --
--|
--| Summary: Set the table heading.
--|            Can be passed as an array or a string of comma separated params.
--| 
--| Format:  rigSetTableHeading param1, param2
--|
--| Parameters: mixed <pHeading>, bool <pFirstUpper> uppercase first char of heading words
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetTableHeading pHeading pFirstUpper
	put pHeading into sTableA["heading"]

	if sTableA["heading"] is not an array then
		split sTableA["heading"] using comma
	end if
	
	if pFirstUpper is TRUE then
		repeat for each key tKey in sTableA["heading"]
			put rigUcwords(sTableA["heading"][tKey]) into sTableA["heading"][tKey]
		end repeat
	end if
end rigSetTableHeading







/*----------------------------------------------------------------------
--| FUNCTION rigMakeTableColumns
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-07-09
--| Last Mod: 22-07-09
--| Requires: rigArraySplice()
--|
--| Summary: Set columns. Takes a one-dimensional array as input and creates
--|            a multi-dimensional array with a depth equal to the number of
--|            columns.  This allows a single array with many elements to  be
--|            displayed in a table that has a fixed column count.
--| 
--| Format:  rigMakeTableColumns(param1, param2, param3)
--|
--| Parameters: array <pArray>, integer <pColLimit>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigMakeTableColumns pArray pColLimit
  local tArray, tColLimit, tKeysNum, tCounter, tOffset
  local tTempArray, tTempKeysNum, tKeyNum, tNewArray
  
	if pArray is not an array then
		return FALSE
	else
	put pArray into tArray
	end if
 
	if (pColLimit is empty) or (pColLimit is not an integer) then
		put 0 into tColLimit
	else
		put pColLimit into tColLimit
	end if

	# TURN OFF THE AUTO-HEADING FEATURE SINCE IT'S DOUBTFUL WE 
	# WILL WANT HEADINGS FROM A ONE-DIMENSIONAL ARRAY
	put FALSE into sTableA["autoHeading"]

	if tColLimit = 0 then
		return tArray
	end if


	put the number of lines in the keys of tArray into tKeysNum

	put 0 into tCounter  
	put 0 into tOffset

	rigLoadHelper "array"

	repeat while tKeysNum > tOffset
		add 1 to tCounter
             
             put rigArraySplice(tArray, tOffset, tColLimit) into tTempArray
             
		put the number of lines in the keys of tTempArray into tTempKeysNum
             
		# ADD NONE BREAKING SPACES 
		if tTempKeysNum < tColLimit then
			put tTempKeysNum + 1 into tKeyNum
			repeat with i = tTempKeysNum to (tColLimit -1)
				put "&nbsp;" into tTempArray[tKeyNum]
				add 1 to tKeyNum
			end repeat
		end if
             
		put tTempArray into tNewArray[tCounter]

            add tColLimit to tOffset

        end repeat

	return tNewArray
end rigMakeTableColumns







/*----------------------------------------------------------------------
--| COMMAND rigSetEmptyCellVal
--|
--| Author: rabit
--| Version:  1.1
--| Created: 22-07-09
--| Last Mod: 04-01-10
--| Requires: --
--|
--| Summary: Set "empty" cells. Set a default value for use in any table cells that are empty.
--| 
--| Format:  rigSetEmptyCellVal param1
--|
--| Parameters: string <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetEmptyCellVal pValue
/*
	if pValue is not an array then
		put 0 into tCounter
		repeat for each item thisItem in pValue
			add 1 to tCounter
			put thisItem into tEmptyCells[tCounter]
		end repeat
		put tEmptyCells into sTableA["emptyCells"]
	else
*/
		put pValue into sTableA["emptyCells"]
	--end if
end rigSetEmptyCellVal






/*----------------------------------------------------------------------
--| COMMAND rigAddTableRow
--|
--| Author: rabit
--| Version:  1.1
--| Created: 22-07-09
--| Last Mod: 04-11-09
--| Requires: --
--|
--| Summary: Add a table row.
--|            Can be passed as an array or a string of comma separated params.
--| 
--| Format:  rigAddTableRow param1
--|
--| Parameters: mixed <pRow>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigAddTableRow pRow
  local tRow, tKeyNum
  
	put pRow into tRow

	if tRow is not an array then
		split tRow using comma
	end if

	if sTableA["rows"] is an array then
		put (the number of lines in the keys of sTableA["rows"] + 1) into tKeyNum
		put tRow into sTableA["rows"][tKeyNum]
	else
		put tRow into sTableA["rows"][1]
	end if
end rigAddTableRow







/*----------------------------------------------------------------------
--| COMMAND rigSetTableCaption
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-07-09
--| Last Mod: 22-07-09
--| Requires: --
--|
--| Summary: Add a table caption.
--| 
--| Format:  rigSetTableCaption param1
--|
--| Parameters: string <pCaption>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetTableCaption pCaption
	put pCaption into sTableA["caption"]
end rigSetTableCaption







/*----------------------------------------------------------------------
--| FUNCTION rigGenerateTable
--|
--| Author: rabit
--| Version:  1.2
--| Created: 22-07-09
--| Last Mod: 04-08-12
--| Requires: _rigSetTableData, _rigCompileTableTemplate, rigIsNumberedArray()
--|
--| Summary: Generate the table.
--| 
--| Format:  rigGenerateTable(param1)
--|
--| Parameters: array <pTableData>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigGenerateTable pTableData
  local tSetHeading, tOut, tHeadingNumberedConsecutive, tHeadingArrayInfo
  local tHeadingNumbered, tKey, tCounter, tConsecutive, tArrayInfo
  local tNumbered, tName, tTemplateKey, tRowNumberedConsecutive
  local tRowArrayInfo, tRowNumbered, tRowCounter
  
	if pTableData is not an array then
		return FALSE
	end if

	if (sTableA["heading"] is not an array) and (sTableA["autoHeading"] is FALSE) then
		put FALSE into tSetHeading
	else
		put TRUE into tSetHeading
	end if
	_rigSetTableData pTableData, tSetHeading
	

	# IS THERE ANYTHING TO DISPLAY? NO? SMITE THEM!
	if (sTableA["heading"] is not an array) and (sTableA["rows"] is not an array) then
		return "Undefined table data"
	end if

	# COMPILE AND VALIDATE THE TEMPLATE DATA
	_rigCompileTableTemplate
	
	# BUILD THE TABLE!
	put sTableA["template"]["tableOpen"] into tOut
	put tOut & sTableA["newline"] into tOut

	# ADD ANY CAPTION HERE
	if sTableA["caption"] is not empty then
		put tOut & sTableA["newline"] into tOut
		put tOut & "<caption>" & sTableA["caption"] & "</caption>" into tOut
		put tOut & sTableA["newline"] into tOut
	end if

	# IS THERE A TABLE HEADING TO DISPLAY?
	if sTableA["heading"] is an array then
		put tOut & sTableA["template"]["headingRowStart"] into tOut
		put tOut & sTableA["newline"] into tOut

		# CHECK IF ARRAY IS NUMBERED CONSECUTIVELY
		put TRUE into tHeadingNumberedConsecutive
		put rigIsNumberedArray(sTableA["heading"], tHeadingNumberedConsecutive) into tHeadingArrayInfo

		put item 1 of tHeadingArrayInfo into tHeadingNumbered
		
		if tHeadingNumbered is TRUE then
			# USE VALUE OF FIRST LINE OF ARRAY KEYS AS STARTING NUMBER
			put item 2 of tHeadingArrayInfo into tCounter
		else
			put 1 into tCounter
		end if
		
		repeat for each key tKey in sTableA["heading"]
			if tHeadingNumbered is TRUE then
				put tCounter into tKey
			end if

			put tOut & sTableA["template"]["headingCellStart"] into tOut
			put tOut & sTableA["heading"][tKey] into tOut
			put tOut & sTableA["template"]["headingCellEnd"] into tOut
			
			add 1 to tCounter
		end repeat

		put tOut & sTableA["template"]["headingRowEnd"] into tOut
		put tOut & sTableA["newline"] into tOut
	end if

	# BUILD THE TABLE ROWS
	if sTableA["rows"] is an array then
		# CHECK IF ARRAY IS NUMBERED CONSECUTIVELY
		put TRUE into tConsecutive
		put rigIsNumberedArray(sTableA["rows"], tConsecutive) into tArrayInfo

		put item 1 of tArrayInfo into tNumbered

		if tNumbered is TRUE then
			# USE VALUE OF FIRST LINE OF ARRAY KEYS AS STARTING NUMBER
			put item 2 of tArrayInfo into tCounter
		else
			put 1 into tCounter
		end if

		repeat for each key tKey in sTableA["rows"]
			if tNumbered is TRUE then
				put tCounter into tKey
			end if

			if sTableA["rows"][tKey] is not an array then
				exit repeat
			end if

			# WE USE MODULUS TO ALTERNATE THE ROW COLORS
			add 1 to tCounter
			if tCounter mod 2 = 0 then
				put "" into tName
			else
				put "Alt" into tName
			end if

			put "row" & tName & "Start" into tTemplateKey
			put tOut & sTableA["template"][tTemplateKey] into tOut
			put tOut & sTableA["newline"] into tOut

			# CHECK IF ARRAY IS NUMBERED CONSECUTIVELY
			put TRUE into tRowNumberedConsecutive
			put rigIsNumberedArray(sTableA["rows"], tRowNumberedConsecutive) into tRowArrayInfo

			put item 1 of tRowArrayInfo into tRowNumbered

			if tRowNumbered is TRUE then
				# USE VALUE OF FIRST LINE OF ARRAY KEYS AS STARTING NUMBER
				put item 2 of tRowArrayInfo into tRowCounter
			else
				put 1 into tRowCounter
			end if

			repeat for each key tCellKey in sTableA["rows"][tKey]

				if tRowNumbered is TRUE then
					put tRowCounter into tCellKey
				end if

				put "cell" & tName & "Start" into tTemplateKey
				put tOut & sTableA["template"][tTemplateKey] into tOut

				if sTableA["rows"][tKey][tCellKey] is empty then
					put tOut & sTableA["emptyCells"] into tOut
				else
					put tOut & sTableA["rows"][tKey][tCellKey] into tOut
				end if

				put "cell" & tName & "End" into tTemplateKey
				put tOut & sTableA["template"][tTemplateKey] into tOut

				add 1 to tRowCounter

			end repeat
		
			put "row" & tName & "End" into tTemplateKey
			put tOut & sTableA["template"][tTemplateKey] into tOut
			put tOut & sTableA["newline"] into tOut
			
			
		end repeat

	end if

	put tOut & sTableA["template"]["tableClose"] into tOut

	return tOut
end rigGenerateTable







/*----------------------------------------------------------------------
--| COMMAND rigClearTableVars
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-07-09
--| Last Mod: 22-07-09
--| Requires: --
--|
--| Summary: Clears the table arrays.  Useful if multiple tables are being generated.
--| 
--| Format:  rigClearTableVars
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigClearTableVars
	put empty into sTableA["rows"]
	put empty into sTableA["heading"]
	put TRUE into sTableA["autoHeading"]
end rigClearTableVars







/*----------------------------------------------------------------------
--| COMMAND _rigSetTableData
--|
--| Author: rabit
--| Version:  1.1
--| Created: 22-07-09
--| Last Mod: 16-12-09
--| Requires: rigIsNumberedArray()
--|
--| Summary: Set table data from an array.
--| 
--| Format:  _rigSetTableData param1, param2
--|
--| Parameters: array <pData>, bool <pSetHeading>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetTableData pData, pSetHeading
  local tSetHeading, tConsecutive, tArrayInfo, tNumbered
  local tCounter, tKey, tKeyNum
  
	if pSetHeading is empty then
		put TRUE into tSetHeading
	else
		put pSetHeading into tSetHeading
	end if

	if pData is not an array then
		return FALSE
	end if

	# CHECK IF ARRAY IS NUMBERED CONSECUTIVELY
	put TRUE into tConsecutive
	put rigIsNumberedArray(sTableA["rows"], tConsecutive) into tArrayInfo

	put item 1 of tArrayInfo into tNumbered

	put 1 into tCounter
	
	repeat for each key tKey in pData
		if tNumbered is TRUE then
			put tCounter into tKey
		end if

		if pData[tKey] is not an array then
			if sTableA["rows"] is an array then
				put (the number of lines in the keys of sTableA["rows"]) + 1 into tKeyNum
				put pData into sTableA["rows"][tKeyNum]
			else
				put pData into sTableA["rows"][1]
			end if
		end if
	
		# IF A HEADING HASN'T ALREADY BEEN SET WE'LL USE THE FIRST ROW OF THE ARRAY AS THE HEADING
		if (tCounter = 1) and (the number of lines in the keys of pData > 1) and (sTableA["heading"] is not an array) and (tSetHeading is TRUE) then
			put pData[tKey] into sTableA["heading"]
		else
			if sTableA["rows"] is an array then
				put (the number of lines in the keys of sTableA["rows"]) + 1 into tKeyNum
				put pData[tKey] into sTableA["rows"][tKeyNum]
			else
				put pData[tKey] into sTableA["rows"][1]
			end if
		end if

		add 1 to tCounter
		
	end repeat

end _rigSetTableData




/*----------------------------------------------------------------------
--| COMMAND _rigCompileTableTemplate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-07-09
--| Last Mod: 22-07-09
--| Requires: _rigDefaultTableTemplate()
--|
--| Summary: Compile template.
--| 
--| Format:  _rigCompileTableTemplate
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigCompileTableTemplate
  local tTemp, tKeys, tKey
  
	if sTableA["template"] is not an array then
		put _rigDefaultTableTemplate() into sTableA["template"]
		exit _rigCompileTableTemplate
	end if

	put _rigDefaultTableTemplate() into tTemp

	put "tableOpen,headingRowStart,headingRowEnd,headingCellStart,headingCellEnd,rowStart,rowEnd,cellStart,cellEnd,rowAltStart,rowAltEnd,cellAltStart,cellAltEnd,tableClose" into tKeys
	repeat for each item tKey in tKeys
		if sTableA["template"][tKey] is empty then
			put tTemp[tKey] into sTableA["template"][tKey]
		end if
	end repeat
end _rigCompileTableTemplate







/*----------------------------------------------------------------------
--| FUNCTION _rigDefaultTableTemplate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-07-09
--| Last Mod: 22-07-09
--| Requires: --
--|
--| Summary: Default template.
--| 
--| Format:  _rigDefaultTableTemplate()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigDefaultTableTemplate
  local tTemplate
  
	put "<table border=" & quote & "0" & quote && "cellpadding=" & quote & "4" & quote && "cellspacing=" & quote & "0" & quote && ">" into tTemplate["tableOpen"]

	put "<tr>" into tTemplate["headingRowStart"]
	put "</tr>" into tTemplate["headingRowEnd"]
	put "<th>" into tTemplate["headingCellStart"]
	put "</th>" into tTemplate["headingCellEnd"]

	put "<tr>" into tTemplate["rowStart"]
	put "</tr>" into tTemplate["rowEnd"]
	put "<td>" into tTemplate["cellStart"]
	put "</td>" into tTemplate["cellEnd"]

	put "<tr>" into tTemplate["rowAltStart"]
	put "</tr>" into tTemplate["rowAltEnd"]
	put "<td>" into tTemplate["cellAltStart"]
	put "</td>" into tTemplate["cellAltEnd"]
	
	put "</table>" into tTemplate["tableClose"]

	return tTemplate
end _rigDefaultTableTemplate






/*----------------------------------------------------------------------
--| FUNCTION rigTableGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Get table array variable values.
--| 
--| Format: rigTableGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigTableGet pWhat
  if pWhat is among the keys of sTableA then
    return sTableA[pWhat]
  end if
   
  return empty
end rigTableGet




/*----------------------------------------------------------------------
--| COMMAND rigTableSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-07
--| Last Mod: 2019-01-07
--| Requires: --
--|
--| Summary: Setter for table variables.
--| 
--| Format: rigTableSet param1, param2
--|
--| Parameters: string <pKey>, sTableA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigTableSet pKey pVal
  if pKey is among the keys of sTableA then
    put pVal into sTableA[pKey]
  end if
end rigTableSet









--| END OF Table.livecodescript
--| Location:  ./system/libraries/Table.livecodescript
----------------------------------------------------------------------