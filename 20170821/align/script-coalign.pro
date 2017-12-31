;
; Sample script for coaligning AIA and NuSTAR data.
;

; Grab the reference data set.
; Here, I'm using a set of AIA Fe-XVII maps that I've already computed.
restore, '~/nustar/20170821/context/fe18.sav', /v

; Get the NuSTAR maps (already computed).
restore, '~/nustar/20170821/quicklook/raw_15sec_all_energies.sav', /v
; For my sets, I combine two OBSIDs into one sequence for each FPM.
mapA_raw=[map1A_raw,map2A_raw]
mapB_raw=[map1B_raw,map2B_raw]

; Smooth the NuSTAR data.  I like Gaussian smoothing.  We want to smooth over a FWHM of 
; ~17 arcsec (~7 pixels), so I set the Gaussian sigma to 7 pixels / 2.35 to convert from 
; FWHM to sigma.
mapA = mapA_raw
mapB = mapB_raw
for i=0, n_elements(mapA_raw)-1 do mapA[i].data = gauss_smooth(mapA_raw[i].data, 7/2.35 )
for i=0, n_elements(mapB_raw)-1 do mapB[i].data = gauss_smooth(mapB_raw[i].data, 7/2.35 )
mapA.id = 'FPMA'
mapB.id = 'FPMB'

;
; There are two steps -- coalign the FPMs to the reference data set, and coalign each 
; FPM map array to itself assuming little change between frames.  The steps are 
; independent, so order doesn't matter.  Here I align to the reference set (Fe XVIII first.)
;

shiftA = coalign_maps( dmap[127], mapa[23] )
shiftB = coalign_maps( dmap[127], mapb[23] )
avgX = mean( [shiftA[0],shiftB[0]] )
avgY = mean( [shiftA[1],shiftB[1]] )

; For my set, the best cross correlation so far seemed to be around time 18:55:38.
; Those offsets are:
IDL> print, coalign_maps( dmap[127], mapa[23] )
       43.798578       5.6082326
IDL> print, coalign_maps( dmap[127], mapb[23] )
       40.432783      -2.8107176

; It's debatable at this point whether applying the individual (A or B) offsets or 
; taking the average of the two sets is better.  Following code gives both options.
shiftedA = shift_map( mapa, shiftA[0], shiftA[1] )
shiftedB = shift_map( mapb, shiftB[0], shiftB[1] )
;shiftedA = shift_map( mapa, avgx, avgy )
;shiftedB = shift_map( mapb, avgx, avgy )

; AT THIS POINT WE HAVE STATIC OFFSETS FOR FPMA AND FPMB THAT CAN COALIGN INDEX 23
; WITH AIA.  To look at the results, use the following:
!p.multi=[0,2,1]
plot_map, fe18[127], /log
plot_map, shiftedA[23], lev=[5,10,30,50,70,90]/100.*max(shiftedA.data), /over
plot_map, fe18[127], /log
plot_map, shiftedB[23], lev=[5,10,30,50,70,90]/100.*max(shiftedB.data), /over
!p.multi=0

; Now look at the correlation of the FPMs with their sequential data.
; Remember, index 23 (18:55:38) is our reference map.  We'll do it independently of 
; the AIA reference and make this adjustment at the end, but reference everything to 
; this time.
; ALSO NOTE!  pointing is moving a lot.  We probably have smear on the 10-sec timescale.

correctionsA = fltarr( 2, n_elements(mapA) )
correctionsB = fltarr( 2, n_elements(mapB) )
for i=0, n_elements(mapA)-2 do correctionsA[*,i:i+1] += get_correl_offsets( mapA[i:i+1].data )
for i=0, n_elements(mapB)-2 do correctionsB[*,i:i+1] += get_correl_offsets( mapB[i:i+1].data )
correctionsA[0,*] *= mapA[0].dx
correctionsA[1,*] *= mapA[0].dy
correctionsB[0,*] *= mapB[0].dx
correctionsB[1,*] *= mapB[0].dy

; Those are the corrections between consecutive maps.  Now take the cumulative sum to 
; get the corrections from (for now) the first map.
for i=n_elements(mapA)-1, 0, -1 do correctionsA[0,i] = total(correctionsA[0,0:i])
for i=n_elements(mapA)-1, 0, -1 do correctionsA[1,i] = total(correctionsA[1,0:i])
for i=n_elements(mapB)-1, 0, -1 do correctionsB[0,i] = total(correctionsB[0,0:i])
for i=n_elements(mapB)-1, 0, -1 do correctionsB[1,i] = total(correctionsB[1,0:i])

; Now index everything to our reference map (map 23 at 18:55:38 UT)
refA = correctionsA[*,23]
refB = correctionsB[*,23]
for i=0, n_elements(mapA)-1 do correctionsA[*,i] -= refA
for i=0, n_elements(mapB)-1 do correctionsB[*,i] -= refB

; To look at the results, apply the alignment to the maps.
selfcorA = mapA
selfcorB = mapB
for i=0, n_elements(mapA)-1 do selfcorA[i] = shift_map( mapA[i], correctionsA[0,i], correctionsA[1,i] )
for i=0, n_elements(mapB)-1 do selfcorB[i] = shift_map( mapB[i], correctionsB[0,i], correctionsB[1,i] )
movie_map, selfcorB, cen=[250,50], fov=12

; Save the corrections for future use.
correctionsA[0,*] += shiftA[0]
correctionsA[1,*] += shiftA[1]
correctionsB[0,*] += shiftB[0]
correctionsB[1,*] += shiftB[1]
; Use the time that is the MIDPOINT of the duration.  (Note the maps by default 
; give the START TIME of the duration.)
time = anytim(mapA.time) + 0.5*mapA.dur
corr={time:anytim( TIME, /YO ), corrA: correctionsA, corrB: correctionsB}
!p.multi=[0,2,1]
hsi_linecolors
utplot,  corr.time, corr.corrA[0,*], col=6, ytitle='X shift to correct [arcsec]'
outplot, corr.time, corr.corrB[0,*], col=7
al_legend, ['FPMA','FPMB'], textcol=[6,7], box=0, /right
utplot,  corr.time, corr.corrA[1,*], col=6, ytitle='Y shift to correct [arcsec]'
outplot, corr.time, corr.corrB[1,*], col=7
al_legend, ['FPMA','FPMB'], textcol=[6,7], box=0, /right
!p.multi=0
save, corr, file='corrections_self_fe18_1855.sav'

;
; That's it!  Now apply BOTH adjustments together to get pointing-corrected maps.
; 

restore, 'corrections_self_fe18_1855.sav'

alignedA = mapA
alignedB = mapB
for i=0, n_elements(mapA)-1 do alignedA[i] = shift_map( mapA[i], corr.corrA[0,i], corr.corrA[1,i] )
for i=0, n_elements(mapB)-1 do alignedB[i] = shift_map( mapB[i], corr.corrB[0,i], corr.corrB[1,i] )

;;; debugging
restore, 'corrections_self_fe18_1855.sav'
alignedA = mapA_raw
alignedB = mapB_raw
for i=0, n_elements(mapA)-1 do alignedA[i] = shift_map( mapA_raw[i], corr.corrA[0,i], corr.corrA[1,i] )
for i=0, n_elements(mapB)-1 do alignedB[i] = shift_map( mapB_raw[i], corr.corrB[0,i], corr.corrB[1,i] )
movie_map, alignedA, cen=alignedA[0], fov=8
;;; end debugging


; NOTE!!!
; The A and B corrections are NOT the same at the moment.  They differ by ~20 arcsec
; between 1930 and 1940 UT.  This is not possible and should be investigated further.
; ADDITIONAL NOTE: Don't trust anything after the eclipse starts (in the 1940s).

;
; At this point, we can also deconvolve the images if desired.
; For a large data set, this takes awhile, especially if many iterations are used.
; For 240 images in each A and B and 20 iterations each, it took >20 min on my laptop.
;

deconvA = nustar_deconv( alignedA, 10, fpm='a' )
deconvB = nustar_deconv( alignedB, 10, fpm='b' )
save, deconvA, deconvB, file='deconvolved_and_aligned.sav'

; routine doesn't conserve flux (should fix this)
deconvA.data = deconvA.data/max(deconvA.data)*max(alignedA.data)
deconvB.data = deconvB.data/max(deconvB.data)*max(alignedB.data)

movie_map, fe18[90:290], /log, cen=[280,50], fov=5.5, cmap=deconvA, lev=[2,5,10,30,50,70,90]/100.*max(deconvA.data)

map=alignedA
map.data = alignedA.data + alignedB.data
movie_map, fe18[90:290], /log, cen=[280,50], fov=5.5, cmap=map, lev=[2,5,10,30,50,70,90]/100.*max(map.data)

loadct, 1
reverse_ct
mpeg_movie_map_double, fe18[90:282], fe18[90:290], 'fe18_overlay_deconv', $
	cen=[280,50], fov=5.5, cmap1=alignedB, cmap2=deconvB, $
	lev=[3,5,10,30,50,70,90]/100.*max(alignedB.data), dmax1=max(fe18[90].data), dmax2=max(fe18[90].data), $
	dmin1=min(fe18[90].data), dmin2=min(fe18[90].data)

; Now do some AIA movies with overlaid NuSTAR maps.

filter_loops, aia, filt, wave=1600, dir='~/data/aia/20170821/cutout/', cen=[280,50], fov=5.5, imax=100, integ=3

mpeg_movie_map_double, aia, filt, 'loops_1600A', /nodate, $
	dmin1=max(aia[0].data)*0.005, dmin2=min(filt[0].data), dmax1=max(aia[0].data), dmax2=max(filt[0].data), $
	cmap1=deconvb, lev=[3,5,10,30,50,70,90]/100.*max(deconvb.data)

	
