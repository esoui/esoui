-- Common Data and Functions for CharacterCreate

g_shouldBePromptedForTutorialSkip = true -- this in addition to the account flag means we should prompt
local g_callbacksRegistered = false

function OnCharacterCreateOptionChanged()
    g_shouldBePromptedForTutorialSkip = true
end

CREATE_BUCKET_RACE = 1
CREATE_BUCKET_CLASS = 2
CREATE_BUCKET_BODY = 3
CREATE_BUCKET_HEAD_TYPE = 4
CREATE_BUCKET_FEATURES = 5
CREATE_BUCKET_BODY_SHAPE = 6
CREATE_BUCKET_FACE = 7
CREATE_BUCKET_EYES = 8
CREATE_BUCKET_EARS = 9
CREATE_BUCKET_NOSE = 10
CREATE_BUCKET_MOUTH = 11
NUM_CREATE_BUCKETS = 11

--[[ Character Creation Manager]]--

ZO_CharacterCreateManager = ZO_Object:Subclass()

function ZO_CharacterCreateManager:New(characterData)
    local object = ZO_Object.New(self)

    object.m_characterData = characterData

    return object
end

-- Any functions that end up changing sliders need to be wrapped like this
function ZO_CharacterCreateManager:SetRace(race, options)
    CharacterCreateSetRace(race)
    
    -- When picking a race, unless the player is entitled to playing any race as any alliance or if the newly selected race
    -- has no alliance, we need to choose a new alliance for the player.  This is currently done as picking an alliance that matches
    -- the newly selected race
    local chooseNewAlliance = true
    if(CanPlayAnyRaceAsAnyAlliance() or options == "preventAllianceChange") then 
        chooseNewAlliance = false
    end

    local currentRaceData = self.m_characterData:GetRaceForRaceDef(CharacterCreateGetRace())
    if(currentRaceData.alliance == 0) then 
        chooseNewAlliance = false
    end

    if(chooseNewAlliance) then
        local alliances = self.m_characterData:GetAllianceInfo()
        for _, allianceData in ipairs(alliances) do
            if(allianceData.alliance == currentRaceData.alliance) then
                self:SetAlliance(allianceData.alliance, "preventRaceChange")
            end
        end
    end

    self:InitializeControls()
end

function ZO_CharacterCreateManager:SetAlliance(allianceDef, options) -- still local
    CharacterCreateSetAlliance(allianceDef)

    -- When picking an alliance, unless the player is entitled to playing any race as any alliance or if the current race
    -- has no alliance, we need to choose a new race for the player.  This is currently done as picking a race in the new
    -- alliance column that shares the row with the previous race.  If that race isn't selectable, then a random race in the 
    -- new alliance will be selected.
    if(CanPlayAnyRaceAsAnyAlliance() or options == "preventRaceChange") then return end

    local currentRaceData = self.m_characterData:GetRaceForRaceDef(CharacterCreateGetRace())
    if(currentRaceData.alliance == 0) then return end

    local currentAllianceData = self.m_characterData:GetAllianceForAllianceDef(allianceDef)
    local currentAlliance = currentAllianceData.alliance

    -- Looking for the race on the same row as this one in the column under the appropriate alliance
    local racePos = currentRaceData.position - 1
    local raceRow = zo_floor(racePos / 3)
    local allianceCol = currentAllianceData.position - 1
    local desiredRacePos = (raceRow * 3) + allianceCol + 1

    local races = self.m_characterData:GetRaceInfo()
    for _, raceData in ipairs(races) do
        if(raceData.position == desiredRacePos) then
            self:SetRace(raceData.race, "preventAllianceChange")
        end
    end
end

function ZO_CharacterCreateManager:SetGender(gender)
    CharacterCreateSetGender(gender)
    self:InitializeControls()
end

--[[ Character Creation Bucket]]--

ZO_CharacterCreateBucket = ZO_Object:Subclass()

function ZO_CharacterCreateBucket:New(parent, bucketCategory)
    local ccBucket = ZO_Object.New(self)

    ccBucket.m_category = bucketCategory
    ccBucket.m_expanded = false
    ccBucket.m_controlData = {}

    return ccBucket
end

function ZO_CharacterCreateBucket:GetContainer()
    return self.m_container
end

function ZO_CharacterCreateBucket:GetScrollChild()
    return self.m_scrollChild
end

function ZO_CharacterCreateBucket:UpdateControlsFromData()
    for control, data in pairs(self.m_controlData) do
        if(data.updateFn) then
            data.updateFn(control)
        end
    end
end

function ZO_CharacterCreateBucket:RandomizeAppearance(randomizeType)
    for control, data in pairs(self.m_controlData) do
        if(data.randomizeFn) then
            data.randomizeFn(control, randomizeType)
        end
    end    
end

--[[ Character Creation Bucket Manager ]]--
ZO_CharacterCreateBucketManager = ZO_Object:Subclass()

function ZO_CharacterCreateBucketManager:New(container)
    local mgr = ZO_Object.New(self)

    mgr.m_buckets = {}
    mgr.m_container = container
    mgr.m_currentBucket = nil

    return mgr
end

function ZO_CharacterCreateBucketManager:BucketForCategory(category)
    return self.m_buckets[category]
end

function ZO_CharacterCreateBucketManager:BucketForChildControl(control)
    return control.m_bucket
end

function ZO_CharacterCreateBucketManager:Reset()
    for _, bucket in pairs(self.m_buckets) do
        bucket:Reset()
    end
end

function ZO_CharacterCreateBucketManager:AddControl(control, category, updateFn, randomizeFn, subCategoryId)
    local bucket = self:BucketForCategory(category)
    if(bucket) then
        bucket:AddControl(control, updateFn, randomizeFn, subCategoryId)
    end
end

function ZO_CharacterCreateBucketManager:RemoveControl(control)
    local bucket = control.m_bucket
    if(bucket) then
        bucket:RemoveControl(control)
    end
end

function ZO_CharacterCreateBucketManager:UpdateControlsFromData()
    for _, bucket in pairs(self.m_buckets) do
        bucket:UpdateControlsFromData()
    end
end

function ZO_CharacterCreateBucketManager:RandomizeAppearance(randomizeType)
    for _, bucket in pairs(self.m_buckets) do
        bucket:RandomizeAppearance(randomizeType)
    end
end

--[[ Character Create Slider ]]--

ZO_CharacterCreateSlider = ZO_Object:Subclass()

function ZO_CharacterCreateSlider:New(control)
    local slider = ZO_Object.New(self)

    control.m_sliderObject = slider
    slider.m_control = control
    slider.m_slider = GetControl(control, "Slider")
    slider.m_name = GetControl(control, "Name")
    slider.m_padlock = GetControl(control, "Padlock")
    slider.m_lockState = TOGGLE_BUTTON_OPEN

    return slider
end

function ZO_CharacterCreateSlider:SetName(displayName, enumNameFallback, enumValue)
    if(displayName and displayName ~= "") then
        self.m_name:SetText(displayName)
    else
        self.m_name:SetText(GetString(enumNameFallback, enumValue))
    end
end

function ZO_CharacterCreateSlider:SetData(sliderIndex, name, category, steps, value, defaultValue)
    self.m_sliderIndex = sliderIndex
    self.m_category = category

    self.m_initializing = true
    self.m_numSteps = steps
    self.m_defaultValue = defaultValue
    self.m_slider:SetValueStep(1 / steps)
    self:SetName(nil, "SI_CHARACTERSLIDERNAME", name)
    self:Update(value)
end

function ZO_CharacterCreateSlider:SetValue(value)
    if(not self.m_initializing) then
        SetSliderValue(self.m_sliderIndex, value)
        self:UpdateChangeButtons(value)
    end
end

function ZO_CharacterCreateSlider:ChangeValue(changeAmount)
    local newSteppedValue = zo_floor(self.m_slider:GetValue() * self.m_numSteps) + changeAmount
    self:SetValue(newSteppedValue / self.m_numSteps)
    self:Update()
end

function ZO_CharacterCreateSlider:GetValue()
    return self.m_slider:GetValue()
end

function ZO_CharacterCreateSlider:Randomize(randomizeType)
    if(self.m_lockState == TOGGLE_BUTTON_OPEN) then
        local randomValue = 0

        if((randomizeType == "initial") and (self.m_defaultValue >= 0)) then
            -- If this is the initial randomization and we have a valid default value
            -- then don't actually randomize anything, just use the default value.
            randomValue = self.m_defaultValue
        else
            -- Otherwise, pick a random value from the valid values
            local numSteps = self.m_numSteps
            
            if(numSteps > 0) then
                randomValue = zo_random(0, numSteps) / numSteps
            end
        end

        self:SetValue(randomValue)
        self:Update()
    end
end

function ZO_CharacterCreateSlider:ToggleLocked()
    self.m_lockState = not self.m_lockState
    ZO_ToggleButton_SetState(self.m_padlock, self.m_lockState)

    self:UpdateLockState()
end

function ZO_CharacterCreateSlider:CanLock()
    return true
end

function ZO_CharacterCreateSlider:IsLocked()
    return self.m_lockState ~= TOGGLE_BUTTON_OPEN
end

function ZO_CharacterCreateSlider:UpdateLockState()
    local enabled = self.m_lockState == TOGGLE_BUTTON_OPEN
    self.m_slider:SetEnabled(enabled)

    if(enabled) then
        self:UpdateChangeButtons()
    else
        self:UpdateChangeButton(self.m_decrementButton, false)
        self:UpdateChangeButton(self.m_incrementButton, false)        
    end
end

function ZO_CharacterCreateSlider:UpdateChangeButton(button, isEnabled)
    if(button) then     --- This means that the gamepad version (which has no buttons) works fine.
        if(isEnabled) then
            button:SetState(BSTATE_NORMAL, false)
        else
            button:SetState(BSTATE_DISABLED, true)
        end
    end
end

function ZO_CharacterCreateSlider:UpdateChangeButtons(value)
    if(value == nil) then
        local _
        _, _, _, value = GetSliderInfo(self.m_sliderIndex)
    end

    local steppedValue = zo_floor(value * self.m_numSteps)

    self:UpdateChangeButton(self.m_decrementButton, steppedValue > 0)
    self:UpdateChangeButton(self.m_incrementButton, steppedValue < self.m_numSteps)
end

function ZO_CharacterCreateSlider:Update(value)
    self.m_initializing = true
    if(not value) then
        local _
        _, _, _, value = GetSliderInfo(self.m_sliderIndex)
    end

    self.m_slider:SetValue(value)
    self.m_initializing = nil

    self:UpdateChangeButtons(value)
end

--[[ Character Create Appearance Slider ]]--
-- Implemented as a mixin

ZO_CharacterCreateAppearanceSlider = {}

function ZO_CharacterCreateAppearanceSlider:SetData(appearanceName, numValues, displayName)
    self.m_category = appearanceName

    self:SetName(displayName, "SI_CHARACTERAPPEARANCENAME", appearanceName)
    
    self.m_legalInitialSettings = {}

    for appearanceIndex =  1, numValues do
        local _, _, _, legalInitialSetting = GetAppearanceValueInfo(appearanceName, appearanceIndex)
        if(legalInitialSetting) then
            table.insert(self.m_legalInitialSettings, appearanceIndex)
        end
    end

    self.m_initializing = true
    self.m_slider:SetMinMax(1, numValues)
    self.m_slider:SetValueStep(1)
    self.m_numSteps = numValues
    self:Update()
end

function ZO_CharacterCreateAppearanceSlider:SetValue(value)
    if(not self.m_initializing) then
        OnCharacterCreateOptionChanged()
        SetAppearanceValue(self.m_category, value)
        self:UpdateChangeButtons(value)
    end
end

function ZO_CharacterCreateAppearanceSlider:ChangeValue(changeAmount)
    local newSteppedValue = zo_floor(self.m_slider:GetValue()) + changeAmount
    self:SetValue(newSteppedValue)
    self:Update()
end

function ZO_CharacterCreateAppearanceSlider:Randomize(randomizeType)
    if(self.m_lockState == TOGGLE_BUTTON_OPEN) then
        local randomValue = 1

        if((randomizeType == "initial") and (#self.m_legalInitialSettings > 0)) then
            -- If this is the initial randomization and we have some legal initial values
            -- then only randomize over those values
            randomValue = self.m_legalInitialSettings[zo_random(1, #self.m_legalInitialSettings)]            
        else
            -- Otherwise, pick a random value from the valid values
            local maxValue = self.m_numSteps
            if(maxValue > 0) then
                randomValue = zo_random(1, maxValue)
            end
        end

        self:SetValue(randomValue)
        self:Update()
    end
end

function ZO_CharacterCreateAppearanceSlider:UpdateChangeButtons(value)
    if(value == nil) then
        value = GetAppearanceValue(self.m_category)
    end

    self:UpdateChangeButton(self.m_decrementButton, value > 1)
    self:UpdateChangeButton(self.m_incrementButton, value < self.m_numSteps)
end

function ZO_CharacterCreateAppearanceSlider:Update()
    self.m_initializing = true
    local currentValue = GetAppearanceValue(self.m_category)
    self.m_slider:SetValue(currentValue)
    self.m_initializing = nil

    self:UpdateChangeButtons(currentValue)
end

--[[ Character Creation Triangle Common Code]]--

ZO_CharacterCreateTriangle = ZO_Object:Subclass()

function ZO_CharacterCreateTriangle:New(triangleControl, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)
    local triangle = ZO_Object.New(self)

    triangle:Initialize(triangleControl, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)

    return triangle
end

function ZO_CharacterCreateTriangle:Initialize(triangleControl, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)
    GetControl(triangleControl, "LabelTop"):SetText(GetString(topStringId))
    GetControl(triangleControl, "LabelLeft"):SetText(GetString(leftStringId))
    GetControl(triangleControl, "LabelRight"):SetText(GetString(rightStringId))

    local pickerControl = GetControl(triangleControl, "Picker")
    self.m_width, self.m_height = pickerControl:GetDimensions()

    local picker = ZO_TrianglePicker:New(self.m_width, self.m_height, pickerControl:GetParent(), pickerControl)
    local thumb = GetControl(pickerControl, "Thumb")
    thumb:SetDrawLevel(1)
    picker:SetThumb(thumb)
    picker:SetThumbPosition(pickerControl:GetWidth() * 0.5, pickerControl:GetHeight() * 0.67) -- put the thumb in the "center" of the triangle for now.
    picker:SetUpdateCallback(function(picker, x, y) self:SetValue(x, y) end)

    triangleControl.m_sliderObject = self
    self.m_control = triangleControl
    self.m_padlock = GetControl(triangleControl, "Padlock")
    self.m_thumb = thumb
    self.m_picker = picker
    self.m_setterFn = setterFn
    self.m_updaterFn = updaterFn
    self.m_lockState = TOGGLE_BUTTON_OPEN

    -- NOTE: This button data may change to be defined by whatever is using the triangle object...for all triangles use the same icon layouts.
    -- NOTE: The coordinates are normalized!!  You can make the window any size and the subtriangles will still be correct.
    -- Liberties have been taken with the normalized values to account for image data (make the buttons appear at the correct junction points)
    self.triangleButtonData =
    {
        { x = 0.5, y = 0, },          -- point 0 (top)
        { x = 0.7455, y = 0.5034, },  -- proceeding clockwise, point 1, etc...
        { x = 1, y = 1, },
        { x = 0.5, y = 1, },
        { x = 0, y = 1, },
        { x = 0.2544, y = 0.5034, },
    }

    -- The picker control is split into 4 sub triangles, the picker defines points in CCW order, but the sub triangles
    -- used by the game are in CW order, so adjust accordingly
    self.subTriangles =
    {
        { 6, 2, 1 },
        { 4, 3, 2 },
        { 6, 2, 4, isMirrored = true }, -- the upside down triangle
        { 5, 4, 6},   
    }

    -- Create control points
    local baseName = triangleControl:GetName().."Point"
    local width = pickerControl:GetWidth()
    local height = pickerControl:GetHeight()

    self.m_subTriangles = {}
    local points = {}

    for i = 1, #self.subTriangles do
        local pointIndices = self.subTriangles[i]
        local isMirrored = pointIndices.isMirrored
        ZO_TrianglePoints_SetPoint(points, 1, self.triangleButtonData[pointIndices[1]], isMirrored)
        ZO_TrianglePoints_SetPoint(points, 2, self.triangleButtonData[pointIndices[2]], isMirrored)
        ZO_TrianglePoints_SetPoint(points, 3, self.triangleButtonData[pointIndices[3]], isMirrored)

        self.m_subTriangles[i] = ZO_Triangle:New(points, isMirrored)
    end
end

function ZO_CharacterCreateTriangle:ToggleLocked()
    self.m_lockState = not self.m_lockState
    ZO_ToggleButton_SetState(self.m_padlock, self.m_lockState)

    self:UpdateLockState()
end

function ZO_CharacterCreateTriangle:CanLock()
    return true
end

function ZO_CharacterCreateTriangle:IsLocked()
    return self.m_lockState ~= TOGGLE_BUTTON_OPEN
end

function ZO_CharacterCreateTriangle:Randomize(randomizeType)
    if(self.m_lockState == TOGGLE_BUTTON_OPEN) then
        local triangle = zo_random(1, #self.subTriangles)
        local a = zo_random() * .5
        local b = zo_random() * .5

        self.m_setterFn(triangle, a, b)
        if self.onValueChangedCallback then
            self.onValueChangedCallback()
        end
        self:Update()
    end
end

function ZO_CharacterCreateTriangle:SetOnValueChangedCallback(onValueChangedCallback)
    self.onValueChangedCallback = onValueChangedCallback
end

local function LengthSquared(x1, y1, x2, y2)
    local x = x2 - x1
    local y = y2 - y1
    return (x * x) + (y * y)
end

-- NOTE: x and y are normalized
function ZO_CharacterCreateTriangle:GetSubTriangle(x, y)
    local closestX
    local closestY
    local closestTri

    for triIndex, triangle in ipairs(self.m_subTriangles) do
        local cX, cY, isInside = triangle:ContainsPoint(x, y)

        if(isInside) then
            return triIndex, cX, cY
        end

        if(not closestX or (LengthSquared(cX, cY, x, y) < LengthSquared(closestX, closestY, x, y))) then
            closestX = cX
            closestY = cY
            closestTri = triIndex
        end
    end

    return closestTri, closestX, closestY
end

-- NOTE: x and y are normalized
function ZO_CharacterCreateTriangle:GetSubTriangleParams(triIndex, x, y)
    return self.m_subTriangles[triIndex]:GetTriangleParams(x, y)
end

function ZO_CharacterCreateTriangle:SetValue(x, y)
    x = x / self.m_width
    y = y / self.m_height

    local triangleIndex, subPosX, subPosY = self:GetSubTriangle(x, y)
    local setterParamA, setterParamB = self:GetSubTriangleParams(triangleIndex, subPosX, subPosY)

    self.m_setterFn(triangleIndex, setterParamA, setterParamB)
    if self.onValueChangedCallback then
        self.onValueChangedCallback()
    end
end

function ZO_CharacterCreateTriangle:Update()
    local triIndex, a, b = self.m_updaterFn()
    local triangle = self.m_subTriangles[triIndex]

    if(triangle) then
        local x, y = triangle:PointFromParams(a, b)
        self.m_picker:SetThumbPosition(self.m_width * x, self.m_height * y)
    end
end

-- Character Creation CurrentData
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
        if(position > 0) then return position end
        missingDataPosition = missingDataPosition + 1
        return missingDataPosition
    end

    local function ResetMissingDataPosition()
        missingDataPosition = 0
    end

    self.m_alliances = {}
    self.m_races = {}
    self.m_classes = {}
    self.m_templates = {}

    local alliances = self.m_alliances
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

    local classes = self.m_classes
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

    local races = self.m_races
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

    local templatesAllowed, templatesRequired = GetTemplateStatus()
    if(templatesAllowed) then
        local templates = self.m_templates

        if(not templatesRequired) then
            templates[#templates + 1] =
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
        end

        -- Keep these in the order that they are returned in so the template list matches the def order
        -- If lookup time ever becomes a problem, make a table that maps templateDefId -> tableIndex
        for i = 1, GetNumTemplates() do
            local templateDef, name, race, class, gender, alliance, overrideAppearance, isSelectable = GetTemplateInfo(i)
            templates[#templates + 1] =
            {
                template = templateDef,
                name = name,
                race = race,
                class = class,
                gender = gender,
                alliance = alliance,
                overrideAppearance = overrideAppearance,
                isSelectable = isSelectable
            }
        end
    end

    self:UpdateAllianceSelectability()
end

function ZO_CharacterCreateData:UpdateAllianceSelectability()
    -- Updates whether or not an alliance is selectable based on whether or not the races in the alliance can be selected
    -- This could actually be overridden by the "play any race as any alliance" entitlement, it's just a safe starting point
    for allianceIndex, allianceData in ipairs(self.m_alliances) do
        local currentAlliance = allianceData.alliance
        allianceData.isSelectable = false

        for raceIndex, raceData in ipairs(self.m_races) do
            if(raceData.alliance == currentAlliance and (raceData.isSelectable and raceData.isRadioEnabled)) then
                allianceData.isSelectable = true
                break
            end
        end
    end
end

function ZO_CharacterCreateData:GetAllianceInfo()
    return self.m_alliances
end

function ZO_CharacterCreateData:GetRaceInfo()
    return self.m_races
end

function ZO_CharacterCreateData:GetRaceForRaceDef(defId)
    local races = self.m_races
    for i = 1, #races do
        if(races[i].race == defId) then
            return races[i]
        end
    end
end

function ZO_CharacterCreateData:GetAllianceForAllianceDef(defId)
    local alliances = self.m_alliances
    for i = 1, #alliances do
        if(alliances[i].alliance == defId) then
            return alliances[i]
        end
    end
end

function ZO_CharacterCreateData:GetClassInfo()
    return self.m_classes
end

function ZO_CharacterCreateData:GetClassForClassDef(defId)
    local classes = self.m_classes
    for i = 1, #classes do
        if(classes[i].class == defId) then
            return classes[i]
        end
    end
end

function ZO_CharacterCreateData:GetTemplateInfo()
    return self.m_templates
end

function ZO_CharacterCreateData:GetTemplate(templateDef)
    for _, template in ipairs(self.m_templates) do
        if(template.template == templateDef) then
            return template
        end
    end
end

local function CheckAddOption(optionsTable, option)
    if(option.isSelectable) then
        optionsTable[#optionsTable + 1] = option
    end
end

function ZO_CharacterCreateData:PickRandom(validIndices, dataTable, defIdFieldName)
    local optionsTable = {}

    if(validIndices) then
        for _, dataIndex in ipairs(validIndices) do
            CheckAddOption(optionsTable, dataTable[dataIndex])
        end
    else
        for _, data in pairs(dataTable) do
            CheckAddOption(optionsTable, data)
        end
    end

    if(#optionsTable > 0) then
        local randomIndex = zo_random(#optionsTable)
        return optionsTable[randomIndex][defIdFieldName]
    end

    return 1
end

function ZO_CharacterCreateData:PickRandomRace(validIndicesTable)
    return self:PickRandom(validIndicesTable, self.m_races, "race")
end

function ZO_CharacterCreateData:PickRandomAlliance(validIndicesTable)
    -- Needs special behavior because this will usually follow the selected race...however
    -- some races have no alliance, so we should actually make a random choice for the alliance.
    -- So, if there are no preselected alliances do the fancy business.

    if(not validIndicesTable) then
        local currentRace = self:GetRaceForRaceDef(CharacterCreateGetRace())
        if(not currentRace or currentRace.alliance == 0) then
            return self:PickRandom(nil, self.m_alliances, "alliance")
        else
            return currentRace.alliance
        end
    end

    return self:PickRandom(validIndicesTable, self.m_alliances, "alliance")
end

function ZO_CharacterCreateData:PickRandomGender()
    local gender = zo_random(2)
    if(gender == 1) then
        return GENDER_MALE
    end

    return GENDER_FEMALE
end

function ZO_CharacterCreateData:PickRandomClass()
    return self:PickRandom(nil, self.m_classes, "class")
end

local function OnPregameCharacterListReceived(characterCount, previousCharacterCount)
    if(characterCount == 0) then
        if(previousCharacterCount > 0) then
            -- User just deleted their last character, go straight to character create
            PregameStateManager_SetState("CharacterCreate")
        else
            -- User is coming in from an initial login without any characters...play intro movie
            PregameStateManager_SetState("CharacterCreate_PlayIntro")
        end
    end
end

function ZO_CharacterCreate_PrepareFadeFromMovie()
    ZO_CharacterCreateOverlay.fadeTimeline:Stop()
    ZO_CharacterCreateOverlay:SetHidden(false)
    ZO_CharacterCreateOverlay:SetMouseEnabled(true)
    ZO_CharacterCreateOverlay:SetAlpha(1)
    g_playingTransitionAnimations = true
end

function ZO_CharacterCreate_AbortMovieFade()
    ZO_CharacterCreateOverlay:SetHidden(true)
    ZO_CharacterCreateOverlay:SetMouseEnabled(false)
    g_playingTransitionAnimations = false
end

function ZO_CharacterCreate_FadeFromMovie()
    ZO_CharacterCreateOverlay.fadeTimeline:PlayFromStart()
    g_playingTransitionAnimations = true
end

function ZO_CharacterCreate_FadeInMainControls()
    local screen

    if(IsConsoleUI()) then
        screen = ZO_CharacterCreate_Gamepad
    else
        screen = ZO_CharacterCreate
    end

    screen.fadeTimeline:PlayFromStart()
    g_playingTransitionAnimations = true
end

function ZO_CharacterCreate_FinishTransitions()
    ZO_CharacterCreateOverlay:SetMouseEnabled(false)
    g_playingTransitionAnimations = false

    PregameStateManager_SetState("CharacterCreate")
end

function ZO_CharacterCreate_Shared_Initialize()
    if not g_callbacksRegistered then
        CALLBACK_MANAGER:RegisterCallback("PregameCharacterListReceived", OnPregameCharacterListReceived)
        g_callbacksRegistered = true
    end
end
