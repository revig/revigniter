script "Authentication"

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
# revIgniter Authentication Library
# based on Ion Auth for CodeIgniter by Ben Edmunds, ben.edmunds@gmail.com
# http://github.com/benedmunds/CodeIgniter-Ion-Auth
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Authentication
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/authentication/index.html
##

## ------------------------------------------------------------------------




global gRigA, gData

local sAuthConfigA																																					  --  array containing all config values, see authentication.lc
local sAuthUserA                                                                                           --  user data like "username", "email" etc., see table "users"
local sAuthMessagesA, sAuthErrorsA, sActivationCode, sAuthForgottenPasswordCode           			--  misc
local sAuthHooksA, sAuthHooksEnabled, sAuthHookInProgress, sAuthHooksHandlers, sAuthHooksFiles	-- "hooks" variables
local sAuthSelect, sAuthWhere, sAuthLike, sAuthLimit, sAuthOffset, sAuthOrderBy, sAuthOrder			--  database related
local sAuthQuery, sAuthFieldnames, sStackInUse







 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-19
 --| Last Mod: --
 --| Requires: rigLogMessage
 --|
 --| Summary:  Run security check and load additional files.
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
        rigLogMessage "debug", "Authentication Library Loaded"
      end if

      # AUTOMATICALLY LOAD LIBS / HELPERS / LANGUAGE FILES
      rigLoadHelper "cookie"
      rigLoaderLoadLibrary "Encrypt"
      rigLoaderLoadLibrary "Session"
      rigLoaderLoadLibrary "Email"
      get rigLoadDatabase(, TRUE, TRUE)
      get rigLangLoadLang("authentication")
      #
    end if -- if sStackInUse <> TRUE

  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack






/*----------------------------------------------------------------------
--| COMMAND rigRunInitialAuthenticationConfig
--|
--| Author: rabit
--| Version:  1.1
--| Created: 07-09-12
--| Last Mod: 22-12-14
--| Requires: _rigInitializeAuthentication
--|
--| Summary: Run initial configuration procedures. Don't remove, even if it does nothing!
--|
--| Format:  rigRunInitialAuthenticationConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialAuthenticationConfig pConfig
  local tConfig

	put pConfig into tConfig

	if tConfig is not an array then
		if tConfig is not empty then
			split tConfig using numToCodepoint(1) and numToCodepoint(2)
		end if
	end if

	if tConfig is an array then

		_rigInitializeAuthentication tConfig
	end if
end rigRunInitialAuthenticationConfig





/*----------------------------------------------------------------------
--| COMMAND _rigInitializeAuthentication
--|
--| Author: rabit
--| Version:  1.0
--| Created: 07-09-2012
--| Last Mod: 07-09-2012
--| Requires: _rigSetInitialAuthenticationValue, rigGetCookie(),
--|           _rigAuthLoginRememberedUser(), rigInitializeMail, _rigAuthCallHook()
--|
--| Summary: Initialize preferences.
--|
--| Format: _rigInitializeAuthentication param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigInitializeAuthentication pConfig
  local tKey, tVal, tIdentity, tRememberCode

	if pConfig is an array then
		repeat for each key tKey in pConfig

			put pConfig[tKey] into tVal

			_rigSetInitialAuthenticationValue tKey, tVal

		end repeat
	end if

	# AUTO-LOGIN USER PROVIDED THE USER IS REMEMBERED
	put rigGetCookie("identity") into tIdentity
	put rigGetCookie("rememberCode") into tRememberCode
	if (rigAuthLoggedIn() is FALSE) and (tIdentity <> FALSE) and (tRememberCode <> FALSE) then
		get _rigAuthLoginRememberedUser(tIdentity, tRememberCode)
	end if

	# MAIL CONFIGURATION
	if sAuthConfigA["emailConfig"] is an array then
		rigInitializeMail sAuthConfigA["emailConfig"]
	end if

	# INITIALIZE THE AUTHENTICATION HOOKS PREFERENCES
	_rigInitAuthHooksPrefs

	get _rigAuthCallHook("authLibraryInitialized")
end _rigInitializeAuthentication






/*----------------------------------------------------------------------
--| COMMAND _rigSetInitialAuthenticationValue
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2012-09-10
--| Last Mod: 2019-06-26
--| Requires: rigLogMessage, rigLoadHelper
--|
--| Summary: Set initial values.
--|
--| Format: _rigSetInitialAuthenticationValue param1, param2
--|
--| Parameters: string <pVarName>, mixed <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetInitialAuthenticationValue pVarName pValue
  switch pVarName
    case "tables"
      if pValue is an array then
        put pValue into sAuthConfigA["tables"]
      else
        rigLogMessage "error", "Authentication tables settings must be an array!"
      end if

    break
    case "join"
      if pValue is an array then
        put pValue into sAuthConfigA["join"]
      else
        rigLogMessage "error", "Authentication join settings must be an array!"
      end if

    break
    case "emailConfig"
      if pValue is an array then
        put pValue into sAuthConfigA["emailConfig"]
      else
        rigLogMessage "error", "Authentication emailConfig settings must be an array!"
      end if

    break
    case "otpEnabled"
      if pValue is TRUE then
        put pValue into sAuthConfigA["otpEnabled"]
        rigLoadHelper "otp"
      end if
    break

  default
  put pValue into sAuthConfigA[pVarName]
end switch

end _rigSetInitialAuthenticationValue





/*----------------------------------------------------------------------
--| FUNCTION rigAuthActivate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-10-2012
--| Last Mod: 14-10-2012
--| Requires: _rigAuthCallHook(), rigDBselect, rigDbWhere, rigDbLimit, rigDbGet(),
--|          rigDbRow(), rigAuthSetError, rigDbUpdate()
--|
--| Summary: User activation. Validate and remove activation code.
--|
--| Format:  rigAuthActivate(param1, param2)
--|
--| Parameters: integer <pID>, string <pCode>
--|
--| Return: empty
----------------------------------------------------------------------*/

function rigAuthActivate pID pCode
  local tCode, tUserA, tIdentity, tData

	get _rigAuthCallHook("authPreActivate")

	if pCode is empty then
		put False into tCode
	else
		put pCode into tCode
	end if

	if tCode <> FALSE then
		rigDBselect sAuthConfigA["identityColumn"]
		rigDbWhere "activationCode", pCode
		rigDbLimit 1
		put rigDbGet(sAuthConfigA["tables"]["users"]) into sAuthQuery

		if (sAuthQuery <> FALSE) and (sAuthQuery["numrows"] is 1) then
			put rigDbRow() into sAuthUserA
			put sAuthUserA into tUserA

		else
			get _rigAuthCallHook("authPostActivate")
			get _rigAuthCallHook("authPostActivateUnsuccessful")
			rigAuthSetError "activateUnsuccessful"
			return FALSE
		end if

		put tUserA[sAuthConfigA["identityColumn"]] into tIdentity

		put empty into tData["activationCode"]
		put 1 into tData["active"]

		get _rigAuthCallHook("authExtraWhere")

 		rigDbWhere sAuthConfigA["identityColumn"], tIdentity
		get rigDbUpdate(sAuthConfigA["tables"]["users"], tData)

	else
		put empty into tData["activationCode"]
		put 1 into tData["active"]

		get _rigAuthCallHook("authExtraWhere")

		get rigDbUpdate(sAuthConfigA["tables"]["users"], tData, "id =" && pID)
	end if

	if rigDbAffectedRows() is 1 then
			get _rigAuthCallHook("authPostActivate")
			get _rigAuthCallHook("authPostActivateSuccessful")
			rigAuthSetMessage "activateSuccessful"
			return TRUE
	else
			get _rigAuthCallHook("authPostActivate")
			get _rigAuthCallHook("authPostActivateUnsuccessful")
			rigAuthSetError "activateUnsuccessful"
	end if

	return FALSE
end rigAuthActivate






/*----------------------------------------------------------------------
--| FUNCTION rigAuthDeactivate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-02-2013
--| Last Mod: 11-02-2013
--| Requires: _rigAuthCallHook(), rigAuthSetError, rigHexDigest(), rigDbWhere, rigDbUpdate()
--|            rigDbAffectedRows(), rigAuthSetMessage, rigAuthSetError
--|
--| Summary: Deactivate user.
--|
--| Format:  rigAuthDeactivate(param1)
--|
--| Parameters: integer <pID>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthDeactivate pID
  local tActivationData, tAffectedRows

	get _rigAuthCallHook("authDeactivate")

	if pID is empty then
		rigAuthSetError "deactivateUnsuccessful"

		return FALSE
	end if

	put rigHexDigest(sha1Digest(the long seconds)) into sActivationCode

	put sActivationCode into tActivationData["activationCode"]
	put 0 into tActivationData["active"]

	get _rigAuthCallHook("authExtraWhere")

	rigDbWhere "id", pID
	get rigDbUpdate(sAuthConfigA["tables"]["users"], tActivationData)

	put rigDbAffectedRows() into tAffectedRows
	if tAffectedRows is 1 then
		rigAuthSetMessage "deactivateSuccessful"

		return TRUE
	else
		rigAuthSetError "deactivateUnsuccessful"
	end if

	return FALSE
end rigAuthDeactivate






/*----------------------------------------------------------------------
--| FUNCTION rigAuthLoggedIn
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2012-09-11
--| Last Mod: 2019-06-24
--| Requires: _rigAuthCallHook(), rigSessUserdata(), rigAuthUserHasOTP()
--|
--| Summary: Check logged in state. Returns FALSE if
--|            session data item identity is empty.
--|
--| Format:  rigAuthLoggedIn()
--|
--| Parameters: --
--|
--| Return: mixed (bool or "pending" or "pendingOTPsetup")
----------------------------------------------------------------------*/

function rigAuthLoggedIn
  local tUserHasOTP

	get _rigAuthCallHook("authCheckLoggedIn")

  if rigSessUserdata(sAuthConfigA["identityColumn"]) is not FALSE then

    # CHECK IF USER SUPPLIED THE CORRECT ONE-TIME PASSWORD
    put rigAuthUserHasOTP() into tUserHasOTP
    if (tUserHasOTP is TRUE) and (rigSessUserdata("otpCheck") <> "success") then
      return "pending"
    else if tUserHasOTP is "pendingOTPsetup" then
      return "pendingOTPsetup"
    end if

    return TRUE
  end if

	return FALSE
end rigAuthLoggedIn






/*----------------------------------------------------------------------
--| FUNCTION rigAuthIsAdmin
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-09-2012
--| Last Mod: 11-09-2012
--| Requires: _rigAuthCallHook()
--|
--| Summary: Check if user is admin.
--|
--| Format:  rigAuthIsAdmin(param1)
--|
--| Parameters: string <pID> (optional)
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthIsAdmin pID
	get _rigAuthCallHook("authIsAdmin")

	return rigAuthInGroup(sAuthConfigA["defaultAdminGroup"], pID)
end rigAuthIsAdmin





/*----------------------------------------------------------------------
--| FUNCTION rigAuthInGroup
--|
--| Author: rabit
--| Version:  1.0
--| Created: 13-09-2012
--| Last Mod: 13-09-2012
--| Requires: _rigAuthCallHook(), rigAuthUserGroups(), rigInArray()
--|
--| Summary: Check if user is a member of a specific group.
--|
--| Format:  rigAuthInGroup(param1, param2)
--|
--| Parameters: mixed <pGroup>, integer <pID> (optional)
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthInGroup pGroup pID
  local tUserGroups, tIncr, tRow, tGroupsByID, tGroupsByName, tKey, tVal
  local tGroups

	get _rigAuthCallHook("authInGroup")

	put rigAuthUserGroups(pID) into tUserGroups

	# RETURN FALSE IF QUERY RETURNED FALSE OTHERWISE STORE VALUES IN ARRAYS
	if tUserGroups <> FALSE then
		put 0 into tIncr
		repeat for each key tKey in tUserGroups
			add 1 to tIncr

			put tUserGroups[tIncr] into tRow
			# GET IDs AND NAMEs
			put tRow[1] into tGroupsByID[tIncr]
			put tRow[2] into tGroupsByName[tIncr]
		end repeat

	else
		return FALSE
	end if

	if pGroup is an array then
		repeat for each key tKey in pGroup
			put pGroup[tKey] into tVal

			# DETERMINE WHICH ARRAY SHOULD BE USED FOR CHECKING
			if tVal is an integer then
				put tGroupsByID into tGroups
			else
				put tGroupsByName into tGroups
			end if

			if rigInArray(tGroups, tVal) is TRUE then
				return TRUE
			end if

		end repeat

	else

		# DETERMINE WHICH ARRAY SHOULD BE USED FOR CHECKING
		if pGroup is an integer then
				put tGroupsByID into tGroups
			else
				put tGroupsByName into tGroups
		end if

		if rigInArray(tGroups, pGroup) is TRUE then
			return TRUE
		end if
	end if

	return FALSE
end rigAuthInGroup





/*----------------------------------------------------------------------
--| COMMAND rigAuthSetMessage
--|
--| Author: rabit
--| Version:  1.0
--| Created: 31-12-2012
--| Last Mod: 31-12-2012
--| Requires: --
--|
--| Summary: Add a message to sAuthMessagesA.
--|
--| Format:  rigAuthSetMessage param1
--|
--| Parameters: string <pMessage>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigAuthSetMessage pMessage
  local tMessageNum

	put (the number of lines in the keys of sAuthMessagesA) + 1 into tMessageNum
	put pMessage into sAuthMessagesA[tMessageNum]
end rigAuthSetMessage






/*----------------------------------------------------------------------
--| FUNCTION rigAuthMessages
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-09-2012
--| Last Mod: 11-09-2012
--| Requires: rigLangLangLine()
--|
--| Summary: Return authentication messages.
--|
--| Format:  rigAuthMessages(param1, param2)
--|
--| Parameters: string <pPrefix> (optional), string <pSuffix> (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigAuthMessages pPrefix pSuffix
  local tMessagesOut, tMessage, tLangMessage

	if pPrefix is empty then
		put sAuthConfigA["messagePrefix"] into pPrefix
	end if

	if pSuffix is empty then
		put sAuthConfigA["messageSuffix"] into pSuffix
	end if

	put "" into tMessagesOut

	repeat for each key tKey in sAuthMessagesA
		put sAuthMessagesA[tKey] into tMessage

		# CHECK IF MESSAGE IS IN LANGUAGE FILE
		put rigLangLangLine(tMessage) into tLangMessage
		if tLangMessage is FALSE then
			put "--" & tMessage & "--" into tLangMessage
		end if

		put pPrefix & tLangMessage & pSuffix after tMessagesOut
	end repeat

	return tMessagesOut
end rigAuthMessages







/*----------------------------------------------------------------------
--| FUNCTION rigAuthUsers
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-09-2012
--| Last Mod: 12-09-2012
--| Requires: _rigAuthCallHook(), _rigStrToArray(), rigDbSelect, rigDbDistinct, rigDbJoin,
--|            rigDbWhereIn, rigDbWhere, rigDbOrLike, rigDbLimit, rigDbOrderBy, rigDbGet()
--|
--| Summary: Get the users.
--|
--| Format:  rigAuthUsers(param1)
--|
--| Parameters: mixed <pGroupIDs> (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigAuthUsers pGroupIDs
  local tGroupsIDs, tKey, tVal

	get _rigAuthCallHook("authUsers")

	put pGroupIDs into tGroupsIDs

	# MAKE SURE pGroupIDs IS AN ARRAY
	if tGroupsIDs is not an array then
		if tGroupsIDs is not empty then
			put _rigStrToArray(pGroupIDs) into tGroupsIDs
		end if
	end if

	# DEFAULT SELECTS
	rigDbSelect "*," && sAuthConfigA["tables"]["users"] & ".id AS id," && sAuthConfigA["tables"]["users"] & ".id AS userID"

	# SELECTS STORED IN sAuthSelect
	if sAuthSelect is an array then
		repeat for each key tKey in sAuthSelect
			put sAuthSelect[tKey] into tVal
			rigDbSelect tVal
		end repeat

		put empty into sAuthSelect
	end if

	# FILTER RESULT BY GROUP IDs
	if tGroupsIDs is an array then
		# JOIN AND THEN RUN A rigDbWhereIn AGAINST THE GROUP IDs
		rigDbDistinct
		rigDbJoin sAuthConfigA["tables"]["usersGroups"], sAuthConfigA["tables"]["usersGroups"] & ".userId =" && sAuthConfigA["tables"]["users"] & ".id", "inner"

		rigDbWhereIn sAuthConfigA["tables"]["usersGroups"] & ".groupId", tGroupsIDs
	end if

	get _rigAuthCallHook("authExtraWhere")

	# RUN EACH WHERE OF sAuthWhere
	if sAuthWhere is an array then
		rigDbWhere sAuthWhere
		put empty into sAuthWhere
	end if

	# RUN EACH LIKE OF sAuthLike
	if sAuthLike is an array then
		rigDbOrLike sAuthLike

		put empty into sAuthLike
	end if

	# CHECK LIMIT AND OFFSET
	if (sAuthLimit <> "") and (sAuthOffset <> "") then
		rigDbLimit sAuthLimit, sAuthOffset
		put "" into sAuthLimit
		put "" into sAuthOffset
	else if sAuthLimit <> "" then
		rigDbLimit sAuthLimit
		put "" into sAuthLimit
	end if

	# SET ORDER
	if (sAuthOrderBy <> "") and (sAuthOrder <> "") then
		rigDbOrderBy sAuthOrderBy, sAuthOrder
		put "" into sAuthOrderBy
		put "" into sAuthOrder
	end if

	# RUN THE QUERY AND RETURN THE RESULT
	put rigDbGet(sAuthConfigA["tables"]["users"]) into sAuthQuery

	if (sAuthQuery <> FALSE) and (sAuthQuery["numrows"] > 0) then
		put sAuthQuery["fieldnames"] into sAuthFieldnames
		return sAuthQuery["resultarray"]
	else
		put FALSE into sAuthQuery
	end if

	return FALSE
end rigAuthUsers






/*----------------------------------------------------------------------
--| FUNCTION rigAuthUser
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-02-2013
--| Last Mod: 17-02-2013
--| Requires: _rigAuthCallHook(), rigSessUserdata(), rigDbLimit, _rigAuthWhere,
--|            rigAuthUsers()
--|
--| Summary: Get a particular user.
--|
--| Format:  rigAuthUser(param1)
--|
--| Parameters: integer <pID> (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigAuthUser pID
  local tID

	get _rigAuthCallHook("authUser")

	# USE ID OF CURRENT USER IF pID IS EMPTY
	if pID is empty then
		put rigSessUserdata("userID") into tID
	else
		put pID into tID
	end if

	rigDbLimit 1
	_rigAuthWhere sAuthConfigA["tables"]["users"] & ".id", tID

	return rigAuthUsers()
end rigAuthUser








/*----------------------------------------------------------------------
--| FUNCTION rigAuthUserGroups
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-09-2012
--| Last Mod: 12-09-2012
--| Requires: _rigAuthCallHook(), rigSessUserdata(), rigDbSelect, rigDbWhere,
--|           rigDbJoin, rigDbGet()
--|
--| Summary: Get groups of a specific user.
--|
--| Format:  rigAuthUserGroups(param1)
--|
--| Parameters: integer <pID>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigAuthUserGroups pID
  local tID, tQuery

	get _rigAuthCallHook("authUserGroups")

	# USE ID OF CURRENT USER IF pID IS EMPTY
	if pID is empty then
		put rigSessUserdata("userID") into tID
	else
		put pID into tID
	end if

	rigDbSelect sAuthConfigA["tables"]["usersGroups"] & "." & sAuthConfigA["join"]["groups"] && "as id," && sAuthConfigA["tables"]["groups"] & ".name," && sAuthConfigA["tables"]["groups"] & ".description"
	rigDbWhere sAuthConfigA["tables"]["usersGroups"] & "." & sAuthConfigA["join"]["users"], tID
	rigDbJoin sAuthConfigA["tables"]["groups"], sAuthConfigA["tables"]["usersGroups"] & "." & sAuthConfigA["join"]["groups"] && "=" && sAuthConfigA["tables"]["groups"] & ".id"

	put rigDbGet(sAuthConfigA["tables"]["usersGroups"]) into tQuery

	if tQuery <> FALSE then
		return tQuery["resultarray"]
	end if

	return FALSE
end rigAuthUserGroups





/*----------------------------------------------------------------------
--| FUNCTION rigAuthLogin
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2012-10-10
--| Last Mod: 2019-06-24
--| Requires: rigAuthSetError, _rigAuthCallHook(), rigDbSelect, rigDbWhere,
--|            rigDbLimit, rigDbGet(), rigDbRow(), _rigAuthValidatePassword(),
--|            rigAuthSetError, _rigAuthUpdateLastLogin(), rigAuthClearLoginAttempts(),
--|            rigAuthUserHasOTP(), rigSetSessUserdata, rigAuthRememberUser(),
--|            rigAuthSetMessage, rigAuthIncreaseLoginAttempts()
--|
--| Summary: User login.
--|
--| Format:  rigAuthLogin(param1, param2, param3)
--|
--| Parameters: string <pIdentity>, string <pPassword>, bool <pRemember>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthLogin pIdentity pPassword pRemember
  local tRemember, tUserA, tPasswordValid, tSessionData

	if pRemember is empty then
		put FALSE into tRemember
	else
		put pRemember into tRemember
	end if

	if (pIdentity is empty) or (pPassword is empty) then
		rigAuthSetError "loginUnsuccessful"
		return FALSE
	end if

	get _rigAuthCallHook("authExtraWhere")

	rigDbSelect sAuthConfigA["identityColumn"] & ", username, email, id, password, active, lastLogin"
	rigDbWhere sAuthConfigA["identityColumn"], pIdentity
	rigDbLimit 1
	put rigDbGet(sAuthConfigA["tables"]["users"]) into sAuthQuery

	if (sAuthQuery <> FALSE) and (sAuthQuery["numrows"] is 1) then
		put rigDbRow(1) into sAuthUserA
		put sAuthUserA into tUserA

		# VALIDATE PASSWORD AGAINST ENTRY IN USERS TABLE
		put _rigAuthValidatePassword(tUserA["id"], pPassword) into tPasswordValid

		if tPasswordValid is TRUE then
			if tUserA["active"] is 0 then

				get _rigAuthCallHook("authPostLoginUnsuccessful")
				rigAuthSetError "loginUnsuccessfulNotActive"
				return FALSE
			end if

			get _rigAuthUpdateLastLogin(tUserA["id"])
			get rigAuthClearLoginAttempts(pIdentity)

			# SET SESSION DATA
			put tUserA[sAuthConfigA["identityColumn"]] into tSessionData["identity"]
			put tUserA["username"] into tSessionData["username"]
			-- put "testerchen" into tSessionData["test"] ------------------------------------------------------ OK
			-- put "testerchen" into tSessionData["username"] ------------------------------------- OK
			-- put "admin" into tSessionData["username"] ------------------------------------- OK
			-- put "blabla" into tSessionData["test"] ---------------------------------- OK
			-- put "administrator" into tSessionData["test"] ---------------------------------- failure
			put tUserA["email"] into tSessionData["email"]
			put tUserA["id"] into tSessionData["userID"]
			put tUserA["lastLogin"] into tSessionData["oldLastLogin"]

      if rigAuthUserHasOTP() is TRUE then
        # USER NEEDS TO SUPPLY A ONE-TIME PASSWORD
        put "pending" into tSessionData["otpCheck"]
      end if

			rigSetSessUserdata tSessionData

			if (tRemember is TRUE) and (sAuthConfigA["rememberUsers"] is TRUE) then
				get rigAuthRememberUser(tUserA)
			end if

			get _rigAuthCallHook("authPostLogin")
			get _rigAuthCallHook("authPostLoginSuccessful")

			rigAuthSetMessage "loginSuccessful"

			return TRUE
		end if -- if tPasswordValid is TRUE then

	end if -- if (sAuthQuery <> FALSE) and (sAuthQuery["numrows"] is 1) then

	get rigAuthIncreaseLoginAttempts(pIdentity)

	get _rigAuthCallHook("authPostLoginUnsuccessful")

	rigAuthSetError "loginUnsuccessful"

	return FALSE
end rigAuthLogin





/*----------------------------------------------------------------------
--| COMMAND rigAuthLogout
--|
--| Author: rabit
--| Version:  1.0
--| Created: 08-02-2013
--| Last Mod: 08-02-2013
--| Requires: _rigAuthCallHook(), rigUnsetSessUserdata, rigGetCookie(), rigDeleteCookie
--|            rigSessDestroy, rigSessCreate, rigAuthSetMessage
--|
--| Summary: User logout.
--|
--| Format:  rigAuthLogout
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigAuthLogout
  local tSessionItems

	get _rigAuthCallHook("authLogout")

	# REMOVE SESSION DATA
	put "" into tSessionItems[sAuthConfigA["identityColumn"]]
	put "" into tSessionItems["username"]
	put "" into tSessionItems["userID"]
	rigUnsetSessUserdata tSessionItems

	# DELETE REMEMBER ME COOKIES
	if rigGetCookie("identity") <> FALSE then
		rigDeleteCookie "identity"
	end if
	if rigGetCookie("rememberCode") <> FALSE then
		rigDeleteCookie "rememberCode"
	end if

	# RECREATE THE SESSION
	rigSessDestroy
	rigSessCreate

	rigAuthSetMessage "logoutSuccessful"
end rigAuthLogout





/*----------------------------------------------------------------------
--| FUNCTION rigAuthRegister
--|
--| Author: rabit
--| Version:  1.3
--| Created: 08-02-2013
--| Last Mod: 21-03-2014
--| Requires: _rigAuthCallHook(), _rigAuthRegisterUser(), rigAuthSetMessage, rigAuthSetError,
--|            rigDbWhere, rigDbGet(), rigDbRow(), rigAnchor(), rigLoadView(), rigClearMail,
--|            rigMailFrom, rigMailTo, rigMailSubject, rigMailMessage, rigMailSend()
--|
--| Summary: Register new user.
--|
--| Format:  rigAuthRegister(param1, param2, param3, param4, param5)
--|
--| Parameters: string <pUsername>, string <pPassword>, string <pEmail>
--|             array <pExtraData>, array <pGroupname>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigAuthRegister pUsername pPassword pEmail pExtraData pGroupname
  local tID, tDeactivate, tUserA, tRegData, tEmailTemplate, tAuthPathToEmailTemplates
  local tMessage

	get _rigAuthCallHook("authPreAccountCreation")

	if sAuthConfigA["emailActivation"] is FALSE then
		put _rigAuthRegisterUser(pUsername, pPassword, pEmail, pExtraData, pGroupname) into tID

		if tID <> FALSE then
			rigAuthSetMessage "accountCreationSuccess"
			get _rigAuthCallHook("authPostAccountCreation")
			get _rigAuthCallHook("authPostAccountCreationSuccessful")

			return tID
		else
			rigAuthSetError "accountCreationUnsuccessful"
			get _rigAuthCallHook("authPostAccountCreation")
			get _rigAuthCallHook("authPostAccountCreationUnsuccessful")

			return FALSE
		end if


	else --if sAuthConfigA["emailActivation"] is FALSE then
		put _rigAuthRegisterUser(pUsername, pPassword, pEmail, pExtraData, pGroupname) into tID

		if tID is FALSE then
			rigAuthSetError "accountCreationUnsuccessful"
			return FALSE
		end if

		put rigAuthDeactivate(tID) into tDeactivate

		if tDeactivate is FALSE then
			rigAuthSetError "deactivateUnsuccessful"
			get _rigAuthCallHook("authPostAccountCreation")
			get _rigAuthCallHook("authPostAccountCreationUnsuccessful")

			return FALSE
		end if

		# GET THE USER
		rigDbWhere "id", tID
		put rigDbGet(sAuthConfigA["tables"]["users"]) into sAuthQuery

		if (sAuthQuery <> FALSE) and (sAuthQuery["numrows"] is 1) then
			put rigDbRow() into sAuthUserA
			put sAuthUserA into tUserA
		else
			rigAuthSetError "accountCreationUnsuccessful"
			return FALSE
		end if

		# REGISTRATION DATA
		put tUserA[sAuthConfigA["identityColumn"]] into tRegData["identity"]
		put tUserA["id"] into tRegData["id"]
		put pEmail into tRegData["email"]
		put sActivationCode into tRegData["activationCode"]

		put tUserA[sAuthConfigA["identityColumn"]] into gData["identity"]

		# BUILD LINK FOR ACTIVATION
		If pExtraData["activationLink"] is empty then
			put "auth/activate/" into pExtraData["activationLink"]
			else if char -1 of pExtraData["activationLink"] <> "/" then
				put pExtraData["activationLink"] & "/" into pExtraData["activationLink"]
		end if
		put rigAnchor(pExtraData["activationLink"] & tID & "/" & sActivationCode & "/", rigLangLangLine("activationLinkText")) into gData["activationCode"]
		put empty into sActivationCode

		if sAuthConfigA["sendEmails"] is FALSE then
			get _rigAuthCallHook("authPostAccountCreation")
			get _rigAuthCallHook("authPostAccountCreationSuccessful")
			get _rigAuthCallHook("authPActivationEmailSuccessful")
			rigAuthSetMessage "activationEmailSuccessful"

			return tRegData
		else
			# GET PATH TO EMAIL ACTIVATION TEMPLATE
			if sAuthConfigA["pathToEmailTemplates"] is empty then
				put "emailTemplates/" & sAuthConfigA["emailActivate"] into tEmailTemplate
			else
				if char -1 of sAuthConfigA["pathToEmailTemplates"] <> "/" then
					put sAuthConfigA["pathToEmailTemplates"] & "/" into tAuthPathToEmailTemplates
				else
					put sAuthConfigA["pathToEmailTemplates"] into tAuthPathToEmailTemplates
				end if

				put tAuthPathToEmailTemplates & sAuthConfigA["emailActivate"] into tEmailTemplate
			end if

			# MERGE EMAIL ACTIVATION TEMPLATE
			put rigLoadView(tEmailTemplate, TRUE) into tMessage
			put merge(tMessage) into tMessage

			rigClearMail
			rigMailFrom sAuthConfigA["adminEmail"], sAuthConfigA["siteTitle"]
			rigMailTo pEmail
			rigMailSubject sAuthConfigA["siteTitle"] && "-" && rigLangLangLine("emailActivationSubject")
			rigMailMessage tMessage

			if rigMailSend() is TRUE then
				get _rigAuthCallHook("authPostAccountCreation")
				get _rigAuthCallHook("authPostAccountCreationSuccessful")
				get _rigAuthCallHook("authPActivationEmailSuccessful")
				rigAuthSetMessage "activationEmailSuccessful"

				return tUserA["id"]
			end if
		end if -- if sAuthConfigA["sendEmails"] is FALSE then

		get _rigAuthCallHook("authPostAccountCreation")
		get _rigAuthCallHook("authPostAccountCreationUnsuccessful")
		get _rigAuthCallHook("authPActivationEmailUnsuccessful")
		rigAuthSetError "activationEmailUnsuccessful"

		return FALSE
	end if -- if sAuthConfigA["emailActivation"] is FALSE then

end rigAuthRegister





/*----------------------------------------------------------------------
--| FUNCTION _rigAuthRegisterUser
--|
--| Author: rabit
--| Version:  1.4
--| Created: 2013-02-08
--| Last Mod: 2019-09-23
--| Requires: _rigAuthCallHook(), rigAuthEmailCheck(), rigAuthSetError, rigAuthUsernameCheck(),
--|            _rigAuthEncryptPassword(), rigIpAddress(), rigMasterNow(), _rigAuthFilteredData(),
--|            rigDbInsert(), _rigAuthWhere, rigAuthUsers(), rigDbRow(),
--|            rigAuthAddToGroup, rigAuthGroups()
--|
--| Summary: Register new user.
--|
--| Format:  _rigAuthRegisterUser(param1, param2, param3, param4, param5)
--|
--| Parameters: string <pUsername>, string <pPassword>, string <pEmail>
--|             array <pExtraData>, array <pGroups>
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigAuthRegisterUser pUsername pPassword pEmail pExtraData pGroups
  local tOriginalUsername, tUsernameExists, tUserNumber, tData
  local tFilteredData, tFirstDelim, tSecondDelim, tUserID, tGroupRow
  local tGroupID

	get _rigAuthCallHook("authPreRegister")

	if (sAuthConfigA["identityColumn"] is "email") and (rigAuthEmailCheck(pEmail) is TRUE) then
		# EMAIL ALREADY USED OR INVALID
		rigAuthSetError "accountCreationDuplicateInvalidEmail"
		return FALSE

	else if (sAuthConfigA["identityColumn"] is "username") and (rigAuthUsernameCheck(pUsername) is TRUE) then
		# USERNAME ALREADY USED OR INVALID
		rigAuthSetError "accountCreationDuplicateInvalidUsername"
		return FALSE
	end if

	# IF USERNAME ALREADY EXISTS ADD A NUMBER LIKE USERNAME1, USERNAME2 ETC.
	if sAuthConfigA["identityColumn"] <> "username" then
		put pUsername into tOriginalUsername
		put TRUE into tUsernameExists

		put 1 into tUserNumber
		repeat until tUsernameExists is FALSE
			if rigAuthUsernameCheck(pUsername) is TRUE then
				put tOriginalUsername & tUserNumber into pUsername
				add 1 to tUserNumber
			else
				put FALSE into tUsernameExists
			end if
		end repeat
	end if

	# ENCRYPT PASSWORD
	put _rigAuthEncryptPassword(pPassword) into pPassword

	# USER DATA
	put pUsername into tData["username"]
	put pPassword into tData["password"]
	put pEmail into tData["email"]
	put rigIpAddress() into tData["ipAddress"]
	put rigMasterNow() into tData["createdOn"]
	put rigMasterNow() into tData["lastLogin"]
	if sAuthConfigA["manualActivation"] is FALSE then
		put 1 into tData["active"]
	else
		put 0 into tData["active"]
	end if

	if pExtraData is an array then
		# FILTER OUT DATA THAT DOESN'T HAVE A MATCHING FIELD IN THE USERS TABLE
		put _rigAuthFilteredData(sAuthConfigA["tables"]["users"], pExtraData) into tFilteredData

		# MERGE FILTERED EXTRA DATA WITH tData
		if tFilteredData is an array then
			put numToCodepoint(1) into tFirstDelim
			put numToCodepoint(2) into tSecondDelim
			combine tData using tFirstDelim and tSecondDelim
			combine tFilteredData using tFirstDelim and tSecondDelim

			put tFirstDelim & tFilteredData after tData
			split tData using tFirstDelim and tSecondDelim
		end if
	end if

	get _rigAuthCallHook("authExtraSet")

	# INSERT USER DATA AND GET ID OF LAST INSERT
	put rigDbInsert(sAuthConfigA["tables"]["users"], tData, TRUE) into tUserID

	# ADD USER ID TO TABLE users_groups
	if tUserID <> FALSE then
		if pGroups is an array then
			repeat for each key tKey in pGroups
				rigAuthAddToGroup pGroups[tKey], tUserID
			end repeat
		end if

		# GET ID OF DEFAULT GROUP
		_rigAuthWhere "name", sAuthConfigA["defaultGroup"]
		put 1 into sAuthLimit
		get rigAuthGroups()
		if sAuthQuery <> FALSE then
			put rigDbRow() into tGroupRow
			put tGroupRow["id"] into tGroupID
		else
			put empty into tGroupID
		end if

		# ADD USER TO DEFAULT GROUP IF NOT SET ALREADY
		if ((tGroupID <> empty) and (pGroups is not an array)) or ((pGroups is an array) and (tGroupID is not among the keys of pGroups)) then
			rigAuthAddToGroup tGroupID, tUserID
		end if

		get _rigAuthCallHook("authPostRegister")

		return tUserID
	end if

	return FALSE
end _rigAuthRegisterUser







/*----------------------------------------------------------------------
--| FUNCTION _rigAuthUpdateLastLogin
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-12-2012
--| Last Mod: 30-12-2012
--| Requires: _rigAuthCallHook(), rigLoadHelper, rigMasterNow(), rigDbWhere,
--|            rigDbUpdate(), rigDbAffectedRows()
--|
--| Summary: Update date of last user login.
--|
--| Format:  _rigAuthUpdateLastLogin(param1)
--|
--| Parameters: integer <pID>
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigAuthUpdateLastLogin pID
  local tData

	get _rigAuthCallHook("authUpdateLastLogin")

	get _rigAuthCallHook("authExtraWhere")

	put rigMasterNow() into tData["lastLogin"]

	rigDbWhere "id", pID
	get rigDbUpdate(sAuthConfigA["tables"]["users"], tData)

	if rigDbAffectedRows() <> FALSE then
		return TRUE
	end if

	return FALSE
end _rigAuthUpdateLastLogin





/*----------------------------------------------------------------------
--| FUNCTION rigAuthClearLoginAttempts
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-12-2012
--| Last Mod: 30-12-2012
--| Requires: rigIpAddress(), rigLoadHelper, rigDbWhere, rigMasterNow(),
--|            rigDbOrWhere, rigDbDelete()
--|
--| Summary: Clear entry for login attempts.
--|
--| Format:  rigAuthClearLoginAttempts(param1, param2)
--|
--| Parameters: string <pIdentity>, integer <pExpirePeriod> (optional)
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthClearLoginAttempts pIdentity pExpirePeriod
  local tExpirePeriod, tIP, tArray, tTimeLessExpirePeriod

	if sAuthConfigA["trackLoginAttempts"] is TRUE then
		if pExpirePeriod is empty then
			put 86400 into tExpirePeriod
		else
			put pExpirePeriod into tExpirePeriod
		end if

		put rigIpAddress() into tIP

		put tIP into tArray["ipAddress"]
		put pIdentity into tArray["login"]

		rigDbWhere tArray
		put rigMasterNow() - tExpirePeriod into tTimeLessExpirePeriod
		rigDbOrWhere "time <", tTimeLessExpirePeriod, FALSE

		if rigDbDelete(sAuthConfigA["tables"]["loginAttempts"]) <> FALSE then
			return TRUE
		end if
	end if

	return FALSE
end rigAuthClearLoginAttempts





/*----------------------------------------------------------------------
--| FUNCTION rigAuthIncreaseLoginAttempts
--|
--| Author: rabit
--| Version:  1.0
--| Created: 31-12-2012
--| Last Mod: 31-12-2012
--| Requires: rigLoadHelper, rigIpAddress(), rigMasterNow(), rigDbInsert()
--|
--| Summary: Increase the number of login attempts.
--|
--| Format:  rigAuthIncreaseLoginAttempts(param1)
--|
--| Parameters: string <pIdentity>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthIncreaseLoginAttempts pIdentity
  local tData

	if sAuthConfigA["trackLoginAttempts"] is TRUE then

		put rigIpAddress() into tData["ipAddress"]
		put pIdentity into tData["login"]
		put rigMasterNow() into tData["time"]

		return rigDbInsert(sAuthConfigA["tables"]["loginAttempts"], tData, TRUE)
	end if

	return FALSE
end rigAuthIncreaseLoginAttempts






/*----------------------------------------------------------------------
--| FUNCTION rigAuthRememberUser
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2012-12-30
--| Last Mod: 2019-01-06
--| Requires: _rigAuthCallHook(), rigDbWhere, rigDbUpdate(), rigDbAffectedRows(), rigSetCookie
--|
--| Summary: Remember user and enable auto-login.
--|
--| Format: rigAuthRememberUser(param1)
--|
--| Parameters: array <pUser>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthRememberUser pUser
  local tSalt, tData, tExpire, tCookieIdentity, tCookieRemCode

	get _rigAuthCallHook("authPreRememberUser")

	if pUser is not an array then
		return FALSE
	end if

	set the itemDel to "."

  if item 1 of the version < 9 then
    put base64Encode(sha1Digest(pUser["password"])) into tSalt
  else
    put base64Encode(messageDigest(pUser["password"], "SHA3-256")) into tSalt
  end if

	put tSalt into tData["rememberCode"]

	rigDbWhere "id", pUser["id"]
	get rigDbUpdate(sAuthConfigA["tables"]["users"], tData)

	if rigDbAffectedRows() <> FALSE then
		# IF autoLoginExpire IS 0 SET THE EXPIRATION TWO YEARS FROM NOW
		if sAuthConfigA["autoLoginExpire"] is 0 then
			put (60*60*24*365*2) into tExpire
		else
			put sAuthConfigA["autoLoginExpire"] into tExpire
		end if

		# SET AUTO-LOGIN COOKIES
		put "identity" into tCookieIdentity["name"]
		put pUser[sAuthConfigA["identityColumn"]] into tCookieIdentity["value"]
		put tExpire into tCookieIdentity["expire"]
		rigSetCookie tCookieIdentity

		put "rememberCode" into tCookieRemCode["name"]
		put tSalt into tCookieRemCode["value"]
		put tExpire into tCookieRemCode["expire"]
		rigSetCookie tCookieRemCode

		get _rigAuthCallHook("authPostRememberUser")
		get _rigAuthCallHook("authRememberUserSuccessful")
		return TRUE
	end if

	get _rigAuthCallHook("authPostRememberUser")
	get _rigAuthCallHook("authRememberUserUnsuccessful")
	return FALSE
end rigAuthRememberUser






/*----------------------------------------------------------------------
--| FUNCTION _rigAuthLoginRememberedUser
--|
--| Author: rabit
--| Version:  1.0
--| Created: 02-01-2013
--| Last Mod: 02-01-2013
--| Requires: _rigAuthCallHook(), rigAuthIdentityCheck(), rigDbSelect, rigDbWhere, rigDbLimit,
--|            rigDbGet(), rigDbRow(), _rigAuthUpdateLastLogin(), rigSetSessUserdata,
--|            rigAuthRememberUser()
--|
--| Summary: Auto-login remembered user.
--|
--| Format:  _rigAuthLoginRememberedUser(param1, param2)
--|
--| Parameters: string <pIdentity>, string <pRememberCode>
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigAuthLoginRememberedUser pIdentity pRememberCode
  local tUserA, tSessionData

	get _rigAuthCallHook("authPreLoginRememberedUser")

	# CHECK FOR VALID DATA
	if rigAuthIdentityCheck(pIdentity) is FALSE then
		get _rigAuthCallHook("authPostLoginRememberedUser")
		get _rigAuthCallHook("authLoginRememberedUserUnsuccessful")

		return FALSE
	end if

	# GET THE USER
	get _rigAuthCallHook("authExtraWhere")

	rigDbSelect sAuthConfigA["identityColumn"] & ", id, password"
	rigDbWhere sAuthConfigA["identityColumn"], pIdentity
	rigDbWhere "rememberCode", pRememberCode
	rigDbLimit 1
	put rigDbGet(sAuthConfigA["tables"]["users"]) into sAuthQuery

	# IF THE IDENTITY WAS FOUND CHECK THE USER IN
	if (sAuthQuery <> FALSE) and (sAuthQuery["numrows"] is 1) then
		put rigDbRow(1) into sAuthUserA
		put sAuthUserA into tUserA

		get _rigAuthUpdateLastLogin(tUserA["id"])

		# SET SESSION DATA
		put tUserA[sAuthConfigA["identityColumn"]] into tSessionData[sAuthConfigA["identityColumn"]]
		put tUserA["id"] into tSessionData["userID"]

		rigSetSessUserdata tSessionData

		# EXTEND THE USERS COOKIES IF THE OPTION IS ENABLED
		if sAuthConfigA["userExtendOnLogin"] is TRUE then
			get rigAuthRememberUser(tUserA)
		end if

		get _rigAuthCallHook("authPostLoginRememberedUser")
		get _rigAuthCallHook("authPostLoginRememberedUserSuccessful")

		return TRUE

	end if

	get _rigAuthCallHook("authPostLoginRememberedUser")
	get _rigAuthCallHook("authPostLoginRememberedUserUnsuccessful")

	return FALSE
end _rigAuthLoginRememberedUser







/*----------------------------------------------------------------------
--| FUNCTION _rigAuthEncryptPassword
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2012-12-31
--| Last Mod: 2017-06-18
--| Requires: _rigAuthSetHash, rigEncode()
--|
--| Summary: Encrypts the password to be stored in the database.
--|
--| Format:  _rigAuthEncryptPassword(param1)
--|
--| Parameters: string <pPassword>
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigAuthEncryptPassword pPassword
	if pPassword is empty then
		return FALSE
	end if

	_rigAuthSetHash

	# CHECK WHICH ENCRYPTION KEY SHOULD BE USED
	# AND ENCRYPT THE PASSWORD
	if sAuthConfigA["useAuthEncryptionKey"] is TRUE then
		return rigEncode(pPassword, sAuthConfigA["authEncryptionKey"])
	end if

	return rigEncode(pPassword)
end _rigAuthEncryptPassword






/*----------------------------------------------------------------------
--| FUNCTION _rigAuthDecryptPassword
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2013-02-20
--| Last Mod: 2017-06-18
--| Requires: _rigAuthSetHash, rigDecode()
--|
--| Summary: Decrypts the password currently stored in the database.
--|
--| Format:  _rigAuthDecryptPassword(param1)
--|
--| Parameters: string <pPassword>
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigAuthDecryptPassword pPassword
	if pPassword is empty then
		return FALSE
	end if

	_rigAuthSetHash

	# CHECK WHICH ENCRYPTION KEY SHOULD BE USED
	# AND ENCRYPT THE PASSWORD
	if sAuthConfigA["useAuthEncryptionKey"] is TRUE then
		return rigDecode(pPassword, sAuthConfigA["authEncryptionKey"])
	end if

	return rigDecode(pPassword)
end _rigAuthDecryptPassword







/*----------------------------------------------------------------------
--| FUNCTION _rigAuthValidatePassword
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2012-12-29
--| Last Mod: 2018-02-21
--| Requires: _rigAuthCallHook(), rigDbSelect, rigDbWhere, rigDbLimit, rigDbGet(),
--|            rigDbRow(), _rigAuthSetHash, rigSetCipher, rigDecode()
--|
--| Summary: Validate password against entry in Users table.
--|
--| Format:  _rigAuthValidatePassword(param1, param2)
--|
--| Parameters: integer <pID>, string <pPassword>
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigAuthValidatePassword pID pPassword
  local tQuery, tRow, tPasswordDBencrypted, tPasswordDB

	if (pID is empty) or (pPassword is empty) then
		return FALSE
	end if

	get _rigAuthCallHook("authExtraWhere")

	rigDbSelect "password"
	rigDbWhere "id", pID
	rigDbLimit 1
	put rigDbGet(sAuthConfigA["tables"]["users"]) into tQuery

	if tQuery["numrows"] <> 1 then
		return FALSE
	end if

	put rigDbRow(1) into tRow
	put tRow["password"] into tPasswordDBencrypted

	_rigAuthSetHash

	# SET THE CIPHER AND THE KEY LENGTH
	rigSetCipher sAuthConfigA["cipher"], sAuthConfigA["keyLength"]

	# CHECK WHICH ENCRYPTION KEY SHOULD BE USED
	# AND DECRYPT THE STORED PASSWORD
	if sAuthConfigA["useAuthEncryptionKey"] is TRUE then
		put rigDecode(tPasswordDBencrypted, sAuthConfigA["authEncryptionKey"]) into tPasswordDB
	else
		put rigDecode(tPasswordDBencrypted) into tPasswordDB
	end if

	# COMPARE PASSWORDS
	set the caseSensitive to true
	if tPasswordDB is pPassword then
		return TRUE
	end if

	return FALSE
end _rigAuthValidatePassword







/*----------------------------------------------------------------------
--| COMMAND rigAuthSetError
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-10-2012
--| Last Mod: 10-10-2012
--| Requires: --
--|
--| Summary: Set error message.
--|
--| Format:  rigAuthSetError param1
--|
--| Parameters: string <pError>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigAuthSetError pError
  local tErrorCount

	put the number of lines in the keys of sAuthErrorsA into tErrorCount
	add 1 to tErrorCount
	put pError into sAuthErrorsA[tErrorCount]
end rigAuthSetError






/*----------------------------------------------------------------------
--| FUNCTION rigAuthErrors
--|
--| Author: rabit
--| Version:  1.0
--| Created: 31-12-2012
--| Last Mod: 31-12-2012
--| Requires: rigLangLangLine()
--|
--| Summary: Return authentication errors.
--|
--| Format:  rigAuthErrors(param1, param2)
--|
--| Parameters: string <pPrefix> (optional), string <pSuffix> (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function rigAuthErrors pPrefix pSuffix
  local tErrorsOut, tError, tLangError

	if pPrefix is empty then
		put sAuthConfigA["errorPrefix"] into pPrefix
	end if

	if pSuffix is empty then
		put sAuthConfigA["errorSuffix"] into pSuffix
	end if

	put "" into tErrorsOut

	repeat for each key tKey in sAuthErrorsA
		put sAuthErrorsA[tKey] into tError

		# CHECK IF ERROR IS IN LANGUAGE FILE
		put rigLangLangLine(tError) into tLangError
		if tLangError is FALSE then
			put "--" & tError & "--" into tLangError
		end if

		put pPrefix & tLangError & pSuffix after tErrorsOut
	end repeat

	return tErrorsOut
end rigAuthErrors






/*----------------------------------------------------------------------
--| FUNCTION rigAuthFieldnames
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-09-2012
--| Last Mod: 12-09-2012
--| Requires: --
--|
--| Summary: Get query field names.
--|
--| Format:  rigAuthFieldnames()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigAuthFieldnames
	return sAuthFieldnames
end rigAuthFieldnames





/*----------------------------------------------------------------------
--| FUNCTION rigAuthIdentityCheck
--|
--| Author: rabit
--| Version:  1.0
--| Created: 02-01-2013
--| Last Mod: 02-01-2013
--| Requires: _rigAuthCallHook(), rigDbWhere, rigDbCountAllResults()
--|
--| Summary: Identity check for remembered users (auto-login).
--|
--| Format:  rigAuthIdentityCheck(param1)
--|
--| Parameters: string <pIdentity>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthIdentityCheck pIdentity
	get _rigAuthCallHook("authIdentityCheck")

	if pIdentity is empty then
		return FALSE
	end if

	rigDbWhere sAuthConfigA["identityColumn"], pIdentity
	if rigDbCountAllResults(sAuthConfigA["tables"]["users"]) > 0 then
		return TRUE
	end if

	return FALSE
end rigAuthIdentityCheck





/*----------------------------------------------------------------------
--| FUNCTION rigAuthEmailCheck
--|
--| Author: rabit
--| Version:  1.0
--| Created: 08-02-2013
--| Last Mod: 08-02-2013
--| Requires: _rigAuthCallHook(), rigDbWhere, rigDbCountAllResults()
--|
--| Summary: Check if there is an entry in the DB regarding
--|            the email address provided.
--|
--| Format:  rigAuthEmailCheck(param1)
--|
--| Parameters: string <pEmail>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthEmailCheck pEmail
	get _rigAuthCallHook("authEmailCheck")

	if pEmail is empty then
		return FALSE
	end if

	get _rigAuthCallHook("authExtraWhere")

	rigDbWhere "email", pEmail
	if rigDbCountAllResults(sAuthConfigA["tables"]["users"]) > 0 then
		return TRUE
	end if

	return FALSE
end rigAuthEmailCheck





/*----------------------------------------------------------------------
--| FUNCTION rigAuthUsernameCheck
--|
--| Author: rabit
--| Version:  1.0
--| Created: 08-02-2013
--| Last Mod: 08-02-2013
--| Requires: _rigAuthCallHook(), rigDbWhere, rigDbCountAllResults()
--|
--| Summary: Check if there is an entry in the DB regarding
--|            the username provided.
--|
--| Format:  rigAuthUsernameCheck(param1)
--|
--| Parameters: string <pUsername>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthUsernameCheck pUsername
	get _rigAuthCallHook("authUsernameCheck")

	if pUsername is empty then
		return FALSE
	end if

	get _rigAuthCallHook("authExtraWhere")

	rigDbWhere "username", pUsername
	if rigDbCountAllResults(sAuthConfigA["tables"]["users"]) > 0 then
		return TRUE
	end if

	return FALSE
end rigAuthUsernameCheck






/*----------------------------------------------------------------------
--| FUNCTION _rigAuthFilteredData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 08-02-2013
--| Last Mod: 08-02-2013
--| Requires: rigDbListFields()
--|
--| Summary: Filter out data that doesn't have a matching field in the users table.
--|
--| Format:  _rigAuthFilteredData(param1, param2)
--|
--| Parameters: string <pTable>, array <pData>
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigAuthFilteredData pTable pData
  local tFields, tDataKeysList, tKey, tFilteredData

	# GET ARRAY OF FIELD NAMES
	put rigDbListFields(pTable) into tFields

	if pData is an array then
		put the keys of pData into tDataKeysList

		# CHECK IF pData KEY IS AMONG THE LINES OF FIELD NAMES
		# FILTER OUT DATA WITHOUT A CORRESPONDING FIELD NAME
		repeat for each key tKey in tFields
			if tFields[tKey] is among the lines of tDataKeysList then
				put pData[tFields[tKey]] into tFilteredData[tFields[tKey]]
			end if
		end repeat

	else
		return FALSE
	end if

	return tFilteredData
end _rigAuthFilteredData





/*----------------------------------------------------------------------
--| COMMAND rigAuthAddToGroup
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2013-02-08
--| Last Mod: 2017-01-17
--| Requires: _rigAuthCallHook(), rigSessUserdata(), rigDbInsert
--|
--| Summary: Add user to group.
--|
--| Format:  rigAuthAddToGroup param1, param2
--|
--| Parameters: integer <pGroupID>, integer <pUserID>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigAuthAddToGroup pGroupID pUserID
  local tUserID, tData

	get _rigAuthCallHook("authAddToGroup")

	# USE ID OF CURRENT USER IF pUserID IS EMPTY
	if pUserID is empty then
		put rigSessUserdata("userID") into tUserID
	else
		put pUserID into tUserID
	end if

	if rigAuthInGroup(pGroupID, tUserID) is false then
		put pGroupID into tData[sAuthConfigA["join"]["groups"]]
		put tUserID into tData[sAuthConfigA["join"]["users"]]
		get rigDbInsert(sAuthConfigA["tables"]["usersGroups"], tData)
	end if
end rigAuthAddToGroup





/*----------------------------------------------------------------------
--| COMMAND _rigAuthWhere
--|
--| Author: rabit
--| Version:  1.2
--| Created: 08-02-2013
--| Last Mod: 22-12-2014
--| Requires: _rigAuthCallHook()
--|
--| Summary: Add key value pairs to sAuthWhere.
--|
--| Format:  _rigAuthWhere param1, param2
--|
--| Parameters: mixed <pWhere>, string <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigAuthWhere pWhere pValue
  local tWhereArray, tFirstDelim, tSecondDelim

	get _rigAuthCallHook("authWhere")

	if pWhere is not an array then
		put pValue into tWhereArray[pWhere]
	else
		put pWhere into tWhereArray
	end if

	if sAuthWhere is an array then
		put numToCodepoint(1) into tFirstDelim
		put numToCodepoint(2) into tSecondDelim
		combine sAuthWhere using tFirstDelim and tSecondDelim
		combine tWhereArray using tFirstDelim and tSecondDelim

		put tFirstDelim & tWhereArray after sAuthWhere
		split sAuthWhere using tFirstDelim and tSecondDelim
	else
		put tWhereArray into sAuthWhere
	end if
end _rigAuthWhere








/*----------------------------------------------------------------------
--| FUNCTION rigAuthGroups
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-02-2013
--| Last Mod: 09-02-2013
--| Requires: _rigAuthCallHook()
--|
--| Summary: Get the groups.
--|
--| Format:  rigAuthGroups()
--|
--| Parameters: --
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigAuthGroups
	get _rigAuthCallHook("authGroups")

	# RUN EACH WHERE OF sAuthWhere
	if sAuthWhere is an array then
			rigDbWhere sAuthWhere

		put empty into sAuthWhere
	end if

	# CHECK LIMIT AND OFFSET
	if (sAuthLimit <> "") and (sAuthOffset <> "") then
		rigDbLimit sAuthLimit, sAuthOffset
		put "" into sAuthLimit
		put "" into sAuthOffset
	else if sAuthLimit <> "" then
		rigDbLimit sAuthLimit
		put "" into sAuthLimit
	end if

	# SET ORDER
	if (sAuthOrderBy <> "") and (sAuthOrder <> "") then
		rigDbOrderBy sAuthOrderBy, sAuthOrder
		put "" into sAuthOrderBy
		put "" into sAuthOrder
	end if

	# RUN THE QUERY AND RETURN THE RESULT
	put rigDbGet(sAuthConfigA["tables"]["groups"]) into sAuthQuery

	if sAuthQuery <> FALSE then
		put sAuthQuery["fieldnames"] into sAuthFieldnames
		return sAuthQuery["resultarray"]
	end if

	return FALSE
end rigAuthGroups






/*----------------------------------------------------------------------
--| FUNCTION rigAuthGroup
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-02-2013
--| Last Mod: 21-02-2013
--| Requires: _rigAuthCallHook(), rigDbWhere
--|
--| Summary: Get a specific group.
--|
--| Format:  rigAuthGroup(param1)
--|
--| Parameters: integer <pID>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigAuthGroup pID
	get _rigAuthCallHook("authGroup")

	if pID <> empty then
		rigDbWhere sAuthConfigA["tables"]["groups"] & ".id", pID
	end if

	put 1 into sAuthLimit

	return rigAuthGroups()
end rigAuthGroup







/*----------------------------------------------------------------------
--| FUNCTION rigAuthForgottenPassword
--|
--| Author: rabit
--| Version:  1.2
--| Created: 17-02-2013
--| Last Mod: 21-03-2014
--| Requires: _rigAuthForgottenPassword(), _rigAuthWhere, rigAuthUsers(), rigDbRow(),
--|            rigAuthSetMessage, rigAnchor(), rigLoadView(), rigClearMail,
--|            rigMailFrom, rigMailTo, rigMailSubject, rigMailMessage, rigMailSend(),
--|            rigAuthSetError
--|
--| Summary: User forgot password.
--|
--| Format:  rigAuthForgottenPassword(param1, param2)
--|
--| Parameters: string <pIdentity>, array <pExtraData> currently used for custom link
--|             to a reset password page
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigAuthForgottenPassword pIdentity pExtraData
  local tQueryResultArray, tUserA, tData, tEmailTemplate, tAuthPathToEmailTemplates
  local tMessage

	if _rigAuthForgottenPassword(pIdentity) is TRUE then
		# GET USER INFORMATION
		_rigAuthWhere sAuthConfigA["identityColumn"], pIdentity
		put rigAuthUsers() into tQueryResultArray

		if tQueryResultArray <> FALSE then
			put rigDbRow() into tUserA

			put tUserA[sAuthConfigA["identityColumn"]] into tData["identity"]
			put tUserA["forgottenPasswordCode"] into tData["forgottenPasswordCode"]

			if sAuthConfigA["sendEmails"] is FALSE then
				rigAuthSetMessage "forgotPasswordSuccessful"

				return tData
			else

				put tUserA[sAuthConfigA["identityColumn"]] into gData["identity"]

				# BUILD LINK FOR PASSWORD RESET
				if pExtraData["passwordResetLink"] is empty then
					put "auth/resetPassword/" into pExtraData["passwordResetLink"]
					else if char -1 of pExtraData["passwordResetLink"] <> "/" then
						put pExtraData["passwordResetLink"] & "/" into pExtraData["passwordResetLink"]
				end if
				put rigAnchor(pExtraData["passwordResetLink"] & tUserA["forgottenPasswordCode"] & "/", rigLangLangLine("resetPasswordLinkText")) into gData["forgottenPasswordCode"]

				# GET PATH TO FORGOTTEN PASSWORD EMAIL TEMPLATE
				if sAuthConfigA["pathToEmailTemplates"] is empty then
					put "emailTemplates/" & sAuthConfigA["emailForgotPassword"] into tEmailTemplate
				else
					if char -1 of sAuthConfigA["pathToEmailTemplates"] <> "/" then
						put sAuthConfigA["pathToEmailTemplates"] & "/" into tAuthPathToEmailTemplates
					else
						put sAuthConfigA["pathToEmailTemplates"] into tAuthPathToEmailTemplates
					end if

					put tAuthPathToEmailTemplates & sAuthConfigA["emailForgotPassword"] into tEmailTemplate
				end if

				# MERGE FORGOTTEN PASSWORD EMAIL TEMPLATE
				put rigLoadView(tEmailTemplate, TRUE) into tMessage
				put merge(tMessage) into tMessage

				# SEND MAIL
				rigClearMail
				rigMailFrom sAuthConfigA["adminEmail"], sAuthConfigA["siteTitle"]
				rigMailTo tUserA["email"]
				rigMailSubject sAuthConfigA["siteTitle"] && "-" && rigLangLangLine("emailForgottenPasswordSubject")
				rigMailMessage tMessage

				if rigMailSend() is TRUE then
					rigAuthSetMessage "forgotPasswordSuccessful"

					return TRUE
				else
					rigAuthSetError "forgotPasswordUnsuccessful"

					return FALSE
				end if

			end if

		else
			rigAuthSetError "forgotPasswordUnsuccessful"

			return FALSE
		end if -- if tQueryResultArray <> FALSE then

	else
		rigAuthSetError "forgotPasswordUnsuccessful"

		return FALSE
	end if -- if _rigAuthForgottenPassword(pIdentity) is TRUE then

end rigAuthForgottenPassword







/*----------------------------------------------------------------------
--| FUNCTION _rigAuthForgottenPassword
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-02-2013
--| Last Mod: 17-02-2013
--| Requires: _rigAuthCallHook(), rigHexDigest(), rigMasterNow(),
--|            rigDbWhere, rigDbUpdate(), rigDbAffectedRows()
--|
--| Summary: Insert a forgotten password key.
--|
--| Format:  _rigAuthForgottenPassword(param1)
--|
--| Parameters: string <pIdentity>
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigAuthForgottenPassword pIdentity
  local tData

	if pIdentity is empty then
		get _rigAuthCallHook("authPostFrogottenPassword")
		get _rigAuthCallHook("authPostFrogottenPasswordUnsuccessful")

		return FALSE
	end if

	put rigHexDigest(sha1Digest(the long seconds & pIdentity)) into sAuthForgottenPasswordCode

	get _rigAuthCallHook("authExtraWhere")

	put sAuthForgottenPasswordCode into tData["forgottenPasswordCode"]
	put rigMasterNow() into tData["forgottenPasswordTime"]

	rigDbWhere sAuthConfigA["identityColumn"], pIdentity
	get rigDbUpdate(sAuthConfigA["tables"]["users"], tData)

	if rigDbAffectedRows() is 1 then
			get _rigAuthCallHook("authPostFrogottenPassword")
			get _rigAuthCallHook("authPostFrogottenPasswordSuccessful")

			return TRUE
	else
			get _rigAuthCallHook("authPostFrogottenPassword")
			get _rigAuthCallHook("authPostFrogottenPasswordUnsuccessful")
	end if

	return FALSE
end _rigAuthForgottenPassword







/*----------------------------------------------------------------------
--| FUNCTION rigAuthForgottenPasswordCheck
--|
--| Author: rabit
--| Version:  1.0
--| Created: 17-02-2013
--| Last Mod: 17-02-2013
--| Requires: _rigAuthWhere, rigAuthUsers(), rigAuthSetError, rigDbRow(),
--|            rigMasterNow(), rigAuthClearForgottenPasswordCode()
--|
--| Summary: Check the forgotten password reset code.
--|
--| Format:  rigAuthForgottenPasswordCheck(param1)
--|
--| Parameters: string <pCode>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigAuthForgottenPasswordCheck pCode
  local tUserA

	# GET USER DATA
	_rigAuthWhere "forgottenPasswordCode", pCode
	get rigAuthUsers()

	if sAuthQuery is FALSE then
		rigAuthSetError "passwordChangeUnsuccessful"

		return FALSE
	else

		put rigDbRow() into tUserA

		if sAuthConfigA["forgotPasswordExpiration"] > 0 then
			# CHECK IF THE FORGOT PASSWORD REQUEST IS EXPIRED
			if (rigMasterNow() - tUserA["forgottenPasswordTime"]) > sAuthConfigA["forgotPasswordExpiration"] then
				# IT HAS EXPIRED
				get rigAuthClearForgottenPasswordCode(pCode)
				rigAuthSetError "passwordChangeUnsuccessful"

				return FALSE
			end if

		end if

		return tUserA
	end if
end rigAuthForgottenPasswordCheck







/*----------------------------------------------------------------------
--| FUNCTION rigAuthClearForgottenPasswordCode
--|
--| Author: rabit
--| Version:  1.1
--| Created: 17-02-2013
--| Last Mod: 05-03-2013
--| Requires: rigDbWhere, rigDbCountAllResults(), rigDbUpdate()
--|
--| Summary: Delete the forgotten password code.
--|
--| Format:  rigAuthClearForgottenPasswordCode(param1)
--|
--| Parameters: string <pCode>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthClearForgottenPasswordCode pCode
  local tData

	if pCode is empty then
		return FALSE
	end if

	rigDbWhere "forgottenPasswordCode", pCode
	if rigDbCountAllResults(sAuthConfigA["tables"]["users"]) > 0 then
		put empty into tData["forgottenPasswordCode"]
		put 0 into tData["forgottenPasswordTime"]

		-- rigDbWhere "forgottenPasswordCode", pCode
		get rigDbUpdate(sAuthConfigA["tables"]["users"], tData, "forgottenPasswordCode = '" & pCode & "'")

		return TRUE
	end if

	return FALSE
end rigAuthClearForgottenPasswordCode







/*----------------------------------------------------------------------
--| FUNCTION rigAuthResetPassword
--|
--| Author: rabit
--| Version:  1.1
--| Created: 18-02-2013
--| Last Mod: 05-03-2013
--| Requires: _rigAuthCallHook(), rigAuthIdentityCheck(), rigDbSelect, rigDbWhere,
--|            rigDbLimit, rigDbGet(), rigDbRow(), rigAuthSetError, _rigAuthEncryptPassword(),
--|            rigDbUpdate(), rigDbAffectedRows(), rigAuthSetMessage
--|
--| Summary: Replace password with a new one.
--|
--| Format:  rigAuthResetPassword(param1, param2)
--|
--| Parameters: string <pIdentity>, string <pNewPassword>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthResetPassword pIdentity pNewPassword
  local tUserA, tNewPassword, tData

	get _rigAuthCallHook("authPreChangePassword")

	if rigAuthIdentityCheck(pIdentity) is FALSE then
		get _rigAuthCallHook("authPostChangePassword")
		get _rigAuthCallHook("authPostChangePasswordUnsuccessful")

		return FALSE
	end if

	get _rigAuthCallHook("authExtraWhere")

	rigDbSelect "id, password"
	rigDbWhere sAuthConfigA["identityColumn"], pIdentity
	rigDbLimit 1
	put rigDbGet(sAuthConfigA["tables"]["users"]) into sAuthQuery

	if (sAuthQuery <> FALSE) and (sAuthQuery["numrows"] is 1) then
		put rigDbRow() into sAuthUserA
		put sAuthUserA into tUserA

	else
		get _rigAuthCallHook("authPostChangePassword")
		get _rigAuthCallHook("authPostChangePasswordUnsuccessful")
		rigAuthSetError "passwordChangeUnsuccessful"

		return FALSE
	end if

	# ENCRYPT NEW PASSWORD
	put _rigAuthEncryptPassword(pNewPassword) into tNewPassword

	# STORE THE NEW PASSWORD AND RESET THE REMEMBER CODE SO ALL REMEMBERED INSTANCES HAVE TO RE-LOGIN
	# CLEAR THE FORGOTTEN PASSWORD CODE
	put tNewPassword into tData["password"]
	put empty into tData["rememberCode"]
	put empty into tData["forgottenPasswordCode"]
	put 0 into tData["forgottenPasswordTime"]

	get _rigAuthCallHook("authExtraWhere")

	get rigDbUpdate(sAuthConfigA["tables"]["users"], tData, sAuthConfigA["identityColumn"] && "= '" & pIdentity & "'")

	if rigDbAffectedRows() is 1 then
			get _rigAuthCallHook("authPostChangePassword")
			get _rigAuthCallHook("authPostChangePasswordSuccessful")
			rigAuthSetMessage "passwordChangeSuccessful"

			return TRUE
	else
			get _rigAuthCallHook("authPostChangePassword")
			get _rigAuthCallHook("authPostChangePasswordUnsuccessful")
			rigAuthSetError "passwordChangeUnsuccessful"
	end if

	return FALSE
end rigAuthResetPassword






/*----------------------------------------------------------------------
--| FUNCTION rigAuthChangePassword
--|
--| Author: rabit
--| Version:  1.1
--| Created: 20-02-2013
--| Last Mod: 05-03-2013
--| Requires: _rigAuthCallHook(), rigDbSelect, rigDbWhere, rigDbLimit, rigDbGet(),
--|            rigDbRow(), rigAuthSetError, _rigAuthDecryptPassword(), _rigAuthEncryptPassword(),
--|            rigDbUpdate(), rigDbAffectedRows, rigAuthSetMessage
--|
--| Summary: Change user password.
--|
--| Format:  rigAuthChangePassword(param1, param2, param3)
--|
--| Parameters: string <pIdentity>, string <pOldPassword>, string <pNewPassword>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthChangePassword pIdentity pOldPassword pNewPassword
  local tUserA, tDBpassword, tNewPassword, tData

	get _rigAuthCallHook("authPreChangePassword")

	get _rigAuthCallHook("authExtraWhere")

	rigDbSelect "id, password"
	rigDbWhere sAuthConfigA["identityColumn"], pIdentity
	rigDbLimit 1
	put rigDbGet(sAuthConfigA["tables"]["users"]) into sAuthQuery

	if (sAuthQuery <> FALSE) and (sAuthQuery["numrows"] is 1) then
		put rigDbRow() into sAuthUserA
		put sAuthUserA into tUserA

	else
		get _rigAuthCallHook("authPostChangePassword")
		get _rigAuthCallHook("authPostChangePasswordUnsuccessful")
		rigAuthSetError "passwordChangeUnsuccessful"
		return FALSE
	end if

	put _rigAuthDecryptPassword(tUserA["password"]) into tDBpassword
	put _rigAuthEncryptPassword(pNewPassword) into tNewPassword

	# VALIDATE OLD PASSWORD
	# DECRYPT DATABASE PASSWORD
	if pOldPassword is tDBpassword then
		put tNewPassword into tData["password"]
		put empty into tData["rememberCode"]

		get _rigAuthCallHook("authExtraWhere")

		get rigDbUpdate(sAuthConfigA["tables"]["users"], tData, sAuthConfigA["identityColumn"] && "= '" & pIdentity & "'")

		if rigDbAffectedRows() is 1 then
				get _rigAuthCallHook("authPostChangePassword")
				get _rigAuthCallHook("authPostChangePasswordSuccessful")
				rigAuthSetMessage "passwordChangeSuccessful"

				return TRUE
		else
				get _rigAuthCallHook("authPostChangePassword")
				get _rigAuthCallHook("authPostChangePasswordUnsuccessful")
				rigAuthSetError "passwordChangeUnsuccessful"

				return FALSE
		end if

	end if -- if pOldPassword is tDBpassword then

	rigAuthSetError "passwordChangeUnsuccessful"

	return FALSE
end rigAuthChangePassword








/*----------------------------------------------------------------------
--| FUNCTION rigAuthUpdate
--|
--| Author: rabit
--| Version:  1.1
--| Created: 20-02-2013
--| Last Mod: 05-03-2013
--| Requires: _rigAuthCallHook(), rigAuthUser(), rigDbRow(), rigTransBegin(),
--|            rigAuthIdentityCheck(), rigTransRollback, rigAuthSetError,
--|            rigAuthFilterData(), _rigAuthEncryptPassword(), rigDbUpdate(),
--|            rigDbTransStatus(), rigTransCommit
--|
--| Summary: Update user data.
--|
--| Format:  rigAuthUpdate(param1, param2)
--|
--| Parameters: integer <pID>, array <pData>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthUpdate pID pData
  local tQueryResult, tUserA, tData

	get _rigAuthCallHook("authPreUpdateUser")

	put rigAuthUser(pID) into tQueryResult

	if (tQueryResult <> FALSE) and (tQueryResult is an array) then
		put rigDbRow() into tUserA
	else
		get _rigAuthCallHook("authPostUpdateUser")
		get _rigAuthCallHook("authPostUpdateUserUnsuccessful")

		return FALSE
	end if

	# RUN TRANSACTIONS
	get rigTransBegin()

	if (sAuthConfigA["identityColumn"] is among the keys of pData) and \
		(rigAuthIdentityCheck(pData[sAuthConfigA["identityColumn"]]) is TRUE) and \
		(tUserA[sAuthConfigA["identityColumn"]] <> pData[sAuthConfigA["identityColumn"]]) then

		rigTransRollback

		rigAuthSetError "accountCreationDuplicateInvalid" & sAuthConfigA["identityColumn"]
		get _rigAuthCallHook("authPostUpdateUser")
		get _rigAuthCallHook("authPostUpdateUserUnsuccessful")
		rigAuthSetError "updateUnsuccessful"

		return FALSE
	end if

	put rigAuthFilterData(sAuthConfigA["tables"]["users"], pData) into tData

	if ("username" is among the keys of tData) or ("password" is among the keys of tData) or ("email" is among the keys of tData) then
		if "password" is among the keys of tData then
			if tData["password"] <> empty then
				# ENCRYPT PASSWORD
				put _rigAuthEncryptPassword(tData["password"]) into tData["password"]

			else
				# REMOVE VARIABLE PASSWORD SO IT DOESN'T EFFECT DATABASE ENTRY IF NO PASSWORD PASSED
				delete variable tData["password"]
			end if

		end if

	end if

	get _rigAuthCallHook("authExtraWhere")

	get rigDbUpdate(sAuthConfigA["tables"]["users"], tData, "id = '" & tUserA["id"] & "'")

	# CHECK TRANSACTION STATUS
	if rigDbTransStatus() is FALSE then
	    rigTransRollback

			get _rigAuthCallHook("authPostUpdateUser")
			get _rigAuthCallHook("authPostUpdateUserUnsuccessful")
			rigAuthSetError "updateUnsuccessful"

			return FALSE
	end if

	rigTransCommit

	get _rigAuthCallHook("authPostUpdateUser")
	get _rigAuthCallHook("authPostUpdateUserSuccessful")
	rigAuthSetError "updateSuccessful"

	return TRUE

end rigAuthUpdate







/*----------------------------------------------------------------------
--| FUNCTION rigAuthFilterData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 20-02-2013
--| Last Mod: 20-02-2013
--| Requires: rigDbListFields()
--|
--| Summary: Filter passed data prior to updating existing user data.
--|
--| Format:  rigAuthFilterData(param1, param2)
--|
--| Parameters: string <pTable>, array <pData>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigAuthFilterData pTable pData
  local tFilteredArray, tColumns, tKey

	put empty into tFilteredArray

	put rigDbListFields(pTable) into tColumns

	if pData is an array then
		repeat for each key tKey in tColumns
			if tColumns[tKey] is among the keys of pData then
				put pData[tColumns[tKey]] into tFilteredArray[tColumns[tKey]]
			end if

		end repeat
	end if

	return tFilteredArray
end rigAuthFilterData







/*----------------------------------------------------------------------
--| FUNCTION rigAuthDeleteUser
--|
--| Author: rabit
--| Version:  1.1
--| Created: 21-02-2013
--| Last Mod: 05-03-2013
--| Requires: _rigAuthCallHook(), rigTransBegin(), rigDbDelete(), rigAuthRemoveFromGroup(),
--|            rigDbTransStatus(), rigTransRollback, rigAuthSetError, rigTransCommit
--|            rigAuthSetMessage
--|
--| Summary: Delete user from database.
--|
--| Format:  rigAuthDeleteUser(param1)
--|
--| Parameters: integer <pID>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthDeleteUser pID
  local tGroupIDs

	get _rigAuthCallHook("authPreDeleteUser")

	# RUN TRANSACTIONS
	get rigTransBegin()

	# DELETE USER FROM USERS TABLE
	get rigDbDelete(sAuthConfigA["tables"]["users"], "id =" && pID)

	# REMOVE USER FROM ALL GROUPS
	put empty into tGroupIDs
	get rigAuthRemoveFromGroup(tGroupIDs , pID)

	# CHECK TRANSACTION STATUS
	if rigDbTransStatus() is FALSE then
	   rigTransRollback

		get _rigAuthCallHook("authPostDeleteUser")
		get _rigAuthCallHook("authPostDeleteUserUnsuccessful")
		rigAuthSetError "deleteUnsuccessful"

		return FALSE
	end if

	rigTransCommit

	get _rigAuthCallHook("authPostDeleteUser")
	get _rigAuthCallHook("authPostDeleteUserSuccessful")
	rigAuthSetMessage "deleteSuccessful"

	return TRUE
end rigAuthDeleteUser







/*----------------------------------------------------------------------
--| FUNCTION rigAuthRemoveFromGroup
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-02-2013
--| Last Mod: 21-02-2013
--| Requires: _rigAuthCallHook(), rigDbDelete()
--|
--| Summary: Remove user from group.
--|
--| Format:  rigAuthRemoveFromGroup(param1, param2)
--|
--| Parameters: mixed <pGroupIDs>, integer <pUserID>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthRemoveFromGroup pGroupIDs pUserID
  local tWhereArray, tKey

  get _rigAuthCallHook("authRemoveFromGroup")

  # USER ID IS REQUIRED
  if pUserID is empty then
    return FALSE
  end if

  put pUserID into tWhereArray[sAuthConfigA["join"]["users"]]

  if (pGroupIDs is an array) or (pGroupIDs <> empty) then

    if pGroupIDs is an array then
      repeat for each key tKey in pGroupIDs
        put pGroupIDs[tKey] into tWhereArray[sAuthConfigA["join"]["groups"]]
        get rigDbDelete(sAuthConfigA["tables"]["usersGroups"], tWhereArray)
      end repeat

      return TRUE

    else
      put pGroupIDs into tWhereArray[sAuthConfigA["join"]["groups"]]
      return rigDbDelete(sAuthConfigA["tables"]["usersGroups"], tWhereArray)
    end if

  else
    # IF NO GROUP WAS SPECIIFIED REMOVE USER FROM ALL GROUPS
    return rigDbDelete(sAuthConfigA["tables"]["usersGroups"], tWhereArray)
  end if -- if (pGroupIDs is an array) or (pGroupIDs <> empty) then

end rigAuthRemoveFromGroup






/*----------------------------------------------------------------------
--| FUNCTION rigAuthIsMaxLoginAttemptsExceeded
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-02-2013
--| Last Mod: 21-02-2013
--| Requires: rigAuthGetAttemptsNum()
--|
--| Summary: Check if the number of login attempts exeeds the allowed number.
--|
--| Format:  rigAuthIsMaxLoginAttemptsExceeded(param1)
--|
--| Parameters: string <pIdentity>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigAuthIsMaxLoginAttemptsExceeded pIdentity
  local tMaxAttempts, tAttempts

  if sAuthConfigA["trackLoginAttempts"] is TRUE then
    put sAuthConfigA["maxLoginAttempts"] into tMaxAttempts

    if sAuthConfigA["maxLoginAttempts"] > 0 then
      put rigAuthGetAttemptsNum(pIdentity) into tAttempts

      return tAttempts >= tMaxAttempts
    end if

  end if

  return FALSE
end rigAuthIsMaxLoginAttemptsExceeded







/*----------------------------------------------------------------------
--| FUNCTION rigAuthGetAttemptsNum
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-02-2013
--| Last Mod: 21-02-2013
--| Requires: rigIpAddress(), rigDbSelect, rigDbWhere, rigDbOrWhere, rigDbGet()
--|
--| Summary: Get number of login attempts from a given ipAddress or identity.
--|
--| Format:  rigAuthGetAttemptsNum(param1)
--|
--| Parameters: string <pIdentity>
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigAuthGetAttemptsNum pIdentity
  local tIPaddress, tQuery

  if sAuthConfigA["maxLoginAttempts"] <> 0 then

    put rigIpAddress() into tIPaddress

    # CREATE A COLUMN CONTAINING THE VALUE 1 FOR EACH ROW
    rigDbSelect 1, FALSE
    rigDbWhere "ipAddress", tIPaddress

    if pIdentity <> empty then
      rigDbOrWhere "login", pIdentity
    end if

    put rigDbGet(sAuthConfigA["tables"]["loginAttempts"]) into tQuery

    return tQuery["numrows"]
  end if

  return 0
end rigAuthGetAttemptsNum






/*----------------------------------------------------------------------
--| COMMAND rigAuthSetMessageDelimiters
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-02-2013
--| Last Mod: 21-02-2013
--| Requires: --
--|
--| Summary: Set the message delimiters.
--|
--| Format:  rigAuthSetMessageDelimiters param1, param2
--|
--| Parameters: string <pStartDelimiter>, string <pEndDelimiter>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigAuthSetMessageDelimiters pStartDelimiter pEndDelimiter
	put pStartDelimiter into sAuthConfigA["messagePrefix"]
	put pEndDelimiter into sAuthConfigA["messagePrefix"]
end rigAuthSetMessageDelimiters






/*----------------------------------------------------------------------
--| COMMAND rigAuthSetErrorDelimiters
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-02-2013
--| Last Mod: 21-02-2013
--| Requires: --
--|
--| Summary: Set the message delimiters.
--|
--| Format:  rigAuthSetErrorDelimiters param1, param2
--|
--| Parameters: string <pStartDelimiter>, string <pEndDelimiter>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigAuthSetErrorDelimiters pStartDelimiter pEndDelimiter
	put pStartDelimiter into sAuthConfigA["errorPrefix"]
	put pEndDelimiter into sAuthConfigA["errorSuffix"]
end rigAuthSetErrorDelimiters






/*----------------------------------------------------------------------
--| COMMAND _rigInitAuthHooksPrefs
--|
--| Author: rabit
--| Version:  1.1
--| Created: 22-02-13
--| Last Mod: 17-09-15
--| Requires: rigLogMessage
--|
--| Summary: Initialize the authentication hooks preferences.
--|
--|
--| Format:  _rigInitAuthHooksPrefs
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigInitAuthHooksPrefs
	# IF AUTHENTICATION HOOKS ARE NOT ENABLED IN THE AUTHENTICATION CONFIG FILE
	# THERE IS NOTHING ELSE TO DO
	if sAuthConfigA["enableAuthenticationHooks"] is FALSE then
		exit _rigInitAuthHooksPrefs
	end if

	# GRAB THE AUTHENTICATION HOOKS DEFINITION FILE.
	# IF THERE ARE NO HOOKS, WE'RE DONE.
	try
    _rigRequire gRigA["APPPATH"] & "config/authenticationHooks" & gRigA["EXT"]
	catch err
		rigLogMessage "error", "An error occured while trying to include configuration file:" && "authenticationHooks" & gRigA["EXT"]
	end try

	if sAuthHooksA is not an array then
		exit _rigInitAuthHooksPrefs
	end if

	put TRUE into sAuthHooksEnabled
end _rigInitAuthHooksPrefs






/*----------------------------------------------------------------------
--| COMMAND rigSetAuthHooksConfig
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-02-13
--| Last Mod: 22-02-13
--| Requires: --
--|
--| Summary: Set hooks configuration.
--|
--| Format:  rigSetAuthHooksConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetAuthHooksConfig pConfig
	if pConfig is an array then
		put pConfig into sAuthHooksA
	end if
end rigSetAuthHooksConfig






/*----------------------------------------------------------------------
--| FUNCTION _rigAuthCallHook
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-02-13
--| Last Mod: 22-02-13
--| Requires: _rigAuthRunHook()
--|
--| Summary: Calls a particular authentication hook.
--|
--| Format:  _rigAuthCallHook(param1)
--|
--| Parameters: string <pWhich>the hook name
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigAuthCallHook pWhich
  local tAuthHookResultTemp, tAuthHookResult

	if sAuthHooksEnabled is not TRUE or (sAuthHooksA is not an array) then
		return FALSE
	end if

	put "" into tAuthHookResultTemp

	if sAuthHooksA[pWhich][1] is an array then
		repeat for each key tKey in sAuthHooksA[pWhich]
			put _rigAuthRunHook(sAuthHooksA[pWhich][tKey]) into tAuthHookResult
			if tAuthHookResult is FALSE then
				put FALSE into tAuthHookResultTemp
			end if
		end repeat
	else

		put _rigAuthRunHook(sAuthHooksA[pWhich]) into tAuthHookResult
	end if

	if tAuthHookResultTemp is not empty then
		return FALSE
	end if

	return tAuthHookResult
end _rigAuthCallHook






/*----------------------------------------------------------------------
--| FUNCTION _rigAuthRunHook
--|
--| Author: rabit
--| Version:  1.2
--| Created: 22-02-13
--| Last Mod: 17-09-15
--| Requires: rigTrim()
--|
--| Summary: Runs a particular authentication hook.
--|
--| Format:  _rigAuthRunHook(param1)
--|
--| Parameters: array <pData> the hook details
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigAuthRunHook pData
  local tFilePath, tFilename, tHandler, tParams, tIsFunction

	if pData is not an array then
		return FALSE
	end if

	# SAFETY - PREVENTS RUN-AWAY LOOPS
	#
	# IF THE SCRIPT BEING CALLED HAPPENS TO HAVE THE SAME
	# HOOK CALL WITHIN IT A LOOP CAN HAPPEN
	if sAuthHookInProgress is TRUE then
		exit _rigAuthRunHook
	end if

	# SET FILE PATH
	if pData["filepath"] is empty or pData["filename"] is empty then
		return FALSE
	else
		put pData["filepath"] into tFilePath
	end if

	put rigTrim(tFilePath, "/") into tFilePath

	put pData["filename"] into tFilename

	put gRigA["APPPATH"] & tFilePath & "/" & tFilename into tFilepath

	if there is a file tFilepath then
	else
		return FALSE
	end if

	# GET HANDLER NAME
	if pData["handler"] is not empty then
		put pData["handler"] into tHandler
	else
		return FALSE
	end if

	put "" into tParams

	if (pData["params"] is an array) or ((pData["params"] is not an array) and (pData["params"] is not empty)) then
		put pData["params"] into tParams
	end if

	# SET THE sAuthHookInProgress FLAG
	put TRUE into sAuthHookInProgress

	# CALL THE REQUESTED HANDLER
	if itemOffset(tHandler, sAuthHooksHandlers) is 0 then


		if itemOffset(tFilename, sAuthHooksFiles) is 0 then
			start using stack tFilepath

			if sAuthHooksFiles is empty then
				put tFilename into sAuthHooksFiles
			else
				put comma & tFilename after sAuthHooksFiles
			end if
		end if


		if sAuthHooksHandlers is empty then
			put tHandler into sAuthHooksHandlers
		else
			put comma & tHandler after sAuthHooksHandlers
		end if
	end if

	combine tParams using comma

	# CHECK IF HANDLER IS A FUNCTION
	if char -2 to -1 of tHandler is "()" then
		put TRUE into tIsFunction
	end if

	if tIsFunction is TRUE then
		put "get" && (char 1 to -2 of tHandler)  & tParams & ")" into tHandler
	else
		put tHandler && tParams into tHandler
	end if

	do tHandler

	put FALSE into sAuthHookInProgress

	return TRUE
end _rigAuthRunHook





/*----------------------------------------------------------------------
--| COMMAND _rigAuthSetHash
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2017-06-18
--| Last Mod: 2017-06-18
--| Requires: rigSetHash (see Encrypt.lc)
--|
--| Summary: Set hash type to be used by the encryption library.
--|
--| Format:  _rigAuthSetHash
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigAuthSetHash
	if sAuthConfigA["hashType"] <> "" then
		rigSetHash sAuthConfigA["hashType"]
	end if
end _rigAuthSetHash





/*----------------------------------------------------------------------
--| FUNCTION rigAuthenticationGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2018-12-20
--| Last Mod: 2018-12-20
--| Requires: --
--|
--| Summary: Get user data like "username", "email" etc.
--|
--| Format:  rigAuthenticationGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigAuthenticationGet pWhat
   if pWhat is among the keys of sAuthUserA then
      return sAuthUserA[pWhat]
   end if

   return empty
end rigAuthenticationGet





# --------------------------- OTP -------------------------------------->





/*----------------------------------------------------------------------
--| COMMAND rigAuthUseOTP
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2019-06-19
--| Last Mod: 2019-06-26
--| Requires: rigLoadHelper
--|
--| Summary: Load the OTP helper.
--|
--| Format:  rigAuthUseOTP
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigAuthUseOTP
  put TRUE into sAuthConfigA["otpEnabled"]
  rigLoadHelper "otp"
end rigAuthUseOTP



/*----------------------------------------------------------------------
--| FUNCTION rigAuthGenerateQR
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2019-06-18
--| Last Mod: 2019-06-26
--| Requires: rigAuthUser(), rigDbRow(), rigAuthFetchConfigItem(), rigOTPqrCode()
--|
--| Summary: Return user key and QR code of OTP URI data.
--|
--| Format:  rigAuthGenerateQR([param1])
--|
--| Parameters: string <pAccount> (optional)
--|
--| Return: array
----------------------------------------------------------------------*/

function rigAuthGenerateQR pAccount
  local tQueryResult, tUser, tIdentityCol, tKey, tIssuer
  local tAlgo, tDigits, tPeriod, tECC, tSize, tMask
  local tImgData, tQRcode, tQRa

  if sAuthConfigA["otpEnabled"] <> TRUE then
    rigLogMessage "error", "Auth OTP: OTP helper not loaded!"
    put "" into tQRa["qr"]
    put "" into tQRa["key"]

    return tQRa
  end if

  # GET USER ACCOUNT (NAME OR EMAIL)
  if pAccount is empty then
    put rigAuthUser() into tQueryResult
    if (tQueryResult <> FALSE) and (tQueryResult is an array) then
      put rigDbRow() into tUser

    # GET THE DATABASE FIELD NAME USED TO LOGIN WITH
    put rigAuthFetchConfigItem("identityColumn") into tIdentityCol

    put tUser[tIdentityCol] into pAccount

    else
      rigLogMessage "error", "Auth OTP: User not logged in!"
      put "" into tQRa["qr"]
      put "" into tQRa["key"]

      return tQRa
    end if -- if (tQueryResult <> FALSE) and (tQueryResult is an array)
  end if -- if pAccount is empty

  # GENERATE USER KEY
  _rigAuthGenerateOTPuserKey tUser["id"]
  put the result into tKey

  -- put "NV4VGZLDOJSXIU3UOJUW4ZY" into tKey --------------------- test
  put sAuthConfigA["otpIssuer"] into tIssuer
  put sAuthConfigA["otpAlgo"] into tAlgo
  put sAuthConfigA["otpDigits"] into tDigits
  put sAuthConfigA["otpPeriod"] into tPeriod
  put sAuthConfigA["otpQRecc"] into tECC
  put sAuthConfigA["otpQRsize"] into tSize
  put sAuthConfigA["otpQRmask"] into tMask

  put rigOTPqrCode(tKey, pAccount, tIssuer, tAlgo, tDigits, tPeriod, tECC, tSize, tMask) into tImgData

  put "<img src='data:image/png;base64," & tImgData & "' />" into tQRcode

  put tQRcode into tQRa["qr"]
  put tKey into tQRa["key"]

  return tQRa
end rigAuthGenerateQR





/*----------------------------------------------------------------------
--| COMMAND _rigAuthGenerateOTPuserKey
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2019-06-19
--| Last Mod: 2019-06-24
--| Requires: rigDbGet(), _rigAuthEncryptPassword(), rigDbInsert(),
--|            rigDbRow(), _rigAuthDecryptPassword, rigOTPgenerateUserKey
--|
--| Summary: Generate random user key used to setup OTP.
--|
--| Format:  _rigAuthGenerateOTPuserKey param1
--|
--| Parameters: integer <pUserID>
--|
--| Return: string
----------------------------------------------------------------------*/

private command _rigAuthGenerateOTPuserKey pUserID
  local tQuery, tSecret, tEncryptedOTPsecret, tTableData, tRow, tBase32Secret

  # CHECK IF THERE IS AN ENTRY ALREADY
  rigDbWhere "userId", pUserID
  put rigDbGet(sAuthConfigA["tables"]["otp"]) into tQuery

  if tQuery["numrows"] = 0 then
    put randomBytes(16) into tSecret
    put _rigAuthEncryptPassword(tSecret) into tEncryptedOTPsecret

    # STORE ENCRYPTED SECRET IN DB
    put pUserID into tTableData["userId"]
    put tEncryptedOTPsecret into tTableData["key"]
    get rigDbInsert(sAuthConfigA["tables"]["otp"], tTableData)

  else
    # USE EXISTING SECRET AND DECRYPT IT
    put rigDbRow() into tRow
    put _rigAuthDecryptPassword(tRow["key"]) into tSecret
  end if

  # RETURN DECRYPTED BASE 32 ENCODED SECRET
  rigOTPgenerateUserKey tSecret
  put the result into tBase32Secret

  return tBase32Secret
end _rigAuthGenerateOTPuserKey






/*----------------------------------------------------------------------
--| FUNCTION rigAuthOTPkeysMatch
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2019-06-19
--| Last Mod: 2019-06-26
--| Requires: _rigAuthCurrentUserID(), rigDbWhere, rigDbGet(), rigDbRow(),
--|           _rigAuthDecryptPassword(), rigAuthFetchConfigItem(), rigOTPcompareKeys,
--|            rigSetSessUserdata, rigMasterNow(), rigDbUpdate(), rigAuthSetMessage
--|
--| Summary: Compare supplied authentication code with generated code.
--|
--| Format:  rigAuthOTPkeysMatch(param1)
--|
--| Parameters: integer <pChallenge>
--|
--| Return: boolean
----------------------------------------------------------------------*/

function rigAuthOTPkeysMatch pChallenge
  local tQueryResult, tUserID, tQuery, tRow, tKey, tRegEx, tMatchStart
  local tAlgo, tAlgoLength, tCryptoType, tCryptoNumBits, tMatchEnd
  local tTokenLength, tTimeStep, tTimeWindow, tMatch, tTableData

  if sAuthConfigA["otpEnabled"] <> TRUE then
    rigLogMessage "error", "Auth OTP: OTP helper not loaded!"

    return FALSE
  end if

  replace " " with empty in pChallenge

  # GET USER ID
  put _rigAuthCurrentUserID() into tUserID
  #

  # GET DECRYPTED STORED KEY
  rigDbWhere "userId", tUserID
  put rigDbGet(sAuthConfigA["tables"]["otp"]) into tQuery

  if tQuery["numrows"] > 0 then
    put rigDbRow() into tRow
    put _rigAuthDecryptPassword(tRow["key"]) into tKey
  end if
  #

  put rigAuthFetchConfigItem("otpDigits") into tTokenLength
  put rigAuthFetchConfigItem("otpAlgo") into tAlgo
  put the number of chars of tAlgo into tAlgoLength

  if tAlgoLength < 7 then
    put char 1 to 3 of tAlgo into tCryptoType
    put char 4 to tAlgoLength of tAlgo into tCryptoNumBits
  else
    # SHA3
    put char 1 to 4 of tAlgo into tCryptoType
    put char 4 to tAlgoLength of tAlgo into tCryptoNumBits
  end if

  put rigAuthFetchConfigItem("otpPeriod") into tTimeStep
  put rigAuthFetchConfigItem("otpTimeWindow") into tTimeWindow

  rigOTPcompareKeys pChallenge, tKey, tTokenLength, tCryptoType, tCryptoNumBits, tTimeStep, tTimeWindow

  put the result into tMatch

  if tMatch is true then
    rigSetSessUserdata "otpCheck", "success"

    # INSERT TIME ON TWO-FACTOR AUTHENTICATION ACTIVATION
    if (tRow["time"] is NULL) or (tRow["time"] is empty) then
      put rigMasterNow() into tTableData["time"]
      rigDbWhere "userId", tUserID
      get rigDbUpdate(sAuthConfigA["tables"]["otp"], tTableData)
    end if

  else
    rigAuthSetMessage "Wrong token!"
  end if -- if tMatch is true

  return tMatch
end rigAuthOTPkeysMatch






/*----------------------------------------------------------------------
--| FUNCTION rigAuthUserHasOTP
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2019-06-20
--| Last Mod: 2019-06-27
--| Requires: rigDbTableExists(), rigLogMessage, _rigAuthCurrentUserID(), rigDbWhere,
--|            rigDbGet(), rigDbRow()
--|
--| Summary: Check if user has set up OTP authentication.
--|
--| Format:  rigAuthUserHasOTP([param1])
--|
--| Parameters: integer <pUserID> (otional)
--|
--| Return: mixed (boolean or "pendingOTPsetup")
----------------------------------------------------------------------*/

function rigAuthUserHasOTP pUserID
  local tQueryResult, tUser, tUserID, tQuery, tRow

  # CHECK IF THERE IS A OTP TABLE
  if rigDbTableExists(sAuthConfigA["tables"]["otp"]) is FALSE then
    rigLogMessage "error", "Auth OTP: OTP table missing!"
    return False
  end if

  # GET USER ID
  if (pUserID is empty) or (pUserID is not an integer) then
    put _rigAuthCurrentUserID() into tUserID

    if tUserID is FALSE then
      return FALSE
    end if

  else
    put pUserID into tUserID
  end if -- if (pUserID is empty) or (pUserID is not an integer)

  if tUserID <> empty then
    # IS THERE AN ENTRY IN THE OTP TABLE
    rigDbWhere "userId", tUserID
    put rigDbGet(sAuthConfigA["tables"]["otp"]) into tQuery

    if tQuery["numrows"] > 0 then
      put rigDbRow() into tRow

      # CHECK IF THE OTP SETUP IS PENDING
      if (tRow["time"] is NULL) or (tRow["time"] is empty) then
        return "pendingOTPsetup"
      else
        return TRUE
      end if

    end if -- if tQuery["numrows"] > 0
  end if -- if tUserID <> empty

  return False
end rigAuthUserHasOTP







/*----------------------------------------------------------------------
--| FUNCTION rigAuthClearOTP
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2019-06-20
--| Last Mod: 2019-06-24
--| Requires: rigAuthLoggedIn(), _rigAuthCurrentUserID(), rigAuthUserHasOTP(),
--|            rigDbWhere, rigDbDelete()
--|
--| Summary: Delete user's OTP database entry.
--|
--| Format:  rigAuthClearOTP([param1])
--|
--| Parameters: integer <pUserID> optional
--|
--| Return: boolean
----------------------------------------------------------------------*/

function rigAuthClearOTP pUserID
  local tUserID

  if rigAuthLoggedIn() is TRUE then
    # GET USER ID
    if (pUserID is empty) or (pUserID is not an integer) then
      put _rigAuthCurrentUserID() into tUserID

      if tUserID is FALSE then
        return FALSE
      end if

    else
      put pUserID into tUserID
    end if -- if (pUserID is empty) or (pUserID is not an integer)

    # CHECK IF USER HAS SETUP OTP AUTHENTICATION
    if rigAuthUserHasOTP(pUserID) is TRUE then
      rigDbWhere "userId", tUserID
      get rigDbDelete(sAuthConfigA["tables"]["otp"])

      return TRUE
    end if
  end if -- if rigAuthLoggedIn() is TRUE

  return FALSE
end rigAuthClearOTP







/*----------------------------------------------------------------------
--| FUNCTION _rigAuthCurrentUserID
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-06-20
--| Last Mod: 2019-06-20
--| Requires: rigAuthUser(), rigDbRow()
--|
--| Summary: Get ID of user currently logged in.
--|
--| Format:  _rigAuthCurrentUserID()
--|
--| Parameters: --
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigAuthCurrentUserID
  local tQueryResult, tUser

  put rigAuthUser() into tQueryResult
  if (tQueryResult <> FALSE) and (tQueryResult is an array) then
    put rigDbRow() into tUser
    return tUser["id"]
  end if

  return FALSE
end _rigAuthCurrentUserID







--| END OF Authentication.livecodescript
--| Location:  ./system/libraries/Authentication.livecodescript
----------------------------------------------------------------------