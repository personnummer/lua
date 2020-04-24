local function mod(n,d)
    return n - d*math.floor(n/d)
end

-- The Luhn algorithm.
local function luhn(str)
    local sum = 0

    for i = 1, #str do
        local v = string.byte(str:sub(i,i)) - string.byte("0")

        if i % 2 == 1 then
            v = v * 2
        end

        if v > 9 then
            v = v - 9
        end

        sum = sum + v
    end

    return (math.ceil(sum/10) * 10) - sum
end

-- Test if the input parameters are a valid date or not.
local function testDate(year, month, day)
    local y = tonumber(year)
    local m = tonumber(month)
    local dd = tonumber(day)
    local t = os.time{year=y,month=m,day=dd}
    local d = os.date("*t", t)
    return d.year == y and d.month == m and d.day == dd
end

local Personnummer = {}

do
    -- Personnummer constructor.
    function Personnummer:new(pin)
        self.__index = self

        local p = setmetatable({}, self)
        p:parse(pin)

        if not p:valid() then
            error("Invalid swedish personal identity number")
        end

        return p
    end

    -- Format a Swedish personal identity as one of the official formats,
    -- a long format or a short format.
    function Personnummer:format(long)
        if long then
            return self.century .. self.year .. self.month .. self.day .. self.num .. self.check
        end

        return self.year .. self.month .. self.day .. self.sep .. self.num .. self.check
    end

    -- Get age from a Swedish personal identity.
    function Personnummer:get_age()
        local age_day = self.day

        if self:is_coordination_number() then
            age_day = tostring(tonumber(age_day - 60))
        end

        local t = os.time{year=self.fullYear,month=self.month,day=age_day}
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

    function Personnummer:is_coordination_number()
        return testDate(self.fullYear,self.month, tostring(tonumber(self.day)-60))
    end

    -- Check if a Swedish personal identity number is for a female.
    function Personnummer:is_female()
        return self:is_male() == false
    end

    -- Check if a Swedish personal identity number is for a male.
    function Personnummer:is_male()
        local sexDigit = tonumber(string.sub(self.num, 3, 3))
        return sexDigit % 2 == 1
    end

    -- Parse Swedish personal identity number.
    function Personnummer:parse(pin)
        local plus = string.match(pin, "+")

        self.sep = "-"

        pin = string.gsub(pin,"+", "")
        pin = string.gsub(pin, "-", "")

        if string.len(pin) == 12 then
            self.century = string.sub(pin, 1, 2)
            self.year = string.sub(pin, 3,4)
            self.month = string.sub(pin, 5, 6)
            self.day = string.sub(pin, 7, 8)
            self.num = string.sub(pin, 9, 11)
            self.check = string.sub(pin, 12, 12)
        elseif string.len(pin) == 10 then
            self.century = ""
            self.year = string.sub(pin, 0, 2)
            self.month = string.sub(pin, 3, 4)
            self.day = string.sub(pin, 5, 6)
            self.num = string.sub(pin, 7, 9)
            self.check = string.sub(pin, 10, 10)
        end

        if self.century == "" then
            local baseYear = tonumber(os.date("%Y"))
            local year = tonumber(self.year)

            if plus then
                self.sep = "+"
                baseYear = baseYear - 100
            end

            self.century = string.sub(tostring((baseYear - ((baseYear - year) % 100))), 0, 2)
        end

        self.fullYear = self.century .. self.year
    end

    -- Check if Swedish personal identity number is valid or not.
    function Personnummer:valid()
        local valid = luhn(self.year .. self.month .. self.day .. self.num) == tonumber(self.check)

        if valid and testDate(self.fullYear,self.month,self.day) then
            return true
        end

        return valid and testDate(self.fullYear,self.month, tostring(tonumber(self.day)-60))
    end
end

return {
    -- Personnummer constructor.
    new = function(pin)
        return Personnummer:new(pin)
    end,
    -- Parse Swedish personal identity number.
    parse = function(pin)
        return Personnummer:new(pin)
    end,
    -- Check if Swedish personal identity number is valid or not.
    valid = function(pin)
        local status = pcall(function(pin)
            return Personnummer:new(pin)
        end,pin)
        return status
    end
}