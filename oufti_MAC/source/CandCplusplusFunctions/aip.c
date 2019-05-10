#include <math.h>
// #include <iostream.h>
#include "mex.h"
#include <time.h>



typedef struct{double x; double y; int ctr; double ind;} point;

double pow2(double x){return x*x;}

double delta = 1E-4;



point findNextIntersection(double *x1, double *y1, double *x2, double *y2, int m, int n, point p0, bool self)
{
    // find the first intersection along contour 1 with contour 2 after startpoint
    
    double *x1a,*y1a,*x2a,*y2a;
    double vx,vy,wx,wy,vvx,vvy,zx,zy,ux,uy,cpuv,cpuvv,cpvz,cpwz,magv,magz,magu,r,ia,ib,intx,inty,ia2,ib2,intx2,inty2;
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
    flint=(int)floor(p0.ind);
    ia2=ind1+2;
    ind1a=0;
    {
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
                if((ia>p0.ind+delta*delta)&&(ia<ia2)){ia2=ia;ib2=ib;intx2=intx;inty2=inty;}
            }
        }
        if(ia2<=ind1+1){
            endpoint.x = intx2;
            endpoint.y = inty2;
            if(self){endpoint.ind = ia2;endpoint.ctr = p0.ctr;}
            else{endpoint.ind = ib2;endpoint.ctr = 1-p0.ctr;}
        }
    }
    //printf("%f %f %d %f\n",endpoint.x,endpoint.y,endpoint.ctr,endpoint.ind);
    return endpoint;
}



int countIntersections(double *x1a, double *y1a, double *x2a, double *y2a, int ind2)
{
    // count intersections of countour 1 (2 points / 1 segment) with contour 2 (m points / m segments)
    
    double vx,vy,wx,wy,vvx,vvy,zx,zy,ux,uy,cpuv,cpuvv,cpvz,cpwz,magu;
    int ind2a,ind1b,ind2b,ind1c,ind2c,c;
    
    ind1b=0;
    ind1c=1;
    ux = x1a[ind1c]-x1a[ind1b];
    uy = y1a[ind1c]-y1a[ind1b];
    magu=sqrt(ux*ux+uy*uy);
    if(magu==0){return 0;};
    ux=ux/magu;
    uy=uy/magu;
    
    c = 0;
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



double frand()
{
    return ((double)rand()/(double)RAND_MAX)-0.5;
}



bool inpolygon(double *x, double *y, int m, double x0, double y0)
{
    double xi[2];
    double yi[2];
    xi[0] = -1E6;
    yi[0] = 2E6*frand();
    xi[1] = x0;
    yi[1] = y0;
    if(countIntersections(xi,yi,x,y,m)%2==1){return true;}else{return false;}
}




double getArea(double *x1, double *y1, int m, double *x2c, double *y2c)
{
    int i;
    double r;
    int n=4;
    double x2p[4]={0,0,1,1};
    double y2p[4]={0,1,1,0};
    double x2[4];
    double y2[4];
    point p0, startpoint;
    bool inpoly;
    double area,xold,yold,ind;

    srand ( time(NULL) ); frand();
    r = frand()*delta;
    //printf("rand=%f\n",r);
    for(i=0;i<m;i++){x1[i]=x1[i]+r;y1[i]=y1[i]+r;}
    
    for(i=0;i<4;i++){x2[i]=*x2c+x2p[i];}
    for(i=0;i<4;i++){y2[i]=*y2c+y2p[i];}
    
    p0.x = x2[0];
    p0.y = y2[0];
    p0.ctr = 0;
    p0.ind = 0;
    
    // choose the starting point
    inpoly = inpolygon(x1,y1,m,x2[0],y2[0]);
    if(!inpoly)
    {
        for(i=0;i<4;i++)
        {
            p0.ind = i;
            p0 = findNextIntersection(x2,y2,x1,y1,n,m,p0,true);
            if(p0.ind>=0){break;}
        }
        if(p0.ind<0){return 0;}
    }
    startpoint = p0;
    //printf("starting point=%f %f %d %f\n",p0.x,p0.y,p0.ctr,p0.ind);
    
    // cycle around the intersection
    area = 0;
    for(i=1;i<100;i++)
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
        area = area + (p0.x-xold)*(p0.y+yold)/2;
        //printf("x=%f, y=%f, xold=%f, yold=%f, ctr=%d, ind=%f, area=%f\n",p0.x,p0.y,xold,yold,p0.ctr,p0.ind,area);
        if((abs(p0.ind-startpoint.ind)<delta*delta)&&(abs(p0.ctr-startpoint.ctr)<delta*delta)){break;}
    }
    
    //if(area>1){printf("error computing segment area: area=%f\n",area);return 0;}else{printf("finished OK: area=%f\n",area);}
    if(area>1){return 0;}
    return area;
}




void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[])
{ 
    double *ax,*ay,*bx,*by,*area;
    mwSize m,n;

    /* Check for proper number and type of arguments */
    if (nrhs != 4) { 
	mexErrMsgTxt("4 input arguments required."); 
    } else if (nlhs != 1) {
	mexErrMsgTxt("1 output argument required."); 
    } 
    m = mxGetN(prhs[0]); 
    n = mxGetN(prhs[2]);
    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) || 
        !mxIsDouble(prhs[1]) || mxIsComplex(prhs[1]) ||
        !mxIsDouble(prhs[2]) || mxIsComplex(prhs[2]) ||
        !mxIsDouble(prhs[3]) || mxIsComplex(prhs[3]) || (n != 1) || (m == 1)) { 
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
    area[0] = getArea(ax,ay,m,bx,by);
    return;
}
