local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------
-- discord webhook function
---------------------------------
local webhookQueue = {}
local lastWebhookTime = 0
local playerLootStats = {} -- Track player loot statistics

local function GetPlayerIdentifiers(src)
    if not Config.IncludeSteamInfo then return nil end
    
    local identifiers = {
        steam = nil,
        license = nil,
        discord = nil
    }
    
    for _, id in pairs(GetPlayerIdentifiers(src)) do
        if string.match(id, 'steam:') then
            identifiers.steam = id
        elseif string.match(id, 'license:') then
            identifiers.license = id
        elseif string.match(id, 'discord:') then
            identifiers.discord = '<@' .. string.gsub(id, 'discord:', '') .. '>'
        end
    end
    
    return identifiers
end

local function FormatCoords(coords)
    if not Config.IncludeCoordinates or not coords then return nil end
    return string.format("X: %.2f, Y: %.2f, Z: %.2f", coords.x, coords.y, coords.z)
end

local function SendDiscordLog(title, description, color, fields, thumbnail, author)
    if not Config.EnableDiscordLogs or not Config.DiscordWebhook or Config.DiscordWebhook == '' then return end
    
    -- Rate limiting
    local currentTime = GetGameTimer()
    if (currentTime - lastWebhookTime) < (Config.WebhookRateLimit or 1000) then
        table.insert(webhookQueue, {title, description, color, fields, thumbnail, author})
        return
    end
    
    lastWebhookTime = currentTime
    
    local embed = {
        ["title"] = title,
        ["description"] = description,
        ["color"] = color,
        ["fields"] = fields or {},
        ["footer"] = {
            ["text"] = os.date("%Y-%m-%d %H:%M:%S") .. " | Rex Loot NPC",
            ["icon_url"] = "https://i.imgur.com/YourIconHere.png" -- Optional: Add your server icon
        },
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    if thumbnail then
        embed["thumbnail"] = { ["url"] = thumbnail }
    end
    
    if author then
        embed["author"] = author
    end
    
    PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers)
        if err ~= 200 and err ~= 204 then
            print(string.format('[ERROR] Discord webhook failed with code: %s', err))
        end
    end, 'POST', json.encode({
        username = Config.DiscordBotName or 'Loot NPC Logs',
        avatar_url = Config.DiscordAvatar,
        embeds = {embed}
    }), { ['Content-Type'] = 'application/json' })
end

-- Process queued webhook requests
CreateThread(function()
    while true do
        Wait(Config.WebhookRateLimit or 1000)
        if #webhookQueue > 0 then
            local data = table.remove(webhookQueue, 1)
            SendDiscordLog(table.unpack(data))
        end
    end
end)

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
        
        -- Log security event to Discord
        if Config.LogSecurityEvents then
            local identifiers = GetPlayerIdentifiers(src)
            SendDiscordLog(
                "🚨 Security Alert: Invalid NPC Loot Attempt",
                string.format("**%s %s** attempted to loot an invalid NPC!", firstname, lastname),
                15158332, -- Red
                {
                    { name = "Player", value = firstname.." "..lastname, inline = true },
                    { name = "Citizen ID", value = citizenid, inline = true },
                    { name = "Server ID", value = tostring(src), inline = true },
                    { name = "NPC Network ID", value = tostring(npcNetId), inline = true },
                    { name = "Location", value = FormatCoords(playerCoords) or "Unknown", inline = false },
                    { name = "Steam ID", value = identifiers and identifiers.steam or "N/A", inline = true },
                    { name = "License", value = identifiers and identifiers.license or "N/A", inline = true },
                    { name = "Discord", value = identifiers and identifiers.discord or "N/A", inline = true },
                },
                nil,
                {
                    ["name"] = "⚠️ Exploit Attempt",
                    ["icon_url"] = "https://i.imgur.com/warning_icon.png"
                }
            )
        end
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
    
    -- Track player statistics
    if not playerLootStats[citizenid] then
        playerLootStats[citizenid] = { total = 0, rare = 0, common = 0, totalMoney = 0 }
    end
    
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
            local minReward = Config.RareMinMoneyReward or 20
            local maxReward = math.max(minReward, Config.RareMaxMoneyReward or 50)
            moneyAmount = math.random(minReward, maxReward)
            Player.Functions.AddMoney(Config.MoneyReward, moneyAmount)
        end

        if Config.RexWanted then
            exports['rex-wanted']:AddPlayerOutlawStatus(src, Config.RexWantedRare, Config.RexWantedCrime)
        end

        -- Update statistics
        playerLootStats[citizenid].total = playerLootStats[citizenid].total + 1
        playerLootStats[citizenid].rare = playerLootStats[citizenid].rare + 1
        playerLootStats[citizenid].totalMoney = playerLootStats[citizenid].totalMoney + moneyAmount
        
        -- Discord log for rare loot
        if Config.LogRareLoot then
            local identifiers = GetPlayerIdentifiers(src)
            local statsText = ""
            if Config.LogPlayerStats then
                statsText = string.format(" | Total Loots: %d (Rare: %d, Common: %d)", 
                    playerLootStats[citizenid].total,
                    playerLootStats[citizenid].rare,
                    playerLootStats[citizenid].common)
            end
            
            local fields = {
                { name = "Player", value = firstname.." "..lastname, inline = true },
                { name = "Citizen ID", value = citizenid, inline = true },
                { name = "Server ID", value = tostring(src), inline = true },
                { name = "Item", value = RSGCore.Shared.Items[itemName].label, inline = true },
                { name = "Money Reward", value = "$"..moneyAmount.." ("..Config.MoneyReward..")", inline = true },
                { name = "Rarity Roll", value = rewardchance.."%", inline = true },
            }
            
            if Config.IncludeCoordinates then
                table.insert(fields, { name = "Location", value = FormatCoords(playerCoords), inline = false })
            end
            
            if Config.LogPlayerStats then
                table.insert(fields, { name = "Player Statistics", value = string.format("Total: %d | Rare: %d | Common: %d | Total $: %d",
                    playerLootStats[citizenid].total,
                    playerLootStats[citizenid].rare,
                    playerLootStats[citizenid].common,
                    playerLootStats[citizenid].totalMoney), inline = false })
            end
            
            if identifiers then
                table.insert(fields, { name = "Steam ID", value = identifiers.steam or "N/A", inline = true })
                if identifiers.discord then
                    table.insert(fields, { name = "Discord", value = identifiers.discord, inline = true })
                end
            end
            
            SendDiscordLog(
                "🌟 Rare Loot Obtained",
                string.format("**%s %s** looted a rare item!%s", firstname, lastname, statsText),
                16776960, -- Gold color
                fields,
                "https://i.imgur.com/rare_item_icon.png", -- Optional: rare item thumbnail
                {
                    ["name"] = firstname.." "..lastname,
                    ["icon_url"] = "https://i.imgur.com/player_icon.png" -- Optional: player icon
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
            local maxReward = math.max(minReward, Config.CommonMaxMoneyReward or 20)
            moneyAmount = math.random(minReward, maxReward)
            Player.Functions.AddMoney(Config.MoneyReward, moneyAmount)
        end
		
        if Config.RexWanted then
            exports['rex-wanted']:AddPlayerOutlawStatus(src, Config.RexWantedCommon, Config.RexWantedCrime)
        end
        
        -- Update statistics
        playerLootStats[citizenid].total = playerLootStats[citizenid].total + 1
        playerLootStats[citizenid].common = playerLootStats[citizenid].common + 1
        playerLootStats[citizenid].totalMoney = playerLootStats[citizenid].totalMoney + moneyAmount
        
        -- Discord log for common loot
        if Config.LogCommonLoot then
            local identifiers = GetPlayerIdentifiers(src)
            local statsText = ""
            if Config.LogPlayerStats then
                statsText = string.format(" | Total Loots: %d", playerLootStats[citizenid].total)
            end
            
            local fields = {
                { name = "Player", value = firstname.." "..lastname, inline = true },
                { name = "Citizen ID", value = citizenid, inline = true },
                { name = "Server ID", value = tostring(src), inline = true },
                { name = "Item", value = RSGCore.Shared.Items[itemName].label, inline = true },
                { name = "Money Reward", value = "$"..moneyAmount.." ("..Config.MoneyReward..")", inline = true },
            }
            
            if Config.IncludeCoordinates then
                table.insert(fields, { name = "Location", value = FormatCoords(playerCoords), inline = false })
            end
            
            if Config.LogPlayerStats then
                table.insert(fields, { name = "Player Statistics", value = string.format("Total: %d | Rare: %d | Common: %d | Total $: %d",
                    playerLootStats[citizenid].total,
                    playerLootStats[citizenid].rare,
                    playerLootStats[citizenid].common,
                    playerLootStats[citizenid].totalMoney), inline = false })
            end
            
            SendDiscordLog(
                "📦 Common Loot Obtained",
                string.format("**%s %s** looted a common item.%s", firstname, lastname, statsText),
                3447003, -- Blue color
                fields
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

