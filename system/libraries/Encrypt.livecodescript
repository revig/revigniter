script "Encrypt"

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
# revIgniter Encryption Library
#
#
# @package		revIgniter
# @subpackage	Libraries
# @category		Libraries
# @author			rabit@revigniter.com
# @link				https://revigniter.com/userGuide/libraries/encryption.html
##



global gRigA

local sEncryptA, sStackInUse






 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-13
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
        rigLogMessage "debug", "Encrypt Library Loaded"
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
  put "SHA-1" into sEncryptA["_hashType"]
  put "bf" into sEncryptA["cipher"]
  put 128 into sEncryptA["cipherKeyLength"]
end _rigSetDefaultValues





/*----------------------------------------------------------------------
--| COMMAND rigRunInitialEncryptConfig
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-10-09
--| Last Mod: 27-10-09
--| Requires: --
--|
--| Summary: Run initial configuration procedures. Don't remove, even if it does nothing.
--| 
--| Format:  rigRunInitialEncryptConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialEncryptConfig pConfig

end rigRunInitialEncryptConfig








/*----------------------------------------------------------------------
--| FUNCTION _rigGetEncryptionKey
--|
--| Author: rabit
--| Version:  1.1
--| Created: 16-10-09
--| Last Mod: 06-02-15
--| Requires: rigFetchConfigItem(), rigHexDigest()
--|
--| Summary: Fetch the encryption key. Returns it as md5 or SHA-256 (depending on LC server version)
--|            in text format as a 32 (64) digit hexadecimal number. 
--| 
--| Format:  _rigGetEncryptionKey(param1)
--|
--| Parameters: string <pKey>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigGetEncryptionKey pKey
	if pKey is empty then
		if sEncryptA["encryptionKey"] is not empty then
			return sEncryptA["encryptionKey"]
		end if

		put rigFetchConfigItem("encryption_key") into pKey
		if pKey is empty then
			rigShowError "In order to use the Encrypt library requires that you set an encryption key in your config file."
		end if
	end if

	return rigHexDigest(pKey)
end _rigGetEncryptionKey










/*----------------------------------------------------------------------
--| COMMAND rigSetEncryptionKey
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2009-10-16
--| Last Mod: --
--| Requires: --
--|
--| Summary: Set the encryption key. Undocumented!!!!!!!!!!!
--| 
--| Format:  rigSetEncryptionKey param1
--|
--| Parameters: string <pKey>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetEncryptionKey pKey
	put pKey into sEncryptA["encryptionKey"]
end rigSetEncryptionKey










/*----------------------------------------------------------------------
--| FUNCTION rigEncode
--|
--| Author: rabit
--| Version:  2.0
--| Created: 16-10-09
--| Last Mod: 18-07-11
--| Requires: _rigGetEncryptionKey(), _rigXorEncode()
--|
--| Summary:	Encodes the message string using bitwise XOR encoding.
--|					The key is combined with a random hash, and then it
--|          	too gets converted using XOR. The whole thing is then
--|					encrypted using a randomly generated salt for the key.
--|            The end result is a message string that is randomized with
--|            each call to this function, even if the supplied message and
--|            key are the same.
--| 
--| Format:  rigEncode(param1, param2)
--|
--| Parameters: string <pString> the string to encode, string <pKey>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigEncode pString pKey
  local tKey, tEnc
  
	put _rigGetEncryptionKey(pKey) into tKey
	put _rigXorEncode(pString, tKey) into tEnc

	encrypt tEnc using sEncryptA["cipher"] with tKey at sEncryptA["cipherKeyLength"] bit
	if the result is empty then
		return base64encode(it)
	end if

	return FALSE
end rigEncode









/*----------------------------------------------------------------------
--| FUNCTION rigDecode
--|
--| Author: rabit
--| Version: 2.2
--| Created: 16-10-09
--| Last Mod: 22-12-14
--| Requires: _rigGetEncryptionKey(), _rigXorDecode()
--|
--| Summary: Reverses the above process.
--| 
--| Format:  rigDecode(param1, param2)
--|
--| Parameters: string <pString> the string to decode, string <pKey>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDecode pString pKey
  local tKey, tRegEx, tDec
  
   put _rigGetEncryptionKey(pKey) into tKey
   -- put "[^a-zA-Z0-9\/\+=]" into tRegEx
   put "[^a-zA-Z0-9\/\+=" & numToNativeChar(10) & numToNativeChar(13) & "]" into tRegEx
   
   if matchtext(pString,tRegEx) is TRUE then
     return FALSE
   end if
   
   put base64Decode(pString) into tDec

   decrypt tDec using sEncryptA["cipher"] with tKey at sEncryptA["cipherKeyLength"] bit
   if the result is empty then
      return _rigXorDecode(it, tKey)
   end if

   return FALSE
end rigDecode









/*----------------------------------------------------------------------
--| FUNCTION _rigXorEncode
--|
--| Author: rabit
--| Version:  1.3
--| Created: 16-10-09
--| Last Mod: 23-12-14
--| Requires: rigRandomNum(), _rigHash(), rigSubstr(), _rigXorMerge()
--|
--| Summary: Takes a plain-text string and key as input and generates an
--|            encoded bit-string using XOR.
--| 
--| Format:  _rigXorEncode(param1, param2)
--|
--| Parameters: string <pString>, string <pKey>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigXorEncode pString pKey
  local tRand, tStringLength, tRandLength, tEnc
  
	put rigRandomNum() into tRand

	put _rigHash(tRand) into tRand

	put length(pString) into tStringLength
	put length(tRand) into tRandLength
	
	repeat with i = 1 to tStringLength
    put rigSubstr(tRand, ((i - 1) mod tRandLength) + 1, 1) & (numToNativeChar(rigSubstrToNum(tRand, ((i - 1) mod tRandLength) + 1, 1, TRUE) bitXOr rigSubstrToNum(pString, i, 1, TRUE))) after tEnc
	end repeat

	return _rigXorMerge(tEnc, pKey)
end _rigXorEncode







/*----------------------------------------------------------------------
--| FUNCTION _rigXorDecode
--|
--| Author: rabit
--| Version:  1.2
--| Created: 16-10-09
--| Last Mod: 23-12-14
--| Requires: _rigXorMerge(), rigSubstrToNum()
--|
--| Summary: Takes an encoded string and key as input and generates the
--|            plain-text original message.
--| 
--| Format:  _rigXorDecode(param1, param2)
--|
--| Parameters: string <pString>, string <pKey>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigXorDecode pString pKey
  local tString, tStringLength, tDec, i, j
  
  put _rigXorMerge(pString, pKey) into tString

  put length(tString) into tStringLength

  repeat with i = 1 to tStringLength
    put i into j
    add 1 to i
    put numToNativeChar((rigSubstrToNum(tString, i, 1, TRUE)) bitXOr (rigSubstrToNum(tString, j, 1, TRUE))) after tDec
  end repeat

  return tDec
end _rigXorDecode







/*----------------------------------------------------------------------
--| FUNCTION _rigXorMerge
--|
--| Author: rabit
--| Version:  1.3
--| Created: 16-10-09
--| Last Mod: 23-12-14
--| Requires: _rigHash(), rigSubstrToNum()
--|
--| Summary: Takes a string and key as input and computes the difference using XOR.
--| 
--| Format:  _rigXorMerge(param1, param2)
--|
--| Parameters: string <pString>, string <pKey>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigXorMerge pString pKey
  local tHash, tStringLength, tHashLength, i, tStr
  
	put _rigHash(pKey) into tHash

	put length(pString) into tStringLength
	put length(tHash) into tHashLength

	repeat with i = 1 to tStringLength
    put numToNativeChar((rigSubstrToNum(pString, i, 1, TRUE)) bitXOr (rigSubstrToNum(tHash, ((i - 1) mod tHashLength) + 1, 1, TRUE))) after tStr
	end repeat

	return tStr
end _rigXorMerge




/*----------------------------------------------------------------------
--| COMMAND rigSetCipher
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-07-2011
--| Last Mod: 18-07-2011
--| Requires: --
--|
--| Summary: Set the cipher and the key length
--| 
--| Format:  rigSetCipher param1, param2
--|
--| Parameters: string <pName>, ineger <pKeyLength>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetCipher pName pKeyLength
	put pName into sEncryptA["cipher"]
	put pKeyLength into sEncryptA["cipherKeyLength"]
end rigSetCipher





/*----------------------------------------------------------------------
--| COMMAND rigSetHash
--|
--| Author: rabit
--| Version:  2.2
--| Created: 2009-10-16
--| Last Mod: 2018-11-02
--| Requires: --
--|
--| Summary: Set the hash type. 
--| 
--| Format:  rigSetHash param1
--|
--| Parameters: string <pType>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetHash pType
  local tType
  
	if (pType is empty) or (pType is not among the items of "SHA-1,SHA-224,SHA-256,SHA-384,SHA-512,SHA3-224,SHA3-256,SHA3-384,SHA3-512") then
		# DEFAULT HASH TYPE -- used for backwards compatibility
		put "SHA-1" into tType
	else
		put pType into tType
	end if
	
	set the itemdel to "."
	
	if (item 1 of the version < 9) then
		if (tType is not "SHA-1") and (tType is not "md5") then
			put "SHA-1" into sEncryptA["_hashType"]
		else
			put tType into sEncryptA["_hashType"]
		end if
	
	else
		# SERVER VERSION 9_0_0_dp_7 AND UP
		put tType into sEncryptA["_hashType"]
	end if
end rigSetHash








/*----------------------------------------------------------------------
--| FUNCTION _rigHash
--|
--| Author: rabit
--| Version:  2.2
--| Created: 2009-10-16
--| Last Mod: 2018-11-02
--| Requires: rigHexDigest()
--|
--| Summary: Hash encode a string. 
--| 
--| Format:  _rigHash(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigHash pStr
  local tHash
  
	set the itemdel to "."
	
	if (item 1 of the version < 9) then
		if sEncryptA["_hashType"] is "SHA-1" then
			put sha1Digest(pStr) into tHash
		else

			put rigHexDigest(pStr) into tHash
		end if
	
	else
		# SERVER VERSION 9_0_0_dp_7 AND UP
		put messageDigest(pStr, sEncryptA["_hashType"]) into tHash
	end if

	return tHash
end _rigHash






/*----------------------------------------------------------------------
--| FUNCTION rigEncryptGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-04
--| Last Mod: 2019-01-04
--| Requires: --
--|
--| Summary: Get library array variable values.
--| 
--| Format:  rigEncryptGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigEncryptGet pWhat
  if pWhat is among the keys of sEncryptA then
    return sEncryptA[pWhat]
  end if
   
  return empty
end rigEncryptGet





/*----------------------------------------------------------------------
--| COMMAND rigEncryptSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-04
--| Last Mod: 2019-01-04
--| Requires: --
--|
--| Summary: Setter for encrypt array variables.
--| 
--| Format:  rigEncryptSet param1, param2
--|
--| Parameters: string <pKey> sEncryptA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigEncryptSet pKey pVal
  if pKey is among the keys of sEncryptA then
    put pVal into sEncryptA[pKey]
  end if
end rigEncryptSet








--| END OF Encrypt.livecodescript
--| Location:  ./system/libraries/Encrypt.livecodescript
----------------------------------------------------------------------