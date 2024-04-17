# to run the script outside of the azd context, we need to set the env vars
while IFS='=' read -r key value; do
        value=$(echo "$value" | sed 's/^"//' | sed 's/"$//')
        export "$key=$value"
done <<EOF
$(azd env get-values)
EOF

echo "deploy AzureChat = $DEPLOY_AZURE_CHATAPP"
    
if [ "$DEPLOY_AZURE_CHATAPP" = "false" ]        # The previous condition just checks if the variable is set and not empty, regardless of its value. By adding "$DEPLOY_AZURE_CHATAPP" inside double quotes and using the = operator for string comparison, you ensure that the conditional block is only executed when the value of $DEPLOY_AZURE_CHATAPP is exactly "false"
then
    echo "checking app registration"
    ./scripts/appreg.sh
    echo "deploying azurechat"
    azd deploy azurechat
fi 
