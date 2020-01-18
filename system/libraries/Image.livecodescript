script "Image"

##
# revIgniter
#
# An application development framework for LiveCode
# modeled on CodeIgniter.
#
# @package	  revIgniter
# @author		  rabit@revigniter.com
# @copyright	Copyright (c) 2009 - 2020, dimensionB Bitter u. Bitter GmbH
# @license	  https://revigniter.com/userGuide/license.html
# @link		    https://revigniter.com
##

## ------------------------------------------------------------------------

##
# revIgniter Image Manipulation Library
#
#
# @version       1.0.0
# @package	    revIgniter
# @subpackage  Libraries
# @category	    Image
# @author		    rabit@revigniter.com
# @link		      https://revigniter.com/userGuide/libraries/image_lib.html
##

## ------------------------------------------------------------------------




global gRigA

local sImageA, sStackInUse




 /*----------------------------------------------------------------------
 --| COMMAND libraryStack
 --|
 --| Author: rabit
 --| Version:  1.0
 --| Created: 2018-12-21
 --| Last Mod: --
 --| Requires: rigLogMessage
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

      # LOGGING
      if the environment is "server" then
        rigLogMessage "debug", "Image Library Loaded"
      end if
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack





/*----------------------------------------------------------------------
--| COMMAND rigRunInitialimageConfig
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-13
--| Last Mod: 04-11-13
--| Requires: rigImgClear, _rigInitializeImage
--|
--| Summary: Run initial configuration procedures. Don't remove, even if it does nothing!
--| 
--| Format:  rigRunInitialimageConfig param1
--|
--| Parameters: mixed <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigRunInitialimageConfig pConfig
   if pConfig is not an array then
      if pConfig is not empty then
         split pConfig using numToCodepoint(1) and numToCodepoint(2)
      end if
   end if
   
   # SET DEFAULT VALUES
   rigImgClear
   
   if pConfig is an array then
      _rigInitializeImage pConfig
   end if
end rigRunInitialimageConfig





/*----------------------------------------------------------------------
--| COMMAND _rigInitializeImage
--|
--| Author: rabit
--| Version:  1.1
--| Created: 04-11-2013
--| Last Mod: 21-03-2014
--| Requires: _rigSetInitialImageValue, _rigSetImgError, _rigGetImageProperties(),
--|            _rigImageReproportion, _rigExplodeImgName
--|
--| Summary: Initialize preferences.
--| 
--| Format:  _rigInitializeImage param1
--|
--| Parameters: array <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigInitializeImage pConfig
  local tKey, tVal, tFullSourcePath, tFullDestPath, tRegEx, tXP,
  local tFileName, tFileExt, tImgXaxisTemp, tImgYaxisTemp
   
  # CONVERT ARRAY ELEMENTS INTO LIBRARY VARIABLES
  if pConfig is an array then
    repeat for each key tKey in pConfig
      put pConfig[tKey] into tVal
         
      _rigSetInitialImageValue tKey, tVal
         
    end repeat
  end if
   
  # IS THERE A SOURCE IMAGE?
  # IF NOT, THERE'S NO REASON TO CONTINUE
  if sImageA["sourceImage"] is "" then
    _rigSetImgError "imglib_source_image_required"
      
    return FALSE
  end if
   
  put toLower(sImageA["imageLibrary"]) into sImageA["imageLibrary"]
   
  # SET THE FULL SERVER PATH
  if char 1 of sImageA["sourceImage"] is "/" then
    put the defaultFolder & sImageA["sourceImage"] into tFullSourcePath
  else
    put the defaultFolder & "/" & sImageA["sourceImage"] into tFullSourcePath
  end if
   
  set the itemDelimiter to "/"
  put item -1 of tFullSourcePath into sImageA["sourceImage"]
  put item 1 to -2 of tFullSourcePath into sImageA["sourceFolder"]
   
  # SET THE IMAGE PROPERTIES
  if _rigGetImageProperties(sImageA["sourceFolder"] & "/" & sImageA["sourceImage"]) is FALSE then
    return FALSE
  end if
   
  # ASSIGN THE "NEW" IMAGE NAME/PATH
  #
  # IF THE USER HAS SET A "NEW_IMAGE" NAME IT MEANS
  # WE ARE MAKING A COPY OF THE SOURCE IMAGE. IF NOT
  # IT MEANS WE ARE ALTERING THE ORIGINAL.  WE'LL
  # SET THE DESTINATION FILENAME AND PATH ACCORDINGLY.
  if sImageA["newImage"] is empty then
    put sImageA["sourceImage"] into sImageA["destImage"]
    put sImageA["sourceFolder"] into sImageA["destFolder"]
  else
    if "/" is not in sImageA["newImage"] then
      put sImageA["sourceFolder"] into sImageA["destFolder"]
      put sImageA["newImage"] into sImageA["destImage"]
    else
      if char 1 of sImageA["sourceImage"] is "/" then
        put the defaultFolder & sImageA["newImage"] into tFullDestPath
      else
        put the defaultFolder & "/" & sImageA["newImage"] into tFullDestPath
      end if
         	
      # IS THERE A FILE NAME?
      put "(?i)\.(jpg|jpeg|gif|png)" into tRegEx
      get matchText(tFullDestPath, tRegEx)
      if it is FALSE then
        put tFullDestPath & "/" into sImageA["destFolder"]
        put sImageA["sourceImage"] into sImageA["destImage"]
      else
        put item -1 of tFullDestPath into sImageA["destImage"]
        put item 1 to -2 of tFullDestPath into sImageA["destFolder"]
      end if			
         
    end if
  end if
   
  # COMPILE THE FINALIZED FILENAMES/PATHS
  #
  # WE'LL CREATE TWO MASTER STRINGS CONTAINING THE
  # FULL SERVER PATH TO THE SOURCE IMAGE AND THE
  # FULL SERVER PATH TO THE DESTINATION IMAGE.
  # WE'LL ALSO SPLIT THE DESTINATION IMAGE NAME
  # SO WE CAN INSERT THE THUMBNAIL MARKER IF NEEDED.
  if (sImageA["createThumb"] is FALSE) or (sImageA["thumbMarker"] is empty) then
    put empty into sImageA["thumbMarker"]
  end if
   
  # SET OUTPUT FILE EXTENSION / MIME TYPE
  # CHECK IF EXPORT FORMAT IS SET BY USER
  put _rigExplodeImgName(sImageA["destImage"]) into tXP
  put tXP["name"] into tFileName
  put tXP["ext"] into tFileExt
   
  if sImageA["exportFormat"] <> empty then
    if sImageA["exportFormat"] is "JPG" then put "JPEG" into sImageA["exportFormat"]
    if sImageA["exportFormat"] <> "JPEG" then
      put toUpper(sImageA["exportFormat"]) into sImageA["exportFormat"]
      put toLower(sImageA["exportFormat"]) into sImageA["outFileExtension"]
      put "image/" & sImageA["outFileExtension"] into sImageA["outMimeType"]
    else
      put "jpg" into sImageA["outFileExtension"]
      put "image/jpeg" into sImageA["outMimeType"]
    end if
      
  else -- if sImageA["exportFormat"] <> empty then
    # EXPORT FORMAT IS NOT SET, USE MIME TYPE AND EXTENSION OF SOURCE IMAGE
    put char 2 to -1 of tFileExt into sImageA["outFileExtension"]
    put sImageA["imageType"] into sImageA["exportFormat"]
    put sImageA["mimeType"] into sImageA["outMimeType"]
  end if
   
  put sImageA["sourceFolder"] & "/" & sImageA["sourceImage"] into sImageA["fullSrcPath"]
  put sImageA["destFolder"] & "/" & tFileName & sImageA["thumbMarker"] & "." & sImageA["outFileExtension"] into sImageA["fullDstPath"]
   
  #SHOULD WE MAINTAIN IMAGE PROPORTIONS?
  #
  # WHEN CREATING THUMBS OR COPIES, THE TARGET WIDTH/HEIGHT
  # MIGHT NOT BE IN CORRECT PROPORTION WITH THE SOURCE
  # IMAGE'S WIDTH/HEIGHT.  WE'LL RECALCULATE IT HERE.
  if (sImageA["maintainRatio"] is TRUE) and (sImageA["cropToFit"] is not TRUE) and (sImageA["width"] <> "") and (sImageA["height"] <> "") then
    _rigImageReproportion
  end if
   
  # WAS A WIDTH AND HEIGHT SPECIFIED?
  #
  # IF THE DESTINATION WIDTH/HEIGHT WAS
  # NOT SUBMITTED WE WILL USE THE VALUES
  # FROM THE ACTUAL FILE
  if sImageA["width"] is empty then
    put sImageA["origWidth"] into sImageA["width"]
  end if
  if sImageA["height"] is empty then
    put sImageA["origHeight"] into sImageA["height"]
  end if
   
  # SET THE QUALITY
  replace "%" with "" in sImageA["quality"]
  put rigTrim(sImageA["quality"]) into sImageA["quality"]
  if (sImageA["quality"] is empty) or (sImageA["quality"] = 0) or (sImageA["quality"] is not a number) then
    put "90" into sImageA["quality"]
  end if
   
  # SET THE RESIZE QUALITY
  if sImageA["createThumb"] is TRUE then
    put "best" into sImageA["resizeQuality"]
  end if
   
  # SET THE X/Y COORDINATES
  put sImageA["xAxis"] into tImgXaxisTemp
  replace "%" with "" in tImgXaxisTemp
   
  put sImageA["yAxis"] into tImgYaxisTemp
  replace "%" with "" in tImgYaxisTemp
   
  if (sImageA["xAxis"] is empty) or (tImgXaxisTemp is not a number) then
    put "0" into sImageA["xAxis"]
  end if
  if (sImageA["yAxis"] is empty) or (tImgYaxisTemp is not a number) then
    put "0" into sImageA["yAxis"]
  end if
   
  # WATERMARK-RELATED STUFF . . .
  if sImageA["WMfontcolor"] <> "" then
    if comma is not in sImageA["WMfontcolor"] then
      if the number of chars of sImageA["WMfontcolor"] = 6 then
        put "#" & sImageA["WMfontcolor"] into sImageA["WMfontcolor"]
      end if
         
    else
      put TRUE into sImageA["WMfontColorRGB"]
    end if
  end if

  if sImageA["WMshadowcolor"] <> "" then
    if comma is not in sImageA["WMshadowcolor"] then
      if the number of chars of sImageA["WMshadowcolor"] = 6 then
        put "#" & sImageA["WMshadowcolor"] into sImageA["WMshadowcolor"]
      end if
         
    else
      put TRUE into sImageA["WMshadowColorRGB"]
    end if
    put TRUE into sImageA["WMuseDropshadow"]
  end if
   
  if sImageA["WMoverlaypath"] <> "" then
    if char 1 of sImageA["WMoverlaypath"] is "/" then
      put the defaultFolder & sImageA["WMoverlaypath"] into sImageA["WMoverlaypath"]
    else
      put the defaultFolder & "/" & sImageA["WMoverlaypath"] into sImageA["WMoverlaypath"]
    end if
  end if
   
  return TRUE
end _rigInitializeImage



/*----------------------------------------------------------------------
--| COMMAND _rigSetInitialImageValue
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-13
--| Last Mod: 04-11-13
--| Requires: --
--|
--| Summary: Set initial values.
--| 
--| Format:  _rigSetInitialImageValue param1, param2
--|
--| Parameters: string <pKey>, mixed <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetInitialImageValue pKey pValue
  if pKey is "exportFormat" then
    if pValue <> "JPEG" then
      if pValue is among the items of "GIF,PNG" then
        put pValue into sImageA["exportFormat"]
      else
        put "JPEG" into sImageA["exportFormat"]
      end if
    end if
  else
    put pValue into sImageA[pKey]
  end if -- if pKey is "exportFormat"
end _rigSetInitialImageValue





/*----------------------------------------------------------------------
--| COMMAND rigImgClear
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-02-14
--| Last Mod: 12-02-14
--| Requires: --
--|
--| Summary: Initializes values. Resets values in case this library is used in a loop.
--| 
--| Format:  rigImgClear
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigImgClear
   # SET DEFAULT VALUES
   put FALSE into sImageA["dynamicOutput"]					  -- whether to send to browser or write to disk
   put "imageSrc" into sImageA["dynamicOutputURI"]	  -- dynamic output image source file path relative to the controllers directory
   put "90" into sImageA["quality"]
   put FALSE into sImageA["createThumb"]
   put "_thumb" into sImageA["thumbMarker"]
   put TRUE into sImageA["maintainRatio"]					  -- whether to maintain aspect ratio when resizing or use hard values
   put "auto" into sImageA["masterDim"]						  -- auto, height, or width.  Determines what to use as the master dimension
   put "Center" into sImageA["cropAlignment"]				  -- crop alignment: Center, North, East, South, West, NorthEast, SouthEast, SouthWest, NorthWest
   put FALSE into sImageA["cropToFit"]						    -- crop if the target width/height is not in correct proportion
   
   -- watermark vars
   put "text" into sImageA["WMtype"]							    -- type of watermarking,  options:  text/overlay
   put "16" into sImageA["WMfontsize"]
   put "Helvetica" into sImageA["WMfont"]
   put "South" into sImageA["WMalignment"]					  -- watermark alignment: Center, North, East, South, West, NorthEast, SouthEast, SouthWest, NorthWest
   put "0" into sImageA["WMhorOffset"]						     -- lets you push text to the right/left
   put "10" into sImageA["WMvrtOffset"]						   -- lets you push  text up/down
   put "#f6f6f6" into sImageA["WMfontcolor"]				   -- text color
   put "#656565" into sImageA["WMshadowcolor"]			 -- text shadow color
   put "1" into sImageA["WMshadowdistance"]				    -- dropshadow distance
   put "1" into sImageA["WMshadowsize"]                  -- dropshadow size
   put "180" into sImageA["WMshadowopacity"]            -- dropshadow opacity
   put "15" into sImageA["WMopacity"]						       -- image opacity: 1 - 100  Only works with image
   put FALSE into sImageA["WMuseDropshadow"]
   put "600" into sImageA["WMTextImgWidth"]
   put "stamp" into sImageA["WMtextFileName"]
   
   -- private vars
   put "theImage" into sImageA["newImageObject"]
   put "good" into sImageA["resizeQuality"]
   put "jpg" into sImageA["outFileExtension"]
   put "image/jpeg" into sImageA["outMimeType"]
   put FALSE into sImageA["WMfontColorRGB"]
   put FALSE into sImageA["WMshadowColorRGB"]
   put "8,0,8,8" into sImageA["WMtextMargins"]
end rigImgClear




/*----------------------------------------------------------------------
--| FUNCTION rigImageResize
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2013
--| Last Mod: 04-11-2013
--| Requires: _rigProcessImage()
--|
--| Summary: This is a wrapper function.
--| 
--| Format:  rigImageResize()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigImageResize
   return _rigProcessImage("resize")
end rigImageResize





/*----------------------------------------------------------------------
--| FUNCTION rigImageCrop
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2013
--| Last Mod: 04-11-2013
--| Requires: _rigProcessImage()
--|
--| Summary: This is a wrapper function.
--| 
--| Format:  rigImageCrop()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigImageCrop
	return _rigProcessImage("crop")
end rigImageCrop





/*----------------------------------------------------------------------
--| FUNCTION rigImageRotate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2013
--| Last Mod: 04-11-2013
--| Requires: _rigProcessImage()
--|
--| Summary: This is a wrapper function.
--| 
--| Format:  rigImageRotate()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigImageRotate
	return _rigProcessImage("rotate")
end rigImageRotate





/*----------------------------------------------------------------------
--| FUNCTION _rigProcessImage
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2013
--| Last Mod: 04-11-2013
--| Requires: _rigCreateImage, _rigImageSourceTag(), _rigSetImgError, _rigCropValues()
--|            _rigImageSourceFile(), _rigWriteImgSrcFile(), _rigSaveTheImage,
--|            _rigDynamicImageResizeController(), _rigDynamicImageRotateController,
--|            _rigDynamicImageCropController
--|
--| Summary: This function will resize, crop or rotate.
--| 
--| Format:  _rigProcessImage(param1)
--|
--| Parameters: string <pAction>
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigProcessImage pAction
  local tPercentageCrop, tRetval, tQualityStatement, tImgTag, tFilePath, tCropStatement, tImgSrcData, tRatio
  local tCropRectLeft, tCropRectTop, tCropRectRight, tCropRectBottom, tXpercent, tYpercent, tXamount, tYamount, tDiff
  local tNewWidth, tNewHeight, tRotateStatement
   
  if pAction is "" then
    put "resize" into pAction
  end if
   
  put FALSE into tPercentageCrop
  put empty into tRetval
   
  if sImageA["dynamicOutput"] is not TRUE then
    # OUTPUT SAVED TO DISK
    # CREATE IMAGE TO PROCESS
    _rigCreateImage sImageA["resizeQuality"], pAction
      
    # SET JPG QUALITY
    if sImageA["exportFormat"] is "JPEG" then
      set the JPEGQuality to sImageA["quality"]
    end if
  else
    # DYNAMIC OUTPUT
    # SET JPG QUALITY
    if sImageA["exportFormat"] is "JPEG" then
      put "set the JPEGQuality to" && sImageA["quality"] into tQualityStatement
    else
      put empty into tQualityStatement
    end if
  end if
  
  switch pAction
      # CROP
      #
      case "crop"
         if ("%" is in sImageA["xAxis"]) or ("%" is in sImageA["yAxis"]) then
            put sImageA["xAxis"] into tXpercent
            put sImageA["yAxis"] into tYpercent
            
            put TRUE into tPercentageCrop
            
            replace "%" with "" in tXpercent
            replace "%" with "" in tYpercent
         end if
         
         # CALCULATE CROP VALUES
         if tPercentageCrop is FALSE then
            if (sImageA["xAxis"] <> 0) and (sImageA["xAxis"] < sImageA["origWidth"]) then
               put sImageA["xAxis"] into tCropRectLeft
            else
               put 0 into tCropRectLeft
            end if
            
            if (sImageA["yAxis"] <> 0) and (sImageA["yAxis"] < sImageA["origHeight"]) then
               put sImageA["yAxis"] into tCropRectTop
            else
               put 0 into tCropRectTop
            end if
            
            put sImageA["origWidth"] into tCropRectRight
            put sImageA["origHeight"] into tCropRectBottom
            
            
         else -- if tPercentageCrop is FALSE then
            # CALCULATE PERCENTAGE CROP VALUES
            if (tXpercent <> 0) and (tXpercent < 100) then
               put round((sImageA["origWidth"] - ((sImageA["origWidth"] / 100) * tXpercent)) / 2) into tXamount
            else
               put 0 into tXamount
            end if
            
            if (tYpercent <> 0) and (tYpercent < 100) then
               put round((sImageA["origHeight"] - ((sImageA["origHeight"] / 100) * tYpercent)) / 2) into tYamount
            else
               put 0 into tYamount
            end if
         end if -- if tPercentageCrop is FALSE then
         
         
         # SAVE OUTPUT TO DISK
         if sImageA["dynamicOutput"] is not TRUE then
            
            try
               # SET IMAGE TO ORIGINAL SIZE
               set the width of image sImageA["newImageObject"] to sImageA["origWidth"]
               set the height of image sImageA["newImageObject"] to sImageA["origHeight"]
               
               # CROP IMAGE
               if tPercentageCrop is FALSE then
                  crop image sImageA["newImageObject"] to tCropRectLeft & "," & tCropRectTop & "," & tCropRectRight & "," & tCropRectBottom
               else
                  crop image sImageA["newImageObject"] to _rigCropValues(tXamount, tYamount)
               end if
               
               # SAVE IMAGE
               _rigSaveTheImage
               delete image sImageA["newImageObject"]
            catch e
               put e into tRetval
            end try
            
            
         else -- if sImageA["dynamicOutput"] is not TRUE then
            # DYNAMIC OUTPUT
            # CALCULATE NEW SIZE
            if tPercentageCrop is TRUE then
               put round((sImageA["origWidth"] / 100) * tXpercent) into tNewWidth
               put round((sImageA["origHeight"] / 100) * tYpercent) into tNewHeight
            else
               put sImageA["origWidth"] - sImageA["xAxis"]  into tNewWidth
               put sImageA["origHeight"] - sImageA["yAxis"]  into tNewHeight
            end if
            			
            # BUILD IMAGE SOURCE TAG
            put _rigImageSourceTag(tNewWidth, tNewHeight) into tImgTag
            
            # BUILD CROP STATEMENT
            if tPercentageCrop is FALSE then
               put "crop image" && sImageA["newImageObject"] && "to" && tCropRectLeft & "," & tCropRectTop & "," & tCropRectRight & "," & tCropRectBottom into tCropStatement
            else
               put "crop image" && sImageA["newImageObject"] && "to" && _rigCropValues(tXamount, tYamount) into tCropStatement
            end if
            
            # BUILD DYNAMIC CONTROLLER
            put _rigDynamicImageCropController(tCropStatement, tQualityStatement) into tImgSrcData
            
            
         end if
         
         break
         
         # ROTATE
         #
      case "rotate"
         # SAVE OUTPUT TO DISK
         
         if sImageA["dynamicOutput"] is not TRUE then
            
            try
               # SET IMAGE TO ORIGINAL SIZE
               set the width of image sImageA["newImageObject"] to sImageA["origWidth"]
               set the height of image sImageA["newImageObject"] to sImageA["origHeight"]
               
               switch sImageA["rotationAngle"]
                  case "hor"
                     flip image sImageA["newImageObject"] horizontal
                     break
                  case "vrt"
                     flip image sImageA["newImageObject"] vertical
                     break
                  default
                     set the angle of image sImageA["newImageObject"] to - sImageA["rotationAngle"]
               end switch
               
               # SAVE IMAGE
               _rigSaveTheImage
               delete image sImageA["newImageObject"]
            catch e
               put e into tRetval
            end try
            
         else -- if sImageA["dynamicOutput"] is not TRUE then
            # DYNAMIC OUTPUT
            
            put sImageA["origWidth"] into tNewWidth
            put sImageA["origHeight"] into tNewHeight
            
            # BUILD ROTATION STATEMENT AND CALCULATE NEW SIZE
            switch sImageA["rotationAngle"]
               case "hor"
                  put "flip image" && quote & sImageA["newImageObject"] & quote && "horizontal" into tRotateStatement
                  break
               case "vrt"
                  put "flip image" && quote & sImageA["newImageObject"] & quote && "vertical" into tRotateStatement
                  break
               default
                  put "set the angle of image" & quote & sImageA["newImageObject"] & quote && "to -" && sImageA["rotationAngle"] into tRotateStatement
                  
                  if (sImageA["rotationAngle"] is 90) or (sImageA["rotationAngle"] is 270) then
                     put sImageA["origHeight"] into tNewWidth
                     put sImageA["origWidth"] into tNewHeight
                  end if
            end switch
            
            # BUILD IMAGE SOURCE TAG
            put _rigImageSourceTag(tNewWidth, tNewHeight) into tImgTag
            
            # BUILD DYNAMIC CONTROLLER
            put _rigDynamicImageRotateController(tRotateStatement, tQualityStatement) into tImgSrcData
            
         end if -- if sImageA["dynamicOutput"] is not TRUE then
         
         break
         
         
         # RESIZE
         # 
      case "resize"
         # SAVE OUTPUT TO DISK
         if sImageA["dynamicOutput"] is not TRUE then
            
            try
               # CROP
               if sImageA["cropToFit"] is TRUE then
                  # SET IMAGE TO ORIGINAL SIZE
                  set the width of image sImageA["newImageObject"] to sImageA["origWidth"]
                  set the height of image sImageA["newImageObject"] to sImageA["origHeight"]
                  
                  # CALCULATE CROP VALUES
                  put sImageA["width"]/sImageA["origWidth"] into tRatio
                  if tRatio * sImageA["origHeight"] < sImageA["height"] then
                     
                     put sImageA["origWidth"] - ((sImageA["width"] / sImageA["height"]) * sImageA["origHeight"]) into tDiff
                     
                     # CROP WIDTH
                     crop image sImageA["newImageObject"] to round(tDiff / 2),0,sImageA["origWidth"] - round(tDiff / 2),sImageA["origHeight"]
                  else
                     
                     put sImageA["origHeight"] - ((sImageA["height"] / sImageA["width"]) * sImageA["origWidth"]) into tDiff
                     
                     # CROP HEIGHT
                     crop image sImageA["newImageObject"] to 0,round(tDiff / 2),sImageA["origWidth"],sImageA["origHeight"] - round(tDiff / 2)
                  end if -- if tRatio * sImageA["origHeight"] < sImageA["height"] then
               end if -- if sImageA["cropToFit"] is TRUE then
               
               # RESIZE IMAGE
               set the width of image sImageA["newImageObject"] to sImageA["width"]
               set the height of image sImageA["newImageObject"] to sImageA["height"]
              
               # SAVE IMAGE
               _rigSaveTheImage
               delete image sImageA["newImageObject"]
            catch e
               put e into tRetval
            end try
            
            
         else -- if sImageA["dynamicOutput"] is not TRUE then
            # DYNAMIC OUTPUT
            
            # BUILD IMAGE SOURCE TAG
            put _rigImageSourceTag(sImageA["width"], sImageA["height"]) into tImgTag
            
            
            # PREPARE CROPSTATEMENT
            put empty into tCropStatement
            
            if sImageA["cropToFit"] is TRUE then
               # SET IMAGE TO ORIGINAL SIZE
               put "set the width of image" && quote & sImageA["newImageObject"] & quote && "to" && sImageA["origWidth"] & return & \
                     "set the height of image" && quote & sImageA["newImageObject"] & quote && "to" && sImageA["origHeight"] & return into tCropStatement
               
               # CALCULATE CROP VALUES
               put sImageA["width"]/sImageA["origWidth"] into tRatio
               if tRatio * sImageA["origHeight"] < sImageA["height"] then
                  
                  put sImageA["origWidth"] - ((sImageA["width"] / sImageA["height"]) * sImageA["origHeight"]) into tDiff
                  
                  # CROP WIDTH
                  put "crop image" && quote & sImageA["newImageObject"] & quote && "to" && round(tDiff / 2) & ",0," & sImageA["origWidth"] - round(tDiff / 2) & "," & sImageA["origHeight"] after tCropStatement
               else
                  
                  put sImageA["origHeight"] - ((sImageA["height"] / sImageA["width"]) * sImageA["origWidth"]) into tDiff
                  
                  # CROP HEIGHT
                  put "crop image" && quote & sImageA["newImageObject"] & quote && "to 0," & round(tDiff / 2) & "," & sImageA["origWidth"] & "," & sImageA["origHeight"] - round(tDiff / 2)  after tCropStatement
                  
               end if -- if tRatio * sImageA["origHeight"] < sImageA["height"] then
            end if -- if sImageA["cropToFit"] is TRUE then
            
            # BUILD DYNAMIC CONTROLLER
            put _rigDynamicImageResizeController(tCropStatement, tQualityStatement) into tImgSrcData
            
         end if -- if sImageA["dynamicOutput"] is not TRUE then
         
  end switch
   
  # BUILD PATH TO IMAGE SOURCE FILE
  if sImageA["dynamicOutput"] is TRUE then
    put _rigImageSourceFile() into tFilePath
      
    get _rigWriteImgSrcFile(tFilePath, tImgSrcData)
      		
    # CHECK IF THERE WAS AN ERROR WHILE WRITING THE FILE
    if it is TRUE then
         
      return tImgTag
    else
         
      return FALSE
    end if
  end if
   
  # DID IT WORK?
  if tRetval is not empty then
    _rigSetImgError "imglib_image_processing_failed"
      
    return FALSE
  end if
   
  return TRUE
end _rigProcessImage




/*----------------------------------------------------------------------
--| FUNCTION rigImageWatermark
--|
--| Author: rabit
--| Version:  1.0
--| Created: 13-01-10
--| Last Mod: 13-01-10
--| Requires: _rigOverlayWatermark(), _rigTextWatermark()
--|
--| Summary: This is a wrapper function that chooses the type
--|            of watermarking based on the specified preference.
--| 
--| Format:  rigImageWatermark()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigImageWatermark
	if sImageA["WMtype"] is "overlay" then
		return _rigOverlayWatermark()
	else
		return _rigTextWatermark()
	end if
end rigImageWatermark








/*----------------------------------------------------------------------
--| FUNCTION _rigOverlayWatermark
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-02-14
--| Last Mod: 11-02-14
--| Requires: _rigWatermarkTopLeft(), _rigCreateImage, _rigSaveTheImage,
--|            _rigDynamicImageWMoverlayController, _rigImageSourceTag(),
--|            _rigImageSourceFile(), _rigWriteImgSrcFile, _rigSetImgError
--|
--| Summary: Watermark grafic version.
--| 
--| Format:  _rigOverlayWatermark()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigOverlayWatermark
   local tRetval, tBlendlevel, tOverlayWidth, tOverlayHeight, tOverlayTopLeft, tQualityStatement, tImgTag
   local tImgSrcData, tFilePath
   
   put empty into tRetval
   
   # THE BLENDLEVEL
   put 100 - sImageA["WMopacity"] into tBlendlevel
   
   # GET DIMENSIONS OF OVERLAY IMAGE
   try
      import paint from file sImageA["WMoverlaypath"]
      put the width of last image into tOverlayWidth
      put the height of last image into tOverlayHeight
      
      # DELETE IMAGE IN CASE THE OUTPUT IS JUST CODE
      if sImageA["dynamicOutput"] is TRUE then
         delete last image
      else
         set the name of last image to "overlayImage"
      end if
      
   catch e
      put e into tRetval
   end try
   
   # GET TOPLEFT POSITION OF OVERLAY IMAGE
   put _rigWatermarkTopLeft(tOverlayWidth, tOverlayHeight) into tOverlayTopLeft
   
   # SAVE OUTPUT TO DISK
   if sImageA["dynamicOutput"] is not TRUE then
      # SET JPG QUALITY
      if sImageA["exportFormat"] is "JPEG" then
         set the JPEGQuality to sImageA["quality"]
      end if
      
      try
         # CREATE IMAGE TO PROCESS
         _rigCreateImage
         
         # SET IMAGE TO ORIGINAL SIZE
         set the width of image sImageA["newImageObject"] to sImageA["origWidth"]
         set the height of image sImageA["newImageObject"] to sImageA["origHeight"]
         
         # CREATE OVERLAY IMAGE
         set the topleft of image "overlayImage" to tOverlayTopLeft["left"] & "," & tOverlayTopLeft["top"]
         set the lockLoc of image "overlayImage" to true
         set the width of image "overlayImage" to tOverlayWidth
         set the height of image "overlayImage" to tOverlayHeight
         set the blendlevel of image "overlayImage" to tBlendlevel
         
         # GROUP BOTH IMAGES
         group image "theImage" and image "overlayImage"
         set the name of last group to "theGroup"
         set the margins of grp "theGroup" to 0
         
         # SAVE IMAGE
         _rigSaveTheImage "group" && quote & "theGroup" & quote
         delete image sImageA["newImageObject"]
         delete image "overlayImage"
      catch e
         put e into tRetval
      end try
      
   else
      # DYNAMIC OUTPUT
      # SET JPG QUALITY
      if sImageA["exportFormat"] is "JPEG" then
         put "set the JPEGQuality to" && sImageA["quality"] into tQualityStatement
      else
         put empty into tQualityStatement
      end if
      
      # BUILD IMAGE SOURCE TAG
      put _rigImageSourceTag(sImageA["origWidth"], sImageA["origHeight"]) into tImgTag
      
      # BUILD DYNAMIC CONTROLLER
      put _rigDynamicImageWMoverlayController(tOverlayWidth, tOverlayHeight, tOverlayTopLeft["left"], tOverlayTopLeft["top"], tBlendlevel, tQualityStatement) into tImgSrcData
      	
      # BUILD PATH TO IMAGE SOURCE FILE
      put _rigImageSourceFile() into tFilePath
      
      get _rigWriteImgSrcFile(tFilePath, tImgSrcData)
      
      # CHECK IF THERE WAS AN ERROR WHILE WRITING THE FILE
      if it is TRUE then
         
         return tImgTag
      else
         			
         return FALSE
      end if
   end if
   
   
   # DID IT WORK?
   if tRetval is not empty then
      _rigSetImgError "imglib_image_process_failed"
      
      return FALSE
   end if
   
   return TRUE
end _rigOverlayWatermark






/*----------------------------------------------------------------------
--| FUNCTION _rigTextWatermark
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-02-14
--| Last Mod: 11-02-14
--| Requires: _rigSetImgError, _rigWatermarkTopLeft(), _rigCreateImage, _rigImageSourceTag(),
--|            _rigDynamicImageWMtextController, _rigImageSourceFile(), _rigWriteImgSrcFile()
--|
--| Summary: Watermark text version.
--| 
--| Format:  _rigTextWatermark()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigTextWatermark
   local tRetval, tFontcolor, tShadowColor, tOverlayTextWidth, tOverlayTextHeight, tOverlayTopLeft
   local tQualityStatement, tImgTag, tDropShadowStatement, tImgSrcData, tFilePath
   
   # CHECK IF CHOSEN FONT IS AVAILABLE	
   if sImageA["WMfont"] is not empty then
      if sImageA["WMfont"] is not among the lines of the fontNames then
         _rigSetImgError "imglib_missing_font"
         
         return FALSE
      end if
      
   else
      _rigSetImgError "imglib_missing_font"
      
      return FALSE
   end if
   
   # CHECK IF COLOR VALUES ARE HEX OR RGB
   if sImageA["WMfontColorRGB"] is TRUE then
      # RGB VALUE
      put sImageA["WMfontcolor"] into tFontcolor
   else
      # HEX VALUE
      put quote & sImageA["WMfontcolor"] & quote into tFontcolor
   end if
   
   if sImageA["WMshadowColorRGB"] is TRUE then
      # RGB VALUE
      put sImageA["WMshadowcolor"] into tShadowColor
   else
      # HEX VALUE
      put quote & sImageA["WMshadowcolor"] & quote into tShadowColor 
   end if
   	
   put empty into tRetval
   
   # GET DIMENSIONS OF OVERLAY TEXT FIELD
   set the textFont of the templateField to sImageA["WMfont"]
   set the textSize of the templateField to sImageA["WMfontsize"]
   set the margins of the templateField to sImageA["WMtextMargins"]
   set the showBorder of the templateField to false
   set the dontWrap of the templateField to true
   set the text of the templateField to sImageA["WMtext"]
   create field "tempField"
   
   put the formattedWidth of field "tempField" into tOverlayTextWidth
   put the formattedHeight of field "tempField" into tOverlayTextHeight
   
   # DELETE TEXT FIELD IN CASE THE OUTPUT IS JUST CODE
   if sImageA["dynamicOutput"] is TRUE then
      delete last field
   end if
   
   # GET TOPLEFT POSITION OF OVERLAY IMAGE
   put _rigWatermarkTopLeft(tOverlayTextWidth, tOverlayTextHeight) into tOverlayTopLeft
   
   # SAVE OUTPUT TO DISK
   if sImageA["dynamicOutput"] is not TRUE then
      # SET JPG QUALITY
      if sImageA["exportFormat"] is "JPEG" then
         set the JPEGQuality to sImageA["quality"]
      end if
      
      try
         # CREATE IMAGE TO PROCESS
         _rigCreateImage
         
         # SET IMAGE TO ORIGINAL SIZE
         set the width of image sImageA["newImageObject"] to sImageA["origWidth"]
         set the height of image sImageA["newImageObject"] to sImageA["origHeight"]
         
         set the textFont of the templateField to sImageA["WMfont"]
         set the textSize of the templateField to sImageA["WMfontsize"]
         set the margins of the templateField to sImageA["WMtextMargins"]
         set the opaque of the templateField to FALSE
         set the showBorder of the templateField to FALSE
         set the foregroundColor of the templateField to tFontcolor
         set the dontWrap of the templateField to TRUE
         set the text of the templateField to sImageA["WMtext"]
         create field "theText"
         set the width of field "theText" to the formattedWidth of field "theText"
         set the height of field "theText" to the formattedHeight of field "theText"
         set the topLeft of field "theText" to tOverlayTopLeft["left"], tOverlayTopLeft["top"]
         # DROPSHADOW
         if sImageA["WMuseDropshadow"] is TRUE then
            set the dropShadow["color"] of field "theText" to tShadowColor
            set the dropShadow["size"] of field "theText" to sImageA["WMshadowsize"]
            set the dropShadow["opacity"] of field "theText" to sImageA["WMshadowopacity"]
            set the dropShadow["distance"] of field "theText" to sImageA["WMshadowdistance"]
         end if
         
         # GROUP BOTH IMAGES
         group image "theImage" and field "theText"
         set the name of last group to "theGroup"
         set the margins of grp "theGroup" to 0
         
         # SAVE IMAGE
         _rigSaveTheImage "group" && quote & "theGroup" & quote
         delete image sImageA["newImageObject"]
      catch e
         put e into tRetval
      end try
      
      
   else
      # DYNAMIC OUTPUT
      # SET JPG QUALITY
      if sImageA["exportFormat"] is "JPEG" then
         put "set the JPEGQuality to" && sImageA["quality"] into tQualityStatement
      else
         put empty into tQualityStatement
      end if
      
      # BUILD IMAGE SOURCE TAG
      put _rigImageSourceTag(sImageA["origWidth"], sImageA["origHeight"]) into tImgTag
      
      # BUILD DROP SHADOW STATEMENT
      put empty into tDropShadowStatement
      if sImageA["WMuseDropshadow"] is TRUE then
         put "set the dropShadow[" & quote & "color" & quote &"] of field" && quote & "theText" & quote && "to" && tShadowColor & return & \
               "set the dropShadow[" & quote & "size" & quote &"] of field" && quote & "theText" & quote && "to" && sImageA["WMshadowsize"] & return & \
               "set the dropShadow[" & quote & "opacity" & quote &"] of field" && quote & "theText" & quote && "to" && sImageA["WMshadowopacity"] & return & \
               "set the dropShadow[" & quote & "distance" & quote &"] of field" && quote & "theText" & quote && "to" && sImageA["WMshadowdistance"] into tDropShadowStatement
      end if
      
      # BUILD DYNAMIC CONTROLLER
      put _rigDynamicImageWMtextController(tOverlayTopLeft["left"], tOverlayTopLeft["top"], tFontcolor, tDropShadowStatement, tQualityStatement) into tImgSrcData
      
      # BUILD PATH TO IMAGE SOURCE FILE
      put _rigImageSourceFile() into tFilePath
      
      get _rigWriteImgSrcFile(tFilePath, tImgSrcData)
      
      # CHECK IF THERE WAS AN ERROR WHILE WRITING THE FILE
      if it is TRUE then
         
         return tImgTag
      else
         					
         return FALSE
      end if
      
   end if
   
   
   # DID IT WORK?
   if tRetval is not empty then
      _rigSetImgError "imglib_image_process_failed"
      
      return FALSE
   end if
   
   return TRUE
end _rigTextWatermark





/*----------------------------------------------------------------------
--| COMMAND _rigImageReproportion
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2013
--| Last Mod: 04-11-2013
--| Requires: --
--|
--| Summary: When creating thumbs, the desired width/height
--|            can end up warping the image due to an incorrect
--|            ratio between the full-sized image and the thumb.
--|
--|            This command lets us re-proportion the width/height
--|            if users choose to maintain the aspect ratio when resizing.
--| 
--| Format: _rigImageReproportion
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigImageReproportion
   local tNewWidth, tNewHeight, tRatio
   
   if (sImageA["width"] is not a number) or (sImageA["height"] is not a number) or (sImageA["width"] = 0) or (sImageA["height"] = 0) then
      exit _rigImageReproportion
   end if
   
   if (sImageA["origWidth"] is not a number) or (sImageA["origHeight"] is not a number) or (sImageA["origWidth"] = 0) or (sImageA["origHeight"] = 0) then
      exit _rigImageReproportion
   end if
   
   put ceil(sImageA["origWidth"] * sImageA["height"] / sImageA["origHeight"]) into tNewWidth
   put ceil(sImageA["width"] * sImageA["origHeight"] / sImageA["origWidth"]) into tNewHeight

   put ((sImageA["origHeight"] / sImageA["origWidth"]) - (sImageA["height"] / sImageA["width"])) into tRatio
   
   if (sImageA["masterDim"] <> "width") and (sImageA["masterDim"] <> "height") then
      if tRatio < 0 then
         put "width" into sImageA["masterDim"]
      else
         put "height" into sImageA["masterDim"]
      end if
   end if
   
   if (sImageA["width"] <> tNewWidth) and (sImageA["height"] <> tNewHeight) then
      if sImageA["masterDim"] is "height" then
         put tNewWidth into sImageA["width"]
      else
         put tNewHeight into sImageA["height"]
      end if
   end if
end _rigImageReproportion





/*----------------------------------------------------------------------
--| FUNCTION _rigGetImageProperties
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2013
--| Last Mod: 04-11-2013
--| Requires: _rigSetImgError, rigFileSize()
--|
--| Summary: A helper function that gets info about the file.
--| 
--| Format:  _rigGetImageProperties(param1, param2)
--|
--| Parameters: string <pPath>, bool <pReturn>
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigGetImageProperties pPath pReturn
   local tPath, tReturn, tCmd, tVals, tMime, tTypes, tV
   
   if pPath is empty then
      put sImageA["fullSrcPath"] into tPath
   else
      put pPath into tPath
   end if
   
   if pReturn is empty then
      put FALSE into tReturn
   else
      put pReturn into tReturn
   end if
   
   if there is not a file tPath then
      _rigSetImgError "imglib_invalid_path"
      	
      return FALSE
   end if
   
   
   # GET WIDTH, HEIGHT, FORMAT
   import paint from file tPath
   put the width of last image into tVals
   put "," & the height of last image after tVals
   put "," & toUpper(the paintCompression of last image) after tVals
   -- put "," & rigFileSize(tPath) after tVals ---------------- currently not needed
   delete last image
   
   # GET MIME TYPE
   put empty into tMime
   put "gif,jpeg,png" into tTypes
   repeat for each item thisItem in tTypes
      if thisItem is toLower(item 3 of tVals) then
         put "image/" & thisItem into tMime
         exit repeat
      end if
   end repeat
   if tMime is empty then
      put "image/jpg" into tMime
   end if
   
   if tReturn is TRUE then
      put item 1 of tVals into tV["width"]
      put item 2 of tVals into tV["height"]
      put item 3 of tVals into tV["imageType"]
      -- put item 4 of tVals into tV["sizeStr"] ---------------- currently not needed
      put tMime into tV["mimeType"]
      
      return tV
   end if
   
   put item 1 of tVals into sImageA["origWidth"]
   put item 2 of tVals into sImageA["origHeight"]
   put item 3 of tVals into sImageA["imageType"]
   -- put item 4 of tVals into sImageA["sizeStr"]  ---------------- currently not needed
   put tMime into sImageA["mimeType"]
   
   return TRUE
end _rigGetImageProperties





/*----------------------------------------------------------------------
--| FUNCTION _rigExplodeImgName
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2013
--| Last Mod: 04-11-2013
--| Requires: --
--|
--| Summary: This is a helper function that extracts the extension
--|                    from the source_image.  This function lets us deal with
--|                    source_images with multiple periods, like:  my.cool.jpg
--|                    It returns an associative array with two elements:
--|                    tArray["ext"]  = ".jpg"
--|                    tArray['name'] = "my.cool"
--| 
--| Format:  _rigExplodeImgName(param1)
--|
--| Parameters: string <pSourceImg>
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigExplodeImgName pSourceImg
   local tExtension, tName, tArray
   
	set the itemDelimiter to "."
	put "." & item -1 of pSourceImg into tExtension

	if tExtension is "." then
		put pSourceImg into tName
	else
		put item 1 to -2 of pSourceImg into tName
	end if

	put tExtension into tArray["ext"]
	put tName into tArray["name"]

	return tArray
end _rigExplodeImgName





/*----------------------------------------------------------------------
--| COMMAND _rigSetImgError
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2013
--| Last Mod: 04-11-2013
--| Requires: rigLangLoadLang(), rigLangLangLine(), rigLogMessage
--|
--| Summary: Set error message.
--| 
--| Format:  _rigSetImgError param1
--|
--| Parameters: string <pMsg>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigSetImgError pMsg
   local tErrorNum, tVal, tLangLine, tMsg
   
   get rigLangLoadLang("imglib")
   	
   put the number of lines in the keys of sImageA["errorMsg"] into tErrorNum
   
   if pMsg is an array then
      repeat for each key tKey in pMsg
         put pMsg[tKey] into tVal
         put rigLangLangLine(tVal) into tLangLine
         
         if tLangLine is FALSE then
            put tVal into tMsg
         else
            put tLangLine into tMsg
         end if
         
         put tErrorNum + 1 into tErrorNum
         put tMsg into sImageA["errorMsg"][tErrorNum]
         rigLogMessage "error", tMsg
      end repeat

   else
      put rigLangLangLine(pMsg) into tLangLine
      
      if tLangLine is FALSE then
         put pMsg into tMsg
      else
         put tLangLine into tMsg
      end if

      put tErrorNum + 1 into tErrorNum
      put tMsg into sImageA["errorMsg"][tErrorNum]
      rigLogMessage "error", tMsg
   end if
end _rigSetImgError




/*----------------------------------------------------------------------
--| FUNCTION rigDisplayImgErrors
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-02-2014
--| Last Mod: 11-02-2014
--| Requires: --
--|
--| Summary: Show error messages.
--| 
--| Format:  rigDisplayImgErrors(param1, param2)
--|
--| Parameters: string <pOpen>, string <pClose>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDisplayImgErrors pOpen pClose
   local tOpen, tClose, tStr, tVal
   
	if pOpen is "" then
		put "<p>" into tOpen
	else
		put pOpen into tOpen
	end if

	if pClose is "" then
		put "</p>" into tClose
	else
		put pClose into tClose
	end if

	put empty into tStr
	repeat for each key tKey in sImageA["errorMsg"]
		put sImageA["errorMsg"][tKey] into tVal
		put tOpen & tVal & tClose & return after tStr
	end repeat

	return tStr
end rigDisplayImgErrors





/*----------------------------------------------------------------------
--| FUNCTION _rigWriteImgSrcFile
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2013
--| Last Mod: 04-11-2013
--| Requires: _rigSetImgError
--|
--| Summary: Write dynamic output file.
--| 
--| Format:  _rigWriteImgSrcFile()
--|
--| Parameters: string <pFile>, string <pData>
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigWriteImgSrcFile pFile pData
	try
		put pData into URL ("binfile:" & pFile)
	catch err
		_rigSetImgError "An error occured while trying to save image source data:" && pFile  && err
		return FALSE
	end try
	return TRUE
end _rigWriteImgSrcFile




/*----------------------------------------------------------------------
--| COMMAND rigImageNewSettings
--|
--| Author: rabit
--| Version:  1.0
--| Created: 12-02-14
--| Last Mod: 12-02-14
--| Requires: _rigInitializeImage
--|
--| Summary: Change image configuration.
--| 
--| Format:  rigImageNewSettings param1
--|
--| Parameters: mixed <pConfig>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigImageNewSettings pConfig
   if pConfig is not an array then
      if pConfig is not empty then
         split pConfig using numToCodepoint(1) and numToCodepoint(2)
      end if
   end if
   
   if pConfig is an array then
      _rigInitializeImage pConfig
   end if
end rigImageNewSettings





/*----------------------------------------------------------------------
--| FUNCTION _rigImageSourceTag
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2013
--| Last Mod: 04-11-2013
--| Requires: rigSiteURL()
--|
--| Summary: Build image source tag for dynamic output.
--| 
--| Format:  _rigImageSourceTag(param1, param2)
--|
--| Parameters: integer <pWidth>, integer <pHeight>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigImageSourceTag pWidth pHeight
   local tWidth, tHeight, tImgSizeTags, tImgTag, tImgSrcURL
   
	if pWidth is empty then
		put sImageA["origWidth"] into tWidth
	else
		put pWidth into tWidth
	end if

	if pHeight is empty then
		put sImageA["origHeight"] into tHeight
	else
		put pHeight into tHeight
	end if

	put "width=" & quote & tWidth & quote && "height=" & quote & tHeight & quote into tImgSizeTags
	put rigSiteURL(sImageA["dynamicOutputURI"]) into tImgSrcURL
	put "<img src=" & quote & tImgSrcURL & quote && tImgSizeTags && "/>"  into tImgTag

	return tImgTag
end _rigImageSourceTag





/*----------------------------------------------------------------------
--| FUNCTION _rigImageSourceFile
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2013-11-04
--| Last Mod: 2018-12-21
--| Requires: --
--|
--| Summary: Path to image source file to be written to disk.
--| 
--| Format:  _rigImageSourceFile()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigImageSourceFile
  local tFilePath
   
	-- local tSystemFolder
	-- set the itemDelimiter to "/"
	-- put item -1 of 	gRigA["systemFolder"] into tSystemFolder		
 	-- put "./" & tSystemFolder & "/application/controllers/" & sImageA["dynamicOutputURI"] & gRigA["EXT"] into tFilePath
  put gRigA["APPPATH"] & "controllers/" & sImageA["dynamicOutputURI"] & gRigA["EXT"] into tFilePath

	return tFilePath
end _rigImageSourceFile








/*----------------------------------------------------------------------
--| FUNCTION rigKnownFonts
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-02-2014
--| Last Mod: 11-02-2014
--| Requires: --
--|
--| Summary: Return known fonts.
--| 
--| Format:  rigKnownFonts()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigKnownFonts
	return the fontNames
end rigKnownFonts







/*----------------------------------------------------------------------
--| COMMAND _rigCreateImage
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2013
--| Last Mod: 04-11-2013
--| Requires: --
--|
--| Summary: Create new image object.
--| 
--| Format:  _rigCreateImage param1, param2
--|
--| Parameters: string <pResizeQuality>, string <pAction>
--|
--| Return: empty
----------------------------------------------------------------------------*/

private command _rigCreateImage pResizeQuality pAction
   if pResizeQuality is empty then
      put "normal" into pResizeQuality
   end if
   
   if pAction is "resize" then
      set the resizeQuality of the templateImage to pResizeQuality
   end if
   
   create image sImageA["newImageObject"]
   
   set the topleft of image sImageA["newImageObject"] to 0,0
   if pAction <> "rotate" then
      set the lockLoc of image sImageA["newImageObject"] to true
   end if
   
   set the text of image sImageA["newImageObject"] to URL ("binfile:" & sImageA["fullSrcPath"])
end _rigCreateImage





/*----------------------------------------------------------------------
--| FUNCTION _rigDynamicImageCropController
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2014-02-10
--| Last Mod: 2018-12-22
--| Requires: --
--|
--| Summary: Cropped image source controller to be written to disk.
--| 
--| Format:  _rigDynamicImageCropController()
--|
--| Parameters: string <pCropStatement>, string <pQualityStatement>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigDynamicImageCropController pCropStatement pQualityStatement
  local tImgSrcData

  put "<?lc" & return & \
  return & \
  "put" && quote & "index" & quote && "into gControllerHandlers" & return & \
  return & \
  "command index" & return & \
  "create image" && quote & sImageA["newImageObject"] & quote & return & \
  "set the topleft of image" && quote & sImageA["newImageObject"] & quote && "to 0,0" & return & \
  "set the lockLoc of image" && quote & sImageA["newImageObject"] & quote && "to true" & return & \
  "set the text of image" && quote & sImageA["newImageObject"] & quote && "to URL" && quote & "binfile:" & sImageA["fullSrcPath"] & quote & return & \
  "set the width of image" && quote & sImageA["newImageObject"] & quote && "to" && sImageA["origWidth"] & return & \
  "set the height of image" && quote & sImageA["newImageObject"] & quote && "to" && sImageA["origHeight"] & return & \
  pCropStatement & return & \
  pQualityStatement & return & \
  "export image" && quote & sImageA["newImageObject"] & quote && "to tModImage as" && sImageA["exportFormat"]  & return & \
  "put header" && quote & "Content-type:" && sImageA["outMimeType"] & quote & return & \
  "put binary tModImage" & return & \
  "end index" & return \
  into tImgSrcData
   
  return tImgSrcData
end _rigDynamicImageCropController






/*----------------------------------------------------------------------
--| FUNCTION _rigDynamicImageRotateController
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2014-02-10
--| Last Mod: 2018-12-22
--| Requires: --
--|
--| Summary: Rotated image source controller to be written to disk.
--| 
--| Format:  _rigDynamicImageRotateController()
--|
--| Parameters: string <pRotateStatement>, string <pQualityStatement>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigDynamicImageRotateController pRotateStatement pQualityStatement
  local tImgSrcData
   
  put "<?lc" & return & \
  return & \
  "put" && quote & "index" & quote && "into gControllerHandlers" & return & \
  return & \
  "command index" & return & \
  "create image" && quote & sImageA["newImageObject"] & quote & return & \
  "set the topleft of image" && quote & sImageA["newImageObject"] & quote && "to 0,0" & return & \
  "set the text of image" && quote & sImageA["newImageObject"] & quote && "to URL" && quote & "binfile:" & sImageA["fullSrcPath"] & quote & return & \
  "set the width of image" && quote & sImageA["newImageObject"] & quote && "to" && sImageA["origWidth"] & return & \
  "set the height of image" && quote & sImageA["newImageObject"] & quote && "to" && sImageA["origHeight"] & return & \
  pRotateStatement & return & \
  pQualityStatement & return & \
  "export image" && quote & sImageA["newImageObject"] & quote && "to tModImage as" && sImageA["exportFormat"]  & return & \
  "put header" && quote & "Content-type:" && sImageA["outMimeType"] & quote & return & \
  "put binary tModImage" & return & \
  "end index" & return \
  into tImgSrcData
   
  return tImgSrcData
end _rigDynamicImageRotateController







/*----------------------------------------------------------------------
--| FUNCTION _rigDynamicImageResizeController
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2014-02-09
--| Last Mod: 2018-12-22
--| Requires: --
--|
--| Summary: Resized image source controller to be written to disk.
--| 
--| Format:  _rigDynamicImageResizeController(param1, param2)
--|
--| Parameters: string <pCropStatement>, string <pQualityStatement>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigDynamicImageResizeController pCropStatement pQualityStatement
  local tImgSrcData
   
  put "<?lc" & return & \
  return & \
  "put" && quote & "index" & quote && "into gControllerHandlers" & return & \
  return & \
  "command index" & return & \
  "set the resizeQuality of the templateImage to" && quote & sImageA["resizeQuality"] & quote & return & \
  "create image" && quote & sImageA["newImageObject"] & quote & return & \
  "set the topleft of image" && quote & sImageA["newImageObject"] & quote && "to 0,0" & return & \
  "set the lockLoc of image" && quote & sImageA["newImageObject"] & quote && "to true" & return & \
  "set the text of image" && quote & sImageA["newImageObject"] & quote && "to URL" && quote & "binfile:" & sImageA["fullSrcPath"] & quote & return & \
  pCropStatement & return & \
  "set the width of image" && quote & sImageA["newImageObject"] & quote && "to" && sImageA["width"] & return & \
  "set the height of image" && quote & sImageA["newImageObject"] & quote && "to" && sImageA["height"] & return & \
  pQualityStatement & return & \
  "export image" && quote & sImageA["newImageObject"] & quote && "to tModImage as" && sImageA["exportFormat"]  & return & \
  "put header" && quote & "Content-type:" && sImageA["outMimeType"] & quote & return & \
  "put binary tModImage" & return & \
  "end index" & return \
  into tImgSrcData
   
  return tImgSrcData
end _rigDynamicImageResizeController






/*----------------------------------------------------------------------
--| FUNCTION _rigDynamicImageWMoverlayController
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2014-02-10
--| Last Mod: 2018-12-22
--| Requires: --
--|
--| Summary: Watermarked image source controller to be written to disk.
--| 
--| Format:  _rigDynamicImageWMoverlayController()
--|
--| Parameters: integer <pOverlayWidth>, integer <pOverlayHeight>, integer <pOverlayLeft>,
--|                    integer <pOverlayTop>, integer <pBlendlevel>, string <pQualityStatement>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigDynamicImageWMoverlayController pOverlayWidth pOverlayHeight pOverlayLeft pOverlayTop pBlendlevel pQualityStatement
  local tImgSrcData
   
  put "<?lc" & return & \
  return & \
  "put" && quote & "index" & quote && "into gControllerHandlers" & return & \
  return & \
  "command index" & return & \
  "create image" && quote & sImageA["newImageObject"] & quote & return & \
  "set the topleft of image" && quote & sImageA["newImageObject"] & quote && "to 0,0" & return & \
  "set the lockLoc of image" && quote & sImageA["newImageObject"] & quote && "to true" & return & \
  "set the text of image" && quote & sImageA["newImageObject"] & quote && "to URL" && quote & "binfile:" & sImageA["fullSrcPath"] & quote & return & \
  "set the width of image" && quote & sImageA["newImageObject"] & quote && "to" && sImageA["origWidth"] & return & \
  "set the height of image" && quote & sImageA["newImageObject"] & quote && "to" && sImageA["origHeight"] & return & \
  "create image" && quote & "overlayImage" & quote & return & \
  "set the topleft of image" && quote & "overlayImage" & quote && "to" && pOverlayLeft & "," & pOverlayTop & return & \
  "set the lockLoc of image" && quote & "overlayImage" & quote && "to true" & return & \
  "set the text of image" && quote & "overlayImage" & quote && "to URL" && quote & "binfile:" & sImageA["WMoverlaypath"] & quote & return & \
  "set the width of image" && quote & "overlayImage" & quote && "to" && pOverlayWidth & return & \
  "set the height of image" && quote & "overlayImage" & quote && "to" && pOverlayHeight & return & \
  "set the blendlevel of image" && quote & "overlayImage" & quote && "to" && pBlendlevel & return & \
  "group image" && quote & "theImage" & quote && "and image" && quote & "overlayImage" & quote & return & \
  "set the name of last group to" && quote & "theGroup" & quote & return & \
  "set the margins of grp" && quote & "theGroup" & quote && "to 0" & return & \
  pQualityStatement & return & \
  "export snapshot from group" && quote & "theGroup" & quote && "to tModImage as" && sImageA["exportFormat"]  & return & \
  "put header" && quote & "Content-type:" && sImageA["outMimeType"] & quote & return & \
  "put binary tModImage" & return & \
  "end index" & return \
  into tImgSrcData
   
  return tImgSrcData
end _rigDynamicImageWMoverlayController





/*----------------------------------------------------------------------
--| FUNCTION _rigDynamicImageWMtextController
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2014-02-10
--| Last Mod: 2018-12-22
--| Requires: --
--|
--| Summary: Watermarked image source controller to be written to disk.
--| 
--| Format:  _rigDynamicImageWMtextController(param1, param2, param3, param4)
--|
--| Parameters: integer <pOverlayLeft>, integer <pOverlayTop>, mixed <pFontcolor>,
--|                    string <pDropShadowStatement>, string <pQualityStatement>                 
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigDynamicImageWMtextController pOverlayLeft pOverlayTop pFontcolor pDropShadowStatement pQualityStatement
  local tImgSrcData
   
  put "<?lc" & return & \
  return & \
  "put" && quote & "index" & quote && "into gControllerHandlers" & return & \
  return & \
  "command index" & return & \
  "create image" && quote & sImageA["newImageObject"] & quote & return & \
  "set the topleft of image" && quote & sImageA["newImageObject"] & quote && "to 0,0" & return & \
  "set the lockLoc of image" && quote & sImageA["newImageObject"] & quote && "to true" & return & \
  "set the text of image" && quote & sImageA["newImageObject"] & quote && "to URL" && quote & "binfile:" & sImageA["fullSrcPath"] & quote & return & \
  "set the width of image" && quote & sImageA["newImageObject"] & quote && "to" && sImageA["origWidth"] & return & \
  "set the height of image" && quote & sImageA["newImageObject"] & quote && "to" && sImageA["origHeight"] & return & \
  "set the textFont of the templateField to" && quote & sImageA["WMfont"] & quote & return & \
  "set the textSize of the templateField to" && sImageA["WMfontsize"] & return & \
  "set the margins of the templateField to" && sImageA["WMtextMargins"] & return & \
  "set the opaque of the templateField to false" & return & \
  "set the showBorder of the templateField to false" & return & \
  "set the foregroundColor of the templateField to" && pFontcolor & return & \
  "set the dontWrap of the templateField to true" & return & \
  "set the text of the templateField to" && quote & sImageA["WMtext"] & quote & return & \
  "create field" && quote & "theText" & quote & return & \
  "set the width of field" && quote & "theText" & quote && "to the formattedWidth of field" && quote & "theText" & quote & return & \
  "set the height of field" && quote & "theText" & quote && "to the formattedHeight of field" && quote & "theText" & quote & return & \
  "set the topLeft of field" && quote & "theText" & quote && "to" && pOverlayLeft & "," & pOverlayTop & return & \
  pDropShadowStatement & return & \
  "group image" && quote & "theImage" & quote && "and field" && quote & "theText" & quote & return & \
  "set the name of last group to" && quote & "theGroup" & quote & return & \
  "set the margins of grp" && quote & "theGroup" & quote && "to 0" & return & \
  pQualityStatement & return & \
  "export snapshot from group" && quote & "theGroup" & quote && "to tModImage as" && sImageA["exportFormat"]  & return & \
  "put header" && quote & "Content-type:" && sImageA["outMimeType"] & quote & return & \
  "put binary tModImage" & return & \
  "end index" & return \
  into tImgSrcData
   
  return tImgSrcData
end _rigDynamicImageWMtextController






/*----------------------------------------------------------------------
--| FUNCTION _rigCropValues
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-02-2014
--| Last Mod: 10-02-2014
--| Requires: --
--|
--| Summary: Calculates cropping rectangle.
--| 
--| Format:  _rigCropValues(param1, param2)
--|
--| Parameters: integer <pXamount>, string <pYamount>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCropValues pXamount pYamount
   local tCropRectLeft, tCropRectTop, tCropRectRight, tCropRectBottom
   
   switch sImageA["cropAlignment"]
      # NORTH POSITION
      case "North"
         put pXamount into tCropRectLeft
         put 0 into tCropRectTop
         put sImageA["origWidth"] - pXamount into tCropRectRight
         put sImageA["origHeight"] - (pYamount * 2) into tCropRectBottom
         
         break
         # EAST POSITION
      case "East"
         put pXamount * 2 into tCropRectLeft
         put pYamount into tCropRectTop
         put sImageA["origWidth"] into tCropRectRight
         put sImageA["origHeight"] - pYamount into tCropRectBottom
         
         break
         # SOUTH POSITION
      case "South"
         put pXamount into tCropRectLeft
         put pYamount * 2 into tCropRectTop
         put sImageA["origWidth"] - pXamount into tCropRectRight
         put sImageA["origHeight"] into tCropRectBottom
         
         break
         # WEST POSITION
      case "West"
         put 0 into tCropRectLeft
         put pYamount into tCropRectTop
         put sImageA["origWidth"] - (pXamount * 2) into tCropRectRight
         put sImageA["origHeight"] - pYamount into tCropRectBottom
         
         break
         # NORTH EAST POSITION
      case "NorthEast"
         put pXamount * 2 into tCropRectLeft
         put 0 into tCropRectTop
         put sImageA["origWidth"] into tCropRectRight
         put sImageA["origHeight"] - (pYamount * 2) into tCropRectBottom
         
         break
         # SOUTH EAST POSITION
      case "SouthEast"
         put pXamount * 2 into tCropRectLeft
         put pYamount * 2 into tCropRectTop
         put sImageA["origWidth"] into tCropRectRight
         put sImageA["origHeight"] into tCropRectBottom
         
         break
         # SOUTH WEST POSITION
      case "SouthWest"
         put 0 into tCropRectLeft
         put pYamount * 2 into tCropRectTop
         put sImageA["origWidth"] - (pXamount * 2) into tCropRectRight
         put sImageA["origHeight"] into tCropRectBottom
         
         break
          # NORTH WEST POSITION
      case "NorthWest"
         put 0 into tCropRectLeft
         put 0 into tCropRectTop
         put sImageA["origWidth"] - (pXamount * 2) into tCropRectRight
         put sImageA["origHeight"] - (pYamount * 2) into tCropRectBottom
         
         break
      default
         # CENTER POSITION
         put pXamount into tCropRectLeft
         put pYamount into tCropRectTop
         put sImageA["origWidth"] - pXamount into tCropRectRight
         put sImageA["origHeight"] - pYamount into tCropRectBottom
   end switch
   
   return tCropRectLeft & "," & tCropRectTop & "," & tCropRectRight & "," & tCropRectBottom
end _rigCropValues





/*----------------------------------------------------------------------
--| FUNCTION _rigWatermarkTopLeft
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-02-2014
--| Last Mod: 11-02-2014
--| Requires: --
--|
--| Summary: Calculates the topleft position of the watermark.
--| 
--| Format:  _rigWatermarkTopLeft(param1, param2)
--|
--| Parameters: integer <pOverlayWidth>, integer <pOverlayHeight>
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigWatermarkTopLeft pOverlayWidth pOverlayHeight
   local tOverlayLeft, tOverlayTop, tTopLeft
   
   switch sImageA["WMalignment"]
      case "North"
         put (sImageA["origWidth"] / 2) - (pOverlayWidth / 2) into tOverlayLeft
         put 0 into tOverlayTop
         
         break
      case "East"
         put sImageA["origWidth"] - pOverlayWidth into tOverlayLeft
         put (sImageA["origHeight"] / 2) - (pOverlayHeight / 2) into tOverlayTop
         
         break
      case "South"
         put (sImageA["origWidth"] / 2) - (pOverlayWidth / 2) into tOverlayLeft
         put sImageA["origHeight"] - pOverlayHeight into tOverlayTop
         
         break
      case "West"
         put 0 into tOverlayLeft
         put round((sImageA["origHeight"] / 2) - (pOverlayHeight / 2)) into tOverlayTop
         
         break
      case "NorthEast"
         put sImageA["origWidth"] - pOverlayWidth into tOverlayLeft
         put 0 into tOverlayTop
         
         break
      case "SouthEast"
         put sImageA["origWidth"] - pOverlayWidth into tOverlayLeft
         put sImageA["origHeight"] - pOverlayHeight into tOverlayTop
         
         break
      case "SouthWest"
         put 0 into tOverlayLeft
         put sImageA["origHeight"] - pOverlayHeight into tOverlayTop
         
         break
      case "NorthWest"
         put 0 into tOverlayLeft
         put 0 into tOverlayTop
         
         break
      case "Center"
         put (sImageA["origWidth"] / 2) - (pOverlayWidth / 2) into tOverlayLeft
         put (sImageA["origHeight"] / 2) - (pOverlayHeight / 2) into tOverlayTop
         
         break
      default
         # SOUTH
         put (sImageA["origWidth"] / 2) - (pOverlayWidth / 2) into tOverlayLeft
         put sImageA["origHeight"] - pOverlayHeight into tOverlayTop
   end switch
   
   put round(min((sImageA["origWidth"] - pOverlayWidth), (tOverlayLeft + sImageA["WMhorOffset"]))) into tTopLeft["left"]
   put round(min((sImageA["origHeight"] - pOverlayHeight), (tOverlayTop + sImageA["WMvrtOffset"]))) into tTopLeft["top"]
   
   return tTopLeft
end _rigWatermarkTopLeft







/*----------------------------------------------------------------------
--| COMMAND _rigSaveTheImage
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-02-2014
--| Last Mod: 10-02-2014
--| Requires: --
--|
--| Summary: Store the modified image on disk.
--| 
--| Format:  _rigSaveTheImage param 1
--|
--| Parameters: string <pObject> object to save as image
--|
--| Return: empty
----------------------------------------------------------------------------*/

private command _rigSaveTheImage pObject
  # CHECK IF WE ARE DEALING WITH AN IMAGE OR A GROUP
  if  "group" is in pObject then
    # EXPORT SNAPSHOT OF A GROUP
    switch sImageA["exportFormat"]
      case "PNG"
        export snapshot from pObject to  file sImageA["fullDstPath"] as PNG
      break
      case "GIF"
        export snapshot from pObject to file sImageA["fullDstPath"] as GIF
      break
      default
        export snapshot from pObject to  file sImageA["fullDstPath"] as JPEG
    end switch
      
  else
    # EXPORT IMAGE
    switch sImageA["exportFormat"]
      case "PNG"
        export image sImageA["newImageObject"] to file sImageA["fullDstPath"] as PNG
      break
      case "GIF"
        export image sImageA["newImageObject"] to file sImageA["fullDstPath"] as GIF
      break
      default
      export image sImageA["newImageObject"] to file sImageA["fullDstPath"] as JPEG
    end switch
  end if
end _rigSaveTheImage





/*----------------------------------------------------------------------
--| FUNCTION rigImageGet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-02
--| Last Mod: 2019-01-02
--| Requires: --
--|
--| Summary: Get image array variable value.
--| 
--| Format:  rigImageGet(param)
--|
--| Parameters: string <pWhat>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigImageGet pWhat
  if pWhat is among the keys of sImageA then
    return sImageA[pWhat]
  end if
   
  return empty
end rigImageGet




/*----------------------------------------------------------------------
--| COMMAND rigImageSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-01-02
--| Last Mod: 2019-01-02
--| Requires: --
--|
--| Summary: Setter for image variables.
--| 
--| Format:  rigImageSet param1, param2
--|
--| Parameters: string <pKey> sImageA array key, mixed <pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigImageSet pKey pVal
  if pKey is among the keys of sImageA then
    put pVal into sImageA[pKey]
  end if
end rigImageSet








--| END OF Image.livecodescript
--| Location:  ./system/libraries/Image.livecodescript
----------------------------------------------------------------------