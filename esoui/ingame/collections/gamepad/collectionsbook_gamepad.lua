
local GAMEPAD_COLLECTIONS_ACTIONS_DIALOG_NAME = "GAMEPAD_COLLECTIONS_ACTIONS_DIALOG"
local GAMEPAD_COLLECTIONS_RENAME_COLLECTIBLE_DIALOG_NAME = "GAMEPAD_COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE"

local ZO_GamepadCollectionsBook = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_GamepadCollectionsBook:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_GamepadCollectionsBook:Initialize(control)
    GAMEPAD_COLLECTIONS_BOOK_SCENE = ZO_Scene:New("gamepadCollectionsBook", SCENE_MANAGER)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, GAMEPAD_COLLECTIONS_BOOK_SCENE)
    
    self.categoryList = {}
    self.categoryList.list = ZO_Gamepad_ParametricList_Screen.GetMainList(self)
    self.categoryList.fragment = self:GetListFragment(self.categoryList.list)
    self.categoryList.keybind = self.categoryKeybindStripDescriptor
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.categoryKeybindStripDescriptor , self.categoryList.list)
    self.categoryList.headerText = nil
    self.categoryList.titleText = GetString(SI_MAIN_MENU_COLLECTIONS)

    self.collectionList = {}
    self.collectionList.list = self:AddList("Collection")
    self.collectionList.fragment = self:CreateListFragment("Collection")
    self.collectionList.keybind = self.collectionKeybindStripDescriptor
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.collectionKeybindStripDescriptor, self.collectionList.list)
    self.collectionList.headerText = GetString(SI_MAIN_MENU_COLLECTIONS)
    self.collectionList.titleText = nil

    self.currentList = nil

    self.headerData = {}
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    self:InitializeActionsDialog()
    self:InitializeRenameCollectibleDialog()

    SYSTEMS:RegisterGamepadObject(ZO_COLLECTIONS_SYSTEM_NAME, self)

    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectibleUpdated", function(...) self:OnCollectibleUpdated(...) end)
    COLLECTIONS_BOOK_SINGLETON:RegisterCallback("OnCollectionUpdated", function(...) self:OnCollectionUpdated(...) end)
end

function ZO_GamepadCollectionsBook:SetupList(list)
    ZO_Gamepad_ParametricList_Screen.SetupList(self, list)

    list:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_GamepadCollectionsBook:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    
    self:ShowList(self.categoryList)
    if self.browseToCollectibleInfo then
        self:ViewCategory(self.browseToCollectibleInfo.categoryIndex)
        self.browseToCollectibleInfo = nil
    end
end

function ZO_GamepadCollectionsBook:OnHide()
    self:HideCurrentList()
end

function ZO_GamepadCollectionsBook:InitializeKeybindStripDescriptors()
    -- Category Keybind
    self.categoryKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select Category
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:ViewCategory()
            end,
            visible = function()
                if self.currentList then
                    local entryData = self.currentList.list:GetTargetData()
                    return entryData ~= nil
                end
                return false
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.categoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    -- Collection Keybind
    self.collectionKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Set Active or Put Away Collectible
        {
            name = function()
                local entryData = self.currentList.list:GetTargetData()
                local collectibleData = entryData.data
                return collectibleData.active and GetString(SI_COLLECTIBLE_ACTION_PUT_AWAY) or GetString(SI_COLLECTIBLE_ACTION_SET_ACTIVE)
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local entryData = self.currentList.list:GetTargetData()
                local collectibleData = entryData.data
                UseCollectible(collectibleData.collectibleId)
            end,
            visible = function()
                local entryData = self.currentList.list:GetTargetData()
                if entryData and entryData.data then
                    local collectibleData = entryData.data
                    return collectibleData.useable
                else
                    return false
                end
            end,
            sound = SOUNDS.DEFAULT_CLICK,
        },
        -- Actions
        {
            -- If there is never going to be a "Link to chat" option then there will only ever be "rename."  Since design considers an
            -- "action panel" with only one action silly, we want to just make "rename" the default keybind with no other action layer
            name = GetString(IsChatSystemAvailableForCurrentPlatform() and SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND or SI_COLLECTIBLE_ACTION_RENAME),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local entryData = self.currentList.list:GetTargetData()
                local collectibleData = entryData.data

                if IsChatSystemAvailableForCurrentPlatform() then
                    local dialogData = 
                    {
                        collectibleId = collectibleData.collectibleId,
                        name = collectibleData.nickname,
                        active = collectibleData.active,
                    }
                    ZO_Dialogs_ShowGamepadDialog(GAMEPAD_COLLECTIONS_ACTIONS_DIALOG_NAME, dialogData)
                else
                    ZO_Dialogs_ShowGamepadDialog(GAMEPAD_COLLECTIONS_RENAME_COLLECTIBLE_DIALOG_NAME, { collectibleId = collectibleData.collectibleId, name = collectibleData.nickname })
                end
            end,
            visible = function()
                local entryData = self.currentList.list:GetTargetData()
                local collectibleData = entryData and entryData.data
                
                if collectibleData then
                    if IsChatSystemAvailableForCurrentPlatform() then --Every collectible can link to chat
                        return true
                    else
                        return IsCollectibleRenameable(collectibleData.collectibleId)
                    end
                else
                    return false
                end
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.collectionKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:ShowList(self.categoryList) end )
end

--Opens up the provided category, or the current category if no categoryIndex is provided
function ZO_GamepadCollectionsBook:ViewCategory(categoryIndex)
    if categoryIndex then
        self.categoryList.list:SetSelectedIndexWithoutAnimation(categoryIndex)
    end
    local entryData = self.categoryList.list:GetTargetData()
    self.collectionList.data = entryData.data
    self:BuildCollectionList()
    self:ShowList(self.collectionList)
end

function ZO_GamepadCollectionsBook:PerformUpdate()
   self:BuildCategoryList()
end

function ZO_GamepadCollectionsBook:ShowList(list)
    if self.currentList == list then
        return
    end
    self:HideCurrentList()

    self.currentList = list
    if list then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.currentList.keybind)
        SCENE_MANAGER:AddFragment(list.fragment)
        list.list:Activate()
    end

    self.headerData.titleText = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, list.titleText)
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    if self.currentList == self.collectionList then
        self:RefreshTooltip(self.collectionList.list:GetTargetData())
    end
end

function ZO_GamepadCollectionsBook:HideCurrentList()
    if self.currentList == nil then
        return
    end

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentList.keybind)

    SCENE_MANAGER:RemoveFragment(self.currentList.fragment)
    self.currentList.list:Deactivate()
    self.currentList = nil

    self:RefreshTooltip(nil)
end

function ZO_GamepadCollectionsBook:OnCollectionUpdated()
    if not self.control:IsHidden() then
        if self.categoryList then
            self:BuildCategoryList()
        end
    end
end

function ZO_GamepadCollectionsBook:OnCollectibleUpdated(collectibleId)
    if not self.control:IsHidden() then
        if self.currentList == self.collectionList and self.collectionList then
            self:BuildCollectionList()
        end
    end
end

function ZO_GamepadCollectionsBook:BuildCategoryList()
    self.categoryList.list:Clear()

    -- Add the categories entries
    for categoryIndex = 1, GetNumCollectibleCategories() do
        local categoryName, numSubCategories, numCollectibles, unlockedCollectibles, totalCollectibles, hidesUnearned, categoryType = GetCollectibleCategoryInfo(categoryIndex)
        local gamepadIcon = GetCollectibleCategoryGamepadIcon(categoryIndex)
        categoryName = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, categoryName)
        
        local entryData = ZO_GamepadEntryData:New(categoryName, gamepadIcon or ZO_NO_TEXTURE_FILE)
        entryData.data = {
            categoryIndex = categoryIndex,
            categoryName = categoryName,
            categoryType = categoryType,
            numCollectibles = numCollectibles,
            unlockedCollectibles = unlockedCollectibles,
            totalCollectibles = totalCollectibles,
        }
        entryData:SetIconTintOnSelection(true)

        self.categoryList.list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end
    self.categoryList.list:Commit()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryList.keybind)
end

function ZO_GamepadCollectionsBook:BuildCollectionList()
    self.collectionList.list:Clear()

    local data = self.collectionList.data

    local unlockedData = {}
    local lockedData = {}

    local categoryName, numSubCategories, numCollectibles,_,_,_,categoryType = GetCollectibleCategoryInfo(data.categoryIndex)

    -- Add top level collectibles
    for collectibleIndex = 1, numCollectibles do
        local entryData = self:BuildCollectibleData(data.categoryIndex, nil, collectibleIndex, categoryType)
        if not entryData.data.isPlaceholder then
            if entryData.data.unlocked then
                table.insert(unlockedData, entryData)
            else
                table.insert(lockedData, entryData)
            end
        end
    end

    -- Add subcategories
    for subCategoryIndex=1, numSubCategories do
        local subCategoryName, subNumCollectibles,_,_,subCategoryType = GetCollectibleSubCategoryInfo(data.categoryIndex, subCategoryIndex)
        for collectibleIndex = 1, subNumCollectibles do
            local entryData = self:BuildCollectibleData(data.categoryIndex, subCategoryIndex, collectibleIndex, subCategoryType)
            if not entryData.data.isPlaceholder then
                if entryData.data.unlocked then
                    table.insert(unlockedData, entryData)
                else
                    table.insert(lockedData, entryData)
                end
            end
        end
    end

    self:BuildListFromTable(self.collectionList.list, unlockedData, GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED))
    self:BuildListFromTable(self.collectionList.list, lockedData, GetString("SI_COLLECTIBLEUNLOCKSTATE", COLLECTIBLE_UNLOCK_STATE_LOCKED))

    self.collectionList.list:Commit()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.collectionList.keybind)

    self:RefreshTooltip(self.collectionList.list:GetTargetData())

    self.collectionList.titleText = data.categoryName
end

function ZO_GamepadCollectionsBook:BuildCollectibleData(categoryIndex, subCategoryIndex, collectibleIndex, categoryType)
    local collectibleId = GetCollectibleId(categoryIndex, subCategoryIndex, collectibleIndex)
    local name, description, iconFile, lockedIconFile, unlocked, purchasable, active, _, hint, isPlaceholder = GetCollectibleInfo(collectibleId)
    local unlockState = GetCollectibleUnlockStateById(collectibleId)
    iconFile = unlocked and iconFile or lockedIconFile
    
    local useable = unlocked and COLLECTIONS_INVENTORY_VALID_CATEGORY_TYPES[categoryType] and not (active and categoryType == COLLECTIBLE_CATEGORY_TYPE_MOUNT)

    local entryData = ZO_GamepadEntryData:New(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, name), iconFile)
    entryData.data = {
        name = name,
        nickname = GetCollectibleNickname(collectibleId),
        description = description,
        hint = hint,
        iconFile = iconFile,
        collectibleId = collectibleId,
        unlocked = unlocked,
        unlockState = unlockState,
        purchasable = purchasable,
        useable = useable,
        active = active,
        isPlaceholder = isPlaceholder,
    }
    entryData.isEquippedInCurrentCategory = active
    return entryData
end

function ZO_GamepadCollectionsBook:BuildListFromTable(list, dataTable, header)
    if #dataTable >= 1 then
        for i,entryData in ipairs(dataTable) do
            if i == 1 then
                entryData:SetHeader(header)
                list:AddEntryWithHeader("ZO_GamepadItemEntryTemplate", entryData)
            else
                list:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
            end
        end
    end
end

function ZO_GamepadCollectionsBook:OnSelectionChanged(list, selectedData, oldSelectedData)
    if self.currentList == self.collectionList then
        self:RefreshTooltip(selectedData)
    end
    if self.currentList then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentList.keybind)
    end
end

function ZO_GamepadCollectionsBook:RefreshTooltip(entryData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:SetBottomRailHidden(GAMEPAD_LEFT_TOOLTIP, true)
    if entryData and entryData.data then
        local categoryName = self.collectionList.data.name
        local data = entryData.data
        GAMEPAD_TOOLTIPS:LayoutCollectible(GAMEPAD_LEFT_TOOLTIP, categoryName, data.name, data.nickname, data.unlockState, data.purchasable, data.description, data.hint, data.isPlaceholder)
    end
end

function ZO_GamepadCollectionsBook:BrowseToCollectible(collectibleId, categoryIndex, subcategoryIndex)
    self.browseToCollectibleInfo = 
    {
        categoryIndex = categoryIndex,
        collectibleId = collectibleId,
    }

    SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "gamepadCollectionsBook")
end

--[[Global functions]]--
------------------------

function ZO_GamepadCollectionsBook:InitializeActionsDialog()

    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
    ZO_Dialogs_RegisterCustomDialog(GAMEPAD_COLLECTIONS_ACTIONS_DIALOG_NAME,
    {
        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        canQueue = true,
        setup = function()
            dialog.setupFunc(dialog)
        end,
        title =
        {
            text = SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND,
        },
        parametricList =
        {
            -- Link In Chat
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = {
                    text = GetString(SI_ITEM_ACTION_LINK_TO_CHAT),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function()
                        local link = ZO_LinkHandler_CreateChatLink(GetCollectibleLink, dialog.data.collectibleId)
                        ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link))
                        CHAT_SYSTEM:SubmitTextEntry()
                    end,
                },
            },
            -- Rename
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = {
                    text = GetString(SI_COLLECTIBLE_ACTION_RENAME),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function()
                       ZO_Dialogs_ShowGamepadDialog(GAMEPAD_COLLECTIONS_RENAME_COLLECTIBLE_DIALOG_NAME, { collectibleId = dialog.data.collectibleId, name = dialog.data.name })
                    end,
                    visible = function()
                        return IsCollectibleRenameable(dialog.data.collectibleId)
                    end
                },
            },
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_OK,
                callback =  function(dialog)
                    local data = dialog.entryList:GetTargetData()
                     data.callback()
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        }
    })
end

-------------------
-- Rename Collectible
-------------------

function ZO_GamepadCollectionsBook:InitializeRenameCollectibleDialog()
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    local inputText = ""
    local dialogName = GAMEPAD_COLLECTIONS_RENAME_COLLECTIBLE_DIALOG_NAME

    local function ReleaseDialog()
        ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
    end

    local function UpdateSelectedName(name)
        if(self.selectedName ~= name or not self.noViolations) then
            self.selectedName = name
            self.nameViolations = { IsValidCollectibleName(self.selectedName) }
            self.noViolations = #self.nameViolations == 0
            
            if(not self.noViolations) then
                local HIDE_UNVIOLATED_RULES = true
                local violationString = ZO_ValidNameInstructions_GetViolationString(self.selectedName, self.nameViolations, HIDE_UNVIOLATED_RULES)
            
                local headerData = 
                {
                    titleText = GetString(SI_INVALID_NAME_DIALOG_TITLE),
                    messageText = violationString,
                    messageTextAlignment = TEXT_ALIGN_LEFT,
                }
                GAMEPAD_TOOLTIPS:ShowGenericHeader(GAMEPAD_LEFT_DIALOG_TOOLTIP, headerData)
                ZO_GenericGamepadDialog_ShowTooltip(dialog)
            else
                ZO_GenericGamepadDialog_HideTooltip(dialog)
            end
        end

        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
    end
    
    local function SetActiveEdit(edit)
        local SAVE_EXISTING_TEXT = true
        edit:TakeFocus()
        UpdateSelectedName(inputText)
    end

    ZO_Dialogs_RegisterCustomDialog(dialogName,
    {
        canQueue = true,
        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function()
            dialog.setupFunc(dialog)
        end,

        title =
        {
            text = SI_COLLECTIONS_INVENTORY_DIALOG_RENAME_COLLECTIBLE_TITLE,
        },
        mainText = 
        {
            text = SI_COLLECTIONS_INVENTORY_DIALOG_RENAME_COLLECTIBLE_MAIN,
        },
        parametricList =
        {
            -- user name
            {
                template = "ZO_GamepadTextFieldItem",
                templateData = {
                    nameField = true,
                    textChangedCallback = function(control) 
                        inputText = control:GetText()
                        UpdateSelectedName(inputText)
                    end,  
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.editBoxControl.textChangedCallback = data.textChangedCallback
                        control.editBoxControl:SetMaxInputChars(COLLECTIBLE_NAME_MAX_LENGTH)
                        data.control = control

                        if dialog.data then
                            control.editBoxControl:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, dialog.data.name))
                        else
                            ZO_EditDefaultText_Initialize(control.editBoxControl, "")
                        end
                    end, 
                },
                
            },
        },
        blockDialogReleaseOnPress = true,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback =  function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    SetActiveEdit(data.control.editBoxControl)
                end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_GAMEPAD_COLLECTIONS_SAVE_NAME_OPTION,
                callback =  function(dialog)
                                local collectibleId = dialog.data.collectibleId
                                RenameCollectible(collectibleId, inputText)
                                ReleaseDialog()
                end,
                visible = function()
                    return self.noViolations
                end,
                clickSound = SOUNDS.DIALOG_ACCEPT,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback =  function(dialog)
                    ReleaseDialog()
                end,
            },
        }
    })

end

--[[Global functions]]--
------------------------
function ZO_GamepadCollectionsBook_OnInitialize(control)
    GAMEPAD_COLLECTIONS_BOOK = ZO_GamepadCollectionsBook:New(control)
end