#!/bin/bash

read -p 'curl -i "localhost:9080/anything"'
curl -i "localhost:9080/anything"

echo ""
read -p 'curl -i "localhost:9080/demo"'
curl -i "localhost:9080/demo"

echo ""
read -p 'curl -i "localhost:9080/apisix/plugin/demo/public_api"'
curl -i "localhost:9080/apisix/plugin/demo/public_api"
