-- Create a modal hotkey object for Cmd+K
local cmdK = hs.hotkey.modal.new({"cmd"}, "k")

-- When Cmd+K is pressed, enter the modal state
function cmdK:entered()
  hs.alert.show("Cmd+K mode")
end

-- When Cmd+K is released, exit the modal state
function cmdK:exited()
  hs.alert.show("Exited Cmd+K mode")
end

-- Bind 'A' key inside the modal to do something
cmdK:bind({}, "a", function()
  hs.alert.show("You pressed Cmd+K then A!")
  cmdK:exit() -- exit modal after action
end)

-- Optionally, bind escape or other keys to exit modal without action
cmdK:bind({}, "escape", function()
  cmdK:exit()
end)
