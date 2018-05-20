--[[
label.lua
Copyright (C) 2018 Jeroen P. Broks
Permission is hereby granted, free of charge, to any person obtaining a copy of 
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights 
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
THE SOFTWARE.
Version 18.05.20
]]
-- $USE libs/maneschijn_core

local core = maneschijn_core

local l = {}

function l:Draw()
     self:SetColor()
     love.graphics.setFont(self.font or core.deffont)
     love.graphics.print(self.caption or "",self:TX(),self:TY())
end

function CreateLabel(text,x,y,parent,font)
    local g={ caption=text,x=x,y=y,parent=parent,font=font,kind='label' }
    CreateGadget(g)
    return g
end

core.RegisterGadget("label",l)     

return true
