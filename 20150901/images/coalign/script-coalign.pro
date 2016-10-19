;
; Coalign the NuSTAR and AIA FeXVIII data.
;

; Note for Lindsay: Script for making AIA FeXVIII images is in CONTEXT.

; Get AIA maps and extract midpoint of time intervals.
restore, '~/nustar/20150901/context/aia/fe18.sav', /v
aia_time = fexviii.time

; For NuSTAR, use time plus/minus 6 seconds.
nu_time = anytim( anytim( aia_time ) - 6., /yo )

; Only need to do this next part once.
; If files are already there then skip it.
; NOTE!  If you don't have the NuSTAR solar software, this won't work so you'll need 
; to have the data already in hand.
data_dir = '~/data/nustar/20150901/'
obsid = '20102002001'
;for i=0, n_elements(nu_time)-2 do make_map_nustar, obsid, maindir=data_dir, $
;	grdid=1, erang=2., /xflip, /plot, /major_chu, tr=nu_time[i:i+1]

; Restore the NuSTAR images.  This reads in the image files and makes map structures.
; NuSTAR has two telescopes labeled A and B.  Variables are labaled accordingly here.
; Ideally, the two telescopes are identical but realistically, there are differences.
fA = file_search('out_files/*FPMA*')
fB = file_search('out_files/*FPMB*')
fits2map, fA, mA
fits2map, fB, mB

; Sort the images to get them in the correct time order.
mA = mA[sort(anytim(mA.time))]
mB = mB[sort(anytim(mB.time))]

; Add the two telescopes together for a master map.
; NOTE! It is unclear whether it's better to do the alignment with A, B, both, or a linear combination!
mSum = mA

; Here we choose how to combine the data.  FPMA seems more reliable than FPMB 
; for some of this, so I'm combining them but weighting that one more.
mSum.data = 2*mA.data + mB.data

; Set up some arrays.
n=n_elements( mA )
shiftA = fltarr(2,n)
shiftB = fltarr(2,n)
shiftSum = fltarr(2,n)

nsmooth = 4		; number of pixels over which to smooth.

; NOTE! This loop is set up for use in a script that is copied-and-pasted into the IDL
; terminal.  If you instead set it up as a procedure or as a script to be run 
; by name, then you'll need to slightly change the syntax of the loop.

; Loop over all the time intervals, doing the coalignment for each one.
; Suggestion!  A good first exercise would be to remove this loop and just do it for 
; one time interval.
.run
for i=0, n-1 do begin
	print, 'Iteration ', i, ' out of ', n
	amap = mA[i]
	bmap = mB[i]
	cmap = mSum[i]
	aia_time = anytim( fexviii.time )
	; Find the AIA map that is closest in time to the NuSTAR time interval of interest.
	aia = fexviii[ closest( aia_time, anytim(amap.time)+6. ) ]	; add 6 sec b/c aia time is the start time.

	; Smooth the NuSTAR map by averaging over a few pixels.
	amap.data = gauss_smooth( amap.data, nsmooth )
	bmap.data = gauss_smooth( bmap.data, nsmooth )
	cmap.data = gauss_smooth( cmap.data, nsmooth )

	; Get the NuSTAR and AIA maps on the same plate scale, field of view, etc.
	nu_coregA = coreg_map( amap, aia, /rescale, /no_project )  
	nu_coregB = coreg_map( bmap, aia, /rescale, /no_project )  
	nu_coregC = coreg_map( cmap, aia, /rescale, /no_project )  

	; Construct a data "cube" that contains the coregistered NuSTAR and AIA data together.
	sz = size( aia.data, /dim )
	cubeA = fltarr( sz[0], sz[1], 2 )
	cubeA( *, *, 1 ) = aia.data
	cubeB = cubeA
	cubeC = cubeA
	cubeA( *, *, 0 ) = nu_coregA.data
	cubeB( *, *, 0 ) = nu_coregB.data
	cubeC( *, *, 0 ) = nu_coregC.data

	; Use cross-correlation to find the spatial offsets and create a new NUSTAR map with corrected pointing.
	offsetsA = get_correl_offsets( cubeA )
	offsetsB = get_correl_offsets( cubeB )
	offsetsC = get_correl_offsets( cubeC )
	;print, offsetsA, offsetsB, offsetsC		; Comment out this line to see the offsets.
	shiftA[*,i] = [(-1)*offsetsA[0,1]*aia.dx,(-1)*offsetsA[1,1]*aia.dy]		; This shifts the maps.
	shiftB[*,i] = [(-1)*offsetsB[0,1]*aia.dx,(-1)*offsetsB[1,1]*aia.dy]
	shiftSum[*,i] = [(-1)*offsetsC[0,1]*aia.dx,(-1)*offsetsC[1,1]*aia.dy]

	; This was for debugging.
	;	newA = shift_map( amap, shiftA[0,i], shiftA[1,i] )
	;	newB = shift_map( bmap, shiftB[0,i], shiftB[1,i] )
	;	newC = shift_map( cmap, shiftSum[0,i], shiftSum[1,i] )

endfor
end

; Smooth the shifts to average out noise.
; NOTE! It is unresolved to what extent this should be done.  If we average too much 
; then we will start losing some of the faster variation.
boxcar=6	; This variable is named because this averaging technique is sometimes called "boxcar" smoothing.
smoothA = shiftA
smoothB = shiftB
smoothSum = shiftSum
smoothA[0,*] = smooth(shifta[0,*],boxcar)
smoothA[1,*] = smooth(shifta[1,*],boxcar)
smoothB[0,*] = smooth(shiftb[0,*],boxcar)
smoothB[1,*] = smooth(shiftb[1,*],boxcar)
smoothSum[0,*] = smooth(shiftSum[0,*],boxcar)
smoothSum[1,*] = smooth(shiftSum[1,*],boxcar)

; Get CHU info.  CHUs are star cameras.  The combination of CHUs used for pointing 
; reconstruction at any given time has a big effect on the alignment, so it's nice to 
; know when/if this configuration changes.
; Don't worry about the details of this code section; it's NOT interesting.
.run
chufile = file_search( data_dir+obsid+'/hk/*chu123.fits')
  for chunum= 1, 3 do begin
    chu = mrdfits(chufile, chunum)
    maxres = 20 ;; [arcsec] maximum solution residual
    qind=1 ; From KKM code...
    if chunum eq 1 then begin
      mask = (chu.valid EQ 1 AND $          ;; Valid solution from CHU
        chu.residual LT maxres AND $  ;; CHU solution has low residuals
        chu.starsfail LT chu.objects AND $ ;; Tracking enough objects
        chu.(qind)(3) NE 1)*chunum^2       ;; Not the "default" solution
    endif else begin
      mask += (chu.valid EQ 1 AND $            ;; Valid solution from CHU
        chu.residual LT maxres AND $    ;; CHU solution has low residuals
        chu.starsfail LT chu.objects AND $ ;; Tracking enough objects
        chu.(qind)(3) NE 1)*chunum^2       ;; Not the "default" solution
    endelse
  endfor
end
chu_time = convert_nustar_time( chu.time, /fits )
nchu = n_elements(mask)
chu_time = chu_time[1:nchu-1]
chu_change = abs( mask[1:nchu-1] - mask[0:nchu-2] )

; This produces some plots.  The POPEN and PCLOSE routines are for saving the plot,  
; but you'll need to get these routines since they're not standard.
; For now, I've commented them out.
; popen, 'sept1-nustar-aia-shifts', xsi=8, ysi=3, /port

!p.multi=[0,2,1]	; Make multiple panels in the plot.
loadct,5			; Colors
hsi_linecolors		; Colors

utplot, ma.time, shifta[0,*], psym=10, $;yra=minmax([shifta[0,*],shiftb[0,*]]), $
	ytit='X shift [arcsec]', tit='NuSTAR to FeXVIII shift', $
	xth=3, yth=3, charsi=0.8, yra=[-40,-5]
outplot, ma.time, smootha[0,*], thick=4
outplot, mb.time, shiftb[0,*], col=6, psym=10
outplot, mb.time, smoothb[0,*], col=6, thick=4
outplot, chu_time, chu_change*1000., col=12
outplot, chu_time, -chu_change*1000., col=12
al_legend, ['FPMA','FPMB'], textcolor=[0,6], box=0, /right, charsi=0.8
al_legend, ['Trend lines show data smoothed over '+strtrim(boxcar,2)+' points.'], /left, $
	/bot, box=0, charsi=0.7
	
utplot, ma.time, shifta[1,*], psym=10, yra=minmax([shifta[1,*],shiftb[1,*]]), $
	ytit='Y shift [arcsec]', tit='NuSTAR to FeXVIII shift', $
	xth=3, yth=3, charsi=0.8
outplot, ma.time, smootha[1,*], thick=4
outplot, mb.time, shiftb[1,*], col=6, psym=10
outplot, mb.time, smoothb[1,*], col=6, thick=4
outplot, chu_time, chu_change*1000., col=12
outplot, chu_time, -chu_change*1000., col=12
al_legend, ['FPMA','FPMB'], textcolor=[0,6], box=0, /right, charsi=0.8
al_legend, ['Trend lines show data smoothed over '+strtrim(boxcar,2)+' points.'], /left, $
	/bot, box=0, charsi=0.7

!p.multi=0		; Set paneling back to normal for future use.

;pclose

for i=0, n_elements(mSum)-1 do mSum[i].data = smooth(mSum[i].data,20)
for i=0, n_elements(ma)-1 do ma[i].data = smooth(ma[i].data,20)
for i=0, n_elements(mb)-1 do mb[i].data = smooth(mb[i].data,20)
corrected_map = mSum
corrected_mapA = mA
corrected_mapB = mB
mSum.id = 'Uncorrected A+B'
corrected_map.id = 'Corrected A+B'
corrected_mapA.id = 'Corrected A'
corrected_mapB.id = 'Corrected B'
for i=0, n_elements(mSum)-1 do corrected_map[i] = shift_map( mSum[i], smoothSum[0,i], smoothSum[1,i] )
for i=0, n_elements(mA)-1 do corrected_mapA[i] = shift_map( mA[i], smoothA[0,i], smoothA[1,i] )
for i=0, n_elements(mB)-1 do corrected_mapB[i] = shift_map( mB[i], smoothB[0,i], smoothB[1,i] )
;for i=0, n_elements(mSum)-1 do corrected_map[i] = shift_map( mSum[i], shiftSum[0,i], shiftSum[1,i] )


loadct,1
reverse_ct
map1 = fexviii[1:*]
map2 = fexviii[1:*]
map3 = fexviii[1:*]
map1.id='Fe18 + Sum FPMA+B, no alignment'
map2.id='Coaligned A'
map3.id='Coaligned B'
mpeg_movie_map_triple, map1, map2, map3, cmap1=mSum, cmap2=corrected_mapA, cmap3=corrected_mapB, /log, $
	lev=[10,30,50,70,90], /per
$	lev=[2.,4.,6.,8.,10.,12.]


;popen, 'nustar-coalignment-sept1', xsi=9, ysi=6, /land
; investigate coalignment trends over time...
!p.multi=[0,2,1]
loadct,1
reverse_ct
plot_map, map2, /log, cen=[930,-230], fov=5, col=255
loadct,5
for i=0, n_elements(corrected_map)-1 do plot_map, corrected_mapA[i], /over, col=2*i, lev=[20.], /per,thick=2
loadct,1
reverse_ct
plot_map, map3, /log, cen=[930,-230], fov=5, col=255
loadct,5
for i=0, n_elements(corrected_map)-1 do plot_map, corrected_mapB[i], /over, col=2*i, lev=[20.], /per,thick=2
;pclose
;spawn, 'open nustar-coalignment-sept1.ps'

;; IMPORTANT NOTE: in examining the results, it looks like FPMA is far more reliable for the alignment than FPMB!
;; Use only the FPMA coalignment for the Sept 1 2015 observation.

; Now, write the results to a text file that can be used for future analysis work.
openw,lun, '20150901_alignment_aiafexviii_v20161019.txt', /get_lun
; First, write a 'header' saying what's in the file.
printf, lun, 'NuSTAR alignment corrections'
printf, lun, '20150901 observation date'
printf, lun, 'OBSID 20102002001'
printf, lun, 'FPMA'
printf, lun, 'Orbit 2'
printf, lun, 'Reference is AIA FeXVIII'
printf, lun, 'Coalignment performed on 20161019'
printf, lun, ''
printf, lun, ''
printf, lun, ''
printf, lun, ''
; Now write the alignment corrections.
printf, lun, 'Time                X correction[arcsec]  Y correction[arcsec]'
for i=0, n_elements(ma)-1 do printf, lun, ma[i].time, smootha[0,i], smootha[1,i]
; Close the file and free up the logical unit.
close, lun
free_lun, lun
