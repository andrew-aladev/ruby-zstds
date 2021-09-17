# Gentoo images for software testing

You can find them on https://hub.docker.com/u/puchuu.

## Dependencies

- [buildah](https://github.com/containers/buildah)

## Build

Please add your local user to `/etc/subuid` and `/etc/subgid`:

```
my_user:100000:65536
```

Than open [`env.sh`](env.sh) and update variables.

```sh
./build.sh
./push.sh
./pull.sh
./run.sh
```

Build is rootless, just use your regular `my_user`.

## Related bugs

- [sys-libs/musl: undefined reference to __stack_chk_fail_local (x86)](https://www.openwall.com/lists/musl/2018/09/11/2)
