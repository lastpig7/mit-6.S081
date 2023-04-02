
/*************************************************************************
	* @File Name: find.c
	* @Author: song
	* @Mail: 2368338993@1qq.com
	* @Created Time:2023/3/30.
 ************************************************************************/

#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

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






