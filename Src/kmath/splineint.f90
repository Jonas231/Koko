!///////////////////////////////////////////////////////////////////////
!/
!/ Copyright (C) 2020 The Koko Project Developers
!/
!/ See the file COPYRIGHT.md in the top-level directory of this
!/ distribution
!/
!/ This file is part of Koko.
!/
!/ Koko is free software: you can redistribute it and/or modify it
!/ under the terms of the GNU General Public License as published by
!/ the Free Software Foundation, either version 3 of the License, or
!/ (at your option) any later version.
!/
!/ Koko is distributed in the hope that it will be useful, but
!/ WITHOUT ANY WARRANTY; without even the implied warranty of
!/ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!/ GNU General Public License for more details.
!/
!/ You should have received a copy of the GNU General Public License
!/ along with Koko; see the file COPYING.  If not, see
!/ <https://www.gnu.org/licenses/>.
!/
!///////////////////////////////////////////////////////////////////////

subroutine spline(x,y,n, yps,ype, ypp)

  ! A drop-in replacement for the "Numerical Recipes" subroutine
  ! 'spline'. Calculates a natural cubic spline for data
  ! interpolation. The function is an interface to the spline
  ! interpolation subroutines by J. Burkardt (see 'cubicspline.f90')
  !
  ! INPUT
  ! x,y,n :  n values y(i) at knots x(i), i = 1, ..., n that are
  !          to be interpolated
  ! yps :    first derivative at x(1)
  ! ype :    first derivative at x(end)
  !
  ! OUTPUT
  ! ypp :    second derivatives at the knots x(i)
  !
  ! Ulf Griesmann, April 2020

  implicit none

  integer, intent(in) :: n
  real (kind=8), intent(in) :: x(n), y(n), yps, ype
  real (kind=8), intent(out) :: ypp(n)
  
  integer :: ier

  ! call interpolation function
  call spline_cubic_set(n,x,y, 1,yps, 1,ype, ypp, ier)
  
  if (ier .ne. 0) then
     call splerror
  end if
  
end subroutine spline


subroutine splint(x,y,ypp,n, xi,yi)

  ! A drop-in replacement for "the Numerical Recipes" subroutine
  ! 'splint'. Evaluates a natural cubic spline at a specified abscissa.
  !
  ! INPUT
  ! x,y,n :  n values y(i) at knots x(i), i = 1, ..., n that are
  !          to be interpolated
  ! ypp :    2nd derivate at the knots x(i) (output of 'spline')
  ! xi :     location at which to evaluate the spline
  !
  ! OUTPUT
  ! yi :     value of the spline at xi
  !
  ! Ulf Griesmann, April 2020

  implicit none

  integer, intent(in) :: n
  real (kind=8), intent(in) :: x(n), y(n), ypp(n), xi
  real (kind=8), intent(out) :: yi
  real (kind=8) :: ypi, yppi

  call spline_cubic_val(n,x,y,ypp, xi,yi,ypi,yppi)
  
end subroutine splint