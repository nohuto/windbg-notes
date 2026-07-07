# Executive & Kernel

`Ntoskrnl.exe` contains the Windows executive and kernel. They are conceptual layers within the same image, not separate modules.

| Layer | Purpose |
| --- | --- |
| Executive | Higher-level operating system services and policy, including process/thread, memory, I/O, security, configuration, cache, PnP and power management |
| Kernel | Low-level mechanisms including thread scheduling, synchronization, interrupt/exception dispatching and architecture-dependent processor support |

Executive components build services and managed objects from kernel mechanisms. For example, the process manager uses the kernel's process/thread implementation, while `_EPROCESS` and `_ETHREAD` add executive state around embedded `_KPROCESS` and `_KTHREAD` objects.

Thread scheduling is implemented by the kernel even though process/thread management is exposed as an executive service.

| Prefix | Area |
| --- | --- |
| `Ex` | Executive support |
| `Ke` | Kernel |
| `Ki` | Internal kernel implementation |
| `Ps` | Process/thread manager |
| `Mm` | Memory manager |
| `Io` | I/O manager |
| `Ob` | Object manager |
| `Se` | Security reference monitor |

See Windows Internals [Chapter 2, System Architecture](https://github.com/nohuto/windows-books/releases/download/7th-Edition/Windows-Internals-E7-P1.pdf) for the complete component overview.
