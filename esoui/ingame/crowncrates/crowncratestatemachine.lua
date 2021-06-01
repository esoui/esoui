ZO_CROWN_CRATE_TRIGGER_COMMANDS =
{
    SCENE_SHOWN = "OnSceneShowing",
    CAT_SUMMON_COMPLETE = "UI_Greet", -- Anim Note
    CAT_GREETING_COMPLETE = "UI_OpenManifest", -- Anim Note
    MANIFEST_IN_COMPLETE = "OnManifestInComplete",
    DEAL_REQUESTED = "OnDealRequested",
    MANIFEST_OUT_COMPLETE = "OnManifestOutComplete",
    PRIMARY_DEAL_COMPLETE_CAT = "UI_Deal_Primary", -- Anim Note
    PRIMARY_DEAL_COMPLETE = "OnPrimaryDealComplete",
    BONUS_DEAL_COMPLETE_CAT = "UI_Deal_Bonus", -- Anim Note
    BONUS_DEAL_COMPLETE = "OnBonusDealComplete",
    CARD_REVEALED = "OnCardRevealed",
    CARD_OUT_COMPLETE = "OnCardOutComplete",
    CARD_DEAL_COMPLETE = "OnCardDealComplete",
    CARD_SELECTED = "OnCardSelected",
    FLIP_CARD = "OnFlipCard",
    CARD_DESELECTED = "OnCardDeselected",
    CARD_FLIP_COMPLETE = "OnFlipComplete",
    CARD_GEMIFY_COMPLETE = "OnGemifyComplete",
    CARD_LEAVE = "OnCardLeave",
    BACK_TO_MANIFEST = "BackToManifest",
    GEMIFICATION_HIDDEN = "GemificationHidden",
    MANIFEST_PAGE_OUT = "ManifestPageOut",
    MANIFEST_PAGE_IN = "ManifestPageIn",
}

ZO_CrownCratesStateMachine = ZO_StateMachine_Base:Subclass()

function ZO_CrownCratesStateMachine:New(...)
    return ZO_StateMachine_Base.New(self, ...)
end

function ZO_CrownCratesStateMachine:Initialize(manager, packChoosing, packOpening, gemificationKeyboard, gemificationGamepad, gemificationSlot)
    ZO_StateMachine_Base.Initialize(self, "CROWN_CRATE_STATE_MACHINE")

    self.manager = manager
    self.packChoosing = packChoosing
    self.packOpening = packOpening
    self.gemificationKeyboard = gemificationKeyboard
    self.gemificationGamepad = gemificationGamepad
    self.gemificationSlot = gemificationSlot

    --States--
    self:AddState("START") --1
    self:AddState("SUMMON_CAT") --2
    self:AddState("MANIFEST_IN") --3
    self:AddState("MANIFEST") --4
    self:AddState("MANIFEST_OUT_FOR_DEAL") --5
    self:AddState("CAT_PRIMARY_DEAL") --6
    self:AddState("UI_PRIMARY_DEAL") --7
    self:AddState("CAT_BONUS_DEAL") --8
    self:AddState("UI_BONUS_DEAL") --9
    self:AddState("ACTIVE_HAND_MANIPULATION") --10
    self:AddState("ALL_REVEALED") --11
    self:AddState("CARDS_OUT_BACK") --12
    self:AddState("CARDS_OUT_NEXT") --13
    self:AddState("FRAMING_PLAYER") --14
    self:AddState("MANIFEST_OUT_FOR_GEMIFICATION") --15
    self:AddState("GEMIFICATION") --16
    self:AddState("MANIFEST_PAGE_OUT") --17
    self:AddState("MANIFEST_PAGE_IN") --18

    --Edges--
    self:AddEdgeAutoName("START", "FRAMING_PLAYER") --1 -> 14
    self:AddEdgeAutoName("FRAMING_PLAYER", "SUMMON_CAT") --14 -> 2
    self:AddEdge("SUMMON_CAT_TO_MANIFEST_IN", "SUMMON_CAT", "MANIFEST_IN") --2 -> 3
    self:AddEdge("MANIFEST_IN_TO_MANIFEST", "MANIFEST_IN", "MANIFEST") --3 -> 4
    self:AddEdge("MANIFEST_TO_MANIFEST_OUT_FOR_DEAL", "MANIFEST", "MANIFEST_OUT_FOR_DEAL") --4 -> 5
    self:AddEdge("MANIFEST_OUT_FOR_DEAL_TO_MANIFEST_IN", "MANIFEST_OUT_FOR_DEAL", "MANIFEST_IN") --5 -> 3
    self:AddEdge("MANIFEST_OUT_FOR_DEAL_TO_CAT_PRIMARY_DEAL", "MANIFEST_OUT_FOR_DEAL", "CAT_PRIMARY_DEAL") --5 -> 6
    self:AddEdge("CAT_PRIMARY_DEAL_TO_UI_PRIMARY_DEAL", "CAT_PRIMARY_DEAL", "UI_PRIMARY_DEAL") --6 -> 7
    self:AddEdge("UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION", "UI_PRIMARY_DEAL", "ACTIVE_HAND_MANIPULATION") --7 -> 10
    self:AddEdge("UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL", "UI_PRIMARY_DEAL", "CAT_BONUS_DEAL") --7 -> 8
    self:AddEdge("CAT_BONUS_DEAL_TO_UI_BONUS_DEAL", "CAT_BONUS_DEAL", "UI_BONUS_DEAL") --8 -> 9
    self:AddEdge("UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION", "UI_BONUS_DEAL", "ACTIVE_HAND_MANIPULATION") --9 -> 10
    self:AddEdge("ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED", "ACTIVE_HAND_MANIPULATION", "ALL_REVEALED") --10 -> 11
    self:AddEdge("ALL_REVEALED_TO_CARDS_OUT_BACK", "ALL_REVEALED", "CARDS_OUT_BACK") --11 -> 12 (Back to Manifest)
    self:AddEdge("ALL_REVEALED_TO_CARDS_OUT_NEXT", "ALL_REVEALED", "CARDS_OUT_NEXT") --11 -> 13 (Open next pack)
    self:AddEdge("CARDS_OUT_BACK_TO_MANIFEST_IN", "CARDS_OUT_BACK", "MANIFEST_IN") --12 -> 3
    self:AddEdge("CARDS_OUT_NEXT_TO_MANIFEST_IN", "CARDS_OUT_NEXT", "MANIFEST_IN") --13 -> 3
    self:AddEdge("CARDS_OUT_NEXT_TO_CAT_PRIMARY_DEAL", "CARDS_OUT_NEXT", "CAT_PRIMARY_DEAL") --13 -> 6
    self:AddEdge("MANIFEST_TO_MANIFEST_OUT_FOR_GEMIFICATION", "MANIFEST", "MANIFEST_OUT_FOR_GEMIFICATION") --4 -> 15
    self:AddEdge("MANIFEST_OUT_FOR_GEMIFICATION_TO_GEMIFICATION", "MANIFEST_OUT_FOR_GEMIFICATION", "GEMIFICATION") --15 -> 16
    self:AddEdge("GEMIFICATION_TO_MANIFEST_IN", "GEMIFICATION", "MANIFEST_IN") --16 -> 3

    self:AddEdge("MANIFEST_TO_MANIFEST_PAGE_OUT", "MANIFEST", "MANIFEST_PAGE_OUT") --4 -> 17
    self:AddEdge("MANIFEST_PAGE_OUT_TO_MANIFEST_PAGE_IN", "MANIFEST_PAGE_OUT", "MANIFEST_PAGE_IN") --17 -> 18
    self:AddEdge("MANIFEST_PAGE_IN_TO_MANIFEST", "MANIFEST_PAGE_IN", "MANIFEST") --18 -> 4

    --Triggers--
    do
        local MANIFEST_TO_GEMIFICATION_KEYBIND =
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            keybind = "UI_SHORTCUT_TERTIARY",
            name = function()
                local gemIcon = ZO_Currency_GetPlatformFormattedCurrencyIcon(GetCurrencyTypeFromMarketCurrencyType(MKCT_CROWN_GEMS), "100%")
                return gemIcon..GetString(SI_GEMIFICATION_TITLE)
            end,
            gamepadOrder = 10000,
            order = -10000,
            callback = nil,
        }

        local ALL_REVEALED_TO_CARDS_OUT_NEXT_KEYBIND = 
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                local currentCrateId = GetCurrentCrownCrateId()
                local currentCrateName = GetCrownCrateName(currentCrateId)
                local remainingCount = GetCrownCrateCount(currentCrateId)
                local remainingCountColor = remainingCount == 0 and ZO_ERROR_COLOR or ZO_SELECTED_TEXT
                remainingCount = remainingCountColor:Colorize(remainingCount)
                return zo_strformat(SI_CROWN_CRATE_OPEN_NEXT_KEYBIND, currentCrateName, remainingCount)
            end,
            callback = nil,
            enabled = function()
                            local currentCrateId = GetCurrentCrownCrateId()

                            if GetCrownCrateCount(currentCrateId) == 0 then
                                return false, GetString("SI_LOOTCRATEOPENRESPONSE", LOOT_CRATE_OPEN_RESPONSE_OUT_OF_LOOT_CRATE)
                            end

                            local numSlotsForCrate = GetInventorySpaceRequiredToOpenCrownCrate(currentCrateId)
                            local freeSlots = GetNumBagFreeSlots(BAG_BACKPACK)
                            if freeSlots < numSlotsForCrate then
                                return false, zo_strformat(GetString("SI_LOOTCRATEOPENRESPONSE", LOOT_CRATE_OPEN_RESPONSE_FAIL_NO_INVENTORY_SPACE), numSlotsForCrate - freeSlots)
                            end

                            return true
                      end
        }

        local function FilterOpenResponseSuccess(eventCode, crateId, response)
            return response == LOOT_CRATE_OPEN_RESPONSE_SUCCESS
        end

        local function FilterOpenResponseFailed(eventCode, crateId, response)
            return response ~= LOOT_CRATE_OPEN_RESPONSE_SUCCESS
        end

        local function CreateServerResponseAndAnimationMultiTrigger(animationCompleteTriggerCommand, serverResponseFilterCallback, animationEventCountCallback)
            local animationTrigger = ZO_StateMachine_TriggerStateCallback:New(animationCompleteTriggerCommand)
            local serverResponseTrigger = ZO_StateMachine_TriggerEventManager:New(EVENT_CROWN_CRATE_OPEN_RESPONSE)

            serverResponseTrigger:SetFilterCallback(serverResponseFilterCallback)
            if animationEventCountCallback then
                animationTrigger:SetEventCount(animationEventCountCallback)
            end

            return ZO_StateMachine_MultiTrigger:New(animationTrigger, serverResponseTrigger)
        end

        local function ManifestOutEventCountCallback()
            local packsOnPage = self.packChoosing:GetNumPacksToDisplayOnPage(self.packChoosing:GetCurrentPage())
            -- If there are no packs, expect the manifest to tell us it's done immediately. This is for transitioning from 0 crates (the transparent current season one) to gemify.
            return packsOnPage > 0 and packsOnPage or 1
        end

        self:AddTrigger("START_TO_FRAMING_PLAYER", ZO_StateMachine_TriggerStateCallback, ZO_CROWN_CRATE_TRIGGER_COMMANDS.SCENE_SHOWN) --1 -> 14
        self:AddTrigger("FRAMING_PLAYER_TO_SUMMON_CAT", ZO_StateMachine_TriggerEventManager, EVENT_GAME_CAMERA_CHARACTER_FRAMING_STARTED) --14 -> 2
        self:AddTrigger("SUMMON_CAT_TO_MANIFEST_IN", ZO_StateMachine_TriggerAnimNote, ZO_CROWN_CRATE_TRIGGER_COMMANDS.CAT_SUMMON_COMPLETE) --2 -> 3
        self:AddTrigger("MANIFEST_IN_TO_MANIFEST", ZO_StateMachine_TriggerStateCallback, ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_IN_COMPLETE) --3 -> 4
        self:AddTrigger("MANIFEST_TO_MANIFEST_OUT_FOR_DEAL", ZO_StateMachine_TriggerStateCallback, ZO_CROWN_CRATE_TRIGGER_COMMANDS.DEAL_REQUESTED) --4 -> 5
        self:SetTrigger("MANIFEST_OUT_FOR_DEAL_TO_MANIFEST_IN", CreateServerResponseAndAnimationMultiTrigger(ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_OUT_COMPLETE, FilterOpenResponseFailed, ManifestOutEventCountCallback)) --5 -> 3
        self:SetTrigger("MANIFEST_OUT_FOR_DEAL_TO_CAT_PRIMARY_DEAL", CreateServerResponseAndAnimationMultiTrigger(ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_OUT_COMPLETE, FilterOpenResponseSuccess, ManifestOutEventCountCallback)) --5 -> 6
        self:AddTrigger("CAT_PRIMARY_DEAL_TO_UI_PRIMARY_DEAL", ZO_StateMachine_TriggerAnimNote, ZO_CROWN_CRATE_TRIGGER_COMMANDS.PRIMARY_DEAL_COMPLETE_CAT) --6 -> 7
        self:AddTrigger("UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION", ZO_StateMachine_TriggerStateCallback, ZO_CROWN_CRATE_TRIGGER_COMMANDS.PRIMARY_DEAL_COMPLETE) --7 -> 10
        self:AddTrigger("UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL", ZO_StateMachine_TriggerStateCallback, ZO_CROWN_CRATE_TRIGGER_COMMANDS.PRIMARY_DEAL_COMPLETE) --7 -> 8
        self:AddTrigger("CAT_BONUS_DEAL_TO_UI_BONUS_DEAL", ZO_StateMachine_TriggerAnimNote, ZO_CROWN_CRATE_TRIGGER_COMMANDS.BONUS_DEAL_COMPLETE_CAT) --8 -> 9
        self:AddTrigger("UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION", ZO_StateMachine_TriggerStateCallback, ZO_CROWN_CRATE_TRIGGER_COMMANDS.BONUS_DEAL_COMPLETE) --9 -> 10
        self:AddTrigger("ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED", ZO_StateMachine_TriggerStateCallback, ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_REVEALED) --10 -> 11
        self:AddTrigger("ALL_REVEALED_TO_CARDS_OUT_BACK", ZO_StateMachine_TriggerStateCallback, ZO_CROWN_CRATE_TRIGGER_COMMANDS.BACK_TO_MANIFEST) --11 -> 12
        self:AddTrigger("ALL_REVEALED_TO_CARDS_OUT_NEXT", ZO_StateMachine_TriggerKeybind, ALL_REVEALED_TO_CARDS_OUT_NEXT_KEYBIND) --11 -> 13
        self:AddTrigger("CARDS_OUT_BACK_TO_MANIFEST_IN", ZO_StateMachine_TriggerStateCallback, ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_OUT_COMPLETE) --12 -> 3
        self:SetTrigger("CARDS_OUT_NEXT_TO_MANIFEST_IN", CreateServerResponseAndAnimationMultiTrigger(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_OUT_COMPLETE, FilterOpenResponseFailed, GetNumCurrentCrownCrateTotalRewards)) --13 -> 3
        self:SetTrigger("CARDS_OUT_NEXT_TO_CAT_PRIMARY_DEAL", CreateServerResponseAndAnimationMultiTrigger(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_OUT_COMPLETE, FilterOpenResponseSuccess, GetNumCurrentCrownCrateTotalRewards)) --13 -> 6
        self:AddTrigger("MANIFEST_TO_MANIFEST_OUT_FOR_GEMIFICATION", ZO_StateMachine_TriggerKeybind, MANIFEST_TO_GEMIFICATION_KEYBIND) --4 -> 15
        self:AddTrigger("MANIFEST_OUT_FOR_GEMIFICATION_TO_GEMIFICATION", ZO_StateMachine_TriggerStateCallback, ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_OUT_COMPLETE) --15 -> 16
        self:AddTrigger("GEMIFICATION_TO_MANIFEST_IN", ZO_StateMachine_TriggerStateCallback, ZO_CROWN_CRATE_TRIGGER_COMMANDS.GEMIFICATION_HIDDEN) --16 -> 3

        -- change page trigger
        self:AddTrigger("MANIFEST_TO_MANIFEST_PAGE_OUT", ZO_StateMachine_TriggerStateCallback, ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_PAGE_OUT) --4 -> 17
        -- page out complete
        self:AddTrigger("MANIFEST_PAGE_OUT_TO_MANIFEST_PAGE_IN", ZO_StateMachine_TriggerStateCallback, ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_OUT_COMPLETE) --17 -> 18
        -- page in complete
        self:AddTrigger("MANIFEST_PAGE_IN_TO_MANIFEST", ZO_StateMachine_TriggerStateCallback, ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_IN_COMPLETE) --18 -> 4

        --Add Conditionals
        self:GetTriggerByName("UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION"):SetEventCount(GetNumCurrentCrownCratePrimaryRewards)
        self:GetTriggerByName("UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL"):SetEventCount(GetNumCurrentCrownCratePrimaryRewards)
        self:GetTriggerByName("UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION"):SetEventCount(GetNumCurrentCrownCrateBonusRewards)
        self:GetTriggerByName("ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED"):SetEventCount(GetNumCurrentCrownCrateTotalRewards)
        self:GetTriggerByName("MANIFEST_OUT_FOR_GEMIFICATION_TO_GEMIFICATION"):SetEventCount(ManifestOutEventCountCallback)
        self:GetTriggerByName("MANIFEST_PAGE_OUT_TO_MANIFEST_PAGE_IN"):SetEventCount(ManifestOutEventCountCallback)
    end

    --Add triggers to edges--
    self:AddTriggerToEdge("START_TO_FRAMING_PLAYER", "START_TO_FRAMING_PLAYER")

    self:AddTriggerToEdge("FRAMING_PLAYER_TO_SUMMON_CAT", "FRAMING_PLAYER_TO_SUMMON_CAT")
    self:AddTriggerToEdge("SUMMON_CAT_TO_MANIFEST_IN", "SUMMON_CAT_TO_MANIFEST_IN")
    self:AddTriggerToEdge("MANIFEST_IN_TO_MANIFEST", "MANIFEST_IN_TO_MANIFEST")
    self:AddTriggerToEdge("MANIFEST_TO_MANIFEST_OUT_FOR_DEAL", "MANIFEST_TO_MANIFEST_OUT_FOR_DEAL")
    self:AddTriggerToEdge("MANIFEST_OUT_FOR_DEAL_TO_MANIFEST_IN", "MANIFEST_OUT_FOR_DEAL_TO_MANIFEST_IN")
    self:AddTriggerToEdge("MANIFEST_OUT_FOR_DEAL_TO_CAT_PRIMARY_DEAL", "MANIFEST_OUT_FOR_DEAL_TO_CAT_PRIMARY_DEAL")
    self:AddTriggerToEdge("CAT_PRIMARY_DEAL_TO_UI_PRIMARY_DEAL", "CAT_PRIMARY_DEAL_TO_UI_PRIMARY_DEAL")
    self:AddTriggerToEdge("UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION", "UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION")
    self:AddTriggerToEdge("UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL", "UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL")
    self:AddTriggerToEdge("CAT_BONUS_DEAL_TO_UI_BONUS_DEAL", "CAT_BONUS_DEAL_TO_UI_BONUS_DEAL")
    self:AddTriggerToEdge("UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION", "UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION")
    self:AddTriggerToEdge("ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED", "ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED")
    self:AddTriggerToEdge("ALL_REVEALED_TO_CARDS_OUT_BACK", "ALL_REVEALED_TO_CARDS_OUT_BACK")
    self:AddTriggerToEdge("ALL_REVEALED_TO_CARDS_OUT_NEXT", "ALL_REVEALED_TO_CARDS_OUT_NEXT")
    self:AddTriggerToEdge("CARDS_OUT_BACK_TO_MANIFEST_IN", "CARDS_OUT_BACK_TO_MANIFEST_IN")
    self:AddTriggerToEdge("CARDS_OUT_NEXT_TO_MANIFEST_IN", "CARDS_OUT_NEXT_TO_MANIFEST_IN")
    self:AddTriggerToEdge("CARDS_OUT_NEXT_TO_CAT_PRIMARY_DEAL", "CARDS_OUT_NEXT_TO_CAT_PRIMARY_DEAL")
    self:AddTriggerToEdge("MANIFEST_TO_MANIFEST_OUT_FOR_GEMIFICATION", "MANIFEST_TO_MANIFEST_OUT_FOR_GEMIFICATION")
    self:AddTriggerToEdge("MANIFEST_OUT_FOR_GEMIFICATION_TO_GEMIFICATION", "MANIFEST_OUT_FOR_GEMIFICATION_TO_GEMIFICATION")
    self:AddTriggerToEdge("GEMIFICATION_TO_MANIFEST_IN", "GEMIFICATION_TO_MANIFEST_IN")

    self:AddTriggerToEdge("MANIFEST_TO_MANIFEST_PAGE_OUT", "MANIFEST_TO_MANIFEST_PAGE_OUT")
    self:AddTriggerToEdge("MANIFEST_PAGE_OUT_TO_MANIFEST_PAGE_IN", "MANIFEST_PAGE_OUT_TO_MANIFEST_PAGE_IN")
    self:AddTriggerToEdge("MANIFEST_PAGE_IN_TO_MANIFEST", "MANIFEST_PAGE_IN_TO_MANIFEST")

    --Add Conditionals--
    self:GetEdgeByName("UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION"):SetConditional(function() return GetNumCurrentCrownCrateBonusRewards() == 0 end)
    self:GetEdgeByName("UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL"):SetConditional(function() return GetNumCurrentCrownCrateBonusRewards() > 0 end)

    do
        local function ManifestInEventCountCallback()
            self.packChoosing:UpdatePackData()
            return self.packChoosing:GetNumPacksToDisplayOnPage(self.packChoosing:GetCurrentPage())
        end

        self:GetTriggerByName("MANIFEST_IN_TO_MANIFEST"):SetEventCount(ManifestInEventCountCallback)
        self:GetTriggerByName("MANIFEST_PAGE_IN_TO_MANIFEST"):SetEventCount(ManifestInEventCountCallback)
    end

    self:GetEdgeByName("MANIFEST_PAGE_OUT_TO_MANIFEST_PAGE_IN"):RegisterCallback("OnTrigger", function()
        self.packChoosing:SetupForPageIn()
    end)

    --Register actions on states--
    self:GetStateByName("START"):RegisterCallback("OnActivated", function()
        SetCrownCrateNPCVisible(false)
        self.packChoosing:ResetPacks()
        self.packOpening:ResetCards()
        local IMMEDIATE = true
        SetFullscreenEffect(FULLSCREEN_EFFECT_NONE, 0, 0, IMMEDIATE)
    end)

    self:GetStateByName("SUMMON_CAT"):RegisterCallback("OnActivated", function()
        SetCrownCrateNPCVisible(true)
    end)

    self:GetEdgeByName("SUMMON_CAT_TO_MANIFEST_IN"):RegisterCallback("OnTrigger", function()
        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_GREET_PLAYER)
    end)

    self:GetStateByName("MANIFEST_IN"):RegisterCallback("OnActivated", function()
        self.manager:LockLocalSpaceToCurrentCamera()
        self.packChoosing:Show()
        SetFullscreenEffect(FULLSCREEN_EFFECT_CHARACTER_FRAMING_BLUR, 2, 0)
        PlaySound(SOUNDS.CROWN_CRATES_MANIFEST_IN)
        --NPC passively reacts to your current supply of crates
        local numOwnedCrateTypes = GetNumOwnedCrownCrateTypes()
        if numOwnedCrateTypes == 0 then
            TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_MANIFEST_ENTER_NO_CRATES)
        elseif numOwnedCrateTypes == 1 then
            TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_MANIFEST_ENTER_ONE_CRATES)
        else
            TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_MANIFEST_ENTER_MULTI_CRATES)
        end
    end)

    self:GetStateByName("MANIFEST"):RegisterCallback("OnActivated", function()
        self.packChoosing:OnActivate()
    end)

    self:GetStateByName("MANIFEST"):RegisterCallback("OnDeactivating", function()
        self.packChoosing:OnDeactivate()
    end)

    self:GetStateByName("MANIFEST_OUT_FOR_DEAL"):RegisterCallback("OnActivated", function()
        self.packChoosing:AnimateChoice()
        PlaySound(SOUNDS.CROWN_CRATES_MANIFEST_OUT)
        --Start the flourish while we wait so it doesn't feel unresponsive
        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_FLOURISH)
    end)

    self:GetStateByName("MANIFEST_OUT_FOR_GEMIFICATION"):RegisterCallback("OnActivated", function()
        self.packChoosing:Hide()
    end)

    self:GetStateByName("MANIFEST_OUT_FOR_GEMIFICATION"):RegisterCallback("OnDeactivating", function()
        self.packChoosing:ResetPacks()
    end)

    self:GetStateByName("GEMIFICATION"):RegisterCallback("OnActivated", function()
        local gemificationSystem
        if SCENE_MANAGER:IsCurrentSceneGamepad() then
            gemificationSystem = self.gemificationGamepad
        else
            gemificationSystem = self.gemificationKeyboard
        end
        gemificationSystem:InsertIntoScene()
        SCENE_MANAGER:AddFragment(self.gemificationSlot:GetFragment())
    end)

    self:GetStateByName("GEMIFICATION"):RegisterCallback("OnDeactivating", function()
        SCENE_MANAGER:RemoveFragment(self.gemificationSlot:GetFragment())
    end)

    self:GetStateByName("MANIFEST_OUT_FOR_DEAL"):RegisterCallback("OnDeactivating", function()
        self.packChoosing:ResetPacks()
        SetFullscreenEffect(FULLSCREEN_EFFECT_NONE)
    end)

    self:GetStateByName("CAT_PRIMARY_DEAL"):RegisterCallback("OnActivated", function()
        self.packOpening:ResetCards()
        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_DEAL_PRIMARY_CARDS)
    end)

    self:GetStateByName("UI_PRIMARY_DEAL"):RegisterCallback("OnActivated", function()
        local success, worldX, worldY, worldZ = GetCrownCrateNPCBoneWorldPosition(GetCrownCrateNPCCardThrowingBoneName())
        if success then
            local localX, localY, localZ = self.manager:GetCameraLocalPositionFromWorldPosition(worldX, worldY, worldZ)
            self.packOpening:StartPrimaryDealAnimation(localX, localY, localZ)
        end
        PlaySound(SOUNDS.CROWN_CRATES_DEAL_PRIMARY)
    end)

    self:GetStateByName("UI_PRIMARY_DEAL"):RegisterCallback("OnDeactivating", function()
        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_PRIMARY_CARDS_DEALT)
    end)

    self:GetStateByName("CAT_BONUS_DEAL"):RegisterCallback("OnActivated", function()
        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_DEAL_BONUS_CARDS)
    end)

    self:GetStateByName("UI_BONUS_DEAL"):RegisterCallback("OnActivated", function()
        local success, worldX, worldY, worldZ = GetCrownCrateNPCBoneWorldPosition(GetCrownCrateNPCCardThrowingBoneName())
        if success then
            local localX, localY, localZ = self.manager:GetCameraLocalPositionFromWorldPosition(worldX, worldY, worldZ)
            self.packOpening:StartBonusDealAnimation(localX, localY, localZ)
        end
        PlaySound(SOUNDS.CROWN_CRATES_DEAL_BONUS)
    end)

    self:GetStateByName("ACTIVE_HAND_MANIPULATION"):RegisterCallback("OnActivated", function()
        self.packOpening:OnDealComplete()
        self.packOpening:AddHandManipulationKeybinds()
        self.packOpening:RefreshSelectedCard()
    end)

    self:GetStateByName("ACTIVE_HAND_MANIPULATION"):RegisterCallback("OnDeactivating", function()
        self.packOpening:RemoveHandManipulationKeybinds()
    end)

    self:GetStateByName("ALL_REVEALED"):RegisterCallback("OnActivated", function()
        self.packOpening:AddAllRevealedKeybinds()
        --NPC passively reacts to you being done, depending on your current supply of crates
        if GetNumOwnedCrownCrateTypes() == 0 then
            TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_ALL_CARDS_REVEALED_NO_CRATES)
        else
            TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_ALL_CARDS_REVEALED_HAS_CRATES)
        end
    end)

    self:GetStateByName("ALL_REVEALED"):RegisterCallback("OnDeactivating", function()
        self.packOpening:RemoveAllRevealedKeybinds()
    end)

    self:GetStateByName("CARDS_OUT_BACK"):RegisterCallback("OnActivated", function()
        self.packOpening:StartLeaveAnimation()
        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_SWIPE_CARDS_AWAY)
    end)

    self:GetStateByName("CARDS_OUT_NEXT"):RegisterCallback("OnActivated", function()
        local currentCrownCrateId = GetCurrentCrownCrateId()
        SendCrownCrateOpenRequest(currentCrownCrateId)
        self.packOpening:StartLeaveAnimation()
        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_SWIPE_CARDS_AWAY)
        --Start the shuffle while we wait so it doesn't feel unresponsive
        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_SHUFFLE_CARDS)
    end)

    self:GetStateByName("MANIFEST_PAGE_OUT"):RegisterCallback("OnActivated", function()
        self.packChoosing:StartPageOutAnimation()
    end)

    self:GetStateByName("MANIFEST_PAGE_IN"):RegisterCallback("OnActivated", function()
        self.packChoosing:StartPageShowAnimation()
    end)

    self.DISABLED_BACK_STATES =
    {
        ["MANIFEST_OUT_FOR_DEAL"] = true,
        ["CAT_PRIMARY_DEAL"] = true,
        ["UI_PRIMARY_DEAL"] = true,
        ["CAT_BONUS_DEAL"] = true,
        ["UI_BONUS_DEAL"] = true,
        ["ACTIVE_HAND_MANIPULATION"] = true,
    }

    self:Reset()
end

function ZO_CrownCratesStateMachine:Reset()
    if self:HasCurrentState() and not self:IsCurrentState("START") then
        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_FAREWELL)
    end
    self:SetCurrentState("START")
end

function ZO_CrownCratesStateMachine:CanUseBackKeybind_Gamepad()
    local currentState = self:GetCurrentState()
    if currentState and self.DISABLED_BACK_STATES[currentState:GetName()] then
        return false
    else
        return true
    end
end