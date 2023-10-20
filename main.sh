#!/bin/bash
set -e

if [ -z $CLUSTER_GIT_CLONE_URL ]; then
    echo "Missing CLUSTER_GIT_CLONE_URL environment var"
    exit 1
fi

if [ -z $YAML_FILE_PATH ]; then
    echo "Missing YAML_FILE_PATH environment var"
    exit 1
fi

if [ -z $NAMESPACE ]; then
    echo "Missing NAMESPACE environment var"
    exit 1
fi

if [ -z $DOCKER_REPO ]; then
    echo "Missing DOCKER_REPO environment var"
    exit 1
fi

if [ -z $DOCKER_IMAGE ]; then
    echo "Missing DOCKER_IMAGE environment var"
    exit 1
fi

if [ -z $DOCKER_TAG ]; then
    echo "Missing DOCKER_TAG environment var"
    exit 1
fi

# add extra validations here if you need, regarding the value of those variables for example (you may want to check that only expected directories are modified)
# if [ ... ]; then
#     echo "Given value [...] is not authorised for deployment. Perhaps this is a typo?"
#     exit 1
# fi

git clone --depth=1 $CLUSTER_GIT_CLONE_URL
# if needed :
# cd some-folder/some-subfolder/

IMAGE_NAME=$DOCKER_REPO/$DOCKER_IMAGE:$DOCKER_TAG

yq eval -i "select(.kind == \"Deployment\").spec.template.spec.containers[0].image = \"$IMAGE_NAME\"" $YAML_FILE_PATH

# bonus : if your cluster Git repo does follow a clean nomenclature, then the path of the right .yaml file to update can be guessed with extra environment variables, like this for example :
# yq eval -i "select(.kind == \"Deployment\").spec.template.spec.containers[0].image = \"$IMAGE_NAME\"" "$CLUSTER_FOLDER_NAME"/"$NAMESPACE"/"$PROJECT_TYPE"s/"$DEPLOYMENT_NAME".yaml

# bonus : modify at the same time a container environment variable that tracks the current version deployed, for Datadog Agent for example :
# yq eval -i "(select(.kind == \"Deployment\").spec.template.spec.containers[0].env[] | select(.name == \"DD_VERSION\")).value = \"$DOCKER_TAG\"" "$CLUSTER_FOLDER_NAME"/"$NAMESPACE"/"$PROJECT_TYPE"s/"$DEPLOYMENT_NAME".yaml

git add -A
if [ -n "$(git status --porcelain)" ]; then
    echo "File "$YAML_FILE_PATH" has been modified"
else
    echo "The image $IMAGE_NAME is already used by Deployment $NAMESPACE:deployment/$DOCKER_IMAGE"
    exit 1
fi

git commit -m "Rolling image $IMAGE_NAME to Deployment $NAMESPACE:deployment/$DOCKER_IMAGE"
git push

# bonus : notify the right Slack channel regarding the namespace you are deploying to (example for two namespaces called "dev" and "prod")
if [[ "$NAMESPACE" == "dev" ]] || [[ "$NAMESPACE" == "prod" ]]; then

    if [[ "$NAMESPACE" == "dev" ]]; then
      SLACK_CHANNEL=${SLACK_DEV_CHANNEL_ID}
    else
      SLACK_CHANNEL=${SLACK_PROD_CHANNEL_ID}
    fi

    # this is the syntax for a Gitlab pipeline, but you get the idea : basically you can build the perfect message that fits your needs
    COMMIT_URL="$CI_PROJECT_URL/-/commit/$CI_COMMIT_SHA"
    COMMIT_MESSAGE_CLEANED=$(echo "${CI_COMMIT_MESSAGE}" | tr '"' "'")

    BODY="{\"channel\":\"${SLACK_CHANNEL}\",
    \"username\":\"gitops-deploy\",
    \"text\":\"*${SERVICE_NAME}* has been released including this <${COMMIT_URL}|commit>\",
    \"icon_emoji\":\":rocket:\",
    \"attachments\":[{\"blocks\":[{\"type\":\"context\",\"elements\":[{\"type\":\"plain_text\",\"text\":\"${COMMIT_MESSAGE_CLEANED}\",\"emoji\":false}]}]}]
    }";

    echo "Calling Slack API: https://slack.com/api/chat.postMessage with BODY: $BODY"
    curl -X POST "https://slack.com/api/chat.postMessage" -H "Authorization: Bearer ${SLACK_APP_TOKEN}" -H "Content-type: application/json" --data "$BODY"
    
fi
