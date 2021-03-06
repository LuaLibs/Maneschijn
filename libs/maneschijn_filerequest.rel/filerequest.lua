--[[
        filerequest.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.23
]]

-- $USE libs/maneschijn_gadgets
-- $USE libs/glob
-- $USE libs/path
-- $USE libs/jcrxenv
-- $USE libs/nothing
-- $USE libs/qff

local core=maneschijn_core
local module = {}
local gui 
local dbclickchk=love.timer.getTime() 
local cb = { handlers = {
   -- Resize
   resize = function (w, h)
      -- Automatically resize all required gadgets
      core.MainGadget:ReCreate()
      -- Call back features that may be need to be called
      if maan.resize then return maan.resize(w, h) end      
   end,
   
   mousepressed= function (x,y,b,t,c)
      -- Original code, but we ain't gonna be using that -- if love.mousepressed then return love.mousepressed(x,y,b,t,c) end
      local tm=love.timer.getTime() dbclickchk=dbclickchk or tm
      local verschil=math.abs(tm-dbclickchk)
      local och=dbclickchk
      if verschil<=maan.doubleclicktimer then 
         --for m in core.MainGadget:irmeth('mousedoubleclick') do m(x,y,b,t,c) end
         maan.doubleclicked=true         
      else
         maan.doubleclicked=false
      end
      dbclickchk=tm
      --print("mousepress callback   (double="..sval(maan.doubleclicked).." << "..tm.."-"..och.."="..verschil..")")
      for m,g in gui:irmeth('mousepressed') do
          --print("Go for mousepress in: "..(g.dbgid or "something")) 
          m(g,x,y,b,t,c) 
      end
   end,
   
   mousereleased=function (x,y,b,t,c)
      --if love.mousereleased then return love.mousereleased(x,y,b,t,c) end
      for m,g in gui:irmeth('mousereleased') do m(g,x,y,b,t,c) end
    end,

    textinput = function(t)
      for m,g in gui:irmeth('textinput') do m(g,t) end
    end    
   

}}

local n = {}

-- debug
local xedebug
local  edebug

-- default config
module.config = {
    background      = 'Libs/maneschijn_filerequest.rel/assets/dfback.png', -- This picture is terrible, but at least it's something you can use. :P
    icon_directory  = 'Libs/maneschijn_filerequest.rel/assets/directory.png',
    fieldbackcolor  = {0, 0,.002},
    fieldfrontcolor = {0,.4,.8} ,
    labelcolor      = {0,0.705882,1}
}
local config = copytable(module.config,true) -- When the user messes it up, I always go this backup :P

local volumes,favorites,files,cpath,csave,diricon,filter,flags,cancelled,chosen,chbox

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
           br = (module.config.fieldbackcolor or config.fieldbackcolor)[1],
           bg = (module.config.fieldbackcolor or config.fieldbackcolor)[2],
           bb = (module.config.fieldbackcolor or config.fieldbackcolor)[3],
           action = function(self)
               local vi = self.selection
               local vs; if vi and vi<=self:Items() then vs=self:ItemText(vi) else return end
               -- $IF $LINUX
               cpath = "/"
               -- $FI
               
               -- $IF $MAC
               if vs=="/" then cpath="/" else cpath="/Volumes/"..vs end
               -- $FI
               
               -- $IF $WINDOWS
               cpath = vs .."/"
               -- $FI
               
               n.gfiles((filter or {})[1],flags.hidden)
           end
        },
        favorites = {
           x='2%',y='30%',w='15%',h='58%',kind='listbox',
            r = (module.config.fieldfrontcolor or config.fieldfrontcolor)[1],
            g = (module.config.fieldfrontcolor or config.fieldfrontcolor)[2],
            b = (module.config.fieldfrontcolor or config.fieldfrontcolor)[3],
           br = (module.config.fieldbackcolor or config.fieldbackcolor)[1],
           bg = (module.config.fieldbackcolor or config.fieldbackcolor)[2],
           bb = (module.config.fieldbackcolor or config.fieldbackcolor)[3],
           autostripdir=true,
           action = function(self)
               local vi = self.selection
               local vs; if vi and vi<=self:Items() then vs=self:ItemText(vi) else return end
               cpath = vs
               n.gfiles((filter or {})[1],flags.hidden)
           end
        },
        plusmin = {
           x='2%',y='90%',w='15%',h='8%',kind='pivot',
           kids = {
              add = {kind='button',x=   0 ,y=0,w='49%',h='100%',caption="+", dbutton='green', pbutton='blue',
              action = function(self)
                  local favs=jcrxenv.getmulti("FileRequest_Favorites")
                  table.sort(favs)
                  for d in each(favs) do 
                      if d==cpath then return end
                  end
                  favs[#favs+1]=cpath
                  favorites:Add(cpath)
                  jcrxenv.setmulti("FileRequest_Favorites",favs)                  
              end},
              rem = {kind='button',x='51%',y=0,w='49%',h='100%',caption="-", dbutton='red',   pbutton='brown', autoenable=function(self) local i = favorites.selection return i~=nil and i>0 and i<=favorites:Items() end,
              action = function(self) 
                 local favs=jcrxenv.getmulti("FileRequest_Favorites")
                 table.sort(favs)
                 local r = {}
                 for d in each(favs) do
                     if d~=favorites:ItemText(favorites.selection) then r[#r+1]=d end
                 end
                 favorites.selection=nil
                 favorites:Clear()
                 for d in each(r) do favorites:Add(d) end
              end
              }
           }
        },
        currentdir = {
           x='20%',y=2,w='60%',h=18,kind='label',
           r = (module.config.labelcolor or config.labelcolor)[1],
           g = (module.config.labelcolor or config.labelcolor)[2],
           b = (module.config.labelcolor or config.labelcolor)[3]
        },
        files = {
           x='20%', y=20,w='60%',h="60-",kind='listbox',allowicons=true,
            r = (module.config.fieldfrontcolor or config.fieldfrontcolor)[1],
            g = (module.config.fieldfrontcolor or config.fieldfrontcolor)[2],
            b = (module.config.fieldfrontcolor or config.fieldfrontcolor)[3],
           br = (module.config.fieldbackcolor or config.fieldbackcolor)[1],
           bg = (module.config.fieldbackcolor or config.fieldbackcolor)[2],
           bb = (module.config.fieldbackcolor or config.fieldbackcolor)[3],
           select=function(self,kz)
               if (not kz) or kz<0 or kz>self:Items() then return end
               local f  = self:ItemText(kz)
               chbox.text=f
               chbox.pos=#f
           end,
           action=function(self,kz)
               --print("files:action(",kz,")")
               if (not kz) or kz<0 or kz>self:Items() then return end
               local f  = self:ItemText(kz)
               local ff = cpath.."/"..f
               if qff.IsDir(ff) then 
                  cpath = ff
                  n.gfiles((filter or {})[1],flags.hidden)
               else
                  gui.kids.buttons.kids.ok:action()
               end   
           end
        },
        chosenfile = {
          x='20%',y="26-",kind='textfield',
            r = (module.config.fieldfrontcolor or config.fieldfrontcolor)[1],
            g = (module.config.fieldfrontcolor or config.fieldfrontcolor)[2],
            b = (module.config.fieldfrontcolor or config.fieldfrontcolor)[3],
           br = (module.config.fieldbackcolor or config.fieldbackcolor)[1],
           bg = (module.config.fieldbackcolor or config.fieldbackcolor)[2],
           bb = (module.config.fieldbackcolor or config.fieldbackcolor)[3],           
        },
        buttons = {
           x="82%", y=2, w="16%",h="100%", kind='pivot',
           kids = {
               ok={
                  kind='button',
                  x=0,y=0,w='100%',h="18",
                  buttontype='ok',
                  caption="Ok",
                  autoenable = function(self)
                     if not files.multiselect then
                        local i = files.selection
                        --print(i)
                        return i~=nil and i<=files:Items() and i>0
                     else
                        return #files.selections>0
                     end   
                  end,
                  action=function(self)
                           if files.multiselect then
                              assert(#files.selections>0,"Action should without files not be possible under these conditions")
                              if (not flags.dirs) and #files.selection==1 and qff.IsDir(cpath.."/"..files.selections[1]) then
                                 cpath=cpath.."/"..cpath.."/"..files.selections[1]
                                 n.gfiles((filter or {})[1],flags.hidden)
                                 return
                              end                             
                              chosen = {}
                              for a in each(files.selections) do
                                  local ff = cpath.."/"..a
                                  if (qff.IsDir(ff) and flags.dirs) or (qff.IsFile(ff and (not flags.dirs))) then chosen[#chosen+1]=ff end
                              end                              
                           else
                              local i = files.selection
                              assert(i~=nil and i<=files:Items() and i>0,"Action should without a selection not be possible under these conditions")
                              local r = cpath.."/"..files:ItemText(i)
                              if qff.IsDir(r) and not flags.dirs then 
                                 cpath=r
                                 n.gfiles((filter or {})[1],flags.hidden)
                                 return 
                              end
                              chosen = r
                           end      
                         end
               },
               cancel={
                  kind='button',
                  x=0,y=20,w='100%',h="18",
                  buttontype='cancel',
                  caption="Cancel",
                  action=function(self)
                           cancelled=true
                         end
               },
               parent={
                  kind='button',
                  x=0,y=60,w='100%',h="18",
                  caption="Parent",
                  autoenable=function(self)
                                local l = 1
                                
                                -- $IF $WINDOWS
                                   l = 3
                                -- $FI
                                
                                -- $IF !$WINDOWS
                                   l = 1
                                -- $FI
                                
                                return #cpath~=l
                             end,
                  action=function(self)
                            cpath = replace(cpath,"\\","/")
                            local s = mysplit(cpath,"/")
                            local np = ""
                            -- $IF $WINDOWS
                            np = left(cpath,2) -- Windows drive letter
                            -- $FI
                            for i=1,#s-1 do
                                np = np .. "/" .. s[i]
                            end
                            cpath=np    
                            if cpath=="" then cpath="/" end
                            -- $IF $WINDOWS
                            if #cpath==2 then cpath=cpath.."/" end
                            -- $FI
                            n.gfiles((filter or {})[1],flags.hidden)
                         end
               },
               makedir = {
                  kind='button',
                  x=0,y=80,w='100%',h="18",
                  caption="Createdir",
                  autoenable=function(self)
                                return csave
                             end,
                  action=function(self)
                         end
               },
               
           }
        }
        
    }    
  }
  CreateGadget(gui)
  volumes   = gui.kids.volumes
  favorites = gui.kids.favorites  
  files     = gui.kids.files
  chbox     = gui.kids.chosenfile
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

local function frq_GetFiles(filter,hidden)
    files:Clear()
    cpath=replace(cpath,"\\","/") -- Only / even in Windows
    cpath=replace(cpath,"//","/") -- Make sure no duplicate // exist, as they spook things up.
    if cpath=="~" then cpath=os.getenv("HOME") end
    local fls=cdglob(cpath,"*")
    local adds = {}
    for f in each(fls) do
        if f~="." and f~=".." and (hidden or (not prefixed(f,"."))) then
           --[[        
           if qff.isdir(cpath.."/"..f) then
              files:Add(f,diricon)
           else   
              files:Add(f)
           end 
           ]]
           local t=qff.filetype(cpath.."/"..f)
           local ic={directory=diricon}
           print(t,cpath.."/"..f)
           adds[t]=adds[t] or {}  
           adds[t][#adds[t]+1] = {f,ic[t]}
        end
    end
    -- print(serialize('adds',adds))                  
    for t,add in spairs(adds) do
        for a in each(add) do
            files:Add(a[1],a[2])
        end    
    end    
end     ; n.gfiles=frq_GetFiles
             
   
local dt
function module.TrueRequest(ftype,caption,path,pfilter,save,unparsedflags)
    -- Init
    cancelled = false
    chosen = nil
    diricon = diricon or LoadImage(module.config.icon_directory or config.icon_directory)
    csave=save==true
    if not gui then frq_init() end
    gui.Visible=true
    cpath = path or jcrxenv.get("FILEREQUESTORLASTPATH") or os.getenv("HOME"); assert(cpath,"No path to work with")
    flags = frq_parseflags(unparsedflags)
    filter = filter
    frq_GetVolumes()
    frq_favorites()
    frq_GetFiles((filter or {})[1],flags.hidden)
    
    -- Without this, go to hell!
    assert(love.event and love.graphics,"Required LOVE modules NOT present")
    
    -- Take over the flow. No matter what flow routine was active, this routine will take over until the file requesting is over
    while not (cancelled or chosen) do
        
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
        
        -- Dir always accurate
        gui.kids.currentdir.caption=cpath
        
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
    return chosen
end    

function module.GUIRESET()
   if gui then  gui:Free() gui=nil end
end   

function module.RequestFile(caption,dir,filter,save,flags)
    return module.TrueRequest('file',caption,dir,filter,save,flags)
end
RequestFile=module.RequestFile



return module
