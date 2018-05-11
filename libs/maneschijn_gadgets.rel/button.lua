--[[
        button.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.11
]]

-- $USE libs/maneschijn_core
-- $USE libs/qgfx
-- $USE libs/nothing
local core=maneschijn_core
local debug=true

local function dp(a)
   if debug then print(a) end
end   


local knopje={}

function knopje:SetCaption(caption)
    self.caption=caption or self.caption or ""
    self:SetFont()
    self.TextTex=love.graphics.newText(self.loadedfont,caption)
    self.TextImg=LoadImage(self.TextTex)
    HotCenter(self.TextImg)
end

function knopje:onCreate()
    -- dbutton = default button (for calls to the default graphics)
    -- cbutton = custom button or create button (for creation only. Will be linked to the true button)
    -- tbutton = true button
    if self.tbutton then
       nothing()
    elseif self.cbutton then
       self.tbutton=self.cbutton
       self.cbutton.stretch=self.cbutton.stretch~=false
    else   
       assert(maneschijn_defaultgraphics,"The usage of the 'dbutton' field requires the maneschijn_defaultgraphics library to be loaded.\nWithout it you are solely dependent on the cbutton settings!")
       local dcol='grey'
       if self.buttontype=='ok' then dcol='blue' elseif self.buttontype=='cancel' then dcol='red' end
       local dbc = self.dbutton or dcol
       self.tbutton={texture='libs/maneschijn_defaultgraphics.rel/buttons/'..dbc..".png",stretch=true}
    end
    self.tbutton.butimage = self.tbutton.butimage or LoadImage(self.tbutton.texture)
    local iw,ih=ImageSizes(self.tbutton.butimage)
    local gw,gh=self:Stat("w",'dw'),self:Stat('h','dh')
    if self.tbutton.stretch then
       self.tbutton.sw,self.tbutton.sh=gw/iw,gh/ih
    else
       self.tbutton.sw,self.tbutton.sh=1,1
    end    
    self.btr=self.btr or 1
    self.btg=self.btg or 1
    self.btb=self.btb or 1      
    self.frame=self.frame or 1
    self:SetCaption(self.caption)
end

function knopje:Draw()
    self:SetColor('bt')    
    DrawImage(self.tbutton.butimage,self:TX(),self:TY(),self.frame,0,self.tbutton.sw,self.tbutton.sh)
    self:SetColor()
    DrawImage(self.TextImg,self:TX()+(self:TW()/2),self:TY()+(self:TH()/2))
end



core.RegisterGadget("button",knopje) 
