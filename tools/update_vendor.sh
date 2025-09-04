#!/usr/bin/env bash

# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

cd "$(pwd -P)"

KUBE_ROOT=$(dirname "${BASH_SOURCE[0]}")/..

# update vendor/
cat go.mod | grep '^go' > go.work
go work use .
go work use providers
echo "replace (" >> go.work
cat go.mod | grep '=>' | gazellerep -v "k8s.io/cloud-provider-gcp/providers" >> go.work
echo ")" >> go.work

cat go.mod | grep replace -A 100 | grep -v "k8s.io/cloud-provider-gcp/providers" >> go.work
go work vendor

# remove repo-originated BUILD files
find vendor -type f \( \
    -name BUILD \
    -o -name BUILD.bazel \
    -o -name '*.bzl' \
  \) -delete

# clean up unused dependencies
go mod tidy
# create a symlink in vendor directory pointing cloud-provider-gcp/providers to the //providers.
# This lets other packages and tools use the local staging components as if they were vendored.

# restore BUILD files in vendor/
bazel run //:gazelle
