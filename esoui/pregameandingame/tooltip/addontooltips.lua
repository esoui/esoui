local AddOnManager = GetAddOnManager()

function ZO_Tooltip:LayoutAddOnTooltip(data, isSpecificCharacterSelected)
    --Things added to the top section stack downward
    local topSection = self:AcquireSection(self:GetStyle("addOnTopSection"))

    local _, _, _, description, enabled, _, isOutOfDate = AddOnManager:GetAddOnInfo(data.addOnIndex)

    -- Does the addon have a dependency?
    if data.hasDependencyError then
        topSection:AddLine(ZO_ERROR_COLOR:Colorize(GetString("SI_ADDONLOADSTATE", ADDON_STATE_DEPENDENCIES_DISABLED)))
    end
    
    -- Is the addon out of date?
    if isOutOfDate then
        topSection:AddLine(GetString("SI_ADDONLOADSTATE", ADDON_STATE_VERSION_MISMATCH))
    end
    
    -- Determine whether the addon is enabled or disabled
    local showEnabled
    if isSpecificCharacterSelected then
        local canEnable = HasAgreedToEULA(EULA_TYPE_ADDON_EULA) and not data.hasDependencyError
        showEnabled = canEnable and enabled
    else
        showEnabled = HasAgreedToEULA(EULA_TYPE_ADDON_EULA) and not data.allDisabled
    end

    if showEnabled then
        topSection:AddLine(GetString(SI_GAMEPAD_ADDON_MANAGER_TOOLTIP_ENABLED))
    else
        topSection:AddLine(GetString(SI_GAMEPAD_ADDON_MANAGER_TOOLTIP_DISABLED))
    end
    self:AddSection(topSection)

    --Add the addon name
    self:AddLine(data.addOnName, self:GetStyle("addOnName"))

    --Add the author
    local authorPair = self:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
    authorPair:SetStat(GetString(SI_GAMEPAD_ADDON_MANAGER_TOOLTIP_AUTHOR), self:GetStyle("statValuePairStat"))
    authorPair:SetValue(data.addOnAuthor, self:GetStyle("statValuePairValueSmall"))
    self:AddStatValuePair(authorPair)

    --Add the description if there is one
    if description ~= "" then
        local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
        bodySection:AddLine(description, self:GetStyle("bodyDescription"))
        self:AddSection(bodySection)
    end

    -- Add the dependency text if there is any
    if data.addOnDependencyText ~= "" then
        local dependencySection = self:AcquireSection(self:GetStyle("bodySection"))
        dependencySection:AddLine(GetString(SI_ADDON_MANAGER_DEPENDENCIES), self:GetStyle("bodyHeader"))
        dependencySection:AddLine(data.addOnDependencyText, self:GetStyle("bodyDescription"))
        self:AddSection(dependencySection)
    end

    -- If a specific character is not selected, include additional information about the enabled state of the addon
    if not isSpecificCharacterSelected then
        local enableSection = self:AcquireSection(self:GetStyle("bodySection"))
        if data.allEnabled then
            enableSection:AddLine(GetString(SI_ADDON_MANAGER_TOOLTIP_ENABLED_ALL), self:GetStyle("bodyDescription"))
        elseif data.allDisabled then
            enableSection:AddLine(GetString(SI_ADDON_MANAGER_TOOLTIP_ENABLED_NONE), self:GetStyle("bodyDescription"))
        else
            enableSection:AddLine(GetString(SI_ADDON_MANAGER_TOOLTIP_ENABLED_SOME), self:GetStyle("bodyDescription"))
        end
        self:AddSection(enableSection)
    end
end

function ZO_Tooltip:LayoutModTooltip(data, imageIndex)
    --Things added to the top section stack downward
    local topSection = self:AcquireSection(self:GetStyle("addOnTopSection"))

    -- Mod Category
    local category = data:GetCategory()
    topSection:AddLine(GetString("SI_MODBROWSERCATEGORYTYPE", category))

    -- Mod Version
    local version = data:GetLatestVersion()
    topSection:AddLine(zo_strformat(SI_GAMEPAD_MOD_BROWSER_LISTING_TOOLTIP_VERSION, version))

    -- Last Updated
    topSection:AddLine(zo_strformat(SI_GAMEPAD_MOD_BROWSER_LISTING_TOOLTIP_LAST_UPDATED, data:GetFormattedLastUpdatedTime()))

    --Install State
    topSection:AddLine(data:GetInstallStateText())
    self:AddSection(topSection)

    --Add the mod name
    self:AddLine(data:GetTitle(), self:GetStyle("addOnName"))

    --Add the author
    local authorPair = self:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
    authorPair:SetStat(GetString(SI_GAMEPAD_ADDON_MANAGER_TOOLTIP_AUTHOR), self:GetStyle("statValuePairStat"))
    authorPair:SetValue(data:GetAuthor(), self:GetStyle("statValuePairValueSmall"))
    self:AddStatValuePair(authorPair)

    local numImages = data:GetNumImages()
    if numImages ~= nil then
        if numImages > 0 then
            --Show the image if it's ready, otherwise start loading the image and show a loading spinner
            if data:IsImageReady(imageIndex) then
                if imageIndex < numImages then
                    --If the current image is ready and there is a next image, preload it now
                    data:RequestLoadImage(imageIndex + 1)
                end

                local image = data:GetImage(imageIndex)
                local imageControl = self:AcquireCustomControl(self:GetStyle("modBrowserListingImage"))
                imageControl:GetNamedChild("Image"):SetTextureFromGuiTexture(image)
                self:AddCustomControl(imageControl)
            else
                data:RequestLoadImage(imageIndex)
                local loadingControl = self:AcquireCustomControl(self:GetStyle("modBrowserListingLoadingIcon"))
                self:AddCustomControl(loadingControl)
            end
        end

        --If there are at least 2 images, show the pips underneath
        if numImages > 1 then
            local function GetPipNarration()
                return zo_strformat(SI_SCREEN_NARRATION_MOD_BROWSER_IMAGE_FORMATTER, imageIndex, numImages)
            end
            local selectionIndicatorControl = self:AcquireCustomControl(self:GetStyle("modBrowserListingSelectionIndicator"))
            local selectionIndicator = selectionIndicatorControl:GetNamedChild("Indicator").object
            selectionIndicator:SetButtonClickedEnabled(false)
            selectionIndicator:SetGrowthPadding(10)
            selectionIndicator:SetCount(numImages)
            selectionIndicator:SetSelectionByIndex(imageIndex)

            self:AddCustomControl(selectionIndicatorControl, GetPipNarration)
        end
    else
        --If we get here, we do not yet know how many images there are, so request the image (which will fetch the number of images as well) and show a loading spinner without the pips
        data:RequestLoadImage(imageIndex)
        local loadingControl = self:AcquireCustomControl(self:GetStyle("modBrowserListingLoadingIcon"))
        self:AddCustomControl(loadingControl)
    end

    --Add the overview if there is one
    local overview = data:GetOverview()
    if overview ~= "" then
        local overviewSection = self:AcquireSection(self:GetStyle("bodySection"))
        overviewSection:AddLine(overview, self:GetStyle("bodyDescription"))
        self:AddSection(overviewSection)
    end

    --Add the description if there is one
    local description = data:GetDescription()
    if description ~= "" then
        local descriptionSection = self:AcquireSection(self:GetStyle("bodySection"))
        descriptionSection:AddLine(description, self:GetStyle("bodyDescription"))
        self:AddSection(descriptionSection)
    end

    local numDependencies = data:GetNumDependencies()
    if numDependencies > 0 then
        --Show the dependencies if they're ready, otherwise start loading the dependencies and show a loading spinner
        if data:AreDependenciesReady() then
            local dependencySection = self:AcquireSection(self:GetStyle("bodySection"))
            dependencySection:AddLine(GetString(SI_ADDON_MANAGER_DEPENDENCIES), self:GetStyle("bodyHeader"))
            dependencySection:AddLine(data:GetFormattedDependencyText(), self:GetStyle("bodyDescription"))
            self:AddSection(dependencySection)
        else
            data:RequestLoadDependencies()
            local loadingControl = self:AcquireCustomControl(self:GetStyle("modBrowserListingLoadingIcon"))
            self:AddCustomControl(loadingControl)
        end
    end
end

function ZO_Tooltip:LayoutModListingReleaseTooltip(data, releaseIndex)
    --Things added to the top section stack downward
    local topSection = self:AcquireSection(self:GetStyle("addOnTopSection"))

    -- Mod Version
    local version = data:GetReleaseVersion(releaseIndex)
    topSection:AddLine(zo_strformat(SI_GAMEPAD_MOD_BROWSER_LISTING_TOOLTIP_VERSION, version))

    -- Creation Time
    topSection:AddLine(zo_strformat(SI_GAMEPAD_MOD_BROWSER_LISTING_RELEASE_NOTE_TOOLTIP_CREATED, data:GetFormattedReleaseCreationTime(releaseIndex)))

    self:AddSection(topSection)

    -- Show the release note if it's ready, otherwise request to load it and show the loading spinner
    if data:IsReleaseNoteReady(releaseIndex) then
        local releaseNoteSection = self:AcquireSection(self:GetStyle("bodySection"))
        releaseNoteSection:AddLine(data:GetReleaseNote(releaseIndex), self:GetStyle("bodyDescription"))
        self:AddSection(releaseNoteSection)
    else
        data:RequestLoadReleaseNote(releaseIndex)
        local loadingControl = self:AcquireCustomControl(self:GetStyle("modBrowserListingLoadingIcon"))
        self:AddCustomControl(loadingControl)
    end
end