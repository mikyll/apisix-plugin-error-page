#!/bin/bash

read -p 'curl -i "localhost:9080/anything"'
curl -i "localhost:9080/anything"

echo ""
read -p 'curl -i "localhost:9080/unknown"'
curl -i "localhost:9080/unknown"

echo ""
read -p 'curl -i "localhost:9080/apisix_status/404"'
curl -i "localhost:9080/apisix_status/404"

echo ""
read -p 'curl -i "localhost:9080/apisix_status/500"'
curl -i "localhost:9080/apisix_status/500"
