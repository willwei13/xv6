#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/sysinfo.h"
#include "user/user.h"

int main(int argc, char *argv[]){
    if(argc!=1){
        printf("sysinfo: no need for parameters");
        exit(1);
    }
    struct sysinfo info;
    sysinfo(&info);
    printf("free space:%d, used process num:%d\n",info.freemem,info.nproc);
    exit(0);
}