script "Email"

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
# revIgniter Email Library
#
# Permits email to be sent using Mail, Sendmail, or SMTP.
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Mail
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/email.html
##

## ------------------------------------------------------------------------



global gRigA

local sEmailA ----- keys are: mailUseragent, mailpath, smtpHost, smtpUser, smtpPass, smtpPort, smtpTimeout,
                ----- wrapchars, charset, validate, bccBatchMode, bccBatchSize, altMessage, mailtype, wordwrap,
                ----- protocol, priority, mailNewline, crlf
                
local sEmailArrayKeys, sValidSetHandlers, sMultipart, sSendMultipart, sStackInUse

local _sSubject, _sBody, _sFinalbody, _sAltBoundary, _sAtcBoundary
local _sHeaderStr, _sSmtpConnect, _sEncoding, _sIP, _sSmtpAuth, _sReplytoFlag, _sDebugMsg
local _sRecipients, _sCcArray, _sBccArray, _sHeaders, _sAttachName
local _sAttachType, _sAttachDisp, _sProtocols, _sBaseCharsets, _sBitDepths, _sPriorities, _sSmtpReply
local _sSmtpError, _sSmtpSuccess, _sSmtpReadyForNextCommand






 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-11
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
        rigLogMessage "debug", "Email Library Loaded"
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
  put "revIgniter" into sEmailA["mailUseragent"]
  put "/usr/sbin/sendmail" into sEmailA["mailpath"]    -- Sendmail path
  put "sendmail" into sEmailA["protocol"]                -- sendmail or smtp
  put "25" into sEmailA["smtpPort"]                      -- SMTP Port
  put 300000 into sEmailA["smtpTimeout"]               -- SMTP Timeout in milliseconds
  put TRUE into sEmailA["wordwrap"]                     -- TRUE/FALSE  Turns word-wrap on/off
  put "76" into sEmailA["wrapchars"]                    -- Number of characters to wrap at
  put "text" into sEmailA["mailtype"]                     -- text/html  Defines email formatting
  put "utf-8" into sEmailA["charset"]                    -- Default char set: iso-8859-1 or us-ascii
  put "mixed" into sMultipart                              -- "mixed" (in the body) or "related" (separate)
  put FALSE into sEmailA["validate"]									  -- TRUE/FALSE.  Enables email validation
  put "3" into sEmailA["priority"]										  -- Default priority (1 - 5)
  -- put "\n" into sEmailA["mailNewline"]
  -- put "\n" into sEmailA["crlf"]
  put LF into sEmailA["mailNewline"]									  -- Default newline. CRLF or LF or numToChar(13) / numToCodepoint(13) (Use CRLF to comply with RFC 822)
  put LF into sEmailA["crlf"]													-- The RFC 2045 compliant CRLF for quoted-printable is numberToChar(13) & numberToChar(10). Apparently
  																					            -- some servers, even on the receiving end think they need to muck with CRLFs, so using LF, while
  																					            -- distasteful, is the only thing that seems to work for all environments.
  put TRUE into sSendMultipart							            -- TRUE/FALSE - Yahoo does not like multipart alternative, so this is an override.  Set to FALSE for Yahoo.
  put FALSE into sEmailA["bccBatchMode"]						   -- TRUE/FALSE  Turns on/off Bcc batch feature
  put 200 into sEmailA["bccBatchSize"]							   -- If bcc_batch_mode = TRUE, sets max number of Bccs in each batch
  put "8bit" into _sEncoding
  put FALSE into _sIP
  put FALSE into _sSmtpAuth
  put FALSE into _sReplytoFlag
  put "sendmail" into _sProtocols[1]
  put "smtp" into _sProtocols[2]
  put "us-ascii" into _sBaseCharsets[1]			            -- 7-bit charsets (excluding language suffix)
  put "iso-2022-" into _sBaseCharsets[2]		            -- 7-bit charsets (excluding language suffix)
  put "7bit" into _sBitDepths[1]
  put "8bit" into _sBitDepths[2]
  put "1 (Highest)" into _sPriorities[1]
  put "2 (High)" into _sPriorities[2]
  put "3 (Normal)" into _sPriorities[3]
  put "4 (Low)" into _sPriorities[4]
  put "5 (Lowest)" into _sPriorities[5]
  put "mailUseragent,mailpath,smtpHost,smtpUser,smtpPass,smtpPort,smtpTimeout,wrapchars,charset,validate,bccBatchMode,bccBatchSize,altMessage,mailtype,wordwrap,protocol,priority,mailNewline,crlf" into sEmailArrayKeys

  put "rigSet_sAltMessage,rigSet_altMessage,rigSet_mailtype,rigSet_wordwrap,rigSet_protocol,rigSet_priority,rigSet_mailNewline,rigSet_crlf" into sValidSetHandlers
end _rigSetDefaultValues






/*----------------------------------------------------------------------
--| COMMAND rigRunInitialEmailConfig
--|
--| Author: rabit
--| Version:  1.3
--| Created: 14-08-09
--| Last Mod: 22-12-14
--| Requires: rigInitializeMail
--|
--| Summary: Run initial configuration procedures.
--| 
--| Format:  rigRunInitialEmailConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialEmailConfig pConfig
  local tConfig
  
	put pConfig into tConfig

	if tConfig is not an array then
		if tConfig is not empty then
			split tConfig using numToCodepoint(1) and numToCodepoint(2)
		end if
	end if

	if tConfig is an array then
		rigInitializeMail tConfig
	else
		if (sEmailA["smtpUser"] is "") and (sEmailA["smtpPass"] is "") then
			put FALSE into _sSmtpAuth
		else
			put TRUE into _sSmtpAuth
		end if
	end if
end rigRunInitialEmailConfig






/*----------------------------------------------------------------------
--| COMMAND rigInitializeMail
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-08-14
--| Last Mod: 2019-01-04
--| Requires: rigClearMail, _rigSetInitialMailValue
--|
--| Summary: Initialize preferences.
--| 
--| Format:  rigInitializeMail param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigInitializeMail pConfig
  local tKey, tVal, tHandler
  
	rigClearMail

	if pConfig is an array then
		repeat for each key tKey in pConfig
			put pConfig[tKey] into tVal

			## CHECK IF VARIABLE WITH NAME tKey IS SET ???????????????????????
			# 
			put "rigSet_" & tKey into tHandler
			if tHandler is among the items of sValidSetHandlers then
				do tHandler && tVal
			else
				_rigSetInitialMailValue tKey, tVal
			end if		
	
		end repeat
	end if

	if (sEmailA["smtpUser"] is "") and (sEmailA["smtpPass"] is "") then
		put FALSE into _sSmtpAuth
	else
		put TRUE into _sSmtpAuth
	end if
end rigInitializeMail








/*----------------------------------------------------------------------
--| COMMAND _rigSetInitialMailValue
--|
--| Author: rabit
--| Version:  1.1
--| Created: 15-08-09
--| Last Mod: 20-09-09
--| Requires: rigClearMail
--|
--| Summary: Set initial values.
--| 
--| Format:  _rigSetInitialMailValue param1, param2
--|
--| Parameters: string <pKey>, mixed <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetInitialMailValue pKey pValue
  if pKey is among the items of sEmailArrayKeys then
    put pValue into sEmailA[pKey]
  end if
end _rigSetInitialMailValue







/*----------------------------------------------------------------------
--| COMMAND rigClearMail
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-08-09
--| Last Mod: 14-08-09
--| Requires: _rigSetHeader, _rigSetDate()
--|
--| Summary: Initialize the Email Data.
--| 
--| Format:  rigClearMail param1
--|
--| Parameters: bool <pClearAttachments>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigClearMail pClearAttachments
  local tClearAttachments, tDate
  
	if pClearAttachments is "" then
		put FALSE into tClearAttachments
	else
		put pClearAttachments into tClearAttachments
	end if

	put empty into _sSubject
	put empty into _sBody
	put empty into _sFinalbody
	put empty into _sHeaderStr
	put FALSE into _sReplytoFlag
	put empty into _sRecipients
	put empty into _sHeaders
	put empty into _sDebugMsg

	_rigSetHeader "User-Agent", sEmailA["mailUseragent"]

	put _rigSetDate() into tDate
	_rigSetHeader "Date", tDate

	if tClearAttachments is not FALSE then
		put empty into _sAttachName
		put empty into _sAttachType
		put empty into _sAttachDisp
	end if
end rigClearMail








/*----------------------------------------------------------------------
--| COMMAND rigMailFrom
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-08-15
--| Last Mod: 2017-06-27
--| Requires: _rigStrToArray(), _rigValidateEmail(), rigAddCslashes(), _rigPrepQencoding(), _rigSetHeader
--|
--| Summary: Set From.
--| 
--| Format:  rigMailFrom param1, param2
--|
--| Parameters: string <pFrom>, string <pName>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigMailFrom pFrom, pName
  local tRegEx, tFoundTextVar, tFrom, tFromArray, tCharsList
  local tFromHeaderVal, tReturnHeaderVal
  
	put "\<(.*)\>" into tRegEx
	put empty into tFoundTextVar -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	get matchText(pFrom,tRegEx,tFoundTextVar)

    	if it is TRUE then
       	put tFoundTextVar into tFrom
	else
		put pFrom into tFrom
    	end if

	if sEmailA["validate"] is TRUE then
		put _rigStrToArray(tFrom) into tFromArray
		get _rigValidateEmail(tFromArray)
	end if

	# PREPARE THE DISPLAY NAME
	if pName is not empty then
    # ONLY USE Q ENCODING IF THERE ARE CHARACTERS THAT WOULD REQUIRE IT
    # OCTAL VALUES ARE USED HERE (128 - 255 AS DECIMAL VALUES)
    put "[\200-\377]" into tRegEx
    get matchText(pName,tRegEx)
		if it is not TRUE then
			# ADD SLASHES FOR NON-PRINTING CHARACTERS, SLASHES, AND DOUBLE QUOTES, AND SURROUND IT IN DOUBLE QUOTES
			# OCTAL VALUES ARE USED HERE (0 - 31 AND 127 AS DECIMAL VALUES)
			put "\0..\37,\177,'," & quote & ",\" into tCharsList
			put quote & rigAddCslashes(pName, tCharsList) & quote into pName
		else
			put _rigPrepQencoding(pName, TRUE) into pName
		end if

	end if

	put pName && "<" & tFrom & ">" into tFromHeaderVal
	_rigSetHeader "From", tFromHeaderVal
	put "<" & tFrom & ">" into tReturnHeaderVal
	_rigSetHeader "Return-Path", tReturnHeaderVal
end rigMailFrom







/*----------------------------------------------------------------------
--| COMMAND rigReplyTo
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-08-16
--| Last Mod: 2017-06-27
--| Requires: _rigStrToArray(), _rigValidateEmail(), _rigSetHeader
--|
--| Summary: Set reply-to.
--| 
--| Format:  rigReplyTo param1, param2
--|
--| Parameters: string <pReplyto>, string <pName>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigReplyTo pReplyto pName
  local tName, tRegEx, tFoundTextVar, tReplyto, tReplyArray, tReplyHeaderVal
  
	put pName into tName

	put "\<(.*)\>" into tRegEx
	put empty into tFoundTextVar -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	get matchText(pReplyto,tRegEx,tFoundTextVar)

    	if it is TRUE then
       	put tFoundTextVar into tReplyto
	else
		put pReplyto into tReplyto
    	end if

	if sEmailA["validate"] is TRUE then
		put _rigStrToArray(tReplyto) into tReplyArray
		get _rigValidateEmail(tReplyArray)
	end if

	if tName is empty then
		put tReplyto into tName
	end if

	if char 1 of tName is not quote then
		put quote & tName & quote into tName
	end if

	put tName && "<" & tReplyto & ">" into tReplyHeaderVal
	_rigSetHeader "Reply-To", tReplyHeaderVal

	put TRUE into _sReplytoFlag
end rigReplyTo








/*----------------------------------------------------------------------
--| COMMAND rigMailTo
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-08-16
--| Last Mod: 2019-01-04
--| Requires: _rigStrToArray(), _rigCleanEmail(), _rigValidateEmail(), _rigGetProtocol(), _rigSetHeader
--|
--| Summary: Set recipients.
--| 
--| Format:  rigMailTo param1
--|
--| Parameters: mixed <pTo>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigMailTo pTo
  local tTo, tProtocol, tToString
  
  put _rigStrToArray(pTo) into tTo
  put _rigCleanEmail(tTo) into tTo

  if sEmailA["validate"] is TRUE then
    get _rigValidateEmail(tTo)
  end if

  put _rigGetProtocol() into tProtocol

  put tTo into tToString
  combine tToString using comma
  replace comma with ", " in  tToString
  _rigSetHeader "To", tToString

  switch tProtocol
    case "smtp"
      put tTo into _sRecipients
    break
    case "sendmail"
      put tTo into tToString
      combine tToString using comma
      replace comma with ", " in  tToString
      put tToString into _sRecipients
  end switch
end rigMailTo







/*----------------------------------------------------------------------
--| COMMAND rigMailCC
--|
--| Author: rabit
--| Version:  1.0
--| Created: 16-08-09
--| Last Mod: 16-08-09
--| Requires: _rigStrToArray(), _rigCleanEmail(), _rigValidateEmail(), _rigSetHeader, _rigGetProtocol()
--|
--| Summary: Set CC.
--| 
--| Format:  rigMailCC param1
--|
--| Parameters: string <pCC>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigMailCC pCC
  local tCC, tCCString, tProtocol
  
	put _rigStrToArray(pCC) into tCC
	put _rigCleanEmail(tCC) into tCC

	if sEmailA["validate"] is TRUE then
		get _rigValidateEmail(tCC)
	end if

	put tCC into tCCString
	combine tCCString using comma
	replace comma with ", " in  tCCString
	_rigSetHeader "Cc", tCCString

	put _rigGetProtocol() into tProtocol
	if  tProtocol is "smtp" then
		put tCC into _sCcArray
	end if
end rigMailCC







/*----------------------------------------------------------------------
--| COMMAND rigMailBcc
--|
--| Author: rabit
--| Version:  1.0
--| Created: 16-08-09
--| Last Mod: 16-08-09
--| Requires: _rigStrToArray(), _rigCleanEmail(), _rigValidateEmail(), _rigSetHeader, _rigGetProtocol()
--|
--| Summary: Set BCC.
--| 
--| Format:  rigMailBcc param1, param2
--|
--| Parameters: string <pBcc>, string <pLimit>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigMailBcc pBcc pLimit
  local tBcc, tProtocol, tBccItems, tBccString
  
	if (pLimit is not empty) and (pLimit is a number) then
		put TRUE into sEmailA["bccBatchMode"]
		put pLimit into sEmailA["bccBatchSize"]
	end if

	put _rigStrToArray(pBcc) into tBcc
	put _rigCleanEmail(tBcc) into tBcc

	if sEmailA["validate"] is TRUE then
		get _rigValidateEmail(tBcc)
	end if

	put _rigGetProtocol() into tProtocol
	put the number of lines in the keys of tBcc into tBccItems

	if (tProtocol is "smtp") or ((sEmailA["bccBatchMode"] is TRUE) and (tBccItems > sEmailA["bccBatchSize"])) then
		put tBcc into _sBccArray
	else
		put tBcc into tBccString
		combine tBccString using comma
		replace comma with ", " in  tBccString
		_rigSetHeader "Bcc", tBccString
	end if
end rigMailBcc







/*----------------------------------------------------------------------
--| COMMAND rigMailSubject
--|
--| Author: rabit
--| Version:  1.1
--| Created: 16-08-09
--| Last Mod: 22-09-09
--| Requires: _rigSetHeader
--|
--| Summary: Set email subject.
--| 
--| Format:  rigMailSubject param1
--|
--| Parameters: string <pSubject>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigMailSubject pSubject
  local tSubject

  put _rigPrepQencoding(pSubject) into tSubject

	_rigSetHeader "Subject", tSubject
end rigMailSubject







/*----------------------------------------------------------------------
--| COMMAND rigMailMessage
--|
--| Author: rabit
--| Version:  1.1
--| Created: 16-08-09
--| Last Mod: 22-12-14
--| Requires: rigRTrim(), rigStripSlashes
--|
--| Summary: Set body.
--| 
--| Format:  rigMailMessage param1
--|
--| Parameters: string <pBody>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigMailMessage pBody
  local tBody
  
	put pBody into tBody

	replace numToCodepoint(13) with "" in tBody
	put rigRTrim(tBody) into tBody
	put rigStripSlashes(tBody) into _sBody
end rigMailMessage








/*----------------------------------------------------------------------
--| COMMAND rigMailAttach
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-08-17
--| Last Mod: 2019-01-12
--| Requires: _rigMimeTypes()
--|
--| Summary: Assign file attachments.
--| 
--| Format:  rigMailAttach param1, param2
--|
--| Parameters: string <pFilename>, string <pDisposition>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigMailAttach pFilename, pDisposition
  local tDisposition, tNameItems, tTypeItems, tDispItems, tExtension
  
	if pDisposition is empty then
		put "attachment" into tDisposition
	else
		put pDisposition into tDisposition
	end if

	if _sAttachName is an array then
		put the number of lines in the keys of _sAttachName into tNameItems
	else
		put 0 into tNameItems
	end if

	if _sAttachType is an array then
		put the number of lines in the keys of _sAttachType into tTypeItems
	else
		put 0 into tTypeItems
	end if

	if _sAttachDisp is an array then
		put the number of lines in the keys of _sAttachDisp into tDispItems
	else
		put 0 into tDispItems
	end if

	add 1 to tNameItems
	add 1 to tTypeItems
	add 1 to tDispItems
  
  
  # USE ABSOLUTE PATH
  replace "\" with "/" in pFilename
  put rigTrim(pFilename, "/") into pFilename
  if not rigIsAbsolutePath(pFilename, TRUE) then
    put the defaultfolder & "/" & pFilename into pFilename
  else
    put "/" & pFilename into pFilename
  end if
  
	put pFilename into _sAttachName[tNameItems]

	set the itemDelimiter to "."
	put item -1 of pFilename into tExtension
	put _rigMimeTypes(tExtension) into _sAttachType[tTypeItems]

	put tDisposition into _sAttachDisp[tDispItems] -- Can also be "inline" 
end rigMailAttach








/*----------------------------------------------------------------------
--| COMMAND _rigSetHeader
--|
--| Author: rabit
--| Version:  1.0
--| Created: 15-08-09
--| Last Mod: 15-08-09
--| Requires: _rigSetHeader, _rigSetDate()
--|
--| Summary: Initialize the Email Data.
--| 
--| Format:  _rigSetHeader param1, param2
--|
--| Parameters: string <pHeader>, string <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetHeader pHeader, pValue
	put pValue into _sHeaders[pHeader]
end _rigSetHeader








/*----------------------------------------------------------------------
--| COMMAND rigSet_sAltMessage
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-08-09
--| Last Mod: 17-08-09
--| Requires: --
--|
--| Summary: Set multipart value.
--| 
--| Format:  rigSet_sAltMessage param1
--|
--| Parameters: string <pStr>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSet_sAltMessage pStr
	rigSet_altMessage
end rigSet_sAltMessage






/*----------------------------------------------------------------------
--| COMMAND rigSet_altMessage
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-04
--| Last Mod: 2019-01-04
--| Requires: --
--|
--| Summary: Set multipart value.
--| 
--| Format:  rigSet_altMessage param1
--|
--| Parameters: string <pStr>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSet_altMessage pStr
	put pStr into sEmailA["altMessage"]
end rigSet_altMessage






/*----------------------------------------------------------------------
--| COMMAND rigSet_mailtype
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-08-09
--| Last Mod: 17-08-09
--| Requires: --
--|
--| Summary: Set mailtype.
--| 
--| Format:  rigSet_mailtype param1
--|
--| Parameters: string <pType>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSet_mailtype pType
	if pType is "html" then
		put "html" into sEmailA["mailtype"]
	else
		put "text" into sEmailA["mailtype"]
	end if
end rigSet_mailtype







/*----------------------------------------------------------------------
--| COMMAND rigSet_wordwrap
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-08-09
--| Last Mod: 17-08-09
--| Requires: --
--|
--| Summary: Set wordwrap.
--| 
--| Format:  rigSet_wordwrap param1
--|
--| Parameters: bool <pWordwrap>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSet_wordwrap pWordwrap
	if pWordwrap is not FALSE then
		put TRUE into sEmailA["wordwrap"]
	else
		put FALSE into sEmailA["wordwrap"]
	end if
end rigSet_wordwrap







/*----------------------------------------------------------------------
--| COMMAND rigSet_protocol
--|
--| Author: rabit
--| Version:  1.1
--| Created: 17-08-09
--| Last Mod: 16-08-15
--| Requires: rigInArray()
--|
--| Summary: Set protocol.
--| 
--| Format:  rigSet_protocol param1
--|
--| Parameters: string <pProtocol>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSet_protocol pProtocol
  local tProtocol
  
	if pProtocol is empty then
		put "sendmail" into tProtocol
	else
		put pProtocol into tProtocol
	end if

	if rigInArray(_sProtocols, tProtocol) is FALSE then
		put "sendmail" into sEmailA["protocol"]
	else
		put toLower(tProtocol) into sEmailA["protocol"]
	end if
end rigSet_protocol








/*----------------------------------------------------------------------
--| COMMAND rigSet_priority
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-08-09
--| Last Mod: 17-08-09
--| Requires: --
--|
--| Summary: Set priority.
--| 
--| Format:  rigSet_priority param1
--|
--| Parameters: integer <pN>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSet_priority pN
  local tN
  
	if pN is empty then
		put 3 into tN
	else
		put pN into tN
	end if

	if (tN is not a number) or (tN < 1) or (tN > 5) then
		put 3 into sEmailA["priority"]
		exit rigSet_priority
	end if

	put tN into sEmailA["priority"]
end rigSet_priority








/*----------------------------------------------------------------------
--| COMMAND rigSet_mailNewline
--|
--| Author: rabit
--| Version:  1.2
--| Created: 17-08-09
--| Last Mod: 22-12-14
--| Requires: --
--|
--| Summary: Set newline character.
--| 
--| Format:  rigSet_mailNewline param1
--|
--| Parameters: string <pNewline>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSet_mailNewline pNewline
  local tNewline
  
	if pNewline is empty then
		-- put "\n" into tNewline
		put LF into tNewline
	else
		put pNewline into tNewline
	end if

	-- if (tNewline <> "\n") and (tNewline <> "\r\n") and (tNewline <> "\r") then
	if (tNewline <> LF) and (tNewline <> CRLF) and (tNewline <> numToCodepoint(13)) then
		-- put "\n" into sEmailA["mailNewline"]
		put LF into sEmailA["mailNewline"]
		exit rigSet_mailNewline
	end if

	put tNewline into sEmailA["mailNewline"]
end rigSet_mailNewline






/*----------------------------------------------------------------------
--| COMMAND rigSet_crlf
--|
--| Author: rabit
--| Version:  1.1
--| Created: 17-08-09
--| Last Mod: 22-12-14
--| Requires: --
--|
--| Summary: Set CRLF.
--| 
--| Format:  rigSet_crlf param1
--|
--| Parameters: string <pCRLF>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSet_crlf pCRLF
  local tCRLF
  
	if pCRLF is empty then
		-- put "\n" into tCRLF
		put LF into tCRLF
	else
		put pCRLF into tCRLF
	end if

	-- if (tCRLF <> "\n") and (tCRLF <> "\r\n") and (tCRLF <> "\r") then
	if (tCRLF <> LF) and (tCRLF <> CRLF) and (tCRLF <> numToCodepoint(13)) then
		-- put "\n" into sEmailA["crlf"]
		put LF into sEmailA["crlf"]
		exit rigSet_crlf
	end if

	put tCRLF into sEmailA["crlf"]
end rigSet_crlf







/*----------------------------------------------------------------------
--| COMMAND _rigSetBoundaries
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-08-09
--| Last Mod: 17-08-09
--| Requires: --
--|
--| Summary: Set message boundary.
--| 
--| Format:  _rigSetBoundaries 
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetBoundaries
  local tUniqueid
  
	repeat 25
        	put any char of "1234567890abcdefghijklmnopqrstuvwxyz" after tUniqueid
    	end repeat

	put "B_ALT_" & tUniqueid into _sAltBoundary -- multipart/alternative

	put empty into tUniqueid
	repeat 25
        	put any char of "1234567890abcdefghijklmnopqrstuvwxyz" after tUniqueid
    	end repeat

	put "B_ATC_" & tUniqueid into _sAtcBoundary -- attachment boundary
end _rigSetBoundaries




/*----------------------------------------------------------------------
--| FUNCTION _rigGetMessageID
--|
--| Author: rabit
--| Version:  1.2
--| Created: 17-08-09
--| Last Mod: 23-12-14
--| Requires: --
--|
--| Summary: Get the message id.
--| 
--| Format:  _rigGetMessageID()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigGetMessageID
  local tFrom, tDomain, tUniqueid
  
	put _sHeaders["Return-Path"] into tFrom
	replace ">" with "" in tFrom
	replace "<" with "" in tFrom
	
	set the itemDelimiter to "@"
	put item -1 of tFrom into tDomain
  
  # USE INTEGER AS FIRST CHAR OF ID SO THAT MESSAGE-ID IS ALWAYS SHOWN IN MAIL DEBUGGER
  put random(9) into tUniqueid
  repeat 24
    put any char of "1234567890abcdefghijklmnopqrstuvwxyz" after tUniqueid
  end repeat

  return  "<" & tUniqueid & "@" & tDomain & ">"
end _rigGetMessageID




/*----------------------------------------------------------------------
--| FUNCTION _rigGetProtocol
--|
--| Author: rabit
--| Version:  1.1
--| Created: 16-08-09
--| Last Mod: 16-08-15
--| Requires: rigInArray()
--|
--| Summary: Get mail protocol.
--| 
--| Format:  _rigGetProtocol(param1)
--|
--| Parameters: bool <pReturn>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigGetProtocol pReturn
  local tReturn
  
	if pReturn is empty then
		put TRUE into tReturn
	else
		put pReturn into tReturn
	end if

	put toLower(sEmailA["protocol"]) into sEmailA["protocol"]

	if rigInArray(_sProtocols, sEmailA["protocol"]) is FALSE then
		put "sendmail" into sEmailA["protocol"]
	end if

	if tReturn is TRUE then
		return sEmailA["protocol"]
	end if
end _rigGetProtocol




/*----------------------------------------------------------------------
--| FUNCTION _rigGetMailEncoding
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-08-09
--| Last Mod: 17-08-09
--| Requires: rigInArray()
--|
--| Summary: Get mail encoding.
--| 
--| Format:  _rigGetMailEncoding(param1)
--|
--| Parameters: bool <pReturn>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigGetMailEncoding pReturn
  local tReturn, tKey, tCharset, tCharsetLength
  
	if pReturn is empty then
		put TRUE into tReturn
	else
		put pReturn into tReturn
	end if

	if rigInArray(_sBitDepths, _sEncoding) is FALSE then
		put "8bit" into _sEncoding
	end if

	repeat for each key tKey in _sBaseCharsets
		put _sBaseCharsets[tKey] into tCharset

		put the length of tCharset into tCharsetLength
		if (the length of sEmailA["charset"] >= tCharsetLength) and ((char 1 to tCharsetLength of sEmailA["charset"]) is tCharset) then
			put "7bit" into _sEncoding
		end if
	end repeat

	if tReturn is TRUE then
		return _sEncoding
	end if 
end _rigGetMailEncoding




/*----------------------------------------------------------------------
--| FUNCTION _rigGetContentType
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-08-09
--| Last Mod: 17-08-09
--| Requires: --
--|
--| Summary: Get content type (text/html/attachment).
--| 
--| Format:  _rigGetContentType()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigGetContentType
	if (sEmailA["mailtype"] is "html") and (_sAttachName is not an array) then
		return "html"
	else if (sEmailA["mailtype"] is "html") and (_sAttachName is an array) then
		return "html-attach"
	else if (sEmailA["mailtype"] is "text") and (_sAttachName is an array) then
		return "plain-attach"
	else
		return "plain"
	end if
end _rigGetContentType




/*----------------------------------------------------------------------
--| FUNCTION _rigSetDate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 15-08-09
--| Last Mod: 15-08-09
--| Requires: rigFormValidSelectCheckboxRadio()
--|
--| Summary: Set RFC 822 date.
--| 
--| Format:  _rigSetDate()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigSetDate
	return the internet date
end _rigSetDate




/*----------------------------------------------------------------------
--| FUNCTION _rigGetMimeMessage
--|
--| Author: rabit
--| Version:  1.1
--| Created: 17-08-09
--| Last Mod: 24-07-10
--| Requires: --
--|
--| Summary: Mime message.
--| 
--| Format:  _rigGetMimeMessage()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigGetMimeMessage
	return "This is a multi-part message in MIME format." & sEmailA["mailNewline"] & "Your email application may not support this format."
end _rigGetMimeMessage





/*----------------------------------------------------------------------
--| FUNCTION _rigValidateEmail
--|
--| Author: rabit
--| Version:  1.0
--| Created: 16-08-09
--| Last Mod: 16-08-09
--| Requires: _rigSetErrorMessage, rigMailValidEmail()
--|
--| Summary: Validate email address.
--| 
--| Format:  _rigValidateEmail(param1)
--|
--| Parameters: string <pEmail>
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigValidateEmail pEmail
  local tKey, tVal
  
	if pEmail is not an array then
		_rigSetErrorMessage "email_must_be_array"
		return FALSE
	end if

	repeat for each key tKey in pEmail
		put pEmail[tKey] into tVal

		if rigMailValidEmail(tVal) is FALSE then
			_rigSetErrorMessage "email_invalid_address", tVal
			return FALSE
		end if
	end repeat

	return TRUE
end _rigValidateEmail







/*----------------------------------------------------------------------
--| FUNCTION rigMailValidEmail
--|
--| Author: rabit
--| Version:  1.0
--| Created: 16-08-09
--| Last Mod: 16-08-09
--| Requires: --
--|
--| Summary: Email validation.
--| 
--| Format:  rigMailValidEmail(param1)
--|
--| Parameters: string <pAddress>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigMailValidEmail pAddress
  local tRegEx
  
	put "(?ix)^([a-z0-9\+_\-]+)(\.[a-z0-9\+_\-]+)*@([a-z0-9\-]+\.)+[a-z]{2,6}$" into tRegEx

	return matchtext(pAddress,tRegEx)
end rigMailValidEmail







/*----------------------------------------------------------------------
--| FUNCTION _rigCleanEmail
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-08-16
--| Last Mod: 2017-06-27
--| Requires: --
--|
--| Summary: Clean extended email address: Joe Smith <joe@smith.com>.
--| 
--| Format:  _rigCleanEmail(param1)
--|
--| Parameters: mixed <pEmail>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCleanEmail pEmail
  local tRegEx, tFoundTextVar, tCounter, tAddy, tCleanEmail
  
	put "\<(.*)\>" into tRegEx
	put empty into tFoundTextVar -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	
	if pEmail is not an array then
		get matchText(pEmail,tRegEx,tFoundTextVar)

    		if it is TRUE then
			return tFoundTextVar
		else
			return pEmail
		end if
	end if

	put 0 into tCounter
	repeat for each element tAddy in pEmail
		add 1 to tCounter
		get matchText(tAddy,tRegEx,tFoundTextVar)

    		if it is TRUE then
			put tFoundTextVar into tCleanEmail[tCounter]
		else
			put tAddy into tCleanEmail[tCounter]
		end if
	end repeat

	return tCleanEmail
end _rigCleanEmail







/*----------------------------------------------------------------------
--| FUNCTION _rigGetAltMessage
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-08-17
--| Last Mod: 2017-06-27
--| Requires: _rigWord_wrap(), rigStripHTML(), rigTrim()
--|
--| Summary: Build alternative plain text message.
--|
--|                    This function provides the raw message for use
--|                    in plain-text headers of HTML-formatted emails.
--|                    If the user hasn't specified his own alternative message
--|                    it creates one by stripping the HTML.
--| 
--| Format:  _rigGetAltMessage()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigGetAltMessage
  local tRegEx, tFoundTextVar, tBody, tN, tNewLines
  
	if sEmailA["altMessage"] is not empty then
		return _rigWord_wrap(sEmailA["altMessage"], "76")
	end if

	put "(?i)\<body.*?\>(.*)\<\/body\>" into tRegEx
	put empty into tFoundTextVar -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	get matchText(_sBody,tRegEx,tFoundTextVar)
	if it is TRUE then
		put tFoundTextVar into tBody
	else
		put _sBody into tBody
	end if

	put rigStripHTML(tBody) into tBody
	put rigTrim(tBody) into tBody

	put "<!--(.*)--\>" into tRegEx
	put replaceText(tBody,tRegEx,"") into tBody

	filter tBody without empty -----------

	repeat with i = 20 down to 3
		put "" into tN

		repeat with x = 1 to i
			-- put "\n" after tN
			put LF after tN
		end repeat

		-- put replaceText(tBody,tN,"\n\n") into tBody
		put LF & LF into tNewLines
		put replaceText(tBody,tN,tNewLines) into tBody
	end repeat

	replace tab with "" in tBody -----------------

	return _rigWord_wrap(tBody, "76")
end _rigGetAltMessage




/*----------------------------------------------------------------------
--| FUNCTION _rigWord_wrap
--|
--| Author: rabit
--| Version:  1.5
--| Created: 2009-08-17
--| Last Mod: 2017-06-27
--| Requires: rigPregReplace(), rigWordWrap(), _rigUnwrappedWrapMarkersString()
--|
--| Summary: Word wrap.
--| 
--| Format:  _rigWord_wrap(param1, param2)
--|
--| Parameters: string <pStr>, integer <pCharLim>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigWord_wrap pStr pCharLim
  local tStr, tCharLim, tRegEx, tReplacement, tStrToCheck
  local tStrMarked, tMatchFound, tCounter, tFoundStr, tFoundStrLength
  local tStrOffset, tSearchStartNum, tStrLength, tStrFragment, tUnwrap
  local tOutput, tTemp, tKey, tVal
  
	put pStr into tStr
	put pCharLim into tCharLim

	# SET THE CHARACTER LIMIT
	if pCharLim is empty then
		if sEmailA["wrapchars"] is empty then
			put 76 into tCharLim
		else
			put sEmailA["wrapchars"] into tCharLim
		end if
	end if

	# REDUCE MULTIPLE SPACES
	put "( +)" into tRegEx
	put " " into tReplacement
	put rigPregReplace(tStr, tRegEx,,tReplacement) into tStr

	# STANDARDIZE NEWLINES
	if numToCodepoint(13) is in tStr then
		replace CRLF with LF in tStr
		replace numToCodepoint(13) with LF in tStr
	end if

	# IF THE CURRENT WORD IS SURROUNDED BY {UNWRAP} TAGS WE'LL
	# STRIP THE ENTIRE CHUNK AND REPLACE IT WITH A MARKER.
	put tStr into tStrToCheck
    
	put "(?s)(\{unwrap\}.+?\{/unwrap\})" into tRegEx
    
	put "" into tStrMarked
    
	put TRUE into tMatchFound
	put 0 into tCounter
    
	put empty into tFoundStr -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	repeat until tMatchFound is FALSE
		get matchText(tStrToCheck,tRegEx,tFoundStr)
        
		if it is TRUE then
			add 1 to tCounter
             
			put the length of tFoundStr into tFoundStrLength
			put offset(tFoundStr,tStrToCheck) into tStrOffset
			put tStrOffset + tFoundStrLength into tSearchStartNum
			put the length of tStrToCheck into tStrLength
             
			# THE PART OF THE STRING WITH THE FIRST MATCH
			put char tStrOffset to (tStrOffset + (tFoundStrLength - 1)) of tStrToCheck into tStrFragment
             
			# REPLACE STRING
			replace tFoundStr with "{{unwrapped" & tCounter & "}}" in tStrFragment
            
			# ADD FOUND STRING TO ARRAY
			put tFoundStr into tUnwrap[tCounter]
             
			# ADD MARK TO THE STRING
			put (char 1 to (tStrOffset -1) of tStrToCheck) & tStrFragment after tStrMarked
             
			put char tSearchStartNum to tStrLength of tStrToCheck into tStrToCheck
             
		else
			# NO MATCH FOUND
			if tStrMarked is "" then
				put tStr into tStrMarked
			else
				# ADD THE REMAINING PART TO THE STRING TO RETURN
				put tStrToCheck after tStrMarked
			end if
             
			put FALSE into tMatchFound
		end if
	end repeat

	put tStrMarked into tStr

	# USE THE FUNCTION IN COMMON.LC TO DO THE INITIAL WORDWRAP.
	# WE SET THE CUT FLAG TO FALSE SO THAT ANY INDIVIDUAL WORDS THAT ARE
	# TOO LONG GET LEFT ALONE.  IN THE NEXT STEP WE'LL DEAL WITH THEM.
	put rigWordWrap(tStr, tCharLim, LF, FALSE) into tStr

	# SPLIT THE STRING INTO INDIVIDUAL LINES OF TEXT AND CYCLE THROUGH THEM
	put "" into tOutput

    
	repeat for each line thisLine in tStr
		# IS THE LINE WITHIN THE ALLOWED CHARACTER COUNT?
		# IF SO WE'LL JOIN IT TO THE OUTPUT AND CONTINUE
		if (the length of thisLine) <= tCharLim then
			put thisLine & sEmailA["mailNewline"] after tOutput
			next repeat
		end if
        
		put "" into tTemp
        
		repeat until (the length of thisLine) <= tCharLim
			# IF THE OVER-LENGTH WORD IS A URL WE WON'T WRAP IT
			put "\[url.+\]|://|wwww." into tRegEx
			get matchText(thisLine,tRegEx)
			if it is TRUE then
				exit repeat
			end if
            
			# TRIM THE WORD DOWN
			put char 1 to (tCharLim -1) of thisLine after tTemp
			put char tCharLim to (the length of thisLine) of thisLine into thisLine
		end repeat
        
		# IF $TEMP CONTAINS DATA IT MEANS WE HAD TO SPLIT UP AN OVER-LENGTH
		# WORD INTO SMALLER CHUNKS SO WE'LL ADD IT BACK TO OUR CURRENT LINE
		if tTemp <> "" then
			put tTemp & sEmailA["mailNewline"] & thisLine after tOutput
		else
			put thisLine after tOutput
		end if
        
		put sEmailA["mailNewline"] after tOutput
	end repeat

	# PUT OUR MARKERS BACK
	if tUnwrap is an array then
		# UNWRAP MARKERS
		put _rigUnwrappedWrapMarkersString(tOutput) into tOutput

		repeat for each key tKey in tUnwrap
			put tUnwrap[tKey] into tVal
			replace "{{unwrapped" & tKey & "}}" with tVal in tOutput
		end repeat
	end if

	return tOutput
end _rigWord_wrap







/*----------------------------------------------------------------------
--| COMMAND _rigBuildHeaders
--|
--| Author: rabit
--| Version:  1.1
--| Created: 19-08-09
--| Last Mod: 26-12-09
--| Requires: _rigCleanEmail(), _rigSetHeader, _rigGetMessageID()
--|
--| Summary: Build final headers.
--| 
--| Format:  _rigBuildHeaders 
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigBuildHeaders
  local tHeadersFrom, tMessageID
  
	put _rigCleanEmail(_sHeaders["From"]) into tHeadersFrom
	_rigSetHeader "X-Sender", tHeadersFrom

	_rigSetHeader "X-Mailer", sEmailA["mailUseragent"]

	_rigSetHeader "X-Priority", _sPriorities[sEmailA["priority"]]

	put _rigGetMessageID() into tMessageID
	_rigSetHeader "Message-ID", tMessageID

	_rigSetHeader "Mime-Version", "1.0"
end _rigBuildHeaders





/*----------------------------------------------------------------------
--| COMMAND _rigWriteHeaders
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-08-19
--| Last Mod: 2019-01-04
--| Requires: rigTrim(), rigRTrim()
--|
--| Summary: Write headers as a string.
--| 
--| Format:  _rigWriteHeaders 
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigWriteHeaders
  local tKey, tVal

	put empty into _sHeaderStr
	repeat for each key tKey in _sHeaders
		put _sHeaders[tKey] into tVal

		put rigTrim(tVal) into tVal
		
		if tVal <> "" then
			put tKey & ": " & tVal & sEmailA["mailNewline"] after _sHeaderStr
		end if
	end repeat
end _rigWriteHeaders






/*----------------------------------------------------------------------
--| COMMAND _rigBuildMessage
--|
--| Author: rabit
--| Version:  1.5
--| Created: 2009-08-19
--| Last Mod: 2019-01-12
--| Requires: _rigWord_wrap(), _rigSetBoundaries, _rigWriteHeaders, _rigGetProtocol(),
--|           _rigGetContentType(), _rigGetMailEncoding(), _rigGetMimeMessage(),
--|           _rigGetAltMessage(), _rigPrepQuotedPrintable()
--|
--| Summary: Build final body and attachments.
--| 
--| Format:  _rigBuildMessage 
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigBuildMessage
  local tProtocol, tHdr, tContentType, tEncoding, tMimeMessage, tAltMessage
  local tBody, tAttacheNameItems, tZ, tFileName, tBaseName, tCtype, tH
  local tAttachment, tFolderName, tFileNameFromPath, tOldFolder, tFileList
  local tInfo, tFileSize, tFile, tFilesToAttach, tNamesOfFilesToAttach
  local tAttachmentAsString, tItemCount, tItemName
  
	if (sEmailA["wordwrap"] is TRUE)  and  (sEmailA["mailtype"] <> "html") then
		put _rigWord_wrap(_sBody) into _sBody
	end if

	_rigSetBoundaries
	_rigWriteHeaders

	put _rigGetProtocol() into tProtocol

	put "" into tHdr

	put _rigGetContentType() into tContentType

	put _rigGetMailEncoding() into tEncoding

	put _rigGetMimeMessage() into tMimeMessage

	put _rigGetAltMessage() into tAltMessage

	switch tContentType
		case "plain"
			put "Content-Type: text/plain; charset=" & sEmailA["charset"]  & sEmailA["mailNewline"] after tHdr
			put "Content-Transfer-Encoding: " & tEncoding after tHdr

			put sEmailA["mailNewline"] & sEmailA["mailNewline"] & _sBody after tHdr
			put tHdr into _sFinalbody

			exit _rigBuildMessage
		break

		case "html"
			if sSendMultipart is FALSE then
				put "Content-Type: text/html; charset=" & sEmailA["charset"] & sEmailA["mailNewline"] after tHdr
				put "Content-Transfer-Encoding: quoted-printable" after tHdr

			else

				put "Content-Type: multipart/alternative; boundary=" & quote & _sAltBoundary & quote & sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
				put tMimeMessage & sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
				put "--" & _sAltBoundary & sEmailA["mailNewline"] after tHdr

				put "Content-Type: text/plain; charset=" & sEmailA["charset"] & sEmailA["mailNewline"] after tHdr
				put "Content-Transfer-Encoding: " & tEncoding & sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
				put tAltMessage & sEmailA["mailNewline"] & sEmailA["mailNewline"] & "--" & _sAltBoundary & sEmailA["mailNewline"] after tHdr

				put "Content-Type: text/html; charset=" & sEmailA["charset"] & sEmailA["mailNewline"] after tHdr
				put "Content-Transfer-Encoding: quoted-printable" after tHdr
			end if

			put _rigPrepQuotedPrintable(_sBody) into _sBody

			put sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
			put _sBody & sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr

			if sSendMultipart is not FALSE then
				put "--" & _sAltBoundary & "--" after tHdr
			end if

			put tHdr into _sFinalbody

			exit _rigBuildMessage
		break

		case "plain-attach"
			put "Content-Type: multipart/" & sMultipart & "; boundary=" & quote & _sAtcBoundary & quote & sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
			put tMimeMessage & sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
			put "--" & _sAtcBoundary & sEmailA["mailNewline"] after tHdr

			put "Content-Type: text/plain; charset=" & sEmailA["charset"] & sEmailA["mailNewline"] after tHdr
			put "Content-Transfer-Encoding: " & tEncoding after tHdr

			put sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
			put _sBody & sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
		break

		case "html-attach"
			put "Content-Type: multipart/" & sMultipart & "; boundary=" & quote & _sAtcBoundary & quote & sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
			put tMimeMessage & sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
			put "--" & _sAtcBoundary & sEmailA["mailNewline"] after tHdr

			put "Content-Type: multipart/alternative; boundary=" & quote & _sAltBoundary & quote & sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
			put "--" & _sAltBoundary & sEmailA["mailNewline"] after tHdr

			put "Content-Type: text/plain; charset=" & sEmailA["charset"] & sEmailA["mailNewline"] after tHdr
			put "Content-Transfer-Encoding: " & tEncoding & sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
			put tAltMessage & sEmailA["mailNewline"] & sEmailA["mailNewline"] & "--" & _sAltBoundary & sEmailA["mailNewline"] after tHdr

			put "Content-Type: text/html; charset=" & sEmailA["charset"] & sEmailA["mailNewline"] after tHdr
			put "Content-Transfer-Encoding: quoted-printable" after tHdr

			put _rigPrepQuotedPrintable(_sBody) into _sBody

			put sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
			put _sBody & sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
			put "--" & _sAltBoundary & "--" & sEmailA["mailNewline"] & sEmailA["mailNewline"] after tHdr
		break
	end switch

	put 0 into tAttacheNameItems

	if _sAttachName is an array then
		put 0 into tZ

		put the number of lines in the keys of _sAttachName into tAttacheNameItems

		repeat with i = 1 to tAttacheNameItems
			put _sAttachName[i] into tFileName

			set the itemdelimiter to "/"
			put item -1 of tFileName into tBaseName

			put _sAttachType[i] into tCtype

			if there is not a file tFileName then
				get _setErrorMessage("email_attachment_missing", tFileName)

				return FALSE
			end if

			put "--" & _sAtcBoundary & sEmailA["mailNewline"] into tH
			put "Content-type: " & tCtype & "; " after tH
			put "name=" & quote & tBaseName & quote & sEmailA["mailNewline"] after tH
			put "Content-Disposition: " & _sAttachDisp[i] & ";" & sEmailA["mailNewline"] after tH
			put "Content-Transfer-Encoding: base64" & sEmailA["mailNewline"] after tH

      add 1 to tZ
      put tH into tAttachment[tZ]
      # GET FILE SIZE
      -- put the itemdelimiter into tOldItemDelimiter
      -- set the itemdelimiter to "/"
      put item 1 to -2 of tFileName & "/" into tFolderName

      put item -1 of tFileName into tFileNameFromPath
      -- set the itemdelimiter to tOldItemDelimiter

      put urldecode(files(tFolderName, "detailed")) into tFileList
     
      filter tFileList with tFileNameFromPath & "*"
      put tFileList into tInfo
    
      set the itemdelimiter to comma
      put item 2 of tInfo into tFileSize
			#
		
			add 1 to tZ

			put tFileSize + 1 into tFile

			open file tFileName for binary read
			if the result is not empty then
				get _setErrorMessage("email_attachment_unreadable", tFileName)
				return FALSE
			end if

			read from file tFileName for tFile
			put base64Encode(it) into tAttachment[tZ]

			close file tFileName

			# COLLECT FILE PATHS FOR ATTACHMENT
			put rigShellEscape(tFileName) into tFileName
			put tFileName & comma after tFilesToAttach
			# COLLECT FILE NAMES FOR ATTACHMENT
			put rigShellEscape(tFileNameFromPath) into tFileNameFromPath
			put tFileNameFromPath & comma after tNamesOfFilesToAttach
		end repeat

		delete char -1 of tFilesToAttach
		delete char -1 of tNamesOfFilesToAttach

		put tAttachment into tAttachmentAsString
		combine tAttachmentAsString using numToCodepoint(1)
		replace numToCodepoint(1) with sEmailA["mailNewline"] in tAttachmentAsString

	else
		put "" into tAttachmentAsString
	end if -- if _sAttachName is an array then

	put tHdr & tAttachmentAsString & sEmailA["mailNewline"] & "--" & _sAtcBoundary & "--" into _sFinalbody
end _rigBuildMessage





/*----------------------------------------------------------------------
--| FUNCTION _rigPrepQuotedPrintable
--|
--| Author: rabit
--| Version:  1.3
--| Created: 20-08-09
--| Last Mod: 22-12-14
--| Requires: --
--|
--| Summary: Prepares string for Quoted-Printable Content-Transfer-Encoding
--|            Refer to RFC 2045 http://www.ietf.org/rfc/rfc2045.txt.
--| 
--| Format:  _rigPrepQuotedPrintable(param1, param2)
--|
--| Parameters: string <pStr>, integer <pCharLim>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigPrepQuotedPrintable pStr pCharLim
  local tStr, tCharLim, tRegEx, tEscape, tOutput, tLength, tTemp
  local tChar, tAscii, tAsciiHex, tCRLFfound, tLastChar
  
	put pStr into tStr

	# SET THE CHARACTER LIMIT
	# DON'T ALLOW OVER 76, AS THAT WILL MAKE SERVERS AND MUAS BARF
	# ALL OVER QUOTED-PRINTABLE DATA
	if (pCharLim is empty) or  (pCharLim > 76) then
		put 76 into tCharLim
	else
		put pCharLim into tCharLim
	end if

	# REDUCE MULTIPLE SPACES
	put " +" into tRegEx
	put replaceText(tStr,tRegEx," ") into tStr

	# KILL NULLS
	put "\x00+" into tRegEx
	put replaceText(tStr,tRegEx,"") into tStr

	# STANDARDIZE NEWLINES
	-- if "\r" is in tStr then
	if numToCodepoint(13) is in tStr then
		-- replace "\r\n" with "\n" in tStr
		replace CRLF with LF in tStr
		-- replace "\r" with "\n" in tStr
		replace numToCodepoint(13) with LF in tStr
	end if

	# WE ARE INTENTIONALLY WRAPPING SO MAIL SERVERS WILL ENCODE CHARACTERS
	# PROPERLY AND MUAS WILL BEHAVE, SO {UNWRAP} MUST GO!
	replace "{unwrap}" with "" in tStr
	replace "{/unwrap}" with "" in tStr

	# BREAK INTO AN ARRAY OF LINES
	-- replace "\n" with numToCodepoint(1) in tStr
	replace LF with numToCodepoint(1) in tStr
	split tStr using numToCodepoint(1)

	put "=" into tEscape
	put empty into tOutput
	
	repeat for each element thisLine in tStr
		put the length of thisLine into tLength
		put empty into tTemp

		# LOOP THROUGH EACH CHARACTER IN THE LINE TO ADD SOFT-WRAP
		# CHARACTERS AT THE END OF A LINE " =\r\n" AND ADD THE NEWLY
		# PROCESSED LINE(S) TO THE OUTPUT (SEE COMMENT ON sEmailA["crlf"] VARIABLE)
		repeat with i = 1 to tLength
			# GRAB THE NEXT CHARACTER
			put char i of thisLine into tChar
			put codepointToNum(tChar) into tAscii

			# CONVERT SPACES AND TABS BUT ONLY IF IT'S THE END OF THE LINE
			if i = tLength then
				if (tAscii is 32) or (tAscii is 9) then
					put format("%x", tAscii) into tAsciiHex
         				put tEscape & format("%02s", tAsciiHex) into tChar 
				else
					put tChar into tChar
				end if
			end if

			# ENCODE = SIGNS
			if tAscii is 61 then
				put format("%x", tAscii) into tAsciiHex
				put toUpper(tAsciiHex) into tAsciiHex

				put tEscape & tAsciiHex into tChar -- =3D
			end if

			# IF WE'RE AT THE CHARACTER LIMIT, ADD THE LINE TO THE OUTPUT,
			# RESET OUR TEMP VARIABLE, AND KEEP ON CHUGGIN'
			if (the length of tTemp) + (the length of tChar) >= tCharLim then
				put tTemp & tEscape & sEmailA["crlf"] after tOutput
				put empty into tTemp
			end if

			# ADD THE CHARACTER TO OUR TEMPORARY LINE
			put tChar after tTemp
		end repeat

		# ADD OUR COMPLETED LINE TO THE OUTPUT
		put tTemp & sEmailA["crlf"] after tOutput

	end repeat

	# GET RID OF EXTRA CRLF TACKED ONTO THE END
	put TRUE into tCRLFfound
	repeat until tCRLFfound is FALSE
		put char -1 of tOutput into tLastChar
		if (codepointToNum(tLastChar) is 13) or (codepointToNum(tLastChar) is 10) then
			delete char -1 of tOutput
		else
			put FALSE into tCRLFfound
		end if
	end repeat

	return tOutput
end _rigPrepQuotedPrintable





/*----------------------------------------------------------------------
--| FUNCTION _rigPrepQencoding
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-08-16
--| Last Mod: 2017-06-27
--| Requires: --
--|
--| Summary: Performs "Q Encoding" on a string for use in email headers.  It's related
--|            but not identical to quoted-printable, so it has its own method.
--| 
--| Format:  _rigPrepQencoding(param1, param2)
--|
--| Parameters: string <pStr>, bool <pFrom> set to TRUE for processing From: headers
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigPrepQencoding pStr pFrom
  local tFrom, tStr, tCharsetLength, tLimit, tConvert, tOutput, tTemp
  local tConvertedChar, tAscii, tAsciiHEX, tRegEx, tFoundTextVar
  local tLineNums, tCounter, tModStr
  
	if (pFrom is empty) or (pFrom is not a boolean) then
		put FALSE into tFrom
	else
		put pFrom into tFrom
	end if
	
	put pStr into tStr
	
	-- replace "\r" with "" in tStr
	replace numToCodepoint(13) with "" in tStr
	-- replace "\n" with "" in tStr
	replace LF with "" in tStr
	
	# LINE LENGTH MUST NOT EXCEED 76 CHARACTERS, SO WE ADJUST FOR
	# A SPACE, 7 EXTRA CHARACTERS =??Q??=, AND THE CHARSET THAT WE WILL ADD TO EACH LINE
	put the length of sEmailA["charset"] into tCharsetLength
	put (75 - 7) - tCharsetLength into tLimit

	# THESE SPECIAL CHARACTERS MUST BE CONVERTED TOO
	put "_,=,?" into tConvert
	split tConvert using comma

	if tFrom is TRUE then
		put "," into tConvert[4]
		put ";" into tConvert[5]
	end if

	put "" into tOutput
	put "" into tTemp

	repeat for each char thisChar in tStr
		put thisChar into tConvertedChar
		# GRAB THE NEXT CHARACTER
		put codepointToNum(tConvertedChar) into tAscii

		# CONVERT ALL NON-PRINTABLE ASCII CHARACTERS AND OUR SPECIALS
		if (tAscii < 32) or (tAscii > 126) or (rigInArray(tConvert, tConvertedChar) is TRUE) then
			put format("%x", tAscii) into tAsciiHEX
			put "=" & tAsciiHEX into tConvertedChar
		end if

		if tAscii is 32 then
			put "_" into tConvertedChar
		end if

		# IF WE'RE AT THE CHARACTER LIMIT, ADD THE LINE TO THE OUTPUT,
		# RESET OUR TEMP VARIABLE, AND KEEP ON CHUGGIN'
		if ((the length of tTemp) + 1) >= tLimit then
			put tTemp & sEmailA["crlf"] after tOutput
			put empty into tTemp
		end if

		# ADD THE CHARACTER TO OUR TEMPORARY LINE
		put tConvertedChar after tTemp
	end repeat

	put tOutput & tTemp into tStr
	 
	# WRAP EACH LINE WITH THE SHEBANG, CHARSET, AND TRANSFER ENCODING
	# THE PRECEDING SPACE ON SUCCESSIVE LINES IS REQUIRED FOR HEADER "FOLDING"
	put "(?m)^(.*)$" into tRegEx
  
	put empty into tFoundTextVar -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
	put the number of lines of tStr into tLineNums
	put 0 into tCounter
	if tLineNums > 1 then
		add 1 to tCounter
		repeat for each line thisLine in tStr
			get matchText(thisLine,tRegEx,tFoundTextVar)
             
			if it is TRUE then
				put " =?" & "utf-8" & "?Q?" & tFoundTextVar & "?=" after tModStr
			else
				put thisLine after tModStr
			end if
            
			if tCounter < tLineNums then
				put return after tModStr
			end if
		end repeat
        
	else
        
		get matchText(tStr,tRegEx,tFoundTextVar)
		if it is TRUE then
			put " =?" & "utf-8" & "?Q?" & tFoundTextVar & "?=" into tModStr
		else
			put tStr into tModStr
		end if
	end if

	return tModStr
end _rigPrepQencoding





/*----------------------------------------------------------------------
--| FUNCTION rigMailSend
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2009-08-23
--| Last Mod: 2019-01-04
--| Requires: rigReplyTo, _rigSetErrorMessage, _rigBuildHeaders, _rigBatchBccSend(),
--|            _rigBuildMessage, _rigSpoolEmail()
--|
--| Summary: Send email.
--| 
--| Format:  rigMailSend()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigMailSend
	if _sReplytoFlag is FALSE then
    rigReplyTo _sHeaders["From"]
	end if

	if (_sRecipients is not an array) and (_sRecipients is empty) then
		if (_sHeaders["To"] is not an array) and (_sHeaders["To"] is empty) then
			if (_sBccArray is not an array) and (_sBccArray is empty) then
				if (_sHeaders["Bcc"] is not an array) and (_sHeaders["Bcc"] is empty) then
					if (_sHeaders["Cc"] is not an array) and (_sHeaders["Cc"] is empty) then
						_rigSetErrorMessage "email_no_recipients"
		
						return FALSE
					end if
				end if			
			end if
		end if
	end if

	_rigBuildHeaders

	if (sEmailA["bccBatchMode"] is TRUE) and (_sBccArray is an array) then
		if (the number of lines in the keys of _sBccArray) > sEmailA["bccBatchSize"] then
			get _rigBatchBccSend()

			return it
		end if
	end if

	_rigBuildMessage

	get _rigSpoolEmail()

	if it is not TRUE then
		return FALSE
	end if
	return TRUE
end rigMailSend








/*----------------------------------------------------------------------
--| FUNCTION _rigBatchBccSend
--|
--| Author: rabit
--| Version:  1.2
--| Created: 23-08-09
--| Last Mod: 22-12-14
--| Requires: _rigStrToArray(), _rigCleanEmail(), _rigSetHeader,
--|            _rigBuildMessage, _rigSpoolEmail()
--|
--| Summary: Sends groups of BCCs in batches.
--| 
--| Format:  _rigBatchBccSend()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigBatchBccSend
  local tFloat, tSet, tBccCount, tChunkCounter, tChunk, tChunkCount, tBcc
  
	put sEmailA["bccBatchSize"] into tFloat
	put "" into tSet

	put the number of lines in the keys of _sBccArray into tBccCount
	
	put 0 into tChunkCounter

	repeat with i = 1 to tBccCount
		if _sBccArray[i] is not empty then
			put ", " & _sBccArray[i] after tSet
		end if
		
		if i = tFloat then
			add 1 to tChunkCounter
			put char 2 to -1 of tSet into tChunk[tChunkCounter]
			put tFloat + sEmailA["bccBatchSize"] into tFloat
			put "" into tSet
		end if

		if i = tBccCount then
			add 1 to tChunkCounter
			put char 2 to -1 of tSet into tChunk[tChunkCounter]
		end if
	end repeat

	put the number of lines in the keys of tChunk into tChunkCount

	repeat with i = 1 to tChunkCount
		put empty into _sHeaders["Bcc"]
		put _rigStrToArray(tChunk[i]) into tBcc
		put _rigCleanEmail(tBcc) into tBcc

		if sEmailA["protocol"] is not "smtp" then
			combine tBcc using numToCodepoint(1)
			replace numToCodepoint(1) with ", " in tBcc

			_rigSetHeader "Bcc", tBcc
		else
			put tBcc into _sBccArray
		end if

		_rigBuildMessage
		get _rigSpoolEmail()
	end repeat
end _rigBatchBccSend








/*----------------------------------------------------------------------
--| COMMAND _rigUnwrapSpecials
--|
--| Author: rabit
--| Version:  1.0
--| Created: 23-08-09
--| Last Mod: 23-08-09
--| Requires: rigPregReplace(), _rigRemoveNlCallback
--|
--| Summary: Unwrap special elements.
--| 
--| Format:  _rigUnwrapSpecials
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigUnwrapSpecials
  local tRegEx
  
	put "(?i)\{unwrap\}(.*?)\{\/unwrap\}" into tRegEx
	
	put rigPregReplace(_sFinalbody, tRegEx, , "_callback__rigRemoveNlCallback") into _sFinalbody
    
    	replace "{unwrap}" with "" in _sFinalbody
    	replace "{/unwrap}" with "" in _sFinalbody
end _rigUnwrapSpecials





/*----------------------------------------------------------------------
--| COMMAND _rigRemoveNlCallback
--|
--| Author: rabit
--| Version:  1.1
--| Created: 23-08-09
--| Last Mod: 22-12-14
--| Requires: --
--|
--| Summary: Strip line-breaks via callback.
--| 
--| Format:  _rigRemoveNlCallback param1
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

private command _rigRemoveNlCallback pStr
  local tStr
  
  put pStr into tStr
    
	-- if ("\r" is in tStr) or ("\n" is in tStr) then
	if (numToCodepoint(13) is in tStr) or (LF is in tStr) then
		-- replace "\r" with "" in tStr
		replace numToCodepoint(13) with "" in tStr
    		-- replace "\n" with "" in tStr
		replace LF with "" in tStr
	end if
    
    	return tStr
end _rigRemoveNlCallback






/*----------------------------------------------------------------------
--| FUNCTION _rigSpoolEmail
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-08-23
--| Last Mod: 2018-12-30
--| Requires: _rigUnwrapSpecials, _rigGetProtocol(), _rigSetErrorMessage
--|            _rigSendWithSendmail(), _rigSendWithSmtp()
--|
--| Summary: Spool mail to the mail server.
--| 
--| Format:  _rigSpoolEmail()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigSpoolEmail
  local tProtocol
  
	_rigUnwrapSpecials

	put _rigGetProtocol() into tProtocol
			
	switch tProtocol
		case "sendmail"
			get _rigSendWithSendmail()

			if it is not TRUE then
				_rigSetErrorMessage "email_send_failure_sendmail"
				
				return FALSE
			end if
		break

		case "smtp"
			get _rigSendWithSmtp()

			if it is not TRUE then
				_rigSetErrorMessage "email_send_failure_smtp"
				
				return FALSE
			end if
	end switch

	_rigSetErrorMessage "email_sent", tProtocol

	return TRUE
end _rigSpoolEmail






/*----------------------------------------------------------------------
--| FUNCTION _rigSendWithSendmail
--|
--| Author: rabit
--| Version:  1.1
--| Created: 17-09-09
--| Last Mod: 02-02-15
--| Requires: _rigCleanEmail(), rigShellEscape(), _rigTempMailPath(), rigLogMessage
--|
--| Summary: Send using sendmail as shell command.
--| 
--| Format:  _rigSendWithSendmail()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigSendWithSendmail
  local tEnvelopeSender, tHdr, tFinalbody, tTempMailPath, tMailData
  local tCmd, tResult
  
	put _rigCleanEmail(_sHeaders["From"]) into tEnvelopeSender

	--put rigShellEscape(_sHeaderStr) into tHdr
	--put rigShellEscape(_sFinalbody) into tFinalbody
	put _sHeaderStr into tHdr
	put _sFinalbody into tFinalbody

	# TEMPORARILY SAVE MAIL TO DISK
	#
	#GET PATH TO TEMP DIRECTORY
	put _rigTempMailPath() into tTempMailPath
	put tHdr & tFinalbody into tMailData
	put tMailData into url ("binfile:" & tTempMailPath)
	
	if the result <> empty then
		rigLogMessage "error", "Error on saving temporary eMail data:" && tTempMailPath && "System error:" && the sysError
	end if

	# BUILD COMMAND
	put "cat" && quote & tTempMailPath & quote && "|" && sEmailA["mailpath"] && "-t -oi -f" && rigQ(tEnvelopeSender) into tCmd

	# SEND SHELL COMMAND
	put shell(tCmd) into tResult
    
	# REMOVE TEMP MAIL FILE
	delete file tTempMailPath
    	if the result is not empty then
		rigLogMessage "error", "Temporary eMail data could not be deleted:" && tTempMailPath
	end if

	# CHECK SENDMAIL RESULT
	if tResult is empty then
		return TRUE
	else
		rigLogMessage "error", "Error on sending eMail:" && tResult
		return FALSE
	end if
end _rigSendWithSendmail




/*----------------------------------------------------------------------
--| FUNCTION _rigSendWithSmtp
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-09-09
--| Last Mod: 17-09-09
--| Requires: _rigSetErrorMessage, _rigSmtpConnect, _rigSmtpAuthenticate, _rigCleanEmail(), _rigSendSmtpCommand
--|                  _rigSendSmtpData, _rigGetSmtpData()
--|
--| Summary: Send mail using an smtp socket.
--| 
--| Format:  _rigSendWithSmtp()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigSendWithSmtp
  local tFrom, tKey, tVal, tFinalbody, tDataToSend
  
	if sEmailA["smtpHost"] is empty then
		_rigSetErrorMessage "email_no_hostname"
		return FALSE
	end if

	_rigSmtpConnect
	_rigSmtpAuthenticate

	put _rigCleanEmail(_sHeaders["From"]) into tFrom
	_rigSendSmtpCommand "from", tFrom

	repeat for each key tKey in _sRecipients
		put _sRecipients[tKey] into tVal
		_rigSendSmtpCommand "to", tVal
	end repeat

	if the number of lines in the keys of _sCcArray > 0 then
		repeat for each key tKey in _sCcArray
			put _sCcArray[tKey] into tVal
				
			if tVal is not empty then
				_rigSendSmtpCommand "to", tVal
			end if
		end repeat
	end if

	if the number of lines in the keys of _sBccArray > 0 then
		repeat for each key tKey in _sBccArray
			put _sBccArray[tKey] into tVal
				
			if tVal is not empty then
				_rigSendSmtpCommand "to", tVal 
			end if
		end repeat
	end if

	_rigSendSmtpCommand "data" 

	# PERFORM DOT TRANSFORMATION ON ANY LINES THAT BEGIN WITH A DOT
	put replacetext(_sFinalbody,"(?m)^\.", "..") into tFinalbody

	put _sHeaderStr & tFinalbody into tDataToSend
	_rigSendSmtpData tDataToSend, sEmailA["smtpTimeout"], FALSE
	_rigSendSmtpData ".", sEmailA["smtpTimeout"]

	_rigSetErrorMessage _sSmtpReply
	if char 1 to 3 of of _sSmtpReply is not "250" then
		_rigSetErrorMessage "email_smtp_error", _sSmtpReply
		return FALSE
	end if

	_rigSendSmtpCommand "quit"

	return TRUE
end _rigSendWithSmtp




/*----------------------------------------------------------------------
--| COMMAND _rigSmtpConnect
--|
--| Author: rabit
--| Version:  1.2
--| Created: 17-09-09
--| Last Mod: 13-02-15
--| Requires: _rigResetSmtpVars, _rigSetErrorMessage, _rigSendSmtpCommand
--|
--| Summary: SMTP connect.
--| 
--| Format:  _rigSmtpConnect
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private command _rigSmtpConnect
	# RESET SMTP VARIABLES
	_rigResetSmtpVars

	put sEmailA["smtpHost"] & ":" & sEmailA["smtpPort"] into _sSmtpConnect

	open socket to _sSmtpConnect with message "_rigGetSmtpData"

	if (the result is empty) or (the result is "socket is already open") then
		wait until _sSmtpReadyForNextCommand is TRUE with messages

		if _sSmtpSuccess is not TRUE then
			_rigSetErrorMessage "email_smtp_error", _sSmtpError
			return FALSE
		end if

		_rigSetErrorMessage _sSmtpReply
		_rigSendSmtpCommand "hello"

		return the result
	else
		_rigSetErrorMessage "email_smtp_error", the result
		return FALSE
	end if
end _rigSmtpConnect






/*----------------------------------------------------------------------
--| COMMAND _rigSendSmtpCommand
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-09-09
--| Last Mod: 18-09-09
--| Requires: _rigSendSmtpData, _rigSetErrorMessage
--|
--| Summary: Send smtp command.
--| 
--| Format:  _rigSendSmtpCommand param1, param2
--|
--| Parameters: string <pCmd>, string <pData>
--|
--| Return: bool
----------------------------------------------------------------------*/

private command _rigSendSmtpCommand pCmd, pData
  local tDataToSend, tResp, tDebugItemsNum
  
	switch pCmd
    		case "hello"
        		if (_sSmtpAuth is TRUE) or (_rigGetMailEncoding() is "8bit") then
				put "EHLO" && _rigGetHostname() into tDataToSend
				_rigSendSmtpData tDataToSend, sEmailA["smtpTimeout"]
			else
				put "HELO" && _rigGetHostname() into tDataToSend
				_rigSendSmtpData tDataToSend, sEmailA["smtpTimeout"]
			end if

			put 250 into tResp
		break

		case "from"
			put "MAIL FROM:<" & pData & ">" into tDataToSend
			_rigSendSmtpData tDataToSend, sEmailA["smtpTimeout"]
	
			put 250 into tResp
		break

		case "to"
			put "RCPT TO:<" & pData & ">" into tDataToSend
			_rigSendSmtpData tDataToSend, sEmailA["smtpTimeout"]

			put 250 into tResp
		break

		case "data"
			_rigSendSmtpData "DATA", sEmailA["smtpTimeout"]

			put 354 into tResp
		break

		case "quit"
			_rigSendSmtpData "QUIT", sEmailA["smtpTimeout"]

			put 221 into tResp
		break
	end switch


	put (the number of lines in the keys of _sDebugMsg) + 1 into tDebugItemsNum
	put "<pre>" & pCmd & ": " & _sSmtpReply & "</pre>" into _sDebugMsg[tDebugItemsNum]
	
	if char 1 to 3 of _sSmtpReply is not tResp then
		_rigSetErrorMessage "email_smtp_error", _sSmtpReply
		return FALSE
	end if

	if pCmd is "quit" then
		 if (_sSmtpConnect is among the lines of the openSockets) then close socket _sSmtpConnect
  		-- put TRUE into sSmtpSocketContinue ??????????
	end if

	return TRUE
end _rigSendSmtpCommand




/*----------------------------------------------------------------------
--| COMMAND _rigSmtpAuthenticate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-09-09
--| Last Mod: 18-09-09
--| Requires: _rigSetErrorMessage, _rigSendSmtpData
--|
--| Summary: SMTP authenticate.
--| 
--| Format:  _rigSmtpAuthenticate
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private command _rigSmtpAuthenticate
  local tDataToSend
  
	if _sSmtpAuth is FALSE then
		return TRUE
	end if

	if (sEmailA["smtpUser"] is empty) and (sEmailA["smtpPass"] is empty) then
		_rigSetErrorMessage "email_no_smtp_unpw"
		return FALSE
	end if

	_rigSendSmtpData "AUTH LOGIN", sEmailA["smtpTimeout"]
	# RESET SMTP VARIABLES
	--_rigResetSmtpVars

	--_rigGetSmtpData
	--wait until _sSmtpReadyForNextCommand is TRUE with messages

	if char 1 to 3 of _sSmtpReply is not "334" then
		_rigSetErrorMessage "email_failed_smtp_login", _sSmtpReply
		return FALSE
	end if

	put base64Encode(sEmailA["smtpUser"]) into tDataToSend
	_rigSendSmtpData tDataToSend, sEmailA["smtpTimeout"]
	# RESET SMTP VARIABLES
	--_rigResetSmtpVars

	--_rigGetSmtpData
	--wait until _sSmtpReadyForNextCommand is TRUE with messages

	if char 1 to 3 of _sSmtpReply is not "334" then
		_rigSetErrorMessage "email_smtp_auth_un", _sSmtpReply
		return FALSE
	end if

	put base64Encode(sEmailA["smtpPass"]) into tDataToSend
	_rigSendSmtpData tDataToSend, sEmailA["smtpTimeout"]
	# RESET SMTP VARIABLES
	--_rigResetSmtpVars

	--_rigGetSmtpData
	--wait until _sSmtpReadyForNextCommand is TRUE with messages

	if char 1 to 3 of _sSmtpReply is not "235" then
		_rigSetErrorMessage "email_smtp_auth_pw", _sSmtpReply
		return FALSE
	end if

	return TRUE
end _rigSmtpAuthenticate




/*----------------------------------------------------------------------
--| COMMAND _rigSendSmtpData
--|
--| Author: rabit
--| Version:  1.3
--| Created: 18-09-09
--| Last Mod: 13-02-15
--| Requires: _rigResetSmtpVars
--|
--| Summary: Send SMTP data.
--| 
--| Format:  _rigSendSmtpData param1, param2
--|
--| Parameters: string <pData>, integer <pTimeout>
--|
--| Return: bool
----------------------------------------------------------------------*/

private command _rigSendSmtpData pData, pTimeout
  local tTimeout
  
	if pTimeout is empty then
		put sEmailA["smtpTimeout"] into tTimeout
	else
		put pTimeout into tTimeout
	end if

	# RESET SMTP VARIABLES
	_rigResetSmtpVars

	set the sockettimeoutinterval to tTimeout

	if (paramcount() = 2) then
		write pData & sEmailA["mailNewline"] to socket _sSmtpConnect with message "_rigGetSmtpData"
	else
		write pData & sEmailA["mailNewline"] to socket _sSmtpConnect with message "_rigSmtpDataWritten"
	end if

	wait until _sSmtpReadyForNextCommand is TRUE with messages

	return _sSmtpSuccess
end _rigSendSmtpData




/*----------------------------------------------------------------------
--| COMMAND _rigSmtpDataWritten
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-09-09
--| Last Mod: 18-09-09
--| Requires: --
--|
--| Summary: SMTP data written without getting a reply.
--| 
--| Format:  _rigSmtpDataWritten
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSmtpDataWritten
  put TRUE into _sSmtpSuccess
  put TRUE into _sSmtpReadyForNextCommand
end _rigSmtpDataWritten



/*----------------------------------------------------------------------
--| COMMAND _rigGetSmtpData
--|
--| Author: rabit
--| Version:  1.2
--| Created: 18-09-09
--| Last Mod: 20-07-11
--| Requires: --
--|
--| Summary: Get SMTP reply.
--| 
--| Format:  _rigGetSmtpData param1
--|
--| Parameters: string <pSmtpConnection>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigGetSmtpData pSmtpConnection
  read from socket pSmtpConnection until sEmailA["mailNewline"] with message "_rigDataFromSmtpSocket"
end _rigGetSmtpData





/*----------------------------------------------------------------------
--| COMMAND _rigDataFromSmtpSocket
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2009-09-18
--| Last Mod: 2018-12-14
--| Requires: --
--|
--| Summary: Get data from smtp socket.
--| 
--| Format:  _rigDataFromSmtpSocket param1, param2
--|
--| Parameters: string <pSmtpConnection>, string <pData>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigDataFromSmtpSocket pSmtpConnection, pData
	put pData after _sSmtpReply

	if offset("-",pData) is 4 then
		# THE REPLY CONSISTS OF MULTIPLE LINES
		read from socket pSmtpConnection until sEmailA["mailNewline"] with message "_rigDataFromSmtpSocket"
	else
		# THE REPLY CONSISTS OF ONE SINGLE LINES
		switch (char 1 to 3 of _sSmtpReply)
    			case "211"
    			case "214"
    			case "220" 
    			case "221" 
    			case "235"
    			case "250"
    			case "251"
    			case "252"
    			case "334"
    			case "354"
      			put TRUE into _sSmtpSuccess
      			break
       
    			case "421"
    			case "450"
    			case "451"
    			case "452"
    			case "500"
    			case "501"
    			case "502"
    			case "503"
    			case "504"
    			case "535"
    			case "550"
    			case "551"
    			case "552"
    			case "553"
    			case "554"
      			put char 1 to 3 of _sSmtpReply into _sSmtpError
      			break
    		default
      			put "Unknown error." into _sSmtpError
    		end switch
    
    		put TRUE into _sSmtpReadyForNextCommand
  	end if

end _rigDataFromSmtpSocket




/*----------------------------------------------------------------------
--| COMMAND _rigResetSmtpVars
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-09-09
--| Last Mod: 18-09-09
--| Requires: --
--|
--| Summary: Reset smtp variables.
--| 
--| Format:  _rigResetSmtpVars
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigResetSmtpVars
	put EMPTY into _sSmtpReply
  put EMPTY into _sSmtpError
	put FALSE into _sSmtpSuccess
	put FALSE into _sSmtpReadyForNextCommand
end _rigResetSmtpVars







/*----------------------------------------------------------------------
--| FUNCTION _rigGetHostname
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-09-09
--| Last Mod: 18-09-09
--| Requires: --
--|
--| Summary: Get hostname.
--| 
--| Format:  _rigGetHostname()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigGetHostname
	if $_SERVER["SERVER_NAME"] is not empty then
		return $_SERVER["SERVER_NAME"]
	end if

	return "localhost.localdomain"
end _rigGetHostname




/*----------------------------------------------------------------------
--| FUNCTION rigPrintMailDebugger
--|
--| Author: rabit
--| Version:  1.1
--| Created: 18-09-09
--| Last Mod: 03-05-15
--| Requires: rigHtmlSpecialChars()
--|
--| Summary: Get debug message.
--| 
--| Format:  rigPrintMailDebugger()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigPrintMailDebugger
  local tKey, tVal, tMsg, tHeaderStr, tSubject, tFinalbody
  
	if the number of lines in the keys of _sDebugMsg > 0 then
		repeat for each key tKey in _sDebugMsg
			put _sDebugMsg[tKey] into tVal
			put tVal after tMsg
		end repeat
	end if
	
	put _sHeaderStr into tHeaderStr
	replace "<" with "&lt;" in tHeaderStr

	put rigHtmlSpecialChars(_sSubject) into tSubject
	put rigHtmlSpecialChars(_sFinalbody) into tFinalbody
	put "<pre>" & tHeaderStr & "<br />" & tSubject & "<br />" & tFinalbody & "</pre>" after tMsg

	return tMsg
end rigPrintMailDebugger







/*----------------------------------------------------------------------
--| COMMAND _rigSetErrorMessage
--|
--| Author: rabit
--| Version:  1.0
--| Created: 16-08-09
--| Last Mod: 16-08-09
--| Requires: rigLangLoadLang(), rigLangLangLine()
--|
--| Summary: Set message.
--| 
--| Format:  _rigSetErrorMessage param1, param2
--|
--| Parameters: string <pMsg>, string <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetErrorMessage pMsg pVal
  local tMsg, tCurrentDebugItems, tLine
  
	put pMsg into tMsg

	get rigLangLoadLang("email")
	
	put the number of lines in the keys of _sDebugMsg into tCurrentDebugItems

	put rigLangLangLine(tMsg) into tLine

	if tLine is FALSE then
		add 1 to tCurrentDebugItems
		replace "%s" with pVal in tMsg
		put tMsg & "<br />" into _sDebugMsg[tCurrentDebugItems]
	else
		replace "%s" with pVal in tLine
		put tLine & "<br />" into _sDebugMsg[tCurrentDebugItems]
	end if
end _rigSetErrorMessage




/*----------------------------------------------------------------------
--| FUNCTION _rigMimeTypes
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-08-09
--| Last Mod: 17-08-09
--| Requires: --
--|
--| Summary: Mime Types.
--| 
--| Format:  _rigMimeTypes(param1)
--|
--| Parameters: string <pExt>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigMimeTypes pExt
  local tExtension, tMime
  
	put tolower(pExt) into tExtension

	put "application/mac-binhex40" into tMime["hqx"]
	put "application/mac-compactpro" into tMime["cpt"]
	put "application/msword" into tMime["doc"]
	put "application/macbinary" into tMime["bin"]
	put "application/octet-stream" into tMime["dms"]
	put "application/octet-stream" into tMime["lha"]
	put "application/octet-stream" into tMime["lzh"]
	put "application/octet-stream" into tMime["exe"]
	put "application/octet-stream" into tMime["class"]
	put "application/x-photoshop" into tMime["psd"]
	put "application/octet-stream" into tMime["so"]
	put "application/octet-stream" into tMime["sea"]
	put "application/octet-stream" into tMime["dll"]
	put "application/oda" into tMime["oda"]
	put "application/pdf" into tMime["pdf"]
	put "application/postscript" into tMime["ai"]
	put "application/postscript" into tMime["eps"]
	put "application/postscript" into tMime["ps"]
	put "application/smil" into tMime["smi"]
	put "application/smil" into tMime["smil"]
	put "application/vnd.mif" into tMime["mif"]
	put "application/vnd.ms-excel" into tMime["xls"]
	put "application/vnd.ms-powerpoint" into tMime["ppt"]
	put "application/wbxml" into tMime["wbxml"]
	put "application/wmlc" into tMime["wmlc"]
	put "application/x-director" into tMime["dcr"]
	put "application/x-director" into tMime["dir"]
	put "application/x-director" into tMime["dxr"]
	put "application/x-dvi" into tMime["dvi"]
	put "application/x-gtar" into tMime["gtar"]
	put "application/x-gzip" into tMime["gz"]
	put "application/x-httpd-php" into tMime["php"]
	put "application/x-httpd-php" into tMime["php4"]
	put "application/x-httpd-php" into tMime["php3"]
	put "application/x-httpd-php" into tMime["phtml"]
	put "application/x-httpd-php-source" into tMime["phps"]
	put "application/x-javascript" into tMime["js"]
	put "application/x-shockwave-flash" into tMime["swf"]
	put "application/x-stuffit" into tMime["sit"]
	put "application/x-tar" into tMime["tar"]
	put "application/x-tar" into tMime["tgz"]
	put "application/xhtml+xml" into tMime["xhtml"]
	put "application/xhtml+xml" into tMime["xht"]
	put "application/zip" into tMime["zip"]
	put "audio/midi" into tMime["mid"]
	put "audio/midi" into tMime["midi"]
	put "audio/mpeg" into tMime["mpga"]
	put "audio/mpeg" into tMime["mp2"]
	put "audio/mpeg" into tMime["mp3"]
	put "audio/x-aiff" into tMime["aif"]
	put "audio/x-aiff" into tMime["aiff"]
	put "audio/x-aiff" into tMime["aifc"]
	put "audio/x-pn-realaudio" into tMime["ram"]
	put "audio/x-pn-realaudio" into tMime["rm"]
	put "audio/x-pn-realaudio-plugin" into tMime["rpm"]
	put "audio/x-realaudio" into tMime["ra"]
	put "video/vnd.rn-realvideo" into tMime["rv"]
	put "audio/x-wav" into tMime["wav"]
	put "image/bmp" into tMime["bmp"]
	put "image/gif" into tMime["gif"]
	put "image/jpeg" into tMime["jpeg"]
	put "image/jpeg" into tMime["jpg"]
	put "image/jpeg" into tMime["jpe"]
	put "image/png" into tMime["png"]
	put "image/tiff" into tMime["tiff"]
	put "image/tiff" into tMime["tif"]
	put "text/css" into tMime["css"]
	put "text/html" into tMime["html"]
	put "text/html" into tMime["htm"]
	put "text/html" into tMime["shtml"]
	put "text/plain" into tMime["txt"]
	put "text/plain" into tMime["text"]
	put "text/plain" into tMime["log"]
	put "text/richtext" into tMime["rtx"]
	put "text/rtf" into tMime["rtf"]
	put "text/xml" into tMime["xml"]
	put "text/xml" into tMime["xsl"]
	put "video/mpeg" into tMime["mpeg"]
	put "video/mpeg" into tMime["mpg"]
	put "video/mpeg" into tMime["mpe"]
	put "video/quicktime" into tMime["qt"]
	put "video/quicktime" into tMime["mov"]
	put "video/x-msvideo" into tMime["avi"]
	put "video/x-sgi-movie" into tMime["movie"]
	put "application/vnd.openxmlformats-officedocument.wordprocessingml.document" into tMime["docx"]
	put "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" into tMime["xlsx"]
	put "application/msword" into tMime["word"]
	put "application/excel" into tMime["xl"]
	put "message/rfc822" into tMime["eml"]
	put "application/runrev" into tMime["rev"]

	 if tExtension is among the keys of tMime then
         	return tMime[tExtension]
         else
         	return "application/x-unknown-content-type"
    end if
end _rigMimeTypes





/*----------------------------------------------------------------------
--| FUNCTION _rigUnwrappedWrapMarkersString
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-09-09
--| Last Mod: 21-09-09
--| Requires: --
--|
--| Summary: Unwrap wrapped unwrap markers in wrapped string.
--| 
--| Format:  _rigUnwrappedWrapMarkersString(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigUnwrappedWrapMarkersString pStr
  local tLineCount, tNotWrapped, tNextLine, tMarkerEndFound, tWrappedChars
  
	put 0 into tLineCount

	repeat for each line thisLine in pStr
		add 1 to tLineCount
		if "{" is in thisLine then

			put offset("}}",thisLine) into tNotWrapped

			if tNotWrapped is 0 then
				# MARKER IS WRAPPED
				put line (tLineCount + 1) of pStr into tNextLine
				put offset("}}",tNextLine) into tMarkerEndFound
				if tMarkerEndFound is 0 then
					# LINE STARTS WITH } AND SPACE
					delete char 1 to 2 of line (tLineCount + 1) of pStr
					put "}" after line tLineCount of pStr
				else
					# GET WRAPPED CHARS AND PUT THEM BACK AFTER THE FOUND LINE
					put char 1 to (tMarkerEndFound + 1) of line (tLineCount + 1) of pStr into tWrappedChars
					put tWrappedChars after line tLineCount of pStr
					delete char 1 to (tMarkerEndFound + 2) of line (tLineCount + 1) of pStr

					if line (tLineCount + 1) of pStr is empty then
						delete line (tLineCount + 1) of pStr
					end if
				end if
			end if
		end if
	end repeat

	return pStr
end _rigUnwrappedWrapMarkersString





/*----------------------------------------------------------------------
--| FUNCTION rigEmailGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-04
--| Last Mod: 2019-01-04
--| Requires: --
--|
--| Summary: Get rule names, prep methods, field data.
--| 
--| Format:  rigEmailGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigEmailGet pWhat
  if pWhat is among the keys of sEmailA then
    return sEmailA[pWhat]
  end if
   
  return empty
end rigEmailGet





/*----------------------------------------------------------------------
--| COMMAND rigEmailSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-04
--| Last Mod: 2019-01-04
--| Requires: --
--|
--| Summary: Setter for email array variables.
--| 
--| Format:  rigEmailSet param1, param2
--|
--| Parameters: string <pKey> sEmailA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigEmailSet pKey pVal
  if pKey is among the keys of sEmailA then
    put pVal into sEmailA[pKey]
  end if
end rigEmailSet





--| END OF Email.livecodescript
--| Location:  ./system/libraries/Email.livecodescript
----------------------------------------------------------------------