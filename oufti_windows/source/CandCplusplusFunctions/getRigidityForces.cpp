


/*
mex -v -largeArrayDims -I'C:\projects\oufti\CandCplusplusFunctions' -I'C:\projects\mexopencv\include' -I'C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\include' -I'C:\openCV245\opencv\build\include' -L'C:\openCV245\opencv\build\x64\vc10\lib'  -lopencv_calib3d245 -lopencv_contrib245 -lopencv_core245 -lopencv_features2d245 -lopencv_flann245 -lopencv_gpu245 -lopencv_haartraining_engine -lopencv_highgui245 -lopencv_imgproc245 -lopencv_legacy245 -lopencv_ml245 -lopencv_nonfree245 -lopencv_objdetect245 -lopencv_photo245 -lopencv_stitching245 -lopencv_superres245 -lopencv_ts245 -lopencv_video245 -lopencv_videostab245 'C:\projects\oufti\CandCplusplusFunctions\getRigidityForces.cpp' -output 'C:\projects\oufti\CandCplusplusFunctions\getRigidityForces_'
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
 
 
void getRigidityForces(valarray<double> &x, valarray<double> &y,valarray<double> &A, valarray<double> &outx, valarray<double> &outy)
{	
	double temp1 = -2.0 * A.sum();
    int sizeX = x.size();
    for (int ii = 0; ii<sizeX; ii++)
    {    
        outx[ii] = (temp1 * x[ii]);
        outy[ii] = (temp1 * y[ii]);
    }
	
	std::valarray<double> out1ShiftLeft(sizeX),out1ShiftRight(sizeX),out2ShiftLeft(sizeX),out2ShiftRight(sizeX),temp2(sizeX),temp3(sizeX);
    
	for (int i = 1; i<A.size()+1; i++)
	{
		out1ShiftLeft = x.cshift(-i);
        out1ShiftRight = x.cshift(i);
        out2ShiftLeft = y.cshift(-i);
        out2ShiftRight = y.cshift(i);
        for (int jj = 0; jj<sizeX; jj++)
        { 
            temp2[jj] = A[i-1] * (out1ShiftLeft[jj] + out1ShiftRight[jj]);
            temp3[jj] = A[i-1] * (out2ShiftLeft[jj] + out2ShiftRight[jj]);
            outx[jj] = outx[jj] + temp2[jj];
            outy[jj] = outy[jj] + temp3[jj];
        }
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


double  *xCell,*yCell,*Aarray,*out1,*out2;
size_t rowsOfxCell,colsOfxCell,colsOfA;	
xCell	= mxGetPr(prhs[0]);
yCell	= mxGetPr(prhs[1]);
Aarray  = mxGetPr(prhs[2]);
rowsOfxCell 	= mxGetM(prhs[0]);
colsOfxCell 	= mxGetN(prhs[0]);
colsOfA			= mxGetN(prhs[2]);

valarray<double> xCellArray(rowsOfxCell),yCellArray(rowsOfxCell),A(colsOfA),D4x(rowsOfxCell),D4y(rowsOfxCell);
mxArray2valArray(Aarray, colsOfA, colsOfxCell, A);
mxArray2valArray(xCell, rowsOfxCell, colsOfxCell, xCellArray);
mxArray2valArray(yCell, rowsOfxCell, colsOfxCell, yCellArray);


getRigidityForces(xCellArray,yCellArray,A,D4x,D4y);

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