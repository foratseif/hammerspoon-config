-- Configuration
local borderColor = {red=0.7, green=0.7, blue=0.7, alpha=0.8}
local borderWidth = 2

-- Global variable to store the border
local focusBorder = nil

-- Function to delete the border
local function deleteBorder()
    if focusBorder then
        focusBorder:delete()
        focusBorder = nil
    end
end

-- Function to draw the border
local function drawBorder()
    local offset = 1
    local win = hs.window.focusedWindow()

    deleteBorder()

    if not win then
        return
    end

    local frame = win:frame()

    -- Adjust frame for border width and padding
    local adjustedFrame = {
        x = frame.x - offset,
        y = frame.y - offset,
        w = frame.w + (2*offset),
        h = frame.h + (2*offset)
    }

    if focusBorder then
        focusBorder:setFrame(adjustedFrame)
    else
        focusBorder = hs.drawing.rectangle(adjustedFrame)
        focusBorder:setStrokeColor(borderColor)
        focusBorder:setFill(false)
        focusBorder:setStrokeWidth(borderWidth)
        focusBorder:setRoundedRectRadii(13,13)
        focusBorder:show()
    end
end

-- Event listener for window focus changes
local windowFilter = hs.window.filter.new()
windowFilter:subscribe(hs.window.filter.windowFocused, drawBorder)
windowFilter:subscribe(hs.window.filter.windowUnfocused, deleteBorder)
windowFilter:subscribe(hs.window.filter.windowDestroyed, deleteBorder)
windowFilter:subscribe(hs.window.filter.windowMinimized, deleteBorder)
windowFilter:subscribe(hs.window.filter.windowHidden, deleteBorder)
windowFilter:subscribe(hs.window.filter.windowUnminimized, drawBorder)
windowFilter:subscribe(hs.window.filter.windowUnhidden, drawBorder)
windowFilter:subscribe(hs.window.filter.windowMoved, drawBorder)

return {
  drawBorder = drawBorder
}
