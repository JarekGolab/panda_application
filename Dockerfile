FROM openjdk:11.0

ARG JAR_FILE=target/*.jar

COPY ${JAR_FILE} app.jar

RUN ["java","-jar","/app.jar"]

