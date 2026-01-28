# Truenas Encrypted ZFS Unlocking with Self-Managed Keys

[![GitHub License](https://img.shields.io/github/license/thorpejosh/truenas-zfs-unlock)](https://github.com/ThorpeJosh/truenas-zfs-unlock/blob/main/LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/thorpejosh/truenas-zfs-unlock)](https://github.com/thorpejosh/truenas-zfs-unlock/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/thorpejosh/truenas-zfs-unlock)](https://hub.docker.com/r/thorpejosh/truenas-zfs-unlock)
[![Tests](https://github.com/ThorpeJosh/truenas-zfs-unlock/actions/workflows/test.yml/badge.svg)](https://github.com/ThorpeJosh/truenas-zfs-unlock/actions/workflows/test.yml)
[![Publish Docker Image](https://github.com/ThorpeJosh/truenas-zfs-unlock/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/ThorpeJosh/truenas-zfs-unlock/actions/workflows/docker-publish.yml)
[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/ThorpeJosh/truenas-zfs-unlock/main.svg)](https://results.pre-commit.ci/latest/github/ThorpeJosh/truenas-zfs-unlock/main)

This tool grants you full control of your Truenas ZFS encryption keys by enabling offsite key storage, remote dataset unlocking, and automated control over when your datasets are unlocked.

## Why?
ZFS dataset encryption provides a multitude of security benefits, chiefly; the securing of hardware data drives when at rest, in transit, after disposal, and in the event of theft.

Unfortunately, by default Truenas stores ZFS dataset encryption keys on the boot drive. As the boot drive is physically located with all the encrypted drives the benefits of zfs encryption are undermined.

To protect the data on your drives from unauthorised access during transportation or in the event of theft, keys cannot be stored locally on your Truenas server.

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

This image uses the [semver](https://semver.org/) format for releases, ~~with this image's major version matching the Truenas API major version in use~~.
~~For example, all `2.*.*` image releases use Truenas API `v2`~~.

**Note:** Truenas has changed their api versioning and introduced breaking changes between versions 25.04 and 25.10, see release notes to ensure compatibility.

**Avoid using the `latest` tag in production environments. Lock the tag to a specific version.**

### Registries
The image is published on both [docker.io](https://hub.docker.com/r/thorpejosh/truenas-zfs-unlock) and [ghcr.io](https://github.com/ThorpeJosh/ssh-agent-docker/pkgs/container/truenas-zfs-unlock), and can be pulled with either:
``` shell
docker pull thorpejosh/truenas-zfs-unlock:latest
docker pull ghcr.io/thorpejosh/truenas-zfs-unlock:latest
```

## How to use this image
This tool is designed to run on a machine that has network access to the Truenas server, preferably in a different physical location for enhanced security. This image can run on a cloud server, raspberry pi, laptop, workstation, etc.

Firstly set up (or edit) your zfs datasets to use "Passphrase" encryption, this will enable you to set the key yourself and therefore the encryption keys won't be stored by Truenas.

Generate a Truenas API key in the web UI, as this tool works by sending unlock requests via the Truenas API.

Several environment variables below need to be configured for the tool to function.

### Environment Variables

| Env Variable               | Example                         | Function                                                                                                                          |
|:--------------------------:|:-------------------------------:|-----------------------------------------------------------------------------------------------------------------------------------|
| TZ                         | TZ=America/Chicago              | *Optional.* Used to set timezone for crontab and log messages. *Default='UTC'*                                                    |
| TRUENAS_HOST               | TRUENAS_HOST=10.0.0.1:443       | IP:port or hostname of Truenas Server                                                                                             |
| TRUENAS_API_KEY            | TRUENAS_API_KEY=1-5x23jkKKsy    | Truenas API Key                                                                                                                   |
| SKIP_CERT_VERIFY           | SKIP_CERT_VERIFY=true           | *Optional.* Set to `true` to skip Truenas SSL/TLS certificate verification. Required for self-signed certs. *Default=false*       |
| CRONTAB                    | CRONTAB=*/10 * * * * * * unlock | *Optional.* Enables running on a schedule with vixie cron expressions:<br>`s m h dom month dow year command`                      |
| ZFS__\<pool\>__\<dataset\> | ZFS__tank__photos=@#$^1234asdf  | Declare a dataset(s) to unlock. The zfs `pool/dataset` are declared after the `ZFS__` prefix, and the value is the passphrase/key |

### Environment Variables from Files (Docker Secrets)

You can set any environment variable from a file by prepending it with `FILE__`.

For example if you had a file mounted at `/run/secrets/dataset_key` that contained your zfs `pool/dataset` encryption key then simply set an environment variable `FILE__ZFS__pool__dataset=/var/run/secrets/dataset_key`

### Running on demand
If you want to manually unlock your datasets, override the container entry command with `unlock`.
#### docker-compose
```yaml
---
services:
  truenas_unlock:
    image: thorpejosh/truenas-zfs-unlock:latest
    environment:
      - TRUENAS_HOST=10.0.0.1:443
      - TRUENAS_API_KEY=1-5x23jkKKsy
      - SKIP_CERT_VERIFY=true
      - ZFS__tank__photos=SomeSecureKey
    command: unlock
```
#### docker run

```shell
docker run --rm \
    -e TRUENAS_HOST=10.0.0.1:443 \
    -e TRUENAS_API_KEY=1-5x23jkKKsy \
    -e SKIP_CERT_VERIFY=true \
    -e ZFS__tank__photos=SomeSecureKey \
    thorpejosh/truenas-zfs-unlock:latest unlock
```

### Running on a schedule
If you want your datasets to unlock automatically when your Truenas server boots, then set a cron schedule to run every 10 seconds (The datasets will unlock before VMs or Kubernetes are deployed). To achieve this set a `CRONTAB=*/10 * * * * * * unlock` environment variable.

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
      - SKIP_CERT_VERIFY=true
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
      - SKIP_CERT_VERIFY=true
      - FILE__TRUENAS_API_KEY=/run/secrets/TRUENAS_API_KEY
      - FILE__ZFS__tank__home=/run/secrets/ZFS_HOME_KEY
      - FILE__ZFS__tank__photos=/run/secrets/ZFS_PHOTOS_KEY
      # supercronic allows vixie cron expressions:
      # s m h dom month dow year command
      - CRONTAB=*/10 * * * * * * unlock
    restart: unless-stopped
```
