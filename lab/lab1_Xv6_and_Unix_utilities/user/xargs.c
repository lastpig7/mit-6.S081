
/*************************************************************************
	* @File Name: xargs.c
	* @Author: song
	* @Mail: 2368338993@1qq.com
	* @Created Time:2023/4/2.
 ************************************************************************/


#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/param.h"
#define MSGSIZE  16
int main(int argc,char * argv[])
{
    char buf[MSGSIZE];
    read(0,buf,MSGSIZE);
    // read the input . By convention, a process reads
    //from file descriptor 0 (standard input), writes output to file descriptor 1 (standard output), and
    //writes error messages to file descriptor 2 (standard error).
    char *xargv[MAXARG]; /* the parameter array on the command line about xargs  */
    int xagrc=0;
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
