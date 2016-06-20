;
; Lindsay's example script for producing NuSTAR images and movies for Sept. 1-2 2015 data.
;	Inputs and outputs for any of these steps can be provided.
;

add_path, '~/Dropbox/NuSTAR_Solar/code/image/'

;
; Step 1 (if needed):  Do a 3rd-order polynomial fit to the JPL Horizons data.
;

; To start, must have a text file with the Horizons output ('ephem_201509.txt' in this example).
; If fit has already been done, just need the RA and DEC fit coefficients and the
; reference time that was used for the fit.  Watch the units.

; Produce a template for reading the text file, if desired.
;tmp = ascii_template( 'ephem_201509.txt' )
;save, tmp, file='template.sav'

restore, 'template.sav', /v
ephem = read_ascii( 'ephem_201509.txt', temp=tmp )
time = anytim( ephem.date + ' ' + ephem.time )

fitdec = poly_fit( (time-time[0])/3600./24., (ephem.dec)*!dpi/180., 3, yfit=yfit )
fitra  = poly_fit( (time-time[0])/3600./24., (ephem.ra)*!dpi/180., 3, yfit=yfit )
ref_time = anytim(time[0], /vms)
save, fitra, fitdec, ref_time, file='ephem_201509.sav'

;
; Step 2: Transfer cleaned event lists to solar coordinates.
;

restore, 'ephem_201509.sav', /v

; This observation list includes 7 orbits on Sept 1 and 2.
obs_list = ['20102002001','20102003001','20102004001','20102005001', $
						'20102006001','20102007001','20102008001']
dir = '~/data/nustar/20150901/'

; Note: this will produce solar event lists within the existing directory structure
; (i.e. in "event_cl")
.r
for obs = 0, n_elements(obs_list) -1 do begin
   datpath = file_search( dir+obs_list[obs]+'/*', /test_dir)
   if n_elements( DATPATH ) gt 1 then $			; allows for two different dir structures.
   		datpath = file_search( dir+obs_list[obs]+'/', /test_dir)
   f = file_search( datpath + '/event_cl/*06_cl.evt' )
	convert_to_solar_gen, f[0], fitra, fitdec, ref_time
	convert_to_solar_gen, f[1], fitra, fitdec, ref_time
endfor
end

;
; Step 3: Add together multiple data sets (if desired) and prep the housekeeping file.
; Since this example doesn't have a mosaic, you could skip the "solar_mosaic" step.
; (I include it here to keep the example general. 
; The second step (the housekeeping step) still must be done.
;

obs_list = ['20102002001','20102003001','20102004001','20102005001', $
						'20102006001','20102007001','20102008001']
dir = '~/data/nustar/20150901/'

.r
for obs=0, n_elements(obs_list) -1 do begin
	filestem = 'orbit'+strtrim(obs+2,2)
	solar_mosaic, obs_list[obs], filestem, topdir=dir
	solar_mosaic_hk_gen, obs_list[obs], filestem, topdir=dir
endfor
end

;
; Make a NuSTAR image in a plot_map form.
;

date = '2015-sep-01'
time = '03:31:08'	; choose a starting time.
dur = 18000.			; choose an integration time in seconds
evt_file = 'orbit2.evt'
nu_map = nustar_solar_image( date, time, dur, evt_file )
nu_map = nustar_solar_image( date, time, dur, evt_file, /smooth )
plot_map, nu_map, /limb, fov=40

;
; Options for nustar_solar_image
;
; INPUTS:
;			date		Observation date in string form, example '2014-nov-01'
;			time		Start time for image integration, string form, ex. '21:40:21'
;			dur			Integration time for image
;			evt_file	Filename, including path, for EVT file.
;			
; OPTIONAL KEYWORDS:
;			energy_range	2-element array restricting photon energies
;			smooth				If set, data will be smoothed over this many subpixels.
;

;
; For images sequences, use nustar_movie instead.
;

date = '2015-sep-01'
time = '03:47:08'	; choose a starting time.
dur = 60.					; choose an integration time in seconds
cen = [950,-200]
fov = 20					; FOV in arcmin
evt_file = 'orbit2.evt'
map = nustar_solar_movie( date, time, dur, evt_file, cen=cen, fov=fov, /smooth ) 

