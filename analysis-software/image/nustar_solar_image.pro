;+
; NAME:			nustar_solar_image
;
; PURPOSE:	Create a plot_map from the solar-coord-adjusted EVT and HK files.
;
; EXAMPLE:
;   date = '2014-nov-01'
;   time = '21:40:21'	; choose a starting time.
;   dur = 600.			; choose an integration time (in seconds)
;	evt_file = 'solar_mosaic_orbit4.evt'
;	nu_map = nustar_solar_image( date, time, dur, evt_file )
;	plot_map, nu_map, fov=40
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
;	COMING SOON:  keyword to control pixel size and image size.
;
; RETURN VALUE:	plot_map containing the NuSTAR image in solar coordinates, with 
;								data integrated from start time TIME for DUR seconds.
;		
; MODIFICATION HISTORY:
;			2015-feb-05		LG	Created routine.
;-

FUNCTION	NUSTAR_SOLAR_IMAGE,	DATE, START_TIME, DUR, EVT_FILE, $
			ENERGY_RANGE = ENERGY_RANGE, SMOOTH = SMOOTH, STOP=STOP

	start_time_nu = convert_nustar_time( anytim( date+' '+start_time, /vms ), /from_ut )
	
	; Allowable utime formats for convert_nustar_time are:
	;14-JUL-2005 15:25:44.23		; vms?  stime?
	;YYYY-MM-DD HH:MM:SS.SS		; ccsds?
	; a quick check shows that VMS, STIME, and CCSDS should all work...

	infile = evt_file
	hkfile = file_basename(infile, '.evt')+'.hk'

	evt = mrdfits(infile, 1,evth)
	hk = mrdfits(hkfile, 1, hkhdr)

	; Screen out bad events
	;	inrange = where(evt.x lt 1500)
	;	evt = evt[inrange]
	inrange = where(evt.pi ge 0)
	evt = evt[inrange]
	
	; energy filtering
	; Use approx rule; kev = evt.pi*0.04+1.6
	if keyword_set( energy_range ) then begin
		en = evt.pi*0.04+1.6
		inrange = where( en ge energy_range[0] and en le energy_range[1] )
		evt = evt[inrange]
	endif

	ttype = where(stregex(evth, "TTYPE", /boolean))
	xt = where(stregex(evth[ttype], 'X', /boolean))

	; Converted X/Y is always last in the header:
	; Parse out the position:
	xpos = (strsplit( (strsplit(evth[ttype[max(xt)]], ' ', /extract))[0], 'E', /extract))[1]
	npix = sxpar(evth, 'TLMAX'+xpos)
	pix_size = abs(sxpar(evth,'TCDLT'+xpos))    ; pixel size in arcseconds

	evt_diff = evt.time - start_time_nu[0]
	hk_diff  = hk.time  - start_time_nu[0]
	t_ind  = where( evt_diff ge 0 and evt_diff lt dur )
	hk_ind = where( hk_diff ge 0 and hk_diff lt dur )

	if average( hk[hk_ind].livetime ) gt 0.2 then $
		print, 'WARNING!  Avg livetime is high; likely some bad intervals included.'

	; reverse order to match AIA formalism
	pixinds = (npix - evt[t_ind].x) + evt[t_ind].y * npix
	im_hist = histogram(pixinds, min = 0, max = npix*npix-1, binsize = 1)
	im = reform(im_hist, npix, npix)

	plot_map, make_map( im, dx=pix_size, dy=pix_size), /log, /limb, fov=40

		; Get the livetime:
		livetime = average( hk[hk_ind].livetime )
	
		time = average( evt[ t_ind ].time )
		time_string = convert_nustar_time(time, /fits)

;		plot_map, make_map( im, dx=pix_size, dy=pix_size), time=time_string, /log, /limb, fov=40

		; Livetime correction
		if not keyword_set( NO_LIVE_CORRECT ) then im = im / livetime
		if keyword_set( SMOOTH ) then im = gauss_smooth(float(im), 5)
		nu_map = make_map( im, dx=pix_size, dy=pix_size, time=time_string, dur=dur )

		plot_map, nu_map, /limb, fov=40

	if keyword_set(stop) then stop

	return, nu_map

END