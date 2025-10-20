local ScrapList, Contracts, Plates = {}, {}, {}

local function DeleteCarFromList(source, car)
    local src = source
    local player = GetPlayer(src)
    local citizenid = player.license or player.PlayerData.citizenid
    for i, model in ipairs(ScrapList[citizenid]) do
        if model == car then
            table.remove(ScrapList[citizenid], i)
            break
        end
    end
end

local function DeleteFromContract(source, car)
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    local citizenid = player.license or player.PlayerData.citizenid
    if not Contracts[citizenid] then return end

    for k, v in pairs(Config.ScrapVehicles) do
        local contractLists = Contracts[citizenid][k]
        if contractLists then
            for contractIndex, contractList in ipairs(contractLists) do
                for carIndex, model in ipairs(contractList) do
                    if model == car then
                        table.remove(contractList, carIndex)
                        if #contractList == 0 then
                            table.remove(contractLists, contractIndex)
                            local reward = Config.ContractRewards[k][math.random(1, #Config.ContractRewards[k])]
                            if reward.item == 'cash' or reward.item == 'money' or reward.item == 'bank' or reward.item == 'crypto' then
                                AddMoney(src, reward.item, reward.amount, Language.success.contractreward)
                            else
                                AddItem(src, reward.item, reward.amount, reward.info, nil)
                            end
                        end
                        return
                    end
                end
            end
        end
    end
end

local function GetRandomVehicles(contractType, count)
    local vehicles = Config.ScrapVehicles[contractType:lower()]
    if not vehicles then return {} end

    local shuffled = {}
    for i = 1, #vehicles do
        shuffled[i] = vehicles[i]
    end

    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    local result = {}
    for i = 1, math.min(count, #shuffled) do
        table.insert(result, shuffled[i])
    end

    return result
end

lib.callback.register("flex_carscrap:Server:GetScrapList", function(source, id)
    local src = id or source
    local player = GetPlayer(src)
    if not player then return false end
    local citizenid = player.license or player.PlayerData.citizenid
    if not citizenid then return false end
    return ScrapList[citizenid]
end)

lib.callback.register("flex_carscrap:Server:IsPlateRegistered", function(source, id)
    for i, plate in ipairs(Plates) do
        if plate == id then
            return true
        end
    end
    return false
end)

RegisterServerEvent("flex_carscrap:Server:RegisterPlate", function(plate)
    Plates[#Plates+1] = plate
end)

RegisterServerEvent("flex_carscrap:Server:RemovePlate", function(id)
    for i, plate in ipairs(Plates) do
        if plate == id then
            table.remove(Plates, i)
            return
        end
    end
end)

RegisterServerEvent("flex_carscrap:Server:BreakDoor", function(vehicle, id)
    TriggerClientEvent('flex_carscrap:Client:BreakDoor', -1, vehicle, id)
end)

RegisterServerEvent("flex_carscrap:Server:BreakTyre", function(vehicle, bone)
    TriggerClientEvent('flex_carscrap:Client:BreakTyre', -1, vehicle, bone)
end)

RegisterServerEvent("flex_carscrap:Server:GiveItem", function(bone)
    local src = source
    if string.find(bone, "wheel") then
        AddItem(src, 'vehicle_wheel', 1, nil)
    elseif string.find(bone, "door") then
        AddItem(src, 'vehicle_door', 1, nil)
    elseif string.find(bone, "bonnet") then
        AddItem(src, 'vehicle_hood', 1, nil)
    elseif string.find(bone, "boot") then
        AddItem(src, 'vehicle_trunk', 1, nil)
    end
end)

RegisterServerEvent("flex_carscrap:Server:SellItem", function()
    local src = source
    local items = {'vehicle_wheel', 'vehicle_door', 'vehicle_hood', 'vehicle_trunk'}
    for k, item in pairs(items) do
        if HasInvGotItem(src, 'count', item, nil, 1) then
            if RemoveItem(src, item, 1, nil, nil) then
                if Config.Reward[item].item == 'cash' or Config.Reward[item].item == 'bank' or Config.Reward[item].item == 'crypto' then
                    AddMoney(src, Config.Reward[item].item, Config.Reward[item].amount, Language.success.soldpartbank)
                else
                    AddItem(src, Config.Reward[item].item, Config.Reward[item].amount, Config.Reward[item].info)
                end
            end
        end
    end
end)

RegisterServerEvent("flex_carscrap:Server:RegisterContract", function(cars, id, contract)
    local src = id or source
    local player = GetPlayer(src)
    if not player then return end
    local citizenid = player.license or player.PlayerData.citizenid
    if not citizenid then return end
    if not ScrapList[citizenid] then
        ScrapList[citizenid] = {}
    end
    if not Contracts[citizenid] then
        Contracts[citizenid] = {}
    end
    if not Contracts[citizenid][contract] then
        Contracts[citizenid][contract] = {}
    end
    Contracts[citizenid][contract][#Contracts[citizenid][contract]+1] = {}
    local contractList = Contracts[citizenid][contract][#Contracts[citizenid][contract]]
    for k, v in pairs(cars) do
        ScrapList[citizenid][#ScrapList[citizenid]+1] = GetHashKey(v)
        contractList[#contractList+1] = GetHashKey(v)
    end
    TriggerClientEvent('flex_carscrap:Client:UpdateScrapList', src, ScrapList[citizenid])
end)

RegisterServerEvent("flex_carscrap:Server:Disconnect", function(car)
    DeleteCarFromList(source, car)
    DeleteFromContract(source, car)
end)

RegisterServerEvent("flex_carscrap:Server:FinishContract", function(car)
    DeleteCarFromList(source, car)
    DeleteFromContract(source, car)
end)

RegisterServerEvent("flex_carscrap:Server:ForceDeleteVehicle", function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle and DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end
end)

RegisterServerEvent("flex_carscrap:Server:GiveContract", function(id, contract, amount)
    if not contract then contract = Config.DefaultContract.type[math.random(1, #Config.DefaultContract.type)] end
    while amount > #Config.ScrapVehicles[contract] do
        amount -= 1
        Wait(500)
    end
    local src = source
    if id then src = id end
    if not amount then amount = Config.DefaultContract.amount end
    local RandomVehicles = GetRandomVehicles(contract, amount)
    local list = {}
    for _, vehicle in ipairs(RandomVehicles) do
        local name = lib.callback.await('flex_carscrap:Client:GetVehicleDisplayName', src, GetHashKey(vehicle))
        table.insert(list, '\n' .. name:upper()..' - ')
    end
    AddItem(src, Config.ContractItem, 1, {scrapcars = RandomVehicles, scrapvehiclelist = table.concat(list), scrapcontracttype = contract, scrapregistred = false, scrapaccepted = Language.info.scrapnotaccepted})
end)

function GiveContract(src, contract, amount)
    TriggerEvent('flex_carscrap:Server:GiveContract', src, contract, amount)
end
exports('GiveContract', GiveContract)

lib.addCommand('givecontract', {
    help =  'Give player a contract',
	restricted = 'group.admin',
	params = {
        { name = 'id', help = 'ID of player', type = 'playerId'},
        { name = 'contract', help = 'Type of contract', type = 'string'},
        { name = 'amount', help = 'Amount of cars in the contract', type = 'number'},
    }
}, function(source, args)
	if not args.id then args.id = source end
    if not args.contract or not Config.ScrapVehicles[args.contract:lower()] then args.contract = 'c' end
    if not args.amount then args.amount = 1 end
	local player = GetPlayer(args.id)
	if not player then
		Config.Notify.server(source, Language.info.invalidplayer, 'info', 5000)
		return
	end
    TriggerEvent('flex_carscrap:Server:GiveContract', args.id, args.contract, args.amount)
end)

if Config.ScrapListCommand then
    lib.addCommand(Config.ScrapListCommand, {
        help = Language.command.scraplist,
    }, function(source, args, raw)
        local src = source
        local player = GetPlayer(src)
        if not player then return false end
        local citizenid = player.license or player.PlayerData.citizenid
        if not citizenid then return false end
        TriggerClientEvent('flex_carscrap:Client:ShowScrapList', source, ScrapList[citizenid])
    end)
else
    RegisterServerEvent("flex_carscrap:Server:ShowScrapList", function()
        local src = source
        local player = GetPlayer(src)
        if not player then return false end
        local citizenid = player.license or player.PlayerData.citizenid
        if not citizenid then return false end
        TriggerClientEvent('flex_carscrap:Client:ShowScrapList', source, ScrapList[citizenid])
    end)
end

function GenerateScrapMeta(src)
    local contract = Config.DefaultContract.type[math.random(1, #Config.DefaultContract.type)]
    local RandomVehicles = GetRandomVehicles(contract, Config.DefaultContract.amount)
    local list = {}
    for _, vehicle in ipairs(RandomVehicles) do
        local name = lib.callback.await('flex_carscrap:Client:GetVehicleDisplayName', src, GetHashKey(vehicle))
        table.insert(list, '\n' .. name:upper()..' - ')
    end
    return {scrapcars = RandomVehicles, scrapvehiclelist = table.concat(list), scrapcontracttype = contract, scrapregistred = false, scrapaccepted = Language.info.scrapnotaccepted}
end
exports('GenerateScrapMeta', GenerateScrapMeta)

if GetResourceState(Config.CoreName.qbx) == 'started' then
    exports.qbx_core:CreateUseableItem(Config.ContractItem, function(source, item)
        local src = source
        local itemslot = GetItemBySlot(src, item.slot)
        local contract = Config.DefaultContract.type[math.random(1, #Config.DefaultContract.type)]
        if itemslot.metadata.scrapregistred then return Config.Notify.server(src, Language.info.contractalreadydone, 'info', 5000) end
        if not itemslot then return end
        if not item.metadata then return end
        if not item.metadata.scrapcontracttype then
            item.metadata.scrapcontracttype = contract
        end
        if not item.metadata.scrapcars then item.metadata.scrapcars = GetRandomVehicles(contract, Config.DefaultContract.amount) end
        TriggerEvent('flex_carscrap:Server:RegisterContract', item.metadata.scrapcars, src, item.metadata.scrapcontracttype)
        RemoveItem(src, Config.ContractItem, 1, item.metadata, item.slot)
        AddItem(src, Config.ContractItem, 1, {scrapcars = item.metadata.scrapcars, scrapvehiclelist = item.metadata.scrapvehiclelist, scrapcontracttype = item.metadata.scrapcontracttype, scrapregistred = true, scrapaccepted = Language.info.scrapaccepted} , item.slot)
    end)
    return
elseif GetResourceState(Config.CoreName.qb) == 'started' then
    local QBCore = exports[Config.CoreName.qb]:GetCoreObject()
    QBCore.Functions.CreateUseableItem(Config.ContractItem, function(source, item)
        local src = source
        local itemslot = GetItemBySlot(src, item.slot)
        local contract = Config.DefaultContract.type[math.random(1, #Config.DefaultContract.type)]
        if itemslot.metadata.scrapregistred then return Config.Notify.server(src, Language.info.contractalreadydone, 'info', 5000) end
        if not itemslot then return end
        if not item.metadata then return end
        if not item.metadata.scrapcontracttype then item.metadata.scrapcontracttype = contract end
        if not item.metadata.scrapcars then item.metadata.scrapcars = GetRandomVehicles(contract, Config.DefaultContract.amount) end
        TriggerEvent('flex_carscrap:Server:RegisterContract', item.metadata.scrapcars, src, item.metadata.scrapcontracttype)
        RemoveItem(src, Config.ContractItem, 1, item.metadata, item.slot)
        AddItem(src, Config.ContractItem, 1, {scrapcars = item.metadata.scrapcars, scrapvehiclelist = item.metadata.scrapvehiclelist, scrapcontracttype = item.metadata.scrapcontracttype, scrapregistred = true, scrapaccepted = Language.info.scrapaccepted} , item.slot)
    end)
    return
elseif GetResourceState(Config.CoreName.esx) == 'started' then
    local ESX = exports[Config.CoreName.esx]:getSharedObject()
    ESX.RegisterUsableItem(Config.ContractItem, function(source)
        local src = source
        local contract = Config.DefaultContract.type[math.random(1, #Config.DefaultContract.type)]
        local scrapList = GetRandomVehicles(contract, Config.DefaultContract.amount)
        TriggerEvent('flex_carscrap:Server:RegisterContract', scrapList, src, contract)
        RemoveItem(src, Config.ContractItem, 1, nil, nil)
        AddItem(src, Config.ContractItem, 1, {scrapcars = scrapList, scrapvehiclelist = scrapList, scrapcontracttype = contract, scrapregistred = true, scrapaccepted = Language.info.scrapaccepted} , nil)
    end)
    return
elseif GetResourceState(Config.CoreName.ox_inv) == 'started' and GetResourceState(Config.CoreName.qbx) ~= 'started' then
    AddEventHandler('ox_inventory:usedItem', function(source, name, slotId, metadata)
        if name:lower() == Config.ContractItem:lower() then
            local src = source
            local contract = Config.DefaultContract.type[math.random(1, #Config.DefaultContract.type)]
            if metadata.scrapregistred then return Config.Notify.server(src, Language.info.contractalreadydone, 'info', 5000) end
            if not slotId then return end
            if not metadata then return end
            if not metadata.scrapcontracttype then metadata.scrapcontracttype = contract end
            if not metadata.scrapcars then metadata.scrapcars = GetRandomVehicles(contract, Config.DefaultContract.amount) end
            TriggerEvent('flex_carscrap:Server:RegisterContract', metadata.scrapcars, src, metadata.scrapcontracttype)
            RemoveItem(src, Config.ContractItem, 1, metadata, slotId)
            AddItem(src, Config.ContractItem, 1, {scrapcars = metadata.scrapcars, scrapvehiclelist = metadata.scrapvehiclelist, scrapcontracttype = metadata.scrapcontracttype, scrapregistred = true, scrapaccepted = Language.info.scrapaccepted} , slotId)
        end
    end)
    return
end