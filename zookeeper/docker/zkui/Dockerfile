# based on https://github.com/maauso/docker/tree/master/zkui
FROM openjdk:8-jdk-alpine
RUN apk add --no-cache bash git maven 'su-exec>=0.2'
RUN git clone -b v2.0 https://github.com/gary0416/zkui.git && cd /zkui && mvn clean install
WORKDIR /zkui/target/
COPY config.cfg entrypoint.sh /zkui/target/
EXPOSE 9090
ENTRYPOINT ["./entrypoint.sh"]
CMD ["/usr/bin/java", "-jar", "/zkui/target/zkui-2.0-SNAPSHOT-jar-with-dependencies.jar"]
