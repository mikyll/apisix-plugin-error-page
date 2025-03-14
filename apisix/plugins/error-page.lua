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
local ngx           = ngx
local apisix_plugin = require("apisix.plugin")
local core          = require("apisix.core")
local utils         = require("apisix.core.utils")

local plugin_name   = "error-page"


local schema = {
  type = "object",
  properties = {
    pages = {
      description = "List of custom pages",
      type = "array",
      minItems = 1,
      uniqueItems = true,
      items = {
        description = "Page to display for a list of status codes",
        type = "object",
        properties = {
          status_codes = {
            description =
            "List of status codes for a specific page. Status codes in this list take precedence over the ones in status_range",
            type = "array",
            minItems = 1,
            uniqueItems = true,
            items = {
              type = "integer",
              minimum = 200,
              maximum = 599,
            }
          },
          status_range = {
            description = "Range (inclusive) of status codes for a specific page",
            type = "object",
            properties = {
              min = {
                type = "integer",
                default = 200,
                minimum = 200,
                maximum = 598,
              },
              max = {
                type = "integer",
                default = 599,
                minimum = 201,
                maximum = 599,
              },
              additionalProperties = false,
            },
          },
          page_content = {
            description =
            "String representing the response APISIX must send. Can contain NGiNX variables (https://nginx.org/en/docs/http/ngx_http_core_module.html#variables)",
            type = "string",
          },
          page_filepath = {
            description =
            "Path of a file containing the response APISIX must send. Can contain NGiNX variables (https://nginx.org/en/docs/http/ngx_http_core_module.html#variables)",
            type = "string",
          },
          response_headers = {
            description = "extra headers for response",
            {
              type = "object",
              minProperties = 1,
              patternProperties = {
                ["^[^:]+$"] = {
                  oneOf = {
                    { type = "string" },
                    { type = "number" }
                  }
                },
              },
            },
          },
        },
        additionalProperties = false,
      },
    },
    required = { "pages" },
    additionalProperties = false,
  },
}

local metadata_schema = {
  type = "object",
  properties = {
    response_headers = {
      description = "default headers to be included in every response",
      {
        type = "object",
        patternProperties = {
          ["^[^:]+$"] = {
            oneOf = {
              { type = "string" },
              { type = "number" }
            }
          },
        },
      },
    }
  },
}


local _M = {
  version = 0.1,
  priority = 0,
  name = plugin_name,
  schema = schema,
  metadata_schema = metadata_schema,
}


local function read_all(file)
  local f = assert(io.open(file, "rb"))
  local content = f:read("*all")
  f:close()
  return content
end

function _M.check_schema(conf, schema_type)
  core.log.info("input conf for " .. tostring(schema_type) .. ": ", core.json.delay_encode(conf))

  if schema_type == core.schema.TYPE_METADATA then
    return core.schema.check(metadata_schema, conf)
  end

  -- Validate config parameters
  for i, value in ipairs(conf.pages) do
    if value.status_codes and value.status_range then
      core.log.error("Cannot set both status_codes and status_range, they are mutually exclusive")
      return false, "Cannot set both status_codes and status_range, they are mutually exclusive"
    end

    -- to fix (if one of min or max is not defined, here there's no default value yet)
    -- if value.status_range then
    --   if value.status_range.min >= value.status_range.max then
    --     core.log.error("status_range.min must be lower than status_range.max")
    --     return false, "status_range.min must be lower than status_range.max"
    --   end
    -- end

    if not value.page_content and not value.page_filepath then
      core.log.error("Must set one of page_content or page_filepath")
      return false, "Must set one of page_content or page_filepath"
    end

    if value.page_content and value.page_filepath then
      core.log.error("Cannot set both page_content and page_filepath, they are mutually exclusive")
      return false, "Cannot set both page_content and page_filepath, they are mutually exclusive"
    end

    if value.page_filepath then
      local res, _ = pcall(read_all, value.page_filepath)
      if not res then
        core.log.error("File not found: " .. value.page_filepath)
        return false, "File not found: " .. value.page_filepath
      end

      -- Load the page from file
      conf.pages[i].page_content = read_all(value.page_filepath)
      conf.pages[i].page_filepath = nil
    end
  end

  -- Order pages: status_codes > status_range
  table.sort(conf.pages, function(a, b)
    -- If 'a' has status_codes and 'b' has status_range, 'a' should come first
    if a.status_codes and b.status_range then
      return true
    end
    -- Otherwise, maintain the original order
    return false
  end)

  return core.schema.check(schema, conf)
end

function _M.header_filter(conf, ctx)
  local error_page, error_headers
  local pages = conf.pages

  -- Loop over pages to check if there's a status_code that matches
  for _, page in ipairs(pages) do
    if page.status_codes then
      for _, status in ipairs(page.status_codes) do
        -- Status code matches
        if ngx.status == status then
          error_page = page.page_content
        end
      end
    elseif page.status_range then
      if ngx.status >= page.status_range.min and
          ngx.status <= page.status_range.max then
        error_page = page.page_content
      end
    end

    if error_page then
      error_headers = page.response_headers
      break
    end
  end

  if error_page then
    -- Set shared headers for every error-page plugin instance
    local metadata = apisix_plugin.plugin_metadata(plugin_name)
    if metadata and metadata.value.response_headers then
      core.log.warn("metadata: ", core.json.delay_encode(metadata))
      core.log.warn("type: ", type(metadata.value.response_headers))
      for key, value in pairs(metadata.value.response_headers) do
        ngx.header[key] = value
      end
    end

    -- Set specific headers for the single error-page plugin instance
    if error_headers then
      for key, value in pairs(error_headers) do
        ngx.header[key] = value
      end
    end

    -- Set body (and parse NGiNX vars)
    error_page = utils.resolve_var(error_page, ctx.var)
    ngx.header['Content-Length'] = #error_page
    ctx.error_page = error_page
  end
end

function _M.body_filter(conf, ctx)
  if ctx.error_page then
    local body = core.response.hold_body_chunk(ctx)

    -- We don't send a response until we've read all chunks
    if ngx.arg[2] == false and not body then
      return
    end

    -- We've read the last chunk, so we can return the response
    ngx.arg[1] = ctx.error_page
    ctx.error_page = nil
  end
end

return _M
