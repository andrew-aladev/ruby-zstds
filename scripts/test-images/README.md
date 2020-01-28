# Gentoo images for software testing

You can find them on https://hub.docker.com/u/puchuu.

## Dependencies

- `"CONFIG_X86_X32=y"` in kernel config
- docker
- buildah
- qemu `QEMU_USER_TARGETS="aarch64 aarch64_be arm armeb mips64 mips64el mips mipsel"`

## Build

Please start `docker` and `qemu-binfmt` services.

Than add your local user to `/etc/subuid` and `/etc/subgid`:

```sh
my_user:100000:65536
```

Please ensure that your local user is in `docker` group.

Than open [`env.sh`](env.sh) and update variables.

```sh
./build.sh
./push.sh
./pull.sh
./run.sh
```

Build is rootless, just use your regular `my_user`.
