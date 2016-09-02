ZO_LABEL_TEMPLATE_DUMMY_LABEL = CreateControl("ZO_LabelTemplates_DummyLabel", GuiRoot, CT_LABEL)
ZO_LABEL_TEMPLATE_DUMMY_LABEL:SetHidden(true)

-------------------
--SelectableLabel--
-------------------
do
    local function SetSelected(self, selected)
        self.selected = selected
        self:RefreshTextColor()
    end

    local function IsSelected(self)
        return self.selected
    end

    local function SetEnabled(self, enabled)
        self.enabled = enabled
        self:RefreshTextColor()
    end

    local function RefreshTextColor(self)
        self:SetColor(self:GetTextColor())
    end

    local function GetTextColor(self)
        if not self.enabled then
            return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED)
        elseif self.selected then
            return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED)
        elseif self.mouseover then
            return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_HIGHLIGHT)
        else
            return self.normalColor:UnpackRGBA()
        end
    end

    function ZO_SelectableLabel_OnInitialized(label, colorFunction)
        label.selected = false
        label.enabled = true
        label.mouseoverEnabled = true
        label.normalColor = ZO_NORMAL_TEXT
        label.SetSelected = SetSelected
        label.IsSelected = IsSelected
        label.GetTextColor = colorFunction or GetTextColor
        label.RefreshTextColor = RefreshTextColor
        label.SetEnabled = SetEnabled
    end

    function ZO_SelectableLabel_OnMouseEnter(label)
        if(label.mouseoverEnabled) then
            label.mouseover = true
        end
        label:RefreshTextColor()
    end

    function ZO_SelectableLabel_OnMouseExit(label)
        if(label.mouseoverEnabled) then
            label.mouseover = false
        end
        label:RefreshTextColor()
    end

    function ZO_SelectableLabel_SetNormalColor(label, color)
        if color ~= label.normalColor and not label.normalColor:IsEqual(color) then
            label.normalColor = color
            label:RefreshTextColor()
        end
    end

    function ZO_SelectableLabel_SetMouseOverEnabled(label, enabled)
        label.mouseoverEnabled = enabled
    end
end

------------------
--KeyMarkupLabel--
------------------
do
    local g_largeKeyEdgefilePool
    local g_smallKeyEdgefilePool

    local function GetOrCreateKeyEdgefile(largeSize)
        if largeSize then
            if not g_largeKeyEdgefilePool then
                g_largeKeyEdgefilePool = ZO_ControlPool:New("ZO_LargeKeyBackdrop")
                g_largeKeyEdgefilePool:SetCustomResetBehavior(   function(control)
                                                                control:SetParent(nil)
                                                            end)
            end
            return g_largeKeyEdgefilePool:AcquireObject()
        else
            if not g_smallKeyEdgefilePool then
                g_smallKeyEdgefilePool = ZO_ControlPool:New("ZO_SmallKeyBackdrop")
                g_smallKeyEdgefilePool:SetCustomResetBehavior(   function(control)
                                                                control:SetParent(nil)
                                                            end)
            end
            return g_smallKeyEdgefilePool:AcquireObject()
        end
    end

    local function UpdateEdgeFileColor(self, keyEdgeFile)
        if self.edgeFileColor then
            keyEdgeFile:SetCenterColor(self.edgeFileColor:UnpackRGBA())
            keyEdgeFile:SetEdgeColor(self.edgeFileColor:UnpackRGBA())
        else
            keyEdgeFile:SetCenterColor(1, 1, 1, 1)
            keyEdgeFile:SetEdgeColor(1, 1, 1, 1)
        end
    end

    function ZO_KeyMarkupLabel_OnNewUserAreaCreated(self, areaData, areaText, left, right, top, bottom, largeSize)
        if areaData == "key" then
            if not self.keyBackdrops then
                self.keyBackdrops = {}
            end

            local keyEdgeFile, key = GetOrCreateKeyEdgefile(largeSize)
            keyEdgeFile.key = key
            keyEdgeFile:SetParent(self)
            keyEdgeFile:SetAnchor(TOPLEFT, self, TOPLEFT, left, top)
            keyEdgeFile:SetAnchor(BOTTOMRIGHT, self, TOPLEFT, right, bottom)

            UpdateEdgeFileColor(self, keyEdgeFile)

            keyEdgeFile:SetHidden(false)

            self.keyBackdrops[#self.keyBackdrops + 1] = keyEdgeFile
        end
    end

    function ZO_SmallKeyMarkupLabel_OnNewUserAreaCreated(self, areaData, areaText, left, right, top, bottom)
        local leftOffset = left + (self.leftOffset or 2)
        local rightOffset = right + (self.rightOffset or -2)
        local topOffset = top + (self.topOffset or -2)
        local bottomOffset = bottom + (self.bottomOffset or 3)

        ZO_KeyMarkupLabel_OnNewUserAreaCreated(self, areaData, areaText, leftOffset, rightOffset, topOffset, bottomOffset, false)
    end

    function ZO_LargeKeyMarkupLabel_OnNewUserAreaCreated(self, areaData, areaText, left, right, top, bottom)
        local leftOffset = left + (self.leftOffset or 2)
        local rightOffset = right + (self.rightOffset or -2)
        local topOffset = top + (self.topOffset or -1)
        local bottomOffset = bottom + (self.bottomOffset or 1)

        ZO_KeyMarkupLabel_OnNewUserAreaCreated(self, areaData, areaText, leftOffset, rightOffset, topOffset, bottomOffset, true)
    end

    function ZO_KeyMarkupLabel_SetEdgeFileColor(self, color)
        self.edgeFileColor = color

        if self.keyBackdrops then
            for i, keyEdgeFile in ipairs(self.keyBackdrops) do
                UpdateEdgeFileColor(self, keyEdgeFile)
            end
        end
    end

    function ZO_KeyMarkupLabel_SetCustomOffsets(self, left, right, top, bottom)
        self.leftOffset = left
        self.rightOffset = right
        self.topOffset = top
        self.bottomOffset = bottom
    end

    function ZO_KeyMarkupLabel_OnTextChanged(self, largeSize)
        local pool
        if largeSize then
            pool = g_largeKeyEdgefilePool
        else
            pool = g_smallKeyEdgefilePool
        end

        if self.keyBackdrops then
            for i = #self.keyBackdrops, 1, -1 do
                pool:ReleaseObject(self.keyBackdrops[i].key)
                self.keyBackdrops[i] = nil
            end
        end
    end

    function ZO_SmallKeyMarkupLabel_OnTextChanged(self)
        ZO_KeyMarkupLabel_OnTextChanged(self, false)
    end

    function ZO_LargeKeyMarkupLabel_OnTextChanged(self)
        ZO_KeyMarkupLabel_OnTextChanged(self, true)
    end
end

--------------------------
--FontAdjustingWrapLabel--
--------------------------
do
    -- dontUseMaxLinesForAdjusting is used when multiple fonts have fontData.lineLimit == label.maxLines
    -- With MaxLineCount non-zero the text will be truncated on the larger font so the smaller font will not be tested
    -- To see the true number of lines with the given font, we SetMaxLineCount(0) before adjusting and then set it back to label.maxLines
    local function AdjustWrappingLabelFont(label)
        if label.dontUseMaxLinesForAdjusting then
            label:SetMaxLineCount(0)
        end

        for i, fontData in ipairs(label.fonts) do
            local fontLineLimit = fontData.lineLimit or i
            label:SetFont(fontData.font)
            local lines = label:GetNumLines()
            if lines <= fontLineLimit and not label:WasTruncated() then
                break
            end
        end

        if label.dontUseMaxLinesForAdjusting then
            label:SetMaxLineCount(label.maxLines)
        end
    end
    
    local function FontAdjustingWrapLabel_Update(label)
        local width = label:GetWidth()
        if label.forceUpdate or label.width ~= width then
            label.width = width
            label.forceUpdate = false
            AdjustWrappingLabelFont(label)
        end
    end

    local function SetTextOverride(label, text)
        ZO_LABEL_TEMPLATE_DUMMY_LABEL.SetText(label, text)
        label.forceUpdate = true
        FontAdjustingWrapLabel_Update(label)
    end

    local function ApplyStyle(label, fonts)
        label.fonts = fonts
        local numFonts = #fonts
        local lastFont = fonts[numFonts]
        local maxLines = lastFont.lineLimit or numFonts
        label.maxLines = maxLines
        label.dontUseMaxLinesForAdjusting = lastFont.dontUseForAdjusting
        label:SetMaxLineCount(maxLines)
        label.forceUpdate = true
    end

    local function FontAdjustingWrapLabel_Initialize(label, wrapMode)
        label.SetText = SetTextOverride
        label:SetWrapMode(wrapMode)
        label:SetHandler("OnUpdate", FontAdjustingWrapLabel_Update)
    end

    function ZO_FontAdjustingWrapLabel_OnInitialized(label, fonts, wrapMode)
        FontAdjustingWrapLabel_Initialize(label, wrapMode)
        ApplyStyle(label, fonts)
    end

    function ZO_PlatformStyleFontAdjustingWrapLabel_OnInitialized(label, keyboardFonts, gamepadFonts, wrapMode)
        FontAdjustingWrapLabel_Initialize(label, wrapMode)
        ZO_PlatformStyle:New(function(...) ApplyStyle(label, ...) end, keyboardFonts, gamepadFonts)
    end
end

function ZO_TooltipIfTruncatedLabel_OnMouseEnter(self)
    if self:WasTruncated() then
        InitializeTooltip(InformationTooltip)
        ZO_Tooltips_SetupDynamicTooltipAnchors(InformationTooltip, self)
        SetTooltipText(InformationTooltip, self:GetText())
    end
end

function ZO_TooltipIfTruncatedLabel_OnMouseExit(self)
    if self:WasTruncated() then
        ClearTooltip(InformationTooltip)
    end
end