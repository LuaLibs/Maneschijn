--[[
        core.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.11
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

local sct = {'x','y','w','h'}
local scd = {x='w',w='w',y='h',h='h'}


local childless = {} -- must always be an empty table, but it savers performance for having to create and dispose a table for each Method attachment to a childless gadget
local gadgettypes = {}
local pures = {
     absolute = function(gadget,t,d) return tonumber(gadget[t]) or 0 end,
     screenw  = function(gadget,t,d) local width, height = love.window.getDesktopDimensions(  )  return width *gadget[t] end,
     screenh  = function(gadget,t,d) local width, height = love.window.getDesktopDimensions(  )  return height*gadget[t] end,
     windoww  = function(gadget,t,d) local width, height = love.graphics.getDimensions( )        return width *gadget[t] end,
     windowh  = function(gadget,t,d) local width, height = love.graphics.getDimensions( )        return height*gadget[t] end,
     parent   = function(gadget,t,d) return (gadget.parent or core.MainGadget):Stat(d)*gadget[t] end
     
}

local methoden = { -- This is a bunch of methods and subvariables ALL gadgets should have

    irmeth = function(self,meth)
       local i=0
       local t={}
       local function get(g)
         if g.Enabled==false then return end
         if g[meth] then t[#t+1]={g,g[meth]} end
         for _,kid in pairs(g.kids or childless) do get(kid) end
       end
       get(self)
       --print("Iterate "..#t.." "..sval(meth).." callbacks")
       return function()
            i=i+1
            if i>#t then return nil,nil end
            return t[i][2],t[i][1]
       end     
    end,
    
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
              if self.id and maan[self.id] and maan[self.id.."_TimerAction"] then 
                 maan[self.id.."TimerAction"](self)
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
         local pddebug=nil -- set to 0 if in use, set to false or nil if not!
         local cdebug=false
         if cdebug and prio~="RECURSE" then
             print("\n\n"..string.char(27).."[31mNEW DRAW CYCLE"..string.char(27).."[0m")
         end
         -- Not visible? Then get outta here!
         if self.Visible==false then return end
         -- init
         local priolist = {}   
         for i=1,core.maxpriority do priolist[i]={} end      
         local uprio = math.ceil(self.priority or core.maxpriority/2)
         -- Add stuff into the right priority list         
         if self.id and maan[self.id] and maan[self.id.."Draw"] then 
            priolist[uprio][#priolist[uprio]+1] = {maan[self.id.."Draw"],self}
         elseif self.Draw then
            priolist[uprio][#priolist[uprio]+1] = {self.Draw,self}
         end
         -- Recurse
         --[[
         if pddebug then
            pddebug = pddebug + 5
            love.graphics.print("KIDS of "..(self.dbgid or "idless "..self.kind),5,pddebug)
            pddebug = pddebug + 20
         end
         --]]
         if cdebug then
            print(string.char(27).."[32mDEBUG>"..string.char(27).."[0m Processing kids of: "..(self.dbgid or "idless "..self.kind))
         end            
         for _,kid in pairs(self.kids or childless) do
             if kid.Visible~=false then
                if cdebug then
                   print(string.char(27).."[32mDEBUG>"..string.char(27).."[0m Processing kid: "..(kid.dbgid or "idless "..kid.kind).."; from parent: "..(self.dbgid or "idless "..self.kind))
                end            
                local tp = kid:PerformDraw('RECURSE')
                for ip,lp in ipairs(tp or childless) do 
                    for f in each(lp) do priolist[ip][#priolist[ip]+1]=f end
                end 
             end
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
                    love.graphics.print(iprio..": Drawing a "..(d[2].kind or "superior").." at ("..d[2]:TX()..","..d[2]:TY()..") >> "..d[2]:TW().."x"..d[2]:TH().."   ("..(d[2].dw or "nil").."/"..(d[2].dh or "nil")..")   "..(d[2].dbgid or "noid").." from parent "..((d[2].parent or {}).dbgid or "idlessparent"),0,pddebug)
                    pddebug = pddebug + 20
                 end
             end
         end                             
     end ,
     
     ReCreate = function(self)
        print("Recreating:"..(self.kind or 'superior')) 
        if self.onCreate then self:onCreate() end
        for _,kid in pairs(self.kids or childless) do
           kid:ReCreate()
        end            
     end,
     
     Pure = function(self,truef,depf)
        return pures[depf or 'absolute'](self,truef,scd[truef])
     end,
     
     Stat = function(self,s)
         return tonumber(self:Pure(s,self["d"..scd[s]])) or 0
     end,
     
     TX = function(self) if self.superior then return 0 else return self.parent:TX()+self:Stat("x") end end,           
     TY = function(self) if self.superior then return 0 else return self.parent:TY()+self:Stat("y") end end,
     TW = function(self) return self:Stat("w") end,
     TH = function(self) return self:Stat("h") end,    
     
     TrueCoords = function(self) 
        return self:TX(),self:TY(),self:TW(),self:TH() 
     end,
     
     Parents = function(self,donotincludeself) -- For use in for routines. Goes way back to all parents until there are none any more.
        local wg = self
        local i=0
        local gtab = {}
        if not donotincludeself then gtab[1]=self end
        while not wg.superior do
            wg=wg.parent
            gtab[#gtab+1]=wg
        end
        return function()
           i=i+1
           return gtab[i]
        end
     end,
     
     Disabled=function(self)
        for gad in self:Parents() do
            if gad.Enabled==false then return true end
        end
        return false
     end,     
     
     SetColor=function(self,pref)
        local dv=1
        if self:Disabled() then dv=3 end
        if type(pref)=="string" then
           love.graphics.setColor((self[pref.."r"] or 1)/dv, (self[pref.."g"] or 1)/dv, (self[pref.."b"] or 1)/dv,(self[pref.."alpha"] or 1)/dv)
        else
          love.graphics.setColor((self.r or 1)/dv, (self.g or 1)/dv, (self.b or 1)/dv,(self.alpha or 1)/dv)
       end
     end,
          
     Color= function(self,r,g,b,alpha,scale)
         self.r=(r or scale)/(scale or 1)
         self.g=(g or scale)/(scale or 1)
         self.b=(b or scale)/(scale or 1)
         self.alpha=(alpha or scale)/(scale or 1)
     end,
     
     HexColor=function(self,hex)
        assert(#hex==6,"Invalid color code")
        self:color(tonumber("0x"..mid(hex,1,2)),tonumber("0x"..mid(hex,3,2)),tonumber("0x"..mid(hex,5,2)),255,255)
     end,
     
     PerformAction=function(self,data,data2)              
              if self.id  and maan[self.id.."_Action"] then 
                 maan[self.id.."_Action"](self,data,data2)
              elseif self.id  and maan[self.id.."_action"] then 
                 maan[self.id.."_action"](self,data,data2)
              elseif self.Action then
                 self:Action(data,data2)
              end 
     end,

     PerformSelect=function(self,data,data2)
              if self.id and maan[self.id.."_Select"] then 
                 maan[self.id.."_Select"](self,data,data2)
              elseif self.id and maan[self.id.."_select"] then 
                 maan[self.id.."_select"](self,data,data2)
              elseif self.Select then
                 self:Select(data,data2)
              end 
     end                            
}

local superior_methods = {  Draw=nothing }



core.MainGadget = {
       dbgid="superior",
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
        kid.parent=gadget
        core.AttachMethods(kid,meths) 
    end
end    

function core.RegisterGadget(kind,data)
    gadgettypes[kind]=data
end

-- Free all gadgets tied to the MainGadget
function core.FreeAll()
     for _,gadget in pairs(core.MainGadget.kids) do gadget:free() end
end

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


function core.Tree(pgadget,level) -- This is only for debugging purposes
    local gadget = pgadget or core.MainGadget
    local strings=string
    local tabs=""
    local l=level or 0
    local ret=""
    local ansi={[true]=strings.char(27).."[32m",[false]=strings.char(27).."[31m"}
    for i=1,l do tabs=tabs.."\t" end ret=ret..tabs 
    ret=ret..(gadget.kind or "MAIN GADGET").." "..(gadget.dbgid or "IDLESS")
    for _,kid in pairs(gadget.kids or childless) do
        ret=ret.."\n"..tabs..ansi[kid.parent==gadget]..kid.kind.." "..(kid.dbgid or "IDLESS")..string.char(27).."[0m\n"..core.Tree(kid,l+1).."\n\n"
    end
    return ret    
end 



return core
