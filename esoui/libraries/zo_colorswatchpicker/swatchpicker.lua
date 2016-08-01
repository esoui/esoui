local ENTRY_PADDING = 2
local ENTRY_WIDTH = 16
local SELECTED_ENTRY_WIDTH = 24
local DEFAULT_STRIDE = 10 -- Might make this adjustable later.

local ZO_PaletteButtonManager = ZO_ObjectPool:Subclass()

function ZO_PaletteButtonManager:New()
    -- Just use GuiRoot as parent, since all of these controls will be reparented to the correct swatch picker
    local function CreateEntry(pool)
        return ZO_ObjectPool_CreateNamedControl("ZO_ColorSwatchEntry", "ZO_PaletteEntry", pool, GuiRoot)
    end

    local function ResetEntry(entryControl)
        entryControl.m_key = nil
        entryControl.m_paletteIndex = nil
        entryControl:SetHidden(true)
    end
    
    return ZO_ObjectPool.New(self, CreateEntry, ResetEntry)
end

local g_buttonManager = ZO_PaletteButtonManager:New()

local ZO_ColorSwatchPicker = ZO_Object:Subclass()

function ZO_ColorSwatchPicker:New(control)
    local picker = ZO_Object.New(self)

    control.m_picker = picker
    picker.m_control = control
    picker.m_paletteEntries = {}

    return picker
end

local function GetAnchorOffsets(entryIndex, size, pad, nudge)
    local stride = DEFAULT_STRIDE
    local row = zo_floor(entryIndex / stride)
    local col = zo_mod(entryIndex, stride)
    local halfSize = size / 2
    local offsetWithPad = size + pad

    nudge = nudge or 0

    local offsetX = (col * offsetWithPad) + halfSize + nudge
    local offsetY = (row * offsetWithPad) + halfSize + nudge

    return offsetX, offsetY
end

local function SetupEntryAnchors(entry, size, padding, nudge)
    local offsetX, offsetY = GetAnchorOffsets(entry.m_paletteIndex - 1, size, padding, nudge)

    entry:ClearAnchors()
    entry:SetAnchor(CENTER, nil, TOPLEFT, offsetX, offsetY)
end

function ZO_ColorSwatchPicker:AddEntry(paletteIndex, r, g, b)
    local entryControl, entryKey = g_buttonManager:AcquireObject()
    entryControl.m_key = entryKey
    entryControl.m_paletteIndex = paletteIndex
    GetControl(entryControl, "Color"):SetColor(r, g, b, 1)

    entryControl:SetParent(self.m_control)
    entryControl:SetHidden(false)

    SetupEntryAnchors(entryControl, ENTRY_WIDTH, ENTRY_PADDING)

    self.m_paletteEntries[#self.m_paletteEntries + 1] = entryControl
end

function ZO_ColorSwatchPicker:Clear()
    self:SetEntryPressed(nil)

    for controlIndex, control in ipairs(self.m_paletteEntries) do
        g_buttonManager:ReleaseObject(control.m_key)
        control.m_key = nil
        control:SetHidden(true)
        control:SetState(BSTATE_NORMAL, false)
        GetControl(control, "Color"):SetDesaturation(0)

        self.m_paletteEntries[controlIndex] = nil
    end

    self.m_pressedEntry = nil
end

function ZO_ColorSwatchPicker:SetClickedCallback(callback)
    self.m_callback = callback
end

function ZO_ColorSwatchPicker:OnClicked(entry)
    if(self.m_callback) then
        self.m_callback(entry.m_paletteIndex)
    end

    self:SetEntryPressed(entry)
end

function ZO_ColorSwatchPicker:SetEntryPressed(entry)
    -- Unpress current entry
    local pressed = self.m_pressedEntry

    if(pressed == entry) then return end

    if(pressed) then
        pressed:SetDimensions(ENTRY_WIDTH, ENTRY_WIDTH)
        pressed:SetPressedTexture("EsoUI/Art/Buttons/swatchFrame_down.dds")
        pressed:SetState(BSTATE_NORMAL, false)
        pressed:SetDrawTier(DT_LOW)

        local color = GetControl(pressed, "Color")
        color:ClearAnchors()
        color:SetAnchorFill()

        SetupEntryAnchors(pressed, ENTRY_WIDTH, ENTRY_PADDING)
    end

    -- Press new entry
    if(entry) then
        entry:SetDimensions(SELECTED_ENTRY_WIDTH, SELECTED_ENTRY_WIDTH)
        entry:SetPressedTexture("EsoUI/Art/Buttons/swatchFrame_selected.dds")
        entry:SetState(BSTATE_PRESSED, true)
        entry:SetDrawTier(DT_MEDIUM)

        local color = GetControl(entry, "Color")
        color:ClearAnchors()
        color:SetAnchor(TOPLEFT)
        color:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, -4, -4)

        SetupEntryAnchors(entry, ENTRY_WIDTH, ENTRY_PADDING, 1)
    end

    self.m_pressedEntry = entry
end

function ZO_ColorSwatchPicker:SetSelected(index)
    self:SetEntryPressed(self.m_paletteEntries[index])
end

function ZO_ColorSwatchPicker:SetEnabled(enabled)
    local pressed = self.m_pressedEntry

    for controlIndex, control in ipairs(self.m_paletteEntries) do
        if(control == pressed) then
            if(enabled) then
                control:SetState(BSTATE_PRESSED, true)
                GetControl(control, "Color"):SetDesaturation(0)
            else
                control:SetState(BSTATE_DISABLED_PRESSED, true)
                -- Do not desaturate the disabled-selected color.
            end
        else
            if(enabled) then
                control:SetState(BSTATE_NORMAL, false)
                GetControl(control, "Color"):SetDesaturation(0)
            else
                control:SetState(BSTATE_DISABLED, true)
                GetControl(control, "Color"):SetDesaturation(1)
            end
        end
    end
end

function ZO_ColorSwatchPicker_Create(colorPicker)
    ZO_ColorSwatchPicker:New(colorPicker)
end

function ZO_ColorSwatchPicker_OnEntryClicked(entry)
    entry:GetParent().m_picker:OnClicked(entry)
end

function ZO_ColorSwatchPicker_SetClickedCallback(colorPicker, callback)
    colorPicker.m_picker:SetClickedCallback(callback)
end

function ZO_ColorSwatchPicker_AddColor(colorPicker, paletteIndex, r, g, b)
    colorPicker.m_picker:AddEntry(paletteIndex, r, g, b)
end

function ZO_ColorSwatchPicker_Clear(colorPicker)
    colorPicker.m_picker:Clear()
end

function ZO_ColorSwatchPicker_SetSelected(colorPicker, index)
    colorPicker.m_picker:SetSelected(index)
end

function ZO_ColorSwatchPicker_SetEnabled(colorPicker, enabled)
    -- TODO: Better updating for locked controls...something like show selected in color, desaturate the rest?
    colorPicker.m_picker:SetEnabled(enabled)
end