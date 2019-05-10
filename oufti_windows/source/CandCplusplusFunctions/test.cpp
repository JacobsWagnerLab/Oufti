//---Inside mexFunction---
 
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )//Declarations
{
mxArray *xData;
double *xValues, *outArray;
int i,j;
int rowLen, colLen;

//Copy input pointer x
xData = prhs[0];

//Get matrix x
xValues = mxGetPr(xData);
rowLen = mxGetN(xData);
colLen = mxGetM(xData);

//Allocate memory and assign output pointer
plhs[0] = mxCreateDoubleMatrix(colLen, rowLen, mxREAL); //mxReal is our data-type

//Get a pointer to the data space in our newly allocated memory
outArray = mxGetPr(plhs[0]);

//Copy matrix while multiplying each point by 2
for(i=0;i<rowLen;i++)
{
    for(j=0;j<colLen;j++)
    {
        outArray[(i*colLen)+j] = 2*xValues[(i*colLen)+j];
    }
}
}