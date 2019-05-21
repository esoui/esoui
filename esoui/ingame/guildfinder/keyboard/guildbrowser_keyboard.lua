------------------
-- Guild Finder --
------------------

ZO_GUILD_BROWSER_APPLICATIONS_SUBCATEGORY_ACTIVE = 1
ZO_GUILD_BROWSER_APPLICATIONS_SUBCATEGORY_MESSAGE = 2

local treeIdToCategoryInfo =
{
    [ZO_GUILD_BROWSER_CATEGORY_APPLICATIONS] = 
    {
        name = GetString(SI_GUILD_BROWSER_CATEGORY_APPLICATIONS),
        up = "EsoUI/Art/GuildFinder/Keyboard/guildBrowser_applications_up.dds",
        down = "EsoUI/Art/GuildFinder/Keyboard/guildBrowser_applications_down.dds",
        over = "EsoUI/Art/GuildFinder/Keyboard/guildBrowser_applications_over.dds",
        category = ZO_GUILD_BROWSER_CATEGORY_APPLICATIONS,
        subCategories =
        {
            { name = GetString(SI_GUILD_BROWSER_APPLICATIONS_ACTIVE), value = ZO_GUILD_BROWSER_APPLICATIONS_SUBCATEGORY_ACTIVE },
            { name = GetString(SI_GUILD_BROWSER_APPLICATIONS_MESSAGE), value = ZO_GUILD_BROWSER_APPLICATIONS_SUBCATEGORY_MESSAGE },
        }
    },
    [ZO_GUILD_BROWSER_CATEGORY_GUILD_LIST] = 
    {
        name = GetString(SI_GUILD_BROWSER_CATEGORY_BROWSE_GUILDS),
        up = "EsoUI/Art/GuildFinder/Keyboard/guildBrowser_guildList_up.dds",
        down = "EsoUI/Art/GuildFinder/Keyboard/guildBrowser_guildList_down.dds",
        over = "EsoUI/Art/GuildFinder/Keyboard/guildBrowser_guildList_over.dds",
        category = ZO_GUILD_BROWSER_CATEGORY_GUILD_LIST,
        subCategories =
        {
            { name = GetString("SI_GUILDFOCUSATTRIBUTEVALUE", GUILD_FOCUS_ATTRIBUTE_VALUE_TRADING), value = GUILD_FOCUS_ATTRIBUTE_VALUE_TRADING },
            { name = GetString("SI_GUILDFOCUSATTRIBUTEVALUE", GUILD_FOCUS_ATTRIBUTE_VALUE_GROUP_PVE), value = GUILD_FOCUS_ATTRIBUTE_VALUE_GROUP_PVE },
            { name = GetString("SI_GUILDFOCUSATTRIBUTEVALUE", GUILD_FOCUS_ATTRIBUTE_VALUE_ROLEPLAYING), value = GUILD_FOCUS_ATTRIBUTE_VALUE_ROLEPLAYING },
            { name = GetString("SI_GUILDFOCUSATTRIBUTEVALUE", GUILD_FOCUS_ATTRIBUTE_VALUE_SOCIAL), value = GUILD_FOCUS_ATTRIBUTE_VALUE_SOCIAL },
            { name = GetString("SI_GUILDFOCUSATTRIBUTEVALUE", GUILD_FOCUS_ATTRIBUTE_VALUE_PVP), value = GUILD_FOCUS_ATTRIBUTE_VALUE_PVP },
            { name = GetString("SI_GUILDFOCUSATTRIBUTEVALUE", GUILD_FOCUS_ATTRIBUTE_VALUE_QUESTING), value = GUILD_FOCUS_ATTRIBUTE_VALUE_QUESTING },
            { name = GetString("SI_GUILDFOCUSATTRIBUTEVALUE", GUILD_FOCUS_ATTRIBUTE_VALUE_CRAFTING), value = GUILD_FOCUS_ATTRIBUTE_VALUE_CRAFTING },
        }
    },
}

local ZO_GuildBrowser_Keyboard = ZO_Object.MultiSubclass(ZO_GuildBrowser_Shared, ZO_GuildFinder_Keyboard_Base)

function ZO_GuildBrowser_Keyboard:New(...)
    return ZO_GuildFinder_Keyboard_Base.New(self, ...)
end

function ZO_GuildBrowser_Keyboard:Initialize(control)
    ZO_GuildBrowser_Shared.Initialize(self, control)
    ZO_GuildFinder_Keyboard_Base.Initialize(self, control)

    self.applicationsLabel = self.control:GetNamedChild("PersonalData"):GetNamedChild("ApplicationsLabel")
    self:UpdateApplicationsLabel()

    KEYBOARD_GUILD_BROWSER_SCENE = ZO_Scene:New("guildBrowserKeyboard", SCENE_MANAGER)
    KEYBOARD_GUILD_BROWSER_SCENE:RegisterCallback("StateChange", function(oldState, state)
                                                                if state == SCENE_SHOWING then
                                                                    self:OnShowing()
                                                                elseif state == SCENE_HIDDEN then
                                                                    self:OnHidden()
                                                                end
                                                            end)

    KEYBOARD_GUILD_BROWSER_FRAGMENT = ZO_FadeSceneFragment:New(self.control)

    self:SetupData(treeIdToCategoryInfo)

    GUILD_BROWSER_MANAGER:RegisterCallback("OnApplicationsChanged", function() self:UpdateApplicationsLabel() end)
end

function ZO_GuildBrowser_Keyboard:DeferredInitialize()
    if self.hasDeferredInitialized then
        return
    end

    treeIdToCategoryInfo[ZO_GUILD_BROWSER_CATEGORY_GUILD_LIST].manager = GUILD_BROWSER_GUILD_LIST_KEYBOARD
    treeIdToCategoryInfo[ZO_GUILD_BROWSER_CATEGORY_APPLICATIONS].manager = GUILD_BROWSER_APPLICATIONS_KEYBOARD

    self.hasDeferredInitialized = true
end

function ZO_GuildBrowser_Keyboard:UpdateApplicationsLabel()
    local applicationLabelText = zo_strformat(SI_GUILD_BROWSER_APPLICATIONS_QUANTITY_FORMATTER, GetGuildFinderNumAccountApplications(), MAX_GUILD_FINDER_APPLICATIONS_PER_ACCOUNT)
    self.applicationsLabel:SetText(applicationLabelText)
end

function ZO_GuildBrowser_Keyboard:ShowApplicationsList()
    local targetNode = self.nodeLookupTable[ZO_GUILD_BROWSER_CATEGORY_APPLICATIONS].subCategories[ZO_GUILD_BROWSER_APPLICATIONS_SUBCATEGORY_ACTIVE]
    self.categoryTree:SelectNode(targetNode)
end

function ZO_GuildBrowser_Keyboard:IsSceneShown()
    return KEYBOARD_GUILD_BROWSER_SCENE:IsShowing()
end

function ZO_GuildBrowser_Keyboard:OnShowing()
    ZO_GuildBrowser_Shared.OnShowing(self)
    self:DeferredInitialize()
    self:ShowSelectedCategory()
    -- we cleared our results when exiting this scene. If we open it back up and are on the searching category
    -- we need to start a new search since the old data was old
    if self.selectedCategory.category == ZO_GUILD_BROWSER_CATEGORY_GUILD_LIST then
        GUILD_BROWSER_MANAGER:ExecuteSearch()
    end
end

function ZO_GuildBrowser_Keyboard:OnHidden()
    ZO_GuildBrowser_Shared.OnHidden(self)
    GUILD_BROWSER_MANAGER:ClearCurrentFoundGuilds()
end

function ZO_GuildBrowser_Keyboard:SetCategoryTreeHidden(hidden)
    self.listContainer:SetHidden(hidden)
end

-- XML Functions
-----------------

function ZO_GuildBrowser_Keyboard_OnInitialized(control)
    GUILD_BROWSER_KEYBOARD = ZO_GuildBrowser_Keyboard:New(control)
end
