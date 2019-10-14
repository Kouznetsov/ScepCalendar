local _, NS = ...
NS = NS or {}
NS.logic = {}

ScepCalendar = LibStub("AceAddon-3.0"):NewAddon("ScepCalendar", "AceConsole-3.0", "AceComm-3.0")

function ScepCalendar:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ScepCalendarDB");
end

function ScepCalendar:OnEnable()
    self:Print("coucou")
    -- Called when the addon is enabled
end

function ScepCalendar:OnDisable()
    print("ScepCalendar disabled")
    -- Called when the addon is disabled
end

local onCommCallback = function(prefix, message, channel, sender)
    print("Received  new comm: " .. "prefix: '" .. prefix .. "' message: '" .. message .. "'")
end
local COMMPREFIX = "ScepCalendarComm"

ScepCalendar:RegisterComm(COMMPREFIX, onCommCallback)
--ScepCalendar:SendCommMessage(COMMPREFIX, "c", "GUILD"); -- works

function ScepCalendar:CreateNewEvent()
    
end

NS.logic.getEventsForMonth = function(month, year)

end
