#include "mex.h"

mxArray *mxCreateNumericArray(mwSize ndim, const mwSize *dims, 
			       mxClassID classid, mxComplexity ComplexFlag);
mxArray *mxCreateNumericMatrix(mwSize m, mwSize n, mxClassID classid, mxComplexity ComplexFlag);
mxArray *mxCreateDoubleMatrix(mwSize m, mwSize n, 
			       mxComplexity ComplexFlag);
