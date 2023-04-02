/*************************************************************************
	* @File Name: pingpong.c
	* @Author: song
	* @Mail: 2368338993@1qq.com
	* @Created Time: 2023/3/27.
 ************************************************************************/


#include "kernel/types.h"
#include "user/user.h"
#include "kernel/stat.h"
#include "stddef.h"
void err_quit(char *msg)
//when happens error,return the msg of error.
{
    printf(msg);
    exit(1);
}


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





