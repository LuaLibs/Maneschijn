--[[
        filerequest.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.19
]]

-- $USE libs/maneschijn_gadgets
-- $USE libs/glob
-- $USE libs/path
-- $USE libs/jcrxenv
-- $USE libs/nothing

local core=maneschijn_core
local module = {}
local gui 
local cb = {}

-- debug
local xedebug
local  edebug

-- default config
module.config = {
    background = 'Libs/maneschijn_filerequest.rel/assets/dfback.png', -- This picture is terrible, but at least it's something you can use. :P
    fieldbackcolor  = {0,0,.2},
    fieldfrontcolor = {0,0,.8} 
}
local config = copytable(module.config,true) -- When the user messes it up, I always go this backup :P

local volumes,favorites

local function frq_init()
  gui = {
    id = "FILEREQUESTORSTUFF",
    filerequestordoesnthidethisgadgetwhenrunning=true,
    kind='quad',
    x=0,y=0,w="100%",h="100%",
    texture = module.config.background or config.background,
    parent  = core.MainGadget,
    kids={
        volumes = {
           x='2%',y='2%',w='15%',h='25%',kind='listbox',
            r = (module.config.fieldfrontcolor or config.fieldfrontcolor)[1],
            g = (module.config.fieldfrontcolor or config.fieldfrontcolor)[2],
            b = (module.config.fieldfrontcolor or config.fieldfrontcolor)[3],
           br = (module.config.fieldfrontcolor or config.fieldfrontcolor)[1],
           bg = (module.config.fieldfrontcolor or config.fieldfrontcolor)[2],
           bb = (module.config.fieldfrontcolor or config.fieldfrontcolor)[3],
        },
        favorites = {
           x='2%',y='30%',w='15%',h='58%',kind='listbox',
            r = (module.config.fieldfrontcolor or config.fieldfrontcolor)[1],
            g = (module.config.fieldfrontcolor or config.fieldfrontcolor)[2],
            b = (module.config.fieldfrontcolor or config.fieldfrontcolor)[3],
           br = (module.config.fieldfrontcolor or config.fieldfrontcolor)[1],
           bg = (module.config.fieldfrontcolor or config.fieldfrontcolor)[2],
           bb = (module.config.fieldfrontcolor or config.fieldfrontcolor)[3],
        }
    }    
  }
  CreateGadget(gui)
  volumes   = gui.kids.volumes
  favorites = gui.kids.favorites  
end

local function frq_GetVolumes()
    volumes:Clear()
    -- $IF $WINDOWS
    for i=1,26 do 
        volumes:Add(string.char(64+i))
    end
    -- $FI
    -- $IF $LINUX
    volumes:Add("/")
    -- $FI
    -- $IF $MAC
    volumes:Add("/")
    for f in each(glob("/Volumes/*")) do
        volumes:Add(StripDir(f))
    end
    -- $FI
end        

local function frq_parseflags(flags)
   local ret = {}   
   local work
   if     type(flags)=='string' then work=mysplit(flags,";")
   else   work=flags end
   if not work then return {} end
   for k,v in pairs(work) do
       if     type(k)=='number' and type(v)=='string' then ret[v]=true
       elseif type(k)=='string' and v==true           then ret[k]=true
       else   error("I don't understand the flag setup!") end
   end    
   return ret
end

local function frq_favorites()
    favorites:Clear()
    for fav in each(jcrxenv.getmulti("FileRequest_Favorites") or {}) do
        favorites:Add(fav)
    end
end                           

local function autoset(gadget,fname,field)
     if gadget['auto'..fname] then gadget[field]=gadget['auto'..fname]() end
     if gadget.kids then 
        for _,kid in pairs(gadget.kids) do autoset(kid,fname,field) end 
     end
end     
             
   
local dt
function module.TrueRequest(ftype,caption,path,filter,save,unparsedflags)
    -- Init
    if not gui then frq_init() end
    gui.Visible=true
    local cpath = path or jcrxenv.get("FILEREQUESTORLASTPATH") or os.getenv("HOME"); assert(cpath,"No path to work with")
    local flags = frq_parseflags(unparsedflags)
    frq_GetVolumes()
    frq_favorites()
    
    -- Without this, go to hell!
    assert(love.event and love.graphics,"Required LOVE modules NOT present")
    
    -- Take over the flow. No matter what flow routine was active, this routine will take over until the file requesting is over
    while true do
        
        --love.graphics.clear()        
        -- Process events.
        if love.event then
           love.event.pump()        
           for name, a,b,c,d,e,f in love.event.poll() do
               -- Quit process is the same
               if name == "quit" then
                  gui.Visible=false
                  return nil
                  --[[
                  if not love.quit or not love.quit() then
                     core.MainGadget.cantkill=false
                     core.MainGadget:free()
                     return a or 0
                  end
                  ]]
               end
               --love.handlers[name](a,b,c,d,e,f)
               if edebug or (xedebug and (not cb.handlers[name])) then print("Event triggered: ",name,"\nParameters: ",a,b,c,d,e,f) end
               (cb.handlers[name] or nothing)(a,b,c,d,e,f)
               -- Please note the call to love for non-existent handlers is only a temporary measure to prevent bugs and crashes, but is deprecated from the start!
           end
        end
        -- autoenable/visibility
        autoset(gui,'enable','Enabled')
        autoset(gui,'visible','Visible')
        
        -- Update timer value  
        dt = love.timer.step()
      
        -- Update all timer based gadgets
        gui:UpdateTimer(dt)
      
        -- Draw
        if love.graphics and love.graphics.isActive() then
           love.graphics.origin()
           love.graphics.clear(love.graphics.getBackgroundColor())
           gui:PerformDraw()
        end   
        
       love.graphics.present()
    end
    -- Closure
    gui.Visible=false
end    


function module.RequestFile(caption,dir,filter,save,flags)
    return module.TrueRequest('file',caption,dir,filter,save,flags)
end
RequestFile=module.RequestFile



return module
