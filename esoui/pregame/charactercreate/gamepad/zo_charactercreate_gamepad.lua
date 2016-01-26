local g_allianceRadioGroup
local g_raceRadioGroup
local g_classRadioGroup

local g_playingTransitionAnimations
local g_randomCharacterGenerated = false
local g_characterCreateOption = CHARACTER_CREATE_DEFAULT_LOCATION
local g_controlLookup = {}
local g_bucketManager
local g_manager
local g_randomizeAppearanceEnabled = true
local g_genderControlSlider

local CHARACTER_CREATE_GAMEPAD_DIALOG = "CHARACTER_CREATE_GAMEPAD"
local SKIP_TUTORIAL_GAMEPAD_DIALOG = "SKIP_TUTORIAL_GAMEPAD"

local IGNORE_POSITION = -1

local DEFAULT_OFFSET = -60
local SELECTOR_OFFSET = -10
local SELECTOR_ROW_OFFSET = -100

local INITIAL_BUCKET = CREATE_BUCKET_RACE

local SLIDER = 1
local APPEARANCE = 2
local CUSTOM = 3

local CUSTOM_CONTROL_GENDER = 1
local CUSTOM_CONTROL_ALLIANCE = 2
local CUSTOM_CONTROL_RACE = 3
local CUSTOM_CONTROL_CLASS = 4
local CUSTOM_CONTROL_PHYSIQUE = 5
local CUSTOM_CONTROL_FACE = 6

local PREVIEW_NO_GEAR = 1
local PREVIEW_NOVICE_GEAR = 2
local PREVIEW_VETERAN_GEAR = 3

local PREVIEW_GEAR_INFO = 
{
    [PREVIEW_NO_GEAR] = 
    {
        name = GetString(SI_CREATE_CHARACTER_GAMEPAD_PREVIEW_NO_GEAR),
        fn = function () SelectClothing(DRESSING_OPTION_NUDE) end
    },
    [PREVIEW_NOVICE_GEAR] =
    {
        name = GetString(SI_CREATE_CHARACTER_GAMEPAD_PREVIEW_NOVICE_GEAR),
        fn = function () SelectClothing(DRESSING_OPTION_STARTING_GEAR) end
    },
    [PREVIEW_VETERAN_GEAR] =
    {
        name = GetString(SI_CREATE_CHARACTER_GAMEPAD_PREVIEW_VETERAN_GEAR),
        fn = function () SelectClothing(DRESSING_OPTION_WARDROBE_1) end
    }
}

local CREATE_BUCKET_WINDOW_DATA_ORDER = {
    CREATE_BUCKET_RACE,
    CREATE_BUCKET_BODY,
    CREATE_BUCKET_BODY_SHAPE,
    CREATE_BUCKET_HEAD_TYPE,
    CREATE_BUCKET_FEATURES,
    CREATE_BUCKET_FACE,
}

-- Table for the Bucket data. Each Bucket is a tab in the UI.
local CREATE_BUCKET_WINDOW_DATA =
{
    [CREATE_BUCKET_RACE] = 
    { 
        windowName = "RaceBucket_Gamepad", 
        title = GetString(SI_CREATE_CHARACTER_GAMEPAD_BUCKET_TITLE_CHARACTER), 
        onExpandFn =    function()
                            if(not g_playingTransitionAnimations) then
                                CharacterCreateSetIdlePosture()
                            end
                            SetCharacterCameraZoomAmount(-1)
                        end,

        -- Controls for the tab
        controls =
        {
            -- <Type of controls (CUSTOM, APPEARANCE or SLIDER)>, <enum of control>
            { CUSTOM, CUSTOM_CONTROL_GENDER },
            { APPEARANCE, APPEARANCE_NAME_VOICE },
            { CUSTOM, CUSTOM_CONTROL_ALLIANCE },
            { CUSTOM, CUSTOM_CONTROL_RACE },
            { CUSTOM, CUSTOM_CONTROL_CLASS },
        }
    },

    [CREATE_BUCKET_BODY] = 
    { 
        windowName = "BodyTypeBucket_Gamepad", 
        title = GetString(SI_CREATE_CHARACTER_GAMEPAD_BUCKET_TITLE_BODY_TYPE), 
        onExpandFn = function() SetCharacterCameraZoomAmount(-1) end,

        controls =
        {
            { CUSTOM, CUSTOM_CONTROL_PHYSIQUE },
        }
    },

    [CREATE_BUCKET_BODY_SHAPE] = 
    { 
        windowName = "BodyShapeBucket_Gamepad", 
        title = GetString(SI_CREATE_CHARACTER_BUCKET_TITLE_BODY), 
        onExpandFn = function() SetCharacterCameraZoomAmount(-1) end,

        controls =
        {
            { SLIDER, SLIDER_NAME_CHARACTER_HEIGHT },
            { APPEARANCE, APPEARANCE_NAME_SKIN_TINT },
            { APPEARANCE, APPEARANCE_NAME_BODY_MARKING },
            { SLIDER, SLIDER_NAME_TORSO_SIZE },
            { SLIDER, SLIDER_NAME_CHEST_SIZE },
            { SLIDER, SLIDER_NAME_GUT_SIZE },
            { SLIDER, SLIDER_NAME_WAIST_SIZE },
            { SLIDER, SLIDER_NAME_ARM_SIZE },
            { SLIDER, SLIDER_NAME_HAND_SIZE },
            { SLIDER, SLIDER_NAME_HIP_SIZE },
            { SLIDER, SLIDER_NAME_BUTTOCKS_SIZE },
            { SLIDER, SLIDER_NAME_LEG_SIZE },
            { SLIDER, SLIDER_NAME_FOOT_SIZE },
        },
    },

    [CREATE_BUCKET_HEAD_TYPE] = 
    { 
        windowName = "HeadTypeBucket_Gamepad", 
        title = GetString(SI_CREATE_CHARACTER_GAMEPAD_BUCKET_TITLE_HEAD_TYPE), 
        onExpandFn = function() SetCharacterCameraZoomAmount(1) end,
        controls =
        {
            { CUSTOM, CUSTOM_CONTROL_FACE },
        }
    },

    [CREATE_BUCKET_FEATURES] = 
    { 
        windowName = "FeaturesBucket_Gamepad", 
        title = GetString(SI_CREATE_CHARACTER_GAMEPAD_BUCKET_TITLE_HEAD), 
        previousTab = CREATE_BUCKET_CLASS,
        onExpandFn = function() SetCharacterCameraZoomAmount(1) end,

        controls =
        {
            { APPEARANCE, APPEARANCE_NAME_AGE },
            { APPEARANCE, APPEARANCE_NAME_ACCESSORY },  -- "adornment"
            { APPEARANCE, APPEARANCE_NAME_HAIR_STYLE },
            { APPEARANCE, APPEARANCE_NAME_HAIR_TINT },
            { APPEARANCE, APPEARANCE_NAME_HEAD_MARKING },
            { SLIDER, SLIDER_NAME_FOREHEAD_SLOPE },
            { SLIDER, SLIDER_NAME_CHEEK_BONE_SIZE },
            { SLIDER, SLIDER_NAME_CHEEK_BONE_HEIGHT },
            { SLIDER, SLIDER_NAME_JAW_SIZE },
            { SLIDER, SLIDER_NAME_CHIN_HEIGHT },
            { SLIDER, SLIDER_NAME_CHIN_SIZE },
            { SLIDER, SLIDER_NAME_NECK_SIZE },
            { SLIDER, SLIDER_NAME_EAR_SIZE },
            { SLIDER, SLIDER_NAME_EAR_ROTATION },
            { SLIDER, SLIDER_NAME_EAR_HEIGHT },
            { SLIDER, SLIDER_NAME_EAR_TIP_FLARE },
        },
    },

    [CREATE_BUCKET_FACE] = 
    { 
        windowName = "FaceBucket_Gamepad", 
        title = GetString(SI_CREATE_CHARACTER_BUCKET_TITLE_FACE), 
        onExpandFn = function() SetCharacterCameraZoomAmount(1) end,

        controls =
        {
            { APPEARANCE, APPEARANCE_NAME_EYE_TINT },
            { SLIDER, SLIDER_NAME_EYE_SIZE },
            { SLIDER, SLIDER_NAME_EYE_ANGLE },
            { SLIDER, SLIDER_NAME_EYE_SEPARATION },
            { SLIDER, SLIDER_NAME_EYE_HEIGHT },
            { SLIDER, SLIDER_NAME_EYE_SQUINT },
            { APPEARANCE, APPEARANCE_NAME_EYEBROW },
            { SLIDER, SLIDER_NAME_EYEBROW_HEIGHT },
            --SLIDER_NAME_EYEBROW_ANGLE,  -- TODO Missing from Design?
            { SLIDER, SLIDER_NAME_EYEBROW_SKEW },
            { SLIDER, SLIDER_NAME_EYEBROW_DEPTH },
            { SLIDER, SLIDER_NAME_NOSE_SHAPE },
            { SLIDER, SLIDER_NAME_NOSE_HEIGHT },
            { SLIDER, SLIDER_NAME_NOSE_WIDTH },
            { SLIDER, SLIDER_NAME_NOSE_LENGTH },
            { SLIDER, SLIDER_NAME_MOUTH_HEIGHT },
            --SLIDER_NAME_MOUTH_WIDTH,  -- TODO Missing from Design?
            { SLIDER, SLIDER_NAME_MOUTH_CURVE },
            { SLIDER, SLIDER_NAME_LIP_FULLNESS },
        },
    },
}

-- Lore Info Controls

local CREATE_LORE_INFO_CONTROLS =
{
    [CUSTOM_CONTROL_ALLIANCE] = {
        "AllianceIcon",
        "AllianceName",
        "AllianceDescription",
    },
    [CUSTOM_CONTROL_RACE] = {
        "RaceIcon",
        "RaceName",
        "RaceDescription",
    },
    [CUSTOM_CONTROL_CLASS] = {
        "ClassIcon",
        "ClassName",
        "ClassDescription",
    },
}

function ZO_CharacterCreate_Gamepad_ShowLoreInfo(type)
    SCENE_MANAGER:AddFragment(CHARACTER_CREATE_GAMEPAD_LOREINFO_FRAGMENT)

    for src_type, t in pairs(CREATE_LORE_INFO_CONTROLS) do
        for i, control in pairs(t) do
            ZO_CharacterCreate_GamepadContainerLoreInfo:GetNamedChild(control):SetHidden(type ~= src_type)
        end
    end
end

function ZO_CharacterCreate_Gamepad_HideLoreInfo()
    SCENE_MANAGER:RemoveFragment(CHARACTER_CREATE_GAMEPAD_LOREINFO_FRAGMENT)
end

--[[ Character Create Manager ]]--

local CharacterCreateManager = ZO_CharacterCreateManager:Subclass()

function CharacterCreateManager:New(characterData)
    local object = ZO_CharacterCreateManager.New(self, characterData)

    return object
end

local function RefreshTabBar()
    ZO_GamepadGenericHeader_Refresh(ZO_CharacterCreate_Gamepad.header, ZO_CharacterCreate_Gamepad.headerData)
end

-- Bucket List Entry Setup
-- We use an empty template and then add/remove controls to the template.

local function SetupListEntry(control, data, selected, selectedDuringRebuild, enable, activated)
    if (control.m_occupiedBy) then
        if (control.m_occupiedBy:GetParent() == control) then
            -- Detach old control
            control.m_occupiedBy:ClearAnchors()
            control.m_occupiedBy:SetParent(ZO_CharacterCreate_Gamepad)
            control.m_occupiedBy:SetAnchor(TOPLEFT, ZO_CharacterCreate_Gamepad, TOPLEFT, 0, 0)
            control.m_occupiedBy:SetHidden(true)
            control.m_occupiedBy = nil
        end
    end

    control:SetDimensions(data.control:GetDimensions())

    data.control:SetParent(control)
    data.control:SetHidden(false)
    control.m_occupiedBy = data.control

    data.control:ClearAnchors()
    data.control:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
    data.control:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, 0, 0)

    if (selected and activated) then
        ZO_CharacterCreate_Gamepad:SetFocus(data.control.m_sliderObject)
    end
end

--[[ Character Creation Bucket Instances ]]--

local CharacterCreateBucket = ZO_CharacterCreateBucket:Subclass()

local function OnTabBarCategoryChanged(bucketCategory)
    if g_bucketManager then
        g_bucketManager:SwitchBucketsInternal(bucketCategory)
    end
end

function CharacterCreateBucket:New(parent, bucketCategory)
    local ccBucket = ZO_CharacterCreateBucket.New(self, parent, bucketCategory)

    local windowData = CREATE_BUCKET_WINDOW_DATA[bucketCategory]

    local container = CreateControlFromVirtual(windowData.windowName, parent, "CCCategoryBucket_Gamepad")

    local tabsTable = ZO_CharacterCreate_Gamepad.headerData.tabBarEntries
    local tabBarParams = {  text = windowData.title,
                            index = (#tabsTable + 1),
                            bucket = windowData,
                            canSelect = true,
                            callback = function() OnTabBarCategoryChanged(bucketCategory) end,
                         }
    table.insert(tabsTable, tabBarParams)
    ccBucket.m_index = #tabsTable

    container.m_bucket = ccBucket

    ccBucket.m_windowData = windowData
    ccBucket.m_container = container

    ccBucket.m_scrollChild = ZO_GamepadVerticalParametricScrollList:New(GetControl(container, "List"))
    ccBucket.m_scrollChild:SetFixedCenterOffset(DEFAULT_OFFSET)

    -- Handle all the input through this screen
    -- (so the focused control gets first access then we pass the input to the scrollchild)
    ccBucket.m_scrollChild:SetDirectionalInputEnabled(false) 

    return ccBucket
end

function CharacterCreateBucket:SetEnabled(enabled)
    local tabBarParams = ZO_CharacterCreate_Gamepad.headerData.tabBarEntries[self.m_index]
    if tabBarParams then
        tabBarParams.canSelect = enabled
    end
end

function CharacterCreateBucket:Finalize()
    self:GetScrollChild():Commit()
end

function CharacterCreateBucket:AddControl(control, updateFn, randomizeFn)
    control.m_bucket = self
    control:ClearAnchors()
    control:SetHidden(false)

    local list = self:GetScrollChild()
    list:AddEntry("ZO_CharacterCreateEntry_Gamepad", { control=control }, control.prePadding, control.postPadding, control.preSelectedOffsetAdditionalPadding, control.postSelectedOffsetAdditionalPadding, control.selectedCenterOffset)
    control:SetHidden(true)

    self.m_controlData[control] = { updateFn = updateFn, randomizeFn = randomizeFn }
end

function CharacterCreateBucket:RemoveControl(control)
    control.m_bucket = nil
    self.m_controlData[control] = nil
end

function CharacterCreateBucket:Reset()
    self.m_expanded = false
    self.m_controlData = {}

    self.m_scrollChild:Clear()
    self.m_scrollChild:AddDataTemplate("ZO_CharacterCreateEntry_Gamepad", SetupListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

function CharacterCreateBucket:Expand()
    local container = self:GetContainer()
    container:SetHidden(false)
    self.m_expanded = true
    
    local expandFn = self.m_windowData.onExpandFn
    if(expandFn) then
        expandFn()
    end
end

function CharacterCreateBucket:Collapse()
    self:GetContainer():SetHidden(true)
    self.m_expanded = false

    local collapseFn = self.m_windowData.onCollapseFn
    if(collapseFn) then
        collapseFn()
    end
end

-- Character Creation Bucket Manager

local CharacterCreateBucketManager = ZO_CharacterCreateBucketManager:Subclass()

function CharacterCreateBucketManager:New(container)
    local mgr = ZO_CharacterCreateBucketManager.New(self, container)

    mgr:Initialize()
    mgr.m_active = false

    return mgr
end

function CharacterCreateBucketManager:Initialize()
    for i,bucketCategory in ipairs(CREATE_BUCKET_WINDOW_DATA_ORDER) do
        self:AddBucket(bucketCategory)
    end
    RefreshTabBar()
end

function CharacterCreateBucketManager:AddBucket(bucketCategory)
    local bucket = CharacterCreateBucket:New(self.m_container, bucketCategory)
    local bucketContainer = bucket:GetContainer()

    bucketContainer:SetAnchor(TOPLEFT, self.m_container, TOPLEFT, 13, 138)
    bucketContainer:SetAnchor(BOTTOMRIGHT, self.m_container, BOTTOMRIGHT, -14, -73)

    self.m_buckets[bucketCategory] = bucket
end

function CharacterCreateBucketManager:Activate()
    if(not self.m_active) then
        self.m_active = true
        if(self.m_currentBucket) then
            self.m_currentBucket:GetScrollChild():Activate()
            self.m_currentBucket:GetScrollChild():RefreshVisible()
        end
    end
end

function CharacterCreateBucketManager:Deactivate()
    if(self.m_active) then
        self.m_active = false
        if(self.m_currentBucket) then
            self.m_currentBucket:GetScrollChild():Deactivate()
        end
    end
end

function CharacterCreateBucketManager:SwitchBuckets(bucketCategory)
    local bucket = self:BucketForCategory(bucketCategory)
    local tab = bucket.m_index
    ZO_GamepadGenericHeader_SetActiveTabIndex(ZO_CharacterCreate_Gamepad.header, tab)
end

function CharacterCreateBucketManager:SwitchBucketsInternal(bucketCategory)
    -- collapse current bucket
    if(self.m_currentBucket) then
        self.m_currentBucket:Collapse()
        if(self.m_active) then
            self.m_currentBucket:GetScrollChild():Deactivate()
        end
        self.m_currentBucket = nil
    end

    -- expand desired bucket
    local bucket = self:BucketForCategory(bucketCategory)

    if(bucket) then
        bucket:Expand()
        self.m_currentBucket = bucket
        if(self.m_active) then
            self.m_currentBucket:GetScrollChild():Activate()
            self.m_currentBucket:GetScrollChild():RefreshVisible()
        end
    end
end

function CharacterCreateBucketManager:MoveNext()
    self.m_currentBucket:GetScrollChild():MoveNext()
end

function CharacterCreateBucketManager:MovePrevious()
    self.m_currentBucket:GetScrollChild():MovePrevious()
end

function CharacterCreateBucketManager:SetEnabled(category, enabled)
    local bucket = self:BucketForCategory(category)
    bucket:SetEnabled(enabled)
end

function CharacterCreateBucketManager:Finalize()
    for _, bucket in pairs(self.m_buckets) do
        bucket:Finalize()
    end
end

function CharacterCreateBucketManager:RefreshBucketCenterOffset(focusControl)
    local offset = DEFAULT_OFFSET

    if focusControl and focusControl.CalculateAdditionalOffset then
        offset = offset + focusControl:CalculateAdditionalOffset()
    end

    self.m_currentBucket:GetScrollChild():SetFixedCenterOffset(offset)
end

-- Slider Randomization Helper...all sliders share the m_sliderObject from the top control, so this just helps cut down on duplicate functions
local function RandomizeSlider(control, randomizeType)
    control.m_sliderObject:Randomize(randomizeType)
end

-- Character Create Slider
-- To use this, create a CCSlider_Gamepad, its OnInitialize handler will create this object and wire everything up.
-- Those controls are intended to be used from a pool, and after acquiring those controls from the pool
-- the caller will use CharacterCreateSlider:SetData to set up that specific instance.
local CharacterCreateSlider = ZO_CharacterCreateSlider:Subclass()

function CharacterCreateSlider:New(control)
    local slider = ZO_CharacterCreateSlider.New(self, control)

    slider:EnableFocus(false)

    return slider
end

function CharacterCreateSlider:EnableFocus(enabled)
    if enabled then
        local r,g,b = GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED)
        self.m_name:SetColor(r,g,b)
        self.m_name:SetFont("ZoFontGamepad42")
        self.m_slider:SetColor(r,g,b)
        self.m_slider:GetNamedChild("Left"):SetColor(r,g,b)
        self.m_slider:GetNamedChild("Right"):SetColor(r,g,b)
        self.m_slider:GetNamedChild("Center"):SetColor(r,g,b)
        self.m_padlock:SetAlpha(1.0)
    else
        local r,g,b = GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED)
        self.m_name:SetColor(r,g,b)
        self.m_name:SetFont("ZoFontGamepad34")
        self.m_slider:SetColor(r,g,b)
        self.m_slider:GetNamedChild("Left"):SetColor(r,g,b)
        self.m_slider:GetNamedChild("Right"):SetColor(r,g,b)
        self.m_slider:GetNamedChild("Center"):SetColor(r,g,b)
        self.m_padlock:SetAlpha(0.5)
    end
end

function CharacterCreateSlider:Move(delta)
    if self:IsLocked() then
        return
    end

    OnCharacterCreateOptionChanged()
    local oldValue = self:GetValue()
    self:ChangeValue(delta)
    if oldValue ~= self:GetValue() then
        PlaySound(SOUNDS.DEFAULT_CLICK)
    end
end

function CharacterCreateSlider:MoveNext()
    self:Move(1)
end

function CharacterCreateSlider:MovePrevious()
    self:Move(-1)
end

-- Character Create Appearance Slider
-- Similar construction details to the CharacterCreateSlider.  Make the appropriate ui control from a template (color picker, icon picker, etc...)
-- and it will wire all the fields up.
local CharacterCreateAppearanceSlider = CharacterCreateSlider:Subclass()

function CharacterCreateAppearanceSlider:New(control)
    local slider = CharacterCreateSlider.New(self, control)

    zo_mixin(slider, ZO_CharacterCreateAppearanceSlider)

    return slider
end

-- Voice slider
local CharacterCreateVoiceSlider = CharacterCreateAppearanceSlider:Subclass()

function CharacterCreateVoiceSlider:New(control)
    local slider = CharacterCreateAppearanceSlider.New(self, control)
    slider.primaryButtonName = GetString(SI_CREATE_CHARACTER_GAMEPAD_TEST_VOICE)
    slider.showKeybind = true
    return slider
end

function CharacterCreateVoiceSlider:OnPrimaryButtonPressed(control)
    PreviewAppearanceValue(APPEARANCE_NAME_VOICE)
end

function CharacterCreateVoiceSlider:MoveNext()
    if self:IsLocked() then
        return
    end

    local oldValue = self.m_slider:GetValue()

    CharacterCreateAppearanceSlider.MoveNext(self)
end

function CharacterCreateVoiceSlider:MovePrevious()
    if self:IsLocked() then
        return
    end

    local oldValue = self.m_slider:GetValue()

    CharacterCreateAppearanceSlider.MovePrevious(self)
end

-- Gender slider
local CharacterCreateGenderSlider = CharacterCreateSlider:Subclass()

function CharacterCreateGenderSlider:New(control)
    local slider = CharacterCreateSlider.New(self, control)
    return slider
end

function CharacterCreateGenderSlider:SetData()
    self:SetName(GetString(SI_CREATE_CHARACTER_GAMEPAD_GENDER_SLIDER_NAME))

    self.m_legalInitialSettings = {}

    local numValues = 2
    for appearanceIndex =  1, numValues do
        table.insert(self.m_legalInitialSettings, appearanceIndex)
    end

    self.m_initializing = true
    self.m_slider:SetMinMax(1, numValues)
    self.m_slider:SetValueStep(1)
    self.m_numSteps = numValues
    self:Update()
end

function CharacterCreateGenderSlider:CanLock()
    return false
end

function CharacterCreateGenderSlider:SetValue(value)
    if(not self.m_initializing) then
        OnCharacterCreateOptionChanged()
        g_manager:SetGender(value)
    end
end

function CharacterCreateGenderSlider:ChangeValue(changeAmount)
    local newSteppedValue = zo_floor(self.m_slider:GetValue()) + changeAmount
    local min, max = self.m_slider:GetMinMax()
    newSteppedValue = zo_clamp(newSteppedValue, min, max)
    self:SetValue(newSteppedValue)
    self:Update()
end

function CharacterCreateGenderSlider:Randomize(randomizeType)
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

function CharacterCreateGenderSlider:Update()
    self.m_initializing = true
    local currentValue = CharacterCreateGetGender()
    self.m_slider:SetValue(currentValue)
    self.m_initializing = nil
end

-- Character Create Slider and Appearance Slider Managers
-- Manages a collection of sliders with a pool

local CharacterCreateSliderManager = ZO_Object:Subclass()
local g_sliderManager

function CharacterCreateSliderManager:New(parent)
    local manager = ZO_Object.New(self)

    manager.m_pools =
    {
        ["slider"] = ZO_ControlPool:New("CCSlider_Gamepad"),
        ["icon"] = ZO_ControlPool:New("CCAppearanceSlider_Gamepad"),
        ["color"] = ZO_ControlPool:New("CCAppearanceSlider_Gamepad", ZO_CharacterCreate_Gamepad, "Color"),     -- Color Pickers use appearance sliders on gamepad
        ["named"] = ZO_ControlPool:New("CCVoiceSlider_Gamepad", ZO_CharacterCreate_Gamepad, "Named"),
        ["gender"] = ZO_ControlPool:New("CCGenderSlider_Gamepad"),     -- Gender Slider
    }

    local function ResetSlider(sliderControl)
        g_bucketManager:RemoveControl(sliderControl)
        sliderControl:SetHidden(true)
    end

    for k,v in pairs(manager.m_pools) do
        v:SetCustomResetBehavior(ResetSlider)
    end

    return manager
end

function CharacterCreateSliderManager:AcquireObject(objectType)
    local pool = self.m_pools[objectType]
    if(pool) then
        return pool:AcquireObject()
    end
end

function CharacterCreateSliderManager:ReleaseAllObjects()
    for poolType, pool in pairs(self.m_pools) do
        pool:ReleaseAllObjects()
    end
end

--[[ Character Creation Triangle ]]--
-- Character Creation Triangle control. This is shared across gamepad and keyboard files
-- And uses a common subclass

local CharacterCreateTriangle = ZO_CharacterCreateTriangle:Subclass()

function CharacterCreateTriangle:New(triangleControl, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)
    local triangle = ZO_CharacterCreateTriangle.New(self, triangleControl, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)

    triangle.m_disableFocusMovementController = true     -- Prevent the Focus Movement Controller from interfering with the triangle movement

    return triangle
end

function CharacterCreateTriangle:UpdateLockState()
    local enabled = self.m_lockState == TOGGLE_BUTTON_OPEN
end

function CharacterCreateTriangle:UpdateDirectionalInput()
    if self:IsLocked() then
        return
    end

    local x, y = self.m_picker:GetThumbPosition()
    x = x / self.m_width
    y = y / self.m_height

    local mx, my = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK, ZO_DI_DPAD)

    local deadZone = 0.0
    local scale = 0.02

    local changed = false
    if (math.abs(mx) > deadZone) then
        x = x + mx * scale
        changed = true
    end

    if (math.abs(my) > deadZone) then
        y = y - my * scale
        changed = true
    end

    if changed then
        self:SetValue(self.m_width * x, self.m_height * y)
        self:Update()
    end
end

function CharacterCreateTriangle:EnableFocus(enabled)
    if enabled then
        DIRECTIONAL_INPUT:Activate(self, self.m_control)
    else
        DIRECTIONAL_INPUT:Deactivate(self)
    end
end

-- Character Creation Generic Selector

local CharacterCreateSelector = ZO_Object:Subclass()

function CharacterCreateSelector:New(control)
    local object = ZO_Object.New(self)

    object:Initialize(control)

    return object
end

function CharacterCreateSelector:Initialize(control)
    control.m_sliderObject = self
    self.m_control = control
    self.m_currentHighlight = 1
    self.m_highlightControl = CCSelectorHighlight
    self.m_selectedControl = CreateControlFromVirtual(control:GetName() .. "Selected", control, "CCSelected")

    self.m_stride = 3
end

function CharacterCreateSelector:FocusButton(enabled)
    local control = self:GetCurrentButton()
    if not control then
        return
    end

    local highlight = self.m_highlightControl

    if enabled then
        highlight:SetParent(control)
        highlight:SetAnchor(CENTER, control, CENTER, 0, 0)
        highlight:SetScale(1.3)
        highlight:SetHidden(false)

        self.focused = true
    else
        highlight:SetHidden(true)
        self.focused = false
    end

    self:UpdateButtons()
end

function CharacterCreateSelector:GetBannerText(control)
    return ""
end

function CharacterCreateSelector:SetHighlightIndex(index)
    self.m_currentHighlight = index
end

function CharacterCreateSelector:SetHighlightIndexByColumn(index, moveDown)
    -- To be overridden
end

function CharacterCreateSelector:GetHighlightColumn()
    -- To be overridden
    return 0
end

function CharacterCreateSelector:GetFocusIndex()
    return self.m_control.m_sliderObject.info.index
end

function CharacterCreateSelector:GetSelectedIndex()
    return self.m_selectedPosition
end

function CharacterCreateSelector:UpdateButtons()
    local selectionName = self.m_control:GetNamedChild("SelectionName")
    local selectedControl = self.m_selectedControl
    local info = self:GetSelectionInfo()
    local bannerText = nil
    for i = 1, #info do
        if info[i].position == IGNORE_POSITION then
            -- Ignore
        elseif(info[i].selectorButton:GetState() == BSTATE_PRESSED) then
            -- If the button is selected
            bannerText = bannerText or self:GetBannerText(info[i].selectorButton)

            selectedControl:SetParent(info[i].selectorButton)
            selectedControl:SetAnchor(CENTER, control, CENTER, 0, 0)
            selectedControl:SetScale(1.3)
            selectedControl:SetHidden(false)
            self.m_selectedPosition = info[i].position
        elseif(info[i].position == self.m_currentHighlight and self.focused) then
            -- If we have the button highlighted (in focus)
            bannerText = self:GetBannerText(info[i].selectorButton)
        else
            -- Unselected and unhighlighted
        end
    end

    selectionName:SetText(bannerText)
end

function CharacterCreateSelector:EnableFocus(enabled)

    local name = self.m_control:GetNamedChild("Name")
    local selectionName = self.m_control:GetNamedChild("SelectionName")
    if name then
        if enabled then
            name:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
            name:SetFont("ZoFontGamepad42")
            selectionName:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
        else
            name:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
            name:SetFont("ZoFontGamepad34")
            selectionName:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
        end
    end

    self:FocusButton(enabled)
end

function CharacterCreateSelector:OnPrimaryButtonPressed()
    local control = self:GetCurrentButton()
    ZO_CharacterCreate_Gamepad_OnSelectorPressed(control)
end

function CharacterCreateSelector:GetButton(position)
    if position == IGNORE_POSITION then
        return nil
    end

    local info = self:GetSelectionInfo()
    for i = 1, #info do
        if(info[i].position == position) then
            return info[i].selectorButton
        end
    end
    return nil
end

function CharacterCreateSelector:GetCurrentButton()
    return self:GetButton(self.m_currentHighlight)
end

function CharacterCreateSelector:MoveNext()
    local count =  #self:GetSelectionInfo() - self.m_currentHighlight;
    local newHighlight = self.m_currentHighlight

    while (count > 0) do
        newHighlight = math.min(newHighlight + 1, #self:GetSelectionInfo())
        if (self.m_currentHighlight % self.m_stride ~= 0 and self:IsButtonValid(newHighlight)) then
            self:FocusButton(false)
            self.m_currentHighlight = newHighlight
            self:FocusButton(true)
            PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
            break
        end
        count = count - 1
    end
end

function CharacterCreateSelector:MovePrevious()
    local count = self.m_currentHighlight - 1
    local newHighlight = self.m_currentHighlight

    while (count > 0) do
        newHighlight = math.max(newHighlight - 1, 1)
        
        if (self.m_currentHighlight % self.m_stride ~= 1 and self:IsButtonValid(newHighlight)) then
            self:FocusButton(false)
            self.m_currentHighlight = newHighlight
            self:FocusButton(true)
            PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
            break
        end
        count = count - 1
    end
end

function CharacterCreateSelector:FindNearestValidButton(newHighlight)
    local count = #self:GetSelectionInfo()

    while(count >= 0) do
        if (self:IsButtonValid(newHighlight)) then
            return newHighlight
        end
        newHighlight = (newHighlight + 1) % (#self:GetSelectionInfo() + 1)
        count = count - 1
    end
    return nil
end

function CharacterCreateSelector:IsButtonValid(buttonIndex)
    local isValid = false
    local newButton = self:GetButton(buttonIndex)
    if (newButton) then
        local newButtonState = newButton:GetState()
        isValid = (newButtonState ~= BSTATE_DISABLED_PRESSED) and (newButtonState ~= BSTATE_DISABLED)
    end
    return isValid
end

function CharacterCreateSelector:ProcessUpDownMove(move)
    local newHighlight = self.m_currentHighlight
    local sound = nil
    if move == MOVEMENT_CONTROLLER_MOVE_NEXT then
        newHighlight = newHighlight + self.m_stride
        sound = SOUNDS.GAMEPAD_MENU_DOWN
    elseif move == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        newHighlight = newHighlight - self.m_stride
        sound = SOUNDS.GAMEPAD_MENU_UP
    elseif not self:IsButtonValid(newHighlight) then
        newHighlight = self:FindNearestValidButton(newHighlight)
    else
        newHighlight = nil    
    end

    if (newHighlight) then
        if ((newHighlight < 1) or (newHighlight > #self:GetSelectionInfo())) then
            newHighlight = nil
        else
            PlaySound(sound)
        end
    end

    return newHighlight
end

function CharacterCreateSelector:FocusUpdate(move)
    -- Up/down movement
    local newHighlight = self:ProcessUpDownMove(move)

    if (newHighlight) then
        self:FocusButton(false)
        self.m_currentHighlight = newHighlight
        self:FocusButton(true)
        return true
    end
end

function CharacterCreateSelector:CalculateAdditionalOffset()
    return math.ceil(self.m_currentHighlight / self.m_stride) * SELECTOR_ROW_OFFSET + SELECTOR_OFFSET
end

-- Character Creation Alliance

local CharacterCreateAllianceSelector = CharacterCreateSelector:Subclass()

function CharacterCreateAllianceSelector:New(control)
    local object = CharacterCreateSelector.New(self, control)

    object.m_stride = 3
    object.showKeybind = true
end

function CharacterCreateAllianceSelector:GetSelectionInfo(control)
    return ZO_CharacterCreate_GetCharacterData():GetAllianceInfo()
end

function CharacterCreateAllianceSelector:GetBannerText(control)
    return zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(control.defId))
end

function CharacterCreateAllianceSelector:SetHighlightIndexByColumn(index, moveDown)
    self.m_currentHighlight = index
end

function CharacterCreateAllianceSelector:GetHighlightColumn()
    return self.m_currentHighlight
end

function CharacterCreateAllianceSelector:EnableFocus(enabled)
    if enabled then
        ZO_CharacterCreate_Gamepad_ShowLoreInfo(CUSTOM_CONTROL_ALLIANCE)
    else
        ZO_CharacterCreate_Gamepad_HideLoreInfo()
    end

    CharacterCreateSelector.EnableFocus(self, enabled)
end

-- Character Creation Race

local CharacterCreateRaceSelector = CharacterCreateSelector:Subclass()

function CharacterCreateRaceSelector:New(control)
    local object = CharacterCreateSelector.New(self, control)

    object.m_stride = 3
    object.showKeybind = true
    control.preSelectedOffsetAdditionalPadding = -20
end

function CharacterCreateRaceSelector:IsValidRaceForAlliance(raceButtonPosition)
    local selectedAlliance = CharacterCreateGetAlliance()

    local button = self:GetButton(raceButtonPosition)
    if not button then
        return false
    end

    local alliance = button.alliance

    return alliance == 0 or alliance == selectedAlliance or CanPlayAnyRaceAsAnyAlliance()
end

function CharacterCreateRaceSelector:GetSelectionInfo(control)
    return ZO_CharacterCreate_GetCharacterData():GetRaceInfo()
end

function CharacterCreateRaceSelector:GetBannerText(control)
    local currentGender = CharacterCreateGetGender()

    return zo_strformat(SI_RACE_NAME, GetRaceName(currentGender, control.defId))
end

function CharacterCreateRaceSelector:SetHighlightIndexByColumn(index, moveDown)
    local maxIndex = self.m_control.numButtons

    if not moveDown then
        local currentIndex = maxIndex
        while(currentIndex > 0) do
            if self:GetColumnFromIndex(currentIndex) == index and self:IsValidRaceForAlliance(currentIndex) then
                self.m_currentHighlight = currentIndex
                return
            end
            currentIndex = currentIndex - 1
        end
    end

	self.m_currentHighlight = index
end

function CharacterCreateRaceSelector:GetColumnFromIndex(index)
    local maxIndex = #self:GetSelectionInfo()

    -- These are the centered buttons
    if maxIndex == 4 then
        if index == 4 then
            return 2
        end
    elseif maxIndex == 10 then
        if index == 10 then
            return 2
        end
    end

    return (index - 1) % self.m_stride + 1
end

function CharacterCreateRaceSelector:GetHighlightColumn(index)
    return self:GetColumnFromIndex(self.m_currentHighlight)
end

function CharacterCreateRaceSelector:EnableFocus(enabled)
    if enabled then
        ZO_CharacterCreate_Gamepad_ShowLoreInfo(CUSTOM_CONTROL_RACE)
    else
        ZO_CharacterCreate_Gamepad_HideLoreInfo()
    end

    CharacterCreateSelector.EnableFocus(self, enabled)
end

function CharacterCreateRaceSelector:GetNearestValidRace(index, minIndex)
    local maxIndex = #self:GetSelectionInfo()
    if not self:IsValidRaceForAlliance(index) then
        index = minIndex

        while index < maxIndex and not self:IsValidRaceForAlliance(index) do
            index = index + 1
        end
    end
    return index
end

function CharacterCreateRaceSelector:ProcessUpDownMove(move)
    local newHighlight = self.m_currentHighlight

    -- Button layout is
    -- 1 2 3
    -- 4 5 6
    -- 7 8 9
    --   10

    local LAST_ROW_LEFT = 7
    local LAST_ROW_MIDDLE = 8
    local MAX_RACE = 10

    if move == MOVEMENT_CONTROLLER_MOVE_NEXT then
        if (newHighlight == MAX_RACE) then
            return nil
        elseif (newHighlight >= LAST_ROW_LEFT) then
            newHighlight = MAX_RACE
        else
            newHighlight = newHighlight + self.m_stride

            -- Make sure we move it back up to a valid button
            newHighlight = self:GetNearestValidRace(newHighlight, newHighlight - (newHighlight - 1) % self.m_stride)
        end
    elseif move == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        if (newHighlight == MAX_RACE) then
            -- Move directly back up
            newHighlight = LAST_ROW_MIDDLE

            -- Make sure we move it back up to a valid button
            newHighlight = self:GetNearestValidRace(newHighlight, LAST_ROW_LEFT)
        else
            newHighlight = newHighlight - self.m_stride
        end
    else
        return nil
    end

    if self:IsValidRaceForAlliance(newHighlight) then
        if move == MOVEMENT_CONTROLLER_MOVE_NEXT then
            PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
        elseif move == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            PlaySound(SOUNDS.GAMEPAD_MENU_UP)
        end

        return newHighlight
    end
    return nil
end

-- Character Creation Class

local CharacterCreateClassSelector = CharacterCreateSelector:Subclass()

function CharacterCreateClassSelector:New(control)
    local object = CharacterCreateSelector.New(self, control)

    object.m_stride = 3
    object.showKeybind = true
end

function CharacterCreateClassSelector:GetSelectionInfo(control)
    return ZO_CharacterCreate_GetCharacterData():GetClassInfo()
end

function CharacterCreateClassSelector:GetBannerText(control)
    local currentGender = CharacterCreateGetGender()

    return zo_strformat(SI_CLASS_NAME, GetClassName(currentGender, control.defId))
end

function CharacterCreateClassSelector:SetHighlightIndexByColumn(index, moveDown)
    self.m_currentHighlight = index
end

function CharacterCreateClassSelector:GetHighlightColumn()
    if self.m_currentHighlight == 4 then
        return 2
    end
    return self.m_currentHighlight
end

function CharacterCreateClassSelector:EnableFocus(enabled)
    if enabled then
        ZO_CharacterCreate_Gamepad_ShowLoreInfo(CUSTOM_CONTROL_CLASS)
    else
        ZO_CharacterCreate_Gamepad_HideLoreInfo()
    end

    CharacterCreateSelector.EnableFocus(self, enabled)
end

function CharacterCreateClassSelector:ProcessUpDownMove(move)
    -- Button layout is
    -- 1 2 3
    --   4 
    -- So moving down from 1-3 goes to 4
    -- and moving up from 4 goes to 2
    local newHighlight = self.m_currentHighlight
    if move == MOVEMENT_CONTROLLER_MOVE_NEXT then
        if newHighlight <= 3 then
            newHighlight = 4
            PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
        else
            newHighlight = nil
        end
    elseif move == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        if newHighlight == 4 then
            newHighlight = 2
            PlaySound(SOUNDS.GAMEPAD_MENU_UP)
        else
            newHighlight = nil
        end
    elseif not self:IsButtonValid(newHighlight) then
        newHighlight = self:FindNearestValidButton(newHighlight)
    else
        newHighlight = nil    
    end

    if (newHighlight) then
        if ((newHighlight < 1) or (newHighlight > #self:GetSelectionInfo())) then
            newHighlight = nil
        end
    end

    return newHighlight
end

-- Character Creation CurrentData
-- The important stuff, data describing all the valid options you can choose from
local g_characterData

function ZO_CharacterCreate_GetCharacterData()
    return g_characterData
end

-- Creator Control Initialization

local g_characterStartLocation

local function GetCurrentAllianceData()
    local selectedAlliance = CharacterCreateGetAlliance()
    local alliance = g_characterData:GetAllianceForAllianceDef(selectedAlliance)

    if(alliance) then
        return alliance.name, alliance.backdropTop, alliance.backdropBottom, alliance.lore
    end

    return "", "", ""
end

local function UpdateGenderSpecificText(currentGender)
    currentGender = currentGender or CharacterCreateGetGender()

    ZO_CharacterCreate_GamepadContainerLoreInfoRaceName:SetText(zo_strformat(SI_RACE_NAME, GetRaceName(currentGender, CharacterCreateGetRace())))
    ZO_CharacterCreate_GamepadContainerLoreInfoClassName:SetText(zo_strformat(SI_CLASS_NAME, GetClassName(currentGender, CharacterCreateGetClass())))
end

local function SetSelectorButtonEnabled(selectorButton, radioGroup, enabled)
    radioGroup:SetButtonIsValidOption(selectorButton, enabled)

    if(enabled) then
        selectorButton:SetDesaturation(0)
    else
        selectorButton:SetDesaturation(1)
    end
end

local function InitializeSelectorButton(buttonControl, data, radioGroup)
    if(data == nil) then return end

    buttonControl:SetHidden(false)

    buttonControl:SetNormalTexture(data.gamepadNormalIcon)
    buttonControl:SetPressedTexture(data.gamepadPressedIcon)

    radioGroup:Add(buttonControl)
   
    SetSelectorButtonEnabled(buttonControl, radioGroup, data.isSelectable and (data.isRadioEnabled ~= false))
    
    -- There should be a single button that represents this piece of data
    -- So add the button control to the character data so that if it's needed
    -- later to update state, there are no insane hoops to jump through to get the button.
    -- For example, these buttons are now accessible by calling g_characterData:GetRaceInfo()[raceIndex].selectorButton
    data.selectorButton = buttonControl
end

local function AddRaceSelectionDataToSelector(buttonControl, raceData)
    buttonControl.nameFn = GetRaceName
    buttonControl.defId = raceData.race
    buttonControl.alliance = raceData.alliance
end

local function InitializeRaceSelectors()
    local races = g_characterData:GetRaceInfo()
    local layoutTable =
    {
        ZO_CharacterCreate_GamepadRaceColumn11,
        ZO_CharacterCreate_GamepadRaceColumn21,
        ZO_CharacterCreate_GamepadRaceColumn31,
        ZO_CharacterCreate_GamepadRaceColumn12,
        ZO_CharacterCreate_GamepadRaceColumn22,
        ZO_CharacterCreate_GamepadRaceColumn32,
        ZO_CharacterCreate_GamepadRaceColumn13,
        ZO_CharacterCreate_GamepadRaceColumn23,
        ZO_CharacterCreate_GamepadRaceColumn33,
        ZO_CharacterCreate_GamepadRaceColumn24,
    }

    -- Hide and reset buttons
    for i, button in ipairs(layoutTable) do
        button:SetHidden(true)
        local raceButton = button:GetNamedChild("Button")
        raceButton.nameFn = nil
        raceButton.defId = nil
        raceButton.alliance = nil
    end

    -- We either need to show 3,4,9 or 10 buttons
    local selectedAlliance = CharacterCreateGetAlliance()
    local position = 1
    local finalRace
    for i, race in ipairs(races) do
        if race.isSelectable then
            if race.alliance == 0 or race.alliance == selectedAlliance or CanPlayAnyRaceAsAnyAlliance() then
                race.position = position
                position = position + 1
                finalRace = race
            else
                race.position = IGNORE_POSITION
            end
        end
    end

    -- If there are 4 buttons we should center the final button
    local raceObject = ZO_CharacterCreate_GamepadRace
    raceObject.numButtons = position - 1
    if raceObject.numButtons == 4 then
        finalRace.position = 5
    end

    local invalidRaces = {}
    for i, race in ipairs(races) do
        if race.position == IGNORE_POSITION then
            --nothing for now
        elseif race.isSelectable then
            local raceContainer = layoutTable[race.position]
            raceContainer:SetHidden(false)
            local raceButton = raceContainer:GetNamedChild("Button")
            InitializeSelectorButton(raceButton, race, g_raceRadioGroup)
            AddRaceSelectionDataToSelector(raceButton, race)
        else
            table.insert(invalidRaces, 1, i)
        end
    end

    for i=1, #invalidRaces do
        table.remove(races, invalidRaces[i])
    end
end

local function SetValidRace()
    local currentRace = CharacterCreateGetRace()
    local currentAlliance = CharacterCreateGetAlliance()

    local race = g_characterData:GetRaceForRaceDef(currentRace)
    if race then
        if race.alliance == 0 or race.alliance == currentAlliance or CanPlayAnyRaceAsAnyAlliance() then
            return
        end
    end

    local races = g_characterData:GetRaceInfo()
    for i, race in ipairs(races) do
        if race.isSelectable then
            if race.alliance == 0 or race.alliance == currentAlliance or CanPlayAnyRaceAsAnyAlliance() then
                g_manager:SetRace(race.race, "preventAllianceChange")
                return
            end
        end
    end
end

local function UpdateRaceControl()
    InitializeRaceSelectors()

    local currentRace = CharacterCreateGetRace()

    local function IsRaceClicked(button)
        return button.defId == currentRace
    end

    g_raceRadioGroup:UpdateFromData(IsRaceClicked)
    ZO_CharacterCreate_GamepadRace.m_sliderObject:UpdateButtons()

    -- if we're focused on race, refocus to update name
    if (ZO_CharacterCreate_GamepadRace.m_sliderObject.focused) then
        ZO_CharacterCreate_GamepadRace.m_sliderObject:FocusButton(true)
    end

    local currentAlliance = CharacterCreateGetAlliance()

    local function IsAllianceClicked(button)
        return button.defId == currentAlliance
    end

    g_allianceRadioGroup:UpdateFromData(IsAllianceClicked)
    ZO_CharacterCreate_GamepadAlliance.m_sliderObject:UpdateButtons()

    local race = g_characterData:GetRaceForRaceDef(currentRace)
    if(race) then
        UpdateGenderSpecificText()

        ZO_CharacterCreate_GamepadContainerLoreInfoRaceDescription:SetText(race.lore)

        ZO_CharacterCreate_GamepadContainerLoreInfoRaceIcon:SetTexture(race.gamepadPressedIcon)

        local alliance = g_characterData:GetAllianceForAllianceDef(currentAlliance)
        ZO_CharacterCreate_GamepadContainerLoreInfoAllianceIcon:SetTexture(alliance.gamepadPressedIcon)
        ZO_CharacterCreate_GamepadContainerLoreInfoAllianceName:SetText(zo_strformat(SI_ALLIANCE_NAME, alliance.name))
        ZO_CharacterCreate_GamepadContainerLoreInfoAllianceDescription:SetText(alliance.lore)
    end
end

local function UpdateClassControl()
    local currentClass = CharacterCreateGetClass()

    local function IsClassClicked(button)
        return button.defId == currentClass
    end

    g_classRadioGroup:UpdateFromData(IsClassClicked)
    ZO_CharacterCreate_GamepadClass.m_sliderObject:UpdateButtons()

    local class = g_characterData:GetClassForClassDef(currentClass)
    if(class) then
        UpdateGenderSpecificText()
        ZO_CharacterCreate_GamepadContainerLoreInfoClassIcon:SetTexture(class.gamepadPressedIcon)
        ZO_CharacterCreate_GamepadContainerLoreInfoClassDescription:SetText(class.lore)
    end
end

local function UpdateSlider(slider)
    slider.m_sliderObject:Update()
end

local function FindBucketFromName(type, name)
    for k,v in pairs(CREATE_BUCKET_WINDOW_DATA) do
        if v.controls then
            for index, item in ipairs(v.controls) do
                if (item[1] == type and item[2] == name) then
                    return k, index
                end
            end
        end
    end
    return nil
end

local function ControlComparator(data1, data2)
    local bucket1, index1 = data1.bucketIndex, data1.index
    local bucket2, index2 = data2.bucketIndex, data2.index

    if (bucket1 == nil) then
        return false
    elseif (bucket2 == nil) then
        return true
    end

    if (bucket1 ~= bucket2) then
        return bucket1 < bucket2
    end

    return index1 < index2
end

local function ZO_CharacterCreate_Gamepad_CreateGenderControl()
    local sliderControl = g_sliderManager:AcquireObject("gender")
    sliderControl.m_sliderObject:SetData()
    g_genderControlSlider = sliderControl.m_sliderObject
    return sliderControl
end

function CharacterCreateManager:InitializeControls()
    -- If this was being suppressed changes MUST be applied now or there will be no slider data to build
    SetSuppressCharacterChanges(false)

    g_sliderManager:ReleaseAllObjects()

    g_bucketManager:Reset()

    local self = ZO_CharacterCreate_Gamepad
    local controlData = {}

    self.controls = {}

    -- Sliders
    for i = 1, GetNumSliders() do
        local name, category, steps, value, defaultValue = GetSliderInfo(i)

        if(name) then
            local sliderControl = g_sliderManager:AcquireObject("slider")
            sliderControl.m_sliderObject:SetData(i, name, category, steps, value, defaultValue)

            local bucketIndex, index = FindBucketFromName(SLIDER, name)

            if bucketIndex then
                local info = { bucketIndex = bucketIndex, index = index, type = SLIDER, name = name, control = sliderControl, updateFn = UpdateSlider, randomizeFn = RandomizeSlider }
                sliderControl.m_sliderObject.info = info
                controlData[#controlData + 1] = info
                self.controls[bucketIndex] = self.controls[bucketIndex] or {}
                self.controls[bucketIndex][index] = sliderControl.m_sliderObject
            else
                sliderControl:SetHidden(true)       -- Hide unused controls
            end
        end
    end

    -- Appearances
    for i = 1, GetNumAppearances() do
        local name, appearanceType, numValues, displayName = GetAppearanceInfo(i)

        if(numValues > 0) then
            local appearanceControl = g_sliderManager:AcquireObject(appearanceType)
            appearanceControl.m_sliderObject:SetData(name, numValues, displayName)

            local bucketIndex, index = FindBucketFromName(APPEARANCE, name)

            if bucketIndex then
                local info = { bucketIndex = bucketIndex, index = index, type = APPEARANCE, name = name, control = appearanceControl, updateFn = UpdateSlider, randomizeFn = RandomizeSlider }
                appearanceControl.m_sliderObject.info = info
                controlData[#controlData + 1] = info
                self.controls[bucketIndex] = self.controls[bucketIndex] or {}
                self.controls[bucketIndex][index] = appearanceControl.m_sliderObject
            else
                appearanceControl:SetHidden(true)       -- Hide unused controls
            end
        end
    end

    -- Custom controls
    local customControls = 
    {

        [CUSTOM_CONTROL_GENDER] = {control = ZO_CharacterCreate_Gamepad_CreateGenderControl, updateFn = UpdateSlider},
        [CUSTOM_CONTROL_ALLIANCE] = {control = ZO_CharacterCreate_GamepadAlliance, updateFn = UpdateRaceControl},
        [CUSTOM_CONTROL_RACE] = {control = ZO_CharacterCreate_GamepadRace, updateFn = UpdateRaceControl},
        [CUSTOM_CONTROL_CLASS] = {control = ZO_CharacterCreate_GamepadClass, updateFn = UpdateClassControl},
        [CUSTOM_CONTROL_PHYSIQUE] = {control = ZO_CharacterCreate_GamepadPhysiqueSelection, updateFn = UpdateSlider, randomizeFn = RandomizeSlider},
        [CUSTOM_CONTROL_FACE] = {control = ZO_CharacterCreate_GamepadFaceSelection, updateFn = UpdateSlider, randomizeFn = RandomizeSlider},
    }

    for bucketIndex, bucket in pairs(CREATE_BUCKET_WINDOW_DATA) do
        if bucket.controls then
            for index, controlItem in ipairs(bucket.controls) do
                if controlItem[1] == CUSTOM then
                    local controlInfo = customControls[ controlItem[2] ]

                    local control = controlInfo.control
                    if type(control) == "function" then
                        control = control()
                    end

                    local info = { index = index,
                                    type = CUSTOM,
                                    bucketIndex = bucketIndex,
                                    control = control,
                                    updateFn = controlInfo.updateFn,
                                    randomizeFn = controlInfo.randomizeFn }

                    control.m_sliderObject = control.m_sliderObject or {}
                    control.m_sliderObject.info = info
                    controlData[#controlData + 1] = info
                    self.controls[bucketIndex] = self.controls[bucketIndex] or {}
                    self.controls[bucketIndex][index] = control.m_sliderObject
                end
            end
        end
    end

    table.sort(controlData, ControlComparator)

    for _, orderingData in ipairs(controlData) do
        g_bucketManager:AddControl(orderingData.control, orderingData.bucketIndex, orderingData.updateFn, orderingData.randomizeFn)
    end

    for category, bucket in pairs(CREATE_BUCKET_WINDOW_DATA) do
        g_bucketManager:SetEnabled(category, (self.controls[category] ~= nil))
    end

    g_bucketManager:Finalize()

    -- TODO: this fixes a bug where the triangles don't reflect the correct data...there will be more fixes to pregameCharacterManager to address the real issue
    -- (where the triangle data needs to live on its own rather than being tied to the unit)
    UpdateSlider(ZO_CharacterCreate_GamepadPhysiqueSelection)
    UpdateSlider(ZO_CharacterCreate_GamepadFaceSelection)
end

local function OnLogoutSuccessful()
    g_randomCharacterGenerated = false
end

local function PickRandomSelectableClass()
    CharacterCreateSetClass(g_characterData:PickRandomClass())
end

local function PickRandomGender()
    CharacterCreateSetGender(g_characterData:PickRandomGender())
end

function ZO_CharacterCreate_Gamepad_GenerateRandomCharacter()
    if(not g_randomCharacterGenerated and g_characterData ~= nil and g_characterData:GetRaceInfo() ~= nil) then
        g_randomCharacterGenerated = true
        CharacterCreateSetRace(g_characterData:PickRandomRace())
        CharacterCreateSetAlliance(g_characterData:PickRandomAlliance())
        CharacterCreateSetGender(g_characterData:PickRandomGender())
        CharacterCreateSetClass(g_characterData:PickRandomClass())

        g_manager:InitializeControls()
        ZO_CharacterCreate_Gamepad_RandomizeAppearance("initial")
        return true
    end

    return false
end

local function InitializeAllianceSelector(allianceButton, allianceData)
    InitializeSelectorButton(allianceButton, allianceData, g_allianceRadioGroup)

    allianceButton.name = allianceData.name
    allianceButton.defId = allianceData.alliance
end

local function InitializeAllianceSelectors()
    local layoutTable =
    {
        ZO_CharacterCreate_GamepadAllianceAllianceSelector1,
        ZO_CharacterCreate_GamepadAllianceAllianceSelector2,
        ZO_CharacterCreate_GamepadAllianceAllianceSelector3,
    }

    local alliances = g_characterData:GetAllianceInfo()
    for _, alliance in ipairs(alliances) do
        local selector = layoutTable[alliance.position]
        InitializeAllianceSelector(selector, alliance)
    end

end

local function AddClassSelectionDataToSelector(buttonControl, classData)
    buttonControl.nameFn = GetClassName
    buttonControl.defId = classData.class
end

local function InitializeClassSelectors()
    local classes = g_characterData:GetClassInfo()
    local layoutTable =
    {
        ZO_CharacterCreate_GamepadClassColumn11,
        ZO_CharacterCreate_GamepadClassColumn21,
        ZO_CharacterCreate_GamepadClassColumn31,
        ZO_CharacterCreate_GamepadClassColumn22,
    }

    -- Hide buttons
    for i, button in ipairs(layoutTable) do
        button:SetHidden(true)
    end

    for i, class in ipairs(classes) do
        class.position = i
        classButton = layoutTable[class.position]
        InitializeSelectorButton(classButton, class, g_classRadioGroup)
        AddClassSelectionDataToSelector(classButton, class)
    end
end

local function SetRandomizeAppearanceEnabled(enabled)
    g_randomizeAppearanceEnabled = enabled
end

local function UpdateRaceSelectorsForTemplate(raceData, templateData)
    local enabled = raceData.isSelectable -- Only if the user is able to play the race in the first place do we even consider disabling it...
    if(enabled) then
        local templateRace = templateData.race
        local forcedRace = (templateRace ~= 0)
        if(forcedRace and templateRace ~= raceData.race) then
            enabled = false
        end

        if(not forcedRace) then
            local templateAlliance = templateData.alliance
            if(templateAlliance ~= 0) then
                if((templateAlliance ~= raceData.alliance) and not CanPlayAnyRaceAsAnyAlliance()) then
                    enabled = false
                end
            end
        end

        -- Exceptions to the rule, some races may still be enabled (Imperials is the only case now...)
        if(not forcedRace and raceData.alliance == ALLIANCE_NONE) then
            enabled = true
        end
    end 

    return enabled
end

local function UpdateClassSelectorsForTemplate(classData, templateData)
    return classData.isSelectable and ((templateData.class == 0) or (templateData.class == classData.class))
end

local function UpdateAllianceSelectorsForTemplate(allianceData, templateData)
    return allianceData.isSelectable and ((templateData.alliance == 0) or (templateData.alliance == allianceData.alliance))
end

local function UpdateSelectorsForTemplate(isEnabledCallback, characterDataTable, templateData, radioGroup, optionalValidIndexTable)
    for dataIndex, data in ipairs(characterDataTable) do
        local wasEnabled = data.isRadioEnabled
        local enabled = isEnabledCallback(data, templateData)
        data.isRadioEnabled = enabled

        if ((wasEnabled ~= enabled) and data.selectorButton) then
            SetSelectorButtonEnabled(data.selectorButton, radioGroup, enabled)
        end

        if(optionalValidIndexTable and enabled) then
            optionalValidIndexTable[#optionalValidIndexTable + 1] = dataIndex
        end
    end
end

local function SetTemplate(templateId)
    local templateData = g_characterData:GetTemplate(templateId)
    if(not templateData) then return false end

    if(not templateData.isSelectable or CharacterCreateGetTemplate() == templateId) then return false end

    CharacterCreateSetTemplate(templateId)

    g_bucketManager:SwitchBuckets(CREATE_BUCKET_RACE)

    -- Disable appearance related controls if the appearance is overridden in the template.
    local enabled = not templateData.overrideAppearance
    g_bucketManager:SetEnabled(CREATE_BUCKET_BODY, enabled)
    g_bucketManager:SetEnabled(CREATE_BUCKET_FACE, enabled)

    SetRandomizeAppearanceEnabled(enabled)
    
    local validRaces = {}
    UpdateSelectorsForTemplate(UpdateRaceSelectorsForTemplate, g_characterData:GetRaceInfo(), templateData, g_raceRadioGroup, validRaces)
    UpdateSelectorsForTemplate(UpdateClassSelectorsForTemplate, g_characterData:GetClassInfo(), templateData, g_classRadioGroup)

    local validAlliances = {}
    g_characterData:UpdateAllianceSelectability()
    UpdateSelectorsForTemplate(UpdateAllianceSelectorsForTemplate, g_characterData:GetAllianceInfo(), templateData, g_allianceRadioGroup, validAlliances)

    if (templateData.gender ~= 0) then
        g_genderControlSlider:ToggleLocked()
    end

    -- Pick a race
    if(templateData.race ~= 0) then
        CharacterCreateSetRace(templateData.race)
    else     
        CharacterCreateSetRace(g_characterData:PickRandomRace(validRaces))
    end

    -- Pick an alliance 
    local alliance = templateData.alliance
    if(alliance == 0) then
        -- (never random unless a race without a fixed alliance is picked)
        alliance = g_characterData:GetRaceForRaceDef(CharacterCreateGetRace()).alliance
        if(alliance == 0) then
            alliance = g_characterData:PickRandomAlliance(validAlliances)
        end
    end
    g_manager:SetAlliance(alliance, "preventRaceChange")

    -- Pick a class
    if(templateData.class ~= 0) then
        CharacterCreateSetClass(templateData.class)
    else
        PickRandomSelectableClass()
    end
    
    -- Pick a gender
    if(templateData.gender ~= 0) then
        CharacterCreateSetGender(templateData.gender)
    else
        PickRandomGender()
    end

    -- Make the controls match what you picked...
    UpdateRaceControl()
    UpdateClassControl()
    g_genderControlSlider:Update()
    if(not templateData.overrideAppearance) then
        ZO_CharacterCreate_Gamepad_RandomizeAppearance("initial")
    else
        InitializeAppearanceFromTemplate(templateId)
    end
    return true
end

local function InitializeTemplatesDialog()
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
    local templates = g_characterData:GetTemplateInfo()

    local dialogDescription = 
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC
        },

        setup = function()
            dialog.setupFunc(dialog)
        end,

        title =
        {
            text = GetString(SI_CREATE_CHARACTER_TEMPLATE_SELECT_TITLE),
        },

        mainText = 
        {
            text = GetString(SI_CREATE_CHARACTER_TEMPLATE_SELECT_DESCRIPTION),
        },

        parametricList = {},
       
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function()
                    local selectedData = dialog.entryList:GetTargetData()
                    if(selectedData and selectedData.callback) then
                        selectedData.callback()
                    end
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },

        }
    }

    for index, characterTemplate in ipairs(templates) do
        local data =
        {
            template = "ZO_GamepadMenuEntryTemplate",
            templateData = {
                isHome = true,
                text = characterTemplate.name,
                setup = ZO_SharedGamepadEntry_OnSetup,
                callback = function() 
                    SetTemplate(characterTemplate.template)
                end,
            },
        }

        table.insert(dialogDescription.parametricList, data)
    end
    
    ZO_Dialogs_RegisterCustomDialog("CHARACTER_CREATE_TEMPLATE_SELECT", dialogDescription)
end

-- XML Handlers and global functions

function ZO_CharacterCreate_Gamepad_RandomizeAppearance(randomizeType)
    if (g_randomizeAppearanceEnabled) then
        g_bucketManager:RandomizeAppearance(randomizeType)
    end
end

local function OnCharacterCreated(eventCode, characterId)
    if IsInGamepadPreferredMode() then
        g_randomCharacterGenerated = false -- the next time we enter character create, we want to generate a random character again.
        g_characterCreateOption = CHARACTER_CREATE_DEFAULT_LOCATION
        g_shouldBePromptedForTutorialSkip = true

        local startLocation = ZO_CharacterCreate_Gamepad_GetStartLocation()
        PregameStateManager_PlayCharacter(characterId, startLocation)
    end
end

local function OnCharacterCreateFailed(eventCode, reason)
    if not IsConsoleUI() then
        return
    end

    local errorReason = GetString("SI_CHARACTERCREATEERROR", reason)

    -- Show the fact that the character could not be created.
    ZO_Dialogs_ShowGamepadDialog("CHARACTER_CREATE_FAILED_REASON", nil, {mainTextParams = {errorReason}})

    ZO_CharacterCreate_Gamepad.isCreating = false
end

local function OnCharacterConstructionReady()
    g_characterData:PerformDeferredInitialization()

    InitializeAllianceSelectors()
    InitializeRaceSelectors()
    InitializeClassSelectors()
    InitializeTemplatesDialog()

    -- Nightmare load-ordering dependency...there are probably other ways around this, and they're probably just as bad.
    -- Once game data is loaded, generate a random character for character create just to advance the 
    -- load state.  It won't necessarily do any extra work creating an actual character, since we're going 
    -- to drop back into the current state, but we need to tell the system to load something
    if(GetNumCharacters() == 0) then
        ZO_CharacterCreate_Gamepad_Reset()
        CharacterCreateSetFirstTimePosture()
    end
end

local function OnCharacterCreateRequested()
end

local function ZO_CharacterCreate_Gamepad_StateChanged(oldState, newState)
    local self = ZO_CharacterCreate_Gamepad

    if newState == SCENE_SHOWING then
        self.gear = PREVIEW_NOVICE_GEAR

        self.control:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
        ZO_CharacterCreate_GamepadCharacterViewport.Activate()
        SCENE_MANAGER:AddFragment(CHARACTER_CREATE_GAMEPAD_CONTAINER_FRAGMENT)

        ZO_CharacterCreate_Gamepad_RefreshKeybindStrip()

        ZO_GamepadGenericHeader_Activate(self.header)
        g_bucketManager:Activate()
    elseif newState == SCENE_HIDDEN then
        self.control:RemoveFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
        ZO_CharacterCreate_GamepadCharacterViewport.Deactivate()
        SCENE_MANAGER:RemoveFragment(CHARACTER_CREATE_GAMEPAD_CONTAINER_FRAGMENT)

        if self.currentKeystrip then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeystrip)
            self.currentKeystrip = nil
        end

        self.isCreating = false

        ZO_GamepadGenericHeader_Deactivate(self.header)
        g_bucketManager:Deactivate()
    end
end

function ZO_CharacterCreate_GamepadContainer_OnUpdate()
    local self = ZO_CharacterCreate_Gamepad
    if (self.focusControl and self.focusControl.m_disableFocusMovementController) then
        -- Just do focus update
        if self.focusControl and self.focusControl.FocusUpdate then
            self.focusControl:FocusUpdate(moveFocus)
        end
        return
    end

    -- Handle Generic Option changes
    local changeOption = self.movementControllerChangeGenericOption:CheckMovement()

    if changeOption == MOVEMENT_CONTROLLER_MOVE_NEXT then
        if self.focusControl and self.focusControl.MoveNext then
            self.focusControl:MoveNext()
        end
    elseif changeOption == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        if self.focusControl and self.focusControl.MovePrevious then
            self.focusControl:MovePrevious()
        end
    end

    local moveFocus = self.movementControllerMoveFocus:CheckMovement()

    local updatedFocusControl = false
    if self.focusControl and self.focusControl.FocusUpdate then
        updatedFocusControl = self.focusControl:FocusUpdate(moveFocus)
    end

    if not updatedFocusControl then
      -- Allow the bucketManager to consume the input
        if moveFocus == MOVEMENT_CONTROLLER_MOVE_NEXT then
            g_bucketManager:MoveNext()
        elseif moveFocus == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            g_bucketManager:MovePrevious()
        end
    else
        g_bucketManager:RefreshBucketCenterOffset(self.focusControl)
    end
end

function ZO_CharacterCreate_Gamepad_ShowFinishScreen()
    local self = ZO_CharacterCreate_Gamepad
    self.isCreating = false
    self.focusControl:EnableFocus(false)

    ZO_Dialogs_ShowGamepadDialog(CHARACTER_CREATE_GAMEPAD_DIALOG)
end


local function ReturnToCharacterSelect()
    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
    PregameStateManager_SetState("CharacterSelect")
    Pregame_ShowScene("gamepadCharacterSelect")
end

local function GenerateKeybindingDescriptor(self)

    if self.isCreating then
        return nil  -- No keybind while creating
    end

    local keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = function()
                return (self.focusControl and self.focusControl.primaryButtonName) or GetString(SI_GAMEPAD_SELECT_OPTION)
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            ethereal = not (self.focusControl and self.focusControl.showKeybind),

            callback = function()
                ZO_CharacterCreate_Gamepad_OnPrimaryButtonPressed()
            end,
        },
        {
            name = GetString(SI_CREATE_CHARACTER_GAMEPAD_FINISH),
            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function()
                PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                ZO_CharacterCreate_Gamepad_ShowFinishScreen()
            end,
        },
        {
            name = GetString(SI_CREATE_CHARACTER_GAMEPAD_RANDOMIZE),
            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                ZO_CharacterCreate_Gamepad_RandomizeAppearance()
            end,
            sound = SOUNDS.CC_RANDOMIZE,
        },
    }


    table.insert(keybindStripDescriptor,         
        {
            name = "Use Template",
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",

            callback = function()
                PlaySound(SOUNDS.CC_GAMEPAD_CHARACTER_CLICK)
                ZO_Dialogs_ShowGamepadDialog("CHARACTER_CREATE_TEMPLATE_SELECT")
            end,

            visible = function()
                    local shouldShow = false
                    if(GetTemplateStatus()) then
                        local templates = g_characterData:GetTemplateInfo()
                        shouldShow = templates and #templates > 0
                    end
                    return shouldShow
            end,
        })


    if (self.focusControl and self.focusControl.CanLock) then
        if (self.focusControl.CanLock()) then
            if (self.focusControl:IsLocked()) then
                keybindStripDescriptor[#keybindStripDescriptor + 1] =
                {
                    name = GetString(SI_CREATE_CHARACTER_GAMEPAD_UNLOCK_VALUE),
                    keybind = "UI_SHORTCUT_RIGHT_STICK",

                    callback = function()
                        self.focusControl:ToggleLocked()
                        PlaySound(SOUNDS.CC_UNLOCK_VALUE)
                        ZO_CharacterCreate_Gamepad_RefreshKeybindStrip()
                    end,
                }
            else
                keybindStripDescriptor[#keybindStripDescriptor + 1] =
                {
                    name = GetString(SI_CREATE_CHARACTER_GAMEPAD_LOCK_VALUE),
                    keybind = "UI_SHORTCUT_RIGHT_STICK",

                    callback = function()
                        self.focusControl:ToggleLocked()
                        PlaySound(SOUNDS.CC_LOCK_VALUE)
                        ZO_CharacterCreate_Gamepad_RefreshKeybindStrip()
                    end,
                }
            end
        end
    end

    local next_gear = (self.gear % #PREVIEW_GEAR_INFO) + 1
    local name = PREVIEW_GEAR_INFO[next_gear].name

    keybindStripDescriptor[#keybindStripDescriptor + 1] =
    {
        name = name,
        keybind = "UI_SHORTCUT_RIGHT_TRIGGER",

        callback = function()
            self.gear = (self.gear % #PREVIEW_GEAR_INFO) + 1

            PREVIEW_GEAR_INFO[self.gear].fn()
            PlaySound(SOUNDS.CC_PREVIEW_GEAR)

            ZO_CharacterCreate_Gamepad_RefreshKeybindStrip()
        end,
    }

    local state = PregameStateManager_GetPreviousState()
    if (state == "CharacterSelect" or state == "CharacterSelect_FromCinematic") and GetNumCharacters() > 0 then
        keybindStripDescriptor[#keybindStripDescriptor + 1] = KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(ReturnToCharacterSelect)
    elseif GetNumCharacters() == 0 then
        -- mimic the behavior from the character select screen
        keybindStripDescriptor[#keybindStripDescriptor + 1] = KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() PregameStateManager_SetState("Disconnect") end)
    end

    return keybindStripDescriptor
end

-- Can't simply return (currentStrip ~= newStrip) because ZoKeybindStrip stores additional 
-- variables on the descriptor (such as currentStrip.handledDown). This causes an altered
-- version of the keybind strip to differ from an unaltered version of the same strip.
local function ShouldRefreshKeybindStrip(currentStrip, newStrip)
    local shouldRefresh = (not currentStrip) or (not newStrip)

    if  (not shouldRefresh) then
        shouldRefresh = #currentStrip ~= #newStrip
        if (not shouldRefresh) then
            for i=1, #currentStrip do
                local currentButton = currentStrip[i]
                local newButton = newStrip[i]

                if (not currentButton or not newButton) then
                    shouldRefresh = true
                    break
                end

                if (currentButton.name ~= newButton.name) then
                    shouldRefresh = true
                    break
                end
            end
        end
    end
    return shouldRefresh
end

function ZO_CharacterCreate_Gamepad_RefreshKeybindStrip()
    local self = ZO_CharacterCreate_Gamepad

    local keybindStrip = GenerateKeybindingDescriptor(self)
    local removed = true

    if ShouldRefreshKeybindStrip(self.currentKeystrip, keybindStrip) then
        if self.currentKeystrip then
            removed = KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeystrip)
        end

        -- won't try to replace keybind strip if there's a current one and it wasn't removed
        -- this occurs when current descriptor is pushed to stack, so can't be found
        if (removed) then
            self.currentKeystrip = keybindStrip

            if self.currentKeystrip then
                KEYBIND_STRIP:RemoveDefaultExit()
                KEYBIND_STRIP:AddKeybindButtonGroup(self.currentKeystrip)
            end
        end
    end
end

function ZO_CharacterCreate_Gamepad_Initialize(self)
    ZO_CharacterCreate_Shared_Initialize()

    CHARACTER_CREATE_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(self)
    GAMEPAD_CHARACTER_CREATE_SCENE = ZO_Scene:New("gamepadCharacterCreate", SCENE_MANAGER)
    GAMEPAD_CHARACTER_CREATE_SCENE:AddFragment(CHARACTER_CREATE_GAMEPAD_FRAGMENT)

    local ALWAYS_ANIMATE = true
    CHARACTER_CREATE_GAMEPAD_FINISH_ERROR_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CharacterCreate_GamepadFinishError, ALWAYS_ANIMATE)
    CHARACTER_CREATE_GAMEPAD_CONTAINER_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CharacterCreate_GamepadContainer, ALWAYS_ANIMATE)
    CHARACTER_CREATE_GAMEPAD_LOREINFO_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CharacterCreate_GamepadContainerLoreInfo, ALWAYS_ANIMATE)

    local function CharacterNameValidationCallback(isValid)
        if isValid then
            if g_shouldBePromptedForTutorialSkip and CanSkipTutorialArea() then
                g_shouldBePromptedForTutorialSkip = false
                local genderDecoratedCharacterName = GetGrammarDecoratedName(self.characterName, CharacterCreateGetGender())
                ZO_Dialogs_ShowGamepadDialog(SKIP_TUTORIAL_GAMEPAD_DIALOG, { characterName = self.characterName }, {mainTextParams = { genderDecoratedCharacterName }})
            else
                local startLocation = ZO_CharacterCreate_Gamepad_GetStartLocation()
                ZO_CharacterCreate_Gamepad_DoCreate(startLocation, g_characterCreateOption)
            end
        else
            local errorReason = GetString("SI_CHARACTERCREATEERROR", CHARACTER_CREATE_ERROR_INVALIDNAME)
            ZO_Dialogs_ShowGamepadDialog("CHARACTER_CREATE_FAILED_REASON", nil, {mainTextParams = {errorReason}})
        end
    end

    ZO_CharacterNaming_Gamepad_CreateDialog(ZO_CharacterCreate_Gamepad,
        {
            errorControl = ZO_CharacterCreate_GamepadFinishError,
            errorFragment = CHARACTER_CREATE_GAMEPAD_FINISH_ERROR_FRAGMENT,
            dialogName = CHARACTER_CREATE_GAMEPAD_DIALOG,
            dialogTitle = SI_CREATE_CHARACTER_GAMEPAD_FINISH_TITLE,
            onBack = function() 
                if self.focusControl then
                    self.focusControl:EnableFocus(true)
                end
            end,
            onFinish = function(dialog)
                local characterName = dialog.selectedName
                self.characterName = characterName

                if characterName and #characterName > 0 then
                    if IsConsoleUI() then
                        PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestNameValidation(characterName, CharacterNameValidationCallback)
                    else
                        CharacterNameValidationCallback(IsValidName(characterName))
                    end
                end
            end,
        })

    ZO_CharacterCreate_Gamepad_SkipTutorialDialog()

    self.control = GAMEPAD_CHARACTER_CREATE_SCENE

    self.headerData =
    {
        tabBarEntries = {},
    }

    self.header = self:GetNamedChild("Container"):GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    self.gear = PREVIEW_NOVICE_GEAR

    self.SetFocus = ZO_CharacterCreate_Gamepad_SetFocus
    self.GetNextFocus = ZO_CharacterCreate_Gamepad_GetNextFocus
    self.GetPreviousFocus = ZO_CharacterCreate_Gamepad_GetPreviousFocus

    GAMEPAD_CHARACTER_CREATE_SCENE:RegisterCallback("StateChange", ZO_CharacterCreate_Gamepad_StateChanged)

    g_allianceRadioGroup = ZO_RadioButtonGroup:New()
    g_raceRadioGroup = ZO_RadioButtonGroup:New()
    g_classRadioGroup = ZO_RadioButtonGroup:New()

    g_characterData = ZO_CharacterCreateData:New()
    g_manager = CharacterCreateManager:New(g_characterData)

    local containerBuckets = ZO_CharacterCreate_GamepadContainerInnerBuckets

    g_bucketManager = CharacterCreateBucketManager:New(containerBuckets)

    g_sliderManager = CharacterCreateSliderManager:New(containerBuckets)

    -- MovementController for changing the option on the currently selected Focus
    self.movementControllerChangeGenericOption = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)

    -- MovementController for changing focus between controls
    self.movementControllerMoveFocus = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)

    self.focusControl = nil

    EVENT_MANAGER:RegisterForEvent("ZO_CharacterCreate_Gamepad", EVENT_LOGOUT_SUCCESSFUL, OnLogoutSuccessful)
    EVENT_MANAGER:RegisterForEvent("ZO_CharacterCreate_Gamepad", EVENT_CHARACTER_CREATED, OnCharacterCreated)
    EVENT_MANAGER:RegisterForEvent("ZO_CharacterCreate_Gamepad", EVENT_CHARACTER_CREATE_FAILED, OnCharacterCreateFailed)

    CALLBACK_MANAGER:RegisterCallback("OnCharacterConstructionReady", OnCharacterConstructionReady)
    CALLBACK_MANAGER:RegisterCallback("CharacterCreateRequested", OnCharacterCreateRequested)

    self.fadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CharacterCreateMainControlsFade", ZO_CharacterCreate_Gamepad)
end

function ZO_CharacterCreate_Gamepad_SetFocus(self, control)
    if control and self.focusControl and self.focusControl ~= control then
        if control.SetHighlightIndexByColumn and self.focusControl.GetHighlightColumn then
            -- Highlight the current selection
            control:SetHighlightIndexByColumn(self.focusControl:GetHighlightColumn(), control:GetFocusIndex() > self.focusControl:GetFocusIndex())
        end
    end

    if (self.focusControl ~= nil and self.focusControl.EnableFocus) then
        self.focusControl:EnableFocus(false)
        self.focusControl = nil
    end

    self.focusControl = control
    if (self.focusControl ~= nil and self.focusControl.EnableFocus) then
        self.focusControl:EnableFocus(true)
    end

    g_bucketManager:RefreshBucketCenterOffset(self.focusControl)

    if (not self:IsHidden()) then
        ZO_CharacterCreate_Gamepad_RefreshKeybindStrip()
    end
end

function ZO_CharacterCreate_Gamepad_OnPrimaryButtonPressed()
    local self = ZO_CharacterCreate_Gamepad
    if (self.focusControl ~= nil and self.focusControl.OnPrimaryButtonPressed) then
        self.focusControl:OnPrimaryButtonPressed()
    end
end

function ZO_CharacterCreate_Gamepad_GetNextFocus(self, control)
    if (control == nil) then
        return nil
    end

    local bucket = control.info.bucketIndex
    local index = control.info.index

    while(index < #(CREATE_BUCKET_WINDOW_DATA[bucket].controls)) do
        index = index + 1

        local newControl = self.controls[bucket][index]
        if newControl then
            return newControl
        end
    end

    return control
end

function ZO_CharacterCreate_Gamepad_GetPreviousFocus(self, control)
    if (control == nil) then
        return nil
    end

    local bucket = control.info.bucketIndex
    local index = control.info.index

    while(index > 1) do
        index = index - 1

        local newControl = self.controls[bucket][index]
        if newControl then
            return newControl
        end
    end

    return control
end

function ZO_CharacterCreate_Gamepad_Reset()
    if(not IsPregameCharacterConstructionReady()) then return end -- Sanity check
    SetSuppressCharacterChanges(true) -- this will be disabled later, right before controls are initialized
    SetCharacterManagerMode(CHARACTER_MODE_CREATION)

    local controlsInitialized = ZO_CharacterCreate_Gamepad_GenerateRandomCharacter()
    if(not controlsInitialized) then
        g_manager:InitializeControls()
    end

    g_bucketManager:SwitchBuckets(INITIAL_BUCKET)
    g_bucketManager:SwitchBucketsInternal(INITIAL_BUCKET)
    g_bucketManager:UpdateControlsFromData()

    g_characterStartLocation = nil
    g_shouldBePromptedForTutorialSkip = true
    g_characterCreateOption = CHARACTER_CREATE_DEFAULT_LOCATION

    SetCharacterCameraZoomAmount(-1) -- zoom all the way out when a reset happens
end

function ZO_CharacterCreate_Gamepad_DoCreate(startLocation, createOption)
    if(not ZO_CharacterCreate_Gamepad.isCreating) then
        ZO_CharacterCreate_Gamepad.isCreating = true
        local self = ZO_CharacterCreate_Gamepad
        local requestSkipTutorial = createOption == CHARACTER_CREATE_SKIP_TUTORIAL
        g_characterCreateOption = createOption
        ZO_Dialogs_ShowGamepadDialog("CHARACTER_CREATE_CREATING")
        CreateCharacter(self.characterName, requestSkipTutorial)
        g_characterStartLocation = startLocation or CHARACTER_OPTION_EXISTING_AREA
        CALLBACK_MANAGER:FireCallbacks("CharacterCreateRequested")
    end
end

function ZO_CharacterCreate_Gamepad_CancelSkipDialogue()
    ZO_CharacterCreate_Gamepad.isCreating = false
    g_shouldBePromptedForTutorialSkip = true -- should be prompted for tutorial again
end

function ZO_CharacterCreate_Gamepad_IsCreating()
    return ZO_CharacterCreate_Gamepad.isCreating
end

function ZO_CharacterCreate_Gamepad_GetStartLocation()
    return g_characterStartLocation
end

function ZO_CharacterCreate_Gamepad_OnSelectorPressed(button)
    local selectorHandlers =
    {
        ["race"] =  function(button)
                        g_manager:SetRace(button.defId)
                        UpdateRaceControl()
                    end,

        ["class"] = function(button)
                        CharacterCreateSetClass(button.defId)
                        UpdateClassControl()
                    end,

        ["alliance"] =  function(button)
                            g_manager:SetAlliance(button.defId, "preventRaceChange")
                            local oldPosition = ZO_CharacterCreate_GamepadRace.m_sliderObject:GetSelectedIndex()

                            InitializeRaceSelectors()

                            local newButton = ZO_CharacterCreate_GamepadRace.m_sliderObject:GetButton(oldPosition)
                            if newButton then
                                g_manager:SetRace(newButton.defId)
                            else
                                SetValidRace()
                            end

                            UpdateRaceControl()
                        end,
    }

    local fn = selectorHandlers[button.selectorType]
    if(fn) then
        OnCharacterCreateOptionChanged()
        fn(button)
        PlaySound(SOUNDS.CC_GAMEPAD_CHARACTER_CLICK)
    end
end

function ZO_CharacterCreate_Gamepad_TogglePadlock(button)
    button:GetParent().m_sliderObject:ToggleLocked()
end

function ZO_CharacterCreate_Gamepad_SetSlider(slider, value)
    OnCharacterCreateOptionChanged()
    slider:GetParent().m_sliderObject:SetValue(value)
end

function ZO_CharacterCreate_Gamepad_ChangeSlider(slider, changeAmount)
    OnCharacterCreateOptionChanged()
    slider:GetParent().m_sliderObject:ChangeValue(changeAmount)
end

function ZO_CharacterCreate_Gamepad_CreateSlider(sliderControl, sliderType)
    if(sliderType == "slider") then
        CharacterCreateSlider:New(sliderControl)
    elseif(sliderType == "icon") then
        CharacterCreateAppearanceSlider:New(sliderControl)
    elseif(sliderType == "named") then
        CharacterCreateVoiceSlider:New(sliderControl)
    elseif(sliderType == "gender") then
        CharacterCreateGenderSlider:New(sliderControl)
    end
end

function ZO_CharacterCreate_Gamepad_CreateTriangle(control, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)
    local triangle = CharacterCreateTriangle:New(control, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)
    triangle:SetOnValueChangedCallback(OnCharacterCreateOptionChanged)
    control.selectedCenterOffset = -140
end

function ZO_CharacterCreate_Gamepad_CreateAllianceSelector(control)
    CharacterCreateAllianceSelector:New(control)
end

function ZO_CharacterCreate_Gamepad_CreateRaceSelector(control)
    CharacterCreateRaceSelector:New(control)
end

function ZO_CharacterCreate_Gamepad_CreateClassSelector(control)
    CharacterCreateClassSelector:New(control)
end

function ZO_CharacterCreate_Gamepad_FadeInMainControls()
    ZO_CharacterCreate_Gamepad.fadeTimeline:PlayFromStart()
    g_playingTransitionAnimations = true
end

do
    local paperDollInputObject =
    {
        UpdateDirectionalInput = function(self)
            local mx, my = DIRECTIONAL_INPUT:GetXY(ZO_DI_RIGHT_STICK)
            if zo_abs(mx) > zo_abs(my) then
                local scalex = -6.0
                if mx ~= 0 then
                    CharacterCreateStartMouseSpin(mx * scalex)
                else
                    CharacterCreateStopMouseSpin()
                end
                StopCharacterCameraZoom()
            else
                if my > 0 then
                    MoveCharacterCameraZoomAmount(1)
                elseif my < 0 then
                    MoveCharacterCameraZoomAmount(-1)
                else
                    StopCharacterCameraZoom()
                end
                CharacterCreateStopMouseSpin()
            end
        end,
    }    

    function ZO_PaperdollManipulation_Gamepad_Initialize(self)
        self.Activate = function()
            DIRECTIONAL_INPUT:Activate(paperDollInputObject, self)
        end

        self.Deactivate = function()
            DIRECTIONAL_INPUT:Deactivate(paperDollInputObject)
        end

        self.StopAllInput = function()
            CharacterCreateStopMouseSpin()
            StopCharacterCameraZoom()
        end
    end
end

function ZO_CharacterNaming_Gamepad_CreateDialog(self, params)
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    self.errorLabel = params.errorControl:GetNamedChild("Errors")

    local function UpdateSelectedName(name, suppressErrors)
        if(dialog.selectedName ~= name) then
            dialog.selectedName = name
            dialog.nameViolations = { IsValidCharacterName(dialog.selectedName) }
            dialog.noViolations = #dialog.nameViolations == 0

            dialog.selectedName = CorrectCharacterNameCase(dialog.selectedName)
            
            if not dialog.noViolations then
                if suppressErrors then
                    SCENE_MANAGER:RemoveFragment(params.errorFragment)
                else
                    local HIDE_UNVIOLATED_RULES = true
                    local violationString = ZO_ValidNameInstructions_GetViolationString(dialog.selectedName, dialog.nameViolations, HIDE_UNVIOLATED_RULES, SI_CREATE_CHARACTER_GAMEPAD_INVALID_NAME_DIALOG_INSTRUCTION_FORMAT)

                    self.errorLabel:SetText(violationString)
                    SCENE_MANAGER:AddFragment(params.errorFragment)
                end
            else
                SCENE_MANAGER:RemoveFragment(params.errorFragment)
            end

        end

        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
    end


    local function ReleaseDialog()
        SCENE_MANAGER:RemoveFragment(params.errorFragment)
        ZO_Dialogs_ReleaseDialogOnButtonPress(params.dialogName)
    end 

    local function SetupDialog(dialog, data)
        dialog.selectedName = nil
        if data ~= nil and data.characterName ~= nil then
            UpdateSelectedName(data.characterName)
        else
            local SUPPRESS_ERRORS = true
            UpdateSelectedName("", SUPPRESS_ERRORS)
        end
        dialog.setupFunc(dialog)
    end

    local doneEntry = ZO_GamepadEntryData:New(GetString(SI_CREATE_CHARACTER_GAMEPAD_FINISH_DONE), "EsoUI/Art/Miscellaneous/Gamepad/gp_submit.dds")
    doneEntry.setup = function(control, data, selected, reselectingDuringRebuild, _, active)
        self.doneControl = control

        data.disabled = not dialog.noViolations or self.isCreating
        local enabled = not data.disabled
        data:SetEnabled(enabled)

        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end


    ZO_Dialogs_RegisterCustomDialog(params.dialogName,
    {
        mustChoose = true,
        canQueue = true,
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = SetupDialog,
        shownCallback = function()
            -- Open Keyboard immediately on entering finishing character dialog
            if self.editBoxControl then
                self.editBoxControl:TakeFocus()
            end
        end,
        blockDialogReleaseOnPress = true, -- We'll handle Dialog Releases ourselves since we don't want DIALOG_PRIMARY to release the dialog on press.

        title =
        {
            text = params.dialogTitle,
        },
        mainText = 
        {
            text = "",
        },
        parametricList =
        {
            -- name edit box
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",

                templateData = {
                    nameField = true,
                    textChangedCallback = function(control) 
                        local newName = control:GetText()
                        
                        UpdateSelectedName(newName)
                        if(control:GetText() ~= dialog.selectedName) then
                            control:SetText(dialog.selectedName)
                        end
                    end,   

                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.editBoxControl.textChangedCallback = data.textChangedCallback
                        
                        ZO_EditDefaultText_Initialize(control.editBoxControl, GetString(SI_CREATE_CHARACTER_GAMEPAD_ENTER_NAME))

                        local validInput = dialog.selectedName and dialog.selectedName ~= ""
                        if validInput then
                            control.editBoxControl:SetText(dialog.selectedName)
                        end
                        
                        SetupEditControlForNameValidation(control.editBoxControl)

                        control.editBoxControl:SetMaxInputChars(CHARNAME_MAX_LENGTH)
                        control.highlight:SetHidden(not selected)
                        self.editBoxSelected = selected
                        self.editBoxControl = control.editBoxControl
                    end,
                },
            },
            -- Done menu item
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData = doneEntry,
            },
        },
       
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_CREATE_CHARACTER_GAMEPAD_FINISH_SELECT),

                callback = function()
                    if self.editBoxSelected then
                        local targetControl = dialog.entryList:GetTargetControl()
                        if targetControl and targetControl.editBoxControl then
                            targetControl.editBoxControl:TakeFocus()
                        end
                    else
                        if (not dialog.noViolations) then
                            return
                        end

                        ReleaseDialog()

                        if params.onFinish then
                            params.onFinish(dialog)
                        end
                    end
                end,
                enabled = function()
                    return self.editBoxSelected or dialog.noViolations
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_CREATE_CHARACTER_GAMEPAD_FINISH_BACK),

                callback = function()
                    ReleaseDialog()

                    if params.onBack then
                        params.onBack(dialog)
                    end

                    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                end,
            },
        },
    })
end


function ZO_CharacterCreate_Gamepad_SkipTutorialDialog()

    local function ReleaseDialog(characterName, shouldGoBack)
        ZO_Dialogs_ReleaseDialogOnButtonPress(SKIP_TUTORIAL_GAMEPAD_DIALOG, true)

        if shouldGoBack then
            ZO_CharacterCreate_Gamepad_CancelSkipDialogue()
            ZO_Dialogs_ShowGamepadDialog(CHARACTER_CREATE_GAMEPAD_DIALOG, { characterName = characterName })
        end
    end 

    ZO_Dialogs_RegisterCustomDialog(SKIP_TUTORIAL_GAMEPAD_DIALOG,
    {
        mustChoose = true,
        canQueue = true,
        blockDialogReleaseOnPress = true, -- We'll handle Dialog Releases ourselves since we don't want DIALOG_PRIMARY to release the dialog on press.
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_PROMPT_TITLE_SKIP_TUTORIAL,
        },
        mainText = 
        {
            text = SI_PROMPT_BODY_SKIP_TUTORIAL,
        },
        noChoiceCallback = function(dialog)
                        local SHOULD_RETURN_TO_NAME_SCREEN = false
                        ReleaseDialog(dialog.data.characterName, false)
                        ZO_CharacterCreate_Gamepad_DoCreate(dialog.data.startLocation, CHARACTER_CREATE_DEFAULT_LOCATION)
                    end,
        buttons =
        {
            {
                text = SI_PROMPT_PLAY_TUTORIAL_BUTTON,
                keybind = "DIALOG_PRIMARY",
                callback =  function(dialog)
                                local SHOULD_RETURN_TO_NAME_SCREEN = false
                                ReleaseDialog(dialog.data.characterName, SHOULD_RETURN_TO_NAME_SCREEN)
                                ZO_CharacterCreate_Gamepad_DoCreate(dialog.data.startLocation, CHARACTER_CREATE_DEFAULT_LOCATION)
                            end,
            },

            {
                text = SI_PROMPT_SKIP_TUTORIAL_BUTTON,
                keybind = "DIALOG_SECONDARY",
                callback =  function(dialog)
                                local SHOULD_RETURN_TO_NAME_SCREEN = false
                                ReleaseDialog(dialog.data.characterName, SHOULD_RETURN_TO_NAME_SCREEN)
                                ZO_CharacterCreate_Gamepad_DoCreate(dialog.data.startLocation, CHARACTER_CREATE_SKIP_TUTORIAL)
                            end,
            },

            {
                text = SI_PROMPT_BACK_TUTORIAL_BUTTON,
                keybind = "DIALOG_NEGATIVE",
                callback =  function(dialog)
                                local SHOULD_RETURN_TO_NAME_SCREEN = true
                                ReleaseDialog(dialog.data.characterName, SHOULD_RETURN_TO_NAME_SCREEN)
                            end,
            },
        }
    })
end