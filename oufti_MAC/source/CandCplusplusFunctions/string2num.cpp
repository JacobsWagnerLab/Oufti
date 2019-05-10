#include <math.h>
//#include <iostream.h>
#include "mex.h"
#include <stdlib.h>

void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray *prhs[] )    
{ 
 #define M_IN prhs[0]
 #define out plhs[0]
 plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
 //out = mxGetPr(plhs[0]);
 *mxGetPr(plhs[0])= M_IN;   /* Do the actual computations */
}