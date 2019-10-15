local addonName, NS = ...
NS = NS or {}
NS.logic = {}

local COMMPREFIX = "ScepCalendarComm"
local Requests = {
    HELLO = "hello",
    DB_EXPORT = "exportDB"
}
local RequestType = {
    REQUEST = "request",
    RESPONSE = "response"
}

local waitTable = {}
local waitFrame = nil

function ScepCalendar_wait(delay, func, ...)
    if (type(delay) ~= "number" or type(func) ~= "function") then
        return false
    end
    if (waitFrame == nil) then
        waitFrame = CreateFrame("Frame", "WaitFrame", UIParent)
        waitFrame:SetScript(
            "onUpdate",
            function(self, elapse)
                local count = #waitTable
                local i = 1
                while (i <= count) do
                    local waitRecord = tremove(waitTable, i)
                    local d = tremove(waitRecord, 1)
                    local f = tremove(waitRecord, 1)
                    local p = tremove(waitRecord, 1)
                    if (d > elapse) then
                        tinsert(waitTable, i, {d - elapse, f, p})
                        i = i + 1
                    else
                        count = count - 1
                        f(unpack(p))
                    end
                end
            end
        )
    end
    tinsert(waitTable, {delay, func, {...}})
    return true
end

ScepCalendar = LibStub("AceAddon-3.0"):NewAddon("ScepCalendar", "AceConsole-3.0", "AceComm-3.0", "AceSerializer-3.0")

function ScepCalendar:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ScepCalendarDB")
    self.db.profiles.dbVersion = self.db.profiles.dbVersion or 1
    print("DB_VERSION: " .. self.db.profiles.dbVersion)
    self:RequestHello()
end

function ScepCalendar:OnEnable()
    self:Print("Merci d'utiliser ScepCalendar. Reportez les bugs en courrier in game à Bordel.")
end

function ScepCalendar:OnDisable()
end

function ScepCalendar:OnCommCallback(message, channel, sender)
    if (sender ~= NS.config.characterName) then
        local success, data = ScepCalendar:Deserialize(message)

        if (not success) then
            print("Could not deserialize " .. message .. " from " .. sender)
        elseif (data.request == Requests.HELLO) then
            print("received hello from " .. sender)
            ScepCalendar:OnReceiveHello(data, sender)
        else
            print(
                "UNKNOWN COMM RECEIVED: channel: " ..
                    channel .. " message: '" .. message .. "'" .. " sender: " .. sender
            )
        end
    end
end

function ScepCalendar:Send(data, sender)
    local channel
    if sender then
        channel = "WHISPER"
    else
        channel = "GUILD"
    end
    ScepCalendar:SendCommMessage(COMMPREFIX, ScepCalendar:Serialize(data), channel, sender)
end

-- REQUESTS
-- Hello: sends hello with the version of the addon
function ScepCalendar:RequestHello()
    local rqData = {
        type = RequestType.REQUEST,
        request = Requests.HELLO,
        addonVersion = NS.config.addonVersion,
        dbVersion = self.db.profiles.dbVersion
    }
    self:Send(rqData)
end

local receivedVersions = {}
local helloBatchRunning = false

-- Responds to the sender with its own data and version if it's superior
function ScepCalendar:OnReceiveHello(data, sender)
    receivedVersions[#receivedVersions + 1] = {
        {version = data.dbVersion, sender = NS.characterName}
    }

    print("received version " .. receivedVersions[1])
    local afterWait = function()
        local highestVersion = self.db.profiles.dbVersion
        for i = 1, #receivedVersions, 1 do
            print(receivedVersions[i])
            if (receivedVersions[i] > highestVersion) then
                highestVersion = receivedVersions[i]
            end
        end
        receivedVersions = {};
        print("Highest version received =  " .. highestVersion)
        helloBatchRunning = false
    end
    if (not helloBatchRunning) then
        helloBatchRunning = true
        ScepCalendar_wait(10, afterWait)
    end
    --[[
    if (data.dbVersion < self.db.profiles.dbVersion) then
        local rqData = {
            type = RequestType.RESPONSE,
            request = Requests.HELLO,
            addonVersion = NS.config.addonVersion,
            dbVersion = self.db.profiles.dbVersion
        }
        print("sending hello to " .. sender)
        self:Send(rqData)
    elseif (data.dbVersion > self.db.profiles.dbVersion) then
        -- Received version is superior, need update
    end
    if (data.addonVersion > NS.config.addonVersion) then
        message("Une nouvelle version de l'addon est disponible. Télécharge la vite fait stp.")
    end
    ]]
end

ScepCalendar:RegisterComm(COMMPREFIX, ScepCalendar.OnCommCallback)

--------- EVENT METHODS ------------
local dummyEvent = {
    id = NS.utils.generateEventId(),
    title = "title",
    description = "description",
    author = "ta mere",
    day = 12,
    month = 12,
    year = 2019,
    hour = 20,
    minutes = 45,
    roster = {}
}

function ScepCalendar:CreateNewEvent(eventData)
end
