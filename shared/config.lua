Config = {}

-------------------------------
-- settings
-------------------------------
Config.HateSystemActive     = true -- enable npc outlaw hate system
Config.UpdateInterval       = 1 -- every min
Config.OutlawTriggerAmount  = 100 -- outlaw status that triggers hate
Config.OutlawCooldownActive = true -- reduces outlaw status over time
Config.OutlawCooldown       = 5 -- mins : reduces outlaw status every cycle
Config.OutlawCooldownAmount = 5 -- amount of outlaw status to reduce
Config.MinOutlawStatus      = 0 -- minimum outlaw status
Config.MaxOutlawStatus      = 100 -- maximum outlaw status

-------------------------------
-- law alert system
-------------------------------
Config.LawAlertActive       = true
Config.LawAlertChance       = 20 -- 20% chance of informing the law

-------------------------------
-- discord webhook settings
-------------------------------
Config.EnableDiscordLogs    = true -- enable discord webhook logging
Config.DiscordWebhook       = '' -- your discord webhook url
Config.DiscordBotName       = 'Loot NPC Logs'
Config.DiscordAvatar        = '' -- optional
Config.LogCommonLoot        = true -- log common loot events
Config.LogRareLoot          = true -- log rare loot events
Config.LogHighOutlawStatus  = true -- log when players reach high outlaw status
Config.HighOutlawThreshold  = 100 -- outlaw status threshold to trigger discord log

-------------------------------
-- loot system
-------------------------------
Config.RareItemChance          = 10 -- 10% of getting a rare item
Config.LootCooldown            = 2000 -- milliseconds between loots (anti-spam)
Config.MoneyReward             = 'bloodmoney' -- use bloodmoney or cash
Config.EnableCommonMoneyReward = true
Config.EnableRareMoneyReward   = true
-------------------------------
-- random money reward
-------------------------------
Config.CommonMinMoneyReward    = 5 -- min common money reward amount
Config.CommonMaxMoneyReward    = 50 -- max common money reward amount
-------------------------------
Config.RareMinMoneyReward    = 10 -- min rare money reward amount
Config.RareMaxMoneyReward    = 100 -- max rare money reward amount
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
