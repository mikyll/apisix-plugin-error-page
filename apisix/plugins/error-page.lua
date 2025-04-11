--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

local plugin_name        = "error-page"
local plugin_description = [[
This plugin allows to return a custom error page,
overriding APISIX/OpenResty defaults.
]]
local plugin_author      = {
  username = "mikyll",
  url = "https://github.com/mikyll",
}


local ngx           = ngx
local core          = require("apisix.core")
local apisix_plugin = require("apisix.plugin")
local apisix_utils  = require("apisix.core.utils")


local metadata_schema = {
  type = "object",
  additionalProperties = false,
  anyOf = {
    { required = { "error_404" } },
    { required = { "error_500" } },
    { required = { "error_502" } },
    { required = { "error_503" } },
  },
  properties = {
    id = plugin_name,
    enable = {
      description = "If true, enable the plugin.",
      type = "boolean",
      default = false,
    },
    error_404 = {
      description = "Error page to return when APISIX returns 404 status codes.",
      type = "object",
      additionalProperties = false,
      properties = {
        body = {
          description = "Response body.",
          type = "string",
          default =
          "<html> <head><title>404 Not Found</title></head> <body> <center><h1>404 Not Found</h1></center> <hr><center>APISIX</center> </html>",
        },
        ["content-type"] = {
          description = "Response content type.",
          type = "string",
          default = "text/html",
        },
      },
    },
    error_500 = {
      description = "Error page to return when APISIX returns 500 status codes.",
      type = "object",
      additionalProperties = false,
      properties = {
        body = {
          description = "Response body.",
          type = "string",
          default =
          "<html> <head><title>500 Internal Server Error</title></head> <body> <center><h1>500 Internal Server Error</h1></center> <hr><center>APISIX</center> </html>",
        },
        ["content-type"] = {
          description = "Response content type.",
          type = "string",
          default = "text/html",
        },
      },
    },
    error_502 = {
      description = "Error page to return when APISIX returns 502 status codes.",
      type = "object",
      additionalProperties = false,
      properties = {
        body = {
          description = "Response body.",
          type = "string",
          default =
          "<html> <head><title>502 Bad Gateway</title></head> <body> <center><h1>502 Bad Gateway</h1></center> <hr><center>APISIX</center> </html>",
        },
        ["content-type"] = {
          description = "Response content type.",
          type = "string",
          default = "text/html",
        },
      },
    },
    error_503 = {
      description = "Error page to return when APISIX returns 503 status codes.",
      type = "object",
      additionalProperties = false,
      properties = {
        body = {
          description = "Response body.",
          type = "string",
          default =
          "<html> <head><title>503 Service Unavailable</title></head> <body> <center><h1>503 Service Unavailable</h1></center> <hr><center>APISIX</center> </html>",
        },
        ["content-type"] = {
          description = "Response content type.",
          type = "string",
          default = "text/html",
        },
      },
    },
  },
}

local schema          = {
  type = "object",
  properties = {},
}

local _M              = {
  version = 1.0,
  priority = 0,
  name = plugin_name,
  schema = schema,
  metadata_schema = metadata_schema,
  description = plugin_description,
  author = plugin_author,
}


local function make_response(error)
  local response = {}
  response.body = error.body
  response.headers = { ["Content-Type"] = error["content-type"] }
  return response
end

function _M.check_schema(conf, schema_type)
  if schema_type == core.schema.TYPE_METADATA then
    return core.schema.check(metadata_schema, conf)
  end

  return true
end

function _M.header_filter(_, ctx)
  local custom_response
  local metadata = apisix_plugin.plugin_metadata(plugin_name)
  if not metadata or not metadata.value.enable then
    return
  end

  -- Return custom error page only if upstream didn't respond
  if ngx.var.upstream_status then
    return
  end

  if ngx.status == 404 and metadata.value.error_404 then
    custom_response = make_response(metadata.value.error_404)
  end

  if ngx.status == 500 and metadata.value.error_500 then
    custom_response = make_response(metadata.value.error_500)
  end

  if ngx.status == 502 and metadata.value.error_502 then
    custom_response = make_response(metadata.value.error_502)
  end

  if ngx.status == 503 and metadata.value.error_503 then
    custom_response = make_response(metadata.value.error_503)
  end

  -- This means a condition was triggered and we set a custom page
  if custom_response then
    -- header manipulation must be performed in header_filter phase
    if custom_response.headers then
      for key, value in pairs(custom_response.headers) do
        ngx.header[key] = value
      end
    end

    -- Parse NGiNX variables
    custom_response.body = apisix_utils.resolve_var(custom_response.body, ngx.var)

    -- Set Content-Length header before body_phase
    ngx.header['Content-Length'] = #(custom_response.body)

    ctx.error_page_response_body = custom_response.body
  end
end

function _M.body_filter(conf, ctx)
  if ctx.error_page_response_body then
    local body = core.response.hold_body_chunk(ctx)

    -- Don't send a response until we've read all chunks
    if ngx.arg[2] == false and not body then
      return
    end

    -- Last chunk was read, so we can return the response
    ngx.arg[1] = ctx.error_page_response_body
    ctx.error_page_response_body = nil
  end
end

return _M
