local g_allianceRadioGroup
local g_raceRadioGroup
local g_classRadioGroup
local g_genderRadioGroup

local g_playingTransitionAnimations
local g_randomCharacterGenerated = false
local g_characterCreateOption = CHARACTER_CREATE_DEFAULT_LOCATION
local g_manager

local SUBCATEGORY_PAD = 10

local CREATE_BUCKET_WINDOW_DATA =
{
    [CREATE_BUCKET_RACE] = 
    { 
        windowName = "RaceBucket", 
        title = GetString(SI_CREATE_CHARACTER_BUCKET_TITLE_RACE), 
        tabNormal = "EsoUI/Art/CharacterCreate/CharacterCreate_raceIcon_up.dds",
        tabPressed = "EsoUI/Art/CharacterCreate/CharacterCreate_raceIcon_down.dds",
        tabMouseOver = "EsoUI/Art/CharacterCreate/CharacterCreate_raceIcon_over.dds",
        nextTab = CREATE_BUCKET_CLASS,
        previousTab = CREATE_BUCKET_FACE,
        onExpandFn =    function()
                            if(not g_playingTransitionAnimations) then
                                CharacterCreateSetIdlePosture()
                            end
                        end,
    },

    [CREATE_BUCKET_CLASS] = 
    { 
        windowName = "ClassBucket", 
        title = GetString(SI_CREATE_CHARACTER_BUCKET_TITLE_CLASS), 
        tabNormal = "EsoUI/Art/CharacterCreate/CharacterCreate_classIcon_up.dds",
        tabPressed = "EsoUI/Art/CharacterCreate/CharacterCreate_classIcon_down.dds",
        tabMouseOver = "EsoUI/Art/CharacterCreate/CharacterCreate_classIcon_over.dds",
        nextTab = CREATE_BUCKET_BODY,
        previousTab = CREATE_BUCKET_RACE,
    },

    [CREATE_BUCKET_BODY] = 
    { 
        windowName = "BodyBucket", 
        title = GetString(SI_CREATE_CHARACTER_BUCKET_TITLE_BODY), 
        tabNormal = "EsoUI/Art/CharacterCreate/CharacterCreate_bodyIcon_up.dds",
        tabPressed = "EsoUI/Art/CharacterCreate/CharacterCreate_bodyIcon_down.dds",
        tabMouseOver = "EsoUI/Art/CharacterCreate/CharacterCreate_bodyIcon_over.dds",
        nextTab = CREATE_BUCKET_FACE,
        previousTab = CREATE_BUCKET_CLASS,
        onExpandFn = function() SetCharacterCameraZoomAmount(-1) end,

        subCategoryData =
        {
            { id = SLIDER_SUBCAT_BODY_TYPE, anchorYOffsetOverride = SUBCATEGORY_PAD, },
            { id = SLIDER_SUBCAT_BODY_FEATURES, anchorYOffsetOverride = SUBCATEGORY_PAD, },
            { id = SLIDER_SUBCAT_BODY_UPPER, anchorYOffsetOverride = SUBCATEGORY_PAD, },
            { id = SLIDER_SUBCAT_BODY_LOWER, anchorYOffsetOverride = SUBCATEGORY_PAD, },
        },
    },

    [CREATE_BUCKET_FACE] = 
    { 
        windowName = "FaceBucket", 
        title = GetString(SI_CREATE_CHARACTER_BUCKET_TITLE_FACE), 
        tabNormal = "EsoUI/Art/CharacterCreate/CharacterCreate_faceIcon_up.dds",
        tabPressed = "EsoUI/Art/CharacterCreate/CharacterCreate_faceIcon_down.dds",
        tabMouseOver = "EsoUI/Art/CharacterCreate/CharacterCreate_faceIcon_over.dds",
        nextTab = CREATE_BUCKET_RACE,
        previousTab = CREATE_BUCKET_BODY,
        onExpandFn = function() SetCharacterCameraZoomAmount(1) end,

        subCategoryData =
        {
            { id = SLIDER_SUBCAT_FACE_TYPE, anchorYOffsetOverride = SUBCATEGORY_PAD, },
            { id = SLIDER_SUBCAT_VOICE, anchorYOffsetOverride = -42, },
            { id = SLIDER_SUBCAT_FACE_HAIR, anchorYOffsetOverride = SUBCATEGORY_PAD, },
            { id = SLIDER_SUBCAT_FACE_FEATURES, anchorYOffsetOverride = SUBCATEGORY_PAD, },
            { id = SLIDER_SUBCAT_FACE_FACE, anchorYOffsetOverride = SUBCATEGORY_PAD, },
            { id = SLIDER_SUBCAT_FACE_EYES, anchorYOffsetOverride = SUBCATEGORY_PAD, },
            { id = SLIDER_SUBCAT_FACE_BROW, anchorYOffsetOverride = SUBCATEGORY_PAD, },
            { id = SLIDER_SUBCAT_FACE_NOSE, anchorYOffsetOverride = SUBCATEGORY_PAD, },
            { id = SLIDER_SUBCAT_FACE_MOUTH, anchorYOffsetOverride = SUBCATEGORY_PAD, },
            { id = SLIDER_SUBCAT_FACE_EARS, anchorYOffsetOverride = SUBCATEGORY_PAD, },
        },
    },
}

local SLIDER_CATEGORY_TO_CREATE_BUCKET =
{
    [SLIDER_CATEGORY_AGE] = CREATE_BUCKET_BODY,
    [SLIDER_CATEGORY_BODY] = CREATE_BUCKET_BODY,
    [SLIDER_CATEGORY_FACE] = CREATE_BUCKET_FACE,
}

local APPEARANCE_NAME_TO_CREATE_BUCKET =
{
    [APPEARANCE_NAME_HAIR_STYLE] = CREATE_BUCKET_FACE,
    [APPEARANCE_NAME_HAIR_TINT] = CREATE_BUCKET_FACE,
    [APPEARANCE_NAME_SKIN_TINT] = CREATE_BUCKET_BODY,
    [APPEARANCE_NAME_ACCESSORY] = CREATE_BUCKET_FACE,
    [APPEARANCE_NAME_HEAD_MARKING] = CREATE_BUCKET_FACE,
    [APPEARANCE_NAME_BODY_MARKING] = CREATE_BUCKET_BODY,
    [APPEARANCE_NAME_EYE_TINT] = CREATE_BUCKET_FACE,
    [APPEARANCE_NAME_AGE] = CREATE_BUCKET_FACE,
    [APPEARANCE_NAME_EYEBROW] = CREATE_BUCKET_FACE,
    [APPEARANCE_NAME_VOICE] = CREATE_BUCKET_FACE,
}

local SUBCATEGORY_FOR_SLIDER =
{
    [SLIDER_NAME_FOREHEAD_SLOPE] = SLIDER_SUBCAT_FACE_FACE,
    [SLIDER_NAME_CHEEK_BONE_SIZE] = SLIDER_SUBCAT_FACE_FACE,
    [SLIDER_NAME_CHEEK_BONE_HEIGHT] = SLIDER_SUBCAT_FACE_FACE,
    [SLIDER_NAME_CHIN_HEIGHT] = SLIDER_SUBCAT_FACE_FACE,
    [SLIDER_NAME_CHIN_SIZE] = SLIDER_SUBCAT_FACE_FACE,
    [SLIDER_NAME_JAW_SIZE] = SLIDER_SUBCAT_FACE_FACE,
    [SLIDER_NAME_NECK_SIZE] = SLIDER_SUBCAT_FACE_FACE,
    [SLIDER_NAME_TOOTH_SIZE] = SLIDER_SUBCAT_FACE_FACE,

    [SLIDER_NAME_NOSE_SHAPE] = SLIDER_SUBCAT_FACE_NOSE,
    [SLIDER_NAME_NOSE_LENGTH] = SLIDER_SUBCAT_FACE_NOSE,
    [SLIDER_NAME_NOSE_HEIGHT] = SLIDER_SUBCAT_FACE_NOSE,
    [SLIDER_NAME_NOSE_WIDTH] = SLIDER_SUBCAT_FACE_NOSE,

    [SLIDER_NAME_EYE_HEIGHT] = SLIDER_SUBCAT_FACE_EYES,
    [SLIDER_NAME_EYE_SIZE] = SLIDER_SUBCAT_FACE_EYES,
    [SLIDER_NAME_EYE_SEPARATION] = SLIDER_SUBCAT_FACE_EYES,
    [SLIDER_NAME_EYE_ANGLE] = SLIDER_SUBCAT_FACE_EYES,
    [SLIDER_NAME_EYE_SQUINT] = SLIDER_SUBCAT_FACE_EYES,

    [SLIDER_NAME_MOUTH_HEIGHT] = SLIDER_SUBCAT_FACE_MOUTH,
    [SLIDER_NAME_MOUTH_WIDTH] = SLIDER_SUBCAT_FACE_MOUTH,
    [SLIDER_NAME_LIP_FULLNESS] = SLIDER_SUBCAT_FACE_MOUTH,
    [SLIDER_NAME_MOUTH_CURVE] = SLIDER_SUBCAT_FACE_MOUTH,

    [SLIDER_NAME_EAR_HEIGHT] = SLIDER_SUBCAT_FACE_EARS,
    [SLIDER_NAME_EAR_SIZE] = SLIDER_SUBCAT_FACE_EARS,
    [SLIDER_NAME_EAR_TIP_FLARE] = SLIDER_SUBCAT_FACE_EARS,
    [SLIDER_NAME_EAR_ROTATION] = SLIDER_SUBCAT_FACE_EARS,

    [SLIDER_NAME_EYEBROW_HEIGHT] = SLIDER_SUBCAT_FACE_BROW,
    [SLIDER_NAME_EYEBROW_ANGLE] = SLIDER_SUBCAT_FACE_BROW,
    [SLIDER_NAME_EYEBROW_SKEW] = SLIDER_SUBCAT_FACE_BROW,
    [SLIDER_NAME_EYEBROW_DEPTH] = SLIDER_SUBCAT_FACE_BROW,

    [SLIDER_NAME_LEG_SIZE] = SLIDER_SUBCAT_BODY_LOWER,
    [SLIDER_NAME_HIP_SIZE] = SLIDER_SUBCAT_BODY_LOWER,
    
    [SLIDER_NAME_FOOT_SIZE] = SLIDER_SUBCAT_BODY_LOWER,
    [SLIDER_NAME_BUTTOCKS_SIZE] = SLIDER_SUBCAT_BODY_LOWER,
    [SLIDER_NAME_TAIL_SIZE] = SLIDER_SUBCAT_BODY_LOWER,

    [SLIDER_NAME_TORSO_SIZE] = SLIDER_SUBCAT_BODY_UPPER,
    [SLIDER_NAME_HAND_SIZE] = SLIDER_SUBCAT_BODY_UPPER,
    [SLIDER_NAME_GUT_SIZE] = SLIDER_SUBCAT_BODY_UPPER,
    [SLIDER_NAME_ARM_SIZE] = SLIDER_SUBCAT_BODY_UPPER,
    [SLIDER_NAME_CHEST_SIZE] = SLIDER_SUBCAT_BODY_UPPER,
    [SLIDER_NAME_WAIST_SIZE] = SLIDER_SUBCAT_BODY_UPPER,

    [SLIDER_NAME_CHARACTER_HEIGHT] = SLIDER_SUBCAT_BODY_TYPE,
}

local SUBCATEGORY_FOR_APPEARANCE =
{
    [APPEARANCE_NAME_HAIR_STYLE] = SLIDER_SUBCAT_FACE_HAIR,
    [APPEARANCE_NAME_HAIR_TINT] = SLIDER_SUBCAT_FACE_HAIR,
    [APPEARANCE_NAME_ACCESSORY] = SLIDER_SUBCAT_FACE_FEATURES,
    [APPEARANCE_NAME_HEAD_MARKING] = SLIDER_SUBCAT_FACE_FEATURES,
    [APPEARANCE_NAME_AGE] = SLIDER_SUBCAT_FACE_FEATURES,
    [APPEARANCE_NAME_BODY_MARKING] = SLIDER_SUBCAT_BODY_FEATURES,
    [APPEARANCE_NAME_SKIN_TINT] = SLIDER_SUBCAT_BODY_FEATURES,
    [APPEARANCE_NAME_EYE_TINT] = SLIDER_SUBCAT_FACE_EYES,    
    [APPEARANCE_NAME_EYEBROW] = SLIDER_SUBCAT_FACE_BROW,
    [APPEARANCE_NAME_VOICE] = SLIDER_SUBCAT_VOICE,
}

-- This table defines how sliders should be ordered within their sub-categories.
-- It's not needed for sub-categories where all the controls are added manually,
-- but when sliders are added in loops (like characterSlider and appearanceSlider)
-- this is used to assist building the ordering table which will be passed over
-- to actually add the sliders.

local CONTROL_ORDERING =
{
    [SLIDER_SUBCAT_BODY_FEATURES] =
    {
        APPEARANCE_NAME_SKIN_TINT,
        APPEARANCE_NAME_BODY_MARKING,
        SLIDER_NAME_CHARACTER_HEIGHT,
    },

    [SLIDER_SUBCAT_BODY_UPPER] =
    {
        SLIDER_NAME_TORSO_SIZE,
        SLIDER_NAME_CHEST_SIZE,
        SLIDER_NAME_GUT_SIZE,
        SLIDER_NAME_WAIST_SIZE,
        SLIDER_NAME_ARM_SIZE, 
        SLIDER_NAME_HAND_SIZE,        
    },

    [SLIDER_SUBCAT_BODY_LOWER] =
    {
        SLIDER_NAME_TAIL_SIZE,
        SLIDER_NAME_HIP_SIZE,
        SLIDER_NAME_BUTTOCKS_SIZE,
        SLIDER_NAME_LEG_SIZE,
        SLIDER_NAME_FOOT_SIZE,        
    },

    [SLIDER_SUBCAT_VOICE] =
    {
        APPEARANCE_NAME_VOICE,
    },

    [SLIDER_SUBCAT_FACE_HAIR] =
    {
        APPEARANCE_NAME_HAIR_STYLE,
        APPEARANCE_NAME_HAIR_TINT,
    },

    [SLIDER_SUBCAT_FACE_FEATURES] =
    {
        APPEARANCE_NAME_AGE,
        APPEARANCE_NAME_ACCESSORY,
        APPEARANCE_NAME_HEAD_MARKING,
    },

    [SLIDER_SUBCAT_FACE_FACE] =
    {
        SLIDER_NAME_FOREHEAD_SLOPE,
        SLIDER_NAME_CHEEK_BONE_SIZE,
        SLIDER_NAME_CHEEK_BONE_HEIGHT,
        SLIDER_NAME_JAW_SIZE,
        SLIDER_NAME_CHIN_SIZE,
        SLIDER_NAME_CHIN_HEIGHT,
        SLIDER_NAME_NECK_SIZE,
        SLIDER_NAME_TOOTH_SIZE,
    },

    [SLIDER_SUBCAT_FACE_EYES] =
    {
        APPEARANCE_NAME_EYE_TINT,
        SLIDER_NAME_EYE_SIZE,
        SLIDER_NAME_EYE_ANGLE,
        SLIDER_NAME_EYE_SEPARATION,
        SLIDER_NAME_EYE_HEIGHT,        
        SLIDER_NAME_EYE_SQUINT,
    },

    [SLIDER_SUBCAT_FACE_BROW] =
    {
        APPEARANCE_NAME_EYEBROW,
        SLIDER_NAME_EYEBROW_HEIGHT,
        SLIDER_NAME_EYEBROW_ANGLE,
        SLIDER_NAME_EYEBROW_SKEW,
        SLIDER_NAME_EYEBROW_DEPTH,
    },

    [SLIDER_SUBCAT_FACE_NOSE] =
    {
        SLIDER_NAME_NOSE_SHAPE,
        SLIDER_NAME_NOSE_HEIGHT,
        SLIDER_NAME_NOSE_WIDTH,
        SLIDER_NAME_NOSE_LENGTH,
    },

    [SLIDER_SUBCAT_FACE_MOUTH] =
    {
        SLIDER_NAME_MOUTH_HEIGHT,
        SLIDER_NAME_MOUTH_WIDTH,
        SLIDER_NAME_MOUTH_CURVE,
        SLIDER_NAME_LIP_FULLNESS,        
    },

    [SLIDER_SUBCAT_FACE_EARS] =
    {
        SLIDER_NAME_EAR_SIZE,
        SLIDER_NAME_EAR_ROTATION,
        SLIDER_NAME_EAR_HEIGHT,        
        SLIDER_NAME_EAR_TIP_FLARE,        
    },
}

local function CreateTabControl(parent, windowData)
    local tabControl = CreateControlFromVirtual(windowData.windowName.."Tab", parent, "CCCategoryTab")

    tabControl:SetNormalTexture(windowData.tabNormal)
    tabControl:SetMouseOverTexture(windowData.tabMouseOver)
    tabControl:SetPressedTexture(windowData.tabPressed)

    tabControl.m_windowData = windowData

    return tabControl
end

--[[ Character Creation Bucket Instances ]]--

local CharacterCreateBucket = ZO_CharacterCreateBucket:Subclass()

function CharacterCreateBucket:New(parent, bucketCategory)
    local ccBucket = ZO_CharacterCreateBucket.New(self, parent, bucketCategory)

    local windowData = CREATE_BUCKET_WINDOW_DATA[bucketCategory]
    local container = CreateControlFromVirtual(windowData.windowName, parent, "CCCategoryBucket")
    local tabControl = CreateTabControl(parent, windowData)

    tabControl.m_bucket = ccBucket
    container.m_bucket = ccBucket

    ccBucket.m_windowData = windowData
    ccBucket.m_container = container
    ccBucket.m_tab = tabControl
    ccBucket.m_scrollChild = GetControl(container, "PaneScrollChild")
    ccBucket.m_subcategoryContainers = {}

    -- Create a spacer control to keep the contents of the scroll panel centered
    -- since scrolling operates by setting the topleft anchor of the scrollChild
    -- window.
    local widthSpacer = ccBucket.m_scrollChild:CreateControl("$(parent)WidthSpacer", CT_CONTROL)
    widthSpacer:SetWidth(360)
    widthSpacer:SetAnchor(TOP)

    -- Create another spacer to pad out the bottom so that the full contents of the pane
    -- can be scrolled into view.  This will need to be reanchored to each control that gets 
    -- added to the bucket.
    ccBucket.m_viewSpacer = ccBucket.m_scrollChild:CreateControl("$(parent)ViewSpacer", CT_CONTROL)
    ccBucket.m_viewSpacer:SetDimensions(360, 10)

    return ccBucket
end

function CharacterCreateBucket:GetTab()
    return self.m_tab
end

local BucketSubCategory = ZO_Object:Subclass()
function BucketSubCategory:New(bucketWindowData, subCategoryData, parent)
    local subCategory = ZO_Object.New(self)

    local subCategoryWindowName = string.format("%sSub%d", bucketWindowData.windowName, subCategoryData.id)
    local subCategoryControl = CreateControlFromVirtual(subCategoryWindowName, parent, "CCSubCategory")

    subCategory.m_control = subCategoryControl

    GetControl(subCategoryControl, "Name"):SetText(GetString("SI_CHARACTERSLIDERSUBCATEGORY", subCategoryData.id))
    return subCategory
end

function BucketSubCategory:GetControl()
    return self.m_control
end

function BucketSubCategory:AddControl(control)
    control:SetParent(self:GetControl())

    if(self.m_lastAnchored) then
        control:SetAnchor(TOP, self.m_lastAnchored, BOTTOM, 0, 20)
    else
        control:SetAnchor(TOP, GetControl(self.m_control, "TopSpacer"), BOTTOM)
    end 
        
    self.m_lastAnchored = control
end

function BucketSubCategory:Reset()
    self.m_lastAnchored = nil
end

function BucketSubCategory:IsEmpty()
    return self.m_lastAnchored == nil
end

function CharacterCreateBucket:AddSubCategories()
    local windowData = self.m_windowData

    if(windowData.subCategoryData) then
        if(not self.m_subCategories) then
            self.m_subCategories = {}
        end

        for subCatIndex, subCatData in ipairs(windowData.subCategoryData) do
            local subCategoryObj = self.m_subCategories[subCatData.id]
            if(not subCategoryObj) then
                subCategoryObj = BucketSubCategory:New(windowData, subCatData, self:GetScrollChild())
                self.m_subCategories[subCatData.id] = subCategoryObj
            end

            local subCategoryContainer = subCategoryObj:GetControl()
            subCategoryContainer:SetHidden(false)
            table.insert(self.m_subcategoryContainers, subCategoryContainer)

            self:AddControl(subCategoryContainer, nil, nil, nil, subCatData.anchorYOffsetOverride)
        end
    end
end

function CharacterCreateBucket:RemoveUnusedSubCategories()
    local windowData = self.m_windowData

    if(windowData.subCategoryData and self.m_subCategories) then
        for subCatIndex, subCatData in ipairs(windowData.subCategoryData) do
            local subCategoryObj = self.m_subCategories[subCatData.id]
            if(subCategoryObj and subCategoryObj:IsEmpty()) then
                local subCategoryContainer = subCategoryObj:GetControl()

                -- Grab the subcategory after this one and anchor it to the current 
                local nextSubCatControl = self.m_subcategoryContainers[subCatIndex + 1]
                if(nextSubCatControl) then
                    local valid, point, relTo, relPoint, offsX, offsY = subCategoryContainer:GetAnchor(0)

                    if(valid) then
                        nextSubCatControl:ClearAnchors()
                        nextSubCatControl:SetAnchor(point, relTo, relPoint, offsX, offsY)
                    end
                end
                
                subCategoryContainer:SetHidden(true)
                subCategoryContainer:ClearAnchors()
                subCategoryContainer:SetAnchor(TOP, self:GetScrollChild(), TOP, 0, 0)
            end
        end
    end
end

function CharacterCreateBucket:AddControl(control, updateFn, randomizeFn, subCategoryId, anchorYOffsetOverride)
    control.m_bucket = self
    control:ClearAnchors()
    control:SetHidden(false)

    if(subCategoryId and self.m_subCategories and self.m_subCategories[subCategoryId]) then
        self.m_subCategories[subCategoryId]:AddControl(control)
    else
        control:SetParent(self:GetScrollChild())

        anchorYOffsetOverride = anchorYOffsetOverride or 0

        if(self.m_lastAnchored) then
            control:SetAnchor(TOP, self.m_lastAnchored, BOTTOM, 0, 20 + anchorYOffsetOverride)
        else
            -- using a little vertical padding so controls with backdrops don't overlap at the top
            -- NOTE: Do not use override here, if it were negative it could easily push this control out of the window
            control:SetAnchor(TOP, self:GetScrollChild(), TOP, 0, 5)
        end

        self.m_lastAnchored = control

        self.m_viewSpacer:ClearAnchors()
        self.m_viewSpacer:SetAnchor(TOP, self.m_lastAnchored, BOTTOM, 0, 0)
    end

    self.m_controlData[control] = { updateFn = updateFn, randomizeFn = randomizeFn }
end

function CharacterCreateBucket:RemoveControl(control)
    -- Once a control is removed from a bucket it's no longer safe to add controls
    -- unless the bucket is totally reset (this is because of how m_lastAnchored works)
    -- This just cleans up the control and removes any lingering update handlers
    -- All the controls will be re-added to the bucket at some point.
    self.m_lastAnchored = nil

    control.m_bucket = nil
    self.m_controlData[control] = nil
end

function CharacterCreateBucket:Reset()
    self.m_expanded = false
    self.m_controlData = {}
    self.m_lastAnchored = nil
    self.m_subcategoryContainers = {}

    if(self.m_subCategories) then
        for _, subCategoryObj in pairs(self.m_subCategories) do
            subCategoryObj:Reset()
        end
    end
end

function CharacterCreateBucket:Expand()
    local container = self:GetContainer()
    container:SetHidden(false)
    self:GetTab():SetState(BSTATE_PRESSED, true)
    self.m_expanded = true
    
    local expandFn = self.m_windowData.onExpandFn
    if(expandFn) then
        expandFn()
    end
end

function CharacterCreateBucket:Collapse()
    self:GetContainer():SetHidden(true)
    self:GetTab():SetState(BSTATE_NORMAL, false)
    self.m_expanded = false

    local collapseFn = self.m_windowData.onCollapseFn
    if(collapseFn) then
        collapseFn()
    end
end

function CharacterCreateBucket:IsExpanded()
    return self.m_expanded
end

function CharacterCreateBucket:MouseEnter()
    InitializeTooltip(InformationTooltip, self:GetTab(), TOPRIGHT, 0, 0, TOPLEFT)
    SetTooltipText(InformationTooltip, self.m_windowData.title)
end

function CharacterCreateBucket:MouseExit()
    ClearTooltip(InformationTooltip)
end

--[[ Character Create Manager ]]--

local CharacterCreateManager = ZO_CharacterCreateManager:Subclass()

function CharacterCreateManager:New(characterData)
    local object = ZO_CharacterCreateManager.New(self, characterData)

    return object
end

--[[ Character Creation Bucket Manager ]]--

local g_bucketManager
local CharacterCreateBucketManager = ZO_CharacterCreateBucketManager:Subclass()

function CharacterCreateBucketManager:New(container)
    local mgr = ZO_CharacterCreateBucketManager.New(self, container)

    mgr:Initialize()

    return mgr
end

function CharacterCreateBucketManager:Initialize()
    for i = 1,NUM_CREATE_BUCKETS do
        if CREATE_BUCKET_WINDOW_DATA[i] then
            self:AddBucket(i)
        end
    end
end

function CharacterCreateBucketManager:AddBucket(bucketCategory)
    local bucket = CharacterCreateBucket:New(self.m_container, bucketCategory)
    local bucketContainer = bucket:GetContainer()

    bucketContainer:SetAnchor(TOPLEFT, ZO_CharacterCreateBuckets, TOPLEFT, 13, 138)
    bucketContainer:SetAnchor(BOTTOMRIGHT, ZO_CharacterCreateBuckets, BOTTOMRIGHT, -14, -73)

    self.m_buckets[bucketCategory] = bucket

    local tabControl = bucket:GetTab()
    if(self.m_lastAnchoredTab) then
        tabControl:SetAnchor(TOPLEFT, self.m_lastAnchoredTab, TOPRIGHT, 12, 0)
    else
        tabControl:SetAnchor(TOPLEFT, self.m_container, TOPLEFT, 62, 20)
    end

    self.m_lastAnchoredTab = tabControl
end

function CharacterCreateBucketManager:SwitchBuckets(tabButtonOrCategory)
    -- collapse current bucket
    if(self.m_currentBucket) then
        self.m_currentBucket:Collapse()
    end

    -- expand desired bucket
    local bucket
    if(type(tabButtonOrCategory) == "number") then
        bucket = self:BucketForCategory(tabButtonOrCategory)
    else
        bucket = self:BucketForChildControl(tabButtonOrCategory)
    end

    if(bucket) then
        bucket:Expand()
        self.m_currentBucket = bucket
    end
end

function CharacterCreateBucketManager:GetCurrentTab()
    if(self.m_currentBucket) then
        return self.m_currentBucket:GetTab()
    end
end

function CharacterCreateBucketManager:EnableBucketTab(bucketCategory, enabled)
    local bucket = self.m_buckets[bucketCategory]
    local tabControl = bucket:GetTab()

    local saturation = 1
    if(enabled) then
        saturation = 0
    end

    tabControl:SetEnabled(enabled)
    tabControl:SetDesaturation(saturation)
end

function CharacterCreateBucketManager:MouseOverBucket(bucketTab)
    self:BucketForChildControl(bucketTab):MouseEnter()
end

function CharacterCreateBucketManager:MouseExitBucket(bucketTab)
    self:BucketForChildControl(bucketTab):MouseExit()
end


function CharacterCreateBucketManager:AddSubCategories()
    for _, bucket in pairs(self.m_buckets) do
        bucket:AddSubCategories()
    end
end

function CharacterCreateBucketManager:RemoveUnusedSubCategories()
    for _, bucket in pairs(self.m_buckets) do
        bucket:RemoveUnusedSubCategories()
    end
end

--[[ Slider Randomization Helper...all sliders share the m_sliderObject from the top control, so this just helps cut down on duplicate functions ]]--
local function RandomizeSlider(control, randomizeType)
    control.m_sliderObject:Randomize(randomizeType)
end

--[[ Character Create Slider ]]--
-- To use this, create a CCSlider, its OnInitialize handler will create this object and wire everything up.
-- Those controls are intended to be used from a pool, and after acquiring those controls from the pool
-- the caller will use CharacterCreateSlider:SetData to set up that specific instance.
local CharacterCreateSlider = ZO_CharacterCreateSlider:Subclass()

function CharacterCreateSlider:New(control)
    local slider = ZO_CharacterCreateSlider.New(self, control)

    slider.m_decrementButton = GetControl(control, "Decrement")
    slider.m_incrementButton = GetControl(control, "Increment")

    return slider
end

--[[ Character Create Appearance Slider ]]-- 
-- Similar construction details to the CharacterCreateSlider.  Make the appropriate ui control from a template (color picker, icon picker, etc...)
-- and it will wire all the fields up.
local CharacterCreateAppearanceSlider = CharacterCreateSlider:Subclass()

function CharacterCreateAppearanceSlider:New(control)
    local slider = CharacterCreateSlider.New(self, control)

    zo_mixin(slider, ZO_CharacterCreateAppearanceSlider)

    return slider
end

--[[ Character Create Color Slider ]]--
-- Similar construction details to the CharacterCreateSlider.  Make the appropriate ui control from a template (color picker, icon picker, etc...)
-- and it will wire all the fields up.  The one main difference is that this comes from a common utility class, so it needs a little extra
-- for wiring up the subsystems.  The internal object and control will be a ZO_ColorSwatchPicker, but this will wrap that in an interface
-- that makes it look like a CharCreate*Slider object.
local CharacterCreateColorSlider = CharacterCreateSlider:Subclass()

function CharacterCreateColorSlider:New(control)
    local slider = CharacterCreateSlider.New(self, control)

    local function OnClickedCallback(paletteIndex)
        OnCharacterCreateOptionChanged()
        SetAppearanceValue(slider.m_category, paletteIndex)
    end

    ZO_ColorSwatchPicker_SetClickedCallback(slider.m_slider, OnClickedCallback)
    return slider
end

function CharacterCreateColorSlider:SetData(appearanceName, numValues, displayName)
    self.m_category = appearanceName
    self.m_numSteps = numValues

    self:SetName(displayName, "SI_CHARACTERAPPEARANCENAME", appearanceName)

    self.m_legalInitialSettings = {}

    for paletteIndex =  1, numValues do
        local r, g, b, legalInitialSetting = GetAppearanceValueInfo(appearanceName, paletteIndex)
        ZO_ColorSwatchPicker_AddColor(self.m_slider, paletteIndex, r, g, b)

        if(legalInitialSetting) then
            table.insert(self.m_legalInitialSettings, paletteIndex)
        end
    end

    self:Update()
end

function CharacterCreateColorSlider:Randomize(randomizeType)
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

        OnCharacterCreateOptionChanged()
        SetAppearanceValue(self.m_category, randomValue)
        self:Update()
    end
end

function CharacterCreateColorSlider:UpdateLockState()
    ZO_ColorSwatchPicker_SetEnabled(self.m_slider, self.m_lockState == TOGGLE_BUTTON_OPEN)
end

function CharacterCreateColorSlider:Update()
    ZO_ColorSwatchPicker_SetSelected(self.m_slider, GetAppearanceValue(self.m_category))
end

--[[ Character Create Dropdown Slider ]]--
-- Similar interface to the CharacterCreateSlider, completely different internals.  
-- The drop down is used to choose named appearance types.
local CharacterCreateDropdownSlider = ZO_Object:Subclass()

function CharacterCreateDropdownSlider:New(control)
    local slider = ZO_Object.New(self)

    control.m_sliderObject = slider
    slider.m_control = control
    slider.m_padlock = GetControl(control, "Padlock")
    slider.m_lockState = TOGGLE_BUTTON_OPEN

    slider.m_dropdown = ZO_ComboBox_ObjectFromContainer(control:GetNamedChild("Dropdown"))
    slider.m_dropdown:SetSortsItems(false)
    slider.m_dropdown:SetFont("ZoFontGame")
    slider.m_dropdown:SetSpacing(4)
    
    return slider
end

function CharacterCreateDropdownSlider:SetName(displayName, enumNameFallback, enumValue)
    -- nothing to do for now, the only dropdown in use has its own section
end

-- Terrible first implementation
local voiceIdToNameId =
{
    SI_CREATE_CHARACTER_VOICE_A,
    SI_CREATE_CHARACTER_VOICE_B,
    SI_CREATE_CHARACTER_VOICE_C,
    SI_CREATE_CHARACTER_VOICE_D,
    SI_CREATE_CHARACTER_VOICE_E,
    SI_CREATE_CHARACTER_VOICE_F,
    SI_CREATE_CHARACTER_VOICE_G,
    SI_CREATE_CHARACTER_VOICE_H,
}

local function GetAppearanceItemName(appearanceName, value)
    local nameId = voiceIdToNameId[value]
    if(nameId) then
        return GetString(nameId)
    end

    return GetString(SI_CREATE_CHARACTER_VOICE_A)
end

function CharacterCreateDropdownSlider:SetData(appearanceName, numValues, displayName)
    self.m_category = appearanceName
    self.m_numSteps = numValues

    self:SetName(displayName, "SI_CHARACTERAPPEARANCENAME", appearanceName)

    self.m_legalInitialSettings = {}
    self.m_dropdown:ClearItems()

    local function OnAppearanceItemSelected(dropdown, itemName, entry)
        OnCharacterCreateOptionChanged()
        SetAppearanceValue(self.m_category, entry.value)
        self:Update()
    end

    for valueIndex = 1, numValues do
        local _, _, _, legalInitialSetting = GetAppearanceValueInfo(appearanceName, valueIndex)

        local itemName = GetAppearanceItemName(appearanceName, valueIndex)
        local entry = self.m_dropdown:CreateItemEntry(itemName, OnAppearanceItemSelected)
        entry.value = valueIndex
        self.m_dropdown:AddItem(entry)

        if(legalInitialSetting) then
            table.insert(self.m_legalInitialSettings, valueIndex)
        end
    end

    self:Update()
end

function CharacterCreateDropdownSlider:Randomize(randomizeType)
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

        OnCharacterCreateOptionChanged()
        SetAppearanceValue(self.m_category, randomValue)
        self:Update()
    end
end

function CharacterCreateDropdownSlider:ToggleLocked()
    self.m_lockState = not self.m_lockState
    ZO_ToggleButton_SetState(self.m_padlock, self.m_lockState)

    self:UpdateLockState()
end

function CharacterCreateDropdownSlider:UpdateLockState()
    self.m_dropdown:SetEnabled(self.m_lockState == TOGGLE_BUTTON_OPEN)
end

function CharacterCreateDropdownSlider:Update()
    local appearanceValue = GetAppearanceValue(self.m_category)

    local function SelectAppropriateAppearance(index, entry)
        if(entry.value == appearanceValue) then
            self.m_dropdown:SetSelectedItem(entry.name)
            return true
        end
    end

    self.m_dropdown:EnumerateEntries(SelectAppropriateAppearance)
end

function CharacterCreateDropdownSlider:Preview()
    PreviewAppearanceValue(self.m_category)
end

--[[ Character Create Slider and Appearance Slider Managers ]]--
-- Manages a collection of sliders with a pool

local CharacterCreateSliderManager = ZO_Object:Subclass()
local g_sliderManager

function CharacterCreateSliderManager:New(parent)
    local manager = ZO_Object.New(self)

    local CreateSlider = function(pool) return ZO_ObjectPool_CreateNamedControl("CharacterCreateSlider", "CCSlider", pool, parent) end
    local CreateAppearanceSlider = function(pool) return ZO_ObjectPool_CreateNamedControl("CharacterCreateAppearanceSlider", "CCAppearanceSlider", pool, parent) end
    local CreateColorPicker = function(pool) return ZO_ObjectPool_CreateNamedControl("CharacterCreateColorPicker", "CCColorSlider", pool, parent) end
    local CreateDropdown = function(pool) return ZO_ObjectPool_CreateNamedControl("CharacterCreateDropdown", "CCDropDown", pool, parent) end

    local function ResetSlider(sliderControl)
        g_bucketManager:RemoveControl(sliderControl)
        sliderControl:SetHidden(true)
    end

    local function ResetColorPicker(sliderControl)
        g_bucketManager:RemoveControl(sliderControl)
        ZO_ColorSwatchPicker_Clear(GetControl(sliderControl, "Slider"))
        sliderControl:SetHidden(true)
    end

    manager.m_pools =
    {
        ["slider"] = ZO_ObjectPool:New(CreateSlider, ResetSlider),
        ["icon"] = ZO_ObjectPool:New(CreateAppearanceSlider, ResetSlider),
        ["color"] = ZO_ObjectPool:New(CreateColorPicker, ResetColorPicker),
        ["named"] = ZO_ObjectPool:New(CreateDropdown, ResetSlider),
    }

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

    return triangle
end


function CharacterCreateTriangle:UpdateLockState()
    local enabled = self.m_lockState == TOGGLE_BUTTON_OPEN
    self.m_picker:SetEnabled(enabled)
    GetControl(self.m_thumb, "Glow"):SetHidden(not enabled)

    if(enabled) then
        GetControl(self.m_control, "BG"):SetTexture("EsoUI/Art/CharacterCreate/selectorTriangle.dds")
    else
        GetControl(self.m_control, "BG"):SetTexture("EsoUI/Art/CharacterCreate/selectorTriangle_disabled.dds")
    end
end


--[[ Character Creation CurrentData ]]--
-- The important stuff, data describing all the valid options you can choose from
local g_characterData



--[[ Creator Control Initialization ]]--

local g_characterStartLocation
local characterCreateTemplateRefCount = 0

local function GetCurrentAllianceData()
    local selectedAlliance = CharacterCreateGetAlliance()
    local alliance = g_characterData:GetAllianceForAllianceDef(selectedAlliance)

    if(alliance) then
        return alliance.name, alliance.backdropTop, alliance.backdropBottom
    end

    return "", "", ""
end

local function UpdateGenderSpecificText(currentGender)
    currentGender = currentGender or CharacterCreateGetGender()

    ZO_CharacterCreateRaceName:SetText(zo_strformat(SI_RACE_NAME, GetRaceName(currentGender, CharacterCreateGetRace())))
    ZO_CharacterCreateClassSelectionName:SetText(zo_strformat(SI_CLASS_NAME, GetClassName(currentGender, CharacterCreateGetClass())))
end

local function UpdateRaceControl()
    local currentRace = CharacterCreateGetRace()

    local function IsRaceClicked(button)
        return button.defId == currentRace
    end
    
    g_raceRadioGroup:UpdateFromData(IsRaceClicked)

    local currentAlliance = CharacterCreateGetAlliance()

    local function IsAllianceClicked(button)
        return button.defId == currentAlliance
    end

    g_allianceRadioGroup:UpdateFromData(IsAllianceClicked)

    local race = g_characterData:GetRaceForRaceDef(currentRace)
    if(race) then
        local allianceName, backdropTop, backdropBottom = GetCurrentAllianceData()

        UpdateGenderSpecificText()

        ZO_CharacterCreateRaceAlliance:SetText(zo_strformat(SI_ALLIANCE_NAME, allianceName))
        ZO_CharacterCreateRaceDescription:SetText(race.lore)

        ZO_CharacterCreateRaceAllianceBG:SetTexture(backdropTop)
        ZO_CharacterCreateRaceAllianceBGBottom:SetTexture(backdropBottom)
    end
end

local function UpdateGenderControl()
    local currentGender = CharacterCreateGetGender()

    local function IsGenderClicked(button)
        return button.gender == currentGender
    end
    
    g_genderRadioGroup:UpdateFromData(IsGenderClicked)
end

local function UpdateClassControl()
    local currentClass = CharacterCreateGetClass()

    local function IsClassClicked(button)
        return button.defId == currentClass
    end

    g_classRadioGroup:UpdateFromData(IsClassClicked)

    local class = g_characterData:GetClassForClassDef(currentClass)
    if(class) then
        UpdateGenderSpecificText()
        ZO_CharacterCreateClassSelectionDescription:SetText(class.lore)
    end
end

local function UpdateSlider(slider)
    slider.m_sliderObject:Update()
end

local function FindOrdering(orderingTable, name)
    for i = 1, #orderingTable do
        if(orderingTable[i] == name) then
            return i
        end
    end

    return 1
end

local function SliderComparator(data1, data2)
    local name1 = data1.name
    local name2 = data2.name

    local subCat1 = data1.subCat
    local subCat2 = data2.subCat

    if(subCat1 ~= subCat2) then
        return subCat1 < subCat2
    end

    return FindOrdering(CONTROL_ORDERING[subCat1], name1) < FindOrdering(CONTROL_ORDERING[subCat2], name2)
end

function CharacterCreateManager:InitializeControls()
    -- If this was being suppressed changes MUST be applied now or there will be no slider data to build
    SetSuppressCharacterChanges(false)

    g_sliderManager:ReleaseAllObjects()

    g_bucketManager:Reset()
    g_bucketManager:AddSubCategories()
    g_bucketManager:AddControl(ZO_CharacterCreateGenderSelection, CREATE_BUCKET_RACE, UpdateGenderControl)
    g_bucketManager:AddControl(ZO_CharacterCreateRace, CREATE_BUCKET_RACE, UpdateRaceControl)    
    g_bucketManager:AddControl(ZO_CharacterCreateClassSelection, CREATE_BUCKET_CLASS, UpdateClassControl)
    g_bucketManager:AddControl(ZO_CharacterCreatePhysiqueSelection, CREATE_BUCKET_BODY, UpdateSlider, RandomizeSlider, SLIDER_SUBCAT_BODY_TYPE)
    g_bucketManager:AddControl(ZO_CharacterCreateFaceSelection, CREATE_BUCKET_FACE, UpdateSlider, RandomizeSlider, SLIDER_SUBCAT_FACE_TYPE)

    -- TODO: this fixes a bug where the triangles don't reflect the correct data...there will be more fixes to pregameCharacterManager to address the real issue
    -- (where the triangle data needs to live on its own rather than being tied to the unit)
    UpdateSlider(ZO_CharacterCreatePhysiqueSelection)
    UpdateSlider(ZO_CharacterCreateFaceSelection)

    local sliderData = {}

    for i = 1, GetNumSliders() do
        local name, category, steps, value, defaultValue = GetSliderInfo(i)

        if(name) then
            local sliderControl = g_sliderManager:AcquireObject("slider")
            sliderControl.m_sliderObject:SetData(i, name, category, steps, value, defaultValue)

            local bucket = SLIDER_CATEGORY_TO_CREATE_BUCKET[category]
            local subCat = SUBCATEGORY_FOR_SLIDER[name]

            sliderData[#sliderData + 1] = { bucket = bucket, subCat = subCat, name = name, control = sliderControl, }
        end
    end

    for i = 1, GetNumAppearances() do
        local appearanceName, appearanceType, numValues, displayName = GetAppearanceInfo(i)

        if(numValues > 0) then
            local appearanceControl = g_sliderManager:AcquireObject(appearanceType)
            appearanceControl.m_sliderObject:SetData(appearanceName, numValues, displayName)
            
            local bucket = APPEARANCE_NAME_TO_CREATE_BUCKET[appearanceName]
            local subCat = SUBCATEGORY_FOR_APPEARANCE[appearanceName]
            
            sliderData[#sliderData + 1] = { bucket = bucket, subCat = subCat, name = appearanceName, control = appearanceControl, }
        end
    end

    table.sort(sliderData, SliderComparator)

    for _, orderingData in ipairs(sliderData) do
        g_bucketManager:AddControl(orderingData.control, orderingData.bucket, UpdateSlider, RandomizeSlider, orderingData.subCat)
    end

    g_bucketManager:RemoveUnusedSubCategories()
end

local function OnLogoutSuccessful()
    g_randomCharacterGenerated = false
end

local function SetSelectorButtonEnabled(selectorButton, radioGroup, enabled)
    radioGroup:SetButtonIsValidOption(selectorButton, enabled)

    if(enabled) then
        selectorButton:SetDesaturation(0)
    else
        selectorButton:SetDesaturation(1)
    end
end

local function UpdateSelectorsForTemplate(isEnabledCallback, characterDataTable, templateData, radioGroup, optionalValidIndexTable)
    for dataIndex, data in ipairs(characterDataTable) do
        local enabled = isEnabledCallback(data, templateData)
        data.isRadioEnabled = enabled
        SetSelectorButtonEnabled(data.selectorButton, radioGroup, enabled)

        if(optionalValidIndexTable and enabled) then
            optionalValidIndexTable[#optionalValidIndexTable + 1] = dataIndex
        end
    end
end

local function PickRandomSelectableClass()
    -- UpdateSelectorsForTemplate() should be called prior to this function or unselectable classes might be set (which would result in no class being set).
    CharacterCreateSetClass(g_characterData:PickRandomClass())
end

local function PickRandomGender()
    CharacterCreateSetGender(g_characterData:PickRandomGender())
end

local function UpdateSelectedTemplateText(selectedText)
    if(not selectedText) then
        local templateData = g_characterData:GetTemplate(CharacterCreateGetTemplate())
        if(templateData) then
            selectedText = templateData.name
        end
    end

    if(selectedText) then
        ZO_CharacterCreateTemplateSelectedText:SetText(selectedText)
        ZO_CharacterCreateTemplateList:SetHidden(true)
        characterCreateTemplateRefCount = 0
    end
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

local function SetTemplate(templateId)
    local templateData = g_characterData:GetTemplate(templateId)
    if(not templateData) then return false end

    UpdateSelectedTemplateText(templateData.name)

    if(not templateData.isSelectable or CharacterCreateGetTemplate() == templateId) then return false end

    CharacterCreateSetTemplate(templateId)

    g_bucketManager:SwitchBuckets(CREATE_BUCKET_RACE)

    -- Disable appearance related controls if the appearance is overridden in the template.
    local enabled = not templateData.overrideAppearance
    g_bucketManager:EnableBucketTab(CREATE_BUCKET_BODY, enabled)
    g_bucketManager:EnableBucketTab(CREATE_BUCKET_FACE, enabled)
    ZO_CharacterCreateRandomizeAppearance:SetEnabled(enabled)

    local validRaces = {}
    UpdateSelectorsForTemplate(UpdateRaceSelectorsForTemplate, g_characterData:GetRaceInfo(), templateData, g_raceRadioGroup, validRaces)
    UpdateSelectorsForTemplate(UpdateClassSelectorsForTemplate, g_characterData:GetClassInfo(), templateData, g_classRadioGroup)

    local validAlliances = {}
    g_characterData:UpdateAllianceSelectability()
    UpdateSelectorsForTemplate(UpdateAllianceSelectorsForTemplate, g_characterData:GetAllianceInfo(), templateData, g_allianceRadioGroup, validAlliances)

    g_genderRadioGroup:SetEnabled(templateData.gender == 0)
    
    -- Pick a race
    if(templateData.race ~= 0) then
        CharacterCreateSetRace(templateData.race)
    else     
        CharacterCreateSetRace(g_characterData:PickRandomRace(validRaces))
    end

    -- Pick an alliance 
    if(templateData.alliance ~= 0) then
        CharacterCreateSetAlliance(templateData.alliance)
    else
        -- (never random unless a race without a fixed alliance is picked)
        local alliance = g_characterData:GetRaceForRaceDef(CharacterCreateGetRace()).alliance
        if(alliance ~= 0) then
            CharacterCreateSetAlliance(alliance)
        else
            CharacterCreateSetAlliance(g_characterData:PickRandomAlliance(validAlliances))
        end
    end

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
    g_manager:InitializeControls()
    if(not templateData.overrideAppearance) then
        ZO_CharacterCreate_RandomizeAppearance("initial")
    else
        InitializeAppearanceFromTemplate(templateId)
    end
    return true
end

function ZO_CharacterCreate_GenerateRandomCharacter()
    if(not g_randomCharacterGenerated and g_characterData ~= nil and g_characterData:GetRaceInfo() ~= nil) then
        g_randomCharacterGenerated = true
        CharacterCreateSetRace(g_characterData:PickRandomRace())
        CharacterCreateSetAlliance(g_characterData:PickRandomAlliance())
        CharacterCreateSetGender(g_characterData:PickRandomGender())
        CharacterCreateSetClass(g_characterData:PickRandomClass())

        g_manager:InitializeControls()
        ZO_CharacterCreate_RandomizeAppearance("initial")
        return true
    end

    return false
end

local function InitializeSelectorButton(buttonControl, data, radioGroup)
    if(data == nil) then return end

    buttonControl:SetHidden(false)

    buttonControl:SetNormalTexture(data.normalIcon)
    buttonControl:SetPressedTexture(data.pressedIcon)
    buttonControl:SetMouseOverTexture(data.mouseoverIcon)

    radioGroup:Add(buttonControl)
    SetSelectorButtonEnabled(buttonControl, radioGroup, data.isSelectable)

    -- There should be a single button that represents this piece of data
    -- So add the button control to the character data so that if it's needed
    -- later to update state, there are no insane hoops to jump through to get the button.
    -- For example, these buttons are now accessible by calling g_characterData:GetRaceInfo()[raceIndex].selectorButton
    data.selectorButton = buttonControl
end

local function InitializeAllianceSelector(allianceButton, allianceData)
    InitializeSelectorButton(allianceButton, allianceData, g_allianceRadioGroup)

    allianceButton.name = allianceData.name
    allianceButton.defId = allianceData.alliance
end

local function InitializeAllianceSelectors()
    local layoutTable =
    {
        ZO_CharacterCreateRaceAllianceSelector1,
        ZO_CharacterCreateRaceAllianceSelector2,
        ZO_CharacterCreateRaceAllianceSelector3,
    }

    local alliances = g_characterData:GetAllianceInfo()
    for _, alliance in ipairs(alliances) do
        local selector = layoutTable[alliance.position]
        InitializeAllianceSelector(selector, alliance)
    end
end

local function AddRaceSelectionDataToSelector(buttonControl, raceData)
    buttonControl.nameFn = GetRaceName
    buttonControl.defId = raceData.race
    buttonControl.alliance = raceData.alliance
end

local function InitializeRaceSelectors()
    local layoutTable =
    {
        ZO_CharacterCreateRaceColumn11,
        ZO_CharacterCreateRaceColumn21,
        ZO_CharacterCreateRaceColumn31,
        ZO_CharacterCreateRaceColumn12,
        ZO_CharacterCreateRaceColumn22,
        ZO_CharacterCreateRaceColumn32,
        ZO_CharacterCreateRaceColumn13,
        ZO_CharacterCreateRaceColumn23,
        ZO_CharacterCreateRaceColumn33,
        ZO_CharacterCreateRaceSingleButton,
    }

    local races = g_characterData:GetRaceInfo()
    for _, race in ipairs(races) do
        local raceButton = layoutTable[race.position]
        InitializeSelectorButton(raceButton, race, g_raceRadioGroup)
        AddRaceSelectionDataToSelector(raceButton, race)
    end
end

local function InitializeGenderSelector()
    ZO_CharacterCreateGenderSelectionMaleLabel:SetText(GetString("SI_GENDER", GENDER_MALE))
    ZO_CharacterCreateGenderSelectionFemaleLabel:SetText(GetString("SI_GENDER", GENDER_FEMALE))

    ZO_CharacterCreateGenderSelectionMaleButton.gender = GENDER_MALE
    ZO_CharacterCreateGenderSelectionFemaleButton.gender = GENDER_FEMALE

    g_genderRadioGroup:Add(ZO_CharacterCreateGenderSelectionMaleButton)
    g_genderRadioGroup:Add(ZO_CharacterCreateGenderSelectionFemaleButton)
end

local function InitializeClassSelectors()
    local classes = g_characterData:GetClassInfo()

    local parent = ZO_CharacterCreateClassSelectionButtonArea
    local stride = 3
    local padX = 0
    local padY = 0
    local controlWidth = 120
    local controlHeight = 80
    local initialX = 0
    local initialY = 0

    local anchor = ZO_Anchor:New(TOPLEFT, parent, TOPLEFT, initialX, initialY)

    for i = 1, #classes do
        local class = classes[i]
        local selectorName = "SelectClass"..class.class
        local selector = GetControl(selectorName)
        if(not selector) then
            selector = CreateControlFromVirtual(selectorName, parent, "ClassSelectorButton")
        end

        selector.nameFn = GetClassName
        selector.defId = class.class

        InitializeSelectorButton(selector, class, g_classRadioGroup)
        ZO_Anchor_BoxLayout(anchor, selector, i - 1, stride, padX, padY, controlWidth, controlHeight, initialX, initialY, GROW_DIRECTION_DOWN_RIGHT)
    end
end

local function InitializeTemplateList()
    local templateList = ZO_CharacterCreateTemplateList
    ZO_ScrollList_Clear(templateList)

    local templatesAllowed = GetTemplateStatus()

    if(templatesAllowed) then
        local templates = g_characterData:GetTemplateInfo()
        local scrollData = ZO_ScrollList_GetDataList(templateList)
    
        for _, template in ipairs(templates) do
		    if(template.isSelectable) then 
				scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(1, template)
		    end
        end            
        
        ZO_CharacterCreateTemplateSelected:SetHidden(false)
    else
        ZO_CharacterCreateTemplateSelected:SetHidden(true)
    end

    ZO_ScrollList_Commit(templateList)

    ZO_CharacterCreateTemplateList:SetHidden(true)
    characterCreateTemplateRefCount = 0
end

function ZO_CharacterCreate_InitializeNameControl(nameEdit, linkedButton, linkedInstructions)
    SetupEditControlForNameValidation(nameEdit)

    nameEdit.linkedButton = linkedButton
    nameEdit.linkedInstructions = linkedInstructions
end

--[[ XML Handlers and global functions ]]--

function ZO_OpenCharacterCreateTemplateDropdown()
    if ZO_CharacterCreateTemplateList:IsHidden() then
         characterCreateTemplateRefCount = 2
         ZO_CharacterCreateTemplateList:SetHidden(false)
    else
        characterCreateTemplateRefCount = 0
        ZO_CharacterCreateTemplateList:SetHidden(true)
    end
end

function ZO_CharacterCreateTemplateEntry_OnClicked(control)
    if(SetTemplate(control.data.template)) then
        g_bucketManager:UpdateControlsFromData()
    end
end

function ZO_CharacterCreate_RandomizeAppearance(randomizeType)
    g_bucketManager:RandomizeAppearance(randomizeType)
end

local function OnCharacterCreated(eventCode, characterId)
    g_randomCharacterGenerated = false -- the next time we enter character create, we want to generate a random character again.
    g_characterCreateOption = CHARACTER_CREATE_DEFAULT_LOCATION
    g_shouldBePromptedForTutorialSkip = true

    local startLocation = ZO_CharacterCreate_GetStartLocation()
    PregameStateManager_PlayCharacter(characterId, startLocation)
end

local reasonsThatDisableCreateButton =
{
    [CHARACTER_CREATE_ERROR_INVALIDNAME] = true,
    [CHARACTER_CREATE_ERROR_DUPLICATENAME] = true,
    [CHARACTER_CREATE_ERROR_NAMETOOSHORT] = true,
    [CHARACTER_CREATE_ERROR_NAMETOOLONG] = true,
}

local function OnCharacterCreateFailed(eventCode, reason)
    if IsConsoleUI() then
        return
    end

    local errorReason = GetString("SI_CHARACTERCREATEERROR", reason)
    
    -- Show the fact that the character could not be created.
    ZO_Dialogs_ShowDialog("CHARACTER_CREATE_FAILED_REASON", nil, {mainTextParams = {errorReason}})

    if(reasonsThatDisableCreateButton[reason]) then
        ZO_CharacterCreateDoIt:SetEnabled(false)
    end
end

local function OnCharacterConstructionReady()
    g_characterData:PerformDeferredInitialization()

    InitializeGenderSelector()
    InitializeAllianceSelectors()
    InitializeRaceSelectors()
    InitializeClassSelectors()
    InitializeTemplateList()

    -- Nightmare load-ordering dependency...there are probably other ways around this, and they're probably just as bad.
    -- Once game data is loaded, generate a random character for character create just to advance the 
    -- load state.  It won't necessarily do any extra work creating an actual character, since we're going 
    -- to drop back into the current state, but we need to tell the system to load something
    if(GetNumCharacters() == 0) then
        ZO_CharacterCreate_Reset()
        CharacterCreateSetFirstTimePosture()
    end
end

local function OnCharacterCreateRequested()
    ZO_CharacterCreateDoIt:SetEnabled(false)
end

function ZO_CharacterCreate_Initialize()
    ZO_CharacterCreate_Shared_Initialize()

    ZO_CharacterCreate.fadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CharacterCreateMainControlsFade", ZO_CharacterCreate)

    g_allianceRadioGroup = ZO_RadioButtonGroup:New()
    g_raceRadioGroup = ZO_RadioButtonGroup:New()
    g_classRadioGroup = ZO_RadioButtonGroup:New()
    g_genderRadioGroup = ZO_RadioButtonGroup:New()

    g_characterData = ZO_CharacterCreateData:New()
    g_manager = CharacterCreateManager:New(g_characterData)
    g_bucketManager = CharacterCreateBucketManager:New(ZO_CharacterCreateBuckets)

    g_sliderManager = CharacterCreateSliderManager:New(ZO_CharacterCreateBuckets)

    ZO_CharacterCreateDoIt:SetEnabled(false)
    local nameInstructions = ZO_ValidNameInstructions:New(ZO_CharacterCreateNameInstructions)
    ZO_CharacterCreateCharacterNameInstructions:SetText(GetString(SI_CREATE_CHARACTER_TITLE_NAME))
    ZO_CharacterCreate_InitializeNameControl(ZO_CharacterCreateCharacterName, ZO_CharacterCreateDoIt, nameInstructions)
    
	local list = ZO_CharacterCreateTemplateList

    local function SetupData(control, data)
        control.data = data
        control:SetText(data.name)
    end
	
	ZO_ScrollList_SetHeight(list, 350)
	ZO_ScrollList_AddDataType(list, 1, "CharacterCreateTemplateRow", 20, SetupData)
	ZO_ScrollList_EnableHighlight(list, "ZO_ThinListHighlight")

    local downFromSlider = false
    local function OnGlobalMouseUp()
        local currentState = PregameStateManager_GetCurrentState()
        if(currentState == "CharacterSelect" or currentState == "CharacterCreate") then
            CharacterCreateStopMouseSpin()
        end

        if characterCreateTemplateRefCount > 0 and (not MouseIsOver(ZO_CharacterCreateTemplateList) or downFromSlider) then
            characterCreateTemplateRefCount = characterCreateTemplateRefCount - 1
            if characterCreateTemplateRefCount == 0 then
                ZO_CharacterCreateTemplateList:SetHidden(true)
            end
        end

        downFromSlider = false
    end

    ZO_CharacterCreateTemplateListScrollBar:SetHandler("OnMouseDown", function() 
        characterCreateTemplateRefCount = 2
        downFromSlider = true
    end)

    EVENT_MANAGER:RegisterForEvent("ZO_CharacterCreate", EVENT_GLOBAL_MOUSE_UP, OnGlobalMouseUp)
    EVENT_MANAGER:RegisterForEvent("ZO_CharacterCreate", EVENT_CHARACTER_CREATE_ZOOM_CHANGED, ZO_CharacterCreate_HandleZoomChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_CharacterCreate", EVENT_LOGOUT_SUCCESSFUL, OnLogoutSuccessful)
    EVENT_MANAGER:RegisterForEvent("ZO_CharacterCreate", EVENT_CHARACTER_CREATED, OnCharacterCreated)          
    EVENT_MANAGER:RegisterForEvent("ZO_CharacterCreate", EVENT_CHARACTER_CREATE_FAILED, OnCharacterCreateFailed)

    CALLBACK_MANAGER:RegisterCallback("OnCharacterConstructionReady", OnCharacterConstructionReady)
    CALLBACK_MANAGER:RegisterCallback("CharacterCreateRequested", OnCharacterCreateRequested)

    CHARACTER_CREATE_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CharacterCreate, 300)
end

function ZO_CharacterCreate_HandleZoomChanged(eventCode, zoomInAllowed, zoomOutAllowed)
    ZO_CharacterCreateZoomIn:SetEnabled(zoomInAllowed)
    ZO_CharacterCreateZoomOut:SetEnabled(zoomOutAllowed)
end

local function ResetNameEdit(nameEdit)
    nameEdit:TakeFocus() -- Fix an issue where the animated name text wouldn't display
    nameEdit:SetText("")
    nameEdit:LoseFocus()    
end

function ZO_CharacterCreate_Reset()
    if(not IsPregameCharacterConstructionReady()) then return end -- Sanity check
    SetSuppressCharacterChanges(true) -- this will be disabled later, right before controls are initialized
    SetCharacterManagerMode(CHARACTER_MODE_CREATION)
    ResetNameEdit(ZO_CharacterCreateCharacterName)    

    local defaultTemplate = GetDefaultTemplate()
    local controlsInitialized = false
    if(defaultTemplate > 0) then
        controlsInitialized = SetTemplate(defaultTemplate)
    else
        UpdateSelectedTemplateText()
        controlsInitialized = ZO_CharacterCreate_GenerateRandomCharacter()
    end

    if(not controlsInitialized) then
        g_manager:InitializeControls()
    end

    g_bucketManager:SwitchBuckets(CREATE_BUCKET_RACE)
    g_bucketManager:UpdateControlsFromData()

    g_characterStartLocation = nil
    g_shouldBePromptedForTutorialSkip = true
    g_characterCreateOption = CHARACTER_CREATE_DEFAULT_LOCATION

    SetCharacterCameraZoomAmount(-1) -- zoom all the way out when a reset happens
end

function ZO_CharacterCreate_DoCreate(startLocation, createOption)
    local characterName = ZO_CharacterCreateCharacterName:GetText()
    local requestSkipTutorial = createOption == CHARACTER_CREATE_SKIP_TUTORIAL
    g_characterCreateOption = createOption
    CreateCharacter(characterName, requestSkipTutorial)
    g_characterStartLocation = startLocation or CHARACTER_OPTION_EXISTING_AREA
    CALLBACK_MANAGER:FireCallbacks("CharacterCreateRequested")
end

function ZO_CharacterCreate_OnCreateButtonClicked(startLocation)
    local characterName = ZO_CharacterCreateCharacterName:GetText()
    
    if characterName and #characterName > 0 then
        if g_shouldBePromptedForTutorialSkip and CanSkipTutorialArea() and startLocation ~= CHARACTER_OPTION_CLEAN_TEST_AREA and startLocation ~= "CharacterSelect_FromIngame" then
            g_shouldBePromptedForTutorialSkip = false
            local genderDecoratedCharacterName = GetGrammarDecoratedName(characterName, CharacterCreateGetGender())
            ZO_Dialogs_ShowDialog("CHARACTER_CREATE_SKIP_TUTORIAL", { startLocation = startLocation }, {mainTextParams = { genderDecoratedCharacterName }})
        else
            ZO_CharacterCreate_DoCreate(startLocation, g_characterCreateOption)
        end
    end
end

local function ValidateNameText(editControl)
    local nameText = editControl:GetText()    
    local nameViolations = { IsValidCharacterName(nameText) }
    local nameIsValid = (#nameViolations == 0)

    if(nameIsValid) then
        editControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
    else
        editControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_FAILED))
    end

    local oldPos = editControl:GetCursorPosition()
    editControl:SetText(CorrectCharacterNameCase(nameText))
    editControl:SetCursorPosition(oldPos)

    return nameIsValid, nameViolations
end

function ZO_CharacterCreate_CheckEnableCreateButton(editControl)
    -- Validation changes the text in the edit control, which causes this to be called again, bail if we're already validating to avoid recursion.
    if(editControl.validating) then return end
    editControl.validating = true

    local isValidName, nameViolations = ValidateNameText(editControl)

    if(isValidName) then
        editControl.linkedButton:SetState(BSTATE_NORMAL, false)
        editControl.linkedInstructions:Hide()
    else
        editControl.linkedButton:SetState(BSTATE_DISABLED, true)

        if(editControl:HasFocus()) then
            editControl.linkedInstructions:Show(editControl, nameViolations)
        else
            editControl.linkedInstructions:Hide()
        end
    end

    CALLBACK_MANAGER:FireCallbacks("OnCharacterCreateNameChanged", isValidName)
    editControl.validating = nil
end

function ZO_CharacterCreate_OnNameFieldFocusGained(editControl)
    GetControl(editControl, "Instructions"):SetHidden(true)
    ZO_CharacterCreate_CheckEnableCreateButton(editControl)
end

function ZO_CharacterCreate_OnNameFieldFocusLost(editControl)
    if(#editControl:GetText() == 0) then
        GetControl(editControl, "Instructions"):SetHidden(false)
    end
    editControl.linkedInstructions:Hide()
end

function ZO_CharacterCreate_GetStartLocation()
    return g_characterStartLocation
end

function ZO_CharacterCreate_BucketMouseEnter(tabButton)
    g_bucketManager:MouseOverBucket(tabButton)
end

function ZO_CharacterCreate_BucketMouseExit(tabButton)
    g_bucketManager:MouseExitBucket(tabButton)
end

function ZO_CharacterCreate_BucketClicked(tabButton)
    g_bucketManager:SwitchBuckets(tabButton)
end

function ZO_CharacterCreate_OnSelectorClicked(button)
    local selectorClickHandlers =
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
                            g_manager:SetAlliance(button.defId)
                            UpdateRaceControl()
                        end,
    }

    local fn = selectorClickHandlers[button.selectorType]
    if(fn) then
        OnCharacterCreateOptionChanged()
        fn(button)
    end
end

function ZO_CharacterCreate_MouseEnterNamedSelector(button)
    InitializeTooltip(InformationTooltip, button, TOPRIGHT, 0, 0, TOPLEFT)

    if(button.name) then
        SetTooltipText(InformationTooltip, zo_strformat(button.tooltipFormatter, button.name))
    elseif(button.nameFn) then
        SetTooltipText(InformationTooltip, zo_strformat(button.tooltipFormatter, button.nameFn(CharacterCreateGetGender(), button.defId)))
    end
end

function ZO_CharacterCreate_MouseExitNamedSelector(button)
    ClearTooltip(InformationTooltip)
end

function ZO_CharacterCreateSelectGender(button)
    OnCharacterCreateOptionChanged()
    g_manager:SetGender(button.gender)
end

function ZO_CharacterCreate_TogglePadlock(button)
    button:GetParent().m_sliderObject:ToggleLocked()
end

function ZO_CharacterCreate_SetSlider(slider, value)
    OnCharacterCreateOptionChanged()
    slider:GetParent().m_sliderObject:SetValue(value)
end

function ZO_CharacterCreate_ChangeSlider(slider, changeAmount)
    OnCharacterCreateOptionChanged()
    slider:GetParent().m_sliderObject:ChangeValue(changeAmount)
end

function ZO_CharacterCreate_ChangePanel(direction)
    local currentTab = g_bucketManager:GetCurrentTab()
    if(currentTab) then
        g_bucketManager:SwitchBuckets(currentTab.m_windowData[direction])
    end
end

function ZO_CharacterCreate_CreateSlider(sliderControl, sliderType)
    if(sliderType == "slider") then
        CharacterCreateSlider:New(sliderControl)
    elseif(sliderType == "icon") then
        CharacterCreateAppearanceSlider:New(sliderControl)
    elseif(sliderType == "color") then
        CharacterCreateColorSlider:New(sliderControl)
    elseif(sliderType == "named") then
        CharacterCreateDropdownSlider:New(sliderControl)
    end
end

function ZO_CharacterCreate_CreateTriangle(control, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)
    local triangle = CharacterCreateTriangle:New(control, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)
    triangle:SetOnValueChangedCallback(OnCharacterCreateOptionChanged)
end

function ZO_CharacterCreate_PreviewClicked(previewButton)
    local slider = previewButton:GetParent()
    slider.m_sliderObject:Preview()
end
