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
    RESPONSE = "response",
    BROADCAST = "broadcast"
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
            ScepCalendar:OnReceiveHello(data, sender)
        elseif (data.request == Requests.DB_EXPORT) then
            ScepCalendar:OnReceiveDbExport(data)
        else
            print(
                "UNKNOWN COMM RECEIVED: channel: " ..
                    channel .. " message: '" .. message .. "'" .. " sender: " .. sender
            )
            print("request = " .. data.request)
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
        rqType = RequestType.REQUEST,
        request = Requests.HELLO,
        version = self.db.profiles.dbVersion
    }
    print("requesting HELLO")
    self:Send(rqData)
end

local receivedVersions = {}
local helloBatchRunning = false
local newAddonVersionAvailable = false
ScepCalendar.newAddonVersionShown = false

-- Responds to the sender with its own data and version if it's superior
function ScepCalendar:OnReceiveHello(data, sender)
    if (data.rqType == RequestType.REQUEST) then
        print("Received a HELLO request")
        local rqData = {
            rqType = RequestType.RESPONSE,
            request = Requests.HELLO,
            addonVersion = NS.config.addonVersion,
            version = self.db.profiles.dbVersion
        }
        if (data.version > self.db.profiles.dbVersion) then 
            print("Received DB version > to ours, asking for his DB")
            ScepCalendar:RequestExportDB(sender)
        else 
            print("Sending own version as response to " .. sender)
            self:Send(rqData, sender)
        end
    elseif data.rqType == RequestType.RESPONSE then
        print("Received a HELLO response")
        receivedVersions[#receivedVersions + 1] = {
            version = data.version,
            sender = sender,
            addonVersion = data.addonVersion
        }
        print("received version " .. data.version .. " from " .. sender)
        local afterWait = function()
            local highestVersion = {version = self.db.profiles.dbVersion, sender = NS.config.characterName}

            for i = 1, #receivedVersions, 1 do
                if (receivedVersions[i].version > highestVersion.version) then
                    highestVersion = receivedVersions[i]
                end
                if (receivedVersions[i].addonVersion > NS.config.addonVersion) then
                    newAddonVersionAvailable = true
                end
            end
            receivedVersions = {}
            print("Highest version received =  " .. highestVersion.version .. " from " .. highestVersion.sender)
            if (newAddonVersionAvailable == true and ScepCalendar.newAddonVersionShown == false) then
                ScepCalendar:Print("Une nouvelle version de l'addon est dispo sur discord. Chope la vite fait.")
                ScepCalendar.newAddonVersionShown = true
            end
            if (highestVersion.sender ~= NS.config.characterName) then
            -- If i don't have the highest DB version
            -- TODO Envoyer une demande de db export à highestVersion.sender
            end
            helloBatchRunning = false
        end
        if (not helloBatchRunning) then
            helloBatchRunning = true
            ScepCalendar_wait(5, afterWait)
        end
    end
end

function ScepCalendar:OnReceiveDbExport(data, sender) 
    if (data.rqType == RequestType.REQUEST) then
        print("Receive DB Export request")
        ScepCalendar:ExportDB(sender)
    elseif data.rqType == RequestType.RESPONSE then
        print("Receive DB Export response")
        if data.version > self.db.profiles.dbVersion then
            print("version superior to ours, taking received DB")
            self.db.profiles.events = data.db
            self.db.profiles.dbVersion = data.version
        end
    end
end

function ScepCalendar:RequestExportDB(sender)
    local rqData = {
        rqType = RequestType.REQUEST,
        request = Requests.DB_EXPORT,
    }
    ScepCalendar:Send(rqData, sender)
end

function ScepCalendar:ExportDB(sender)
    local rqData = {
        rqType = RequestType.RESPONSE,
        request = Requests.DB_EXPORT,
        db = self.db.profiles.events,
        version = self.db.profiles.dbVersion
    }
    print("sending our own DB")
    ScepCalendar:Send(rqData, sender);    
end

ScepCalendar:RegisterComm(COMMPREFIX, ScepCalendar.OnCommCallback)

--------- EVENT METHODS -----------
local eventsFakeDb = {
    {
        id = "Fakeid1",
        title = "Halloween",
        description = "Une certaine description de merde bien longue à afficher juste pour casser les couilles putainde nom de dieu de bordel de merde",
        author = "Bordel",
        day = 31,
        month = 10,
        year = 2019,
        hour = 20,
        minutes = 45,
    },
    {
        id = "Fakeid2", 
        title = "Halloween2",
        description = "Une certaine description de merde bien longue à afficher juste pour casser les couilles putainde nom de dieu de bordel de merde",
        author = "Sildarion",
        day = 31,
        month = 10,
        year = 2019,
        hour = 20,
        minutes = 45,
    }, {
        id = "Fakeid3", 
        title = "Halloween3",
        description = "Une certaine description de merde bien longue à afficher juste pour casser les couilles putainde nom de dieu de bordel de merde",
        author = "Lïena",
        day = 31,
        month = 10,
        year = 2019,
        hour = 20,
        minutes = 45,
    }, {
        id = "Fakeid3", 
        title = "RAID ONY + MC CE SOIR BOUGEZ VOUS",
        description = " de dieu de bordel de merde",
        author = "Kurt",
        day = 31,
        month = 10,
        year = 2019,
        hour = 20,
        minutes = 45,
    },
    {
        id = "Fakeid5", 
        title = "coucou",
        description = "Une certaine description de merde bien longue à afficher juste pour casser les couilles putainde nom de dieu de bordel de merde",
        author = "Sildarion",
        day = 2,
        month = 2,
        year = 2020,
        hour = 20,
        minutes = 45,
    },
}

function DeepPrint (e)
    -- if e is a table, we should iterate over its elements
    if type(e) == "table" then
        for k,v in pairs(e) do -- for every element in the table
            print(k)
            DeepPrint(v)       -- recursively repeat the same procedure
        end
    else -- if not, we can just print it
        print(e)
    end
end

function ScepCalendar:CreateNewEvent(eventData)
    ScepCalendar.db.profiles.events = ScepCalendar.db.profiles.events or {}

    --ScepCalendar.db.profiles.events[#ScepCalendar.db.profiles.events + 1] = eventData
    ScepCalendar.db.profiles.events[eventData.year] = ScepCalendar.db.profiles.events[eventData.year] or {}
    ScepCalendar.db.profiles.events[eventData.year][eventData.month] = ScepCalendar.db.profiles.events[eventData.year][eventData.month] or {}
    ScepCalendar.db.profiles.events[eventData.year][eventData.month][eventData.day] = ScepCalendar.db.profiles.events[eventData.year][eventData.month][eventData.day] or {}
    local r = ScepCalendar.db.profiles.events[eventData.year][eventData.month][eventData.day];
    ScepCalendar.db.profiles.events[eventData.year][eventData.month][eventData.day][#r + 1] = eventData
    

    --print("Creating event with title from db = " .. ScepCalendar.db.profiles.events[eventData.year][eventData.month][eventData.day][1].title)
    print("creating event for date " .. eventData.day .. "/" .. eventData.month .. "/" .. eventData.year)
    print("testing: " .. ScepCalendar.db.profiles.events["2019"][11][30][1].title)
    ScepCalendar.db.profiles.dbVersion = ScepCalendar.db.profiles.dbVersion + 1
    print("Create event")
    ScepCalendar:ExportDB();
end


function ScepCalendar:GetEventsForDay(day, month, year)
    --print(day .. "/" .. month .. "/" .. year)
    
    --DeepPrint(ScepCalendar.db.profiles.events)
    
   --[[] if (ScepCalendar.db.profiles.events[year]) then
        print("there are events this year" .. year)
        if (ScepCalendar.db.profiles.events[year][month]) then
            print("there are events this month" .. month)
            if ScepCalendar.db.profiles.events[year][month][day] then
                print("there are events this day" .. day)
            else 
                print("No events this day" .. day)
            end
        else
            print("No events this month" .. month)
        end
    else
        print("No events this year" .. year)
    end
]]


    if ScepCalendar.db.profiles.events[tostring(year)] and ScepCalendar.db.profiles.events[tostring(year)][month] and ScepCalendar.db.profiles.events[tostring(year)][month][day] then
        --print("YES")
        return ScepCalendar.db.profiles.events[tostring(year)][month][day]
    else
        --print("NO")
        return {}
    end
end


SLASH_WIPESCEPDB1 = "/wipescepdb"
SlashCmdList["WIPESCEPDB"] = function()
    ScepCalendar.db.profiles.events = {}
    print("Database wiped")
end

NS.ScepCalendar = ScepCalendar
