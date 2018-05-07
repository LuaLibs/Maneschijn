--[[
        core.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.06
]]
-- Some core code will appear here, once development has begun

-- $USE libs/nothing

maan={} -- The only definition here, but it's used for some basic callbacks

local core = {
   copyright = "Jeroen P. Broks",
   
   
   -- With this you can set the number of priority layers.
   -- With this you can determine if something is always drawn first or last.
   -- By default I've set this to 3, but you can use any setup you like
   -- Minimum level is 1, anything below that number is ignored.
   -- Please note, if you have too many of these your game *is* likely to slow down
   maxpriority=3
}

local gadgettypes = {}

local methoden = { -- This is a bunch of methods and subvariables ALL gadgets should have
    
    free = function(self) -- VERY VERY important. Only release gadgets through the "free" method If you just put them to nil before releasing them you will get memory leaks do to a bug in Lua's garbage collector in 'cyclic references' in tables!
        assert(not self.cantkill , "You tried to kill a gadget you cannot kill");
        (self.kids.onfree or nothing)()
        if self.kids then
           for kid in each(self.kids) do kid:free() end -- A kid MUST have free!
        end
        self.parent=nil -- Very important one too!
        self.freed=true
        -- Now all the "dangerous stuff" is done, however keep in mind that the gadget still contains data, but if you set it to nil now, everything should be fine!
     end,    
     
     UpdateTimer = function(self,dt)
        if self.Enabled==false then return end
        if self.Timer and self.Timer>0 then
           self.TimerValue = (self.TimerValue or 0) + dt
           if self.TimerValue>self.Timer then 
              if self.id and maan[self.id] and maan[self.id].TimerAction then 
                 maan[self.id].TimerAction(self)
              elseif self.TimerAction then
                 self:TimerAction()
              end
              self.TimerValue=0
           end
        end
        for _,kid in pairs(self.kids or {}) do
            kid:UpdateTimer()
        end 
     end,
     
     PerformDraw = function(self,prio)
         -- Not visible? Then get outta here!
         if self.Visible==false then return end
         -- init
         local priolist = {}
         local uprio = math.ceil(self.priority) or math.ceil(core.maxpriority/2)
         -- Add stuff into the right priority list         
         if self.id and maan[self.id] and maan[self.id].Draw then 
            priolist[uprio][#priolist[uprio]+1] = {maan[self.id].Draw,self}
         elseif self.Draw then
            priolist[uprio][#priolist[uprio]+1] = {self.Draw,self}
         end
         -- Recurse
         for _,kid in pairs(self.kids or {}) do
             local tp = kid:PerformDraw('RECURSE')
             for ip,lp in ipairs(tp) do for f in each(lp) do priolist[ip][#priolist[ip]+1]=f end end
         end          
         if prio=='RECURSE' then return priolist end -- When 'RECURSE' is set, we're just gathering 
         -- Show everything according to priority
         assert(core.maxprio>=1,"Invalid maxprio! Must be 1 or higher!")
         local maxp,minp=core.maxprio,1
         if prio then maxp,minp=prio,prio end
         for iprio = maxp,minp,-1 do
             for d in each(priolist[iprio]) do d[1](d[2]) end
         end                             
     end       
}

local superior_methods = {   
}

local childless = {} -- must always be an empty table, but it savers performance for having to create and dispose a table for each Method attachment to a childless gadget

-- Is in normal setups not required in your code and called automatically when needed
function core.AttachMethods(gadget,meths,ignorekids)
    for mk,mv in pairs(meths or methoden) do
        gadget[mk]=mv
    end
    assert(gadgettypes[gadget.kind] or gadget.superior,"I do not know gadget kind: "..sval(gadget.kind))
    local kind
    if gadget.superior then kind=superior_methods else kind=gadgettypes[gadget.kind] end
    for mk,mv in pairs(kind) do
        gadget[mk]=mv
    end
    if ignorekids then return end
    if not gadget.superior then 
       gadget.parent = gadget.parent or core.MainGadget
       local found=false
       for _,kid in pairs(gadget.parent.kids) do
           found = found or (kid==gadget)
       end
       if not found then gadget.parent.kids[#gadget.parent.kids+1]=gadget end
    end 
    for _,kid in pairs(gadget.kids or childless) do
        core.AttachMethods(kid,meths) 
        kid.parent=gadget
    end
end    

function core.RegisterGadget(kind,data)
    gadgettypes[kind]=data
end


-- This is the 'main' gadget. Best is NOT to alter it (unless you KNOW what you are doing)
core.MainGadget = {
       superior=true,
       cantkill=true,
       x=0,y=0,
       w=1,h=1,
       dw='screen',dh='screen',
       kids={} 
}
core.AttachMethods(core.MainGadget)






return core
