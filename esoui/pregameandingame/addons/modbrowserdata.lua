-----------------------------------------
--- Mod Browser Listing Search Data   ---
-----------------------------------------

ZO_ModBrowserListingSearchData = ZO_InitializingObject:Subclass()

function ZO_ModBrowserListingSearchData:Initialize(listingIndex)
    self.listingIndex = listingIndex
end

function ZO_ModBrowserListingSearchData:GetListingIndex()
    return self.listingIndex
end

function ZO_ModBrowserListingSearchData:GetTitle()
    return GetModListingTitle(self.listingIndex)
end

function ZO_ModBrowserListingSearchData:GetAuthor()
    return GetModListingAuthor(self.listingIndex)
end

function ZO_ModBrowserListingSearchData:GetOverview()
    return GetModListingOverview(self.listingIndex)
end

function ZO_ModBrowserListingSearchData:GetDescription()
    return GetModListingDescription(self.listingIndex)
end

function ZO_ModBrowserListingSearchData:GetNumUsers()
    return GetModListingNumUsers(self.listingIndex)
end

function ZO_ModBrowserListingSearchData:GetInstallState()
    return GetModListingInstallState(self.listingIndex)
end

function ZO_ModBrowserListingSearchData:GetInstallStateText()
    return GetString("SI_MODINSTALLSTATE", self:GetInstallState())
end

function ZO_ModBrowserListingSearchData:GetFormattedLastUpdatedTime()
    local lastUpdatedTime = GetModListingLastUpdatedTime(self.listingIndex)
    local year, month, day = GetDateElementsFromTimestamp(lastUpdatedTime)
    return ZO_FormatGregorianDate(year, month, day)
end

function ZO_ModBrowserListingSearchData:GetLatestVersion()
    return GetModListingLatestVersion(self.listingIndex)
end

function ZO_ModBrowserListingSearchData:GetNumReleases()
    return GetNumReleasesForModListing(self.listingIndex)
end

function ZO_ModBrowserListingSearchData:GetReleaseVersion(releaseIndex)
    return GetModListingReleaseVersion(self.listingIndex, releaseIndex)
end

function ZO_ModBrowserListingSearchData:GetFormattedReleaseCreationTime(releaseIndex)
    local creationTime = GetModListingReleaseCreationTime(self.listingIndex, releaseIndex)
    local year, month, day = GetDateElementsFromTimestamp(creationTime)
    return ZO_FormatGregorianDate(year, month, day)
end

function ZO_ModBrowserListingSearchData:IsReleaseNoteReady(releaseIndex)
    return IsModListingReleaseNoteReady(self.listingIndex, releaseIndex)
end

function ZO_ModBrowserListingSearchData:RequestLoadReleaseNote(releaseIndex)
    if not self:IsReleaseNoteReady(releaseIndex) then
        RequestLoadModListingReleaseNote(self.listingIndex, releaseIndex)
    end
end

function ZO_ModBrowserListingSearchData:GetReleaseNote(releaseIndex)
    return GetModListingReleaseNote(self.listingIndex, releaseIndex)
end

function ZO_ModBrowserListingSearchData:GetCategory()
    return GetModListingCategory(self.listingIndex)
end

do
    internalassert(MOD_BROWSER_CATEGORY_TYPE_MAX_VALUE == 25, "A new mod browser category type has been added. It will need to be added to the CATEGORY_TO_ICON table.")
    local CATEGORY_TO_ICON =
    {
        [MOD_BROWSER_CATEGORY_TYPE_LIBRARIES] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_libraries.dds",
        [MOD_BROWSER_CATEGORY_TYPE_MAIL] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_mail.dds",
        [MOD_BROWSER_CATEGORY_TYPE_COMBAT] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_combat.dds",
        [MOD_BROWSER_CATEGORY_TYPE_CHAT] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_chat.dds",
        [MOD_BROWSER_CATEGORY_TYPE_MISC] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_misc.dds",
        [MOD_BROWSER_CATEGORY_TYPE_ABILITY_BAR] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_abilityBar.dds",
        [MOD_BROWSER_CATEGORY_TYPE_GUILD_TRADERS_AND_VENDORS] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_guildTradersAndVendors.dds",
        [MOD_BROWSER_CATEGORY_TYPE_BANK_AND_INVENTORY] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_bankAndInventory.dds",
        [MOD_BROWSER_CATEGORY_TYPE_BUFFS_AND_DEBUFFS] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_buffsAndDebuffs.dds",
        [MOD_BROWSER_CATEGORY_TYPE_CAST_BARS_AND_COOLDOWNS] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_castBarsAndCooldowns.dds",
        [MOD_BROWSER_CATEGORY_TYPE_CHARACTER_PROGRESSION] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_characterProgression.dds",
        [MOD_BROWSER_CATEGORY_TYPE_CRAFTING] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_crafting.dds",
        [MOD_BROWSER_CATEGORY_TYPE_DATA] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_data.dds",
        [MOD_BROWSER_CATEGORY_TYPE_UI_GRAPHICS] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_uiGraphics.dds",
        [MOD_BROWSER_CATEGORY_TYPE_SOCIAL] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_social.dds",
        [MOD_BROWSER_CATEGORY_TYPE_HOUSING] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_housing.dds",
        [MOD_BROWSER_CATEGORY_TYPE_INFO_AND_PLUGIN_BARS] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_infoAndPluginBars.dds",
        [MOD_BROWSER_CATEGORY_TYPE_MAP_AND_COMPASS] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_mapAndCompass.dds",
        [MOD_BROWSER_CATEGORY_TYPE_PVP] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_pvp.dds",
        [MOD_BROWSER_CATEGORY_TYPE_ROLEPLAY] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_roleplay.dds",
        [MOD_BROWSER_CATEGORY_TYPE_TOOLTIP] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_tooltip.dds",
        [MOD_BROWSER_CATEGORY_TYPE_TRIALS] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_trials.dds",
        [MOD_BROWSER_CATEGORY_TYPE_UNIT_FRAMES] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_unitFrames.dds",
        [MOD_BROWSER_CATEGORY_TYPE_UTILITY] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_utility.dds",
        [MOD_BROWSER_CATEGORY_TYPE_BETA] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_beta.dds",
        [MOD_BROWSER_CATEGORY_TYPE_PLUGINS_AND_PATCHES] = "EsoUI/Art/Addons/Gamepad/gp_mod_listing_category_pluginsAndPatches.dds",
    }

    function ZO_ModBrowserListingSearchData:GetCategoryIcon()
        local category = self:GetCategory()
        return CATEGORY_TO_ICON[category]
    end
end

function ZO_ModBrowserListingSearchData:GetNumImages()
    return GetModListingNumImages(self.listingIndex)
end

function ZO_ModBrowserListingSearchData:IsImageReady(imageIndex)
    return IsModListingImageReady(self.listingIndex, imageIndex)
end

do
    local DEFAULT_MOD_BROWSER_IMAGE_DESIRED_WIDTH = 400
    local DEFAULT_MOD_BROWSER_IMAGE_DESIRED_HEIGHT = 400

    function ZO_ModBrowserListingSearchData:RequestLoadImage(imageIndex, desiredWidth, desiredHeight)
        if not self:IsImageReady(imageIndex) then
            local width = desiredWidth or DEFAULT_MOD_BROWSER_IMAGE_DESIRED_WIDTH
            local height = desiredHeight or DEFAULT_MOD_BROWSER_IMAGE_DESIRED_HEIGHT
            RequestLoadModListingImage(self.listingIndex, imageIndex, width, height)
        end
    end
end

function ZO_ModBrowserListingSearchData:GetImage(imageIndex)
    return GetModListingImage(self.listingIndex, imageIndex)
end

function ZO_ModBrowserListingSearchData:GetNumDependencies()
    return GetModListingNumDependencies(self.listingIndex)
end

function ZO_ModBrowserListingSearchData:AreDependenciesReady()
    return AreModListingDependenciesReady(self.listingIndex)
end

function ZO_ModBrowserListingSearchData:RequestLoadDependencies()
    if not self:AreDependenciesReady() then
        RequestLoadModListingDependencies(self.listingIndex)
    end
end

function ZO_ModBrowserListingSearchData:GetDependencyTitle(dependencyIndex)
    return GetModListingDependencyTitle(self.listingIndex, dependencyIndex)
end

function ZO_ModBrowserListingSearchData:GetDependencyInstallState(dependencyIndex)
    return GetModListingDependencyInstallState(self.listingIndex, dependencyIndex)
end

function ZO_ModBrowserListingSearchData:GetFormattedDependencyText()
    local formattedText = ""
    local numDependencies = self:GetNumDependencies()
    if self:AreDependenciesReady() and numDependencies > 0 then
        for dependencyIndex = 1, numDependencies do
            local dependencyName = self:GetDependencyTitle(dependencyIndex)
            local dependencyInstallState = self:GetDependencyInstallState(dependencyIndex)

            local dependencyLine = zo_strformat(SI_GAMEPAD_MOD_BROWSER_DEPENDENCY_FORMATTER, dependencyName, GetString("SI_MODINSTALLSTATE", dependencyInstallState))

            if dependencyInstallState == MOD_INSTALL_STATE_NOT_INSTALLED or dependencyInstallState == MOD_INSTALL_STATE_UNINSTALLING then
                dependencyLine = ZO_ERROR_COLOR:Colorize(dependencyLine)
            elseif dependencyInstallState == MOD_INSTALL_STATE_UPDATE_AVAILABLE then
                dependencyLine = ZO_SUCCEEDED_TEXT:Colorize(dependencyLine)
            end

            if formattedText == "" then
                formattedText = string.format("%s  %s", GetString(SI_BULLET), dependencyLine)
            else
                formattedText = string.format("%s\n%s  %s", formattedText, GetString(SI_BULLET), dependencyLine)
            end
        end
    end

    return formattedText
end

function ZO_ModBrowserListingSearchData:IsInstalled()
    return self:GetInstallState() == MOD_INSTALL_STATE_INSTALLED or self:GetInstallState() == MOD_INSTALL_STATE_UPDATE_AVAILABLE
end

function ZO_ModBrowserListingSearchData:Install()
    if self:GetInstallState() == MOD_INSTALL_STATE_NOT_INSTALLED or self:GetInstallState() == MOD_INSTALL_STATE_UPDATE_AVAILABLE then
        InstallModListing(self.listingIndex)
    end
end

function ZO_ModBrowserListingSearchData:Uninstall(deleteSavedVariables)
    if self:IsInstalled() then
        UninstallModListing(self.listingIndex, deleteSavedVariables)
    end
end

function ZO_ModBrowserListingSearchData:Reinstall()
    if self:IsInstalled() then
        ReinstallModListing(self.listingIndex)
    end
end

function ZO_ModBrowserListingSearchData:DeleteSavedVariables()
    if self:IsInstalled() then
        DeleteSavedVariablesForModListing(self.listingIndex)
    end
end

function ZO_ModBrowserListingSearchData:GetSavedVariablesDiskUsageMB()
    if self:IsInstalled() then
        return GetSavedVariablesDiskUsageMBForModListing(self.listingIndex)
    else
        return 0
    end
end

function ZO_ModBrowserListingSearchData:SetIgnoreUpdates(ignoreUpdates)
    if self:IsInstalled() then
        SetModListingIgnoresUpdates(self.listingIndex, ignoreUpdates)
    end
end

function ZO_ModBrowserListingSearchData:GetIgnoreUpdates()
    if self:IsInstalled() then
        return GetModListingIgnoresUpdates(self.listingIndex)
    end
    return false
end

function ZO_ModBrowserListingSearchData:Report(reportSource, reportReason, comment)
    return ReportModListing(self.listingIndex, reportSource, reportReason, comment)
end