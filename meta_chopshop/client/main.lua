-- Meta Chop Shop by namicKIDDO
print('^2[Meta Scripts] ^7Meta Chop Shop by ^1namicKIDDO^7')
print('^2[Meta Scripts] ^7Version: ^1v1.0.0^7')
print('^2[Meta Scripts] ^7Discord: ^1discord.gg/gyHsE3ZvQs^7')
print('^2[Meta Scripts] ^7Report any bugs to our Discord for fixes^7')

local QBCore = exports['qb-core']:GetCoreObject()
local ESX = nil
local PlayerData = {}
local isChopping = false
local lastAlert = 0
local currentPartName = nil
local chopMode = false
local choppedParts = {}
local currentChopLocation = nil
local currentVehicle = nil
local chopHistory = {}
local chopShopPed = nil
local partBuyerPed = nil

-- Framework Initialization
if Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

-- Initialize Player Data
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    -- Request history data from server
    TriggerServerEvent('meta_chopshop:server:requestHistory')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

-- Create Blips
CreateThread(function()
    if not Config.Blips.enabled then return end

    -- Create chop shop blip
    if Config.Blips.chopShop.enabled then
        local chopShopBlip = AddBlipForCoord(Config.Blips.chopShop.coords.x, Config.Blips.chopShop.coords.y, Config.Blips.chopShop.coords.z)
        SetBlipSprite(chopShopBlip, Config.Blips.chopShop.sprite)
        SetBlipDisplay(chopShopBlip, 4)
        SetBlipScale(chopShopBlip, Config.Blips.chopShop.scale)
        SetBlipColour(chopShopBlip, Config.Blips.chopShop.color)
        SetBlipAsShortRange(chopShopBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blips.chopShop.label)
        EndTextCommandSetBlipName(chopShopBlip)
    end

    -- Create part buyer blips
    if Config.Blips.partBuyer.enabled then
        for _, location in ipairs(Config.Blips.partBuyer.locations) do
            local partBuyerBlip = AddBlipForCoord(location.x, location.y, location.z)
            SetBlipSprite(partBuyerBlip, Config.Blips.partBuyer.sprite)
            SetBlipDisplay(partBuyerBlip, 4)
            SetBlipScale(partBuyerBlip, Config.Blips.partBuyer.scale)
            SetBlipColour(partBuyerBlip, Config.Blips.partBuyer.color)
            SetBlipAsShortRange(partBuyerBlip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(Config.Blips.partBuyer.label)
            EndTextCommandSetBlipName(partBuyerBlip)
        end
    end
end)

-- Create PEDs
CreateThread(function()
    -- Create chop shop ped
    local chopShopModel = GetHashKey(Config.ChopShopPed.model)
    RequestModel(chopShopModel)
    while not HasModelLoaded(chopShopModel) do
        Wait(0)
    end
    
    chopShopPed = CreatePed(4, chopShopModel, Config.ChopShopPed.coords.x, Config.ChopShopPed.coords.y, Config.ChopShopPed.coords.z - 1.0, Config.ChopShopPed.coords.w, false, true)
    SetEntityHeading(chopShopPed, Config.ChopShopPed.coords.w)
    FreezeEntityPosition(chopShopPed, true)
    SetEntityInvincible(chopShopPed, true)
    SetBlockingOfNonTemporaryEvents(chopShopPed, true)
    TaskStartScenarioInPlace(chopShopPed, Config.ChopShopPed.scenario, 0, true)
    
    -- Add targeting option for chop shop ped
    if Config.TargetSystem == 'qb-target' then
        exports['qb-target']:AddTargetEntity(chopShopPed, {
            options = Config.ChopShopPed.options,
            distance = 2.0
        })
    elseif Config.TargetSystem == 'ox_target' then
        exports.ox_target:addLocalEntity(chopShopPed, Config.ChopShopPed.options)
    end

    -- Create part buyer peds at all locations
    local partBuyerModel = GetHashKey(Config.PartBuyerPed.model)
    RequestModel(partBuyerModel)
    while not HasModelLoaded(partBuyerModel) do
        Wait(0)
    end

    for _, location in ipairs(Config.Blips.partBuyer.locations) do
        local ped = CreatePed(4, partBuyerModel, location.x, location.y, location.z - 1.0, location.w, false, true)
        SetEntityHeading(ped, location.w)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        TaskStartScenarioInPlace(ped, Config.PartBuyerPed.scenario, 0, true)
        
        -- Add targeting option for part buyer ped
        if Config.TargetSystem == 'qb-target' then
            exports['qb-target']:AddTargetEntity(ped, {
                options = Config.PartBuyerPed.options,
                distance = 2.0
            })
        elseif Config.TargetSystem == 'ox_target' then
            exports.ox_target:addLocalEntity(ped, Config.PartBuyerPed.options)
        end
    end
end)

-- Check if player is in chop shop area
function IsInChopShopArea()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, location in pairs(Config.ChopShops) do
        local distance = #(playerCoords - location.coords)
        if distance <= location.radius then
            return true, location
        end
    end
    return false, nil
end

-- Check if vehicle is blacklisted
function IsVehicleBlacklisted(vehicle)
    local model = GetEntityModel(vehicle)
    local modelName = GetDisplayNameFromVehicleModel(model):lower()
    
    for _, blacklistedVehicle in pairs(Config.BlacklistedVehicles) do
        if modelName == blacklistedVehicle then
            return true
        end
    end
    return false
end

-- Play animation
function PlayChopAnimation(animDict, animName)
    if not Config.UseAnimations then return end
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end
    
    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
end

-- Get nearest vehicle
function GetNearestVehicle()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = 3.0
    local closestVehicle = nil
    
    for _, vehicle in ipairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(playerCoords - vehicleCoords)
        
        if distance < closestDistance then
            closestDistance = distance
            closestVehicle = vehicle
        end
    end
    
    return closestVehicle
end

-- Check if player is in vehicle
function IsPlayerInVehicle()
    local playerPed = PlayerPedId()
    return IsPedInAnyVehicle(playerPed, false)
end

-- Reset chopped parts when entering a new vehicle
function ResetChoppedParts()
    CleanupPhysicalParts()
    choppedParts = {}
end

-- Function to play part removal effects
function PlayPartRemovalEffects(coords)
    -- Play metal breaking sound
    PlaySoundFrontend(-1, "Metal_Snapping", "GTAO_FM_Events_Soundset", true)
end

-- Function to get appropriate debris prop for part
function GetDebrisPropForPart(part)
    local props = {
        door_ds = "prop_car_door_01",
        door_ps = "prop_car_door_01",
        door_lr = "prop_car_door_02",
        door_rr = "prop_car_door_02",
        hood = "prop_car_bonnet_01",
        trunk = "prop_car_bonnet_02",
        wheel_lf = "prop_wheel_roller_car",
        wheel_rf = "prop_wheel_roller_car",
        wheel_lr = "prop_wheel_roller_car",
        wheel_rr = "prop_wheel_roller_car"
    }
    
    -- Special handling for wheels to use different props
    if part.name:find("wheel") then
        local wheelProps = {
            "prop_wheel_roller_car",
            "prop_wheel_roller_car_2",
            "prop_wheel_roller_car_3",
            "prop_wheel_roller_car_4",
            "prop_wheel_roller_car_5"
        }
        return GetHashKey(wheelProps[math.random(1, #wheelProps)])
    end
    
    -- Special handling for trunk to use different props
    if part.name == "trunk" then
        local trunkProps = {
            "prop_car_bonnet_02",
            "prop_car_boot_01",
            "prop_car_boot_02",
            "prop_car_boot_03"
        }
        return GetHashKey(trunkProps[math.random(1, #trunkProps)])
    end
    
    return GetHashKey(props[part.name] or "prop_rub_carwreck_3")
end

-- Function to play part pickup animation
function PlayPartPickupAnimation()
    local playerPed = PlayerPedId()
    local animDict = "anim@heists@box_carry@"
    local animName = "idle"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
    Wait(1000)
end

-- Function to play part drop animation
function PlayPartDropAnimation()
    local playerPed = PlayerPedId()
    local animDict = "anim@heists@box_carry@"
    local animName = "exit"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 0, 0, false, false, false)
    Wait(1000)
end

-- Function to create physical part
function CreatePhysicalPart(part, coords)
    local model = GetDebrisPropForPart(part)
    local object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
    
    -- Set object properties
    SetEntityCollision(object, true, true)
    SetEntityDynamic(object, true)
    SetEntityHasGravity(object, true)
    
    -- Add to chopped parts collection
    if not choppedParts.objects then
        choppedParts.objects = {}
    end
    table.insert(choppedParts.objects, object)
    
    return object
end

-- Function to check if player is near drop location
function IsNearDropLocation()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, location in pairs(Config.DropLocations) do
        local distance = #(playerCoords - location.coords)
        if distance <= location.radius then
            return true, location
        end
    end
    return false, nil
end

-- Function to attach part to player's hands
function AttachPartToHands(object)
    local playerPed = PlayerPedId()
    
    -- Get hand positions
    local rightHand = GetPedBoneIndex(playerPed, 57005) -- Right hand
    local leftHand = GetPedBoneIndex(playerPed, 18905) -- Left hand
    
    -- Calculate attachment points based on part type
    local offset = vector3(0.0, 0.0, 0.0)
    local rotation = vector3(0.0, 0.0, 0.0)
    
    -- Adjust offsets based on part type
    if currentPartName:find("door") then
        offset = vector3(0.0, 0.0, 0.0)
        rotation = vector3(0.0, 0.0, 0.0)
    elseif currentPartName:find("wheel") then
        offset = vector3(0.0, 0.0, 0.0)
        rotation = vector3(0.0, 0.0, 0.0)
    elseif currentPartName == "hood" or currentPartName == "trunk" then
        offset = vector3(0.0, 0.0, 0.0)
        rotation = vector3(0.0, 0.0, 0.0)
    end
    
    -- Attach to right hand
    AttachEntityToEntity(object, playerPed, rightHand,
        offset.x, offset.y, offset.z,
        rotation.x, rotation.y, rotation.z,
        true, true, false, true, 1, true)
end

-- Function to check if all parts are chopped
function AreAllPartsChopped()
    for _, part in pairs(Config.VehicleParts) do
        if not choppedParts[part.name] then
            return false
        end
    end
    return true
end

-- Function to remove vehicle part with enhanced effects
function RemoveVehiclePart(vehicle, part)
    if not DoesEntityExist(vehicle) then return end
    
    -- Get the bone index
    local boneIndex = GetEntityBoneIndexByName(vehicle, part.bones.primary)
    if boneIndex == -1 then
        -- Try secondary bones if primary not found
        for _, secondaryBone in ipairs(part.bones.secondary) do
            boneIndex = GetEntityBoneIndexByName(vehicle, secondaryBone)
            if boneIndex ~= -1 then break end
        end
    end
    
    if boneIndex ~= -1 then
        -- Get part position and rotation
        local partCoords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
        local partRotation = GetEntityBoneRotation(vehicle, boneIndex)
        
        -- Play removal effects
        PlayPartRemovalEffects(partCoords)
        
        -- Create the physical part first
        local partObject = CreatePhysicalPart(part, partCoords)
        
        -- Set the part's rotation to match the vehicle's bone
        SetEntityRotation(partObject, partRotation.x, partRotation.y, partRotation.z, 2, true)
        
        -- Special handling for wheels
        if part.name:find("wheel") then
            -- Remove the wheel from the vehicle
            local wheelIndex = 0
            if part.name == "wheel_lf" then wheelIndex = 0
            elseif part.name == "wheel_rf" then wheelIndex = 1
            elseif part.name == "wheel_lr" then wheelIndex = 2
            elseif part.name == "wheel_rr" then wheelIndex = 3 end
            
            -- Set wheel as broken and remove it
            SetVehicleWheelHealth(vehicle, wheelIndex, 0.0)
            SetVehicleWheelTireColliderWidth(vehicle, wheelIndex, 0.0)
            SetVehicleWheelTireColliderSize(vehicle, wheelIndex, 0.0)
        end
        
        -- Detach the part from the vehicle
        DetachEntity(vehicle, boneIndex, true)
        
        -- Hide the part on the vehicle
        if part.name:find("door") then
            SetVehicleDoorBroken(vehicle, GetDoorIndex(part.name), true)
        elseif part.name == "hood" then
            SetVehicleDoorBroken(vehicle, 4, true) -- Hood
        elseif part.name == "trunk" then
            SetVehicleDoorBroken(vehicle, 5, true) -- Trunk
        end
        
        -- Wait a moment to ensure proper detachment
        Wait(100)
        
        -- Play pickup animation
        PlayPartPickupAnimation()
        
        -- Attach part to player's hands
        AttachPartToHands(partObject)
        
        -- Start a thread to check for drop location
        CreateThread(function()
            local isHolding = true
            while isHolding do
                Wait(0)
                -- Check if player is near drop location
                local nearDrop, dropLocation = IsNearDropLocation()
                if nearDrop then
                    -- Show drop prompt
                    DrawText3D(dropLocation.coords.x, dropLocation.coords.y, dropLocation.coords.z, "Press [E] to drop part")
                    
                    -- Check for drop input
                    if IsControlJustPressed(0, 38) then -- E key
                        isHolding = false
                        
                        -- Play drop animation
                        PlayPartDropAnimation()
                        
                        -- Detach from player
                        if choppedParts.objects then
                            for _, object in ipairs(choppedParts.objects) do
                                if DoesEntityExist(object) then
                                    DetachEntity(object, true, true)
                                    
                                    -- Apply physics to the dropped part
                                    local randomRotation = vector3(
                                        math.random(-10, 10),
                                        math.random(-10, 10),
                                        math.random(-10, 10)
                                    )
                                    local randomVelocity = vector3(
                                        math.random(-1, 1),
                                        math.random(-1, 1),
                                        math.random(-2, -1)
                                    )
                                    
                                    SetEntityRotation(object, 
                                        randomRotation.x,
                                        randomRotation.y,
                                        randomRotation.z,
                                        2, true)
                                    SetEntityVelocity(object, 
                                        randomVelocity.x,
                                        randomVelocity.y,
                                        randomVelocity.z)
                                end
                            end
                        end
                        
                        -- Give XP reward
                        TriggerServerEvent('meta_chopshop:server:giveXP', dropLocation.xp)
                        
                        -- Show success notification
                        TriggerEvent('meta_chopshop:notify', 'Part delivered! +' .. dropLocation.xp .. ' XP')
                        
                        -- Delete the parts after a delay
                        SetTimeout(2000, function()
                            if choppedParts.objects then
                                for _, object in ipairs(choppedParts.objects) do
                                    if DoesEntityExist(object) then
                                        -- Fade out the part
                                        SetEntityAlpha(object, 0, false)
                                        -- Delete after fade
                                        SetTimeout(500, function()
                                            if DoesEntityExist(object) then
                                                DeleteEntity(object)
                                            end
                                        end)
                                    end
                                end
                            end
                        end)
                        
                        -- Clear any active menus
                        if Config.MenuType == 'qb-menu' then
                            if Config.Framework == 'qb' or Config.Framework == 'qbx' then
                                exports['qb-menu']:closeMenu()
                            end
                        else -- ox_lib
                            lib.hideContext()
                        end
                    end
                end
            end
        end)
    end
end

-- Function to get door index from part name
function GetDoorIndex(partName)
    if partName == "door_ds" then return 0
    elseif partName == "door_ps" then return 1
    elseif partName == "door_lr" then return 2
    elseif partName == "door_rr" then return 3
    end
    return 0
end

-- Function to get entity bone rotation
function GetEntityBoneRotation(entity, boneIndex)
    local rotation = GetEntityBonePosition_2(entity, boneIndex)
    if rotation then
        return vector3(rotation.x, rotation.y, rotation.z)
    end
    return vector3(0.0, 0.0, 0.0)
end

-- Function to draw 3D text
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

-- Function to clean up physical parts
function CleanupPhysicalParts()
    if choppedParts.objects then
        for _, object in ipairs(choppedParts.objects) do
            if DoesEntityExist(object) then
                DeleteEntity(object)
            end
        end
        choppedParts.objects = {}
    end
end

-- Chop vehicle part
function ChopVehiclePart(part)
    if not chopMode then
        TriggerEvent('meta_chopshop:notify', 'Chop mode is disabled')
        return
    end
    
    if isChopping then return end
    isChopping = true
    
    -- Check if player is in vehicle
    if IsPlayerInVehicle() then
        TriggerEvent('meta_chopshop:notify', Config.Notifications.in_vehicle)
        isChopping = false
        return
    end
    
    local vehicle = GetNearestVehicle()
    if not vehicle or not IsEntityAVehicle(vehicle) then
        TriggerEvent('meta_chopshop:notify', Config.Notifications.failed)
        isChopping = false
        return
    end
    
    if IsVehicleBlacklisted(vehicle) then
        TriggerEvent('meta_chopshop:notify', Config.Notifications.blacklisted)
        isChopping = false
        return
    end
    
    local inArea, currentLocation = IsInChopShopArea()
    if not inArea then
        TriggerEvent('meta_chopshop:notify', Config.Notifications.too_far)
        isChopping = false
        return
    end
    
    -- Check if part is already chopped
    if choppedParts[part.name] then
        TriggerEvent('meta_chopshop:notify', 'This part has already been chopped')
        isChopping = false
        return
    end
    
    -- Check police count through server
    TriggerServerEvent('meta_chopshop:server:checkPolice')
    currentPartName = part.name
    currentChopLocation = currentLocation -- Store the current location
end

-- Handle police count result
RegisterNetEvent('meta_chopshop:client:policeCountResult', function(hasEnoughPolice)
    if not hasEnoughPolice then
        TriggerEvent('meta_chopshop:notify', Config.Notifications.no_police)
        isChopping = false
        return
    end
    
    -- Get the current part being chopped
    local currentPart = nil
    for _, part in pairs(Config.VehicleParts) do
        if part.name == currentPartName then
            currentPart = part
            break
        end
    end
    
    if not currentPart then
        isChopping = false
        return
    end
    
    local vehicle = GetNearestVehicle()
    if not vehicle then
        isChopping = false
        return
    end
    
    -- Play animation
    PlayChopAnimation(currentPart.animation.dict, currentPart.animation.anim)
    
    -- Progress bar
    if Config.UseProgressBar then
        if Config.Framework == 'qb' or Config.Framework == 'qbx' then
            QBCore.Functions.Progressbar("chop_vehicle", "Chopping " .. currentPart.label, currentPart.time, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function() -- Done
                -- Remove the part visually
                RemoveVehiclePart(vehicle, currentPart)
                
                -- Process the reward
                TriggerServerEvent('meta_chopshop:server:reward', currentPart)
                ClearPedTasks(PlayerPedId())
                isChopping = false
                
                -- Mark part as chopped
                choppedParts[currentPart.name] = true
                
                -- Chance to alert police
                if Config.Police.alert.enabled and math.random(100) <= Config.Police.alert.chance then
                    local currentTime = GetGameTimer()
                    if currentTime - lastAlert > (Config.Police.alert.cooldown * 1000) then
                        lastAlert = currentTime
                        if currentChopLocation then
                            TriggerServerEvent('meta_chopshop:server:alertPolice', currentChopLocation.name)
                        end
                    end
                end
            end, function() -- Cancel
                ClearPedTasks(PlayerPedId())
                isChopping = false
            end)
        else
            -- ESX progress bar logic here
        end
    else
        Wait(currentPart.time)
        -- Remove the part visually
        RemoveVehiclePart(vehicle, currentPart)
        
        -- Process the reward
        TriggerServerEvent('meta_chopshop:server:reward', currentPart)
        ClearPedTasks(PlayerPedId())
        isChopping = false
        
        -- Mark part as chopped
        choppedParts[currentPart.name] = true
        
        -- Chance to alert police
        if Config.Police.alert.enabled and math.random(100) <= Config.Police.alert.chance then
            local currentTime = GetGameTimer()
            if currentTime - lastAlert > (Config.Police.alert.cooldown * 1000) then
                lastAlert = currentTime
                if currentChopLocation then
                    TriggerServerEvent('meta_chopshop:server:alertPolice', currentChopLocation.name)
                end
            end
        end
    end
end)

-- Function to get vehicle part position using bone configuration
function GetPartPosition(vehicle, part)
    if not DoesEntityExist(vehicle) then return nil end
    
    local vehicleCoords = GetEntityCoords(vehicle)
    local vehicleHeading = GetEntityHeading(vehicle)
    
    -- Get bone position
    local boneIndex = GetEntityBoneIndexByName(vehicle, part.bones.primary)
    if boneIndex == -1 then
        -- Try secondary bones if primary not found
        for _, secondaryBone in ipairs(part.bones.secondary) do
            boneIndex = GetEntityBoneIndexByName(vehicle, secondaryBone)
            if boneIndex ~= -1 then break end
        end
    end
    
    if boneIndex == -1 then
        -- Fallback to offset-based positioning if no bones found
        local offset = part.bones.offset
        local rad = math.rad(vehicleHeading)
        local cos = math.cos(rad)
        local sin = math.sin(rad)
        local rotatedX = offset.x * cos - offset.y * sin
        local rotatedY = offset.x * sin + offset.y * cos
        
        return vector3(
            vehicleCoords.x + rotatedX,
            vehicleCoords.y + rotatedY,
            vehicleCoords.z + offset.z
        )
    end
    
    -- Get bone position and apply offset
    local boneCoords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
    local offset = part.bones.offset
    local rotation = part.bones.rotation
    
    -- Apply rotation based on vehicle heading
    local rad = math.rad(vehicleHeading)
    local cos = math.cos(rad)
    local sin = math.sin(rad)
    local rotatedX = offset.x * cos - offset.y * sin
    local rotatedY = offset.x * sin + offset.y * cos
    
    return vector3(
        boneCoords.x + rotatedX,
        boneCoords.y + rotatedY,
        boneCoords.z + offset.z
    )
end

-- Function to check if bone exists on vehicle
function DoesBoneExist(vehicle, boneName)
    local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
    return boneIndex ~= -1
end

-- Function to get all valid bones for a part
function GetValidBones(vehicle, part)
    local validBones = {}
    
    -- Check primary bone
    if DoesBoneExist(vehicle, part.bones.primary) then
        table.insert(validBones, part.bones.primary)
    end
    
    -- Check secondary bones
    for _, secondaryBone in ipairs(part.bones.secondary) do
        if DoesBoneExist(vehicle, secondaryBone) then
            table.insert(validBones, secondaryBone)
        end
    end
    
    return validBones
end

-- Function to check if player is near part with improved accuracy
function IsNearPart(partPosition, maxDistance)
    if not partPosition then return false end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - partPosition)
    
    -- Draw debug marker if debug mode is enabled
    if Config.Debug then
        DrawMarker(1, partPosition.x, partPosition.y, partPosition.z, 
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
            0.3, 0.3, 0.3, 255, 0, 0, 100, 
            false, true, 2, false, nil, nil, false)
    end
    
    return distance <= maxDistance
end

-- Target setup for vehicle parts with enhanced bone targeting
CreateThread(function()
    while true do
        Wait(500)
        if chopMode then
            local vehicle = GetNearestVehicle()
            if vehicle and DoesEntityExist(vehicle) and not IsVehicleBlacklisted(vehicle) then
                -- Reset chopped parts when entering a new vehicle
                if not choppedParts.vehicle or choppedParts.vehicle ~= vehicle then
                    ResetChoppedParts()
                    choppedParts.vehicle = vehicle
                end

                -- Remove all existing targets first
                if Config.TargetSystem == 'qb-target' then
                    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
                        for _, part in pairs(Config.VehicleParts) do
                            exports['qb-target']:RemoveTargetBone(part.bones.primary)
                            for _, secondaryBone in ipairs(part.bones.secondary) do
                                exports['qb-target']:RemoveTargetBone(secondaryBone)
                            end
                        end
                    end
                else -- ox_target
                    exports.ox_target:removeLocalEntity(vehicle)
                end

                -- Add vehicle status target
                if Config.TargetSystem == 'qb-target' then
                    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
                        exports['qb-target']:AddTargetEntity(vehicle, {
                            options = {
                                {
                                    type = "client",
                                    event = "meta_chopshop:client:showPartsStatus",
                                    icon = "fas fa-list",
                                    label = "View Parts Status"
                                }
                            },
                            distance = 2.5
                        })
                    end
                else -- ox_target
                    local options = {
                        {
                            name = 'parts_status',
                            icon = 'fas fa-list',
                            label = 'View Parts Status',
                            onSelect = function()
                                currentVehicle = vehicle
                                ShowPartsStatusMenu()
                            end
                        }
                    }
                    
                    exports.ox_target:addLocalEntity(vehicle, options)
                end

                -- Check each part
                for _, part in pairs(Config.VehicleParts) do
                    if not choppedParts[part.name] then
                        local validBones = GetValidBones(vehicle, part)
                        if #validBones > 0 then
                            local partPosition = GetPartPosition(vehicle, part)
                            if partPosition and IsNearPart(partPosition, 1.5) then
                                if Config.TargetSystem == 'qb-target' then
                                    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
                                        -- Add target to all valid bones
                                        for _, bone in ipairs(validBones) do
                                            exports['qb-target']:AddTargetBone(bone, {
                                                options = {
                                                    {
                                                        type = "client",
                                                        event = "meta_chopshop:client:chopPart",
                                                        icon = "fas fa-wrench",
                                                        label = "Chop " .. part.label,
                                                        args = part
                                                    }
                                                },
                                                distance = 1.5
                                            })
                                        end
                                    end
                                else -- ox_target
                                    local options = {
                                        {
                                            name = 'chop_part_' .. part.name,
                                            icon = 'fas fa-wrench',
                                            label = 'Chop ' .. part.label,
                                            bones = validBones,
                                            onSelect = function()
                                                currentPartName = part.name
                                                ChopVehiclePart(part)
                                            end
                                        }
                                    }
                                    
                                    exports.ox_target:addLocalEntity(vehicle, options)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Add event handler for parts status
RegisterNetEvent('meta_chopshop:client:showPartsStatus', function()
    local vehicle = GetNearestVehicle()
    if vehicle then
        currentVehicle = vehicle
        ShowPartsStatusMenu()
    end
end)

-- Menu
RegisterNetEvent('meta_chopshop:client:openMenu', function()
    -- Check if player is in vehicle
    if IsPlayerInVehicle() then
        TriggerEvent('meta_chopshop:notify', Config.Notifications.in_vehicle)
        return
    end
    
    -- Get player XP data
    TriggerServerEvent('meta_chopshop:server:getXPData')
end)

-- Receive XP data from server
RegisterNetEvent('meta_chopshop:client:receiveXPData', function(xpData)
    if Config.MenuType == 'qb-menu' then
        local menu = {
            {
                header = "Chop Shop Menu",
                isMenuHeader = true
            },
            {
                header = "Chop Shop XP",
                txt = string.format("Level: %d | XP: %d/%d", xpData.level, xpData.currentXP, xpData.nextLevelXP),
                isMenuHeader = true
            },
            {
                header = chopMode and "Chop Mode: Enabled" or "Chop Mode: Disabled",
                txt = "Toggle chop mode on/off",
                params = {
                    event = "meta_chopshop:client:toggleChopMode"
                }
            }
        }
        
        -- Add history option if enabled
        if Config.History.enabled and Config.History.showInMenu then
            table.insert(menu, {
                header = "View History",
                txt = "View your recent chop jobs",
                params = {
                    event = "meta_chopshop:client:showHistory"
                }
            })
        end
        
        table.insert(menu, {
            header = "Close Menu",
            txt = "",
            params = {
                event = "qb-menu:client:closeMenu"
            }
        })
        
        if Config.Framework == 'qb' or Config.Framework == 'qbx' then
            exports['qb-menu']:openMenu(menu)
        else
            -- ESX menu logic here
        end
    else -- ox_lib context menu
        local options = {
            {
                title = "Chop Shop XP",
                description = string.format("Level: %d | XP: %d/%d", xpData.level, xpData.currentXP, xpData.nextLevelXP),
                icon = "star",
                disabled = true
            },
            {
                title = chopMode and "Chop Mode: Enabled" or "Chop Mode: Disabled",
                description = "Toggle chop mode on/off",
                icon = chopMode and "check" or "times",
                onSelect = function()
                    TriggerEvent('meta_chopshop:client:toggleChopMode')
                end
            }
        }
        
        -- Add history option if enabled
        if Config.History.enabled and Config.History.showInMenu then
            table.insert(options, {
                title = "View History",
                description = "View your recent chop jobs",
                icon = "history",
                onSelect = function()
                    ShowHistoryMenu()
                end
            })
        end
        
        lib.registerContext({
            id = 'chopshop_menu',
            title = 'Chop Shop Menu',
            options = options
        })
        
        lib.showContext('chopshop_menu')
    end
end)

-- Toggle chop mode
RegisterNetEvent('meta_chopshop:client:toggleChopMode', function()
    chopMode = not chopMode
    if not chopMode then
        ResetChoppedParts()
        if Config.TargetSystem == 'qb-target' then
            if Config.Framework == 'qb' or Config.Framework == 'qbx' then
                for _, part in pairs(Config.VehicleParts) do
                    exports['qb-target']:RemoveTargetBone(part.bones.primary)
                    for _, secondaryBone in ipairs(part.bones.secondary) do
                        exports['qb-target']:RemoveTargetBone(secondaryBone)
                    end
                end
            end
        else -- ox_target
            local vehicle = GetNearestVehicle()
            if vehicle and DoesEntityExist(vehicle) then
                exports.ox_target:removeLocalEntity(vehicle)
            end
        end
    end
    TriggerEvent('meta_chopshop:notify', chopMode and 'Chop mode enabled' or 'Chop mode disabled')
    -- Reopen menu to show updated state
    TriggerEvent('meta_chopshop:client:openMenu')
end)

RegisterNetEvent('meta_chopshop:client:chopPart', function(part)
    currentPartName = part.name
    ChopVehiclePart(part)
end)

-- Notifications
RegisterNetEvent('meta_chopshop:notify', function(message)
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        QBCore.Functions.Notify(message, 'primary', 5000)
    else
        -- ESX notification logic here
    end
end)

-- Police alert
RegisterNetEvent('meta_chopshop:client:policeAlert', function(location)
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        if PlayerData.job.name == "police" then
            local coords = GetEntityCoords(PlayerPedId())
            local alertCoords = nil
            
            for _, chopLocation in pairs(Config.ChopShops) do
                if chopLocation.name == location then
                    alertCoords = chopLocation.coords
                    break
                end
            end
            
            if alertCoords then
                local alertData = {
                    title = "Chop Shop Alert",
                    coords = alertCoords,
                    description = string.format(Config.Notifications.alert, location)
                }
                TriggerEvent("qb-phone:client:addPoliceAlert", alertData)
            end
        end
    else
        -- ESX police alert logic here
    end
end)

-- Function to show parts status menu
function ShowPartsStatusMenu()
    if not currentVehicle then return end
    
    -- Get vehicle model name and plate
    local vehicleModel = GetEntityModel(currentVehicle)
    local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel)
    local vehiclePlate = GetVehicleNumberPlateText(currentVehicle)
    
    -- Get available doors for this vehicle
    local availableDoors = GetAvailableDoors(currentVehicle)
    
    -- Count parts
    local totalParts = 0
    local choppedCount = 0
    
    -- Create menu items
    local options = {
        {
            title = vehicleName,
            description = "Vehicle Parts Status",
            icon = "car",
            iconColor = "blue",
            disabled = true
        }
    }
    
    -- Add debug section if debug is enabled
    if Config.Debug then
        table.insert(options, {
            title = "Debug Information",
            description = "Vehicle Details",
            icon = "bug",
            iconColor = "red",
            disabled = true
        })
        
        table.insert(options, {
            title = "Model: " .. vehicleModel,
            description = "Vehicle Model Hash",
            icon = "hashtag",
            iconColor = "gray",
            disabled = true
        })
        
        table.insert(options, {
            title = "Plate: " .. vehiclePlate,
            description = "Vehicle License Plate",
            icon = "id-card",
            iconColor = "gray",
            disabled = true
        })
        
        table.insert(options, {
            title = "Available Doors: " .. #availableDoors,
            description = "Number of removable doors",
            icon = "door-open",
            iconColor = "gray",
            disabled = true
        })
    end
    
    -- Add parts sections
    local sections = {
        {
            title = "Doors",
            icon = "door-open",
            iconColor = "orange",
            parts = {
                {name = "door_ds", label = "Driver's Door", icon = "door-open", iconColor = "blue"},
                {name = "door_ps", label = "Passenger's Door", icon = "door-open", iconColor = "blue"},
                {name = "door_lr", label = "Rear Left Door", icon = "door-open", iconColor = "blue"},
                {name = "door_rr", label = "Rear Right Door", icon = "door-open", iconColor = "blue"}
            }
        },
        {
            title = "Other Parts",
            icon = "wrench",
            iconColor = "green",
            parts = {
                {name = "hood", label = "Hood", icon = "car-side", iconColor = "yellow"},
                {name = "trunk", label = "Trunk", icon = "box", iconColor = "yellow"},
                {name = "wheel_lf", label = "Left Front Wheel", icon = "circle", iconColor = "gray"},
                {name = "wheel_rf", label = "Right Front Wheel", icon = "circle", iconColor = "gray"},
                {name = "wheel_lr", label = "Left Rear Wheel", icon = "circle", iconColor = "gray"},
                {name = "wheel_rr", label = "Right Rear Wheel", icon = "circle", iconColor = "gray"}
            }
        }
    }
    
    -- Process each section
    for _, section in ipairs(sections) do
        local sectionChopped = 0
        local sectionTotal = 0
        
        -- Add section header
        table.insert(options, {
            title = section.title,
            description = "",
            icon = section.icon,
            iconColor = section.iconColor,
            disabled = true
        })
        
        -- Process each part in section
        for _, part in ipairs(section.parts) do
            -- Skip doors that don't exist on this vehicle
            if section.title == "Doors" and not table.contains(availableDoors, part.name) then
                goto continue
            end
            
            sectionTotal = sectionTotal + 1
            totalParts = totalParts + 1
            
            if choppedParts[part.name] then
                sectionChopped = sectionChopped + 1
                choppedCount = choppedCount + 1
                table.insert(options, {
                    title = part.label,
                    description = "✓ Successfully removed",
                    icon = "check-circle",
                    iconColor = "green",
                    disabled = true
                })
            else
                table.insert(options, {
                    title = part.label,
                    description = "Click to chop this part",
                    icon = part.icon,
                    iconColor = part.iconColor,
                    onSelect = function()
                        currentPartName = part.name
                        ChopVehiclePart(part)
                    end
                })
            end
            
            ::continue::
        end
        
        -- Add section summary
        if sectionTotal > 0 then
            table.insert(options, {
                title = string.format("%s Progress: %d/%d", section.title, sectionChopped, sectionTotal),
                description = "",
                icon = "chart-bar",
                iconColor = section.iconColor,
                disabled = true
            })
        end
    end
    
    -- Add overall progress
    table.insert(options, {
        title = string.format("Overall Progress: %d/%d parts chopped", choppedCount, totalParts),
        description = "",
        icon = "trophy",
        iconColor = "gold",
        disabled = true
    })
    
    -- Add completion option if all parts are chopped
    if choppedCount == totalParts then
        table.insert(options, {
            title = "Complete Chopping",
            description = "Click to finish and remove vehicle",
            icon = "check-double",
            iconColor = "green",
            onSelect = function()
                -- Start completion sequence
                local vehicleToDelete = currentVehicle
                
                -- Get final vehicle data
                local finalVehicleData = {
                    plate = vehiclePlate,
                    model = vehicleModel,
                    name = vehicleName
                }
                
                -- Calculate total earnings
                local totalEarnings = 0
                local choppedPartsList = {}
                for partName, _ in pairs(choppedParts) do
                    if partName ~= "vehicle" and partName ~= "objects" then
                        for _, part in pairs(Config.VehicleParts) do
                            if part.name == partName then
                                local earnings = math.random(part.reward.sell_price.min, part.reward.sell_price.max)
                                totalEarnings = totalEarnings + earnings
                                table.insert(choppedPartsList, {
                                    name = part.label,
                                    earnings = earnings
                                })
                            end
                        end
                    end
                end
                
                -- Update history
                UpdateChopHistory(finalVehicleData, choppedPartsList, totalEarnings)
                
                -- Play completion sound
                PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
                
                -- Create completion effect
                local coords = GetEntityCoords(vehicleToDelete)
                RequestNamedPtfxAsset("scr_xs_celebration")
                while not HasNamedPtfxAssetLoaded("scr_xs_celebration") do
                    Wait(0)
                end
                UseParticleFxAssetNextCall("scr_xs_celebration")
                StartParticleFxNonLoopedAtCoord("scr_xs_confetti_burst", coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
                
                -- Fade out vehicle
                SetEntityAlpha(vehicleToDelete, 0, false)
                
                -- Remove vehicle from garage and delete it
                SetTimeout(1000, function()
                    if DoesEntityExist(vehicleToDelete) then
                        -- Trigger server event to remove from garage
                        TriggerServerEvent('meta_chopshop:server:removeFromGarage', finalVehicleData)
                        
                        -- Delete the vehicle
                        DeleteEntity(vehicleToDelete)
                        TriggerEvent('meta_chopshop:notify', string.format('Vehicle completely chopped! Total earnings: %s%d', Config.History.format.currency, totalEarnings))
                        
                        -- Reset chopped parts tracking
                        ResetChoppedParts()
                    end
                end)
            end
        })
    end
    
    -- Add history section if enabled
    if Config.History.enabled and Config.History.showInMenu then
        table.insert(options, {
            title = "Chop History",
            description = "View your recent chop jobs",
            icon = "history",
            iconColor = "purple",
            onSelect = function()
                ShowHistoryMenu()
            end
        })
    end
    
    -- Add debug toggle option
    table.insert(options, {
        title = "Toggle Debug Mode",
        description = Config.Debug and "Debug Mode: Enabled" or "Debug Mode: Disabled",
        icon = "bug",
        iconColor = Config.Debug and "red" or "gray",
        onSelect = function()
            Config.Debug = not Config.Debug
            TriggerEvent('meta_chopshop:notify', Config.Debug and 'Debug mode enabled' or 'Debug mode disabled')
            -- Refresh menu
            ShowPartsStatusMenu()
        end
    })
    
    -- Add close option
    table.insert(options, {
        title = "Close Menu",
        description = "Exit parts status",
        icon = "times",
        iconColor = "red",
        onSelect = function()
            -- Menu will close automatically
        end
    })
    
    -- Show menu using ox_lib
    lib.registerContext({
        id = 'parts_status_menu',
        title = 'Vehicle Parts Status',
        options = options
    })
    
    lib.showContext('parts_status_menu')
end

-- Helper function to check if table contains value
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Update the existing menu to include parts status
function ShowChopShopMenu()
    if not currentVehicle then return end
    
    local options = {
        {
            title = "Chop Vehicle Parts",
            description = "Start chopping parts from the vehicle",
            icon = "fas fa-car-crash",
            onSelect = function()
                StartChopping()
            end
        },
        {
            title = "Parts Status",
            description = "View chopped and remaining parts",
            icon = "fas fa-list",
            onSelect = function()
                ShowPartsStatusMenu()
            end
        },
        {
            title = "Cancel",
            description = "Exit the menu",
            icon = "fas fa-times",
            onSelect = function()
                -- Close menu
            end
        }
    }
    
    lib.registerContext({
        id = 'chop_shop_menu',
        title = 'Chop Shop Menu',
        options = options
    })
    
    lib.showContext('chop_shop_menu')
end

-- Add after other RegisterNetEvent handlers
RegisterNetEvent('meta_chopshop:client:updateHistory', function(historyData)
    chopHistory = historyData
end)

-- Add this function to handle history updates
function UpdateChopHistory(vehicleData, parts, earnings)
    if not Config.History.enabled then return end
    
    local historyEntry = {
        vehicleName = vehicleData.name,
        plate = vehicleData.plate,
        date = os.date(Config.History.format.date),
        parts = parts,
        earnings = earnings
    }
    
    table.insert(chopHistory, 1, historyEntry)
    
    -- Keep only the maximum number of entries
    if #chopHistory > Config.History.maxEntries then
        table.remove(chopHistory, Config.History.maxEntries + 1)
    end
    
    -- Update history on server
    TriggerServerEvent('meta_chopshop:server:updateHistory', historyEntry)
end

-- Add new function to show history menu
function ShowHistoryMenu()
    local options = {
        {
            title = "Chop History",
            description = "Your recent chop jobs",
            icon = "history",
            iconColor = "purple",
            disabled = true
        }
    }
    
    if #chopHistory == 0 then
        table.insert(options, {
            title = "No History",
            description = "You haven't chopped any vehicles yet",
            icon = "info-circle",
            iconColor = "gray",
            disabled = true
        })
    else
        for _, entry in ipairs(chopHistory) do
            local details = {}
            if Config.History.showDetails.vehicleName then
                table.insert(details, "Vehicle: " .. entry.vehicleName)
            end
            if Config.History.showDetails.plate then
                table.insert(details, "Plate: " .. entry.plate)
            end
            if Config.History.showDetails.date then
                table.insert(details, "Date: " .. entry.date)
            end
            if Config.History.showDetails.parts then
                local partsList = {}
                for _, part in ipairs(entry.parts) do
                    table.insert(partsList, part.name)
                end
                table.insert(details, "Parts: " .. table.concat(partsList, ", "))
            end
            if Config.History.showDetails.earnings then
                table.insert(details, "Earnings: " .. Config.History.format.currency .. entry.earnings)
            end
            
            table.insert(options, {
                title = entry.vehicleName,
                description = table.concat(details, "\n"),
                icon = "car",
                iconColor = "blue",
                disabled = true
            })
        end
    end
    
    -- Add back option
    table.insert(options, {
        title = "Back",
        description = "Return to parts status",
        icon = "arrow-left",
        iconColor = "gray",
        onSelect = function()
            ShowPartsStatusMenu()
        end
    })
    
    lib.registerContext({
        id = 'chop_history_menu',
        title = 'Chop History',
        options = options
    })
    
    lib.showContext('chop_history_menu')
end

-- Add event handler for showing history
RegisterNetEvent('meta_chopshop:client:showHistory', function()
    ShowHistoryMenu()
end)

-- Add cleanup for PEDs
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if DoesEntityExist(chopShopPed) then
            DeleteEntity(chopShopPed)
        end
        if DoesEntityExist(partBuyerPed) then
            DeleteEntity(partBuyerPed)
        end
    end
end)

-- Open part selling menu
function OpenPartSellingMenu()
    TriggerServerEvent('meta_chopshop:server:getSellableParts')
end

-- Receive sellable parts from server
RegisterNetEvent('meta_chopshop:client:receiveSellableParts', function(parts)
    if #parts == 0 then
        lib.notify({
            title = 'Part Buyer',
            description = Config.PartSelling.notifications.no_parts,
            type = 'error'
        })
        return
    end

    -- Calculate total value of all parts
    local totalValue = 0
    local totalParts = 0
    for _, part in ipairs(parts) do
        totalValue = totalValue + (part.count * part.price.min)
        totalParts = totalParts + part.count
    end

    local options = {
        {
            title = "Part Buyer",
            description = string.format("Total Parts: %d | Estimated Value: $%d", totalParts, totalValue),
            icon = "store",
            iconColor = "blue",
            disabled = true
        },
        {
            title = "Sell All Parts",
            description = string.format("Sell all %d parts for $%d", totalParts, totalValue),
            icon = "dollar-sign",
            iconColor = "green",
            onSelect = function()
                lib.registerContext({
                    id = 'confirm_sell_all',
                    title = 'Confirm Sell All',
                    options = {
                        {
                            title = "Confirm",
                            description = string.format("Sell all %d parts for $%d", totalParts, totalValue),
                            icon = "check",
                            iconColor = "green",
                            onSelect = function()
                                TriggerServerEvent('meta_chopshop:server:sellAllParts')
                            end
                        },
                        {
                            title = "Cancel",
                            description = "Return to menu",
                            icon = "times",
                            iconColor = "red",
                            onSelect = function()
                                OpenPartSellingMenu()
                            end
                        }
                    }
                })
                lib.showContext('confirm_sell_all')
            end
        },
        {
            title = "Swap for Materials",
            description = "Exchange parts for crafting materials",
            icon = "exchange-alt",
            iconColor = "orange",
            onSelect = function()
                ShowMaterialSwapMenu(parts)
            end
        }
    }

    -- Add section for individual parts
    table.insert(options, {
        title = "Individual Parts",
        description = "Sell parts individually",
        icon = "list",
        iconColor = "purple",
        disabled = true
    })

    -- Group parts by type
    local groupedParts = {
        doors = {},
        other = {}
    }

    for _, part in ipairs(parts) do
        if part.name:find("door") then
            table.insert(groupedParts.doors, part)
        else
            table.insert(groupedParts.other, part)
        end
    end

    -- Add doors section
    if #groupedParts.doors > 0 then
        table.insert(options, {
            title = "Doors",
            description = "Vehicle doors",
            icon = "door-open",
            iconColor = "blue",
            disabled = true
        })

        for _, part in ipairs(groupedParts.doors) do
            table.insert(options, {
                title = part.label,
                description = string.format('Quantity: %d | Price: $%d-$%d', part.count, part.price.min, part.price.max),
                icon = "door-open",
                iconColor = "blue",
                onSelect = function()
                    ShowPartSellOptions(part)
                end
            })
        end
    end

    -- Add other parts section
    if #groupedParts.other > 0 then
        table.insert(options, {
            title = "Other Parts",
            description = "Hoods, trunks, and wheels",
            icon = "wrench",
            iconColor = "orange",
            disabled = true
        })

        for _, part in ipairs(groupedParts.other) do
            table.insert(options, {
                title = part.label,
                description = string.format('Quantity: %d | Price: $%d-$%d', part.count, part.price.min, part.price.max),
                icon = part.name:find("wheel") and "circle" or "car-side",
                iconColor = "orange",
                onSelect = function()
                    ShowPartSellOptions(part)
                end
            })
        end
    end

    -- Add close option
    table.insert(options, {
        title = "Close",
        description = "Exit menu",
        icon = "times",
        iconColor = "red",
        onSelect = function()
            -- Menu will close automatically
        end
    })

    lib.registerContext({
        id = 'part_selling_menu',
        title = 'Part Buyer',
        options = options
    })

    lib.showContext('part_selling_menu')
end)

-- Function to show part sell options
function ShowPartSellOptions(part)
    local options = {
        {
            title = part.label,
            description = string.format('Quantity: %d | Price: $%d-$%d', part.count, part.price.min, part.price.max),
            icon = part.name:find("door") and "door-open" or (part.name:find("wheel") and "circle" or "car-side"),
            iconColor = part.name:find("door") and "blue" or "orange",
            disabled = true
        },
        {
            title = "Sell All",
            description = string.format('Sell all %d for $%d', part.count, part.count * part.price.min),
            icon = "dollar-sign",
            iconColor = "green",
            onSelect = function()
                TriggerServerEvent('meta_chopshop:server:sellPart', part.name, part.count)
            end
        }
    }

    -- Add individual sell options if more than 1
    if part.count > 1 then
        for i = 1, math.min(5, part.count) do
            table.insert(options, {
                title = string.format("Sell %d", i),
                description = string.format('Sell %d for $%d', i, i * part.price.min),
                icon = "dollar-sign",
                iconColor = "green",
                onSelect = function()
                    TriggerServerEvent('meta_chopshop:server:sellPart', part.name, i)
                end
            })
        end
    end

    -- Add back option
    table.insert(options, {
        title = "Back",
        description = "Return to main menu",
        icon = "arrow-left",
        iconColor = "gray",
        onSelect = function()
            OpenPartSellingMenu()
        end
    })

    lib.registerContext({
        id = 'part_sell_options',
        title = 'Sell ' .. part.label,
        options = options
    })

    lib.showContext('part_sell_options')
end

-- Function to show material swap menu
function ShowMaterialSwapMenu(parts)
    if not Config.MaterialExchange.enabled then
        lib.notify({
            title = 'Part Buyer',
            description = 'Material exchange is currently disabled',
            type = 'error'
        })
        return
    end

    local options = {
        {
            title = "Material Exchange",
            description = "Swap parts for crafting materials",
            icon = "exchange-alt",
            iconColor = "orange",
            disabled = true
        }
    }

    -- Calculate total parts
    local totalParts = 0
    for _, part in ipairs(parts) do
        totalParts = totalParts + part.count
    end

    -- Add available parts info
    table.insert(options, {
        title = string.format("Available Parts: %d", totalParts),
        description = Config.MaterialExchange.notifications.available_parts:format(totalParts),
        icon = "car",
        iconColor = "blue",
        disabled = true
    })

    -- Add material exchange options from config
    for _, material in ipairs(Config.MaterialExchange.materials) do
        local possibleAmount = math.floor(totalParts / material.ratio)
        local finalAmount = math.min(possibleAmount, material.maxAmount)

        if finalAmount > 0 then
            local estimatedValue = math.random(material.price.min, material.price.max) * finalAmount
            table.insert(options, {
                title = string.format("Exchange for %s", material.label),
                description = string.format("%s\nRequired: %s\nYou can get: %d %s\nEstimated Value: $%d", 
                    material.description,
                    material.requiredParts,
                    finalAmount, 
                    material.label,
                    estimatedValue
                ),
                icon = material.icon,
                iconColor = "orange",
                onSelect = function()
                    lib.registerContext({
                        id = 'confirm_material_swap',
                        title = 'Confirm Exchange',
                        options = {
                            {
                                title = "Confirm",
                                description = string.format("Exchange %d parts for %d %s\nEstimated Value: $%d", 
                                    finalAmount * material.ratio, 
                                    finalAmount, 
                                    material.label,
                                    estimatedValue
                                ),
                                icon = "check",
                                iconColor = "green",
                                onSelect = function()
                                    TriggerServerEvent('meta_chopshop:server:swapForMaterial', material.name, finalAmount)
                                end
                            },
                            {
                                title = "Cancel",
                                description = "Return to menu",
                                icon = "times",
                                iconColor = "red",
                                onSelect = function()
                                    ShowMaterialSwapMenu(parts)
                                end
                            }
                        }
                    })
                    lib.showContext('confirm_material_swap')
                end
            })
        else
            -- Show option as disabled if not enough parts
            table.insert(options, {
                title = string.format("Exchange for %s", material.label),
                description = string.format("%s\nRequired: %s\nYou need %d more parts", 
                    material.description,
                    material.requiredParts,
                    material.ratio - totalParts
                ),
                icon = material.icon,
                iconColor = "gray",
                disabled = true
            })
        end
    end

    -- Add back option
    table.insert(options, {
        title = "Back",
        description = "Return to main menu",
        icon = "arrow-left",
        iconColor = "gray",
        onSelect = function()
            OpenPartSellingMenu()
        end
    })

    lib.registerContext({
        id = 'material_swap_menu',
        title = 'Material Exchange',
        options = options
    })

    lib.showContext('material_swap_menu')
end

-- Add event handler for selling menu
RegisterNetEvent('meta_chopshop:client:openSellingMenu', function()
    OpenPartSellingMenu()
end) 

