---@diagnostic disable-next-line: undefined-global
local HS = hs

local modifiersDown = false

-- Callback when modifiers change
local modifierWatcher = HS.eventtap.new({ HS.eventtap.event.types.flagsChanged }, function(event)
    local flags = event:getFlags()
    local cmd = flags.cmd
    local ctrl = flags.ctrl

    -- Check if modifiers are pressed
    if cmd and ctrl and not modifiersDown then
        modifiersDown = true
        HS.alert("Modifiers down (cmd+ctrl)")
        -- Do setup here
    elseif not (cmd and ctrl) and modifiersDown then
        modifiersDown = false
        HS.alert("Modifiers released (cmd+ctrl)")
        -- Do cleanup here
    end

    return false
end)

modifierWatcher:start()
