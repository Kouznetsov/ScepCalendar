local _, NS = ...;
NS = NS or {};
NS.config = {}
NS.config.addonVersion = 1
NS.config.dbVersion = 1

local l = {
    "a2321281c76b3d375fee0e49b0fde8e31758a849b3a34410b5227220b1430fea", 
    "d43b518b8391f7fc1e525cc1062eaeca40e3f0791fa042dfb427fe9ca09a278c",
    "13d75b53f95d2516ecc4d72b6edafe0aac711704114e77e1332e5e37e3c449f6",
};
local c = NS.utils.sha256(UnitName("player"));
NS.config.characterName = UnitName("player");

NS.config.isAdmin = false;

for k,v in next, l do
    if (v == c) then 
        NS.config.isAdmin = true;
        break;
    end
end

NS.utils.generateEventId = function()
    return NS.utils.sha256(NS.config.characterName .. time());
end

