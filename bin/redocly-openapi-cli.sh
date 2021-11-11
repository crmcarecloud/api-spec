PROJECT_DIRECTORY=$(dirname $(cd `dirname $0` && pwd))
docker run --rm -v $PROJECT_DIRECTORY:/data redocly/openapi-cli lint /data/_build/openapi.yaml