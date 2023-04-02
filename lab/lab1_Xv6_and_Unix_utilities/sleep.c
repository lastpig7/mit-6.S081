//
// Created by song on 2023/3/27.
//

#include "kernel/types.h"
#include "user/user.h"

int
main(int argc, char *argv[])
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





