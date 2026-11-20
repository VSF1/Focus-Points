--[[
  Original work © Whizzbang Inc
  Ongoing maintenance and modifications © 2026 Karsten Gieselmann

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
local KonicaMinoltaDelegates = {}

local DefaultDelegates = require 'DefaultDelegates'
local DefaultPointRenderer = require 'DefaultPointRenderer'
local ExifUtils = require 'ExifUtils'
local FocusInfo = require 'FocusInfo'
local Utils = require 'Utils'

-- AF point centers for the Dynax 7D image dimensions (3008 x 2000).
local afPoints = {
  { "Top-left", 867, 740 },
  { "Top", 1504, 683 },
  { "Top-right", 2150, 740 },
  { "Left", 1204, 1000 },
  { "Center", 1504, 1000 },
  { "Right", 1804, 1000 },
  { "Bottom-left", 867, 1270 },
  { "Bottom", 1504, 1317 },
  { "Bottom-right", 2150, 1270 },
}

function KonicaMinoltaDelegates.modelSupported(model)
  model = string.lower(model or "")
  return model == "dynax 7d" or model == "maxxum 7d" or model == "7d"
end

function KonicaMinoltaDelegates.makerNotesFound(_photo, metadata)
  return ExifUtils.findFirstMatchingValue(metadata, {
    "AF Points", "AF Point Selected", "AFPointSelected", "AF Point", "Subject Area",
  }) ~= nil
end

function KonicaMinoltaDelegates.manualFocusUsed(_photo, metadata)
  local focusMode = ExifUtils.findFirstMatchingValue(metadata, { "Focus Mode" })
  return focusMode == "Manual" or focusMode == "MF"
end

local function parseNames(value)
  if not value then return {} end
  value = string.gsub(value, ";", ",")
  local names = Utils.splitTrim(value, ",")
  for index, name in ipairs(names) do
    names[index] = string.lower(name)
  end
  return names
end

function KonicaMinoltaDelegates.getAfPoints(photo, metadata)
  local width, height = DefaultPointRenderer.getNormalizedDimensions(photo, metadata)
  local selected = parseNames(ExifUtils.findFirstMatchingValue(metadata, {
    "AF Point Selected", "AFPointSelected",
  }))
  local inFocus = parseNames(ExifUtils.findFirstMatchingValue(metadata, { "AF Points" }))
  local result = {
    pointTemplates = DefaultDelegates.pointTemplates,
    points = {},
  }

  for _, point in ipairs(afPoints) do
    local name = string.lower(point[1])
    local isSelected = Utils.arrayKeyOf(selected, name) ~= nil
    local isInFocus = Utils.arrayKeyOf(inFocus, name) ~= nil
    local pointType = DefaultDelegates.POINTTYPE_AF_INACTIVE
    if isInFocus then
      pointType = DefaultDelegates.POINTTYPE_AF_FOCUS_BOX
      FocusInfo.focusPointsDetected = true
    elseif isSelected then
      pointType = DefaultDelegates.POINTTYPE_AF_SELECTED
      FocusInfo.focusPointsDetected = true
    end
    table.insert(result.points, {
      pointType = pointType,
      x = point[2] * width / 3008,
      y = point[3] * height / 2000,
      width = width * 0.0206,
      height = height * 0.031,
    })
  end

  local subjectArea = ExifUtils.findValue(metadata, "Subject Area")
  local x, y, areaWidth, areaHeight
  if subjectArea then
    local values = Utils.splitTrim(subjectArea, " ")
    if #values >= 4 then
      x, y, areaWidth, areaHeight =
        tonumber(values[1]), tonumber(values[2]), tonumber(values[3]), tonumber(values[4])
    end
  end
  if x and y and areaWidth and areaHeight then
    table.insert(result.points, {
      pointType = DefaultDelegates.POINTTYPE_AF_SELECTED,
      x = x * width / 3008,
      y = y * height / 2000,
      width = areaWidth * width / 3008,
      height = areaHeight * height / 2000,
    })
    FocusInfo.focusPointsDetected = true
  end

  return result
end

return KonicaMinoltaDelegates
