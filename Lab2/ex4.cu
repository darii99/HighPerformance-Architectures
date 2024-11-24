#include <iostream>
#include <math.h>

__global__ void multKernel(int n, float* a, float* b, float* c, int* perm) {
 int index = blockIdx.x * blockDim.x + threadIdx.x;
 int stride = blockDim.x * gridDim.x;
 for (int i = index; i < n; i += stride) {
 int idx = perm[i];
 c[idx] = a[idx] * b[idx];
 }
}

int main() {
 int N = 1<<24; 
 int *h_perm, *d_perm;
 h_perm = new int[N];
 
 float *h_a, *h_b, *h_c;
 float *d_a, *d_b, *d_c;

 // Allocate host memory
 h_a = new float[N];
 h_b = new float[N];
 h_c = new float[N];

 // Allocate device memory
 cudaMalloc(&d_a, N * sizeof(float));
 cudaMalloc(&d_b, N * sizeof(float));
 cudaMalloc(&d_c, N * sizeof(float));
 cudaMalloc(&d_perm, N *sizeof(int));

 // Initialize host data
 for (int i = 0; i < N; i++)
 {
    h_a[i] = 2.0f;
    h_b[i] = 3.0f;
    h_perm [i] = i;
 }

 // Copy data from host to device
 cudaMemcpy(d_a, h_a, N * sizeof(float), cudaMemcpyHostToDevice);
 cudaMemcpy(d_b, h_b, N * sizeof(float), cudaMemcpyHostToDevice);

 //Ex4 
 cudaMemcpy(d_perm, h_perm, N * sizeof(float), cudaMemcpyHostToDevice);

 // Shuffle perm
 for (int i = N-1; i > 0; i--) {
    int j = rand() % (i + 1);
    std::swap(h_perm[i], h_perm[j]);
 }
 
 // Launch the kernel
 int blockSize = 256;
 int numBlocks = (N + blockSize - 1) / blockSize;
 multKernel<<<numBlocks, blockSize>>>(N, d_a, d_b, d_c, d_perm);

 // Copy result back to host
 cudaMemcpy(h_c, d_c, N * sizeof(float), cudaMemcpyDeviceToHost);

 // Check result for errors (all values should be 6.0f)
 float maxError = 0.0f;
 for (int i = 0; i < N; i++)
 maxError = fmax(maxError, fabs(h_c[i] - 6.0f));
 std::cout << "Max error: " << maxError << std::endl;

 // Clean up
 cudaFree(d_a);
 cudaFree(d_b);
 cudaFree(d_c);
 delete[] h_a;
 delete[] h_b;
 delete[] h_c;
}
