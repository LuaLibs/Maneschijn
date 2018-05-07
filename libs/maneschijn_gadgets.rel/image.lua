--[[
        image.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.07
]]
-- $USE libs/maneschijn_core
-- $USE libs/nothing
local core=maneschijn_core
local plaatje={}


function plaatje:hot(h,v)
    if type(h)=='number' and type(v)=='number' then return Hot(self,h,v) end
    self.hoth=h or self.hoth or "l"
    self.hotv=v or self.hotv or "t"
    QHot(self.imgtexture,self.hoth..self.hotv)
end    

function plaatje:texload(forcereload)
    if forcereload then self.imgtexture=nil end
    self.imgtexture = self.imgtexture or LoadImage(self.image)
    self:hot()
end

function plaatje:onCreate()
   self:texload()
end

function plaatje:Draw()
     self:SetColor()
     self.Frame=self.Frame or 1
     --for k,v in spairs(self) do print("Image has key:",k,"for:",type(v)) end
     DrawImage(self.imgtexture,self:TX(),self:TY(),self.Frame)
end


function CreateImage(x,y,image,parent)
   local ret = {kind='image',x=x,y=y,parent=parent}
   return CreateGadget(ret)
end      




core.RegisterGadget("image",plaatje)    




