script "Formvalidation"

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
# revIgniter Form Validation Library
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Validation
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/formValidation.html
##

## ------------------------------------------------------------------------




global gRigA, gControllerHandlers, gData

local sFormValidA                                                                   -- array containing rule names, prep methods, field data (read only)
local sErrorArray, sErrorMessages, sErrorPrefix, sErrorSuffix, sErrorString    -- error varaibles
local sConfigRules, sSafeFormData, sConfigLoaded, sPrivateVars
local sPrefilledValues, sGroupName, sRulesIndex, sGroupRulesIndex, sStackInUse






 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-19
 --| Last Mod: --
 --| Requires: rigLogMessage, _rigSetDefaultValues, rigLoadHelper
 --|
 --| Summary:  Run security check, set initial values and load additional files.
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
        rigLogMessage "debug", "Formvalidation Library Loaded"
      end if

      # SET INITIAL VALUES
      _rigSetDefaultValues

      # AUTOMATICALLY LOAD THE FORM HELPER
      rigLoadHelper "form"
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
  put "<p>" into sErrorPrefix
  put "</p>" into sErrorSuffix
  put FALSE into sSafeFormData
  put "requiredR,matchesR,minLengthR,maxLengthR,exactLengthR,greaterThanR,lessThanR,alphaR,alphaNumericR,alphaDashR,alphaAccentR,alphaNumericAccentR,AlphaDashAccentR,numericR,isNumericR,integerR,decimalR,isNaturalR,isNaturalNoZeroR,validEmailR,validEmailsR,validIpR,validBase64R" into sFormValidA["ruleNames"]

  put "trim,md5,sha1,sha3,prepForForm,prepURL,xssClean,stripImageTags,encodeRevTags,htmlSpecialChars,urlDecodeStr" into sFormValidA["prepMethods"]

  put FALSE into sConfigLoaded
  put "fieldData" into sPrivateVars
end _rigSetDefaultValues





/*----------------------------------------------------------------------
--| COMMAND rigRunInitialFormvalidationConfig
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-10-09
--| Last Mod: 27-10-09
--| Requires: --
--|
--| Summary: Run initial configuration procedures. Don't remove, even if it does nothing.
--|
--| Format:  rigRunInitialFormvalidationConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialFormvalidationConfig pConfig

end rigRunInitialFormvalidationConfig






/*----------------------------------------------------------------------
--| COMMAND rigSetConfigRules
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: --
--|
--| Summary: Store form validation rules in sConfigRules variable.
--|
--| Format:  rigSetConfigRules param1
--|
--| Parameters: array <pRules>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetConfigRules pRules
	# VALIDATION RULES CAN BE STORED IN A CONFIG FILE.
	put pRules into sConfigRules
end rigSetConfigRules







/*----------------------------------------------------------------------
--| COMMAND rigSetRules
--|
--| Author: rabit
--| Version:  1.3
--| Created: 30-07-09
--| Last Mod: 17-09-15
--| Requires: --
--|
--| Summary: This handler takes an array of field names and validation
--|            rules as input, validates the info, and stores it.
--|
--| Format:  rigSetRules param1, param2, param3
--|
--| Parameters: mixed <pField>, string <pLabel>, string <pRules>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetRules pField, pLabel, pRules
  local tField, tKey, tLabel, tIndexes, tIsArray

	put pField into tField

	# NO REASON TO SET RULES IF WE HAVE NO POST DATA
	if $_POST is not an array then
		exit rigSetRules
	end if

	# IF AN ARRAY WAS PASSED VIA THE FIRST PARAMETER INSTEAD OF INDIDUAL STRING
	# VALUES WE CYCLE THROUGH IT AND RECURSIVELY CALL THIS FUNCTION.
	if tField is an array then

		repeat for each key tKey in tField

			# HOUSTON, WE HAVE A PROBLEM...
			if ("field" is not among the keys of tField[tKey]) or ("rules" is not among the keys of tField[tKey]) then
				next repeat
			end if

			# IF THE FIELD LABEL WASN'T PASSED WE USE THE FIELD NAME
			if "label" is not among the keys of tField[tKey] then
				put tField[tKey]["field"] into tLabel
			else
				put tField[tKey]["label"] into tLabel
			end if

			# HERE WE GO!
			rigSetRules tField[tKey]["field"], tLabel, tField[tKey]["rules"]
		end repeat

		exit rigSetRules
	end if

	# NO FIELDS? NOTHING TO DO...
	if tField is empty then
		exit rigSetRules
	end if

	# IF THE FIELD LABEL WASN'T PASSED WE USE THE FIELD NAME
	if pLabel is empty then
		put tField into tLabel
	else
		put pLabel into tLabel
	end if

	# IS THE FIELD NAME AN ARRAY?  WE TEST FOR THE EXISTENCE OF A BRACKETS "[]" IN
	# THE FIELD NAME TO DETERMINE THIS.  IF IT IS AN ARRAY, WE REMOVE THE BRACKETS
	# SO THAT WE CAN FETCH THE CORRESPONDING POST DATA LATER
	if "[]" is in tField then
		put char 1 to -3 of tField into tIndexes[1]
		put TRUE into tIsArray

	else
		put empty into tIndexes
		put FALSE into tIsArray
	end if

	# BUILD OUR MASTER ARRAY
	put tField into sFormValidA["fieldData"][tField]["field"]
	put tLabel into sFormValidA["fieldData"][tField]["label"]
	put pRules into sFormValidA["fieldData"][tField]["rules"]
	put tIsArray into sFormValidA["fieldData"][tField]["isArray"]
	put tIndexes into sFormValidA["fieldData"][tField]["keys"]
	put empty into sFormValidA["fieldData"][tField]["postdata"]
	put empty into sFormValidA["fieldData"][tField]["error"]
end rigSetRules







/*----------------------------------------------------------------------
--| COMMAND rigSetMessage
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-07-30
--| Last Mod: 2018-12-29
--| Requires: rigArrayMerge()
--|
--| Summary: Set error message. Lets users set their own error messages on the fly.
--|            Note:  The key name has to match the  function name that it corresponds to.
--|
--| Format:  rigSetMessage param1, param2
--|
--| Parameters: string <pLang>, string <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetMessage pLang pVal
  local tLang

  if pLang is not an array then
    put pVal into tLang[pLang]
  else
    put pLang into tLang
  end if

  if sErrorMessages is an array then
    union sErrorMessages with tLang
  else
    put tLang into sErrorMessages
  end if
end rigSetMessage






/*----------------------------------------------------------------------
--| COMMAND rigSetErrorDelimiters
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-07-09
--| Last Mod: 30-07-09
--| Requires: --
--|
--| Summary: Set the error delimiter. Permits a prefix/suffix to be added to each error message.
--|
--| Format:  rigSetErrorDelimiters param1, param2
--|
--| Parameters: string <pPrefix>, string <pSuffix>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetErrorDelimiters pPrefix pSuffix
  local tPrefix, tSuffix

	if pPrefix is empty then
		put "<p>" into tPrefix
	else
		put pPrefix into tPrefix
	end if

	if pSuffix is empty then
		put "</p>" into tSuffix
	else
		put pSuffix into tSuffix
	end if

	put tPrefix into sErrorPrefix
	put tSuffix into sErrorSuffix
end rigSetErrorDelimiters





/*----------------------------------------------------------------------
--| COMMAND rigSetPrefilledValues
--|
--| Author: rabit
--| Version:  1.2
--| Created: 06-05-11
--| Last Mod: 22-12-14
--| Requires: --
--|
--| Summary: Store prefilled values of form fields in a variable for later
--|            use with rigRequiredR. rigRequiredR then checks if a field value
--|            is among the items of the variable.
--|
--| Format:  rigSetPrefilledValues param1
--|
--| Parameters: mixed <pFieldValuesPrefilled> strings used in prefilled form fields as
--|             comma delimited list or as array
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetPrefilledValues pFieldValuesPrefilled
  local tTempDel, tCurrentDel, tKey

	put empty into sPrefilledValues
	put numToCodepoint(2) into tTempDel

	put the itemDel into tCurrentDel

	if pFieldValuesPrefilled is an array then
		set the itemDel to tTempDel

		repeat for each key tKey in pFieldValuesPrefilled
			put pFieldValuesPrefilled[tKey] & tTempDel after sPrefilledValues
		end repeat

	else

		repeat for each item thisItem in pFieldValuesPrefilled
			put thisItem & tTempDel after sPrefilledValues
		end repeat
	end if

	delete char -1 of sPrefilledValues

	set the itemDel to tCurrentDel
end rigSetPrefilledValues





/*----------------------------------------------------------------------
--| FUNCTION rigFormValidError
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-07-09
--| Last Mod: 30-07-09
--| Requires: --
--|
--| Summary: Gets the error message associated with a particular field.
--|
--| Format:  rigFormValidError(param1, param2, param3)
--|
--| Parameters: string <pField>, string <pPrefix>, string <pSuffix>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormValidError pField pPrefix pSuffix
  local tField, tPrefix, tSuffix

	put pField into tField
	put pPrefix into tPrefix
	put pSuffix into tSuffix

	if ((sFormValidA["fieldData"][tField] is an array) and ("error" is not among the keys of sFormValidA["fieldData"][tField])) or ((sFormValidA["fieldData"][tField] is an array) and (sFormValidA["fieldData"][tField]["error"] is empty)) then
		return ""
	end if

	if tPrefix is empty then
		put sErrorPrefix into tPrefix
	end if

	if tSuffix is empty then
		put sErrorSuffix into tSuffix
	end if

	return tPrefix & sFormValidA["fieldData"][tField]["error"] & tSuffix
end rigFormValidError







/*----------------------------------------------------------------------
--| FUNCTION rigFormValidErrorString
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-07-09
--| Last Mod: 30-07-09
--| Requires: --
--|
--| Summary: Returns the error messages as a string, wrapped in the error delimiters.
--|
--| Format:  rigFormValidErrorString(param1, param2)
--|
--| Parameters: string <pPrefix>, string <pSuffix>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormValidErrorString pPrefix pSuffix
  local tPrefix, tSuffix, tStr

	put pPrefix into tPrefix
	put pSuffix into tSuffix

	# NO ERRRORS, VALIDATION PASSES!
	if sErrorArray is not an array then
		return ""
	end if

	if tPrefix is empty then
		put sErrorPrefix into tPrefix
	end if

	if tSuffix is empty then
		put sErrorSuffix into tSuffix
	end if

	# GENERATE THE ERROR STRING
	put "" into tStr
	repeat for each element tVal in sErrorArray
		if tVal is not empty then
			put tPrefix & tVal & tSuffix & return after tStr
		end if
	end repeat

	return tStr
end rigFormValidErrorString








/*----------------------------------------------------------------------
--| FUNCTION rigFormValidRun
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2009-07-30
--| Last Mod: 2015-09-17
--| Requires: rigSetConfigRules, _rigRequire, rigFetchValidationConf(), rigTrim, rigSetRules
--|           rigLogMessage, rigLangLoadLang(), _rigReduceArray(), _rigFormValidExecute, _rigResetPostArray
--|
--| Summary: Run the validator. This function does all the work.
--|
--| Format: rigFormValidRun(param1)
--|
--| Parameters: array <pGroup>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigFormValidRun pGroup
  local tValidationConfig, tConfigArray, tURI, tRow, tRules
  local tTotalErrors

	if pGroup is an array then
		rigSetConfigRules pGroup
	else
		if sConfigLoaded is not TRUE then
			put gRigA["APPPATH"] & "config/validation" & gRigA["EXT"] into tValidationConfig
			if there is a file tValidationConfig then
				_rigRequire tValidationConfig
				put TRUE into sConfigLoaded

				put rigFetchValidationConf() into tConfigArray
				rigSetConfigRules tConfigArray
			end if
		end if
	end if

	# DO WE EVEN HAVE ANY DATA TO PROCESS?  MM?
	if $_POST is not an array then
		return FALSE
	end if

	# DOES THE _FIELD_DATA ARRAY CONTAINING THE VALIDATION RULES EXIST?
	# IF NOT, WE LOOK TO SEE IF THEY WERE ASSIGNED VIA A CONFIG FILE
	if sFormValidA["fieldData"] is not an array then
		# NO VALIDATION RULES?  WE'RE DONE...
		if sConfigRules is not an array then
			return FALSE
		end if

		# IS THERE A VALIDATION RULE FOR THE PARTICULAR URI BEING ACCESSED?
		if (pGroup is not an array) and (pGroup is empty) then
			put rigTrim(rigUriString(), "/") into tURI

			if tURI is empty then
				put gRigA["controller"] & "/" & gRigA["handler"] into tURI
			end if

		else
			if pGroup is not an array then
				put pGroup into tURI
			end if
		end if

		-- if (tURI is not empty) and (tURI is among the keys of sConfigRules) then
		if ((tURI is not an array) and (tURI is not empty)) and (tURI is among the keys of sConfigRules) then
			rigSetRules sConfigRules[tURI]
		else
			rigSetRules sConfigRules
		end if

		# WERE WE ABLE TO SET THE RULES CORRECTLY?
		if sFormValidA["fieldData"] is not an array then
			rigLogMessage "debug", "Unable to find validation rules"
			return FALSE
		end if

	end if

	# LOAD THE LANGUAGE FILE CONTAINING ERROR MESSAGES
	get rigLangLoadLang("formvalidation")

	# CYCLE THROUGH THE RULES FOR EACH FIELD, MATCH THE
	# CORRESPONDING $_POST ITEM AND TEST FOR ERRORS
	repeat for each key tField in sFormValidA["fieldData"]
		put sFormValidA["fieldData"][tField] into tRow

		# FETCH THE DATA FROM THE CORRESPONDING $_POST ARRAY AND CACHE IT IN THE _FIELD_DATA ARRAY.
		# DEPENDING ON WHETHER THE FIELD NAME IS AN ARRAY OR A STRING WILL DETERMINE WHERE WE GET IT FROM.
		if sFormValidA["fieldData"][tField]["isArray"] is TRUE then
			put _rigReduceArray($_POST, tRow["keys"]) into sFormValidA["fieldData"][tField]["postdata"]

		else
			--if (tField is among the keys of $_POST) and ($_POST[tField] is not empty) then
				--put $_POST[tField] into sFormValidA["fieldData"][tField]["postdata"]
			--if (tField is among the keys of $_POST) and ($_POST[tField] is not empty) then
			if tField is among the keys of $_POST then

				if $_POST[tField] is an array then
					put $_POST[tField] into sFormValidA["fieldData"][tField]["postdata"]
				else
					if $_POST[tField] is not empty then
						put $_POST[tField] into sFormValidA["fieldData"][tField]["postdata"]
					end if
				end if

			end if -- if tField is among the keys of $_POST then
		end if -- if sFormValidA["fieldData"][tField]["isArray"] is TRUE then

		put tRow["rules"] into tRules
		split tRules using "|"

		_rigFormValidExecute tRow, tRules, sFormValidA["fieldData"][tField]["postdata"]
	end repeat

		# DID WE END UP WITH ANY ERRORS?
		put the number of lines in the keys of sErrorArray into tTotalErrors

		if tTotalErrors > 0 then
			put TRUE into sSafeFormData
		end if

		# NOW WE NEED TO RE-SET THE POST DATA WITH THE NEW, PROCESSED DATA
		_rigResetPostArray

		# NO ERRORS, VALIDATION PASSES!
		if tTotalErrors is 0 then
			return TRUE
		end if

		# VALIDATION FAILS
		return FALSE
end rigFormValidRun







/*----------------------------------------------------------------------
--| FUNCTION _rigReduceArray
--|
--| Author: rabit
--| Version:  1.1
--| Created: 30-07-09
--| Last Mod: 13-08-09
--| Requires: --
--|
--| Summary: Traverse a multidimensional $_POST array index until the data is found.
--|
--| Format: _rigReduceArray(param1, param2, param3)
--|
--| Parameters: array <pArray>, array <pKeys>, integer <pInt>
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigReduceArray pArray pKeys pInt
  local tInt, tArray, tCurrentKeyVal

	if pInt is empty then
		put 1 into tInt
	else
		put pInt into tInt
	end if

	put pArray into tArray

	if tArray is an array then

		if tInt is among the keys of pKeys then

		put pKeys[tInt] into tCurrentKeyVal
		if quote is in tCurrentKeyVal then
			replace quote with "" in tCurrentKeyVal
		end if

			--if pKeys[tInt] is among the keys of tArray then
			if tCurrentKeyVal is among the keys of tArray then

				add 1 to tInt
				--put _rigReduceArray(tArray[pKeys[tInt]], pKeys, tInt) into tArray
				put _rigReduceArray(tArray[tCurrentKeyVal], pKeys, tInt) into tArray

			else
				return empty
			end if

		else
			return tArray
		end if

	end if

	return tArray
end _rigReduceArray




/*----------------------------------------------------------------------
--| COMMAND _rigResetPostArray
--|
--| Author: rabit
--| Version:  1.3
--| Created: 02-08-09
--| Last Mod: 17-07-11
--| Requires: _rigPrepForForm
--|
--| Summary: Re-populate the $_POST array with our finalized and processed data.
--|
--| Format:  _rigResetPostArray
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigResetPostArray
  local tPostTemp, tField, tRow, tVal, tV, tArray

	put $_POST into tPostTemp

	repeat for each key tField in sFormValidA["fieldData"]
		put sFormValidA["fieldData"][tField] into tRow

			if tRow["postdata"] is not empty then
				if tRow["isArray"] is FALSE then
					if tRow["field"] is in the keys of $_POST then
						-- put prepForForm(tRow["postdata"]) into $_POST[tRow["field"]]
						_rigPrepForForm tRow["postdata"]
						put the result into tPostTemp[tRow["field"]]
					end if

				else
					--put $_POST into tPostTemp

					if the number of lines in the keys of tRow["keys"] is 1 then
						put tRow["keys"] into tPostTemp[tRow["keys"]]
					else
						--repeat for each element tVal in tRow["keys"]
						repeat for each key tKeysKey in tRow["keys"]
							put tRow["keys"][tKeysKey] into tVal
							--put tVal into tPostTemp[tPostTemp]
							put tVal into tPostTemp[tRow["keys"][tKeysKey]]
						end repeat
					end if

					if tRow["postdata"] is an array then
						repeat for each key tK in tRow["postdata"]
							put tRow["postdata"][tK] into tV

							--put prepForForm(tV) into tArray[tK]
							_rigPrepForForm tV
							put the result into tArray[tK]
						end repeat

						-- put tArray into tPostTemp
						put tArray into tPostTemp[tRow["field"]]
					else
						--put prepForForm(tRow["postdata"]) into tPostTemp
						_rigPrepForForm tRow["postdata"]
						-- put the result into tPostTemp
						put the result into tPostTemp[tRow["field"]]
					end if

					-- put tPostTemp into $_POST
				end if
			end if
	end repeat

	put tPostTemp into $_POST
end _rigResetPostArray



/*----------------------------------------------------------------------
--| COMMAND _rigFormValidExecute
--|
--| Author: rabit
--| Version:  1.11
--| Created: 2009-07-30
--| Last Mod: 2018-12-20
--| Requires: _rigFormValidExecute, rigLangLangLine(), _rigTranslateFieldname(),
--|           _rigExceptionHandler(), rigLogException
--|
--| Summary: Executes the validation routines.
--|
--| Format:  _rigFormValidExecute param1, param2, param3, param4
--|
--| Parameters: array <pRow>, array <pRules>, mixed <pPostdata>, integer <pCycles>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigFormValidExecute pRow, pRules, pPostdata, pCycles
  local tRules, tRulesList, tPostdata, tCycles, tKey, tVal, tCallback
  local tRegEx, tFoundTextVar, tTextFound, tType, tLine, tTranslatedLabel
  local tMessage, tFoundTextVar1, tFoundTextVar2, tRule, tInArray
  local tParam, tResult, tCurrentFile, tCurrentMethod, tErrorData
  local tDisplayError, tPostdataTemp, tTranslatedParam

	put pRules into tRules
	put tRules into tRulesList
	combine tRulesList using comma
	put pPostdata into tPostdata

	if pCycles is not an integer then
		put 0 into tCycles
	else
		put pCycles into tCycles
	end if

	# IF THE $_POST DATA IS AN ARRAY WE WILL RUN A RECURSIVE CALL
	if tPostdata is an array then
		repeat for each key tKey in tPostdata
			put tPostdata[tKey] into tVal

			_rigFormValidExecute pRow, tRules, tVal, tCycles
			add 1 to tCycles
		end repeat

		exit _rigFormValidExecute
	end if

	## --------------------------------------------------------------------
	# IF THE FIELD IS BLANK, BUT NOT REQUIRED, NO FURTHER TESTS ARE NECESSARY
	put FALSE into tCallback

	if ("requiredR" is not among the items of tRulesList) and (tPostdata is empty) then
		# BEFORE WE BAIL OUT, DOES THE RULE CONTAIN A CALLBACK?
		combine tRules using " "

		put "(callback_\w+)" into tRegEx

     put empty into tFoundTextVar -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
     put matchText(tRules,tRegEx,tFoundTextVar) into tTextFound
		if tTextFound is TRUE then
			put TRUE into tCallback
			put empty into tRules
			put tFoundTextVar into tRules[1] -- callback handler name
		else
			exit _rigFormValidExecute
		end if

	end if

	## --------------------------------------------------------------------
	# TYPICALLY THIS RULE WILL ONLY APPLY TO CHECKBOXES.
	if (tPostdata is empty) and (tCallback is FALSE) then
		if ("isset" is among the items of tRulesList) or ("requiredR" is among the items of tRulesList) then -- ????????????????????
			# SET THE MESSAGE TYPE
			if "requiredR" is among the items of tRulesList then
				put "requiredR" into tType
			else
				put "isset" into tType
			end if

			if tType is not among the keys of sErrorMessages then

				put rigLangLangLine(tType) into tLine
				if tLine is FALSE then
					put "The field was not set" into tLine
				end if

			else
				put sErrorMessages[tType] into tLine
			end if

			# BUILD THE ERROR MESSAGE
			put _rigTranslateFieldname(pRow["label"]) into tTranslatedLabel
			put format(tLine,  tTranslatedLabel) into tMessage

			# SAVE THE ERROR MESSAGE
			put tMessage into sFormValidA["fieldData"][pRow["field"]]["error"]

			if pRow["field"] is not among the keys of sErrorArray then
				put tMessage into sErrorArray[pRow["field"]]
			end if

		end if

		exit _rigFormValidExecute
	end if

	## --------------------------------------------------------------------
	# CYCLE THROUGH EACH RULE AND RUN IT
	put empty into tFoundTextVar1 -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	put empty into tFoundTextVar2
	repeat for each key tKey in tRules

		put tRules[tKey] into tRule

		put FALSE into tInArray
		# WE SET THE pPostdata VARIABLE WITH THE CURRENT DATA IN OUR MASTER ARRAY SO THAT
		# EACH CYCLE OF THE LOOP IS DEALING WITH THE PROCESSED DATA FROM THE LAST CYCLE
		if (pRow["isArray"] is TRUE) and (sFormValidA["fieldData"][pRow["field"]]["postdata"] is an array) then
			# WE SHOULDN'T NEED THIS SAFETY, BUT JUST IN CASE THERE ISN'T AN ARRAY INDEX
			# ASSOCIATED WITH THIS CYCLE WE'LL BAIL OUT
			if tCycles is not among the keys of sFormValidA["fieldData"][pRow["field"]]["postdata"] then
				next repeat
			end if

			put sFormValidA["fieldData"][pRow["field"]]["postdata"][tCycles] into tPostdata
			put TRUE into tInArray
		else
			put sFormValidA["fieldData"][pRow["field"]]["postdata"] into tPostdata
		end if

		## --------------------------------------------------------------------
		# IS THE RULE A CALLBACK?
		put FALSE into tCallback

		if char 1 to 9 of tRule is "callback_" then
			put char 10 to -1 of tRule into tRule
			put TRUE into tCallback
		end if

		# STRIP THE PARAMETER (IF EXISTS) FROM THE RULE
		# RULES CAN CONTAIN A PARAMETER: maxLengthR[5]
		put FALSE into tParam

		 put "(.*?)\[(.*?)\]" into tRegEx

    		if matchText(tRule,tRegEx,tFoundTextVar1,tFoundTextVar2) is TRUE then
    			put tFoundTextVar1 into tRule
			put tFoundTextVar2 into tParam
    		end if

		# CALL THE HANDLER THAT CORRESPONDS TO THE RULE
		if tCallback is TRUE then
			if tRule is not among the items of gControllerHandlers then
				next repeat
			end if

			# RUN THE FUNCTION AND GRAB THE RESULT
			try
				--do tRule && tPostdata & "," & tParam
				# TEMPORARILY REPLACE QUOTES
				replace quote with numToCodepoint(2) in tPostdata

				do tRule && quote & tPostdata & quote & "," & tParam
				put the result into tResult

				# SET QUOTES AGAIN
				if numToCodepoint(2) is in tResult then
					replace numToCodepoint(2) with quote in tResult
				end if

			catch tContexts
				put tContexts into gData["formValidErrornumbers"]
				put "Formavalidation.livecodescript" into tCurrentFile
				put "_formValidExecute" into tCurrentMethod

				put _rigExceptionHandler(tContexts) into tErrorData

				if rigConfigItem("logThreshold") > 1 then
					put TRUE into tDisplayError
				else
					put FALSE into tDisplayError
				end if
				rigLogException tErrorData, tDisplayError, tCurrentFile, tCurrentMethod
			end try

			# RE-ASSIGN THE RESULT TO THE MASTER DATA ARRAY
			if tInArray is TRUE then
				if tResult is a boolean then
					put tPostdata into sFormValidA["fieldData"][pRow["field"]]["postdata"][tCycles]
				else
					put tResult into sFormValidA["fieldData"][pRow["field"]]["postdata"][tCycles]
				end if
			else
				if tResult is a boolean then
					put tPostdata into sFormValidA["fieldData"][pRow["field"]]["postdata"]
				else
					put tResult into sFormValidA["fieldData"][pRow["field"]]["postdata"]
				end if
			end if

			# IF THE FIELD ISN'T REQUIRED AND WE JUST PROCESSED A CALLBACK WE'LL MOVE ON...
			if ("requiredR" is among the items of tRulesList) and (tResult <> FALSE) then
				next repeat
			end if

		else

			if (tRule is not among the items of sFormValidA["ruleNames"]) and (tRule is not among the items of sFormValidA["prepMethods"]) then
				next repeat
			end if

			put tPostdata into tPostdataTemp

			# TEMPORARILY REPLACE QUOTES
			replace quote with "__[quote]__" in tPostdataTemp

			# TEMPORARILY REPLACE LINE FEEDS
			replace return with "__[return]__" in tPostdataTemp

			# VALIDATE
			#
       do "rig" & tRule && quote & tPostdataTemp & quote & "," & tParam
			put the result into tResult
			#

			# SET QUOTES AGAIN
			if "__[quote]__" is in tResult then
				replace "__[quote]__" with quote in tResult
			end if

			# SET LINE FEEDS AGAIN
			if "__[return]__"  is in tResult then
				replace "__[return]__"  with return in tResult
			end if


			if tInArray is TRUE then
				if tResult is a boolean then
					put tPostdata into sFormValidA["fieldData"][pRow["field"]]["postdata"][tCycles]
				else
					put tResult into sFormValidA["fieldData"][pRow["field"]]["postdata"][tCycles]
				end if
			else
				if tResult is a boolean then
					put tPostdata into sFormValidA["fieldData"][pRow["field"]]["postdata"]
				else
					put tResult into sFormValidA["fieldData"][pRow["field"]]["postdata"]
				end if
			end if
		end if

		# DID THE RULE TEST NEGATIVELY?  IF SO, GRAB THE ERROR.
		if tResult is FALSE then
			if tRule is not in the keys of sErrorMessages then
				put rigLangLangLine(tRule) into tLine
				if tLine is FALSE then
					put "Unable to access an error message corresponding to your field name."  into tLine
				end if
			else
				put sErrorMessages[tRule] into tLine
			end if

			# IS THE PARAMETER WE ARE INSERTING INTO THE ERROR MESSAGE THE NAME
			# OF ANOTHER FIELD?  IF SO WE NEED TO GRAB ITS "FIELD LABEL"
			if (tParam is in the keys of sFormValidA["fieldData"]) and ("label" is in the keys of sFormValidA["fieldData"][tParam]) then
				put sFormValidA["fieldData"][tParam]["label"] into tParam
			end if

			# BUILD THE ERROR MESSAGE
			put _rigTranslateFieldname(pRow["label"]) into tTranslatedLabel
			put _rigTranslateFieldname(tParam) into tTranslatedParam
			put format(tLine,  tTranslatedLabel, tTranslatedParam) into tMessage

			# SAVE THE ERROR MESSAGE
			put tMessage into sFormValidA["fieldData"][pRow["field"]]["error"]
			if pRow["field"] is not among the keys of sErrorArray then
				put tMessage into sErrorArray[pRow["field"]]
			end if

			exit _rigFormValidExecute
		end if
	end repeat

end _rigFormValidExecute




/*----------------------------------------------------------------------
--| FUNCTION _rigTranslateFieldname
--|
--| Author: rabit
--| Version:  1.1
--| Created: 31-07-09
--| Last Mod: 14-08-09
--| Requires: rigLangLangLine()
--|
--| Summary: Translate a field name.
--|
--| Format: _rigTranslateFieldname(param1)
--|
--| Parameters: string <pFieldName>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigTranslateFieldname pFieldName
  local tFieldName, tLine

	put pFieldName into tFieldName

	# DO WE NEED TO TRANSLATE THE FIELD NAME?
	# WE LOOK FOR THE PREFIX LANG: TO DETERMINE THIS
	if char 1 to 5 of tFieldName is "lang:" then
		# GRAB THE VARIABLE
		set the itemDelimiter to ":"
		put item 2 of tFieldName into tLine

		# WERE WE ABLE TO TRANSLATE THE FIELD NAME?  IF NOT WE USE tLine
		put rigLangLangLine(tLine) into tFieldName
		if tFieldName is FALSE then
			return tLine
		end if

	end if

	return tFieldName
end _rigTranslateFieldname






/*----------------------------------------------------------------------
--| FUNCTION rigFormValidSetValue
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: --
--|
--| Summary: Get the value from a form. Permits you to repopulate a form field with
--|            the value it was submitted with, or, if that value doesn't exist, with the default.
--|
--| Format:  rigFormValidSetValue(param1, param2)
--|
--| Parameters: string <pField>, string <pDefault>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormValidSetValue pField pDefault
	if sFormValidA["fieldData"][pField] is not an array then
		return pDefault
	end if

	return sFormValidA["fieldData"][pField]["postdata"]
end rigFormValidSetValue







/*----------------------------------------------------------------------
--| FUNCTION rigFormValidSetSelect
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: rigFormValidSelectCheckboxRadio()
--|
--| Summary: Enables pull-down lists to be set to the value the user
--|            selected in the event of an error.
--|
--| Format:  rigFormValidSetSelect(param1, param2)
--|
--| Parameters: string <pField>, string <pValue>, bool <pDefault>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormValidSetSelect pField pValue pDefault
  local tStatusMarker

	put "selected" into tStatusMarker
	return rigFormValidSelectCheckboxRadio(pField, pValue, pDefault, tStatusMarker)
end rigFormValidSetSelect








/*----------------------------------------------------------------------
--| FUNCTION rigFormValidSetCheckbox
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: rigFormValidSelectCheckboxRadio()
--|
--| Summary: Enables checkboxes to be set to the value the user
--|                   selected in the event of an error.
--|
--| Format:  rigFormValidSetCheckbox(param1, param2, param3)
--|
--| Parameters: string <pField>, string <pValue>, bool <pDefault>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormValidSetCheckbox pField pValue pDefault
  local tStatusMarker

	put "checked" into tStatusMarker
	return rigFormValidSelectCheckboxRadio(pField, pValue, pDefault, tStatusMarker)
end rigFormValidSetCheckbox








/*----------------------------------------------------------------------
--| FUNCTION rigFormValidSetRadio
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-07-09
--| Last Mod: 30-07-09
--| Requires: rigFormValidSelectCheckboxRadio()
--|
--| Summary: Enables checkboxes to be set to the value the user
--|            selected in the event of an error.
--|
--| Format:  rigFormValidSetRadio(param1, param2, param3)
--|
--| Parameters: string <pField>, string <pValue>, bool <pDefault>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormValidSetRadio pField pValue pDefault
  local tStatusMarker

	put "checked" into tStatusMarker
	return rigFormValidSelectCheckboxRadio(pField, pValue, pDefault, tStatusMarker)
end rigFormValidSetRadio








/*----------------------------------------------------------------------
--| FUNCTION rigFormValidSelectCheckboxRadio
--|
--| Author: rabit
--| Version:  1.2
--| Created: 30-07-09
--| Last Mod: 14-08-09
--| Requires: rigSetSelectCheckboxRadio()
--|
--| Summary: Helper function used by some of the functions in this library.
--|            Enables pull-down lists, checkboxes and radio buttons to be set to the value
--|            the user selected in the event of an error.
--|
--| Format: rigFormValidSelectCheckboxRadio(param1, param2, param3)
--|
--| Parameters: string <pField>, string <pValue>, bool <pDefault>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormValidSelectCheckboxRadio pField pValue pDefault pStatusMarker
  local tField, tDefault, tFieldAsElementsList

	put pField into tField

	if pDefault is empty then
		put FALSE into tDefault
	else
		put pDefault into tDefault
	end if

	if ((sFormValidA["fieldData"] is an array) and (tField is not among the keys of sFormValidA["fieldData"])) \
		or ((sFormValidA["fieldData"][tField] is an array) and ("postdata" is not among the keys of sFormValidA["fieldData"][tField])) \
			or ((sFormValidA["fieldData"] is not an array) and (sFormValidA["fieldData"] is empty)) then

		if (tDefault is TRUE) and (sFormValidA["fieldData"] is not an array) then
			return " " & pStatusMarker & "=" & quote & pStatusMarker & quote
		end if
		return ""
	end if

	put sFormValidA["fieldData"][tField]["postdata"] into tField

	if tField is an array then
		# GET ELEMENTS OF tField
		put tField into tFieldAsElementsList
		combine tFieldAsElementsList using comma

		if pValue is not among the items of tFieldAsElementsList then
			return ""
		end if

	else

		if ((tField is empty or pValue is empty) or (tField <> pValue)) then
			return ""
		end if
	end if

	return " " & pStatusMarker & "=" & quote & pStatusMarker & quote
end rigFormValidSelectCheckboxRadio







/*----------------------------------------------------------------------
--| COMMAND rigRequiredR
--|
--| Author: rabit
--| Version:  1.4
--| Created: 02-08-09
--| Last Mod: 22-12-14
--| Requires: rigTrim()
--|
--| Summary: Required.
--|
--| Format: rigRequiredR param1
--|
--| Parameters: mixed <pFormValue>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigRequiredR pFormValue
  local tCurrentDel

	put the itemDel into tCurrentDel
	set the itemDel to numToCodepoint(2)

	if pFormValue is not an array then
		if rigTrim(pFormValue) is empty then
			return FALSE
		else
			if sPrefilledValues <> empty then

				if pFormValue is among the items of sPrefilledValues then
					set the itemDel to tCurrentDel
					return FALSE
				else
					set the itemDel to tCurrentDel
					return TRUE
				end if

			end if

		end if
	else
		if the number of lines in the keys of pFormValue > 0 then
			repeat for each key tKey in pFormValue
				if pFormValue[tKey] is among the items of sPrefilledValues then
					set the itemDel to tCurrentDel
					return FALSE
				end if
			end repeat
			set the itemDel to tCurrentDel
			return TRUE
		else
			set the itemDel to tCurrentDel
			return FALSE
		end if
	end if

end rigRequiredR






/*----------------------------------------------------------------------
--| COMMAND rigMatchesR
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2009-08-02
--| Last Mod: 2018-02-21
--| Requires: --
--|
--| Summary: Match one field to another.
--|
--| Format: rigMatchesR param1, param2
--|
--| Parameters: string <pStr>, field <pField>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigMatchesR pStr, pField
  local tField

	put pField into tField

	if tField is not in the keys of $_POST then
		return FALSE
	end if

	put $_POST[tField] into tField

	set the caseSensitive to true
	if pStr <> tField then
		return FALSE
	else
		return TRUE
	end if
end rigMatchesR





/*----------------------------------------------------------------------
--| COMMAND rigMinLengthR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 09-08-09
--| Requires: --
--|
--| Summary: Minimum length.
--|
--| Format: rigMinLengthR param1, param2
--|
--| Parameters: string <pStr>, value <pVal>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigMinLengthR pStr, pVal
  local tRegEx, tMatchFound

	put "[^0-9]" into tRegEx

	put matchtext(pVal,tRegEx) into tMatchFound
	if tMatchFound is TRUE then
    		return FALSE
	end if

	if the length of pStr < pVal then
		return FALSE
	else
		return TRUE
	end if
end rigMinLengthR






/*----------------------------------------------------------------------
--| COMMAND rigMaxLengthR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 09-08-09
--| Requires: --
--|
--| Summary: Maximum length.
--|
--| Format: rigMaxLengthR param1, param2
--|
--| Parameters: string <pStr>, value <pVal>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigMaxLengthR pStr, pVal
  local tRegEx, tMatchFound

	put "[^0-9]" into tRegEx

	put matchtext(pVal,tRegEx) into tMatchFound
	if tMatchFound is TRUE then
    		return FALSE
	end if

	if the length of pStr > pVal then
		return FALSE
	else
		return TRUE
	end if
end rigMaxLengthR





/*----------------------------------------------------------------------
--| COMMAND rigExactLengthR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 09-08-09
--| Requires: --
--|
--| Summary: Exact length.
--|
--| Format: rigExactLengthR param1, param2
--|
--| Parameters: string <pStr>, value <pVal>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigExactLengthR pStr, pVal
  local tRegEx, tMatchFound

	put "[^0-9]" into tRegEx

	put matchtext(pVal,tRegEx) into tMatchFound
	if tMatchFound is TRUE then
    		return FALSE
	end if

	if the length of pStr <> pVal then
		return FALSE
	else
		return TRUE
	end if
end rigExactLengthR





/*----------------------------------------------------------------------
--| COMMAND rigValidEmailR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 09-08-09
--| Requires: --
--|
--| Summary: Valid email.
--|
--| Format: rigValidEmailR param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

Command rigValidEmailR pStr
  local tRegEx

	put "(?ix)^([a-z0-9\+_\-]+)(\.[a-z0-9\+_\-]+)*@([a-z0-9\-]+\.)+[a-z]{2,6}$" into tRegEx

	return matchText(pStr, tRegEx)
end rigValidEmailR




/*----------------------------------------------------------------------
--| COMMAND rigValidEmailsR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 13-08-09
--| Requires: rigTrim(), rigValidEmailR
--|
--| Summary: Valid email.
--|
--| Format: rigValidEmailsR param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigValidEmailsR pStr
  local tStr, tEmail

	put pStr into tStr

	if the number of items of pStr is 1 then
		put rigTrim(tStr) into tStr
		rigValidEmailR tStr

		return the result
	end if

	repeat for each item tEmail in tStr
		put rigTrim(tEmail) into tEmail
		if (tEmail is not empty) then
			rigValidEmailR tEmail
			if the result is FALSE then
				return FALSE
			end if
		else
			return FALSE
		end if
	end repeat

	return TRUE
end rigValidEmailsR






/*----------------------------------------------------------------------
--| COMMAND rigValidIpR
--|
--| Author: rabit
--| Version:  1.2
--| Created: 02-08-09
--| Last Mod: 03-07-12
--| Requires: --
--|
--| Summary: Validate IP address.
--|
--| Format: rigValidIpR param1, param2
--|
--| Parameters: string <pIP>, string <pWhich> "ipv4" or "ipv6" to
--|             validate a specific ip format
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigValidIpR pIP pWhich
	return rigValidIP(pIP, pWhich)
end rigValidIpR





/*----------------------------------------------------------------------
--| COMMAND rigAlphaR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 09-08-09
--| Requires: --
--|
--| Summary: Alpha.
--|
--| Format: rigAlphaR param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigAlphaR pStr
  local tRegEx, tMatchFound

	put "(?i)^([a-z])+$" into tRegEx
	put matchText(pStr, tRegEx) into tMatchFound

	return tMatchFound
end rigAlphaR





/*----------------------------------------------------------------------
--| COMMAND rigAlphaNumericR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 09-08-09
--| Requires: --
--|
--| Summary: Alpha numeric.
--|
--| Format: rigAlphaNumericR param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigAlphaNumericR pStr
  local tRegEx, tMatchFound

	put "(?i)^([a-z0-9])+$" into tRegEx
	put matchText(pStr, tRegEx) into tMatchFound

	return tMatchFound
end rigAlphaNumericR





/*----------------------------------------------------------------------
--| COMMAND rigAlphaDashR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 09-08-09
--| Requires: --
--|
--| Summary: Alpha numeric with underscores and dashes.
--|
--| Format: rigAlphaDashR param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigAlphaDashR pStr
  local tRegEx, tMatchFound

	put "(?i)^([-a-z0-9_-])+$" into tRegEx
	put matchText(pStr, tRegEx) into tMatchFound

	return tMatchFound
end rigAlphaDashR





/*----------------------------------------------------------------------
--| COMMAND rigAlphaAccentR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-05-11
--| Last Mod: 04-05-11
--| Requires: --
--|
--| Summary: Alpha and accented characters.
--|
--| Format: rigAlphaAccentR param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigAlphaAccentR pStr
  local tRegEx, tMatchFound

	put "(?i)^([a-zàèòùÀÈÌÒÙáéíóúýÁÉÍÓÚÝâêîôûÂÊÎÔÛãñõÃÑÕäëïöüÿÄËÏÖÜåÅçÇß])+$" into tRegEx
	put matchText(pStr, tRegEx) into tMatchFound

	return tMatchFound
end rigAlphaAccentR





/*----------------------------------------------------------------------
--| COMMAND rigAlphaNumericAccentR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-05-11
--| Last Mod: 04-05-11
--| Requires: --
--|
--| Summary: Alpha numeric and accented characters.
--|
--| Format: rigAlphaNumericAccentR param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigAlphaNumericAccentR pStr
  local tRegEx, tMatchFound

	put "(?i)^([a-z0-9àèòùÀÈÌÒÙáéíóúýÁÉÍÓÚÝâêîôûÂÊÎÔÛãñõÃÑÕäëïöüÿÄËÏÖÜåÅçÇß])+$" into tRegEx
	put matchText(pStr, tRegEx) into tMatchFound

	return tMatchFound
end rigAlphaNumericAccentR





/*----------------------------------------------------------------------
--| COMMAND rigAlphaDashAccentR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-05-11
--| Last Mod: 04-05-11
--| Requires: --
--|
--| Summary: Alpha numeric with underscores, dashes and accented characters.
--|
--| Format: rigAlphaDashAccentR param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigAlphaDashAccentR pStr
  local tRegEx, tMatchFound

	put "(?i)^([-a-z0-9_-àèòùÀÈÌÒÙáéíóúýÁÉÍÓÚÝâêîôûÂÊÎÔÛãñõÃÑÕäëïöüÿÄËÏÖÜåÅçÇß])+$" into tRegEx
	put matchText(pStr, tRegEx) into tMatchFound

	return tMatchFound
end rigAlphaDashAccentR





/*----------------------------------------------------------------------
--| COMMAND rigNumericR
--|
--| Author: rabit
--| Version:  1.2
--| Created: 02-08-09
--| Last Mod: 13-08-09
--| Requires: --
--|
--| Summary: Numeric.
--|
--| Format: rigNumericR param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigNumericR pStr
  local tRegEx, tMatchFound

	-- put "^[\-+]?[0-9]*\.?[0-9]+$" into tRegEx
	put "^[\-+]?[0-9]*[,\.]?[0-9]+$" into tRegEx
	put matchText(pStr, tRegEx) into tMatchFound

	return tMatchFound
end rigNumericR




/*----------------------------------------------------------------------
--| COMMAND rigIsNumericR
--|
--| Author: rabit
--| Version:  1.2
--| Created: 02-08-09
--| Last Mod: 13-08-09
--| Requires: --
--|
--| Summary: Is numeric if it consists of digits, optional leading minus sign, optional decimal point,
--|            and optional "E" or "e" (scientific notation) and !!!!!!!  optional comma.
--|
--| Format: rigIsNumericR param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigIsNumericR pStr
  local tStr

	put pStr into tStr

	if "," is in tStr then
         	replace "," with "." in tStr
	end if

	return tStr is a number
end rigIsNumericR






/*----------------------------------------------------------------------
--| COMMAND rigIntegerR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 09-08-09
--| Requires: --
--|
--| Summary: Integer.
--|
--| Format: rigIntegerR param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigIntegerR pStr
	-- put "^[\-+]?[0-9]+$" into tRegEx
	-- put matchText(pStr, tRegEx) into tMatchFound

	-- return tMatchFound
	return pStr is an integer
end rigIntegerR





/*----------------------------------------------------------------------
--| COMMAND rigDecimalR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-07-12
--| Last Mod: --
--| Requires: --
--|
--| Summary: Decimal number.
--|
--| Format: rigDecimalR param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigDecimalR pStr
  local tRegEx, tMatchFound

	put "^[\-+]?[0-9]+\.|,[0-9]+$" into tRegEx
	put matchText(pStr, tRegEx) into tMatchFound

	return tMatchFound
end rigDecimalR





/*----------------------------------------------------------------------
--| COMMAND rigGreaterThanR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-07-12
--| Last Mod: --
--| Requires: --
--|
--| Summary: Greater than.
--|
--| Format: rigGreaterThanR param1, param2
--|
--| Parameters: string <pStr>, number <pMin>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigGreaterThanR pStr pMin
	if isNumber(pStr) is FALSE then
		return FALSE
	end if

	return (pStr > pMin)
end rigGreaterThanR





/*----------------------------------------------------------------------
--| COMMAND rigLessThanR
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-07-12
--| Last Mod: --
--| Requires: --
--|
--| Summary: Less than.
--|
--| Format: rigLessThanR param1, param2
--|
--| Parameters: string <pStr>, number <pMax>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigLessThanR pStr pMax
	if isNumber(pStr) is FALSE then
		return FALSE
	end if

	return (pStr < pMax)
end rigLessThanR





/*----------------------------------------------------------------------
--| COMMAND rigIsNaturalR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 09-08-09
--| Requires: --
--|
--| Summary: Is a Natural number  (0,1,2,3, etc.).
--|
--| Format: rigIsNaturalR param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigIsNaturalR pStr
  local tRegEx, tMatchFound

	put "^[0-9]+$" into tRegEx
	put matchText(pStr, tRegEx) into tMatchFound

	return tMatchFound
end rigIsNaturalR





/*----------------------------------------------------------------------
--| COMMAND rigIsNaturalNoZeroR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 09-08-09
--| Requires: --
--|
--| Summary: Is a Natural number, but not a zero  (1,2,3, etc.).
--|
--| Format: rigIsNaturalNoZeroR param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigIsNaturalNoZeroR pStr
  local tRegEx, tMatchFound

	put "^[0-9]+$" into tRegEx
	put matchText(pStr, tRegEx) into tMatchFound

	if tMatchFound is not TRUE then
		return FALSE
	end if

	if pStr is 0 then
		return FALSE
	end if

	return TRUE
end rigIsNaturalNoZeroR





/*----------------------------------------------------------------------
--| COMMAND rigValidBase64R
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 09-08-09
--| Requires: --
--|
--| Summary: Tests a string for characters outside of the Base64 alphabet
--|            as defined by RFC 2045 http://www.faqs.org/rfcs/rfc2045.
--|
--| Format: rigValidBase64R param1
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigValidBase64R pStr
  local tRegEx, tMatchFound

	put "[^a-zA-Z0-9\/\+=]" into tRegEx
	put matchText(pStr, tRegEx) into tMatchFound

	if tMatchFound is TRUE then
		return FALSE
	else
		return TRUE
	end if
end rigValidBase64R





/*----------------------------------------------------------------------
--| COMMAND rigTrim
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-08-09
--| Last Mod: 09-08-09
--| Requires: rigTrim()
--|
--| Summary: Trim whitespace at the start and at the end of a string to validate.
--|
--| Format: rigTrim param1
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

command rigTrim pStr
	return rigTrim(pStr)
end rigTrim






/*----------------------------------------------------------------------
--| COMMAND rigMd5
--|
--| Author: Dave Cragg
--| Version:  1.0
--| Created: 09-08-09
--| Last Mod: 09-08-09
--| Requires: --
--|
--| Summary: This will convert the 128-bit value that Rev returns to a hex format
--|            similiar to that returned by PHP and other languages.
--|
--| Format: rigMd5 param1
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

command rigMd5 pStr
  local tMD5str, tBinDecodeMD5str

  put md5digest(pStr) into tMD5str
  get binarydecode("H*",tMD5str,tBinDecodeMD5str)
  return tBinDecodeMD5str
end rigMd5




/*----------------------------------------------------------------------
--| COMMAND rigSha1
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-09-2012
--| Last Mod: 06-09-2012
--| Requires: --
--|
--| Summary: Returns a base64 encoded SHA-1 digest of a block of data.
--|
--| Format:  rigSha1 param1
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

command rigSha1 pStr
	return base64Encode(sha1Digest(pStr))
end rigSha1




/*----------------------------------------------------------------------
--| COMMAND rigSha3
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2018-11-02
--| Last Mod: 2018-11-02
--| Requires: --
--|
--| Summary: Returns a base64 encoded SHA3-384 digest of a block of data.
--|
--| Format:  rigSha3 param1
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

command rigSha3 pStr
  set the itemdel to "."

  # FALLBACK
	if (item 1 of the version < 9) then
    return base64Encode(sha1Digest(pStr))
  end if

  return base64Encode(messageDigest(pStr, "SHA3-384"))
end rigSha3




/*----------------------------------------------------------------------
--| COMMAND _rigPrepForForm
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 10-08-09
--| Requires: rigStripSlashes()
--|
--| Summary: This handler allows HTML to be safely shown in a form.
--|            Special characters are converted.
--|
--| Format: _rigPrepForForm param1
--|
--| Parameters: string <pData>
--|
--| Return: string
----------------------------------------------------------------------*/

private command _rigPrepForForm pData
  local tData, tKey, tVal

	put pData into tData

	if tData is an array then
		repeat for each key tKey in tData
			put tData[tKey] into tVal

			_rigPrepForForm tVal
			put the result into tData[tKey]
		end repeat

		return tData
	end if

	if (sSafeFormData is FALSE) or (tData is empty) then
		return tData
	end if

	put rigStripSlashes(tData) into tData

	replace "'" with "&#39;" in tData
	replace quote with "&quot;" in tData
	replace "<" with "&lt;" in tData
	replace ">" with "&gt;" in tData

	return tData
end _rigPrepForForm





/*----------------------------------------------------------------------
--| COMMAND rigPrepURL
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 10-08-09
--| Requires: --
--|
--| Summary: Prep URL.
--|
--| Format: rigPrepURL param1
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

command rigPrepURL pStr
  local tStr

	put pStr into tStr

	if (tStr is "http://") or (tStr is empty) then
		return empty
	end if

	if (char 1 to 7 of tStr is not "http://") and (char 1 to 8 of tStr is not "https://") then
		put "http://" & tStr into tStr
	end if

	return tStr
end rigPrepURL





/*----------------------------------------------------------------------
--| COMMAND rigStripImageTags
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-08-09
--| Last Mod: 11-08-09
--| Requires: rigStripImgTags()
--|
--| Summary: Strip image tags. Calls function in Input lib.
--|
--| Format: rigStripImageTags param1
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

command rigStripImageTags pStr
	return rigStripImgTags(pStr)
end rigStripImageTags






/*----------------------------------------------------------------------
--| COMMAND rigXssClean
--|
--| Author: rabit
--| Version:  1.1
--| Created: 03-08-09
--| Last Mod: 09-08-09
--| Requires: rigXssClean()
--|
--| Summary: XSS clean.
--|
--| Format: rigXssClean param1
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

command rigXssClean pStr
	return rigXssClean(pStr)
end rigXssClean




/*----------------------------------------------------------------------
--| COMMAND rigEncodeRevTags
--|
--| Author: rabit
--| Version:  1.2
--| Created: 03-08-09
--| Last Mod: 06-09-12
--| Requires: --
--|
--| Summary: Convert REV / LC tags to entities.
--|
--| Format: rigEncodeRevTags param1
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

command rigEncodeRevTags pStr
  local tStr

	put pStr into tStr

	replace "<?rev" with "&lt;?rev" in tStr
	replace "<?REV" with "&lt;?rev" in tStr
	replace "<?lc" with "&lt;?lc" in tStr
	replace "<?LC" with "&lt;?lc" in tStr
	replace "?>" with "?&gt;" in tStr

	return tStr
end rigEncodeRevTags






/*----------------------------------------------------------------------
--| COMMAND rigHtmlSpecialChars
--|
--| Author: rabit
--| Version:  1.1
--| Created: 11-08-09
--| Last Mod: 22-12-14
--| Requires: rigHtmlSpecialChars()
--|
--| Summary: Convert special characters to HTML entities.
--|
--| Format: rigHtmlSpecialChars param1
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

command rigHtmlSpecialChars pStr
  local tStr, tModStr

	put pStr into tStr

	if numToCodepoint(2) is in tStr then
		replace numToCodepoint(2) with quote in tStr
	end if

	put rigHtmlSpecialChars(tStr) into tModStr

	if quote is in tModStr then
		replace quote with numToCodepoint(2) in tModStr
	end if

	return tModStr
end rigHtmlSpecialChars






/*----------------------------------------------------------------------
--| COMMAND rigAddValidationGrp
--|
--| Author: Alex Tweedly
--| Modifications: rabit
--| Version:  1.0
--| Created: 18-09-2015
--| Last Mod: 18-09-2015
--| Requires: --
--|
--| Summary: Define a group name for a set o of validation rules.
--|
--| Format: rigAddValidationGrp [param1]
--|
--| Parameters: string <pGroup> (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigAddValidationGrp pGroup
  put pGroup into sGroupName

  if pGroup <> empty then
    put 0 into sGroupRulesIndex
  end if
end rigAddValidationGrp





/*----------------------------------------------------------------------
--| COMMAND rigAddValidationRules
--|
--| Author: Alex Tweedly
--| Modifications: rabit
--| Version:  1.0
--| Created: 18-09-2015
--| Last Mod: 18-09-2015
--| Requires: --
--|
--| Summary: Add rules to array in validation configuration file.
--|
--| Format: rigAddValidationRules param1, param2, param3, param4
--|
--| Parameters: string <pField> the field name, string <pLabel> the field label,
--|               string <pRules> the validation rules, array <@confArray> the referenced config array
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigAddValidationRules pField pLabel pRules @confArray
  if sGroupName <> empty then
    add 1 to sGroupRulesIndex
    put pField into confArray[sGroupName][sGroupRulesIndex]["field"]
    put pLabel into confArray[sGroupName][sGroupRulesIndex]["label"]
    put pRules into confArray[sGroupName][sGroupRulesIndex]["rules"]

  else
    add 1 to sRulesIndex
    put pField into confArray[sRulesIndex]["field"]
    put pLabel into confArray[sRulesIndex]["label"]
    put pRules into confArray[sRulesIndex]["rules"]
  end if
end rigAddValidationRules





/*----------------------------------------------------------------------
--| FUNCTION rigFormvalidationGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2018-12-31
--| Last Mod: 2018-12-31
--| Requires: --
--|
--| Summary: Get rule names, prep methods, field data.
--|
--| Format:  rigFormvalidationGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigFormvalidationGet pWhat
  if pWhat is among the keys of sFormValidA then
    return sFormValidA[pWhat]
  end if

  return empty
end rigFormvalidationGet





/*----------------------------------------------------------------------
--| COMMAND rigFormvalidationSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2018-12-31
--| Last Mod: 2018-12-31
--| Requires: --
--|
--| Summary: Setter for rule names, prep methods.
--|
--| Format:  rigFormvalidationSet param1, param2
--|
--| Parameters: string <pKey> sFormValidA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigFormvalidationSet pKey pVal
  if (pKey is among the keys of sFormValidA) and (pKey is not among the items of sPrivateVars) then
    put pVal into sFormValidA[pKey]
  end if
end rigFormvalidationSet







--| END OF Formvalidation.livecodescript
--| Location:  ./system/libraries/Formvalidation.livecodescript
----------------------------------------------------------------------
