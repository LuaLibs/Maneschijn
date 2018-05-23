--[[
        textfield.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.23
]]
-- $USE libs/maneschijn_core
-- $USE libs/qgfx
-- $USE libs/nothing
local core=maneschijn_core


local txt = {}

function txt:InitFont(fnt,siz)
   self.font=fnt
   self.fontsize=siz or 20
   --self.maxshow=math.floor(self:TH()/self.fontsize)
   if not self.font then self.fontsize=siz or 20 return end
   self.fontfont = love.graphics.newFont( self.font )   
end


function txt:CompileSizes()
    self.widthby = self.widthby or "font"
    self.maxlen=self.maxlen or 20
    self.h = self.h or self.fontsize or 20
    if     self.widthby=="font" then
           self.w = math.floor(self.maxlen*self.fontsize)
           self.h = self.fontsize
    elseif self.widthby=="width" then
           self.maxlen = math.floor(self:TW()/self.fontsize)
           --self.h = self.fontsize
    elseif self.widthby=="ignore" then
           -- Just do nothing.
    else
           error("[listbox]:CompileSizes(): I don't know what to do with widthby: "..sval(self.widthby))           
    end
    self.rect = { bx=self:TX(), by=self:TY(), ex=self:TW()+self:TX(), ey=self:TH()+self:TY(), w=self:TW(), h=self:TH()  }              
end

function txt:onCreate()
    -- $USE libs/utf8
   self:InitFont(self.font,self.fontsize)
   self:CompileSizes()
   self.br  =self. br or 40 /255
   self.bg  =self. bg or 40 /255
   self.bb  =self. bb or 40 /255
   self.r   =self.  r or 200/255
   self.g   =self.  g or 200/255
   self.b   =self.  b or 200/255         
end

function txt:Draw()
   -- Rect itself
   local r=self.rect
   self:SetColor('b')
   love.graphics.rectangle('fill',r.bx,r.by,r.w,r.h)
   -- Lines around it
   local c=love.graphics.setColor
   local l=love.graphics.line
   local tr = self.br*2; if tr>1 then tr=1 end    
   local tg = self.bg*2; if tg>1 then tg=1 end    
   local tb = self.bb*2; if tb>1 then tb=1 end    
   local br = self.br/2    
   local bg = self.bg/2    
   local bb = self.bb/2   
   c(br,bg,bb,1)
   l(r.bx-1,r.by-1,r.ex+1,r.by-1) -- top
   l(r.bx-1,r.by-1,r.bx-1,r.ey+1) -- left
   c(tr,tg,tb,1)
   l(r.bx-1,r.ey+1,r.ex+1,r.ey+1) -- bottom
   l(r.ex+1,r.by-1,r.ex+1,r.ey+1) -- right
   -- Text config
   self.text = self.text or ""
   self.cursor = self.cursor or "_"
   self.pos = self.pos or #self.text
   self:SetColor()
   local out=""
   if self.pos>0          then out=     left (self.text,self.pos) end
   if self:Active() then out = out .. self.cursor end
   if self.pos<#self.text then out=out..right(self.text,#self.text-self.pos) end
   love.graphics.print(out,r.bx,r.by)
end

function txt:mousepressed(x,y,b)
     if debug then print("MOUSEPRESS DETECTED ON LISTBOX: "..(self.dbgid or "IDLESS")) end
     if not(x<self:TX() or y<self:TY() or x>self:TX()+self:TW() or y>self:TY()+self:TH()) then
        --if debug then print("MOUSEPRESS OUTSIDE THE FIELD") end 
        --return
        self:Activate() 
     end
end

function txt:textinput(t)
    if not self:Active() then return end
    if (#self.text)>=(self.maxlen or 20) then return end
    if #t~=utf8.len(t) and (self.pos~=#self.text or #self.text==0) then return end
    -- self.upos = utf8.offset(self.text,self.pos)
    print("Got:",t,#t,self.pos,self.text)
    local n = ""
    if self.pos~=0 then n = left (self.text,self.pos) end
    n = n .. t
    if self.pos~=#self.text then n = n .. right(self.text,#self.text-self.pos) end
    self.pos = self.pos + #t
    self.text = n
    print("Ret: ",self.text,self.pos,#self.text)
end    
    

core.RegisterGadget("textfield",txt) 


-- $IF IGNORE
return txt
-- $FI
