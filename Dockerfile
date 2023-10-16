FROM quay.io/fedora/s2i-base:latest
LABEL maintainer="ISU Research IT <researchit@iastate.edu>"

ENV \
    STI_SCRIPTS_URL=image:///usr/libexec/s2i \
    STI_SCRIPTS_PATH=/usr/libexec/s2i \
    APP_ROOT=/opt/app-root \
    HOME=/opt/app-root/ \
    PATH=/opt/app-root/:/opt/spack/bin:$PATH

# core package installation
RUN \
    dnf -y update && \
    dnf -y install nodejs-npm nginx && \
    dnf clean all;

# Change the default port for nginx 
# Required if you plan on running images as a non-root user).
RUN \
    sed -i 's/80/8081/' /etc/nginx/nginx.conf && \
    sed -i 's/user nginx;//' /etc/nginx/nginx.conf && \
    sed -i 's|pid /run/nginx.pid;|pid /tmp/nginx.pid;|' /etc/nginx/nginx.conf && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Change folders to container user
#RUN \
#    touch /run/nginx.pid && \
#    mkdir -p /var/lib/nginx/tmp/client_body && \
#    chown -R 1001:1001 /usr/share/nginx && \
#    chown -R 1001:1001 /var/log/nginx && \
#    chown -R 1001:1001 /var/lib/nginx && \
#    chown -R 1001:1001 /run/nginx.pid && \
#    chown -R 1001:1001 /etc/nginx && \
#    chmod -R ugo=rwx /var/lib/nginx/tmp

# Copy in installdeps.R to set cran mirror & handle package installs
COPY ./reactjs-build.sh /opt/app-root/src

# Copy default nginx config for reactjs to config folder.
COPY ./reactjs.conf /etc/nginx/conf.d/

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy the passwd template for nss_wrapper
COPY passwd.template /tmp/passwd.template

USER 1001

EXPOSE 8080

STOPSIGNAL SIGTERM

CMD ["/usr/libexec/s2i/run"]
