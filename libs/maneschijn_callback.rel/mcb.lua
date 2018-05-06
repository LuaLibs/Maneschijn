--[[
        mcb.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.06
]]

-- $USE libs/maneschijn_core

local core = maneschijn_core
local cb = { Desc='Callback'}


cb.handlers={
}


function love.run()
      local mj,mi,re,cod = love.getVersion()
      assert(mi>11 or mj>0,"GJCR6 requires LOVE 0.11 or higher")
      -- There no need to use a different function for this
      love.load = love.load or maan.load or maan.onload
      love.quit = love.quit or maan.quit or maan.onquit
      if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
      
      -- Only copied for safety's sake
      -- And besides timed gadgets could need this.
      --if love.timer then love.timer.step() end
      assert(love.time,"Maneschijn cannot work without the love timer!")
      love.timer.step()
      local dt = 0       
      
      return function()
        -- Process events.
        if love.event then
           love.event.pump()        
           for name, a,b,c,d,e,f in love.event.poll() do
               -- Quit process is the same
               if name == "quit" then
                  if not love.quit or not love.quit() then
                     core.MainGadget.cantkill=false
                     core.MainGadget:free()
                     return a or 0
                  end
               end
               --love.handlers[name](a,b,c,d,e,f)
               (cb.handlers[name] or love.handlers[name])(a,b,c,d,e,f)
               -- Please note the call to love for non-existent handlers is only a temporary measure to prevent bugs and crashes, but is deprecated from the start!
           end
        end
        
      -- Update timer value  
      dt = love.timer.step()
      
      -- Update all timer based gadgets
      core.MainGadget:UpdateTimer(dt)
      
      -- Draw
      if love.graphics and love.graphics.isActive() then
         love.graphics.origin()
         love.graphics.clear(love.graphics.getBackgroundColor())
         core.MainGadget:PerformDraw()
         love.graphics.present()
      end
      

      
      -- The 'rest' routine
      love.timer.sleep(0.001)
      end
end

return {}




--[[ 
  Below is the ORIGINAL love.run routine....
  It does not serve any other purpose aside from being reference material.
  
  
function love.run()
  if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
 
  -- We don't want the first frame's dt to include time taken by love.load.
  if love.timer then love.timer.step() end
 
  local dt = 0
 
  -- Main loop time.
  return function()
    -- Process events.
    if love.event then
      love.event.pump()
      for name, a,b,c,d,e,f in love.event.poll() do
        if name == "quit" then
          if not love.quit or not love.quit() then
            return a or 0
          end
        end
        love.handlers[name](a,b,c,d,e,f)
      end
    end
 
    -- Update dt, as we'll be passing it to update
    if love.timer then dt = love.timer.step() end
 
    -- Call update and draw
    if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
 
    if love.graphics and love.graphics.isActive() then
      love.graphics.origin()
      love.graphics.clear(love.graphics.getBackgroundColor())
 
      if love.draw then love.draw() end
 
      love.graphics.present()
    end
 
    if love.timer then love.timer.sleep(0.001) end
  end
end
  
]]
