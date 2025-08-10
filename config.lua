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
Config.LawAlertActive       = true
Config.LawAlertChance       = 20 -- 20% chance of informing the law
-------------------------------
-- money rewards during looting
-------------------------------
Config.EnableMoneyReward = true -- if true looter will also get money as well as an item
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
