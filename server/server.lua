local QBCore = exports['qb-core']:GetCoreObject()

-- Routing Bucket
RegisterNetEvent("thd_vehicleshop:setBucket", function(bucket)
    SetPlayerRoutingBucket(source, bucket)
end)

-- Araç listesi çekme
RegisterNetEvent("thd_vehicleshop:requestVehicles", function()
    local src = source
    local vehicles, categories = {}, {}

    for model, v in pairs(QBCore.Shared.Vehicles) do
        if v.shop == "pdm" then
            table.insert(vehicles, {
                model = model,
                label = v.name,
                price = v.price,
                category = v.category
            })
            categories[v.category] = true
        end
    end

    local catList = {}
    for c,_ in pairs(categories) do
        table.insert(catList, c)
    end

    TriggerClientEvent("thd_vehicleshop:openMenu", src, vehicles, catList)
end)

-- Kategori filtresi
RegisterNetEvent("thd_vehicleshop:requestCategory", function(category)
    local src = source
    local list = {}

    for model, v in pairs(QBCore.Shared.Vehicles) do
        if v.shop == "pdm" and (category == "all" or category == v.category) then
            table.insert(list, {
                model = model,
                label = v.name,
                price = v.price,
                category = v.category
            })
        end
    end

    TriggerClientEvent("thd_vehicleshop:updateVehicles", src, list)
end)

-- Araç satın alma
RegisterNetEvent("thd_vehicleshop:buyVehicle", function(model, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.Functions.RemoveMoney("bank", price) then
        local plate = "THD"..math.random(1000,9999)
        local cid = Player.PlayerData.citizenid
        local license = Player.PlayerData.license

        local spawn = {
            x = -49.32,
            y = -1111.79,
            z = 26.44,
            w = 82.14
        }

        MySQL.insert(
            'INSERT INTO thd_garages (license, citizenid, plate, model, fuel, engine, body, x, y, z, w, stored, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            { 
                license, 
                cid, 
                plate, 
                model, 
                100,     -- fuel
                1000,    -- engine
                1000,    -- body
                spawn.x, 
                spawn.y, 
                spawn.z, 
                spawn.w, 
                0,       -- stored = 0 (dışarıda)
                "out" 
            }
        )

        -- 🔑 Aracın anahtarını oyuncuya ver
        Player.Functions.AddItem("vehicle_key", 1, false, {
            plate = plate,
            model = model,
            owner = cid
        })
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["vehiclekey"], "add")
        TriggerClientEvent("thd_vehicleshop:spawnPurchasedVehicle", src, model, plate, spawn)
        TriggerClientEvent("QBCore:Notify", src, "Araç satın alındı! Anahtar verildi.", "success")
    else
        TriggerClientEvent("QBCore:Notify", src, "Bankanda yeterli para yok!", "error")
    end
end)

RegisterNetEvent("thd_vehicleshop:testDrive", function(model)
    TriggerClientEvent("thd_vehicleshop:startTestDrive", source, model)
end)

RegisterNetEvent("thd_garages:checkKey", function(plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    local hasKey = false

    for slot, item in pairs(Player.PlayerData.items or {}) do
        if item.name == "vehiclekey" then
            if item.info and item.info.plate == plate then
                hasKey = true
                break
            end
        end
    end

    if not hasKey then
        TriggerClientEvent("thd_garages:forceOut", src)
    end
end)
