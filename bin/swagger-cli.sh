PROJECT_DIRECTORY=$(dirname $(cd `dirname $0` && pwd))
docker run --rm -v $PROJECT_DIRECTORY:/data redocly/cli:2.23.0 bundle /data/api.yaml --output /data/_build/openapi.yaml --ext yaml