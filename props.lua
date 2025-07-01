local tireIni = ac.INIConfig.carData(ac.getCar(0).index, 'tyres.ini')
local tireName = ac.getCar(0):tyresLongName():gsub('%s?%b()', '')

--- Retrieves a property value for a given tire name in a given section.
---@param sectionName string @The section to look in.
---@param propertyName string @The property to get.
---@return any @The property value for the given tire name in the given section.
local function getTireProperty(sectionName, propertyName)
    for index, section in tireIni:iterate(sectionName, true) do
        if tireIni:get(section, 'NAME', nil)[1] == tireName then
            return tireIni:get(section, propertyName, 'string')
        end
    end
end

--- Retrieves the optimal pressures for the front and rear tires.
---@return number frontPressure @The optimal pressure for the front tires.
---@return number rearPressure @The optimal pressure for the rear tires.
function GetOptPressure()
    local frontPressure = getTireProperty('FRONT', 'PRESSURE_IDEAL')
    local rearPressure = getTireProperty('REAR', 'PRESSURE_IDEAL')
    return frontPressure, rearPressure
end