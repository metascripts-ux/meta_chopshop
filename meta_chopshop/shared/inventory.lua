local Inventory = {}

-- Get the current inventory system
local function GetInventorySystem()
    if GetResourceState('ox_inventory') == 'started' then
        return 'ox'
    elseif GetResourceState('qb-inventory') == 'started' then
        return 'qb'
    elseif GetResourceState('qs-inventory') == 'started' then
        return 'qs'
    else
        return 'qb' -- Default to qb-inventory
    end
end

-- Check if an item exists
function Inventory.HasItem(source, item)
    local system = GetInventorySystem()
    
    if system == 'ox' then
        return exports.ox_inventory:GetItemCount(source, item) > 0
    elseif system == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        local hasItem = Player.Functions.GetItemByName(item)
        return hasItem and hasItem.amount > 0
    elseif system == 'qs' then
        return exports['qs-inventory']:GetItemCount(source, item) > 0
    end
    return false
end

-- Add an item to inventory
function Inventory.AddItem(source, item, amount)
    local system = GetInventorySystem()
    
    if system == 'ox' then
        return exports.ox_inventory:AddItem(source, item, amount)
    elseif system == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        return Player.Functions.AddItem(item, amount)
    elseif system == 'qs' then
        return exports['qs-inventory']:AddItem(source, item, amount)
    end
    return false
end

-- Remove an item from inventory
function Inventory.RemoveItem(source, item, amount)
    local system = GetInventorySystem()
    
    if system == 'ox' then
        return exports.ox_inventory:RemoveItem(source, item, amount)
    elseif system == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        return Player.Functions.RemoveItem(item, amount)
    elseif system == 'qs' then
        return exports['qs-inventory']:RemoveItem(source, item, amount)
    end
    return false
end

-- Get item count
function Inventory.GetItemCount(source, item)
    local system = GetInventorySystem()
    
    if system == 'ox' then
        return exports.ox_inventory:GetItemCount(source, item)
    elseif system == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return 0 end
        local hasItem = Player.Functions.GetItemByName(item)
        return hasItem and hasItem.amount or 0
    elseif system == 'qs' then
        return exports['qs-inventory']:GetItemCount(source, item)
    end
    return 0
end

-- Check if item exists in shared items
function Inventory.ItemExists(item)
    local system = GetInventorySystem()
    
    if system == 'ox' then
        return exports.ox_inventory:Items(item) ~= nil
    elseif system == 'qb' then
        return QBCore.Shared.Items[item] ~= nil
    elseif system == 'qs' then
        return exports['qs-inventory']:GetItemData(item) ~= nil
    end
    return false
end

-- Get item data
function Inventory.GetItemData(item)
    local system = GetInventorySystem()
    
    if system == 'ox' then
        return exports.ox_inventory:Items(item)
    elseif system == 'qb' then
        return QBCore.Shared.Items[item]
    elseif system == 'qs' then
        return exports['qs-inventory']:GetItemData(item)
    end
    return nil
end

return Inventory 