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
    //Halving size of shared mem by reducing amount of mem req / thread.
    //It's done by performing the first reduction step while also writing to shared mem.
    //Ergo: Do first summation while filling up the shared mem => reducing overall mem usage.
    extern __shared__ int sdata[];

    unsigned int tid = threadIdx.x;
    unsigned int start = 2 * blockIdx.x * blockDim.x;
    
    //Doing the first reduction step while loading into shared memory
    sdata[tid] = input[start + tid] + input[start + blockDim.x + tid];
    
    //Unrolling the loop for stride values 512, 256, 128, 256, 512
    //Exec time using this technique = 3.38ms
    if (tid < blockDim.x / 32) sdata[tid] += sdata[tid + blockDim.x / 32];  // stride = 32
    __syncthreads();

    if (tid < blockDim.x / 64) sdata[tid] += sdata[tid + blockDim.x / 64];  // stride = 16
    __syncthreads();

    if (tid < blockDim.x / 128) sdata[tid] += sdata[tid + blockDim.x / 128];  // stride = 8
    __syncthreads();

    if (tid < blockDim.x / 256) sdata[tid] += sdata[tid + blockDim.x / 256];  // stride = 4
    __syncthreads();

    if (tid < blockDim.x / 512) sdata[tid] += sdata[tid + blockDim.x / 512];  // stride = 2
    __syncthreads();

    //Slower version with loop = 3.5ms
    /*for (unsigned int stride = blockDim.x; stride > 0; stride >>= 1)
    {
        __syncthreads();
        if (tid < stride)
            sdata[tid] += sdata[tid + stride];
    }

    __syncthreads();*/

    if (tid == 0)
        output[blockIdx.x] = sdata[0];
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