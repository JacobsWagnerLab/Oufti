#include <math.h>
#include "mex.h"
//#include <iostream.h>
#include <time.h>
//#include <stddef.h>



typedef struct{long double x; long double y; int ctr; long double ind;} point;

long double pow2(long double x){return x*x;}

const long double delta2 = 2E-8L;
const long double delta3 = 1E-7L;


point findNextIntersection(long double *x1, long double *y1, long double *x2, long double *y2, int m, int n, point p0, bool self)
{
    // find the first intersection along contour 1 with contour 2 after startpoint
    
    long double *x1a,*y1a,*x2a,*y2a;
    long double vx,vy,wx,wy,vvx,vvy,zx,zy,ux,uy,cpuv,cpuvv,cpvz,cpwz,magv,magz,magu,r,ia,ib,intx,inty,ia2,ib2,intx2,inty2;
    int ind1,ind2,ind1a,ind2a,ind1b,ind2b,ind1c,ind2c,flint;
    point endpoint;
    
    // define the new contours so that we walk along contour x1a,y1a
    if(p0.ctr==0){x1a=x1;y1a=y1;ind1=m;x2a=x2;y2a=y2;ind2=n;}
    else{x1a=x2;y1a=y2;ind1=n;x2a=x1;y2a=y1;ind2=m;}
    
    // define the output for the case when there is no intersection
    endpoint.x = -1;
    endpoint.y = -1;
    endpoint.ctr = p0.ctr;
    endpoint.ind = -1;
    
    // check for intersections
    flint=int(floor(p0.ind));
    ia2=ind1+2;
    ind1a=0;
    
    ind1b=(ind1a+flint)%ind1;
    ind1c=(ind1a+flint+1)%ind1;
    ux = x1a[ind1c]-x1a[ind1b];
    uy = y1a[ind1c]-y1a[ind1b];
    magu=sqrt(ux*ux+uy*uy);
    if(magu==0){return endpoint;};
    ux=ux/magu;
    uy=uy/magu;
    for(ind2a=0;ind2a<ind2;ind2a++)
    {
        ind2b=ind2a%ind2;
        ind2c=(ind2a+1)%ind2;

        vx = x2a[ind2c]-x1a[ind1b];
        vy = y2a[ind2c]-y1a[ind1b];
        wx = x2a[ind2c]-x1a[ind1c];
        wy = y2a[ind2c]-y1a[ind1c];
        vvx = x2a[ind2b]-x1a[ind1b];
        vvy = y2a[ind2b]-y1a[ind1b];
        zx = x2a[ind2c]-x2a[ind2b];
        zy = y2a[ind2c]-y2a[ind2b];
        cpuv = ux*vy-uy*vx;
        cpuvv = ux*vvy-uy*vvx;
        cpvz = vx*zy-vy*zx;
        cpwz = wx*zy-wy*zx;
        if((cpuv*cpuvv<=0)&&(cpvz*cpwz<0))
        {
            magv=sqrt(vx*vx+vy*vy);
            if(magv==0)continue;
            vx=vx/magv;
            vy=vy/magv;
            magz=sqrt(zx*zx+zy*zy);
            if(magz==0)continue;
            zx=zx/magz;
            zy=zy/magz;
            r=magv*sin(acos(vx*zx+vy*zy))/sin(acos(-ux*zx-uy*zy));
            if((cpuv*cpuvv==0)&&(r==1))continue;
            ia=ind1b+r/magu;
            intx=x1a[ind1b]+r/magu*(x1a[ind1c]-x1a[ind1b]);
            inty=y1a[ind1b]+r/magu*(y1a[ind1c]-y1a[ind1b]);
            r=sqrt((x2a[ind2c]-intx)*(x2a[ind2c]-intx)+(y2a[ind2c]-inty)*(y2a[ind2c]-inty));
            if((cpuv*cpuvv==0)&&(r==1))continue;
            ib=ind2c-r/magz;
            if(ib<0){ib=ib+ind2;}
            //printf("ia=%f, p0.ind=%f, ia2=%f\n",ia,p0.ind,ia2);
            if((ia>p0.ind+delta2)&&(ia<ia2)){ia2=ia;ib2=ib;intx2=intx;inty2=inty;}
        }
    }
    if(ia2<=ind1+1){
        endpoint.x = intx2;
        endpoint.y = inty2;
        if(self){endpoint.ind = ia2;endpoint.ctr = p0.ctr;}
        else{endpoint.ind = ib2;endpoint.ctr = 1-p0.ctr;}
    }    
    //printf("%f %f %d %f\n",endpoint.x,endpoint.y,endpoint.ctr,endpoint.ind);
    return endpoint;
}



int countIntersections(long double *x1a, long double *y1a, long double *x2a, long double *y2a, int ind2)
{
    // count intersections of countour 1 (2 points / 1 segment) with contour 2 (m points / m segments)
    
    long double vx,vy,wx,wy,vvx,vvy,zx,zy,ux,uy,cpuv,cpuvv,cpvz,cpwz,magu;
    int ind2a,ind1b,ind2b,ind1c,ind2c;
    
    ind1b=0;
    ind1c=1;
    ux = x1a[ind1c]-x1a[ind1b];
    uy = y1a[ind1c]-y1a[ind1b];
    magu=sqrt(ux*ux+uy*uy);
    if(magu==0){return 0;};
    ux=ux/magu;
    uy=uy/magu;
    
    int c = 0;
    for(ind2a=0;ind2a<ind2;ind2a++)
    {
        ind2b=ind2a%ind2;
        ind2c=(ind2a+1)%ind2;
        vx = x2a[ind2c]-x1a[ind1b];
        vy = y2a[ind2c]-y1a[ind1b];
        wx = x2a[ind2c]-x1a[ind1c];
        wy = y2a[ind2c]-y1a[ind1c];
        vvx = x2a[ind2b]-x1a[ind1b];
        vvy = y2a[ind2b]-y1a[ind1b];
        zx = x2a[ind2c]-x2a[ind2b];
        zy = y2a[ind2c]-y2a[ind2b];
        cpuv = ux*vy-uy*vx;
        cpuvv = ux*vvy-uy*vvx;
        cpvz = vx*zy-vy*zx;
        cpwz = wx*zy-wy*zx;
        if((cpuv*cpuvv<=0)&&(cpvz*cpwz<0))
        {
            c++;
        }
    }
    return c;
}




bool inpolygon(long double *x, long double *y, int m, long double x0, long double y0)
{
    long double xi[2];
    long double yi[2];
    xi[0] = -1E6L;
    yi[0] = -1E6L;
    xi[1] = x0;
    yi[1] = y0;
    if(countIntersections(xi,yi,x,y,m)%2==1){return true;}else{return false;}
}


void makecw(long double *x1, long double *y1, int m)
{
    long double area = 0;
    int i,j;
    for(i=0;i<m;i++)
    {
        j = (i+1)%m;
        area = area + (x1[j]-x1[i])*(y1[j]+y1[i]);        
    }
    if(area<0)
    {
        long double tmp;
        int m2 = m/2;
        for(i=0;i<m2;i++)
        {
            tmp = x1[i];
            x1[i] = x1[m-1-i];
            x1[m-1-i] = tmp;
            tmp = y1[i];
            y1[i] = y1[m-1-i];
            y1[m-1-i] = tmp;
        }
    }
}



long double getArea(double *x0, double *y0, int m, double *x2c, double *y2c)
{
    long double x1[4];
    long double y1[4];   
    for(int i=0;i<m;i++){x1[i]=x0[i];y1[i]=y0[i];}
    makecw(x1,y1,m);
    //printf("%f %f %f %f   %f %f %f %f\n",x1[0],x1[1],x1[2],x1[3],y1[0],y1[1],y1[2],y1[3]);
    int n=4;
    long double x2[4]={0,0,1,1};
    long double y2[4]={0,1,1,0};
    for(int i=0;i<4;i++){x2[i]=*x2c+x2[i]-0.50000000L+0.0000123L;} // introducing a small shift to avoid overlapping nodes
    for(int i=0;i<4;i++){y2[i]=*y2c+y2[i]-0.50000000L+0.0000104L;}
    
    point p0;
    p0.x = x2[0];
    p0.y = y2[0];
    p0.ctr = 0;
    p0.ind = 0;
    //printf("p0=%f %f %d %f\n",p0.x,p0.y,p0.ctr,p0.ind);
    
    // choose the starting point
    bool inpoly = inpolygon(x1,y1,m,x2[0],y2[0]);
    if(!inpoly)
    {
        for(int i=0;i<4;i++)
        {
            p0.ind = i;
            p0 = findNextIntersection(x2,y2,x1,y1,n,m,p0,true);
            //printf("current point=%f %f %d %f\n",p0.x,p0.y,p0.ctr,p0.ind);
            if(p0.ind>=0){break;}
        }
        if(p0.ind<0){return 0;}
    }
    point startpoint = p0;
    //printf("starting point=%f %f %d %f\n",p0.x,p0.y,p0.ctr,p0.ind);
    
    // initialize cycling variables
    long double area = 0;
    long double xold,yold,ind,da;
    
    // initialize variables for the "second check"
    point secondpoint;
    bool secondpointchk = true;
    long double area2;
    
    // cycle around the overlapping area
    for(int i=1;i<200;i++)
    {
        xold = p0.x;
        yold = p0.y;
        ind = p0.ind;
        p0 = findNextIntersection(x2,y2,x1,y1,n,m,p0,false);
        if(p0.ind<0)
        {
            if(p0.ctr==0)
            {
                p0.ind = fmod(floor(ind+1),4);
                p0.x = x2[(int)p0.ind];
                p0.y = y2[(int)p0.ind];
            }
            else
            {
                p0.ind = fmod(floor(ind+1),m);
                p0.x = x1[(int)p0.ind];
                p0.y = y1[(int)p0.ind];
            }
            //printf("No xn: proceed from vertex %f (%f,%f) to vertex %f (%f,%f) on contour %d\n",ind,xold,yold,p0.ind,p0.x,p0.y,p0.ctr);
        }
        da = (p0.x-xold)*(p0.y+yold)/2;
        area += da;
        area2 += da;
        //printf("x=%f, y=%f, xold=%f, yold=%f, ctr=%d, ind=%f, area=%f\n",p0.x,p0.y,xold,yold,p0.ctr,p0.ind,area);
        if((fabs(p0.x-startpoint.x)<delta3)&&(fabs(p0.y-startpoint.y)<delta3)){break;}
        //printf("0x=%f, sx=%f, dx=%e, cx=%d, 0y=%f, sy=%f, dy=%e, cy=%d\n",p0.x,startpoint.x,fabs(p0.x-startpoint.x),(fabs(p0.x-startpoint.x)<delta3),p0.y,startpoint.y,fabs(p0.y-startpoint.y),(fabs(p0.y-startpoint.y)<delta3));
        //printf("0i=%f, si=%f, di=%e, ci=%d, 0c=%d, sc=%d, dc=%d, cy=%d\n",p0.ind,startpoint.ind,fabs(p0.ind-startpoint.ind),(fabs(p0.ind-startpoint.ind)<delta3),p0.ctr,startpoint.ctr,abs(p0.ctr-startpoint.ctr),(abs(p0.ctr-startpoint.ctr)<delta3));
        if(secondpointchk)
            {secondpoint=p0; secondpointchk=false; area2=0;}
        else
            if((fabs(p0.x-secondpoint.x)<delta3)&&(fabs(p0.y-secondpoint.y)<delta3)){area=area2;break;}
        //printf("0x=%f, sx=%f, dx=%e, cx=%d, 0y=%f, sy=%f, dy=%e, cy=%d\n",p0.x,secondpoint.x,fabs(p0.x-secondpoint.x),(fabs(p0.x-secondpoint.x)<delta3),p0.y,secondpoint.y,fabs(p0.y-secondpoint.y),(fabs(p0.y-secondpoint.y)<delta3));
        //printf("0i=%f, si=%f, di=%e, ci=%d, 0c=%d, sc=%d, dc=%d, cy=%d\n",p0.ind,secondpoint.ind,fabs(p0.ind-secondpoint.ind),(fabs(p0.ind-secondpoint.ind)<delta3),p0.ctr,secondpoint.ctr,abs(p0.ctr-secondpoint.ctr),(abs(p0.ctr-secondpoint.ctr)<delta3));
    }
    //printf("da=%e\n",area-1);
    if((area<-delta2)||(area>1+delta2)){printf("Possible error computing segment area: area=%f.\n",area);return 0;}
    return area;
}




void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{ 
    double *ax,*ay,*bx,*by,*area;
    size_t m0,n0,m1,n1;

    /* Check for proper number and type of arguments */
    if (nrhs != 4) { 
	mexErrMsgTxt("4 input arguments required."); 
    } else if (nlhs != 1) {
	mexErrMsgTxt("1 output argument required."); 
    } 
    m0 = mxGetM(prhs[0]); 
    n0 = mxGetN(prhs[0]);
    m1 = mxGetM(prhs[1]); 
    n1 = mxGetN(prhs[1]);
    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) || (n0 != 1 ) || (m0 <= 1 ) ||
        !mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]) || (n1 != n0) || (m1 != m0) ||
        !mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]) ||
        !mxIsDouble(prhs[3]) || mxIsComplex(prhs[3])) {
        mexErrMsgTxt("Inputs 1-2 must be Nx1 real vectors, inputs 3-4 must be real scalars."); 
    }

    /* Assign pointers to the arguments */ 
    ax = mxGetPr(prhs[0]);
    ay = mxGetPr(prhs[1]);
    bx = mxGetPr(prhs[2]);
    by = mxGetPr(prhs[3]);

    /* Create a matrix for the return argument */ 
    plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
    area = mxGetPr(plhs[0]);
    
    /* Assign the result */
    area[0] = getArea(ax,ay,m0,bx,by);
    return;
}