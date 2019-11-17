local addonName, NS = ...
NS = NS or {}
NS.logic = {}

local COMMPREFIX = "ScepCalendarComm"
local Requests = {
    HELLO = "hello",
    DB_EXPORT = "exportDB",
    SUBSCRIBE = "subscribe",
    UNSUBSCRIBE = "unsubscribe",
    PLAYER_SUBSCRRIPTIONS = "playerSubsribes",
    UNHASHED_SUBSCRIPTIONS = "unhashedPlayersSubscriptions"
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

ScepCalendar =
    LibStub("AceAddon-3.0"):NewAddon(
    "ScepCalendar",
    "AceConsole-3.0",
    "AceComm-3.0",
    "AceSerializer-3.0",
    "AceTimer-3.0"
)

function ScepCalendar:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ScepCalendarDB")
    self.db.profiles.dbVersion = self.db.profiles.dbVersion or 1
    print("DB_VERSION: " .. self.db.profiles.dbVersion)
    self:RequestHello()
    self:ScheduleRepeatingTimer("BroadcastSubscriptions", 15)
end

function ScepCalendar:OnEnable()
    self:Print("Merci d'utiliser ScepCalendar. Reportez les bugs en message discord à Bordel.")
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
        elseif (data.request == Requests.PLAYER_SUBSCRRIPTIONS) then
            ScepCalendar:OnReceiveBroadcastSubscriptions(data, sender)
        elseif (data.request == Requests.UNHASHED_SUBSCRIPTIONS) then
            ScepCalendar:OnReceiveUnhashedSubscriptions(data, sender)
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
                ScepCalendar:RequestExportDB(highestVersion.sender)
            end
            helloBatchRunning = false
        end
        if (not helloBatchRunning) then
            helloBatchRunning = true
            ScepCalendar_wait(5, afterWait)
        end
    end
end

function ScepCalendar:BroadcastSubscriptions()
    ScepCalendar.db.profiles.subscriptions = ScepCalendar.db.profiles.subscriptions or {}
    local hash = NS.utils.sha256(ScepCalendar:Serialize(ScepCalendar.db.profiles.subscriptions))
    local rqData = {
        hash = hash,
        rqType = RequestType.BROADCAST,
        request = Requests.PLAYER_SUBSCRRIPTIONS
    }
    ScepCalendar:Send(rqData)
end

function ScepCalendar:OnReceiveBroadcastSubscriptions(data, sender)
    local selfHash = NS.utils.sha256(ScepCalendar:Serialize(ScepCalendar.db.profiles.subscriptions))
    if data.hash ~= selfHash then
        local rqData = {
            request = Requests.UNHASHED_SUBSCRIPTIONS,
            rqType = RequestType.REQUEST
        }
        ScepCalendar:Send(data, sender)
    end
end

function ScepCalendar:OnReceiveUnhashedSubscriptions(data, sender)
    if data.rqType == RequestType.REQUEST then
        -- Send nos unhashed subs au sender
        ScepCalendar.db.profiles.subscriptions = ScepCalendar.db.profiles.subscriptions or {}
        local rqData = {
            data = ScepCalendar.db.profiles.subscriptions,
            rqType = RequestType.RESPONSE,
            request = Requests.UNHASHED_SUBSCRIPTIONS
        }
        ScepCalendar:Send(rqData, sender)
    elseif data.rqType == RequestType.RESPONSE then
        -- Comparer les hash et recuperer les plus recentes subscriptions pour les update dans notre db
        local otherSubs = data.data
        local ourSubs = ScepCalendar.db.profiles.subscriptions or {}

        for k, v in ipairs(otherSubs) do
            if ourSubs[k] then
                -- Si on a déjà une entrée pour ce joueur, comparer le timestamp
                if ourSubs[k].lastModification < v.lastModification then
                    -- Si le timestamp reçu est supérieur au notre, remplacer notre entry par la leur
                    ourSubs[k] = v
                end
            else
                -- Si on en a pas, la rajouter
                ourSubs[k] = v
            end
        end
        ScepCalendar.db.profiles.subscriptions = ourSubs
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
        request = Requests.DB_EXPORT
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
    ScepCalendar:Send(rqData, sender)
end

ScepCalendar:RegisterComm(COMMPREFIX, ScepCalendar.OnCommCallback)

--------- EVENT METHODS -----------

function ScepCalendar:CreateNewEvent(eventData)
    ScepCalendar.db.profiles.events = ScepCalendar.db.profiles.events or {}
    ScepCalendar.db.profiles.events[eventData.year] = ScepCalendar.db.profiles.events[eventData.year] or {}
    ScepCalendar.db.profiles.events[eventData.year][eventData.month] =
        ScepCalendar.db.profiles.events[eventData.year][eventData.month] or {}
    ScepCalendar.db.profiles.events[eventData.year][eventData.month][eventData.day] =
        ScepCalendar.db.profiles.events[eventData.year][eventData.month][eventData.day] or {}
    local r = ScepCalendar.db.profiles.events[eventData.year][eventData.month][eventData.day]
    ScepCalendar.db.profiles.events[eventData.year][eventData.month][eventData.day][#r + 1] = eventData
    ScepCalendar.db.profiles.dbVersion = ScepCalendar.db.profiles.dbVersion + 1
    ScepCalendar:ExportDB()
end

function ScepCalendar:GetEventsForDay(day, month, year)
    if
        ScepCalendar.db.profiles.events[tostring(year)] and ScepCalendar.db.profiles.events[tostring(year)][month] and
            ScepCalendar.db.profiles.events[tostring(year)][month][day]
     then
        return ScepCalendar.db.profiles.events[tostring(year)][month][day]
    else
        return {}
    end
end

function ScepCalendar:SignupForEvent(event)
    local localizedClass, englishClass, classIndex = UnitClass("unit")

    ScepCalendar.db.profiles.subscriptions = ScepCalendar.db.profiles.subscriptions or {}
    ScepCalendar.db.profiles.subscriptions[NS.config.characterName] =
        ScepCalendar.db.profiles.subscriptions[NS.config.characterName] or {}
    ScepCalendar.db.profiles.subscriptions[NS.config.characterName].lastModification = time()
        ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events = ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events or {}
    ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events[#ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events + 1] = event.id
    ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events =
        NS.utils.removeDuplicates(ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events)
    print("Signed up for " .. event.title)
    print("Self subscriptions length " .. #ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events)
    for i = 1, #ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events, 1 do
        print(ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events[i])
    end
end

function ScepCalendar:IsSubscribedToEvent(id)
    ScepCalendar.db.profiles.subscriptions = ScepCalendar.db.profiles.subscriptions or {}
    ScepCalendar.db.profiles.subscriptions[NS.config.characterName] =
        ScepCalendar.db.profiles.subscriptions[NS.config.characterName] or {}
    ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events =
        ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events or {}

    for i = 1, #ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events, 1 do
        if ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events[i] == id then
            return true
        end
    end
    return false
end

function ScepCalendar:SignOutOfEvent(event)
    --[[ for i = 1, #ScepCalendar.db.profiles.subscriptions, 1 do
        if ScepCalendar.db.profiles.subscriptions[i] == event.id then
            table.remove(ScepCalendar.db.profiles.subscriptions, i)
            return
        end
    end
    local rqData = {
        rqType = RequestType.BROADCAST,
        request = Requests.UNSUBSCRIBE,
        eventId = event.id,
        eventDay = event.day,
        eventMonth = event.month,
        eventYear = event.year
    }
    ScepCalendar:Send(rqData)
    ]]
end

SLASH_WIPESCEPDB1 = "/wipescepdb"
SlashCmdList["WIPESCEPDB"] = function()
    ScepCalendar.db.profiles.events = {}
    print("Database wiped")
end

NS.ScepCalendar = ScepCalendar
