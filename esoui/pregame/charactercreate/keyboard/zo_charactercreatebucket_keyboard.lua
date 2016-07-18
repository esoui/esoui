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
                            if not ZO_CHARACTERCREATE_MANAGER:GetPlayingTransitionAnimations() then
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

--[[ Character Create Bucket ]]--

ZO_CharacterCreateBucket_Keyboard = ZO_CharacterCreateBucket_Base:Subclass()

function ZO_CharacterCreateBucket_Keyboard:New(...)
    return ZO_CharacterCreateBucket_Base.New(self, ...)
end

function ZO_CharacterCreateBucket_Keyboard:Initialize(...)
    ZO_CharacterCreateBucket_Base.Initialize(self, ...)

    local windowData = CREATE_BUCKET_WINDOW_DATA[self.category]
    local container = CreateControlFromVirtual(windowData.windowName, self.parent, "ZO_CharacterCreateCategoryBucket_Keyboard")
    local tabControl = self:CreateTabControl(windowData)

    tabControl.bucket = self
    container.bucket = self

    self.windowData = windowData
    self.container = container
    self.tab = tabControl
    self.scrollChild = GetControl(container, "PaneScrollChild")
    self.subcategoryContainers = {}

    -- Create a spacer control to keep the contents of the scroll panel centered
    -- since scrolling operates by setting the topleft anchor of the scrollChild
    -- window.
    local widthSpacer = self.scrollChild:CreateControl("$(parent)WidthSpacer", CT_CONTROL)
    widthSpacer:SetWidth(360)
    widthSpacer:SetAnchor(TOP)

    -- Create another spacer to pad out the bottom so that the full contents of the pane
    -- can be scrolled into view.  This will need to be reanchored to each control that gets 
    -- added to the bucket.
    self.viewSpacer = self.scrollChild:CreateControl("$(parent)ViewSpacer", CT_CONTROL)
    self.viewSpacer:SetDimensions(360, 10)
end

function ZO_CharacterCreateBucket_Keyboard:CreateTabControl(windowData)
    local tabControl = CreateControlFromVirtual(windowData.windowName .. "Tab", self.parent, "ZO_CharacterCreateCategoryTab_Keyboard")

    tabControl:SetNormalTexture(windowData.tabNormal)
    tabControl:SetMouseOverTexture(windowData.tabMouseOver)
    tabControl:SetPressedTexture(windowData.tabPressed)

    tabControl.windowData = windowData

    tabControl:SetHandler("OnMouseUp", function(tabControl, button, upInside)
        if upInside then
            self.manager:SwitchBuckets(tabControl)
        end
    end)

    tabControl:SetHandler("OnMouseEnter", function(tabControl)
        self:MouseEnter()
    end)

    tabControl:SetHandler("OnMouseExit", function(tabControl)
        self:MouseExit()
    end)

    return tabControl
end

function ZO_CharacterCreateBucket_Keyboard:GetTab()
    return self.tab
end

function ZO_CharacterCreateBucket_Keyboard:AddSubCategories()
    local windowData = self.windowData

    if windowData.subCategoryData then
        if not self.subCategories then
            self.subCategories = {}
        end

        for subCatIndex, subCatData in ipairs(windowData.subCategoryData) do
            local subCategoryObj = self.subCategories[subCatData.id]
            if not subCategoryObj then
                subCategoryObj = ZO_CharacterCreateBucketSubcategory_Keyboard:New(windowData, subCatData, self:GetScrollChild())
                self.subCategories[subCatData.id] = subCategoryObj
            end

            local subCategoryContainer = subCategoryObj:GetControl()
            subCategoryContainer:SetHidden(false)
            table.insert(self.subcategoryContainers, subCategoryContainer)

            self:AddControl(subCategoryContainer, nil, nil, nil, subCatData.anchorYOffsetOverride)
        end
    end
end

function ZO_CharacterCreateBucket_Keyboard:RemoveUnusedSubCategories()
    local windowData = self.windowData

    if windowData.subCategoryData and self.subCategories then
        for subCatIndex, subCatData in ipairs(windowData.subCategoryData) do
            local subCategoryObj = self.subCategories[subCatData.id]
            if subCategoryObj and subCategoryObj:IsEmpty() then
                local subCategoryContainer = subCategoryObj:GetControl()

                -- Grab the subcategory after this one and anchor it to the current 
                local nextSubCatControl = self.subcategoryContainers[subCatIndex + 1]
                if nextSubCatControl then
                    local valid, point, relTo, relPoint, offsX, offsY = subCategoryContainer:GetAnchor(0)

                    if valid then
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

function ZO_CharacterCreateBucket_Keyboard:AddControl(control, updateFn, randomizeFn, subCategoryId, anchorYOffsetOverride)
    control.bucket = self
    control:ClearAnchors()
    control:SetHidden(false)

    if subCategoryId and self.subCategories and self.subCategories[subCategoryId] then
        self.subCategories[subCategoryId]:AddControl(control)
    else
        control:SetParent(self:GetScrollChild())

        anchorYOffsetOverride = anchorYOffsetOverride or 0

        if self.lastAnchored then
            control:SetAnchor(TOP, self.lastAnchored, BOTTOM, 0, 20 + anchorYOffsetOverride)
        else
            -- using a little vertical padding so controls with backdrops don't overlap at the top
            -- NOTE: Do not use override here, if it were negative it could easily push this control out of the window
            control:SetAnchor(TOP, self:GetScrollChild(), TOP, 0, 5)
        end

        self.lastAnchored = control

        self.viewSpacer:ClearAnchors()
        self.viewSpacer:SetAnchor(TOP, self.lastAnchored, BOTTOM, 0, 0)
    end

    self.controlData[control] = { updateFn = updateFn, randomizeFn = randomizeFn }
end

function ZO_CharacterCreateBucket_Keyboard:RemoveControl(control)
    -- Once a control is removed from a bucket it's no longer safe to add controls
    -- unless the bucket is totally reset (this is because of how lastAnchored works)
    -- This just cleans up the control and removes any lingering update handlers
    -- All the controls will be re-added to the bucket at some point.
    self.lastAnchored = nil

    control.bucket = nil
    self.controlData[control] = nil
end

function ZO_CharacterCreateBucket_Keyboard:Reset()
    self.expanded = false
    self.controlData = {}
    self.lastAnchored = nil
    self.subcategoryContainers = {}

    if self.subCategories then
        for _, subCategoryObj in pairs(self.subCategories) do
            subCategoryObj:Reset()
        end
    end
end

function ZO_CharacterCreateBucket_Keyboard:Expand()
    local container = self:GetContainer()
    container:SetHidden(false)
    self:GetTab():SetState(BSTATE_PRESSED, true)
    self.expanded = true
    
    local expandFn = self.windowData.onExpandFn
    if expandFn then
        expandFn()
    end
end

function ZO_CharacterCreateBucket_Keyboard:Collapse()
    self:GetContainer():SetHidden(true)
    self:GetTab():SetState(BSTATE_NORMAL, false)
    self.expanded = false

    local collapseFn = self.windowData.onCollapseFn
    if collapseFn then
        collapseFn()
    end
end

function ZO_CharacterCreateBucket_Keyboard:IsExpanded()
    return self.expanded
end

function ZO_CharacterCreateBucket_Keyboard:MouseEnter()
    InitializeTooltip(InformationTooltip, self:GetTab(), TOPRIGHT, 0, 0, TOPLEFT)
    SetTooltipText(InformationTooltip, self.windowData.title)
end

function ZO_CharacterCreateBucket_Keyboard:MouseExit()
    ClearTooltip(InformationTooltip)
end

--[[ Character Create Bucket Subcategory ]]--

ZO_CharacterCreateBucketSubcategory_Keyboard = ZO_Object:Subclass()

function ZO_CharacterCreateBucketSubcategory_Keyboard:New(bucketWindowData, subCategoryData, parent)
    local subCategory = ZO_Object.New(self)

    local subCategoryWindowName = string.format("%sSub%d", bucketWindowData.windowName, subCategoryData.id)
    local subCategoryControl = CreateControlFromVirtual(subCategoryWindowName, parent, "ZO_CharacterCreateSubCategoryBucket_Keyboard")

    subCategory.control = subCategoryControl

    GetControl(subCategoryControl, "Name"):SetText(GetString("SI_CHARACTERSLIDERSUBCATEGORY", subCategoryData.id))
    return subCategory
end

function ZO_CharacterCreateBucketSubcategory_Keyboard:GetControl()
    return self.control
end

function ZO_CharacterCreateBucketSubcategory_Keyboard:AddControl(control)
    control:SetParent(self:GetControl())

    if self.lastAnchored then
        control:SetAnchor(TOP, self.lastAnchored, BOTTOM, 0, 20)
    else
        control:SetAnchor(TOP, GetControl(self.control, "TopSpacer"), BOTTOM)
    end 
        
    self.lastAnchored = control
end

function ZO_CharacterCreateBucketSubcategory_Keyboard:Reset()
    self.lastAnchored = nil
end

function ZO_CharacterCreateBucketSubcategory_Keyboard:IsEmpty()
    return self.lastAnchored == nil
end

--[[ Character Creation Bucket Manager ]]--

local CHARACTER_CREATE_BUCKETS = {
    CREATE_BUCKET_RACE,
    CREATE_BUCKET_CLASS,
    CREATE_BUCKET_BODY,
    CREATE_BUCKET_FACE,
}

ZO_CharacterCreateBucketManager_Keyboard = ZO_CharacterCreateBucketManager_Base:Subclass()

function ZO_CharacterCreateBucketManager_Keyboard:New(container)
    return ZO_CharacterCreateBucketManager_Base.New(self, container, CHARACTER_CREATE_BUCKETS)
end

function ZO_CharacterCreateBucketManager_Keyboard:AddBucket(bucketCategory)
    local bucket = ZO_CharacterCreateBucket_Keyboard:New(self.container, bucketCategory, self)
    local bucketContainer = bucket:GetContainer()

    bucketContainer:SetAnchor(TOPLEFT, self.container, TOPLEFT, 13, 138)
    bucketContainer:SetAnchor(BOTTOMRIGHT, self.container, BOTTOMRIGHT, -14, -73)

    self.buckets[bucketCategory] = bucket

    local tabControl = bucket:GetTab()
    if self.lastAnchoredTab then
        tabControl:SetAnchor(TOPLEFT, self.lastAnchoredTab, TOPRIGHT, 12, 0)
    else
        tabControl:SetAnchor(TOPLEFT, self.container, TOPLEFT, 62, 20)
    end

    self.lastAnchoredTab = tabControl
end

function ZO_CharacterCreateBucketManager_Keyboard:SwitchBuckets(tabButtonOrCategory)
    -- collapse current bucket
    if self.currentBucket then
        self.currentBucket:Collapse()
    end

    -- expand desired bucket
    local bucket
    if type(tabButtonOrCategory) == "number" then
        bucket = self:BucketForCategory(tabButtonOrCategory)
    else
        bucket = self:BucketForChildControl(tabButtonOrCategory)
    end

    if bucket then
        bucket:Expand()
        self.currentBucket = bucket
    end
end

function ZO_CharacterCreateBucketManager_Keyboard:GetCurrentTab()
    if self.currentBucket then
        return self.currentBucket:GetTab()
    end
end

function ZO_CharacterCreateBucketManager_Keyboard:EnableBucketTab(bucketCategory, enabled)
    local bucket = self.buckets[bucketCategory]
    local tabControl = bucket:GetTab()

    local saturation = 1
    if enabled then
        saturation = 0
    end

    tabControl:SetEnabled(enabled)
    tabControl:SetDesaturation(saturation)
end

function ZO_CharacterCreateBucketManager_Keyboard:AddSubCategories()
    for _, bucket in pairs(self.buckets) do
        bucket:AddSubCategories()
    end
end

function ZO_CharacterCreateBucketManager_Keyboard:RemoveUnusedSubCategories()
    for _, bucket in pairs(self.buckets) do
        bucket:RemoveUnusedSubCategories()
    end
end