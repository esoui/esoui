----
-- ZO_DailyRewardsLogoutTile_Gamepad
----

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_DailyRewardsLogoutTile_Gamepad = ZO_Object.MultiSubclass(ZO_ActionTile_Gamepad, ZO_DailyRewardsLogoutTile)

function ZO_DailyRewardsLogoutTile_Gamepad:New(...)
    return ZO_DailyRewardsLogoutTile.New(self, ...)
end

-----
-- Global XML Functions
-----

function ZO_DailyRewardsLogoutTile_Gamepad_OnInitialized(control)
	ZO_DailyRewardsLogoutTile_Gamepad:New(control)
end