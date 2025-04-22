# -----------------------------------------------------------------------------
# written by: Lawrence McDaniel https://lawrencemcdaniel.com
# date:       2025-Apr
#
# Usage:      manually build tutor MFE container and push to AWS ECR
# -----------------------------------------------------------------------------

AWS_ACCOUNT_ID="081248911030"
AWS_REGION="il-central-1"
TUTOR_VERSION="18.2.2"
OPENEDX_VERSION="v18"
OPENEDX_RELEASE="open-release/redwood.master"

# sign in to AWS ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# ensure that this tutor plugin is installed and enabled.
pip uninstall -y tutor-indigo-madrasa


# set environment variables
TIMESTAMP=$(date +"%Y%m%d%H%M")
REPOSITORY_TAG_MFE=${TUTOR_VERSION}-${TIMESTAMP}
AWS_ECR_REGISTRY_MFE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
AWS_ECR_REPOSITORY_MFE="courses.madrasafree.com/openedx-mfe-${OPENEDX_VERSION}"
MFE_DOCKER_IMAGE=${AWS_ECR_REGISTRY_MFE}/${AWS_ECR_REPOSITORY_MFE}:${REPOSITORY_TAG_MFE}
tutor config save --set MFE_DOCKER_IMAGE=${MFE_DOCKER_IMAGE}
tutor images build mfe
