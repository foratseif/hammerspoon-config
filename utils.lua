---@diagnostic disable-next-line: undefined-global
local HS = hs

local constants = require("constants");

local M = {}

local function roundWithDecimals(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 2)
    return math.floor(num * mult + 0.5) / mult
end

local windowsMethods = {}
function windowsMethods:getFocusedIndex()
  local focused = HS.window.focusedWindow()
  for i, win in ipairs(self) do
    if win:id() == focused:id() then
      return i
    end
  end
  return nil
end

local screenMethods = {}
function screenMethods:getFocusedIndex()
  local focusedWindow = HS.window.focusedWindow()

  if focusedWindow == nil then
    return
  end

  local focused = focusedWindow:screen()

  print(string.format("focusedScreenId: %s", focused:id()))
  for i, screen in ipairs(self) do
    print(string.format("%s == %s", screen:id(), focused:id()))
    if screen:id() == focused:id() then
      return i
    end
  end
  return nil
end

local groupMethods = {}
function groupMethods:sortByRightXCorner()
  table.sort(self, function(aFrame, bFrame)
    local aRightX = aFrame.x + aFrame.w
    local bRightX = bFrame.x + bFrame.w
    if aRightX == bRightX then
      return aFrame.y < bFrame.y
    else
      return aRightX < bRightX
    end
  end)
  return self
end

function groupMethods:sortByLeftXCorner()
  table.sort(self, function(aFrame, bFrame)
    local aLeftX = aFrame.x
    local bLeftX = bFrame.x
    if aLeftX == bLeftX then
      return aFrame.y < bFrame.y
    else
      return aLeftX < bLeftX
    end
  end)
  return self
end


function groupMethods:getIndexOf(frame)
  for i, gr in ipairs(self) do
    if M.sameFrame(frame, gr) then
      return i
    end
  end

  return nil
end

function groupMethods:filter(cond)
  local i = 1
  while i <= #self do
    if not cond(self[i]) then
      table.remove(self, i)
    else
      i = i+1
    end
  end

  return self
end

function M.getScreens()
  local screens = {}

  for _, scr in ipairs(HS.screen.allScreens()) do
    screens[#screens+1] = scr
  end

  table.sort(screens, function(a, b)
    local aFrame = a:frame()
    local bFrame = b:frame()

    if not (aFrame.x == bFrame.x) then
      return aFrame.x < bFrame.x
    end

    if not (aFrame.y == bFrame.y) then
      return aFrame.y < bFrame.y
    end

    return a:id() < b:id()
  end)

  return setmetatable(screens, { __index = screenMethods })
end


function M.getAllGroupFrames()
  local windows = {}

  for _, win in ipairs(HS.window.allWindows()) do
    if win:isStandard()
      and not win:isMinimized()
    then
      table.insert(windows, win:frame())
    end
  end

  local thres = constants.THRESHOLD
  local groups = {}

  for _, win in ipairs(windows) do
    local frame = HS.geometry.copy(win)
    local intersectingFrames = {}

    local i = 1
    while i <= #groups do
      local intersection = frame:intersect(groups[i])

      local groupScreen = M.getScreenOf(groups[i])
      local frameScreen = M.getScreenOf(frame)

      if frame.w * thres < intersection.w
        and frame.h * thres < intersection.h
        and groupScreen ~= nil
        and frameScreen ~= nil
        and groupScreen:id() == frameScreen:id()
      then
        local group = table.remove(groups, i)
        table.insert(intersectingFrames, group)
      else
        i = i+1
      end
    end

    local x1 = frame.x
    local x2 = frame.x + frame.w
    local y1 = frame.y
    local y2 = frame.y + frame.h

    for _, f in ipairs(intersectingFrames) do
      x1 = math.min(x1, f.x)
      x2 = math.max(x2, f.x + f.w)
      y1 = math.min(y1, f.y)
      y2 = math.max(y2, f.y + f.h)
    end

    frame.x = x1
    frame.w = x2 - x1
    frame.y = y1
    frame.h = y2 - y1

    table.insert(groups, frame)
  end


  table.sort(groups, function(a, b)
    if not (a.x == b.x) then
      return a.x < b.x
    end

    return a.y < b.y
  end)

  return setmetatable(groups, { __index = groupMethods })
end

function M.getAllColumnFrames()
  local windows = {}

  for _, win in ipairs(HS.window.allWindows()) do
    if win:isStandard()
      and not win:isMinimized()
    then
      table.insert(windows, win:frame())
    end
  end

  local thres = constants.THRESHOLD
  local columns = {}

  for _, win in ipairs(windows) do
    local frame = HS.geometry.copy(win)
    local intersectingFrames = {}

    local i = 1
    while i <= #columns do
      local intersection = frame:intersect(columns[i])
      
      local columnScreen = M.getScreenOf(columns[i])
      local frameScreen = M.getScreenOf(frame)

      if frame.w * thres < intersection.w
        and columnScreen ~= nil
        and frameScreen ~= nil
        and columnScreen:id() == frameScreen:id() 
      then
        local column = table.remove(columns, i)
        table.insert(intersectingFrames, column)
      else
        i = i+1
      end
    end

    local x1 = frame.x
    local x2 = frame.x + frame.w
    local y1 = frame.y
    local y2 = frame.y + frame.h

    for _, f in ipairs(intersectingFrames) do
      x1 = math.min(x1, f.x)
      x2 = math.max(x2, f.x + f.w)
      y1 = math.min(y1, f.y)
      y2 = math.max(y2, f.y + f.h)
    end

    frame.x = x1
    frame.w = x2 - x1
    frame.y = y1
    frame.h = y2 - y1

    table.insert(columns, frame)
  end


  table.sort(columns, function(a, b)
    if not (a.x == b.x) then
      return a.x < b.x
    end

    return a.y < b.y
  end)

  return setmetatable(columns, { __index = groupMethods })
end

function M.getWindowsOf(frame)
  local windows = {}
  for _, win in ipairs(HS.window.allWindows()) do
    if win:isStandard()
      and M.frameMostlyInFrame(win:frame(), frame)
      and not win:isMinimized()
    then
      windows[#windows+1] = win
    end
  end

  table.sort(windows, function(a, b)
    local aFrame = a:frame()
    local bFrame = b:frame()

    if not (aFrame.x == bFrame.x) then
      return aFrame.x < bFrame.x
    end

    if not (aFrame.y == bFrame.y) then
      return aFrame.y < bFrame.y
    end

    return a:id() < b:id()
  end)

  return setmetatable(windows, { __index = windowsMethods })
end

function M.getTopWindowOf(frame)
  for _, win in ipairs(HS.window.orderedWindows()) do
    if win:isStandard()
      and M.frameMostlyInFrame(win:frame(), frame)
      and not win:isMinimized()
    then
      return win
    end
  end
end

function M.getScreenOf(frame)
  for _, screen in ipairs(HS.screen.allScreens()) do
    if M.frameMostlyInFrame(frame, screen:frame()) then
      return screen
    end
  end
end



--function M.getColumnFrameOf(frame)
--  local screenFrame = M.getScreenOf(frame):frame()
--
--  local thres = constants.THRESHOLD
--
--  local columnFrame = HS.geometry.copy(frame)
--
--  for _, win in ipairs(M.getWindowsOf(screenFrame)) do
--    local winFrame = win:frame()
--    local intersection = columnFrame:intersect(winFrame)
--
--    if winFrame.w * thres < intersection.w then
--      columnFrame.x = math.min(columnFrame.x, winFrame.x)
--      columnFrame.w = math.max(columnFrame.w, winFrame.x + winFrame.w - columnFrame.x)
--
--      columnFrame.y = math.min(columnFrame.y, winFrame.y)
--      columnFrame.h = math.max(columnFrame.h, winFrame.y + winFrame.h - columnFrame.y)
--    end
--  end
--
--  return columnFrame
--end


function M.getGroupFrameOf(frame)
  local screenFrame = M.getScreenOf(frame):frame()

  local thres = constants.THRESHOLD
  local groupFrame = HS.geometry.copy(frame)

  for _, win in ipairs(M.getWindowsOf(screenFrame)) do
    local winFrame = win:frame()
    local intersection = frame:intersect(winFrame)

    if frame.w * thres < intersection.w
       and frame.h * thres < intersection.h
    then
      groupFrame.x = math.min(groupFrame.x, winFrame.x)
      groupFrame.w = math.max(groupFrame.w, winFrame.x + winFrame.w - groupFrame.x)

      groupFrame.y = math.min(groupFrame.y, winFrame.y)
      groupFrame.h = math.max(groupFrame.h, winFrame.y + winFrame.h - groupFrame.y)
    end
  end

  return groupFrame
end

function M.expandFrame(frame)
  local screenFrame = M.getScreenOf(frame):frame()

  local minX = { screenFrame.x }
  local maxX = { screenFrame.x + screenFrame.w }
  local minY = { screenFrame.y }
  local maxY = { screenFrame.y + screenFrame.h }

  local threshold = (1-constants.THRESHOLD)

  for _, win in ipairs(M.getWindowsOf(screenFrame)) do
    local winFrame = win:frame()
    if winFrame.x + winFrame.w*threshold <= frame.x then
      table.insert(minX, winFrame.x + winFrame.w)
    end

    if winFrame.x >= frame.x + frame.w*threshold then
      table.insert(maxX, winFrame.x)
    end

    if winFrame.y + winFrame.h*threshold <= frame.y then
      table.insert(minY, winFrame.y + winFrame.h)
    end

    if winFrame.y >= frame.y + frame.h*threshold then
      table.insert(maxY, winFrame.y)
    end
  end

  table.sort(minX)
  table.sort(maxX)
  table.sort(minY)
  table.sort(maxY)

  local expandedFrame = HS.geometry.copy(screenFrame)
  expandedFrame.x = minX[#minX]
  expandedFrame.w = maxX[1] - minX[#minX]
  expandedFrame.y = minY[#minY]
  expandedFrame.h = maxY[1] - minY[#minY]

  return expandedFrame
end

function M.padFrame(frame, padding)
  local paddedFrame = HS.geometry.copy(frame)

  paddedFrame.x = paddedFrame.x + padding
  paddedFrame.y = paddedFrame.y + padding
  paddedFrame.w = paddedFrame.w - 2*padding
  paddedFrame.h = paddedFrame.h - 2*padding
  return paddedFrame
end

function M.intersectsX(innie, outie)
  local intersection = innie:intersect(outie)
  return innie.w * constants.THRESHOLD < intersection.w
end

function M.intersectsY(innie, outie)
  local intersection = innie:intersect(outie)
  return innie.h * constants.THRESHOLD < intersection.h
end

function M.sameFrame(a, b)
    return a.x == b.x
    and a.y == b.y
    and a.h == b.h
    and a.w == b.w
end

function M.frameMostlyInFrame(innie, outie)
  local intersection = innie:intersect(outie)
  local intersectionArea = intersection.h *intersection.w

  local innieArea = innie.h * innie.w

  return intersectionArea >= innieArea/2
end

function M.setWindowFrame(win, frame)
  local orignalFrame = win:frame()
  win:setFrame(frame, 0)
  local newFrame = win:frame()

  local originalRatio = roundWithDecimals(orignalFrame.w/orignalFrame.h)
  local newRatio = roundWithDecimals(newFrame.w/newFrame.h)

  if originalRatio == newRatio then
    if newFrame.h > frame.h then
      newFrame.h = frame.h
      newFrame.w = frame.h*newRatio
      win:setFrame(newFrame, 0)
    elseif newFrame.w > frame.w then
      newFrame.w = frame.w
      newFrame.h = frame.w/newRatio
      win:setFrame(newFrame, 0)
    end
  end
end

function M.focusWindow(win)
  win:becomeMain()
  HS.timer.doAfter(0.01, function() win:focus() end)
end

function M.focusTopWindowInFrame(frame)
  local win = M.getTopWindowOf(frame)
  if win ~= nil then
    M.focusWindow(win)
  end
end


return M
