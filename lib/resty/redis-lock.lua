-- Copyright (C) 2013 Bearnard Hibbins


local null = ngx.null
local sleep = ngx.sleep
local now = ngx.now
local log = ngx.log
local NOTICE = ngx.NOTICE
local ERR = ngx.ERR
local math = require "math"
local setmetatable = setmetatable
local tonumber = tonumber
local error = error


module(...)

_VERSION = '0.1'


local mt = { __index = _M }


function new(self, redis, key, blocking)
    if not redis then
        return nil, "no redis supplied"
    end
    return setmetatable({ redis = redis, key = key, blocking = blocking }, mt)
end

function acquire(self)

    local sleep_time = 0.2
    local timeout = 2
    self.acquired_until = nil
    
    while true do
        local unixtime = math.floor(now())
        local timeout_at = unixtime + timeout
        
        local ok, err = self.redis:setnx(self.key, timeout_at)
        
        if ok == 1 then
            self.acquired_until = timeout_at
            return true
        end

        local existing, err = self.redis:get(self.key)
        
        if (not existing) or existing == null then
            existing = 1
        else
            existing = tonumber(existing)
        end

        if existing < unixtime then
            existing = self.redis:getset(self.key, timeout_at)
            if (not existing) or existing == null then
                existing = 1
            else
                existing = tonumber(existing) 
            end
            if existing < unixtime then
                self.acquired_until = timeout_at
                return true
            end
        end
            
        if not self.blocking then
            return false
        end
        log(ERR, "WAITING FOR LOCK")
        sleep(sleep_time)
    end
end

function release(self)
    if not self.acquired_until then
        return false
    end
    local okget, err = self.redis:get(self.key)
    local existing = 1
    if (not okget) or okget == null then
        existing = 1
    else
        existing = tonumber(okget)
    end
    
    if existing >= self.acquired_until then
        local ok, err = self.redis:del(self.key)
        if ok then
            return true
        end
    end
    return false
end

local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}


setmetatable(_M, class_mt)

