#! /bin/sh

echo "cleaning gamma_ray.zip"
rm gamma_ray.zip

echo "running npm install"
npm install

echo "building zip file"
zip -r gamma_ray.zip gamma_ray.js node_modules

function_name=$1

if [[ -z $function_name ]]; then
  echo "Usage $0 <func>"
  exit 1
fi

aws lambda update-function-code --function-name $function_name --zip-file fileb://gamma_ray.zip

echo "Find alias development"
aliase=`aws lambda list-aliases --function-name $function_name | grep development`
if [[ $aliase == "" ]] ; then
  echo "Create alias development"
  aws lambda create-alias --function-name $function_name --name development --function-version \$LATEST
  echo "Alias was created but SNS Topic still needs to be attached"
fi

echo "Publish new Version of function"
version=`aws lambda publish-version --function-name $function_name | grep  \"Version\" | tr -dc '0-9'`

echo "Updating the development Lambda Alias so it points to the new function"
aws lambda update-alias --function-name $function_name --function-version $version --name development


