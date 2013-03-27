Name
====

lua-resty-redis-lock - Implements a locking primitive using lua-resty-redis

Status
======

This library is considered experimental.

Description
===========

This Lua library Implements a locking primitive using lua-resty-redis:
It is a port to lua of the locking mechanisim in https://github.com/andymccurdy/redis-py

Blocking and Non-Blocking locks
100% nonblocking behavior.

Synopsis
========

    lua_package_path "/path/to/lua-resty-redis-lock/lib/?.lua;;";

    server {
        location /test {
            content_by_lua '
                local redis = require "resty.redis"
                local redislock = require "resty.redis-lock"
                local red = redis:new()

                red:set_timeout(1000) -- 1 sec

                -- or connect to a unix domain socket file listened
                -- by a redis server:
                --     local ok, err = red:connect("unix:/path/to/redis.sock")

                local ok, err = red:connect("127.0.0.1", 6379)
                if not ok then
                    ngx.say("failed to connect: ", err)
                    return
                end

                local lock = redislock:new(red, "foo", true)
                local lock_acquired = lock:acquire()
                if lock_acquired then
                    ngx.say("lock aquired!")
                    return
                end
   
                -- Critical section
 
                local lock_released = lock:release()
                if lock_acquired then
                    ngx.say("lock released!")
                    return
                end
                

                -- put it into the connection pool of size 100,
                -- with 0 idle timeout
                local ok, err = red:set_keepalive(0, 100)
                if not ok then
                    ngx.say("failed to set keepalive: ", err)
                    return
                end

                -- or just close the connection right away:
                -- local ok, err = red:close()
                -- if not ok then
                --     ngx.say("failed to close: ", err)
                --     return
                -- end
            ';
        }
    }

Methods
=======

new
---
`syntax: lock, err = redis-lock:new(redis, key, blocking)`

Creates a lock object. In case of failures, returns `nil` and a string describing the error.
* `blocking`
: Specifies wether or not to block until the lock is aquired, if set to false lock:acquire() will return immediately.

acquire
-------
`syntax: lock_quired = lock:acquire()`


Attempts to obtain a lock, may block or return immediately depending on the options provided to redis-lock:new().

Limitations
===========

* This library cannot be used in code contexts like init_by_lua*, set_by_lua*, log_by_lua*, and
header_filter_by_lua* where the ngx_lua cosocket API is not available.
* Requires a `resty.redis` object instance.

Installation
============


TODO
====



Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2012-2013, by Bearnard Hibbins <bearnard@gmail.com>, Yola Inc.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

See Also
========
* redis-py: https://github.com/andymccurdy/redis-py
* lua-resty-redis: https://github.com/agentzh/lua-resty-redis
* the ngx_lua module: http://wiki.nginx.org/HttpLuaModule
* the redis wired protocol specification: http://redis.io/topics/protocol
* the [lua-resty-memcached](https://github.com/agentzh/lua-resty-memcached) library
* the [lua-resty-mysql](https://github.com/agentzh/lua-resty-mysql) library

