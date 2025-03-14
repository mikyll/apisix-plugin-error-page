<div align="center">

[![APISIX][apisix-shield]][apisix-url]
[![NGINX][nginx-shield]][nginx-url]
[![Lua][lua-shield]][lua-url]
[![Perl][perl-shield]][perl-url]
[![YAML][yaml-shield]][yaml-url]\
[![Build Status][build-status-shield]][build-status-url]

# APISIX Error-page Custom Plugin

This plugin allows APISIX to send a custom response based on status codes received by backend or APISIX itself. For example, it can be used to override default APISIX responses.

</div>

- Route not found error (status code `404`):
    
    ```json
    {"error_msg":"404 Route Not Found"}
    ```

- Generic gateway errors (status code `5xx`), such as:

    ```html
    <html>
    <head><title>504 Gateway Time-out</title>
    </head>
    <body>
    <center><h1>504 Gateway Time-out</h1></center>
    <hr><center>openresty</center>
    <p><em>Powered by <a href="https://apisix.apache.org/">APISIX</a>.</em></p></body>
    </html>
    ```

## Table of Contents

- [APISIX Error-page Custom Plugin](#apisix-error-page-custom-plugin)
  - [Table of Contents](#table-of-contents)
  - [Plugin Usage](#plugin-usage)
    - [Installation](#installation)
    - [Configuration](#configuration)
      - [Attributes](#attributes)
      - [Metadata](#metadata)
    - [Enable Plugin](#enable-plugin)
      - [Traditional](#traditional)
      - [Standalone](#standalone)
    - [Example Usage](#example-usage)
  - [Testing](#testing)
    - [CI](#ci)
  - [Examples](#examples)
    - [Standalone Example](#standalone-example)
      - [Setup](#setup)
      - [Test Routes](#test-routes)
  - [Learn More](#learn-more)

## Plugin Usage

### Installation

To install custom plugins in APISIX there are 2 methods:

- placing them alongside other built-in plugins, in `${APISIX_INSTALL_DIRECTORY}/apisix/plugins/` (by default `/usr/local/apisix/apisix/plugins/`);
- placing them in a custom directory and setting `apisix.extra_lua_path` to point that directory, in `config.yaml`.

The [example below](#examples) shows how to setup the plugin in a Standalone deployment, using the second method (`extra_lua_path`).

### Configuration

You can configure this plugin for [Routes](https://apisix.apache.org/docs/apisix/terminology/route/) or [Global Rules](https://apisix.apache.org/docs/apisix/terminology/global-rule/).

#### Attributes

| Name | Type | Required | Default | Valid values | Description |
| ---- | ---- | -------- | ------- | ------------ | ----------- |
| pages | array[object] | True |  |  | List of custom pages |
| pages.status_codes | array[integer] | False |  | [200, 599] | List of status codes for a specific page. Status codes in this list take precedence over the ones in status_range |
| pages.status_range | array[object] | False |  |  | Range (inclusive) of status codes for a specific page |
| pages.status_range.min | array[object] | False | 200 | [200, 598] | Minimum status code for the page |
| pages.status_range.max | array[object] | False | 599 | [201, 599] | Maximum status code for the page |
| pages.response_content | string | False |  |  | Content of the page that APISIX will return for the status codes. Value supports [NGiNX variables](https://nginx.org/en/docs/http/ngx_http_core_module.html#variables) |
| pages.response_filepath | string | False |  |  | File path of the page that APISIX will return for the status codes. Value supports [NGiNX variables](https://nginx.org/en/docs/http/ngx_http_core_module.html#variables) |
| pages.response_headers | object | False |  |  | Dictionary of headers to be included in APISIX response, for a specific plugin instance. Example: `Content-Type: text/html` |

#### Metadata

| Name | Type | Required | Default | Valid values | Description |
| ---- | ---- | -------- | ------- | ------------ | ----------- |
| response_headers | object | False |  | Valid values | Dictionary of headers to be included in APISIX response, for all plugin instances. Example: `Content-Type: text/html` |

> [!IMPORTANT]
> Plugin metadata set global values, shared accross all plugin instances. For example, if we have 2 different routes with `error-page` plugin enabled, `plugin_metadata` values will be the same for both of them.

[Back to TOC](#table-of-contents)

### Enable Plugin

The examples below enable `error-page` plugin globally. With these configurations, APISIX will return a custom error message for status codes between `400` and `450`.

#### Traditional

```bash
curl http://127.0.0.1:9180/apisix/admin/global_rules/1  -H "X-API-KEY: $admin_key" -X PUT -d '
{
  "plugins": {
    "error-page": {
      "pages": [
        {
          "status_range": {
            "min": 400,
            "max": 450
          },
          "response_headers": {
            "Content-Type": "application/json"
          },
          "response_content": "{\"error_msg\": \"$status Server Error\"}"
        }
      ]
    }
  }
}'
```

#### Standalone

```yaml
global_rules:
  - id: error_page
    plugins:
      error-page:
        pages:
          - status_range:
              min: 400
              max: 450
            response_headers:
              content_type: "application/json"
            response_content: |
              {"error_msg": "$status Server Error"}
```

### Example Usage

Once you have enabled the Plugin as shown above, you can make a request:

```bash
curl -X GET "http://127.0.0.1:9080/test/index.html"
```

The response will be as shown below:

```json
{"error_msg": "404 Server Error"}
```

Instead of the default `404` error message:

```json
{"error_msg":"404 Route Not Found"}
```

[Back to TOC](#table-of-contents)

## Testing

### CI

TODO

The [`ci.yml`](.github/workflows/ci.yml) workflow runs the tests cases in the [`t/`](t/) folder and can be triggered by a **workflow_dispatch** event, from GitHub: [Actions | CI](https://github.com/mikyll/apisix-plugin-template/actions/workflows/ci.yml).

[Back to TOC](#table-of-contents)

## Examples

Folder [`examples/`](examples/) contains a simple example that shows how to setup APISIX locally on Docker, and load `error-page` plugin.

For more example ideas, have a look at [github.com/mikyll/apisix-examples](https://github.com/mikyll/apisix-examples).

### Standalone Example

#### Setup

See [`apisix.yaml`](examples/apisix-docker-standalone/conf/apisix.yaml).

Run the following command to setup the example:

```bash
docker compose -f examples/apisix-docker-standalone/compose.yaml up
```

#### Test Routes

Visit the following URLs:

- HTML **page content**, with [*NGiNX variables*](https://nginx.org/en/docs/http/ngx_http_core_module.html#variables) substitution, for backend errors (`400` - `450`):
  - [`localhost:9080/status/400`](http://localhost:9080/status/400)
  - [`localhost:9080/status/402`](http://localhost:9080/status/402)
  
- HTML page loaded **from file**, for backend errors (`5xx`):
  - [`localhost:9080/status/500`](http://localhost:9080/status/500)
  - [`localhost:9080/status/505`](http://localhost:9080/status/505)
  - [`localhost:9080/status/506`](http://localhost:9080/status/506)

- Simple **JSON** response for specific backend error (`403`): [`localhost:9080/status/403`](http://localhost:9080/status/403)

- HTML page with **CSS** for APISIX error route not found (`404`): [`localhost:9080/unknown_route`](http://localhost:9080/unknown_route)

[Back to TOC](#table-of-contents)

## Learn More

- [APISIX Source Code](https://github.com/apache/apisix)
- [APISIX Deployment Modes](https://apisix.apache.org/docs/apisix/deployment-modes/)
- [Developing custom APISIX plugins](https://apisix.apache.org/docs/apisix/plugin-develop)
- [APISIX testing framework](https://apisix.apache.org/docs/apisix/internal/testing-framework)
- [APISIX debug mode](https://apisix.apache.org/docs/apisix/debug-mode/)
- [NGiNX variables](https://nginx.org/en/docs/http/ngx_http_core_module.html#variables)
- [APISIX Examples](https://github.com/mikyll/apisix-examples)

<!-- GitHub Shields -->

[apisix-shield]: https://custom-icon-badges.demolab.com/badge/APISIX-grey.svg?logo=apisix_logo
[apisix-url]: https://apisix.apache.org/
[nginx-shield]: https://img.shields.io/badge/Nginx-%23009639.svg?logo=nginx
[nginx-url]: https://nginx.org/en/
[lua-shield]: https://img.shields.io/badge/Lua-%232C2D72.svg?logo=lua&logoColor=white
[lua-url]: https://www.lua.org/
[perl-shield]: https://img.shields.io/badge/Perl-%2339457E.svg?logo=perl&logoColor=white
[perl-url]: https://www.perl.org/
[yaml-shield]: https://img.shields.io/badge/YAML-%23ffffff.svg?logo=yaml&logoColor=151515
[yaml-url]: https://yaml.org/
[build-status-shield]: https://github.com/mikyll/apisix-error-page/actions/workflows/ci.yml/badge.svg
[build-status-url]: https://github.com/mikyll/apisix-plugin-error-page/actions
