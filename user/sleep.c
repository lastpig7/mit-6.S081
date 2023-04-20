/*************************************************************************
	* @File Name: pingpong.c
	* @Author: song
	* @Mail: 2368338993@1qq.com
	* @Created Time: 2023/3/27.
 ************************************************************************/

#include "kernel/types.h"
#include "user/user.h"
int main(int argc, char *argv[])
{
    if(argc!=2) {
        write(2, "Usage: sleep <int>time\n", strlen("Usage: sleep <int>time\n"));
        exit(1);
    }

    else
    {
        int time=atoi(argv[1]);
        sleep(time);
        exit(0);

    }
}





