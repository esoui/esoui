-----------------------------
-- Scene Group Bar
-----------------------------
ZO_SceneGroupBar = ZO_InitializingObject:Subclass()

function ZO_SceneGroupBar:Initialize(menuBarControl)
    self.menuBarControl = menuBarControl
    self.label = menuBarControl:GetNamedChild("Label")
    self.buttonData = {}
end

function ZO_SceneGroupBar:Clear()
    ZO_MenuBar_ClearSelection(self.menuBarControl)
end

function ZO_SceneGroupBar:RemoveAll()
    self:Clear()
    ZO_MenuBar_ClearButtons(self.menuBarControl)
    for _, buttonData in ipairs(self.buttonData) do
        buttonData.callback = buttonData.existingCallback
    end
    self.buttonData = {}
end

function ZO_SceneGroupBar:SetActiveScene(sceneName)
    if self.sceneGroupName then
        local sceneGroup = SCENE_MANAGER:GetSceneGroup(self.sceneGroupName)
        sceneGroup:SetActiveScene(sceneName)
    end
end

function ZO_SceneGroupBar:SelectTab(sceneName)
    ZO_MenuBar_SelectDescriptor(self.menuBarControl, sceneName)
end

function ZO_SceneGroupBar:CreateSceneGroup(name, tabDataList, activeSceneName)
    self:RemoveAll()

    local scenes = {}
    for i, tabData in pairs(tabDataList) do
        table.insert(scenes, tabData.descriptor)
    end

    SCENE_MANAGER:AddSceneGroup(name, ZO_SceneGroup:New(unpack(scenes)))
    self.sceneGroupName = name
    self.sceneGroup = SCENE_MANAGER:GetSceneGroup(name)
    local isInitialized = false

    self.sceneGroup:RegisterCallback("StateChange", function(_, newState)
        if newState == SCENE_GROUP_SHOWING then
            local nextScene = SCENE_MANAGER:GetNextScene():GetName()
            -- this update can be called before the scene itself is set to showing,
            -- so make sure to set the active scene here so we can update the scene group bar correctly
            self.sceneGroup:SetActiveScene(nextScene)

            if not isInitialized then
                 -- This is a scene group
                ZO_MenuBar_ClearButtons(self.menuBarControl)

                for i, tabData in pairs(tabDataList) do
                    -- Set the first tab in the list as the active scene if an active scene wasn't passed in
                    if not activeSceneName then
                        activeSceneName = tabData.descriptor
                    end

                    local buttonData = tabData
                    buttonData.existingCallback = buttonData.callback
                    local existingCallback = buttonData.callback
                    buttonData.callback = function()
                        local sceneGroup = SCENE_MANAGER:GetSceneGroup(name)
                        sceneGroup:SetActiveScene(buttonData.descriptor)
                        if self.sceneGroup:IsShowing() then
                            SCENE_MANAGER:Show(buttonData.descriptor)
                        end
                        if self.label then
                            self.label:SetText(zo_strformat(SI_SCENE_FRAGMENT_BAR_TITLE, GetString(buttonData.categoryName)))
                        end

                        self.lastSceneName = buttonData.descriptor
                        if existingCallback then
                            existingCallback()
                        end
                    end

                    ZO_MenuBar_AddButton(self.menuBarControl, buttonData)
                    table.insert(self.buttonData, buttonData)
                end
                isInitialized = true
                self:SelectTab(activeSceneName)
            end
        end
    end)
end

function ZO_SceneGroupBar:UpdateButtons(forceSelection)
    ZO_MenuBar_UpdateButtons(self.menuBarControl, forceSelection)
end
