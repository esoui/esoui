GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER = 1
GAMEPAD_BUCKET_CONTROL_TYPE_APPEARANCE = 2
GAMEPAD_BUCKET_CONTROL_TYPE_CUSTOM = 3

GAMEPAD_BUCKET_CUSTOM_CONTROL_GENDER = 1
GAMEPAD_BUCKET_CUSTOM_CONTROL_ALLIANCE = 2
GAMEPAD_BUCKET_CUSTOM_CONTROL_RACE = 3
GAMEPAD_BUCKET_CUSTOM_CONTROL_CLASS = 4
GAMEPAD_BUCKET_CUSTOM_CONTROL_PHYSIQUE = 5
GAMEPAD_BUCKET_CUSTOM_CONTROL_FACE = 6

local DEFAULT_OFFSET = -60

-- Table for the Bucket data. Each Bucket is a tab in the UI.
ZO_CHARACTER_CREATE_BUCKET_WINDOW_DATA_GAMEPAD =
{
    [CREATE_BUCKET_RACE] = 
    { 
        windowName = "RaceBucket_Gamepad",
        title = GetString(SI_CREATE_CHARACTER_GAMEPAD_BUCKET_TITLE_CHARACTER),
        onExpandFn =    function()
                            if not ZO_CHARACTERCREATE_MANAGER:GetPlayingTransitionAnimations() then
                                CharacterCreateSetIdlePosture()
                            end
                            SetCharacterCameraZoomAmount(-1)
                        end,

        -- Controls for the tab
        controls =
        {
            -- <Type of controls (GAMEPAD_BUCKET_CONTROL_TYPE_CUSTOM, GAMEPAD_BUCKET_CONTROL_TYPE_APPEARANCE or GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER)>, <enum of control>
            { GAMEPAD_BUCKET_CONTROL_TYPE_CUSTOM, GAMEPAD_BUCKET_CUSTOM_CONTROL_GENDER },
            { GAMEPAD_BUCKET_CONTROL_TYPE_CUSTOM, GAMEPAD_BUCKET_CUSTOM_CONTROL_ALLIANCE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_CUSTOM, GAMEPAD_BUCKET_CUSTOM_CONTROL_RACE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_CUSTOM, GAMEPAD_BUCKET_CUSTOM_CONTROL_CLASS },
        }
    },

    [CREATE_BUCKET_BODY] = 
    { 
        windowName = "BodyTypeBucket_Gamepad", 
        title = GetString(SI_CREATE_CHARACTER_GAMEPAD_BUCKET_TITLE_BODY_TYPE), 
        onExpandFn = function() SetCharacterCameraZoomAmount(-1) end,

        controls =
        {
            { GAMEPAD_BUCKET_CONTROL_TYPE_CUSTOM, GAMEPAD_BUCKET_CUSTOM_CONTROL_PHYSIQUE },
        }
    },

    [CREATE_BUCKET_BODY_SHAPE] =
    { 
        windowName = "BodyShapeBucket_Gamepad",
        title = GetString(SI_CREATE_CHARACTER_BUCKET_TITLE_BODY), 
        onExpandFn = function() SetCharacterCameraZoomAmount(-1) end,

        controls =
        {
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_CHARACTER_HEIGHT },
            { GAMEPAD_BUCKET_CONTROL_TYPE_APPEARANCE, APPEARANCE_NAME_SKIN_TINT },
            { GAMEPAD_BUCKET_CONTROL_TYPE_APPEARANCE, APPEARANCE_NAME_BODY_MARKING },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_TORSO_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_CHEST_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_GUT_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_WAIST_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_ARM_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_HAND_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_HIP_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_BUTTOCKS_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_LEG_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_FOOT_SIZE },
        },
    },

    [CREATE_BUCKET_HEAD_TYPE] = 
    { 
        windowName = "HeadTypeBucket_Gamepad", 
        title = GetString(SI_CREATE_CHARACTER_GAMEPAD_BUCKET_TITLE_HEAD_TYPE),
        onExpandFn = function() SetCharacterCameraZoomAmount(1) end,
        controls =
        {
            { GAMEPAD_BUCKET_CONTROL_TYPE_CUSTOM, GAMEPAD_BUCKET_CUSTOM_CONTROL_FACE },
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
            { GAMEPAD_BUCKET_CONTROL_TYPE_APPEARANCE, APPEARANCE_NAME_AGE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_APPEARANCE, APPEARANCE_NAME_ACCESSORY },  -- "adornment"
            { GAMEPAD_BUCKET_CONTROL_TYPE_APPEARANCE, APPEARANCE_NAME_HAIR_STYLE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_APPEARANCE, APPEARANCE_NAME_HAIR_TINT },
            { GAMEPAD_BUCKET_CONTROL_TYPE_APPEARANCE, APPEARANCE_NAME_HEAD_MARKING },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_FOREHEAD_SLOPE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_CHEEK_BONE_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_CHEEK_BONE_HEIGHT },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_JAW_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_CHIN_HEIGHT },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_CHIN_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_NECK_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_EAR_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_EAR_ROTATION },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_EAR_HEIGHT },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_EAR_TIP_FLARE },
        },
    },

    [CREATE_BUCKET_FACE] = 
    {
        windowName = "FaceBucket_Gamepad", 
        title = GetString(SI_CREATE_CHARACTER_BUCKET_TITLE_FACE),
        onExpandFn = function() SetCharacterCameraZoomAmount(1) end,

        controls =
        {
            { GAMEPAD_BUCKET_CONTROL_TYPE_APPEARANCE, APPEARANCE_NAME_VOICE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_APPEARANCE, APPEARANCE_NAME_EYE_TINT },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_EYE_SIZE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_EYE_ANGLE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_EYE_SEPARATION },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_EYE_HEIGHT },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_EYE_SQUINT },
            { GAMEPAD_BUCKET_CONTROL_TYPE_APPEARANCE, APPEARANCE_NAME_EYEBROW },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_EYEBROW_HEIGHT },
            --{ GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_EYEBROW_ANGLE},  -- TODO Missing from Design?
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_EYEBROW_SKEW },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_EYEBROW_DEPTH },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_NOSE_SHAPE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_NOSE_HEIGHT },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_NOSE_WIDTH },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_NOSE_LENGTH },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_MOUTH_HEIGHT },
            --{ GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_MOUTH_WIDTH},  -- TODO Missing from Design?
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_MOUTH_CURVE },
            { GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, SLIDER_NAME_LIP_FULLNESS },
        },
    },
}

--[[ Character Creation Bucket Instances ]]--

ZO_CharacterCreateBucket_Gamepad = ZO_CharacterCreateBucket_Base:Subclass()

function ZO_CharacterCreateBucket_Gamepad:New(...)
    return ZO_CharacterCreateBucket_Base.New(self, ...)
end

function ZO_CharacterCreateBucket_Gamepad:Initialize(...)
    ZO_CharacterCreateBucket_Base.Initialize(self, ...)
    
    local windowData = ZO_CHARACTER_CREATE_BUCKET_WINDOW_DATA_GAMEPAD[self.category]

    local container = CreateControlFromVirtual("$(parent)" .. windowData.windowName, self.parent, "ZO_CategoryBucket_Gamepad")

    container.bucket = self

    self.windowData = windowData
    self.container = container

    self.scrollChild = ZO_GamepadVerticalParametricScrollList:New(GetControl(container, "List"))
    self.scrollChild:SetFixedCenterOffset(DEFAULT_OFFSET)

    -- Handle all the input through this screen
    -- (so the focused control gets first access then we pass the input to the scrollchild)
    self.scrollChild:SetDirectionalInputEnabled(false) 
end

function ZO_CharacterCreateBucket_Gamepad:SetTabIndex(index)
    self.tabIndex = index
end

function ZO_CharacterCreateBucket_Gamepad:GetTabIndex()
    return self.tabIndex
end

function ZO_CharacterCreateBucket_Gamepad:SetEnabled(enabled)
    self.manager:EnableTabBarCategory(self, enabled)
end

function ZO_CharacterCreateBucket_Gamepad:Finalize()
    self:GetScrollChild():Commit()
end

function ZO_CharacterCreateBucket_Gamepad:AddControl(control, updateFn, randomizeFn)
    control.bucket = self
    control:ClearAnchors()

    local list = self:GetScrollChild()
    list:AddEntry("ZO_CharacterCreateEntry_Gamepad", { control = control }, control.prePadding, control.postPadding, control.preSelectedOffsetAdditionalPadding, control.postSelectedOffsetAdditionalPadding, control.selectedCenterOffset)
    control:SetHidden(true)

    self.controlData[control] = { updateFn = updateFn, randomizeFn = randomizeFn }
end

function ZO_CharacterCreateBucket_Gamepad:RemoveControl(control)
    control.bucket = nil
    self.controlData[control] = nil
end

do
    -- Bucket List Entry Setup
    -- We use an empty template and then add/remove controls to the template.

    local function SetupListEntry(control, data, selected, selectedDuringRebuild, enable, activated)
        if control.occupiedBy then
            if control.occupiedBy:GetParent() == control then
                -- Detach old control
                control.occupiedBy:ClearAnchors()
                control.occupiedBy:SetParent(ZO_CharacterCreate_Gamepad)
                control.occupiedBy:SetAnchor(TOPLEFT, ZO_CharacterCreate_Gamepad, TOPLEFT, 0, 0)
                control.occupiedBy:SetHidden(true)
                control.occupiedBy = nil
            end
        end

        control:SetDimensions(data.control:GetDimensions())

        data.control:SetParent(control)
        data.control:SetHidden(false)
        control.occupiedBy = data.control

        data.control:ClearAnchors()
        data.control:SetAnchorFill(control)

        if selected and activated then
            GAMEPAD_CHARACTER_CREATE_MANAGER:SetFocus(data.control.sliderObject)
        end
    end

    function ZO_CharacterCreateBucket_Gamepad:Reset()
        self.expanded = false
        self.controlData = {}

        self.scrollChild:Clear()
        self.scrollChild:AddDataTemplate("ZO_CharacterCreateEntry_Gamepad", SetupListEntry, ZO_GamepadMenuEntryTemplateParametricListFunction)
    end
end

function ZO_CharacterCreateBucket_Gamepad:Expand()
    local container = self:GetContainer()
    container:SetHidden(false)
    self.expanded = true
    
    local expandFn = self.windowData.onExpandFn
    if expandFn then
        expandFn()
    end
end

function ZO_CharacterCreateBucket_Gamepad:Collapse()
    self:GetContainer():SetHidden(true)
    self.expanded = false

    local collapseFunction = self.windowData.onCollapseFn
    if collapseFunction then
        collapseFunction()
    end
end

--[[ Character Creation Bucket Manager ]]--

-- order specified here is the order they will appear in game
local CHARACTER_CREATE_BUCKETS = {
    CREATE_BUCKET_RACE,
    CREATE_BUCKET_BODY,
    CREATE_BUCKET_BODY_SHAPE,
    CREATE_BUCKET_HEAD_TYPE,
    CREATE_BUCKET_FEATURES,
    CREATE_BUCKET_FACE,
}

ZO_CharacterCreateBucketManager_Gamepad = ZO_CharacterCreateBucketManager_Base:Subclass()

function ZO_CharacterCreateBucketManager_Gamepad:New(...)
    return ZO_CharacterCreateBucketManager_Base.New(self, ...)
end

function ZO_CharacterCreateBucketManager_Gamepad:Initialize(container)
    self.tabBarEntries = {}
    self.headerData =
    {
        tabBarEntries = self.tabBarEntries,
    }
    ZO_CharacterCreateBucketManager_Base.Initialize(self, container, CHARACTER_CREATE_BUCKETS)

    self.active = false

    local header = GAMEPAD_CHARACTER_CREATE_MANAGER.header
    ZO_GamepadGenericHeader_Refresh(header, self.headerData)
end

function ZO_CharacterCreateBucketManager_Gamepad:AddBucket(bucketCategory)
    local bucket = ZO_CharacterCreateBucket_Gamepad:New(self.container, bucketCategory, self)
    local bucketContainer = bucket:GetContainer()

    bucketContainer:SetAnchor(TOPLEFT, self.container, TOPLEFT, 13, 138)
    bucketContainer:SetAnchor(BOTTOMRIGHT, self.container, BOTTOMRIGHT, -14, -73)

    self.buckets[bucketCategory] = bucket

    local tabBarParams = {
                            text = bucket.windowData.title,
                            bucket = bucket.windowData,
                            canSelect = true,
                            callback = function() self:OnTabBarCategoryChanged(bucket.category) end,
                         }
    table.insert(self.tabBarEntries, tabBarParams)
    bucket:SetTabIndex(#self.tabBarEntries)
end

function ZO_CharacterCreateBucketManager_Gamepad:OnTabBarCategoryChanged(bucketCategory)
    self:SwitchBucketsInternal(bucketCategory)
end

function ZO_CharacterCreateBucketManager_Gamepad:EnableTabBarCategory(bucket, enabled)
    local tabBarParams = self.tabBarEntries[bucket:GetTabIndex()]
    tabBarParams.canSelect = enabled
end

function ZO_CharacterCreateBucketManager_Gamepad:Activate()
    if not self.active then
        self.active = true
        if self.currentBucket then
            self.currentBucket:GetScrollChild():Activate()
            self.currentBucket:GetScrollChild():RefreshVisible()
        end
    end
end

function ZO_CharacterCreateBucketManager_Gamepad:Deactivate()
    if self.active then
        self.active = false
        if self.currentBucket then
            self.currentBucket:GetScrollChild():Deactivate()
        end
    end
end

function ZO_CharacterCreateBucketManager_Gamepad:SwitchBuckets(bucketCategory)
    local bucket = self:BucketForCategory(bucketCategory)
    local tab = bucket:GetTabIndex()
    ZO_GamepadGenericHeader_SetActiveTabIndex(GAMEPAD_CHARACTER_CREATE_MANAGER.header, tab)
end

function ZO_CharacterCreateBucketManager_Gamepad:SwitchBucketsInternal(bucketCategory)
    -- collapse current bucket
    if self.currentBucket then
        self.currentBucket:Collapse()
        if self.active then
            self.currentBucket:GetScrollChild():Deactivate()
        end
        self.currentBucket = nil
    end

    -- expand desired bucket
    local bucket = self:BucketForCategory(bucketCategory)

    if bucket then
        bucket:Expand()
        self.currentBucket = bucket
        if self.active then
            self.currentBucket:GetScrollChild():Activate()
            self.currentBucket:GetScrollChild():RefreshVisible()
        end
    end
end

function ZO_CharacterCreateBucketManager_Gamepad:MoveNext()
    self.currentBucket:GetScrollChild():MoveNext()
end

function ZO_CharacterCreateBucketManager_Gamepad:MovePrevious()
    self.currentBucket:GetScrollChild():MovePrevious()
end

function ZO_CharacterCreateBucketManager_Gamepad:SetEnabled(category, enabled)
    local bucket = self:BucketForCategory(category)
    bucket:SetEnabled(enabled)
end

function ZO_CharacterCreateBucketManager_Gamepad:Finalize()
    for _, bucket in pairs(self.buckets) do
        bucket:Finalize()
    end
end