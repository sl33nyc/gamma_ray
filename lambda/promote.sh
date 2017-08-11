#! /bin/bash

if [[ "$#" -ne 3 ]]; then
  echo "Usage $0 <func> <src> <dest>"
  echo 'Promote function <func> from version at <src> to <dest>'
  exit 1
fi

function_name=$1
src=$2
dest=$3

echo "Promoting $function_name from $src to $dest"

aliases=$(aws lambda list-aliases --function-name $function_name)
echo $aliases | jq '.'

alias_map=$(echo $aliases | jq 'reduce .Aliases[] as $item ({}; . + {($item.Name) : $item.FunctionVersion | tonumber})')
echo $alias_map | jq '.'

src_version=$(echo $alias_map | jq .$src)
if [[ -z $src_version ]]; then
  echo "Could not find alias $src among aliases"
  exit 1
fi

dest_version=$(echo $alias_map | grep .$dest)
if [[ -z $dest_version ]]; then
  lambda_cmd="create-alias"
else
  lambda_cmd="update-alias"
fi

echo "Promoting $function_name $dest from version $dest_version to $src_version ($src)"

aws lambda $lambda_cmd --function-name $function_name --function-version $src_version --name $dest