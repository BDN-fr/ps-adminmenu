-- Clear Inventory
RegisterNetEvent('ps-adminmenu:server:ClearInventory', function(data, selectedData)
    local data = CheckDataFromKey(data)
    if not data or not CheckPerms(data.perms) then return end

    local src = source
    local player = selectedData["Player"].value
    local Player = getPlayerFromId(src)

    if not Player then
        return showNotification(source, locale("not_online"), 'error', 7500)
    end

    if Config.Inventory == 'ox_inventory' then
        exports.ox_inventory:ClearInventory(player)
    else
        exports[Config.Inventory]:ClearInventory(player, nil)
    end

    showNotification(src,
        locale("invcleared", Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname),
        'success', 7500)
end)

-- Clear Inventory Offline
RegisterNetEvent('ps-adminmenu:server:ClearInventoryOffline', function(data, selectedData)
    local data = CheckDataFromKey(data)
    if not data or not CheckPerms(source, data.perms) then return end

    local src = source
    if Config.Framework == 'QBCore' then
        local citizenId = selectedData["Citizen ID"].value
        local Player = QBCore.Functions.GetPlayerByCitizenId(citizenId)
    
        if Player then
            if Config.Inventory == 'ox_inventory' then
                exports.ox_inventory:ClearInventory(Player.PlayerData.source)
            else
                exports[Config.Inventory]:ClearInventory(Player.PlayerData.source, nil)
            end
            showNotification(src,
                locale("invcleared", Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname),
                'success', 7500)
        else
            MySQL.Async.fetchAll("SELECT * FROM players WHERE citizenid = @citizenid", { ['@citizenid'] = citizenId },
                function(result)
                    if result and result[1] then
                        MySQL.Async.execute("UPDATE players SET inventory = '{}' WHERE citizenid = @citizenid",
                            { ['@citizenid'] = citizenId })
                        showNotification(src, "Player's inventory cleared", 'success', 7500)
                    else
                        showNotification(src, locale("player_not_found"), 'error', 7500)
                    end
                end)
        end
    end
    if Config.Framework == "ESX" then
        local identifier = selectedData["Citizen ID"].value
        local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
    
        if xPlayer then
            if Config.Inventory == 'ox_inventory' then
                exports.ox_inventory:ClearInventory(xPlayer.source)
            else
                exports[Config.Inventory]:ClearInventory(xPlayer.source, nil)
            end
            showNotification(src,
                locale("invcleared", Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname),
                'success', 7500)
        else
            MySQL.Async.fetchAll("SELECT * FROM users WHERE identifier = @identifier", { ['@identifier'] = identifier },
                function(result)
                    if result and result[1] then
                        MySQL.Async.execute("UPDATE users SET inventory = '{}' WHERE identifier = @identifier",
                            { ['@identifier'] = identifier })
                            showNotification(src, "Player's inventory cleared", 'success', 7500)
                    else
                        showNotification(src, locale("player_not_found"), 'error', 7500)
                    end
                end)
        end
    end
end)

-- Open Inv [ox side]
RegisterNetEvent('ps-adminmenu:server:OpenInv', function(data)
    exports.ox_inventory:forceOpenInventory(source, 'player', data)
end)

-- Open Stash [ox side]
RegisterNetEvent('ps-adminmenu:server:OpenStash', function(data)
    exports.ox_inventory:forceOpenInventory(source, 'stash', data)
end)

-- Open Trunk [ox side]
RegisterNetEvent('ps-adminmenu:server:OpenTrunk', function(data)
    exports.ox_inventory:forceOpenInventory(source, 'trunk', data)
end)

-- Give Item
RegisterNetEvent('ps-adminmenu:server:GiveItem', function(data, selectedData)
    local data = CheckDataFromKey(data)
    if not data or not CheckPerms(source, data.perms) then return end

    local target = selectedData["Player"].value
    local item = selectedData["Item"].value
    local amount = selectedData["Amount"].value
    local Player = getPlayerFromId(target)

    if not item or not amount then return end
    if not Player then
        return showNotification(source, locale("not_online"), 'error', 7500)
    end
    addItem(target,item,amount)
    local fullName = getName(target)
    showNotification(source, locale("give_item", tonumber(amount) .. " " .. item, fullName), "success", 7500)
end)

-- Give Item to All
RegisterNetEvent('ps-adminmenu:server:GiveItemAll', function(data, selectedData)
    local data = CheckDataFromKey(data)
    if not data or not CheckPerms(source, data.perms) then return end
    local src = source
    local item = selectedData["Item"].value
    local amount = selectedData["Amount"].value
    local players = getAllPlayers()

    if not item or not amount then return end
    for _, Player in pairs(players) do
        if Config.Framework == "QBCore" then
            addItem(Player.PlayerData.source,item,amount)
        end
        if Config.Framework == "ESX" then
            addItem(Player.source,item,amount)
        end
    end
    showNotification(src, locale("give_item_all", amount .. " " .. item), "success", 7500)
end)
