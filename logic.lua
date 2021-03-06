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
local guildRoster = {}
local waitFrame = nil

local logOptions = {
    broadcastReceive = false,
    broadcastSend = false,
    unhashedSubsReceive = false,
    unhashedSubsSend = false,
    helloReceive = false,
    helloSend = false
}

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
                            tinsert(waitTable, i, { d - elapse, f, p })
                            i = i + 1
                        else
                            count = count - 1
                            f(unpack(p))
                        end
                    end
                end
        )
    end
    tinsert(waitTable, { delay, func, { ... } })
    return true
end

ScepCalendar = LibStub("AceAddon-3.0"):NewAddon(
        "ScepCalendar",
        "AceConsole-3.0",
        "AceComm-3.0",
        "AceSerializer-3.0",
        "AceTimer-3.0",
        "AceEvent-3.0"
)

function ScepCalendar:Log(tag, message)
    if logOptions[tag] then
        print(message)
    end
end

function ScepCalendar:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ScepCalendarDB")
    self.db.profiles.dbVersion = self.db.profiles.dbVersion or 1
    if GetGuildInfo("player") then
        self:RegisterEvent("GUILD_ROSTER_UPDATE", "RefreshGuildRoster");
        self:RequestHello()
        self:BroadcastSubscriptions()
        self:RefreshGuildRoster()
        self:ScheduleRepeatingTimer("BroadcastSubscriptions", 30)

        -- init
        local playerClass, englishClass = UnitClass("player")
        ScepCalendar.db.profiles.subscriptions = ScepCalendar.db.profiles.subscriptions or {}
        ScepCalendar.db.profiles.subscriptions[NS.config.characterName] = ScepCalendar.db.profiles.subscriptions[NS.config.characterName] or {}
        ScepCalendar.db.profiles.subscriptions[NS.config.characterName].class = string.lower(englishClass)
        ScepCalendar.db.profiles.subscriptions[NS.config.characterName].lastModification = ScepCalendar.db.profiles.subscriptions[NS.config.characterName].lastModification or time()
        ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events = ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events or {}
        ScepCalendar.db.profiles.events = ScepCalendar.db.profiles.events or {}
    end
end

function ScepCalendar:RefreshGuildRoster()
    local onlineMembersCount = select(3, GetNumGuildMembers())

    guildRoster = {}
    for i = 1, onlineMembersCount do
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i);

        if online then
            if name ~= nil then
                table.insert(guildRoster, ScepCalendar:SlimName(name));
            end
        end
    end
end

function ScepCalendar:SlimName(name)
    if name ~= nil then
        if string.find(name, "-", 1) ~= nil then
            return string.sub(name, 1, string.find(name, "-") - 1);
        else
            return name;
        end
    else
        return "";
    end
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
        end
    end
end

function ScepCalendar:Send(data, sender)
    local channel = nil
    if sender then
        for i = 1, #guildRoster do
            if guildRoster[i] == sender then
                channel = "WHISPER"
            end
        end
        if not channel then
            return
        end
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
    ScepCalendar:Log("helloSend", "Sending  Hello request with version " .. rqData.version)
    self:Send(rqData)
end

local receivedVersions = {}
local helloBatchRunning = false
local newAddonVersionAvailable = false
ScepCalendar.newAddonVersionShown = false

-- Responds to the sender with its own data and version if it's superior
function ScepCalendar:OnReceiveHello(data, sender)
    if (data.rqType == RequestType.REQUEST) then
        local rqData = {
            rqType = RequestType.RESPONSE,
            request = Requests.HELLO,
            addonVersion = NS.config.addonVersion,
            version = self.db.profiles.dbVersion
        }
        if (data.version > self.db.profiles.dbVersion) then
            ScepCalendar:RequestExportDB(sender)
        else
            self:Send(rqData, sender)
        end
    elseif data.rqType == RequestType.RESPONSE then
        receivedVersions[#receivedVersions + 1] = {
            version = data.version,
            sender = sender,
            addonVersion = data.addonVersion
        }
        local afterWait = function()
            local highestVersion = { version = self.db.profiles.dbVersion, sender = NS.config.characterName }

            for i = 1, #receivedVersions, 1 do
                if (receivedVersions[i].version > highestVersion.version) then
                    highestVersion = receivedVersions[i]
                end
                if (receivedVersions[i].addonVersion > NS.config.addonVersion) then
                    newAddonVersionAvailable = true
                end
            end
            receivedVersions = {}
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

function ScepCalendar:GetRosterForEvent(id)
    local subs = ScepCalendar.db.profiles.subscriptions
    local roster = {}

    for player, data in pairs(subs) do
        for _, eventId in pairs(data.events) do
            if eventId == id then
                roster[#roster + 1] = {
                    name = player,
                    class = data.class
                }
            end
        end
    end
    return roster
end

function ScepCalendar:BroadcastSubscriptions()
    ScepCalendar:Log("broadcastSend", "Sending broadcast")
    ScepCalendar.db.profiles.subscriptions = ScepCalendar.db.profiles.subscriptions or {}
    local hash = ScepCalendar:GenerateSelfHash()
    local rqData = {
        hash = hash,
        rqType = RequestType.BROADCAST,
        request = Requests.PLAYER_SUBSCRRIPTIONS
    }
    ScepCalendar:Send(rqData)
end

function ScepCalendar:GenerateSelfHash()
    local subs = ScepCalendar.db.profiles.subscriptions
    local array = {}
    local index = 1

    for k, v in pairs(subs) do
        array[index] = k .. "-" .. v.lastModification
        index = index + 1
    end
    table.sort(array, function(a, b)
        return a < b
    end)
    return NS.utils.sha256(ScepCalendar:Serialize(array))
end

function ScepCalendar:OnReceiveBroadcastSubscriptions(data, sender)
    local selfHash = ScepCalendar:GenerateSelfHash()

    if data.hash ~= selfHash then
        ScepCalendar:Log("broadcastReceive", "Received broadcast with different hashes from " .. sender)
        ScepCalendar:Log("broadcastReceive", "our = " .. selfHash)
        ScepCalendar:Log("broadcastReceive", "oth = " .. data.hash)
        local rqData = {
            request = Requests.UNHASHED_SUBSCRIPTIONS,
            rqType = RequestType.REQUEST
        }
        ScepCalendar:Log("broadcastReceive", "Sending Unhashed Subscriptions request to " .. sender)
        ScepCalendar:Send(rqData, sender)
    else
        ScepCalendar:Log("broadcastReceive", "Received broadcast with same hashes from " .. sender)
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
        ScepCalendar:Log("unhashedSubsReceive", "Received unhashed subs request from " .. sender .. ", sending table")
        ScepCalendar:Send(rqData, sender)
    elseif data.rqType == RequestType.RESPONSE then
        ScepCalendar:Log("unhashedSubsSend", "received response to unhashed request from " .. sender)
        -- Comparer les hash et recuperer les plus recentes subscriptions pour les update dans notre db
        local otherSubs = data.data
        local ourSubs = ScepCalendar.db.profiles.subscriptions or {}

        local ourSubsAmount = 0
        for k, v in pairs(ourSubs) do
            ourSubsAmount = ourSubsAmount + 1
        end

        local otherSubsAmount = 0
        for k, v in pairs(otherSubs) do
            if ourSubs[k] then
                --ScepCalendar:Log("unhashedSubsSend", "Checking player " .. k .. " self.lastModif = " .. ourSubs[k].lastModification .. " other : " .. v.lastModification)
                -- Si on a déjà une entrée pour ce joueur, comparer le timestamp
                if ourSubs[k].lastModification < v.lastModification then
                    -- Si le timestamp reçu est supérieur au notre, remplacer notre entry par la leur
                    ScepCalendar:Log("unhashedSubsSend", "Updated entry for player " .. k)
                    ourSubs[k] = v
                end
            else
                -- Si on en a pas, la rajouter
                ScepCalendar:Log("unhashedSubsSend", "Created entry for player " .. k)
                ourSubs[k] = v
            end
            otherSubsAmount = otherSubsAmount + 1
        end
        ScepCalendar:Log("unhashedSubsSend", "entries at home: " .. ourSubsAmount .. " other subs : " .. otherSubsAmount)

        ScepCalendar:Log("unhashedSubsSend", "Received unhashed subs response from " .. sender .. ", updated internal DB")
        ScepCalendar.db.profiles.subscriptions = ourSubs
    end
end

function ScepCalendar:OnReceiveDbExport(data, sender)
    if (data.rqType == RequestType.REQUEST) then
        ScepCalendar:ExportDB(sender)
    elseif data.rqType == RequestType.RESPONSE then
        if data.version > self.db.profiles.dbVersion then
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
    ScepCalendar:Send(rqData, sender)
end

ScepCalendar:RegisterComm(COMMPREFIX, ScepCalendar.OnCommCallback)

--------- EVENT METHODS -----------

function ScepCalendar:CreateNewEvent(eventData)
    ScepCalendar.db.profiles.events = ScepCalendar.db.profiles.events or {}
    ScepCalendar.db.profiles.events[eventData.year] = ScepCalendar.db.profiles.events[eventData.year] or {}
    ScepCalendar.db.profiles.events[eventData.year][eventData.month] = ScepCalendar.db.profiles.events[eventData.year][eventData.month] or {}
    ScepCalendar.db.profiles.events[eventData.year][eventData.month][eventData.day] = ScepCalendar.db.profiles.events[eventData.year][eventData.month][eventData.day] or {}
    local r = ScepCalendar.db.profiles.events[eventData.year][eventData.month][eventData.day]
    ScepCalendar.db.profiles.events[eventData.year][eventData.month][eventData.day][#r + 1] = eventData
    ScepCalendar.db.profiles.dbVersion = ScepCalendar.db.profiles.dbVersion + 1
    ScepCalendar:ExportDB()
end

function ScepCalendar:GetEventsForDay(day, month, year)
    if ScepCalendar.db.profiles.events and
            ScepCalendar.db.profiles.events[tostring(year)] and
            ScepCalendar.db.profiles.events[tostring(year)][month] and
            ScepCalendar.db.profiles.events[tostring(year)][month][day]
    then
        return ScepCalendar.db.profiles.events[tostring(year)][month][day]
    else
        return {}
    end
end

function ScepCalendar:SignupForEvent(event)
    local playerClass, englishClass = UnitClass("player")

    ScepCalendar.db.profiles.subscriptions = ScepCalendar.db.profiles.subscriptions or {}
    ScepCalendar.db.profiles.subscriptions[NS.config.characterName] = ScepCalendar.db.profiles.subscriptions[NS.config.characterName] or {}
    ScepCalendar.db.profiles.subscriptions[NS.config.characterName].class = string.lower(englishClass)
    ScepCalendar.db.profiles.subscriptions[NS.config.characterName].lastModification = time()
    ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events = ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events or {}
    ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events[
    #ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events + 1
    ] = event.id
end

function ScepCalendar:IsSubscribedToEvent(id)
    ScepCalendar.db.profiles.subscriptions = ScepCalendar.db.profiles.subscriptions or {}
    ScepCalendar.db.profiles.subscriptions[NS.config.characterName] = ScepCalendar.db.profiles.subscriptions[NS.config.characterName] or {}
    ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events = ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events or {}

    for i = 1, #ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events, 1 do
        if ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events[i] == id then
            return true
        end
    end
    return false
end

function ScepCalendar:SignOutOfEvent(event)
    for i = 1, #ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events, 1 do
        if ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events[i] == event.id then
            ScepCalendar.db.profiles.subscriptions[NS.config.characterName].lastModification = time()
            table.remove(ScepCalendar.db.profiles.subscriptions[NS.config.characterName].events, i)
        end
    end
end

SLASH_WIPESCEPDB1 = "/wipescepdb"
SlashCmdList["WIPESCEPDB"] = function()
    ScepCalendar.db.profiles.events = {}
    ScepCalendar.db.profiles.subscriptions = {}
    print("Database wiped")
end

NS.ScepCalendar = ScepCalendar
