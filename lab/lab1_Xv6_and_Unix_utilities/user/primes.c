
/*************************************************************************
	* @File Name: primes.c
	* @Author: song
	* @Mail: 2368338993@1qq.com
	* @Created Time: 2023/3/29.
 ************************************************************************/

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




