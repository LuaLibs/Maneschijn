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