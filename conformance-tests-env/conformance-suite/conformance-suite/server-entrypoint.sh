#!/bin/sh
cd conformance-suite
mv -f run-tests.sh ./.gitlab-ci
mvn package -DskipTests
java -Xdebug -Xrunjdwp:transport=dt_socket,address=*:9999,server=y,suspend=n \
    -Djava.security.egd=file:/dev/./urandom \
    -Dnet.openid.conformance.testModules.logFinalEnv=false \
    -jar target/fapi-test-suite.jar \
    --fintechlabs.base_url=${CONFORMANCE_SERVER} \
    --fintechlabs.devmode=true \
    --fintechlabs.startredir=true \
    --logging.level.net.openid.conformance.frontChannel=DEBUG \
    --logging.level.com.gargoylesoftware.htmlunit=ERROR \
    --logging.level.org.htmlunit.DefaultCssErrorHandler=ERROR \
    --logging.level.org.htmlunit.css.CssStyleSheet=ERROR