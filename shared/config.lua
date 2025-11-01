Config = {}

-------------------------------
-- settings
-------------------------------
Config.RareItemChance = 10 -- 10% of getting a rare item
Config.LawAlertActive = true -- toggle law alerts on/off
Config.LawAlertChance = 20 -- 20% chance of informing the law
Config.OutlawAdd      = 5 -- amount of outlawstatus to add

-------------------------------
-- money rewards during looting
-------------------------------
Config.EnableMoneyReward = true -- if true looter will also get money as well as an item
Config.MoneyReward       = 'bloodmoney' -- use bloodmoney or cash
-------------------------------
Config.CommonMinMoneyReward = 5 -- min common money reward amount
Config.CommonMaxMoneyReward = 20 -- max common money reward amount
-------------------------------
Config.RareMinMoneyReward = 20 -- min rare money reward amount
Config.RareMaxMoneyReward = 50 -- max rare money reward amount

-------------------------------
-- common loot
-------------------------------
Config.CommonRewardItems = {
    'bread' -- example
}

-------------------------------
-- rare loot
-------------------------------
Config.RareRewardItems = {
    'water' -- example
}

-------------------------------
-- discord webhook settings
-------------------------------
Config.EnableDiscordWebhook = true -- toggle discord webhook notifications
Config.DiscordWebhookURL = 'YOUR_WEBHOOK_URL_HERE' -- your discord webhook URL
Config.DiscordBotName = 'Loot NPC Logger' -- name displayed in discord
Config.DiscordAvatar = 'https://i.imgur.com/YourAvatarURL.png' -- avatar URL (optional)
Config.DiscordColor = 16711680 -- embed color (decimal) - default is red
Config.LogRareOnly = false -- if true, only logs rare item loots
