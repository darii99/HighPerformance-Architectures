#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <arm_neon.h>

#define NUM_THREADS 4

typedef struct {
	int threadId;
	int startVector;
	int endVector;
	float *a;
	float *b;
	float *r;
} Worker;



void mult_std (float* a , float* b, float* r, int num)
{
	for (int i= 0; i< num; i++)
	{
		r[i] =a[i] * b[i];
	}
}

void mult_vect(float* a, float *b, float *r, int num)
{
	float32x4_t va, vb, vr;
	
	for (int i= 0; i<num; i+=4)
	{
		va = vld1q_f32(&a[i]);
		vb = vld1q_f32(&b[i]);
		
		vr = vmulq_f32(va, vb);

		vst1q_f32(&r[i], vr);
	}
}


void thread_std(void* WorkerIn)
{
	Worker *info = (Worker*) WorkerIn;
	mult_std(info ->a, info-> b, info -> r, info -> threadId);
	pthread_exit(NULL);
	return NULL;

}

void thread_vec (void* WorkerVec)
{
	Worker *vect = (Worker*) WorkerVec
	mult_vect(vect->a, vect-> b, vect -> r, vect-> threadId);
	pthread_exit(NULL);
	return 
}
int main (int argc, char *argv[]) {
	
	int num = 100000000;
	int rc;
	float *a = (float*) aligned_alloc (16, num*sizeof(float));
	float *b = (float*) aligned_alloc (16, num*sizeof(float));
	float *r = (float*) aligned_alloc (16, num*sizeof(float));
	
	for(int i = 0; i<num; i++)
	{
		a[i] = (i%127)  *0.1457f;
		b[i]= (i %331) * 0.1231f;
	}


	Worker arr[NUM_THREADS];
	
	arr[0].threadId = 0;
	arr[0].startVector = 0;
	arr[0].endVector = num/4;
	arr[0].a = 0;
	arr[0].b = 0;
	arr[0].r = 0;

	arr[1].threadId = 1;
	arr[1].startVector = num/4 +1;
	arr[1].endVector = num/2;
	arr[1].a = 1;
	arr[1].b = 1;
	arr[1].r = 1;

	arr[2].threadId = 2;
	arr[2].startVector = num/2 +1;
	arr[2].endVector = 3/4 * num;
	arr[2].a = 2;
	arr[2].b = 2;
	arr[2].r = 2;

	arr[3].threadId = 3;
	arr[3].startVector = (3/4 * num)+1;
	arr[3].endVector = num;
	arr[3].a = 3;
	arr[3].b = 3;
	arr[3].r = 3;

	pthread_t threads[NUM_THREADS];
	
	for (long t = 0; t < NUM_THREADS; t++)
	{
		printf("Creating thread %ld\n", t);
		rc= pthread_create(&threads[t], NULL, thread_std, (void*) &arr[t]);
		if(rc)
		{
			printf("Error, unable to create thread, %d\n",rc);
			exit(-1);
		}
	}
	for(long t= 0; t<NUM_THREADS;t++)
	{
		pthread_join(threads[t], NULL);
	}

	for (long t = 0; t < NUM_THREADS; t++)
	{
		printf("Creating thread %ld\n", t);
		rc= pthread_create(&threads[t], NULL, thread_vec, (void*) &arr[t]);
		if(rc)
		{
			printf("Error, unable to create thread, %d\n",rc);
			exit(-1);
		}
	}

	for(long t= 0; t<NUM_THREADS;t++)
	{
		pthread_join(threads[t], NULL);
	}

	struct timespec ts_start;
	struct timespec ts_end_1;
	struct timespec ts_end_2;

	clock_gettime(CLOCK_MONOTONIC, &ts_start);
	//mult_std(a,b,r,num);

	clock_gettime(CLOCK_MONOTONIC, &ts_end_1);
	//mult_vect(a,b,r,num);

	clock_gettime(CLOCK_MONOTONIC, &ts_end_2);
	
	double duration_std = (ts_end_1.tv_sec - ts_start.tv_sec) + (ts_end_1.tv_nsec - ts_start.tv_sec) * 1e-9;

	
	double duration_vec = (ts_end_2.tv_sec - ts_end_1.tv_sec) + (ts_end_2.tv_nsec - ts_end_1.tv_sec) * 1e-9;

	printf("Elapsed time std: %f\n", duration_std);
	printf("Elapsed time vec: %f\n", duration_vec);

	free(a);
	free(b);
	free(r);

	return 0;

}
