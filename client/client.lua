local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

----------------------------
-- disable player pushing
----------------------------
CreateThread(function()
    while true do
      Wait(0)
      SetPedResetFlag(cache.ped, 310, false)
    end
end)

----------------------------
-- make local NPC hostile
----------------------------
CreateThread(function()
    while true do
        local sleep = 0
        if LocalPlayer.state.isLoggedIn and Config.HateSystemActive then
            sleep = (5000)
            local outlawstatus = exports['rsg-hud']:GetOutlawStatus()
            local playerPed = PlayerPedId()
            local playerGroup = GetPedRelationshipGroupHash(playerPed)
            if outlawstatus ~= nil and outlawstatus > Config.OutlawTriggerAmount and not LocalPlayer.state['isDead'] then
                SetRelationshipBetweenGroups(6, `rel_civmale`, playerGroup)
            else
                SetRelationshipBetweenGroups(0, `rel_civmale`, playerGroup)
            end
        end
        Wait(sleep)
    end
end)

----------------------------
-- reduce outlaw status over time
----------------------------
CreateThread(function()
    while true do
        local sleep = 0
        if LocalPlayer.state.isLoggedIn and Config.OutlawCooldownActive then
            sleep = (1000 * 60) * Config.OutlawCooldown
            local outlawstatus = exports['rsg-hud']:GetOutlawStatus()
            if outlawstatus == nil then return end
            if outlawstatus > 0 then
                TriggerServerEvent('rex-lootnpc:server:reduceoutlawstaus', outlawstatus)
            end
        end
        Wait(sleep)
    end
end)

----------------------------
-- loot NPCs give outlaw status
----------------------------
CreateThread(function()
    while true do
        local sleep = 0
        local size = GetNumberOfEvents(0)
        if size > 0 then
            for i = 0, size - 1 do
                local eventAtIndex = GetEventAtIndex(0, i)
                if eventAtIndex == 1376140891 then --event needed
                    local view = exports[GetCurrentResourceName()]:DataViewNativeGetEventData2(0, i, 3)
                    local entity = view["2"]
                    if not Citizen.InvokeNative(0x964000D355219FC0, entity) then -- dont allow again
                        local eventDataSize = 3
                        local eventDataStruct = DataView.ArrayBuffer(128)
                        eventDataStruct:SetInt32(0, 0)
                        eventDataStruct:SetInt32(8, 0)
                        eventDataStruct:SetInt32(16, 0)
                        local is_data_exists = Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, 0, i, eventDataStruct:Buffer(),
                            eventDataSize)
                        if is_data_exists then -- can contiue
                            if PlayerPedId() == eventDataStruct:GetInt32(0) then
                                local type = GetPedType(entity)
                                if type == 4 then
                                    if Citizen.InvokeNative(0x8DE41E9902E85756, entity) then -- press prompt
                                        RSGCore.Functions.TriggerCallback('hud:server:getoutlawstatus', function(result)
                                            if Config.LawAlertActive then
                                                local random = math.random(100)
                                                if random <= Config.LawAlertChance then
                                                    local coords = GetEntityCoords(cache.ped)
                                                    TriggerEvent('rsg-lawman:client:lawmanAlert', coords, locale('cl_lang_1'))
                                                end
                                            end
                                            outlawstatus = result[1].outlawstatus
                                            TriggerServerEvent('rex-lootnpc:server:givereward', outlawstatus)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- DATAVIEW
DataView = {
    EndBig = ">",
    EndLittle = "<",
    Types = {
        Int8 = { code = "i1", size = 1 },
        Uint8 = { code = "I1", size = 1 },
        Int16 = { code = "i2", size = 2 },
        Uint16 = { code = "I2", size = 2 },
        Int32 = { code = "i4", size = 4 },
        Uint32 = { code = "I4", size = 4 },
        Int64 = { code = "i8", size = 8 },
        Uint64 = { code = "I8", size = 8 },

        LuaInt = { code = "j", size = 8 },   -- a lua_Integer
        UluaInt = { code = "J", size = 8 },  -- a lua_Unsigned
        LuaNum = { code = "n", size = 8 },   -- a lua_Number
        Float32 = { code = "f", size = 4 },  -- a float (native size)
        Float64 = { code = "d", size = 8 },  -- a double (native size)
        String = { code = "z", size = -1, }, -- zero terminated string
    },
    FixedTypes = {
        String = { code = "c", size = -1, }, -- a fixed-sized string with n bytes
        Int = { code = "i", size = -1, },    -- a signed int with n bytes
        Uint = { code = "I", size = -1, },   -- an unsigned int with n bytes
    },
}
local _strblob = string.blob or function(length)
    return string.rep("\0", math.max(40 + 1, length))
end

DataView.__index = DataView

local function _ib(o, l, t) return ((t.size < 0 and true) or (o + (t.size - 1) <= l)) end

local function _ef(big) return (big and DataView.EndBig) or DataView.EndLittle end

local SetFixed = nil

function DataView.ArrayBuffer(length)
    return setmetatable({
        offset = 1, length = length, blob = _strblob(length)
    }, DataView)
end

function DataView.Wrap(blob)
    return setmetatable({
        offset = 1, blob = blob, length = blob:len(),
    }, DataView)
end

function DataView:Buffer() return self.blob end

function DataView:ByteLength() return self.length end

function DataView:ByteOffset() return self.offset end

function DataView:SubView(offset)
    return setmetatable({
        offset = offset, blob = self.blob, length = self.length,
    }, DataView)
end

for label, datatype in pairs(DataView.Types) do
    DataView["Get" .. label] = function(self, offset, endian)
        local o = self.offset + offset
        if _ib(o, self.length, datatype) then
            local v, _ = string.unpack(_ef(endian) .. datatype.code, self.blob, o)
            return v
        end
        return nil
    end

    DataView["Set" .. label] = function(self, offset, value, endian)
        local o = self.offset + offset
        if _ib(o, self.length, datatype) then
            return SetFixed(self, o, value, _ef(endian) .. datatype.code)
        end
        return self
    end

    if datatype.size >= 0 and string.packsize(datatype.code) ~= datatype.size then
        local msg = "Pack size of %s (%d) does not match cached length: (%d)"
        error(msg:format(label, string.packsize(fmt[#fmt]), datatype.size))
        return nil
    end
end

for label, datatype in pairs(DataView.FixedTypes) do
    DataView["GetFixed" .. label] = function(self, offset, typelen, endian)
        local o = self.offset + offset
        if o + (typelen - 1) <= self.length then
            local code = _ef(endian) .. "c" .. tostring(typelen)
            local v, _ = string.unpack(code, self.blob, o)
            return v
        end
        return nil -- Out of bounds
    end

    DataView["SetFixed" .. label] = function(self, offset, typelen, value, endian)
        local o = self.offset + offset
        if o + (typelen - 1) <= self.length then
            local code = _ef(endian) .. "c" .. tostring(typelen)
            return SetFixed(self, o, value, code)
        end
        return self
    end
end

SetFixed = function(self, offset, value, code)
    local fmt = {}
    local values = {}
    if self.offset < offset then
        local size = offset - self.offset
        fmt[#fmt + 1] = "c" .. tostring(size)
        values[#values + 1] = self.blob:sub(self.offset, size)
    end

    fmt[#fmt + 1] = code
    values[#values + 1] = value
    local ps = string.packsize(fmt[#fmt])
    if (offset + ps) <= self.length then
        local newoff = offset + ps
        local size = self.length - newoff + 1

        fmt[#fmt + 1] = "c" .. tostring(size)
        values[#values + 1] = self.blob:sub(newoff, self.length)
    end

    self.blob = string.pack(table.concat(fmt, ""), table.unpack(values))
    self.length = self.blob:len()
    return self
end
