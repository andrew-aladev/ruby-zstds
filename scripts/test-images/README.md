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

- [dev-lang/ruby-3.1.*: patch -p1 failed with 900-musl-coroutine.patch](https://bugs.gentoo.org/835038)
