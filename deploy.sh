#!/bin/bash

RESTART="no"

while getopts ":rne:" option;
do
    case "${option}" in
        n) CACHE="nocache";;
        e) ENV=$OPTARG;;
        r) RESTART="yes";;
    esac
done

if [ "${ENV}" == "" ]; then
  ENV="staging"
fi

echo "Deploying to ${ENV}..."
sleep 1s

ACR="ktsites${ENV}acr"

if [ "${CACHE}" == "nocache" ]; then
  echo "Building Docker image with --no-cache..."
  sleep 2s
  docker build . --build-arg php_version=8.3 --build-arg dest_env="${ENV}" --no-cache --tag qrpracing:latest
else
  echo "Building Docker image..."
  sleep 2s
  docker build . --build-arg php_version=8.3 --build-arg dest_env="${ENV}" --tag qrpracing:latest
fi

if [ $? != 0 ]; then
  exit
fi

echo "Getting token..."
TOKEN=$(az acr login --name $ACR  --expose-token --output tsv --query refreshToken --only-show-errors)
echo "Token received. Logging in..."
docker login $ACR.azurecr.io --username 00000000-0000-0000-0000-000000000000 --password-stdin <<< $TOKEN
echo "Deploying container..."
docker tag qrpracing:latest $ACR.azurecr.io/qrpracing:latest

docker push $ACR.azurecr.io/qrpracing:latest
echo "Container deployment complete."

if [ "${RESTART}" == "yes" ]; then
  echo "Restarting container group..."
    if [ "${ENV}" == "prod" ]; then
      ENV="Production"
    fi
  az container restart -g Ktea-Websites-External-"${ENV^}" -n qrpracing-aci
fi
