

/*

mex -v -largeArrayDims -I'C:\projects\microbeTracker\CandCplusplusFunctions' -I'C:\projects\mexopencv\include' -I'C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\include' -I'C:\openCV245\opencv\build\include' -L'C:\openCV245\opencv\build\x64\vc10\lib'  -lopencv_calib3d245 -lopencv_contrib245 -lopencv_core245 -lopencv_features2d245 -lopencv_flann245 -lopencv_gpu245 -lopencv_haartraining_engine -lopencv_highgui245 -lopencv_imgproc245 -lopencv_legacy245 -lopencv_ml245 -lopencv_nonfree245 -lopencv_objdetect245 -lopencv_photo245 -lopencv_stitching245 -lopencv_superres245 -lopencv_ts245 -lopencv_video245 -lopencv_videostab245 'C:\projects\microbeTracker\CandCplusplusFunctions\align4.cpp' -output 'C:\projects\microbeTracker\CandCplusplusFunctions\align4_'
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
#include "opencv/cv.h"
#include "opencv/highgui.h"
#include "string.h"
#include "math.h"
#include <valarray>
#include <Eigen/Dense>

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

/*void replicateArray(valarray<double> &input1,double input2,valarray<double> &output)
{
	for (int j = 0; j<input2; ++j)
	{
		for(int i = 0; i<input1.size(); ++i)
		{
			out
 */
 void rotateArray(valarray<double> &input)
 {
 valarray<double> tempArray = input;
 int counter = 0;
	for(int i=input.size()-1; i>-1; i--)
	{
	
	input[counter] = tempArray[i];
	counter = counter + 1;
	}
}
 void mxArrayAdditionAndMultiply(double *input1,valarray<double> &input2, valarray<double> &input3,mwSize &rows, mwSize &cols)
 {
	for(int j=0; j<cols; j++)
		for(int i=0; i<rows; i++)
			input1[(j*rows)+i] = input1[(i*cols)+j] + (input2[i] * input3[i]);
		
 }
 
void mxArray2EigenMatrix(double *input,Eigen::MatrixXd &output,mwSize &rows,mwSize &cols)
{
	for(int j=0; j<cols; j++)
	{
		for(int i=0; i<rows; i++)
		{
			output(i,j) = input[(j*rows)+i];
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

void vallArray2mxArray(valarray<double> &input, double *output, mwSize &rows, mwSize &cols)
{
	for(int j=0; j<cols; j++)
	{
		for(int i=0; i<rows; i++)
		{
			output[(j*rows)+i] = input[i];
		}
	}
}
/*
 * creates a new matrix by appending one matrix to the side of the other, note
 * that the three matrcies have the same row count r
 *
 * for example:
 *
 *  matrix a        matrix b     matrix c
 *  01 02 03 04     01 02 03     01 02 03 04 01 02 03
 *  05 06 07 08  +  04 05 06  =  05 06 07 08 04 05 06
 *  09 10 11 12     07 08 09     09 10 11 12 07 08 09
 */
void appendMatRows( const int height, valarray<double> &first,
      valarray<double> &second, valarray<double> &result ) 
{
  size_t firstwidth = first.size() / height;
  size_t secondwidth = second.size() / height;
  size_t resultwidth = firstwidth + secondwidth;
  // make the result matrix the right size
  result.resize( first.size() + second.size() );
  // use a gslice to get a valarray for inserting the first matrix
  size_t x1[] = { height, firstwidth }; // shape of extracted array
  size_t s1[] = { resultwidth, 1 }; // parent row length and row item distance
  valarray<size_t> xa1( x1, 2 );
  valarray<size_t> sa1( s1, 2 );
  result[( const gslice )gslice( 0, xa1, sa1 )] = first;
  // then repeat with the second matrix
  size_t x2[] = { height, secondwidth }; 
  size_t s2[] = { resultwidth, 1 }; 
  valarray<size_t> xa2( x2, 2 );
  valarray<size_t> sa2( s2, 2 );
  result[( const gslice )gslice( firstwidth, xa2, sa2 )] = second;
 }
 /*
 double circShift(double *x,int y)
 {
	int rows = mxGetM(x);
	int columns = mxGetN(x);
	double output = [rows][columns];
	for (int i = 0; i<rows; i++)
	{
		double valueMod = modf((i-y),rows)+1;
		output[i][1] = x[valueMod][1];
		output[j][2] = x[valueMod][2];
	}
	return output;
 
 }*/
void getRigidityForces(valarray<double> &x, valarray<double> &y,valarray<double> &A, valarray<double> &out1, valarray<double> &out2)
{	
	double temp1 = -2.0 * A.sum();
	out1 = (temp1 * x);
	out2 = (temp1 * y);
	
	std::valarray<double> out1CshiftRight,out1CshiftLeft,out2CshiftRight,out2CshiftLeft;
	for (int i = 1; i<A.size()+1; i++)
	{
		out1CshiftRight = x.cshift(-i);
		out1CshiftLeft  = x.cshift(i);
		out2CshiftRight = y.cshift(-i);
		out2CshiftLeft  = y.cshift(i);
		out1 = (out1 + (A[i-1] * (out1CshiftRight + out1CshiftLeft)));
		out2 = (out2 + (A[i-1] * (out2CshiftRight + out2CshiftLeft)));
	}
 }
 
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
 
 void getNormals(valarray<double>& x, valarray<double>& y, valarray<double>& Tx, valarray<double>& Ty)
 {
	Tx = (y.cshift(1) - y.cshift(-1));
	Ty = (x.cshift(-1) - x.cshift(1));
	valarray<double> TxTemp,TyTemp,dtxyTemp,TxTy;
	TxTemp = pow(Tx,2.0);
	TyTemp = pow(Ty,2.0);
	TxTy = (TxTemp + TyTemp);
	dtxyTemp = sqrt(TxTy);
	Tx = (Tx / dtxyTemp);
	Ty = (Ty / dtxyTemp);
}
 
void replicateArray(valarray<double> &input1,valarray<double> &input2, valarray<double> &input3, Eigen::MatrixXd &output)
{
	Eigen::MatrixXd tempTx(input2.size(),input3.size());
	Eigen::MatrixXd tempOutput(input2.size(),input3.size());
	for(int jj=0; jj<input3.size(); jj++)
	{
		for(int j=0; j<input2.size(); j++)
		{
			tempTx(j,jj) = input2[j] * input3[jj];
		}
	}

	for(int j=0; j<input3.size(); j++)
	{
		for(int i=0; i<input1.size(); i++)
		{
			tempOutput(i,j) = input1[i];
		}
	}

	output = tempOutput + tempTx;
}

void eigenTomxArray(Eigen::MatrixXd &arrayTxM, double *startOfArrayTxM,mwSize &rows,mwSize &cols)
{
	for(int j=0; j<cols; j++)
	{
		for(int i=0; i<rows; i++)
		{
			startOfArrayTxM[(j*rows)+i] = arrayTxM(i,j);
		}
	}
}

void eigenArrayToValArray(Eigen::MatrixXd &input, valarray<double> &output)
{
	for(int i=0; i<input.rows(); i++)
	{
		output[i] = input(i);
	}
}


void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
    // Check the number of arguments
    if (nrhs!=40)
	{
      mexErrMsgIdAndTxt("align4:error","40 input arguements are required.");
    }
    double  *mpx,*mpy,*ngmap,*xCell,*yCell,*roiBox,*imageValues,*pcc1,*pcc2,*cellWidthInit,
			*TxInit,*TyInit,*hcorrInit,*rgtInit,*wdtInit,*AInit,*BInit,*pointer;
    //int nFields, iField;
    size_t NoOfCols, NoOfRows, rowsOfxCell,colsOfxCell,rowsOfCellWidth,rowsOfTx,rowsOfTy,rowsOfhcorr,rowsOfrgt,rowsOfwdt,rowsOfA,rowsOfB;	
    //Copy input pointer 
    // This carries the input grayscale image that was sent from Matlab
	mpx       = mxGetPr(prhs[1]);
	mpy		  = mxGetPr(prhs[2]);
	ngmap	  = mxGetPr(prhs[3]);
	xCell	  = mxGetPr(prhs[4]);
	yCell	  = mxGetPr(prhs[5]);
	roiBox	  = mxGetPr(prhs[6]);
	double thres 		  = mxGetScalar(prhs[7]);
	//prhs[8] ----> linear
	//prhs[9] ---> 0
	double cellwidth 	  = mxGetScalar(prhs[10]);
	double rigidityRange  = mxGetScalar(prhs[11]);
	double rigidityRangeB = mxGetScalar(prhs[12]);
	double scaleFactor 	  = mxGetScalar(prhs[13]);
	double imageforce 	  = mxGetScalar(prhs[14]);
	double fitMaxIter 	  = mxGetScalar(prhs[15]);
	double attrRegion 	  = mxGetScalar(prhs[16]);
	double thresFactorF   = mxGetScalar(prhs[17]);
	double attrPower 	  = mxGetScalar(prhs[18]);
	double attrCoeff 	  = mxGetScalar(prhs[19]);
	double repCoeff		  = mxGetScalar(prhs[20]);
	double repArea 	  	  = mxGetScalar(prhs[21]);
	double areaMax 		  = mxGetScalar(prhs[22]);
	double neighRepA 	  = mxGetScalar(prhs[23]);
	double wspringconst   = mxGetScalar(prhs[24]);
	double rigidity 	  = mxGetScalar(prhs[25]);
	double rigidityB 	  = mxGetScalar(prhs[26]);
	double horalign 	  = mxGetScalar(prhs[27]);
	double eqaldist 	  = mxGetScalar(prhs[28]);
	double fitStep 	  	  = mxGetScalar(prhs[29]);
	double moveall 		  = mxGetScalar(prhs[30]);
	double fitStepM 	  = mxGetScalar(prhs[31]);
	cellWidthInit = mxGetPr(prhs[32]);
	TxInit		  = mxGetPr(prhs[33]);
	TyInit		  = mxGetPr(prhs[34]);
	hcorrInit	  = mxGetPr(prhs[35]);
	rgtInit		  = mxGetPr(prhs[36]);
	wdtInit		  = mxGetPr(prhs[37]);
	AInit		  = mxGetPr(prhs[38]);
	BInit		  = mxGetPr(prhs[39]);
	
	#define colsToReplicate 2*attrRegion+1
    //Get the matrix from the input data
    // The matrix is rasterized in a column wise read
    imageValues 	= mxGetPr(prhs[0]);
    NoOfCols    	= mxGetN(prhs[0]); // Gives the number of Columns in the image
    NoOfRows    	= mxGetM(prhs[0]); // Gives the number of Rows in the image
	rowsOfxCell 	= mxGetM(prhs[4]);
	colsOfxCell 	= mxGetN(prhs[4]);
	rowsOfCellWidth = mxGetM(prhs[32]);
	rowsOfTx		= mxGetM(prhs[33]);
	rowsOfTy		= mxGetM(prhs[34]);
	rowsOfhcorr		= mxGetM(prhs[35]);
	rowsOfrgt		= mxGetM(prhs[36]);
	rowsOfwdt		= mxGetM(prhs[37]);
	rowsOfA			= mxGetN(prhs[38]);
	rowsOfB			= mxGetN(prhs[39]);
	//Initializations
     int L = mxGetM(prhs[4]);
	 double N = L/2+1;
	 int stp = 1,counter = 0;
	 int H = ceil(cellwidth*PI/2/stp/2);
	 valarray<double> xCellArrayTemp(rowsOfxCell),yCellArrayTemp(rowsOfxCell),xCellArray(rowsOfxCell),yCellArray(rowsOfxCell),cellWidth(rowsOfCellWidth),Tx(rowsOfTx),Ty(rowsOfTy),
					  hcorr(rowsOfhcorr),rgt(rowsOfrgt),wdt(rowsOfwdt),A(rowsOfA),B(rowsOfB),lside(N-2),rside(L-N);
	 mxArray2valArray(xCell, rowsOfxCell, colsOfxCell, xCellArray);
	 mxArray2valArray(yCell, rowsOfxCell, colsOfxCell, yCellArray);
	 mxArray2valArray(cellWidthInit, rowsOfCellWidth, colsOfxCell, cellWidth);
	 mxArray2valArray(TxInit, rowsOfTx, colsOfxCell, Tx);
	 mxArray2valArray(TyInit, rowsOfTy, colsOfxCell, Ty);
	 mxArray2valArray(hcorrInit, rowsOfhcorr, colsOfxCell, hcorr);
	 mxArray2valArray(rgtInit, rowsOfrgt, colsOfxCell, rgt);
	 mxArray2valArray(AInit, rowsOfA, colsOfxCell, A);
	 mxArray2valArray(BInit, rowsOfB, colsOfxCell, B);
	 
	 double Kstp3, ddx = ceil(rigidityRange), ddxB = ceil(rigidityRangeB), sizeXTemp = H+3*ddx;
	 /*
	 valarray<double> A1(ddx), A(ddx),B1(ddxB),B(ddxB),HA1(H+1),HA(H+1),xTemp(sizeXTemp),yTemp(sizeXTemp);
	 for (int i=0; i<ddx; i++) 
	 {
		A1[i] = (0.5/(i+1));
	 }
	 for (int i=0; i<ddx; i++)
	 {
		double temp = 2*A1.sum() - A1[0];
		A[i] = (A1[i]/temp);
	 }

	 for (int i=0; i<ddxB; i++) 
	 {
		double temp = sqrt(ddxB);
		B1[i] = (0.5/temp);
	 }

	 for (int i = 0; i<ddxB; i++)
	 {
		double temp = 2 * B1.sum() - B1[0];
		B[i] = (B1[i]/temp);
	 }

	for (int i = 0; i<H+1; i++)
	{
		HA1[i] = (H+1)-i;
	}

	for (int i=0; i<H+1; i++)
	{
		HA[i] = PI*HA1[i]/(2*HA1.sum()-HA1[0]);
	}
	
	for (int i = (H+2*ddx); i>H; i--)
	{
		xTemp[i] = xTemp[i+1] - stp;
		yTemp[i] = yTemp[i+1];
	}
	
	double alpha = HA[H+1];
	for (int j = H;j>-1; j--)
	{
		xTemp[j] = xTemp[j+1] - stp * cos(alpha);
		yTemp[j] = yTemp[j+1] + stp * sin(alpha);
		alpha = HA[j] + alpha;
	}
	valarray<double> xTemp1(xTemp.size()-1);
	valarray<double> yTemp1(yTemp.size()-1);
	yTemp.cshift(xTemp.size());
	xTemp.cshift(xTemp.size());
	for (int jj = 0; jj<xTemp1.size(); jj++)
	{
		xTemp1[jj] = xTemp[jj+1];
		yTemp1[jj] = yTemp[jj+1];
	}
	valarray<double> x((xTemp.size()*2)-1);
	valarray<double> y((yTemp.size()*2)-1);
	for (int i = 0; i<xTemp1.size(); i++)
	{
		x[i] = xTemp1[i];
		y[i] = 2 * yTemp[0] - yTemp1[i];
		y[i] = y[i] * cellwidth * scaleFactor/abs(y[0]);
	}
	for (int i = xTemp1.size()+1; i<x.size(); i++)
	{
		x[i] = xTemp[i];
		y[i] = yTemp[i];
		y[i] = y[i]*cellwidth*scaleFactor/abs(y[0]);
	}
	
	std::valarray<double> fx(x.size()),fy(y.size()),Tx(x.size()),Ty(y.size()); 
	getRigidityForces(x,y,A,fx,fy);
	getNormals(x,y,Tx,Ty);
	
	std::valarray<double> f1(Tx.size());
	f1 = ((Tx * fx) + (Ty * fy));
	slice slc ((f1.size()+1)/2,(f1.size()+1)/2+H,1);
	valarray<double> f = f1[slc];
	slice slc1 (2,f.size(),1);
	valarray<double> zeroArray(N-2*H-2),result,resultTemp,result1,result2,result3,result4,hcorr,array1(H+1),rgt,fSlice1,lside(N-3),rside(L-N),cellWidth;
	fSlice1 = f[slc1];
	appendMatRows( 1, f,zeroArray, result1 ); 
	appendMatRows( 1, result1, f.cshift(f.size()), result2 ); 
	appendMatRows( 1, result2, fSlice1, result3 ); 
	appendMatRows( 1, result3, zeroArray, result4 ); 
	appendMatRows( 1, result4,(fSlice1.cshift(f.size()-1)), hcorr );
	for(int i=0; i<H+1; i++)
	{
		array1[i] = i+1;
	}
	
	valarray<double> array2(N-2*H-2,H+1);
	valarray<double> array3 = array1.cshift(array1.size());
	slice slcTemp(2,H+1,1);
	valarray<double> array4 = array1[slcTemp];
	valarray<double> array5 = array4.cshift(array4.size());
	appendMatRows( 1, array1,array2,  result1);
	appendMatRows( 1, result1,array3, result2);
    appendMatRows( 1, result2,array4, result3);
    appendMatRows( 1, result3,array5, rgt);
	
	if (rgt.size() > L)
	{
		int L2 = rgt.size();
		int rm = (L2-L)/2;
		double lv = ceil(N/2)-1;
		slice slcTemp1(1,lv,1);
		slice slcTemp2(lv+1+rm,L2/2+1+lv,1);
		slice slcTemp3(L2/2+1+1+rm,hcorr.size(),1);
		valarray<double> array1Temp = hcorr[slcTemp1];
		valarray<double> array2Temp = hcorr[slcTemp2];
		valarray<double> array3Temp = hcorr[slcTemp3];
		appendMatRows( 1, array1Temp,array2Temp, result);
		appendMatRows( 1, result,array3Temp, hcorr);
		valarray<double> array1Temp1 = rgt[slcTemp1];
		valarray<double> array2Temp2 = rgt[slcTemp2];
		valarray<double> array3Temp3 = rgt[slcTemp3];
		appendMatRows( 1, array1Temp1,array2Temp2, resultTemp);
		appendMatRows( 1, resultTemp,array3Temp3, rgt);
	}
	*/
	for(int i=0; i<lside.size(); i++)
	{
		lside[i] = i+1;
	}

	for(int i=L-1; i>L-N+2; i--)
	{
		rside[counter] = i;
		counter = counter + 1;
	}
	
	slice rsideSlice(rside.max(),rside.size(),-1);
	slice lsideSlice(lside.min(),lside.size(),1);
	/*
	slice sliceTemp((y.size()/2)+1.5,(y.size()/2)+(1/2+H),1);
	valarray<double> array1Temp = y[sliceTemp], array2Temp(1,N-2*H-2), array3Temp = array1Temp.cshift(-array1.size()), array4Temp (y[(y.size()/2)+1.5],1), array5Temp(2,1), array6Temp((cellwidth * scaleFactor),1);
	appendMatRows( 1, (array5Temp * (abs( array1Temp - array4Temp))),(array6Temp * array2Temp), result1);
	appendMatRows( 1, result1,(array5Temp * (abs(array3Temp - array4Temp))), cellWidth);
	if (cellWidth.size() > N-2)
	{
		slice sliceTemp(1,ceil(N/2)-1,1);
		valarray<double> tempArray = cellWidth[sliceTemp];
		slice sliceTemp1(cellWidth[cellWidth.size()] + 2-floor(N/2),cellWidth.size(),1);
		valarray<double> tempArray2 = cellWidth[sliceTemp1];
		appendMatRows(1,tempArray,tempArray2,cellWidth);
	}
	valarray<double> wdt = (cellWidth/cellWidth.max());
	*/
	int ftqHistory = 0;
	//double areaCell;
	int ftqHistoryCounter = 0;
	int attrTemp = attrRegion+1;
	int xCellArraySize = xCellArray.size();
	if (imageforce >= 7)
	{	
		int ftqThresh = 11;
	}
	else
	{
	int ftqThresh = 17;
	}
	mxArray *TxM[1],*TyM[1],*area,*lhs,*lhs1,*mxTempArray[2],*mxArrayTxM,*mxArrayTyM,*mxArrayOut,*mxArrayOut1,*temp1[1],*temp2[1],*tempOut,
			*mxXCellArray[1],*mxXCellArrayTemp[1],*mxYCellArray[1],*rhsx[5],*rhsy[5],*mxArrayIn[5],*mxArrayIn2[5],*repInputy[3],*repInputx[3],*xyCellArray[2],*mxXCnt[1],*mxYCnt[1];
	
	
	temp1[0] = mxCreateDoubleScalar(1);
	temp2[0] = mxCreateDoubleScalar(2*attrTemp);
	mwSize cols = 2*attrRegion+1;
	mwSize rows = xCellArraySize;
	mxArrayTxM = mxCreateDoubleMatrix(rows,cols,mxREAL);
	mxArrayTyM = mxCreateDoubleMatrix(rows,cols,mxREAL);
	//mxArrayOut[0] = mxCreateDoubleMatrix(rows,cols,mxREAL);
	//mxArrayOut1[0] = mxCreateDoubleMatrix(rows,cols,mxREAL);
	mxXCellArray[0] = mxCreateDoubleMatrix(mxGetM(prhs[4]),1,mxREAL);
	mxYCellArray[0] = mxCreateDoubleMatrix(mxGetM(prhs[4]),1,mxREAL);
	mxXCellArrayTemp[0] = mxCreateDoubleMatrix(rowsOfxCell,1,mxREAL);
	TxM[0] = mxCreateDoubleMatrix(rows,cols,mxREAL);
	TyM[0] = mxCreateDoubleMatrix(rows,cols,mxREAL);
	mxXCnt[0] = mxCreateDoubleMatrix(N-1,1,mxREAL);
	mxYCnt[0] = mxCreateDoubleMatrix(N-1,1,mxREAL);
	//lhs[0] = mxCreateDoubleMatrix(mxGetM(prhs[4]),1,mxREAL);
	//area[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	
	double Kstp = 1,tempVal1,tempVal2,are,FxMax,FyMax,mndDivideBymxfDivideByTwo, g=5,Kstp2=1,K,mnd,med,MF,mfx,mfy,MFold,mfxold,Kstpm = fitStepM,mfyold,MI,mxf,dtxyMean,
				  FmTemp1,xCellArrayMean,yCellArrayMean,MFDivideByMI,fxSquaredMean,fySquaredMean;

	valarray<double> attrRegionVector(attrRegion*2+1),output(rowsOfxCell),output1(rowsOfxCell),Fix,Fiy,Fax,Fay,Fnrx(rowsOfxCell),yCellArrayPositiveShift,MFTemp,MITemp,
					 Fnry(rowsOfxCell),Dst,Fdst,Fdst1x,Fdst1y,xCellArraySlice1(N),xCellArraySlice2(N),Fmrx,Fmry,xCellArrayPositiveShift,yCellArrayNegativeShift,fxSquared,fySquared,
					 yCellArraySlice1(N),yCellArraySlice2(N),Fdstx(L),Fdsty(L),Frx,Fry,D4x,D4y,xCnt,yCnt,xCnt1,xCnt2,yCnt1,yCnt2,Tbx,xm,ym,xCellArrayNegativeShift,asdxTemp,asdyTemp,
					 Tby,D4btx(N),D4bty(N),D4b(N),Fbrx(L),Fpbx,Fpby,Fp,Fpx(L),Fpy(L),Fq,Fqx,Fx,Fy,Fm,FmTemp,Fo,Fs,asd,KstpArray,D4bx,D4by,TbxSliceArray,TbySliceArray,
					 xCellArrayrsideSlice,xCellArraylsideSlice,yCellArrayrsideSlice,yCellArraylsideSlice,dtxy,Lx,Ly,T(rowsOfxCell),Fqy,Fbry(L),D4bTemp,Two(2,1),
					 absFx,absFy,xCellOut(1),yCellOut(1),TxSquared(xCellArray.size()),TySquared(xCellArray.size()),yCellShiftPlus(xCellArray.size()),absK,TbxPow2,TbyPow2,
					 yCellShiftMinus(xCellArray.size()),xCellShiftPlus(xCellArray.size()),xCellShiftMinus(xCellArray.size()),TxTy,xxTemp,D4bxRev(N-2),D4byRev(N-2),valueArray(20); 
	slice slice1(0,N,1),slice2(L-1,N,-1),TbxSlice(1,N,1),FbrxSlice1(0,N,1),D4bRevSlice(N-2,N-2,-1),FbrxSlice2(N,L-N,1);
	for(int i=0; i<attrRegion*2+1; i++)
	{
		attrRegionVector[i] = i - attrRegion;
	}
	int numCols = 2 * attrTemp;
	int rowsTemp = N, colsTemp = 2;
	Eigen::MatrixXd Clr0(xCellArraySize,2 * attrTemp);
	Eigen::MatrixXd Clr(xCellArraySize,2 * attrTemp);
	Eigen::MatrixXd ClrTemp(xCellArraySize,2 * attrTemp);
	Eigen::MatrixXd ClrTemp1(xCellArraySize,2 * attrTemp);
	Eigen::MatrixXd ClrTemp2(xCellArraySize,attrTemp);
	Eigen::MatrixXd ClrTemp4(xCellArraySize,attrTemp);
	Eigen::MatrixXd arrayTxM(xCellArraySize,numCols);
	Eigen::MatrixXd arrayTyM(xCellArraySize,numCols);
	Eigen::MatrixXd onesMatrix(xCellArraySize,numCols);
	Eigen::MatrixXd ClrTemp3;
	Eigen::MatrixXd ClrTemp5;
	Eigen::MatrixXd D4btXY(rowsTemp,colsTemp);
	Eigen::MatrixXd D4btX, D4btY;
	onesMatrix.setOnes();
	
	for(int a = 1; a<fitMaxIter; a++)
	{
		vallArray2mxArray(xCellArray,mxGetPr(mxXCellArray[0]),rowsOfxCell,colsOfxCell);
		vallArray2mxArray(yCellArray,mxGetPr(mxYCellArray[0]),rowsOfxCell,colsOfxCell);
		rhsx[0] = mxDuplicateArray(prhs[1]);//mpx
		rhsx[1] = mxDuplicateArray(mxXCellArray[0]);//xCell
		rhsx[2] = mxDuplicateArray(mxYCellArray[0]);
		rhsx[3] = mxDuplicateArray(prhs[8]);//linear
		rhsx[4] = mxDuplicateArray(prhs[9]);//0
		rhsy[0] = mxDuplicateArray(prhs[2]);//mpy;
		rhsy[1] = mxDuplicateArray(mxXCellArray[0]);
		rhsy[2] = mxDuplicateArray(mxYCellArray[0]);
		rhsy[3] = mxDuplicateArray(prhs[8]);//'linear';
		rhsy[4] = mxDuplicateArray(prhs[9]);//0;

		mexCallMATLAB(1,&lhs,5,rhsx,"interp2_");
		mxArray2valArray(mxGetPr(lhs), rowsOfxCell, colsOfxCell,output);
		Fix = (-imageforce * output);
		//vallArray2mxArray(Fix,mxGetPr(mxXCellArrayTemp[0]),rowsOfxCell,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxXCellArrayTemp[0],"disp");
		

		mexCallMATLAB(1,&lhs1,5,rhsy,"interp2_");
		mxArray2valArray(mxGetPr(lhs1), rowsOfxCell, colsOfxCell,output1);
		Fiy = (imageforce * output1);
		yCellShiftPlus = yCellArray.cshift(1);
		yCellShiftMinus = yCellArray.cshift(-1);
		xCellShiftPlus = xCellArray.cshift(1);
		xCellShiftMinus = xCellArray.cshift(-1);
		Tx = (yCellShiftPlus - yCellShiftMinus);
		Ty = (xCellShiftMinus - xCellShiftPlus);
		
		TxSquared = pow(Tx,2.0);
		TySquared = pow(Ty,2.0);
		TxTy = (TxSquared + TySquared);
		dtxy = sqrt(TxTy);
		dtxyMean = (dtxy.sum()/dtxy.size());
		dtxy = (dtxy + (dtxyMean / 100.0));
		if (dtxy.min() == 0)
		{
			xCellOut[0] = 1; 
			yCellOut[0] = 1;
			break;
		}

		Tx = (Tx / dtxy);
		Ty = (Ty / dtxy);
		Lx = Ty;
		Ly = -Tx;
		//vallArray2mxArray(Lx,mxGetPr(mxXCellArrayTemp[0]),rowsOfxCell,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxXCellArrayTemp[0],"disp");
		
		
		replicateArray(xCellArray,Tx,attrRegionVector,arrayTxM);
		eigenTomxArray(arrayTxM,mxGetPr(mxArrayTxM),rows,cols);
		replicateArray(yCellArray,Ty,attrRegionVector,arrayTyM);
		eigenTomxArray(arrayTyM,mxGetPr(mxArrayTyM),rows,cols);
		//mxArrayAdditionAndMultiply(mxGetPr(mxArrayTxM),Tx,attrRegionVector,rows,cols);
		//mxArrayAdditionAndMultiply(mxGetPr(mxArrayTyM),Ty,attrRegionVector,rows,cols);
		mxArrayIn[0] = mxDuplicateArray(prhs[0]);//imageValues;
		mxArrayIn[1] = mxDuplicateArray(mxArrayTxM);//mxArrayTxM
		mxArrayIn[2] = mxDuplicateArray(mxArrayTyM);//mxArrayTym
		mxArrayIn[3] = mxDuplicateArray(prhs[8]);//'linear';
		mxArrayIn[4] = mxDuplicateArray(prhs[9]);//0;
		mexCallMATLAB(1,&mxArrayOut,5,mxArrayIn,"interp2_");
		//vallArray2mxArray(Tx,mxGetPr(mxYCellArray[0]),rowsOfxCell,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxArrayOut,"disp");
		//mexCallMATLAB(0,NULL,1,&mxYCellArray[0],"disp");
		
		//convert mxArray Clr0 to Eignen matrix
		mxArray2EigenMatrix(mxGetPr(mxArrayOut),Clr0,rows,cols);
		double tempDiv = thres / thresFactorF;
		ClrTemp = (Clr0.array()/tempDiv).matrix();
		ClrTemp1 = (ClrTemp.array().pow(attrPower)).matrix();
		ClrTemp = (ClrTemp1.array()+1.0).matrix();
		Clr = (onesMatrix.array() - (1.0/ClrTemp.array())).matrix();

		xyCellArray[0] = mxDuplicateArray(mxXCellArray[0]);//xCellArray;
		xyCellArray[1] = mxDuplicateArray(mxYCellArray[0]);//yCellArray;
		mexCallMATLAB(1,&area,2,xyCellArray,"polyarea");
		are = *mxGetPr(area);
		ClrTemp2 = Clr.rightCols(attrTemp);
		ClrTemp3 = (ClrTemp2.rowwise().mean());
		if (are < (repArea * areaMax))
		{
			ClrTemp4 = Clr.leftCols(attrTemp);
			ClrTemp5 = (ClrTemp4.rowwise().mean());
			ClrTemp3 = (ClrTemp3.array() * attrCoeff).matrix() - (repCoeff * (1.0 - ClrTemp5.array())).matrix();
		}
		else
		{
			ClrTemp3 = (ClrTemp3.array() * attrCoeff).matrix();
		}
		eigenArrayToValArray(ClrTemp3,T);
		
		//vallArray2mxArray(T,mxGetPr(mxXCellArrayTemp[0]),rowsOfxCell,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxXCellArrayTemp[0],"disp");
		


		Fax = (Tx * T);
		Fay = (Ty * T);
		mxArrayIn2[0] = mxDuplicateArray(prhs[3]);//ngmap;
		mxArrayIn2[1] = mxDuplicateArray(mxXCellArray[0]);//xCellArray;
		mxArrayIn2[2] = mxDuplicateArray(mxYCellArray[0]);//yCellArray;
		mxArrayIn2[3] = mxDuplicateArray(prhs[8]);//'linear';
		mxArrayIn2[4] = mxDuplicateArray(prhs[9]);//0
		mexCallMATLAB(1,&mxArrayOut1, 5,mxArrayIn2,"interp2_");
		mxArray2valArray(mxGetPr(mxArrayOut1), rowsOfxCell, colsOfxCell,output);
		T = (-neighRepA * output);
		Fnrx = (Tx * T);
		Fnry = (Ty * T);
		xCellArrayrsideSlice = xCellArray[rsideSlice];
		xCellArraylsideSlice = xCellArray[lsideSlice];
		yCellArrayrsideSlice = yCellArray[rsideSlice];
		yCellArraylsideSlice = yCellArray[lsideSlice];
		
		Dst = sqrt((pow((xCellArraylsideSlice - xCellArrayrsideSlice),2.0) + pow((yCellArraylsideSlice - yCellArrayrsideSlice),2.0)));
		Fdst = ((cellWidth - Dst) / cellWidth);
	
	
		//size_t tempRow = L-N;
	    //vallArray2mxArray(Fdst,mxGetPr(mxTempArray[0]),tempRow,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxTempArray[0],"disp");

	
		//-------------------------------------------------------------------------
		//Fdst((Dst./cellWidth)<0.5)=Fdst((Dst./cellWidth)<0.5).*g-(g-1)*0.5;
		//-------------------------------------------------------------------------
		Fdst = (((wspringconst * wdt) * Fdst) * cellWidth);
		Fdst1x = ((Fdst * (xCellArraylsideSlice - xCellArrayrsideSlice)) / Dst);
		Fdst1y = ((Fdst * (yCellArraylsideSlice - yCellArrayrsideSlice)) / Dst);
		Fdstx[lsideSlice]  = Fdst1x;
		Fdsty[lsideSlice]  = Fdst1y;
		Fdstx[rsideSlice]  = -Fdst1x;
		Fdsty[rsideSlice]  = -Fdst1y;
		/*
		for (int i=lside.min(); i<lside.size(); i++)
		{
				Fdstx[i-lside.min()-1] 		= Fdst1x[i-lside.min()];
				Fdsty[i-lside.min()-1] 		= Fdst1y[i-lside.min()];
				Fdstx[rside[i]-lside.min()] = -1*Fdst1x[i-lside.min()];
				Fdsty[rside[i]-lside.min()] = -1*Fdst1y[i-lside.min()];
		} */
		
	
		getRigidityForces(xCellArray,yCellArray,A,D4x,D4y);
	
		//vallArray2mxArray(D4x,mxGetPr(mxXCellArrayTemp[0]),rowsOfxCell,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxXCellArrayTemp[0],"disp");
		//mexCallMATLAB(0,NULL,1,&mxXCellArray[0],"disp");


		Frx = (rigidity * ((D4x - (Tx * hcorr)) * rgt));
		Fry = (rigidity * ((D4y - (Ty * hcorr)) * rgt));
		
		xCellArraySlice1 	 = xCellArray[slice1];
		xCellArraySlice2 	 = xCellArray[slice2];
		xCellArraySlice2     = xCellArraySlice2.cshift(-1);
		xCellArraySlice2[0]  = xCellArray[0];
		yCellArraySlice1 	 = yCellArray[slice1];
		yCellArraySlice2	 = yCellArray[slice2];
		yCellArraySlice2     = yCellArraySlice2.cshift(-1);
		yCellArraySlice2[0]  = yCellArray[0]; 
		
		xCnt = ((xCellArraySlice1 + xCellArraySlice2) / 2.0);
		yCnt = ((yCellArraySlice1 + yCellArraySlice2) / 2.0);
		yCnt1 = yCnt.cshift(1); yCnt2 = yCnt.cshift(-1);
		xCnt1 = xCnt.cshift(-1);  xCnt2 = xCnt.cshift(1);
		Tbx = (yCnt1 - yCnt2);
		Tby = (xCnt1 - xCnt2);
		
		Tbx[Tbx.size()] = Tbx[Tbx.size()-1];
		Tby[Tby.size()] = Tby[Tby.size()-1];
		Tbx[0] = Tbx[1]; Tby[0] = Tby[1];
		TbxPow2 = pow(Tbx,2.0);
		TbyPow2 = pow(Tby,2.0);
		dtxy = sqrt(TbxPow2 + TbyPow2);
		Tbx = (Tbx / dtxy); Tby = (Tby / dtxy);
		//size_t nn = N;
		//vallArray2mxArray(Tbx,mxGetPr(mxXCellArrayTemp[0]),nn,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxXCellArrayTemp[0],"disp");

		/*
		size_t nn = N;
		//vallArray2mxArray(Tbx,mxGetPr(mxTempArray[0]),nn,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxTempArray[0],"disp");
		vallArray2mxArray(xCnt,mxGetPr(mxXCnt[0]),nn,colsOfxCell);
		vallArray2mxArray(yCnt,mxGetPr(mxYCnt[0]),nn,colsOfxCell);
		mxTempArray[0] = mxDuplicateArray(mxXCnt[0]);
		mxTempArray[1] = mxDuplicateArray(mxYCnt[0]);
		mxTempArray[2] = mxDuplicateArray(prhs[39]);
		mexCallMATLAB(1,&tempOut,3,mxTempArray,"getrigidityforcesL");
		mwSize rows = N, cols = 2;
		mxArray2EigenMatrix(mxGetPr(tempOut),D4btXY,rows,cols);
		/////-----------------------  work from here ------------------------
		D4btX = D4btXY.col(0);
		D4btY = D4btXY.col(1);
		eigenArrayToValArray(D4btX, D4btx);
		eigenArrayToValArray(D4btY, D4bty);
		//vallArray2mxArray(D4btx,mxGetPr(mxXCellArrayTemp[0]),nn,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxXCellArrayTemp[0],"disp");*/

		getRigidityForcesL(xCnt,yCnt,B,D4btx,D4bty);
		//size_t nn = N;
		//vallArray2mxArray(D4btx,mxGetPr(mxXCellArrayTemp[0]),nn,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxXCellArrayTemp[0],"disp");


		D4bTemp = ((D4btx * Tbx) + (D4bty * Tby));
		D4b = (D4bTemp / 2.0);
		D4bx = (rigidityB * (D4b * Tbx)); D4by = (rigidityB * (D4b * Tby));
		//D4bxSlice = D4bx[D4bSlice];
		//D4bySlice = D4by[D4bSlice];	
		D4bxRev   = D4bx[D4bRevSlice];
		D4byRev   = D4by[D4bRevSlice];
		Fbrx[FbrxSlice1] = D4bx;
		Fbrx[FbrxSlice2] = D4bxRev;
		Fbry[FbrxSlice1] = D4by;
		Fbry[FbrxSlice2] = D4byRev;
		//size_t nn = N;
		//vallArray2mxArray(Fbrx,mxGetPr(mxXCellArrayTemp[0]),rowsOfxCell,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxXCellArrayTemp[0],"disp");
		//vallArray2mxArray(D4bty,mxGetPr(mxTempArray[1]),nn,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxTempArray[1],"disp"); 

		//appendMatRows( 1, D4bx,D4bxSlice.cshift(D4bx.size()-2), Fbrx); 
		//appendMatRows( 1, D4by,D4bySlice.cshift(D4by.size()-2), Fbry);
		Fpbx = (xCellArraylsideSlice - xCellArrayrsideSlice);
		Fpby = (yCellArraylsideSlice - yCellArrayrsideSlice);
		TbxSliceArray = Tbx[TbxSlice];
		TbySliceArray = Tby[TbxSlice];
		Fp = ((Fpbx * TbxSliceArray) + (Fpby * TbySliceArray));
		Fpbx = (horalign * (Fpbx - (Fp * TbxSliceArray)));
		Fpby = (horalign * (Fpby - (Fp * TbySliceArray)));

		Fpx[lsideSlice] = -Fpbx;
		Fpy[lsideSlice] = -Fpby;
		Fpx[rsideSlice] = Fpbx;
		Fpy[rsideSlice] = Fpby;

		/*
		for (int i=lside.min(); i<lside.size(); i++)
		{
				Fpx[i-lside.min()-1] 		= -1 * Fpbx[i-lside.min()];
				Fpy[i-lside.min()-1] 		= -1 * Fpby[i-lside.min()];
				Fpx[rside[i]-lside.min()] 	= Fpbx[i-lside.min()];
				Fpy[rside[i]-lside.min()] = Fpby[i-lside.min()];
		} */

	
		//Equal distances between points (Fqx,Fqy)
		xCellArrayPositiveShift = xCellArray.cshift(1);
		xCellArrayNegativeShift = xCellArray.cshift(-1);
		yCellArrayPositiveShift = yCellArray.cshift(1);
		yCellArrayNegativeShift = yCellArray.cshift(-1);
		Fqx = (eqaldist * (xCellArrayNegativeShift + (xCellArrayPositiveShift - (2.0 * xCellArray)))); 
		Fqy = (eqaldist * (yCellArrayNegativeShift + (yCellArrayPositiveShift - (2.0 * yCellArray)))); 
		Fq = ((Lx * Fqx) + (Ly * Fqy));
		Fqx = (Fq * Lx); Fqy = (Fq * Ly);
		//vallArray2mxArray(Fqx,mxGetPr(mxYCellArray[0]),rowsOfxCell,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxYCellArray[0],"disp");

		// Get the resulting force
		if (a>1)
		{
			appendMatRows( 1, Fx,Fy,Fo);
		}
		
		
		Fx = (((Fix + Fax) + (Fnrx + Fdstx)) + Frx);
		Fy = (((Fiy + Fay) + (Fnry + Fdsty)) + Fry);
		Fs = ((Fx * Tx) + (Fy * Ty));
		Fx = ((Fs * Tx) + ((Fpx + Fbrx) + Fqx));
	    Fy = ((Fs * Ty) + ((Fpy + Fbry) + Fqy));
	
		//vallArray2mxArray(Fx,mxGetPr(mxXCellArrayTemp[0]),rowsOfxCell,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxXCellArrayTemp[0],"disp");
				

	//Start work here -------------------------------
		// Normalize
		FmTemp = abs(Fs);
		Fm = pow(FmTemp, 0.2); 
		FmTemp1 = ((Fm.sum()/Fm.size()) / 100.0);
		Fm = (Fm + FmTemp1);
		if ((Fm.sum()/Fm.size()) == 0)
		{
			xCellOut[0] = 1; 
			yCellOut[0] = 1;
			break;
		}

		if (a > 1)
		{
			//this might be problematic;
			appendMatRows(1,Fx,Fy,Fm);
			absK = abs(Fo * Fm);
			K = ((absK.sum())/2.0)/L;
			if (K < 0.4) 
			{
				Kstp = Kstp/1.4;
			}
			else if (K > 0.6)
			{
				Kstp3 = Kstp * 1.2;
				Kstp = min(Kstp3,1.0);
			}
		} 

		//----------------- temp -----------
		size_t xx = 4, yy = 3;
		//----------------------------------
		absFx = abs (Fx);
		absFy = abs (Fy);
		FxMax = absFx.max();
		FyMax = absFy.max();
		mxf = (fitStep * Kstp * (FxMax+ FyMax));
		asdxTemp = (xCellArray - xCellArrayPositiveShift);
		asdyTemp = (yCellArray - yCellArrayPositiveShift);
		asdxTemp = pow(asdxTemp, 2.0);
		asdyTemp = pow(asdyTemp, 2.0);
		asd = (asdxTemp + asdyTemp); 
		mnd = sqrt(asd.min());
		med = sqrt(asd.sum()/asd.size());
		mndDivideBymxfDivideByTwo = ((mnd / mxf) / 2.0);
		//double tempArray[] = {Kstp2 * 1.1,mndDivideBymxfDivideByTwo,3 * (mnd/med)};
		double tempArray[] = {1.0, mndDivideBymxfDivideByTwo, 1.0, (3.0 * (mnd/med))};
		Kstp2 = *std::min_element(tempArray,tempArray + 4);
		
		if (moveall>0)
		{
			if(a>1)
			{
				mfxold = mfx;
				mfyold = mfy;
				MFold  = MF;
			}
			xCellArrayMean = xCellArray.sum()/xCellArray.size();
			yCellArrayMean = yCellArray.sum()/yCellArray.size();
			xm = (xCellArray - xCellArrayMean); 
			ym = (yCellArray - yCellArrayMean);
			MFTemp = ( (-Fy * xm) + (Fx * ym) );
			MF = MFTemp.sum()/MFTemp.size();
			MITemp = ( (pow(xm,2.0)) + (pow(ym,2.0)) );
			MI = MITemp.sum();
			MFDivideByMI = MF/MI;
			Fmrx = (ym * MFDivideByMI); 
			Fmry = ((-xm) * MFDivideByMI);
			mfx = Fx.sum()/Fx.size(); mfy = Fy.sum()/Fy.size();
			fxSquared = pow(Fx,2.0);
			fySquared = pow(Fy,2.0);
			fxSquaredMean = (fxSquared.sum() / fxSquared.size());
			fySquaredMean = (fySquared.sum() / fySquared.size());
			tempVal1 = sqrt(fxSquaredMean + fySquaredMean);
			tempVal1 = Kstpm / tempVal1;
			tempVal2 = (abs(MF))*sqrt(MI);
			tempVal2 = Kstpm / tempVal2;
			double tempArray[] = {Kstpm*1.5,tempVal1, tempVal2};
			Kstpm = *std::min_element(tempArray,tempArray+3);
			//double tempArray2[] = {0.5, 0.6, 0.7};
			//valarray<double> KstpmArray(tempArray2,3);
			//vallArray2mxArray(KstpmArray,mxGetPr(mxYCellArray[0]),yy,colsOfxCell);
			//mexCallMATLAB(0,NULL,1,&mxYCellArray[0],"disp");
			//Kstpm = min(min(tempArray[0],tempArray[1]),tempArray[2]);
			/*
			if a>1 && (mfx*sign(mfxold)<-abs(mfxold)/2 || mfy*sign(mfyold)<-abs(mfyold)/2 || MF*sign(MFold)<-abs(MFold)/2)
				Kstpm = Kstpm/2;
			end */

			if (Kstpm == 0.0) 
			{
				Kstpm = fitStepM;
			}
		}
	
		//vallArray2mxArray(Fx,mxGetPr(mxXCellArray[0]),rowsOfxCell,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxXCellArray[0],"disp");
		
		if (moveall>1)
		{
			Fx = ((((Kstp * Kstp2 * scaleFactor * fitStep) * Fx) * (1.0 - moveall)) + ((Kstpm *((Fx.sum()/Fx.size()) + Fmrx)) * moveall)); 
			Fy = ((((Kstp * Kstp2 * scaleFactor * fitStep) * Fy) * (1.0 - moveall)) + ((Kstpm *((Fy.sum()/Fy.size()) + Fmry)) * moveall));
		}
		else
		{
			/*Fx = ((Kstp * Kstp2 * scaleFactor * fitStep) * Fx);
			Fy = ((Kstp * Kstp2 * scaleFactor * fitStep) * Fy);
			Fx = ((scaleFactor * fitStep) * Fx);
			Fy = ((scaleFactor * fitStep) * Fy);*/
			Fx = fitStep * Fx;
			Fy = fitStep * Fy;
			
		}
		
		xCellArray = (xCellArray + Fx); yCellArray = (yCellArray + Fy);
		//Looking for self-intersections
		//vallArray2mxArray(xCellArray,mxGetPr(mxXCellArray[0]),rowsOfxCell,colsOfxCell);
	//	vallArray2mxArray(yCellArray,mxGetPr(mxYCellArray[0]),rowsOfxCell,colsOfxCell);
		//mxTempArray[0] = mxDuplicateArray(mxXCellArray[0]);
		//mxTempArray[1] = mxDuplicateArray(mxYCellArray[0]);
		//mexCallMATLAB(2,&tempOut,2,mxTempArray,"intxySelfC");
		//size_t tempVal = 1,tempVal2 = 2;
		//std::array temp = *(mxGetPr(tempOut));
		//if (temp[0])
		//{
		//mxArray2valArray(mxGetPr(tempOut), tempVal, tempVal, valueArray);
		//}
		
		//	mexCallMATLAB(2,&tempOut,2,mxTempArray,"avoidSelfIntersections");
		//	rowsOfxCell 	= mxGetM(tempOut);
		//	pointer = mxGetPr(tempOut);
		//	for ( int index = 0; index < rowsOfxCell; index++ ) {
		//	xCellArray[index] = pointer[(0*rowsOfxCell)+index];
		//	}
		//	for ( int index = 0; index < rowsOfxCell; index++ ) {
		//	yCellArray[index] = pointer[(1*rowsOfxCell)+index];
		//	}

		
		//Moving points halfway to the projection on the opposite strand
		
		//vallArray2mxArray(Fx,mxGetPr(mxXCellArrayTemp[0]),rowsOfxCell,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&mxXCellArrayTemp[0] ,"disp");
		//vallArray2mxArray(xCellArray,mxGetPr(mxYCellArray[0]),rowsOfxCell,colsOfxCell);
		//mexCallMATLAB(0,NULL,1,&tempOut,"disp");
		//mxDestroyArray(rhsx);
		//mxDestroyArray(rhsy);
		//mexCallMATLAB(0,NULL,1,&mxXCellArray[0],"disp");
		
	}
	
	
	
	/* Create a matrix for the return argument */ 
	//xCellArray = (xCellArray + Fx); yCellArray = (yCellArray + Fy);
	plhs[0] = mxCreateDoubleMatrix(rowsOfxCell,colsOfxCell,mxREAL);
	plhs[1] = mxCreateDoubleMatrix(rowsOfxCell,colsOfxCell,mxREAL);
	pcc1 = mxGetPr(plhs[0]);
	pcc2 = mxGetPr(plhs[1]);
	
	if (xCellOut[0] == 1)
	{
		pcc1[0] = 0;
		pcc2[0] = 0;
	}
	else
	{
		for(int i=0;i<rowsOfxCell;i++)
		{
			for(int j=0; j<colsOfxCell; j++)
			{
				pcc1[(j*rowsOfxCell)+i] = xCellArray[i];
				pcc2[(j*rowsOfxCell)+i] = yCellArray[i];
			}
		}
	}
		

	//}
	//delete[] xCellOut;
	//delete[] yCellOut;
	/*
	mxDestroyArray(mxArrayTxM);
	mxDestroyArray(mxArrayTyM);
	mxDestroyArray(mxArrayOut);
	mxDestroyArray(mxArrayOut1);
	mxDestroyArray(mxXCellArray[1]);
	mxDestroyArray(mxYCellArray[1]);
	mxDestroyArray(TxM[1]);
	mxDestroyArray(lhs);
	mxDestroyArray(area);
	mxDestroyArray(TyM[1]);
	//return;
	*/
	return;
}
	


