local utils = require("utils");

local TAGS = {
  data = {},
}

function TAGS:includes(screen)
  for screenId, _ in pairs(self.data) do
    if screenId == screen:id() then
      return true
    end
  end 
  return false
end

function TAGS:add(screen)
  local firstTag = {}
  for _, win in ipairs(utils.getWindowsOf(screen:frame())) do
    table.insert(firstTag, win:id())
  end
  self.data[screen:id()] = { firstTag }
end


function TAGS:sort_screens() 
  local screens = utils.getScreens()

  for _, scr in ipairs(screens) do
    if not TAGS:includes(scr) then
      TAGS:add(scr)
    end
  end
end

function TAGS:sort_tags(screenId)
  
end


function TAGS:dbg()
  for screenId, tags in pairs(self.data) do
    print(string.format("Screen [id=%s]", screenId))
    for i, tag in ipairs(tags) do
      print(
        string.format(
          "%s -> [%s]",
          i,
          table.concat(tag, ", ")
        )
      )
    end
  end 
end

function TAGS:shit()
  self:sort_screens() 
  self:dbg()
end

return TAGS
