#!/bin/bash

set -euo pipefail

packages=$(pwd)/../packages.yaml
working=/tmp/

usage () {
  echo 
  echo "Usage: $0 [options...]" >&2
  echo
  echo "  -p, --packages        packages YAML file [${packages}]"
  echo "  -w, --working         working directory [${working}]"
  echo
  [ $# -ge 1 ] && exit 1
  exit 0
}

while [ $# -gt 0 ]
do
  case "${1}" in
    -h | --help)
        usage
        ;;
    -p | --packages)
        packages="${2}" && shift 2
        ;;
    -w | --working)
        working="${2}" && shift 2
        ;;
    *)  # No more options
        break
        ;;
  esac
done

if [ ! -f "${packages}" ]; then
  echo "${packages} package YAML file unreadable or does not exist"
  usage
fi

if [ ! -d "${working}" ]; then
  mkdir -p "${working}"
  if [ $? -ne 0 ]; then
    usage
  fi
fi

while IFS=$'\t' read -r name version description _; do
  echo "Fetching ${name}/${version}"
  
  s3_url=s3://naps-dev-artifacts/naps-dev/${name}/${version}/zarf-package-${name}-amd64.tar.zst

  aws s3 cp ${s3_url} ${working}
  if [ $? -ne 0 ]; then
    echo "${name}/${version} package copy failed"
    exit 1
  fi
done < <(yq e '.[] | [.name, .version, .description] | @tsv' "$packages")
