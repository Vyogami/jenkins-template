FROM jenkins/jenkins:2.479.2-jdk17

# Set Jenkins and Java options for optimization
ENV JENKINS_OPTS="--handlerCountMax=100 --logfile=/var/log/jenkins/jenkins.log"
ENV JAVA_OPTS="-Xmx256m -Xms256m -XX:MaxMetaspaceSize=128m -XX:+UseG1GC -XX:+ExitOnOutOfMemoryError -Djava.awt.headless=true -Xlog:gc*=debug:/var/log/jenkins/gc.log"

USER root

# Install necessary packages
RUN apt-get update && \
    apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    make \
    vim \
    lsb-release

# Add Docker's official GPG key
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up Docker repository
RUN echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
RUN apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Set up Docker group and add Jenkins user
RUN groupadd -g 999 docker || true && \
    usermod -aG docker jenkins

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Create log directory
RUN mkdir -p /var/log/jenkins && \
    chown -R jenkins:jenkins /var/log/jenkins

# Copy configuration
COPY jenkins.yaml /var/jenkins_home/jenkins.yaml
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml

# Install minimal set of plugins
USER jenkins
RUN jenkins-plugin-cli --plugins "docker-workflow git matrix-auth workflow-aggregator"

# Switch back to root for permissions
USER root
RUN chown -R jenkins:jenkins /var/jenkins_home && \
    chmod 666 /var/run/docker.sock || true

# Switch back to jenkins user
USER jenkins