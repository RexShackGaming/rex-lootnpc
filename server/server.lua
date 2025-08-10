local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------
-- give reward item
---------------------------------
RegisterNetEvent('rex-lootnpc:server:givereward', function(outlawstatus)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname = Player.PlayerData.charinfo.lastname
    if not Player then return end
    local rewardchance = math.random(100)
    if rewardchance > (100 - Config.RareItemChance) then
        local randomItem = Config.RareRewardItems[math.random(#Config.RareRewardItems)]
        Player.Functions.AddItem(randomItem, 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[randomItem], 'add', 1)
        TriggerEvent('rsg-log:server:CreateLog', 'looting', locale('sv_lang_1'), 'green', firstname..' '..lastname..' ('..citizenid..locale('sv_lang_2')..RSGCore.Shared.Items[randomItem].label)
        -- money reward during looting
        if Config.EnableRareMoneyReward then
            if Config.RareRandomMoneyReward then
                Player.Functions.AddMoney(Config.MoneyReward, math.random(Config.RareMinMoneyReward,Config.RareMaxMoneyReward))
            else
                Player.Functions.AddMoney(Config.MoneyReward, Config.RareMoneyReward)
            end
        end
        -- udpate outlaw status
        local newoutlawstatus = (outlawstatus + 1)
        MySQL.update('UPDATE players SET outlawstatus = ? WHERE citizenid = ?', { newoutlawstatus, citizenid })
    else
        local randomItem = Config.CommonRewardItems[math.random(#Config.CommonRewardItems)]
        Player.Functions.AddItem(randomItem, 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[randomItem], 'add', 1)
        TriggerEvent('rsg-log:server:CreateLog', 'looting', locale('sv_lang_3'), 'green', firstname..' '..lastname..' ('..citizenid..locale('sv_lang_2')..RSGCore.Shared.Items[randomItem].label)
        -- money reward during looting
        if Config.EnableCommonMoneyReward then
            if Config.CommonRandomMoneyReward then
                Player.Functions.AddMoney(Config.MoneyReward, math.random(Config.CommonMinMoneyReward,Config.CommonMaxMoneyReward))
            else
                Player.Functions.AddMoney(Config.MoneyReward, Config.CommonMoneyReward)
            end
        end
        -- udpate outlaw status
        local newoutlawstatus = (outlawstatus + 1)
        MySQL.update('UPDATE players SET outlawstatus = ? WHERE citizenid = ?', { newoutlawstatus, citizenid })
    end
end)

---------------------------------
-- reduce outlaw status
---------------------------------
RegisterNetEvent('rex-lootnpc:server:reduceoutlawstaus', function(outlawstatus)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local newoutlawstatus = (outlawstatus - Config.OutlawCooldownAmount)
    MySQL.update('UPDATE players SET outlawstatus = ? WHERE citizenid = ?', { newoutlawstatus, citizenid })
end)
