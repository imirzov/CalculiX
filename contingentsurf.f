!     
!     CalculiX - A 3-dimensional finite element program
!     Copyright (C) 1998-2021 Guido Dhondt
!     
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation(version 2);
!     
!     
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of 
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
!     GNU General Public License for more details.
!     
!     You should have received a copy of the GNU General Public License
!     along with this program; if not, write to the Free Software
!     Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
!     
      subroutine contingentsurf(ncrack,xplanecrack,istartcrackbou,
     &     iendcrackbou,costruc,cg,coproj,crackarea,nnfront,
     &     isubsurffront,istartcrackfro,iendcrackfro,istartfront,
     &     iendfront,acrack,xa,ifrontrel,integerglob,doubleglob,
     &     nstep,surfnor,surfco,resarea,alambdapj,shape,xt,surftan)
!     
!     determine the increase of the K-factors due to the vicinity
!     of contingent free surfaces
!     
      implicit none
!
      character*4 outlabel
      character*8 filename
      character*9 filelabel
!     
      integer i,j,k,l,m,ncrack,istartcrackbou(*),iendcrackbou(*),loopa,
     &     nnfront,istart,iend,isubsurffront(*),isf,icrack,konl(20),
     &     istartcrackfro(*),iendcrackfro(*),istartfront(*),nummin,
     &     iendfront(*),jrel,ifrontrel(*),integerglob(*),nterms,
     &     nstep,nselect,nktet,nkon,nfield,nfaces,netet,nelem,ne,
     &     istartset(1),iselect(6),imastset,iendset(1),ialset(1),
     &     itrend,itrendprev
!     
      real*8 a(3,3),x,y,z,det,dd,xplanecrack(4,*),cg(3,*),costruc(3,*),
     &     pa,pb,pc,coproj(3,*),crackarea(*),v1(3),v2(3),al,p(3),
     &     acrack(*),xa(3,*),alambda,doubleglob(*),
     &     q(3),coords(3),value(1),ratio(20),dist,xinter(3),r(3),
     &     cosang,alambdaprev,snor(3),xinterprev(3),surfnor(3,*),
     &     resarea(*),a1,b1,c1,d1,e1,f1,surfco(3,*),alambdapj(*),
     &     xxs(3),xxt(3),amin,amax,bmin,bmax,xt(3,*),stan(3),
     &     alambdamin,xk1max,xk2max,xk3max,acr,bcr,aratio,arearatio,
     &     prod,xratio,shape(3,*),alamratio,surftan(3,*)
!     
      nktet=integerglob(1)
      netet=integerglob(2)
      ne=integerglob(3)
      nkon=integerglob(4)
      nfaces=integerglob(5)
      nfield=13
!     
      nselect=0
      imastset=0
      loopa=8
!     
!     loop over all cracks (each crack has a unique mean plane,
!     no matter how many fronts belong to the crack)
!     
      do i=1,ncrack
!     
!     setting the LHS (a; only upper triangle is used since the matrix
!     is symmetric) and the RHS (b) to zero
!     
        do k=1,3
          cg(k,i)=0.d0
          do l=k,3
            a(k,l)=0.d0
          enddo
        enddo
!     
!     loop over all nodes belonging to the boundary of the crack
!     
        do j=istartcrackbou(i),iendcrackbou(i)
!     
!     taking into account the front node
!     
          x=costruc(1,j)
          y=costruc(2,j)
          z=costruc(3,j)
          a(1,1)=a(1,1)+x*x
          a(1,2)=a(1,2)+x*y
          a(1,3)=a(1,3)+x*z
          a(2,2)=a(2,2)+y*y
          a(2,3)=a(2,3)+y*z
          a(3,3)=a(3,3)+z*z
          cg(1,i)=cg(1,i)+x
          cg(2,i)=cg(2,i)+y
          cg(3,i)=cg(3,i)+z
        enddo
!     
!     solving the system of equations (3 x 3 system)
!     
        det=a(1,1)*(a(2,2)*a(3,3)-a(2,3)*a(2,3))
     &       -a(1,2)*(a(1,2)*a(3,3)-a(1,3)*a(2,3))
     &       +a(1,3)*(a(1,2)*a(2,3)-a(1,3)*a(2,2))
        pa=cg(1,i)*(a(2,2)*a(3,3)-a(2,3)*a(2,3))
     &       -cg(2,i)*(a(1,2)*a(3,3)-a(2,3)*a(1,3))
     &       +cg(3,i)*(a(1,2)*a(2,3)-a(2,2)*a(1,3))
        pb=-cg(1,i)*(a(1,2)*a(3,3)-a(1,3)*a(2,3))
     &       +cg(2,i)*(a(1,1)*a(3,3)-a(1,3)*a(1,3))
     &       -cg(3,i)*(a(1,1)*a(2,3)-a(1,2)*a(1,3))
        pc=cg(1,i)*(a(1,2)*a(2,3)-a(1,3)*a(2,2))
     &       -cg(2,i)*(a(1,1)*a(2,3)-a(1,3)*a(1,2))
     &       +cg(3,i)*(a(1,1)*a(2,2)-a(1,2)*a(1,2))
        pa=pa/det
        pb=pb/det
        pc=pc/det
!
!       taking the mean to get the center of gravity
!
        do k=1,3
          cg(k,i)=cg(k,i)/(iendcrackbou(i)-istartcrackbou(i)+1)
        enddo
!     
!       scaling the equation of the plane such that pa*pa+pb*pb+pc*pc=1
!       and that the center of gravity belongs to the plane       
!     
        dd=dsqrt(pa*pa+pb*pb+pc*pc)
        xplanecrack(1,i)=pa/dd
        xplanecrack(2,i)=pb/dd
        xplanecrack(3,i)=pc/dd
        xplanecrack(4,i)=(pa*cg(1,i)+pb*cg(2,i)+pc*cg(3,i))/dd
!
c     write(*,*)
c     write(*,*) 'crackplane'
c     write(*,*) 'equation of the crack plane for crack ',i
c     write(*,*) xplanecrack(1,i),' * x + ',xplanecrack(2,i),
c     &         ' * y + ',xplanecrack(3,i),' * z = ',xplanecrack(4,i)
c     write(*,*)
!     
      enddo
!
!     projection of all boundary nodes onto the mean plane
!
      do i=1,ncrack
        do j=istartcrackbou(i),iendcrackbou(i)
          al=(costruc(1,j)-cg(1,i))*xplanecrack(1,i)+
     &       (costruc(2,j)-cg(2,i))*xplanecrack(2,i)+
     &       (costruc(3,j)-cg(3,i))*xplanecrack(3,i)
          do k=1,3
c            coproj(k,j)=costruc(k,j)-al*xplanecrack(k,i)
            coproj(k,j)=costruc(k,j)
          enddo
        enddo
      enddo
!
!     calculate the area of the cracks
!
      do i=1,ncrack
        crackarea(i)=0.d0
        do j=istartcrackbou(i),iendcrackbou(i)-1
          do k=1,3
            v1(k)=coproj(k,j)-cg(k,i)
            v2(k)=coproj(k,j+1)-cg(k,i)
          enddo
          crackarea(i)=crackarea(i)+
     &         dsqrt((v1(2)*v2(3)-v1(3)*v2(2))**2+
     &               (v1(3)*v2(1)-v1(1)*v2(3))**2+
     &               (v1(1)*v2(2)-v1(2)*v2(1))**2)
        enddo
        crackarea(i)=crackarea(i)/2.d0
      enddo
!
!     1) calculating the area of the remaining cross section
!     2) determining the adjacent free surfaces and the minimum
!        distance from the crack front
!
      open(14,file='set0.fbd',status='unknown')
      write(14,*) 'seto set0'
!
      do icrack=1,ncrack
!
!       determine the fronts belonging to the crack
!
        do istart=1,nnfront
          if(istartfront(istart).eq.istartcrackfro(icrack)) exit
        enddo
        do iend=1,nnfront
          if(iendfront(iend).eq.iendcrackfro(icrack)) exit
        enddo
!
        resarea(icrack)=0.d0
        nummin=0
!
!       loop over the fronts
!
        do i=istart,iend
          itrendprev=0
!
!         check whether surface or subsurface crack
!
          if(isubsurffront(i).eq.0) then
            isf=1
          else
            isf=0
          endif
!
!         loop over the internal nodes of a front
!
          do j=istartfront(i)+isf,iendfront(i)-isf
            jrel=ifrontrel(j)
!
!           project the local crack propagation direction onto
!           the crack plane and normalized
!
c            do k=1,3
c              dir(k)=costruc(k,jrel)+xa(k,j)
c            enddo
c            al=(dir(1)-cg(1,icrack))*xplanecrack(1,icrack)+
c     &         (dir(2)-cg(2,icrack))*xplanecrack(2,icrack)+
c     &         (dir(3)-cg(3,icrack))*xplanecrack(3,icrack)
c            do k=1,3
c              dirproj(k)=dir(k)-al*xplanecrack(k,icrack)-coproj(k,jrel)
c            enddo
c            dd=dsqrt(dirproj(1)**2+dirproj(2)**2+dirproj(3)**2)
c            do k=1,3
c              dirproj(k)=dirproj(k)/dd
c            enddo
!     
!           finding the intersection of a straight line through
!           the actual node on the crack front and in the direction of
!           the projected crack propagation with the free surface
!
            alambda=acrack(j)*0.1d0
            do k=1,3
              p(k)=coproj(k,jrel)
            enddo
!
            do
              do k=1,3
c                q(k)=p(k)+alambda*dirproj(k)
                q(k)=p(k)+alambda*xa(k,j)
                coords(k)=q(k)
              enddo
              call basis(doubleglob(1),doubleglob(netet+1),
     &             doubleglob(2*netet+1),doubleglob(3*netet+1),
     &             doubleglob(4*netet+1),doubleglob(5*netet+1),
     &             integerglob(6),integerglob(netet+6),
     &             integerglob(2*netet+6),doubleglob(6*netet+1),
     &             integerglob(3*netet+6),nktet,netet,
     &             doubleglob(4*nfaces+6*netet+1),nfield,
     &             doubleglob(nstep*13*nktet+4*nfaces+6*netet+1),
     &             integerglob(7*netet+6),integerglob(ne+7*netet+6),
     &             integerglob(2*ne+7*netet+6),
     &             integerglob(nkon+2*ne+7*netet+6),coords(1),
     &             coords(2),coords(3),value,ratio,iselect,
     &             nselect,istartset,iendset,ialset,imastset,
     &             integerglob(nkon+2*ne+8*netet+6),nterms,konl,
     &             nelem,loopa,dist)
              if(dist.gt.1.d-6) exit
c              alambda=2*alambda
              alambda=1.2d0*alambda
            enddo
!
            do k=1,3
              r(k)=coords(k)
            enddo
            cosang=((p(1)-q(1))*(r(1)-q(1))+
     &              (p(2)-q(2))*(r(2)-q(2))+
     &           (p(3)-q(3))*(r(3)-q(3)))/(dist*alambda)
            alambda=max(alambda-dist/cosang,1.d-10)
!
!           intersection with the free surface
!
            do k=1,3
c              xinter(k)=p(k)+alambda*dirproj(k)
              xinter(k)=p(k)+alambda*xa(k,j)
            enddo
!
!           printing lambda to standard out
!           storing intersection points to file            
!
            write(*,*) 'set0',j,alambda
            write(outlabel(1:2),'(i2)') j
            outlabel(3:4)='p '
 100        format('pnt ',a4,3(1x,e15.8))
            write(14,100) outlabel,xinter(1),xinter(2),xinter(3)
!
!           first subsurface node
!
            if(j.eq.istartfront(i)+isf) then
              itrend=-1
            else
!
!             remaining nodes: determine the area outside
!             the crack
!
              a1=dsqrt((costruc(1,jrel)-costruc(1,jrel-1))**2+
     &                 (costruc(2,jrel)-costruc(2,jrel-1))**2+
     &                 (costruc(3,jrel)-costruc(3,jrel-1))**2)
              b1=dsqrt((costruc(1,jrel)-xinter(1))**2+
     &                 (costruc(2,jrel)-xinter(2))**2+
     &                 (costruc(3,jrel)-xinter(3))**2)
              c1=dsqrt((xinter(1)-xinterprev(1))**2+
     &                 (xinter(2)-xinterprev(2))**2+
     &                 (xinter(3)-xinterprev(3))**2)
              d1=dsqrt((costruc(1,jrel-1)-xinterprev(1))**2+
     &                 (costruc(2,jrel-1)-xinterprev(2))**2+
     &                 (costruc(3,jrel-1)-xinterprev(3))**2)
              e1=dsqrt((costruc(1,jrel-1)-xinter(1))**2+
     &                 (costruc(2,jrel-1)-xinter(2))**2+
     &                 (costruc(3,jrel-1)-xinter(3))**2)
              f1=dsqrt((costruc(1,jrel)-xinterprev(1))**2+
     &                 (costruc(2,jrel)-xinterprev(2))**2+
     &             (costruc(3,jrel)-xinterprev(3))**2)
              resarea(icrack)=resarea(icrack)+0.25d0*
     &             dsqrt(4.d0*(e1*f1)**2-(b1**2+d1**2-a1**2-c1**2)**2)
              if((alambda.lt.alambdaprev).and.
     &           (dabs(alambda-alambdaprev).gt.0.01*alambdaprev)) then
                itrend=-1
              else
                itrend=1
              endif
            endif
!
!           check for minima of alambda
!            itrend/itrendprev=-1 means alambda is/was decreasing
!            itrend/itrendprev=1 means alambda is/was increasing
!
            if((itrendprev.eq.-1).and.(itrend.eq.1)) then
              if(nummin.eq.0) then
!
!               first minimum is always stored;
!               the intersection point is stored (surfco) and the normal
!               on the free surface at the intersection point (surfnor);
!               they are both located at the PREVIOUS front node (= the
!               real minimum)
!
                nummin=nummin+1
                do k=1,3
                  surfco(k,nummin)=xinterprev(k)
                  surfnor(k,nummin)=snor(k)
                  surftan(k,nummin)=stan(k)
                enddo
                write(*,*) 'contingentsurf min!:',j-1
              elseif(surfnor(1,nummin)*snor(1)+
     &               surfnor(2,nummin)*snor(2)+
     &               surfnor(3,nummin)*snor(3).lt.0.5d0) then
!
!               not first minimum: check that the free surface normal
!               does not coincide with the one from the previous minimum
!
                nummin=nummin+1
                do k=1,3
                  surfco(k,nummin)=xinterprev(k)
                  surfnor(k,nummin)=snor(k)
                  surftan(k,nummin)=stan(k)
                enddo
                write(*,*) 'contingentsurf min!:',j-1
              endif
            endif
!
!           for surface crack:
!           last subsurface front node: minimum if decreasing trend and
!           1) no other minimum was found OR
!           2) the free surface normal does not coincide with the one from
!              the previous minimum !
!
            if((j.eq.iendfront(i)-isf).and.(isf.eq.1)) then
              if(itrend.lt.0) then
                if(nummin.eq.0) then
                  nummin=nummin+1
                  do k=1,3
                    surfco(k,nummin)=xinter(k)
                    surfnor(k,nummin)=xa(k,j)
                    surftan(k,nummin)=xt(k,j)
                  enddo
                  write(*,*) 'contingentsurf min!:',j-1
                elseif(surfnor(1,nummin)*xa(1,j)+
     &                 surfnor(2,nummin)*xa(2,j)+
     &                 surfnor(3,nummin)*xa(3,j).lt.0.5d0) then
                  nummin=nummin+1
                  do k=1,3
                    surfco(k,nummin)=xinter(k)
                    surfnor(k,nummin)=xa(k,j)
                    surftan(k,nummin)=xt(k,j)
                  enddo
                  write(*,*) 'contingentsurf min!:',j-1
                endif
              endif
            endif
!
            itrendprev=itrend
            alambdaprev=alambda
            do k=1,3
              xinterprev(k)=xinter(k)
c              snor(k)=dirproj(k)
              snor(k)=xa(k,j)
              stan(k)=xt(k,j)
            enddo
!            
          enddo
        enddo
!
c        do k=1,3
c          xxn(k)=xplanecrack(k,icrack)
c        enddo
!
        write(14,*) 'setc set0'
        close(14)
!
!     loop over all minima found
!
        do m=1,nummin
          filename='set .fbd'
          write(filename(4:4),'(i1)') m
          open(14,file=filename,status='unknown')
          filelabel='seto set '
          write(filelabel(9:9),'(i1)') m
          write(14,*) filelabel
!
          alambdamin=1.d30
!
!         free surface normal for minimum m
!
          do k=1,3
            xxs(k)=surfnor(k,m)
            xxt(k)=surftan(k,m)
          enddo
c!
c!         in-plane vector orthogonal to free surface normal
c!
c          xxt(1)=xxn(2)*xxs(3)-xxn(3)*xxs(2)
c          xxt(2)=xxn(3)*xxs(1)-xxn(1)*xxs(3)
c          xxt(3)=xxn(1)*xxs(2)-xxn(2)*xxs(1)
!     
!         loop over the fronts: determine the distance from the free
!         surface in direction xxs (normal to surface at minimum)
!     
          do i=istart,iend
!     
!     loop over the internal nodes of a front
!     
            do j=istartfront(i)+isf,iendfront(i)-isf
              jrel=ifrontrel(j)
!
!***  begin alternative 2              
!
c     alambda=(surfco(1,m)-costruc(1,jrel))*xxs(1)+
c             (surfco(2,m)-costruc(2,jrel))*xxs(2)+              
c             (surfco(3,m)-costruc(3,jrel))*xxs(3)
!
!***  end alternative 2              
!
!***  begin alternative 1              
!
!             look for the intersection point of a straight line
!             through the front node at stake and in the direction              
!             of the free surface normal corresponding to minimum m
!
              alambda=acrack(j)*0.1d0
              do k=1,3
                p(k)=coproj(k,jrel)
              enddo
              do
                do k=1,3
                  q(k)=p(k)+alambda*xxs(k)
                  coords(k)=q(k)
                enddo
                call basis(doubleglob(1),doubleglob(netet+1),
     &               doubleglob(2*netet+1),doubleglob(3*netet+1),
     &               doubleglob(4*netet+1),doubleglob(5*netet+1),
     &               integerglob(6),integerglob(netet+6),
     &               integerglob(2*netet+6),doubleglob(6*netet+1),
     &               integerglob(3*netet+6),nktet,netet,
     &               doubleglob(4*nfaces+6*netet+1),nfield,
     &               doubleglob(nstep*13*nktet+4*nfaces+6*netet+1),
     &               integerglob(7*netet+6),integerglob(ne+7*netet+6),
     &               integerglob(2*ne+7*netet+6),
     &               integerglob(nkon+2*ne+7*netet+6),coords(1),
     &               coords(2),coords(3),value,ratio,iselect,
     &               nselect,istartset,iendset,ialset,imastset,
     &               integerglob(nkon+2*ne+8*netet+6),nterms,konl,
     &               nelem,loopa,dist)
                if(dist.gt.1.d-6) exit
c                alambda=2*alambda
                alambda=1.2d0*alambda
              enddo
!     
              do k=1,3
                r(k)=coords(k)
              enddo
              cosang=((p(1)-q(1))*(r(1)-q(1))+
     &             (p(2)-q(2))*(r(2)-q(2))+
     &             (p(3)-q(3))*(r(3)-q(3)))
              alambda=max(alambda-dist/cosang,1.d-10)
!
!*** end alternative 1              
!
!             alambda is the distance from the free surface in direction xxs
!
              alambdapj(j)=alambda
!
              alambdamin=min(alambdamin,alambda)
            enddo
          enddo
!
!         determine the "diameter" of the crack in direction xxs
!         and xxt
!
          bmin=1.d30
          bmax=-1.d30
          amin=1.d30
          amax=-1.d30
!     
!     loop over the internal nodes of a front
!     
          do j=istartcrackbou(icrack),iendcrackbou(icrack)
!     
!     scalar product of vector connecting the front
!     node with the center of gravity with xxs
!     
            prod=(coproj(1,j)-cg(1,icrack))*xxs(1)+
     &           (coproj(2,j)-cg(2,icrack))*xxs(2)+
     &           (coproj(3,j)-cg(3,icrack))*xxs(3)
            amin=min(amin,prod)
            amax=max(amax,prod)
!     
!     scalar product of vector connecting the front
!     node with the center of gravity with xxt
!     
            prod=(coproj(1,j)-cg(1,icrack))*xxt(1)+
     &           (coproj(2,j)-cg(2,icrack))*xxt(2)+
     &           (coproj(3,j)-cg(3,icrack))*xxt(3)
            bmin=min(bmin,prod)
            bmax=max(bmax,prod)
          enddo
!     
!         "diameter" in xxs and xxt-direction
!     
          acr=amax-amin
          bcr=bmax-bmin
!     
!         ratio expressing the relative closeness of crack to free
!         surface: if 1: very close, if 0: very far
!     
          xratio=acr/(acr+alambdamin)
!     
!         ratio of "major axes" of crack
!     
          aratio=acr/bcr
c!     
c!         area ratio for residual area: if 0: big crack, if 1: small crack
c!
c          arearatio=resarea(icrack)/(resarea(icrack)+crackarea(icrack))
!
!         limits for the ratios
!
          aratio=min(aratio,8.0d0)
          aratio=max(aratio,0.05d0)
          xratio=min(xratio,0.99d0)
          xratio=max(xratio,0.05d0)
!
!         magnification factor due to aratio (the ellipticity of the crack)
!         and xratio (the closeness to the free surface)
!         for all modes at minimum point (to do)
!
          xk1max=xk1max
          xk2max=xk2max
          xk3max=xk3max
!
!         for all other positions along the crack front the magnification
!         factor is less
!          
          do i=istart,iend
!     
!           positions at the free surface (for surface cracks)
!
            if(isf.eq.1) then
              alambdapj(istartfront(i))=alambdapj(istartfront(i)+1)
              alambdapj(iendfront(i))=alambdapj(iendfront(i)-1)
            endif
!     
!           loop over the internal nodes of a front
!     
            do j=istartfront(i),iendfront(i)
              jrel=ifrontrel(j)
              alamratio=alambdamin/alambdapj(j)
              alamratio=max(alamratio,0.d0)
              alamratio=min(alamratio,1.d0)
              shape(1,j)=shape(1,j)*((xk1max-1.d0)*alamratio+1.d0)
              shape(2,j)=shape(2,j)*((xk2max-1.d0)*alamratio+1.d0)
              shape(3,j)=shape(3,j)*((xk3max-1.d0)*alamratio+1.d0)
            enddo
!
          enddo
!     
          filelabel='setc set '
          write(filelabel(9:9),'(i1)') m
          write(14,*) filelabel
          close(14)
!     
        enddo  ! end loop over the mimima for crack "icrack"
!     
!       taking the area effect into account
!       area ratio for residual area: if 0: big crack, if 1: small crack
!     
        arearatio=resarea(icrack)/(resarea(icrack)+crackarea(icrack))
!     
        do j=istartcrackfro(icrack),iendcrackfro(icrack)
        enddo
!
      enddo ! end crack loop
!
      return
      end

