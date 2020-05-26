----
-- ZO_CharacterSelect_EventTile_Gamepad
----

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_CharacterSelect_EventTile_Gamepad = ZO_Object.MultiSubclass(ZO_Tile_Gamepad, ZO_CharacterSelect_EventTile_Shared)

function ZO_CharacterSelect_EventTile_Gamepad:New(...)
    return ZO_CharacterSelect_EventTile_Shared.New(self, ...)
end

function ZO_CharacterSelect_EventTile_Gamepad:Initialize(...)
    return ZO_CharacterSelect_EventTile_Shared.Initialize(self, ...)
end

-----
-- Global XML Functions
-----

function ZO_CharacterSelect_EventTile_Gamepad_OnInitialized(control)
    ZO_CharacterSelect_EventTile_Gamepad:New(control)
end