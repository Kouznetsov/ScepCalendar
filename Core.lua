local _, core = ...

SLASH_FRAMESTK1 = "/fs"
SlashCmdList.FRAMESTK = function()
    LoadAddOn("Blizzard_DebugTools")
    FrameStackTooltip_Toggle()
end

for i = 1, NUM_CHAT_WINDOWS do
    _G["ChatFrame" .. i .. "EditBox"]:SetAltArrowKeyMode(false)
end

function get_day_of_week(dd, mm, yy)
    dw = date("*t", time {year = yy - 1, month = mm, day = dd})["wday"]
    return dw, ({"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"})[dw]
end

local mainContainer = CreateFrame("Frame", "ScepCalendarMainContainer", UIParent, "BasicFrameTemplateWithInset")

local monthsStrings = {
    "Janvier",
    "Février",
    "Mars",
    "Avril",
    "Mai",
    "Juin",
    "Juillet",
    "Août",
    "Septembre",
    "Octobre",
    "Novembre",
    "Décembre"
}
local weekdayStrings = {"Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"}
local currentMonth = date("*t").month
local currentYear = date("*t").year

function getDaysInMonth(index)
    if (index == 1 or (index > 1 and index % 2 == 0 and index ~= 2)) then
        return 31
    elseif (index == 2) then
        return 28
    else
        return 30
    end
end

function onNextMonthClick()
    currentMonth = currentMonth + 1
    if (currentMonth > 12) then
        currentMonth = 1
        currentYear = currentYear + 1
    end
    mainContainer.currentMonthLabel:SetText(monthsStrings[currentMonth])
    mainContainer.currentYearLabel:SetText(currentYear)
    generateDayFrames()
end

function onPreviousMonthClick()
    currentMonth = currentMonth - 1
    if (currentMonth < 1) then
        currentMonth = 12
        currentYear = currentYear - 1
    end
    mainContainer.currentMonthLabel:SetText(monthsStrings[currentMonth])
    mainContainer.currentYearLabel:SetText(currentYear)
    generateDayFrames()
end

-- Main Frame
mainContainer:SetSize(700, 550)
mainContainer:SetPoint("CENTER", UIParent, "CENTER")
mainContainer.title = mainContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mainContainer.title:SetPoint("CENTER", mainContainer.TitleBg, "CENTER", 10, 0)
mainContainer.title:SetText("Scep Calendar")

-- Current month label
mainContainer.currentMonthLabel = mainContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
mainContainer.currentMonthLabel:SetText(monthsStrings[currentMonth])
mainContainer.currentMonthLabel:SetPoint("CENTER", mainContainer.Bg, "TOP", 0, -30)

-- Current year label
mainContainer.currentYearLabel = mainContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
mainContainer.currentYearLabel:SetText(currentYear)
mainContainer.currentYearLabel:SetPoint("CENTER", mainContainer.Bg, "TOP", 0, -45)

-- Next month button
mainContainer.nextMonthBtn = CreateFrame("Button", "ScepCalendarNexMonthBtn", mainContainer, "UIPanelButtonTemplate")
mainContainer.nextMonthBtn:SetText(">")
mainContainer.nextMonthBtn:SetScript("OnClick", onNextMonthClick)
mainContainer.nextMonthBtn:SetPoint("CENTER", mainContainer, "TOP", 100, -50)
mainContainer.nextMonthBtn:SetSize(30, 30)

-- Previous month button
mainContainer.previousMonthBtn =
    CreateFrame("Button", "ScepCalendarNexMonthBtn", mainContainer, "UIPanelButtonTemplate")
mainContainer.previousMonthBtn:SetText("<")
mainContainer.previousMonthBtn:SetScript("OnClick", onPreviousMonthClick)
mainContainer.previousMonthBtn:SetPoint("CENTER", mainContainer, "TOP", -100, -50)
mainContainer.previousMonthBtn:SetSize(30, 30)

-- Calendar Frame
mainContainer.monthContainer = CreateFrame("Frame", "ScepCalendarMonthContainer", mainContainer)
mainContainer.monthContainer:SetSize(680, 350)
mainContainer.monthContainer:SetPoint("CENTER", mainContainer, "CENTER", 0, -23)

-- Weekdays labels
mainContainer.monthContainer.weekdays = {}
for k, v in next, weekdayStrings do
    local xOffset = ((k - 1) * 97)
    local str = weekdayStrings[k]

    if (str == "Mercredi") then
        xOffset = xOffset - 10
    end
    if (str == "Vendredi") then
        xOffset = xOffset - 10
    end
    if (str == "Dimanche") then
        xOffset = xOffset - 10
    end
    if (str == "Jeudi") then
        xOffset = xOffset + 5
    end
    mainContainer.monthContainer.weekdays[k] =
        mainContainer.monthContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    mainContainer.monthContainer.weekdays[k]:SetText(str)
    mainContainer.monthContainer.weekdays[k]:SetPoint(
        "TOPLEFT",
        mainContainer.monthContainer,
        "TOPLEFT",
        30 + xOffset,
        12
    )
end

-- Days frames
local dayFramesPool = {}
for i = 1, 31, 1 do
    dayFramesPool[i] = CreateFrame("Frame", "ScepCalendarDay", mainContainer.monthContainer, "InsetFrameTemplate3")
end

function generateDayFrames()
    local dateTable = date("*t")
    local firstDayOfMonth = get_day_of_week(1, currentMonth, currentYear)
    for i, v in next, dayFramesPool do
        v:Hide()
    end
    mainContainer.monthContainer.days = {}
    for i = 1, getDaysInMonth(currentMonth) + firstDayOfMonth - 1, 1 do
        if (firstDayOfMonth <= i) then
            local dayFrame = dayFramesPool[i-firstDayOfMonth + 1]
            local yOffset = math.floor(((i - 1) / 7)) * -70
            local xOffset = ((i - 1) % 7) * 97

            dayFrame:SetSize(97, 70)
            dayFrame:SetPoint("TOPLEFT", mainContainer.monthContainer, "TOPLEFT", xOffset, yOffset)
            dayFrame:Show()
            mainContainer.monthContainer.days[i] = dayFrame
        end
    end
end

generateDayFrames()

--[[
ScepCalendar = LibStub("AceAddon-3.0"):NewAddon("ScepCalendar", "AceConsole-3.0", "AceComm-3.0")
local l = {
    "a2321281c76b3d375fee0e49b0fde8e31758a849b3a34410b5227220b1430fea",
    "d43b518b8391f7fc1e525cc1062eaeca40e3f0791fa042dfb427fe9ca09a278c",
    "13d75b53f95d2516ecc4d72b6edafe0aac711704114e77e1332e5e37e3c449f6"
}
local c = sha256(UnitName("player"))
local CALLOW = false

for k, v in next, l do
    if (v == c) then
        CALLOW = true
        break
    end
end

function ScepCalendar:OnInitialize()
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

local AceGUI = LibStub("AceGUI-3.0")
local textStore

-- Main container
local mainContainer = AceGUI:Create("Frame")
mainContainer:SetTitle("Scep Calendar")
mainContainer:SetWidth(700)
mainContainer:SetCallback(
    "OnClose",
    function(widget)
        AceGUI:Release(widget)
    end
)
mainContainer:SetStatusText("Report les bugs à Bordel")
mainContainer:SetLayout("List")

--month:
local monthText = 

-- Calendar view
local calendarView = AceGUI:Create("SimpleGroup")
--calendarView:SetFullHeight(true)
calendarView:SetPoint("CENTER")
calendarView:SetFullWidth(true)
calendarView:SetLayout("Flow")

for i = 1, 31, 1 do
    local dayContainer = AceGUI:Create("SimpleGroup")
    dayContainer:SetHeight(50)
    dayContainer:SetWidth(100)

    --local icon = AceGUI:Create("Icon");
    --print("icons/".. i .. ".blp");
    --icon:SetImage("icons\\".. i .. ".blp");
    local il = AceGUI:Create("InteractiveLabel")
    il:SetText(i)
    il:SetCallback("OnEnter", function(self) self:SetColor(0.9, 0.9, 0) end)
    il:SetCallback("OnLeave", function(self) self:SetColor(1, 1, 1) end)
    il:SetWidth(30);
    il:SetImage("icons/".. i .. ".blp")
    il:SetHeight(50);
    il:SetPoint("CENTER", 30, 30); 

    local btn = AceGUI:Create("Button");
    btn:SetText(i);
    btn:SetWidth(50);

    dayContainer:AddChild(btn)
    calendarView:AddChild(dayContainer)
end

mainContainer:AddChild(calendarView)

-- Create event button
local createEventBtn = AceGUI:Create("Button")
createEventBtn:SetText("Créer un event")
createEventBtn:SetPoint("RIGHT")
createEventBtn:SetDisabled(not CALLOW) -- disabled if unauthorized
createEventBtn:SetCallback(
    "OnClick",
    function()
        print("clicked create")
    end
)
mainContainer:AddChild(createEventBtn)
]]
