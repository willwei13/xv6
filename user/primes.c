#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

void primes(int p[2]){
    int num,prime;
    int p1[2];
    close(p[1]);
    if(read(p[0],&prime,4)==0){
        close(p[0]);
        exit(1);
    }
    else{
        printf("prime %d\n",prime);
        pipe(p1);
        if(fork()==0){
            close(p[0]);
            primes(p1);
        }
        else{
            close(p1[0]);
            while(read(p[0],&num,4)){
                if(num%prime!=0)
                    write(p1[1],&num,4);
            }
            close(p[0]);
            close(p1[1]);
            wait(0);
        }
    }
    exit(0);
}

int main(int argc, char *argv[]){
    if(argc>1){
        printf("primes: illegal argument");
        exit(1);
    }
    int p[2];
    pipe(p);
    if(fork()==0){
        primes(p);
    }
    else{
        close(p[0]);
        for(int i=2;i<36;i++)
            write(p[1],&i,4);
        close(p[1]);
        wait(0);
    }
    exit(0);
}