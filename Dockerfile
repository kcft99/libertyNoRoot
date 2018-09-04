# (C) Copyright IBM Corporation 2018.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM websphere-liberty

LABEL maintainer="Arthur De Magalhaes <arthurdm@ca.ibm.com> (@arthurdm)"

    
# Copy IBM Java, WebSphere Liberty and docker-server into the image
#COPY --from=websphere-liberty:kernel /opt/ibm/java /opt/ibm/java
#COPY --from=websphere-liberty:kernel /opt/ibm/wlp /opt/ibm/wlp
#COPY --from=websphere-liberty:kernel /opt/ibm/docker /opt/ibm/docker


# Set environment vars and shorcuts
ENV JAVA_HOME=/opt/ibm/java \
    PATH=/opt/ibm/wlp/bin:$PATH \
    LOG_DIR=/logs \
    WLP_OUTPUT_DIR=/opt/ibm/wlp/output \
    RANDFILE=/tmp/.rnd \
    JVM_ARGS="-Xshareclasses:name=liberty,nonfatal,cacheDir=/output/.classCache/"

# Install MicroProfile features
RUN if [ ! -z $REPOSITORIES_PROPERTIES ]; then mkdir /opt/ibm/wlp/etc/ \
  && echo $REPOSITORIES_PROPERTIES > /opt/ibm/wlp/etc/repositories.properties; fi \
  && installUtility install --acceptLicense \
    appSecurity-2.0 bluemixUtility-1.0 collectiveMember-1.0 ldapRegistry-3.0 \
    localConnector-1.0 microProfile-1.0 microProfile-1.2 microProfile-1.3 monitor-1.0 restConnector-1.0 \
    requestTiming-1.0 restConnector-2.0 sessionDatabase-1.0 sessionCache-1.0 ssl-1.0 transportSecurity-1.0 \
    webCache-1.0 webProfile-7.0 appSecurityClient-1.0 javaee-7.0 javaeeClient-7.0 adminCenter-1.0 \ 
  && if [ ! -z $REPOSITORIES_PROPERTIES ]; then rm /opt/ibm/wlp/etc/repositories.properties; fi \
  && rm -rf /output/workarea /output/logs


# Create symlinks && set permissions for non-root user
RUN  useradd -u 1001 -r -g 0 -s /sbin/nologin default \
    && chown -R 1001:0 /config \
    && chmod -R g+rw /config \
    && chown -R 1001:0 /opt/ibm/docker/docker-server \
    && chmod -R g+rwx /opt/ibm/docker/docker-server \
    && chown -R 1001:0 /opt/ibm/wlp/usr/servers/defaultServer \
    && chmod -R g+rw /opt/ibm/wlp/usr/servers/defaultServer \
    && chown -R 1001:0 /opt/ibm/wlp/output \
    && chmod -R g+rw /opt/ibm/wlp/output \
    && chown -R 1001:0 /logs \
    && chmod -R g+rw /logs

USER 1001

# Add server.xml
COPY server.xml /config/

EXPOSE 9080 9443
ENTRYPOINT ["/opt/ibm/docker/docker-server"]
CMD ["/opt/ibm/wlp/bin/server", "run", "defaultServer"]
