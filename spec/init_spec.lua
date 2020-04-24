require "busted"

local Personnummer = require('personnummer')

local name = "spec/list.json"
local function readall(filename)
    local fh = assert(io.open(filename, "rb"))
    local contents = assert(fh:read("a")) -- "a" in Lua 5.3; "*a" in Lua 5.1 and 5.2
    fh:close()
    return contents
end

local fileContent = readall(name)

local lunajson = require("dkjson")
local testList = lunajson.decode(fileContent)
local availableListFormats = {"integer","long_format","short_format","separated_format","separated_long"}

local function mod(n,d)
    return n - d*math.floor(n/d)
end

local get_expected_age = function(item)
    local year = string.sub(item.separated_long, 1,4)
    local month = string.sub(item.separated_long, 5, 6)
    local day = string.sub(item.separated_long, 7, 8)

    if type == "con" then
        day = tostring(tonumber(day - 60))
    end

    local t = os.time{year=year,month=month,day=day}
    local d = os.date("*t", t)
    local n = os.date("*t", os.time())

    local years = n.year - d.year
    local days = os.difftime(os.time(), t) / (3600 * 24 * 1000)
    local totalDays = 365

    if math.abs(t) > os.time() then
        years = years - 1
    end

    -- leap year
    if (mod(years, 4) == 0 and (mod(years, 100) ~= 0 or mod(years, 400) == 0)) then
        totalDays = 366
    end

    return math.floor(years + days / totalDays)
end

describe("Personnummer tests", function ()
    it("Should validate personnummer", function ()
        for _, item in pairs(testList) do
            for _, format in pairs(availableListFormats) do
                assert.are.same(item.valid, Personnummer.valid(item[format]))
            end
        end
    end)
    it("Should test personnummer formatting", function ()
        for _, item in pairs(testList) do
            for _, format in pairs(availableListFormats) do
                if not format == "short_format" and not string.match(item[format], "+") then
                    local p = Personnummer.parse(item[format])
                    assert.are.same(item.separated_format, p:format())
                    assert.are.same(item.long_format, p:format(true))
                end
            end
        end
    end)
    it("Should catch personnummer errors", function ()
        for _, item in pairs(testList) do
            if not item.valid then
                for _, format in pairs(availableListFormats) do
                    local status, res = pcall(function(pin)
                        return Personnummer.parse(item[format])
                    end)
                    assert.falsy(status)
                    assert.are.same("string", type(res))
                end
            end
        end
    end)
    it("Should test personnummer sex", function ()
        for _, item in pairs(testList) do
            if item.valid then
                for _, format in pairs(availableListFormats) do
                    local p = Personnummer.parse(item[format])
                    assert.are.same(item.isMale, p:is_male())
                    assert.are.same(item.isFemale, p:is_female())
                end
            end
        end
    end)
    it("Should test personnummer age", function ()
        for _, item in pairs(testList) do
            if item.valid then
                local expected_age = get_expected_age(item)
                for _, format in pairs(availableListFormats) do
                    if not format == "short_format" and not string.match(item[format], "+") then
                        local p = Personnummer.parse(item[format])
                        assert.are.same(expected_age, p.get_age())
                    end
                end
            end
        end
    end)
end)