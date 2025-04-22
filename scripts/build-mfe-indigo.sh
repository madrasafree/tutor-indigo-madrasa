# -----------------------------------------------------------------------------
# written by: Lawrence McDaniel https://lawrencemcdaniel.com
# date:       2025-Apr
#
# Usage:      manually build tutor MFE container with customized Indigo theme
#             and push to AWS ECR
# -----------------------------------------------------------------------------

AWS_ACCOUNT_ID="081248911030"
AWS_REGION="il-central-1"
TUTOR_VERSION="18.2.2"
OPENEDX_VERSION="v18"
OPENEDX_RELEASE="open-release/redwood.master"

# stop any running docker containers
docker stop $(docker ps -q)

# sign in to AWS ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# remove everything
# be mindful that one of the most common mistakes is to leave some unrelated
# tutor pypi package who's version is inconsistent with whatever we're trying to install here.
# in this case, you'll likely end up with whichever version is latest on pypi, which often is not
# the same as the version of tutor you're using here.
pip uninstall -y tutor tutor-indigo-madrasa tutor-mfe tutor-android tutor-cairn tutor-credentials tutor-discovery tutor-ecommerce tutor-forum tutor-indigo tutor-jupyter tutor-minio tutor-notes tutor-webui tutor-xqueue tutor-contrib-madrasa  tutor-contrib-madrasa-hebrew tutor-contrib-madrasa-s3 


# ensure that we're running the correct version of tutor and that we're using
# the most recent codebase for the indigo plugin.
pip install tutor==${TUTOR_VERSION}
pip install tutor-mfe==18.1.0
pip install git+https://github.com/madrasafree/tutor-indigo-madrasa@${OPENEDX_RELEASE}

pip list
tutor plugins enable mfe
tutor plugins enable indigo
tutor plugins list

# set environment variables
AWS_ECR_ENVIRONMENT="courses.madrasafree.com"
TIMESTAMP=$(date +"%Y%m%d%H%M")
REPOSITORY_TAG_MFE=${TUTOR_VERSION}-${TIMESTAMP}
AWS_ECR_REGISTRY_MFE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
AWS_ECR_REPOSITORY_MFE="${AWS_ECR_ENVIRONMENT}/openedx-mfe-${OPENEDX_VERSION}"
MFE_DOCKER_IMAGE=${AWS_ECR_REGISTRY_MFE}/${AWS_ECR_REPOSITORY_MFE}:${REPOSITORY_TAG_MFE}

# Check if the ECR repository exists
aws ecr describe-repositories --repository-names ${AWS_ECR_REPOSITORY_MFE} --region ${AWS_REGION} > /dev/null 2>&1

# If the repository does not exist, create it
if [ $? -ne 0 ]; then
  aws ecr create-repository --repository-name ${AWS_ECR_REPOSITORY_MFE} --region ${AWS_REGION}
fi

tutor config save --set MFE_DOCKER_IMAGE=${MFE_DOCKER_IMAGE}
docker buildx create --use --name=max1cpu --driver=docker-container --config=/home/ubuntu/buildkit.toml
tutor images build mfe

# push and tag container
tutor images push mfe
docker tag ${AWS_ECR_REGISTRY_MFE}/${AWS_ECR_REPOSITORY_MFE}:${REPOSITORY_TAG_MFE} ${AWS_ECR_REGISTRY_MFE}/${AWS_ECR_REPOSITORY_MFE}:latest
docker push ${AWS_ECR_REGISTRY_MFE}/${AWS_ECR_REPOSITORY_MFE}:latest
