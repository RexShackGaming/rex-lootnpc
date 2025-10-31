local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------
-- discord webhook function
---------------------------------
local function SendDiscordLog(title, description, color, fields)
    if not Config.EnableDiscordLogs or Config.DiscordWebhook == '' then return end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color,
            ["fields"] = fields or {},
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S"),
            },
        }
    }
    
    PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({
        username = Config.DiscordBotName,
        avatar_url = Config.DiscordAvatar,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

---------------------------------
-- anti-exploit tracking
---------------------------------
local lootCooldowns = {} -- Track player cooldowns
local lootedNPCs = {} -- Track looted NPCs to prevent duplicates

-- Clean up old looted NPCs every 5 minutes
CreateThread(function()
    while true do
        Wait(300000)
        lootedNPCs = {}
    end
end)

---------------------------------
-- helper functions
---------------------------------
local function IsOnCooldown(src)
    if not lootCooldowns[src] then return false end
    return (GetGameTimer() - lootCooldowns[src]) < Config.LootCooldown
end

local function SetCooldown(src)
    lootCooldowns[src] = GetGameTimer()
end

local function ClampOutlawStatus(status)
    return math.max(Config.MinOutlawStatus, math.min(Config.MaxOutlawStatus, status))
end

local function MarkNPCAsLooted(npcId)
    lootedNPCs[npcId] = true
end

local function IsNPCLooted(npcId)
    return lootedNPCs[npcId] == true
end

---------------------------------
-- give reward item
---------------------------------
RegisterNetEvent('rex-lootnpc:server:givereward', function(npcNetId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Security checks
    if IsOnCooldown(src) then
        return -- Silent fail to prevent notification spam
    end
    
    if not npcNetId then return end
    
    if IsNPCLooted(npcNetId) then
        return -- NPC already looted
    end
    
    -- Validate reward tables
    if #Config.CommonRewardItems == 0 and #Config.RareRewardItems == 0 then
        print(locale('sv_error_no_rewards'))
        return
    end
    
    SetCooldown(src)
    MarkNPCAsLooted(npcNetId)
    
    local citizenid = Player.PlayerData.citizenid
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname = Player.PlayerData.charinfo.lastname
    
    -- Get current outlaw status from database (don't trust client)
    local result = MySQL.query.await('SELECT outlawstatus FROM players WHERE citizenid = ?', { citizenid })
    if not result or not result[1] then return end
    
    local outlawstatus = result[1].outlawstatus or 0
    local rewardchance = math.random(100)
    local isRare = rewardchance > (100 - Config.RareItemChance)
    local moneyAmount = 0
    local itemName = ''
    
    if isRare and #Config.RareRewardItems > 0 then
        itemName = Config.RareRewardItems[math.random(#Config.RareRewardItems)]
        Player.Functions.AddItem(itemName, 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], 'add', 1)
        TriggerEvent('rsg-log:server:CreateLog', 'looting', locale('sv_lang_1'), 'green', firstname..' '..lastname..' ('..citizenid..locale('sv_lang_2')..RSGCore.Shared.Items[itemName].label)
        
        -- money reward during looting
        if Config.EnableRareMoneyReward then
            if Config.RareRandomMoneyReward then
                moneyAmount = math.random(Config.RareMinMoneyReward, Config.RareMaxMoneyReward)
            else
                moneyAmount = Config.RareMoneyReward
            end
            Player.Functions.AddMoney(Config.MoneyReward, moneyAmount)
        end
        
        -- Discord log for rare loot
        if Config.LogRareLoot then
            SendDiscordLog(
                "🌟 Rare Loot Obtained",
                string.format("**%s %s** looted a rare item!", firstname, lastname),
                16776960, -- Gold color
                {
                    { name = "Player", value = firstname.." "..lastname, inline = true },
                    { name = "Citizen ID", value = citizenid, inline = true },
                    { name = "Item", value = RSGCore.Shared.Items[itemName].label, inline = true },
                    { name = "Money Reward", value = "$"..moneyAmount..(" ("..Config.MoneyReward..")"), inline = true },
                    { name = "Outlaw Status", value = newoutlawstatus.."/%s"..(Config.MaxOutlawStatus), inline = true },
                }
            )
        end
    else
        if #Config.CommonRewardItems == 0 then return end
        itemName = Config.CommonRewardItems[math.random(#Config.CommonRewardItems)]
        Player.Functions.AddItem(itemName, 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], 'add', 1)
        TriggerEvent('rsg-log:server:CreateLog', 'looting', locale('sv_lang_3'), 'green', firstname..' '..lastname..' ('..citizenid..locale('sv_lang_2')..RSGCore.Shared.Items[itemName].label)
        
        -- money reward during looting
        if Config.EnableCommonMoneyReward then
            if Config.CommonRandomMoneyReward then
                moneyAmount = math.random(Config.CommonMinMoneyReward, Config.CommonMaxMoneyReward)
            else
                moneyAmount = Config.CommonMoneyReward
            end
            Player.Functions.AddMoney(Config.MoneyReward, moneyAmount)
        end
        
        -- Discord log for common loot
        if Config.LogCommonLoot then
            SendDiscordLog(
                "📦 Common Loot Obtained",
                string.format("**%s %s** looted a common item.", firstname, lastname),
                3447003, -- Blue color
                {
                    { name = "Player", value = firstname.." "..lastname, inline = true },
                    { name = "Citizen ID", value = citizenid, inline = true },
                    { name = "Item", value = RSGCore.Shared.Items[itemName].label, inline = true },
                    { name = "Money Reward", value = "$"..moneyAmount..(" ("..Config.MoneyReward..")"), inline = true },
                    { name = "Outlaw Status", value = newoutlawstatus.."/%s"..(Config.MaxOutlawStatus), inline = true },
                }
            )
        end
    end
    
    -- Update outlaw status with bounds checking
    local newoutlawstatus = ClampOutlawStatus(outlawstatus + 1)
    MySQL.update('UPDATE players SET outlawstatus = ? WHERE citizenid = ?', { newoutlawstatus, citizenid })
    
    -- Discord log for high outlaw status
    if Config.LogHighOutlawStatus and newoutlawstatus >= Config.HighOutlawThreshold and outlawstatus < Config.HighOutlawThreshold then
        SendDiscordLog(
            "⚠️ High Outlaw Status Alert",
            string.format("**%s %s** has reached high outlaw status!", firstname, lastname),
            15158332, -- Red color
            {
                { name = "Player", value = firstname.." "..lastname, inline = true },
                { name = "Citizen ID", value = citizenid, inline = true },
                { name = "Outlaw Status", value = newoutlawstatus.."/%s"..(Config.MaxOutlawStatus), inline = true },
                { name = "Threshold", value = Config.HighOutlawThreshold, inline = true },
            }
        )
    end
    
    -- Send feedback notification to player
    local itemLabel = RSGCore.Shared.Items[itemName].label
    local rewardType = isRare and locale('notify_rare_loot') or locale('notify_common_loot')
    local moneyText = moneyAmount > 0 and ' + $'..moneyAmount or ''
    local message = string.format(locale('notify_looted'), itemLabel, moneyText)
    TriggerClientEvent('ox_lib:notify', src, {
        title = rewardType,
        description = message,
        type = 'success',
        duration = 3000
    })
end)

---------------------------------
-- reduce outlaw status
---------------------------------
RegisterNetEvent('rex-lootnpc:server:reduceoutlawstaus', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Get current status from database (don't trust client)
    local result = MySQL.query.await('SELECT outlawstatus FROM players WHERE citizenid = ?', { citizenid })
    if not result or not result[1] then return end
    
    local currentStatus = result[1].outlawstatus or 0
    local newoutlawstatus = ClampOutlawStatus(currentStatus - Config.OutlawCooldownAmount)
    
    MySQL.update('UPDATE players SET outlawstatus = ? WHERE citizenid = ?', { newoutlawstatus, citizenid })
end)
