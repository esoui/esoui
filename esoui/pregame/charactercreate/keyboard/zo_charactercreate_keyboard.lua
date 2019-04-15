local KEYBOARD_BUCKET_MANAGER

--[[ Slider Randomization Helper...all sliders share the sliderObject from the top control, so this just helps cut down on duplicate functions ]]--
local function RandomizeSlider(control, randomizeType)
    control.sliderObject:Randomize(randomizeType)
end

--[[ Character Create Slider and Appearance Slider Managers ]]--
-- Manages a collection of sliders with a pool

local CharacterCreateSliderManager = ZO_Object:Subclass()

function CharacterCreateSliderManager:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function CharacterCreateSliderManager:Initialize(parent)
    local CreateSlider =    function(pool)
                                local control = ZO_ObjectPool_CreateNamedControl("CharacterCreateSlider", "ZO_CharacterCreateSlider_Keyboard", pool, parent)
                                return ZO_CharacterCreateSlider_Keyboard:New(control)
                            end

    local CreateAppearanceSlider =  function(pool)
                                        local control = ZO_ObjectPool_CreateNamedControl("CharacterCreateAppearanceSlider", "ZO_CharacterCreateSlider_Keyboard", pool, parent)
                                        return ZO_CharacterCreateAppearanceSlider_Keyboard:New(control)
                                    end

    local CreateColorPicker =   function(pool)
                                    local control = ZO_ObjectPool_CreateNamedControl("CharacterCreateColorPicker", "ZO_CharacterCreateColorSlider_Keyboard", pool, parent)
                                    return ZO_CharacterCreateColorSlider_Keyboard:New(control)
                                end

    local CreateDropdown =  function(pool)
                                local control = ZO_ObjectPool_CreateNamedControl("CharacterCreateDropdown", "ZO_CharacterCreateDropDownSlider_Keyboard", pool, parent)
                                return ZO_CharacterCreateDropdownSlider_Keyboard:New(control)
                            end

    local function ResetSlider(slider)
        local sliderControl = slider.control
        KEYBOARD_BUCKET_MANAGER:RemoveControl(sliderControl)
        sliderControl:SetHidden(true)
        if slider:IsLocked() then
            slider:ToggleLocked()
        end
    end

    local function ResetColorPicker(slider)
        local sliderControl = slider.control
        KEYBOARD_BUCKET_MANAGER:RemoveControl(sliderControl)
        ZO_ColorSwatchPicker_Clear(GetControl(sliderControl, "Slider"))
        sliderControl:SetHidden(true)
        if slider:IsLocked() then
            slider:ToggleLocked()
        end
    end

    self.pools =
    {
        [CHARACTER_CREATE_SLIDER_TYPE_SLIDER] = ZO_ObjectPool:New(CreateSlider, ResetSlider),
        [CHARACTER_CREATE_SLIDER_TYPE_ICON] = ZO_ObjectPool:New(CreateAppearanceSlider, ResetSlider),
        [CHARACTER_CREATE_SLIDER_TYPE_COLOR] = ZO_ObjectPool:New(CreateColorPicker, ResetColorPicker),
        [CHARACTER_CREATE_SLIDER_TYPE_NAMED] = ZO_ObjectPool:New(CreateDropdown, ResetSlider),
    }
end

function CharacterCreateSliderManager:AcquireObject(objectType)
    local pool = self.pools[objectType]
    if pool then
        return pool:AcquireObject()
    end
end

function CharacterCreateSliderManager:ReleaseAllObjects()
    for poolType, pool in pairs(self.pools) do
        pool:ReleaseAllObjects()
    end
end

--[[ Creator Control Initialization ]]--

local function FindOrdering(orderingTable, name)
    for i = 1, #orderingTable do
        if orderingTable[i] == name then
            return i
        end
    end

    return 1
end

--[[ Character Create Keyboard ]]--

local ZO_CharacterCreate_Keyboard = ZO_CharacterCreate_Base:Subclass()

function ZO_CharacterCreate_Keyboard:New(...)
    return ZO_CharacterCreate_Base.New(self, ...)
end

function ZO_CharacterCreate_Keyboard:Initialize(...)
    ZO_CharacterCreate_Base.Initialize(self, ...)

    local function HandleZoomChanged(eventCode, zoomInAllowed, zoomOutAllowed)
        ZO_CharacterCreateZoomIn:SetEnabled(zoomInAllowed)
        ZO_CharacterCreateZoomOut:SetEnabled(zoomOutAllowed)
    end

    EVENT_MANAGER:RegisterForEvent("ZO_CharacterCreate", EVENT_CHARACTER_CREATE_ZOOM_CHANGED, HandleZoomChanged)

    CHARACTER_CREATE_FRAGMENT = ZO_FadeSceneFragment:New(self.control, 300)

    self:InitializeSkipTutorialDialog()
end

function ZO_CharacterCreate_Keyboard:OnCharacterCreateRequested()
    self.createButton:SetEnabled(false)
end

do
    local reasonsThatDisableCreateButton =
    {
        [CHARACTER_CREATE_EDIT_ERROR_INVALID_NAME] = true,
        [CHARACTER_CREATE_EDIT_ERROR_DUPLICATE_NAME] = true,
        [CHARACTER_CREATE_EDIT_ERROR_NAME_TOO_SHORT] = true,
        [CHARACTER_CREATE_EDIT_ERROR_NAME_TOO_LONG] = true,
    }

    function ZO_CharacterCreate_Keyboard:OnCharacterCreateFailed(reason)
        local errorReason = GetString("SI_CHARACTERCREATEEDITERROR", reason)
    
        -- Show the fact that the character could not be created.
        ZO_Dialogs_ShowDialog("CHARACTER_CREATE_FAILED_REASON", nil, {mainTextParams = {errorReason}})

        if reasonsThatDisableCreateButton[reason] then
            self.createButton:SetEnabled(false)
        end
    end
end

do
    local function CreateTriangle(control, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)
        local triangle = ZO_CharacterCreateTriangle_Keyboard:New(control, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)
        triangle:SetOnValueChangedCallback(OnCharacterCreateOptionChanged)
        return triangle
    end

    function ZO_CharacterCreate_Keyboard:InitializeControls()
        self.control.fadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CharacterCreateMainControlsFade", self.control)

        self.bucketsControl = self.control:GetNamedChild("Buckets")

        self.sliderManager = CharacterCreateSliderManager:New(self.bucketsControl)

        -- create the radio button groups
        self.allianceRadioGroup = ZO_RadioButtonGroup:New()
        self.raceRadioGroup = ZO_RadioButtonGroup:New()
        self.classRadioGroup = ZO_RadioButtonGroup:New()
        self.genderRadioGroup = ZO_RadioButtonGroup:New()

        -- create the triangle controls
        local physiqueTriangleControl = CreateControlFromVirtual("$(parent)PhysiqueSelection", self.control, "ZO_CharacterCreateTriangleTemplate_Keyboard")
        self.physiqueTriangle = CreateTriangle(physiqueTriangleControl, SetPhysique, GetPhysique, SI_CREATE_CHARACTER_BODY_TRIANGLE_LABEL, SI_CREATE_CHARACTER_TRIANGLE_MUSCULAR, SI_CREATE_CHARACTER_TRIANGLE_FAT, SI_CREATE_CHARACTER_TRIANGLE_THIN)

        local faceTriangleControl = CreateControlFromVirtual("$(parent)FaceSelection", self.control, "ZO_CharacterCreateTriangleTemplate_Keyboard")
        self.faceTriangle = CreateTriangle(faceTriangleControl, SetFace, GetFace, SI_CREATE_CHARACTER_FACE_TRIANGLE_LABEL, SI_CREATE_CHARACTER_TRIANGLE_FACE_MUSCULAR, SI_CREATE_CHARACTER_TRIANGLE_FACE_FAT, SI_CREATE_CHARACTER_TRIANGLE_FACE_THIN)

        -- setup the create button and link it to the name control
        self.createButton = self.control:GetNamedChild("CreateButton")
        self.createButton:SetEnabled(false)

        self.instructionsControl = self.control:GetNamedChild("NameInstructions")
        self.nameInstructionsObject = ZO_ValidNameInstructions:New(self.instructionsControl)

        self.nameControl = self.control:GetNamedChild("CharacterName")
        SetupEditControlForNameValidation(self.nameControl)
        self.nameControl.linkedButton = self.createButton
        self.nameControl.linkedInstructions = self.nameInstructionsObject

        self.saveButton = self.control:GetNamedChild("SaveButton")

        self.templateControl = self.control:GetNamedChild("Template")
    end
end

function ZO_CharacterCreate_Keyboard:InitializeSelectorButtonTextures(buttonControl, data)
    buttonControl:SetNormalTexture(data.normalIcon)
    buttonControl:SetPressedTexture(data.pressedIcon)
    buttonControl:SetMouseOverTexture(data.mouseoverIcon)
end

function ZO_CharacterCreate_Keyboard:InitializeSelectors()
    self:InitializeGenderSelector()
    self:InitializeAllianceSelectors()
    self:InitializeRaceSelectors()
    self:InitializeClassSelectors()
    self:InitializeTemplateList()
end

function ZO_CharacterCreate_Keyboard:InitializeAllianceSelectors()
    local layoutTable =
    {
        ZO_CharacterCreateRaceAllianceSelector1,
        ZO_CharacterCreateRaceAllianceSelector2,
        ZO_CharacterCreateRaceAllianceSelector3,
    }

    local alliances = self.characterData:GetAllianceInfo()
    for _, alliance in ipairs(alliances) do
        local selector = layoutTable[alliance.position]
        self:InitializeAllianceSelector(selector, alliance)
    end
end

function ZO_CharacterCreate_Keyboard:InitializeRaceSelectors()
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

    local races = self.characterData:GetRaceInfo()
    for _, race in ipairs(races) do
        local raceButton = layoutTable[race.position]
        self:InitializeSelectorButton(raceButton, race, self.raceRadioGroup)
        self:AddRaceSelectionDataToSelector(raceButton, race)
    end
end

function ZO_CharacterCreate_Keyboard:InitializeGenderSelector()
    ZO_CharacterCreateGenderSelectionMaleLabel:SetText(GetString("SI_GENDER", GENDER_MALE))
    ZO_CharacterCreateGenderSelectionFemaleLabel:SetText(GetString("SI_GENDER", GENDER_FEMALE))

    ZO_CharacterCreateGenderSelectionMaleButton.gender = GENDER_MALE
    ZO_CharacterCreateGenderSelectionFemaleButton.gender = GENDER_FEMALE

    self.genderRadioGroup:Add(ZO_CharacterCreateGenderSelectionMaleButton)
    self.genderRadioGroup:Add(ZO_CharacterCreateGenderSelectionFemaleButton)
end

function ZO_CharacterCreate_Keyboard:InitializeTemplateList()
    local comboBox = ZO_ComboBox_ObjectFromContainer(self.templateControl)
    comboBox:ClearItems()
    comboBox:SetSortsItems(false)
    comboBox:SetFont("ZoFontGame")
    comboBox:SetSpacing(4)

    local function OnTemplateChanged(comboBox, entryText, entry)
        if self:SetTemplate(entry.templateData.template) then
            KEYBOARD_BUCKET_MANAGER:UpdateControlsFromData()
        end
    end

    local defaultTemplate = GetDefaultTemplate()

    local function SelectDefaultTemplate(entry)
        return entry.templateData.template == defaultTemplate
    end

    local templatesAllowed = GetTemplateStatus()
    if templatesAllowed then
        local templates = self.characterData:GetTemplateInfo()

        for _, templateData in ipairs(templates) do
            if templateData.isSelectable then
                local entry = comboBox:CreateItemEntry(templateData.name, OnTemplateChanged)
                entry.templateData = templateData
                comboBox:AddItem(entry)
            end
        end

        if not comboBox:SetSelectedItemByEval(SelectDefaultTemplate) then
            comboBox:SelectFirstItem()
        end

        self.templateControl:SetHidden(false)
    else
        self.templateControl:SetHidden(true)
    end
end

function ZO_CharacterCreate_Keyboard:InitializeSkipTutorialDialog()
    local control = ZO_CharacterCreateSkipTutorialDialog
    ZO_Dialogs_RegisterCustomDialog("CHARACTER_CREATE_SKIP_TUTORIAL",
    {
        customControl = control,
        canQueue = true,
        title =
        {
            text = SI_PROMPT_TITLE_SKIP_TUTORIAL,
        },
        mainText = 
        {
            text = SI_PROMPT_BODY_SKIP_TUTORIAL,
        },
        noChoiceCallback =  function(dialog)
                                ZO_CHARACTERCREATE_MANAGER:SetShouldPromptForTutorialSkip(true)
                            end,
        buttons =
        {
            {
                control = GetControl(control, "Play"),
                text = SI_PROMPT_PLAY_TUTORIAL_BUTTON,
                keybind = "DIALOG_PRIMARY",
                callback =  function(dialog)
                                self:CreateCharacter(dialog.data.startLocation, CHARACTER_CREATE_DEFAULT_LOCATION)
                            end,
            },

            {
                control = GetControl(control, "Skip"),
                text = SI_PROMPT_SKIP_TUTORIAL_BUTTON,
                keybind = "DIALOG_SECONDARY",
                callback =  function(dialog)
                                self:CreateCharacter(dialog.data.startLocation, CHARACTER_CREATE_SKIP_TUTORIAL)
                            end,
            },

            {
                control = GetControl(control, "Back"),
                text = SI_PROMPT_BACK_TUTORIAL_BUTTON,
                keybind = "DIALOG_NEGATIVE",
                callback =  function(dialog)
                                ZO_CHARACTERCREATE_MANAGER:SetShouldPromptForTutorialSkip(true)
                            end,
            },
        }
    })
end

function ZO_CharacterCreate_Keyboard:SetTemplate(templateId)
    local templateData = self.characterData:GetTemplate(templateId)
    if not templateData then
        return false
    end

    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    if not templateData.isSelectable or CharacterCreateGetTemplate(characterMode) == templateId then
        return false
    end

    CharacterCreateSetTemplate(templateId)

    KEYBOARD_BUCKET_MANAGER:SwitchBuckets(CREATE_BUCKET_RACE)

    -- Disable appearance related controls if the appearance is overridden in the template.
    local enabled = not templateData.overrideAppearance
    KEYBOARD_BUCKET_MANAGER:EnableBucketTab(CREATE_BUCKET_BODY, enabled)
    KEYBOARD_BUCKET_MANAGER:EnableBucketTab(CREATE_BUCKET_FACE, enabled)

    ZO_CharacterCreateRandomizeAppearance:SetEnabled(enabled)

    local validRaces = {}
    self:UpdateSelectorsForTemplate(function(...) return self:UpdateRaceSelectorsForTemplate(...) end, self.characterData:GetRaceInfo(), templateData, self.raceRadioGroup, validRaces)
    self:UpdateSelectorsForTemplate(function(...) return self:UpdateClassSelectorsForTemplate(...) end, self.characterData:GetClassInfo(), templateData, self.classRadioGroup)

    local validAlliances = {}
    self.characterData:UpdateAllianceSelectability()
    self:UpdateSelectorsForTemplate(function(...) return self:UpdateAllianceSelectorsForTemplate(...) end, self.characterData:GetAllianceInfo(), templateData, self.allianceRadioGroup, validAlliances)

    self.genderRadioGroup:SetEnabled(templateData.gender == 0)
    
    -- Pick a race
    if templateData.race ~= 0 then
        CharacterCreateSetRace(templateData.race)
    else
        CharacterCreateSetRace(self.characterData:PickRandomRace(validRaces))
    end

    -- Pick an alliance 
    if templateData.alliance ~= 0 then
        ZO_CharacterCreate_SetAlliance(templateData.alliance)
    else
        -- (never random unless a race without a fixed alliance is picked)
        local alliance = self.characterData:GetRaceForRaceDef(CharacterCreateGetRace(characterMode)).alliance
        if alliance ~= 0 then
            ZO_CharacterCreate_SetAlliance(alliance)
        else
            ZO_CharacterCreate_SetAlliance(self.characterData:PickRandomAlliance(validAlliances))
        end
    end

    -- Pick a class
    if templateData.class ~= 0 then
        CharacterCreateSetClass(templateData.class)
    else
        -- UpdateSelectorsForTemplate() should be called prior to this function or unselectable classes might be set (which would result in no class being set).
        self:PickRandomSelectableClass()
    end

    -- Pick a gender
    if templateData.gender ~= 0 then
        CharacterCreateSetGender(templateData.gender)
    else
        self:PickRandomGender()
    end

    -- Make the controls match what you picked...
    KEYBOARD_CHARACTER_CREATE_MANAGER:ResetControls()
    if not templateData.overrideAppearance then
        ZO_CharacterCreate_RandomizeAppearance("initial")
    else
        InitializeAppearanceFromTemplate(templateId)
    end
    return true
end

function ZO_CharacterCreate_Keyboard:InitializeClassSelectors()
        local classes = self.characterData:GetClassInfo()
        if #classes > CHARACTER_CREATE_MAX_SUPPORTED_CLASSES then
            -- this assert is duplicated from the gamepad UI so that non-console builds will catch the issue as well
            local errorString = string.format("The gamepad UI currently only supports up to %d classes, but there are currently %d classes used", CHARACTER_CREATE_MAX_SUPPORTED_CLASSES, #classes)
            internalassert(false, errorString)
        end

        local parent = ZO_CharacterCreateClassSelectionButtonArea
        local stride = 3
        local padX = 0
        local padY = 0
        local controlWidth = 120
        local controlHeight = 80
        local initialX = 0
        local initialY = 0

        local anchor = ZO_Anchor:New(TOPLEFT, parent, TOPLEFT, initialX, initialY)

        for i, classData in ipairs(classes) do
            local selectorName = "SelectClass" .. classData.class
            local selector = GetControl(selectorName)
            if not selector then
                selector = CreateControlFromVirtual(selectorName, parent, "ClassSelectorButton")
            end

            selector.nameFn = GetClassName
            selector.defId = classData.class

            self:InitializeSelectorButton(selector, classData, self.classRadioGroup)
            ZO_Anchor_BoxLayout(anchor, selector, i - 1, stride, padX, padY, controlWidth, controlHeight, initialX, initialY, GROW_DIRECTION_DOWN_RIGHT)
        end
    end

do
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

    local function SliderComparator(data1, data2)
        local name1 = data1.name
        local name2 = data2.name

        local subCat1 = data1.subCat
        local subCat2 = data2.subCat

        if subCat1 ~= subCat2 then
            return subCat1 < subCat2
        end

        return FindOrdering(CONTROL_ORDERING[subCat1], name1) < FindOrdering(CONTROL_ORDERING[subCat2], name2)
    end

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

    local function UpdateSlider(slider)
        slider.sliderObject:Update()
    end

    function ZO_CharacterCreate_Keyboard:ResetControls()
        -- If this was being suppressed changes MUST be applied now or there will be no slider data to build
        SetSuppressCharacterChanges(false)

        self.sliderManager:ReleaseAllObjects()

        KEYBOARD_BUCKET_MANAGER:Reset()
        KEYBOARD_BUCKET_MANAGER:AddSubCategories()
        KEYBOARD_BUCKET_MANAGER:AddControl(ZO_CharacterCreateGenderSelection, CREATE_BUCKET_RACE, function() self:UpdateGenderControl() end)
        KEYBOARD_BUCKET_MANAGER:AddControl(ZO_CharacterCreateRace, CREATE_BUCKET_RACE, function() self:UpdateRaceControl() end)
        KEYBOARD_BUCKET_MANAGER:AddControl(ZO_CharacterCreateClassSelection, CREATE_BUCKET_CLASS, function() self:UpdateClassControl() end)
        KEYBOARD_BUCKET_MANAGER:AddControl(ZO_CharacterCreatePhysiqueSelection, CREATE_BUCKET_BODY, UpdateSlider, RandomizeSlider, SLIDER_SUBCAT_BODY_TYPE)
        KEYBOARD_BUCKET_MANAGER:AddControl(ZO_CharacterCreateFaceSelection, CREATE_BUCKET_FACE, UpdateSlider, RandomizeSlider, SLIDER_SUBCAT_FACE_TYPE)

        -- TODO: this fixes a bug where the triangles don't reflect the correct data...there will be more fixes to pregameCharacterManager to address the real issue
        -- (where the triangle data needs to live on its own rather than being tied to the unit)
        self.physiqueTriangle:Update()
        self.faceTriangle:Update()

        local sliderData = {}

        for i = 1, GetNumSliders() do
            local name, category, steps, value, defaultValue = GetSliderInfo(i)

            if name then
                local slider = self.sliderManager:AcquireObject(CHARACTER_CREATE_SLIDER_TYPE_SLIDER)
                slider:SetData(i, name, category, steps, value, defaultValue)

                local bucket = SLIDER_CATEGORY_TO_CREATE_BUCKET[category]
                local subCat = SUBCATEGORY_FOR_SLIDER[name]

                sliderData[#sliderData + 1] = { bucket = bucket, subCat = subCat, name = name, control = slider.control, }
            end
        end

        for i = 1, GetNumAppearances() do
            local appearanceName, appearanceType, numValues, displayName = GetAppearanceInfo(i)

            if numValues > 0 then
                local appearanceSlider = self.sliderManager:AcquireObject(appearanceType)
                appearanceSlider:SetData(appearanceName, numValues, displayName)

                local bucket = APPEARANCE_NAME_TO_CREATE_BUCKET[appearanceName]
                local subCat = SUBCATEGORY_FOR_APPEARANCE[appearanceName]

                sliderData[#sliderData + 1] = { bucket = bucket, subCat = subCat, name = appearanceName, control = appearanceSlider.control, }
            end
        end

        table.sort(sliderData, SliderComparator)

        for _, orderingData in ipairs(sliderData) do
            KEYBOARD_BUCKET_MANAGER:AddControl(orderingData.control, orderingData.bucket, UpdateSlider, RandomizeSlider, orderingData.subCat)
        end

        KEYBOARD_BUCKET_MANAGER:RemoveUnusedSubCategories()
    end
end

function ZO_CharacterCreate_Keyboard:ResetNameEdit()
    local nameEdit = self.nameControl
    nameEdit:TakeFocus() -- Fix an issue where the animated name text wouldn't display
    nameEdit:SetText("")
    nameEdit:LoseFocus()
    GetControl(self.nameControl, "Instructions"):SetHidden(false)
end

function ZO_CharacterCreate_Keyboard:Reset()
    -- Sanity check
    if not IsPregameCharacterConstructionReady() then
        return
    end

    SetCharacterCameraZoomAmount(-1) -- zoom all the way out when a reset happens
    SetSuppressCharacterChanges(true) -- this will be disabled later, right before controls are reset

    self:ResetNameEdit()

    local controlsInitialized = false

    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    if characterMode == CHARACTER_MODE_CREATION then
        self:InitializeTemplateList()

        -- assume that we have already initialized the controls because we have set the default template
        controlsInitialized = true
        local defaultTemplate = GetDefaultTemplate()
        if defaultTemplate == 0 then
            -- default template was undefined so see if we generated a new random character
            controlsInitialized = self:GenerateRandomCharacter()
        end
    end

    if not controlsInitialized then
        self:ResetControls()
    end

    KEYBOARD_BUCKET_MANAGER:SwitchBuckets(CREATE_BUCKET_RACE)
    KEYBOARD_BUCKET_MANAGER:UpdateControlsFromData()

    self.characterStartLocation = nil
    ZO_CHARACTERCREATE_MANAGER:SetShouldPromptForTutorialSkip(true)
    self.characterCreateOption = CHARACTER_CREATE_DEFAULT_LOCATION
end

function ZO_CharacterCreate_Keyboard:UpdateGenderSpecificText(currentGender)
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    currentGender = currentGender or CharacterCreateGetGender(characterMode)

    ZO_CharacterCreateRaceName:SetText(zo_strformat(SI_RACE_NAME, GetRaceName(currentGender, CharacterCreateGetRace(characterMode))))
    ZO_CharacterCreateClassSelectionName:SetText(zo_strformat(SI_CLASS_NAME, GetClassName(currentGender, CharacterCreateGetClass(characterMode))))
end

function ZO_CharacterCreate_Keyboard:UpdateRaceControl()
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local currentRace = CharacterCreateGetRace(characterMode)

    local function IsRaceClicked(button)
        return button.defId == currentRace
    end

    self.raceRadioGroup:UpdateFromData(IsRaceClicked)

    local currentAlliance = CharacterCreateGetAlliance(characterMode)

    local function IsAllianceClicked(button)
        return button.defId == currentAlliance
    end

    self.allianceRadioGroup:UpdateFromData(IsAllianceClicked)

    local race = self.characterData:GetRaceForRaceDef(currentRace)
    if race then
        local allianceName, backdropTop, backdropBottom = self:GetCurrentAllianceData()

        self:UpdateGenderSpecificText()

        ZO_CharacterCreateRaceAlliance:SetText(zo_strformat(SI_ALLIANCE_NAME, allianceName))
        ZO_CharacterCreateRaceDescription:SetText(race.lore)

        ZO_CharacterCreateRaceAllianceBG:SetTexture(backdropTop)
        ZO_CharacterCreateRaceAllianceBGBottom:SetTexture(backdropBottom)
    end
end

function ZO_CharacterCreate_Keyboard:UpdateGenderControl()
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local currentGender = CharacterCreateGetGender(characterMode)

    local function IsGenderClicked(button)
        return button.gender == currentGender
    end
    
    self.genderRadioGroup:UpdateFromData(IsGenderClicked)
end

function ZO_CharacterCreate_Keyboard:UpdateClassControl()
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local currentClass = CharacterCreateGetClass(characterMode)

    local function IsClassClicked(button)
        return button.defId == currentClass
    end

    self.classRadioGroup:UpdateFromData(IsClassClicked)

    local class = self.characterData:GetClassForClassDef(currentClass)
    if class then
        self:UpdateGenderSpecificText()
        ZO_CharacterCreateClassSelectionDescription:SetText(class.lore)
    end
end

function ZO_CharacterCreate_Keyboard:OnGenerateRandomCharacter()
    ZO_CharacterCreate_RandomizeAppearance("initial")
end

function ZO_CharacterCreate_Keyboard:CreateCharacter(startLocation, createOption)
    self.characterName = self.nameControl:GetText()
    ZO_CharacterCreate_Base.CreateCharacter(self, startLocation, createOption)
end

function ZO_CharacterCreate_Keyboard:OnCreateButtonClicked(startLocation)
    local characterName = self.nameControl:GetText()
    
    if characterName and #characterName > 0 then
        if ZO_CHARACTERCREATE_MANAGER:GetShouldPromptForTutorialSkip() and CanSkipTutorialArea() and startLocation ~= CHARACTER_OPTION_CLEAN_TEST_AREA and startLocation ~= "CharacterSelect_FromIngame" then
            ZO_CHARACTERCREATE_MANAGER:SetShouldPromptForTutorialSkip(false)
            -- color the character name white so it's highlighted in the dialog
            local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
            local genderDecoratedCharacterName = ZO_SELECTED_TEXT:Colorize(GetGrammarDecoratedName(characterName, CharacterCreateGetGender(characterMode)))
            ZO_Dialogs_ShowDialog("CHARACTER_CREATE_SKIP_TUTORIAL", { startLocation = startLocation }, {mainTextParams = { genderDecoratedCharacterName }})
        else
            self:CreateCharacter(startLocation, self.characterCreateOption)
        end
    end
end

function ZO_CharacterCreate_Keyboard:InitializeForEditChanges(characterInfo, mode)
    self:SetCharacterCreateMode(mode)

    local raceTemplate = characterInfo
    if mode == CHARACTER_CREATE_MODE_EDIT_RACE then
        raceTemplate =  {
                            race = 0,
                            alliance = characterInfo.alliance,
                        }
    end

    self:UpdateSelectorsForTemplate(function(...) return self:UpdateRaceSelectorsForTemplate(...) end, self.characterData:GetRaceInfo(), raceTemplate, self.raceRadioGroup)
    self:UpdateSelectorsForTemplate(function(...) return self:UpdateClassSelectorsForTemplate(...) end, self.characterData:GetClassInfo(), characterInfo, self.classRadioGroup)

    self:UpdateSelectorsForTemplate(function(...) return self:UpdateAllianceSelectorsForTemplate(...) end, self.characterData:GetAllianceInfo(), characterInfo, self.allianceRadioGroup)

    self:Reset()

    self.templateControl:SetHidden(true)

    local name = zo_strformat(SI_CHARACTER_SELECT_NAME, characterInfo.name)
    self.nameControl:SetText(name)
    self.nameControl:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGB())
    GetControl(self.nameControl, "Instructions"):SetHidden(true)
    self.nameControl:SetEditEnabled(false)
    self.nameControl:SetMouseEnabled(false)

    self.saveButton:SetHidden(false)
    self.createButton:SetHidden(true)
end

function ZO_CharacterCreate_Keyboard:InitializeForAppearanceChange(characterInfo)
    self:InitializeForEditChanges(characterInfo, CHARACTER_CREATE_MODE_EDIT_APPEARANCE)
end

function ZO_CharacterCreate_Keyboard:InitializeForRaceChange(characterInfo)
    self:InitializeForEditChanges(characterInfo, CHARACTER_CREATE_MODE_EDIT_RACE)
end

function ZO_CharacterCreate_Keyboard:InitializeForCharacterCreate()
    self:SetCharacterCreateMode(CHARACTER_CREATE_MODE_CREATE)
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()

    local templateData = self.characterData:GetTemplate(CharacterCreateGetTemplate(characterMode))
    -- we may not have any template selected or we have no templates
    -- so create a default template with no restrictions
    if templateData == nil then
        templateData = self.characterData:GetNoneTemplate()
    end

    self:UpdateSelectorsForTemplate(function(...) return self:UpdateRaceSelectorsForTemplate(...) end, self.characterData:GetRaceInfo(), templateData, self.raceRadioGroup)
    self:UpdateSelectorsForTemplate(function(...) return self:UpdateClassSelectorsForTemplate(...) end, self.characterData:GetClassInfo(), templateData, self.classRadioGroup)

    self.characterData:UpdateAllianceSelectability()
    self:UpdateSelectorsForTemplate(function(...) return self:UpdateAllianceSelectorsForTemplate(...) end, self.characterData:GetAllianceInfo(), templateData, self.allianceRadioGroup)

    self.nameControl:SetEditEnabled(true)
    self.nameControl:SetMouseEnabled(true)
    self.nameControl:SetColor(ZO_NORMAL_TEXT:UnpackRGB())

    self.saveButton:SetHidden(true)
    self.createButton:SetHidden(false)

    local currentAlliance = CharacterCreateGetAlliance(characterMode)
    ZO_CharacterCreate_SetChromaColorForAlliance(currentAlliance)
end

--
--[[ XML Handlers and global functions ]]--
--

function ZO_CharacterCreate_RandomizeAppearance(randomizeType)
    KEYBOARD_BUCKET_MANAGER:RandomizeAppearance(randomizeType)
end

function ZO_CharacterCreate_Initialize(control)
    KEYBOARD_CHARACTER_CREATE_MANAGER = ZO_CharacterCreate_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject(ZO_CHARACTER_CREATE_SYSTEM_NAME, KEYBOARD_CHARACTER_CREATE_MANAGER)

    KEYBOARD_BUCKET_MANAGER = ZO_CharacterCreateBucketManager_Keyboard:New(ZO_CharacterCreateBuckets)
end

function ZO_CharacterCreate_OnCreateButtonClicked(startLocation)
    KEYBOARD_CHARACTER_CREATE_MANAGER:OnCreateButtonClicked(startLocation)
end

function ZO_CharacterCreate_OnSaveButtonClicked()
    KEYBOARD_CHARACTER_CREATE_MANAGER:SaveCharacterChanges()
end

local function ValidateNameText(editControl)
    local nameText = editControl:GetText()
    local nameViolations = { IsValidCharacterName(nameText) }
    local nameIsValid = (#nameViolations == 0)

    if nameIsValid then
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
    if editControl.validating then
        return
    end

    editControl.validating = true

    local isValidName, nameViolations = ValidateNameText(editControl)

    if isValidName then
        editControl.linkedButton:SetState(BSTATE_NORMAL, false)
        editControl.linkedInstructions:Hide()
    else
        editControl.linkedButton:SetState(BSTATE_DISABLED, true)

        if editControl:HasFocus() then
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

    if WINDOW_MANAGER:IsHandlingHardwareEvent() then
        PlaySound(SOUNDS.EDIT_CLICK)
    end
end

function ZO_CharacterCreate_OnNameFieldFocusLost(editControl)
    if #editControl:GetText() == 0 then
        GetControl(editControl, "Instructions"):SetHidden(false)
    end
    editControl.linkedInstructions:Hide()
end

function ZO_CharacterCreate_OnSelectorClicked(button)
    local selectorClickHandlers =
    {
        [CHARACTER_CREATE_SELECTOR_RACE] =  function(button)
                        KEYBOARD_CHARACTER_CREATE_MANAGER:SetRace(button.defId)
                        KEYBOARD_CHARACTER_CREATE_MANAGER:UpdateRaceControl()
                    end,

        [CHARACTER_CREATE_SELECTOR_CLASS] = function(button)
                        CharacterCreateSetClass(button.defId)
                        KEYBOARD_CHARACTER_CREATE_MANAGER:UpdateClassControl()
                    end,

        [CHARACTER_CREATE_SELECTOR_ALLIANCE] =  function(button)
                            KEYBOARD_CHARACTER_CREATE_MANAGER:SetAlliance(button.defId)
                            KEYBOARD_CHARACTER_CREATE_MANAGER:UpdateRaceControl()
                        end,
    }

    local clickHandler = selectorClickHandlers[button.selectorType]
    if clickHandler then
        OnCharacterCreateOptionChanged()
        clickHandler(button)
    end
end

function ZO_CharacterCreate_MouseEnterNamedSelector(button)
    InitializeTooltip(InformationTooltip, button, TOPRIGHT, 0, 0, TOPLEFT)

    if button.name then
        SetTooltipText(InformationTooltip, zo_strformat(button.tooltipFormatter, button.name))
    elseif button.nameFn then
        local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
        SetTooltipText(InformationTooltip, zo_strformat(button.tooltipFormatter, button.nameFn(CharacterCreateGetGender(characterMode), button.defId)))
    end

    -- If a button is disabled, add any disable reasons to the tooltip
    if button:GetState() == BSTATE_DISABLED or button:GetState() == BSTATE_DISABLED_PRESSED then
        -- Check if disabled due to a barbershop mode
        local characterCreateMode = KEYBOARD_CHARACTER_CREATE_MANAGER:GetCharacterCreateMode()
        if characterCreateMode ~= CHARACTER_CREATE_MODE_CREATE then
            local selectorType = button.selectorType

            local addDisableReason = false
            local tokenType
            if characterCreateMode == CHARACTER_CREATE_MODE_EDIT_APPEARANCE then
                tokenType = SERVICE_TOKEN_APPEARANCE_CHANGE
                addDisableReason = selectorType == CHARACTER_CREATE_SELECTOR_RACE or selectorType == CHARACTER_CREATE_SELECTOR_CLASS or selectorType == CHARACTER_CREATE_SELECTOR_ALLIANCE
            elseif characterCreateMode == CHARACTER_CREATE_MODE_EDIT_RACE then
                tokenType = SERVICE_TOKEN_RACE_CHANGE
                addDisableReason = selectorType == CHARACTER_CREATE_SELECTOR_CLASS or selectorType == CHARACTER_CREATE_SELECTOR_ALLIANCE
            end

            if addDisableReason then
                local tokenString = GetString("SI_SERVICETOKENTYPE", tokenType)
                InformationTooltip:AddLine(zo_strformat(SI_CREATE_CHARACTER_SELECTOR_TOKEN_DISABLED, tokenString), "", ZO_NORMAL_TEXT:UnpackRGB())
            end
        end

        local raceSelector = button.selectorType == CHARACTER_CREATE_SELECTOR_RACE
        local classSelector = button.selectorType == CHARACTER_CREATE_SELECTOR_CLASS

        -- Check for race/class specific disable reasons
        if raceSelector or classSelector then
            local restrictionReasonFunction = raceSelector and GetRaceRestrictionReason or GetClassRestrictionReason
            local restrictionReason, restrictingCollectible = restrictionReasonFunction(button.defId)
            local restrictionString = ZO_CHARACTERCREATE_MANAGER.GetOptionRestrictionString(restrictionReason, restrictingCollectible)
            if restrictionString ~= "" then
                InformationTooltip:AddLine(restrictionString, "", ZO_NORMAL_TEXT:UnpackRGB())

                if restrictingCollectible ~= 0 and IsCollectiblePurchasable(restrictingCollectible) then
                    InformationTooltip:AddLine(GetString(SI_CHARACTER_CREATE_RESTRICTION_COLLECTIBLE_PURCHASABLE), "", ZO_NORMAL_TEXT:UnpackRGB())
                end
            end
        end
    end
end

function ZO_CharacterCreate_MouseExitNamedSelector(button)
    ClearTooltip(InformationTooltip)
end

function ZO_CharacterCreateSelectGender(button)
    OnCharacterCreateOptionChanged()
    KEYBOARD_CHARACTER_CREATE_MANAGER:SetGender(button.gender)
end

function ZO_CharacterCreate_ChangeSlider(slider, changeAmount)
    OnCharacterCreateOptionChanged()
    slider:GetParent().sliderObject:ChangeValue(changeAmount)
end

function ZO_CharacterCreate_ChangePanel(direction)
    local currentTab = KEYBOARD_BUCKET_MANAGER:GetCurrentTab()
    if currentTab then
        KEYBOARD_BUCKET_MANAGER:SwitchBuckets(currentTab.windowData[direction])
    end
end

function ZO_CharacterCreate_PreviewClicked(previewButton)
    local slider = previewButton:GetParent()
    slider.sliderObject:Preview()
end

function ZO_PaperdollManipulation_OnInitialized(self)
    --While we need a mouse down over the paper doll area to start spinning, the mouse up may not be delivered to this same control. If we press mouse left to start spinning (which starts
    --mouse tracking) then press mouse right this will release mouse left but it won't stop mouse tracking because tracking is locked when the up is delivered. So we catch it on the event instead
    --when tracking isn't locked. ESO-546877
    EVENT_MANAGER:RegisterForEvent("PaperDollManipulation", EVENT_GLOBAL_MOUSE_UP, function() CharacterCreateStopMouseSpin() end)
end
