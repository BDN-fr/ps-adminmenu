-- Freeze Player
local frozen = false
RegisterNetEvent('ps-adminmenu:server:FreezePlayer', function(data, selectedData)
    local data = CheckDataFromKey(data)
    if not data or not CheckPerms(source, data.perms) then return end
    local src = source

    local target = selectedData["Player"].value

    local ped = GetPlayerPed(target)
    local Player = QBCore.Functions.GetPlayer(target)

    if not frozen then
        frozen = true
        FreezeEntityPosition(ped, true)
        showNotification(src, locale("Frozen", fullName .. " | " .. identifier), 'Success', 7500)
    else
        frozen = false
        FreezeEntityPosition(ped, false)
        showNotification(src, locale("deFrozen", fullName .. " | " .. identifier), 'Success', 7500)

    end
    if Player == nil then return showNotification(src, locale("not_online"), 'error', 7500) end
end)

-- Drunk Player
RegisterNetEvent('ps-adminmenu:server:DrunkPlayer', function(data, selectedData)
    local data = CheckDataFromKey(data)
    if not data or not CheckPerms(source, data.perms) then return end

    local src = source
    local target = selectedData["Player"].value
    local Player = getPlayerFromId(target)

    if not Player then
        return showNotification(src, locale("not_online"), 'error', 7500)
    end

    TriggerClientEvent('ps-adminmenu:client:InitiateDrunkEffect', target)
    showNotification(src,
        locale("playerdrunk",
            Player.PlayerData.charinfo.firstname ..
            " " .. Player.PlayerData.charinfo.lastname .. " | " .. Player.PlayerData.citizenid), 'Success', 7500)
end)
