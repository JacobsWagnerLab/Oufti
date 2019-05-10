

#include "mex.h" // Mex header 
#include <stdio.h>
#include <ipp.h> // Intel IPP header
#include <math.h>
#include <string.h>

#ifdef MULTITHREADING_OMP
#include <omp.h> // OpenMP header
#endif

#define MAX_NUM_THREADS      4 // Max number of parallel threads that the ...
//code will try to use (Integer). Set to 1 if you want to use a single core ...
//    (typical speedup over Matlab's conv2/fft2 is 3.5x). Set >1 for ...
//    multithreading. This number should be less than the #cpus per ...
//    machine x #cores/cpu. i.e. a machine which two quad-core cpu's ...
//    could have upto 8 threads. Note that if there are fewer images than threads 
//    then the code will automatically turn down the number of threads (since the extra ones do nothing except waste
//    resources.

// Input Arguments 
#define	IMAGE   	prhs[0] // The stack of images you want to convolve: n x m x c matrix of single precision floating point numbers.
 // The kernel: i x j matrix of single precision floating point numbers. // String: either "full" or "valid". Unless string is "full", code will default to "valid".

// Output Arguments 
#define	OUTPUT   	plhs[0] // Convolved stack of images. If in valid mode, this will be (n-i+1) x (m-j+1) x c  matrix of single ...
//  precision floating point numbers. If in full mode, this will be  (n+i-1) x (m+j-1) x c  matrix of single ...
//  precision floating point numbers.
/* Display the subscript associated with th given index. */ 
float computeMax(float *imagep,int stepByte,IppiSize imageSize,int numImages,int num_threads){
    int i;
    float max,*src,dst,arrayDst[numImages];
    IppStatus retval;
    if (numImages < num_threads){
        num_threads = numImages;
    }
    #pragma omp parallel for shared(retval,src,dst,arrayDst,imagep,stepByte,imageSize,numImages,num_threads) private(i)
    
    for (i = 0; i<numImages;i++){
        src = (float*)imagep + (i*imageSize.width*imageSize.height);
        ippiMax_32f_C1R(src,sizeof(float)*stepByte,imageSize,&dst);
        arrayDst[i] = dst;
        // Parse any error (can't put inside inner loop as it will stop ...
        //  multithreading)
       /* if (retval!=ippStsNoErr){
          mexPrintf("Error performing Min\n");}

          if (retval==ippStsNullPtrErr){
        mexErrMsgTxt("Pointers are NULL\n");}

          if (retval==ippStsSizeErr){
        mexErrMsgTxt("Sizes negative or zero\n");}

          if (retval==ippStsStepErr){
        mexErrMsgTxt("Steps negative or zero\n");}

          if (retval==ippStsMemAllocErr){
        mexErrMsgTxt("Memory allocation error\n");}  */
    }
     retval = ippiMax_32f_C1R(arrayDst,sizeof(float)*stepByte,imageSize,&max);
    return max;
}



void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
{
  int num_images,num_dims;
  float *imagep,*outputp,max;
  IppiSize output_size, image_size;

  const mwSize *imagedims;
  mwSize outputdims[3];  
  mwSize ndims = 3;
  // Check for proper number of arguments 
  if (nrhs != 1) { 
    mexErrMsgTxt("One input arguments required."); 
  } else if (nlhs > 1) {
    mexErrMsgTxt("Too many output arguments."); 
  } 
  
  
  // Get dimensions of image and kernel
    num_dims = mxGetNumberOfDimensions(IMAGE);
    imagedims = (mwSize*) mxCalloc(num_dims, sizeof(mwSize));
    imagedims = mxGetDimensions(IMAGE);
    
    image_size.width = imagedims[1];
    image_size.height = imagedims[0];
      if (num_dims == 2){
        num_images = 1;
      }
      else{
        num_images = imagedims[2];
        }

  // *****************************************************************************************************
  // Main part of code
  
  //*******************************************************************************
    
    
	// set pointer offset for input
	imagep = (float*)mxGetData(IMAGE);

	
    if (num_images ==1){
      ippiMax_32f_C1R(imagep,sizeof(float)*image_size.width,image_size,&max);
    }
    else{
        max = computeMax(imagep,image_size.width,image_size,num_images,MAX_NUM_THREADS);
    }
    /*create space for output*/
    
 	 OUTPUT = mxCreateNumericMatrix(1,1, mxSINGLE_CLASS, mxREAL);
     outputp = (float*)mxGetPr(OUTPUT);
     outputp[0] = max;
     //mexPrintf("%d",max);
   return;
    
}

