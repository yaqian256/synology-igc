FROM centos:centos7.9.2009

# 1. Copy only files needed for environment setup first to leverage caching
# This ensures that changes to compile.sh or other scripts don't trigger a full rebuild of dependencies
COPY build/setup_env.sh /usr/src/igc/build/
COPY build/rpm_pkg /usr/src/igc/build/rpm_pkg/

# 2. Run setup script (installs deps and local RPMs)
# This layer will be cached unless setup_env.sh or rpm_pkg changes
RUN bash /usr/src/igc/build/setup_env.sh

# 3. Copy the rest of the build scripts
COPY build/ /usr/src/igc/build/

# Set working directory
WORKDIR /usr/src/igc

# Default command
CMD ["/bin/bash", "build/docker/build_docker.sh"]

