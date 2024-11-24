#include <jetson-utils/videoSource.h>
#include <jetson-utils/videoOutput.h>


__global__ void plotHistogramKernel(uchar4* image, int* histogram, int width, int height, int max_freq)
    {
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    uchar4 white_pixel = make_uchar4(255, 255, 255, 255);
    //uchar4 black_pixel = make_uchar4(0, 0, 0, 255);
    float transparency_factor = 0.7;
    if (index < 256)
    {
    int freq = histogram[index] * 256 / max_freq;

    for (int i = 0; i < 256; i++)
    {
        int row = height - i - 1;
        int pixel_index= row * width +2 * index;
        if (i <= freq)
        {
            image[row * width + 2*index] = white_pixel;
            image[row * width + 2*index+1] = white_pixel;
        }
        else
        {
            image[row * width + 2*index].x *= transparency_factor;
            image[row * width + 2*index].y *= transparency_factor;
            image[row * width + 2*index].z *= transparency_factor;

            image[pixel_index +1 ].x *= transparency_factor;
            image[pixel_index +1 ].y *= transparency_factor;
            image[pixel_index +1 ].z *= transparency_factor;
        }
    }
    }
}

__global__ void rgb2grayKernel (uchar4* image, uchar4* outPut, int w, int h)
{
    int total = w * h;
    int index = threadIdx.x + blockIdx.x * blockDim.x;
    int stride = blockDim.x * gridDim.x;

    for (size_t i = index; i <total ; i+=stride)
    {
        unsigned char gray = image[i].x * 0.299 + image[i].y * 0.587 + image[i].z * 0.114;
        outPut[i].x = gray;
        outPut[i].y = gray;
        outPut[i].z = gray;
    }
}


__global__ void calcHistogramKernel (uchar4 *image, int* hvector, int w, int h) {
    
    int total = w * h;
    int index = threadIdx.x + blockIdx.x * blockDim.x;
    int stride = blockDim.x * gridDim.x;
    
    //__shared__ int h_local[256];

    if (threadIdx.x < 256) {
        hvector[threadIdx.x] = 0;
    }
    __syncthreads();

    
    for (size_t i = index; i <total ; i+=stride) {
        unsigned char gray = image[i].x;
        atomicAdd(&hvector[gray], 1);
    }
   // __syncthreads();

    //update global histogram
    //if (threadIdx.x < 256) {
     //   atomicAdd(&hvector[threadIdx.x], h_local[threadIdx.x]);
    //}

}


int main( int argc, char** argv )
{

 int max_freq= 20000;
 // create input/output streams
 videoSource* input = videoSource::Create(argc, argv, ARG_POSITION(0));
 videoOutput* output = videoOutput::Create(argc, argv, ARG_POSITION(1));
 videoOutput* output_2 = videoOutput::Create(argc,  argv, ARG_POSITION(1));

 uchar4* outPut = NULL;
 cudaMalloc(&outPut, sizeof(uchar4) * 720 *1280);
 
 //host
 int hvector[256]= {0};
    

 //device 
 int* d_hvector = NULL;
 cudaMalloc(&d_hvector, sizeof(int)*256);
 
 
 if ( !input )
    return 0;

 //capture/display loop
 while (true)
 {
    uchar4* image = NULL; // can be uchar3, uchar4, float3, float4
    int status = 0; // see videoSource::Status (OK, TIMEOUT, EOS, ERROR)
    if ( !input->Capture(&image, 1000, &status) ) // 1000ms timeout (default)
    {
        if (status == videoSource::TIMEOUT)
            continue;
            break; // EOS
    }
    if ( output != NULL )
    {
        cudaMemset(d_hvector, 0, sizeof(int)*256);
        rgb2grayKernel<<<16,256>>> (image,outPut, input -> GetWidth(), input -> GetHeight());
        calcHistogramKernel<<<16,256>>>(outPut, d_hvector, input -> GetWidth(), input-> GetHeight());
        plotHistogramKernel<<<1,256>>> (outPut, d_hvector, input -> GetWidth(), input -> GetHeight(), max_freq);

        cudaMemcpy(hvector, d_hvector, sizeof(int)*256, cudaMemcpyDeviceToHost);
        //__syncthreads();

        output->Render(outPut, input->GetWidth(), input->GetHeight());
        int sum = 0;

        for (int i = 0; i < 256; i++)
            sum += hvector[i];

        //printf("Sum is %d", sum); //Validate sum

        // Update status bar
        char str[256];
        sprintf(str, "Camera Viewer (%ux%u) | %0.1f FPS", input->GetWidth(),
        input->GetHeight(), output->GetFrameRate());
        output->SetStatus(str);

        if (!output->IsStreaming()) // check if the user quit
        break;

        /*
        if( output_2 != NULL)
        {

            output_2-> Render(outPut, input -> GetWidth(), input-> GetHeight());

            // Update status bar
        char str[256];
        sprintf(str, "Camera Viewer (%ux%u) | %0.1f FPS", input->GetWidth(),
            input->GetHeight(), output_2->GetFrameRate());
        output_2->SetStatus(str);
        if (!output_2->IsStreaming()) // check if the user quit
        break;
        }*/
    }
 }
cudaFree(outPut);
cudaFree(d_hvector);
} 