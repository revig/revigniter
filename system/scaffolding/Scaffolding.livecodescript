script "Scaffolding"

##
# RevIgniter
#
# A web development framework for LiveCode
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
# Profiler Library
#
# Provides the scaffolding framework.
#
# @package		RevIgniter
# @subpackage	Libraries
# @category	  Scaffolding
# @author		  rabit@revigniter.com
# @link		    https://revigniter.com/userGuide/libraries/uri.html
##




global gRigA, gControllerHandlers, gData

local sScaffCurrentTable, sScaffBaseURL, sScaffBaseURI, sScaffLang




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-11
 --| Last Mod: --
 --| Requires: --
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
    # PUT SCAFFOLDING HANDLER NAMES INTO THE GLOBAL gControllerHandlers AS A COMMA SEPARATED LIST
    put "rigScaffolding,rigScaffAdd,rigScaffInsert,rigScaffEdit,rigScaffUpdate,rigScaffView,rigScaffDelete,rigScaffDoDelete" into gControllerHandlers

  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack






/*----------------------------------------------------------------------
--| COMMAND rigScaffolding
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2010-01-25
--| Last Mod: 2020-04-27
--| Requires: rigLoaderLoadLibrary, rigDbCacheOff(), _rigSetViewPath, rigSiteURL(), rigFetchSegment(),
--|           rigSystemURL(), rigLoadScaffoldingLanguage(), rigLoadHelper, rigLogMessage
--|
--| Summary: Run initial procedures.
--|
--| Format: rigScaffolding param1
--|
--| Parameters: string <pDBtable>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigScaffolding pDBtable
  local tSiteURL, tIndexPage, tHelpers

	get rigLoadDatabase("", FALSE, TRUE)

	rigLoaderLoadLibrary "Pagination"

	# TURN OFF CACHING
	get rigDbCacheOff()

	# SET THE CURRENT TABLE NAME
	# THIS IS DONE WHEN INITIALIZING SCAFFOLDING:
	# rigLoadScaffolding "tableName"
	put pDBtable into sScaffCurrentTable

	# SET THE PATH TO THE "VIEW" FILES
	# WE'LL MANUALLY OVERRIDE THE "VIEW" PATH SO THAT
	# THE rigLoadView FUNCTION KNOWS WHERE TO LOOK.
	_rigSetViewPath gRigA["BASEPATH"] & "scaffolding/views/"

	# CHECK IF mod_rewrite IS USED TO REMOVE THE INDEX PAGE
	put rigSiteURL() into tSiteURL
	put FALSE into tIndexPage

	set the itemDel to "."
	if ("." & item -1 of tSiteURL) is gRigA["EXT"] then
		put TRUE into tIndexPage
	end if

	# SET THE BASE URL
	put rigSiteURL() & rigFetchSegment(1) & rigSlashSegment(2, "both") into sScaffBaseURL
	put rigFetchSegment(1) & rigSlashSegment(2, "leading") into sScaffBaseURI

	# SET A FEW GLOBALS
	if tIndexPage is TRUE then
		set the itemdelimiter to "/"
		put item 1 to -2 of tSiteURL  & "/" into tSiteURL
	end if
	put tSiteURL & rigSystemURL() & "scaffolding/images/" into gData["imageURL"]
	put sScaffBaseURI into gData["baseURI"]
	put sScaffBaseURL into gData["baseURL"]
	put sScaffCurrentTable into gData["title"]
	put rigVersion() into gData["riVersion"]
	put rigVersion("state") into gData["state"]

	# LOAD THE LANGUAGE FILE AND CREATE VARIABLES
	put rigLoadScaffoldingLanguage("scaffolding", "", TRUE) into sScaffLang
	put sScaffLang into gData["lang"]

	# LOAD THE HELPER FILES WE PLAN TO USE
	put "url,form" into tHelpers
	rigLoadHelper tHelpers

	# LOGGING
	rigLogMessage "debug", "rigScaffolding Library Initialized"
end rigScaffolding









/*----------------------------------------------------------------------
--| COMMAND rigScaffAdd
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-01-10
--| Last Mod: 27-01-10
--| Requires: rigLangLangLine(), rigDbFieldData(), rigAnchor(), rigLoadView()
--|
--| Summary: "Add" page, shows a form representing the currently selected DB
--|             so that data can be inserted. Show the HTML "add" page.
--|
--| Format:  rigScaffAdd
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigScaffAdd
  local tViewAnchorA, tViewLangLine, tAddAnchorA, tAddLangLine

	# SET GLOBALS
	if rigLangLangLine("scaff_add") is empty then
		put "Add Data" into gData["pageTitle"]
	else
		put rigLangLangLine("scaff_add") into gData["pageTitle"]
	end if
	put rigDbFieldData(sScaffCurrentTable) into gData["fields"]
	put sScaffBaseURI & "/rigScaffInsert" into gData["action"]

	# BUILD VIEW ANCHOR
	put sScaffBaseURI into tViewAnchorA[1]
	put "rigScaffView" into tViewAnchorA[2]
	put "&lt; " & rigLangLangLine("scaff_view_all") into tViewLangLine
	put rigAnchor(tViewAnchorA, tViewLangLine) into gData["viewAnchor"]

	# BUILD ADD ANCHOR
	put sScaffBaseURI into tAddAnchorA[1]
	put "rigScaffAdd" into tAddAnchorA[2]
	put rigLangLangLine("scaff_create_record") into tAddLangLine
	put rigAnchor(tAddAnchorA, tAddLangLine) into gData["addAnchor"]

	# LOAD VIEW FILES
	get rigLoadView("header")
	get rigLoadView("add")
	get rigLoadView("footer")
end rigScaffAdd








/*----------------------------------------------------------------------
--| COMMAND rigScaffInsert
--|
--| Author: rabit
--| Version:  1.1
--| Created: 27-01-10
--| Last Mod: 17-07-11
--| Requires: rigDbInsert(), rigRedirect
--|
--| Summary: Insert the data. Redirects to the view page.
--|
--| Format:  rigScaffInsert
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigScaffInsert
	if rigDbInsert(sScaffCurrentTable, $_POST) is FALSE then
		rigScaffAdd
	else
		rigRedirect sScaffBaseURI & "/rigScaffView/"
	end if
end rigScaffInsert










/*----------------------------------------------------------------------
--| COMMAND rigScaffView
--|
--| Author: rabit
--| Version:  1.3
--| Created: 26-01-10
--| Last Mod: 04-08-12
--| Requires: rigDbCountAllResults(), rigLoadView(), rigFetchSegment(), rigDbGet(), rigInitializePagination
--|                   rigLangLangLine(), rigCreatePaginationLinks()
--|
--| Summary: "View" page, shows a table containing the data in the currently
--|             selected DB. Shows the HTML "view" page.
--|
--| Format:  rigScaffView
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigScaffView
  local tTotalRows, tAddAnchorA, tAddLangLine, tPerPage, tOffset, tQuery
  local tFields, tPrimary, tConfigA, tViewAnchorA, tViewLangLine
  local tEditLangLine, tDeleteLangLine, tCounter, tKey, tRowA, tField

	# FETCH THE TOTAL NUMBER OF DB ROWS
	put rigDbCountAllResults(sScaffCurrentTable) into tTotalRows

	if tTotalRows < 1 then
		# NO DATA EXISTS FOR THIS TABLE YET
		put rigLangLangLine("scaff_no_data") into gData["noDataMessage"]
		if gData["noDataMessage"] is empty  then
			put "No data exists for this table yet." into gData["noDataMessage"]
		end if

		# BUILD ADD ANCHOR
		put sScaffBaseURI into tAddAnchorA[1]
		put "rigScaffAdd" into tAddAnchorA[2]
		put rigLangLangLine("scaff_create_record") into tAddLangLine
		put rigAnchor(tAddAnchorA, tAddLangLine) into gData["addAnchor"]

		get rigLoadView("header")
		get rigLoadView("nodata")
		get rigLoadView("footer")
		exit rigScaffView
	end if

	# SET THE QUERY LIMIT/OFFSET
	put rigFetchConfigItem("scaffNumRecords") into tPerPage
	if tPerPage is not a integer then
		put 5 into tPerPage
	end if
	put rigFetchSegment(4, 0) into tOffset

	# RUN THE QUERY
	put rigDbGet(sScaffCurrentTable, tPerPage, tOffset) into tQuery

	# NOW LET'S GET THE FIELD NAMES
	put tQuery["fieldnames"] into tFields

	# WE ASSUME THAT THE COLUMN IN THE FIRST POSITION IS THE PRIMARY FIELD
	put tFields[1] into tPrimary

	# PAGINATION!
	put sScaffBaseURL & "/rigScaffView" into tConfigA["baseUrl"]
	put tTotalRows into tConfigA["totalRows"]
	put tPerPage into tConfigA["perPage"]
	put 4 into tConfigA["uriSegment"]
	put "<p>" into tConfigA["fullTagOpen"]
	put "</p>" into tConfigA["fullTagClose"]

	rigInitializePagination tConfigA

	# SET GLOBALS
	if rigLangLangLine("scaff_view") is empty then
		put "View Data" into gData["pageTitle"]
	else
		put rigLangLangLine("scaff_view") into gData["pageTitle"]
	end if
	put tQuery into gData["query"]
	put tFields into gData["fields"]
	put tPrimary into gData["primary"]
	put rigCreatePaginationLinks() into gData["paginate"]

	# BUILD VIEW ANCHOR
	put sScaffBaseURI into tViewAnchorA[1]
	put "rigScaffView" into tViewAnchorA[2]
	put rigLangLangLine("scaff_view_records") into tViewLangLine
	put rigAnchor(tViewAnchorA, tViewLangLine) into gData["viewAnchor"]

	# BUILD ADD ANCHOR
	put sScaffBaseURI into tAddAnchorA[1]
	put "rigScaffAdd" into tAddAnchorA[2]
	put rigLangLangLine("scaff_create_record") into tAddLangLine
	put rigAnchor(tAddAnchorA, tAddLangLine) into gData["addAnchor"]

	# BUILD EDIT ANCHOR
	put sScaffBaseURI into gData["editAnchor"][1]
	put "rigScaffEdit" into gData["editAnchor"][2]

	# BUILD DELET ANCHOR
	put sScaffBaseURI into gData["deleteAnchor"][1]
	put "rigScaffDelete" into gData["deleteAnchor"][2]

	put tQuery["resultarray"] into gData["queryResult"]

	# BUILD TABLE CONTENT
	put rigLangLangLine("scaff_edit") into tEditLangLine
	put rigLangLangLine("scaff_delete") into tDeleteLangLine

	put 0 into tCounter

	repeat for each key tKey in gData["queryResult"]
		add 1 to tCounter

		put gData["queryResult"][tCounter] into tRowA
		put tRowA[1] into gData["editAnchor"][3]
		put tRowA[1] into gData["deleteAnchor"][3]
		put "<tr>" & return & "<td>&nbsp;" & rigAnchor(gData["editAnchor"], tEditLangLine) & "&nbsp;</td>" & return after gData["tableContent"]
		put "<td>" & rigAnchor(gData["deleteAnchor"], tDeleteLangLine) & "</td>" & return after gData["tableContent"]

		put 0 into tField

		repeat for each key tKey in gData["fields"]
			add 1 to tField
			put "<td>" & rigFormPrep(tRowA[tField]) & "</td>" & return after gData["tableContent"]
		end repeat

		put "</tr>" & return after gData["tableContent"]
	end repeat

	# LOAD VIEW FILES
	get rigLoadView("header")
	get rigLoadView("view")
	get rigLoadView("footer")
end rigScaffView









/*----------------------------------------------------------------------
--| COMMAND rigScaffEdit
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-01-10
--| Last Mod: 27-01-10
--| Requires: rigFetchSegment(), rigPrimary(), rigDbGetWhere(), rigLangLangLine(), rigDbFieldData(), rigAnchor(), rigLoadView()
--|
--| Summary: "Edit" page, shows a form representing the currently selected DB
--|             so that data can be edited. Show the HTML "add" page.
--|
--| Format:  rigScaffEdit
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigScaffEdit
  local tID, tPrimary, tArray, tQuery, tViewAnchorA, tViewLangLine
  local tAddAnchorA, tAddLangLine

	put rigFetchSegment(4) into tID
	if tID is FALSE then
		rigScaffView
		exit rigScaffEdit
	end if

	# FETCH THE PRIMARY FIELD NAME
	put rigPrimary(sScaffCurrentTable) into tPrimary

	# RUN THE QUERY
	put tID into tArray[tPrimary]
	put rigDbGetWhere(sScaffCurrentTable, tArray) into tQuery

	# SET GLOBALS
	if rigLangLangLine("scaff_edit") is empty then
		put "Edit Data" into gData["pageTitle"]
	else
		put rigLangLangLine("scaff_edit") into gData["pageTitle"]
	end if
	put rigDbFieldData(sScaffCurrentTable) into gData["fields"]
	put tQuery["resultarray"][1] into gData["queryResult"]
	put sScaffBaseURI & "/rigScaffUpdate/" & tID into gData["action"]

	# BUILD VIEW ANCHOR
	put sScaffBaseURI into tViewAnchorA[1]
	put "rigScaffView" into tViewAnchorA[2]
	put "&lt; " & rigLangLangLine("scaff_view_all") into tViewLangLine
	put rigAnchor(tViewAnchorA, tViewLangLine) into gData["viewAnchor"]

	# BUILD ADD ANCHOR
	put sScaffBaseURI into tAddAnchorA[1]
	put "rigScaffAdd" into tAddAnchorA[2]
	put rigLangLangLine("scaff_create_record") into tAddLangLine
	put rigAnchor(tAddAnchorA, tAddLangLine) into gData["addAnchor"]

	# LOAD VIEW FILES
	get rigLoadView("header")
	get rigLoadView("edit")
	get rigLoadView("footer")
end rigScaffEdit










----------------------------------------------------------------------
--| COMMAND rigScaffUpdate
--|
--| Author: rabit
--| Version:  1.1
--| Created: 27-01-10
--| Last Mod: 17-07-11
--| Requires: rigPrimary(), rigFetchSegment(), rigDbUpdate(), rigRedirect
--|
--| Summary: Update, redirects to the view page.
--|
--| Format:  rigScaffUpdate
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------

command rigScaffUpdate
  local tPrimary, tID, tArray

	# FETCH THE PRIMARY KEY
	put rigPrimary(sScaffCurrentTable) into tPrimary

	put rigFetchSegment(4) into tID
	put tID into tArray[tPrimary]

	# NOW DO THE QUERY
	get rigDbUpdate(sScaffCurrentTable, $_POST, tArray)

	rigRedirect sScaffBaseURI & "/rigScaffView/"
end rigScaffUpdate










/*----------------------------------------------------------------------
--| COMMAND rigScaffDelete
--|
--| Author: rabit
--| Version:  1.1
--| Created: 27-01-10
--| Last Mod: 03-08-12
--| Requires: rigFetchSegment(), rigLangLangLine(), rigAnchor(), rigLoadView()
--|
--| Summary: Delete confirmation, show the HTML "delete confirm" page.
--|
--| Format:  rigScaffDelete
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigScaffDelete
  local tID, tPrimary, tMessage, tAnswerNo, tNoArray, tAnswerYes
  local tYesArray, tViewAnchorA, tViewLangLine, tAddAnchorA
  local tAddLangLine

	put rigFetchSegment(4) into tID

	# FETCH THE PRIMARY KEY
	put rigPrimary(sScaffCurrentTable) into tPrimary

	if rigLangLangLine("scaff_del_confirm") is empty then
		put "Are you sure you want to delete the following row:" && tPrimary && tID into tMessage
	else
		put rigLangLangLine("scaff_del_confirm") && tPrimary && tID into tMessage
	end if

	# SET GLOBALS
	if rigLangLangLine("scaff_delete") is empty then
		put "Edit Data" into gData["pageTitle"]
	else
		put rigLangLangLine("scaff_delete") into gData["pageTitle"]
	end if

	put tMessage into gData["message"]

	# BUILD NO ANCHOR
	if rigLangLangLine("scaff_no") is empty then
		put "No" into tAnswerNo
	else
		put rigLangLangLine("scaff_no") into tAnswerNo
	end if
	put sScaffBaseURI into tNoArray[1]
	put "rigScaffView" into tNoArray[2]
	put rigAnchor(tNoArray, tAnswerNo) into gData["no"]

	# BUILD YES ANCHOR
	if rigLangLangLine("scaff_yes") is empty then
		put "Yes" into tAnswerYes
	else
		put rigLangLangLine("scaff_yes") into tAnswerYes
	end if
	put sScaffBaseURI into tYesArray[1]
	put "rigScaffDoDelete" into tYesArray[2]
	put tID into tYesArray[3]
	put rigAnchor(tYesArray, tAnswerYes) into gData["yes"]

	# BUILD VIEW ANCHOR
	put sScaffBaseURI into tViewAnchorA[1]
	put "rigScaffView" into tViewAnchorA[2]
	put "&lt; " & rigLangLangLine("scaff_view_all") into tViewLangLine
	put rigAnchor(tViewAnchorA, tViewLangLine) into gData["viewAnchor"]

	# BUILD ADD ANCHOR
	put sScaffBaseURI into tAddAnchorA[1]
	put "rigScaffAdd" into tAddAnchorA[2]
	put rigLangLangLine("scaff_create_record") into tAddLangLine
	put rigAnchor(tAddAnchorA, tAddLangLine) into gData["addAnchor"]

	# LOAD VIEW FILES
	get rigLoadView("header")
	get rigLoadView("delete")
	get rigLoadView("footer")
end rigScaffDelete











/*----------------------------------------------------------------------
--| COMMAND rigScaffDoDelete
--|
--| Author: rabit
--| Version:  1.1
--| Created: 27-01-10
--| Last Mod: 02-08-12
--| Requires: rigFetchSegment(), rigPrimary(), rigDbWhere, rigDbDelete(), rigSiteURL()
--|
--| Summary: Delete, redirects to the view page.
--|
--| Format:  rigScaffDoDelete
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigScaffDoDelete
  local tID, tPrimary, tURIarrayA, tSiteURL

	put rigFetchSegment(4) into tID

	# FETCH THE PRIMARY KEY
	put rigPrimary(sScaffCurrentTable) into tPrimary

	# NOW DO THE QUERY
	rigDbWhere tPrimary, tID
	get rigDbDelete(sScaffCurrentTable)

	put sScaffBaseURI into tURIarrayA[1]
	put "rigScaffView" into tURIarrayA[2]
	put rigSiteURL(tURIarrayA) into tSiteURL

	rigRedirect tSiteURL
end rigScaffDoDelete








--| END OF Scaffolding.livecodescript
--| Location:  ./system/scaffolding/Scaffolding.livecodescript
----------------------------------------------------------------------
