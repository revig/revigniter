script "stackBehavior"

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
# revIgniter Stack Behavior
#
# This behavior is used by custom stacks which do not include configuration and debug code
#
# @package		  revIgniter
# @subpackage	revigniter
# @category		  Behavior
# @author			  rabit@revigniter.com
# @link				  https://revigniter.com/userGuide
##

## ------------------------------------------------------------------------




# LOGGING
command rigLogLoaded
  rigLogMessage "debug", "Stack" && the short name of this stack && "Loaded"
end rigLogLoaded



# HANDLER CURRENTLY NOT USED
command rigRunInitialStackConfig pConfig
  if pConfig is not an array then
    if pConfig is not empty then
      split pConfig using numtochar(1) and numtochar(2)
    end if
  end if

  if pConfig is an array then
    --Do something with pConfig.
  end if
end rigRunInitialStackConfig



--| END OF stackBehavior.livecodescript
--| Location:  ./system/revigniter/stackBehavior.livecodescript
----------------------------------------------------------------------
