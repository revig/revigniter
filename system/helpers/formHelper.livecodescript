script "formHelper"

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
# revIgniter Form Helpers
#
# @package		revIgniter
# @subpackage	Helpers
# @category	  Helpers
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/helpers/formHelper.html
##

## ------------------------------------------------------------------------




global gRigA

local sPreppedFields, sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-19
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
--| FUNCTION rigFormOpen
--|
--| Author: rabit
--| Version:  1.3
--| Created: 28-07-09
--| Last Mod: 15-07-12
--| Requires: rigSiteURL(), _rigAttributesToString(), rigFormHidden(), rigFetchConfigItem()
--|            rigGetCSRFhash(), rigGetCSRFtokenName()
--|
--| Summary: Creates the opening portion of the form.
--| 
--| Format:  rigFormOpen(param1, param2, param3)
--|
--| Parameters: string <pAction> the URI segments of the form destination,
--|               array <pAttributes> a key/value pair of attributes,
--|               array <pHidden> a key/value pair hidden data 
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormOpen pAction pAttributes pHidden
  local tAttributes, tURIstring, tAction, tForm, tCSRFprotection, tBaseURL
  local tStandardURLs, tURIsegments, tSegment, tHiddenURI
  
	if pAttributes is not an array then
		put "method=" & quote & "post" & quote into tAttributes
	else
		put pAttributes into tAttributes
	end if
    
	# IF NO ACTION IS PROVIDED THEN SET TO THE CURRENT URL
	if pAction is empty then
		put rigUriString() into tURIstring
		put rigSiteURL(tURIstring) into tAction
		
	# IF AN ACTION IS NOT A FULL URL THEN TURN IT INTO ONE
	else 	if "://" is in pAction then
		put pAction into tAction
	else
		put rigSiteURL(pAction) into tAction
	end if
    
	put "<form action=" & quote & tAction & quote into tForm
	put tForm & _rigAttributesToString(tAttributes, TRUE) into tForm
	put tForm & ">" into tForm
	
	# ADD CSRF FIELD IF ENABLED, BUT LEAVE IT OUT FOR GET REQUESTS AND REQUESTS TO EXTERNAL WEBSITES
	put rigFetchConfigItem("csrf_protection") into tCSRFprotection
	put rigFetchConfigItem("baseUrl") into tBaseURL
	if (tCSRFprotection is TRUE) and (tBaseURL is in tAction) and (tAttributes["method"] is not "get") then
		put rigGetCSRFhash() into pHidden[rigGetCSRFtokenName()]
	end if
    
	# CHECK IF STANDARD QUERY STRING BASED URLs ARE ENABLED
	put rigFetchConfigItem("enableQueryStrings") into tStandardURLs
		
	# STANDARD QUERY STRING BASED URLs
	if (tStandardURLs is TRUE) and (tAttributes["method"] is not "post") then

		 set the itemdelimiter to "?"
    
		put item 2 of tAction into tURIsegments
    
    		set the itemdelimiter to "&"
    
    		repeat for each item tSegment in tURIsegments
        		set the itemdelimiter to "="
        		put "<input type=" & quote & "hidden" & quote && "name=" & quote & (item 1 of tSegment) & quote && "value=" & quote & (item 2 of tSegment) & quote & ">" after tHiddenURI
        		set the itemdelimiter to "&"
    		end repeat

		put tForm & return & tHiddenURI into tForm
	end if
	#

	if pHidden is an array then
		put tForm & return & rigFormHidden(pHidden) into tForm
	end if
    
	return tForm
end rigFormOpen








/*----------------------------------------------------------------------
--| FUNCTION rigFormOpenMultiPart
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: rigFormOpen()
--|
--| Summary: Form declaration - multipart type. Creates the opening portion
--|            of the form, but with "multipart/form-data".
--| 
--| Format:  rigFormOpenMultiPart(param1, param2, param3)
--|
--| Parameters: string <pAction> the URI segments of the form destination,
--|               array <pAttributes> a key/value pair of attributes,
--|               array <pHidden> a key/value pair hidden data 
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormOpenMultiPart pAction pAttributes pHidden
  local tAttributes
  
	put pAttributes into tAttributes
	put "multipart/form-data" into tAttributes["enctype"]

	return rigFormOpen(pAction, tAttributes, pHidden)
end rigFormOpenMultiPart







/*----------------------------------------------------------------------
--| FUNCTION rigFormHidden
--|
--| Author: rabit
--| Version:  1.2
--| Created: 28-07-09
--| Last Mod: 06-11-09
--| Requires: rigFormPrep()
--|
--| Summary: Generates hidden fields.  You can pass a simple
--|            key/value string or an associative array with multiple values.
--| 
--| Format:  rigFormHidden(param1, param2, param3)
--|
--| Parameters: mixed <pName>, string <pValue>, bool <pRecursion>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormHidden pName pValue pRecursion
  local tRecursion, tForm, tKey, tK, tV
  
	if pRecursion is empty then
		put FALSE into tRecursion
	else
		put pRecursion into tRecursion
	end if

	if tRecursion is FALSE then
		put return into tForm
	end if

	if pName is an array then
		repeat for each key tKey in pName
			-- get rigFormHidden(tKey, pName[tKey], TRUE)
			put rigFormHidden(tKey, pName[tKey], TRUE) after tForm
		end repeat

		return tForm
	end if

	if pValue is not an array then
		put "<input type=" & quote & "hidden" & quote && "name=" & quote & pName & quote && "value=" & quote & rigFormPrep(pValue, pName) & quote && "/>" & return after tForm
	else
		repeat for each key tK in pValue
			put pValue[tK] into tV
			get rigFormHidden(pName[tK], tV, TRUE)
		end repeat
	end if
    
	return tForm
end rigFormHidden







/*----------------------------------------------------------------------
--| FUNCTION rigFormInput
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: _rigParseFormAttributes()
--|
--| Summary: Text input field.
--| 
--| Format:  rigFormInput(param1, param2, param3)
--|
--| Parameters: mixed <pData>, string <pValue>, string <pExtra>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormInput pData pValue pExtra
  local tDefaults
  
	put "text" into tDefaults["type"]

	if pData is not an array then
		put pData into tDefaults["name"]
	else
		put "" into tDefaults["name"]
	end if

	put pValue into tDefaults["value"]

	return "<input" && _rigParseFormAttributes(pData, tDefaults) & pExtra && "/>"
end rigFormInput







/*----------------------------------------------------------------------
--| FUNCTION rigFormPassword
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: --
--|
--| Summary: Password field. Identical to the input function but adds the "password" type.
--| 
--| Format:  rigFormPassword(param1, param2, param3)
--|
--| Parameters: mixed <pData>, string <pValue>, string <pExtra>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormPassword pData pValue pExtra
  local tData
  
	put pData into tData

	if tData is not an array then
		put tData into tData["name"]
	end if

	put "password" into tData["type"]

	return rigFormInput(tData, pValue, pExtra)
end rigFormPassword






/*----------------------------------------------------------------------
--| FUNCTION rigFormUpload
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: --
--|
--| Summary: Upload field. Identical to the input function but adds the "file" type.
--| 
--| Format:  rigFormUpload(param1, param2, param3)
--|
--| Parameters: mixed <pData>, string <pValue>, string <pExtra>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormUpload pData pValue pExtra
  local tData
  
	put pData into tData

	if tData is not an array then
		put tData into tData["name"]
	end if

	put "file" into tData["type"]

	return rigFormInput(tData, pValue, pExtra)
end rigFormUpload







/*----------------------------------------------------------------------
--| FUNCTION rigFormTextarea
--|
--| Author: rabit
--| Version:  1.3
--| Created: 29-07-09
--| Last Mod: 04-10-09
--| Requires: _rigParseFormAttributes()
--|
--| Summary: Textarea field.
--| 
--| Format:  rigFormTextarea(param1, param2, param3)
--|
--| Parameters: mixed <pData>, string <pValue>, string <pExtra>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormTextarea pData pValue pExtra
  local tData, tDefaults, tVal, tName
  
	put pData into tData

	if tData is not an array then
		put tData into tDefaults["name"]
	else
		put "" into tDefaults["name"]
	end if

	put "90" into tDefaults["cols"]
	put "12" into tDefaults["rows"]

	if (tData is not an array) or ("value" is not among the keys of  tData) then
		put pValue into tVal
	else
		put tData["value"] into tVal

		# REMOVE VALUE ATTRIBUTE FROM pData ARRAY
		# TEXTAREAS DON'T USE THE VALUE ATTRIBUTE
		--put the keys of  tData into tDataKeysList
		--put lineoffset("value",tDataKeysList) into tFoundLineNum
		--delete line tFoundLineNum of tDataKeysList

		--repeat for each line thisLine in tDataKeysList
			--put tData[thisLine] into tDataValRemoved[thisLine]
		--end repeat
		

		--put tData into tDataValRemoved
		--delete variable tDataValRemoved["value"]
		delete variable tData["value"] 

	end if

	if tData is an array then
		put tData["name"] into tName
	else
		put tData into tName
	end if

	--return "<textarea" && _rigParseFormAttributes(tDataValRemoved, tDefaults) & pExtra & ">" & rigFormPrep(tVal, tName) & "</textarea>"
	return "<textarea" && _rigParseFormAttributes(tData, tDefaults) & pExtra & ">" & rigFormPrep(tVal, tName) & "</textarea>"
end rigFormTextarea







/*----------------------------------------------------------------------
--| FUNCTION rigFormMultiselect
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-09-09
--| Last Mod: 12-09-09
--| Requires: rigFormDropDown()
--|
--| Summary: Multi-select menu
--| 
--| Format:  rigFormMultiselect(param1, param2, param3, param4)
--|
--| Parameters: string <pName>, array <pOptions>, mixed <pSelected>, string <pExtra>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormMultiselect pName pOptions pSelected pExtra
	if "multiple" is not in pExtra then
		put " multiple=" & quote & "multiple" & quote after pExtra
	end if

	return rigFormDropDown(pName, pOptions, pSelected, pExtra)
end rigFormMultiselect







/*----------------------------------------------------------------------
--| FUNCTION rigFormDropDown
--|
--| Author: rabit
--| Version:  1.3
--| Created: 29-07-09
--| Last Mod: 26-07-16
--| Requires: --
--|
--| Summary: Drop-Down menu.
--| 
--| Format:  rigFormDropDown(param1, param2[, param3][, param4][, param5])
--|
--| Parameters: string <pName>, array <pOptions>, mixed <pSelected> (optional), 
--| 						string <pExtra> (optional), string <pSortType> (optional) can be
--|              "asctext", "desctext", "ascnum" or "descnum"
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormDropDown pName pOptions pSelected pExtra pSortType
  local tOptions, tSelected, tExtra, tMultiple, tForm, tSelectedAsElementsList
  local tKey, tVal, tValKeys, tSel, tValue, tAdditionalAttributes
  
	put pOptions into tOptions
	put pSelected into tSelected
	
  if (pSortType is empty) or (pSortType is not among the items of "ascnum,descnum,asctext,desctext") then
    put "asctext" into pSortType
  end if

	if (tSelected is not an array) and (tSelected is not empty) then
		put tSelected into tSelected[1]
	end if
	
	# IF NO SELECTED STATE WAS SUBMITTED WE WILL ATTEMPT TO SET IT AUTOMATICALLY
	if (tSelected is not an array) and (tSelected is empty) then
		# IF THE FORM NAME APPEARS IN THE $_POST ARRAY WE HAVE A WINNER!
		if $_POST[pName] is not empty then
			put $_POST[pName] into tSelected[1]
		end if

	end if

	if pExtra <> "" then
		put " " & pExtra into tExtra
	else
		put pExtra into tExtra
	end if
	
	if (the number of lines in the keys of tSelected > 1) and ("multiple" is not in tExtra) then
		put " multiple=" & quote & "multiple" & quote into tMultiple
	else
		put "" into tMultiple
	end if

	put "<select name=" & quote & pName & quote & tExtra & tMultiple & ">" & return into tForm

	# GET ELEMENTS OF tSelected
	put tSelected into tSelectedAsElementsList
	combine tSelectedAsElementsList using comma
	
  get the keys of tOptions
  rigSort it, pSortType
	
  repeat for each line tKey in it
		put tOptions[tKey] into tVal

		if tVal is an array then
        put the keys of tVal into tValKeys   
        rigSort tValKeys, pSortType
				
			put "<optgroup label=" & quote & tKey & quote & ">" & return after tForm

       repeat for each line tOptgroupKey in tValKeys
				if comma is not in tOptgroupKey then
						
					if tOptgroupKey is among the items of tSelectedAsElementsList then
						put " selected=" & quote & "selected" & quote into tSel
					else
						put "" into tSel
					end if

					put "<option value=" & quote & tOptgroupKey & quote & tSel & ">" & tVal[tOptgroupKey] & "</option>" & return after tForm
					
				else -- if comma is not in tOptgroupKey then
					
					put item 1 of tOptgroupKey into tValue
					put item 2 to (the number of items of tOptgroupKey) of tOptgroupKey into tAdditionalAttributes
					replace comma with space in tAdditionalAttributes
					
					if tValue is among the items of tSelectedAsElementsList then
						put " selected=" & quote & "selected" & quote into tSel
					else
						put "" into tSel
					end if

					put "<option value=" & quote & tValue & quote & tSel && tAdditionalAttributes & ">" & tVal[tOptgroupKey] & "</option>" & return after tForm
					
				end if -- if comma is not in tOptgroupKey then
				
			end repeat

			put "</optgroup>" & return after tForm

		else -- if tVal is an array then
				
			if comma is not in tKey then
				if tKey is among the items of tSelectedAsElementsList then
					put " selected=" & quote & "selected" & quote into tSel
				else
					put "" into tSel
				end if

				put "<option value=" & quote & tKey & quote & tSel & ">" & tVal & "</option>" & return after tForm
				
			else
				put item 1 of tKey into tValue
				put item 2 to (the number of items of tKey) of tKey into tAdditionalAttributes
				replace comma with space in tAdditionalAttributes
				
				if tValue is among the items of tSelectedAsElementsList then
					put " selected=" & quote & "selected" & quote into tSel
				else
					put "" into tSel
				end if

				put "<option value=" & quote & tValue & quote & tSel && tAdditionalAttributes & ">" & tVal & "</option>" & return after tForm
			end if
		end if -- if tVal is an array then
			
			
	end repeat 

	put "</select>" after tForm

	return tForm
end rigFormDropDown







/*----------------------------------------------------------------------
--| FUNCTION rigFormCheckbox
--|
--| Author: rabit
--| Version:  1.1
--| Created: 29-07-09
--| Last Mod: 04-08-09
--| Requires: _rigParseFormAttributes()
--|
--| Summary: Checkbox field.
--| 
--| Format:  rigFormCheckbox(param1, param2, param3, param4)
--|
--| Parameters: mixed <pData>, string <pValue>, bool <pChecked>, string <pExtra>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormCheckbox pData pValue pChecked pExtra
  local tChecked, tData, tDefaults
  
	if pChecked is empty then
		put FALSE into tChecked
	else
		put pChecked into tChecked
	end if

	put pData into tData

	put "checkbox" into tDefaults["type"]

	if tData is not an array then
		put tData into tDefaults["name"]
	else
		put "" into tDefaults["name"]
	end if

	put pValue into tDefaults["value"]

	if (tData is an array) and ("checked" is among the keys of tData) then
		put tData["checked"] into tChecked

		if tChecked is FALSE then

			# REMOVE CHECKED ATTRIBUTE FROM tData ARRAY
			--put the keys of  tData into tDataKeysList
			--put lineoffset("checked",tDataKeysList) into tFoundLineNum
			--delete line tFoundLineNum of tDataKeysList

			--repeat for each line thisLine in tDataKeysList
				--put tData[thisLine] into tDataCheckedRemoved[thisLine]
			--end repeat
			--put tDataCheckedRemoved into tData

			delete variable tData["checked"] 

		else
			put "checked" into tData["checked"]
		end if
		
	end if

	if tChecked is TRUE then
		put "checked" into tDefaults["checked"]

	else
		# REMOVE CHECKED ATTRIBUTE FROM tDefaults ARRAY
			--put the keys of  tDefaults into tDefaultsKeysList
			--put lineoffset("checked",tDefaultsKeysList) into tFoundLineNum
			--delete line tFoundLineNum of tDefaultsKeysList

			--repeat for each line thisLine in tDefaultsKeysList
				--put tDefaults[thisLine] into tDefaultsCheckedRemoved[thisLine]
			--end repeat
			--put tDefaultsCheckedRemoved into tDefaults

			delete variable tDefaults["checked"] 

	end if

	return "<input" && _rigParseFormAttributes(tData, tDefaults) & pExtra && "/>"
end rigFormCheckbox







/*----------------------------------------------------------------------
--| FUNCTION rigFormRadio
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: rigFormCheckbox()
--|
--| Summary: Radio button.
--| 
--| Format:  rigFormRadio(param1, param2, param3, param4)
--|
--| Parameters: mixed <pData>, string <pValue>, bool <pChecked>, string <pExtra>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormRadio pData pValue pChecked pExtra
  local tChecked, tData
  
	if pChecked is empty then
		put FALSE into tChecked
	else
		put pChecked into tChecked
	end if

	if pData is not an array then
		put pData into tData["name"]
	else
		put pData into tData
	end if

	put "radio" into tData["type"]

	return rigFormCheckbox(tData, pValue, tChecked, pExtra)
end rigFormRadio







/*----------------------------------------------------------------------
--| FUNCTION rigSubmitButton
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: _rigParseFormAttributes()
--|
--| Summary: Submit button.
--| 
--| Format:  rigSubmitButton(param1, param2, param3)
--|
--| Parameters: mixed <pData>, string <pValue>, string <pExtra>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSubmitButton pData pValue pExtra
  local tData, tDefaults
  
	put pData into tData

	put "submit" into tDefaults["type"]

	if tData is not an array then
		put tData into tDefaults["name"]
	else
		put "" into tDefaults["name"]
	end if

	put pValue into tDefaults["value"]

	return "<input" && _rigParseFormAttributes(tData, tDefaults) & pExtra && "/>"
end rigSubmitButton







/*----------------------------------------------------------------------
--| FUNCTION rigResetButton
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: _rigParseFormAttributes()
--|
--| Summary: Reset button.
--| 
--| Format:  rigResetButton(param1, param2, param3)
--|
--| Parameters: mixed <pData>, string <pValue>, string <pExtra>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigResetButton pData pValue pExtra
  local tData, tDefaults
  
	put pData into tData

	put "reset" into tDefaults["type"]

	if tData is not an array then
		put tData into tDefaults["name"]
	else
		put "" into tDefaults["name"]
	end if

	put pValue into tDefaults["value"]

	return "<input" && _rigParseFormAttributes(tData, tDefaults) & pExtra && "/>"
end rigResetButton








/*----------------------------------------------------------------------
--| FUNCTION rigFormButton
--|
--| Author: rabit
--| Version:  1.1
--| Created: 29-07-09
--| Last Mod: 04-08-09
--| Requires: _rigParseFormAttributes()
--|
--| Summary: Form button.
--| 
--| Format:  rigFormButton(param1, param2, param3)
--|
--| Parameters: mixed <pData>, string <pContent>, string <pExtra>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormButton pData pContent pExtra
  local tContent, tData, tDefaults
  
	put pContent into tContent
	put pData into tData

	if tData is not an array then
		put tData into tDefaults["name"]
	else
		put "" into tDefaults["name"]
	end if

	put "button" into tDefaults["type"]

	if (tData is an array) and ("content" is among the keys of tData) then
		put tData["content"] into tContent

		# REMOVE CONTENT ATTRIBUTE FROM tData ARRAY
		# CONTENT IS NOT AN ATTRIBUTE
		--put the keys of  tData into tDataKeysList
		--put lineoffset("content",tDataKeysList) into tFoundLineNum
		--delete line tFoundLineNum of tDataKeysList

		--repeat for each line thisLine in tDataKeysList
			--put tData[thisLine] into tDataContRemoved[thisLine]
		--end repeat
		--put tDataContRemoved into tData
		
		delete variable tData["content"]	

	end if

	return "<button" && _rigParseFormAttributes(tData, tDefaults) & pExtra & ">" & tContent & "</button>"
end rigFormButton








/*----------------------------------------------------------------------
--| FUNCTION rigFormLabel
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: --
--|
--| Summary: Form label tag.
--| 
--| Format:  rigFormLabel(param1, param2, param3)
--|
--| Parameters: string <pLabelText> text to appear onscreen, string <pID> id the label applies to,
--|               array <pAttributes> additional attributes
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormLabel pLabelText pID pAttributes
  local tLabel
  
	put "<label" into tLabel

	if pID <> "" then
		put " for=" & quote & pID & quote after tLabel
	end if

	if pAttributes is an array then
		repeat for each key tKey in pAttributes
			put " " & tKey & "=" & quote & pAttributes[tKey] & quote after tLabel
		end repeat
	end if

	put ">" & pLabelText & "</label>" after tLabel

	return tLabel
end rigFormLabel








/*----------------------------------------------------------------------
--| FUNCTION rigFormFieldset
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: _rigAttributesToString()
--|
--| Summary: Used to produce <fieldset><legend>text</legend>.  To close fieldset
--|                    use rigFormFieldsetClose().
--| 
--| Format:  rigFormFieldset(param1, param2)
--|
--| Parameters: string <pLegendText> the legend text, array <pAttributes> additional attributes
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormFieldset pLegendText pAttributes
  local tFieldset
  
	put "<fieldset" into tFieldset
	put _rigAttributesToString(pAttributes, FALSE) after tFieldset
	put ">" & return after tFieldset

	if pLegendText <> "" then
		put "<legend>" & pLegendText & "</legend>" & return after tFieldset
	end if

	return tFieldset
end rigFormFieldset







/*----------------------------------------------------------------------
--| FUNCTION rigFormFieldsetClose
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: --
--|
--| Summary: Fieldset close tag.
--| 
--| Format:  rigFormFieldsetClose(param1)
--|
--| Parameters: string <pExtra>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormFieldsetClose pExtra
	return "</fieldset>" & pExtra
end rigFormFieldsetClose







/*----------------------------------------------------------------------
--| FUNCTION rigFormClose
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: --
--|
--| Summary: Form close tag.
--| 
--| Format:  rigFormClose(param1)
--|
--| Parameters: string <pExtra>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormClose pExtra
	return "</form>" & pExtra
end rigFormClose







/*----------------------------------------------------------------------
--| FUNCTION rigFormPrep
--|
--| Author: rabit
--| Version:  1.1
--| Created: 28-07-09
--| Last Mod: 12-09-09
--| Requires: rigPregReplace(), rigHtmlSpecialChars()
--|
--| Summary: Formats text so that it can be safely placed in a form field in the event it has HTML tags.
--| 
--| Format:  rigFormPrep(param1, param2)
--|
--| Parameters: string <pStr>, string <pFieldName>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormPrep pStr pFieldName
  local tStr, tKey, tTemp, tRegEx, tReplacement, tStrToReplaceInFoundStr
  
	put pStr into tStr

	# IF THE FIELD NAME IS AN ARRAY WE DO THIS RECURSIVELY
	if tStr is an array then
		repeat for each key tKey in tStr
			put rigFormPrep(tStr[tKey]) into tStr[tKey]
		end repeat
		return tStr
	end if
    
	if tStr is "" then
		return ""
	end if

	# WE'VE ALREADY PREPPED A FIELD WITH THIS NAME
	# @TODO NEED TO FIGURE OUT A WAY TO NAMESPACE THIS SO
	# THAT WE KNOW THE *EXACT* FIELD AND NOT JUST ONE WITH
	# THE SAME NAME
	if (sPreppedFields is an array) and (sPreppedFields[pFieldName] is not empty) then
		return tStr
	end if

	put "__TEMP_AMPERSANDS__" into tTemp
    
	# REPLACE ENTITIES TO TEMPORARY MARKERS SO THAT 
	# rigHtmlSpecialChars WON'T MESS THEM UP
	put "(&#\d+);" into tRegEx
    	put "__TEMP_AMPERSANDS__" into tReplacement
	put "&#" into tStrToReplaceInFoundStr
	# FUNCTION IN Common.lc
	put rigPregReplace(tStr, tRegEx, tStrToReplaceInFoundStr, tReplacement) into tStr

	put "(&\w+);" into tRegEx
	put "&" into tStrToReplaceInFoundStr
	put rigPregReplace(tStr, tRegEx, tStrToReplaceInFoundStr, tReplacement) into tStr

	# FUNCTION IN Common.lc
	put rigHtmlSpecialChars(tStr) into tStr

	# DECODE THE TEMP MARKERS BACK TO ENTITIES
	put "__TEMP_AMPERSANDS__" into tStrToReplaceInFoundStr
	put "(" & tStrToReplaceInFoundStr & "\d+);" into tRegEx
    	put "&#" into tReplacement
	put rigPregReplace(tStr, tRegEx, tStrToReplaceInFoundStr, tReplacement) into tStr

	put "__TEMP_AMPERSANDS__" into tStrToReplaceInFoundStr
	put "(" & tStrToReplaceInFoundStr & "\w+);" into tRegEx
    	put "&" into tReplacement
	put rigPregReplace(tStr, tRegEx, tStrToReplaceInFoundStr, tReplacement) into tStr

	if pFieldName is not empty then
		put tStr into sPreppedFields[pFieldName]
	end if

	return tStr
end rigFormPrep







/*----------------------------------------------------------------------
--| FUNCTION rigSetValue
--|
--| Author: rabit
--| Version:  1.3
--| Created: 29-07-09
--| Last Mod: 05-08-15
--| Requires: rigLibIsLoaded(), rigFormValidSetValue()
--|
--| Summary: Grabs a value from the POST array for the specified field so you can
--|            re-populate an input field or textarea.  If Form Validation
--|            is active it retrieves the info from the validation library.
--| 
--| Format:  rigSetValue(param1, param2)
--|
--| Parameters: string <pField>, mixed <pDefault>, bool <pHtmlEscape> whether to escape HTML tags
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSetValue pField pDefault pHtmlEscape
  local tHtmlEscape
  
	if pHtmlEscape is empty then
		put TRUE into tHtmlEscape
	else
		put pHtmlEscape into tHtmlEscape
	end if
  
	if rigLibIsLoaded("Formvalidation") is not TRUE then
		rigLoaderLoadLibrary "Formvalidation"
	end if

  if tHtmlEscape is FALSE then
    return rigFormValidSetValue(pField, pDefault)
  end if
  
	return rigFormPrep(rigFormValidSetValue(pField, pDefault), pField)
end rigSetValue







/*----------------------------------------------------------------------
--| FUNCTION rigSetSelect
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: rigSetSelectCheckboxRadio()
--|
--| Summary: Let's you set the selected value of a <select> menu via data in the POST array.
--|            If Form Validation is active it retrieves the info from the validation library.
--| 
--| Format:  rigSetSelect(param1, param2, param3)
--|
--| Parameters: string <pField>, string <pValue>, bool <pDefault>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSetSelect pField pValue pDefault
  local tStatusMarker, tElement
  
	put "selected" into tStatusMarker
	put "select" into tElement
	return rigSetSelectCheckboxRadio(pField, pValue, pDefault, tStatusMarker, tElement)
end rigSetSelect








/*----------------------------------------------------------------------
--| FUNCTION rigSetCheckbox
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-07-09
--| Last Mod: 29-07-09
--| Requires: rigSetSelectCheckboxRadio()
--|
--| Summary: Let's you set the selected value of a checkbox via the value in the POST array.
--|            If Form Validation is active it retrieves the info from the validation library.
--| 
--| Format:  rigSetCheckbox(param1, param2, param3)
--|
--| Parameters: string <pField>, string <pValue>, bool <pDefault>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSetCheckbox pField pValue pDefault
  local tStatusMarker, tElement
  
	put "checked" into tStatusMarker
	put "checkbox" into tElement
	return rigSetSelectCheckboxRadio(pField, pValue, pDefault, tStatusMarker, tElement)
end rigSetCheckbox








/*----------------------------------------------------------------------
--| FUNCTION rigSetRadio
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-07-09
--| Last Mod: 30-07-09
--| Requires: rigSetSelectCheckboxRadio()
--|
--| Summary: Let's you set the selected value of a radio field via info in the POST array.
--|            If Form Validation is active it retrieves the info from the validation library.
--| 
--| Format: rigSetRadio(param1, param2, param3)
--|
--| Parameters: string <pField>, string <pValue>, bool <pDefault>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSetRadio pField pValue pDefault
  local tStatusMarker, tElement
  
	put "checked" into tStatusMarker
	put "radio" into tElement
	return rigSetSelectCheckboxRadio(pField, pValue, pDefault, tStatusMarker, tElement)
end rigSetRadio







/*----------------------------------------------------------------------
--| FUNCTION rigSetSelectCheckboxRadio
--|
--| Author: rabit
--| Version:  1.3
--| Created: 30-07-09
--| Last Mod: 17-07-11
--| Requires: rigLibIsLoaded(), rigFormValidSetSelect(), rigFormValidSetCheckbox(), rigFormValidSetRadio()
--|
--| Summary: Helper function used by some of the form helpers.
--|                    Let's you set the selected value of a <select> menu, a checkbox and a radio field via info in the POST array.
--|                   If Form Validation is active it retrieves the info from the validation library.
--| 
--| Format:  rigSetSelectCheckboxRadio(param1, param2, param3, param4, param5)
--|
--| Parameters: string <pField>, string <pValue>, bool <pDefault>, string <pStatusMarker>, string <pElement>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSetSelectCheckboxRadio pField pValue pDefault pStatusMarker pElement
  local tField, tDefault, tFieldAsElementsList
  
	put pField into tField

	if pDefault is empty then
		put FALSE into tDefault
	else
		put pDefault into tDefault
	end if

	if rigLibIsLoaded("Formvalidation") is not TRUE then
		rigLoaderLoadLibrary "Formvalidation"

		# LIBRARY NOT LOADED
		/*
		if it is FALSE then
			if $_POST[tField] is empty then
				if ($_POST is not an array) and (tDefault is TRUE) then
					return " " & pStatusMarker & "=" & quote & pStatusMarker & quote
				end if
			end if
		
			return ""
		end if
		*/

		put $_POST[tField] into tField
		
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

	end if

	if pElement is "select" then
		return rigFormValidSetSelect(tField, pValue, tDefault)
	end if

	if pElement is "checkbox" then
		return rigFormValidSetCheckbox(tField, pValue, tDefault)
	end if

	if pElement is "radio" then
		return rigFormValidSetRadio(tField, pValue, tDefault)
	end if
end rigSetSelectCheckboxRadio








/*----------------------------------------------------------------------
--| FUNCTION rigFormError
--|
--| Author: rabit
--| Version:  1.1
--| Created: 30-07-09
--| Last Mod: 27-10-09
--| Requires: rigLibIsLoaded(), rigLoaderLoadLibrary, rigFormValidError()
--|
--| Summary: Returns the error for a specific form field.  This is a helper for the
--|            form validation library.
--| 
--| Format:  rigFormError(param1, param2, param3)
--|
--| Parameters: string <pField>, string <pPrefix>, string <pSuffix>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormError pField pPrefix pSuffix
	if rigLibIsLoaded("Formvalidation") is not TRUE then
		rigLoaderLoadLibrary "Formvalidation"

		# LIBRARAY NOT LOADED
		/*
		if it is FALSE then
			return ""
		end if
		*/
	end if

	return rigFormValidError(pField, pPrefix, pSuffix)
end rigFormError







/*----------------------------------------------------------------------
--| FUNCTION rigValidationErrors
--|
--| Author: rabit
--| Version:  1.1
--| Created: 30-07-09
--| Last Mod: 27-10-09
--| Requires: rigLibIsLoaded(), rigLoaderLoadLibrary, rigFormValidErrorString()
--|
--| Summary: Returns all the errors associated with a form submission.  This is a helper
--|            function for the form validation library.
--| 
--| Format:  rigValidationErrors(param1, param2)
--|
--| Parameters: string <pPrefix>, string <pSuffix>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigValidationErrors pPrefix pSuffix
	if rigLibIsLoaded("Formvalidation") is not TRUE then
		rigLoaderLoadLibrary "Formvalidation"

		# LIBRARAY NOT LOADED
		/*
		if it is FALSE then
			return ""
		end if
		*/
	end if

	return rigFormValidErrorString(pPrefix, pSuffix)
end rigValidationErrors







/*----------------------------------------------------------------------
--| FUNCTION _rigParseFormAttributes
--|
--| Author: rabit
--| Version:  1.1
--| Created: 29-07-09
--| Last Mod: 12-09-09
--| Requires: rigFormPrep()
--|
--| Summary: Helper function used by some of the form helpers.
--| 
--| Format:  _rigParseFormAttributes(param1, param2)
--|
--| Parameters: array <pAttributes>, array <pDefault>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigParseFormAttributes pAttributes pDefault
  local tDefault, tAttributesKeysList, tKey, tFoundLineNum, tRemainingAtts
  local tAtt, tVal
  
	put pDefault into tDefault
    
	set the wholematches to true
    
	if pAttributes is an array then
        
		put the keys of pAttributes into tAttributesKeysList
        
		# SET THE DEFAULT ATTRIBUTES TO THE VALUES OF pAttributes
		repeat for each key tKey in tDefault
            			
			if tKey is among the keys of pAttributes then
				put pAttributes[tKey] into tDefault[tKey]
                
				put lineoffset(tKey,tAttributesKeysList) into tFoundLineNum
				delete line tFoundLineNum of tAttributesKeysList
			end if
		end repeat
        
		# IF THERE ARE STILL ATTRIBUTES LEFT, MERGE THE
		# REMAINING ATTRIBUTES WITH THE DEFAULT ATTRIBUTES
		if the number of lines of tAttributesKeysList > 0 then
			repeat for each line thisLine in tAttributesKeysList
				put pAttributes[thisLine] into tRemainingAtts[thisLine]
			end repeat
            
			# MERGE LISTS
			combine tRemainingAtts using return and comma
			combine tDefault using return and comma
			put return & tRemainingAtts after tDefault
             
			#BUILD ARRAY AGAIN
			split tDefault using return and comma
		end if
        
    end if

	put "" into tAtt

	repeat for each key tKey in tDefault
		if tKey is "value" then
			put rigFormPrep(tDefault[tKey], tDefault["name"]) into tVal
		else
			put tDefault[tKey] into tVal
		end if

		put tKey & "=" & quote & tVal & quote & " " after tAtt
	end repeat

	return tAtt
end _rigParseFormAttributes





/*----------------------------------------------------------------------
--| FUNCTION _rigAttributesToString
--|
--| Author: rabit
--| Version:  1.1
--| Created: 28-07-09
--| Last Mod: 04-07-12
--| Requires: --
--|
--| Summary: Helper function used by some of the form helpers.
--| 
--| Format:  _rigAttributesToString(param1, param2)
--|
--| Parameters: mixed <pAttributes>, bool <pFormtag>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigAttributesToString pAttributes pFormtag
  local tAttributes, tFormtag, tCharset, tAtts
  
	put pAttributes into tAttributes
    
	if pFormtag is empty then
		put FALSE into tFormtag
	else
		put pFormtag into tFormtag
	end if
    
	if (tAttributes is not an array) and (the number of chars of tAttributes > 0) then
		if (pFormtag is TRUE) and ("method" is not in tAttributes) then
			put tAttributes && "method=" & quote & "post" & quote into tAttributes
		end if
		
		if (pFormtag is TRUE) and ("accept-charset" is not in tAttributes) then
			put rigConfigItem("charset") into tCharset
			if tCharset is empty then
				put "utf-8" into tCharset
			else
				put toLower(tCharset) into tCharset
			end if
			put tAttributes && "accept-charset=" & quote & tCharset & quote into tAttributes
		end if
        
		return " " & tAttributes
	end if
    
	if tAttributes is an array then
		put "" into tAtts
        
		if ("method" is not among the keys of tAttributes) and (pFormtag is TRUE) then
			put tAtts && "method=" & quote & "post" & quote into tAtts
		end if
		
		if ("accept-charset" is not among the keys of tAttributes) and (pFormtag is TRUE) then
			put rigConfigItem("charset") into tCharset
			if tCharset is empty then
				put "utf-8" into tCharset
			else
				put toLower(tCharset) into tCharset
			end if
			put tAtts && "accept-charset=" & quote & tCharset & quote into tAtts
		end if
        
		repeat for each key tKey in tAttributes
			put tAtts && tKey & "=" & quote & tAttributes[tKey] & quote into tAtts
		end repeat
         
		return tAtts
	end if
     
end _rigAttributesToString








--| END OF formHelper.livecodescript
--| Location:  ./system/helpers/formHelper.livecodescript
----------------------------------------------------------------------