#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[]){
    int p2c[2],c2p[2];

    if(pipe(p2c)==-1||pipe(c2p)==-1){
        printf("pingpong: create pipe error");
        exit(1);
    }
    int pid=fork();
    char buf[64];
    if(pid == 0){ //child 
        read(p2c[0], buf, 4);
        printf("%d: received %s\n", getpid(), buf);
        write(c2p[1], "ping", strlen("ping"));
    }else{
        // parent
        write(p2c[1], "pong", strlen("pang"));
        read(c2p[0], buf, 4);
        printf("%d: received %s\n", getpid(), buf);
    }
    close(p2c[0]);
    close(p2c[1]);
    close(c2p[0]);
    close(c2p[1]);
    exit(0);
}