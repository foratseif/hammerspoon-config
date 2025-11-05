---@diagnostic disable-next-line: undefined-global
local HS = hs

local constants = require("constants");
local utils = require("utils");

local M = {}

function M.stackWindows(frame)
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

function M.getNextWindowBy(indexStep)
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
  return windows[nextIndex]
end

function M.getSideGroupBy(indexStep)
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

  if currentIndex+indexStep > #groupFrames or currentIndex+indexStep < 1 then
    return nil
  else
    return groupFrames[currentIndex+indexStep]
  end

  --local nextIndex = ((currentIndex+indexStep-1) % #groupFrames) + 1
  --return groupFrames[nextIndex]
end

function M.getNextGroupBy(indexStep)
  local focusedWindow = HS.window.focusedWindow()

  if focusedWindow == nil then
    return
  end
  local focusedGroup = utils.getGroupFrameOf(focusedWindow:frame())
  local groupFrames = utils.getAllGroupFrames()

  local currentIndex = groupFrames:getIndexOf(focusedGroup)

  if currentIndex == nil then
    return
  end

  local nextIndex = ((currentIndex+indexStep-1) % #groupFrames) + 1
  return groupFrames[nextIndex]
end


--function M.focusNextScreenBy(indexStep)
--  local focusedWindow = HS.window.focusedWindow()
--  local screen = utils.getScreenOf(focusedWindow:frame())
--  if screen == nil then
--    return
--  end
--
--  local screens = utils.getScreens()
--  local screenIndex = screens:getFocusedIndex()
--
--  if screenIndex == nil then
--    return
--  end
--
--  local nextIndex = ((screenIndex+indexStep-1) % #screens) + 1
--  local screenToFocus = screens[nextIndex]
--
--  utils.focusTopWindowInFrame(screenToFocus:frame())
--end

return M
