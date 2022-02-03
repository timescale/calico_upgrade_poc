#!/bin/bash
set -e
file=$1
prefix=${file%.*}
suffix=${file##*.}
if [[ $suffix != 'yml' && $suffix != 'yaml' ]]; then
   echo "Provide a yaml file"
   exit 1
fi
backup="${prefix}_backup.${suffix}"
cp $file $backup
yq -iP e 'del(.metadata.annotations."kubectl.kubernetes.io/last-applied-configuration") |
          del(.status)                                                                  |
          del(.status)                                                                  |
          del(.metadata.generation)                                                     |
          del(.metadata.resourceVersion)                                                |
          del(.metadata.selfLink)                                                       |
          del(.metadata.uid)                                                            |
          del(.metadata.creationTimestamp)' $file
yq -iP e 'sort_keys(.)' $file
yq -iP e '... comments=""' $file
