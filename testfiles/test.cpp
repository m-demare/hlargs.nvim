#include <iostream>
#include <vector>
#include <algorithm>

class MyClass {
    int arg0_;
    float* arg1;
    MyClass(int arg0, float* arg1): arg0_(arg0){
        this->arg1 = arg1;
    }

    int fn(char* arg2, int arg3 = 0){
        return arg3 + arg2[0];
    }
};

struct mystr {
    int argc;
};

template<typename T>
void fn(T arg) {
    return std::vector<T>({arg});
}

int main(int argc, char* argv[]){

    std::cout<<argv[argc-1]<<std::endl;

    std::vector<int> vec;
    struct mystr a;
    a.argc = 0;

    try {
        sort(vec.begin(), vec.end(), [argc](const int & a, const int & b) -> bool {
            int c = b - argc;
            return a > c;
        });
    } catch (const std::exception& e) {
        std::cout << e.what();
    }

    return 0;
}
