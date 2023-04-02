#lab：Xv6 and Unix utilities

##1、概述
从[官方文档][1]中，要理解一下xv6的文件系统，基础的系统调用等。
##2、代码
###2.1 Boot xv6

这个实验非常简单，配置完虚拟环境后，编译虚拟机，运行xv6虚拟机即可。

###2.2 sleep 
直接调用sleep()的系统调用

```c
#include "kernel/types.h"
#include "user/user.h"
int main(int argc, char *argv[])
{
    if(argc!=2) {
        write(2, "Usage: sleep <int>time\n", 
        strlen("Usage: sleep <int>time\n"));
        exit(1);
    }
    else
    {
        int time=atoi(argv[1]);
        sleep(time);
        exit(0);

    }
}
```
###2.3 pingpong 
这边要理解一下linux 下pipe()函数的使用，管道是半双工通信的，要记得时使用关闭一端。不然pipe会堵塞。
```c
int main(int argc, char *argv[])
{
    int fd_parent[2],fd_child[2];  /*fd_parent used to parent process communicate to child process,
                                    * /fd_child used to child process communicate to parent process*/
    // fd[0] returns the file descriptor of read end , fd[1] returns the file descriptor of write end

    char buf[1];
    if(pipe(fd_parent)||pipe(fd_child))
    {
        err_quit("pipe failed!\n");
    }
    //If pipes' creation failed  ,return "pipe failed";

    int pid=fork();
    if(pid==0)
    //If the process is the child
    {
        close(fd_parent[1]); /* Close unused write end */
        close(fd_child[0]); /* Close unused read end */
        /* because the pipe is Half duplex Communication,so it is necessary to turn off one
        * / of the receiver and transmitter.If not turned off ,pipe may become clogged. */
        if(read(fd_parent[0],buf,sizeof(buf)))
            printf("%d: received ping\n",getpid());
        write(fd_child[1],"b",sizeof("b"));
        close(fd_child[1]); /* Close unused write end */
    }
    else
    //If the process is the parent
    {
        close(fd_parent[0]); /* Close unused read end */
        close(fd_child[1]); /* Close unused write end */
        write(fd_parent[1],"a",sizeof("a"));
        if(read(fd_child[0],buf,sizeof(buf)))
            printf("%d: received pong\n",getpid());
        close(fd_parent[1]); /* Close unused write end */
    };
    exit(0);
}
```
###2.4 primes
这道题还是有点难度的，注意的点有两点：
（1） 注意父进程要在子进程之后关闭，不然会出现父进程结束了，子进程没有结束，导致一些bug
（2） 注意内存的开销，管道在使用完毕后一定要关闭。不然程序会内存不足。
```c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
void err_quit(char *msg)
//when happens error,return the msg of error.
{
    printf(msg);
    exit(1);
}

void new_process(int fd[2])
{
    close(fd[1]); /* close the write end . */
    // If not close ,after subsequent close of read head,
    // due to the write end is not close ,the pipe is not destroyed ,which will cause the
    // insufficient memory space and then can not create pipe later.
    int prime;
    if(read(fd[0],&prime,sizeof(int))!=sizeof(int))
    {
        err_quit("the prime is not successfully read from the pipe !\n");
    }
    printf("prime %d\n",prime); /* output the prime */
    int num;
    if(read(fd[0],&num,sizeof(int))==0)
    // if read(fd[0],&num,sizeof(int))=0, shows 0 bytes in pipe which  represents that all the number has been sieved.
    {
        exit(0);
    }
    else
    {
        int new_fd[2]; /* Used as two file descriptors, when create a new pipe. */
        if(pipe(new_fd)) /* create a new pipe */
        {
            err_quit("new pipe's creation failed");
        };
        if(fork()==0)
        {
            new_process(new_fd);
            // the child process
        }
        else
        {
            close(new_fd[0]); /* close the read end */
            if(num%prime)
            {
                write(new_fd[1],&num,sizeof(int));
            }

            while(read(fd[0],&num,sizeof(int))==sizeof(int))
            //  read data in the read end
            {
                if(num%prime)
                {
                    write(new_fd[1],&num,sizeof(int));
                }
            }
            close(fd[0]);
            close(new_fd[1]);
            wait(0); /* wait until all the child processes has been ended */
        };
    }
    exit(0);
}

int main() {
    int fd[2]; /* Used as two file descriptors, when create a pipe. */
    if (pipe(fd)) /* create a new pipe */
    {
        err_quit("pipe's creation failed");
    };

    if (fork() == 0)
        // if the process is the child.
    {
        new_process(fd);
    } else
        // if the process is the parent.
    {
        close(fd[0]); /* close the read end */
        for (int i = 2; i <= 35; i++) {
            if (write(fd[1], &i, sizeof(int)) != 4) {
                err_quit("the number is not successfully writen into the pipe !");
            };
        }
        close(fd[1]); /* Number's input has stopped, close the write end to avoid clogging */
        wait(0); /* wait until all the child processes has been ended */
        exit(0);
    }
    return 0;
}
```
###2.5 find
写这道题前要先看一下ls.c文件，理解stat和dirent两个结构体。
state：
```c
#define T_DIR     1   // Directory 
#define T_FILE    2   // File 
#define T_DEVICE  3   // Device 

struct stat {
  int dev;     // File system's disk device
  uint ino;    // Inode number
  short type;  // Type of file
  short nlink; // Number of links to file
  uint64 size; // Size of file in bytes
};
```
在[官方文档][1]的91页的8.11中定义了dirent的数据结构。"*Each entry is a struct dirent (kernel/fs.h:56), which contains a name and an inode number. The name is at most DIRSIZ (14) characters;*"。dirent包含了目录的名字和目录的索引节点（inode）。
dirent:
```c
#define DIRSIZ 14

struct dirent {
  ushort inum;
  char name[DIRSIZ];
};

```
其次要懂得 open()函数,fstat()函数的作用,这些函数都写在user.h文件里面，属于系统调用。
```c
int open(const char*, int);
//函数的第一个参数是文件的路径，第二个参数用来控制打开的模式，函数调用成功，
//返回一个系统描述符fd。
int fstat(int fd, struct stat*);
// 函数的第一个参数是文件的文件描述符，第二个参数是struct stat的指针，调用成功
//函数返回1，失败则返回0，调用成功后文件的属性信息存放在stat中
int stat(const char*, struct stat*);
// 函数第一个参数是文件的路径，第二个参数strut stat的指针，调用成功返回1，失败则返回1。调用成功后文件的属性信息会存放在stat中。
```
查找的具体算法为深度优先搜索算法，代码难度不高，注意删除不用的文件描述符，不然会导致内存不足。
以下为具体代码:
```c
void find(char* path ,const char *filename)
{
    char buf[512],*p;
    int fd;
    struct dirent de;
    struct stat st;

    if((fd = open(path, 0)) < 0){
        fprintf(2, "find: cannot open %s\n", path);
        return;
    }

    if(fstat(fd, &st) < 0){
        fprintf(2, "find: cannot stat %s\n", path);
        close(fd);
        return;
    }

    strcpy(buf, path);
    p = buf+strlen(buf);
    *p++ = '/';
    while(read(fd, &de, sizeof(de)) == sizeof(de))
    //
    {
        if(de.inum == 0)
            continue;
        memmove(p, de.name, DIRSIZ);  /* read the name */
        p[DIRSIZ] = 0; /*  the string terminator */ 
        int temp;
        if((temp = open(buf, 0)) < 0){
            fprintf(2, "find: cannot open %s\n", buf);
            return;
        }
        if(fstat(temp, &st) < 0){
            fprintf(2, "find: cannot stat %s\n", buf);
            exit(1);
        }
        if(st.type==T_DIR&&strcmp(p,".")&&strcmp(p,".."))
            // to avoid the parent directory and the child directory
            find(buf,filename);
        // dfs ,continue to find file in the directory
        else
            if(!strcmp(p,filename))
            {
                printf("%s\n",buf);
            };
        close(temp);
        // it is necessary to close the fd,if not closed ,it will cause insufficient memory
    }
    close(fd);

}


int main(int argc, char *argv[])
{
    if(argc!=3)
    {
        fprintf(2,"usage:find <path> <filename>");
    }
    find(argv[1],argv[2]);
    exit(0);

}
```

###2.6 xargs
这道题要首先理解xv6系统中的管道和文件描述符的特殊用法。
linux管道，例如如下指令
```
COMA | COMB | COMC
```
COMA的正确输出作为COMB的正常输入，随后COMB的正常输出作为COMC的正常输入，以此类推。
xargs 的指令的作用是将管道传递过来的输入进行处理然后传递到命令的参数位置上。
那么我们如何获得之前执行过的指令的正常输出呢？
在[官方文档][1]的31页写到："*By convention, a process reads from file descriptor 0 (standard input),writes output to file descriptor 1 (standard output), andwrites error messages to file descriptor 2(standard error).*"
所以我们只要从文件描述符为0的地方读取输入信息就可以了。
```c
read(0,buf,MSGSIZE);
```
然后重新组装命令，用exec函数执行就可以了。
以下为完整代码：
```c
int main(int argc,char * argv[])
{
    char buf[MSGSIZE];
    read(0,buf,MSGSIZE);
    // read the input.
    int xagrc=0;
    char *xargv[MAXARG]; /* the parameter array on the command line about xargs  */
    for (int i=1;i<argc;++i)
    {
        xargv[xagrc]= argv[i];
        xagrc++;
    }
    // read the parameter
    char *p = buf;
    for (int i=0;i<MSGSIZE;++i)
    {
        if(buf[i]=='\n')
        // if the buf[i] read to end
        {
            int pid=fork();
            if(pid>0)
            // if the process is the parent
            {
                p=&buf[i+1];
                wait(0); // wait until the child process is ended
            }
            else
            // if the process is the child
            {
                buf[i] = 0; /* the string terminator */
                xargv[xagrc]=p;
                xagrc++;
                xargv[xagrc] = 0; /* the string terminator */
                xagrc++;
                exec(xargv[0],xargv); /* exec the comond */
                exit(0);
            }
        }
        wait(0);
    }
    exit(0);
}
```


[1]:<https://pdos.csail.mit.edu/6.S081/2020/xv6/book-riscv-rev1.pdf>





