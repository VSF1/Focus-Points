--[[
  Copyright 2016 Whizzbang Inc

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
--]]

--[[
  A collection of delegate functions to be passed into the DefaultPointRenderer
  for Pentax cameras. 
  
  **Note: 
  Unlike other point delegates, this point delegates shows all in-active focus points. I'm 
  not sure what the means for the other delegates. Perhaps I'll update them. Perhaps I'll update this file.

  Notes:
  * Back focus button sets AFPointsInFocus to 'None' regardless of point
    selection mode (sucks). AFPointSelected is set correctly with either button.
  * For phase detection AF, the coordinates taken from the point map represent 
    the center of each AF point.

  2017.03.29 - roguephysicist: works for Pentax K-50 with both phase and contrast detection
--]]

local LrStringUtils = import "LrStringUtils"
local LrErrors = import 'LrErrors'
require "Utils"

local focusPoints_7D = {
  {afs = "Top-left",        name = "Top-left",     altname = "",          d = { -4.5, -1.9}},
  {afs = "Top",             name = "Top",          altname = "",          d = {    0, -2.2}},
  {afs = "Top-right",       name = "Top-right",    altname = "",          d = {  4.5, -1.9}},

  {afs = "Left",            name = "Left",         altname = "",          d = { -2.1,    0}},
  {afs = "Center",          name = "Center",       altname = "",          d = {    0,    0}},
  {afs = "Right",           name = "Right",        altname = "",          d = {  2.1,    0}},
  
  {afs = "Bottom-left",     name = "Bottom-left",  altname = "",          d = { -4.5,  1.9}},
  {afs = "Bottom",          name = "Bottom",       altname = "",          d = {    0,  2.2}},
  {afs = "Bottom-right",    name = "Bottom-right", altname = "",          d = {  4.5,  1.9}}
}

local function axis_overlaps(head1, tail1, head2, tail2)
    return head1 >= head2 and head1 <= tail2 or
           head2 >= head1 and head2 <= tail1
end

local function rect_intersects(left, top, right, bottom, a, b, c, d)
    if type(a) == 'table' then
        -- Assume a is a rect table
        return rect_intersects(left, top, right, bottom,
                               a.left, a.top, a.right, a.bottom)
    end
    return axis_overlaps(left, right, a, c) and axis_overlaps(top, bottom, b, d)
end

KonicaMinoltaDelegates = {}

KonicaMinoltaDelegates.focusPointsMap = nil
KonicaMinoltaDelegates.focusPointDimen = nil

function KonicaMinoltaDelegates.getAfPoints(photo, metaData)
  local result = nil
  local focusMode = ExifUtils.findFirstMatchingValue(metaData, { "Focus Mode" })
  if focusMode == nil then
    --LrErrors.throwUserError("Could not determine the focus mode of the camera.")
	result = KonicaMinoltaDelegates.getAfPointsPhase(photo, metaData)
  else  
    focusMode = splitTrim(focusMode, " ")
    if focusMode[1] == "AF-A" or focusMode[1] == "AF-C" or focusMode[1] == "AF-S" then
      result = KonicaMinoltaDelegates.getAfPointsPhase(photo, metaData)
    elseif focusMode[1] == "Manual" then
      LrErrors.throwUserError("Manual focus: no useful focusing information found.")
    else
	  result = KonicaMinoltaDelegates.getAfPointsPhase(photo, metaData)
      --LrErrors.throwUserError("Could not determine the focus mode of the camera.")
    end
  end
  return result
end

--[[
-- photo - the photo LR object
-- metaData - the metadata as read by exiftool
--]]
function KonicaMinoltaDelegates.getAfPointsPhase(photo, metaData)
  local result = {
    pointTemplates = DefaultDelegates.pointTemplates,
    points = {}
  }
  
  local orgPhotoWidth, orgPhotoHeight, cropW, cropH = DefaultPointRenderer.getNormalizedDimensions(photo)
  local scaleX = orgPhotoWidth / cropW
  local scaleY = orgPhotoHeight / cropH
  local sizeR = 0.020 * orgPhotoWidth 
  local centerX = orgPhotoWidth / 2
  local centerY = orgPhotoHeight / 2
  local spacerH = orgPhotoWidth * 0.047
  local spacerV = orgPhotoWidth * 0.047
  local areaX = nil
  local areaY = nil
  local areaWidth = nil
  local areaHeight = nil
  local areaXS = nil
  local areaYS = nil
  local areaWS = nil
  local areaHS = nil
  
  -- Let's see if we used any Subject area dimensions
  local areaDimensionsStr = ExifUtils.findFirstMatchingValue(metaData, { "Subject Area" })
  if areaDimensionsStr == nil then
	logDebug ("Konica Minolta", "Subject Area not found")
  else
    local areaDimensions = split(areaDimensionsStr, " ")
    areaX = tonumber(LrStringUtils.trimWhitespace(areaDimensions[1]))
    areaY = tonumber(LrStringUtils.trimWhitespace(areaDimensions[2]))
    areaWidth = tonumber(LrStringUtils.trimWhitespace(areaDimensions[3]))
    areaHeight = tonumber(LrStringUtils.trimWhitespace(areaDimensions[4]))
    if areaWidth == nil or areaHeight == nil or areaX == nil or areaY == nil then
      logDebug ("Konica Minolta", "Subject Area coordinates not found")
    else 
      logDebug("Konica Minolta", "Subject Area dimentions: " .. areaWidth .. "x" .. areaHeight)
      logDebug("Konica Minolta", "Subject Area x offset: " .. areaX)
      logDebug("Konica Minolta", "Subject Area  y offset: " .. areaY)
     
	  -- by exif documentation
	  -- areaXS = (areaX - areaWidth / 2) * scaleX
	  -- areaYS = (areaY - areaHeight / 2) * scaleY
	  -- actual behaviour
	  areaXS = areaX * scaleX
	  areaYS = areaY * scaleY
	  areaWS = areaWidth * scaleX
	  areaHS = areaHeight * scaleY
      -- show the Subject area
      table.insert(result.points, {
        pointType = DefaultDelegates.POINTTYPE_AF_SELECTED,
        x = areaXS,
        y = areaYS,
        width = areaWS,
        height = areaHS
      })
    end
  end  
 
  local afPointsSelected = nil
  --ExifUtils.findFirstMatchingValue(metaData, { "AF Points" })
  if afPointsSelected == nil then
    afPointsSelected = {}
  else
    afPointsSelected = splitTrim(afPointsSelected, ",") --  separates with ';' ?
    afPointsSelected = KonicaMinoltaDelegates.fixCenter(afPointsSelected)
  end
  local afPointsInFocus = ExifUtils.findFirstMatchingValue(metaData, { "AF Points" })
  if afPointsInFocus == nil then
    afPointsInFocus = {}
  else
    afPointsInFocus = splitTrim(afPointsInFocus, ",")
    afPointsInFocus = KonicaMinoltaDelegates.fixCenter(afPointsInFocus)
  end
 
  local pdafWidth  = sizeR * scaleX
  local pdafHeight = sizeR * scaleY
-- dynamic adjustment
  local pdafPoints = focusPoints_7D
  for i=1, #pdafPoints do
    
    local key = pdafPoints[i].name
	local altkey = pdafPoints[i].altname
    local pointType = DefaultDelegates.POINTTYPE_AF_INACTIVE
    local isInFocus = arrayKeyOf(afPointsInFocus, key) ~= nil or arrayKeyOf(afPointsInFocus, altkey) ~= nil
    local isSelected = arrayKeyOf(afPointsSelected, key) ~= nil or arrayKeyOf(afPointsSelected, altkey) ~= nil
	local pdafX = (centerX + spacerH*pdafPoints[i].d[1]) * scaleX
	local pdafY = (centerY + spacerV*pdafPoints[i].d[2]) * scaleY

    logDebug("Konica Minolta", "Af Name " .. pdafPoints[i].afs .. " X:" .. pdafX .. " Y:" .. pdafY )	
	
	if not isSelected and areaX ~=nil then
		isSelected = rect_intersects(pdafX, pdafY, pdafX + pdafWidth, pdafY + pdafHeight, areaXS, areaYS, areaXS + areaWS, areaYS + areaHS)
	end 

    if isInFocus and isSelected then
      pointType = DefaultDelegates.POINTTYPE_AF_SELECTED_INFOCUS
    elseif isInFocus then
      pointType = DefaultDelegates.POINTTYPE_AF_INFOCUS
    elseif isSelected then
      pointType = DefaultDelegates.POINTTYPE_AF_SELECTED
    end

    table.insert(result.points, {
      pointType = pointType,
      x = pdafX,
      y = pdafY,
      width = pdafWidth,
      height = pdafHeight
    })	
  end
  
--[[ static adjustment
  for key,value in pairs(KonicaMinoltaDelegates.focusPointsMap) do
	local pointsMap = KonicaMinoltaDelegates.focusPointsMap[key]
	--logDebug("Konica Minolta", "Key: " .. key .. " Value: " .. value)
	local x = tonumber(pointsMap[1])
    local y = tonumber(pointsMap[2])
    local width
    local height
    if (#pointsMap > 2) then 
      width = pointsMap[3] 
      height = pointsMap[4]
    else 
      width = KonicaMinoltaDelegates.focusPointDimen[1]
      height = KonicaMinoltaDelegates.focusPointDimen[2]
    end
    
    local pointType = DefaultDelegates.POINTTYPE_AF_INACTIVE
    local isInFocus = arrayKeyOf(afPointsInFocus, key) ~= nil
    local isSelected = arrayKeyOf(afPointsSelected, key) ~= nil
	
	if not isSelected and areaX ~=nil then
		isSelected = rect_intersects(x,y,x + width, y + height, areaX, areaY, areaX + areaWidth, areaY + areaHeight)
	end 

    if isInFocus and isSelected then
      pointType = DefaultDelegates.POINTTYPE_AF_SELECTED_INFOCUS
    elseif isInFocus then
      pointType = DefaultDelegates.POINTTYPE_AF_INFOCUS
    elseif isSelected then
      pointType = DefaultDelegates.POINTTYPE_AF_SELECTED
    end
	
    table.insert(result.points, {
      pointType = pointType,
      x = x,
      y = y,
      width = width,
      height = height
    })
    
  end
--]]
  
  return result
end

function KonicaMinoltaDelegates.fixCenter(points)
  for k,v in pairs(points) do
    if v == 'Center (vertical)' or v == 'Center (horizontal)' or v == 'Fixed Center' then
      points[k] = 'Center'
    end
  end
  return points
end

