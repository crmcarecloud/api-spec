PROJECT_DIRECTORY=$(dirname $(cd `dirname $0` && pwd))
docker run --rm -v $PROJECT_DIRECTORY:/data jeanberu/swagger-cli swagger-cli bundle /data/api.yaml --outfile /data/_build/openapi.yaml --type yaml