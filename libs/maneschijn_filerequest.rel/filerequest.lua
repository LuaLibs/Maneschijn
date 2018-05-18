--[[
        filerequest.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.18
]]

-- $USE libs/maneschijn_gadgets
-- $USE libs/glob
-- $USE libs/path
-- $USE libs/jcrxenv

local core=maneschijn_core
local module = {}
local gui 

module.config = {
    background = 'libs/maneschijn_filerequest/assets/dfback.png', -- This picture is terrible, but at least it's something you can use. :P
    fieldbackcolor  = {0,0,.2},
    fieldfrontcolor = {0,0,.8} 
}
local config = copytable(module.config,true) -- When the user messes it up, I always go this backup :P


local function frq_init()
  gui = {
    id = "FILEREQUESTORSTUFF",
    filerequestordoesnthidethisgadgetwhenrunning=true,
    kind='quad',
    x=0,y=0,w="100%",h="100%",
    image = module.config.background or config.background,
    parent=core.MainGadget,
    kids={
        volumes = {
           x='2%',y='2%',w='15%',h='25%',kind='listbox',
            r = (module.config.fieldfrontcolors or config.fieldfrontcolors)[1],
            g = (module.config.fieldfrontcolors or config.fieldfrontcolors)[2],
            b = (module.config.fieldfrontcolors or config.fieldfrontcolors)[3],
           br = (module.config.fieldfrontcolors or config.fieldfrontcolors)[1],
           bg = (module.config.fieldfrontcolors or config.fieldfrontcolors)[2],
           bb = (module.config.fieldfrontcolors or config.fieldfrontcolors)[3],
        },
        favorites = {
           x='2%',y='30%',w='15%',h='58%',kind='listbox',
            r = (module.config.fieldfrontcolors or config.fieldfrontcolors)[1],
            g = (module.config.fieldfrontcolors or config.fieldfrontcolors)[2],
            b = (module.config.fieldfrontcolors or config.fieldfrontcolors)[3],
           br = (module.config.fieldfrontcolors or config.fieldfrontcolors)[1],
           bg = (module.config.fieldfrontcolors or config.fieldfrontcolors)[2],
           bb = (module.config.fieldfrontcolors or config.fieldfrontcolors)[3],
        }
    }    
  }
CreateGadget(gui)  
end
local volumes   =gui.kids.volumes
local favorites=gui.kids.favorites

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
             
   
function module.TrueRequest(ftype,caption,path,filter,save,unparsedflags)
    -- Init
    if not gui then frq_init() end
    local cpath = path or jcrxenv.get("FILEREQUESTORLASTPATH") or os.getenv("HOME"); assert(cpath,"No path to work with")
    local flags = frq_parseflags(unparsedflags)
    frq_GetVolumes()
    frq_favorites()
    
    -- Take over the flow. No matter what flow routine was active, this routine will take over until the file requesting is over
    
    -- Closure
    
end    


function module.RequestFile(caption,dir,filter,save,flags)
    return module.TrueRequest('file',caption,dir,filter,save,flags)
end
RequestFile=module.RequestFile



return module
