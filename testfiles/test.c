#include <stdio.h>

void func0(int arg, char* arg2){

    printf("%p", &arg);
}

struct mystr {
   int argc; 
};

void func1(void){
    //
}

int main(int argc, char* argv[]){

    printf("%s", argv[argc-1]);
    func0(argc, *argv);

    struct mystr a;
    a.argc = 0;

    return 0;
}
