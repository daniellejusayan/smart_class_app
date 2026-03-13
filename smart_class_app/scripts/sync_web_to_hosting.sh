#!/usr/bin/env bash
set -euo pipefail

mkdir -p public/app
rsync -a --delete build/web/ public/app/