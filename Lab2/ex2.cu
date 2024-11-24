#include <iostream>
#include <math.h>

__global__ void multKernel(int n, float* a, float* b, float* c) {
 int index = threadIdx.x;
 int stride = blockDim.x;

 for (int i = index; i < n; i += stride) {
    c[i] = a[i] * b[i];
 }
}

int main() {
 int N = 1<<24;
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

 // Initialize host data
 for (int i = 0; i < N; i++) {
    h_a[i] = 2.0f;
    h_b[i] = 3.0f;
 }

 // Copy data from host to device
 cudaMemcpy(d_a, h_a, N * sizeof(float), cudaMemcpyHostToDevice);
 cudaMemcpy(d_b, h_b, N * sizeof(float), cudaMemcpyHostToDevice);

 // Launch the kernel
  multKernel<<<1, 256>>>(N, d_a, d_b, d_c);

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
