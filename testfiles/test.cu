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
auto fn(T arg) {
    return std::vector<T>({arg});
}

__host__ __device__ float dev(float arg0) {
    return arg0 + 1.f;
}

template<typename T>
__global__ void kernel(const T* arg0, float* arg1, int N) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= N)
        return;

    arg1[i] = dev(static_cast<T>(arg0[i]));
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
    
    int* input;
    float* result;
    int N = 256;
    kernel<int><<<dim3(16), dim3(16)>>>(input, result, N);

    cudaDeviceReset();
    return 0;
}
