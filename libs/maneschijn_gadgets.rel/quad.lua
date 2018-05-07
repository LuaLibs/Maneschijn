--[[
        quad.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.07
]]
-- $USE libs/maneschijn_core
-- $USE libs/qgfx
local core=maneschijn_core
local quadmodule={}

-- Methods for kquad
local kquad = {}

function kquad:initquad()
    local x = self.insert_x or 0
    local y = self.insert_y or 0
    local sw,sh=ImageSizes(self.imgtexture)
    local width,height=self:TW(),self:TH()
    self.imgtexture:setWrap(self.xwrap or 'repeat',self.ywrap or 'repeat')
    self.quadtexture = love.graphics.newQuad( x, y, width, height, sw, sh )
end

function kquad:texload(forcereload)
    if forcereload then self.imgtexture=nil end
    self.imgtexture = self.imgtexture or LoadImage(self.texture)
    self:initquad()
end

function kquad:onCreate()
     assert(self.texture,"No texturedata found")
     self.w = self.w or 1
     self.h = self.h or 1
     core.StatCalc(self)
     assert(self.w>0 and self.h>0,"Invalid width and height\n"..serialize("gadget",self))
     self:texload()
end

function kquad:onResize() self:initquar() end

function kquad:Draw()
     self.frame=self.frame or 1
     QuadImage(self.imgtexture,self.quadtexture,self:TX(),self:TY(),self.frame)
end


function CreateQuad(x,y,w,h,image,parent)
     assert(x and y and w and h and image and parent,"CreateQuad: Missing parameters")
     local quad = {
          kind='quad',
          x=x,
          y=y,
          w=w,
          h=h,
          xwrap='repeat',
          ywrap='repeat',
          image=image,
          parent=parent,
          kids={}          
     }
     CreateGadget(quad)
     return quad
end

core.RegisterGadget("quad",kquad)
return quadmodule
