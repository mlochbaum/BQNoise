#include <stdlib.h>

typedef long long I;
typedef double    D;

#define DO(n,stm) {I i=0,_n=(n); for(;i<_n;i++){stm}}
#define DECL_ARR(t, v, l) t *v = malloc(sizeof(t)*(l))

void filter11(I,D*,D,D);
void filter21(I,D*,D,D,D);
void filter32(I,D*,D,D,D,D,D);
void filter(I length, D* a, I lx, D* xc, I ly, D* yc) {
    if (lx==1 && ly==1) { return filter11(length,a,xc[0],yc[0]); }
    if (lx==2 && ly==1) { return filter21(length,a,xc[0],xc[1],yc[0]); }
    if (lx==3 && ly==2) { return filter32(length,a,xc[0],xc[1],xc[2],yc[0],yc[1]); }
    DECL_ARR(D, x, lx); DECL_ARR(D, y, ly);
    DO(lx, x[i]=0;); DO(ly, y[i]=0;);
    int j, ix=0, iy=0;
    for (j=0; j<length; j++) {
        x[ix++] = a[j]; ix%=lx;
        a[j] = 0;
        DO(lx, a[j] += x[(ix+i)%lx] * xc[i];);
        DO(ly, a[j] += y[(iy+i)%ly] * yc[i];);
        y[iy++] = a[j]; iy%=ly;
    }
    free(x); free(y);
    return;
}

void filter11(I length, D* a, D xc0, D yc0) {
    D x0=0, y0=0; int j;
    for (j=0; j<length; j++) {
        x0 = a[j];
        a[j] = x0*xc0 + y0*yc0;
        y0 = a[j];
    }
    return;
}
void filter21(I length, D* a, D xc0, D xc1, D yc0) {
    D x0=0, x1=0, y0=0; int j;
    for (j=0; j<length; j++) {
        x0 = x1; x1 = a[j];
        a[j] = x0*xc0 + x1*xc1 + y0*yc0;
        y0 = a[j];
    }
    return;
}
void filter32(I length, D* a, D xc0, D xc1, D xc2, D yc0, D yc1) {
    D x0=0, x1=0, x2=0, y0=0, y1=0; int j;
    for (j=0; j<length; j++) {
        x0 = x1; x1 = x2; x2 = a[j];
        a[j] = x0*xc0 + x1*xc1 + x2*xc2 + y0*yc0 + y1*yc1;
        y0 = y1; y1 = a[j];
    }
    return;
}
