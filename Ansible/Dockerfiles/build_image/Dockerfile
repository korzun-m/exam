FROM ubuntu:20.04
ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt update -y
RUN apt install -y default-jdk maven git
RUN git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git /tmp/boxfuse-sample-java-war-hello
RUN mvn -f /tmp/boxfuse-sample-java-war-hello/pom.xml package
RUN mkdir /data
RUN cp /tmp/boxfuse-sample-java-war-hello/target/hello-*.war /data
RUN touch /data/foo
RUN echo 123 > /data/foo
