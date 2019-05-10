/*

	CONV2.C	.MEX file for corresponding to CONV2.M
		Implements a 2-D convolution

	Syntax	c = conv2(a,b) or c = conv2(a,b,shape) where
            shape is one of 'same','full','valid'.  'full'
            is the default.

	Clay M. Thompson 10-4-91
	L. Shure 10-21-91 - modified to handle complex case
	CMT 3-10-93       - modified to take shape parameter
 
*/

#include <math.h>
#include "mex.h"

#define DOUBLE double
#define INT int

/* Input Arguments */

#define	A_IN	prhs[0]
#define	B_IN	prhs[1]
#define S_IN	prhs[2]

/* Output Arguments */

#define	C_OUT	plhs[0]

/* define constants */
#define PLUS 1
#define MINUS -1

/* Extract submatrix from a.  b = a(rstart:rend,cstart:cend); */
static void subMatrix(b, a, ma, na, rstart, rend, cstart, cend)
    DOUBLE *b;		/* Result matrix (rend-rstart+1)-by-(cend-cstart+1) */
    DOUBLE *a;		/* Original matrix ma-by-na */
    INT ma;		/* Row size of a */
    INT na;		/* Column size of a */
    INT rstart,rend;	/* Row range of submatrix b: rstart:rend */
    INT cstart,cend;	/* Column range of submatrix b: cstart:cend */
{
    register DOUBLE *p,*q;	/* Pointers to elements in a and b */
    register INT	i,j;	/* Loop counters */
    INT	mb,nb,step;
    
    /* Size of result array */
    mb = rend - rstart + 1;
    nb = cend - cstart + 1;
    
    /* Copy elements from subsection of a to b */
    step = ma - mb;
    q = b;
    p = a + rstart + cstart*ma;
    for (j=0;j<nb;++j) {
	for (i=0;i<mb;++i) {
	    *(q++) = *(p++);
	}
	p += step;
    }
}

static void conv2(c, a, b, ma, na, mb, nb, plusminus, flopcnt)
    DOUBLE *c;	/* Result matrix (ma+mb-1)-by-(na+nb-1) */
    DOUBLE *a;	/* Larger matrix */
    DOUBLE *b;	/* Smaller matrix */
    INT ma;		/* Row size of a */
    INT na;		/* Column size of a */
    INT mb;		/* Row size of b */
    INT nb;		/* Column size of b */
    INT plusminus;	/* add or subtract from result */
    int *flopcnt;	/* flop count */
{
    register DOUBLE *p,*q;	/* Pointer to elements in 'a' and 'c' matrices */
    register DOUBLE w;		/* Weight (element of 'b' matrix) */
    INT mc,nc;
    register INT k,l,i,j;
    DOUBLE *r;				/* Pointer to elements in 'b' matrix */
    
    mc = ma+mb-1;
    nc = na+nb-1;
    
    /* Perform convolution */
    r = b;	
    for (j=0; j<nb; ++j) {			/* For each non-zero element in b */
	for (i=0; i<mb; ++i) {
	    w = *(r++);				/* Get weight from b matrix */
	    if (w != 0.0) {
		p = c + i + j*mc;	/* Start at first column of a in c. */
		for (l=0, q=a; l<na; l++) {		/* For each column of a ... */
		    for (k=0; k<ma; k++) {	
			*(p++) += *(q++) * w * plusminus;	/* multiply by weight and add. */
		    }
		    p += mb - 1;	/* Jump to next column position of a in c */
		}
		*flopcnt += 2*ma*na;
	    } /* end if */
	} 
    }
}

#ifdef __STDC__
void mexFunction(INT nlhs, Matrix  *plhs[], INT nrhs, Matrix  *prhs[])
#else
mexFunction(nlhs, plhs, nrhs, prhs)
    INT nlhs, nrhs;
    Matrix *plhs[], *prhs[];
#endif
{
    Matrix	*tmp;
    DOUBLE	*cr, *ci;
    DOUBLE	*ar, *ai, *br, *bi;
    DOUBLE	*p;
    INT		ma,na;
    INT		mb,nb;
    INT		mc,nc;
    INT		cplx;
    INT		switched;
    INT		code;
    char	*shape;
    INT		nshape;
    Matrix	*pflops[1];
    Matrix	*pflops_tmp[1];
    int		flopcnt;
    
#define SAME 0
#define FULL 1
#define VALID 2
    
    /* Check validity of arguments */
    
    if (nrhs < 2) 
      mexErrMsgTxt("CONV2 requires at least two input arguments.");
    if (nlhs > 1) 
      mexErrMsgTxt("CONV2 only has one output argument.");
    if (mxIsSparse(A_IN) || mxIsSparse(B_IN))
      mexErrMsgTxt("CONV2 cannot operate on sparse matrices.");
    if ((nrhs == 3) && (!mxIsString(S_IN) || (mxGetM(S_IN)*mxGetN(S_IN)<1)))
      mexErrMsgTxt("'shape' must be a string.");
    if (nrhs < 3)
      code = FULL;
    else {	/* Get shape parameter */
	nshape = mxGetM(S_IN)*(mxGetN(S_IN)+1);
	shape = (char *) mxCalloc(nshape,sizeof(char));
	if (mxGetString(S_IN,shape,nshape)==1)
	  mexErrMsgTxt("Having trouble getting 'shape'.");
	switch (shape[0]) {
	  case 's' : code = SAME; break;
	  case 'f' : code = FULL; break;
	  case 'v' : code = VALID; break;
	  default: mexErrMsgTxt("Unknown shape parameter.");
	}
    } /* end if */
    
    /* Get ready to call conv2 */
    cplx = REAL;
    if ((mxGetPi(A_IN) != 0) || (mxGetPi(B_IN) != 0))
      cplx = COMPLEX;
    if ((mxGetM(A_IN) == 0) || (mxGetM(B_IN) == 0)) {  /* Return empty matrix */
	C_OUT = mxCreateFull(0,0,cplx);
    } else {								/* Compute result */
	
	/* Create temporary matrix to hold full convolution */
	tmp = mxCreateFull(mxGetM(A_IN)+mxGetM(B_IN)-1, 
			   mxGetN(A_IN)+mxGetN(B_IN)-1, cplx);
	
	/* Assign pointers to various arguments */
	
	cr = mxGetPr(tmp);
	if (cplx)
	  ci = mxGetPi(tmp);
	
	if (mxGetM(A_IN) * mxGetN(A_IN) > mxGetM(B_IN) * mxGetN(B_IN)) {
	    ar = mxGetPr(A_IN); ma = mxGetM(A_IN); na = mxGetN(A_IN);
	    br = mxGetPr(B_IN); mb = mxGetM(B_IN); nb = mxGetN(B_IN);
	    if (cplx) {
		ai = mxGetPi(A_IN); bi = mxGetPi(B_IN);
	    }
	    switched = 0;
	} else {
	    ar = mxGetPr(B_IN); ma = mxGetM(B_IN); na = mxGetN(B_IN);
	    br = mxGetPr(A_IN); mb = mxGetM(A_IN); nb = mxGetN(A_IN);
	    if (cplx) {
		ai = mxGetPi(B_IN); bi = mxGetPi(A_IN);
	    }
	    switched = 1;
	}		
	
	/* Call subroutine to perform actual calculations */
	
	flopcnt = 0;
	conv2(cr,ar,br,ma,na,mb,nb,PLUS,&flopcnt);
	if (cplx) {
	    conv2(cr,ai,bi,ma,na,mb,nb,MINUS,&flopcnt);
	    conv2(ci,ar,bi,ma,na,mb,nb,PLUS,&flopcnt);
	    conv2(ci,ai,br,ma,na,mb,nb,PLUS,&flopcnt);
	}
	
	/* Report flop count. */
	mexCallMATLAB(1,pflops,0,pflops_tmp,"flops");
	*mxGetPr(pflops[0]) += flopcnt;
	mexCallMATLAB(0,pflops_tmp,1,pflops,"flops");
	
	/* Now extract result and create return argument */
	switch (code) {
	  case FULL: 
	    C_OUT = tmp;
	    break;
	  case SAME: /* Return center section that is the same size as A */
	    if (switched==1) {
		mc = mb; nc = nb; mb = ma; nb = na;
	    } else {
		mc = ma; nc = na;
	    }
	    C_OUT = mxCreateFull(mc, nc, cplx);
	    subMatrix(mxGetPr(C_OUT),mxGetPr(tmp),
		      mxGetM(tmp),mxGetN(tmp),
		      mb/2,mb/2+mc-1,nb/2,nb/2+nc-1);
	    if (cplx) subMatrix(mxGetPi(C_OUT),mxGetPi(tmp),
				mxGetM(tmp),mxGetN(tmp),
				mb/2,mb/2+mc-1,nb/2,nb/2+nc-1);
	    mxFreeMatrix(tmp);
	    break;
	  case VALID:	/* Return center section that is computed without edges. */
	    mc = ma-mb+1; nc = na-nb+1;
	    if ((mc < 0) || (nc < 0)) { /* Catch possible null matrix */
		C_OUT = mxCreateFull(0,0,cplx);
		return;
	    }
	    C_OUT = mxCreateFull(mc, nc, cplx);
	    subMatrix(mxGetPr(C_OUT),mxGetPr(tmp),
		      mxGetM(tmp),mxGetN(tmp),mb-1,mb+mc-2,nb-1,nb+nc-2);
	    if (cplx) subMatrix(mxGetPi(C_OUT),mxGetPi(tmp),
				mxGetM(tmp),mxGetN(tmp),mb-1,mb+mc-2,nb-1,nb+nc-2);
	    mxFreeMatrix(tmp);
	    break;
	}
    }
}

