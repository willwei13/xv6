#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[]){
    if(argc<2){
        printf("sleep:lack of arg");
        exit(1);
    }
    int t=atoi(argv[1]);//change arg to int
    sleep(t);
    exit(0);
}