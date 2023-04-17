# lab: System Calls

## 1、概述
这个lab的主要是写两个系统调用（trade和sysinfo），要了解一下系统调用的过程。
[XV6_Book][1]的4.3、4.4具体讲了系统调用的代码和如何获取系统调用的参数。
系统调用参数是放在了寄存器*a0 a1*中，系统调用号是放在了*a7*中，可以通过*struct pro*中的*tramfame*得到。系统调用是运用了c中的函数指针来实现的。
```c
static uint64 (*syscalls[])(void) = {
[SYS_fork]    sys_fork,
[SYS_exit]    sys_exit,
[SYS_wait]    sys_wait,
[SYS_pipe]    sys_pipe,
[SYS_read]    sys_read,
[SYS_kill]    sys_kill,
[SYS_exec]    sys_exec,
[SYS_fstat]   sys_fstat,
[SYS_chdir]   sys_chdir,
[SYS_dup]     sys_dup,
[SYS_getpid]  sys_getpid,
[SYS_sbrk]    sys_sbrk,
[SYS_sleep]   sys_sleep,
[SYS_uptime]  sys_uptime,
[SYS_open]    sys_open,
[SYS_write]   sys_write,
[SYS_mknod]   sys_mknod,
[SYS_unlink]  sys_unlink,
[SYS_link]    sys_link,
[SYS_mkdir]   sys_mkdir,
[SYS_close]   sys_close,
[SYS_trace]   sys_trace,
[SYS_sysinfo]  sys_sysinfo,
};
```
系统调用的返回值则放在了*p->trapframe->a0*中，如果失败则返回-1。

## 2、代码
### 2.1 System call tracing
这个lab需要我们实现trace的系统调用。通过整数的掩码，来追踪系统调用，返回进程号、系统调用名、系统调用的返回值。
首先在进程的*proc*结构体中新增用于trace的标记变量*tmask*。

```c
struct proc {
  struct spinlock lock;

  // p->lock must be held when using these:
  enum procstate state;        // Process state
  struct proc *parent;         // Parent process
  void *chan;                  // If non-zero, sleeping on chan
  int killed;                  // If non-zero, have been killed
  int xstate;                  // Exit status to be returned to parent's wait
  int pid;                     // Process ID
  int tmask;                   // trace  mask
  // these are private to the process, so p->lock need not be held.
  uint64 kstack;               // Virtual address of kernel stack
  uint64 sz;                   // Size of process memory (bytes)
  pagetable_t pagetable;       // User page table
  struct trapframe *trapframe; // data page for trampoline.S
  struct context context;      // swtch() here to run process
  struct file *ofile[NOFILE];  // Open files
  struct inode *cwd;           // Current directory
  char 
  name[16];               // Process name (debugging)
};
```
在sysproc.c中新增sys_trace函数，当进程调用trace这个系统调用时，对进程*pro*中的tmask进行赋值。
```c
// fetch the trace mask 
uint64
sys_trace(void)
{
  int * mask =&(myproc()->tmask); // get the pointer of the tmask.
  argint(0, mask);  // *(mask) = register a0 , get the value of the tmask from register a0.
  return 0;
}
```
之后不要忘了进程fork()后，子进程继承父进程的mask。
```c
int fork()
{
  ...
  pid = np->pid;
  np->tmask = p ->tmask;
  np->state = RUNNABLE;
  ...
}
```

在syscall.c中，继续修改syscall函数。计算系统调用的掩码和mask，进行输出。
```c
static char *syscalls_name[] = {
[SYS_fork]    "fork",
[SYS_exit]    "exit",
[SYS_wait]    "wait",
[SYS_pipe]    "pipe",
[SYS_read]    "read",
[SYS_kill]    "kill",
[SYS_exec]    "exec",
[SYS_fstat]   "fstat",
[SYS_chdir]   "chdir",
[SYS_dup]     "dup",
[SYS_getpid]  "getpid",
[SYS_sbrk]    "sbrk",
[SYS_sleep]   "sleep",
[SYS_uptime]  "uptime",
[SYS_open]    "open",
[SYS_write]   "write",
[SYS_mknod]   "mknod",
[SYS_unlink]  "unlink",
[SYS_link]    "link",
[SYS_mkdir]   "mkdir",
[SYS_close]   "close",
[SYS_trace]   "trace",
[SYS_sysinfo]    "sys_info",
};

void
syscall(void)
{
  int num;
  struct proc *p = myproc();

  num = p->trapframe->a7;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) 
  {
    p->trapframe->a0 = syscalls[num]();  
    if(1 << num & p->tmask)
    {
      printf("%d: syscall %s -> %d \n",p->pid, 
              syscalls_name[num],p->trapframe->a0);
    }
  }
  else 
  {
    printf("%d %s: unknown sys call %d\n",
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }
}

```
### 2.2 Sysinfo 
这个lab需要我们增加一个得到sysinfo的系统调用，我们需要得知剩余内存的大小和unused的进程数。
关于如果得到unsed的进程数，我们查看proc的结构体。
```c
enum procstate { UNUSED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };

// Per-process state
struct proc {
  struct spinlock lock;

  // p->lock must be held when using these:
  enum procstate state;        // Process state
···
};
```
发现proc结构体中通过state变量来保存进程的状态。
其次在proc.c文件中，通过一个proc的数组来管理proc，同时规定了数组的大小。
```c
···
struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

···
```
于是我们可以通过遍历proc的数组，筛选其state的值，就可以得到unused的进程数。
在proc.c中定义freeproc()函数。
```c
···
// fetch the number of free proc 
void            
freeproc(uint64* dst)
{
  *(dst)=0;
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++)
  {
    if(p->state != UNUSED)
       *(dst)+=1; 
  }
} 

```

关于如何得到可用空间数，再在kalloc.c文件中，它是通过一个前插链表*kmem.freelist*,其永远指向最后一个可用页，不断前插这个链表，直到NULL为止，就可以获得页数的数量，从而得到可用空间数。
```c
//fetch the amount of free memory.
//Get the memory size in bytes.
void freememory(uint64 *bytes)
{
  struct run *r;
  (*bytes)=0;
  acquire(&kmem.lock);
  r= kmem.freelist;
  while(r>0)
  {
    r = r->next;
 //   printf("freememory r:%d\n",r);
    (*bytes) += PGSIZE;
  }
  release(&kmem.lock);
  return ;
}
```
由于得到的两个返回值都在内核空间中，我们需要将其从内核空间复制到用户进程的虚拟地址，我们可以通过copyout函数将其实现
```c
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
```
该函数是将内核地址src开始的len大小的数据拷贝到用户进程pagetable的虚拟地址dstva处。
以下为在sysproc.c中定义的sys_sysinfo函数
```c
uint64
sys_sysinfo(void)
{
  uint64 addr;
  argaddr(0,&addr);
  struct proc *p = myproc();
  struct sysinfo info;
  procnum(&info.nproc);
  freememory(&info.freemem);
  // printf("sys_sysinfo procnum:%d\n",info.nproc);
  // printf("sys_sysinfo freememory:%d\n",info.freemem);
  if(copyout(p->pagetable, addr, (char *)&info, sizeof(info)) < 0)
  return -1;

  return 0;
}
```







[1]:<https://pdos.csail.mit.edu/6.S081/2020/xv6/book-riscv-rev1.pdf>