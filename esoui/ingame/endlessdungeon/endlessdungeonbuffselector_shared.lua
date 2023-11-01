local INTERACTION =
{
    type = "EndlessDungeonBuffSelector",
    interactTypes = { INTERACTION_ENDLESS_DUNGEON_BUFF_SELECTOR },
}

ZO_EndlessDungeonBuffSelector_Shared = ZO_DeferredInitializingObject:Subclass()

function ZO_EndlessDungeonBuffSelector_Shared:Initialize(control)
    self.control = control
    control.object = self

    local scene = ZO_InteractScene:New(self:GetSceneName(), SCENE_MANAGER, INTERACTION)
    ZO_DeferredInitializingObject.Initialize(self, scene)

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)
end

function ZO_EndlessDungeonBuffSelector_Shared:OnDeferredInitialize()
    self:InitializeControls()
    self:InitializeKeybindStripDescriptor()
end

function ZO_EndlessDungeonBuffSelector_Shared:InitializeControls()
    local control = self.control
    self.titleLabel = control:GetNamedChild("Title")

    local containerControl = control:GetNamedChild("Container")
    local previousBuffControl = nil
    self.buffControls = {}

    -- Bucket values are 0 based
    for i = 1, ENDLESS_DUNGEON_BUFF_BUCKET_TYPE_MAX_VALUE + 1 do
        local buffControl = CreateControlFromVirtual("$(parent)Buff" .. i, containerControl, self:GetBuffTemplate())
        self:SetupBuffControl(buffControl, previousBuffControl)
        buffControl.index = i
        table.insert(self.buffControls, buffControl)
        previousBuffControl = buffControl
    end
end

function ZO_EndlessDungeonBuffSelector_Shared:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:CommitChoice()
            end,
            visible = function()
                return self.selectedBuffControl ~= nil
            end,
        },
    }
end

function ZO_EndlessDungeonBuffSelector_Shared:SetupBuffControl(buffControl, previousBuffControl)
    if previousBuffControl then
        buffControl:SetAnchor(TOPLEFT, previousBuffControl, TOPRIGHT, 60)
    else
        buffControl:SetAnchor(TOPLEFT)
    end

    buffControl.iconTexture = buffControl:GetNamedChild("Icon")
    buffControl.nameLabel = buffControl:GetNamedChild("Name")
    buffControl.manager = self
end

function ZO_EndlessDungeonBuffSelector_Shared:OnShowing()
    local titleBuffType = nil
    local hasAvatarVision = false
    local numChoices = 0
    for bucketType = ENDLESS_DUNGEON_BUFF_BUCKET_TYPE_ITERATION_BEGIN, ENDLESS_DUNGEON_BUFF_BUCKET_TYPE_ITERATION_END do
        local abilityId = GetEndlessDungeonBuffSelectorBucketTypeChoice(bucketType)
        if abilityId > 0 then
            numChoices = numChoices + 1

            local buffType, isAvatarVision = GetAbilityEndlessDungeonBuffType(abilityId)
            local data =
            {
                abilityId = abilityId,
                abilityName = GetAbilityName(abilityId),
                buffType = buffType,
                iconTexture = GetAbilityIcon(abilityId),
                instanceIntervalOffset = numChoices,
                isAvatarVision = isAvatarVision,
                stackCount = 1,
            }

            local buffControl = self.buffControls[numChoices]
            buffControl:Layout(data)
            buffControl.bucketType = bucketType
            buffControl.name = ZO_CachedStrFormat(SI_ABILITY_NAME, GetAbilityName(abilityId))
            buffControl.nameLabel:SetText(buffControl.name)
            buffControl:SetHidden(false)

            hasAvatarVision = hasAvatarVision or isAvatarVision
            if not titleBuffType and buffType ~= ENDLESS_DUNGEON_BUFF_TYPE_NONE then
                -- The buff selection type shown in the dialog title.
                titleBuffType = buffType
            end
        end
    end

    self.titleText = zo_strformat(SI_ENDLESS_DUNGEON_BUFF_SELECTOR_TITLE_FORMAT, GetString("SI_ENDLESSDUNGEONBUFFTYPE", titleBuffType))
    self.titleLabel:SetText(self.titleText)

    if titleBuffType == ENDLESS_DUNGEON_BUFF_TYPE_VERSE then
        PlaySound(SOUNDS.ENDLESS_DUNGEON_BUFF_SELECT_VERSE)
    elseif titleBuffType == ENDLESS_DUNGEON_BUFF_TYPE_VISION then
        if hasAvatarVision then
            PlaySound(SOUNDS.ENDLESS_DUNGEON_BUFF_SELECT_AVATAR_VISION)
        else
            PlaySound(SOUNDS.ENDLESS_DUNGEON_BUFF_SELECT_VISION)
        end
    end

    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_EndlessDungeonBuffSelector_Shared:OnHiding()
    self:DeselectBuff(self.selectedBuffControl)

    for i = 1, #self.buffControls do
        local buffControl = self.buffControls[i]
        buffControl:Reset()
        buffControl:SetHidden(true)
    end

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RestoreDefaultExit()
end

function ZO_EndlessDungeonBuffSelector_Shared:SelectBuff(buffControl)
    if self.selectedBuffControl ~= buffControl then
        self:DeselectBuff(self.selectedBuffControl)

        if buffControl then
            buffControl:SetHighlightHidden(false)
            if buffControl.isAvatarVision then
                PlaySound(SOUNDS.ENDLESS_DUNGEON_BUFF_MOUSE_ENTER_AVATAR_VISION)
            else
                PlaySound(SOUNDS.ENDLESS_DUNGEON_BUFF_MOUSE_ENTER)
            end
        end

        self.selectedBuffControl = buffControl
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_EndlessDungeonBuffSelector_Shared:DeselectBuff(buffControl)
    if buffControl and self.selectedBuffControl == buffControl then
        buffControl:SetHighlightHidden(true)

        self.selectedBuffControl = nil
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_EndlessDungeonBuffSelector_Shared:CommitChoice()
    local buffControl = self.selectedBuffControl
    ChooseEndlessDungeonBuff(buffControl.bucketType)
end

ZO_EndlessDungeonBuffSelector_Shared:MUST_IMPLEMENT("GetSceneName")
ZO_EndlessDungeonBuffSelector_Shared:MUST_IMPLEMENT("GetBuffTemplate")