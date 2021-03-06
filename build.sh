#!/usr/bin/env bash

root=$(cd "$(dirname "$0")"; pwd -P)
artifacts=$root/artifacts
configuration=Release

export CLI_VERSION=`cat ./global.json | grep -E '[0-9]\.[0-9]\.[a-zA-Z0-9\-]*' -o`
export DOTNET_INSTALL_DIR="$root/.dotnetcli"
export PATH="$DOTNET_INSTALL_DIR:$PATH"

dotnet_version=$(dotnet --version)

if [ "$dotnet_version" != "$CLI_VERSION" ]; then
    curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --version "$CLI_VERSION" --install-dir "$DOTNET_INSTALL_DIR"
fi

if [ "$CI" != "" ]; then
    docker pull pafortin/goaws
    docker run -d --name goaws -p 4100:4100 pafortin/goaws
    export AWS_SERVICE_URL="http://localhost:4100"
fi

dotnet restore JustSaying.sln --verbosity minimal || exit 1
dotnet build JustSaying/JustSaying.csproj --output $artifacts --configuration $configuration --framework "netstandard2.0" || exit 1

dotnet test ./JustSaying.UnitTests/JustSaying.UnitTests.csproj
dotnet test ./JustSaying.IntegrationTests/JustSaying.IntegrationTests.csproj
