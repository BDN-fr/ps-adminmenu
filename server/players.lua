local function getVehicles(cid)
    local vehicles = {}
    if Config.Framework == "QBCore" then
        local result = MySQL.query.await('SELECT vehicle, plate, fuel, engine, body FROM player_vehicles WHERE citizenid = ?', { cid })
        for k, v in pairs(result) do
            local vehicleData = QBCore.Shared.Vehicles[v.vehicle]
            if vehicleData then
                vehicles[#vehicles + 1] = {
                    id = k,
                    cid = cid,
                    label = vehicleData.name,
                    brand = vehicleData.brand,
                    model = vehicleData.model,
                    plate = v.plate,
                    fuel = v.fuel,
                    engine = v.engine,
                    body = v.body
                }
            end
        end
    end
    if Config.Framework == "ESX" then
        local result = MySQL.query.await('SELECT vehicle, plate FROM owned_vehicles WHERE owner = ?', { cid })
        for k, v in pairs(result) do
            local vehicle_mods = json.decode(v.vehicle)
            if vehicle_mods.model then
                local vehicleData = ESX_VehicleHashes[tonumber(vehicle_mods.model)]
                if vehicleData then
                    vehicles[#vehicles + 1] = {
                        id = k,
                        cid = cid,
                        label = vehicleData.name,
                        brand = vehicleData.brand,
                        model = vehicleData.model,
                        plate = v.plate,
                    }
                end
            end
        end
    end
    return vehicles
end

local function getPlayers()
    local players = {}
    if Config.Framework == "QBCore" then
        local GetPlayers = QBCore.Functions.GetQBPlayers()

        for k, v in pairs(GetPlayers) do
            local playerData = v.PlayerData
            local vehicles = getVehicles(playerData.citizenid)

            players[#players + 1] = {
                id = k,
                name = playerData.charinfo.firstname..' '..playerData.charinfo.lastname,
                cid = playerData.citizenid,
                license = QBCore.Functions.GetIdentifier(k, 'license'),
                discord = QBCore.Functions.GetIdentifier(k, 'discord'),
                steam = QBCore.Functions.GetIdentifier(k, 'steam'),
                job = playerData.job.label,
                grade = playerData.job.grade.level,
                dob = playerData.charinfo.birthdate,
                cash = playerData.money.cash,
                bank = playerData.money.bank,
                phone = playerData.charinfo.phone,
                vehicles = vehicles
            }
        end
    end

    if Config.Framework == "ESX" then
        local GetPlayers = ESX.GetExtendedPlayers()
        for k, v in pairs(GetPlayers) do
            local xPlayer = v
            local vehicles = getVehicles(xPlayer.identifier)
            local phone = exports["lb-phone"]:GetEquippedPhoneNumber(xPlayer.source)
            players[#players + 1] = {
                id = xPlayer.source,
                name = xPlayer.getName(),
                cid = xPlayer.identifier,
                license = getMyIdentifier(xPlayer.source, 'license'),
                discord = getMyIdentifier(xPlayer.source, 'discord'),
                steam = getMyIdentifier(xPlayer.source, 'steam'),
                job = xPlayer.getJob().label,
                grade = xPlayer.getJob().grade,
                dob = "Unknown",
                cash = getMoney(xPlayer.source, "money"),
                bank = getMoney(xPlayer.source, "bank"),
                phone = phone or "Unknown",
                vehicles = vehicles
            }
        end
    end

    table.sort(players, function(a, b) return a.id < b.id end)

    return players
end

lib.callback.register('ps-adminmenu:callback:GetPlayers', function(source)
    return getPlayers()
end)

-- Set Job
RegisterNetEvent('ps-adminmenu:server:SetJob', function(data, selectedData)
    local data = CheckDataFromKey(data)
    if not data or not CheckPerms(source, data.perms) then return end
    local src = source
    local playerId, Job, Grade = selectedData["Player"].value, selectedData["Job"].value, selectedData["Grade"].value
    local targetIdentifier = getIdentifier(tonumber(playerId))
    if targetIdentifier then
        setJobGrade(targetIdentifier,Job,Grade)
        local name = getName(tonumber(playerId))
        showNotification(src, locale("jobset", name, Job, Grade), 'success', 5000)
    end
end)

-- Set Gang
RegisterNetEvent('ps-adminmenu:server:SetGang', function(data, selectedData)
    if Config.Framework == "ESX" then return end -- No gangs with ESX
    local data = CheckDataFromKey(data)
    if not data or not CheckPerms(source, data.perms) then return end
    local src = source
    local playerId, Gang, Grade = selectedData["Player"].value, selectedData["Gang"].value, selectedData["Grade"].value
    local Player = QBCore.Functions.GetPlayer(playerId)
    local name = Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname

    showNotification(src, locale("gangset", name, Gang, Grade), 'success', 5000)
    Player.Functions.SetGang(tostring(Gang), tonumber(Grade))
end)

-- Set Perms
RegisterNetEvent("ps-adminmenu:server:SetPerms", function (data, selectedData)
    if not CheckPerms(data.perms) then return end
    local src = source
    local rank = selectedData["Permissions"].value
    local targetId = selectedData["Player"].value
    local tPlayer = getPlayerFromId(tonumber(targetId))
    
    if not tPlayer then
        showNotification(src, locale("not_online"), "error", 5000)
        return
    end
    
    local name = getName(tonumber(targetId))
    if Config.Framework == "QBCore" then
        QBCore.Functions.AddPermission(tPlayer.PlayerData.source, tostring(rank))
    end
    if Config.Framework == "ESX" then
        tPlayer.setGroup(tostring(rank))
    end
    showNotification(tPlayer.PlayerData.source, locale("player_perms", name, rank), 'success', 5000)
end)

-- Remove Stress
RegisterNetEvent("ps-adminmenu:server:RemoveStress", function(data, selectedData)
    if Config.Framework == 'ESX' then return end -- No Stress with ESX
    local data = CheckDataFromKey(data)
    if not data or not CheckPerms(source, data.perms) then return end
    local src = source
    local targetId = selectedData['Player (Optional)'] and tonumber(selectedData['Player (Optional)'].value) or src
    local tPlayer = QBCore.Functions.GetPlayer(tonumber(targetId))

    if not tPlayer then
        QBCore.Functions.Notify(src, locale("not_online"), "error", 5000)
        return
    end

    TriggerClientEvent('ps-adminmenu:client:removeStress', targetId)

    QBCore.Functions.Notify(tPlayer.PlayerData.source, locale("removed_stress_player"), 'success', 5000)
end)