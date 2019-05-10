


/*
mex -v -largeArrayDims -I'C:\projects\microbeTracker\CandCplusplusFunctions' -I'C:\projects\mexopencv\include' -I'C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\include' -I'C:\openCV245\opencv\build\include' -L'C:\openCV245\opencv\build\x64\vc10\lib'  -lopencv_calib3d245 -lopencv_contrib245 -lopencv_core245 -lopencv_features2d245 -lopencv_flann245 -lopencv_gpu245 -lopencv_haartraining_engine -lopencv_highgui245 -lopencv_imgproc245 -lopencv_legacy245 -lopencv_ml245 -lopencv_nonfree245 -lopencv_objdetect245 -lopencv_photo245 -lopencv_stitching245 -lopencv_superres245 -lopencv_ts245 -lopencv_video245 -lopencv_videostab245 'C:\projects\microbeTracker\CandCplusplusFunctions\getRigidityForcesL.cpp' -output 'C:\projects\microbeTracker\CandCplusplusFunctions\getRigidityForcesL_'
*/

/**
 * @file align4.cpp
 * @brief mex interface for align4.m
 * @author Ahmad Paintdakhi
 * @date May 3, 2013.
 */
//#include "mexopencv.hpp"
//#include "opencv_matlab.hpp"
//using namespace std;
//using namespace cv;
#include "mex.h"
//#include "opencv/cv.h"
//#include "opencv/highgui.h"
#include "string.h"
#include "math.h"
#include <valarray>


//#include <unsupported/Eigen/MatrixFunctions>
/**
 * Main entry called from Matlab
 * @param nlhs number of left-hand-side arguments
 * @param plhs pointers to mxArrays in the left-hand-side
 * @param nrhs number of right-hand-side arguments
 * @param prhs pointers to mxArrays in the right-hand-side
 */
 using namespace std;
 #define PI 3.14159
 
 
 void getRigidityForcesL(valarray<double> &input1, valarray<double> &input2, valarray<double> &B, valarray<double> &out1, valarray<double> &out2)
 {
	valarray<double> fxt,fyt,tempArray1,tempArray2,tempArray3,tempArray4,tempArray5,tempArray6,
					 outArray1,outArray2,outArray3,outArray4,outArray5,outArray6;
	for(int i=1; i<(B.size()+1); i++)
	{	
	
		double temp1 = (input1.size() - ((2.0 * i))), temp2 = (2.0 * i), temp3 = input1.size() - i;
		slice slice1(0,temp1 ,1),slice2(temp2,input1.size()-temp2,1),slice3(i,temp3-i,1);
		tempArray1 = input1[slice1];
		tempArray2 = input1[slice2];
		tempArray3 = input1[slice3];
		tempArray4 = input2[slice1];
		tempArray5 = input2[slice2];
		tempArray6 = input2[slice3];
		fxt = (B[i-1] * ((tempArray1 / 2.0) + ((tempArray2 / 2.0) - tempArray3)));
		fyt = (B[i-1] * ((tempArray4 / 2.0) + ((tempArray5 / 2.0) - tempArray6)));
		outArray1 = out1[slice3];
		outArray2 = out2[slice3];
		out1[slice3] = (outArray1 + fxt);
		out2[slice3] = (outArray2 + fyt);
		outArray3 = out1[slice1];
		outArray4 = out2[slice1];
		out1[slice1] = (outArray3 - (fxt / 2.0));
		out2[slice1] = (outArray4 - (fyt / 2.0));
		outArray5 = out1[slice2];
		outArray6 = out2[slice2];
		out1[slice2] = (outArray5 - (fxt / 2.0));
		out2[slice2] = (outArray6 - (fyt / 2.0));
	}
	
}

 void mxArray2valArray(double *input, size_t rowLen,size_t colsLen, std::valarray<double> &output )
{
	for (int j=0; j<colsLen; j++)
	{
		for (int i=0; i<rowLen; i++)
		{
			output[i] = input[(j*rowLen)+i];
		}
	}
		
}


void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{


double  *xCell,*yCell,*Barray,*out1,*out2;
size_t rowsOfxCell,colsOfxCell,colsOfB;	
xCell	= mxGetPr(prhs[0]);
yCell	= mxGetPr(prhs[1]);
Barray  = mxGetPr(prhs[2]);
rowsOfxCell 	= mxGetM(prhs[0]);
colsOfxCell 	= mxGetN(prhs[0]);
colsOfB			= mxGetN(prhs[2]);

valarray<double> xCellArray(rowsOfxCell),yCellArray(rowsOfxCell),B(colsOfB),D4x(rowsOfxCell),D4y(rowsOfxCell);
mxArray2valArray(Barray, colsOfB, colsOfxCell, B);
mxArray2valArray(xCell, rowsOfxCell, colsOfxCell, xCellArray);
mxArray2valArray(yCell, rowsOfxCell, colsOfxCell, yCellArray);


getRigidityForcesL(xCellArray,yCellArray,B,D4x,D4y);

plhs[0] = mxCreateDoubleMatrix(rowsOfxCell,colsOfxCell,mxREAL);
plhs[1] = mxCreateDoubleMatrix(rowsOfxCell,colsOfxCell,mxREAL);
out1 = mxGetPr(plhs[0]);
out2 = mxGetPr(plhs[1]);
	

for(int i=0;i<rowsOfxCell;i++)
{
	for(int j=0; j<colsOfxCell; j++)
	{
		out1[(j*rowsOfxCell)+i] = D4x[i];
		out2[(j*rowsOfxCell)+i] = D4y[i];
	}
}

 
 
 }