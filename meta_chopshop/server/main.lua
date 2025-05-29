-- Meta Chop Shop by namicKIDDO
print('^2[Meta Scripts] ^7Meta Chop Shop by ^1namicKIDDO^7')
print('^2[Meta Scripts] ^7Version: ^1v1.0.0^7')
print('^2[Meta Scripts] ^7Discord: ^1discord.gg/gyHsE3ZvQs^7')
print('^2[Meta Scripts] ^7Report any bugs to our Discord for fixes^7')

local QBCore = exports['qb-core']:GetCoreObject()
local ESX = nil
local Inventory = require 'shared/inventory'

-- Framework Initialization
if Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

-- Get player framework object
local function GetPlayer(source)
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        return QBCore.Functions.GetPlayer(source)
    else
        return ESX.GetPlayerFromId(source)
    end
end

-- Add item to player inventory
function AddItem(source, item, amount)
    local Player = GetPlayer(source)
    if not Player then
        print("^1[ERROR] Player not found^7")
        return false
    end

    print("^2[DEBUG] Attempting to add item: " .. item .. " amount: " .. amount .. "^7")
    
    -- Check if item exists in shared items
    if not Inventory.ItemExists(item) then
        print("^1[ERROR] Item not found in shared items: " .. item .. "^7")
        return false
    end

    local success = Inventory.AddItem(source, item, amount)
    if not success then
        print("^1[ERROR] Failed to add item: " .. item .. " amount: " .. amount .. "^7")
        return false
    end

    print("^2[DEBUG] Successfully added item: " .. item .. " amount: " .. amount .. "^7")
    return true
end

-- Add money to player
local function AddMoney(source, amount)
    local Player = GetPlayer(source)
    if not Player then 
        print("^1[ERROR] Player not found for source: " .. tostring(source))
        return false 
    end
    
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        local success = Player.Functions.AddMoney('cash', amount)
        if not success then
            print("^1[ERROR] Failed to add money: " .. amount)
        end
        return success
    else
        local success = Player.addMoney(amount)
        if not success then
            print("^1[ERROR] Failed to add money: " .. amount)
        end
        return success
    end
end

-- Get police count
local function GetPoliceCount()
    local count = 0
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        count = QBCore.Functions.GetDutyCount('police')
    else
        local xPlayers = ESX.GetPlayers()
        for i=1, #xPlayers do
            local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
            if xPlayer.job.name == 'police' then
                count = count + 1
            end
        end
    end
    return count
end

-- Process reward for chopped part
RegisterNetEvent('meta_chopshop:server:reward', function(part)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Get reward configuration
    local reward = part.reward
    if not reward then return end
    
    -- Add the part item
    if reward.item then
        local amount = 1 -- Default amount
        
        -- Handle amount configuration
        if type(reward.amount) == 'table' then
            amount = math.random(reward.amount.min or 1, reward.amount.max or 1)
        elseif type(reward.amount) == 'number' then
            amount = reward.amount
        end
        
        -- Add item to inventory
        if AddItem(src, reward.item, amount) then
            -- Get item label from shared items
            local itemLabel = QBCore.Shared.Items[reward.item] and QBCore.Shared.Items[reward.item].label or reward.item
            
            -- Notify player
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[reward.item], "add")
            TriggerClientEvent('meta_chopshop:notify', src, 'You received ' .. amount .. 'x ' .. itemLabel)
        else
            TriggerClientEvent('meta_chopshop:notify', src, 'Your inventory is full!')
        end
    end
end)

-- Sell vehicle part
RegisterNetEvent('meta_chopshop:server:sellPart', function(partName)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end

    -- Find the part configuration
    local partConfig = nil
    for _, part in ipairs(Config.VehicleParts) do
        if part.name == partName then
            partConfig = part
            break
        end
    end

    if not partConfig or not partConfig.reward then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Part Buyer',
            description = Config.PartSelling.notifications.failed,
            type = 'error'
        })
        return
    end

    -- Check if player has the part
    local count = Inventory.GetItemCount(src, partConfig.item)
    if not count or count <= 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Part Buyer',
            description = Config.PartSelling.notifications.no_parts,
            type = 'error'
        })
        return
    end

    -- Calculate sell price
    local minPrice = partConfig.reward.sell_price and partConfig.reward.sell_price.min or 100
    local maxPrice = partConfig.reward.sell_price and partConfig.reward.sell_price.max or 200
    local price = math.random(minPrice, maxPrice)
    
    -- Remove the part
    local success = Inventory.RemoveItem(src, partConfig.item, 1)
    if not success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Part Buyer',
            description = Config.PartSelling.notifications.failed,
            type = 'error'
        })
        return
    end

    -- Add money
    AddMoney(src, price)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Part Buyer',
        description = string.format(Config.PartSelling.notifications.success, price),
        type = 'success'
    })
end)

-- Get sellable parts
RegisterNetEvent('meta_chopshop:server:getSellableParts', function()
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end

    local parts = {}
    for _, part in ipairs(Config.VehicleParts) do
        if part.reward.keep_part then
            local count = Inventory.GetItemCount(src, part.item)
            if count and count > 0 then
                table.insert(parts, {
                    name = part.name,
                    label = part.label,
                    count = count,
                    price = {
                        min = part.reward.sell_price.min,
                        max = part.reward.sell_price.max
                    }
                })
            end
        end
    end

    TriggerClientEvent('meta_chopshop:client:receiveSellableParts', src, parts)
end)

-- Alert police
RegisterNetEvent('meta_chopshop:server:alertPolice', function(location)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    -- Get all players
    local players = {}
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        players = QBCore.Functions.GetPlayers()
    else
        players = ESX.GetPlayers()
    end
    
    -- Alert all police officers
    for _, playerId in ipairs(players) do
        local targetPlayer = GetPlayer(playerId)
        if targetPlayer then
            if Config.Framework == 'qb' or Config.Framework == 'qbx' then
                if targetPlayer.PlayerData.job.name == "police" then
                    TriggerClientEvent('meta_chopshop:client:policeAlert', playerId, location)
                end
            else
                if targetPlayer.job.name == "police" then
                    TriggerClientEvent('meta_chopshop:client:policeAlert', playerId, location)
                end
            end
        end
    end
end)

-- Add wanted level
RegisterNetEvent('meta_chopshop:server:addWanted', function()
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    if Config.Police.wanted.enabled then
        if Config.Framework == 'qb' or Config.Framework == 'qbx' then
            TriggerClientEvent('police:client:SetCopBlip', src)
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Police',
                description = 'You have been spotted by the police!',
                type = 'error'
            })
        else
            -- ESX wanted level logic here
        end
    end
end)

-- Check police count
RegisterNetEvent('meta_chopshop:server:checkPolice', function()
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    local count = GetPoliceCount()
    local hasEnoughPolice = count >= Config.Police.required
    
    TriggerClientEvent('meta_chopshop:client:policeCountResult', src, hasEnoughPolice)
end)

-- Get player XP data
RegisterNetEvent('meta_chopshop:server:getXPData', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Get player's chop shop XP from metadata
    local xpData = Player.PlayerData.metadata.chopshop_xp or {
        level = 1,
        currentXP = 0,
        nextLevelXP = 100
    }
    
    -- Calculate next level XP requirement
    xpData.nextLevelXP = xpData.level * 100
    
    TriggerClientEvent('meta_chopshop:client:receiveXPData', src, xpData)
end)

-- Give XP reward for delivering part
RegisterNetEvent('meta_chopshop:server:giveXP', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Get current XP data
    local xpData = Player.PlayerData.metadata.chopshop_xp or {
        level = 1,
        currentXP = 0,
        nextLevelXP = 100
    }
    
    -- Add XP
    xpData.currentXP = xpData.currentXP + amount
    
    -- Check for level up
    while xpData.currentXP >= xpData.nextLevelXP do
        xpData.level = xpData.level + 1
        xpData.currentXP = xpData.currentXP - xpData.nextLevelXP
        xpData.nextLevelXP = xpData.level * 100
        
        -- Notify player of level up
        TriggerClientEvent('meta_chopshop:notify', src, 'Level Up! You are now level ' .. xpData.level)
    end
    
    -- Save XP data
    Player.Functions.SetMetaData('chopshop_xp', xpData)
    
    -- Send updated XP data to client
    TriggerClientEvent('meta_chopshop:client:receiveXPData', src, xpData)
end)

-- Remove vehicle from garage
RegisterNetEvent('meta_chopshop:server:removeFromGarage', function(vehicleData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Get vehicle data
    local plate = vehicleData.plate
    local model = vehicleData.model
    
    print("^2[DEBUG] Attempting to remove vehicle from garage^7")
    print("^2[DEBUG] Plate: " .. plate .. "^7")
    print("^2[DEBUG] CitizenID: " .. Player.PlayerData.citizenid .. "^7")
    
    -- Remove from garage based on framework
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        -- Remove from QB-Core garage
        exports.oxmysql:execute('DELETE FROM player_vehicles WHERE plate = ? AND citizenid = ?', {
            plate,
            Player.PlayerData.citizenid
        }, function(result)
            print("^2[DEBUG] Query result: " .. json.encode(result) .. "^7")
            if result and result.affectedRows > 0 then
                -- Also remove from QB-Core's vehicle cache
                TriggerEvent('qb-vehiclekeys:server:RemoveVehicleKey', plate)
                TriggerClientEvent('QBCore:Notify', src, 'Vehicle removed from garage', 'success')
            else
                -- Try alternative query if first one fails
                exports.oxmysql:execute('DELETE FROM player_vehicles WHERE plate = ?', {
                    plate
                }, function(result2)
                    if result2 and result2.affectedRows > 0 then
                        TriggerEvent('qb-vehiclekeys:server:RemoveVehicleKey', plate)
                        TriggerClientEvent('QBCore:Notify', src, 'Vehicle removed from garage', 'success')
                    else
                        TriggerClientEvent('QBCore:Notify', src, 'Failed to remove vehicle from garage', 'error')
                    end
                end)
            end
        end)
    elseif Config.Framework == 'esx' then
        -- Remove from ESX garage
        exports.oxmysql:execute('DELETE FROM owned_vehicles WHERE plate = ? AND owner = ?', {
            plate,
            Player.identifier
        }, function(result)
            if result and result.affectedRows > 0 then
                TriggerClientEvent('esx:showNotification', src, 'Vehicle removed from garage')
            else
                -- Try alternative query if first one fails
                exports.oxmysql:execute('DELETE FROM owned_vehicles WHERE plate = ?', {
                    plate
                }, function(result2)
                    if result2 and result2.affectedRows > 0 then
                        TriggerClientEvent('esx:showNotification', src, 'Vehicle removed from garage')
                    else
                        TriggerClientEvent('esx:showNotification', src, 'Failed to remove vehicle from garage')
                    end
                end)
            end
        end)
    end
end)

-- Add at the top with other local variables
local playerHistory = {}

-- Add after other RegisterNetEvent handlers
RegisterNetEvent('meta_chopshop:server:updateHistory', function(historyEntry)
    local src = source
    local Player = GetPlayerFromId(src)
    if not Player then return end
    
    local identifier = GetPlayerIdentifier(src)
    if not identifier then return end
    
    -- Initialize player history if not exists
    if not playerHistory[identifier] then
        playerHistory[identifier] = {}
    end
    
    -- Add new entry
    table.insert(playerHistory[identifier], 1, historyEntry)
    
    -- Keep only the maximum number of entries
    if #playerHistory[identifier] > Config.History.maxEntries then
        table.remove(playerHistory[identifier], Config.History.maxEntries + 1)
    end
    
    -- Save to database if enabled
    if Config.History.saveToDatabase then
        -- Add your database saving logic here
        -- Example: MySQL.Async.execute('INSERT INTO chop_history (identifier, vehicle_name, plate, date, parts, earnings) VALUES (?, ?, ?, ?, ?, ?)',
        --     {identifier, historyEntry.vehicleName, historyEntry.plate, historyEntry.date, json.encode(historyEntry.parts), historyEntry.earnings})
    end
end)

RegisterNetEvent('meta_chopshop:server:requestHistory', function()
    local src = source
    local Player = GetPlayerFromId(src)
    if not Player then return end
    
    local identifier = GetPlayerIdentifier(src)
    if not identifier then return end
    
    -- Initialize player history if not exists
    if not playerHistory[identifier] then
        playerHistory[identifier] = {}
        
        -- Load from database if enabled
        if Config.History.saveToDatabase then
            -- Add your database loading logic here
            -- Example: MySQL.Async.fetchAll('SELECT * FROM chop_history WHERE identifier = ? ORDER BY date DESC LIMIT ?',
            --     {identifier, Config.History.maxEntries},
            --     function(result)
            --         if result then
            --             for _, row in ipairs(result) do
            --                 table.insert(playerHistory[identifier], {
            --                     vehicleName = row.vehicle_name,
            --                     plate = row.plate,
            --                     date = row.date,
            --                     parts = json.decode(row.parts),
            --                     earnings = row.earnings
            --                 })
            --             end
            --         end
            --     end)
        end
    end
    
    -- Send history to client
    TriggerClientEvent('meta_chopshop:client:updateHistory', src, playerHistory[identifier])
end)

-- Add to the existing player dropped event
AddEventHandler('playerDropped', function()
    local src = source
    local identifier = GetPlayerIdentifier(src)
    if identifier and playerHistory[identifier] then
        -- Save to database if enabled
        if Config.History.saveToDatabase then
            -- Add your database saving logic here
            -- Example: MySQL.Async.execute('DELETE FROM chop_history WHERE identifier = ?', {identifier})
            -- for _, entry in ipairs(playerHistory[identifier]) do
            --     MySQL.Async.execute('INSERT INTO chop_history (identifier, vehicle_name, plate, date, parts, earnings) VALUES (?, ?, ?, ?, ?, ?)',
            --         {identifier, entry.vehicleName, entry.plate, entry.date, json.encode(entry.parts), entry.earnings})
            -- end
        end
        
        -- Clear from memory
        playerHistory[identifier] = nil
    end
end)

-- Material Exchange
RegisterNetEvent('meta_chopshop:server:swapForMaterial', function(materialName, amount)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end

    -- Find the material configuration
    local materialConfig = nil
    for _, material in ipairs(Config.MaterialExchange.materials) do
        if material.name == materialName then
            materialConfig = material
            break
        end
    end

    if not materialConfig then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Part Buyer',
            description = 'Invalid material selected',
            type = 'error'
        })
        return
    end

    -- Calculate required parts
    local requiredParts = amount * materialConfig.ratio
    local totalParts = 0

    -- Count available parts
    for _, part in ipairs(Config.VehicleParts) do
        if part.reward.keep_part then
            local count = Inventory.GetItemCount(src, part.item)
            if count and count > 0 then
                totalParts = totalParts + count
            end
        end
    end

    -- Check if player has enough parts
    if totalParts < requiredParts then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Part Buyer',
            description = Config.MaterialExchange.notifications.no_parts,
            type = 'error'
        })
        return
    end

    -- Remove parts and add material
    local partsRemoved = 0
    for _, part in ipairs(Config.VehicleParts) do
        if part.reward.keep_part then
            local count = Inventory.GetItemCount(src, part.item)
            if count and count > 0 then
                local toRemove = math.min(count, requiredParts - partsRemoved)
                if toRemove > 0 then
                    if Inventory.RemoveItem(src, part.item, toRemove) then
                        partsRemoved = partsRemoved + toRemove
                    end
                end
            end
            if partsRemoved >= requiredParts then
                break
            end
        end
    end

    -- Check if all parts were removed successfully
    if partsRemoved < requiredParts then
        -- Refund any parts that were removed
        for _, part in ipairs(Config.VehicleParts) do
            if part.reward.keep_part then
                local count = Inventory.GetItemCount(src, part.item)
                if count and count > 0 then
                    Inventory.AddItem(src, part.item, count)
                end
            end
        end
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Part Buyer',
            description = Config.MaterialExchange.notifications.failed,
            type = 'error'
        })
        return
    end

    -- Add the material
    if Inventory.AddItem(src, materialName, amount) then
        -- Calculate and add money
        local price = math.random(materialConfig.price.min, materialConfig.price.max) * amount
        AddMoney(src, price)

        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Part Buyer',
            description = string.format(Config.MaterialExchange.notifications.success, requiredParts, amount, materialConfig.label),
            type = 'success'
        })

        -- Refresh the sellable parts menu
        TriggerEvent('meta_chopshop:server:getSellableParts', src)
    else
        -- Refund parts if inventory is full
        for _, part in ipairs(Config.VehicleParts) do
            if part.reward.keep_part then
                local count = Inventory.GetItemCount(src, part.item)
                if count and count > 0 then
                    Inventory.AddItem(src, part.item, count)
                end
            end
        end
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Part Buyer',
            description = 'Your inventory is full!',
            type = 'error'
        })
    end
end) 