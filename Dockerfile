FROM ubuntu:16.04

MAINTAINER Rabenda <rabenda.cn@gmail.com>

LABEL version="1.0"

RUN apt update
RUN apt install locales
# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install dependencies
ENV DEBIAN_FRONTEND noninteractive
RUN apt update
RUN apt install -y --no-install-recommends wget mysql-server mysql-client libmysqlclient-dev openjdk-8-jdk

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
ENV JRE_HOME=${JAVA_HOME}/jre
ENV CLASSPATH=$CLASSPATH:.:${JAVA_HOME}/lib:${JRE_HOME}/lib
ENV PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH

EXPOSE 3306
RUN mkdir -p /workspaces
WORKDIR /workspaces

# hadoop
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz
RUN tar -zxvf hadoop-2.7.3.tar.gz -C /usr/local
RUN mv /usr/local/hadoop-2.7.3 /usr/local/hadoop
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV YARN_HOME=/usr/local/hadoop
ENV YARN_CONF_DIR=${YARN_HOME}/etc/hadoop
ENV PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin
EXPOSE 50070 9000

# hive
RUN wget https://archive.apache.org/dist/hive/hive-1.2.1/apache-hive-1.2.1-bin.tar.gz
RUN tar -zxvf apache-hive-1.2.1-bin.tar.gz -C /usr/local
RUN mv /usr/local/apache-hive-1.2.1-bin /usr/local/hive
ENV HIVE_HOME=/usr/local/hive
ENV PATH=${PATH}:${HIVE_HOME}/bin
EXPOSE 9083 10000

# hbase
RUN wget https://archive.apache.org/dist/hbase/1.3.1/hbase-1.3.1-bin.tar.gz
RUN tar -zxvf hbase-1.3.1-bin.tar.gz -C /usr/local
RUN mv /usr/local/hbase-1.3.1 /usr/local/hbase
ENV HBASE_HOME=/usr/local/hbase
ENV PATH=${PATH}:${HBASE_HOME}/bin

# sqoop
RUN wget https://archive.apache.org/dist/sqoop/1.4.6/sqoop-1.4.6.bin__hadoop-2.0.4-alpha.tar.gz
RUN tar -zxvf sqoop-1.4.6.bin__hadoop-2.0.4-alpha.tar.gz -C /usr/local
RUN mv /usr/local/sqoop-1.4.6.bin__hadoop-2.0.4-alpha /usr/local/sqoop
ENV SQOOP_HOME=/usr/local/sqoop
ENV PATH=${PATH}:${SQOOP_HOME}/bin
ENV CLASSPATH=${CLASSPATH}:${SQOOP_HOME}/lib

# spark
RUN wget https://archive.apache.org/dist/spark/spark-2.1.0/spark-2.1.0-bin-without-hadoop.tgz
RUN tar -zxvf spark-2.1.0-bin-without-hadoop.tgz -C /usr/local
RUN mv /usr/local/spark-2.1.0-bin-without-hadoop /usr/local/spark
ENV SPARK_HOME=/usr/local/spark
ENV PATH=${PATH}:${SPARK_HOME}/bin

CMD ["/bin/bash"]