ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_CONTROL_WIDTH = 1200
local ANTIQUITY_LORE_WIDE_DOCUMENT_FILE_WIDTH = 1024
local ANTIQUITY_LORE_WIDE_DOCUMENT_SCALE_MODIFIER = ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_CONTROL_WIDTH / ANTIQUITY_LORE_WIDE_DOCUMENT_FILE_WIDTH

local ANTIQUITY_LORE_WIDE_DOCUMENT_LARGE_FILE_HEIGHT = 1024
local ANTIQUITY_LORE_WIDE_DOCUMENT_LARGE_FILE_BOTTOM_OFFSET = 576
ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_LARGE_CONTROL_HEIGHT = ANTIQUITY_LORE_WIDE_DOCUMENT_LARGE_FILE_BOTTOM_OFFSET * ANTIQUITY_LORE_WIDE_DOCUMENT_SCALE_MODIFIER
ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_LARGE_TEXTURE_COORDS_BOTTOM = ANTIQUITY_LORE_WIDE_DOCUMENT_LARGE_FILE_BOTTOM_OFFSET / ANTIQUITY_LORE_WIDE_DOCUMENT_LARGE_FILE_HEIGHT

local ANTIQUITY_LORE_WIDE_DOCUMENT_MEDIUM_FILE_HEIGHT = 512
local ANTIQUITY_LORE_WIDE_DOCUMENT_MEDIUM_FILE_BOTTOM_OFFSET = 448
ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_MEDIUM_CONTROL_HEIGHT = ANTIQUITY_LORE_WIDE_DOCUMENT_MEDIUM_FILE_BOTTOM_OFFSET * ANTIQUITY_LORE_WIDE_DOCUMENT_SCALE_MODIFIER
ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_MEDIUM_TEXTURE_COORDS_BOTTOM = ANTIQUITY_LORE_WIDE_DOCUMENT_MEDIUM_FILE_BOTTOM_OFFSET / ANTIQUITY_LORE_WIDE_DOCUMENT_MEDIUM_FILE_HEIGHT

local ANTIQUITY_LORE_WIDE_DOCUMENT_SMALL_FILE_HEIGHT = 256
local ANTIQUITY_LORE_WIDE_DOCUMENT_SMALL_FILE_BOTTOM_OFFSET = 256
ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_SMALL_CONTROL_HEIGHT = ANTIQUITY_LORE_WIDE_DOCUMENT_SMALL_FILE_BOTTOM_OFFSET * ANTIQUITY_LORE_WIDE_DOCUMENT_SCALE_MODIFIER
ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_SMALL_TEXTURE_COORDS_BOTTOM = ANTIQUITY_LORE_WIDE_DOCUMENT_SMALL_FILE_BOTTOM_OFFSET / ANTIQUITY_LORE_WIDE_DOCUMENT_SMALL_FILE_HEIGHT

ZO_ANTIQUITY_LORE_BACKGROUND_PADDING_X = 60
ZO_ANTIQUITY_LORE_BACKGROUND_PADDING_Y = 45
ZO_ANTIQUITY_LORE_BACKGROUND_DOUBLE_PADDING_X = ZO_ANTIQUITY_LORE_BACKGROUND_PADDING_X * 2
ZO_ANTIQUITY_LORE_LABEL_PADDING_Y = 15
local ANTIQUITY_LORE_NON_LABEL_DEADSPACE_Y = ZO_ANTIQUITY_LORE_BACKGROUND_PADDING_Y + ZO_ANTIQUITY_LORE_BACKGROUND_PADDING_Y + ZO_ANTIQUITY_LORE_LABEL_PADDING_Y

local NUM_DOCUMENT_VARIANTS = 10

local LABEL_ALIGNMENTS =
{
    TEXT_ALIGN_LEFT,
    TEXT_ALIGN_CENTER,
    TEXT_ALIGN_RIGHT,
}

local ANTIQUITY_CODEX_WIDE_TEXTURE_FORMATTER = "EsoUI/Art/Antiquities/Codex/AntiquityLore_%s_%d.dds"

ZO_AntiquityLoreDocument_Manager = ZO_CallbackObject:Subclass()

function ZO_AntiquityLoreDocument_Manager:New(...)
    local manager = ZO_CallbackObject.New(self, ...)
    manager:Initialize(...)
    return manager
end

function ZO_AntiquityLoreDocument_Manager:Initialize()
    local widePool = ZO_ControlPool:New("ZO_AntiquityLoreWideDocument", nil, "LoreWideDocument")
    widePool:SetCustomFactoryBehavior(function(control)
        control.highlightAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityLoreDocument_HighlightAnimation", control)
    end)
    widePool:SetCustomAcquireBehavior(function(control)
        ApplyTemplateToControl(control, ZO_GetPlatformTemplate("ZO_AntiquityLoreDocument"))
    end)

    --Preparing for the scenario where we want thinner taller versions for keyboard
    self.wideControlAcquisitionDescriptor =
    {
        pool = widePool,
        metaPools = {},
        fileFormatter = ANTIQUITY_CODEX_WIDE_TEXTURE_FORMATTER,
        sizeDescriptors =
        {
            {
                maxLabelHeight = ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_SMALL_CONTROL_HEIGHT - ANTIQUITY_LORE_NON_LABEL_DEADSPACE_Y,
                textureHeight = ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_SMALL_CONTROL_HEIGHT,
                textureCoordBottom = ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_SMALL_TEXTURE_COORDS_BOTTOM,
                imageQualifier = "Small",
            },
            {
                maxLabelHeight = ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_MEDIUM_CONTROL_HEIGHT - ANTIQUITY_LORE_NON_LABEL_DEADSPACE_Y,
                textureHeight = ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_MEDIUM_CONTROL_HEIGHT,
                textureCoordBottom = ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_MEDIUM_TEXTURE_COORDS_BOTTOM,
                imageQualifier = "Medium",
            },
            {
                maxLabelHeight = ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_LARGE_CONTROL_HEIGHT - ANTIQUITY_LORE_NON_LABEL_DEADSPACE_Y,
                textureHeight = ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_LARGE_CONTROL_HEIGHT,
                textureCoordBottom = ZO_ANTIQUITY_LORE_WIDE_DOCUMENT_LARGE_TEXTURE_COORDS_BOTTOM,
                imageQualifier = "Large",
            },
        },
    }
end

-- Never hold on to a control indefinitely. Make sure to always call ReleaseAllObjects when you no longer need them, or at least when leaving your scene
function ZO_AntiquityLoreDocument_Manager:AcquireWideDocumentForLoreEntry(parentControl, antiquityId, loreEntryIndex)
    return self:InternalAcquireDocumentForLoreEntry(self.wideControlAcquisitionDescriptor, parentControl, antiquityId, loreEntryIndex)
end

function ZO_AntiquityLoreDocument_Manager:InternalAcquireDocumentForLoreEntry(acquisitionDescriptor, parentControl, antiquityId, loreEntryIndex)
    local loreEntryData = nil
    if ANTIQUITY_DATA_MANAGER then
        local antiquityData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)
        if antiquityData then
            loreEntryData = antiquityData:GetLoreEntry(loreEntryIndex)
        end
    else
        -- Internal doesn't have the manager, so just build the data manually
        local numEntries = GetNumAntiquityLoreEntries(antiquityId)
        if loreEntryIndex <= numEntries then
            local displayName, description = GetAntiquityLoreEntry(antiquityId, loreEntryIndex)
            loreEntryData =
            {
                displayName = displayName,
                description = description,
                unlocked = GetNumAntiquityLoreEntriesAcquired(antiquityId) >= loreEntryIndex,
            }
        end
    end

    if not loreEntryData then
        -- Invalid lore entry args
        return nil
    end

    -- Spread the seeds far apart because seeds that are very close to eachother typically have the same first number, then throw out the first number for good measure
    -- This will allow for 20 lore per antiquity with 20k antiquities (numbers we "should" never hit)
    -- http://lua-users.org/lists/lua-l/2007-03/msg00564.html
    local seed = (loreEntryIndex * 100000000) + (antiquityId * 1000)
    zo_randomseed(seed)
    zo_random()
    -- BEGIN DETERMINISTIC "RANDOM" SPECIFICATIONS --
    local documentVariant = zo_random(NUM_DOCUMENT_VARIANTS)
    local titleAlignment = LABEL_ALIGNMENTS[zo_random(#LABEL_ALIGNMENTS)]
    local flipHorizontalTextureCoords = zo_random() > 0.5
    local colorR = 1
    local colorG = 1
    local colorB = 1
    local alpha = 1
    local desaturation = nil
    if loreEntryData.unlocked then
        colorR = zo_random(90, 100) / 100
        colorG = zo_random(90, 100) / 100
        colorB = zo_random(90, 100) / 100
        desaturation = zo_random(0, 25) / 100
    else
        alpha = 0.4
        desaturation = 1
    end
    -- END DETERMINISTIC "RANDOM" SPECIFICATIONS --
    zo_randomseed(GetSecondsSinceMidnight())

    -- Every system gets a meta pool
    local metaPool = acquisitionDescriptor.metaPools[parentControl]
    if not metaPool then
        metaPool = ZO_MetaPool:New(acquisitionDescriptor.pool)
        acquisitionDescriptor.metaPools[parentControl] = metaPool
    end

    local control = metaPool:AcquireObject()
    control.titleLabel:SetText(loreEntryData.displayName)
    control.bodyLabel:SetText(loreEntryData.description)
    local totalLabelHeight = control.titleLabel:GetHeight() + control.bodyLabel:GetHeight()

    -- Choose the correctly sized control info
    local sizeDescriptor = nil
    for index, descriptor in ipairs(acquisitionDescriptor.sizeDescriptors) do
        if totalLabelHeight <= descriptor.maxLabelHeight or index == #acquisitionDescriptor.sizeDescriptors then
            sizeDescriptor = descriptor
            break
        end
    end

    control:SetAlpha(alpha)
    local backgroundTexture = control.backgroundTexture
    backgroundTexture:SetTexture(string.format(acquisitionDescriptor.fileFormatter, sizeDescriptor.imageQualifier, documentVariant))
    if flipHorizontalTextureCoords then
        backgroundTexture:SetTextureCoords(0, 1, 0, sizeDescriptor.textureCoordBottom)
    else
        backgroundTexture:SetTextureCoords(1, 0, 0, sizeDescriptor.textureCoordBottom)
    end
    backgroundTexture:SetHeight(sizeDescriptor.textureHeight)
    backgroundTexture:SetVertexColors(VERTEX_POINTS_TOPLEFT, colorR, colorG, colorB, alpha)
    backgroundTexture:SetVertexColors(VERTEX_POINTS_TOPRIGHT, 0.9 * colorR, 0.9 * colorG, 0.9 * colorB, alpha)
    backgroundTexture:SetVertexColors(VERTEX_POINTS_BOTTOMLEFT, 0.65 * colorR, 0.65 * colorG, 0.65 * colorB, alpha)
    backgroundTexture:SetVertexColors(VERTEX_POINTS_BOTTOMRIGHT, 0.25 * colorR, 0.25 * colorG, 0.25 * colorB, alpha)
    backgroundTexture:SetDesaturation(desaturation)
    control.titleLabel:SetHorizontalAlignment(titleAlignment)
    control.titleLabel:SetHidden(not loreEntryData.unlocked)
    control.bodyLabel:SetHidden(not loreEntryData.unlocked)
    control:SetHeight(sizeDescriptor.textureHeight)
    control:SetParent(parentControl)

    if loreEntryData.unlocked then
        control.highlightAnimation:PlayInstantlyToEnd()
    else
        control.highlightAnimation:PlayInstantlyToStart()
    end
    return control
end

function ZO_AntiquityLoreDocument_Manager:ReleaseAllObjects(parentControl)
    local metaPool = self.wideControlAcquisitionDescriptor.metaPools[parentControl]
    if metaPool then
        metaPool:ReleaseAllObjects()
    end
end

function ZO_AntiquityLoreDocument_HighlightAnimation_OnUpdate(control, progress)
    local easedProgress = ZO_EaseInCubic(progress)
    local animatedControl = control:GetAnimatedControl()
    animatedControl.backgroundTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_WEIGHT_RGB, zo_lerp(0.4, 1.5, easedProgress))
end

ANTIQUITY_LORE_DOCUMENT_MANAGER = ZO_AntiquityLoreDocument_Manager:New()