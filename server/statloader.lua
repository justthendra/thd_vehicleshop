local QBCore = exports['qb-core']:GetCoreObject()

VehicleStats = {}

local function generateStat(min, max)
    return math.random(min, max)
end

local function generateVehicleStats(model, category)
    local c = string.lower(category or "")

    if c == "super" then
        return {
            max_speed   = generateStat(260, 330),
            acceleration = generateStat(80, 100),
            braking     = generateStat(60, 100),
            handling    = generateStat(70, 100)
        }
    elseif c == "sports" then
        return {
            max_speed   = generateStat(220, 300),
            acceleration = generateStat(70, 95),
            braking     = generateStat(55, 90),
            handling    = generateStat(60, 95)
        }
    elseif c == "muscle" then
        return {
            max_speed   = generateStat(160, 240),
            acceleration = generateStat(50, 80),
            braking     = generateStat(30, 60),
            handling    = generateStat(30, 60)
        }
    elseif c == "motorcycles" then
        return {
            max_speed   = generateStat(180, 320),
            acceleration = generateStat(70, 100),
            braking     = generateStat(50, 80),
            handling    = generateStat(70, 100)
        }
    else
        return {
            max_speed   = generateStat(140, 220),
            acceleration = generateStat(40, 80),
            braking     = generateStat(40, 80),
            handling    = generateStat(40, 80)
        }
    end
end


CreateThread(function()

    -- DB'den statları çek
    local results = MySQL.query.await("SELECT * FROM thd_vehicle_stats", {})

    for _, row in ipairs(results) do
        VehicleStats[row.model] = {
            max_speed   = row.max_speed,
            acceleration = row.acceleration,
            braking     = row.braking,
            handling    = row.handling
        }
    end

    -- Eksik modeller için stat üret
    for model, veh in pairs(QBCore.Shared.Vehicles) do
        if not VehicleStats[model] then

            local newStats = generateVehicleStats(model, veh.category)
            VehicleStats[model] = newStats

            MySQL.insert.await(
                "INSERT INTO thd_vehicle_stats (model, max_speed, acceleration, braking, handling) VALUES (?, ?, ?, ?, ?)",
                { model, newStats.max_speed, newStats.acceleration, newStats.braking, newStats.handling }
            )

            print("[thd_vehicleshop] Yeni stat oluşturuldu: "..model)
        end
    end

    print("[thd_vehicleshop] Tüm araç statları yüklendi!")
    TriggerClientEvent("thd_vehicleshop:loadStats", -1, VehicleStats)
end)

