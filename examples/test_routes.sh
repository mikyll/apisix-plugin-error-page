#!/bin/bash

read -p 'curl -i "localhost:9080/anything"'
curl -i "localhost:9080/anything"

echo ""
read -p 'curl -i "localhost:9080/status/400"'
curl -i "localhost:9080/status/400"
echo ""
read -p 'curl -i "localhost:9080/status/402"'
curl -i "localhost:9080/status/402"

echo ""
read -p 'curl -i "localhost:9080/status/500"'
curl -i "localhost:9080/status/500"
echo ""
read -p 'curl -i "localhost:9080/status/505"'
curl -i "localhost:9080/status/505"
echo ""
read -p 'curl -i "localhost:9080/status/506"'
curl -i "localhost:9080/status/506"

echo ""
read -p 'curl -i "localhost:9080/status/403"'
curl -i "localhost:9080/status/403"

echo ""
read -p 'curl -i "localhost:9080/unknown_route"'
curl -i "localhost:9080/unknown_route"
