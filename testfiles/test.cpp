#include <iostream>
#include <vector>
#include <algorithm>

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

    sort(vec.begin(), vec.end(), [argc](const int & a, const int & b) -> bool { 
        int c = b - argc;
        return a > c;
    });

    return 0;
}
