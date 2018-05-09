--[[
        listbox.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.09
]]
-- $USE libs/maneschijn_core
-- $USE libs/qgfx
-- $USE libs/nothing
local core=maneschijn_core
local lijst={}

function lijst:InitFont(fnt,siz)
   self.font=fnt
   self.fontsize=siz or 20
   self.maxshow=math.floor(self:TH()/self.fontsize)
   if not self.font then self.fontsize=siz or 20 return end
   self.fontfont = love.graphics.newFont( self.font )   
end

function lijst:onCreate()
   self.items=self.items or {}
   self.br=self.br or 40 /255
   self.bg=self.bg or 40 /255
   self.bb=self.bb or 40 /255
   self.r =self. r or 200/255
   self.g =self. g or 200/255
   self.b =self. b or 200/255      
   self.balpha = self.balpha or .75
   self:InitFont(self.font,self.fontsize)
   self.ident = self.ident or ({[true]=self.fontsize or 20,[false]=2})[self.allowicons]
   self.py=self.py or 0
   self.selected=self.selected or {}
end   

function lijst:Draw()
   self:SetColor('b')
   --print(self:TrueCoords(),'fill') -- debug
   local a,b,c,d=self:TrueCoords() --print(a,b,c,d)
   Rect(a,b,c,d,'fill')  
   local tr,tg,tb=self.br*1.25,self.bg*1.25,self.bb*1.25
   local ur,ug,ub=self.br*0.75,self.bg*0.75,self.bb*0.75
   if tr>1 then tr=1 end
   if tg>1 then tg=1 end
   if tb>1 then tb=1 end
   love.graphics.setColor(tr,tg,tb,1) 
   DrawLine(self:TX()-1,self:TY()-1,self:TX()-1,self:TY()+self:TH())
   DrawLine(self:TX()-1,self:TY()-1,self:TX()+self:TW(),self:TY()-1)
   love.graphics.setColor(tr,tg,tb,1) 
   DrawLine(self:TX()+self:TW()+1,self:TY(),self:TX()+self:TW()+1,self:TY()+self:TH()+1)   
   DrawLine(self:TX()+self:TW()+1,self:TY()+self:TH()+1,self:TX(),self:TY()+self:TH()+1)    
   local y=self:TY()
   local x=self:TX()
   for i=self.py+1,self.py+self.maxshow do if self.items[i] then
       if self.items[i].icon then
          white()
          DrawImage(self.items[i].icon,x+2,y+((i-1)*self.fontsize))
       end
       self:SetColor()
       love.graphics.print(self.items[i].text,x+self.ident,y+((i-1)*self.fontsize))
   end end  
end

function lijst:Clear(brute)
    if brute then
       self.items={}
       return
    end
    local n=#self.items
    for i=1,n do self.items[i]=nil end
end

--[[
function lijst:yupdate()
   for i,d in ipairs(self.items) do
       d.y=(i-1)*self.fontsize
   end
end   
]]

function lijst:Add(text,icon)
   if icon then assert(self.allowicons,"This listbox did not allow icons") end
   assert(type(text)=="string","Itemtext for listbox must be string")
   local iconpic
   if type(icon)=="string" then iconpic=LoadImage(icon) elseif type(icon)=="table" and type(icon.images)=="table" then iconpic=icon elseif icon~=nil then error("Invalid icon") end
   self.items[#self.items+1]={text=text,icon=iconpic}
   --self:yupdate()
end



core.RegisterGadget("listbox",lijst) 

-- $IF IGNORE 
return lijst
-- $FI
