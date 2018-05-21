----
-- ZO_DailyRewardsLogoutTile_Keyboard
----

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_DailyRewardsLogoutTile_Keyboard = ZO_Object.MultiSubclass(ZO_ActionTile_Keyboard, ZO_DailyRewardsLogoutTile)

function ZO_DailyRewardsLogoutTile_Keyboard:New(...)
    return ZO_DailyRewardsLogoutTile.New(self, ...)
end

-----
-- Global XML Functions
-----

function ZO_DailyRewardsLogoutTile_Keyboard_OnInitialized(control)
	ZO_DailyRewardsLogoutTile_Keyboard:New(control)
end