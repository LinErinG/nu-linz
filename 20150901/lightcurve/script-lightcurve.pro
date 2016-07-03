;
; This script produces the images used for time profiles of 
; NuSTAR FPMA and FPMB emission for the Sept. 1, 2015 flare.
; This takes awhile!!
; Make sure to change data_dir to point to wherever the data are.

date = '2015-sep-01'
time = '03:55:30'	; choose a starting time.
dur = 30.					; choose an integration time in seconds
nmax= 28					; Max number of images to make (along with "time" sets time range)
cen = [930,-190]
cen_ar=[925,-270]
fov = 8					; the whole AR, plus a bit extra.
data_dir = '~/data/nustar/20150901/'
era = [2.,3.,4.,5.,7.]		; Here are the energy bin edges
shift = -[-30,25]		; Shift needed to roughly co-align with AIA

tra = findgen(nmax)*dur + anytim( date+' '+time )

; Generate all the maps.  (Time consuming...)
.run
for i=0, n_elements(tra)-2 do begin
for j=0, n_elements(era)-2 do begin
	print, 'Time range = ', anytim(tra[i:i+1],/yo), ' Energy range = ', era[j:j+1]
	make_map_nustar, '20102002001', maindir=data_dir, shift=shift, erang=era[j:j+1], grdid=1, /plot, /xflip, /major_chu, tr=tra[i:i+1], cen=cen_ar, fov=fov
endfor
endfor
end

; At this point, there should be a directory called "out_dir" that contains all the images.
; Next step is to use script-lightcurve-plot to extract and plot the count rates.