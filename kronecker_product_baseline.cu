#include "cuda_runtime.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include "time.h"

#define A_w 50
#define A_h 50
#define B_w 32
#define B_h 32

typedef struct{
	int width;
	int height;
	float * elements;
}Matrix;

// #define 

void rightKronecker1(Matrix A, Matrix B, Matrix C){
	for(int c_row=0; c_row<C.height; c_row++){
		for(int c_col=0; c_col<C.width; c_col++){
			C.elements[c_col + c_row*C.width] = 
			A.elements[c_col/B.width + c_row/B.height * A.width]
			* B.elements[c_col%B.width + c_row%B.height*B.width];
		}
	}
}

void rightKronecker2(Matrix A, Matrix B, Matrix C){
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
//	srand((unsigned)time(NULL));
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

int main(int argc,char** argv){

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
 //        if(strcmp("-h",argv[id])==0)
 //                A_h=atoi(argv[id+1]);
 //        else if(strcmp("-w",argv[id])==0)
 //                A_w=atoi(argv[id+1]);
 //        else if(strcmp("-W",argv[id])==0)
 //                B_w=atoi(argv[id+1]);
 //        else if(strcmp("-H",argv[id])==0)
 //                B_h=atoi(argv[id+1]);
 //    }
    

    // Matrix A,d_A,B,d_B,C,d_C;
    Matrix A, B, C1, C2;
    A.width=A_w;A.height=A_h;
    B.width=B_w;B.height=B_h;
    C1.width=A_w*B_w;C1.height=A_h*B_h;
    C2.width=A_w*B_w;C2.height=A_h*B_h;

    A.elements=(float *)malloc(A.width*A.height*sizeof(float));
	B.elements=(float *)malloc(B.width*B.height*sizeof(float));
	C1.elements=(float *)malloc(C1.width*C1.height*sizeof(float));
	C2.elements=(float *)malloc(C2.width*C2.height*sizeof(float));

 //    A.elements=(float *)malloc(A.width*A.height*sizeof(float));
	// B.elements=(float *)malloc(B.width*B.height*sizeof(float));
	// C.elements=(float *)malloc(C.width*C.height*sizeof(float));

   	generatorNum(A.elements,A.width*A.height);
	generatorNum(B.elements,B.width*B.height);
	memset(C1.elements,0,C1.width*sizeof(float)*C1.height);
	memset(C2.elements,0,C2.width*sizeof(float)*C2.height);

	// printf("A.elements:\n");
	// for(int i=0;i<A.height;i++){
	// 	for(int j=0;j<A.width;j++){
	// 		printf("%d ", int(A.elements[j+i*A.width]));
	// 	}
	// printf("\n");
	// }
	// printf("B.elements:\n");
	// for(int i=0;i<B.height;i++){
	// 	for(int j=0;j<B.width;j++){
	// 		printf("%d ", int(B.elements[j+i*B.width]));
	// 	}
	// printf("\n");
	// }

	srand(time(0));
	clock_t start,finish1, finish2;
	start=clock();
	rightKronecker1(A, B, C1);
	finish1=clock();
	rightKronecker2(A, B, C2);
	finish2=clock();

	// printf("C1.elements:\n");
	// for(int i=0;i<C1.height;i++){
	// 	for(int j=0;j<C1.width;j++){
	// 		printf("%d ", C1.elements[j+i*C1.width]);
	// 	}
	// printf("\n");
	// }

	// printf("C2.elements:\n");
	// for(int i=0;i<C2.height;i++){
	// 	for(int j=0;j<C2.width;j++){
	// 		printf("%d ", C2.elements[j+i*C2.width]);
	// 	}
	// printf("\n");
	// }

	printf("Difference between 2 method:\n");
	float diff = 0;
	for(int i=0;i<C2.height;i++){
		for(int j=0;j<C2.width;j++){
			diff = C2.elements[j+i*C2.width] - C1.elements[j+i*C2.width];
		}
	}
	printf("%f\n", diff);

	printf("method1 cost time %f ms\n",(finish1-start)*1000.0/CLOCKS_PER_SEC);
	printf("method2 cost time %f ms\n",(finish2-finish1)*1000.0/CLOCKS_PER_SEC);
	// malloc matrix A B C on GPU
	// cudaMalloc(&d_A.elements,sizeof(float)*A.width*A.height);
	// cudaMalloc(&d_B.elements,sizeof(float)*B.width*B.height);
	// cudaMalloc(&d_C.elements,sizeof(float)*C.width*C.height);

	return 0;


}