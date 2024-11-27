#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

// Error checking macro
#define cudaCheckError(ans) { cudaAssert((ans), __FILE__, __LINE__); }
inline void cudaAssert(cudaError_t code, const char *file, int line, bool
abort=true)
{
    if (code != cudaSuccess)
    {
        fprintf(stderr,"CUDA Error: %s at %s:%d\n", cudaGetErrorString(code), file,
        line);
        if (abort) exit(code);
    }
}

__global__ void reduceSum(int* input, int* output, int n)
{
    extern __shared__ int partialSum[];

    unsigned int tid = threadIdx.x;
    unsigned int start = 2*blockIdx.x*blockDim.x;

    partialSum[tid] = input[start + tid];
    partialSum[blockDim.x+tid] = input[start + blockDim.x+tid];

    for (unsigned int stride = 1; stride <= blockDim.x; stride *= 2)
    {
        __syncthreads();
        if (tid % stride == 0)
        partialSum[2*tid] += partialSum[2*tid + stride];
    }

    __syncthreads();
    
    if (tid == 0)
        output[blockIdx.x] = partialSum[0];
}

int main(void) {
    const int numElements = 1 << 24;
    const int threadsPerBlock = 512;
    const int blocksPerGrid = (numElements + threadsPerBlock * 2 - 1) /
    (threadsPerBlock * 2);
    const int smemSize = 2 * threadsPerBlock * sizeof(int);

    int *h_input = (int *)malloc(numElements * sizeof(int));
    int *h_output = (int *)malloc(blocksPerGrid * sizeof(int));

    // Initialize the host input vector
    for (int i = 0; i < numElements; ++i) {
    h_input[i] = rand() % 100;
    }

    int *d_input, *d_output;
    cudaCheckError(cudaMalloc((void **)&d_input, numElements * sizeof(int)));
    cudaCheckError(cudaMalloc((void **)&d_output, blocksPerGrid * sizeof(int)));

    cudaCheckError(cudaMemcpy(d_input, h_input, numElements * sizeof(int),
    cudaMemcpyHostToDevice));

    // Launch the reduction kernel
    reduceSum<<<blocksPerGrid, threadsPerBlock, smemSize>>>(d_input, d_output,
    numElements);
    cudaCheckError(cudaGetLastError());

    cudaCheckError(cudaMemcpy(h_output, d_output, blocksPerGrid * sizeof(int),
    cudaMemcpyDeviceToHost));
    
    // Complete the reduction on the CPU
    int totalSum = 0;
    for (int i = 0; i < blocksPerGrid; ++i) {
        totalSum += h_output[i];
    }
    printf("Total Sum (GPU) = %d\n", totalSum);

    int totalSumCPU = 0;
    for (int i = 0; i < numElements; i++) {
        totalSumCPU += h_input[i];
    }

    printf("Total Sum (CPU) = %d\n", totalSumCPU);

    // Free device and host memory
    cudaFree(d_input);
    cudaFree(d_output);
    free(h_input);
    free(h_output);

    return 0;
}