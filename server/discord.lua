local RSGCore = exports['rsg-core']:GetCoreObject()

local function SendDiscordWebhook(playerName, citizenid, itemName, isRareItem, coords, outlawStatus)
    if not Config.EnableDiscordWebhook or not Config.DiscordWebhookURL or Config.DiscordWebhookURL == 'YOUR_WEBHOOK_URL_HERE' then
        return
    end
    
    -- Skip if configured to log rare items only and this isn't rare
    if Config.LogRareOnly and not isRareItem then
        return
    end
    
    local itemType = isRareItem and "**RARE**" or "Common"
    local color = isRareItem and 16776960 or Config.DiscordColor -- Gold for rare, config color for common
    
    local embed = {
        {
            title = "🎯 NPC Looted",
            description = string.format("**%s** has looted an NPC!", playerName),
            color = color,
            fields = {
                {
                    name = "👤 Player",
                    value = playerName,
                    inline = true
                },
                {
                    name = "🆔 Citizen ID", 
                    value = citizenid,
                    inline = true
                },
                {
                    name = "📦 Item Received",
                    value = string.format("%s %s", itemType, RSGCore.Shared.Items[itemName].label),
                    inline = true
                },
                {
                    name = "🏴‍☠️ Outlaw Status",
                    value = tostring(outlawStatus),
                    inline = true
                },
                {
                    name = "📍 Location",
                    value = string.format("X: %.2f, Y: %.2f, Z: %.2f", coords.x, coords.y, coords.z),
                    inline = false
                }
            },
            footer = {
                text = "rex-lootnpc | " .. os.date("%Y-%m-%d %H:%M:%S")
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    local payload = {
        username = Config.DiscordBotName,
        avatar_url = Config.DiscordAvatar,
        embeds = embed
    }
    
    PerformHttpRequest(Config.DiscordWebhookURL, function(err, text, headers) 
        if err ~= 200 and err ~= 204 then
            print("^1[rex-lootnpc] Discord webhook failed with error: " .. tostring(err) .. "^0")
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

-- Export the function for use in other server scripts
exports('SendDiscordWebhook', SendDiscordWebhook)

-- Make it available globally for backwards compatibility
_G.SendDiscordWebhook = SendDiscordWebhook