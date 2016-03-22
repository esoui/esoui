local EditContainerSizerManager = ZO_Object:Subclass()

function EditContainerSizerManager:New()
    local obj = ZO_Object.New(self)
    obj:Initialize()
    return obj
end

function EditContainerSizerManager:Initialize()
    self.sizers = {}
    EVENT_MANAGER:RegisterForEvent("EditContainerSizerManager", EVENT_ALL_GUI_SCREENS_RESIZED, function() self:OnAllGuiScreensResized() end)
end

function EditContainerSizerManager:Add(sizer)
    table.insert(self.sizers, sizer)
end

function EditContainerSizerManager:OnAllGuiScreensResized()
    for _, sizer in ipairs(self.sizers) do
        sizer:OnAllGuiScreensResized()
    end
end

local EDIT_CONTAINER_SIZER_MANAGER = EditContainerSizerManager:New()

--This class is responsible for resizing the edit box backdrops. These backdrops require space for the text, additional padding
--(buffer top and buffer bottom), and for the IME underlining (IME_UNDERLINE_THICKNESS_PIXELS) if applicable.

ZO_EditContainerSizer = ZO_Object:Subclass()

function ZO_EditContainerSizer:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_EditContainerSizer:Initialize(bufferTop, bufferBottom)
    self.backdrops = {}
    self.bufferTop = bufferTop
    self.bufferBottom = bufferBottom
    EDIT_CONTAINER_SIZER_MANAGER:Add(self)
end

function ZO_EditContainerSizer:Add(backdrop)
    table.insert(self.backdrops, backdrop)
    self:RefreshSize(backdrop)
end

function ZO_EditContainerSizer.GetHeight(backdrop, bufferTop, bufferBottom)
    local editBox
    local name = backdrop:GetName()
    for i = 1, backdrop:GetNumChildren() do
        local child = backdrop:GetChild(i)
        if child:GetType() == CT_EDITBOX then
            editBox = child
            break
        end
    end

    if editBox then
        local textHeight = editBox:GetFontHeight()
        local IMEUnderlineThicknessUIUnits = 0
        if DoesCurrentLanguageRequireIME() then
            IMEUnderlineThicknessUIUnits = IME_UNDERLINE_THICKNESS_PIXELS / GetUIGlobalScale()
        end
        return textHeight + bufferTop + bufferBottom + IMEUnderlineThicknessUIUnits
    else
        return 0
    end
end

function ZO_EditContainerSizer:RefreshSize(backdrop)
    backdrop:SetHeight(ZO_EditContainerSizer.GetHeight(backdrop, self.bufferTop, self.bufferBottom))
end

function ZO_EditContainerSizer.ForceRefreshSize(backdrop, bufferTop, bufferBottom)
    backdrop:SetHeight(ZO_EditContainerSizer.GetHeight(backdrop, bufferTop, bufferBottom))
end

function ZO_EditContainerSizer:OnAllGuiScreensResized()
    for _, backdrop in ipairs(self.backdrops) do
        backdrop:SetHeight(ZO_EditContainerSizer.GetHeight(backdrop, self.bufferTop, self.bufferBottom))
    end
end
