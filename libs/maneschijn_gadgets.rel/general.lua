--[[
        general.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.07
]]


-- $USE libs/maneschijn_core
local core=maneschijn_core

local algemeen={}

function CreateGadget(gadget)
     core.StatCalc(gadget)
     core.AttachMethods(gadget)
end

return algemeen
