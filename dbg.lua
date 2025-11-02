---@diagnostic disable-next-line: undefined-global
local HS = hs

local M = {}

function M.printFrame(frame, label)
  if label then
    label = label .. ": "
  else
    label = ""
  end

  print(label .. string.format(
    "Frame {x: %s, y: %s, w: %s, h: %s}",
    frame.x,
    frame.y,
    frame.w,
    frame.h
  ))
end

function M.borderRed(rect)
    local border = HS.drawing.rectangle(rect)
    border:setStrokeColor({red=1, green=0, blue=0, alpha=1}) -- Red border
    border:setStrokeWidth(4)
    border:setFill(false)
    border:setLevel("floating")
    border:setBehaviorByLabels({"canJoinAllSpaces", "stationary", "ignoresMouseEvents"})
    border:show()

    HS.timer.doAfter(1, function()
        border:delete()
    end)
end

function M.borderGreen(rect)
    local border = HS.drawing.rectangle(rect)
    border:setStrokeColor({red=0, green=1, blue=0, alpha=1}) -- Red border
    border:setStrokeWidth(4)
    border:setFill(false)
    border:setLevel("floating")
    border:setBehaviorByLabels({"canJoinAllSpaces", "stationary", "ignoresMouseEvents"})
    border:show()

    HS.timer.doAfter(1, function()
        border:delete()
    end)
end

function M.borderBlue(rect)
    local border = HS.drawing.rectangle(rect)
    border:setStrokeColor({red=0, green=0, blue=1, alpha=1}) -- Red border
    border:setStrokeWidth(4)
    border:setFill(false)
    border:setLevel("floating")
    border:setBehaviorByLabels({"canJoinAllSpaces", "stationary", "ignoresMouseEvents"})
    border:show()

    HS.timer.doAfter(1, function()
        border:delete()
    end)
end

function M.borderCyan(rect)
    local border = HS.drawing.rectangle(rect)
    border:setStrokeColor({red=0, green=1, blue=1, alpha=1}) -- Red border
    border:setStrokeWidth(4)
    border:setFill(false)
    border:setLevel("floating")
    border:setBehaviorByLabels({"canJoinAllSpaces", "stationary", "ignoresMouseEvents"})
    border:show()

    HS.timer.doAfter(1, function()
        border:delete()
    end)
end

function M.drawBorders(frames)
  local borders = {}

  for _, frame in ipairs(frames) do
    local width = 3

    local borderFrame = HS.geometry.copy(frame)
    borderFrame.x = borderFrame.x - width
    borderFrame.y = borderFrame.y - width
    borderFrame.w = borderFrame.w + 2*width
    borderFrame.h = borderFrame.h + 2*width

    local border = HS.drawing.rectangle(borderFrame)
    border:setStrokeColor({red=1, green=0, blue=1, alpha=1}) -- Red border
    border:setStrokeWidth(width+2)
    border:setFill(false)
    border:setLevel("floating")
    border:setBehaviorByLabels({"canJoinAllSpaces", "stationary", "ignoresMouseEvents"})
    border:show()
    table.insert(borders, border)
  end

  HS.timer.doAfter(0.2, function()
    for _, border in ipairs(borders) do
      border:delete()
    end
  end)
end

return M
