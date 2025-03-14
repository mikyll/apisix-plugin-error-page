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

TODO: Describe how to use the plugin (metadata, configuration, ecc.)

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

Run the following command to setup the example:

```bash
docker compose -f examples/apisix-docker-standalone/compose.yaml up
```

#### Test Routes

TODO

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
