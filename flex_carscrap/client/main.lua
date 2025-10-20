local ScrapZone, VehicleTargets = {}, {}
local ScrapList, CurrentScrapList = {}, {}
local IsInScrapZone, IsTakingPart, IsScrapping = false, false, false
local SellPeds, SellPedsTarget, SellTarget = {}, {}, {}
local RadialAddon = false

local boneNames = {
    ["wheel_fl"] = "wheel_lf",      -- Front Left Tyre
    ["wheel_fr"] = "wheel_rf",      -- Front Right Tyre
    ["wheel_rl"] = "wheel_lr",      -- Rear Left
    ["wheel_rr"] = "wheel_rr",      -- Rear Right
    ["door_fl"] = "door_dside_f",   -- Front Left Door
    ["door_fr"] = "door_pside_f",   -- Front Right Door
    ["door_rl"] = "door_dside_r",   -- Rear Left Door
    ["door_rr"] = "door_pside_r",   -- Rear Right Door
    ["hood"]    = "bonnet",         -- Hood
    ["trunk"]   = "boot"            -- Trunk
}
local WheelIndexes = {
    ["wheel_lf"] = 0,  -- Front Left
    ["wheel_rf"] = 1,  -- Front Right
    ["wheel_lr"] = 2,  -- Rear Left
    ["wheel_rr"] = 3,  -- Rear Right
}
local DoorIndexes = {
    ["door_dside_f"] = 0,
    ["door_pside_f"] = 1,
    ["door_dside_r"] = 2,
    ["door_pside_r"] = 3,
    ["bonnet"] = 4,
    ["boot"] = 5
}

local function IsTableEmpty(t)
    if type(t) ~= "table" then
        return true -- Not a table, treat as empty
    end
    for _ in pairs(t) do
        return false -- Found at least one element, not empty
    end
    return true -- No elements found, table is empty
end

local function MakePed(coords, ped)
    local hash = GetHashKey(ped)
    lib.requestModel(hash)
    SellPeds[#SellPeds+1] = CreatePed(1, hash, coords.x, coords.y, coords.z-1)
    SetEntityHeading(SellPeds[#SellPeds],coords.w)
    SetBlockingOfNonTemporaryEvents(SellPeds[#SellPeds], true)
    SetPedDiesWhenInjured(SellPeds[#SellPeds], false)
    SetPedCanPlayAmbientAnims(SellPeds[#SellPeds], true)
    SetPedCanRagdollFromPlayerImpact(SellPeds[#SellPeds], false)
    SetEntityInvincible(SellPeds[#SellPeds], true)
    FreezeEntityPosition(SellPeds[#SellPeds], true)
    return SellPeds[#SellPeds]
end

local function DeleteCarFromList(car)
    for i, model in ipairs(ScrapList) do
        if model == car then
            table.remove(ScrapList, i)
            break
        end
    end
end

local function ContainsBone(vehicle)
    for part, bone in pairs(boneNames) do
        if VehicleTargets[vehicle][bone] then
            return true
        end
    end
    return false
end

local function IsPartBroken(vehicle, bone)
    if WheelIndexes[bone] then
        local wheelHealth = GetVehicleWheelHealth(vehicle, WheelIndexes[bone])
        if wheelHealth > 0 then
            return false
        end
        return true
    elseif DoorIndexes[bone] then
        return IsVehicleDoorDamaged(vehicle, DoorIndexes[bone])
    else
        return true
    end
end

local function HasAllDoors(vehicle)
    local Doors = GetNumberOfVehicleDoors(vehicle)
    local MissingDoors = Doors
    for bone, id in pairs(DoorIndexes) do
        if IsVehicleDoorDamaged(vehicle, id) then
            MissingDoors -= 1
        end
    end
    if MissingDoors <= 0 then
        return false
    else
        return true
    end
end

local function HasAllWheels(vehicle)
    local wheelCount = GetVehicleNumberOfWheels(vehicle)
    local missingWheels = {}
    
    for i = 0, wheelCount - 1 do
        local wheelHealth = GetVehicleWheelHealth(vehicle, i)
        if wheelHealth <= 100 then
            table.insert(missingWheels, i)
        end
    end
    if #missingWheels > 0 then
        return false
    else
        return true
    end
end

local function AreAllWheelsBroken(vehicle)
    local wheelCount = GetVehicleNumberOfWheels(vehicle)
    local count = wheelCount
    local missingWheels = {}
    
    for i = 0, count - 1 do
        local wheelHealth = GetVehicleWheelHealth(vehicle, i)
        if wheelHealth == 0 then
            table.insert(missingWheels, i)
        end
    end
    if #missingWheels >= wheelCount then
        return true
    else
        return false
    end
end

local function isDriver(vehicle)
    return GetPedInVehicleSeat(vehicle, -1) == PlayerPedId()
end

local function deleteVehicleProperly(vehicle)
    if not DoesEntityExist(vehicle) then return end

    -- Make sure it's networked
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId and netId ~= 0 then
        NetworkRequestControlOfNetworkId(netId)
        local timeout = GetGameTimer() + 2000
        while not NetworkHasControlOfNetworkId(netId) and GetGameTimer() < timeout do
            Wait(0)
            NetworkRequestControlOfNetworkId(netId)
        end
    end

    -- Ensure entity control
    local timeoutEntity = GetGameTimer() + 2000
    while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < timeoutEntity do
        Wait(0)
        NetworkRequestControlOfEntity(vehicle)
    end

    -- Mission entity claim
    SetEntityAsMissionEntity(vehicle, true, true)

    -- Double check it's mission entity
    if not IsEntityAMissionEntity(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
    end

    -- Delete attempts
    DeleteEntity(vehicle)
    if DoesEntityExist(vehicle) then
        DeleteVehicle(vehicle)
    end

    -- Final force cleanup if stubborn
    if DoesEntityExist(vehicle) then
        TriggerServerEvent("flex_carscrap:Server:ForceDeleteVehicle", netId)
    end
end

function OnPlayerLoad()
    for k, v in pairs(Config.SellPeds) do
        if not v.ped then
            SellTarget[#SellTarget+1] = exports.ox_target:addBoxZone({
                name = "sellzone_"..k,
                coords = v.coords.xyz,
                size = v.boxsize or vec3(2.0, 2.0, 2.0),
                rotation = v.coords.w,
                debug = Config.Debug,
                drawSprite = true,
                options = {
                    {
                        name = "sellzone_"..k,
                        icon = "fa-solid fa-hand-holding-hand",
                        label = Language.target.sell,
                        distance = 1.5,
                        canInteract = function()
                            local ped = PlayerPedId()
                            return IsEntityPlayingAnim(ped, 'anim@heists@box_carry@', 'idle', 3) or Config.SellWithoutAnim
                        end,
                        onSelect = function(args)
                            SellParts(false)
                        end,
                    },
                    {
                        name = "sellzone_"..k,
                        icon = "fa-solid fa-comment",
                        label = Language.target.talk,
                        distance = 1.5,
                        canInteract = function()
                            local ped = PlayerPedId()
                            return not IsEntityPlayingAnim(ped, 'anim@heists@box_carry@', 'idle', 3) or Config.SellWithoutAnim
                        end,
                        onSelect = function(args)
                            Config.Notify.client(Language.info.fullfixedvehicle, 'info', 5000)
                        end,
                    }
                }
            })
        elseif v.ped then
            local ped = MakePed(v.coords, v.ped)
            SellPedsTarget[#SellPedsTarget+1] = exports.ox_target:addLocalEntity(ped, {
                {
                    name= "sellzone_"..k,
                    icon = "fa-solid fa-hand-holding-hand",
                    label = Language.target.sell,
                    canInteract = function()
                        local ped = PlayerPedId()
                        return IsEntityPlayingAnim(ped, 'anim@heists@box_carry@', 'idle', 3)
                    end,
                    onSelect = function(args)
                        SellParts(ped)
                    end,
                    distance = 1.5
                }
            })
        end
    end
    for k, v in pairs(Config.ScrappingZones) do
        ScrapZone[#ScrapZone+1] = PolyZone:Create(v, {
            name = "ScrappingZone_"..k,
            debugPoly = Config.Debug
        })
        ScrapZone[#ScrapZone]:onPlayerInOut(function(isPointInside)
            IsInScrapZone = isPointInside
            if isPointInside then
                CreateThread(function()
                    while IsInScrapZone do
                        local ped = PlayerPedId()
                        local vehicle = GetVehiclePedIsIn(ped)
                        local model = GetEntityModel(vehicle)
                        if vehicle and vehicle ~= 0 and not IsTableEmpty(ScrapList) then
                            local plate = GetVehicleNumberPlateText(vehicle)
                            if not isDriver(vehicle) then
                                return Config.Notify.client(Language.error.notdriver, 'error', 5000)
                            end
                            if (not HasAllWheels(vehicle) or not HasAllDoors(vehicle)) then
                                IsInScrapZone = false
                                return Config.Notify.client(Language.error.missingparts, 'error', 5000)
                            end
                            local speed = GetEntitySpeed(vehicle)
                            if speed < 0.1 then
                                local registred = lib.callback.await("flex_carscrap:Server:IsPlateRegistered", false, plate)
                                Wait(100)
                                if lib.table.contains(ScrapList, model) and not registred then
                                    if not lib.table.contains(CurrentScrapList, model) then
                                        CurrentScrapList[#CurrentScrapList+1] = model
                                    end
                                    if not registred then
                                        TriggerServerEvent('flex_carscrap:Server:RegisterPlate', plate)
                                    end
                                    if not VehicleTargets[vehicle] then VehicleTargets[vehicle] = {} end
                                    if VehicleTargets[vehicle] then
                                        exports.ox_target:addLocalEntity(vehicle, {
                                            {
                                                name = "flex_carscrap_removevehicle"..vehicle,
                                                icon = "fa-solid fa-dolly",
                                                label = Language.target.removevehicle,
                                                canInteract = function(entity, distance, coords, name)
                                                    if DoesEntityExist(entity) then
                                                        local HasDoors = HasAllDoors(entity)
                                                        local HasBrokenWheels = AreAllWheelsBroken(entity)
                                                        if not HasDoors and HasBrokenWheels then
                                                            return true
                                                        end
                                                        return false
                                                    end
                                                    return false
                                                end,
                                                onSelect = function(data)
                                                    if DoesEntityExist(data.entity) then
                                                        deleteVehicleProperly(data.entity)
                                                    end
                                                    exports.ox_target:removeLocalEntity("flex_carscrap_removevehicle"..vehicle)
                                                end,
                                                distance = 2.0
                                            },
                                        })
                                        if ContainsBone(vehicle) then
                                        else
                                            for part, bone in pairs(boneNames) do
                                                if not VehicleTargets[vehicle][bone] 
                                                and not IsPartBroken(vehicle, bone)
                                                then
                                                    local boneIndex = GetEntityBoneIndexByName(vehicle, bone)
                                                    if boneIndex ~= -1 then
                                                        local x, y, z = table.unpack(GetWorldPositionOfEntityBone(vehicle, boneIndex))
                                                        local heading = GetEntityHeading(vehicle)
                                                        local rad = math.rad(heading)
                                                        local boxsize = vec3(.8, .8, .8)
                                                        if bone == "boot" then
                                                            x = x - math.sin(-rad) * 0.3
                                                            y = y - math.cos(-rad) * 0.3
                                                            boxsize = vec3(1.3, 1.0, .8)
                                                        elseif bone == "bonnet" then
                                                            x = x + math.sin(-rad) * 0.8
                                                            y = y + math.cos(-rad) * 0.8
                                                            boxsize = vec3(1.3, 1.2, .8)
                                                        elseif string.find(bone, "door") then
                                                            x = x - math.sin(-rad) * 0.4
                                                            y = y - math.cos(-rad) * 0.4
                                                            z = z + 0.15
                                                            boxsize = vec3(.7, 1.2, .8)
                                                        end
                                                        VehicleTargets[vehicle][bone] = exports.ox_target:addBoxZone({
                                                            name = "scrapbone_"..vehicle..bone,
                                                            coords = vec3(x, y, z),
                                                            size = boxsize,
                                                            rotation = heading,
                                                            debug = Config.Debug,
                                                            drawSprite = true,
                                                            distance = 1.2,
                                                            options = {
                                                                {
                                                                    name= "scrapbone_"..vehicle..bone,
                                                                    icon = "fas fa-screwdriver",
                                                                    label = Language.target.scrap,
                                                                    distance = 1.3,
                                                                    canInteract = function()
                                                                        local ped = PlayerPedId()
                                                                        return not IsTakingPart and not IsEntityPlayingAnim(ped, 'anim@heists@box_carry@', 'idle', 3)
                                                                    end,
                                                                    onSelect = function(args)
                                                                        scrap(vehicle, bone, boneIndex, vec3(x, y, z))
                                                                        IsScrapping = true
                                                                    end,
                                                                }
                                                            }
                                                        })
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                if VehicleTargets then
                                    if VehicleTargets[vehicle] ~= nil then
                                        for part, bone in pairs(boneNames) do
                                            if VehicleTargets[vehicle][bone] then
                                                exports.ox_target:removeZone(VehicleTargets[vehicle][bone])
                                            end
                                        end
                                        VehicleTargets[vehicle] = nil
                                    end
                                end
                                if lib.callback.await("flex_carscrap:Server:IsPlateRegistered", false, plate) then
                                    TriggerServerEvent('flex_carscrap:Server:RemovePlate', plate)
                                end
                                IsTakingPart = false
                            end
                        end
                        Wait(500)
                    end
                end)
            else
                for k, v in pairs(VehicleTargets) do
                    if v and not IsScrapping then
                        for part, bone in pairs(boneNames) do
                            exports.ox_target:removeZone(v[bone])
                        end
                        v = nil
                    end
                end
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped)
                if vehicle ~= nil then
                    exports.ox_target:removeLocalEntity("flex_carscrap_removevehicle"..vehicle)
                end
                IsTakingPart = false
            end
        end)
    end
end

function SellParts(SellPed)
    local ped = PlayerPedId()
    if SellPed then
        FreezeEntityPosition(SellPed, false)
        lib.requestAnimDict("gestures@m@standing@casual", 5000)
        TaskPlayAnim(SellPed, 'gestures@m@standing@casual' ,'gesture_shrug_hard' ,8.0, -8.0, 10000, 51, 0, false, false, false)
        TaskTurnPedToFaceCoord(ped, GetEntityCoords(SellPed))
        TaskTurnPedToFaceCoord(SellPed, GetEntityCoords(ped))
        SetPedTalk(SellPed)
        PlayAmbientSpeech1(SellPed, 'GENERIC_HI', 'SPEECH_PARAMS_STANDARD')
    else
        lib.playAnim(ped, 'mp_car_bomb', 'car_bomb_mechanic', 3.0, 3.0, -1, 1)
    end
    if lib.progressBar({
        duration = 1000 * Config.ProgressTime.sell,  
        label = Language.progress.sell,      
        useWhileDead = false,
        canCancel = true,  
        disable = { move = true } 
    }) then
        ClearPedTasks(SellPed)
        ClearPedTasks(ped)
        TriggerServerEvent('flex_carscrap:Server:SellItem')
    end
end

function scrap(vehicle, bone, boneindex, coords)
    local ped = PlayerPedId()
    SetVehicleEngineHealth(vehicle, -4000.0)
    SetVehicleUndriveable(vehicle, true)

    IsTakingPart = true
    local doorIndex = DoorIndexes[bone]
    if doorIndex ~= nil then
        SetVehicleDoorOpen(vehicle, doorIndex, false, false)
    end
    TaskTurnPedToFaceCoord(ped, coords, 1500)
    Wait(1500)
    if string.find(bone, "wheel") then
        lib.playAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 3.0, 3.0, -1, 1)
    else
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_WELDING', -1, true)
    end
    if lib.progressBar({
        duration = 1000 * Config.ProgressTime.scrap,  
        label = Language.progress.scrap,      
        useWhileDead = false,
        canCancel = true,  
        disable = { move = true } 
    }) then
        if string.find(bone, "wheel") then
            local wheelIndex = WheelIndexes[bone]
            if wheelIndex ~= nil then
                SetVehicleWheelHealth(vehicle, wheelIndex, 0)
                TriggerServerEvent('flex_carscrap:Server:BreakTyre', NetworkGetNetworkIdFromEntity(vehicle), bone)
            end
        else
            if doorIndex ~= nil then
                -- SetVehicleDoorBroken(vehicle, doorIndex, true)
                TriggerServerEvent('flex_carscrap:Server:BreakDoor', NetworkGetNetworkIdFromEntity(vehicle), doorIndex)
            end
        end
        ClearPedTasks(ped)
        TriggerServerEvent('flex_carscrap:Server:GiveItem', bone)
        exports.ox_target:removeZone(VehicleTargets[vehicle][bone])
        if DoesEntityExist(vehicle) then
            local HasDoors = HasAllDoors(vehicle)
            local HasBrokenWheels = AreAllWheelsBroken(vehicle)
            if not HasDoors and HasBrokenWheels then
                local model = GetEntityModel(vehicle)
                if model then
                    DeleteCarFromList(model)
                    TriggerServerEvent('flex_carscrap:Server:FinishContract', model)
                end
                deleteVehicleProperly(vehicle)
                exports.ox_target:removeLocalEntity("flex_carscrap_removevehicle"..vehicle)
                VehicleTargets[vehicle] = nil
                IsScrapping = false
            end
        end
    else 
    end
    IsTakingPart = false
end

RegisterNetEvent("flex_carscrap:Client:BreakDoor", function(NetId, index)
    local vehicle = NetworkGetEntityFromNetworkId(NetId)
    if DoesEntityExist(vehicle) then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local carCoords = GetEntityCoords(vehicle)
        local distance = #(coords - carCoords)
        if distance < 30.0 then
            SetVehicleDoorBroken(vehicle, index, true)
        end
    end
end)

RegisterNetEvent("flex_carscrap:Client:BreakTyre", function(NetId, bone)
    local vehicle = NetworkGetEntityFromNetworkId(NetId)
    if DoesEntityExist(vehicle) then
        local wheelIndex = WheelIndexes[bone]
        if wheelIndex ~= nil then
            SetVehicleWheelHealth(vehicle, wheelIndex, 0)
            BreakOffVehicleWheel(vehicle, wheelIndex, true, true, true, false)
            ApplyForceToEntity(vehicle, 1, 1, 1, 1, 1, 10, true, true, true, false, true, false, false)
        end
    end
end)

RegisterNetEvent("flex_carscrap:Client:UpdateScrapList", function(list)
    ScrapList = list
    if Config.RadialAddon and list then
        AddRadialOption()
    end
end)

RegisterNetEvent("flex_carscrap:Client:ShowScrapList", function(list)
    local ScrapList = {}
    if list and #list > 0 then
        for i = 1, #list do
            ScrapList[i] = {
                title = GetDisplayNameFromVehicleModel(list[i]),
            }
        end
    else
        ScrapList[1] = {
            title = Language.menu.scraplist.nothingtoscrap,
        }
    end

    lib.registerContext({
        id = 'carscrap_showlist',
        title = Language.menu.scraplist.header,
        options = ScrapList
    })

    lib.showContext('carscrap_showlist')
end)

lib.callback.register('flex_carscrap:Client:GetVehicleDisplayName', function(veh)
    return GetDisplayNameFromVehicleModel(veh)
end)

function OnPlayerUnLoad()
    for k, v in pairs(CurrentScrapList) do
        TriggerServerEvent("flex_carscrap:Server:Disconnect", v)
    end
    -- if Config.RadialAddon and not Config.ScrapListCommand then
    --     exports[Config.CoreName.qb_radial]:RemoveOption('flex_carscrap:Server:ShowScrapList')
    -- end
end

RegisterNetEvent('onPlayerDropped', function(serverId)
    OnPlayerUnLoad()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if VehicleTargets then
            if VehicleTargets[vehicle] ~= nil then
                for part, bone in pairs(boneNames) do
                    exports.ox_target:removeZone(VehicleTargets[vehicle][bone])
                end
                VehicleTargets[vehicle] = nil
            end
        end
        for k, v in pairs(SellPedsTarget) do
            exports.ox_target:removeLocalEntity(v)
        end
        for k, v in pairs(SellTarget) do
            exports.ox_target:removeZone(v)
        end
        for k, v in pairs(ScrapZone) do
            v:destroy()
        end
        for k, v in pairs(SellPeds) do
            if DoesEntityExist(v) then
                DeleteEntity(v)
            end
        end
        if Config.RadialAddon and not Config.ScrapListCommand then
            exports[Config.CoreName.qb_radial]:RemoveOption('flex_carscrap:Server:ShowScrapList')
        end
    end
end)

if GetResourceState(Config.CoreName.qbx) == 'started' or GetResourceState(Config.CoreName.qb) == 'started' then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        OnPlayerLoad()
        local list = lib.callback.await("flex_carscrap:Server:GetScrapList", false)
        ScrapList = list
        if Config.RadialAddon and list then
            AddRadialOption()
        end
    end)
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        OnPlayerUnLoad()
    end)
elseif GetResourceState(Config.CoreName.esx) == 'started' then
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(playerData)
        OnPlayerLoad()
        local list = lib.callback.await("flex_carscrap:Server:GetScrapList", false)
        ScrapList = list
        if Config.RadialAddon and list and not Config.ScrapListCommand then
            AddRadialOption()
        end
    end)
end

function AddRadialOption()
    if RadialAddon then return end
    RadialAddon = true
    exports[Config.CoreName.qb_radial]:AddOption({
        id = 'flex_carscrap:Server:ShowScrapList',
        title = Language.radial.scraplist,
        icon = "clipboard-list",
        type = "server",
        event = 'flex_carscrap:Server:ShowScrapList',
        shouldClose = true
    }, 'flex_carscrap:Server:ShowScrapList')
end

if GetResourceState('ox_inventory') == 'started' then
    exports.ox_inventory:displayMetadata('scrapvehiclelist', Language.info.contractcars)
    exports.ox_inventory:displayMetadata('scrapaccepted', Language.info.scrapregistred)
    exports.ox_inventory:displayMetadata('scrapcontracttype', Language.info.contracttype)
end