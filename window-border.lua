---@diagnostic disable-next-line: undefined-global
local HS = hs

local M = {}

local border = nil


local function updateBorder()

  if border then
      border:delete()
      border = nil
  end

  local win = HS.window.focusedWindow()
  if not win then return end
  if win:isFullscreen() then return end

  local width = 0

  local borderFrame = HS.geometry.copy(win:frame())
  borderFrame.x = borderFrame.x - width
  borderFrame.y = borderFrame.y - width
  borderFrame.w = borderFrame.w + 2*width
  borderFrame.h = borderFrame.h + 2*width

  border = HS.drawing.rectangle(borderFrame)
  --border:setStrokeColor({red=0, green=0.75, blue=0.75, alpha=1})
  --border:setStrokeColor({red=0.46274, green=0.16862, blue=0.10196, alpha=1})
  border:setStrokeColor({red=0.60, green=0.75, blue=0.1, alpha=1})
  border:setStrokeWidth(width+3)
  border:setRoundedRectRadii(11,11)
  border:setFill(false)
  border:setLevel("floating")
  border:setBehaviorByLabels({"canJoinAllSpaces", "stationary", "ignoresMouseEvents"})
  border:show()
end

function M.init()
  local wf = HS.window.filter.new(nil)
  wf:subscribe(HS.window.filter.windowFocused, function()
    updateBorder()
  end)

  wf:subscribe({
      HS.window.filter.windowUnfocused,
      HS.window.filter.windowMoved,
      HS.window.filter.windowResized
  }, function()
      updateBorder()
  end)

  updateBorder()
end

return M
