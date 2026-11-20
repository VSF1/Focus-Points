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
  A collection of delegate functions to be passed into the DefaultPointRenderer when
  the camera is Sony
--]]

local LrStringUtils = import "LrStringUtils"
require "Utils"

-- Sony says PDAF covers approximately 68% of the sensor
-- a7r3 images are 7952x5304 pixels, 3:2
-- sensor is 42 MP, 68% of which is 28,680,637.44
-- Focal Plane AF Point Area value is "640 428"
-- 640 * 428 * 10^2 == 27,392,000
-- 6400x4280, margins - left/right 776, top/bottom 512

local pdafScale = 10 -- this is a guess
local focusLocationSize = 120
local pdafPointSize = 85

local focusPoints_a900 = {
  {afs = "AF Status Center F2-8",            name = "Center F2-8",         altname = "Center",       d = {    0,    0}},
  {afs = "AF Status Center-10",              name = "Center (10)",         altname = "Center",       d = {    0,    0}},
  {afs = "AF Status Center-11",              name = "Center (11)",         altname = "Center",       d = {    0,    0}},
  {afs = "AF Status Center-12",              name = "Center (12)",         altname = "Center",       d = {    0,    0}},
  {afs = "AF Status Center-14",              name = "Center (14)",         altname = "Center",       d = {    0,    0}},
  {afs = "AF Status Center-7",               name = "Center (7)",          altname = "Center",       d = {    0,    0}},
  {afs = "AF Status Center-9",               name = "Center (9)",          altname = "Center",       d = {    0,    0}},
  {afs = "AF Status Center-horizontal",      name = "Center (horizontal)", altname = "Center",       d = {    0,    0}},
  {afs = "AF Status Center-vertical",        name = "Center (vertical)",   altname = "Center",       d = {    0,    0}},
  
  {afs = "AF Status Bottom",                 name = "Bottom",              altname = "Bottom",       d = {    0,    2}},
  {afs = "AF Status Bottom Assist-left",     name = "Bottom Assist-left",  altname = "",             d = {   -1,   2}},
  {afs = "AF Status Bottom Assist-right",    name = "Bottom Assist-right", altname = "",             d = {    1,   2}},
  
  {afs = "AF Status Top",                    name = "Top",                 altname = "Top",          d = {    0,   -2}},
  {afs = "AF Status Top Assist-left",        name = "Top Assist-left",     altname = "",             d = {   -1,   -2}},
  {afs = "AF Status Top Assist-right",       name = "Top Assist-right",    altname = "",             d = {    1,   -2}},
  
  {afs = "AF Status Far Left",               name = "Far Left",            altname = "Far Left",     d = {   -5,    0}},
  {afs = "AF Status Far Right",              name = "Far Right",           altname = "Far Right",    d = {    5,    0}},
  {afs = "AF Status Left",                   name = "Left",                altname = "Left",         d = { -3.5,    0}},
  {afs = "AF Status Lower-left",             name = "Lower-left",          altname = "",             d = { -3.5,  1.6}},
  {afs = "AF Status Lower-right",            name = "Lower-right",         altname = "",             d = {  3.5,  1.6}},
  {afs = "AF Status Right",                  name = "Right",               altname = "Right",        d = {  3.5,    0}},
  {afs = "AF Status Upper-left",             name = "Upper-left",          altname = "",             d = { -3.5, -1.6}},
  {afs = "AF Status Upper-right",            name = "Upper-right",         altname = "",             d = {  3.5, -1.6}}
}
local focusPoints_15 = {
  {afs = "AF Status Center Horizontal",      name = "Center (horizontal)", altname = "Center",       d = {    0,    0}},
  {afs = "AF Status Center Vertical",        name = "Center (vertical)",   altname = "Center",       d = {    0,    0}},
  {afs = "AF Status Bottom Horizontal",      name = "Bottom (horizontal)", altname = "Bottom",       d = {    0,    2}},
  {afs = "AF Status Bottom Vertical",        name = "Bottom (vertical)",   altname = "Bottom",       d = {    0,    2}},
  {afs = "AF Status Top Horizontal",         name = "Top (horizontal)",    altname = "Top",          d = {    0,   -2}},
  {afs = "AF Status Top Vertical",           name = "Top (vertical)",      altname = "Top",          d = {    0,   -2}},
  {afs = "AF Status Lower-middle",           name = "Lower-middle",        altname = "Lower-middle", d = {    0,    1}},
  {afs = "AF Status Upper-middle",           name = "Upper-middle",        altname = "Upper-middle", d = {    0,   -1}},
  {afs = "AF Status Near Left",              name = "Near Left",           altname = "Near Left",    d = {   -1,    0}},
  {afs = "AF Status Near Right",             name = "Near Right",          altname = "Near Right",   d = {    1,    0}},
  {afs = "AF Status Left",                   name = "Left",                altname = "Left",         d = { -3.5,    0}},
  {afs = "AF Status Right",                  name = "Right",               altname = "Right",        d = {  3.5,    0}},
  {afs = "AF Status Lower-left",             name = "Lower-left",          altname = "",             d = { -3.5,  1.6}},
  {afs = "AF Status Lower-right",            name = "Lower-right",          altname = "",            d = {  3.5,  1.6}},
  {afs = "AF Status Upper-left",             name = "Upper-left",          altname = "",             d = { -3.5, -1.6}},
  {afs = "AF Status Upper-right",            name = "Upper-right",         altname = "",             d = {  3.5, -1.6}},
  {afs = "AF Status Far Left",               name = "Far Left",            altname = "Far Left",     d = {   -5,    0}},
  {afs = "AF Status Far Right",              name = "Far Right",           altname = "Far Right",    d = {    5,    0}}
}
local focusPoints_19 = {
  {afs = "AF Status Center Horizontal",      name = "Center (horizontal)", altname = "Center",       d = {    0,    0}},
  {afs = "AF Status Center Vertical",        name = "Center (vertical)",   altname = "Center",       d = {    0,    0}},
  {afs = "AF Status Bottom Horizontal",      name = "Bottom (horizontal)", altname = "Bottom",       d = {    0,    2}},
  {afs = "AF Status Bottom Vertical",        name = "Bottom (vertical)",   altname = "Bottom",       d = {    0,    2}},
  {afs = "AF Status Top Horizontal",         name = "Top (horizontal)",    altname = "Top",          d = {    0,   -2}},
  {afs = "AF Status Top Vertical",           name = "Top (vertical)",      altname = "Top",          d = {    0,   -2}},
  {afs = "AF Status Lower-middle",           name = "Lower-middle",        altname = "Lower-middle", d = {    0,    1}},
  {afs = "AF Status Upper-middle",           name = "Upper-middle",        altname = "Upper-middle", d = {    0,   -1}},
  {afs = "AF Status Near Left",              name = "Near Left",           altname = "Near Left",    d = {   -1,    0}},
  {afs = "AF Status Near Right",             name = "Near Right",          altname = "Near Right",   d = {    1,    0}},
  {afs = "AF Status Left Horizontal",        name = "Left",                altname = "Left",         d = { -3.5,    0}},
  {afs = "AF Status Left Vertical",          name = "Left",                altname = "Left",         d = { -3.5,    0}},
  {afs = "AF Status Right Horizontal",       name = "Right",               altname = "Right",        d = {  3.5,    0}},
  {afs = "AF Status Right Vertical",         name = "Right",               altname = "Right",        d = {  3.5,    0}},
  {afs = "AF Status Lower-left Horizontal",  name = "Lower-left",          altname = "Lower-left",   d = { -3.5,  1.6}},
  {afs = "AF Status Lower-left Vertical",    name = "Lower-left",          altname = "Lower-left",   d = { -3.5,  1.6}},
  {afs = "AF Status Lower-right Horizontal", name = "Lower-right",         altname = "Lower-right",  d = {  3.5,  1.6}},
  {afs = "AF Status Lower-right Vertical",   name = "Lower-right",         altname = "Lower-right",  d = {  3.5,  1.6}},
  {afs = "AF Status Upper-left Horizontal",  name = "Upper-left",          altname = "Upper-left",   d = { -3.5, -1.6}},
  {afs = "AF Status Upper-left Vertical",    name = "Upper-left",          altname = "Upper-left",   d = { -3.5, -1.6}},
  {afs = "AF Status Upper-right Horizontal", name = "Upper-right",         altname = "Upper-right",  d = {  3.5, -1.6}},
  {afs = "AF Status Upper-right Vertical",   name = "Upper-right",         altname = "Upper-right",  d = {  3.5, -1.6}},
  {afs = "AF Status Upper Far Left",         name = "Upper Far Left",      altname = "",             d = { -4.5, -1.6}},
  {afs = "AF Status Lower Far Left",         name = "Lower Far Left",      altname = "",             d = { -4.5,  1.6}},
  {afs = "AF Status Upper Far Right",        name = "Upper Far Right",     altname = "",             d = {  4.5, -1.6}},
  {afs = "AF Status Lower Far Right",        name = "Lower Far Right",     altname = "",             d = {  4.5,  1.6}},
  {afs = "AF Status Far Left Horizontal",    name = "Far Left",            altname = "",             d = {   -5,    0}},
  {afs = "AF Status Far Left Vertical",      name = "Far Left",            altname = "",             d = {   -5,    0}},
  {afs = "AF Status Far Right Horizontal",   name = "Far Right",           altname = "",             d = {    5,    0}},
  {afs = "AF Status Far Right Vertical",     name = "Far Right",           altname = "",             d = {    5,    0}}
}
local focusPoints_79 = {
-- Center
  {afs = "E6",                               name = "E6",                  altname = "E6 (Center)",  d = {    0,    0}},
  {afs = "D6",                               name = "D6",                  altname = "",             d = {    0,   -1}},
  {afs = "F6",                               name = "F6",                  altname = "",             d = {    0,    1}},
  {afs = "C6",                               name = "C6",                  altname = "",             d = {    0,   -2}},
  {afs = "G6",                               name = "G6",                  altname = "",             d = {    0,    2}},
  {afs = "B6",                               name = "B6",                  altname = "",             d = {    0,   -3}},
  {afs = "H6",                               name = "H6",                  altname = "",             d = {    0,    3}},
  {afs = "A6",                               name = "A6",                  altname = "",             d = {    0,   -4}},
  {afs = "I6",                               name = "I6",                  altname = "",             d = {    0,    4}},
  
  {afs = "E5",                               name = "E5",                  altname = "",             d = {   -1,    0}},
  {afs = "D5",                               name = "D5",                  altname = "",             d = {   -1,   -1}},
  {afs = "F5",                               name = "F5",                  altname = "",             d = {   -1,    1}},
  {afs = "C5",                               name = "C5",                  altname = "",             d = {   -1,   -2}},
  {afs = "G5",                               name = "G5",                  altname = "",             d = {   -1,    2}},
  {afs = "B5",                               name = "B5",                  altname = "",             d = {   -1,   -3}},
  {afs = "H5",                               name = "H5",                  altname = "",             d = {   -1,    3}},
  {afs = "A5",                               name = "A5",                  altname = "",             d = {   -1,   -4}},
  {afs = "I5",                               name = "I5",                  altname = "",             d = {   -1,    4}},
  
  {afs = "E7",                               name = "E7",                  altname = "",             d = {    1,    0}},
  {afs = "D7",                               name = "D7",                  altname = "",             d = {    1,   -1}},
  {afs = "F7",                               name = "F7",                  altname = "",             d = {    1,    1}},
  {afs = "C7",                               name = "C7",                  altname = "",             d = {    1,   -2}},
  {afs = "G7",                               name = "G7",                  altname = "",             d = {    1,    2}},
  {afs = "B7",                               name = "B7",                  altname = "",             d = {    1,   -3}},
  {afs = "H7",                               name = "H7",                  altname = "",             d = {    1,    3}},
  {afs = "A7",                               name = "A7",                  altname = "",             d = {    1,   -4}},
  {afs = "I7",                               name = "I7",                  altname = "",             d = {    1,    4}},
-- left 
  {afs = "E4",                               name = "E4",                  altname = "",             d = { -2.8,    0}},
  {afs = "F4",                               name = "F4",                  altname = "",             d = { -2.8,    1}},
  {afs = "D4",                               name = "D4",                  altname = "",             d = { -2.8,   -1}},
  {afs = "C4",                               name = "C4",                  altname = "",             d = { -2.8,   -2}},
  {afs = "G4",                               name = "G4",                  altname = "",             d = { -2.8,    2}},
  {afs = "B4",                               name = "B4",                  altname = "",             d = { -2.8,   -3}},
  {afs = "H4",                               name = "H4",                  altname = "",             d = { -2.8,    3}},
  
  {afs = "E3",                               name = "E3",                  altname = "",             d = { -3.7,    0}},
  {afs = "D3",                               name = "D3",                  altname = "",             d = { -3.7,   -1}},
  {afs = "F3",                               name = "F3",                  altname = "",             d = { -3.7,    1}},
  {afs = "C3",                               name = "C3",                  altname = "",             d = { -3.7,   -2}},
  {afs = "G3",                               name = "G3",                  altname = "",             d = { -3.7,    2}},
  {afs = "B3",                               name = "B3",                  altname = "",             d = { -3.7,   -3}},
  {afs = "H3",                               name = "H3",                  altname = "",             d = { -3.7,    3}},
  
  {afs = "E2",                               name = "E2",                  altname = "",             d = { -4.6,    0}},
  {afs = "D2",                               name = "D2",                  altname = "",             d = { -4.6,   -1}},
  {afs = "F2",                               name = "F2",                  altname = "",             d = { -4.6,    1}},
  {afs = "C2",                               name = "C2",                  altname = "",             d = { -4.6,   -2}},
  {afs = "G2",                               name = "G2",                  altname = "",             d = { -4.6,    2}},
  {afs = "B2",                               name = "B2",                  altname = "",             d = { -4.6,   -3}},
  {afs = "H2",                               name = "H2",                  altname = "",             d = { -4.6,    3}},

  {afs = "E1",                               name = "E1",                  altname = "",             d = { -5.5,    0}},
  {afs = "D1",                               name = "D1",                  altname = "",             d = { -5.5,   -1}},
  {afs = "F1",                               name = "F1",                  altname = "",             d = { -5.5,    1}},
  {afs = "C1",                               name = "C1",                  altname = "",             d = { -5.5,   -2}},
  {afs = "G1",                               name = "G1",                  altname = "",             d = { -5.5,    2}},
-- right
  {afs = "E8",                               name = "E8",                  altname = "",             d = {  2.8,    0}},
  {afs = "F8",                               name = "F8",                  altname = "",             d = {  2.8,    1}},
  {afs = "D8",                               name = "D8",                  altname = "",             d = {  2.8,   -1}},
  {afs = "C8",                               name = "C8",                  altname = "",             d = {  2.8,   -2}},
  {afs = "G8",                               name = "G8",                  altname = "",             d = {  2.8,    2}},
  {afs = "B8",                               name = "B8",                  altname = "",             d = {  2.8,   -3}},
  {afs = "H8",                               name = "H8",                  altname = "",             d = {  2.8,    3}},
  
  {afs = "E9",                               name = "E9",                  altname = "",             d = {  3.7,    0}},
  {afs = "D9",                               name = "D9",                  altname = "",             d = {  3.7,   -1}},
  {afs = "F9",                               name = "F9",                  altname = "",             d = {  3.7,    1}},
  {afs = "C9",                               name = "C9",                  altname = "",             d = {  3.7,   -2}},
  {afs = "G9",                               name = "G9",                  altname = "",             d = {  3.7,    2}},
  {afs = "B9",                               name = "B9",                  altname = "",             d = {  3.7,   -3}},
  {afs = "H9",                               name = "H9",                  altname = "",             d = {  3.7,    3}},
																										    
  {afs = "E10",                              name = "E10",                 altname = "",             d = {  4.6,    0}},
  {afs = "D10",                              name = "D10",                 altname = "",             d = {  4.6,   -1}},
  {afs = "F10",                              name = "F10",                 altname = "",             d = {  4.6,    1}},
  {afs = "C10",                              name = "C10",                 altname = "",             d = {  4.6,   -2}},
  {afs = "G10",                              name = "G10",                 altname = "",             d = {  4.6,    2}},
  {afs = "B10",                              name = "B10",                 altname = "",             d = {  4.6,   -3}},
  {afs = "H10",                              name = "H10",                 altname = "",             d = {  4.6,    3}},
																										    
  {afs = "E11",                              name = "E11",                 altname = "",             d = {  5.5,    0}},
  {afs = "D11",                              name = "D11",                 altname = "",             d = {  5.5,   -1}},
  {afs = "F11",                              name = "F11",                 altname = "",             d = {  5.5,    1}},
  {afs = "C11",                              name = "C11",                 altname = "",             d = {  5.5,   -2}},
  {afs = "G11",                              name = "G11",                 altname = "",             d = {  5.5,    2}}
}

SonyDelegates = {}
SonyDelegates.metaKeyAfPointSelected = { "AF Points Selected", "AF Point Selected" }
SonyDelegates.metaKeyAfPointUsed = { "AF Points Used", "AF Point In Focus", "AF Point" }


--[[
-- metaData - the metadata as read by exiftool
--]]

function SonyDelegates.getAfPoints(photo, metaData)
  local result = {
    pointTemplates = DefaultDelegates.pointTemplates,
    points = {}
  }
  
  local a = nil
  local c = SonyDelegates.getAfPointsNew(photo, metaData)
  if c == nil then
	a = SonyDelegates.getAfPointsILC(photo, metaData)
  end
  local b = SonyDelegates.getAfPointsMILC(photo, metaData)
  

  if a ~= nil then
	for _,v in ipairs(a.points) do 
		table.insert(result.points, v)
	end
  end
  if b ~= nil then
	for _,v in ipairs(b.points) do 
		table.insert(result.points, v)
	end
  end
  if c ~= nil then
	for _,v in ipairs(c.points) do 
		table.insert(result.points, v)
	end
  end
  return result
end 

-- DSLR and SLT
function SonyDelegates.getAfPointsILC(photo, metaData)
  local afPointsSelected = ExifUtils.findFirstMatchingValue(metaData, SonyDelegates.metaKeyAfPointSelected)
  
  if afPointsSelected == nil then
    afPointsSelected = {}
  else
    afPointsSelected = splitTrim(afPointsSelected, ";") --  separates with ';' ?
    afPointsSelected = SonyDelegates.fixCenter(afPointsSelected)
  end
  if (#afPointsSelected > 1) then
    logDebug("getAfPointsILC","afPointSelected " .. afPointsSelected[1])
  end
  local afPointsInFocus = ExifUtils.findFirstMatchingValue(metaData, SonyDelegates.metaKeyAfPointUsed)
  if afPointsInFocus == nil then
    afPointsInFocus = {}
  else
    afPointsInFocus = splitTrim(afPointsInFocus, ",")
    afPointsInFocus = SonyDelegates.fixCenter(afPointsInFocus)
  end
  if (#afPointsInFocus > 1) then
	logDebug("getAfPointsILC","afPointsInFocus " .. afPointsInFocus[1])
  end
  local result = {
    pointTemplates = DefaultDelegates.pointTemplates,
    points = {}
  }

  logDebug("getAfPointsILC", DefaultDelegates.focusPointsMap)
  if DefaultDelegates.focusPointsMap == nil or #DefaultDelegates.focusPointsMap < 1 then
	return nil
  end
  
  for key,value in pairs(DefaultDelegates.focusPointsMap) do
      local pointsMap = DefaultDelegates.focusPointsMap[key]
      local x = pointsMap[1]
      local y = pointsMap[2]
      local width
      local height
      if (#pointsMap > 2) then 
        width = pointsMap[3] 
        height = pointsMap[4]
      else 
        width = DefaultDelegates.focusPointDimen[1]
        height = DefaultDelegates.focusPointDimen[2]
      end
    
      local pointType = DefaultDelegates.POINTTYPE_AF_INACTIVE
      local isInFocus = arrayKeyOf(afPointsInFocus, key) ~= nil
      local isSelected = arrayKeyOf(afPointsSelected, key) ~= nil
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
    
	logDebug("getAfPointsILC", "POINTTYPE" .. pointType)
    end
  return result
end


function SonyDelegates.getAfPointsMILC(photo, metaData)
  logDebug("MILC",a) 
  local focusPoint = ExifUtils.findFirstMatchingValue(metaData, { "Focus Location" })
  if focusPoint == nil then
    return nil
  end
  local values = split(focusPoint, " ")
  local imageWidth = LrStringUtils.trimWhitespace(values[1])
  local imageHeight = LrStringUtils.trimWhitespace(values[2])
  local x = LrStringUtils.trimWhitespace(values[3])
  local y = LrStringUtils.trimWhitespace(values[4])
  if imageWidth == nil or imageHeight == nil or x == nil or y == nil then
    return nil
  end

  local orgPhotoWidth, orgPhotoHeight = DefaultPointRenderer.getNormalizedDimensions(photo)
  local scale_x = orgPhotoWidth / imageWidth
  local scale_y = orgPhotoHeight / imageHeight
  local r_size = orgPhotoWidth * 0.039
  
  local afType = ExifUtils.findFirstMatchingValue(metaData, { "AF Type"})
  if afType == "79-point" then
	r_size = 0.020 * orgPhotoWidth * 1.5
  end

  logInfo("Sony", "Focus location at [" .. math.floor(x * scale_x) .. ", " .. math.floor(y * scale_y) .. "]")

  local result = {
    pointTemplates = DefaultDelegates.pointTemplates,
    points = {
      {
        pointType = DefaultDelegates.POINTTYPE_AF_SELECTED_INFOCUS,
        x = x * scale_x,
        y = y * scale_y,
        width = r_size * scale_y,
        height = r_size * scale_y
      }
    }
  }

  -- Let's see if we used any PDAF points
  local numPdafPointsStr = ExifUtils.findFirstMatchingValue(metaData, { "Focal Plane AF Points Used" })
  if numPdafPointsStr == nil then
    return result
  end
  local numPdafPoints = LrStringUtils.trimWhitespace(numPdafPointsStr)
  if numPdafPoints == nil then
    return result
  end
  logDebug("Sony", "PDAF AF points used: " .. numPdafPoints)

  local pdafDimensionsStr = ExifUtils.findFirstMatchingValue(metaData, { "Focal Plane AF Point Area" })
  if pdafDimensionsStr == nil then
    return result
  end
  local pdafDimensions = split(pdafDimensionsStr, " ")
  local pdafWidth = LrStringUtils.trimWhitespace(pdafDimensions[1])
  local pdafHeight = LrStringUtils.trimWhitespace(pdafDimensions[2])
  if pdafWidth == nil or pdafHeight == nil then
    return result
  end
  logDebug("Sony", "PDAF AF area dimentions: " .. pdafWidth .. "x" .. pdafHeight)
  logDebug("Sony", "PDAF scale: " .. pdafScale)
  local pdafScaledWidth = pdafWidth * pdafScale
  logDebug("Sony", "PDAF scaled width: " .. pdafScaledWidth)
  local pdafScaledHeight = pdafHeight * pdafScale
  logDebug("Sony", "PDAF scaled height: " .. pdafScaledHeight)
  local pdafXOffset = (imageWidth - pdafScaledWidth) / 2
  logDebug("Sony", "PDAF x offset: " .. pdafXOffset)
  local pdafYOffset = (imageHeight - pdafScaledHeight) / 2
  logDebug("Sony", "PDAF y offset: " .. pdafYOffset)

  -- show the PDAF area
  table.insert(result.points, {
    pointType = DefaultDelegates.POINTTYPE_AF_INACTIVE,
    x = pdafXOffset + (pdafScaledWidth / 2),
    y = pdafYOffset + (pdafScaledHeight / 2),
    width = pdafScaledWidth,
    height = pdafScaledHeight
  })

  for i=1, numPdafPoints do
    local pdafPointStr = ExifUtils.findFirstMatchingValue(metaData, { "Focal Plane AF Point Location " .. i })
    if pdafPointStr == nil then
      return result
    end
    local pdafPoint = split(pdafPointStr, " ")
    local x = LrStringUtils.trimWhitespace(pdafPoint[1])
    local y = LrStringUtils.trimWhitespace(pdafPoint[2])
    if x == nil or y == nil then
      return result
    end
    logDebug("Sony", "PDAF unscaled point at [" .. x .. ", " .. y .. "]")
    local pdafX = (pdafXOffset + (x * pdafScale)) * scale_x
    local pdafY = (pdafYOffset + (y * pdafScale)) * scale_y
    logInfo("Sony", "PDAF point at [" .. math.floor(pdafX) .. ", " .. math.floor(pdafY) .. "]")
    table.insert(result.points, {
      pointType = DefaultDelegates.POINTTYPE_AF_INACTIVE,
      x = pdafX,
      y = pdafY,
      width = pdafPointSize * scale_x,
      height = pdafPointSize * scale_y
    })
  end

  return result
end

function SonyDelegates.fixCenter(points)
  for k,v in pairs(points) do
    logDebug("Sony", "AF Points:" .. v)
    if v == 'Center (vertical)' or v == 'Center (horizontal)' or v == 'Fixed Center' then
      points[k] = 'Center' 
	  logDebug("Sony", "Fixed " .. k .. " -> " .. v)
    elseif v == 'E6 (Center)' or v == 'E6 Center' then
		logDebug("Sony", "Fixed " .. k .. " -> " .. v)
		points[k] = 'E6' 
	end
  end
  return points
end


function SonyDelegates.getAfPointsNew(photo, metaData) 
  local cameraModelName = ExifUtils.findFirstMatchingValue(metaData, { "Camera Model Name"})
  logDebug("Sony", "Camera Model Name: " .. cameraModelName)  
  local afType = ExifUtils.findFirstMatchingValue(metaData, { "AF Type"})
  if afType == nil then   
	afType = "Unknown" 
  end

  local afPointsSelected = ExifUtils.findFirstMatchingValue(metaData, SonyDelegates.metaKeyAfPointSelected)  
  if afPointsSelected == nil then
    afPointsSelected = {}
  else
    afPointsSelected = splitTrim(afPointsSelected, ",") 
    afPointsSelected = SonyDelegates.fixCenter(afPointsSelected)
  end
  if (#afPointsSelected > 1) then
    logDebug("Sony","afPointSelected " .. afPointsSelected[1])
  end
  
  local afPointsInFocus = ExifUtils.findFirstMatchingValue(metaData, SonyDelegates.metaKeyAfPointUsed)
  if afPointsInFocus == nil then
    afPointsInFocus = {}
  else
    afPointsInFocus = splitTrim(afPointsInFocus, ",")
    afPointsInFocus = SonyDelegates.fixCenter(afPointsInFocus)
  end
	
  logDebug("Sony", "Af Type: " .. afType)

  local orgPhotoWidth, orgPhotoHeight, cropW, cropH = DefaultPointRenderer.getNormalizedDimensions(photo)
  
  logDebug("Sony", "Width: " .. cropW)
  logDebug("Sony", "Height: " .. cropH)
  
  local scale_x = orgPhotoWidth / cropW
  local scale_y = orgPhotoHeight / cropH
  local r_size = orgPhotoWidth * 0.039
  local x_center = orgPhotoWidth / 2
  local y_center = orgPhotoHeight / 2
  local h_spacer = orgPhotoWidth * 0.047
  local v_spacer = orgPhotoWidth * 0.047
  local afPoints = nil
	
  if cameraModelName == "DSLR-A900" then
    afPoints = focusPoints_a900
  elseif afType == "15-point" then
    afPoints = focusPoints_15
  elseif afType == "19-point" then
      afPoints = focusPoints_19
  elseif afType == "79-point" then
    afPoints = focusPoints_79
	r_size = 0.020 * orgPhotoWidth * 1.5
	v_spacer = 1.2 * r_size
	h_spacer = 2.2 * r_size
  else
    return nil
  end  
  
  local result = {
    pointTemplates = DefaultDelegates.pointTemplates,
    points = {}
  }
  
  for i=1, #afPoints do
    --logDebug("Sony", "Af Name " .. afPoints[i].afs .. " X:" .. (x_center + spacer*afPoints[i].d[1]) * scale_x .. " Y:" .. (x_center + spacer*afPoints[i].d[2]) * scale_y)
    local key = afPoints[i].name
	local altkey = afPoints[i].altname
    local pointType = DefaultDelegates.POINTTYPE_AF_INACTIVE
    local isInFocus = arrayKeyOf(afPointsInFocus, key) ~= nil or arrayKeyOf(afPointsInFocus, altkey) ~= nil
    local isSelected = arrayKeyOf(afPointsSelected, key) ~= nil or arrayKeyOf(afPointsSelected, altkey) ~= nil
    if isInFocus and isSelected then
      pointType = DefaultDelegates.POINTTYPE_AF_SELECTED_INFOCUS
    elseif isInFocus then
      pointType = DefaultDelegates.POINTTYPE_AF_INFOCUS
    elseif isSelected then
      pointType = DefaultDelegates.POINTTYPE_AF_SELECTED
    end

    table.insert(result.points, {
      pointType = pointType,
      x = (x_center + h_spacer*afPoints[i].d[1]) * scale_x,
      y = (y_center + v_spacer*afPoints[i].d[2]) * scale_y,
      width = r_size * scale_x,
      height = r_size * scale_y
    })	
  end
  return result
end