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
	local states =
	{
		START = ZO_StateMachine_State:New(self, "START"), --1
		SUMMON_CAT = ZO_StateMachine_State:New(self, "SUMMON_CAT"), --2
		MANIFEST_IN = ZO_StateMachine_State:New(self, "MANIFEST_IN"), --3
		MANIFEST = ZO_StateMachine_State:New(self, "MANIFEST"), --4
		MANIFEST_OUT_FOR_DEAL = ZO_StateMachine_State:New(self, "MANIFEST_OUT_FOR_DEAL"), --5
		CAT_PRIMARY_DEAL = ZO_StateMachine_State:New(self, "CAT_PRIMARY_DEAL"), --6
		UI_PRIMARY_DEAL = ZO_StateMachine_State:New(self, "UI_PRIMARY_DEAL"), --7
		CAT_BONUS_DEAL = ZO_StateMachine_State:New(self, "CAT_BONUS_DEAL"), --8
		UI_BONUS_DEAL = ZO_StateMachine_State:New(self, "UI_BONUS_DEAL"), --9
		ACTIVE_HAND_MANIPULATION = ZO_StateMachine_State:New(self, "ACTIVE_HAND_MANIPULATION"), --10
		ALL_REVEALED = ZO_StateMachine_State:New(self, "ALL_REVEALED"), --11
		CARDS_OUT_BACK = ZO_StateMachine_State:New(self, "CARDS_OUT_BACK"), --12
		CARDS_OUT_NEXT = ZO_StateMachine_State:New(self, "CARDS_OUT_NEXT"), --13
		FRAMING_PLAYER = ZO_StateMachine_State:New(self, "FRAMING_PLAYER"), --14
        MANIFEST_OUT_FOR_GEMIFICATION = ZO_StateMachine_State:New(self, "MANIFEST_OUT_FOR_GEMIFICATION"), --15
        GEMIFICATION = ZO_StateMachine_State:New(self, "GEMIFICATION"), --16
	}
	self.states = states

	--Edges--
	local edges =
	{
		START_TO_FRAMING_PLAYER = ZO_StateMachine_Edge:New(states.START, states.FRAMING_PLAYER), --1 -> 14
		FRAMING_PLAYER_TO_SUMMON_CAT = ZO_StateMachine_Edge:New(states.FRAMING_PLAYER, states.SUMMON_CAT), --14 -> 2
		SUMMON_CAT_TO_MANIFEST_IN = ZO_StateMachine_Edge:New(states.SUMMON_CAT, states.MANIFEST_IN), --2 -> 3
		MANIFEST_IN_TO_MANIFEST = ZO_StateMachine_Edge:New(states.MANIFEST_IN, states.MANIFEST), --3 -> 4
		MANIFEST_TO_MANIFEST_OUT_FOR_DEAL = ZO_StateMachine_Edge:New(states.MANIFEST, states.MANIFEST_OUT_FOR_DEAL), --4 -> 5
		MANIFEST_OUT_FOR_DEAL_TO_MANIFEST_IN = ZO_StateMachine_Edge:New(states.MANIFEST_OUT_FOR_DEAL, states.MANIFEST_IN), --5 -> 3
		MANIFEST_OUT_FOR_DEAL_TO_CAT_PRIMARY_DEAL = ZO_StateMachine_Edge:New(states.MANIFEST_OUT_FOR_DEAL, states.CAT_PRIMARY_DEAL), --5 -> 6
		CAT_PRIMARY_DEAL_TO_UI_PRIMARY_DEAL = ZO_StateMachine_Edge:New(states.CAT_PRIMARY_DEAL, states.UI_PRIMARY_DEAL), --6 -> 7
		UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION = ZO_StateMachine_Edge:New(states.UI_PRIMARY_DEAL, states.ACTIVE_HAND_MANIPULATION), --7 -> 10
		UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL = ZO_StateMachine_Edge:New(states.UI_PRIMARY_DEAL, states.CAT_BONUS_DEAL), --7 -> 8
		CAT_BONUS_DEAL_TO_UI_BONUS_DEAL = ZO_StateMachine_Edge:New(states.CAT_BONUS_DEAL, states.UI_BONUS_DEAL), --8 -> 9
		UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION = ZO_StateMachine_Edge:New(states.UI_BONUS_DEAL, states.ACTIVE_HAND_MANIPULATION), --9 -> 10
		ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED = ZO_StateMachine_Edge:New(states.ACTIVE_HAND_MANIPULATION, states.ALL_REVEALED), --10 -> 11
		ALL_REVEALED_TO_CARDS_OUT_BACK = ZO_StateMachine_Edge:New(states.ALL_REVEALED, states.CARDS_OUT_BACK), --11 -> 12 (Back to Manifest)
		ALL_REVEALED_TO_CARDS_OUT_NEXT = ZO_StateMachine_Edge:New(states.ALL_REVEALED, states.CARDS_OUT_NEXT), --11 -> 13 (Open next pack)
		CARDS_OUT_BACK_TO_MANIFEST_IN = ZO_StateMachine_Edge:New(states.CARDS_OUT_BACK, states.MANIFEST_IN), --12 -> 3
		CARDS_OUT_NEXT_TO_MANIFEST_IN = ZO_StateMachine_Edge:New(states.CARDS_OUT_NEXT, states.MANIFEST_IN), --13 -> 3
		CARDS_OUT_NEXT_TO_CAT_PRIMARY_DEAL = ZO_StateMachine_Edge:New(states.CARDS_OUT_NEXT, states.CAT_PRIMARY_DEAL), --13 -> 6
        MANIFEST_TO_MANIFEST_OUT_FOR_GEMIFICATION = ZO_StateMachine_Edge:New(states.MANIFEST, states.MANIFEST_OUT_FOR_GEMIFICATION), --4 -> 15
        MANIFEST_OUT_FOR_GEMIFICATION_TO_GEMIFICATION = ZO_StateMachine_Edge:New(states.MANIFEST_OUT_FOR_GEMIFICATION, states.GEMIFICATION), --15 -> 16
        GEMIFICATION_TO_MANIFEST_IN = ZO_StateMachine_Edge:New(states.GEMIFICATION, states.MANIFEST_IN), --16 -> 3
	}
	self.edges = edges

	--Triggers--
	local triggers
	do
        local MANIFEST_TO_GEMIFICATION_KEYBIND =
        {
			alignment = KEYBIND_STRIP_ALIGN_CENTER,
            keybind = "UI_SHORTCUT_TERTIARY",
            name = function()
                local gemIcon = ZO_Currency_GetPlatformFormattedCurrencyIcon(ZO_Currency_MarketCurrencyToUICurrency(MKCT_CROWN_GEMS), "100%")
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
							if freeSlots <  numSlotsForCrate then
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
			-- If there are no packs, expect the manifest to tell us it's done immediately
			return packsOnPage > 0 and packsOnPage or 1
		end

		triggers =
		{
			START_TO_FRAMING_PLAYER = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.SCENE_SHOWN), --1 -> 14
			FRAMING_PLAYER_TO_SUMMON_CAT = ZO_StateMachine_TriggerEventManager:New(EVENT_GAME_CAMERA_CHARACTER_FRAMING_STARTED), --14 -> 2
			SUMMON_CAT_TO_MANIFEST_IN = ZO_StateMachine_TriggerAnimNote:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CAT_SUMMON_COMPLETE), --2 -> 3
			MANIFEST_IN_TO_MANIFEST = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_IN_COMPLETE), --3 -> 4
			MANIFEST_TO_MANIFEST_OUT_FOR_DEAL = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.DEAL_REQUESTED), --4 -> 5
			MANIFEST_OUT_FOR_DEAL_TO_MANIFEST_IN = CreateServerResponseAndAnimationMultiTrigger(ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_OUT_COMPLETE, FilterOpenResponseFailed, ManifestOutEventCountCallback), --5 -> 3
			MANIFEST_OUT_FOR_DEAL_TO_CAT_PRIMARY_DEAL = CreateServerResponseAndAnimationMultiTrigger(ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_OUT_COMPLETE, FilterOpenResponseSuccess, ManifestOutEventCountCallback), --5 -> 6
			CAT_PRIMARY_DEAL_TO_UI_PRIMARY_DEAL = ZO_StateMachine_TriggerAnimNote:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.PRIMARY_DEAL_COMPLETE_CAT), --6 -> 7
			UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.PRIMARY_DEAL_COMPLETE), --7 -> 10
			UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.PRIMARY_DEAL_COMPLETE), --7 -> 8
			CAT_BONUS_DEAL_TO_UI_BONUS_DEAL = ZO_StateMachine_TriggerAnimNote:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.BONUS_DEAL_COMPLETE_CAT), --8 -> 9
			UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.BONUS_DEAL_COMPLETE), --9 -> 10
			ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_REVEALED), --10 -> 11
			ALL_REVEALED_TO_CARDS_OUT_BACK = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.BACK_TO_MANIFEST), --11 -> 12
			ALL_REVEALED_TO_CARDS_OUT_NEXT = ZO_StateMachine_TriggerKeybind:New(ALL_REVEALED_TO_CARDS_OUT_NEXT_KEYBIND), --11 -> 13
			CARDS_OUT_BACK_TO_MANIFEST_IN = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_OUT_COMPLETE), --12 -> 3
			CARDS_OUT_NEXT_TO_MANIFEST_IN = CreateServerResponseAndAnimationMultiTrigger(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_OUT_COMPLETE, FilterOpenResponseFailed, GetNumCurrentCrownCrateTotalRewards), --13 -> 3
			CARDS_OUT_NEXT_TO_CAT_PRIMARY_DEAL = CreateServerResponseAndAnimationMultiTrigger(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_OUT_COMPLETE, FilterOpenResponseSuccess, GetNumCurrentCrownCrateTotalRewards), --13 -> 6
		    MANIFEST_TO_MANIFEST_OUT_FOR_GEMIFICATION = ZO_StateMachine_TriggerKeybind:New(MANIFEST_TO_GEMIFICATION_KEYBIND), --4 -> 15
            MANIFEST_OUT_FOR_GEMIFICATION_TO_GEMIFICATION = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_OUT_COMPLETE), --15 -> 16
            GEMIFICATION_TO_MANIFEST_IN = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.GEMIFICATION_HIDDEN) --16 -> 3
        }

        --Add Conditionals
        triggers.UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION:SetEventCount(GetNumCurrentCrownCratePrimaryRewards)
	    triggers.UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL:SetEventCount(GetNumCurrentCrownCratePrimaryRewards)
	    triggers.UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION:SetEventCount(GetNumCurrentCrownCrateBonusRewards)
	    triggers.ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED:SetEventCount(GetNumCurrentCrownCrateTotalRewards)
        triggers.MANIFEST_OUT_FOR_GEMIFICATION_TO_GEMIFICATION:SetEventCount(ManifestOutEventCountCallback)
	end
	self.triggers = triggers

	--Add triggers to edges--
	edges.START_TO_FRAMING_PLAYER:AddTrigger(triggers.START_TO_FRAMING_PLAYER)
	edges.FRAMING_PLAYER_TO_SUMMON_CAT:AddTrigger(triggers.FRAMING_PLAYER_TO_SUMMON_CAT)
	edges.SUMMON_CAT_TO_MANIFEST_IN:AddTrigger(triggers.SUMMON_CAT_TO_MANIFEST_IN)
	edges.MANIFEST_IN_TO_MANIFEST:AddTrigger(triggers.MANIFEST_IN_TO_MANIFEST)
	edges.MANIFEST_TO_MANIFEST_OUT_FOR_DEAL:AddTrigger(triggers.MANIFEST_TO_MANIFEST_OUT_FOR_DEAL)
	edges.MANIFEST_OUT_FOR_DEAL_TO_MANIFEST_IN:AddTrigger(triggers.MANIFEST_OUT_FOR_DEAL_TO_MANIFEST_IN)
	edges.MANIFEST_OUT_FOR_DEAL_TO_CAT_PRIMARY_DEAL:AddTrigger(triggers.MANIFEST_OUT_FOR_DEAL_TO_CAT_PRIMARY_DEAL)
	edges.CAT_PRIMARY_DEAL_TO_UI_PRIMARY_DEAL:AddTrigger(triggers.CAT_PRIMARY_DEAL_TO_UI_PRIMARY_DEAL)
	edges.UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION:AddTrigger(triggers.UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION)
	edges.UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL:AddTrigger(triggers.UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL)
	edges.CAT_BONUS_DEAL_TO_UI_BONUS_DEAL:AddTrigger(triggers.CAT_BONUS_DEAL_TO_UI_BONUS_DEAL)
	edges.UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION:AddTrigger(triggers.UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION)
	edges.ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED:AddTrigger(triggers.ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED)
	edges.ALL_REVEALED_TO_CARDS_OUT_BACK:AddTrigger(triggers.ALL_REVEALED_TO_CARDS_OUT_BACK)
	edges.ALL_REVEALED_TO_CARDS_OUT_NEXT:AddTrigger(triggers.ALL_REVEALED_TO_CARDS_OUT_NEXT)
	edges.CARDS_OUT_BACK_TO_MANIFEST_IN:AddTrigger(triggers.CARDS_OUT_BACK_TO_MANIFEST_IN)
	edges.CARDS_OUT_NEXT_TO_MANIFEST_IN:AddTrigger(triggers.CARDS_OUT_NEXT_TO_MANIFEST_IN)
	edges.CARDS_OUT_NEXT_TO_CAT_PRIMARY_DEAL:AddTrigger(triggers.CARDS_OUT_NEXT_TO_CAT_PRIMARY_DEAL)
    edges.MANIFEST_TO_MANIFEST_OUT_FOR_GEMIFICATION:AddTrigger(triggers.MANIFEST_TO_MANIFEST_OUT_FOR_GEMIFICATION)
    edges.MANIFEST_OUT_FOR_GEMIFICATION_TO_GEMIFICATION:AddTrigger(triggers.MANIFEST_OUT_FOR_GEMIFICATION_TO_GEMIFICATION)
    edges.GEMIFICATION_TO_MANIFEST_IN:AddTrigger(triggers.GEMIFICATION_TO_MANIFEST_IN)

	--Add Conditionals--
	edges.UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION:SetConditional(function() return GetNumCurrentCrownCrateBonusRewards() == 0 end)
	edges.UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL:SetConditional(function() return GetNumCurrentCrownCrateBonusRewards() > 0 end)

	do
		local function ManifestInEventCountCallback()
			-- This essentially returns how many packs we expect to be on the first page.
			-- Since the manifest possibly hasn't actually begun loading yet at this point, we can't be sure it has page data, so determine it by hand
			local numOwnedCrateTypes = GetNumOwnedCrownCrateTypes()
			if numOwnedCrateTypes == 0 then
				-- If there are no packs, expect the manifest to tell us it's done immediately
				return 1
			elseif numOwnedCrateTypes > ZO_CROWN_CRATES_PACK_CHOOSING_PACKS_PER_PAGE then
				return ZO_CROWN_CRATES_PACK_CHOOSING_PACKS_PER_PAGE
			else
				return numOwnedCrateTypes
			end
		end

		triggers.MANIFEST_IN_TO_MANIFEST:SetEventCount(ManifestInEventCountCallback)
	end

	--Register actions on states--
	states.START:RegisterCallback("OnActivated", function()
		SetCrownCrateNPCVisible(false)
		self.packChoosing:ResetPacks()
		self.packOpening:ResetCards()
		local IMMEDIATE = true
		SetFullscreenEffect(FULLSCREEN_EFFECT_NONE, 0, 0, IMMEDIATE)
	end)

	states.SUMMON_CAT:RegisterCallback("OnActivated", function()
		SetCrownCrateNPCVisible(true)
	end)

    edges.SUMMON_CAT_TO_MANIFEST_IN:RegisterCallback("OnTrigger", function()
        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_GREET_PLAYER)
    end)

	states.MANIFEST_IN:RegisterCallback("OnActivated", function()
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

	states.MANIFEST:RegisterCallback("OnActivated", function()
		self.packChoosing:AddManifestKeybinds()
		self.packChoosing:RefreshSelectedPack()
	end)

	states.MANIFEST:RegisterCallback("OnDeactivated", function()
		self.packChoosing:RemoveManifestKeybinds()
	end)

	states.MANIFEST_OUT_FOR_DEAL:RegisterCallback("OnActivated", function() 
		self.packChoosing:AnimateChoice()
		PlaySound(SOUNDS.CROWN_CRATES_MANIFEST_OUT)
		--Start the flourish while we wait so it doesn't feel unresponsive
		TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_FLOURISH)
	end)

    states.MANIFEST_OUT_FOR_GEMIFICATION:RegisterCallback("OnActivated", function()
        self.packChoosing:Hide()
    end)

    states.MANIFEST_OUT_FOR_GEMIFICATION:RegisterCallback("OnDeactivated", function()
        self.packChoosing:ResetPacks()
    end)

    states.GEMIFICATION:RegisterCallback("OnActivated", function()
        local gemificationSystem
        if SCENE_MANAGER:IsCurrentSceneGamepad() then
            gemificationSystem = self.gemificationGamepad
        else
            gemificationSystem = self.gemificationKeyboard
        end
        gemificationSystem:InsertIntoScene()
        SCENE_MANAGER:AddFragment(self.gemificationSlot:GetFragment())
    end)

    states.GEMIFICATION:RegisterCallback("OnDeactivated", function()
        SCENE_MANAGER:RemoveFragment(self.gemificationSlot:GetFragment())
    end)

	states.MANIFEST_OUT_FOR_DEAL:RegisterCallback("OnDeactivated", function()
		self.packChoosing:ResetPacks()
		SetFullscreenEffect(FULLSCREEN_EFFECT_NONE)
	end)

	states.CAT_PRIMARY_DEAL:RegisterCallback("OnActivated", function()
		self.packOpening:ResetCards()
		TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_DEAL_PRIMARY_CARDS)
	end)

	states.UI_PRIMARY_DEAL:RegisterCallback("OnActivated", function()
		local success, worldX, worldY, worldZ = GetCrownCrateNPCBoneWorldPosition(GetCrownCrateNPCCardThrowingBoneName())
		if success then
			local localX, localY, localZ = self.manager:GetCameraLocalPositionFromWorldPosition(worldX, worldY, worldZ)
			self.packOpening:StartPrimaryDealAnimation(localX, localY, localZ)
		end
		PlaySound(SOUNDS.CROWN_CRATES_DEAL_PRIMARY)
	end)

	states.UI_PRIMARY_DEAL:RegisterCallback("OnDeactivated", function()
		TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_PRIMARY_CARDS_DEALT)
	end)
                                                                      
	states.CAT_BONUS_DEAL:RegisterCallback("OnActivated", function()
		TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_DEAL_BONUS_CARDS)
	end)

	states.UI_BONUS_DEAL:RegisterCallback("OnActivated", function()
		local success, worldX, worldY, worldZ = GetCrownCrateNPCBoneWorldPosition(GetCrownCrateNPCCardThrowingBoneName())
		if success then
			local localX, localY, localZ = self.manager:GetCameraLocalPositionFromWorldPosition(worldX, worldY, worldZ)
			self.packOpening:StartBonusDealAnimation(localX, localY, localZ)
		end
		PlaySound(SOUNDS.CROWN_CRATES_DEAL_BONUS)
	end)

	states.ACTIVE_HAND_MANIPULATION:RegisterCallback("OnActivated", function()
		self.packOpening:OnDealComplete()
		self.packOpening:AddHandManipulationKeybinds()
		self.packOpening:RefreshSelectedCard()
	end)

	states.ACTIVE_HAND_MANIPULATION:RegisterCallback("OnDeactivated", function()
		self.packOpening:RemoveHandManipulationKeybinds()
	end)

	states.ALL_REVEALED:RegisterCallback("OnActivated", function()
		self.packOpening:AddAllRevealedKeybinds()
		--NPC passively reacts to you being done, depending on your current supply of crates
		if GetNumOwnedCrownCrateTypes() == 0 then
			TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_ALL_CARDS_REVEALED_NO_CRATES)
		else
			TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_ALL_CARDS_REVEALED_HAS_CRATES)
		end
	end)

	states.ALL_REVEALED:RegisterCallback("OnDeactivated", function()
		self.packOpening:RemoveAllRevealedKeybinds()
	end)

	states.CARDS_OUT_BACK:RegisterCallback("OnActivated", function()
		self.packOpening:StartLeaveAnimation()
		TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_SWIPE_CARDS_AWAY)
	end)

	states.CARDS_OUT_NEXT:RegisterCallback("OnActivated", function()
		local currentCrownCrateId = GetCurrentCrownCrateId()
		SendCrownCrateOpenRequest(currentCrownCrateId)
		self.packOpening:StartLeaveAnimation()
		TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_SWIPE_CARDS_AWAY)
		--Start the shuffle while we wait so it doesn't feel unresponsive
		TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_SHUFFLE_CARDS)
	end)

	self.DISABLED_BACK_STATES =
	{
		[states.MANIFEST_OUT_FOR_DEAL] = true,
		[states.CAT_PRIMARY_DEAL] = true,
		[states.UI_PRIMARY_DEAL] = true,
		[states.CAT_BONUS_DEAL] = true,
		[states.UI_BONUS_DEAL] = true,
		[states.ACTIVE_HAND_MANIPULATION] = true,
	}

	self:Reset()
end

function ZO_CrownCratesStateMachine:GetStateByName(stateName)
	return self.states[stateName]
end

function ZO_CrownCratesStateMachine:IsCurrentStateByName(stateName)
	return self:GetStateByName(stateName) == self:GetCurrentState()
end

function ZO_CrownCratesStateMachine:Reset()
	local currentState = self:GetCurrentState()
	if currentState and currentState ~= self.states.START then
		TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_FAREWELL)
	end

	self:SetState(self.states.START)
end

function ZO_CrownCratesStateMachine:CanUseBackKeybind_Gamepad()
	local currentState = self:GetCurrentState()
	if  self.DISABLED_BACK_STATES[currentState] then
		return false
	else
		return true
	end
end
