;+
; NAME:			nustar_solar_movie
;
; PURPOSE:	Create a movie from the solar-coord-adjusted EVT and HK files.
;
; EXAMPLE:
;		date = '2015-sep-01'
;		time = '03:31:08'		; choose a starting time.
;		dur = 600.					; choose an integration time in seconds
;		cen = [950,-200]
;		fov = 20						; FOV in arcmin
;		evt_file = 'orbit2.evt'
;		map = nustar_solar_movie( date, time, dur, evt_file, cen=cen, fov=fov ) 
;		movie_map, map, /limb
;
; INPUTS:
;			date			Observation date in string form, example '2014-nov-01'
;			time			Start time for image integration, string form, ex. '21:40:21'
;			dur				Integration time, i.e. frame cadence.
;			evt_file	Filename, including path, for EVT file.
;			
; OPTIONAL KEYWORDS:
;			energy_range			2-element array restricting photon energies
;			smooth						If set, smooth the data.
;			no_live_correct		If set, do not perform the livetime correction.
;			nmax							Max number of frames from start time.
;			gradezero					Return only grade 0 events.
;			dir								Where the EVT and HK files are kept.
;			hkfile						Specify the housekeeping file by name.
;
;	COMING SOON:  keyword to control pixel size and image size.  Also CHU combos.
;
; RETURN VALUE:	plot_map containing the NuSTAR image in solar coordinates, with 
;								data integrated from start time TIME for DUR seconds.
;		
; MODIFICATION HISTORY:
;			2015-sep-27		LG	Created routine, based on nustar_solar_image.pro
;-

FUNCTION	NUSTAR_SOLAR_MOVIE,	DATE, START_TIME, DUR, EVT_FILE, ENERGY_RANGE = ENERGY_RANGE, $
					SMOOTH = SMOOTH, CENTER=CENTER, FOV=FOV, NO_LIVE_CORRECT=NO_LIVE_CORRECT, $
					NMAX=NMAX, DIR=DIR, GRADEZERO=GRADEZERO, HKFILE=HKFILE, STOP=STOP

	default, dur, 60.
	default, center, [0.,0.]
	default, fov, 40
	default, dir, './'

	start_time_nu = convert_nustar_time( anytim( date+' '+start_time, /vms ), /from_ut )
	
	; Allowable utime formats for convert_nustar_time are:
	;14-JUL-2005 15:25:44.23		; vms?  stime?
	;YYYY-MM-DD HH:MM:SS.SS		; ccsds?
	; a quick check shows that VMS, STIME, and CCSDS should all work...

	if strmid(dir,0,1,/rev) ne '/' then dir = dir + '/'
	infile = dir + evt_file
	if not keyword_set(hkfile) then hkfile = file_basename(infile, '.evt')+'.hk'
	if (strpos(hkfile,'/'))[0] eq -1 then hkfile = dir + hkfile

	evt = mrdfits(infile, 1,evth)
	hk = mrdfits(hkfile, 1, hkhdr)

		; Screen out bad events
		;	inrange = where(evt.x lt 1500)
		;	evt = evt[inrange]
		inrange = where(evt.pi ge 0)
		evt = evt[inrange]
	
		; energy filtering
		; Use approx rule; kev = evt.pi*0.04+1.6
		if keyword_set( ENERGY_RANGE ) then begin
			en = evt.pi*0.04+1.6
			inrange = where( en ge energy_range[0] and en le energy_range[1] )
			evt = evt[inrange]
		endif
		
		; grade filtering
		if keyword_set( GRADEZERO ) then evt = evt[ where( evt.grade eq 0 ) ]

		ttype = where(stregex(evth, "TTYPE", /boolean))
		xt = where(stregex(evth[ttype], 'X', /boolean))

		; Converted X/Y is always last in the header:
		; Parse out the position:
		xpos = (strsplit( (strsplit(evth[ttype[max(xt)]], ' ', /extract))[0], 'E', /extract))[1]
		npix = sxpar(evth, 'TLMAX'+xpos)
		pix_size = abs(sxpar(evth,'TCDLT'+xpos))    ; pixel size in arcseconds

		evt_diff = evt.time - start_time_nu[0]
		hk_diff  = hk.time  - start_time_nu[0]

	default, nmax, 100*60/dur		; 100 minutes is max considered.
	
	for frame = 0, nmax-1 do begin

		print, 'Frame ', frame

		t_ind  = where( evt_diff ge frame*dur and evt_diff lt (frame+1)*dur )
		hk_ind = where( hk_diff ge frame*dur and hk_diff lt (frame+1)*dur )

			if t_ind[0] eq -1 then continue

		if average( hk[hk_ind].livetime ) gt 0.2 then $
			print, 'WARNING!  Avg livetime is high; likely some bad intervals included.'
	
		; reverse order to match AIA formalism
		pixinds = (npix - evt[t_ind].x) + evt[t_ind].y * npix
		if n_elements(pixinds) lt 2 then continue
		im_hist = histogram(pixinds, min = 0, max = npix*npix-1, binsize = 1)
		im = reform(im_hist, npix, npix)

		; Get the livetime:
		livetime = average( hk[hk_ind].livetime )
	
		time = average( evt[ t_ind ].time )
		time_string = convert_nustar_time(time, /fits)

;		plot_map, make_map( im, dx=pix_size, dy=pix_size), time=time_string, /log, /limb, fov=40

		; Livetime correction
		if not keyword_set( NO_LIVE_CORRECT ) then im = im / livetime
		if keyword_set( SMOOTH ) then im = gauss_smooth(float(im), 5)
		nu_map = make_map( im, dx=pix_size, dy=pix_size, time=time_string, dur=dur )
		nu_map = make_submap( nu_map, cen=center, fov=fov )

		plot_map, nu_map, /limb
		
		push, maps, nu_map
		
	endfor

;	maps = make_submap( maps, cen=center, fov=fov )

	if keyword_set(stop) then stop

	return, maps

END