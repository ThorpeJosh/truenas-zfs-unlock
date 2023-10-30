# Truenas Encrypted ZFS Unlocking with Self-Managed Keys

[![GitHub License](https://img.shields.io/github/license/thorpejosh/truenas-zfs-unlock)](https://github.com/ThorpeJosh/truenas-zfs-unlock/blob/main/LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/thorpejosh/truenas-zfs-unlock)](https://github.com/thorpejosh/truenas-zfs-unlock/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/thorpejosh/truenas-zfs-unlock)](https://hub.docker.com/r/thorpejosh/truenas-zfs-unlock)
[![Tests](https://github.com/ThorpeJosh/truenas-zfs-unlock/actions/workflows/test.yml/badge.svg)](https://github.com/ThorpeJosh/truenas-zfs-unlock/actions/workflows/test.yml)
[![Publish Docker Image](https://github.com/ThorpeJosh/truenas-zfs-unlock/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/ThorpeJosh/truenas-zfs-unlock/actions/workflows/docker-publish.yml)

Gives you control of your Truenas ZFS encryption keys by allowing you to store your keys offsite, unlock your datasets remotely, and unlock your data only when you need.

## Why?
ZFS dataset encryption provides many security benefits, some of the main ones being; the securing of physical data drives at rest, during transport, after disposal, or in the case hardware is stolen.

This all obviously relies on the proper management of the encryption keys to make sure they don't fall into the wrong hands along with the data drives.

Unfortunately Truenas stores ZFS dataset encryption keys on the boot drive which is physically located with all the encrypted drives, undermining most of the benefits of having encryption.

To protect the data on your drives from falling into the wrong hands during transport or in-case your server is stolen, then the keys cannot be stored on your Truenas server.

## Image variants
### Supported Architectures
![Architecture](https://img.shields.io/badge/architecture-amd64-blue)
![Architecture](https://img.shields.io/badge/architecture-arm64-blue)
![Architecture](https://img.shields.io/badge/architecture-arm/v7-blue)
![Architecture](https://img.shields.io/badge/architecture-arm/v6-blue)
![Architecture](https://img.shields.io/badge/architecture-ppc64le-blue)
![Architecture](https://img.shields.io/badge/architecture-s390x-blue)
![Architecture](https://img.shields.io/badge/architecture-386-blue)

### Shared tags
* `latest`, `${IMAGE_VERSION}`

This image uses semver releases with the major version matching the Truenas API version that is used.

> [!NOTE]  
> Avoid using the `latest` tag in production environments  
> Lock the tag to a specific version

### Registries
The image is published on both [docker.io](https://hub.docker.com/r/thorpejosh/truenas-zfs-unlock) and [ghcr.io](https://github.com/ThorpeJosh/ssh-agent-docker/pkgs/container/truenas-zfs-unlock), and can be pulled with either:
``` shell
docker pull thorpejosh/truenas-zfs-unlock:latest
docker pull ghcr.io/thorpejosh/truenas-zfs-unlock:latest
```

## How to use this image
This tool is designed to be run on a machine that has network access to your Truenas server but preferably not in the same location. It can run on a cloud server, raspberry pi, laptop, workstation, etc.

Firstly setup (or edit) your zfs datasets to use "Passphrase" encryption so that you set the key yourself and it won't be stored by Truenas. Use a password generator and make it long (128 characters for example).

Generate a Truenas API key in the web UI.

The container works by making requests to the Truenas API. A few environment variables need to be configured before it will work

### Environment Variables

| Env Variable               | Example                         | Function                                                                                                                          |
|:--------------------------:|:-------------------------------:|-----------------------------------------------------------------------------------------------------------------------------------|
| TZ                         | TZ=America/Chicago              | *Optional.* Used to set timezone for crontab and log messages. *Default='UTC'*                                                    |
| TRUENAS_HOST               | TRUENAS_HOST=10.0.0.1:443       | IP:port or hostname of Truenas Server                                                                                             |
| TRUENAS_API_KEY            | TRUENAS_API_KEY=1-5x23jkKKsy    | Truenas API Key                                                                                                                   |
| CRONTAB                    | CRONTAB=*/10 * * * * * * unlock | *Optional.* Enables running on a schedule with vixie cron expressions:<br>`s m h dom month dow year command`                         |
| ZFS__\<pool\>__\<dataset\> | ZFS__tank__photos=@#$^1234asdf   | Declare a dataset(s) to unlock. The zfs `pool/dataset` are declared after the `ZFS__` prefix, and the value is the passphrase/key |

### Environment Variables from Files (Docker Secrets)

You can set any environment variable from a file by prepending it with `FILE__`.

For example if you had a file mounted at `/run/secrets/dataset_key` that contained your zfs `pool/dataset` encryption key then simply set an environment variable `FILE__ZFS__pool__dataset=/var/run/secrets/dataset_key`

### Running on demand
If you want to unlock your datasets manually, then override the container command with `unlock`.
For docker compose use `command: unlock`:
```yaml
---
services:
  truenas_unlock:
    image: thorpejosh/truenas-zfs-unlock:latest
    environment:
      - TRUENAS_HOST=10.0.0.1:443
      - TRUENAS_API_KEY=1-5x23jkKKsy
      - ZFS__tank__photos=SomeSecureKey
    command: unlock
```
For docker run add the `unlock` command after the image:

``` shell
docker run --rm \
    -e TRUENAS_HOST=10.0.0.1:443 \
    -e TRUENAS_API_KEY=1-5x23jkKKsy \
    -e ZFS__tank__photos=SomeSecureKey \
    thorpejosh/truenas-zfs-unlock:latest unlock
```

### Running on a schedule
If you want to unlock your datasets automatically when you Truenas server starts then setting a cron schedule to run every 10 seconds works well (The datasets will unlock before VMs or Kubernetes deploys). This can be achieved by setting a `CRONTAB=*/10 * * * * * * unlock` environment variable.

#### docker-compose
```yaml
---
services:
  truenas_unlock:
    image: thorpejosh/truenas-zfs-unlock:latest
    environment:
      - TZ=America/Chicago
      - TRUENAS_HOST=10.0.0.1:443
      - TRUENAS_API_KEY=1-5x23jkKKsy
      - ZFS__tank__home=someRandomGeneratedKey
      - ZFS__tank__photos=SomeSecureKey
      # supercronic allows vixie cron expressions:
      # s m h dom month dow year command
      - CRONTAB=*/10 * * * * * * unlock
    restart: unless-stopped
```
#### docker-compose using secrets
```yaml
---
secrets:
  TRUENAS_API_KEY:
    file: ${PWD}/.secrets/.api_key
  ZFS_HOME_KEY:
    file: ${PWD}/.secrets/.home_key
  ZFS_PHOTOS_KEY:
    file: ${PWD}/.secrets/.photos_key

services:
  truenas_unlock:
    image: thorpejosh/truenas-zfs-unlock:latest
    secrets:
      - TRUENAS_API_KEY
      - ZFS_HOME_KEY
      - ZFS_PHOTOS_KEY
    environment:
      - TZ=America/Chicago
      - TRUENAS_HOST=10.0.0.1:443
      - FILE__TRUENAS_API_KEY=/run/secrets/TRUENAS_API_KEY
      - FILE__ZFS__tank__home=/run/secrets/ZFS_HOME_KEY
      - FILE__ZFS__tank__photos=/run/secrets/ZFS_PHOTOS_KEY
      # supercronic allows vixie cron expressions:
      # s m h dom month dow year command
      - CRONTAB=*/10 * * * * * * unlock
    restart: unless-stopped
```
