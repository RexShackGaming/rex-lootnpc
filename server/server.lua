local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------
-- give reward item / money
---------------------------------
RegisterNetEvent('rex-lootnpc:server:givereward', function(outlawstatus)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local newOutlawStatus = outlawstatus + Config.OutlawAdd
    local rewardChance = math.random(100)
    local isRareReward = rewardChance > (100 - Config.RareItemChance)
    MySQL.update('UPDATE players SET outlawstatus = ? WHERE citizenid = ?', { newOutlawStatus, citizenid })
    -- rest of the reward logic remains the same...
    local rewardItem = isRareReward and Config.RareRewardItems[math.random(#Config.RareRewardItems)] or Config.CommonRewardItems[math.random(#Config.CommonRewardItems)]
    local moneyRange = isRareReward and {Config.RareMinMoneyReward, Config.RareMaxMoneyReward} or {Config.CommonMinMoneyReward, Config.CommonMaxMoneyReward}
    Player.Functions.AddItem(rewardItem, 1)
    Player.Functions.AddMoney(Config.MoneyReward, math.random(table.unpack(moneyRange)))
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[rewardItem], 'add', 1)
end)
