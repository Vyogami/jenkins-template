FROM jenkins/jenkins:2.479.2-jdk17
USER root

# Install necessary packages
RUN apt-get update && \
    apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    make\
    lsb-release

# Add Docker's official GPG key
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up Docker repository
RUN echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker CLI
RUN apt-get update && \
    apt-get install -y docker-ce-cli

# Set up Docker group and add Jenkins user
RUN groupadd -g 999 docker && \
    usermod -aG docker jenkins

# Install Blue Ocean and other plugins
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow"

# Switch back to root for permissions
USER root
RUN chown -R jenkins:jenkins /var/jenkins_home

# Switch back to jenkins user
USER jenkins