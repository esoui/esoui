------------------
-- Guild Finder --
------------------
ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_GUILD_LISTING = 1
ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_APPLICATIONS = 2
ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_BLACKLIST = 3

ZO_GUILD_RECRUITMENT_APPLICATIONS_SUBCATEGORY_KEYBOARD_RECEIVED = 1
ZO_GUILD_RECRUITMENT_APPLICATIONS_SUBCATEGORY_KEYBOARD_MESSAGE = 2

local treeIdToCategoryInfo =
{
    [ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_GUILD_LISTING] =
    {
        categoryIndex = ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_GUILD_LISTING,
        name = GetString(SI_GUILD_RECRUITMENT_CATEGORY_GUILD_LISTING),
        up = "EsoUI/Art/GuildFinder/Keyboard/guildRecruitment_guildListing_up.dds",
        down = "EsoUI/Art/GuildFinder/Keyboard/guildRecruitment_guildListing_down.dds",
        over = "EsoUI/Art/GuildFinder/Keyboard/guildRecruitment_guildListing_over.dds",
    },
    [ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_APPLICATIONS] =
    {
        categoryIndex = ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_APPLICATIONS,
        name = GetString(SI_GUILD_RECRUITMENT_CATEGORY_APPLICATIONS),
        up = "EsoUI/Art/GuildFinder/Keyboard/guildRecruitment_applications_up.dds",
        down = "EsoUI/Art/GuildFinder/Keyboard/guildRecruitment_applications_down.dds",
        over = "EsoUI/Art/GuildFinder/Keyboard/guildRecruitment_applications_over.dds",
        visible = function(self) return DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_MANAGE_APPLICATIONS) end,
        subCategories =
        {
            { name = GetString(SI_GUILD_RECRUITMENT_APPLICATIONS_RECEIVED), value = ZO_GUILD_RECRUITMENT_APPLICATIONS_SUBCATEGORY_KEYBOARD_RECEIVED },
            { name = GetString(SI_GUILD_RECRUITMENT_APPLICATIONS_MESSAGE), value = ZO_GUILD_RECRUITMENT_APPLICATIONS_SUBCATEGORY_KEYBOARD_MESSAGE },
        }
    },
    [ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_BLACKLIST] =
    {
        categoryIndex = ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_BLACKLIST,
        name = GetString(SI_GUILD_RECRUITMENT_CATEGORY_BLACKLIST),
        up = "EsoUI/Art/GuildFinder/Keyboard/guildRecruitment_blacklist_up.dds",
        down = "EsoUI/Art/GuildFinder/Keyboard/guildRecruitment_blacklist_down.dds",
        over = "EsoUI/Art/GuildFinder/Keyboard/guildRecruitment_blacklist_over.dds",
        visible = function(self) return DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_MANAGE_BLACKLIST) end,
    },
}

ZO_GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD_COLUMN_WIDTH = 300

ZO_GuildRecruitment_Keyboard = ZO_Object.MultiSubclass(ZO_GuildRecruitment_Shared, ZO_GuildFinder_Keyboard_Base)

function ZO_GuildRecruitment_Keyboard:New(...)
    return ZO_GuildFinder_Keyboard_Base.New(self, ...)
end

function ZO_GuildRecruitment_Keyboard:Initialize(control)
    self.iconChildlessHeaderTemplateName = "ZO_GuildRecruitment_IconChildlessHeader"
    self.onSetupChildHeader = function(node, control, data, open, userRequested)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(data.name)

        -- SetupControlIcon
        control.icon:SetTexture(open and data.down or data.up)
        control.iconHighlight:SetTexture(data.over)
        ZO_IconHeader_Setup(control, open)

        if open and userRequested then
            self.categoryTree:SelectFirstChild(node)
        end
    end

    ZO_GuildRecruitment_Shared.Initialize(self, control)
    ZO_GuildFinder_Keyboard_Base.Initialize(self, control)

    KEYBOARD_GUILD_RECRUITMENT_SCENE = ZO_Scene:New("guildRecruitmentKeyboard", SCENE_MANAGER)
    KEYBOARD_GUILD_RECRUITMENT_SCENE:RegisterCallback("StateChange", function(oldState, state)
                                                                if(state == SCENE_SHOWING) then
                                                                    self:OnShowing()
                                                                elseif(state == SCENE_HIDDEN) then
                                                                    self:OnHidden()
                                                                end
                                                            end)

    KEYBOARD_GUILD_RECRUITMENT_FRAGMENT = ZO_FadeSceneFragment:New(self.control)

    self:SetupData(treeIdToCategoryInfo)
end

function ZO_GuildRecruitment_Keyboard:DeferredInitialize()
    if self.hasDeferredInitialized then
        return
    end

    treeIdToCategoryInfo[ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_APPLICATIONS].manager = GUILD_RECRUITMENT_APPLICATIONS_KEYBOARD
    treeIdToCategoryInfo[ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_BLACKLIST].manager = GUILD_RECRUITMENT_BLACKLIST_KEYBOARD

    self.hasDeferredInitialized = true

    if self.isGuildIdReady then
        self:SetGuildId(self.guildId)
    end
end

function ZO_GuildRecruitment_Keyboard:SetGuildId(guildId)
    ZO_GuildRecruitment_Shared.SetGuildId(self, guildId)

    self:RefreshGuildPermissionsState()

    self.isGuildIdReady = true
end

function ZO_GuildRecruitment_Keyboard:RefreshGuildPermissionsState()
    if treeIdToCategoryInfo[ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_GUILD_LISTING].manager then
        treeIdToCategoryInfo[ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_GUILD_LISTING].manager:HideCategory()
    end

    if IsPlayerGuildMaster(self.guildId) then
        treeIdToCategoryInfo[ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_GUILD_LISTING].manager = GUILD_RECRUITMENT_GUILD_LISTING_KEYBOARD
    else
        treeIdToCategoryInfo[ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_GUILD_LISTING].manager = GUILD_RECRUITMENT_GUILD_LISTING_INFO_KEYBOARD
    end

    if self.hasDeferredInitialized then
        self:SetupData(treeIdToCategoryInfo)

        for i, data in ipairs(treeIdToCategoryInfo) do
            data.manager:SetGuildId(self.guildId)
        end

        if self.openApplicationsOnShowing then
            self:SetSelectedCategory(treeIdToCategoryInfo[ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_APPLICATIONS], ZO_GUILD_RECRUITMENT_APPLICATIONS_SUBCATEGORY_KEYBOARD_RECEIVED)
        end

        self:ShowSelectedCategory()
    end
end

function ZO_GuildRecruitment_Keyboard:ShowApplicationsList()
    if self:IsSceneShown() then
        local targetNode = self.nodeLookupTable[ZO_GUILD_RECRUITMENT_CATEGORY_KEYBOARD_APPLICATIONS].subCategories[ZO_GUILD_RECRUITMENT_APPLICATIONS_SUBCATEGORY_KEYBOARD_RECEIVED]
        self.categoryTree:SelectNode(targetNode)
    else
        self.openApplicationsOnShowing = true
    end
end

function ZO_GuildRecruitment_Keyboard:IsSceneShown()
    return KEYBOARD_GUILD_RECRUITMENT_SCENE:IsShowing()
end

function ZO_GuildRecruitment_Keyboard:OnShowing()
    self:DeferredInitialize()
    if self.openApplicationsOnShowing then
        self:ShowApplicationsList()
        self.openApplicationsOnShowing = false
    else
        self:ShowSelectedCategory()
    end
end

function ZO_GuildRecruitment_Keyboard:OnHidden()
    if self.selectedCategory then
        self.selectedCategory.manager:HideCategory()
    end
end

-- XML Functions
-----------------

function ZO_GuildRecruitment_Keyboard_OnInitialized(control)
    GUILD_RECRUITMENT_KEYBOARD = ZO_GuildRecruitment_Keyboard:New(control)
end

function ZO_GuildRecruitment_IconChildlessHeader_OnInitialized(control)
    ZO_IconHeader_OnInitialized(control)
    control.OnMouseUp = ZO_GuildRecruitment_TreeEntry_OnMouseUp
    control.SetSelected = ZO_IconHeader_Setup
end

function ZO_GuildRecruitment_TreeEntry_OnMouseUp(self, upInside)
    if upInside and self.node.tree.enabled then
        -- Play the selected sound if not already selected
        if not self.node:IsEnabled() then
            PlaySound(SOUNDS.NEGATIVE_CLICK)
        elseif not self.node.selected and self.node.selectSound then
            PlaySound(self.node.selectSound)
        end

        local NOT_REBUILDING = false
        local DONT_BRING_PARENT_INTO_VIEW = false
        self.node:GetTree():SelectNode(self.node, NOT_REBUILDING, DONT_BRING_PARENT_INTO_VIEW)
    end
end