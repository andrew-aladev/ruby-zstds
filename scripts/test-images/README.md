# Gentoo images for testing.

You can find them on https://hub.docker.com/u/puchuu.

## Dependencies

- docker
- buildah

## Build

Please start `docker` service.

Than add your local user to `/etc/subuid` and `/etc/subgid`:

```sh
my_user:100000:65536
```

Please ensure that your local user is in `docker` group.

Than open [`env.sh`](env.sh) and update variables.

```sh
./build.sh
./push.sh
```

Build is rootless, just use your regular `my_user`.
