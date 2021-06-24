script "numberHelper"

##
# RevIgniter
#
# An application development framework for LiveCode
# modeled on CodeIgniter
#
# @package   RevIgniter
# @author     rabit@revigniter.com
# @copyright  Copyright (c) 2009 - 2021, dimensionB Bitter u. Bitter GmbH
# @license    https://revigniter.com/userGuide/license.html
# @link       https://revigniter.com
##

## ------------------------------------------------------------------------

##
# RevIgniter Number Helper
#
# @package      RevIgniter
# @subpackage  Helpers
# @category     Helpers
# @author       rabit@revigniter.com
# @link          https://revigniter.com/userGuide/helpers/number_helper.html
##

## ------------------------------------------------------------------------





global gRigA

local sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2021-06-15
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
--| FUNCTION rigFormattedNumToNum
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2021-06-14
--| Last Mod: --
--| Requires: rigLangLoadLang(), rigLangLangLine(), rigLogMessage
--|
--| Summary: Convert a formatted number string to a number.
--|
--| Format: rigFormattedNumToNum(param1[, param2])
--|
--| Parameters: string <pNum>, char <pDecimalSep> (optional)
--|
--| Return: number
----------------------------------------------------------------------*/

function rigFormattedNumToNum pNum pDecimalSep
   local tUnformattedNum, tIntegral, tDecimal
   
   get rigLangLoadLang("number")
	 
	 if pDecimalSep is empty then
     put rigLangLangLine("numDecimalSep") into pDecimalSep
	 end if
   
   if pDecimalSep <> empty then
      
      if matchText(pNum, "^[\d\s\.\',]+[\d\s\.\']*$") then
         
         set the itemDel to pDecimalSep
         
         if pDecimalSep is in pNum then
            put item 1 of pNum into tIntegral
            put item -1 of pNum into tDecimal
         end if

         put tIntegral & "%" & tDecimal into tUnformattedNum
         
         if tUnformattedNum is "%" then
            # NOT A DECIMAL NUMBER
            put pNum into tUnformattedNum
         end if
         
         put replaceText(tUnformattedNum,"[,\.\s\']","") into tUnformattedNum
         
         # DECIMAL NUMBER?
         if "%" is in tUnformattedNum then
            replace "%" with "." in tUnformattedNum
         end if
         
         return tUnformattedNum
  
      else
         rigLogMessage "error", "Wrong number format in rigFormattedNumToNum()!"
      end if -- if matchText(pNum, "^[\d\s\.\',]+[\d\s\.\']*$")
      
   end if -- if pDecimalSep <> empty
   
   return empty
end rigFormattedNumToNum






/*----------------------------------------------------------------------
--| FUNCTION rigFormattedNum
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2021-06-14
--| Last Mod: --
--| Requires: rigLangLoadLang(), rigLangLangLine(), _rigNumFormatItems(), rigNumberToCurrency()
--|            rigNumberToSize(), rigNumberToAmount(), _rigFormatted()
--|
--| Summary: Convert a number to a formatted number string.
--|
--| Format: rigFormattedNum(param1[, param2][, param3])
--|
--| Parameters: number <pNum>, string <pNumFormat> like 5%3%d'%d,%d, (optional) string <pUnit> (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigFormattedNum pNum pNumFormat pUnit
   local tNumFormatItemsA
   
   get rigLangLoadLang("number")
	 
	 if pNumFormat is empty then
		 put rigLangLangLine("numFormat") into pNumFormat
	 end if
   
   put _rigNumFormatItems(pNumFormat) into tNumFormatItemsA

 	switch tNumFormatItemsA["unit"]
 		case "currency"
 			return rigNumberToCurrency(pNum, , , tNumFormatItemsA)
			
 		break
 		case "size"
 			return rigNumberToSize(pNum, , tNumFormatItemsA["precision"], tNumFormatItemsA)
			
 		break
 		case "amount"
 			return rigNumberToAmount(pNum, , tNumFormatItemsA["precision"], tNumFormatItemsA)
			
		default
			return _rigFormatted(pNum, tNumFormatItemsA, pUnit)
 	end switch
end rigFormattedNum




/*----------------------------------------------------------------------
--| FUNCTION _rigNumFormatItems
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2021-06-14
--| Last Mod: --
--| Requires: _rigPositionOfUnit(), rigLogMessage
--|
--| Summary: Translate format string to an array.
--|
--| Format: _rigNumFormatItems(param)
--|
--| Parameters: string <pNumberFormat> like 5%3%d'%d,%d or 3%d'%d,%d or 3%d'%d.%d' or 3%d'%d.%d'%s
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigNumFormatItems pNumberFormat
   local tNumFormatItemsA
   
   if matchText(pNumberFormat, "^(%[csa]){0,1}(\d%){0,1}\d%d[\s,\.'’]{0,1}%d[,\.]{1}%d[\s,\.'’]{0,1}(%[csa]){0,1}(\d){0,1}$") then
      #CHECK IF PRECISION IS DEFINED
      if char -1 of pNumberFormat is a number then
         put char -1 of pNumberFormat into tNumFormatItemsA["precision"]
         put char 1 to -2 of pNumberFormat into pNumberFormat
      end if
      
      # CHECK IF THERE IS A CURRENCY, SIZE OR AMOUNT WILDCARD
      put empty into tNumFormatItemsA["unit"]
      if (char 2 of pNumberFormat is in "csa") then
         put _rigPositionOfUnit(char 2 of pNumberFormat, pNumberFormat, tNumFormatItemsA["unit"]) into tNumFormatItemsA["posUnit"]
      else if (char -1 of pNumberFormat is in "csa") then
         put _rigPositionOfUnit(char -1 of pNumberFormat, pNumberFormat, tNumFormatItemsA["unit"]) into tNumFormatItemsA["posUnit"]
      end if
      
      # CHECK IF THERE IS A PARTITION THRESHOLD DEFINED
      if char 1 of pNumberFormat & char 3 of pNumberFormat is a number then
         put char 1 of pNumberFormat into tNumFormatItemsA["partitionThreshold"]
         put char 3 to -1 of pNumberFormat into pNumberFormat
      else
         put 0 into tNumFormatItemsA["partitionThreshold"]
      end if
      
      put char 1 of pNumberFormat into tNumFormatItemsA["digitsGroupSize"]
      put char 7 of pNumberFormat into tNumFormatItemsA["numDecimalSep"]
      put char 4 of pNumberFormat into tNumFormatItemsA["leftSep"]
      
      # CHECK IF THERE IS A DIFFERENT THOUSANDS SEPARATOR DEFINED
      # FOR THE DECIMAL PART, SEE THE SWISS NUMBER FORMAT
      if char -1 of pNumberFormat is in " ,.'’" then
         put char -1 of pNumberFormat into tNumFormatItemsA["rightSep"]
      else
         put tNumFormatItemsA["leftSep"] into tNumFormatItemsA["rightSep"]
      end if
      
      return tNumFormatItemsA

    else
      rigLogMessage "error", "Wrong number format in _rigNumFormatItems()!"
   end if -- if matchText(pNumberFormat, "^(%[csa]){0,1}(\d%){0,1}\d%d[\s,\.'’]{0,1}%d[,\.]{1}%d[\s,\.'’]{0,1}(%[csa]){0,1}(\d){0,1}$")
   
   return empty
end _rigNumFormatItems







/*----------------------------------------------------------------------
--| FUNCTION _rigFormatted
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2021-06-14
--| Last Mod: --
--| Requires: rigLangLoadLang(), rigFormattedNumToNum(), rigLangLangLine(), rigLogMessage
--|
--| Summary: Convert a number to a formatted number string. This function is called by rigFormattedNum().
--|
--| Format: _rigFormatted(param1, param2[, param3])
--|
--| Parameters: number <pNum>, array <pNumFormatItemsA>, string <pUnit> (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigFormatted pNum pNumFormatItemsA pUnit
	local tIntegral, tLengthIntegral, tDecimal, tLengthDecimal
	local tLeadingDigits, tGroupStart, tCount, tTrailingDigits
	local tGroupEnd, tFormattedNum

   get rigLangLoadLang("number")
	
	# IS NUMBER FORMATTED
	if matchText(pNum, "^\d+\.?\d+$") is false then
		put rigFormattedNumToNum(pNum, rigLangLangLine("numDecimalSep")) into pNum
	end if
	
   if matchText(pNum, "^\d+[.]{0,1}\d*$") then
      set the itemDel to "."
      put item 1 of pNum into tIntegral
   
      if tIntegral is empty then
         # THERE IS NO DECIMAL PART
         put pNum into tIntegral
         put length(tIntegral) into tLengthIntegral
         put empty into tDecimal
      else
         
         put item 2 of pNum into tDecimal
         
         put length(tIntegral) into tLengthIntegral
         put length(tDecimal) into tLengthDecimal
      end if
   
      # ADD THOUSANDS SEPARATOR TO LEADING DIGITS
      put tIntegral into tLeadingDigits
      if (tLengthIntegral > pNumFormatItemsA["digitsGroupSize"]) and (tLengthIntegral >= pNumFormatItemsA["partitionThreshold"]) then
         
         put tLengthIntegral - pNumFormatItemsA["digitsGroupSize"] into tGroupStart
         put (tLengthIntegral - 1) div pNumFormatItemsA["digitsGroupSize"] into tCount
         
         repeat tCount times
            put pNumFormatItemsA["leftSep"] after char tGroupStart of tLeadingDigits
            subtract pNumFormatItemsA["digitsGroupSize"] from tGroupStart
         end repeat
         
      end if -- if (tLengthIntegral > pNumFormatItemsA["digitsGroupSize"]) and (tLengthIntegral >= pNumFormatItemsA["partitionThreshold"])

      # ADD THOUSANDS SEPARATOR TO TRAILING DIGITS
      put tDecimal into tTrailingDigits
      if (tLengthDecimal > pNumFormatItemsA["digitsGroupSize"]) and (tLengthDecimal >= pNumFormatItemsA["partitionThreshold"]) then
         
         put pNumFormatItemsA["digitsGroupSize"] into tGroupEnd
         put (tLengthDecimal -1) div pNumFormatItemsA["digitsGroupSize"] into tCount
         
         repeat tCount times
            put pNumFormatItemsA["rightSep"] after char tGroupEnd of tTrailingDigits
            add (pNumFormatItemsA["digitsGroupSize"] + 1) to tGroupEnd
         end repeat
         
      end if -- if (tLengthDecimal > pNumFormatItemsA["digitsGroupSize"]) and (tLengthIntegral >= pNumFormatItemsA["partitionThreshold"])
      
      if tTrailingDigits <> empty then
         put pNumFormatItemsA["numDecimalSep"] & tTrailingDigits into tTrailingDigits
      end if

      # ADD CURRENCY SYMBOL AND DECIMAL SEPARATOR
			if pUnit is empty then
				put rigLangLangLine("numCurrencySymbol") into pUnit
			end if			
      if (pNumFormatItemsA["posUnit"] <> empty) and (pUnit <> empty) then
         if pNumFormatItemsA["posUnit"] is "front" then
            put pUnit && tLeadingDigits & tTrailingDigits into tFormattedNum
         else
            put tLeadingDigits & tTrailingDigits && pUnit into tFormattedNum
         end if
         
       else if pUnit <> empty then
         put tLeadingDigits & tTrailingDigits && pUnit into tFormattedNum
      else
         put tLeadingDigits & tTrailingDigits into tFormattedNum
      end if -- if pNumFormatItemsA["posUnit"] <> empty
   
      return tFormattedNum
      
   else
      rigLogMessage "error", "Wrong number format in _rigFormatted()!"
   end if -- if matchText(pNum, "^\d+[.]{0,1}\d*$")
   
   return empty
end _rigFormatted







/*----------------------------------------------------------------------
--| FUNCTION _rigPositionOfUnit
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2021-06-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Get the position (front or back) of the number unit or currency symbol.
--|
--| Format: _rigPositionOfUnit(param1[, param2][, param3])
--|
--| Parameters: string <pChar>, string <pNumberFormat> like 5%3%d'%d,%d%c, string <pUnit>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigPositionOfUnit pChar @pNumberFormat @pUnit
	local tPosUnit
	
  # CHECK IF THERE IS A CURRENCY WILDCARD
  if char 2 of pNumberFormat is pChar then
     put "front" into tPosUnit
     put char 3 to -1 of pNumberFormat into pNumberFormat
  else if char -1 of pNumberFormat is pChar then
     put "back" into tPosUnit
     put char 1 to -3 of pNumberFormat into pNumberFormat
  end if
	
	switch pChar
		case "c"
			put "currency" into pUnit
			
		break
		case "s"
			put "size" into pUnit
			
		break
		case "a"
			put "amount" into pUnit
	end switch
	
	return tPosUnit
end _rigPositionOfUnit








/*----------------------------------------------------------------------
--| FUNCTION rigNumberToSize
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2021-06-14
--| Last Mod: --
--| Requires: rigLangLoadLang(), rigLangLangLine(), rigFormattedNumToNum()
--|            rigFormattedNum(), rigLogMessage
--|
--| Summary: Format numbers as bytes, based on size, and add the appropriate suffix.
--|
--| Format: rigNumberToSize(param1[, param2][, param3])
--|
--| Parameters: number <pNum>, string <pNumFormat> optional, number <pPrecision> (optional)
--|               array <pNumFormatItemsA> (for internal use only)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigNumberToSize pNum pNumFormat pPrecision pNumFormatItemsA
   local tDataSize, tUnit
   
   get rigLangLoadLang("number")
   
	 if (pNumFormat is empty) and (pNumFormatItemsA is empty) then
     # NUMBER FORMAT IS ONLY NEEDED IF THIS FUNCTION IS NOT CALLED BY rigFormattedNum()
     put rigLangLangLine("numFormat") into pNumFormat
     put pNumFormat & "%s" into pNumFormat
	 end if

	 # IS NUMBER FORMATTED?
	 if matchText(pNum, "^\d+\.?\d+$") is false then
     put rigFormattedNumToNum(pNum, rigLangLangLine("numDecimalSep")) into pNum
   end if

   if pNum is a number then
      if pPrecision is not a number then
         put 1 into pPrecision
      end if
      
      if pNum >= 1000000000000 then
         put round(pNum / 1099511627776, pPrecision) into tDataSize
         put rigLangLangLine("numTerabyteAbbr") into tUnit
         
      else if pNum >= 1000000000 then
         put round(pNum / 1073741824, pPrecision) into tDataSize
         put rigLangLangLine("numGigabyteAbbr") into tUnit
         
      else if pNum >= 1000000 then
         put round(pNum / 1048576, pPrecision) into tDataSize
         put rigLangLangLine("numMegabyteAbbr") into tUnit
         
      else if pNum >= 1000 then
         put round(pNum / 1048576, pPrecision) into tDataSize
         put rigLangLangLine("numKilobyteAbbr") into tUnit
         
      else
         put pNum into tDataSize
         put rigLangLangLine("numBytes") into tUnit
      end if -- if pNum >= 1000000000000 then
        
			if pNumFormatItemsA is empty then
				# IF THE FUNCTION IS NOT CALLED BY rigFormattedNum()
				put _rigNumFormatItems(pNumFormat) into pNumFormatItemsA
			end if
      
      return _rigFormatted(tDataSize, pNumFormatItemsA, tUnit)
			
		else
			rigLogMessage "error", "Number to size not a number!"
   end if -- if pNum is a number
   
   return empty
end rigNumberToSize







/*----------------------------------------------------------------------
--| FUNCTION rigNumberToAmount
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2021-06-14
--| Last Mod: --
--| Requires: rigLangLoadLang(), rigLangLangLine(), rigFormattedNumToNum()
--|            _rigNumFormatItems(), _rigFormatted(), rigLogMessage
--|
--| Summary: Convert a number into a human-readable version, like 123.4 trillion
--|            for numbers up to the quadrillions.
--|
--| Format: rigNumberToAmount(param1[, param2][, param3])
--|
--| Parameters: number <pNum>, string <pNumFormat> optional, number <pPrecision> (optional)
--|               array <pNumFormatItemsA> (for internal use only)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigNumberToAmount pNum pNumFormat pPrecision pNumFormatItemsA
	local tSuffix, tAmountNum
  
   get rigLangLoadLang("number")

	 if pNumFormat is empty then
		 # NUMBER FORMAT IS ONLY NEEDED IF THIS FUNCTION IS NOT CALLED BY rigFormattedNum()
     put rigLangLangLine("numFormat") into pNumFormat
		 put pNumFormat & "%a" into pNumFormat
	 end if

	 # IS NUMBER FORMATTED?
	 if matchText(pNum, "^\d+\.?\d+$") is false then
     put rigFormattedNumToNum(pNum, rigLangLangLine("numDecimalSep")) into pNum
   end if

   if pNum is a number then
      if pPrecision is not a number then
         put 1 into pPrecision
      end if

      put empty into tSuffix

      if pNum > 1000000000000000 then
         put rigLangLangLine("numQuadrillion") into tSuffix
         put round(pNum / 1000000000000000, pPrecision) into tAmountNum

      else if pNum > 1000000000000 then
         put rigLangLangLine("numTrillion") into tSuffix
         put round(pNum / 1000000000000, pPrecision) into tAmountNum

      else if pNum > 1000000000 then
         put rigLangLangLine("numBillion") into tSuffix
         put round(pNum / 1000000000, pPrecision) into tAmountNum

      else if pNum > 1000000 then
         put rigLangLangLine("numMillion") into tSuffix
         put round(pNum / 1000000, pPrecision) into tAmountNum

      else if pNum > 1000 then
         put rigLangLangLine("numThousand") into tSuffix
         put round(pNum / 1000, pPrecision) into tAmountNum
      end if -- if pNum > 1000000000000000

			if pNumFormatItemsA is empty then
				# IF THE FUNCTION IS NOT CALLED BY rigFormattedNum()
				put _rigNumFormatItems(pNumFormat) into pNumFormatItemsA
			end if

      return _rigFormatted(tAmountNum, pNumFormatItemsA, tSuffix)

		else
			rigLogMessage "error", "Number to amount not a number!"
   end if -- if pNum is a number
   
   return empty
end rigNumberToAmount







/*----------------------------------------------------------------------
--| FUNCTION rigNumberToCurrency
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2021-06-14
--| Last Mod: --
--| Requires: rigLangLoadLang(), rigLangLangLine(), rigFormattedNumToNum(),
--|            _rigNumFormatItems(), _rigFormatted(), rigLogMessage
--|
--| Summary: Convert a number in common currency formats, like USD, EUR, GBP, etc.
--|
--| Format: rigNumberToCurrency(param1[, param2][, param3])
--|
--| Parameters: number <pNum>, string <pNumFormat> optional, string <pSymbol> (optional)
--|               array <pNumFormatItemsA> (for internal use only)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigNumberToCurrency pNum pNumFormat pSymbol pNumFormatItemsA
   get rigLangLoadLang("number")
   
	 if (pNumFormat is empty) and (pNumFormatItemsA is empty) then
		 # NUMBER FORMAT IS ONLY NEEDED IF THIS FUNCTION IS NOT CALLED BY rigFormattedNum()
		 put rigLangLangLine("numFormatCurrency") into pNumFormat
	 end if

   if pSymbol is empty then
      put rigLangLangLine("numCurrencySymbol") into pSymbol
   end if
   
	 # IS NUMBER FORMATTED
	 if matchText(pNum, "^\d+\.?\d+$") is false then
		 put rigFormattedNumToNum(pNum, rigLangLangLine("numDecimalSep")) into pNum
	 end if

	 if pNum is a number then		 
		if pNumFormatItemsA is empty then
			# IF THE FUNCTION IS NOT CALLED BY rigFormattedNum()
			put _rigNumFormatItems(pNumFormat) into pNumFormatItemsA
		end if
		
		return _rigFormatted(pNum, pNumFormatItemsA, pSymbol)
			
	 else
			rigLogMessage "error", "Number to currency not a number!"
   end if -- if pNum is a number
 
   return empty
end rigNumberToCurrency






--| END OF numberLib.livecodescript
----------------------------------------------------------------------