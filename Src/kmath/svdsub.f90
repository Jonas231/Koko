! Copyright (C) 2020 The Koko Project Developers
!
! See the file COPYRIGHT.md in the top-level directory of this
! distribution
!
! This file is part of Koko.
!
! Koko is free software: you can redistribute it and/or modify it
! under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! Koko is distributed in the hope that it will be useful, but
! WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with Koko; see the file COPYING.  If not, see
! <https://www.gnu.org/licenses/>.

MODULE svdsub

  ! Emulates or replaces the Singular Value Decomposition related
  ! subroutines from "Numerical Recipes" used in KDP-2 using open-source
  ! subroutines.
  !
  ! Ulf Griesmann, May 2020
  
  USE svd

  IMPLICIT NONE

CONTAINS

  SUBROUTINE svdcmp(AU, m, n, mp, np, W, V)

    ! Emulates the "Numerical Recipes 2nd Ed." singular value
    ! decomposition of a matrix A, including the awful distinction
    ! between logical and physical sizes of input matrix A, made necessary
    ! by the folly of returning matrix U, which can have a different shape
    ! from input matrix A (!), in the argument A.
    !
    !     A = U * diag(W) * V'
    !
    ! INPUT
    ! AU   : on input, system m x n matrix A
    ! m,n  : rows, columns of data in matrix A
    ! mp,np: rows, columns of storate allocated for A and U. Must be
    !        sufficient to hold output matrix U
    !
    ! OUTPUT
    ! AU :   on output, the m x m matrix U
    ! W  :   vector representing a diagonal matrix with singular values
    ! V  :   n x n matrix V (not the transpose V' !)

    INTEGER,   INTENT(in)    :: m, n, mp, np
    REAL (dp), INTENT(inout) :: AU(mp,np)
    REAL (dp), INTENT(out)   :: W(np), V(np,np)

    INTEGER                :: info   ! will ignore because TMI
    REAL (dp), ALLOCATABLE :: xx(:,:), uu(:,:), vv(:,:), ss(:), ee(:)

    ! allocate arguments for SVD subroutine
    ALLOCATE( xx(m,n) )  ! holds A
    ALLOCATE( uu(m,m) )  ! holds U
    ALLOCATE( vv(n,n) )  ! holds V
    ALLOCATE( ss(m) )    ! holds W/S
    ALLOCATE( ee(n) )    ! error info - will be ignored

    ! copy input arguments
    xx = AU(1:m,1:n)
    
    ! compute SVD (returns V')
    CALL dsvdc(xx, m, n, ss, ee, uu, vv, 11, info)

    ! copy results to output arguments
    AU(1:m,1:m) = uu
    W(1:n) = ss(1:n)
    V(1:n,1:n) = TRANSPOSE(vv) ! svdcmp returns V
    
  END SUBROUTINE svdcmp

  
  ! subroutine svdcmpa
  !
  ! In Koko this subroutine is replaced by a call to the generic
  ! subroutine svdcmp. In the original KDP-2 code, the subroutine is
  ! called as follows:
  !
  !  CALL SVDCMPA(W,V,VN,BTB)
  !
  ! where V(VN,VN), W(VN), and BTB(VN,VN).
  ! Two additional parameters are passed through a common block:
  ! COMMON /SVD1/ SM,SSN
  ! SM :  number of (logical) data rows in BTB
  ! SSN : number of (logical) data columns in BTB
  !
  ! The call to svdcmpa is replaced by a call to svdcmp with the following argument
  ! substitutions:
  !   AU --> BTB
  !   m  --> SM
  !   n  --> SSN
  !   mp --> VN
  !   np --> VN
  !   W  --> W
  !   V  --> V
  !
  ! call svdcmp(AU, SM, SSN, VN, VN, W, V)
  

  SUBROUTINE svdcmpb(AU, W, V, nn)

    ! A simplified version of svdcmp that computes the SVD of a
    ! sqare matrix A.
    !
    ! INPUT
    ! AU  : on input, a square system matrix A
    ! nn  : size of square matrix A
    !
    ! OUTPUT
    ! AU :   the nn x nn matrix U
    ! W  :   vector representing a diagonal matrix with singular values
    ! V  :   nn x nn matrix V (not the transpose V' !)

    INTEGER,   INTENT(in)    :: nn
    REAL (dp), INTENT(inout) :: AU(nn,nn)
    REAL (dp), INTENT(out)   :: W(nn), V(nn,nn)

    INTEGER                  :: info ! will be ignored
    REAL (dp), ALLOCATABLE   :: xx(:,:), ee(:)

    ! allocate arguments for SVD subroutine
    ALLOCATE( xx(nn,nn) )  ! holds input matrix
    ALLOCATE( ee(nn) )     ! error info, not needed - will be ignored

    ! copy input argument
    xx = AU
    
    ! compute SVD (returns V')
    CALL dsvdc(xx, nn, nn, W, ee, AU, V, 11, info)
    V = TRANSPOSE(V)

  END SUBROUTINE svdcmpb


  SUBROUTINE svbksb(U, W, V, m, n, mp, np, b, x)

    ! Emulates the "Numerical Recipes" subroutine 'svbksb',
    ! warts and all, to solve a linear system of equations
    !
    !   A * x = b
    !
    ! using a singular value decomposition of matrix A.
    !
    ! INPUT
    ! U,W,V : a singular value decomposition of matrix A
    ! m,n :   size of data in matrix A
    ! mp,np : storage size of matrix A
    ! b :     column vector of length m
    !
    ! OUTPUT
    ! x :     solution as a column vector of length m

    INTEGER,   INTENT(in)  :: m, n, mp, np
    REAL (dp), INTENT(in)  :: U(mp,mp), W(np), V(np,np), b(mp)
    REAL (dp), INTENT(out) :: x(m)

    ! temporary matrices
    REAL (dp), ALLOCATABLE :: uu(:,:), ww(:), vv(:,:), bb(:)
    ALLOCATE( uu(m,n) )
    ALLOCATE( ww(n) )
    ALLOCATE( vv(n,n) )
    ALLOCATE( bb(m) )

    ! copy "logical" parts of input matrices
    uu(1:m,1:n) = U(1:m,1:n)
    ww(1:n) = W(1:n)
    vv(1:n,1:n) = V(1:n,1:n)
    bb(1:m) = b(1:m)

    CALL dsvd_solve(m, n, uu, ww, vv, bb, x)

  END SUBROUTINE svbksb


  ! subroutine svbksba
  !
  ! In Koko, subroutine svbksba is replaced by a call to the generic
  ! subroutine svbksb. In the original KDP-2 code the subroutine is
  ! called as follows:
  !
  ! CALL SVBKSBA(W,V,VN,VN1,BTB,BTG)
  !
  ! where W(VN), V(VN,VN), BTB(VN1,VN1), and BTG(VN1).
  ! Two additional parameters are passed through a common block:
  ! COMMON /SVD1/ SM,SSN
  ! SM :  number of (logical) data rows in BTB
  ! SSN : number of (logical) data columns in BTB
  ! The solution is returned through a second common block
  ! COMMON /SVD2/ X
  !
  ! The call to svbksba is replaced by a call to svbksb with the following argument
  ! substitutions:
  !   U  --> BTB
  !   W  --> W
  !   V  --> V
  !   m  --> SM
  !   n  --> SSN
  !   mp --> VN1
  !   np --> VN
  !   b  --> BTG
  !   x  --> X
  !
  ! call svbksb(BTB, W, V, SM, SSN, VN1, VN, BTG, X)
  

  SUBROUTINE svbksbb(U, W, V, nn, b, x)

    ! A simplified version of subroutine 'svbksb' for square system
    ! matrices A to solve a linear system of equations
    !
    !   A * x = b
    !
    ! using a singular value decomposition of matrix A.
    !
    ! INPUT
    ! U,W,V : a singular value decomposition of square matrix A
    ! nn :    size of matrices A, U, V, and length of W
    ! b :     column vector of length nn
    !
    ! OUTPUT
    ! x :     solution as a column vector of length nn
    !
    ! NOTE: in KDP-2, the solution 'x' is returned through a common
    ! block SVD2 containing a single variable. The common block is
    ! replaced here by the output variable 'x'.

    INTEGER,   INTENT(in)  :: nn
    REAL (dp), INTENT(in)  :: U(nn,nn), W(nn), V(nn,nn), b(nn)
    REAL (dp), INTENT(out) :: x(nn)

    CALL dsvd_solve(nn, nn, U, W, V, b, x)
    
  END SUBROUTINE svbksbb
  
END MODULE svdsub
