--[[
        pivot.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.07
]]
-- $USE libs/maneschijn_core
local core=maneschijn_core


local pivot={}

function pivot:onCreate()
    self.w=self.w or 1
    self.h=self.h or 1
    self.dw = self.dw or "parent"
    self.dh = self.dh or "parent"
end


function CreatePivot(x,y,parent)
    local ret = {kind='pivot',x=x,y=y,parent=parent}
    CreateGadget(ret)
    return ret
end


core.RegisterGadget("pivot",pivot)    
