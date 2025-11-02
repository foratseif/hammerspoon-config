---@diagnostic disable-next-line: undefined-global
local HS = hs

local utils = require("utils");
local dbg = require("dbg");
local constants = require("constants");
local windowBorder = require("window-border");
local TAGS = require("tags");


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
--   - next window
--   - next column
--   - next next group
--   - move window in groups
--   - move groups
--   - window out of group horizontal
--   - window out of group vertical
--   - carve window onto group
--   - tags
--   - make it fennel?
--   - done?

local function stackWindows(frame)
  local offsetStep = constants.OFFSET_STEP

  -- get windows
  local windows = utils.getWindowsOf(frame)

  -- compute new window size
  local numSteps = #windows-1
  local windowFrame = HS.geometry.copy(frame)
  windowFrame.x = windowFrame.x
  windowFrame.y = windowFrame.y
  windowFrame.h = windowFrame.h - offsetStep*numSteps
  windowFrame.w = windowFrame.w - offsetStep*numSteps

  for i, win in ipairs(windows) do
    local newFrame = HS.geometry.copy(windowFrame)
    newFrame.x = newFrame.x + (i-1)*offsetStep
    newFrame.y = newFrame.y + (i-1)*offsetStep
    utils.setWindowFrame(win, newFrame)
  end
end

local function focusNextWindowBy(indexStep)
  local focusedWindow = HS.window.focusedWindow()
  local screen = utils.getScreenOf(focusedWindow:frame())
  if screen == nil then
    print(string.format("ERROR: screen of %s is nil",focusedWindow:title()))
    return
  end

  print(string.format("focusNextWindowBy: '%s' is current screen of '%s'", screen:name(), focusedWindow:title()))

  local windows = utils.getWindowsOf(screen:frame())
  local windowIndex = windows:getFocusedIndex()

  print(string.format("focusNextWindowBy: windowIndex: %s", windowIndex))
  for i, win in ipairs(windows) do
    print(string.format("focusNextWindowBy: windows[%s] -> '%s'", i, win:title()))
  end

  if windowIndex == nil then
    print(string.format("focusNextWindowBy: windowIndex for '%s' in nil", focusedWindow:title()))
    if windows[1] ~= nil then
      windows[1]:focus()
    end
    return
  end

  local nextIndex = ((windowIndex+indexStep-1) % #windows) + 1
  local windowToFocus = windows[nextIndex]

  print(string.format("focusNextWindowBy: gonna switch focus to '%s'", windowToFocus:title()))
  utils.focusWindow(windowToFocus)
end

local function nextWindow()
  focusNextWindowBy(1)
end

local function prevWindow()
  focusNextWindowBy(-1)
end

local function focusNextScreenBy(indexStep)
  local focusedWindow = HS.window.focusedWindow()
  local screen = utils.getScreenOf(focusedWindow:frame())
  if screen == nil then
    return
  end

  local screens = utils.getScreens()
  local screenIndex = screens:getFocusedIndex()

  if screenIndex == nil then
    return
  end

  local nextIndex = ((screenIndex+indexStep-1) % #screens) + 1
  local screenToFocus = screens[nextIndex]

  utils.focusTopWindowInFrame(screenToFocus:frame())
end

local function nextScreen()
  focusNextScreenBy(1)
end

local function prevScreen()
  focusNextScreenBy(-1)
end

local function stackGroup()
  local focusedWindow = HS.window.focusedWindow()
  local groupFrame = utils.getGroupFrameOf(focusedWindow:frame())
  local expandedFrame = utils.expandFrame(groupFrame)
  local paddedFrame = utils.padFrame(expandedFrame, constants.GAP)
  stackWindows(paddedFrame)
end

--local function stackColumn()
--  local focusedWindow = HS.window.focusedWindow()
--  local columnFrame = utils.getColumnFrameOf(focusedWindow:frame())
--  stackWindows(columnFrame)
--end

local function stackScreen()
  local focusedWindow = HS.window.focusedWindow()
  local screen = utils.getScreenOf(focusedWindow:frame())

  if screen == nil then
    return
  end

  stackWindows(screen:frame())
end

local function visualizeFrames()
  local frames = utils.getAllColumnFrames()
  dbg.drawBorders(frames)
end

local function visualizeStuff()
  local focusedWindow = HS.window.focusedWindow()

  --local columnFrame = utils.getColumnFrameOf(focusedWindow:frame())
  local groupFrame = utils.getGroupFrameOf(focusedWindow:frame())
  
  ----local expandedColumnFrame = utils.expandFrame(columnFrame)
  local expandedGroupFrame = utils.expandFrame(groupFrame)

  for i, frame in ipairs({
    --expandedColumnFrame,
    expandedGroupFrame,
    --columnFrame,
    groupFrame,
  }) do
    local step = (i-1)*2
    frame.x = frame.x + step
    frame.y = frame.y + step
    frame.h = frame.h - step*2
    frame.w = frame.w - step*2
  end

  dbg.borderGreen(groupFrame)
  --dbg.borderRed(columnFrame)
  dbg.borderBlue(expandedGroupFrame)
  --dbg.borderCyan(expandedColumnFrame)
end

local function focusNextGroupBy(indexStep)
  local focusedWindow = HS.window.focusedWindow()

  if focusedWindow == nil then
    return
  end
  local focusedGroup = utils.getGroupFrameOf(focusedWindow:frame())
  local groupFrames = utils.getAllGroupFrames()

  groupFrames:filter(function(frame)
    return utils.sameFrame(frame, focusedGroup) or
      not utils.intersectsX(frame, focusedGroup)
  end)

  local currentIndex = groupFrames:getIndexOf(focusedGroup)

  if currentIndex == nil then
    return
  end

  local nextIndex = ((currentIndex+indexStep-1) % #groupFrames) + 1
  local groupFrameToFocus = groupFrames[nextIndex]

  --local screenOfGroupFrameToFocus = utils.getScreenOf(groupFrameToFocus)
  --groupFrameToFocus.y = screenOfGroupFrameToFocus:frame().y
  --groupFrameToFocus.h = screenOfGroupFrameToFocus:frame().h

  utils.focusTopWindowInFrame(groupFrameToFocus)

  --dbg.borderRed(groupFrameToFocus) -- closest left
  --dbg.drawBorders(groupFrames)
end

local function nextGroup()
  focusNextGroupBy(1)
end

local function prevGroup()
  focusNextGroupBy(-1)
end

local function nothing()
  -- nothign
end

local function shit()
  TAGS:shit()
end

HS.hotkey.bind({"cmd"}, "H", nothing)
HS.hotkey.bind({"shift", "ctrl"}, "J", nextWindow)
HS.hotkey.bind({"shift", "ctrl"}, "K", prevWindow)
HS.hotkey.bind({"shift", "ctrl"}, "H", prevGroup)
HS.hotkey.bind({"shift", "ctrl"}, "H", prevGroup)
HS.hotkey.bind({"shift", "ctrl"}, "L", nextGroup)
HS.hotkey.bind({"shift", "ctrl"}, "O", stackScreen)
HS.hotkey.bind({"shift", "ctrl"}, "G", stackGroup)
--HS.hotkey.bind({"shift", "ctrl"}, "R", visualizeGroups)
--HS.hotkey.bind({"shift", "ctrl"}, "D", visualizeStuff)
HS.hotkey.bind({"shift", "ctrl"}, "D", visualizeFrames)
HS.hotkey.bind({"shift", "ctrl"}, "N", shit)

local modeMode = HS.hotkey.modal.new({"shift","ctrl"}, "M")

function modeMode:entered()
  HS.alert.show("mode", 0.2)
end
function modeMode:exited()
  HS.alert.show("normal", 0.2)
end
modeMode:bind({}, "escape", function()
  modeMode:exit()
end)
modeMode:bind({"ctrl"}, "C", function()
  modeMode:exit()
end)

modeMode:bind({}, "J", nextWindow)
modeMode:bind({}, "K", prevWindow)
modeMode:bind({}, "H", prevScreen)
modeMode:bind({}, "L", nextScreen)
modeMode:bind({}, "O", stackScreen)
modeMode:bind({}, "G", stackGroup)
modeMode:bind({}, "D", visualizeStuff)

function vResizeUp()
  local win = HS.window.focusedWindow()
  local frame = win:frame()
  frame.y = frame.y - 20
  frame.h = frame.h + 40
  utils.setWindowFrame(win, frame)
end

function vResizeDown()
  local win = HS.window.focusedWindow()
  local frame = win:frame()
  frame.y = frame.y + 20
  frame.h = frame.h - 40
  utils.setWindowFrame(win, frame)
end

function hResizeUp()
  local win = HS.window.focusedWindow()
  local frame = win:frame()
  frame.x = frame.x - 20
  frame.w = frame.w + 40
  utils.setWindowFrame(win, frame)
end

function hResizeDown()
  local win = HS.window.focusedWindow()
  local frame = win:frame()
  frame.x = frame.x + 20
  frame.w = frame.w - 40
  utils.setWindowFrame(win, frame)
end

modeMode:bind({"shift"}, "J", vResizeDown)
modeMode:bind({"shift"}, "K", vResizeUp)
modeMode:bind({"shift"}, "H", hResizeDown)
modeMode:bind({"shift"}, "L", hResizeUp)

function vMoveUp()
  local win = HS.window.focusedWindow()
  local frame = win:frame()
  frame.y = frame.y - 20
  utils.setWindowFrame(win, frame)
end

function vMoveDown()
  local win = HS.window.focusedWindow()
  local frame = win:frame()
  frame.y = frame.y + 20
  utils.setWindowFrame(win, frame)
end

function hMoveUp()
  local win = HS.window.focusedWindow()
  local frame = win:frame()
  frame.x = frame.x + 20
  utils.setWindowFrame(win, frame)
end

function hMoveDown()
  local win = HS.window.focusedWindow()
  local frame = win:frame()
  frame.x = frame.x - 20
  utils.setWindowFrame(win, frame)
end


modeMode:bind({"ctrl"}, "J", vMoveDown)
modeMode:bind({"ctrl"}, "K", vMoveUp)
modeMode:bind({"ctrl"}, "H", hMoveDown)
modeMode:bind({"ctrl"}, "L", hMoveUp)

--windowBorder.init()
