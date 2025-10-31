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
    'bread'
}

-------------------------------
-- rare loot
-------------------------------
Config.RareRewardItems = {
    'water'
}
