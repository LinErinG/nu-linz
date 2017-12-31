;
; This code is for checking the unphysical grades to estimate pileup contribution.
; Warning: this one is less of a point-to-point script and more of a lab book...
;

	tr = '2017-aug-21 '+['1850','1900']
	path = '~/data/nustar/20170821/20312001_Sol_17233_eclipse_MOS01/20312001001'
	check_grades, path, tr=tr, /b

	; "stop" is so that we can stop within the routine and probe for more info.

;
; Here's the output:
; 

	IDL>  check_grades, path, tr=tr    
	MRDFITS: Binary table.  14 columns by  631011 rows.

	Whole EVT file: 
	          545858 evts GRADE 0
	           27898 evts GRADES 21-24

	Within time range 
	21-Aug-2017 18:50:00.000 21-Aug-2017 19:00:00.000
	          170051 evts GRADE 0
	           12688 evts GRADES 21-24
	
	Not marked bad event (evt.pi ne -10): 
	          170051 evts GRADE 0
	             337 evts GRADES 21-24
               
;
; The same for FPMB
;

IDL>  check_grades, path, tr=tr, /b
MRDFITS: Binary table.  14 columns by  628985 rows.

Whole EVT file: 
          544923 evts GRADE 0
           28851 evts GRADES 21-24

Within time range 
21-Aug-2017 18:50:00.000 21-Aug-2017 19:00:00.000
          166587 evts GRADE 0
           13909 evts GRADES 21-24

Not marked bad event (evt.pi ne -10): 
          166587 evts GRADE 0
             612 evts GRADES 21-24


; Note: for just interval 0359-4000 the last # is 5 for FPMA and 10 for FPMB.
; So basically it scales by time, not by rate.  Prob. just bad pixels.

; It can be useful to rerun the above with a STOP set in order to dig around.
check_grades, path, tr=tr, /b, /stop
evt = evt[ind]
en = 1.6+0.04*evt.pi
plot, en, /psy
hist = hist_2d( evt.rawX, evt.rawY )
histmap = make_map( hist, xc=15, yc=12 )
plot_map, histmap, /cbar

;
; Here's the part that does the pileup probability maps.
;

tra = '2017-aug-21 '+['1855','1900']
cen=[260,60]

; Make the images.
data_dir1 = '~/data/nustar/20170821/20312001_Sol_17233_eclipse_MOS01/'
data_dir2 = '~/data/nustar/20170821/20312002_Sol_17233_eclipse_MOS02/'
make_pileup_maps, '20312001001', maindir=data_dir1, /xflip, tr=tra, cen=cen

fits2map,file_search('out_files/map_FPM*'),m


t0 = '2017-aug-21 1850'
nT = 13
dur = 5*60
tra = anytim(t0)+findgen(nT+1)*dur
cen=[260,60]

; Make the images.
data_dir1 = '~/data/nustar/20170821/20312001_Sol_17233_eclipse_MOS01/'
data_dir2 = '~/data/nustar/20170821/20312002_Sol_17233_eclipse_MOS02/'
.run
for i=0, nT-1 do begin
	ptim, tra[i]
	make_pileup_maps, '20312001001', maindir=data_dir1, /xflip, tr=tra[i:i+1], cen=cen
	make_pileup_maps, '20312002001', maindir=data_dir2, /xflip, tr=tra[i:i+1], cen=cen
endfor
end

fits2map,file_search('out_files/*FPMB_unphysical*'),m_grd2
fits2map,file_search('out_files/*FPMB*from_grades*'),m_grades
fits2map,file_search('out_files/*FPMB*rates*'),m_rates

mpeg_movie_map_double, m_grades[0:11], m_rates[0:11], 'movie_pileup_maps', cen=cen, fov=12, $
	dmin1=0., dmin2=0., dmax1=0.03, dmax2=0.03, /cbar, /nodate, ymarg=5









;
; From here on is old code from another event, kept in case it's useful.
;

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
