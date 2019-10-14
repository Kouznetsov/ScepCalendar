local _, NS = ...
NS = NS or {}

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
mainContainer.title = mainContainer:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
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

function showNewEventFrame()
    local newEventFrame =
        mainContainer.newEventFrame or
        CreateFrame("Frame", "CreateEventFrame", mainContainer, "BasicFrameTemplateWithInset")

        --[[]
    if (mainContainer.eventDetailsFrame ~= nil) then
        mainContainer.eventDetailsFrame:Hide()
    end
    ]]
    newEventFrame:SetSize(300, 550)
    newEventFrame:SetPoint("RIGHT", mainContainer, "RIGHT", 300, 0)
    if (newEventFrame.title == nil) then
        newEventFrame.title = newEventFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    end
    newEventFrame.title:SetText("Nouvel event")
    newEventFrame.title:SetPoint("CENTER", newEventFrame, "TOP", 0, -45)
    -- Event name
    -- Edit
    newEventFrame.eventNameEdit = newEventFrame.eventNameEdit or CreateFrame("EditBox", "NewEventNameEdit", newEventFrame, "InputBoxTemplate");
    newEventFrame.eventNameEdit:SetPoint("TOPRIGHT", newEventFrame, "TOPRIGHT", -20, -75)
    newEventFrame.eventNameEdit:SetMaxBytes(255);
    newEventFrame.eventNameEdit:SetAutoFocus(false);
    newEventFrame.eventNameEdit:SetSize(200, 25)
    -- Label
    newEventFrame.eventNameLabel = newEventFrame.eventNameLabel or newEventFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    newEventFrame.eventNameLabel:SetPoint("TOPLEFT", newEventFrame, "TOPLEFT", 20, -82)
    newEventFrame.eventNameLabel:SetText("Titre")

    -- Event description
    -- Edit
    newEventFrame.eventDescriptionEdit = newEventFrame.eventDescriptionEdit or CreateFrame("EditBox", "NewEventDescriptionEdit", newEventFrame, "UIPanelScrollFrameTemplate");
    newEventFrame.eventDescriptionEdit:SetPoint("TOPRIGHT", newEventFrame, "TOPRIGHT", -20, -120)
    newEventFrame.eventDescriptionEdit:SetAutoFocus(false);
    newEventFrame.eventDescriptionEdit:SetMaxBytes(1024);
    newEventFrame.eventDescriptionEdit:SetSize(200, 100);
  
    -- Label
    newEventFrame.eventDescriptionLabel = newEventFrame.eventDescriptionLabel or newEventFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    newEventFrame.eventDescriptionLabel:SetPoint("TOPLEFT", newEventFrame, "TOPLEFT", 20, -110)
    newEventFrame.eventDescriptionLabel:SetText("Description")

 


    -- Showing and setting to mainContainer
    newEventFrame:Show()
    mainContainer.newEventFrame = newEventFrame
end

function showEventsForDay(day)
    if mainContainer.eventDetailsFrame then
        mainContainer.eventDetailsFrame:Hide()
    end
    if mainContainer.newEventFrame then
        mainContainer.newEventFrame:Hide()
    end
    if (mainContainer.eventsForDayFrame == nil) then
        mainContainer.eventsForDayFrame =
            CreateFrame("Frame", "EventsForDay", mainContainer, "BasicFrameTemplateWithInset")
        mainContainer.eventsForDayFrame:SetSize(200, 550)
        mainContainer.eventsForDayFrame:SetPoint("LEFT", mainContainer, "LEFT", -200, 0)
    end
    mainContainer.eventsForDayFrame:Show()
    if (mainContainer.eventsForDayFrame.title == nil) then
        mainContainer.eventsForDayFrame.title =
            mainContainer.eventsForDayFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    end
    mainContainer.eventsForDayFrame.title:SetText(
        weekdayStrings[get_day_of_week(day, currentMonth, currentYear)] ..
            " " .. day .. " " .. monthsStrings[currentMonth]
    )
    mainContainer.eventsForDayFrame.title:SetPoint("TOPLEFT", mainContainer.eventsForDayFrame, "TOPLEFT", 10, -30)
    if (mainContainer.eventsForDayFrame.createEventBtn == nil and NS.config.isAdmin) then
        mainContainer.eventsForDayFrame.createEventBtn =
            CreateFrame("Button", "CreateEventBtn", mainContainer.eventsForDayFrame, "UIPanelButtonTemplate")
        mainContainer.eventsForDayFrame.createEventBtn:SetText("Créer un nouvel event")
        mainContainer.eventsForDayFrame.createEventBtn:SetScript("OnClick", showNewEventFrame)
        mainContainer.eventsForDayFrame.createEventBtn:SetSize(180, 25)
        mainContainer.eventsForDayFrame.createEventBtn:SetPoint(
            "BOTTOM",
            mainContainer.eventsForDayFrame,
            "BOTTOM",
            0,
            15
        )
    end
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
            local dayNumber = i - firstDayOfMonth + 1
            local dayFrame = dayFramesPool[dayNumber]
            local yOffset = math.floor(((i - 1) / 7)) * -70
            local xOffset = ((i - 1) % 7) * 97

            dayFrame:SetSize(97, 70)
            dayFrame:SetPoint("TOPLEFT", mainContainer.monthContainer, "TOPLEFT", xOffset, yOffset)
            dayFrame:Show()
            if (dayFrame.number == nil) then
                dayFrame.number = dayFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
            end
            dayFrame.number:SetText(dayNumber)
            dayFrame.number:SetPoint("CENTER", dayFrame, "CENTER")
            dayFrame:SetScript(
                "OnMouseDown",
                function(self, button)
                    if (button == "LeftButton") then
                        showEventsForDay(dayNumber)
                    end
                end
            )
            mainContainer.monthContainer.days[i] = dayFrame
        end
    end
end

generateDayFrames()
