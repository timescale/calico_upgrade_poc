#!/bin/bash
function resources() {
   inputManifest=$1
   kinds=($(yq eval ".kind" -N  $inputManifest | grep -v null))
   names=($(yq eval ".metadata.name" -N  $inputManifest | grep -v null))
   if ((${#kinds[@]} != ${#names[@]}))
   then
      echo "Malformed manifest $inputManifest" >&2
      exit 1
   fi
   for i in ${!kinds[@]}; do
      echo ${kinds[$i]}:${names[$i]}
   done
}


function read_yn() {
   read -r -p "Do you want to overwrite $resources_file? [y/N] " response
   if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
   then
      return 0
   else
      return 1
   fi
}


function main() {
   if [[ -z $1 ]]; then
      echo "Provide manifest file as the first argument" >&2
      return 1
   fi
   resources_file="all_resources.yaml "
   if [[ ! -z $2 ]]; then
      resources_file=$2
   fi
   if [ -f $resources_file ]; then
      if read_yn; then
         rm $resources_file
      else
         exit
      fi
   fi
   resources=$(resources $1)
   for r in $resources
   do
      kind=${r%:*}
      resource=${r#*:}
      kubectl get $kind -n kube-system -o yaml $resource >> $resources_file && echo "---" >> $resources_file
   done
}

if !(main $1 $2); then
   exit 1
fi
