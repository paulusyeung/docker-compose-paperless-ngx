source url: https://docs.techdox.nz/paperless/

# Setting Up Paperless-ngx with Docker Compose¶

## Introduction to Paperless-ngx¶

Paperless-ngx is an open-source document management tool designed to digitize your physical documents into a searchable archive. It supports a wide range of hardware architectures including amd64, arm, and arm64.

## Docker Compose Configuration for Paperless-ngx¶

This Docker Compose setup deploys Paperless-ngx along with PostgreSQL, Redis, Apache Tika, and Gotenberg servers. It provides comprehensive support for various document formats, including Office documents.

#### Docker Compose File (docker-compose.yml)¶

```
version: "3.4"
services:
  broker:
    image: docker.io/library/redis:7
    restart: unless-stopped
    volumes:
      - redisdata:/data

  db:
    image: docker.io/library/postgres:15
    restart: unless-stopped
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: paperless
      POSTGRES_USER: paperless
      POSTGRES_PASSWORD: paperless

  webserver:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    restart: unless-stopped
    depends_on:
      - db
      - broker
      - gotenberg
      - tika
    ports:
      - "8000:8000"
    volumes:
      - data:/usr/src/paperless/data
      - media:/usr/src/paperless/media
      - ./export:/usr/src/paperless/export
      - ./consume:/usr/src/paperless/consume
    env_file: docker-compose.env
    environment:
      PAPERLESS_REDIS: redis://broker:6379
      PAPERLESS_DBHOST: db
      PAPERLESS_TIKA_ENABLED: 1
      PAPERLESS_TIKA_GOTENBERG_ENDPOINT: http://gotenberg:3000
      PAPERLESS_TIKA_ENDPOINT: http://tika:9998

  gotenberg:
    image: docker.io/gotenberg/gotenberg:7.10
    restart: unless-stopped
    command:
      - "gotenberg"
      - "--chromium-disable-javascript=true"
      - "--chromium-allow-list=file:///tmp/.*"

  tika:
    image: ghcr.io/paperless-ngx/tika:latest
    restart: unless-stopped

volumes:
  data:
  media:
  pgdata:
  redisdata:
```

## Key Components of the Configuration¶

#### Services:¶

- **Broker (Redis)**: Acts as the message broker for Paperless-ngx.
- **DB (Postgres)**: The database server for storing Paperless-ngx data.
- **Webserver (Paperless-ngx)**: The main Paperless-ngx service providing the web interface and document processing.
- **Gotenberg**: Provides document conversion services, enhancing Paperless-ngx's ability to consume various file formats.
- **Tika**: Offers content analysis and metadata extraction, further extending support for document types.

#### Volumes:¶

- data, media, pgdata, redisdata: Docker-managed volumes for persistent storage of Paperless-ngx data, media files, PostgreSQL database files, and Redis data, respectively.

#### Configuration Notes:¶

- Port 8000: Paperless-ngx is accessible on this port.
- Environment Variables: Critical for configuring the connections between Paperless-ngx, Redis, and Postgres, as well as enabling integration with Tika and Gotenberg.

#### Docker Compose Env File (docker-compose.env)¶

```
# The UID and GID of the user used to run paperless in the container. Set this
# to your UID and GID on the host so that you have write access to the
# consumption directory.
USERMAP_UID=1000
USERMAP_GID=1000

# Additional languages to install for text recognition, separated by a
# whitespace. Note that this is
# different from PAPERLESS_OCR_LANGUAGE (default=eng), which defines the
# language used for OCR.
# The container installs English, German, Italian, Spanish and French by
# default.
# See https://packages.debian.org/search?keywords=tesseract-ocr-&searchon=names&suite=buster
# for available languages.
#PAPERLESS_OCR_LANGUAGES=tur ces

###############################################################################
# Paperless-specific settings                                                 #
###############################################################################

# All settings defined in the paperless.conf.example can be used here. The
# Docker setup does not use the configuration file.
# A few commonly adjusted settings are provided below.

# This is required if you will be exposing Paperless-ngx on a public domain
# (if doing so please consider security measures such as reverse proxy)
#PAPERLESS_URL=https://paperless.example.com

# Adjust this key if you plan to make paperless available publicly. It should
# be a very long sequence of random characters. You don't need to remember it.
#PAPERLESS_SECRET_KEY=change-me

# Use this variable to set a timezone for the Paperless Docker containers. If not specified, defaults to UTC.
#PAPERLESS_TIME_ZONE=America/Los_Angeles

# The default language to use for OCR. Set this to the language most of your
# documents are written in.
#PAPERLESS_OCR_LANGUAGE=eng

# Set if accessing paperless via a domain subpath e.g. https://domain.com/PATHPREFIX and using a reverse-proxy like traefik or nginx
#PAPERLESS_FORCE_SCRIPT_NAME=/PATHPREFIX
#PAPERLESS_STATIC_URL=/PATHPREFIX/static/ # trailing slash required
```

## Setup Instructions¶

1. Preparation: Prior to launching the containers, ensure the folders for the export, and consume volumes exist to prevent permission issues.

2. Environment Variables: Define necessary environment variables in a .env file, including PG_PASS, PG_USER, PG_DB, and AUTHENTIK_SECRET_KEY.

3. Launching Paperless-ngx:

4. Pull the latest images with docker compose pull.

5. Start the services using docker compose up -d.

Paperless-ngx offers a digital solution for managing your documents securely and efficiently. With this Docker Compose setup, you can easily deploy Paperless-ngx along with its dependencies for a comprehensive document management system.

## Setup SAMBA

#### Prepare SAMBA Server

```bash
# install SAMBA
sudo apt install samba

# create group 'paperless'
sudo groupadd paperless

# addd primary user 'marche' to paperless
# The -a (append) switch is essential. Otherwise, the user will be removed from any groups, not in the list.
# The -G switch takes a (comma-separated) list of additional groups to assign the user to.
sudo usermod -a -G paperless marche

# Show primary user id and group id
id

# use them in docker-compose.env
USERMAP_UID=1000    # primary user
USERMAP_GID=1001    # group paperless

# create user 'dmsuser' and add to group 'paperless'
# this user 'dmsuser' will be used to connect to the shared folder
sudo useradd dmsuser
sudo usermod -a -G paperless dmsuser
```

#### Setup SAMBA Shared Drive

```bash
# Create the shared directory
sudo mkdir /srv/dms/dropbox

# Modify its permissions
sudo chmod 777 /srv/dms/dropbox

# Modify smb.conf
sudo nano /etc/samba/smb.conf

# Add the following section
[dropbox]
   comment = paperless consumption
   path = /srv/dms/dropbox
   valid users = @paperless
   public = no
   browsable = yes
   guest ok = no
   read only = no
   writable = yes
```

#### Setup PAPERLESS-NGX Consume Folder

If using SAMBA shared folder:

```bash
services
  webserver:
    volumes:
      - /srv/paperless/consume:/usr/src/paperless/consume
```

If using Synology shared folder:

```bash
# Install the CIFS utilities if not already present
sudo apt update
sudo apt install cifs-utils

# Create a mount point
sudo mkdir -p /mnt/paperless_consume

# Mount the Synology shared folder
sudo mount -t cifs //synology_ip_address/paperless_consume /mnt/paperless_consume -o username=your_username,password=your_password

# Modify fstab to auto-mount the Synology shared folder when boot
sudo nano /etc/fstab

# Append line to the end
//synology_ip_address/paperless_consume /mnt/paperless_consume cifs uid=1000,gid=1000,rw,dir_mode=0777,file_mode=0777,vers=2.0,username=your_username,password=your_password 0 0

# Modify the docker-compose.yml
services:
  webserver:
    volumes:
      - /volume1/paperless_consume:/usr/src/paperless/consume

# Add these PAPERLESS parameters to docker-compose.env
PAPERLESS_CONSUMER_POLLING=10
PAPERLESS_CONSUMER_POLLING_RETRY_COUNT=4
PAPERLESS_CONSUMER_POLLING_DELAY=10


```