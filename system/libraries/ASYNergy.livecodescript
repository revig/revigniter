script "ASYNergy"

##
# revIgniter
#
# An application development framework for LiveCode
# modeled on CodeIgniter.
#
# @package		revIgniter
# @author		  rabit@revigniter.com
# @copyright	Copyright (c) 2009 - 2023, Ralf Bitter
# @license		https://revigniter.com/userGuide/license.html
# @link		     https://revigniter.com
##

## ------------------------------------------------------------------------

##
# revIgniter ASYNergy Library
#
#
# @package			revIgniter
# @subpackage	Libraries
# @category	  	Libraries
# @requires			com.livecode.library.json
# @author		  	rabit@revigniter.com
# @link		    		https://revigniter.com/userGuide/libraries/asynergy.html
##

## ------------------------------------------------------------------------



global gRigA, g_ElapsedTime_, gData

local sSegA, sResponseSent, sStackInUse, sAJAXrequest, sPayloadA, sWorkingPldA, sMutablesDataA, sAccumulatedRespDataA , sFuncWhiteList = "abs,acos,annuity,arithmeticmean,asin,atan,atan2,average,averagedeviation,avg,avgdev,base64decode,base64encode,baseconvert,binarydecode,binaryencode,byteoffset,bytetonum,ceil,ceiling,chartonum,codepointoffset,codepointproperty,codepointtonum,codeunitoffset,colornames,compound,cos,date,dateformat,exp,exp1,exp10,exp2,floor,format,geometricmean,harmonicmean,isnumber,isotomac,itemoffset,len,length,lineoffset,ln,ln1,log10,log2,lower,mactoiso,matchchunk,matchtext,max,md5digest,mean,median,merge,mergMarkdownToXHTML,messagedigest,millisec,millisecond,milliseconds,millisecs,min,monthnames,nativechartonum,normalizetext,numtobyte,numtochar,numtocodepoint,numtonativechar,offset,paragraphoffset,popstddev,populationstandarddeviation,populationvariance,popvariance,random,randombytes,replacetext,round,sec,seconds,secs,sentenceoffset,sha1digest,sin,sqrt,standarddeviation,statround,stddev,sum,tan,textdecode,textencode,tick,ticks,time,tokenoffset,tolower,toupper,truewordoffset,trunc,unidecode,uniencode,upper,urldecode,urlencode,uuid,variance,weekdaynames,wordoffset"





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2022-05-26
 --| Last Mod: --
 --| Requires: rigLogMessage, _rigSetDefaultValues
 --|
 --| Summary:  Run security check and run initial handler.
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
        rigLogMessage "debug", "ASYNergy Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
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
--| Version:  1.1
--| Created: 2022-05-26
--| Last Mod: 2023-05-21
--| Requires: rigGetHTTPheader(), _rigAsynInitHelper, _rigAsynStoreCSS,
--|           _rigAsynStoreScript, _rigAsynPayload(), rigLogMessage
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
  put  rigGetHTTPheader("X-ASYNergy") into sAJAXrequest

  _rigAsynInitHelper
  
  # WE ONLY NEED THE CSS AND THE JS IF THERE IS NO XMLHttpRequest
  if sAJAXrequest <> TRUE then
    put FALSE into sAJAXrequest
    _rigAsynStoreCSS
    _rigAsynStoreScript
      
  else -- if sAJAXrequest <> TRUE
    put _rigAsynPayload() into sWorkingPldA

    if sWorkingPldA is FALSE then
      rigLogMessage "error", "Error on processing the ASYNergy payload."

    end if -- if sWorkingPldA is FALSE
  end if -- if sAJAXrequest <> TRUE
end _rigSetDefaultValues




/*----------------------------------------------------------------------
--| COMMAND rigRunInitialAsynergyConfig
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2022-05-26
--| Last Mod: --
--| Requires: --
--|
--| Summary: Run initial configuration procedures. Don't remove, even if it does nothing.
--|
--| Format:  rigRunInitialAsynergyConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialAsynergyConfig pConfig

end rigRunInitialAsynergyConfig




/*----------------------------------------------------------------------
--| COMMAND _rigAsynInitHelper
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-07-11
--| Last Mod: --
--| Requires: rigLoadHelper, rigLoadExtension
--|
--| Summary: Load the LiveCode Builder JSON library and the asset helper.
--|
--| Format:  _rigAsynInitHelper
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigAsynInitHelper
  # IF THERE IS NO XMLHttpRequest WE DON'T NEED THE JSON EXTENSION
  # IF THERE IS A XMLHttpRequest WE DON'T NEED THE ASSET HELPER
  if sAJAXrequest <> TRUE then
    rigLoadHelper "asset"
  else
    rigLoadExtension "com.livecode.library.json"
  end if
end _rigAsynInitHelper




/*----------------------------------------------------------------------
--| FUNCTION _rigAsynPayload
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2022-05-26
--| Last Mod: 2023-05-21
--| Requires: rigVarPost(), _rigAsynModelValueMod()
--| 
--| Summary: Return ASYNergy JSON data as array
--| 
--| Format:  _rigAsynPayload()
--|
--| Parameters: --
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigAsynPayload
  local tKey, tPayload, tWorkingPldA, tLCfunc
  
  # A PERCENT SIGN IN THE PAYLOAD MAY PRODUCE ZERO ("<NUL>") CHARACTERS
  # WHICH ARE GENERATED WHILE URL DECODING THE PAYLOAD IN rigXssClean()
  # IF ONE OF THE CHARACTERS AFTER "%" IS NOT A HEXADECIMAL DIGIT.
  # THIS WOULD LEAD TO AN ERROR IN JsonImport.
  # SO PRIOR TO XSS CLEANING WE OBSCURE THE PERCENT SIGN AND
  # INSERT IT AFTERWARDS AGAIN.
  replace "%" with "]![" in $_POST
  put rigVarPost("asynPayload", TRUE) into tPayload
  replace "]![" with "%" in tPayload

  if tPayload <> FALSE then
    try
      put textDecode(tPayload, "ASCII") into tPayload
      put JsonImport(tPayload) into sPayloadA
    catch e
      rigLogMessage "error", "ASYNergy JsonImport error!"
      
      return FALSE
    end try

    put sPayloadA into tWorkingPldA

    # DE-NEST THE PAYLOAD ARRAY SO THAT IT IS EASIER TO WORK WITH
    # modelData
    if the number of lines in the keys of tWorkingPldA["modelData"] > 0 then
      put tWorkingPldA["modelData"]["modelVal"] into tWorkingPldA[tWorkingPldA["modelData"]["modelAttrVal"]]

      put tWorkingPldA["modelData"]["modelParams"] into tWorkingPldA["params"]
     
      # CALL THE FUNCTION SPECIFIED IN THE VALUE OF THE asyn:mutable ATTRIBUTE
      put tWorkingPldA["mutablesData"][1]["lcFunc"] into tLCfunc

      if tLCfunc <> empty then
        if (tLCfunc is among the items of sFuncWhiteList) and (tWorkingPldA["modelData"]["modelVal"] <> empty) then
          put _rigAsynModelValueMod(tLCfunc, tWorkingPldA["modelData"]["modelVal"]) into tWorkingPldA[tWorkingPldA["modelData"]["modelAttrVal"]]

        else
          put "Function not available!" into tWorkingPldA["modelAttrVal"]
        end if -- if tLCfunc is among the items of sFuncWhiteList
      end if -- if tLCfunc <> empty
      
    end if -- if the number of lines in the keys of tWorkingPldA["modelData"] > 0
    
    # mutablesData
    put tWorkingPldA["mutablesData"] into sMutablesDataA
    #
   
    # deferredModelData
    if the number of lines in the keys of tWorkingPldA["deferredModelData"] > 0 then
      repeat for each key tKey in tWorkingPldA["deferredModelData"]
        put tWorkingPldA["deferredModelData"][tKey] into tWorkingPldA[tKey]
      end repeat
    end if -- if the number of lines in the keys of tWorkingPldA["modelData"] > 0
    #

    # transmissionElsData
    if the number of lines in the keys of tWorkingPldA["transmissionElsData"] > 0 then
      repeat for each key tKey in tWorkingPldA["transmissionElsData"]
        put tWorkingPldA["transmissionElsData"][tKey] into tWorkingPldA[tKey]
      end repeat
    end if -- if the number of lines in the keys of tWorkingPldA["transmissionElsData"] > 0
    #

  else
    return tPayload
  end if -- if tPayload <> FALSE
  
  return tWorkingPldA
end _rigAsynPayload





/*----------------------------------------------------------------------
--| COMMAND rigAsynRespond
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2022-11-07
--| Last Mod: --
--| Requires: rigElapsedTime()
--|
--| Summary: Prepare ASYNergy response and send JSON data to the client.
--| 
--| Format:  rigAsynRespond param1[, param2][, param3][, param4]
--|
--| Parameters: mixed <pRespData>,
--|               mixed <pSyncModelID> model(s) (identified by it's id) to be synced
--|               with the mutable element (optional),
--|               mixed <pMutableID> mutable element(s) (identified by it's id)
--|               to be updated, needed in case there are multiple mutable elements
--|               having the same mutable attribute value (optional),
--|               mixed <pMutableAttrVal> mutable element(s) identified by it's mutable
--|               attribute value (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigAsynRespond pRespData pSyncModelID pMutableID pMutableAttrVal
  local tParamsA, tKey, tWord, tModelAttrValue
  local tResponseA, tRespKey, tMutableAttrVal = ""
  
  if pRespData is not an array then
    put pRespData into tParamsA[1]["mutableVal"]
    put pSyncModelID into tParamsA[1]["syncModelID"]
    put pMutableID into tParamsA[1]["mutableID"]
    put pMutableAttrVal into tParamsA[1]["mutableAttrVal"]
  else
    if line 1 of the keys of pRespData is a number then
      put pRespData into tParamsA
    else
      repeat for each key tRDkey in pRespData
        put pRespData[tRDkey] into tParamsA[1][tRDkey]
      end repeat
    end if
  end if -- if pRespData is not an array

  # DON'T RESPOND TWICE
  if sResponseSent <> TRUE then

    repeat for each key tKey in tParamsA
      if "{{g_ElapsedTime_}}" is in tParamsA[tKey]["mutableVal"] then
        replace "{{g_ElapsedTime_}}" with "[[g_ElapsedTime_]]" in tParamsA[tKey]["mutableVal"]
      end if

      # CHECK FOR MODEL ATTRIBUTE VALUES IN RESPONSE DATA
      if "{{" is in tParamsA[tKey]["mutableVal"] then
        repeat for each word tWord in tParamsA[tKey]["mutableVal"]
          if matchText(tWord, "{{.+}}") then
            # REGEX FOR {{g_<VARNAME>_}} -> {{(?!g_).+(?<!_)}}
            put char 3 to -3 of tWord into tModelAttrValue
            replace "{{" & tModelAttrValue & "}}" with sWorkingPldA[tModelAttrValue] in tParamsA[tKey]["mutableVal"]
          end if
        end repeat
      end if -- if "{{" is in tParamsA[tKey]["mutableVal"]
      #

      put tParamsA[tKey]["mutableVal"] into tResponseA["asynergyResponse"][tKey]["mutableVal"]
  
      put tParamsA[tKey]["syncModelID"] into tResponseA["asynergyResponse"][tKey]["syncModelID"]

      put tParamsA[tKey]["mutableID"] into tResponseA["asynergyResponse"][tKey]["mutableID"]

      if tParamsA[tKey]["mutableAttrVal"] <> empty then
        put tParamsA[tKey]["mutableAttrVal"] into tMutableAttrVal
      end if

      put tMutableAttrVal into tResponseA["asynergyResponse"][tKey]["mutableAttrVal"]
      #
    end repeat
    
    repeat for each key tRespKey in tResponseA["asynergyResponse"]
      if "[[g_ElapsedTime_]]" is in tResponseA["asynergyResponse"][tRespKey]["mutableVal"] then
        put rigElapsedTime("totalExecutionTime_start", , 4) into g_ElapsedTime_
        put merge(tResponseA["asynergyResponse"][tRespKey]["mutableVal"]) into tResponseA["asynergyResponse"][tRespKey]["mutableVal"]
      end if
    end repeat
    
    _rigAsynRespond tResponseA

  end if -- if sResponseSent <> TRUE
end rigAsynRespond




/*----------------------------------------------------------------------
--| FUNCTION rigAsynElemData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2022-11-09
--| Last Mod: --
--| Requires: --
--|
--| Summary: Get the value/text/html of an element specified by the elements's attribute value.
--|            If dealing with select elements this function returns an array.
--| 
--| Format:  rigAsynElemData(params1)
--|
--| Parameters: string <pAttrVal> the attribute value of the element
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigAsynElemData pAttrVal
  return sWorkingPldA[pAttrVal]
end rigAsynElemData




/*----------------------------------------------------------------------
--| FUNCTION rigAsynParams
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2022-11-13
--| Last Mod: 2023-05-21
--| Requires: _rigAsynModelValueMod
--|
--| Summary: Return model parameters as array.
--| 
--| Format:  rigAsynParams([params])
--|
--| Parameters: integers <params> the model parameter keys of values
--|               to which a LC function should be applied (optional)
--|
--| Return: array
----------------------------------------------------------------------*/

function rigAsynParams
  local tFunc, tParam, tLCfuncParamsKeys

  if the paramCount <> 0 then
    put sWorkingPldA["mutablesData"][1]["lcFunc"] into tFunc
    
    if tFunc <> empty then

      repeat with tParam = 1 to the paramCount
        put param(tParam) & comma after tLCfuncParamsKeys
      end repeat
      delete char -1 of tLCfuncParamsKeys

      return _rigAsynModelValueMod(tFunc, sWorkingPldA["params"], tLCfuncParamsKeys)
    end if
  end if

  return sWorkingPldA["params"]
end rigAsynParams




/*----------------------------------------------------------------------
--| FUNCTION rigAsynPayload
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2023-03-07
--| Last Mod: --
--| Requires: --
--|
--| Summary: Retrieve elements of the payload array.
--| 
--| Format:  rigAsynPayload([param1][, param2])
--|
--| Parameters: string <pKey1> (optional), string <pKey2 (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigAsynPayload
  switch the paramCount
    case 1
      put param(1) into tKey
      return sWorkingPldA[tKey]

    break
    case 2
      put param(1) into tKey1
      put param(2) into tKey2
      return sWorkingPldA[tKey1][tKey2]

    default
    return sWorkingPldA
  end switch
end rigAsynPayload




/*----------------------------------------------------------------------
--| FUNCTION _rigAsynModelValueMod
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2022-08-27
--| Last Mod: 2023-05-21
--| Requires: _rigAsynRunFunc()
--|
--| Summary: Run an arbitrary function on a model value or a model param value,
--|            used to generate the content for the mutable element.
--| 
--| Format:  _rigAsynModelValueMod(param1, param2[, param3])
--|
--| Parameters: string <pFunc>, mixed <pValue>, string <pLCfuncParamsKey> comma separated
--|               list of model parameter array keys (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigAsynModelValueMod pFunc pValue pLCfuncParamsKeys
  local tStatement, tResult

  if pValue is an array then
    repeat for each key tKey in pValue
      
      if tKey is among the items of pLCfuncParamsKeys then
        put _rigAsynRunFunc(pFunc, pValue[tKey]) into tResult[tKey]
      else
        put pValue[tKey] into tResult[tKey]
      end if
      
    end repeat

  else
    put _rigAsynRunFunc(pFunc, pValue) into tResult
  end if -- if pValue is an array

  return tResult
end _rigAsynModelValueMod




/*----------------------------------------------------------------------
--| FUNCTION _rigAsynRunFunc
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2023-03-06
--| Last Mod: --
--| Requires: --
--|
--| Summary: Run an arbitrary function on a model value or a model param value,
--|            used to generate the content for the mutable element.
--| 
--| Format:  _rigAsynRunFunc(param1, param2)
--|
--| Parameters: string <pFunc>, string <pValue>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigAsynRunFunc pFunc pValue
  local tStatement, tResult

  put ("put" && pFunc & "(" & quote & pValue & quote & ") into tResult") into tStatement
  try
    do tStatement
  catch e
    put "ERROR" into tResult
  end try

  return tResult
end _rigAsynRunFunc




/*----------------------------------------------------------------------
--| FUNCTION rigAsynValidateInput
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2023-03-28
--| Last Mod: --
--| Requires: Formvalidation.livecodescript, rigAsynElemData(), rigFormValidRun(), rigFormError()
--|
--| Summary: Validate user input data using the form validation library.
--| 
--| Format:  rigAsynValidateInput(param1[, param2][, param3])
--|
--| Parameters: mixed <pModelAttrVal>, array <pTransmittedElA> attribut names and values
--|               included in JavaScript object "transmissionElsData" (optional),
--|               string <pRuleGroup> the name of the validation group (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigAsynValidateInput pModelAttrVal pTransmittedElA pRuleGroup
  local tValidationA, tAttrVal, tTransmElAttr
  local tError, tKey, tErrorStr, tErrorA
  
  if pRuleGroup is empty then
    put gRigA["controller"] into pRuleGroup
  end if
  
  # USER INPUT TO BE VALIDATED
  if (pModelAttrVal is not an array) and (comma is not in pModelAttrVal) then
    put rigAsynElemData(pModelAttrVal) into tValidationA[pModelAttrVal]
    
  else if comma is in pModelAttrVal then
    repeat for each item tAttrVal in pModelAttrVal
      put rigAsynElemData(tAttrVal) into tValidationA[tAttrVal]
    end repeat
    put tValidationA into pModelAttrVal

  else
    put pModelAttrVal into tValidationA
  end if -- if pModelAttrVal is not an array
  
  # ARE THERE ADDITIONAL TRANSMITTED NAME VALUE PAIRS?
  if pTransmittedElA is an array then
    if the number of lines in the keys of pTransmittedElA is 1 then
      put the keys of pTransmittedElA into tTransmElAttr
    end if
    
    union tValidationA with pTransmittedElA
  end if
  ##

  # SPECIFY THE RULE GROUP WITH THE FIRST PARAMETER, OTHERWISE
  # THE NAME OF THE RULE GROUP WILL BE AUTOMATICALLY COMPOSED
  # OF THE CONTROLLER NAME AND THE RESPECTIVE HANDLER NAME
  # LIKE FOR EXAMPLE asynRegister/email.
  if rigFormValidRun(pRuleGroup, tValidationA) is FALSE then
    if pModelAttrVal is not an array then
      put rigFormError(pModelAttrVal) into tError

      if (tError is empty) and (tTransmElAttr <> empty) then
        put rigFormError(tTransmElAttr) into tError
      end if

    else
      repeat for each key tKey in tValidationA
        put rigFormError(tKey) into tErrorStr
        if tErrorStr <> empty then
          put rigFormError(tKey) into tError[tKey]
        end if
      end repeat
      
    end if -- if pModelAttrVal is not an array
  end if

  # REMOVE DEFAULT PARAGRAPH TAG
  if tError is not an array then
    if tError <> empty then
      put char 4 to -5 of tError into tError
    end if

  else
      
    # GENERATE ERROR RESPONSE DATA
    repeat for each key tErrorKey in tError
      # REMOVE PARAGRAPH TAGS
      put char 4 to -5 of tError[tErrorKey] into tError[tErrorKey]
        
      repeat for each key tKey in sMutablesDataA
        if (sMutablesDataA[tKey]["id"] is tErrorKey) or (sMutablesDataA[tKey]["mutableAttrVal"] is tErrorKey) then
          put sMutablesDataA[tKey]["id"] into tErrorA[tKey]["mutableID"]
          put sMutablesDataA[tKey]["syncModelID"] into tErrorA[tKey]["syncModelID"]
          put tError[tErrorKey] into tErrorA[tKey]["mutableVal"]
          put sMutablesDataA[tKey]["mutableAttrVal"] into tErrorA[tKey]["mutableAttrVal"]
        end if
      end repeat
    end repeat
    
    return tErrorA
    #
  end if -- if tError is not an array

  return tError
end rigAsynValidateInput




/*----------------------------------------------------------------------
--| COMMAND rigAsynNavigate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2023-04-01
--| Last Mod: --
--| Requires: URL helper, rigASiteURL(), _rigAsynRespond
--|
--| Summary: Navigate to another page.
--| 
--| Format:  rigAsynNavigate param
--|
--| Parameters: string <pSegments>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigAsynNavigate pSegments
  local tResponseA
  
  # DON'T RESPOND TWICE, THIS CAN HAPPEN IF HOOK HYDRATE IS USED
  if (sResponseSent <> TRUE) and (pSegments <> empty) then
    rigLoadHelper "url"
    
    put rigASiteURL(pSegments) into tResponseA["asynergyResponse"][1]["url"]
    
    _rigAsynRespond tResponseA
  end if
end rigAsynNavigate




/*----------------------------------------------------------------------
--| COMMAND _rigAsynRespond
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2023-04-01
--| Last Mod: --
--| Requires: --
--|
--| Summary: Send JSON response.
--| 
--| Format:  _rigAsynRespond param
--|
--| Parameters: array <pResponseA>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigAsynRespond pResponseA
  # rigSetHeader DOES NOT WORK WITH AJAX, USE: put header ...
  -- rigSetHeader "Content-type: application/json"
  put header "Content-type: application/json; charset=UTF-8"

  put TRUE into sResponseSent
  
  # AND AWAY WE GO...
  put textEncode(JsonExport(pResponseA), "UTF-8")
end _rigAsynRespond




/*----------------------------------------------------------------------
--| FUNCTION rigAsynAddResponseData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2023-04-03
--| Last Mod: 2023-04-03
--| Requires: --
--|
--| Summary: Accumulate response data.
--| 
--| Format:  rigAsynAddResponseData(param1[, param2][, param3][, param4])
--|
--| Parameters: string <pRespData>,
--|               mixed <pSyncModelID> model(s) (identified by it's id) to be synced
--|               with the mutable element (optional),
--|               mixed <pMutableID> mutable element(s) (identified by it's id)
--|               to be updated, needed in case there are multiple mutable elements
--|               having the same mutable attribute value (optional),
--|               mixed <pMutableAttrVal> mutable element(s) identified by it's mutable
--|               attribute value (optional) 
--|
--| Return: array
----------------------------------------------------------------------*/

function rigAsynAddResponseData pRespData pSyncModelID pMutableID pMutableAttrVal
  local tKey
  
  put (the number of lines in the keys of sAccumulatedRespDataA) + 1 into tKey

  put pRespData into sAccumulatedRespDataA[tKey]["mutableVal"]
  put pSyncModelID into sAccumulatedRespDataA[tKey]["syncModelID"]
  put pMutableID into sAccumulatedRespDataA[tKey]["mutableID"]
  put pMutableAttrVal into sAccumulatedRespDataA[tKey]["mutableAttrVal"]
  
  return sAccumulatedRespDataA
end rigAsynAddResponseData




/*----------------------------------------------------------------------
--| COMMAND _rigAsynStoreCSS
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2022-07-26
--| Last Mod: --
--| Requires: --
--|
--| Summary: Store the ASYNergy Stylesheet in the gData asynergyStyles variable.
--| 
--| Format:  _rigAsynStoreCSS
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigAsynStoreCSS
  local tStyleTag

  if "Contentsecuritypolicy" is among the lines of the stacksInUse then
    put "<style {{g_StyleNonce_}}>" into tStyleTag
  else
  	put "<style>" into tStyleTag
  end if
  
  put tStyleTag & return & \
  "[asyn\:loading], [asyn\:loading\.delay], [asyn\:loading\.inline-block], [asyn\:loading\.inline], [asyn\:loading\.block], [asyn\:loading\.flex], [asyn\:loading\.table], [asyn\:loading\.grid], [asyn\:loading\.inline-flex] {" & return & \
  "display: none;" & return & \
  "}" & return & \
  "[asyn\:loading\.delay\.shortest], [asyn\:loading\.delay\.shorter], [asyn\:loading\.delay\.short], [asyn\:loading\.delay\.long], [asyn\:loading\.delay\.longer], [asyn\:loading\.delay\.longest] {" & return & \
  "display:none;" & return & \
  "}" & return & \
  "[asyn\:offline] {" & return & \
  "display: none;" & return & \
  "}" & return & \
  "[asyn\:dirty]:not(textarea):not(input):not(select) {" & return & \
  "display: none;" & return & \
  "}" & return & \
  "input:-webkit-autofill, select:-webkit-autofill, textarea:-webkit-autofill {" & return & \
  "animation-duration: 50000s;" & return & \
  "animation-name: asynergyAutofill;" & return & \
  "}" & return & \
  "@keyframes asynergyAutofill { from {} }" & return & \
  "</style>" into gData["asynergyStyles"]
end _rigAsynStoreCSS




/*----------------------------------------------------------------------
--| COMMAND _rigAsynStoreScript
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2022-08-23
--| Last Mod: --
--| Requires: rigJsAsset()
--|
--| Summary: Store the ASYNergy Javascript in the asynergyScript gData variable.
--| 
--| Format:  _rigAsynStoreScript
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigAsynStoreScript
  local tNonce, tControllerURL
    
  put rigJsAsset("asynergy.js", "ASYNergy") & return into gData["asynergyScript"]
  
  if "Contentsecuritypolicy" is among the lines of the stacksInUse then
    put " {{g_ScriptNonce_}}" into tNonce
  end if

  -- put rigSiteURL() & gRigA["controller"] into tControllerURL ------------------- temp test
  put rigSiteURL() & rigFetchSegment(1) into tControllerURL
  -- put rigSiteURL() & rigFetchRsegment(1) into tControllerURL ------------------- temp test

  put "<script" & tNonce & ">window.ASYNergy=new ASYNergy,document.addEventListener(" & quote & \
  "DOMContentLoaded" & quote & ",(function(){window.ASYNergy.theURL =" && quote & tControllerURL & quote & \
  ";window.ASYNergy.start();}));</script>" after gData["asynergyScript"]
end _rigAsynStoreScript




/*----------------------------------------------------------------------
--| FUNCTION rigIsAsynRequest
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2023-03-26
--| Last Mod: 2023-03-26
--| Requires: --
--|
--| Summary: Return true or false depending on whether the request was an ASYNergy request.
--| 
--| Format:  rigIsAsynRequest()
--|
--| Parameters: --
--|
--| Return: boolean
----------------------------------------------------------------------*/

function rigIsAsynRequest
  return sAJAXrequest
end rigIsAsynRequest




/*----------------------------------------------------------------------
--| FUNCTION rigAsynGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2022-05-26
--| Last Mod: --
--| Requires: --
--|
--| Summary: Get payload array variable values.
--|
--| Format:  rigAsynGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigAsynGet pWhat
  if pWhat is among the keys of sWorkingPldA then
    return sWorkingPldA[pWhat]
  end if

  return empty
end rigAsynGet




/*----------------------------------------------------------------------
--| COMMAND rigAsynSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2022-05-26
--| Last Mod: --
--| Requires: --
--|
--| Summary: Setter for payload array variables.
--|
--| Format:  rigAsynSet param1, param2
--|
--| Parameters: string <pKey> sEncryptA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigAsynSet pKey pVal
  if pKey is among the keys of sWorkingPldA then
    put pVal into sWorkingPldA[pKey]
  end if
end rigAsynSet




--| END OF ASYNergy.livecodescript
--| Location:  ./system/libraries/ASYNergy.livecodescript
----------------------------------------------------------------------