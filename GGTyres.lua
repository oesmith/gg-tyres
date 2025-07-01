require('gg/props')

local NUM_SAMPLES = 100

local buffer = {
    ---@type number[] Front left tyre pressures
    frontLeft = table.new(NUM_SAMPLES, 0),
    ---@type number[] Front right tyre pressures
    frontRight = table.new(NUM_SAMPLES, 0),
    ---@type number[] Rear left tyre pressures
    rearLeft = table.new(NUM_SAMPLES, 0),
    ---@type number[] Rear right tyre pressures
    rearRight = table.new(NUM_SAMPLES, 0),
    ---@type number Spline position index of the last sample
    lastIndex = -1,
}

---@class TyreMetric
---@field min number minimum tyre pressure
---@field max number maximum tyre pressure
---@field avg number average tyre pressure
---@field p90 number 90th percentile tyre pressure

---@return TyreMetric
local function newTyreMetric()
    return {
        min = 0,
        max = 0,
        avg = 0,
        p90 = 0,
    }
end

--- Cached aggregate data to show in the UI.
--- Only re-calculated when there's new data to show.
local metrics = {
    ---@type TyreMetric Front left tyre metrics
    frontLeft = newTyreMetric(),
    ---@type TyreMetric Front right tyre metrics
    frontRight = newTyreMetric(),
    ---@type TyreMetric Rear left tyre metrics
    rearLeft = newTyreMetric(),
    ---@type TyreMetric Rear right tyre metrics
    rearRight = newTyreMetric(),
    ---@type number Front optimal tyre pressure
    frontOptimal = 0,
    ---@type number Rear optimal tyre pressure
    rearOptimal = 0,
}

---@param samples number[]
---@param metric TyreMetric
local function tyrePressureAgg(samples, metric)
    if table.nkeys(samples) ~= NUM_SAMPLES then
        return
    end
    local ps = table.clone(samples)
    table.sort(ps)
    metric.min = ps[1]
    metric.max = ps[NUM_SAMPLES]
    ---@diagnostic disable-next-line:missing-parameter
    metric.avg = table.sum(ps) / NUM_SAMPLES
    metric.p90 = ps[math.floor(NUM_SAMPLES * 0.9)]
end

local function updateUiData()
    tyrePressureAgg(buffer.frontLeft, metrics.frontLeft)
    tyrePressureAgg(buffer.frontRight, metrics.frontRight)
    tyrePressureAgg(buffer.rearLeft, metrics.rearLeft)
    tyrePressureAgg(buffer.rearRight, metrics.rearRight)
    metrics.frontOptimal, metrics.rearOptimal = GetOptPressure()
end

--- Logs tyre pressure data.
--- @param car ac.StateCar
local function logTyres(car)
    -- don't log samples in the pits, because tyre blankets will throw off the stats
    if (not car.isActive) or car.isInPit or car.isRetired or car.isInPitlane then
        return
    end

    local idx = 1 + math.floor(car.splinePosition * NUM_SAMPLES)
    if idx == buffer.lastIndex then
        return
    end

    if buffer.lastIndex >= 0 and idx - buffer.lastIndex > 1 then
        ac.log(string.format('Discontinuity - %d -> %d', buffer.lastIndex, idx))
    end

    buffer.frontLeft[idx] = car.wheels[0].tyrePressure
    buffer.frontRight[idx] = car.wheels[1].tyrePressure
    buffer.rearLeft[idx] = car.wheels[2].tyrePressure
    buffer.rearRight[idx] = car.wheels[3].tyrePressure
    buffer.lastIndex = idx

    if idx == NUM_SAMPLES then
        updateUiData()
        table.clear(buffer.frontLeft)
        table.clear(buffer.frontRight)
        table.clear(buffer.rearLeft)
        table.clear(buffer.rearRight)
    end
end

---@param name string
---@param metric TyreMetric
---@param opt number
local function drawTyre(name, metric, opt)
    ui.text(name)
    ui.nextColumn()
    ui.text(string.format("%.1f", metric.min))
    ui.nextColumn()
    ui.text(string.format("%.1f", metric.avg))
    ui.nextColumn()
    ui.text(string.format("%.1f", metric.p90))
    ui.nextColumn()
    ui.text(string.format("%.1f", metric.max))
    ui.nextColumn()
    ui.text(string.format("%.1f", opt))
    ui.nextColumn()
    ui.text(string.format("%+d", math.floor(opt - metric.p90)))
    ui.separator()
    ui.nextColumn()
end

function script.setupMain(dt)
    ui.pushFont(ui.Font.Title)
    ui.text("Tyre Pressures")
    ui.popFont()

    ui.offsetCursorY(8)

    ui.childWindow('table', vec2(360, 120), function()
        ui.columns(7)

        ui.text("Tyre")
        ui.nextColumn()
        ui.text("Min.")
        ui.nextColumn()
        ui.text("Av.")
        ui.nextColumn()
        ui.text("90%")
        ui.nextColumn()
        ui.text("Max.")
        ui.nextColumn()
        ui.text("Opt.")
        ui.nextColumn()
        ui.text("Rec.")

        ui.separator()
        ui.nextColumn()

        drawTyre('FL', metrics.frontLeft, metrics.frontOptimal)
        drawTyre('FR', metrics.frontRight, metrics.frontOptimal)
        drawTyre('RL', metrics.rearLeft, metrics.rearOptimal)
        drawTyre('RR', metrics.rearRight, metrics.rearOptimal)

        ui.columns(1)
    end)
end

function script.update(dt)
    local car = ac.getCar(0)
    if car ~= nil then
        logTyres(car)
    end
end
