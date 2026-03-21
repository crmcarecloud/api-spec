PROJECT_DIRECTORY=$(dirname $(cd `dirname $0` && pwd))

docker run -p 8080:80 -v $PROJECT_DIRECTORY/_build/openapi.yaml:/usr/share/nginx/html/swagger.yaml -e SPEC_URL=swagger.yaml redocly/redoc:v2.5.1
# run on the URL http://localhost:8080/