---@diagnostic disable-next-line: undefined-global
local HS = hs

local utils = require("utils");
local dbg = require("dbg");
local constants = require("constants");
local windowBorder = require("window-border");
local functions = require("functions");
--local TAGS = require("tags");


-- Next and prev window should be next and prev in column of group
--  if already at top or bottom, then next win actual window list
--
--  ALSO just sort groups y first for next and prev column -.-
--  (jk for sort by y with no x intersects)
--  (hl for sort by x with no y intersects)
--
--  FIGURE OUT HOW TO ACTUALLY GET THE WINDOW ON THE SIDE
--    then get a random window that is side-ish


-- FEATURE LIST:
--   x next window
--   x next column
--   x next group
--   - move window in groups
--   - move groups
--   - window out of group horizontal
--   - window out of group vertical
--   - carve window onto group
--   - tags
--   - make it fennel?
--   - done?


local function nextWindow()
  local windowToFocus = functions.getNextWindowBy(1)
  utils.focusWindow(windowToFocus)
end

local function prevWindow()
  local windowToFocus = functions.getNextWindowBy(-1)
  utils.focusWindow(windowToFocus)
end

local function stackGroup()
  local focusedWindow = HS.window.focusedWindow()
  local groupFrame = utils.getGroupFrameOf(focusedWindow:frame())
  local expandedFrame = utils.expandFrame(groupFrame)
  local paddedFrame = utils.padFrame(expandedFrame, constants.GAP)
  functions.stackWindows(paddedFrame)
end

local function visualizeFrames()
  local frames = utils.getAllColumnFrames()
  dbg.drawBorders(frames)
end


local function nextSideGroup()
  local groupFrameToFocus = functions.getSideGroupBy(1)
  utils.focusTopWindowInFrame(groupFrameToFocus)
end

local function prevSideGroup()
  local groupFrameToFocus = functions.getSideGroupBy(-1)
  utils.focusTopWindowInFrame(groupFrameToFocus)
end

local function moveWindowToNextGroup()
  local focusedWindow = HS.window.focusedWindow()
  local nextGroup = functions.getNextGroupBy(1)
  utils.setWindowFrame(focusedWindow, nextGroup)
end

local function moveWindowToPrevGroup()
  local focusedWindow = HS.window.focusedWindow()
  local prevGroup = functions.getNextGroupBy(-1)
  utils.setWindowFrame(focusedWindow, prevGroup)
end

local function moveWindowToNextSideGroup()
  local focusedWindow = HS.window.focusedWindow()
  local nextGroup = functions.getSideGroupBy(1)
  utils.setWindowFrame(focusedWindow, nextGroup)
end

local function moveWindowToPrevSideGroup()
  local focusedWindow = HS.window.focusedWindow()
  local nextGroup = functions.getSideGroupBy(-1)
  utils.setWindowFrame(focusedWindow, nextGroup)
end

local function nothing() end

HS.hotkey.bind({"cmd"}, "H", nothing)
HS.hotkey.bind({"shift", "ctrl"}, "J", nextWindow)
HS.hotkey.bind({"shift", "ctrl"}, "K", prevWindow)
HS.hotkey.bind({"shift", "ctrl"}, "H", prevSideGroup)
HS.hotkey.bind({"shift", "ctrl"}, "L", nextSideGroup)
HS.hotkey.bind({"shift", "ctrl"}, "S", stackGroup)
HS.hotkey.bind({"shift", "ctrl"}, "D", visualizeFrames)


-- ## move mode ##
local moveMode = HS.hotkey.modal.new({"shift","ctrl"}, "M")

--function moveMode:entered() HS.alert.show("move mode", 0.2) end
--function modeMode:exited() HS.alert.show("normal", 0.2) end

moveMode:bind({}, "escape", function() moveMode:exit() end)
moveMode:bind({"ctrl"}, "C", function() moveMode:exit() end)
moveMode:bind({}, "J", nextWindow)
moveMode:bind({}, "K", prevWindow)
moveMode:bind({}, "H", prevSideGroup)
moveMode:bind({}, "L", nextSideGroup)
moveMode:bind({}, "S", stackGroup)

moveMode:bind({"shift"}, "J", moveWindowToNextGroup)
moveMode:bind({"shift"}, "K", moveWindowToPrevGroup)
moveMode:bind({"shift"}, "J", moveWindowToNextSideGroup)
moveMode:bind({"shift"}, "H", moveWindowToPrevSideGroup)

-- ## window border ""
--windowBorder.init()
