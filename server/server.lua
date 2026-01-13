local QBCore = exports['qb-core']:GetCoreObject()

-- Routing Bucket
RegisterNetEvent("thd_vehicleshop:setBucket", function(bucket)
    SetPlayerRoutingBucket(source, bucket)
end)

-- Araç listesi çekme
RegisterNetEvent("thd_vehicleshop:requestVehicles", function()
    local src = source
    local vehicles, categories = {}, {}
    local locale = Config.Locales[Config.Language] or Config.Locales["en"]

    for model, v in pairs(QBCore.Shared.Vehicles) do
        if v.shop == "pdm" then

            -- Araç listesine ekle
            table.insert(vehicles, {
                model = model,
                label = v.name,
                price = v.price,
                category = v.category
            })

            -- Kategori çevirisi
            local translated = locale.categories and locale.categories[v.category] or v.category
            categories[v.category] = translated
        end
    end

    -- { key = "sports", label = "Spor" } formatına çevir
    local catList = {}
    for key, label in pairs(categories) do
        table.insert(catList, {
            key = key,     -- Orijinal kategori
            label = label  -- Çevrilmiş kategori
        })
    end

    -- Menüye gönder
    TriggerClientEvent("thd_vehicleshop:openShop", src, {
        vehicles = vehicles,
        categories = catList,
        locale = locale
    })
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
    if not Player then return end

    if not model or not price then
        TriggerClientEvent("QBCore:Notify", src, "Araç verisi alınamadı!", "error")
        return
    end

    if not Player.Functions.RemoveMoney("bank", price) then
        TriggerClientEvent("QBCore:Notify", src, "Bankanda yeterli para yok!", "error")
        return
    end

    local plate   = "THD"..math.random(1000, 9999)
    local cid     = Player.PlayerData.citizenid
    local license = Player.PlayerData.license
    
    -- Oyuncunun Ad ve Soyadını alıyoruz
    local firstName = Player.PlayerData.charinfo.firstname
    local lastName = Player.PlayerData.charinfo.lastname
    local fullName = firstName .. " " .. lastName

    -- Satın alınan araç spawn noktası
    local spawn = {
        x = -49.52,
        y = -1111.08,
        z = 26.44,
        w = 78.64
    }

    -- DB'ye kaydet
    MySQL.insert(
        'INSERT INTO thd_garages (license, citizenid, plate, model, fuel, engine, body, x, y, z, w, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            license, cid, plate, model,
            100,    -- fuel
            1000,   -- engine
            1000,   -- body
            spawn.x, spawn.y, spawn.z, spawn.w,
            "out"
        }
    )

    -- Anahtar ver (Metadata Düzenlendi)
    exports.ox_inventory:AddItem(src, 'vehicle_key', 1, {
        plate = plate,
        model = model,
        owner = fullName, -- CitizenID yerine İsim Soyisim yazdırıldı
        -- description alanı ox_inventory'de eşyaya bakınca görünen yazıdır:
        description = "Plaka: " .. plate .. " | Model: " .. model .. " | Sahibi: " .. fullName 
    })
    
    TriggerClientEvent('QBCore:Notify', src, "Araç anahtarı eklendi!", "success")

    -- 🔥 Satın alma client akışını başlat (menu kapatma + spawn tek eventte)
    TriggerClientEvent("thd_vehicleshop:onVehiclePurchased", src, model, plate, spawn)

    TriggerClientEvent("QBCore:Notify", src, "Araç satın alındı!", "success")
end)



-- Test sürüşü

RegisterNetEvent("thd_vehicleshop:testDrive", function(model)
    TriggerClientEvent("thd_vehicleshop:startTestDrive", source, model)
end)

-- ANAHTAR KONTROL
RegisterNetEvent("thd_garages:checkKey", function(plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    local hasKey = false
    local items = exports.ox_inventory:Search(src, 'slots', 'vehicle_key')

    for _, item in pairs(items or {}) do
        if item.metadata and item.metadata.plate == plate then
            hasKey = true
            break
        end
    end

    if not hasKey then
        TriggerClientEvent("thd_garages:forceOut", src)
    end
end)


-- Mağazadan çıkış

local spawnedVehicle = nil

RegisterNetEvent("thd_vehicleshop:closeShop")
AddEventHandler("thd_vehicleshop:closeShop", function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeShop" })

    TriggerEvent("thd_hud:toggle", true)
    StopCam()

    if spawnedVehicle then
        DeleteVehicle(spawnedVehicle)
        spawnedVehicle = nil
    end

    TriggerServerEvent("thd_vehicleshop:setBucket", 0)
end)

