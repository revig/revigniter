script "Contentsecuritypolicy"

##
# revIgniter
#
# An application development framework for LiveCode
# modeled on CodeIgniter.
#
# @package		revIgniter
# @author		  rabit@revigniter.com
# @copyright	Copyright (c) 2009 - 2021, Ralf Bitter
# @license		https://revigniter.com/userGuide/license.html
# @link		    https://revigniter.com
##

## ------------------------------------------------------------------------

##
# revIgniter Content Security Policy Library
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Libraries
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/csp.html
##




global gRigA, g_StyleNonce_, g_ScriptNonce_

local sCspA, sCspDirectives, sCspModeItems, sStyleNonce, sScriptNonce, sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2021-11-01
 --| Last Mod: 2021-11-01
 --| Requires: --
 --|
 --| Summary: Run security check.
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

    # LOGGING
    if the environment is "server" then
      rigLogMessage "debug", "Content Security Policy Library Loaded"
    end if

    # SET INITIAL VALUES
    _rigSetDefaultValues
    #

  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack






/*----------------------------------------------------------------------
--| COMMAND _rigSetDefaultValues
--|
--| Author: rabit
--| Version: 1.1
--| Created: 2021-11-02
--| Last Mod: 2021-11-17
--| Requires: --
--|
--| Summary: Set default values for library variables.
--|
--| Format: _rigSetDefaultValues
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetDefaultValues
  put FALSE into sCspA["omit-script-nonce"]                   -- omit automatic creation of script source nonce values for the CSP header
  put FALSE into sCspA["omit-style-nonce"]                    -- omit automatic creation of style source nonce values for the CSP header
  put FALSE into sCspA["report-only"]                         -- flag for report only policy
  put "" into sCspA["allow"]["report-uri"]                    -- the URL where a browser will send reports when a content security policy is violated
  put FALSE into sCspA["allow"]["upgrade-insecure-requests"]  -- rewrite URL schemes, changes HTTP to HTTPS
  put "'self'" into sCspA["allow"]["default-src"]             -- default policy for fetching resources
  put "'self'" into sCspA["allow"]["script-src"]              -- defines valid sources of JavaScript
  put "'self'" into sCspA["allow"]["style-src"]               -- defines valid sources of stylesheets or CSS
  put "'self'" into sCspA["allow"]["img-src"]                 -- defines the origins from which images can be loaded
  put "'self'" into sCspA["allow"]["base-uri"]                -- restricts the URLs that can appear in a page's <base> element
  put "'self'" into sCspA["allow"]["child-src"]               -- lists the URLs for workers and embedded frame contents
  put "'self'" into sCspA["allow"]["connect-src"]             -- limits the origins that you can connect to (via XHR, WebSockets, and EventSource)
  put "" into sCspA["allow"]["font-src"]                      -- specifies the origins that can serve web fonts
  put "'self'" into sCspA["allow"]["form-action"]             -- lists valid endpoints for submission from <form> tags
  put "" into sCspA["allow"]["frame-ancestors"]               -- specifies the sources that can embed the current page
  put "" into sCspA["allow"]["media-src"]                     -- restricts the origins allowed to deliver video and audio
  put "'self'" into sCspA["allow"]["object-src"]              -- allows control over Flash and other plugins
  put "" into sCspA["allow"]["manifest-src"]                  -- restricts the URLs that application manifests can be loaded
  put "" into sCspA["allow"]["plugin-types"]                  -- defines valid MIME types for plugins invoked via <object> and <embed>
  put "" into sCspA["allow"]["sandbox"]                       -- enables a sandbox for the requested resource similar to the iframe sandbox attribute

  put "report-uri,upgrade-insecure-requests,default-src,script-src,style-src,img-src,base-uri,child-src,connect-src,font-src,form-action,frame-ancestors,media-src,object-src,manifest-src,plugin-types,sandbox" into sCspDirectives

  put "allow,report" into sCspModeItems
end _rigSetDefaultValues





/*----------------------------------------------------------------------
--| COMMAND rigRunInitialContentsecuritypolicyConfig
--|
--| Author: rabit
--| Version: 1.1
--| Created: 2021-11-02
--| Last Mod: 2021-11-17
--| Requires: _rigInitializeCSP
--|
--| Summary: Run initial configuration procedures. Don't remove, even if it does nothing.
--|
--| Format: rigRunInitialContentsecuritypolicyConfig param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialContentsecuritypolicyConfig pConfig
  local tConfig

	put pConfig into tConfig

	if tConfig is not an array then
		if tConfig is not empty then
			split tConfig using numToCodepoint(1) and numToCodepoint(2)
		end if
	end if

	if tConfig is an array then
    if ("report-only" is among the keys of tConfig) and (tConfig["report-only"] is a boolean) then
      put tConfig["report-only"] into sCspA["report-only"]
    end if

    if ("omit-script-nonce" is among the keys of tConfig) and (tConfig["omit-script-nonce"] is a boolean) then
      put tConfig["omit-script-nonce"] into sCspA["omit-script-nonce"]
    end if

    if ("omit-style-nonce" is among the keys of tConfig) and (tConfig["omit-style-nonce"] is a boolean) then
      put tConfig["omit-style-nonce"] into sCspA["omit-style-nonce"]
    end if

		_rigInitializeCSP tConfig
	end if
end rigRunInitialContentsecuritypolicyConfig




/*----------------------------------------------------------------------
--| COMMAND _rigInitializeCSP
--|
--| Author: rabit
--| Version: 1.0
--| Created: 2021-11-02
--| Last Mod: 2021-11-02
--| Requires: _rigSetInitialCSPvalue
--|
--| Summary: Initialize preferences.
--|
--| Format: _rigInitializeCSP param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigInitializeCSP pConfig
  local tDirective, tVal

  if pConfig is an array then
    if pConfig["report-only"] is TRUE then
      put TRUE into sCspA["report-only"]
    end if

    repeat for each key tDirective in pConfig

      put pConfig[tDirective] into tVal

      _rigSetInitialCSPvalue tDirective, tVal

    end repeat
  end if
end _rigInitializeCSP




/*----------------------------------------------------------------------
--| COMMAND _rigSetInitialCSPvalue
--|
--| Author: rabit
--| Version: 1.0
--| Created: 2021-11-02
--| Last Mod: 2021-11-02
--| Requires: rigCspSet
--|
--| Summary: Set initial values.
--|
--| Format: _rigSetInitialUploadValue param1, param2
--|
--| Parameters: string <pDirective>, mixed <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetInitialCSPvalue pDirective pValue
  local tMode

  if sCspA["report-only"] is TRUE then
    put "report" into tMode
  else
    put "allow" into tMode
  end if

  rigCspSet pDirective, pValue, tMode
end _rigSetInitialCSPvalue




/*----------------------------------------------------------------------
--| FUNCTION _rigCSPheader
--|
--| Author: rabit
--| Version: 1.1
--| Created: 2021-10-30
--| Last Mod: 2021-11-17
--| Requires: --
--|
--| Summary: Generate the content security policy headers according to the options set
--|          in sCspA["allow"] and sCspA["report"]
--|
--| Format: _rigCSPheader(param1[, param2])
--|
--| Parameters: string <pMode> "allow" or "report", string <pOutput> output data (optional)
--|
--| Return: string
----------------------------------------------------------------------*/

function _rigCSPheader pMode pOutput
  local tNonce, tAddNonce, tCspDirective, tCSPheader

  if pMode is among the items of sCspModeItems then
   if sCspA["report"] is empty and pMode is "report" then
     put FALSE into tAddNonce
   else
     put TRUE into tAddNonce
   end if

    # CHECK IF WE NEED CSP NONCES
    if tAddNonce is TRUE then
      if (sStyleNonce <> TRUE) and (sCspA["omit-style-nonce"] is FALSE) then
        put matchText(pOutput,"{{g_StyleNonce_}}") into sStyleNonce
      end if
      if (sScriptNonce <> TRUE) and (sCspA["omit-script-nonce"] is FALSE) then
        put matchText(pOutput,"{{g_ScriptNonce_}}") into sScriptNonce
      end if

      if sStyleNonce is TRUE then
        put rigNonce() into tNonce
        put "nonce=" & quote & tNonce & quote into g_StyleNonce_
        rigCspAdd "style-src", "'nonce-" & tNonce & "'", pMode
      end if

      if sScriptNonce is TRUE then
        if tNonce is empty then
          put rigNonce() into tNonce
        end if

        put "nonce=" & quote & tNonce & quote into g_ScriptNonce_
        rigCspAdd "script-src", "'nonce-" & tNonce & "'", pMode
      end if
    end if -- if tAddNonce is TRUE
    #

    repeat for each key tCspDirective in sCspA[pMode]
      if (tCspDirective <> "upgrade-insecure-requests") and (sCspA[pMode][tCspDirective] <> empty) then
        put tCspDirective && sCspA[pMode][tCspDirective] & "; " after tCSPheader
      end if
    end repeat

    if sCspA[pMode]["upgrade-insecure-requests"] is TRUE then
      put "upgrade-insecure-requests" & "; " after tCSPheader
    end if

    delete byte -1 of tCSPheader

    if pMode is "report" then
      put "Content-Security-Policy-Report-Only:" && tCSPheader into tCSPheader
    else
      put "Content-Security-Policy:" && tCSPheader into tCSPheader
    end if

    return tCSPheader
  end if -- if pMode is among the items of sCspModeItems

  return empty
end _rigCSPheader




/*----------------------------------------------------------------------
--| FUNCTION rigCspGet
--|
--| Author: rabit
--| Version: 1.0
--| Created: 2021-11-01
--| Last Mod: 2021-11-01
--| Requires: --
--|
--| Summary: Get options of content security policy directives.
--|
--| Format: rigCspGet(param1[, param2])
--|
--| Parameters: string <pDirective>, string <pMode> "allow" or
--|             "report", default is "allow" (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigCspGet pDirective pMode
  local tMode

  if pMode is among the items of sCspModeItems then
    put pMode into tMode
  else
    put "allow" into tMode
  end if

  if pDirective is among the items of sCspDirectives then
    return sCspA[tMode][pDirective]
  end if

  return empty
end rigCspGet




/*----------------------------------------------------------------------
--| COMMAND rigCspSet
--|
--| Author: rabit
--| Version: 1.0
--| Created: 2021-11-01
--| Last Mod: 2021-11-01
--| Requires: --
--|
--| Summary: Setter for content security policy directives.
--|
--| Format: rigCspSet param1, param2[, param3]
--|
--| Parameters: mixed <pDirective>, string <pValue>,
--|             string <pMode> "allow" or "report", default is "allow" (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigCspSet pDirective pValue pMode
  local tMode, tKey, tVal

  if pMode is among the items of sCspModeItems then
    put pMode into tMode
  else
    put "allow" into tMode
  end if

  if pDirective is an array then
    if pDirective["report-only"] is TRUE then
      put "report" into tMode
      put TRUE into sCspA["report-only"]
    end if

    repeat for each key tKey in pDirective
      if tKey is among the items of sCspDirectives then
        put pDirective[tKey] into tVal
        put tVal into sCspA[tMode][tKey]
      end if
    end repeat

  else -- if pDirective is an array
    if pDirective is among the items of sCspDirectives then
      put pValue into sCspA[tMode][pDirective]

    else if pDirective is "report-only" then
      put pValue into sCspA[pDirective]
    end if
  end if -- if pDirective is an array
end rigCspSet




/*----------------------------------------------------------------------
--| COMMAND rigCspAdd
--|
--| Author: rabit
--| Version: 1.0
--| Created: 2021-11-01
--| Last Mod: 2021-11-01
--| Requires: --
--|
--| Summary: Add options to content security policy directives.
--|
--| Format: rigCspAdd param1, param2[, param3]
--|
--| Parameters: mixed <pDirective>, string <pValue>,
--|             string <pMode> "allow" or "report", default is "allow" (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigCspAdd pDirective pValue pMode
  local tMode, tKey, tVal, tOption

  if pMode is among the items of sCspModeItems then
    put pMode into tMode
  else
    put "allow" into tMode
  end if

  if pDirective is an array then
    if pDirective["report-only"] is TRUE then
      put "report" into tMode
      put TRUE into sCspA["report-only"]
    end if

    repeat for each key tKey in pDirective
      set the itemDel to comma

      if tKey is among the items of sCspDirectives then
        put pDirective[tKey] into tVal

        if sCspA[tMode][tKey] is empty then
          put tVal into sCspA[tMode][tKey]

        else
          set the itemDel to space

          repeat with tCounter = 1 to the number of words of tVal
            put word tCounter of tVal into tOption

            # DON'T ADD OPTION ALREADY USED
            if tOption is not among the items of sCspA[tMode][tKey] then
              put space & tOption after sCspA[tMode][tKey]
            end if
          end repeat

        end if -- if sCspA[tMode][tKey] is empty
      end if -- if tKey is among the items of sCspDirectives
    end repeat

  else -- if pDirective is an array

    if pDirective is among the items of sCspDirectives then
      if sCspA[tMode][pDirective] is empty then
        put pValue into sCspA[tMode][pDirective]

      else
        set the itemDel to space
        repeat with tCounter = 1 to the number of words of pValue
          put word tCounter of pValue into tOption

          # DON'T ADD OPTION ALREADY USED
          if tOption is not among the items of sCspA[tMode][pDirective] then
            put space & tOption after sCspA[tMode][pDirective]
          end if
        end repeat

      end if -- if sCspA[tMode][pDirective] is empty
    end if -- if pDirective is among the items of sCspDirectives
  end if -- if pDirective is an array
end rigCspAdd





--| END OF Contentsecuritypolicy.livecodescript
--| Location:  ./system/libraries/Contentsecuritypolicy.livecodescript
----------------------------------------------------------------------
