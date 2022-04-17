FROM ubuntu:20.04
ENV TZ=Europe/Moscow
ENV APP_USER=backup-usr

RUN cat /etc/os-release \
 && adduser --disabled-password --gecos "" --home /home/$APP_USER --shell /bin/false $APP_USER \
 && cat /etc/passwd | grep $APP_USER

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
 && apt-get install -y \
    awscli \
    rsync \
    mariadb-client \
    ca-certificates \
    curl \
    apt-transport-https \
    lsb-release \
    gnupg \
    unzip \
 && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null
RUN AZ_REPO=$(lsb_release -cs) \
 && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list

# RUN ACCEPT_EULA=y DEBIAN_FRONTEND=noninteractive \
#  && AZ_VER=$(lsb_release -rs) \
#  && echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/$AZ_VER/prod/ $AZ_REPO main" | tee /etc/apt/sources.list.d/mssql-prod.list 
# apt-get install -y mssql-tools

RUN apt-get update \
 && apt-get install -y azure-cli \
 && rm -rf /var/lib/apt/lists/*

RUN curl -L https://go.microsoft.com/fwlink/?linkid=2143497 -o /tmp/sqlpackage.zip \
 && mkdir -p /home/$APP_USER/sqlpackage \
 && unzip /tmp/sqlpackage.zip -d /home/$APP_USER/sqlpackage \
 && chmod a+x /home/$APP_USER/sqlpackage/sqlpackage \
 && rm -f /tmp/sqlpackage.zip

RUN curl -L https://aka.ms/downloadazcopy-v10-linux -o /tmp/azcopy-v10-linux.tar \
 && tar -xvf /tmp/azcopy-v10-linux.tar \
 && cp ./azcopy_linux_amd64_*/azcopy /usr/bin/ \
 && rm -rf ./azcopy_linux_amd64_* \
 && rm -f /tmp/azcopy-v10-linux.tar

RUN REL_NO=$(lsb_release -rs) \
 && curl -L https://packages.microsoft.com/config/ubuntu/$REL_NO/prod.list | tee /etc/apt/sources.list.d/microsoft.list \
 && apt-get update \
 && apt-get install -y powershell \
 && rm -rf /var/lib/apt/lists/*

RUN pwsh -Command "Install-Module Az -Force"

COPY run.sh backup-files.sh backup-mysql.sh backup-mssql.sh copy-azure.sh copy-local.sh copy-rsync.sh copy-s3.sh sync-azure.sh sync-azure.ps1 sync-s3.sh sync-rsync.sh /home/$APP_USER/
RUN cd /home/$APP_USER && chmod 755 run.sh backup-files.sh backup-mysql.sh backup-mssql.sh copy-azure.sh copy-local.sh copy-rsync.sh copy-s3.sh sync-azure.sh sync-s3.sh sync-rsync.sh

WORKDIR /home/$APP_USER/
CMD ["/home/backup-usr/run.sh"]
