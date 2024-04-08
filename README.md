# minebase ⛏️🐳 

This is a batteries-included Docker base image you can use to create your own Minecraft server images.

## What does it include?

- Automatic backups on startup and/or shutdown via [rclone](https://rclone.org).
- An [RCON CLI](https://github.com/zekroTJA/rconcli) to manage your server via `docker exec` or remotely.
- Docker [healthcheck on the status of your server](https://github.com/evolvedpacks/healthcheck) so you can monitor startup status and anomalies.

## How to build the image?

Simply use the image `ghcr.io/zekrotja/minebase` as base image. You can choose between different JDK versions via the tag of the image. Available tags are:
- `jdk-21`
- `jdk-17`
- `jdk-16`
- `jdk-11`
- `jdk-8`

Then, you need to create a `run.sh`, which contains the script to start the Minecraft server. It must be placed in the `/var/mcserver/scripts` directory of the image.

You can also add a `build.sh` script there, which will then be executed before the `run.sh` script to perform necessary build steps (like building spigot or forge servers, i.e.)

Via the `BACKUP_LOCATION` environment variable, you can define which directory the backup should include. The default is the whole server directory at `/var/mcserver`.

With `PROPERTIES_LOCATION`, you can define where your `server.properties` is located, if it differs from the default value (`/var/mcserver/server.properties`). This is used by the RCON client to automatically get the RCON port and credentials for the server.

```
FROM ghcr.io/zekrotja/minebase:jdk-17

COPY scripts/ scripts/
RUN chmod +x scripts/*.sh

ENV BACKUP_LOCATION="/var/mcserver/world"
```

## How to use the image?

It is recommendet to use the built image in combination with some sort of container orchestration software. In the following example, we are using `docker compose`.

In the following example, you can see a `docker-compose.yml` for an All the Mods 9 modpack server.

```yml
version: '3'

services:
  #...

# Comment out for automatic backups. See section backup
#secrets:
#  minecraftrclone:
#    file: rclone.conf

  atm:
    image: 'atm9'
    restart: unless-stopped
    environment:
      - 'XMS=4G'
      - 'XMX=8G'
    ports:
      - '25565:25565'
      # - '25575:25575' # Uncomment this if you want RCON to be accessible remotely
    volumes:
      - "./atm/world:/var/mcserver/world"
      - "./atm/whitelist.json:/var/mcserver/whitelist.json"
      - "./atm/ops.json:/var/mcserver/ops.json"
      - "./atm/server.properties:/var/mcserver/server.properties"
#    secrets: # Comment out for automatic backups. See section backup
#      - source: minecraftrclone
#        target: rcloneconfig
```


## RCON CLI

Included in the Docker image is an RCON cli which can be used from insde the container to control the server without attaching to the servers stdin.

To use RCON, you need to set following values in the `server.properties`:
```cfg
enable-rcon=true
rcon.password=7mxQ8Br2QBsFFn2n
rcon.port=25575
```

Then, you can use the RCON cli like follwoing:

```
$ docker exec <container> rcon <server_command>
```

As you can see, you do not need to pass the password or port of the RCON connection. The tool automatically recognizes the location of the `server.properties` file and takes the password and address configuration from there.

Alternatively, when you really want to use the raw cli with no prepared presets, use the following command:
```
$ docker exec <container> rconcli -a loalhost:25575 -p <rcon_password> <server_command>
```

If you are further interested in the usage and details of the RCON cli, take a look [**here of the Github project**](https://github.com/zekroTJA/rconclient).

## Backup

Backups can be created automatically before a server start.
For this, a Docker secret must be stored in /run/secrets/rcloneconfig.  
rclone is used. The default target is `minecraft:/`  
Rclone offers a number of very [different destinations](https://rclone.org/overview/). In this example, an S3 endpoint with a specific subdirectory is used.

Example config:

```txt
[contabo]
type = s3
provider = Other
env_auth = false
access_key_id = access_key
secret_access_key = secret_key
endpoint = https://eu2.contabostorage.com/

[minecraft]
type = alias
remote = contabo:/minecraft-server
```

This configuration must now be loaded into the container as a secret.
Target file is ``/run/secrets/rcloneconfig``.
If the target file is found, the backup starts each container start.

### Envs for Backup Settings

For exact details please refer to ``backup.sh``.

- ``BACKUP_FILE_FORMAT``:
This can be used to specify the backup timestamp.
It uses the date command line tool to interpret the placeholder varibales (``date ${BACKUP_FILE_FORMAT}``).  
- ``BACKUP_TARGET``: Rclone backup target name
- ``MAX_AGE_BACKUP_FILES``:
Specify the maximum length of time a backup file should be kept. One backup file is always kept.
- ``POST_START_BACKUP``: Enable backup after server stop
- ``PRE_START_BACKUP``: Enable pre start backup  
- ``BACKUP_SUCCESS_SCRIPT``: Will be executed when the backup creation was successful.
- ``BACKUP_FAILED_SCRIPT``: Will be executed when the backup creation has failed.

An example for a `BACKUP_FAILED_SCRIPT` could look as following.
```
curl -u "user:password" -d "$MESSAGE" "https://ntfy.example.com/minecraft_backups?title=Backup%Failed"
```

The `$MESSAGE` environment variable will contain the stdout and stderr from the backup script.

### Why pre and post backups

The pre backups are necessary because the post backups are only executed when the Minecraft server shuts down by itself, for example by a ``/stop`` command. A Docker stop or Docker kill does not execute the backup anymore

---

© 2024 Ringo Hoffmann (zekro Development)  
Corvered by the MIT Licence.
