#!/bin/sh

# Wait for conformance suite server to be ready
# Check directly within the docker-compose network to avoid routing through host ports
until curl --output /dev/null --silent --head http://server:8080/ 2>/dev/null
do
    echo "Still waiting for conformance suite server to be available"
    sleep 10
done

echo "Conformance suite server is available"

# Wait for keycloak test realm to be imported (keycloak-import service sleeps 60s before importing)
until curl --output /dev/null --silent --fail http://keycloak:8080/auth/realms/test 2>/dev/null
do
    echo "Still waiting for keycloak test realm to be available"
    sleep 10
done

echo "Keycloak test realm is available"

TEST_START_DELAY=30
echo "All services are ready. Waiting $TEST_START_DELAY seconds before starting tests"

sleep $TEST_START_DELAY

docker exec keycloak-fapi-server-1 bash -c "chmod a+x /conformance-suite/.gitlab-ci/run-tests.sh"
docker exec keycloak-fapi-server-1 bash -c "chmod a+x /conformance-suite/scripts/*"

[ $AUTOMATE_TESTS == true ] &&
docker exec keycloak-fapi-server-1 bash -c "/conformance-suite/.gitlab-ci/run-tests.sh $TEST_PLAN"