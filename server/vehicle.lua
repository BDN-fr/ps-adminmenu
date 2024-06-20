-- Admin Car
RegisterNetEvent('ps-adminmenu:server:SaveCar', function(mods, vehicle, _, plate)
    local src = source
    local Player = getPlayerFromId(src)
    if Config.Framework == "QBCore" then
        local result = MySQL.query.await('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
        if result[1] == nil then
            MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                Player.PlayerData.license,
                Player.PlayerData.citizenid,
                vehicle.model,
                vehicle.hash,
                json.encode(mods),
                plate,
                0
            })
            showNotification(src, locale("veh_owner"), 'success', 5000)
        else
            showNotification(src, locale("u_veh_owner"), 'error', 3000)
        end
    end
    if Config.Framework == "ESX" then
        local result = MySQL.query.await('SELECT plate FROM owned_vehicles WHERE plate = ?', {plate})
        if result[1] == nil then
            MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, stored) VALUES (?, ?, ?, ?)', {
                Player.getIdentifier(),
                plate,
                json.encode(mods),
                0
            })
            showNotification(src, locale("veh_owner"), 'success', 5000)
        else
            showNotification(src, locale("u_veh_owner"), 'error', 3000)
        end
    end
end)

-- Give Car
RegisterNetEvent("ps-adminmenu:server:givecar", function(data, selectedData)
    local src = source

    local data = CheckDataFromKey(data)
    if not data or not CheckPerms(source, data.perms) then
        showNotification(src, locale("no_perms"), "error", 5000)
        return
    end

    local vehmodel = selectedData['Vehicle'].value
    local vehicleData = lib.callback.await("ps-adminmenu:client:getvehData", src, vehmodel)

    if not next(vehicleData) then
        return
    end

    local tsrc = selectedData['Player'].value
    local plate = selectedData['Plate (Optional)'] and selectedData['Plate (Optional)'].value or vehicleData.plate
    local garage = selectedData['Garage (Optional)'] and selectedData['Garage (Optional)'].value or Config.DefaultGarage
    local Player = getPlayerFromId(tsrc)

    if plate and #plate < 1 then
        plate = vehicleData.plate
    end

    if garage and #garage < 1 then
        garage = Config.DefaultGarage
    end

    if plate:len() > 8 then
        showNotification(src, locale("plate_max"), "error", 5000)
        return
    end

    if not Player then
        showNotification(src, locale("not_online"), "error", 5000)
        return
    end

    if CheckAlreadyPlate(plate) then
        showNotification(src, locale("givecar.error.plates_alreadyused", plate:upper()), "error", 5000)
        return
    end

    if Config.Framework == 'QBCore' then
        MySQL.insert(
            'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                {
                    Player.PlayerData.license,
                    Player.PlayerData.citizenid,
                    vehmodel,
                    joaat(vehmodel),
                    json.encode(vehicleData),
                    plate,
                    garage,
                    1
                })
        showNotification(src,
            locale("givecar.success.source", QBCore.Shared.Vehicles[vehmodel].name,
                ("%s %s"):format(Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname)), "success", 5000)
        showNotification(Player.PlayerData.source, locale("givecar.success.target", plate:upper(), garage), "success",
            5000)
    end

    if Config.Framework == "ESX" then
        MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, stored) VALUES (?, ?, ?, ?)', {
            Player.getIdentifier(),
            plate,
            json.encode(vehicleData),
            0
            })
        showNotification(src,
            locale("givecar.success.source", ESX_VehicleHashes[vehmodel].name,
                ("%s %s"):format(Player.firstname, Player.lastname)), "success", 5000)
    end
end)

-- Give Car
RegisterNetEvent("ps-adminmenu:server:SetVehicleState", function(data, selectedData)
    if Config.Framework == 'ESX' then return end

    local src = source

    local data = CheckDataFromKey(data)
    if not data or not CheckPerms(source, data.perms) then
        showNotification(src, locale("no_perms"), "error", 5000)
        return
    end

    local plate = string.upper(selectedData['Plate'].value)
    local state = tonumber(selectedData['State'].value)

    if plate:len() > 8 then
        showNotification(src, locale("plate_max"), "error", 5000)
        return
    end

    if not CheckAlreadyPlate(plate) then
        showNotification(src, locale("plate_doesnt_exist"), "error", 5000)
        return
    end

    if Config.Framework == 'QBCore' then
        MySQL.update('UPDATE player_vehicles SET state = ?, depotprice = ? WHERE plate = ?', { state, 0, plate })
    end
    if Config.Framework == 'ESX' then
        if state ~= 1 then
            showNotification(src, 'For impound, state must be 1')
            return
        end
        MySQL.update('UPDATE owned_vehicles SET impound = ? WHERE plate = ?', { state, plate })
    end

    showNotification(src, locale("state_changed"), "success", 5000)
end)

-- Change Plate
RegisterNetEvent('ps-adminmenu:server:ChangePlate', function(newPlate, currentPlate)
    local newPlate = newPlate:upper()

    if Config.Inventory == 'ox_inventory' then
        exports.ox_inventory:UpdateVehicle(currentPlate, newPlate)
    end
    if Config.Framework == "QBCore" then
        MySQL.Sync.execute('UPDATE player_vehicles SET plate = ? WHERE plate = ?', {newPlate, currentPlate})
        MySQL.Sync.execute('UPDATE trunkitems SET plate = ? WHERE plate = ?', {newPlate, currentPlate})
        MySQL.Sync.execute('UPDATE gloveboxitems SET plate = ? WHERE plate = ?', {newPlate, currentPlate})
    end
    if Config.Framework == "ESX" then
        MySQL.Sync.execute('UPDATE owned_vehicles SET plate = ? WHERE plate = ?', {newPlate, currentPlate})
    end
end)

lib.callback.register('ps-adminmenu:getVehicleData', function(source, plate)
    local vehData = {}
    if Config.Framework == "QBCore" then
        local res = MySQL.query.await('SELECT (mods, vehicle) FROM player_vehicles WHERE plate = ?', {plate})
        vehData = res[1] or {}
        if vehData and vehData['mods'] then
            vehData['mods'] = json.decode(vehData['mods'])
        end
    end
    if Config.Framework == "ESX" then
        local res = MySQL.query.await('SELECT vehicle FROM owned_vehicles WHERE plate = ?', {plate})
        vehData = res[1] or {}
        if vehData and vehData['vehicle'] then
            vehData['mods'] = json.decode(vehData['vehicle'])
            vehData['vehicle'] = vehData['mods'].model
        end
    end
    return vehData
end)

lib.callback.register('ps-adminmenu:spawnVehicle', function(source, model, coords, warp)
    local ped = GetPlayerPed(source)
    model = type(model) == 'string' and joaat(model) or model
    if not coords then coords = GetEntityCoords(ped) end
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, true, true)
    while not DoesEntityExist(veh) do Wait(0) end
    if warp then
        while GetVehiclePedIsIn(ped) ~= veh do
            Wait(0)
            TaskWarpPedIntoVehicle(ped, veh, -1)
        end
    end
    while NetworkGetEntityOwner(veh) ~= source do Wait(0) end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    return netId
end)

-- lib.callback.register('ps-adminmenu:server:GetVehicleByPlate', function(source, plate)
--     local result = {}
--     MySQL.query.await('SELECT vehicle FROM player_vehicles WHERE plate = ?', {plate})
--     local veh = result[1] and result[1].vehicle or {}
--     return veh
-- end)

-- Fix Vehicle for player
RegisterNetEvent('ps-adminmenu:server:FixVehFor', function(data, selectedData)
    local data = CheckDataFromKey(data)
    if not data or not CheckPerms(source, data.perms) then return end
    local src = source
    local playerId = tonumber(selectedData['Player'].value)
    if Config.Framework == 'QBCore' then
        local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
        if Player then
            local name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
            TriggerClientEvent('iens:repaira', Player.PlayerData.source)
            TriggerClientEvent('vehiclemod:client:fixEverything', Player.PlayerData.source)
            showNotification(src, locale("veh_fixed", name), 'success', 7500)
        else
            showNotification(src, locale("not_online"), "error")
        end
    end
    if Config.Framework == "ESX" then
        local ped = GetPlayerPed(playerId)
        local pedVehicle = GetVehiclePedIsIn(ped, false)
        if not pedVehicle or GetPedInVehicleSeat(pedVehicle, -1) ~= ped then
            showError(TranslateCap("not_in_vehicle"))
            return
        end
        TriggerClientEvent("esx:repairPedVehicle", playerId)
        showNotification(src, locale("veh_fixed", name), 'success', 7500)
        if src ~= playerId then
            showNotification(xTarget.source, locale("veh_fixed", name), 'success', 7500)
        end
    end
end)
