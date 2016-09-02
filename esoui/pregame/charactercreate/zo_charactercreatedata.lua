--[[ Character Creation Data]]--
-- The important stuff, data describing all the valid options you can choose from

ZO_CharacterCreateData = ZO_Object:Subclass()

function ZO_CharacterCreateData:New()
    local createData = ZO_Object.New(self)
    createData:Initialize()
    return createData
end

function ZO_CharacterCreateData:Initialize()
end

function ZO_CharacterCreateData:PerformDeferredInitialization()
    local missingDataPosition = 0
    local function SafeGetPosition(position)
        if position > 0 then
            return position
        end
        missingDataPosition = missingDataPosition + 1
        return missingDataPosition
    end

    local function ResetMissingDataPosition()
        missingDataPosition = 0
    end

    self.alliances = {}
    local alliances = self.alliances
    for i = 1, GetNumAlliances() do
        local alliance, name, normalIcon, pressedIcon, mouseoverIcon, backdropTop, backdropBottom, position, lore, gamepadNormalIcon, gamepadPressedIcon = GetAllianceInfo(i)
        alliances[i] =
        {
            alliance = alliance,
            name = name,
            normalIcon = normalIcon,
            pressedIcon = pressedIcon,
            mouseoverIcon = mouseoverIcon,
            backdropTop = backdropTop,
            backdropBottom = backdropBottom,
            position = SafeGetPosition(position),
            lore = lore,
            isSelectable = false,
            gamepadNormalIcon = gamepadNormalIcon,
            gamepadPressedIcon = gamepadPressedIcon,
        }
    end

    ResetMissingDataPosition()

    self.classes = {}
    local classes = self.classes
    for i = 1, GetNumClasses() do
        local class, lore, normalIcon, pressedIcon, mouseoverIcon, isSelectable, _, _, gamepadNormalIcon, gamepadPressedIcon = GetClassInfo(i)
        classes[i] =
        {
            class = class,
            lore = lore,
            normalIcon = normalIcon,
            pressedIcon = pressedIcon,
            mouseoverIcon = mouseoverIcon,
            isSelectable = isSelectable,
            gamepadNormalIcon = gamepadNormalIcon,
            gamepadPressedIcon = gamepadPressedIcon,
        }
    end

    self.races = {}
    local races = self.races
    for i = 1, GetNumRaces() do
        local raceDef, lore, alliance, normalIcon, pressedIcon, mouseoverIcon, position, isSelectable, gamepadNormalIcon, gamepadPressedIcon = GetRaceInfo(i)
        races[i] =
        {
            race = raceDef,
            alliance = alliance,
            lore = lore,
            normalIcon = normalIcon,
            pressedIcon = pressedIcon,
            mouseoverIcon = mouseoverIcon,
            position = SafeGetPosition(position),
            isSelectable = isSelectable,
            isRadioEnabled = isSelectable,
            gamepadNormalIcon = gamepadNormalIcon,
            gamepadPressedIcon = gamepadPressedIcon,
        }
    end

    ResetMissingDataPosition()

    self.templates = {}
    local templatesAllowed, templatesRequired = GetTemplateStatus()
    if templatesAllowed then
        local templates = self.templates

        if not templatesRequired then
            -- add the no template option
            table.insert(templates, self:GetNoneTemplate())
        end

        -- Keep these in the order that they are returned in so the template list matches the def order
        -- If lookup time ever becomes a problem, make a table that maps templateDefId -> tableIndex
        for i = 1, GetNumTemplates() do
            local templateDef, name, race, class, gender, alliance, overrideAppearance, isSelectable = GetTemplateInfo(i)
            table.insert(templates,
            {
                template = templateDef,
                name = name,
                race = race,
                class = class,
                gender = gender,
                alliance = alliance,
                overrideAppearance = overrideAppearance,
                isSelectable = isSelectable
            })
        end
    end

    self:UpdateAllianceSelectability()
end

do
    local NONE_TEMPLATE =
        {
            template = 0,
            name = GetString(SI_TEMPLATE_NONE),
            race = 0,
            class = 0,
            gender = 0,
            alliance = 0,
            overrideAppearance = false,
            isSelectable = true
        }
    function ZO_CharacterCreateData:GetNoneTemplate()
        return NONE_TEMPLATE
    end
end

function ZO_CharacterCreateData:UpdateAllianceSelectability()
    -- Updates whether or not an alliance is selectable based on whether or not the races in the alliance can be selected
    -- This could actually be overridden by the "play any race as any alliance" entitlement, it's just a safe starting point
    for allianceIndex, allianceData in ipairs(self.alliances) do
        local currentAlliance = allianceData.alliance
        allianceData.isSelectable = false

        for raceIndex, raceData in ipairs(self.races) do
            if raceData.alliance == currentAlliance and raceData.isSelectable and raceData.isRadioEnabled then
                allianceData.isSelectable = true
                break
            end
        end
    end
end

function ZO_CharacterCreateData:GetAllianceInfo()
    return self.alliances
end

function ZO_CharacterCreateData:GetRaceInfo()
    return self.races
end

function ZO_CharacterCreateData:GetClassInfo()
    return self.classes
end

function ZO_CharacterCreateData:GetTemplateInfo()
    return self.templates
end

function ZO_CharacterCreateData:GetRaceForRaceDef(defId)
    local races = self.races
    for _, raceInfo in ipairs(races) do
        if raceInfo.race == defId then
            return raceInfo
        end
    end
end

function ZO_CharacterCreateData:GetAllianceForAllianceDef(defId)
    local alliances = self.alliances
    for _, allianceInfo in ipairs(alliances) do
        if allianceInfo.alliance == defId then
            return allianceInfo
        end
    end
end

function ZO_CharacterCreateData:GetClassForClassDef(defId)
    local classes = self.classes
    for _, classInfo in ipairs(classes) do
        if classInfo.class == defId then
            return classInfo
        end
    end
end

function ZO_CharacterCreateData:GetTemplate(templateDef)
    for _, templateInfo in ipairs(self.templates) do
        if templateInfo.template == templateDef then
            return templateInfo
        end
    end
end

do
    local function CheckAddOption(optionsTable, option)
        if option.isSelectable then
            optionsTable[#optionsTable + 1] = option
        end
    end

    function ZO_CharacterCreateData:PickRandom(validIndices, dataTable, defIdFieldName)
        local optionsTable = {}

        if validIndices then
            for _, dataIndex in ipairs(validIndices) do
                CheckAddOption(optionsTable, dataTable[dataIndex])
            end
        else
            for _, data in pairs(dataTable) do
                CheckAddOption(optionsTable, data)
            end
        end

        if #optionsTable > 0 then
            local randomIndex = zo_random(#optionsTable)
            return optionsTable[randomIndex][defIdFieldName]
        end

        return 1
    end
end

function ZO_CharacterCreateData:PickRandomRace(validIndicesTable)
    return self:PickRandom(validIndicesTable, self.races, "race")
end

function ZO_CharacterCreateData:PickRandomAlliance(validIndicesTable)
    -- Needs special behavior because this will usually follow the selected race...however
    -- some races have no alliance, so we should actually make a random choice for the alliance.
    -- So, if there are no preselected alliances do the fancy business.

    if not validIndicesTable then
        local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
        local currentRace = self:GetRaceForRaceDef(CharacterCreateGetRace(characterMode))
        if not currentRace or currentRace.alliance == 0 then
            return self:PickRandom(nil, self.alliances, "alliance")
        else
            return currentRace.alliance
        end
    end

    return self:PickRandom(validIndicesTable, self.alliances, "alliance")
end

function ZO_CharacterCreateData:PickRandomGender()
    local gender = zo_random(2)
    if gender == 1 then
        return GENDER_MALE
    end

    return GENDER_FEMALE
end

function ZO_CharacterCreateData:PickRandomClass()
    return self:PickRandom(nil, self.classes, "class")
end