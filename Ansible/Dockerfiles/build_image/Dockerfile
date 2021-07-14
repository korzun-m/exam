FROM openjdk:7
RUN apt update -y
RUN apt install -y maven git
RUN git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git /tmp/boxfuse-sample-java-war-hello
RUN mvn -f /tmp/boxfuse-sample-java-war-hello/pom.xml package
RUN mkdir /var/build_data
COPY cp_app.sh /etc
RUN chmod +x /etc/cp_app.sh
CMD ["/etc/cp_app.sh"]
