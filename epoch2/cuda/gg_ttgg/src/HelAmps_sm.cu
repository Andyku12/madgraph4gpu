//==========================================================================
// This file has been automatically generated for C++ Standalone by
// MadGraph5_aMC@NLO v. 2.8.2, 2020-10-30
// By the MadGraph5_aMC@NLO Development Team
// Visit launchpad.net/madgraph5 and amcatnlo.web.cern.ch
//==========================================================================

#include <cmath>
#include <cstring>
#include <cstdlib>
#include <iomanip>
#include <iostream>

#include "mgOnGpuConfig.h"
#include "mgOnGpuTypes.h"

mgDebugDeclare(); 

namespace MG5_sm
{

using mgOnGpu::nw6; 

//--------------------------------------------------------------------------

__device__
inline const fptype& pIparIp4Ievt(const fptype * momenta1d,  // input: momenta as AOSOA[npagM][npar][4][neppM]
const int ipar, 
const int ip4, 
const int ievt)
{
  // mapping for the various scheme AOS, OSA, ...

  using mgOnGpu::np4; 
  using mgOnGpu::npar; 
  const int neppM = mgOnGpu::neppM;  // ASA layout: constant at compile-time
  fptype (*momenta)[npar][np4][neppM] = (fptype (*)[npar][np4][neppM])
      momenta1d; // cast to multiD array pointer (AOSOA)
  const int ipagM = ievt/neppM;  // #eventpage in this iteration
  const int ieppM = ievt%neppM;  // #event in the current eventpage in this iteration
  // return allmomenta[ipagM*npar*np4*neppM + ipar*neppM*np4 + ip4*neppM +
  // ieppM]; // AOSOA[ipagM][ipar][ip4][ieppM]
  return momenta[ipagM][ipar][ip4][ieppM]; 
}

//--------------------------------------------------------------------------

__device__ void ixxxxx(const fptype * allmomenta, const fptype& fmass, const
    int& nhel, const int& nsf,
cxtype fi[6], 
#ifndef __CUDACC__
const int ievt, 
#endif
const int ipar)  // input: particle# out of npar
{
  mgDebug(0, __FUNCTION__); 
#ifdef __CUDACC__
  const int ievt = blockDim.x * blockIdx.x + threadIdx.x;  // index of event (thread) in grid
#endif
#ifndef __CUDACC__
  using std::max; 
  using std::min; 
#endif

  const fptype& pvec0 = pIparIp4Ievt(allmomenta, ipar, 0, ievt);
  const fptype& pvec1 = pIparIp4Ievt(allmomenta, ipar, 1, ievt); 
  const fptype& pvec2 = pIparIp4Ievt(allmomenta, ipar, 2, ievt); 
  const fptype& pvec3 = pIparIp4Ievt(allmomenta, ipar, 3, ievt); 

  cxtype chi[2]; 
  fptype sf[2], sfomega[2], omega[2], pp, pp3, sqp0p3, sqm[2]; 
  int ip, im, nh; 

  fptype p[4] = {0, pvec1, pvec2, pvec3}; 
  //p[0] = sqrt(p[1] * p[1] + p[2] * p[2] + p[3] * p[3] + fmass * fmass); // AV: BUG?! (NOT AS IN THE FORTRAN)
  p[0] = pvec0; // AV: BUG FIX (DO AS IN THE FORTRAN)
  fi[0] = cxtype(-p[0] * nsf, -p[3] * nsf); 
  fi[1] = cxtype(-p[1] * nsf, -p[2] * nsf); 
  nh = nhel * nsf; 
  if (fmass != 0.0)
  {
    pp = min(p[0], sqrt(p[1] * p[1] + p[2] * p[2] + p[3] * p[3])); 
    if (pp == 0.0)
    {
      sqm[0] = sqrt(std::abs(fmass)); 
      //sqm[1] = (fmass < 0) ? - abs(sqm[0]) : abs(sqm[0]); // BUG issue #198
      sqm[1] = (fmass < 0) ? -sqm[0] : sqm[0];
      ip = (1 + nh)/2; 
      im = (1 - nh)/2; 
      fi[2] = ip * sqm[ip]; 
      fi[3] = im * nsf * sqm[ip]; 
      fi[4] = ip * nsf * sqm[im]; 
      fi[5] = im * sqm[im]; 
    }
    else
    {
      sf[0] = (1 + nsf + (1 - nsf) * nh) * 0.5; 
      sf[1] = (1 + nsf - (1 - nsf) * nh) * 0.5; 
      omega[0] = sqrt(p[0] + pp); 
      omega[1] = fmass/omega[0]; 
      ip = (1 + nh)/2; 
      im = (1 - nh)/2; 
      sfomega[0] = sf[0] * omega[ip]; 
      sfomega[1] = sf[1] * omega[im]; 
      pp3 = max(pp + p[3], 0.0); 
      chi[0] = cxtype(sqrt(pp3 * 0.5/pp), 0); 
      if (pp3 == 0.0)
      {
        chi[1] = cxtype(-nh, 0); 
      }
      else
      {
        chi[1] = 
        cxtype(nh * p[1], p[2])/sqrt(2.0 * pp * pp3); 
      }
      fi[2] = sfomega[0] * chi[im]; 
      fi[3] = sfomega[0] * chi[ip]; 
      fi[4] = sfomega[1] * chi[im]; 
      fi[5] = sfomega[1] * chi[ip]; 
    }
  }
  else
  {
    if (p[1] == 0.0 and p[2] == 0.0 and p[3] < 0.0)
    {
      sqp0p3 = 0.0; 
    }
    else
    {
      sqp0p3 = sqrt(max(p[0] + p[3], 0.0)) * nsf; 
    }
    chi[0] = cxtype(sqp0p3, 0.0); 
    if (sqp0p3 == 0.0)
    {
      chi[1] = cxtype(-nhel * sqrt(2.0 * p[0]), 0.0); 
    }
    else
    {
      chi[1] = cxtype(nh * p[1], p[2])/sqp0p3; 
    }
    if (nh == 1)
    {
      fi[2] = cxtype(0.0, 0.0); 
      fi[3] = cxtype(0.0, 0.0); 
      fi[4] = chi[0]; 
      fi[5] = chi[1]; 
    }
    else
    {
      fi[2] = chi[1]; 
      fi[3] = chi[0]; 
      fi[4] = cxtype(0.0, 0.0); 
      fi[5] = cxtype(0.0, 0.0); 
    }
  }
  //** END LOOP ON IEVT **
  mgDebug(1, __FUNCTION__); 
  return; 
}


__device__ void ipzxxx(const fptype * allmomenta, const int& nhel, const int&
    nsf,
cxtype fi[6], 
#ifndef __CUDACC__
const int ievt, 
#endif
const int ipar)  // input: particle# out of npar
{
  // ASSUMPTION FMASS == 0
  // PX = PY = 0
  // E = P3 (E>0)
#ifdef __CUDACC__
  const int ievt = blockDim.x * blockIdx.x + threadIdx.x;  // index of event (thread) in grid
#endif  
  // const fptype& pvec0 = pIparIp4Ievt( allmomenta, ipar, 0, ievt );
  const fptype& pvec3 = pIparIp4Ievt(allmomenta, ipar, 3, ievt); 

  fi[0] = cxtype (-pvec3 * nsf, -pvec3 * nsf); 
  fi[1] = cxtype (0., 0.); 
  int nh = nhel * nsf; 

  cxtype sqp0p3 = cxtype(sqrt(2. * pvec3) * nsf, 0.); 

  fi[2] = fi[1]; 
  if(nh == 1)
  {
    fi[3] = fi[1]; 
    fi[4] = sqp0p3; 
  }
  else
  {
    fi[3] = sqp0p3; 
    fi[4] = fi[1]; 
  }
  fi[5] = fi[1]; 
}

__device__ void imzxxx(const fptype * allmomenta, const int& nhel, const int&
    nsf,
cxtype fi[6], 
#ifndef __CUDACC__
const int ievt, 
#endif
const int ipar)  // input: particle# out of npar
{
  // ASSUMPTION FMASS == 0
  // PX = PY = 0
  // E = -P3 (E>0)
  // printf("p3 %f", pvec[2]);
#ifdef __CUDACC__
  const int ievt = blockDim.x * blockIdx.x + threadIdx.x;  // index of event (thread) in grid
#endif  
  const fptype& pvec3 = pIparIp4Ievt(allmomenta, ipar, 3, ievt); 
  fi[0] = cxtype (pvec3 * nsf, -pvec3 * nsf); 
  fi[1] = cxtype (0., 0.); 
  int nh = nhel * nsf; 
  cxtype chi = cxtype (-nhel * sqrt(-2.0 * pvec3), 0.0); 


  fi[3] = fi[1]; 
  fi[4] = fi[1]; 
  if (nh == 1)
  {
    fi[2] = fi[1]; 
    fi[5] = chi; 
  }
  else
  {
    fi[2] = chi; 
    fi[5] = fi[1]; 
  }
}

__device__ void ixzxxx(const fptype * allmomenta, const int& nhel, const int&
    nsf,
cxtype fi[6], 
#ifndef __CUDACC__
const int ievt, 
#endif
const int ipar)  // input: particle# out of npar
{
  // ASSUMPTIONS: FMASS == 0
  // Px and Py are not zero

  // cxtype chi[2];
  // fptype sf[2], sfomega[2], omega[2], pp, pp3, sqp0p3, sqm[2];
  // int ip, im, nh;
#ifdef __CUDACC__
  const int ievt = blockDim.x * blockIdx.x + threadIdx.x;  // index of event (thread) in grid
#endif  
  const fptype& pvec0 = pIparIp4Ievt(allmomenta, ipar, 0, ievt); 
  const fptype& pvec1 = pIparIp4Ievt(allmomenta, ipar, 1, ievt); 
  const fptype& pvec2 = pIparIp4Ievt(allmomenta, ipar, 2, ievt); 
  const fptype& pvec3 = pIparIp4Ievt(allmomenta, ipar, 3, ievt); 


  // fptype p[4] = {(float), (float) pvec[0], (float) pvec[1], (float) pvec[2]};
  // p[0] = sqrtf(p[3] * p[3] + p[1] * p[1] + p[2] * p[2]);

  fi[0] = cxtype (-pvec0 * nsf, -pvec2 * nsf); 
  fi[1] = cxtype (-pvec0 * nsf, -pvec1 * nsf); 
  int nh = nhel * nsf; 

  float sqp0p3 = sqrtf(pvec0 + pvec3) * nsf; 
  cxtype chi0 = cxtype (sqp0p3, 0.0); 
  cxtype chi1 = cxtype (nh * pvec1/sqp0p3, pvec2/sqp0p3); 
  cxtype CZERO = cxtype(0., 0.); 

  if (nh == 1)
  {
    fi[2] = CZERO; 
    fi[3] = CZERO; 
    fi[4] = chi0; 
    fi[5] = chi1; 
  }
  else
  {
    fi[2] = chi1; 
    fi[3] = chi0; 
    fi[4] = CZERO; 
    fi[5] = CZERO; 
  }

  return; 
}

__device__ void vxxxxx(const fptype * allmomenta, const fptype& vmass, const
    int& nhel, const int& nsv,
cxtype vc[6], 
#ifndef __CUDACC__
const int ievt, 
#endif
const int ipar)  // input: particle# out of npar
{
  fptype hel, hel0, pt, pt2, pp, pzpt, emp, sqh; 
  int nsvahl; 

#ifdef __CUDACC__
  const int ievt = blockDim.x * blockIdx.x + threadIdx.x;  // index of event (thread) in grid
#else
  using std::min; 
#endif

  const fptype& p0 = pIparIp4Ievt(allmomenta, ipar, 0, ievt); 
  const fptype& p1 = pIparIp4Ievt(allmomenta, ipar, 1, ievt); 
  const fptype& p2 = pIparIp4Ievt(allmomenta, ipar, 2, ievt); 
  const fptype& p3 = pIparIp4Ievt(allmomenta, ipar, 3, ievt); 
  // fptype p[4] = {0, pvec[0], pvec[1], pvec[2]};
  // p[0] = sqrt(p[1] * p[1] + p[2] * p[2] + p[3] * p[3]+vmass*vmass);

  sqh = sqrt(0.5); 
  hel = fptype(nhel); 
  nsvahl = nsv * std::abs(hel); 
  pt2 = (p1 * p1) + (p2 * p2); 
  pp = min(p0, sqrt(pt2 + (p3 * p3))); 
  pt = min(pp, sqrt(pt2)); 
  vc[0] = cxtype(p0 * nsv, p3 * nsv); 
  vc[1] = cxtype(p1 * nsv, p2 * nsv); 
  if (vmass != 0.0)
  {
    hel0 = 1.0 - std::abs(hel); 
    if (pp == 0.0)
    {
      vc[2] = cxtype(0.0, 0.0); 
      vc[3] = cxtype(-hel * sqh, 0.0); 
      vc[4] = cxtype(0.0, nsvahl * sqh); 
      vc[5] = cxtype(hel0, 0.0); 
    }
    else
    {
      emp = p0/(vmass * pp); 
      vc[2] = cxtype(hel0 * pp/vmass, 0.0); 
      vc[5] = 
      cxtype(hel0 * p3 * emp + hel * pt/pp * sqh, 0.0); 
      if (pt != 0.0)
      {
        pzpt = p3/(pp * pt) * sqh * hel; 
        vc[3] = cxtype(hel0 * p1 * emp - p1 * pzpt, 
         - nsvahl * p2/pt * sqh); 
        vc[4] = cxtype(hel0 * p2 * emp - p2 * pzpt, 
        nsvahl * p1/pt * sqh); 
      }
      else
      {
        vc[3] = cxtype(-hel * sqh, 0.0); 
        //vc[4] = cxtype(0.0, nsvahl * (p3 < 0) ? - abs(sqh) : abs(sqh)); // BUG issue #198
        vc[4] = cxtype(0.0, nsvahl * (p3 < 0) ? -sqh : sqh);
      }
    }
  }
  else
  {
    // pp = p0;
    pt = sqrt((p1 * p1) + (p2 * p2)); 
    vc[2] = cxtype(0.0, 0.0); 
    vc[5] = cxtype(hel * pt/p0 * sqh, 0.0); 
    if (pt != 0.0)
    {
      pzpt = p3/(p0 * pt) * sqh * hel; 
      vc[3] = cxtype(-p1 * pzpt, -nsv * p2/pt * sqh); 
      vc[4] = cxtype(-p2 * pzpt, nsv * p1/pt * sqh); 
    }
    else
    {
      vc[3] = cxtype(-hel * sqh, 0.0); 
      //vc[4] = cxtype(0.0, nsv * (p3 < 0) ? - abs(sqh) : abs(sqh)); // BUG issue #198
      vc[4] = cxtype(0.0, nsv * (p3 < 0) ? -sqh : sqh);
    }
  }
  return; 
}

__device__ void sxxxxx(const fptype * allmomenta, const fptype& smass, const
    int& nhel, const int& nss,
cxtype sc[3], 
#ifndef __CUDACC__
const int ievt, 
#endif
const int ipar)
{
#ifdef __CUDACC__
  const int ievt = blockDim.x * blockIdx.x + threadIdx.x;  // index of event (thread) in grid
#endif
  const fptype& p0 = pIparIp4Ievt(allmomenta, ipar, 0, ievt); 
  const fptype& p1 = pIparIp4Ievt(allmomenta, ipar, 1, ievt); 
  const fptype& p2 = pIparIp4Ievt(allmomenta, ipar, 2, ievt); 
  const fptype& p3 = pIparIp4Ievt(allmomenta, ipar, 3, ievt); 
  // fptype p[4] = {0, pvec[0], pvec[1], pvec[2]};
  // p[0] = sqrt(p[1] * p[1] + p[2] * p[2] + p[3] * p[3]+smass*smass);
  sc[2] = cxtype(1.00, 0.00); 
  sc[0] = cxtype(p0 * nss, p3 * nss); 
  sc[1] = cxtype(p1 * nss, p2 * nss); 
  return; 
}

__device__ void oxxxxx(const fptype * allmomenta, const fptype& fmass, const
    int& nhel, const int& nsf,
cxtype fo[6], 
#ifndef __CUDACC__
const int ievt, 
#endif
const int ipar)  // input: particle# out of npar
{
#ifdef __CUDACC__
  const int ievt = blockDim.x * blockIdx.x + threadIdx.x;  // index of event (thread) in grid
#endif
#ifndef __CUDACC__
  using std::min; 
  using std::max; 
#endif
  cxtype chi[2]; 
  fptype sf[2], sfomeg[2], omega[2], pp, pp3, sqp0p3, sqm[2]; 
  int nh, ip, im; 

  const fptype& p0 = pIparIp4Ievt(allmomenta, ipar, 0, ievt); 
  const fptype& p1 = pIparIp4Ievt(allmomenta, ipar, 1, ievt); 
  const fptype& p2 = pIparIp4Ievt(allmomenta, ipar, 2, ievt); 
  const fptype& p3 = pIparIp4Ievt(allmomenta, ipar, 3, ievt); 

  // fptype p[4] = {0, pvec[0], pvec[1], pvec[2]};
  // p[0] = sqrt(p[1] * p[1] + p[2] * p[2] + p[3] * p[3]+fmass*fmass);

  fo[0] = cxtype(p0 * nsf, p3 * nsf); 
  fo[1] = cxtype(p1 * nsf, p2 * nsf); 
  nh = nhel * nsf; 
  if (fmass != 0.000)
  {
    pp = min(p0, sqrt((p1 * p1) + (p2 * p2) + (p3 * p3))); 
    if (pp == 0.000)
    {
      sqm[0] = sqrt(std::abs(fmass)); 
      //sqm[1] = (fmass < 0) ? - abs(sqm[0]) : abs(sqm[0]); // BUG issue #198
      sqm[1] = (fmass < 0) ? -sqm[0] : sqm[0];
      ip = -((1 - nh)/2) * nhel; 
      im = (1 + nh)/2 * nhel; 
      fo[2] = im * sqm[std::abs(ip)]; 
      fo[3] = ip * nsf * sqm[std::abs(ip)]; 
      fo[4] = im * nsf * sqm[std::abs(im)]; 
      fo[5] = ip * sqm[std::abs(im)]; 
    }
    else
    {
      sf[0] = fptype(1 + nsf + (1 - nsf) * nh) * 0.5; 
      sf[1] = fptype(1 + nsf - (1 - nsf) * nh) * 0.5; 
      omega[0] = sqrt(p0 + pp); 
      omega[1] = fmass/omega[0]; 
      ip = (1 + nh)/2; 
      im = (1 - nh)/2; 
      sfomeg[0] = sf[0] * omega[ip]; 
      sfomeg[1] = sf[1] * omega[im]; 
      pp3 = max(pp + p3, 0.00); 
      chi[0] = cxtype(sqrt(pp3 * 0.5/pp), 0.00); 
      if (pp3 == 0.00)
      {
        chi[1] = cxtype(-nh, 0.00); 
      }
      else
      {
        chi[1] = 
        cxtype(nh * p1, -p2)/sqrt(2.0 * pp * pp3); 
      }
      fo[2] = sfomeg[1] * chi[im]; 
      fo[3] = sfomeg[1] * chi[ip]; 
      fo[4] = sfomeg[0] * chi[im]; 
      fo[5] = sfomeg[0] * chi[ip]; 
    }
  }
  else
  {
    if ((p1 == 0.00) and (p2 == 0.00) and (p3 < 0.00))
    {
      sqp0p3 = 0.00; 
    }
    else
    {
      sqp0p3 = sqrt(max(p0 + p3, 0.00)) * nsf; 
    }
    chi[0] = cxtype(sqp0p3, 0.00); 
    if (sqp0p3 == 0.000)
    {
      chi[1] = cxtype(-nhel, 0.00) * sqrt(2.0 * p0); 
    }
    else
    {
      chi[1] = cxtype(nh * p1, -p2)/sqp0p3; 
    }
    if (nh == 1)
    {
      fo[2] = chi[0]; 
      fo[3] = chi[1]; 
      fo[4] = cxtype(0.00, 0.00); 
      fo[5] = cxtype(0.00, 0.00); 
    }
    else
    {
      fo[2] = cxtype(0.00, 0.00); 
      fo[3] = cxtype(0.00, 0.00); 
      fo[4] = chi[1]; 
      fo[5] = chi[0]; 
    }
  }
  return; 
}

__device__ void opzxxx(const fptype * allmomenta, const int& nhel, const int&
    nsf,
cxtype fo[6], 
#ifndef __CUDACC__
const int ievt, 
#endif
const int ipar)  // input: particle# out of npar
{
  // ASSUMPTIONS FMASS =0
  // PX = PY =0
  // E = PZ
#ifdef __CUDACC__
  const int ievt = blockDim.x * blockIdx.x + threadIdx.x;  // index of event (thread) in grid
#endif  
  const fptype& pvec3 = pIparIp4Ievt(allmomenta, ipar, 3, ievt); 

  fo[0] = cxtype (pvec3 * nsf, pvec3 * nsf); 
  fo[1] = cxtype (0., 0.); 
  int nh = nhel * nsf; 

  cxtype CSQP0P3 = cxtype (sqrt(2. * pvec3) * nsf, 0.00); 


  fo[3] = fo[1]; 
  fo[4] = fo[1]; 
  if (nh == 1)
  {
    fo[2] = CSQP0P3; 
    fo[5] = fo[1]; 
  }
  else
  {
    fo[2] = fo[1]; 
    fo[5] = CSQP0P3; 
  }
}


__device__ void omzxxx(const fptype * allmomenta, const int& nhel, const int&
    nsf,
cxtype fo[6], 
#ifndef __CUDACC__
const int ievt, 
#endif
const int ipar)  // input: particle# out of npar
{
  // ASSUMPTIONS FMASS =0
  // PX = PY =0
  // E = -PZ (E>0)
#ifdef __CUDACC__
  const int ievt = blockDim.x * blockIdx.x + threadIdx.x;  // index of event (thread) in grid
#endif  
  const fptype& pvec3 = pIparIp4Ievt(allmomenta, ipar, 3, ievt); 
  fo[0] = cxtype (-pvec3 * nsf, pvec3 * nsf); 
  fo[1] = cxtype (0., 0.); 
  int nh = nhel * nsf; 
  cxtype chi = cxtype (-nhel, 0.00) * sqrt(-2.0 * pvec3); 

  if(nh == 1)
  {
    fo[2] = fo[1]; 
    fo[3] = chi; 
    fo[4] = fo[1]; 
    fo[5] = fo[1]; 
  }
  else
  {
    fo[2] = fo[1]; 
    fo[3] = fo[1]; 
    fo[4] = chi; 
    fo[5] = chi; 
  }
  return; 
}

__device__ void oxzxxx(const fptype * allmomenta, const int& nhel, const int&
    nsf,
cxtype fo[6], 
#ifndef __CUDACC__
const int ievt, 
#endif
const int ipar)  // input: particle# out of npar
{
  // ASSUMPTIONS FMASS =0
  // PT > 0
#ifdef __CUDACC__
  const int ievt = blockDim.x * blockIdx.x + threadIdx.x;  // index of event (thread) in grid
#endif  
  const fptype& p0 = pIparIp4Ievt(allmomenta, ipar, 0, ievt); 
  const fptype& p1 = pIparIp4Ievt(allmomenta, ipar, 1, ievt); 
  const fptype& p2 = pIparIp4Ievt(allmomenta, ipar, 2, ievt); 
  const fptype& p3 = pIparIp4Ievt(allmomenta, ipar, 3, ievt); 

  // float p[4] = {0, (float) pvec[0], (float) pvec[1], (float) pvec[2]};
  // p[0] = sqrtf(p[1] * p[1] + p[2] * p[2] + p[3] * p[3]);

  fo[0] = cxtype (p0 * nsf, p3 * nsf); 
  fo[1] = cxtype (p1 * nsf, p2 * nsf); 
  int nh = nhel * nsf; 

  float sqp0p3 = sqrtf(p0 + p3) * nsf; 
  cxtype chi0 = cxtype (sqp0p3, 0.00); 
  cxtype chi1 = cxtype (nh * p1/sqp0p3, -p2/sqp0p3); 
  cxtype zero = cxtype (0.00, 0.00); 

  if(nh == 1)
  {
    fo[2] = chi0; 
    fo[3] = chi1; 
    fo[4] = zero; 
    fo[5] = zero; 
  }
  else
  {
    fo[2] = zero; 
    fo[3] = zero; 
    fo[4] = chi1; 
    fo[5] = chi0; 
  }
  return; 
}
__device__ void VVV1_0(const cxtype V1[], const cxtype V2[], const cxtype V3[],
    const cxtype COUP, cxtype * vertex)
{
  cxtype cI = cxtype(0., 1.); 
  fptype P1[4]; 
  fptype P2[4]; 
  fptype P3[4]; 
  cxtype TMP0; 
  cxtype TMP1; 
  cxtype TMP2; 
  cxtype TMP3; 
  cxtype TMP4; 
  cxtype TMP5; 
  cxtype TMP6; 
  cxtype TMP7; 
  cxtype TMP8; 
  P1[0] = V1[0].real(); 
  P1[1] = V1[1].real(); 
  P1[2] = V1[1].imag(); 
  P1[3] = V1[0].imag(); 
  P2[0] = V2[0].real(); 
  P2[1] = V2[1].real(); 
  P2[2] = V2[1].imag(); 
  P2[3] = V2[0].imag(); 
  P3[0] = V3[0].real(); 
  P3[1] = V3[1].real(); 
  P3[2] = V3[1].imag(); 
  P3[3] = V3[0].imag(); 
  TMP3 = (V3[2] * V1[2] - V3[3] * V1[3] - V3[4] * V1[4] - V3[5] * V1[5]); 
  TMP0 = (V3[2] * P1[0] - V3[3] * P1[1] - V3[4] * P1[2] - V3[5] * P1[3]); 
  TMP4 = (P1[0] * V2[2] - P1[1] * V2[3] - P1[2] * V2[4] - P1[3] * V2[5]); 
  TMP2 = (V3[2] * P2[0] - V3[3] * P2[1] - V3[4] * P2[2] - V3[5] * P2[3]); 
  TMP6 = (V3[2] * V2[2] - V3[3] * V2[3] - V3[4] * V2[4] - V3[5] * V2[5]); 
  TMP1 = (V2[2] * V1[2] - V2[3] * V1[3] - V2[4] * V1[4] - V2[5] * V1[5]); 
  TMP8 = (V1[2] * P3[0] - V1[3] * P3[1] - V1[4] * P3[2] - V1[5] * P3[3]); 
  TMP7 = (V1[2] * P2[0] - V1[3] * P2[1] - V1[4] * P2[2] - V1[5] * P2[3]); 
  TMP5 = (V2[2] * P3[0] - V2[3] * P3[1] - V2[4] * P3[2] - V2[5] * P3[3]); 
  (*vertex) = COUP * (TMP1 * (-cI * (TMP0) + cI * (TMP2)) + (TMP3 * (+cI *
      (TMP4) - cI * (TMP5)) + TMP6 * (-cI * (TMP7) + cI * (TMP8))));
}


__device__ void VVV1P0_1(const cxtype V2[], const cxtype V3[], const cxtype
    COUP, const fptype M1, const fptype W1, cxtype V1[])
{
  cxtype cI = cxtype(0., 1.); 
  fptype P1[4]; 
  fptype P2[4]; 
  fptype P3[4]; 
  cxtype TMP0; 
  cxtype TMP2; 
  cxtype TMP4; 
  cxtype TMP5; 
  cxtype TMP6; 
  cxtype denom; 
  P2[0] = V2[0].real(); 
  P2[1] = V2[1].real(); 
  P2[2] = V2[1].imag(); 
  P2[3] = V2[0].imag(); 
  P3[0] = V3[0].real(); 
  P3[1] = V3[1].real(); 
  P3[2] = V3[1].imag(); 
  P3[3] = V3[0].imag(); 
  V1[0] = +V2[0] + V3[0]; 
  V1[1] = +V2[1] + V3[1]; 
  P1[0] = -V1[0].real(); 
  P1[1] = -V1[1].real(); 
  P1[2] = -V1[1].imag(); 
  P1[3] = -V1[0].imag(); 
  TMP0 = (V3[2] * P1[0] - V3[3] * P1[1] - V3[4] * P1[2] - V3[5] * P1[3]); 
  TMP4 = (P1[0] * V2[2] - P1[1] * V2[3] - P1[2] * V2[4] - P1[3] * V2[5]); 
  TMP2 = (V3[2] * P2[0] - V3[3] * P2[1] - V3[4] * P2[2] - V3[5] * P2[3]); 
  TMP6 = (V3[2] * V2[2] - V3[3] * V2[3] - V3[4] * V2[4] - V3[5] * V2[5]); 
  TMP5 = (V2[2] * P3[0] - V2[3] * P3[1] - V2[4] * P3[2] - V2[5] * P3[3]); 
  denom = COUP/((P1[0] * P1[0]) - (P1[1] * P1[1]) - (P1[2] * P1[2]) - (P1[3] *
      P1[3]) - M1 * (M1 - cI * W1));
  V1[2] = denom * (TMP6 * (-cI * (P2[0]) + cI * (P3[0])) + (V2[2] * (-cI *
      (TMP0) + cI * (TMP2)) + V3[2] * (+cI * (TMP4) - cI * (TMP5))));
  V1[3] = denom * (TMP6 * (-cI * (P2[1]) + cI * (P3[1])) + (V2[3] * (-cI *
      (TMP0) + cI * (TMP2)) + V3[3] * (+cI * (TMP4) - cI * (TMP5))));
  V1[4] = denom * (TMP6 * (-cI * (P2[2]) + cI * (P3[2])) + (V2[4] * (-cI *
      (TMP0) + cI * (TMP2)) + V3[4] * (+cI * (TMP4) - cI * (TMP5))));
  V1[5] = denom * (TMP6 * (-cI * (P2[3]) + cI * (P3[3])) + (V2[5] * (-cI *
      (TMP0) + cI * (TMP2)) + V3[5] * (+cI * (TMP4) - cI * (TMP5))));
}


__device__ void VVVV1_0(const cxtype V1[], const cxtype V2[], const cxtype
    V3[], const cxtype V4[], const cxtype COUP, cxtype * vertex)
{
  cxtype cI = cxtype(0., 1.); 
  cxtype TMP10; 
  cxtype TMP3; 
  cxtype TMP6; 
  cxtype TMP9; 
  TMP3 = (V3[2] * V1[2] - V3[3] * V1[3] - V3[4] * V1[4] - V3[5] * V1[5]); 
  TMP6 = (V3[2] * V2[2] - V3[3] * V2[3] - V3[4] * V2[4] - V3[5] * V2[5]); 
  TMP9 = (V1[2] * V4[2] - V1[3] * V4[3] - V1[4] * V4[4] - V1[5] * V4[5]); 
  TMP10 = (V2[2] * V4[2] - V2[3] * V4[3] - V2[4] * V4[4] - V2[5] * V4[5]); 
  (*vertex) = COUP * (-cI * (TMP6 * TMP9) + cI * (TMP3 * TMP10)); 
}


__device__ void VVVV1P0_1(const cxtype V2[], const cxtype V3[], const cxtype
    V4[], const cxtype COUP, const fptype M1, const fptype W1, cxtype V1[])
{
  cxtype cI = cxtype(0., 1.); 
  fptype P1[4]; 
  cxtype TMP10; 
  cxtype TMP6; 
  cxtype denom; 
  V1[0] = +V2[0] + V3[0] + V4[0]; 
  V1[1] = +V2[1] + V3[1] + V4[1]; 
  P1[0] = -V1[0].real(); 
  P1[1] = -V1[1].real(); 
  P1[2] = -V1[1].imag(); 
  P1[3] = -V1[0].imag(); 
  TMP6 = (V3[2] * V2[2] - V3[3] * V2[3] - V3[4] * V2[4] - V3[5] * V2[5]); 
  TMP10 = (V2[2] * V4[2] - V2[3] * V4[3] - V2[4] * V4[4] - V2[5] * V4[5]); 
  denom = COUP/((P1[0] * P1[0]) - (P1[1] * P1[1]) - (P1[2] * P1[2]) - (P1[3] *
      P1[3]) - M1 * (M1 - cI * W1));
  V1[2] = denom * (-cI * (TMP6 * V4[2]) + cI * (V3[2] * TMP10)); 
  V1[3] = denom * (-cI * (TMP6 * V4[3]) + cI * (V3[3] * TMP10)); 
  V1[4] = denom * (-cI * (TMP6 * V4[4]) + cI * (V3[4] * TMP10)); 
  V1[5] = denom * (-cI * (TMP6 * V4[5]) + cI * (V3[5] * TMP10)); 
}


__device__ void VVVV3_0(const cxtype V1[], const cxtype V2[], const cxtype
    V3[], const cxtype V4[], const cxtype COUP, cxtype * vertex)
{
  cxtype cI = cxtype(0., 1.); 
  cxtype TMP1; 
  cxtype TMP11; 
  cxtype TMP6; 
  cxtype TMP9; 
  TMP6 = (V3[2] * V2[2] - V3[3] * V2[3] - V3[4] * V2[4] - V3[5] * V2[5]); 
  TMP9 = (V1[2] * V4[2] - V1[3] * V4[3] - V1[4] * V4[4] - V1[5] * V4[5]); 
  TMP11 = (V3[2] * V4[2] - V3[3] * V4[3] - V3[4] * V4[4] - V3[5] * V4[5]); 
  TMP1 = (V2[2] * V1[2] - V2[3] * V1[3] - V2[4] * V1[4] - V2[5] * V1[5]); 
  (*vertex) = COUP * (-cI * (TMP6 * TMP9) + cI * (TMP1 * TMP11)); 
}


__device__ void VVVV3P0_1(const cxtype V2[], const cxtype V3[], const cxtype
    V4[], const cxtype COUP, const fptype M1, const fptype W1, cxtype V1[])
{
  cxtype cI = cxtype(0., 1.); 
  fptype P1[4]; 
  cxtype TMP11; 
  cxtype TMP6; 
  cxtype denom; 
  V1[0] = +V2[0] + V3[0] + V4[0]; 
  V1[1] = +V2[1] + V3[1] + V4[1]; 
  P1[0] = -V1[0].real(); 
  P1[1] = -V1[1].real(); 
  P1[2] = -V1[1].imag(); 
  P1[3] = -V1[0].imag(); 
  TMP6 = (V3[2] * V2[2] - V3[3] * V2[3] - V3[4] * V2[4] - V3[5] * V2[5]); 
  TMP11 = (V3[2] * V4[2] - V3[3] * V4[3] - V3[4] * V4[4] - V3[5] * V4[5]); 
  denom = COUP/((P1[0] * P1[0]) - (P1[1] * P1[1]) - (P1[2] * P1[2]) - (P1[3] *
      P1[3]) - M1 * (M1 - cI * W1));
  V1[2] = denom * (-cI * (TMP6 * V4[2]) + cI * (V2[2] * TMP11)); 
  V1[3] = denom * (-cI * (TMP6 * V4[3]) + cI * (V2[3] * TMP11)); 
  V1[4] = denom * (-cI * (TMP6 * V4[4]) + cI * (V2[4] * TMP11)); 
  V1[5] = denom * (-cI * (TMP6 * V4[5]) + cI * (V2[5] * TMP11)); 
}


__device__ void FFV1_0(const cxtype F1[], const cxtype F2[], const cxtype V3[],
    const cxtype COUP, cxtype * vertex)
{
  cxtype cI = cxtype(0., 1.); 
  cxtype TMP12; 
  TMP12 = (F1[2] * (F2[4] * (V3[2] + V3[5]) + F2[5] * (V3[3] + cI * (V3[4]))) +
      (F1[3] * (F2[4] * (V3[3] - cI * (V3[4])) + F2[5] * (V3[2] - V3[5])) +
      (F1[4] * (F2[2] * (V3[2] - V3[5]) - F2[3] * (V3[3] + cI * (V3[4]))) +
      F1[5] * (F2[2] * (-V3[3] + cI * (V3[4])) + F2[3] * (V3[2] + V3[5])))));
  (*vertex) = COUP * - cI * TMP12; 
}


__device__ void FFV1_1(const cxtype F2[], const cxtype V3[], const cxtype COUP,
    const fptype M1, const fptype W1, cxtype F1[])
{
  cxtype cI = cxtype(0., 1.); 
  fptype P1[4]; 
  cxtype denom; 
  F1[0] = +F2[0] + V3[0]; 
  F1[1] = +F2[1] + V3[1]; 
  P1[0] = -F1[0].real(); 
  P1[1] = -F1[1].real(); 
  P1[2] = -F1[1].imag(); 
  P1[3] = -F1[0].imag(); 
  denom = COUP/((P1[0] * P1[0]) - (P1[1] * P1[1]) - (P1[2] * P1[2]) - (P1[3] *
      P1[3]) - M1 * (M1 - cI * W1));
  F1[2] = denom * cI * (F2[2] * (P1[0] * (-V3[2] + V3[5]) + (P1[1] * (V3[3] -
      cI * (V3[4])) + (P1[2] * (+cI * (V3[3]) + V3[4]) + P1[3] * (-V3[2] +
      V3[5])))) + (F2[3] * (P1[0] * (V3[3] + cI * (V3[4])) + (P1[1] * (-1.) *
      (V3[2] + V3[5]) + (P1[2] * (-1.) * (+cI * (V3[2] + V3[5])) + P1[3] *
      (V3[3] + cI * (V3[4]))))) + M1 * (F2[4] * (V3[2] + V3[5]) + F2[5] *
      (V3[3] + cI * (V3[4])))));
  F1[3] = denom * (-cI) * (F2[2] * (P1[0] * (-V3[3] + cI * (V3[4])) + (P1[1] *
      (V3[2] - V3[5]) + (P1[2] * (-cI * (V3[2]) + cI * (V3[5])) + P1[3] *
      (V3[3] - cI * (V3[4]))))) + (F2[3] * (P1[0] * (V3[2] + V3[5]) + (P1[1] *
      (-1.) * (V3[3] + cI * (V3[4])) + (P1[2] * (+cI * (V3[3]) - V3[4]) - P1[3]
      * (V3[2] + V3[5])))) + M1 * (F2[4] * (-V3[3] + cI * (V3[4])) + F2[5] *
      (-V3[2] + V3[5]))));
  F1[4] = denom * (-cI) * (F2[4] * (P1[0] * (V3[2] + V3[5]) + (P1[1] * (-V3[3]
      + cI * (V3[4])) + (P1[2] * (-1.) * (+cI * (V3[3]) + V3[4]) - P1[3] *
      (V3[2] + V3[5])))) + (F2[5] * (P1[0] * (V3[3] + cI * (V3[4])) + (P1[1] *
      (-V3[2] + V3[5]) + (P1[2] * (-cI * (V3[2]) + cI * (V3[5])) - P1[3] *
      (V3[3] + cI * (V3[4]))))) + M1 * (F2[2] * (-V3[2] + V3[5]) + F2[3] *
      (V3[3] + cI * (V3[4])))));
  F1[5] = denom * cI * (F2[4] * (P1[0] * (-V3[3] + cI * (V3[4])) + (P1[1] *
      (V3[2] + V3[5]) + (P1[2] * (-1.) * (+cI * (V3[2] + V3[5])) + P1[3] *
      (-V3[3] + cI * (V3[4]))))) + (F2[5] * (P1[0] * (-V3[2] + V3[5]) + (P1[1]
      * (V3[3] + cI * (V3[4])) + (P1[2] * (-cI * (V3[3]) + V3[4]) + P1[3] *
      (-V3[2] + V3[5])))) + M1 * (F2[2] * (-V3[3] + cI * (V3[4])) + F2[3] *
      (V3[2] + V3[5]))));
}


__device__ void FFV1_2(const cxtype F1[], const cxtype V3[], const cxtype COUP,
    const fptype M2, const fptype W2, cxtype F2[])
{
  cxtype cI = cxtype(0., 1.); 
  fptype P2[4]; 
  cxtype denom; 
  F2[0] = +F1[0] + V3[0]; 
  F2[1] = +F1[1] + V3[1]; 
  P2[0] = -F2[0].real(); 
  P2[1] = -F2[1].real(); 
  P2[2] = -F2[1].imag(); 
  P2[3] = -F2[0].imag(); 
  denom = COUP/((P2[0] * P2[0]) - (P2[1] * P2[1]) - (P2[2] * P2[2]) - (P2[3] *
      P2[3]) - M2 * (M2 - cI * W2));
  F2[2] = denom * cI * (F1[2] * (P2[0] * (V3[2] + V3[5]) + (P2[1] * (-1.) *
      (V3[3] + cI * (V3[4])) + (P2[2] * (+cI * (V3[3]) - V3[4]) - P2[3] *
      (V3[2] + V3[5])))) + (F1[3] * (P2[0] * (V3[3] - cI * (V3[4])) + (P2[1] *
      (-V3[2] + V3[5]) + (P2[2] * (+cI * (V3[2]) - cI * (V3[5])) + P2[3] *
      (-V3[3] + cI * (V3[4]))))) + M2 * (F1[4] * (V3[2] - V3[5]) + F1[5] *
      (-V3[3] + cI * (V3[4])))));
  F2[3] = denom * (-cI) * (F1[2] * (P2[0] * (-1.) * (V3[3] + cI * (V3[4])) +
      (P2[1] * (V3[2] + V3[5]) + (P2[2] * (+cI * (V3[2] + V3[5])) - P2[3] *
      (V3[3] + cI * (V3[4]))))) + (F1[3] * (P2[0] * (-V3[2] + V3[5]) + (P2[1] *
      (V3[3] - cI * (V3[4])) + (P2[2] * (+cI * (V3[3]) + V3[4]) + P2[3] *
      (-V3[2] + V3[5])))) + M2 * (F1[4] * (V3[3] + cI * (V3[4])) - F1[5] *
      (V3[2] + V3[5]))));
  F2[4] = denom * (-cI) * (F1[4] * (P2[0] * (-V3[2] + V3[5]) + (P2[1] * (V3[3]
      + cI * (V3[4])) + (P2[2] * (-cI * (V3[3]) + V3[4]) + P2[3] * (-V3[2] +
      V3[5])))) + (F1[5] * (P2[0] * (V3[3] - cI * (V3[4])) + (P2[1] * (-1.) *
      (V3[2] + V3[5]) + (P2[2] * (+cI * (V3[2] + V3[5])) + P2[3] * (V3[3] - cI
      * (V3[4]))))) + M2 * (F1[2] * (-1.) * (V3[2] + V3[5]) + F1[3] * (-V3[3] +
      cI * (V3[4])))));
  F2[5] = denom * cI * (F1[4] * (P2[0] * (-1.) * (V3[3] + cI * (V3[4])) +
      (P2[1] * (V3[2] - V3[5]) + (P2[2] * (+cI * (V3[2]) - cI * (V3[5])) +
      P2[3] * (V3[3] + cI * (V3[4]))))) + (F1[5] * (P2[0] * (V3[2] + V3[5]) +
      (P2[1] * (-V3[3] + cI * (V3[4])) + (P2[2] * (-1.) * (+cI * (V3[3]) +
      V3[4]) - P2[3] * (V3[2] + V3[5])))) + M2 * (F1[2] * (V3[3] + cI *
      (V3[4])) + F1[3] * (V3[2] - V3[5]))));
}


__device__ void FFV1P0_3(const cxtype F1[], const cxtype F2[], const cxtype
    COUP, const fptype M3, const fptype W3, cxtype V3[])
{
  cxtype cI = cxtype(0., 1.); 
  fptype P3[4]; 
  cxtype denom; 
  V3[0] = +F1[0] + F2[0]; 
  V3[1] = +F1[1] + F2[1]; 
  P3[0] = -V3[0].real(); 
  P3[1] = -V3[1].real(); 
  P3[2] = -V3[1].imag(); 
  P3[3] = -V3[0].imag(); 
  denom = COUP/((P3[0] * P3[0]) - (P3[1] * P3[1]) - (P3[2] * P3[2]) - (P3[3] *
      P3[3]) - M3 * (M3 - cI * W3));
  V3[2] = denom * (-cI) * (F1[2] * F2[4] + F1[3] * F2[5] + F1[4] * F2[2] +
      F1[5] * F2[3]);
  V3[3] = denom * (-cI) * (-F1[2] * F2[5] - F1[3] * F2[4] + F1[4] * F2[3] +
      F1[5] * F2[2]);
  V3[4] = denom * (-cI) * (-cI * (F1[2] * F2[5] + F1[5] * F2[2]) + cI * (F1[3]
      * F2[4] + F1[4] * F2[3]));
  V3[5] = denom * (-cI) * (-F1[2] * F2[4] - F1[5] * F2[3] + F1[3] * F2[5] +
      F1[4] * F2[2]);
}


__device__ void VVVV4_0(const cxtype V1[], const cxtype V2[], const cxtype
    V3[], const cxtype V4[], const cxtype COUP, cxtype * vertex)
{
  cxtype cI = cxtype(0., 1.); 
  cxtype TMP1; 
  cxtype TMP10; 
  cxtype TMP11; 
  cxtype TMP3; 
  TMP3 = (V3[2] * V1[2] - V3[3] * V1[3] - V3[4] * V1[4] - V3[5] * V1[5]); 
  TMP1 = (V2[2] * V1[2] - V2[3] * V1[3] - V2[4] * V1[4] - V2[5] * V1[5]); 
  TMP10 = (V2[2] * V4[2] - V2[3] * V4[3] - V2[4] * V4[4] - V2[5] * V4[5]); 
  TMP11 = (V3[2] * V4[2] - V3[3] * V4[3] - V3[4] * V4[4] - V3[5] * V4[5]); 
  (*vertex) = COUP * (-cI * (TMP3 * TMP10) + cI * (TMP1 * TMP11)); 
}


__device__ void VVVV4P0_1(const cxtype V2[], const cxtype V3[], const cxtype
    V4[], const cxtype COUP, const fptype M1, const fptype W1, cxtype V1[])
{
  cxtype cI = cxtype(0., 1.); 
  fptype P1[4]; 
  cxtype TMP10; 
  cxtype TMP11; 
  cxtype denom; 
  V1[0] = +V2[0] + V3[0] + V4[0]; 
  V1[1] = +V2[1] + V3[1] + V4[1]; 
  P1[0] = -V1[0].real(); 
  P1[1] = -V1[1].real(); 
  P1[2] = -V1[1].imag(); 
  P1[3] = -V1[0].imag(); 
  TMP10 = (V2[2] * V4[2] - V2[3] * V4[3] - V2[4] * V4[4] - V2[5] * V4[5]); 
  TMP11 = (V3[2] * V4[2] - V3[3] * V4[3] - V3[4] * V4[4] - V3[5] * V4[5]); 
  denom = COUP/((P1[0] * P1[0]) - (P1[1] * P1[1]) - (P1[2] * P1[2]) - (P1[3] *
      P1[3]) - M1 * (M1 - cI * W1));
  V1[2] = denom * (-cI * (V3[2] * TMP10) + cI * (V2[2] * TMP11)); 
  V1[3] = denom * (-cI * (V3[3] * TMP10) + cI * (V2[3] * TMP11)); 
  V1[4] = denom * (-cI * (V3[4] * TMP10) + cI * (V2[4] * TMP11)); 
  V1[5] = denom * (-cI * (V3[5] * TMP10) + cI * (V2[5] * TMP11)); 
}



}  // end namespace $(namespace)s_sm


