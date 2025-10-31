Config = {}

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
Config.DiscordBotName       = 'REX Loot NPC Logs'
Config.DiscordAvatar        = '' -- optional
Config.LogCommonLoot        = false -- log common loot events (can be spammy)
Config.LogRareLoot          = true -- log rare loot events
Config.LogSecurityEvents    = true -- log exploit attempts and security violations
Config.LogPlayerStats       = true -- include player statistics in logs
Config.IncludeCoordinates   = true -- include location coordinates in logs
Config.IncludeSteamInfo     = true -- include steam/license identifiers
Config.WebhookRateLimit     = 1000 -- minimum milliseconds between webhook requests (anti-spam)

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
Config.CommonMaxMoneyReward    = 20 -- max common money reward amount
-------------------------------
Config.RareMinMoneyReward    = 20 -- min rare money reward amount
Config.RareMaxMoneyReward    = 50 -- max rare money reward amount
-------------------------------

-------------------------------
-- rex-wanted : https://rexshackgaming.tebex.io/package/7099128
-------------------------------
Config.RexWanted       = false -- enable rex-wanted system
Config.RexWantedCommon = 5 -- amount of outlaw status to apply
Config.RexWantedRare   = 10 -- amount of outlaw status to apply
Config.RexWantedCrime  = 'Looting NPC' -- crime description

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
