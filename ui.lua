local _, NS = ...
NS = NS or {}

local UI = {}

SLASH_FRAMESTK1 = "/fs"
SlashCmdList.FRAMESTK = function()
    LoadAddOn("Blizzard_DebugTools")
    FrameStackTooltip_Toggle()
end

SLASH_SHOWSCEPCALENDAR1 = "/scepcalendar"
SlashCmdList["SHOWSCEPCALENDAR"] = function()
    showMainContainer()
end

for i = 1, NUM_CHAT_WINDOWS do
    _G["ChatFrame" .. i .. "EditBox"]:SetAltArrowKeyMode(false)
end

function get_day_of_week(dd, mm, yy)
    dw = date("*t", time {year = yy - 1, month = mm, day = dd})["wday"]
    return dw, ({"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"})[dw]
end

local lastDayClicked = 1

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
    UI.mainContainer.currentMonthLabel:SetText(monthsStrings[currentMonth])
    UI.mainContainer.currentYearLabel:SetText(currentYear)
    generateDayFrames()
end

function onPreviousMonthClick()
    currentMonth = currentMonth - 1
    if (currentMonth < 1) then
        currentMonth = 12
        currentYear = currentYear - 1
    end
    UI.mainContainer.currentMonthLabel:SetText(monthsStrings[currentMonth])
    UI.mainContainer.currentYearLabel:SetText(currentYear)
    generateDayFrames()
end

function showMainContainer()
    local mainContainer =
        UI.mainContainer or CreateFrame("Frame", "ScepCalendarMainContainer", UIParent, "BasicFrameTemplateWithInset")

    -- Main Frame
    mainContainer:SetSize(700, 550)
    mainContainer:SetPoint("CENTER", UIParent, "CENTER")
    mainContainer.title = mainContainer.title or mainContainer:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
    mainContainer.title:SetPoint("CENTER", mainContainer.TitleBg, "CENTER", 10, 0)
    mainContainer.title:SetText("Scep Calendar")

    -- Current month label
    mainContainer.currentMonthLabel = mainContainer.currentMonthLabel or mainContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    mainContainer.currentMonthLabel:SetText(monthsStrings[currentMonth])
    mainContainer.currentMonthLabel:SetPoint("CENTER", mainContainer.Bg, "TOP", 0, -30)

    -- Current year label
    mainContainer.currentYearLabel = mainContainer.currentYearLabel or mainContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mainContainer.currentYearLabel:SetText(currentYear)
    mainContainer.currentYearLabel:SetPoint("CENTER", mainContainer.Bg, "TOP", 0, -45)

    -- Next month button
    mainContainer.nextMonthBtn = mainContainer.nextMonthBtn or
        CreateFrame("Button", "ScepCalendarNexMonthBtn", mainContainer, "UIPanelButtonTemplate")
    mainContainer.nextMonthBtn:SetText(">")
    mainContainer.nextMonthBtn:SetScript("OnClick", onNextMonthClick)
    mainContainer.nextMonthBtn:SetPoint("CENTER", mainContainer, "TOP", 100, -50)
    mainContainer.nextMonthBtn:SetSize(30, 30)

    -- Previous month button
    mainContainer.previousMonthBtn = mainContainer.previousMonthBtn or
        CreateFrame("Button", "ScepCalendarNexMonthBtn", mainContainer, "UIPanelButtonTemplate")
    mainContainer.previousMonthBtn:SetText("<")
    mainContainer.previousMonthBtn:SetScript("OnClick", onPreviousMonthClick)
    mainContainer.previousMonthBtn:SetPoint("CENTER", mainContainer, "TOP", -100, -50)
    mainContainer.previousMonthBtn:SetSize(30, 30)

    -- Calendar Frame
    mainContainer.monthContainer = mainContainer.monthContainer or CreateFrame("Frame", "ScepCalendarMonthContainer", mainContainer)
    mainContainer.monthContainer:SetSize(680, 350)
    mainContainer.monthContainer:SetPoint("CENTER", mainContainer, "CENTER", 0, -23)

    -- Weekdays labels
    mainContainer.monthContainer.weekdays = mainContainer.monthContainer.weekdays or {}
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

    UI.mainContainer = mainContainer

    -- Days frames
    if (UI.dayFramesPool == nil) then
        UI.dayFramesPool = {}
        for i = 1, 31, 1 do
            UI.dayFramesPool[i] =
                CreateFrame("Frame", "ScepCalendarDay", mainContainer.monthContainer, "InsetFrameTemplate3")
        end
    end
    UI.mainContainer:Show()
    generateDayFrames()
end

function showEventsDetailsFrame(event)
    local eventDetailsFrame

    if (UI.mainContainer.eventDetailsFrame == nil) then
        eventDetailsFrame = CreateFrame("Frame", "EventDetailsFrame", UI.mainContainer, "BasicFrameTemplateWithInset")
    else
        eventDetailsFrame = UI.mainContainer.eventDetailsFrame
    end

    if (UI.mainContainer.newEventFrame) then
        UI.mainContainer.newEventFrame:Hide()
    end
    eventDetailsFrame:SetSize(300, 550)
    eventDetailsFrame:SetPoint("RIGHT", UI.mainContainer, "RIGHT", 300, 0)
    -- Title
    eventDetailsFrame.title =
        eventDetailsFrame.title or eventDetailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    eventDetailsFrame.title:SetText(event.title)
    eventDetailsFrame.title:SetSize(280, 50)
    eventDetailsFrame.title:SetPoint("TOP", eventDetailsFrame, "TOP", 0, -30)

    -- Hour and minutes
    eventDetailsFrame.dateTime =
        eventDetailsFrame.dateTime or eventDetailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    eventDetailsFrame.dateTime:SetText(event.hour .. " h " .. event.minutes)
    eventDetailsFrame.dateTime:SetPoint("TOP", eventDetailsFrame, "TOP", 0, -80)

    -- Description
    eventDetailsFrame.description =
        eventDetailsFrame.description or eventDetailsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    eventDetailsFrame.description:SetText(event.description)
    eventDetailsFrame.description:SetSize(280, 100)
    eventDetailsFrame.description:SetPoint("TOP", eventDetailsFrame, "TOP", 0, -90)

    -- Signed up Label
    eventDetailsFrame.signedUpLabel =
        eventDetailsFrame.signedUpLabel or eventDetailsFrame:CreateFontString(nil, "OVERLAY", "GameFontGreen")
    eventDetailsFrame.signedUpLabel:SetText("Vous êtes inscrit pour cet event")
    eventDetailsFrame.signedUpLabel:SetPoint("TOP", eventDetailsFrame, "TOP", 0, -200)

    -- Sign up button
    eventDetailsFrame.signUpOrOutBtn =
        eventDetailsFrame.signUpOrOutBtn or
        CreateFrame("Button", "SignUpOrOutBtn", eventDetailsFrame, "UIPanelButtonTemplate")
    eventDetailsFrame.signUpOrOutBtn:SetSize(140, 20)
    local suooTxt = "S'inscrire"
    --
    --[[] for i = 1, #event.roster, 1 do
        if event.roster[i].name == NS.config.playerName then
            suooTxt = "Se désinscrire"
        end
    end
    ]] eventDetailsFrame.signUpOrOutBtn:SetText(
        suooTxt
    )
    eventDetailsFrame.signUpOrOutBtn:SetScript(
        "OnClick",
        function()
            -- s'inscrire a l'event
        end
    )

    -- Roster

    eventDetailsFrame:Show()
    UI.mainContainer.eventDetailsFrame = eventDetailsFrame
end

function showNewEventFrame()
    local chosenMonth = currentMonth
    local chosenDay = lastDayClicked
    local chosenHour = 20
    local chosenMinutes = 45
    local newEventFrame =
        UI.mainContainer.newEventFrame or
        CreateFrame("Frame", "CreateEventFrame", UI.mainContainer, "BasicFrameTemplateWithInset")
    local createEventBtn =
        newEventFrame.createEventBtn or
        CreateFrame("Button", "NEF_CreateEventBtn", newEventFrame, "UIPanelButtonTemplate")

    if (UI.mainContainer.eventDetailsFrame ~= nil) then
        UI.mainContainer.eventDetailsFrame:Hide()
    end
    newEventFrame:SetSize(300, 300)
    newEventFrame:SetPoint("TOPRIGHT", UI.mainContainer, "TOPRIGHT", 300, 0)
    if (newEventFrame.title == nil) then
        newEventFrame.title = newEventFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    end
    newEventFrame.title:SetText("Nouvel event")
    newEventFrame.title:SetPoint("CENTER", newEventFrame, "TOP", 0, -45)
    -- Event name
    -- Edit
    newEventFrame.eventNameEdit =
        newEventFrame.eventNameEdit or CreateFrame("EditBox", "NewEventNameEdit", newEventFrame, "InputBoxTemplate")
    newEventFrame.eventNameEdit:SetPoint("TOPRIGHT", newEventFrame, "TOPRIGHT", -20, -75)
    newEventFrame.eventNameEdit:SetMaxBytes(255)
    newEventFrame.eventNameEdit:SetScript(
        "OnTextChanged",
        function()
            createEventBtn:SetEnabled(#newEventFrame.eventNameEdit:GetText() > 0)
        end
    )
    newEventFrame.eventNameEdit:SetAutoFocus(false)
    newEventFrame.eventNameEdit:SetSize(200, 25)
    -- Label
    newEventFrame.eventNameLabel =
        newEventFrame.eventNameLabel or newEventFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    newEventFrame.eventNameLabel:SetPoint("TOPLEFT", newEventFrame, "TOPLEFT", 20, -82)
    newEventFrame.eventNameLabel:SetText("Titre")

    -- Date dropdown menu
    -- Day Dropdown
    local dayDropdown =
        newEventFrame.dayDropdown or
        CreateFrame("Frame", "NewEventFayDropdown", newEventFrame, "UIDropDownMenuTemplate")
    dayDropdown:SetPoint("TOPLEFT", newEventFrame, "TOPLEFT", 0, -125)
    UIDropDownMenu_SetWidth(dayDropdown, 40)
    UIDropDownMenu_SetText(dayDropdown, chosenDay)
    UIDropDownMenu_Initialize(
        dayDropdown,
        function(self, level, multilist)
            local info = UIDropDownMenu_CreateInfo()
            info.func = self.SetValue
            for i = 1, getDaysInMonth(chosenMonth), 1 do
                info.text = i
                info.checked = i == chosenDay
                info.arg1 = i
                UIDropDownMenu_AddButton(info, 1)
            end
        end
    )
    function dayDropdown:SetValue(newDay)
        chosenDay = newDay
        UIDropDownMenu_SetText(dayDropdown, newDay)
        CloseDropDownMenus()
    end
    newEventFrame.dayDropdown = dayDropdown
    -- Month dropdown
    local monthDropDown =
        newEventFrame.monthDropDown or
        CreateFrame("Frame", "NewEventFayDropdown", newEventFrame, "UIDropDownMenuTemplate")
    monthDropDown:SetPoint("TOPLEFT", newEventFrame, "TOPLEFT", 60, -125)
    UIDropDownMenu_SetWidth(monthDropDown, 90)
    UIDropDownMenu_SetText(monthDropDown, monthsStrings[chosenMonth])
    UIDropDownMenu_Initialize(
        monthDropDown,
        function(self, level, multilist)
            local info = UIDropDownMenu_CreateInfo()
            info.func = self.SetValue
            for i, v in ipairs(monthsStrings) do
                info.text = v
                info.checked = i == chosenMonth
                info.arg1 = v
                info.arg2 = i
                UIDropDownMenu_AddButton(info, 1)
            end
        end
    )
    function monthDropDown:SetValue(newMonth, index)
        if (getDaysInMonth(index) < getDaysInMonth(chosenMonth) and chosenDay > getDaysInMonth(index)) then
            UIDropDownMenu_SetText(newEventFrame.dayDropdown, 1)
            chosenDay = 1
        end
        chosenMonth = index
        UIDropDownMenu_SetText(monthDropDown, newMonth)
        CloseDropDownMenus()
    end
    newEventFrame.monthDropDown = monthDropDown
    -- year label
    local yearLabel = newEventFrame.yearLabel or newEventFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    yearLabel:SetPoint("TOPLEFT", newEventFrame, "TOPLEFT", 200, -132)
    yearLabel:SetText(currentYear)
    newEventFrame.yearLabel = yearLabel

    -- Time dropDowns
    -- Minutes dropdown
    local minutesDropDown =
        newEventFrame.minutesDropDown or
        CreateFrame("Frame", "NewEventFayDropdown", newEventFrame, "UIDropDownMenuTemplate")
    minutesDropDown:SetPoint("TOPLEFT", newEventFrame, "TOPLEFT", 75, -165)
    UIDropDownMenu_SetWidth(minutesDropDown, 40)
    UIDropDownMenu_SetText(minutesDropDown, chosenMinutes)
    UIDropDownMenu_Initialize(
        minutesDropDown,
        function(self, level, multilist)
            local info = UIDropDownMenu_CreateInfo()
            info.func = self.SetValue
            for i = 0, 59, 5 do
                info.text = i
                info.checked = i == chosenMinutes
                info.arg1 = i
                UIDropDownMenu_AddButton(info, 1)
            end
        end
    )
    function minutesDropDown:SetValue(newMinutes)
        chosenMinutes = newMinutes
        UIDropDownMenu_SetText(minutesDropDown, newMinutes)
        CloseDropDownMenus()
    end
    newEventFrame.minutesDropDown = minutesDropDown

    -- H label
    newEventFrame.hLabel = newEventFrame.hLabel or newEventFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    newEventFrame.hLabel:SetText("h")
    newEventFrame.hLabel:SetPoint("TOPLEFT", newEventFrame, "TOPLEFT", 80, -172)
    -- Hour dropdown
    local hourDropDown =
        newEventFrame.hourDropDown or
        CreateFrame("Frame", "NewEventFayDropdown", newEventFrame, "UIDropDownMenuTemplate")
    hourDropDown:SetPoint("TOPLEFT", newEventFrame, "TOPLEFT", 0, -165)
    UIDropDownMenu_SetWidth(hourDropDown, 40)
    UIDropDownMenu_SetText(hourDropDown, chosenHour)
    UIDropDownMenu_Initialize(
        hourDropDown,
        function(self, level, multilist)
            local info = UIDropDownMenu_CreateInfo()
            info.func = self.SetValue
            for i = 0, 23, 1 do
                info.text = i
                info.checked = i == chosenHour
                info.arg1 = i
                UIDropDownMenu_AddButton(info, 1)
            end
        end
    )
    function hourDropDown:SetValue(newHour)
        chosenHour = newHour
        UIDropDownMenu_SetText(hourDropDown, newHour)
        CloseDropDownMenus()
    end
    newEventFrame.hourDropDown = hourDropDown

    -- Event description
    -- Edit
    newEventFrame.eventDescriptionEdit =
        newEventFrame.eventDescriptionEdit or
        CreateFrame("EditBox", "NewEventDescriptionEdit", newEventFrame, "InputBoxTemplate")
    newEventFrame.eventDescriptionEdit:SetPoint("TOPRIGHT", newEventFrame, "TOPRIGHT", -17, -230)
    newEventFrame.eventDescriptionEdit:SetAutoFocus(false)
    newEventFrame.eventDescriptionEdit:SetMaxBytes(256)
    newEventFrame.eventDescriptionEdit:SetJustifyH("LEFT")
    newEventFrame.eventDescriptionEdit:SetJustifyV("CENTER")
    newEventFrame.eventDescriptionEdit:SetSize(265, 20)
    newEventFrame.eventDescriptionEdit:SetCursorPosition(0)
    --newEventFrame.eventDescriptionEdit:SetFont("Fonts\\FRIZQT__.TTF", 10)
    -- Label
    newEventFrame.eventDescriptionLabel =
        newEventFrame.eventDescriptionLabel or newEventFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    newEventFrame.eventDescriptionLabel:SetPoint("TOPLEFT", newEventFrame, "TOPLEFT", 20, -210)
    newEventFrame.eventDescriptionLabel:SetText("Description")

    -- Create Event btn
    createEventBtn =
        newEventFrame.createEventBtn or
        CreateFrame("Button", "NEF_CreateEventBtn", newEventFrame, "UIPanelButtonTemplate")
    createEventBtn:SetText("Créer")
    createEventBtn:SetPoint("BOTTOM", newEventFrame, "BOTTOM", 0, 18)
    createEventBtn:SetSize(100, 25)
    createEventBtn:SetEnabled(#newEventFrame.eventNameEdit:GetText() > 0)
    createEventBtn:SetScript(
        "OnClick",
        function()
            local event = {
                id = NS.utils.generateEventId(),
                title = newEventFrame.eventNameEdit:GetText(),
                description = newEventFrame.eventDescriptionEdit:GetText(),
                author = NS.config.characterName,
                day = chosenDay,
                month = chosenMonth,
                year = yearLabel:GetText(),
                hour = chosenHour,
                minutes = chosenMinutes
            }
            newEventFrame.eventDescriptionEdit:SetText("")
            newEventFrame.eventNameEdit:SetText("")
            -- create event in db and share thru network
            NS.ScepCalendar.CreateNewEvent(NS.ScepCalendar, event)
            UI.mainContainer.eventsForDayFrame:Hide()
            showEventsDetailsFrame(event)
        end
    )
    newEventFrame.createEventBtn = createEventBtn
    -- Showing and setting to UI.mainContainer
    newEventFrame:Show()
    UI.mainContainer.newEventFrame = newEventFrame
end

function showEventsForDay(day)
    lastDayClicked = day
    if UI.mainContainer.eventDetailsFrame then
        UI.mainContainer.eventDetailsFrame:Hide()
    end
    if (UI.mainContainer.eventsForDayFrame == nil) then
        UI.mainContainer.eventsForDayFrame =
            CreateFrame("Frame", "EventsForDay", UI.mainContainer, "BasicFrameTemplateWithInset")
        UI.mainContainer.eventsForDayFrame:SetSize(200, 550)
        UI.mainContainer.eventsForDayFrame:SetPoint("LEFT", UI.mainContainer, "LEFT", -200, 0)
    end
    UI.mainContainer.eventsForDayFrame:Show()
    if (UI.mainContainer.eventsForDayFrame.title == nil) then
        UI.mainContainer.eventsForDayFrame.title =
            UI.mainContainer.eventsForDayFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    end
    UI.mainContainer.eventsForDayFrame.title:SetText(
        weekdayStrings[get_day_of_week(day, currentMonth, currentYear)] ..
            " " .. day .. " " .. monthsStrings[currentMonth]
    )
    UI.mainContainer.eventsForDayFrame.title:SetPoint("TOPLEFT", UI.mainContainer.eventsForDayFrame, "TOPLEFT", 10, -30)
    if (UI.mainContainer.eventsForDayFrame.createEventBtn == nil and NS.config.isAdmin) then
        UI.mainContainer.eventsForDayFrame.createEventBtn =
            CreateFrame("Button", "CreateEventBtn", UI.mainContainer.eventsForDayFrame, "UIPanelButtonTemplate")
        UI.mainContainer.eventsForDayFrame.createEventBtn:SetText("Créer un nouvel event")
        UI.mainContainer.eventsForDayFrame.createEventBtn:SetScript("OnClick", showNewEventFrame)
        UI.mainContainer.eventsForDayFrame.createEventBtn:SetSize(180, 25)
        UI.mainContainer.eventsForDayFrame.createEventBtn:SetPoint(
            "BOTTOM",
            UI.mainContainer.eventsForDayFrame,
            "BOTTOM",
            0,
            15
        )
    end
    local eventsForDay = NS.ScepCalendar:GetEventsForDay(day, currentMonth, currentYear)
    local eventsFrames = UI.mainContainer.eventsForDayFrame.eventsFrames or {}
    -- Hide any event previously shown
    for i = 1, #eventsFrames do
        eventsFrames[i]:Hide()
    end
    -- fill the eventFrames list with eventsForDay
    for i = 1, #eventsForDay, 1 do
        local currentEvent = eventsForDay[i]
        local eventFrame =
            eventsFrames[i] or
            CreateFrame("Frame", "ScepCalendarEventFrame", UI.mainContainer.eventsForDayFrame, "InsetFrameTemplate3")
        eventFrame:SetSize(180, 60)
        eventFrame:SetPoint(
            "TOPLEFT",
            UI.mainContainer.eventsForDayFrame,
            "TOPLEFT",
            10,
            ((i - 1) * -60) - 50 - (i * 5)
        )
        -- Event Title
        eventFrame.title = eventFrame.title or eventFrame:CreateFontString(nil, "OVERLAY", "GameFontGreen")
        eventFrame.title:SetText(eventsForDay[i].title)
        eventFrame.title:SetSize(170, 10)
        eventFrame.title:SetPoint("TOPLEFT", eventFrame, "TOPLEFT", 5, -5) -- Created by
        --
        -- Amount of people in the roster
        --[[eventFrame.rosterSize =
            eventFrame.rosterSize or eventFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        local rosterSizePresent = 0
        for i = 1, #currentEvent.roster, 1 do
            if currentEvent.roster[i].present then
                rosterSizePresent = rosterSizePresent + 1
            end
        end
        eventFrame.rosterSize:SetText(rosterSizePresent .. " participants")
        eventFrame.rosterSize:SetPoint("TOPLEFT", eventFrame, "TOPLEFT", 5, -25)
        ]] eventFrame.author =
            eventFrame.author or eventFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        eventFrame.author:SetText("Créé par " .. currentEvent.author)
        eventFrame.author:SetPoint("BOTTOMRIGHT", eventFrame, "BOTTOMRIGHT", -8, 5)
        eventFrame:SetScript(
            "OnMouseDown",
            function(self, button)
                if (button == "LeftButton") then
                    showEventsDetailsFrame(currentEvent)
                end
            end
        )
        eventFrame:Show()
        eventsFrames[i] = eventFrame
    end
    UI.mainContainer.eventsForDayFrame.eventsFrames = eventsFrames
end

function generateDayFrames()
    local dateTable = date("*t")
    local firstDayOfMonth = get_day_of_week(1, currentMonth, currentYear)
    local today = date("*t")
    for i, v in next, UI.dayFramesPool do
        v:Hide()
    end
    UI.mainContainer.monthContainer.days = {}
    for i = 1, getDaysInMonth(currentMonth) + firstDayOfMonth - 1, 1 do
        if (firstDayOfMonth <= i) then
            local dayNumber = i - firstDayOfMonth + 1
            local dayFrame = UI.dayFramesPool[dayNumber]
            local yOffset = math.floor(((i - 1) / 7)) * -70
            local xOffset = ((i - 1) % 7) * 97
            local eventsThisDay = #(NS.ScepCalendar:GetEventsForDay(dayNumber, currentMonth, currentYear)) > 0

            dayFrame:SetSize(97, 70)
            dayFrame:SetPoint("TOPLEFT", UI.mainContainer.monthContainer, "TOPLEFT", xOffset, yOffset)
            dayFrame:Show()
            dayFrame.redDot = dayFrame.redDot or dayFrame:CreateFontString(nil, "OVERLAY", "GameFontRedLarge")
            dayFrame.redDot:SetPoint("TOPLEFT", dayFrame, "TOPLEFT", 7, -6)
            if (today.day == dayNumber and today.month == currentMonth and today.year == currentYear) then
                dayFrame.redDot:SetText("O")
            else
                dayFrame.redDot:SetText("")
            end
            dayFrame.redDot2 = dayFrame.redDot2 or dayFrame:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
            dayFrame.redDot2:SetPoint("TOPLEFT", dayFrame, "TOPLEFT", 10, -10)
            if (today.day == dayNumber and today.month == currentMonth and today.year == currentYear) then
                dayFrame.redDot2:SetText("X")
            else
                dayFrame.redDot2:SetText("")
            end
            if (eventsThisDay) then
                dayFrame.greenNumber = dayFrame:CreateFontString(nil, "OVERLAY", "GameFontGreenLarge")
                dayFrame.number = dayFrame.greenNumber
            else
                dayFrame.greyNumber = dayFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
                dayFrame.number = dayFrame.greyNumber
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
            UI.mainContainer.monthContainer.days[i] = dayFrame
        end
    end
end
