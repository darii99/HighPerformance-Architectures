#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#define NUM_THREADS 5

void* printHello(void* threadId) {
    long tid = (long)threadId;
    printf("Hello from thread #%ld\n", tid);
    pthread_exit(NULL);
    return(NULL);
}

int main() {
    pthread_t threads[NUM_THREADS];
    int rc;
    for(long t =0; t < NUM_THREADS; t++) {
        printf("Creating thread %ld\n", t);
        rc = pthread_create(&threads[t], NULL, printHello, (void*)t);
        if(rc) {
            printf("Error: Unable to create thread, %d\n", rc);
            exit(-1);
        }
    }


    for(long t=0; t < NUM_THREADS; t++) {
        pthread_join(threads[t], NULL);
    }

    printf("Main thread completing\n");

    return 0;
}
