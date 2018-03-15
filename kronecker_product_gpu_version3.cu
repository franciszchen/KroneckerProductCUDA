#include "cuda_runtime.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include "time.h"
#include "math.h"

#define block_size 1024
#define A_w 50
#define A_h 50
#define B_w 32
#define B_h 32

typedef struct{
	int width;
	int height;
	float * elements;
}Matrix;



__global__ void rightKronecker_gpu2(float *A, float *B, float *C, 
	int A_height, int A_width, int B_height, int B_width, int C_height, int C_width){
	
	int bid = (blockIdx.x );
	int a_col = bid%A_width ;
	int a_row = bid/A_width;

	int tid = (threadIdx.x  );//
	int b_col = tid%B_width ;
	int b_row = tid/B_width;

	if(bid<A_width*A_height&&tid<B_width*B_height){
		
		C[(b_col+a_col*B_width)+(b_row+a_row*B_height)*A_width*B_width] = 
			A[a_col + a_row * A_width]
			* B[b_col + b_row * B_width];
		
		
		// tid += blockIdx.x*blockDim.x;
		__syncthreads();
		
		
	}
}

void rightKronecker_cpu1(Matrix A, Matrix B, Matrix C){
	for(int c_row=0; c_row<C.height; c_row++){
		for(int c_col=0; c_col<C.width; c_col++){
			C.elements[c_col + c_row*C.width] = 
			A.elements[c_col/B.width + c_row/B.height * A.width]
			* B.elements[c_col%B.width + c_row%B.height*B.width];
		}
	}
}

void rightKronecker_cpu2(Matrix A, Matrix B, Matrix C){
	for(int a_row=0; a_row<A.height; a_row++){
		for(int a_col=0; a_col<A.width; a_col++){
			for(int b_row=0; b_row<B.height; b_row++){
				for(int b_col=0; b_col<B.width; b_col++){
					C.elements[(b_col+a_col*B.width)+(b_row+a_row*B.height)*A.width*B.width] 
					= A.elements[a_col+a_row*A.width] * B.elements[b_col+b_row*B.width];
				}
			}
		}
	}
}

void generatorNum(float* array, int num)
{

	for(int i=0;i<num;i++)
	{
		array[i]=rand()%5;
	}
}

void printUsage(void)
{
    printf("\n");
    printf("The program aims to calculate the product of matrix A and B\n");
    printf("-h matrix A row num\n");
    printf("-w matrix A col num\n");
    printf("-H matrix B row num\n");
    printf("-W matrix B col num\n");
}

void displayMatrx(Matrix X){
	printf(".elements:\n");
	for(int i=0;i<X.height;i++){
		for(int j=0;j<X.width;j++){
			printf("%.1f ", X.elements[j+i*X.width]);
		}
	printf("\n");
	}
}

void computeDiff(Matrix X1, Matrix X2){
	float diff = 0;
	if(X1.height==X2.height && X1.width==X2.width){
		for(int i=0;i<X2.height;i++){
			for(int j=0;j<X2.width;j++){
				diff += abs(X2.elements[j+i*X2.width] - X1.elements[j+i*X1.width]);
			}
		}
		printf("%f\n", diff);
	}
}


int main(int argc,char** argv){
// if use command to get matrix size
	// int A_w,B_w,A_h,B_h;
 //    if(argc==1)
 //    {
 //        printf("Error: no enough parameters.Please input the col and row number of Matrix A and B,respectively\n");
 //        exit(0);
 //    }
 //    else if(argc==2)
 //    {
 //        if(strcmp("--help",argv[1])==0)
 //        {
 //            printUsage();
 //            exit(0);
 //        }

 //    }
	// for(int id=1;id<argc;id+=2)
 //    {
 //        if(strcmp("-ah",argv[id])==0)
 //                A_h=atoi(argv[id+1]);
 //        else if(strcmp("-aw",argv[id])==0)
 //                A_w=atoi(argv[id+1]);
 //        else if(strcmp("-bw",argv[id])==0)
 //                B_w=atoi(argv[id+1]);
 //        else if(strcmp("-bh",argv[id])==0)
 //                B_h=atoi(argv[id+1]);
 //    }
    // A_h = 50;
    // A_w = 50;
    // B_h = 50;
    // B_w = 50;
    

    // Matrix A,d_A,B,d_B,C,d_C;
    Matrix A, B, C_cpu1, C_cpu2, C_gpu;
    float *d_A, *d_B, *d_C;
    A.width=A_w;
    A.height=A_h;
    B.width=B_w;
    B.height=B_h;
    
    C_cpu1.width=A_w*B_w;
    C_cpu1.height=A_h*B_h;
    C_cpu2.width=A_w*B_w;
    C_cpu2.height=A_h*B_h;
    C_gpu.width=A_w*B_w;
    C_gpu.height=A_h*B_h;
   

    A.elements=(float *)malloc(A.width*A.height*sizeof(float));
	B.elements=(float *)malloc(B.width*B.height*sizeof(float));
	C_cpu1.elements=(float *)malloc(C_cpu1.width*C_cpu1.height*sizeof(float));
	C_cpu2.elements=(float *)malloc(C_cpu2.width*C_cpu2.height*sizeof(float));
	C_gpu.elements=(float *)malloc(C_gpu.width*C_gpu.height*sizeof(float));
	


   	generatorNum(A.elements,A.width*A.height);
	generatorNum(B.elements,B.width*B.height);
	memset(C_cpu1.elements,0,C_cpu1.width*sizeof(float)*C_cpu1.height);
	memset(C_cpu2.elements,0,C_cpu2.width*sizeof(float)*C_cpu2.height);
	memset(C_gpu.elements,0,C_gpu.width*sizeof(float)*C_gpu.height);


	
	cudaMalloc(&d_A,sizeof(float)*A.width*A.height);
	cudaMalloc(&d_B,sizeof(float)*B.width*B.height);
	cudaMalloc(&d_C,sizeof(float)*C_gpu.width*C_gpu.height);
	
	
	// dim3 block(block_size,block_size);
	// dim3 grid((C3.width-1+block_size)/block_size,(C3.height-1+block_size)/block_size);
	
	dim3 block(block_size);
	dim3 grid((C_gpu.width-1+block_size)/block_size);

	srand(time(0));
	clock_t start_cpu1,start_cpu2, start_gpu, start_gpu_pure, 
	finish_cpu1, finish_cpu2, finish_gpu, finish_gpu_pure;
	
	//cpu1
	start_cpu1=clock();
	rightKronecker_cpu1(A, B, C_cpu1);
	finish_cpu1=clock();
	//cpu2
	start_cpu2=clock();
	rightKronecker_cpu2(A, B, C_cpu2);
	finish_cpu2=clock();

	//gpu1**********************************************************
	start_gpu = clock();
	cudaMemcpy(d_A,A.elements,A.width*A.height*sizeof(float),cudaMemcpyHostToDevice);	
	cudaMemcpy(d_B,B.elements,B.width*B.height*sizeof(float),cudaMemcpyHostToDevice);
	
	start_gpu_pure = clock();

	rightKronecker_gpu2<<<A.width*A.height, block_size>>>
	(d_A, d_B, d_C, A.height, A.width, B.height, B.width, C_gpu.height, C_gpu.width);
	
	finish_gpu_pure = clock();
	
	cudaMemcpy(C_gpu.elements,d_C,C_gpu.width*C_gpu.height*sizeof(float),cudaMemcpyDeviceToHost);


	finish_gpu = clock();

	cudaFree(d_A);
	cudaFree(d_B);
	cudaFree(d_C);


	

	printf("Difference between cpu1 and cpu2:\t");
	computeDiff(C_cpu1, C_cpu2);
	printf("Difference between cpu1 and gpu2:\t");
	computeDiff(C_cpu1, C_gpu);
	
	printf("cpu1 cost time %f ms\n",(finish_cpu1 - start_cpu1)*1000.0/CLOCKS_PER_SEC);
	printf("cpu2 cost time %f ms\n",(finish_cpu2 - start_cpu2)*1000.0/CLOCKS_PER_SEC);
	printf("gpu2 cost time %f ms\tpure computing %f ms\n",(finish_gpu - start_gpu)*1000.0/CLOCKS_PER_SEC, (finish_gpu_pure - start_gpu_pure)*1000.0/CLOCKS_PER_SEC);


	

	free(A.elements);
	free(B.elements);
	free(C_cpu1.elements);
	free(C_cpu2.elements);
	free(C_gpu.elements);
	


	return 0;


}