# jless(8)
FreeBSD Jail listing and managing utility.

## FAQ
### Why `jless(8)` name?
Because that is the closest thing to FreeBSD base system `jls(8)` command and it has some reference for other known `less(8)` command.

### Why another `jail(8)` containers listing/managing tool?
Because builtin `jls(8)` is very limited and does not display VNET IP(s) and interfaces.

Also because - if You do now want to use full blown `jail(8)` manager such as BastilleBSD - which is very good by the way - the base system tools are just too limited for comfort work.

I also needed a tool that will allow me to fast start/stop/restart FreeBSD `jail(8)` containers with minimal typing - more time to focus on what matters.

Usage `help` info from the `jless(8)` command below.

```
% jless.sh help
usage:
  jless.sh            list jail(8) containers
  jless.sh -a         list jail(8) containers with all IP(s)
  jless.sh -h         show help
  jless.sh --help     show help
  jless.sh help       show help
  jless.sh version    show version

manage:
  jless.sh JAILNAME start
  jless.sh JAILNAME restart
  jless.sh JAILNAME stop
  jless.sh JAILNAME console
  jless.sh JAILNAME shell
  jless.sh JAILNAME jexec

shorts:
  jless.sh JAILNAME u   UP ------> alias for start
  jless.sh JAILNAME d   DOWN ----> alias for stop
  jless.sh JAILNAME r   RESTART -> alias for restart
  jless.sh JAILNAME c   CONSOLE -> alias for console|shell|jexec
```

... and some fancy ASCII logo.

```
% jless.sh help
             ___                    __ ____ __
        ___ /  /                   / //    \\ \
       /__//  / ____  _____ _____ / //  /  / \ \
      /  //  / /  _ \/  __//  __// / \     \ / /
     /  //  /_/  ___/\__  \\__  \\ \ /  /  // /
  __/  / \____\____/ /____//____/ \_\\____//_/
 /____/

jless(8) 0.1 2024/11/22

```

Example output from `jless(8)` listing usage.

```
% jless
JAIL       JID  TYPE  VER     DIR                    IFACE     IP(s)
----       ---  ----  ---     ---                    -----     -----
classic    5    std   13.2-R  /jail/classic          em0       10.0.0.199/32
fbsdjail   -    std   13.1-R  /jail/fbsdjail         wlan0     10.0.0.43
ctld-two   -    vnet  13.2-R  /jail/ctld-two         ${if}b    -
ctld       -    vnet  13.2-R  /jail/ctld             ${if}b    -
iscsi      -    vnet  13.2-R  /jail/iscsi            ${if}b    -
minecraft  -    std   -       [GONE]/jail/minecraft  em0       10.0.0.210
minio      -    std   14.0-R  /jail/minio            em0       10.0.0.133
nfsd       3    vnet  14.1-R  /jail/nfsd             epair99b  10.1.1.99/24
other      -    std   14.1-R  /jail/other            em0       10.0.0.199
sambajail  -    vnet  14.1-R  /jail/sambajail        ${if}b    -
unfs3      -    vnet  14.1-R  /jail/unfs3            ${if}b    -

```

EOF
