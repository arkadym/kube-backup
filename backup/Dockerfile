FROM ubuntu:22.04
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
#    postgresql-client \

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

RUN curl -fSsL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /usr/share/keyrings/postgresql.gpg 
RUN echo deb [arch=amd64,arm64,ppc64el signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt/ jammy-pgdg main | tee -a /etc/apt/sources.list.d/postgresql.list
RUN apt-get update \
 && apt-get install -y postgresql-client-15 \
 && rm -rf /var/lib/apt/lists/*

RUN curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.5.4/powershell-7.5.4-linux-arm64.tar.gz \
 && mkdir -p /opt/microsoft/powershell/7 \
 && tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 \
 && rm -f /tmp/powershell.tar.gz \
 && chmod +x /opt/microsoft/powershell/7/pwsh \
 && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

RUN pwsh -Command "Install-Module Az -Force"

COPY run.sh backup-files.sh backup-mysql.sh backup-pgsql.sh backup-mssql.sh copy-azure.sh copy-local.sh copy-rsync.sh copy-s3.sh sync-azure.sh sync-azure.ps1 sync-s3.sh sync-rsync.sh /home/$APP_USER/
RUN cd /home/$APP_USER && chmod 755 run.sh backup-files.sh backup-mysql.sh backup-pgsql.sh backup-mssql.sh copy-azure.sh copy-local.sh copy-rsync.sh copy-s3.sh sync-azure.sh sync-s3.sh sync-rsync.sh

WORKDIR /home/$APP_USER/
CMD ["/home/backup-usr/run.sh"]
