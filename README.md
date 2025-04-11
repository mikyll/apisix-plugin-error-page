<div align="center">

[![APISIX][apisix-shield]][apisix-url]
[![NGINX][nginx-shield]][nginx-url]
[![Lua][lua-shield]][lua-url]
[![Perl][perl-shield]][perl-url]
[![YAML][yaml-shield]][yaml-url]\
[![Build Status][build-status-shield]][build-status-url]

# APISIX Plugin error-page

This custom plugin allows APISIX to return a custom error page for status codes `404`, `500`, `502` and `503`.

For example, it allows to replace the default response for 404:

```json
{"error_msg":"404 Route Not Found"}
```

</div>

## Table of Contents

- [APISIX Plugin error-page](#apisix-plugin-error-page)
  - [Table of Contents](#table-of-contents)
  - [Plugin Usage](#plugin-usage)
    - [Installation](#installation)
    - [Configuration](#configuration)
      - [Plugin Metadata](#plugin-metadata)
    - [Enable Plugin](#enable-plugin)
      - [Traditional](#traditional)
      - [Standalone](#standalone)
    - [Example Usage](#example-usage)
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

[Back to TOC](#table-of-contents)

### Configuration

This plugin can be configured for [Routes](https://apisix.apache.org/docs/apisix/terminology/route/) or [Global Rules](https://apisix.apache.org/docs/apisix/terminology/global-rule/).

#### Plugin Metadata

| Name                   | Type    | Required | Default                                                                                                                                                       | Valid values | Description                                                |
| ---------------------- | ------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ | ---------------------------------------------------------- |
| enable                 | boolean | False    | `false`                                                                                                                                                       |              | If true, enable the plugin.                                |
| error_404              | object  | False    |                                                                                                                                                               |              | Error page to return when APISIX returns 404 status codes. |
| error_404.body         | string  | False    | `<html> <head><title>404 Not Found</title></head> <body> <center><h1>404 Not Found</h1></center> <hr><center>APISIX</center> </html>`                         |              | Response body.                                             |
| error_404.content-type | string  | False    | `text/html`                                                                                                                                                   |              | Response content type.                                     |
| error_500              | object  | False    |                                                                                                                                                               |              | Error page to return when APISIX returns 500 status codes. |
| error_500.body         | string  | False    | `<html> <head><title>500 Internal Server Error</title></head> <body> <center><h1>500 Internal Server Error</h1></center> <hr><center>APISIX</center> </html>` |              | Response body.                                             |
| error_500.content-type | string  | False    | `text/html`                                                                                                                                                   |              | Response content type.                                     |
| error_502              | object  | False    |                                                                                                                                                               |              | Error page to return when APISIX returns 502 status codes. |
| error_502.body         | string  | False    | `<html> <head><title>502 Bad Gateway</title></head> <body> <center><h1>502 Bad Gateway</h1></center> <hr><center>APISIX</center> </html>`                     |              | Response body.                                             |
| error_502.content-type | string  | False    | `text/html`                                                                                                                                                   |              | Response content type.                                     |
| error_503              | object  | False    |                                                                                                                                                               |              | Error page to return when APISIX returns 503 status codes. |
| error_503.body         | string  | False    | `<html> <head><title>503 Service Unavailable</title></head> <body> <center><h1>503 Service Unavailable</h1></center> <hr><center>APISIX</center> </html>`     |              | Response body.                                             |
| error_503.content-type | string  | False    | `text/html`                                                                                                                                                   |              | Response content type.                                     |

> [!IMPORTANT]
> Plugin metadata set global values, shared accross all plugin instances. For example, if we have 2 different routes with `error-page` plugin enabled, `plugin_metadata` values will be the same for both of them.

### Enable Plugin

The examples below enable `error-page` plugin globally. With these configurations, APISIX will return a custom error message for status codes `404` and `500`, on every route (even on undefined ones).

#### Traditional

Configure the plugin metadata:

```bash
curl http://127.0.0.1:9180/apisix/admin/plugin_metadata/error-page  -H "X-API-KEY: $admin_key" -X PUT -d '
{
  "enable": true,
  "error_404": {
    "body": "{\"status_code\":404,\"error\":\"Not Found\"}",
    "content-type": "application/json"
  },
  "error_500": {
    "body": "{\"status_code\":500,\"error\":\"API Gateway Error\"}",
    "content-type": "application/json"
  },
}'
```

Enable the plugin globally, using global rules:

```bash
curl http://127.0.0.1:9180/apisix/admin/global_rules/error-page  -H "X-API-KEY: $admin_key" -X PUT -d '
{
  "plugins": {
    "error-page": {}
  }
}'
```

#### Standalone

Configure the plugin metadata:

```yaml
plugin_metadata:
  - id: error-page
    enable: true
    error_404:
      body: |
        {
          "status_code": 404,
          "error": "Not Found"
        }
      content-type: "application/json"
    error_500:
      body: |
        {
          "status_code": 500,
          "error": "API Gateway Error"
        }
      content-type: "application/json"
```

Enable the plugin globally, using global rules:

```yaml
global_rules:
  - id: generic_error_page
    plugins:
      error-page: {}
```

### Example Usage

Send some request to test error pages:

- Route not defined (overrides default error page for 404):

  ```bash
  curl -i "localhost:9080/unknown"
  ```

  Response:

  ```bash
  HTTP/1.1 404 Not Found
  Content-Type: application/json
  Connection: keep-alive
  Server: APISIX/3.12.0
  Content-Length: 49

  {
    "status_code": 404,
    "error": "Not Found"
  }
  ```

- Status code 500 returned from APISIX:
  
  ```bash
  curl -i "localhost:9080/apisix_status/500"
  ```

  Response:

  ```bash
  HTTP/1.1 500 Internal Server Error
  Content-Type: application/json
  Connection: close
  Server: APISIX/3.12.0
  Content-Length: 57

  {
    "status_code": 500,
    "error": "API Gateway Error"
  }
  ```

[Back to TOC](#table-of-contents)

## Examples

Folder [`examples/`](examples/) contains a simple example that shows how to setup APISIX locally on Docker, and load `error-page` plugin.

For more example ideas, have a look at [github.com/mikyll/apisix-examples](https://github.com/mikyll/apisix-examples).

[Back to TOC](#table-of-contents)

### Standalone Example

#### Setup

See [`apisix.yaml`](examples/apisix-docker-standalone/conf/apisix.yaml).

Run the following command to setup the example:

```bash
docker compose -f examples/apisix-docker-standalone/compose.yaml up
```

#### Test Routes

Run [`test_routes.sh`](examples/utils/test_routes.sh) to send testing requests.

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
[build-status-shield]: https://github.com/mikyll/apisix-plugin-template/actions/workflows/ci.yml/badge.svg
[build-status-url]: https://github.com/mikyll/apisix-plugin-template/actions
