--[[
        script.lua
	(c) 2018 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 18.05.11
]]
local defaults = {

    buttons = {red={},green={},yellow={},brown={},grey={}}
}


-- button class
defbuttons=defaults.buttons
local function getbutton(self)
      -- $USE libs/qgfx
      return LoadImage(self.cname)
end
for k,b in pairs(defbuttons) do 
    b.cname=k
    b.get=getbutton
    print("Initized default button: "..k)
end          



return defaults
