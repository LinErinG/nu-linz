;
; This code is for checking the unphysical grades to estimate pileup contribution.
; Warning: this one is less of a point-to-point script and more of a lab book...
;

	tr = '2015-sep-01 '+['0358','0403']
	data_dir = '~/data/nustar/20150901/'
  check_grades_sept1flare, maindir=data_dir, tr=tr

	; "stop" is so that we can stop within the routine and probe for more info.

;
; Here's the output:
; 

  IDL>   check_grades_sept1flare, maindir=data_dir, tr=tr, /stop
	MRDFITS: Binary table.  39 columns by  429825 rows.

	Whole EVT file: 
          837303 evts GRADE 0
            3341 evts GRADES 21-24

	Within time range 
 	1-Sep-2015 03:58:00.000  1-Sep-2015 04:03:00.000
          103004 evts GRADE 0
             435 evts GRADES 21-24

	Not marked bad event (evt.pi ne -10): 
          103004 evts GRADE 0
              26 evts GRADES 21-24
               
;
; The same for FPMB
;

check_grades_sept1flare, maindir=data_dir, tr=tr, /b
               
Whole EVT file: 
          794471 evts GRADE 0
            3138 evts GRADES 21-24

Within time range 
 1-Sep-2015 03:58:00.000  1-Sep-2015 04:03:00.000
           98507 evts GRADE 0
             388 evts GRADES 21-24

Not marked bad event (evt.pi ne -10): 
           98507 evts GRADE 0
              56 evts GRADES 21-24


; Note: for just interval 0359-4000 the last # is 5 for FPMA and 10 for FPMB.
; So basically it scales by time, not by rate.  Prob. just bad pixels.

; It can be useful to rerun the above with a STOP set in order to dig around.
check_grades_sept1flare, maindir=data_dir, tr=tr, /stop
evt = evt[ind]
en = 1.6+0.04*evt.pi
print, en
hist = hist_2d( evt.rawX, evt.rawY )
histmap = make_map( hist, xc=15, yc=12 )
plot_map, histmap, /cbar
; 11 of these are at the detector edge -- probably bad pixels.  The other 15 are scattered, but some double hits.

; Here's the list for FPMA, in case we want to flag these as bad pix.
IDL> print, transpose([[evt.rawx],[evt.rawy]])
  30  21
  30  16
   7   3
   7   3
   1   9
   5  10
   5   6
   2   6
   4   8
  30  15
  30  19
   2  14
  30  24
  30  20
  14   5
  30  19
  29  19
   2   1
  30  23
   5  17
  16   2
   4  11
   2   6
  14   5
  30  18
  30  15


;
; Repeat for FPMB:
;

IDL> print, transpose([[evt.rawx],[evt.rawy]])
   1   7
   7   3
   1  10
  30  17
   1   7
  30  23
   3   7
   7   2
   3   9
   6   2
  30  15
   2   5
   7   1
  11   1
   7   2
  30  19
   6   6
   8   2
   1  14
   1   8
   3  12
  30  30
   1  14
  30  19
   8   2
  30  19
   2   7
  30  17
   7   6
   3  14
   0  13
   7   2
  11   1
   7   2
  14  29
  30  18
  30  17
   7   2
   3  14
   7   6
   2  10
   8   2
  30  28
   2   7
   3   6
   8   2
   3  12
   7   2
   6   6
   2  10
   1  10
   7   3
  30  28
  30  28
  30  17
  30  16



; Make an image of just the unphysical grades (GRDID=2) in solar coords.
tra = '2015-sep-01 '+['0358','0403']
make_map_nustar, '20102002001', maindir=data_dir, shift=shift, erang=1.5, grdid=2, /xflip, /major_chu, tr=tra, /no_live
f=file_search('out_files/map*live*')
print,f                             
fits2map,f,m                                                                                      
plot_map,m[0],/limb,/cbar                                                                         
print, total(m[0].data), total(m[1].data)



;
; This code is for calculating pileup probabilities.
;

; First, try it just for the 1-minute impulsive phase.
tra = '2015-sep-01 '+['0359','0400']
make_map_nustar, '20102002001', maindir=data_dir, shift=shift, erang=1.5, grdid=1, /xflip, /major_chu, tr=tra
fits2map,file_search('out_files/map_CHU12_GRD1_EG1_FPM*_03:59:00_04:00:00.fits'),m

; For each FPM, cut out a box around the flare region.
subA = make_submap( m[0], cen=[932,-193], fov=0.5 )
subB = make_submap( m[1], cen=[930,-183], fov=0.5 )

; First, be conservative.  Take max counts in a 2.45" square pixel, scale it to a 12" pix,
; and calculate the expected pileup rate.  This is conservative because the rate varies 
; across the 12" pix.
IDL> print, max(subA.data), max(subB.data)
       21.265718       28.257820
; This should be livetime-corrected counts per second per 2.45" pixel.

; Scale this max to a 12" pixel by multiplying by 25.
max = [max(subA.data), max(subB.data)]*25.		; cps per 12" pixel
tau = 8.e-6		; approx pileup window
p = (1-exp(-tau*max))			; probability of pileup occurring in a 12" pix
pileup_rate = p*max				; expected number of piled up cps in a 12" pix
IDL> print, pileup_rate
       2.2563521       3.9812611

; Result: this rate is untenable -- we would certainly see that in the unphysical grades.
; Try a less conservative approach.

total = [total(subA.data), total(subB.data)]		; total cps in the 1 arcmin region
p = 1 - exp(-tau*total*0.075/9.)
print, total, p, total*p*60.
       1488.6003       1563.5994
   4.9618779e-05   5.2118622e-05
       4.4317516       4.8895587
; So expect 4-5 counts piled up in a pixel in 60 sec if use Brian's formula with the 
; measured, livetime-corrected rate integrated over 30" surrounding centroid.

; rebin to 12" pix.
dataA = rebin( subA.data, [5,5] )
dataB = rebin( subB.data, [5,5] )
dataA *= total(subA.data)/total(dataA)
dataB *= total(subB.data)/total(dataB)


mapA = make_map( dataA )
mapB = make_map( dataB )
;mapA.data = 60.*mapA.data*(1-exp(-tau*mapA.data*0.075/9.))		; Expected counts over 60 sec
;mapB.data = 60.*mapB.data*(1-exp(-tau*mapB.data*0.075/9.))

plot_map, mapA, /cbar
; max expected piled up counts in 60 sec is 0.029 for A and 0.059 for B
; the max counts per pixels were 120. and 171. for A and B.
; Expect negligible pileup if just take the measured, livetime-corrected rate in the
; brightest pixel.
