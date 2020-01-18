script "Captcha"

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
# revIgniter Captcha Library
#
# This library enables you to display a barrier-free captcha in the form of digits
# composed of non breaking spaces.
#
# revIgniter version of two php classes written by Rene Schmidt (rene@reneschmidt.de)
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Libraries
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/captcha.html
##


global gRigA

local sCaptchaA, sNum, sBits, sBitmasks, sMatrix, sNumberMatrix
local sCaptchaStyle, sMathRandomLimit, sStackInUse





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
        rigLogMessage "debug", "Captcha Library Loaded"
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
  put 0 into sNum
  put 4 into sCaptchaA["captchaLength"]
  put "#000000" into sCaptchaA["captchaColor"]
  put "#FFFFFF" into sCaptchaA["captchaBckgndColor"]
  put "" into sCaptchaA["captchaHashKey"]

  put 10 into sMathRandomLimit				-- used by rigCaptchaMathProblem

  # 15 BITS FOR A MATRIX OF 5 ROWS AND 3 COLUMNS
  put "1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384" into sBits
  split sBits using comma

  # FOLLOWING THE CALCULATED BITMASKS FOR DIGITS 0 TO 9 IN DECIMAL NOTATION
  put "31599,18740,29607,31143,18921,31183,31695,18855,31727,31215" into sBitmasks
  split sBitmasks using comma

  # BUILD DIGIT MATRIX PROTOTYPE
  # w MEANS: ASSIGN CAPTCHA BACKGROUND COLOR TO SPECIFIED CELLS
  put "w" into sMatrix[1][1]
  put "w" into sMatrix[1][2]
  put "w" into sMatrix[1][3]
  put "w" into sMatrix[2][1]
  put "w" into sMatrix[2][2]
  put "w" into sMatrix[2][3]
  put "w" into sMatrix[3][1]
  put "w" into sMatrix[3][2]
  put "w" into sMatrix[3][3]
  put "w" into sMatrix[4][1]
  put "w" into sMatrix[4][2]
  put "w" into sMatrix[4][3]
  put "w" into sMatrix[5][1]
  put "w" into sMatrix[5][2]
  put "w" into sMatrix[5][3]
end _rigSetDefaultValues






/*----------------------------------------------------------------------
--| COMMAND rigRunInitialCaptchaConfig
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-11-09
--| Last Mod: 07-11-09
--| Requires: rigInitCaptcha
--|
--| Summary: Run initial configuration procedures.
--| 
--| Format:  rigRunInitialCaptchaConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialCaptchaConfig pConfig
	rigInitCaptcha
end rigRunInitialCaptchaConfig







/*----------------------------------------------------------------------
--| COMMAND rigInitCaptcha
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-10-09
--| Last Mod: 19-10-09
--| Requires: rigFetchConfigItem()
--|
--| Summary: Set initial values whenever the library is loaded.
--| 
--| Format:  rigInitCaptcha param1
--|
--| Parameters: array <pParams>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigInitCaptcha pParams
  local tSettingNames
  
	# SET ALL THE SESSION PREFERENCES, WHICH CAN EITHER BE SET
	# MANUALLY VIA THE pParams ARRAY ABOVE OR VIA THE CONFIG FILE
	put "captchaLength,captchaColor,captchaBckgndColor,captchaHashKey" into tSettingNames

	repeat for each item thisItem in tSettingNames
		if pParams[thisItem] is empty then
			put rigFetchConfigItem(thisItem) into sCaptchaA[thisItem]
    		else
			put pParams[thisItem] into sCaptchaA[thisItem]
    		end if
	end repeat

	put "<style type=" & quote & "text/css" & quote & "> " & return & ".b { color: black; background-color: " & sCaptchaA["captchaColor"] & "; }" & return & \
	".w { color: white; background-color: " & sCaptchaA["captchaBckgndColor"] & "; }" & return & "</style>" into sCaptchaStyle
end rigInitCaptcha









/*----------------------------------------------------------------------
--| FUNCTION rigCaptcha
--|
--| Author: rabit
--| Version:  1.1
--| Created: 19-10-09
--| Last Mod: 07-05-11
--| Requires: _rigRandomCaptchaNum(), _rigSetCaptchaNumberMatrix, rigCaptchaCode()
--|
--| Summary: Call this function to get a captcha.
--| 
--| Format:  rigCaptcha(param1, param2)
--|
--| Parameters: integer <pDigit> use this parameter if you prefer to generate
--|               the captcha number yourself, boolean <pReturnCaptchaCode> in case you don't
--|               intend to display the captcha code set this parameter to FALSE
--|
--| Return: string
----------------------------------------------------------------------*/

function rigCaptcha pDigit pReturnCaptchaCode
	if pDigit <> empty then
		# USE SENT NUMBER
		put pDigit into sNum
	else
		# GET RANDOM NUMBER
		put _rigRandomCaptchaNum() into sNum
	end if

	if (pReturnCaptchaCode is empty) or (pReturnCaptchaCode is TRUE) then
		# BUILD MATRIX OF NUMBER
		_rigSetCaptchaNumberMatrix sNum
	
		# RETURN CAPTCHA HTML DATA
		return rigCaptchaCode()
	end if
	
	return "noCaptchaCodeGenerated"
end rigCaptcha





/*----------------------------------------------------------------------
--| FUNCTION rigCaptchaMathProblem
--|
--| Author: Ralf Bitter
--| Version:  1.0
--| Created: 06-05-2011
--| Last Mod: 06-05-2011
--| Requires: --
--|
--| Summary: Call this function to generate a captcha math problem.
--| 
--| Format:  rigCaptchaMathProblem(param1)
--|
--| Parameters: integer <pNumOperators> number of operators to be used
--|
--| Return: string
----------------------------------------------------------------------*/

function rigCaptchaMathProblem pNumOperators
  local tOperand1, tOperand2, tNum1, tNum2, tOperatorID, tDividend
  local tMathstring, tResult
  
	# BUILD RANDOM EXCERCISE
	put random(sMathRandomLimit) into tOperand1
	put random(sMathRandomLimit) into tOperand2

	put max(tOperand1, tOperand2) into tNum1
	put min(tOperand1, tOperand2) into tNum2

	if (pNumOperators is empty) or (pNumOperators <> 2) then
		put random(4) into tOperatorID

		if tOperatorID = 1 then
			put tOperand1 * tOperand2 into tDividend
			put tDividend && "/" && tNum2 into tMathstring
			put tNum1 into tResult

		else if tOperatorID = 2 then
			put tOperand1 && "x" && tOperand2 into tMathstring
			put tOperand1 * tOperand2 into tResult
		else if tOperatorID = 3 then

			put tNum1 && "-" && tNum2 into tMathstring
			put tNum1 - tNum2 into tResult
		else
			put tOperand1 && "+" && tOperand2 into tMathstring
			put tOperand1 + tOperand2 into tResult
		end if

	else
		put random(2) into tOperatorID
		if tOperatorID = 1 then

			put tNum1 && "-" && tNum2 into tMathstring
			put tNum1 - tNum2 into tResult
		else
			put tOperand1 && "+" && tOperand2 into tMathstring
			put tOperand1 + tOperand2 into tResult
		end if
	end if

	put tResult into sNum
	
	return tMathstring
end rigCaptchaMathProblem





/*----------------------------------------------------------------------
--| COMMAND _rigSetCaptchaMatrix
--|
--| Author: rabit
--| Version:  1.1
--| Created: 19-10-09
--| Last Mod: 21-10-14
--| Requires: --
--|
--| Summary: Build captcha matrix (array) for a digit.
--| 
--| Format:  _rigSetCaptchaMatrix param1
--|
--| Parameters: integer <pDigit>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetCaptchaMatrix pDigit
  local tArrayItem, tBitmask, tBitsCount, tBitsset, tDigitKey
  
	if pDigit is an integer then
		if (pDigit >= 0) and (pDigit <= 9) then
			put pDigit + 1 into tArrayItem
		else
			put 1 into tArrayItem
		end if
	else
		put 1 into tArrayItem
	end if

	# GET RELATED BITMASK
	put sBitmasks[tArrayItem] into tBitmask

	put the number of lines in the keys of sBits into tBitsCount
	repeat with i = 1 to tBitsCount
		# IF CORRESPONDING BITS ARE BOTH 1 WE SAVE THE DECIMAL VALUE
		# IN A COMMA DELIMITED LIST FOR LATER USER
		if (tBitmask bitAnd sBits[i]) <> 0 then
			put sBits[i] & comma after tBitsset
		end if
	end repeat
	delete char -1 of tBitsset

	# CHECK IF THIS IS THE FIRST DIGIT
	if sNumberMatrix is not an array then
		put 1 into tDigitKey
	else
		put (the number of lines in the keys of sNumberMatrix) + 1 into tDigitKey		
	end if

	# GET THE MATRIX PROTOTYPE
	put sMatrix into sNumberMatrix[tDigitKey]

	# STORE THE DIGIT MATRIX IN THE NUMBER MATRIX
	repeat for each key tRow in sNumberMatrix[tDigitKey]
		repeat for each key tCellnr in sNumberMatrix[tDigitKey][tRow]
			if (2 ^ ((tRow - 1) * 3 + (tCellnr - 1))) is among the items of tBitsset then
				put "b" into sNumberMatrix[tDigitKey][tRow][tCellnr]
			end if
		end repeat
	end repeat	
end _rigSetCaptchaMatrix







/*----------------------------------------------------------------------
--| COMMAND _rigSetCaptchaNumberMatrix
--|
--| Author: rabit
--| Version:  1.1
--| Created: 19-10-09
--| Last Mod: 21-03-14
--| Requires: _rigSetCaptchaMatrix
--|
--| Summary: Build captcha matrix (array) for a number.
--| 
--| Format:  _rigSetCaptchaNumberMatrix param1
--|
--| Parameters: integer <pNum>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetCaptchaNumberMatrix pNum
	if pNum is not empty then
		put pNum into sNum
	end if

	repeat for each char tDigit in sNum
		_rigSetCaptchaMatrix tDigit
	end repeat
end _rigSetCaptchaNumberMatrix








/*----------------------------------------------------------------------
--| FUNCTION rigGetCaptchaNum
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-10-09
--| Last Mod: 19-10-09
--| Requires: --
--|
--| Summary: Get number to build the captcha with.
--| 
--| Format:  rigGetCaptchaNum()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigGetCaptchaNum
	return format( "%s", sNum)
end rigGetCaptchaNum








/*----------------------------------------------------------------------
--| FUNCTION rigCaptchaStyle
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-10-19
--| Last Mod: 2018-10-24
--| Requires: --
--|
--| Summary: Get captcha style tags.
--| 
--| Format:  rigCaptchaStyle([param1])
--|
--| Parameters: string <pNonce> used by CSP headers (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigCaptchaStyle pNonce
  local tCaptchaStyle
  
  if pNonce <> empty then
    put sCaptchaStyle into tCaptchaStyle
    replace char 1 to 6 of tCaptchaStyle with "<style nonce=" & quote & pNonce & quote in tCaptchaStyle
    return tCaptchaStyle
  end if
  
	return sCaptchaStyle
end rigCaptchaStyle









/*----------------------------------------------------------------------
--| FUNCTION rigCaptchaCode
--|
--| Author: rabit
--| Version:  1.1
--| Created: 19-10-09
--| Last Mod: 27-04-15
--| Requires: --
--|
--| Summary: Get captcha html code.
--| 
--| Format:  rigCaptchaCode()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigCaptchaCode
  local tNumRows, tNumDigits, tRow, tDigit, tCell, tVal, tCaptcha
  
	put the number of lines in the keys of sNumberMatrix[1] into tNumRows

	put sCaptchaA["captchaLength"] into tNumDigits
    
	# SET BACKGROUND COLOR OF NUMBER CELLS ROW BY ROW 
	repeat with tRow = 1 to tNumRows
         
		-- repeat for each key tDigit in sNumberMatrix -- DON'T DO THAT, AS THE ARRAY KEYS ARE NOT ORDERED
		repeat with tDigit = 1 to tNumDigits

			repeat with tCell = 1 to 3
				put sNumberMatrix[tDigit][tRow][tCell] into tVal
				put "<span class=" & quote & tVal & quote & ">&nbsp;&nbsp;</span>" after tCaptcha
			end repeat
			# SPACE BETWEEN DIGITS
			if tDigit is not tNumDigits then
				put "<span class=" & quote & "w" & quote & ">&nbsp;&nbsp;</span>" after tCaptcha
			end if
		end repeat
		# END OF MATRIX ROW
		put "<br />" after tCaptcha
	end repeat
    
	return tCaptcha
end rigCaptchaCode








/*----------------------------------------------------------------------
--| FUNCTION _rigRandomCaptchaNum
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-10-09
--| Last Mod: 19-10-09
--| Requires: --
--|
--| Summary: Build random captcha number.
--| 
--| Format:  _rigRandomCaptchaNum(param1)
--|
--| Parameters: integer <pNumberLength>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigRandomCaptchaNum pNumberLength
  local tNumberLength, tUpperLimit, tLowerLimit
  
  if (pNumberLength is empty) or (pNumberLength is not an integer) then
    put sCaptchaA["captchaLength"] into tNumberLength
  else
    put pNumberLength into tNumberLength
  end if
    
  put "" into sNum

  repeat tNumberLength
    put 9 into tUpperLimit
    put 0 into tLowerLimit
        
    put random(tUpperLimit - tLowerLimit + 1) + tLowerLimit -1 after sNum
  end repeat
    
  return sNum
end _rigRandomCaptchaNum








/*----------------------------------------------------------------------
--| FUNCTION rigGetCaptchaHash
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2009-10-19
--| Last Mod: 2009-10-19
--| Requires: rigGetCaptchaNum(), rigHexDigest()
--|
--| Summary: Build hash from captcha number and a key.
--|            You may store this string in a hidden form field.
--| 
--| Format:  rigGetCaptchaHash()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigGetCaptchaHash
  local tCaptchaString
  
	put rigGetCaptchaNum() & sCaptchaA["captchaHashKey"] into tCaptchaString
	return rigHexDigest(tCaptchaString)
end rigGetCaptchaHash









/*----------------------------------------------------------------------
--| FUNCTION rigValidCaptchaUserInput
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2009-10-19
--| Last Mod: 2009-10-19
--| Requires: rigHexDigest()
--|
--| Summary: Validate captcha user input.
--| 
--| Format:  rigValidCaptchaUserInput(param1, param2)
--|
--| Parameters: mixed <pInput>, string <pHash>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigValidCaptchaUserInput pInput pHash
  local tCaptchaInput, tCaptchaInputHash
  
  if pInput is an integer then
    put pInput & sCaptchaA["captchaHashKey"] into tCaptchaInput
    put rigHexDigest(tCaptchaInput) into tCaptchaInputHash

    if tCaptchaInputHash is pHash then
      return TRUE
    end if
  end if

  return FALSE
end rigValidCaptchaUserInput






/*----------------------------------------------------------------------
--| FUNCTION rigCaptchaGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-02
--| Last Mod: 2019-01-02
--| Requires: --
--|
--| Summary: Get captcha array variable value.
--| 
--| Format:  rigCaptchaGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigCaptchaGet pWhat
  if pWhat is among the keys of sCaptchaA then
    return sCaptchaA[pWhat]
  end if
   
  return empty
end rigCaptchaGet




/*----------------------------------------------------------------------
--| COMMAND rigCaptchaSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-02
--| Last Mod: 2019-01-02
--| Requires: --
--|
--| Summary: Setter for captcha variables.
--| 
--| Format:  rigCaptchaSet param1, param2
--|
--| Parameters: string <pKey> sCaptchaA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigCaptchaSet pKey pVal
  if pKey is among the keys of sCaptchaA then
    put pVal into sCaptchaA[pKey]
  end if
end rigCaptchaSet









--| END OF Captcha.livecodescript
--| Location:  ./system/libraries/Captcha.livecodescript
----------------------------------------------------------------------