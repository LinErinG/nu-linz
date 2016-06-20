;
; Example script for producing NuSTAR images in solar coordinates from cleaned event lists
;

add_path, '~/Dropbox/NuSTAR_Solar/code/image/'

;
; Step 1 (if needed):  Do a 3rd-order polynomial fit to the JPL Horizons data.
;

; To start, must have a text file with the Horizons output ('ephem.txt' in this example).
; If fit has already been done, just need the RA and DEC fit coefficients and the
; reference time that was used for the fit.  Watch the units.

; Produce a template for reading the text file, if desired.
;tmp = ascii_template( 'ephem.txt' )
;save, tmp, file='template.sav'

restore, 'template.sav', /v
ephem = read_ascii( 'ephem.txt', temp=tmp )
time = anytim( ephem.date + ' ' + ephem.time )

fitdec = poly_fit( (time-time[0])/3600./24., (ephem.dec)*!dpi/180., 3, yfit=yfit )
fitra  = poly_fit( (time-time[0])/3600./24., (ephem.ra)*!dpi/180., 3, yfit=yfit )
ref_time = anytim(time[0], /vms)
save, fitra, fitdec, ref_time, file='ephem.sav'

;
; Step 2: Transfer cleaned event lists to solar coordinates.
;

restore, 'ephem.sav', /v

obs_list = ['20012001_Sol_14305_AR2192_1', '20012002_Sol_14305_AR2192_2', $
            '20012003_Sol_14305_AR2192_3','20012004_Sol_14305_AR2192_4']
dir = '~/nustar/obs2/data/'

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
;

filestem = 'mosaic_obs2'
solar_mosaic, obs_list, filestem, topdir='~/nustar/obs2/data/'
solar_mosaic_hk_gen, obs_list, filestem, topdir='~/nustar/obs2/data/'

;
; Make a NuSTAR image in a plot_map form.
;

date = '2014-nov-01'
time = '16:44:00'	; choose a starting time.
time = '21:40:21'
dur = 600.			; choose an integration time (in seconds)
dur = 18000.
evt_file = 'mosaic_obs2.evt'
nu_map = nustar_solar_image( date, time, dur, evt_file )
;nu_map = nustar_solar_image( date, time, dur, evt_file, /smooth )
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
