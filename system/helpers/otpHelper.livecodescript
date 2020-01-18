script "otpHelper"

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
# @link		     https://revigniter.com
##

## ------------------------------------------------------------------------

##
# revIgniter OTP Helper
#
#
# @package			revIgniter
# @subpackage	Helpers
# @category	  	Helpers
# @author		  	rabit@revigniter.com
# @link		    		https://revigniter.com/userGuide/helpers/otpHelper.html
##

## ------------------------------------------------------------------------



global gRigA

local sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2019-06-15
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
--| COMMAND rigOTPgenerate
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2019-06-15
--| Last Mod: 2019-08-15
--| Requires: rigLogMessage, _rigOTPoauthTotp()
--|
--| Summary: Get an OTP providing a secret, token length, hash algorithm, time step and OTP type.
--|
--| Format:  rigOTPgenerate param1[, param2][, param 3][, param4][, param5] [, param6]
--|
--| Parameters: string <pSecret> the decoded shared secret, integer <pTokenLength> 6 or 8 (optional),
--|               string <pCryptoType> SHA or SHA3 (optional), integer <pCryptoNumBits> (optional)
--|               integer <pTimeStep> (optional), string <pType> hotp or totp (optional)
--|
--| Return: integer
----------------------------------------------------------------------*/

command rigOTPgenerate pSecret pTokenLength pCryptoType pCryptoNumBits pTimeStep pType
  local tTimestamp

  if pSecret is empty then
    rigLogMessage "error", "OTP authentication: No secret provided!"
    return FALSE
    -- put randomBytes(16) into pSecret --------- store this string in db (encrypt it?)
  end if

  if (pTokenLength is empty) or (pTokenLength is not an integer) then
    put 6 into pTokenLength
  end if

  if pCryptoType is not among the items of "SHA,SHA3" then
    put "SHA" into pCryptoType
  end if

  if pCryptoNumBits is not among the items of "1,224,256,384,512" then
    put "1" into pCryptoNumBits
  end if

  # TODO implement hotp
  if (pType is empty) or (pType is not among the items of "hotp,totp") then
    put "totp" into pType
  end if

  if pType is "totp" then
    if (pTimeStep is empty) or (pTimeStep is not an integer) then
      put 30 into pTimeStep
    end if

    put floor(the seconds / pTimeStep) into tTimestamp

    # GENERATE OTP
    return _rigOTPoauthTotp(pSecret, tTimestamp, pTokenLength, pCryptoType, pCryptoNumBits)
  end if -- if pType is "totp"
end rigOTPgenerate








/*----------------------------------------------------------------------
--| COMMAND rigOTPcompareKeys
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-06-16
--| Last Mod: 2019-06-16
--| Requires: rigLogMessage, _rigOTPoauthTotp()
--|
--| Summary: Compare supplied OTP with generated OTP.
--|
--| Format:  rigOTPcompareKeys param1, param2[, param3][, param4][, param5][, param5][, param7]
--|
--| Parameters: string <pChallenge>, string <pKey>, integer <pTokenLength> 6 or 8 (optional),
--|               string <pCryptoType> SHA or SHA3 (optional), integer <pCryptoNumBits> (optional),
--|               integer <pTimeStep> (optional), integer <pTimeWindow> (optional)
--|
--| Return: boolean
----------------------------------------------------------------------*/

command rigOTPcompareKeys pChallenge pKey pTokenLength pCryptoType pCryptoNumBits pTimeStep pTimeWindow
  local tTimestamp, tCounter, tTime, tOTP

  if (pChallenge is empty) or (pKey is empty) then
    rigLogMessage "error", "OTP authentication: Missing challenge or secret!"
    return FALSE
  end if

  if (pTokenLength is empty) or (pTokenLength is not an integer) then
    put 6 into pTokenLength
  end if

  if pCryptoType is not among the items of "SHA,SHA3" then
    put "SHA" into pCryptoType
  end if

  if pCryptoNumBits is not among the items of "1,224,256,384,512" then
    put "1" into pCryptoNumBits
  end if

  if (pTimeStep is empty) or (pTimeStep is not an integer) then
    put 30 into pTimeStep
  end if

  if (pTimeWindow is empty) or (pTimeWindow is not an integer) then
    put 2 into pTimeWindow
  end if

  put floor(the seconds / pTimeStep) into tTimestamp

  # COMPARE OTPs
  repeat with tCounter = -pTimeWindow to pTimeWindow
    put tTimestamp + tCounter into tTime

    put _rigOTPoauthTotp(pKey, tTime, pTokenLength, pCryptoType, pCryptoNumBits) into tOTP

    if tOTP is pChallenge then
      return TRUE
    end if
  end repeat

  return FALSE
end rigOTPcompareKeys








/*----------------------------------------------------------------------
--| FUNCTION _rigOTPoauthTotp
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-06-16
--| Last Mod: 2019-06-16
--| Requires: _rigOTPshiftRight(), _rigOTPstrPad, _rigOTPcalcHMAChex()
--|
--| Summary: Time based OTP calculation (RFC 6238).
--|
--| Format:  _rigOTPoauthTotp(param1, param2, param3, param4, param5)
--|
--| Parameters: string <pKey> the decoded shared secret, integer <pTime>, integer <pDigits>,
--|               string <pCryptoType>, integer <pNumBits>
--|
--| Return: integer
----------------------------------------------------------------------*/

private function _rigOTPoauthTotp pKey pTime pDigits pCryptoType pNumBits
  local tNum1, tNum2, tData, tHash, tOffset, tBinary, tResult

  put toUpper(pCryptoType) into pCryptoType

  put _rigOTPshiftRight(pTime, 32) into tNum1
  # baseConvert("FFFFFFFF",16,10) -> 4294967295
  put pTime bitAnd (baseConvert("FFFFFFFF",16,10)) into tNum2
  # CONVERT COUNTER TO BINARY (64-bit)
  put binaryEncode("MM", tNum1, tNum2) into tData

  # PAD TO 8 CHARS (IF NECESSARY)
  if the length of tData < 8 then
    _rigOTPstrPad tData, 8, numToByte(0), "padLeft"
  end if

  # GENERATE HASH
  put _rigOTPcalcHMAChex(tData, pKey, pCryptoType, pNumBits) into tHash

  # GET THE OFFSET
  put 2 * (baseConvert((char -1 of tHash), 16,10)) into tOffset

  # GET THE PORTION WE'RE INTERESTED IN
  put baseConvert(char (tOffset + 1) to (tOffset + 8) of tHash, 16, 10) into tBinary
  put tBinary bitAnd baseConvert("7fffffff", 16, 10) into tBinary

  # MODULUS
  put tBinary mod (10 ^ pDigits) into tResult

  # PAD (IF NECESSARY)
  _rigOTPstrPad tResult, pDigits, "0", "padLeft"

  return tResult
end _rigOTPoauthTotp







/*----------------------------------------------------------------------
--| COMMAND rigOTPgenerateUserKey
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-06-16
--| Last Mod: 2019-06-16
--| Requires: _rigOTPbase32Encode()
--|
--| Summary: Generate a base 32 encoded user key providing a secret.
--|
--| Format:  rigOTPgenerateUserKey param1
--|
--| Parameters: string <pSecret>
--|
--| Return: string
----------------------------------------------------------------------*/

command rigOTPgenerateUserKey pSecret
  local tEncodedSecret, tRegEx, tMatchStart, tMatchEnd

  put _rigOTPbase32Encode(pSecret) into tEncodedSecret
  # REMOVE TRAILING "=" CHARS
  put "(=+)" into tRegEx
  get matchChunk(tEncodedSecret,tRegEx,tMatchStart,tMatchEnd)
  put char 1 to (tMatchStart -1) of tEncodedSecret into tEncodedSecret

  return tEncodedSecret
end rigOTPgenerateUserKey







/*----------------------------------------------------------------------
--| FUNCTION _rigOTPbase32Encode
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-06-16
--| Last Mod: 2019-06-16
--| Requires: _rigOTPchunk(), _rigOTPstrPad
--|
--| Summary: Generate a base 32 encoded string (RFC 3548).
--|
--| Format:  _rigOTPbase32Encode(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigOTPbase32Encode pStr
  local tAlphabet, tBinStr, tBinA, tNumChunks, tVal, tChar, tBase32Str

  put "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567=" into tAlphabet

  if pStr is empty then
    return empty
  end if

  # CONVERT STRING TO BINARY
  get binaryDecode("B*",pStr , tBinStr)

  # BREAK INTO 5-BIT CHUNKS, THEN BREAK THAT INTO AN ARRAY
  put _rigOTPchunk(tBinStr, 5) into tBinA

  # PAD ARRAY TO BE DIVISIBLE BY 8
  put the number of lines in the keys of tBinA into tNumChunks
  repeat while tNumChunks mod 8 <> 0
    add 1 to tNumChunks
    put empty into tBinA[tNumChunks]
  end repeat

  # ENCODE IN BASE32
  repeat for each element tVal in tBinA
    put 32 into tChar

    if tVal <> empty then
      # PAD THE BINARY STRINGS
      _rigOTPstrPad tVal, 5, 0, "padRight"
      put baseConvert(tVal, 2,10) into tChar
    end if

    # BASE32 CHARACTER
    put char (tChar + 1) of tAlphabet after tBase32Str
  end repeat

  return tBase32Str
end _rigOTPbase32Encode









/*----------------------------------------------------------------------
--| FUNCTION _rigOTPbase32Decode
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-06-16
--| Last Mod: 2019-06-16
--| Requires: _rigOTPstrPad
--|
--| Summary: Decode base 32 string.
--|
--| Format:  _rigOTPbase32Decode(param1)
--|
--| Parameters: string <pBase32Str>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigOTPbase32Decode pBase32Str
  local tAlphabetA, tChar, tPos, tBinStr, tBinData
  local tBinDataLength, tBinA, tVal, tDecodedStr

  # WORK IN UPPER CASES ONLY
  put toUpper(pBase32Str) into pBase32Str

  # REMOVE ANYTHING THAT IS NOT BASE32 ALPHABET
  put replaceText(pBase32Str, "[^A-Z2-7]", "") into pBase32Str

  if pBase32Str is empty then
    return empty
  end if

  # BASE32 ALPHABET ARRAY
  put "A 0,B 1,C 2,D 3,E 4,F 5,G 6,H 7,I 8,J 9,K 10,L 11,M 12,N 13,O 14,P 15,Q 16,R 17,S 18,T 19,U 20,V 21,W 22,X 23,Y 24,Z 25,2 26,3 27,4 28,5 29,6 30,7 31,= 32" into tAlphabetA
  split tAlphabetA by comma and space

  # BASE 32 STRING TO BINARY
  repeat for each char tChar in pBase32Str
    put tAlphabetA[tChar] into tPos

    # IGNORE THE PADDING CHARACTER "="
    if tPos <> 32 then
      put baseConvert(tPos, 10, 2) into tBinStr
      _rigOTPstrPad tBinStr, 5, 0, "padLeft"
      put tBinStr after tBinData
    end if
  end repeat

  put the length of tBinData into tBinDataLength
  repeat while tBinDataLength mod 8 <> 0
    put char 1 to (tBinDataLength -1) of tBinData into tBinData
    put the length of tBinData into tBinDataLength
  end repeat

  # BINARY DATA ARRAY
  put rigChunk(tBinData, 8) into tBinA

  repeat for each element tVal in tBinA
    # PAD EACH VALUE TO 8 BITS
    _rigOTPstrPad tVal, 8, 0, "padRight"

    # CONVERT BINARY STRINGS TO ASCII
    put numtobyte(baseConvert(tVal, 2,10)) after tDecodedStr
  end repeat

  return tDecodedStr
end _rigOTPbase32Decode








/*----------------------------------------------------------------------
--| FUNCTION _rigOTPchunk
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-06-16
--| Last Mod: 2019-06-16
--| Requires: --
--|
--| Summary: Break binary data into chunks and return that as array.
--|
--| Format:  _rigOTPchunk(param1, param2)
--|
--| Parameters: binary string <pBinStr>, integer <pBitsPerChunk>
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigOTPchunk pBinStr pBitsPerChunk
  local tPartialChunk, tBinStrLength, tNumChunks, tNumBitsleft
  local tCounter, tChunkedBinStr

  put empty into tPartialChunk
  put the length of pBinStr into tBinStrLength
  put tBinStrLength div pBitsPerChunk into tNumChunks
  put tBinStrLength mod tNumChunks into tNumBitsleft
  if tNumBitsleft <> 0 then
   put byte - tNumBitsleft to -1 of pBinStr into tPartialChunk
  end if

  put 0 into tCounter
  repeat tNumChunks
   if tCounter is 0 then
     put byte 1 to pBitsPerChunk of pBinStr & "," after tChunkedBinStr
   else
     put byte ((pBitsPerChunk * tCounter) + 1) to ((pBitsPerChunk * tCounter) + pBitsPerChunk) of pBinStr & "," after tChunkedBinStr
   end if

   add 1 to tCounter
  end repeat

  if tPartialChunk is empty then
   delete byte -1 of tChunkedBinStr
  else
   put tPartialChunk after tChunkedBinStr
  end if

  split tChunkedBinStr by comma

  return tChunkedBinStr
end _rigOTPchunk






/*----------------------------------------------------------------------
--| COMMAND _rigOTPstrPad
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-06-16
--| Last Mod: 2019-06-16
--| Requires: --
--|
--| Summary: Pad a string to a certain length with another string.
--|
--| Format:  _rigOTPstrPad param1, param2, param3, param4
--|
--| Parameters: string <pStr>, integer <pNum> result string length, string <pPad>,
--|               string <pType> padLeft, padRight or padBoth
--|
--| Return: string
----------------------------------------------------------------------*/

private command _rigOTPstrPad @pStr pNum pPad pType
  local tStrLength, tPadLength, tDifLength, tIteration
  local tPartialPadLength, tPartialPad, tPadStr, tCounter
  local tTemp, tPadStrLeft, tPadStrRight

  put the length of pStr into tStrLength
  put the length of pPad into tPadLength

  put pNum - tStrLength into tDifLength

  if tPadLength <= tDifLength then
    put tDifLength div tPadLength into tIteration
    put tDifLength mod tPadLength into tPartialPadLength
    if tPartialPadLength <> 0 then
      put char 1 to tPartialPadLength of pPad into tPartialPad
    end if

  else
    put 0 into tIteration
    put char 1 to tDifLength of pPad into tPartialPad
  end if

  switch pType
    case "padLeft"
      repeat tIteration
        put pPad before tPadStr
      end repeat
      put tPartialPad after tPadStr
      put tPadStr before pStr
    break

    case "padBoth"
      if tIteration > 0 then
        put 0 into tCounter

        put tIteration div 2 into tIteration

        if (tPadLength = 1) and (tDifLength mod 2 = 1) and (tIteration <> 0) then
          put pPad into tPartialPad
        end if

        if tIteration = 0 then
          put pPad after tPadStrLeft
          put tPartialPad after tPadStrRight
        else

          repeat tIteration
            add 1 to tCounter
            put pPad after tPadStrLeft
            put the length of (tPadStrLeft & pStr & tPadStrRight) into tTemp
            if (tIteration > tCounter) or (pNum - (the length of (tPadStrLeft & pStr & tPadStrRight)) >= tPadLength) then
              put pPad after tPadStrRight
            end if

            if tIteration = tCounter then
              if pNum - (the length of (tPadStrLeft & pStr & tPadStrRight)) = tPadLength then
                put pPad after tPadStrLeft
              else
                put tPartialPad after tPadStrLeft
              end if
            end if
          end repeat

        end if -- if tIteration = 0

        put tPadStrLeft & pStr & tPadStrRight into pStr
      else
        put tPartialPad before pStr
      end if -- if tIteration > 0
    break

    default
    repeat tIteration
      put pPad after pStr
    end repeat
    put tPartialPad after pStr
  end switch
end _rigOTPstrPad





/*----------------------------------------------------------------------
--| FUNCTION _rigOTPshiftRight
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-06-16
--| Last Mod: 2019-06-16
--| Requires: --
--|
--| Summary: Shift the bits of pNum pSteps steps to the right (each step means "divide by two").
--|
--| Format:  _rigOTPshiftRight(param1, param2)
--|
--| Parameters: integer <pNum>, integer <pSteps>
--|
--| Return: integer
----------------------------------------------------------------------*/

private function _rigOTPshiftRight pNum pSteps
  if pSteps is empty then
    put 1 into pSteps
  end if

  return pNum div (2 ^ pSteps)
end _rigOTPshiftRight







/*----------------------------------------------------------------------
--| FUNCTION _rigOTPcalcHMAChex
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-06-16
--| Last Mod: 2019-06-16
--| Requires: _rigOTPhmacSha()
--|
--| Summary: Generate a keyed HMAC hash value converted to a hexadecimal string.
--|
--| Format:  _rigOTPcalcHMAChex(param1, param2, param3, param4)
--|
--| Parameters: string <pData>, string <pKey> the decoded shared secret, string <pType>, integer <pNumBits>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigOTPcalcHMAChex pData, pKey, pType, pNumBits
  local tHMACbin, tHex

  put _rigOTPhmacSha(pData, pKey, pType, pNumBits) into tHMACbin
  get binaryDecode("H*",tHMACbin,tHex)

  return tHex
end _rigOTPcalcHMAChex







/*----------------------------------------------------------------------
--| FUNCTION _rigOTPhmacSha
--|
--| Author: Mark Smith
--| Modification: rabit
--| Version:  1.0
--| Created: 2019-06-16
--| Last Mod: 2019-06-16
--| Requires: _rigOTPSha()
--|
--| Summary: Compute hash-based message authentication code (HMAC, RFC 2104).
--|
--| Format:  _rigOTPhmacSha(param1, param2, param3, param4)
--|
--| Parameters: string <pData>, string <pKey>, string <pType>, integer <pNumBits>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigOTPhmacSha pData pKey pType pNumBits
local tBlockSize, tIpad, tOpad

  if pType is empty then
    put "SHA" into pType
  else
    if pType is not among the items of "SHA,SHA3" then
      put "SHA" into pType
    end if
  end if

  if pType is "SHA" then
    if pNumBits > 256 then
      put 128 into tBlockSize
    else
      put 64 into tBlockSize
    end if
  else
    # SHA3
    switch pNumBits
      case 256
        put 136 into tBlockSize
      break

      case 384
        put 104 into tBlockSize
      break

      case 512
        put 72 into tBlockSize
    end switch
  end if

  if length(pKey) > tBlockSize then
    put _rigOTPSha(pKey, pType, pNumBits) into pKey
  end if

  repeat tBlockSize - length(pKey)
    put null after pKey
  end repeat

  repeat for each byte b in pKey
    put numtobyte(bytetonum(b) bitXor 54) after tIpad
    put numtobyte(bytetonum(b) bitXor 92) after tOpad
  end repeat

  return _rigOTPSha(tOpad & _rigOTPSha(tIpad & pData, pType, pNumBits), pType, pNumBits)
end _rigOTPhmacSha








/*----------------------------------------------------------------------
--| FUNCTION _rigOTPSha
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-06-16
--| Last Mod: 2019-06-16
--| Requires: --
--|
--| Summary: Compute a message digest.
--|
--| Format:  _rigOTPSha(param1, param2, param3)
--|
--| Parameters: string <pData>, string <pType>, integer <pNumBits>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigOTPSha pData, pType, pNumBits
  local tDigestType

  if (pNumBits is among the items of "1,224,256,384,512") and (pType is among the items of "SHA,SHA3") then
    put pType & "-" & pNumBits into tDigestType
    return messageDigest(pData, tDigestType)
  end if

  return messageDigest(pData, "SHA-512")
end _rigOTPSha







/*----------------------------------------------------------------------
--| FUNCTION rigOTPqrCode
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2019-06-18
--| Last Mod: 2019-08-22
--| Requires: rigOTPvalidBase32Str(), rigUrlEncodeRFC(), rigLoaderLoadLibrary, rigLogMessage
--|
--| Summary: Create QR code based on OTP URI data.
--|
--| Format:  rigOTPqrCode(param1, param2, param3[, param4][, param5][, param6][, param7][, param8][, param9])
--|
--| Parameters: string <pKey>, string <pAccount>, string <pIssuer>, string <pAlgo> (optional),
--|               integer <pDigits> (optional), integer <pPeriod> (optional), string <pECC> (optional),
--|               integer <pSize> (optional), mixed <pMask> (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigOTPqrCode pKey pAccount pIssuer pAlgo pDigits pPeriod pECC pSize pMask
  local tData, tImg, tImgData

  if (pKey is empty) or (rigOTPvalidBase32Str(pKey) is FALSE) then
    rigLogMessage "error", "OTP: Missing key or base32 string contains invalid characters!"
    return FALSE
  end if

  if pIssuer is empty then
    rigLogMessage "error", "OTP: Missing issuer!"
    return FALSE
  else
    put rigUrlEncodeRFC(pIssuer) into pIssuer
  end if

  if pAccount is empty then
    rigLogMessage "error", "OTP: Missing account!"
    return FALSE
  else
    put rigUrlEncodeRFC(pAccount) into pAccount
    replace "%40" with "@" in pAccount
  end if

  if (pAlgo is empty) or (pAlgo is not among the items of "SHA1,SHA224,SAH256,SHA384,SHA512,SHA3224,SHA3256,SHA3384,SHA3512") then
    put "SHA1" into pAlgo
  end if

  if (pDigits is empty) or (pDigits is not an integer) then
    put 6 into pDigits
  end if

  if (pPeriod is empty) or (pPeriod is not an integer) then
    put 30 into pPeriod
  end if

  if (pECC is empty) or (pECC is not among the items of "L,M,Q,H,X") then
    put "M" into pECC
  end if

  if (pSize is empty) or (pSize is not among the items of "1,2,3,4,5,6,7,8,9,10") then
    put 4 into pSize
  end if

  if (pMask is empty) or (pMask is not among the items of "Auto,0,1,2,3,4,5,6,7") then
    put "Auto" into pMask
  end if

  rigLoaderLoadLibrary "QR"

  # OTP URI
  put "otpauth://totp/" & pIssuer & ":" & pAccount & "?secret=" & pKey & "&issuer=" & pIssuer & "&algorithm=" & pAlgo & "&digits=" & pDigits & "&period=" & pPeriod into tData

  # GENERATE QR CODE DATA
  put "!" into tImg
  -- qrSetColors "Blue", "255,255,0"
  qrSetColors "Black", "White"
  qrCreate tImg, tData, pECC, pSize, pMask

  put the result into tImgData

  if tImgData begins with "Error" then
    rigLogMessage "error", tImgData
    return FALSE
  end if

  # REMOVE INFO DATA
  delete line 1 of tImgData

  put base64Encode(tImgData) into tImgData
  replace LF with empty in tImgData

  return tImgData
end rigOTPqrCode





/*----------------------------------------------------------------------
--| FUNCTION rigOTPvalidBase32Str
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-06-25
--| Last Mod: 2019-06-25
--| Requires: --
--|
--| Summary: Validate base32 encoding of user keys.
--|
--| Format:  rigOTPvalidBase32Str(param1)
--|
--| Parameters: string <tBase32Str>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigOTPvalidBase32Str tBase32Str
  # USER KEY VALIDATION
  if matchText(tBase32Str, "^[A-Z2-7]+$") is FALSE then
    return FALSE
  end if

  return TRUE
end rigOTPvalidBase32Str






--| END OF otpHelper.livecodescript
--| Location:  ./system/helpers/otpHelper.livecodescript
----------------------------------------------------------------------