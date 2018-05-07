--[[
        core.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.07
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

local childless = {} -- must always be an empty table, but it savers performance for having to create and dispose a table for each Method attachment to a childless gadget
local gadgettypes = {}
local pures = {
     absolute = function(gadget,t) return gadget[t] or 0 end,
     screenw  = function(gadget,t) local width, height = love.window.getDesktopDimensions(  )  return width *gadget[t] end,
     screenh  = function(gadget,t) local width, height = love.window.getDesktopDimensions(  )  return height*gadget[t] end,
     windoww  = function(gadget,t) local width, height = love.graphics.getDimensions( )        return width *gadget[t] end,
     windowh  = function(gadget,t) local width, height = love.graphics.getDimensions( )        return height*gadget[t] end,
     parent   = function(gadget,t) return (gadget.parent or core.MainGadget):Stat(t)*gadget[t] end
     
}

local methoden = { -- This is a bunch of methods and subvariables ALL gadgets should have
    
    free = function(self) -- VERY VERY important. Only release gadgets through the "free" method If you just put them to nil before releasing them you will get memory leaks do to a bug in Lua's garbage collector in 'cyclic references' in tables!
        assert(not self.cantkill , "You tried to kill a gadget you cannot kill");
        (self.onFree or nothing)()
        if self.kids then
           for kid in each(self.kids or childless) do kid:free() end -- A kid MUST have free!
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
        for _,kid in pairs(self.kids or childless) do
            kid:UpdateTimer()
        end 
     end,
     
     PerformDraw = function(self,prio)
         local pddebug=0 -- set to 0 if in use, set to false or nil if not!
         -- Not visible? Then get outta here!
         if self.Visible==false then return end
         -- init
         local priolist = {}   
         for i=1,core.maxpriority do priolist[i]={} end      
         local uprio = math.ceil(self.priority or core.maxpriority/2)
         -- Add stuff into the right priority list         
         if self.id and maan[self.id] and maan[self.id].Draw then 
            priolist[uprio][#priolist[uprio]+1] = {maan[self.id].Draw,self}
         elseif self.Draw then
            priolist[uprio][#priolist[uprio]+1] = {self.Draw,self}
         end
         -- Recurse
         for _,kid in pairs(self.kids or childless) do
             local tp = kid:PerformDraw('RECURSE')
             for ip,lp in ipairs(tp) do for f in each(lp) do priolist[ip][#priolist[ip]+1]=f end end
         end          
         if prio=='RECURSE' then return priolist end -- When 'RECURSE' is set, we're just gathering 
         -- Show everything according to priority
         assert(core.maxpriority>=1,"Invalid maxprio! Must be 1 or higher!")
         local maxp,minp=core.maxpriority,1
         --error("prio = "..type(prio))         
         if prio then maxp,minp=prio,prio end
         -- error("maxp = "..type(maxp))
         -- error(serialize('priolist',priolist))
         for iprio = maxp,minp,-1 do
             for d in each(priolist[iprio]) do                  
                 d[1](d[2]) 
                 if pddebug then
                    love.graphics.print("Drawing a "..(d[2].kind or "superior").." at ("..d[2]:TX()..","..d[2]:TY()..") >> "..d[2]:TW().."x"..d[2]:TH().."   ("..(d[2].dw or "nil").."/"..(d[2].dh or "nil")..")",0,pddebug)
                    pddebug = pddebug + 20
                 end
             end
         end                             
     end ,
     
     ReCreate = function(self) self:onCreate() end,
     
     Pure = function(self,truef,depf)
        return pures[depf or 'absolute'](self,truef)
     end,
     
     Stat = function(self,s)
         return self:Pure(s,self["d"..s])
     end,
     
     TX = function(self) if self.superior then return 0 else return self.parent:Stat("x")+self:Stat("x") end end,           
     TY = function(self) if self.superior then return 0 else return self.parent:Stat("y")+self:Stat("y") end end,
     TW = function(self) return self:Stat("w") end,
     TH = function(self) return self:Stat("h") end,                
}

local superior_methods = {  Draw=nothing }



core.MainGadget = {
       superior=true,
       cantkill=true,
       x=0,y=0,
       w=1,h=1,
       dw='windoww',dh='windowh',
       kids={} 
}

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
    (gadget.onCreate or nothing)(gadget)
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

-- Free all gadgets tied to the MainGadget
function core.FreeAll()
     for _,gadget in pairs(core.MainGadget.kids) do gadget:free() end
end

local sct = {'x','y','w','h'}
local scd = {x='w',w='w',y='h',h='h'}
function core.StatCalc(gadget)
    for s in each(sct) do
        gadget[s] = gadget[s] or 0
        local vs = gadget[s]
        if type(gadget[s])=='number' then
           -- Do nothing! All is fine!           
        elseif type(gadget[s])=='string' then
           local r = tonumber(vs) or 0
           if suffixed(vs,"%%%") then
              r = (tonumber(left(vs,#vs-3)) or 0)/100
              gadget['d'..s]='screen'..scd[s]
           elseif suffixed(vs,"%%") then   
              r = (tonumber(left(vs,#vs-2)) or 0)/100
              gadget['d'..s]='window'..scd[s]
           elseif suffixed(vs,"%") then   
              r = (tonumber(left(vs,#vs-1)) or 0)/100
              gadget['d'..s]='parent'
           end
           gadget[s]=r
        else 
           error("I have no use for a "..type(gadget[s]).." for field "..s)   
        end         
    end
    for _,kid in pairs(gadget.kids or childless) do core.StatCalc(kid) end
end

-- This is the 'main' gadget. Best is NOT to alter it (unless you KNOW what you are doing)
core.AttachMethods(core.MainGadget)






return core
