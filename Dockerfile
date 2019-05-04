FROM ubuntu:16.04

MAINTAINER Rabenda <rabenda.cn@gmail.com>

LABEL version="1.0"

RUN apt update -qq
RUN apt install -y -qq locales
# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install dependencies
ENV DEBIAN_FRONTEND noninteractive
RUN apt update -qq
RUN apt install -y -qq --no-install-recommends wget ssh mysql-server mysql-client libmysqlclient-dev openjdk-8-jdk

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
ENV JRE_HOME=${JAVA_HOME}/jre
ENV CLASSPATH=$CLASSPATH:.:${JAVA_HOME}/lib:${JRE_HOME}/lib
ENV PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH

EXPOSE 3306
RUN sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

RUN mkdir -p /workspaces
WORKDIR /workspaces
COPY conf /workspaces/conf

RUN wget -q https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.47.tar.gz && \
    tar -zxf mysql-connector-java-5.1.47.tar.gz && \
    cp ./mysql-connector-java-5.1.47/mysql-connector-java-5.1.47-bin.jar . && \
    rm -rf ./mysql-connector-java-5.1.47

# hadoop
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV YARN_HOME=/usr/local/hadoop
ENV YARN_CONF_DIR=${YARN_HOME}/etc/hadoop
ENV PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin
RUN wget -q https://archive.apache.org/dist/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz && \
    tar -zxf hadoop-2.7.3.tar.gz -C /usr/local && \
    mv /usr/local/hadoop-2.7.3 ${HADOOP_HOME}
RUN cp -f conf/hadoop/core-site.xml ${HADOOP_CONF_DIR} && \
    cp -f conf/hadoop/hdfs-site.xml ${HADOOP_CONF_DIR} && \
    cp -f conf/hadoop/hadoop-env.sh ${HADOOP_CONF_DIR} && \
    cp -f conf/hadoop/yarn-env.sh ${HADOOP_CONF_DIR}
EXPOSE 50070 9000

# hive
ENV HIVE_HOME=/usr/local/hive
ENV PATH=${PATH}:${HIVE_HOME}/bin
RUN wget -q https://archive.apache.org/dist/hive/hive-1.2.1/apache-hive-1.2.1-bin.tar.gz && \
    tar -zxf apache-hive-1.2.1-bin.tar.gz -C /usr/local && \
    mv /usr/local/apache-hive-1.2.1-bin ${HIVE_HOME}
RUN cp -f conf/hive/hive ${HIVE_HOME}/bin/ && \
    cp -f conf/hive/hive-env.sh ${HIVE_HOME}/conf/ && \
    cp -f conf/hive/hive-site.xml ${HIVE_HOME}/conf/ && \
    cp -f mysql-connector-java-5.1.47-bin.jar ${HIVE_HOME}/lib/ && \
    cp -f ${HIVE_HOME}/lib/jline-2.12.jar ${HADOOP_HOME}/share/hadoop/yarn/lib/
EXPOSE 9083 10000

# hbase
ENV HBASE_HOME=/usr/local/hbase
ENV PATH=${PATH}:${HBASE_HOME}/bin
RUN wget -q https://archive.apache.org/dist/hbase/1.3.1/hbase-1.3.1-bin.tar.gz && \
    tar -zxf hbase-1.3.1-bin.tar.gz -C /usr/local && \
    mv /usr/local/hbase-1.3.1 /usr/local/hbase
RUN cp -f conf/hbase/hbase-env.sh ${HBASE_HOME}/conf/ && \
    cp -f conf/hbase/hbase-site.xml ${HBASE_HOME}/conf/

# sqoop
ENV SQOOP_HOME=/usr/local/sqoop
ENV PATH=${PATH}:${SQOOP_HOME}/bin
ENV CLASSPATH=${CLASSPATH}:${SQOOP_HOME}/lib
RUN wget -q https://archive.apache.org/dist/sqoop/1.4.6/sqoop-1.4.6.bin__hadoop-2.0.4-alpha.tar.gz && \
    tar -zxf sqoop-1.4.6.bin__hadoop-2.0.4-alpha.tar.gz -C /usr/local && \
    mv /usr/local/sqoop-1.4.6.bin__hadoop-2.0.4-alpha ${SQOOP_HOME} 
RUN cp -f conf/sqoop/sqoop-env.sh ${SQOOP_HOME}/conf/ && \
    cp -f mysql-connector-java-5.1.47-bin.jar ${SQOOP_HOME}/lib/ && \
    cp -f conf/sqoop/configure-sqoop ${SQOOP_HOME}/bin 

# spark
ENV SPARK_HOME=/usr/local/spark
ENV PATH=${PATH}:${SPARK_HOME}/bin
RUN wget -q https://archive.apache.org/dist/spark/spark-2.1.0/spark-2.1.0-bin-without-hadoop.tgz && \
    tar -zxf spark-2.1.0-bin-without-hadoop.tgz -C /usr/local && \
    mv /usr/local/spark-2.1.0-bin-without-hadoop /usr/local/spark
RUN cp -f conf/spark/spark-env.sh ${SPARK_HOME}/conf/

RUN hdfs namenode -format && \
    mkdir /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld && \
    /etc/init.d/mysql start && \
    mysql -uroot -p -e "set password for root@localhost = password('root')" && \
    mysql -uroot -proot -e "create database hive" && \
    mysql -uroot -proot -e "grant all on *.* to root@'%' identified by 'root' with grant option" && \
    mysql -uroot -proot -e "flush privileges" && \
    /etc/init.d/mysql restart && \
    schematool -dbType mysql -initSchema && \
    /etc/init.d/mysql stop

RUN mkdir -p /root/.ssh/ && \
    cp -f conf/.ssh/id_rsa.pub /root/.ssh/ && \
    cp -f conf/.ssh/id_rsa /root/.ssh/ && \
    cp -f conf/.ssh/authorized_keys /root/.ssh/

RUN sed -i "s/.*StrictHostKeyChecking.*/ StrictHostKeyChecking no /" /etc/ssh/ssh_config

COPY entrypoint.sh /workspaces
RUN chmod a+x ./entrypoint.sh

ENTRYPOINT [ "./entrypoint.sh" ]
CMD ["start"]