script "jwtHelper"

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
# revIgniter JWT Helper
#
#
# @package			revIgniter
# @subpackage	Helpers
# @category	  	Helpers
# @requires			com.livecode.library.json
# @author		  	rabit@revigniter.com
# @link		    		https://revigniter.com/userGuide/helpers/jwtHelper.html
##

## ------------------------------------------------------------------------



global gRigA

local sH0, sH1, sH2, sH3, sH4, sH5, sH6, sH7, sK
local sSource, sIsFile, sBytesDone, sDataSize, sTail, sStackInUse





 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-28
 --| Last Mod: --
 --| Requires: _rigJWTinitHelper
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
      
      _rigJWTinitHelper
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack





/*----------------------------------------------------------------------
--| COMMAND _rigJWTinitHelper
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-07-11
--| Last Mod: 2016-07-11
--| Requires: rigLoadExtension
--|
--| Summary: Load the LiveCode Builder JSON library.
--| 
--| Format:  _rigJWTinitHelper
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigJWTinitHelper
  rigLoadExtension "com.livecode.library.json"
end _rigJWTinitHelper




/*----------------------------------------------------------------------
--| FUNCTION rigJWTencode
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2016-07-08
--| Last Mod: 2018-11-09
--| Requires: _rigStrToArray(), _rigJWTgenerateSecret(), _rigHmacSha2b64(), _rigJWTpurge
--|
--| Summary: Generates and returns a JSON Web Token. Note: Use a binary string as a secret.
--| 
--| Format:  rigJWTencode([param1], param2[, param3])
--|
--| Parameters: mixed <pHeader> (optional), mixed <pPayload>, integer <pNumBits> the number
--| 						of bits of the hash function (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigJWTencode pHeader pPayload pNumBits
  local tJWTheaderDataA, tJWTheader, tJWTpayload, tSecretFile
  local tJWTsecret, tJWTheaderPayload, tJWThmac
  
	# CHECK VALUE FOR NUMBER OF BITS
	_rigJWTTypeNum pNumBits
	
  # HEADER
  if pHeader is empty then
		set the itemDel to "."
	
		if item 1 of the version < 9 then
			put "HS256" into tJWTheaderDataA["alg"]
		else
			put "HS" & pNumBits into tJWTheaderDataA["alg"]
		end if
    put "JWT"into tJWTheaderDataA["typ"]
  else
    if pHeader is not an array then
      put _rigStrToArray(pHeader, , TRUE, TRUE) into tJWTheaderDataA
    end if
  end if
  put base64Encode(JsonExport(tJWTheaderDataA)) into tJWTheader
  #
  
  # PAYLOAD
  if pPayload is not an array then
    put _rigStrToArray(pPayload, , TRUE, TRUE) into pPayload
  end if
  put base64Encode(JsonExport(pPayload)) into tJWTpayload
  #
  
  # SECRET
  put gRigA["APPPATH"] & "config/jwt.lc" into tSecretFile
  if there is a file tSecretFile then
    put url ("binfile:" & tSecretFile) into tJWTsecret
    put base64Decode(tJWTsecret) into tJWTsecret
  else
    put base64Decode(_rigJWTgenerateSecret()) into tJWTsecret
  end if
  #
  
  # HMAC
  put tJWTheader & "." & tJWTpayload into tJWTheaderPayload
  _rigJWTpurge tJWTheaderPayload

	put _rigHmacSha2b64(tJWTheaderPayload, tJWTsecret, pNumBits) into tJWThmac
	_rigJWTpurge tJWThmac

  return tJWTheaderPayload & "." & tJWThmac
end rigJWTencode






/*----------------------------------------------------------------------
--| FUNCTION rigJWTdecode
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2016-07-09
--| Last Mod: 2018-11-09
--| Requires: rigGetHTTPheader(), _rigJWTVerifySig(), rigLogMessage
--|
--| Summary: Decode and validate a JSON Web Token.
--| 
--| Format:  rigJWTdecode([param1][, param2])
--|
--| Parameters: string <pToken> (optional), integer <pNumBits> the number of bits
--|               of the hash function (optional)
--|
--| Return: array
----------------------------------------------------------------------*/

function rigJWTdecode pToken pNumBits
  local tJWTheader, tJWTpayload, tJWThmac, tJWTDecodedA
  
	# CHECK VALUE FOR NUMBER OF BITS
	_rigJWTTypeNum pNumBits
	
	# GET TOKEN
	if pToken is empty then
		# HEADER DATA
		put rigGetHTTPheader("Authorization") into pToken
		if pToken <> empty then
			put word -1 of pToken into pToken
		end if
	end if
	#
  
	set the itemDel to "."

	put item 1 of pToken into tJWTheader
	put item 2 of pToken into tJWTpayload
	put item 3 of pToken into tJWThmac
    
	if (pToken <> empty) and (the number of items of pToken is 3) then
  
		# CHECK INTEGRITY OF TOKEN
		put _rigJWTVerifySig(tJWTheader, tJWTpayload, tJWThmac, pNumBits) into tJWTDecodedA["valid"]
		#
 
		put JsonImport(base64Decode(tJWTheader)) into tJWTDecodedA["header"]
		put JsonImport(base64Decode(tJWTpayload)) into tJWTDecodedA["payload"]

		if tJWTDecodedA["valid"] is TRUE then
			put "" into tJWTDecodedA["response"]
		else
			put "HTTP/1.0 401 Unauthorized" into tJWTDecodedA["response"]

			rigLogMessage "debug", "The token was not able to be decoded."
		end if
  
	else
		put FALSE into tJWTDecodedA["valid"]
		put empty into tJWTDecodedA["header"]
		put empty into tJWTDecodedA["payload"]
		put "HTTP/1.0 400 Bad Request" into tJWTDecodedA["response"]

		rigLogMessage "debug", "No token was able to be extracted."
	end if -- if (pToken <> empty) and (the number of items of pToken is 3) then

	return tJWTDecodedA
end rigJWTdecode







/*----------------------------------------------------------------------
--| FUNCTION _rigJWTVerifySig
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2016-07-13
--| Last Mod: 2018-11-09
--| Requires: rigLogMessage, _rigHmacSha2b64(), _rigJWTpurge
--|
--| Summary: Verify signature of token received.
--| 
--| Format:  _rigJWTVerifySig(param1, param2, param3, param4)
--|
--| Parameters: string <pHeaderEncoded>, string <pPayloadEncoded>, string <pJWThmac>,
--| 						integer <pNumBits> the number of bits of the hash function
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigJWTVerifySig pHeaderEncoded pPayloadEncoded pJWThmac pNumBits
  local tSecretFile, tJWTsecret, tJWTheaderPayload, tJWThmac
  
  put gRigA["APPPATH"] & "config/jwt.lc" into tSecretFile
  if there is a file tSecretFile then
    put url ("binfile:" & tSecretFile) into tJWTsecret
    put base64Decode(tJWTsecret) into tJWTsecret
  else
		rigLogMessage "error", "Failed to read file jwt.lc!", TRUE
		return FALSE
  end if
	
	put pHeaderEncoded & "." & pPayloadEncoded into tJWTheaderPayload

	put _rigHmacSha2b64(tJWTheaderPayload, tJWTsecret, pNumBits) into tJWThmac
	_rigJWTpurge tJWThmac

	return (tJWThmac is pJWThmac)
end _rigJWTVerifySig







/*----------------------------------------------------------------------
--| FUNCTION _rigJWTgenerateSecret
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2016-07-08
--| Last Mod: 2016-07-08
--| Requires: rigLogMessage
--|
--| Summary: Generate a random secret.
--| 
--| Format:  _rigJWTgenerateSecret()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigJWTgenerateSecret
  local tSecret, tSecretFile
  
  put base64Encode(randomBytes(64)) into tSecret
  put gRigA["APPPATH"] & "config/jwt.lc" into tSecretFile
  put tSecret into URL ("binfile:" & tSecretFile)
  
  if the result is not empty then
    rigLogMessage "error", "Failed to write to file jwt.lc!", TRUE
  end if
  
  return tSecret
end _rigJWTgenerateSecret







/*----------------------------------------------------------------------
--| FUNCTION _rigHmacSha2b64
--|
--| Author: Mark Smith
--| Modification: rabit
--| Version:  1.1
--| Created: 2009-09-09
--| Last Mod: 2018-11-11
--| Requires: rigHmacSha2()
--|
--| Summary: Return signature using a header concatenated with a payload and a secret.
--| 
--| Format: _rigHmacSha2b64(param1, param2, param3)
--|
--| Parameters: string <pMsg>, string <pKey>, integer <pNumBits> the number of bits
--|               of the hash function
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigHmacSha2b64 pMsg pKey pNumBits
  return base64encode(rigHmacSha2(pMsg, pKey, pNumBits))
end _rigHmacSha2b64






/*----------------------------------------------------------------------
--| FUNCTION rigHmacSha2
--|
--| Author: Mark Smith
--| Modification: rabit
--| Version:  1.1
--| Created: 2009-09-09
--| Last Mod: 2018-11-11
--| Requires: _rigsHa2()
--|
--| Summary: Encode string using a secret.
--| 
--| Format:  rigHmacSha2(param1, param2, param3)
--|
--| Parameters: string <pMsg>, string <pKey>, integer <pNumBits> the number of
--|               bits of the hash function
--|
--| Return: string
----------------------------------------------------------------------*/

function rigHmacSha2 pMsg, pKey, pNumBits
  local tBlockSize, ipad, opad
  
  if pNumBits > 256 then
    put 128 into tBlockSize
  else
    put 64 into tBlockSize
  end if
		 
  if length(pKey) > tBlockSize then
    put _rigsHa2(pKey,,pNumBits) into pKey
  end if
	
  repeat tBlockSize - length(pKey)
    put null after pKey
  end repeat
  
  repeat for each byte b in pKey
    put numtobyte(bytetonum(b) bitXor 54) after ipad
    put numtobyte(bytetonum(b) bitXor 92) after opad
  end repeat

  return _rigsHa2(opad & _rigsHa2(ipad & pMsg,,pNumBits),,pNumBits)
end rigHmacSha2






/*----------------------------------------------------------------------
--| FUNCTION _rigsHa2
--|
--| Author: Marc Smith
--| Modification: rabit
--| Version:  1.1
--| Created: 2009-09-09
--| Last Mod: 2018-11-09
--| Requires: _rigJWTSetInput, _rigInitSha256consts, _rigInitSha256vars, _rigNextChunk(),
--|            _rigProcessChunkSha256
--|
--| Summary: Used by rigHmacSha2 to encode a string using a secret.
--| 
--| Format: _rigsHa2(param1, param2, param3)
--|
--| Parameters: string <pInput>, bool <pIsFile>, integer <NumBits> the number of
--|               bits of the hash function
--|
--| Return: binary string
----------------------------------------------------------------------*/

private function _rigsHa2 pInput, pIsFile, pNumBits
  local tChunk, tDigestType
  
	set the itemDel to "."
	
	if item 1 of the version < 9 then
		_rigJWTSetInput pInput, pIsFile

		_rigInitSha256consts
		_rigInitSha256vars

		repeat
			put _rigNextChunk() into tChunk
			if tChunk is not empty then
				_rigProcessChunkSha256 tChunk
			else
				exit repeat
			end if
		end repeat

		return binaryencode("M8", sH0,sH1,sH2,sH3,sH4,sH5,sH6,sH7) 
	end if -- if item 1 of the version < 9
 
	set the itemDel to ","
	if pNumBits is among the items of "256,384,512" then
    put "SHA-" & pNumBits into tDigestType
    return messageDigest(pInput, tDigestType)
	end if -- if pNumBits is among the items of "256,384,512"
 
	return messageDigest(pInput, "SHA-512")
end _rigsHa2





/*----------------------------------------------------------------------
--| COMMAND _rigJWTSetInput
--|
--| Author: Mark Smith
--| Version:  1.0
--| Created: 2009-09-09
--| Last Mod: 2009-09-09
--| Requires: rigFileSize(), _rigDataSizeBytes()
--|
--| Summary: Prepare script local vars using string.
--| 
--| Format: _rigJWTSetInput param1[, param2]
--|
--| Parameters: mixed <pSource>, bool <pIsFile> (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigJWTSetInput pSource, pIsFile
  local tRem
  
  put 0 into sDataSize
  put 0 into sBytesDone
  put pSource into sSource
  put empty into sTail
   
  if pIsFile and there is a file pSource then
    put true into sIsFile
    open file sSource for binary read
    put rigFileSize(sSource) into sDataSize
  else
    put false into sIsFile
    put length(sSource) into sDataSize
  end if
   
  put sDataSize mod 64 into tRem
   
  if tRem = 0 then
    put binaryencode("M16", 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0) into sTail["u"]
    put numtobyte(128) into byte 1 of sTail["u"]
  else if tRem > 55 then
    repeat 64 - tRem
      put null after sTail["p"]
    end repeat
    put numtobyte(128) into byte 1 of sTail["p"]
    put binaryencode("M16", 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0) into sTail["u"]
  else 
    repeat 64 - tRem
      put null after sTail["u"]
    end repeat
    put numtobyte(128) into byte 1 of sTail["u"]
      
  end if
   
  put _rigDataSizeBytes(sDataSize) into byte -8 to -1 of sTail["u"]
end _rigJWTSetInput






/*----------------------------------------------------------------------
--| FUNCTION _rigDataSizeBytes
--|
--| Author: Mark Smith
--| Version:  1.0
--| Created: 2009-09-09
--| Last Mod: 2009-09-09
--| Requires: --
--|
--| Summary: Convert file size to bytes.
--| 
--| Format: _rigDataSizeBytes(param1)
--|
--| Parameters: integer <pNum>
--|
--| Return: integer
----------------------------------------------------------------------*/

private function _rigDataSizeBytes pNum
  local tPow, tBits
  
  multiply pNum by 8
  repeat with n = 63 down to 0
    put 2 ^ n into tPow
    if pNum div tPow > 0 then
      put 1 after tBits
      subtract tPow from pNum
    else
      put 0 after tBits
    end if
  end repeat
  return binaryencode("B*",tBits)
end _rigDataSizeBytes






/*----------------------------------------------------------------------
--| COMMAND _rigInitSha256consts
--|
--| Author: Mark Smith
--| Version:  1.0
--| Created: 2009-09-09
--| Last Mod: 2009-09-09
--| Requires: --
--|
--| Summary: Define constants used for encoding.
--| 
--| Format: _rigInitSha256consts
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigInitSha256consts
  local tConsts, tCount
  
  if keys(sK) is empty then
    put "1116352408,1899447441,3049323471,3921009573,961987163,1508970993,2453635748," & \
    "2870763221,3624381080,310598401,607225278,1426881987,1925078388,2162078206," & \
    "2614888103,3248222580,3835390401,4022224774,264347078,604807628,770255983," & \
    "1249150122,1555081692,1996064986,2554220882,2821834349,2952996808,3210313671," & \
    "3336571891,3584528711,113926993,338241895,666307205,773529912,1294757372,1396182291," & \
    "1695183700,1986661051,2177026350,2456956037,2730485921,2820302411,3259730800,3345764771," & \
    "3516065817,3600352804,4094571909,275423344,430227734,506948616,659060556,883997877," & \
    "958139571,1322822218,1537002063,1747873779,1955562222,2024104815,2227730452," & \
    "2361852424,2428436474,2756734187,3204031479,3329325298" into tConsts
       
    put 0 into tCount
    repeat for each item i in tConsts
      put i into sK[tCount]
      add 1 to tCount
    end repeat
  end if
end _rigInitSha256consts







/*----------------------------------------------------------------------
--| COMMAND _rigInitSha256vars
--|
--| Author: Mark Smith
--| Version:  1.0
--| Created: 2009-09-09
--| Last Mod: 2009-09-09
--| Requires: --
--|
--| Summary: Define variables used for encoding.
--| 
--| Format: _rigInitSha256vars
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigInitSha256vars
  put 1779033703 into sH0
  put 3144134277 into sH1
  put 1013904242 into sH2
  put 2773480762 into sH3
  put 1359893119 into sH4
  put 2600822924 into sH5
  put 528734635 into sH6
  put 1541459225 into sH7
end _rigInitSha256vars







/*----------------------------------------------------------------------
--| FUNCTION _rigNextChunk
--|
--| Author: Mark Smith
--| Version:  1.0
--| Created: 2009-09-09
--| Last Mod: 2009-09-09
--| Requires: --
--|
--| Summary: Generate data chunk used for encoding input data.
--| 
--| Format: _rigNextChunk()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigNextChunk
  local tChunk, tChunkSize
  
  put empty into tChunk
   
  if (sBytesDone < sDataSize) and (sDataSize > 0) then
       
    if sIsFile then
      read from file sSource for 64
      put it into tChunk
    else
      put byte (sBytesDone + 1) to (sBytesDone + 64) of sSource into tChunk
    end if
       
    put length(tChunk) into tChunkSize
    add tChunkSize to sBytesDone
      
    if tChunkSize < 56 then
      put sTail["u"] after tChunk
      delete variable sTail
      if sIsFile then 
        close file sSource
      end if
    else if tChunksize > 55 and tChunkSize < 64 then
      put sTail["p"] after tChunk
    end if
       
  else
    if sTail["u"] is not empty then
      put sTail["u"] into tChunk
      delete variable sTail
      if sIsFile then close file sSource
    end if
  end if
    
  return tChunk
end _rigNextChunk






/*----------------------------------------------------------------------
--| COMMAND _rigProcessChunkSha256
--|
--| Author: Mark Smith
--| Version:  1.0
--| Created: 2009-09-09
--| Last Mod: 2009-09-09
--| Requires: _rigChunkToArray()
--|
--| Summary: Process data chunk used for encoding input data.
--| 
--| Format: _rigProcessChunkSha256 param1
--|
--| Parameters: string <pChunk>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigProcessChunkSha256 pChunk
  local w, tNum, temp1, temp2, s0, s1, a, b, c, d, e, f, g, h
  local temp3, maj, t2, ch, t1
  
  put _rigChunkToArray(pChunk) into w
   
  # MAKE SUBCHUNKS
  repeat with i = 16 to 63
    put w[i-15] * 33554432 into tNum
    if tNum > 4294967295 then
      put tNum mod 4294967295 into temp1
      if temp1 = 0 then 
        put 4294967295 into temp1
      end if
    else
      put tNum into temp1
    end if
      
    put w[i-15] * 16384 into tNum
    if tNum > 4294967295 then
      put tNum mod 4294967295 into temp2
      if temp2 = 0 then 
        put 4294967295 into temp2
      end if
    else
      put tNum into temp2
    end if
      
    put temp1 bitXor temp2 bitXor (w[i-15] div 8) into s0

    put w[i-2] * 32768 into tNum
    if tNum > 4294967295 then
      put tNum mod 4294967295 into temp1
      if temp1 = 0 then 
        put 4294967295 into temp1
      end if
    else
      put tNum into temp1
    end if
      
    put w[i-2] * 8192 into tNum
    if tNum > 4294967295 then
      put tNum mod 4294967295 into temp2
      if temp2 = 0 then 
        put 4294967295 into temp2
      end if
    else
      put tNum into temp2
    end if
      
    put temp1 bitXor temp2 bitXor (w[i-2] div 1024) into s1
  
    put (w[i-16] + s0 + w[i-7] + s1) mod 4294967296 into w[i]
  end repeat
   
  # main processing loop
  put sH0 into a
  put sH1 into b
  put sH2 into c
  put sH3 into d
  put sH4 into e
  put sH5 into f
  put sH6 into g
  put sH7 into h
   
  repeat with i = 0 to 63
    put a * 1073741824 into tNum
    if tNum > 4294967295 then
      put tNum mod 4294967295 into temp1
      if temp1 = 0 then 
        put 4294967295 into temp1
      end if
    else
      put tNum into temp1
    end if
      
    put a * 524288 into tNum
    if tNum > 4294967295 then
      put tNum mod 4294967295 into temp2
      if temp2 = 0 then 
        put 4294967295 into temp2
      end if
    else
      put tNum into temp2
    end if
      
    put a * 1024 into tNum
    if tNum > 4294967295 then
      put tNum mod 4294967295 into temp3
      if temp3 = 0 then 
        put 4294967295 into temp3
      end if
    else
      put tNum into temp3
    end if
      
    put temp1 bitXor temp2 bitXor temp3 into s0
      
      
    put (a bitAnd b) bitXor (a bitAnd c) bitXor (b bitAnd c) into maj
    put (s0 + maj) mod 4294967296 into t2

    put e * 67108864 into tNum
    if tNum > 4294967295 then
      put tNum mod 4294967295 into temp1
      if temp1 = 0 then 
        put 4294967295 into temp1
      end if
    else
      put tNum into temp1
    end if
      
    put e * 2097152 into tNum
    if tNum > 4294967295 then
      put tNum mod 4294967295 into temp2
      if temp2 = 0 then 
        put 4294967295 into temp2
      end if
    else
      put tNum into temp2
    end if
      
    put e * 128 into tNum
    if tNum > 4294967295 then
      put tNum mod 4294967295 into temp3
      if temp3 = 0 then 
        put 4294967295 into temp3
      end if
    else
      put tNum into temp3
    end if
      
    put temp1 bitXor temp2 bitXor temp3 into s1
       
    put (e bitAnd f) bitXor ((bitNot e) bitAnd g) into ch
    put (h + s1 + ch + sK[i] + w[i]) mod 4294967296 into t1
      
    put g into h
    put f into g
    put e into f
    put (d + t1) mod 4294967296 into e
    put c into d
    put b into c
    put a into b
    put (t1 + t2) mod 4294967296 into a
  end repeat

  put (sH0 + a) mod 4294967296 into sH0
  put (sH1 + b) mod 4294967296 into sH1
  put (sH2 + c) mod 4294967296 into sH2
  put (sH3 + d) mod 4294967296 into sH3
  put (sH4 + e) mod 4294967296 into sH4
  put (sH5 + f) mod 4294967296 into sH5
  put (sH6 + g) mod 4294967296 into sH6
  put (sH7 + h) mod 4294967296 into sH7
end _rigProcessChunkSha256





/*----------------------------------------------------------------------
--| FUNCTION _rigChunkToArray
--|
--| Author: Mark Smith
--| Modification: rabit
--| Version:  1.0
--| Created: 2009-09-09
--| Last Mod: 2016-07-10
--| Requires: --
--|
--| Summary: Convert input data chunk used for encoding into an array.
--| 
--| Format: _rigChunkToArray(param1)
--|
--| Parameters: string <pChunk>
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigChunkToArray pChunk
  local bNum, count, tArray
  
  put empty into bNum
  put 0 into count
  repeat with n = 1 to 64 - 4 step 4
    get binarydecode("M", byte n to n + 3 of pChunk, bNum)
    put bNum into tArray[count]
    add 1 to count
  end repeat
  return tArray
end _rigChunkToArray




/*----------------------------------------------------------------------
--| COMMAND _rigJWTpurge
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2017-06-06
--| Last Mod: 2017-06-06
--| Requires: --
--|
--| Summary: Remove CR and "=" from JWT elements.
--| 
--| Format: _rigJWTpurge param1
--|
--| Parameters: string <pStr>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigJWTpurge @pStr
  replace return with "" in pStr
  replace "=" with "" in pStr
end _rigJWTpurge





/*----------------------------------------------------------------------
--| COMMAND _rigJWTTypeNum
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2018-11-09
--| Last Mod: 2018-11-09
--| Requires: --
--|
--| Summary: Check number of bits of the hash function.
--| 
--| Format:  _rigJWTTypeNum param1
--|
--| Parameters: mixed <pNumBits>
--|
--| Return: integer
----------------------------------------------------------------------*/

private command _rigJWTTypeNum @pNumBits
  if pNumBits is not a number then
    if item 1 of the version < 9 then
      put 256 into pNumBits
    else
      put 512 into pNumBits
    end if
  else
    if pNumBits is not among the items of "256,384,512" then
      if item 1 of the version < 9 then
        put 256 into pNumBits
      else
        put 512 into pNumBits
      end if
    end if -- if pNumBits is among the items of "256,384,512"
  end if -- if pNumBits is not a number
end _rigJWTTypeNum








--| END OF jwtHelper.livecodescript
--| Location:  ./system/helpers/jwtHelper.livecodescript
----------------------------------------------------------------------