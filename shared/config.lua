Config = {}

-------------------------------
-- settings
-------------------------------
Config.RareItemChance       = 10 -- 10% of getting a rare item
Config.HateSystemActive     = true -- enable npc outlaw hate system
Config.UpdateInterval       = 1 -- every min
Config.OutlawTriggerAmount  = 20 -- outlaw status that triggers hate
Config.OutlawCooldownActive = true -- reduces outlaw status over time
Config.OutlawCooldown       = 5 -- mins : reduces outlaw status every cycle
Config.OutlawCooldownAmount = 1 -- amount of outlaw status to reduce
Config.MaxOutlawStatus      = 100 -- maximum outlaw status
Config.MinOutlawStatus      = 0 -- minimum outlaw status
Config.LootCooldown         = 2000 -- milliseconds between loots (anti-spam)
Config.LawAlertActive       = true
Config.LawAlertChance       = 20 -- 20% chance of informing the law
-------------------------------
-- discord webhook settings
-------------------------------
Config.EnableDiscordLogs    = true -- enable discord webhook logging
Config.DiscordWebhook       = '' -- your discord webhook url
Config.DiscordBotName       = 'Loot NPC Logs'
Config.DiscordAvatar        = 'https://i.imgur.com/your-avatar.png' -- optional
Config.LogCommonLoot        = false -- log common loot events
Config.LogRareLoot          = true -- log rare loot events
Config.LogHighOutlawStatus  = true -- log when players reach high outlaw status
Config.HighOutlawThreshold  = 50 -- outlaw status threshold to trigger discord log
-------------------------------
-- money rewards during looting
-------------------------------
Config.MoneyReward       = 'bloodmoney' -- use bloodmoney or cash
Config.CommonMoneyReward = 1 -- if random money reward is not enabled this is the default amount given
Config.RareMoneyReward   = 5 -- if random money reward is not enabled this is the default amount given
-------------------------------
Config.EnableCommonMoneyReward = true -- if true it will give random commen money rewards as configued
Config.CommonRandomMoneyReward = true -- if true it will use random reward rather than static
Config.CommonMinMoneyReward    = 1 -- min common money reward amount
Config.CommonMaxMoneyReward    = 3 -- max common money reward amount
-------------------------------
Config.EnableRareMoneyReward = true -- if true it will give random rare money rewards as configued
Config.RareRandomMoneyReward = true
Config.RareMinMoneyReward    = 1 -- min rare money reward amount
Config.RareMaxMoneyReward    = 5 -- max rare money reward amount
-------------------------------

-------------------------------
-- common loot
-------------------------------
Config.CommonRewardItems = {
    'bread', -- example
}

-------------------------------
-- rare loot
-------------------------------
Config.RareRewardItems = {
    'water', -- example
}
