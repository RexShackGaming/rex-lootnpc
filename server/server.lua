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
local processingLoots = {} -- Track in-progress loot requests to prevent race conditions

-- Clean up old looted NPCs every 5 minutes
CreateThread(function()
    while true do
        Wait(300000)
        lootedNPCs = {}
    end
end)

-- Clean up disconnected player cooldowns
AddEventHandler('playerDropped', function()
    local src = source
    lootCooldowns[src] = nil
    processingLoots[src] = nil
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

local function MarkNPCAsLooted(npcId)
    lootedNPCs[npcId] = true
end

local function IsNPCLooted(npcId)
    return lootedNPCs[npcId] == true
end

local function IsProcessingLoot(src)
    return processingLoots[src] == true
end

local function SetProcessingLoot(src, state)
    processingLoots[src] = state
end

local function ValidateNPC(npcNetId, playerCoords)
    if not npcNetId or npcNetId == 0 then return false end
    
    local npcEntity = NetworkGetEntityFromNetworkId(npcNetId)
    if not npcEntity or npcEntity == 0 or not DoesEntityExist(npcEntity) then
        return false
    end
    
    -- Verify it's actually a ped (NPC)
    if GetEntityType(npcEntity) ~= 1 then -- 1 = ped
        return false
    end
    
    -- Verify it's a human NPC (ped type 4)
    if GetPedType(npcEntity) ~= 4 then
        return false
    end
    
    -- Verify NPC is dead
    if not IsEntityDead(npcEntity) then
        return false
    end
    
    -- Distance check (prevent remote looting)
    local npcCoords = GetEntityCoords(npcEntity)
    local distance = #(playerCoords - npcCoords)
    if distance > 5.0 then -- Max loot distance 5 units
        return false
    end
    
    return true
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
    
    -- Prevent race condition exploitation
    if IsProcessingLoot(src) then
        return
    end
    
    if not npcNetId then return end
    
    if IsNPCLooted(npcNetId) then
        return -- NPC already looted
    end
    
    -- Get player position for validation
    local playerPed = GetPlayerPed(src)
    if not playerPed or playerPed == 0 then return end
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Server-side entity validation (CRITICAL SECURITY CHECK)
    if not ValidateNPC(npcNetId, playerCoords) then
        print(string.format('[SECURITY] Player %s (src: %d) failed NPC validation', Player.PlayerData.citizenid, src))
        return
    end
    
    -- Validate reward tables
    if #Config.CommonRewardItems == 0 and #Config.RareRewardItems == 0 then
        print(locale('sv_error_no_rewards'))
        return
    end
    
    -- Mark as processing BEFORE any reward distribution
    SetProcessingLoot(src, true)
    SetCooldown(src)
    MarkNPCAsLooted(npcNetId)
    
    local citizenid = Player.PlayerData.citizenid
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname = Player.PlayerData.charinfo.lastname
    -- Validate config values to prevent errors
    local rareItemChance = math.max(0, math.min(100, Config.RareItemChance or 10))
    local rewardchance = math.random(100)
    local isRare = rewardchance > (100 - rareItemChance)
    local moneyAmount = 0
    local itemName = ''
    
    if isRare and #Config.RareRewardItems > 0 then
        itemName = Config.RareRewardItems[math.random(#Config.RareRewardItems)]
        Player.Functions.AddItem(itemName, 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], 'add', 1)
        
        -- money reward during looting
        if Config.EnableRareMoneyReward then
            local minReward = Config.RareMinMoneyReward or 10
            local maxReward = math.max(minReward, Config.RareMaxMoneyReward or 100)
            moneyAmount = math.random(minReward, maxReward)
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
                }
            )
        end
    else
        if #Config.CommonRewardItems == 0 then return end
        itemName = Config.CommonRewardItems[math.random(#Config.CommonRewardItems)]
        Player.Functions.AddItem(itemName, 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], 'add', 1)
        
        -- money reward during looting
        if Config.EnableCommonMoneyReward then
            local minReward = Config.CommonMinMoneyReward or 5
            local maxReward = math.max(minReward, Config.CommonMaxMoneyReward or 50)
            moneyAmount = math.random(minReward, maxReward)
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
                }
            )
        end
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
    
    -- Clear processing flag
    SetProcessingLoot(src, false)
end)

