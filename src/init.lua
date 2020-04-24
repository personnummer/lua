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
    function Personnummer:new(pin)
        self.__index = self

        local p = setmetatable({}, self)
        p:parse(pin)

        if not p:valid() then
            error("Invalid swedish personal identity number")
        end

        return p
    end

    function Personnummer:format(long)
        if long then
            return self.century .. self.year .. self.month .. self.day .. self.num .. self.check
        end

        return self.year .. self.month .. self.day .. self.sep .. self.num .. self.check
    end

    function Personnummer:is_female()
        return self:is_male() == false
    end

    function Personnummer:is_male()
        local sexDigit = tonumber(string.sub(self.num, 3, 3))
        return sexDigit % 2 == 1
    end

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

    function Personnummer:valid()
        local valid = luhn(self.year .. self.month .. self.day .. self.num) == tonumber(self.check)

        if valid and testDate(self.fullYear,self.month,self.day) then
            return true
        end

        return valid and testDate(self.fullYear,self.month, tostring(tonumber(self.day)-60))
    end
end

return {
    new = function(pin)
        return Personnummer:new(pin)
    end,
    parse = function(pin)
        return Personnummer:new(pin)
    end,
    valid = function(pin)
        local status = pcall(function(pin)
            return Personnummer:new(pin)
        end,pin)
        return status
    end
}