;+
; NAME:			convert_to_solar_gen
;
; PURPOSE:	Generalized version of Brian's convert_to_solar.pro routine.  It takes
;						observation-specific parameters in as arguments so that the architecture
;						should work for any observation.
;
; CALLING EXAMPLE:
;		restore, 'ephem.sav', /v		; Restore solar ephemeris data from file.
;		file = '~/nustar/obs3/data/20001005_Sol_14345_AR2222/20001005001/event_cl/nu20001005001B06_cl.evt'
;		convert_to_solar_mod, file, fitra, fitdec, ref_time
;
; INPUTS:
;		evtfile			Cleaned event list produced by the NuSTAR pipeline
;		ra_coeff		Coefficients from 3rd-order polynomial fit to solar RA from Horizons
;		dec_coeff		Coefficients from 3rd-order polynomial fit to solar Dec from Horizons
;		ref_time		The reference time used for the polynomial fit.
;
; OPTIONAL KEYWORDS:
;		offset			Additional [X,Y] offset to add onto the coords (for example if known
;								from comparisons with other instruments)
;		outdir			Output directory, default is evtfile directory
;
; OUTPUTS:		None
;
; COMMON BLOCKS:
;
; SIDE EFFECTS:	Produces a new event list file with filename ending in _sunpos.evt
;								If file exists, it will be overwritten.
;
; RESTRICTIONS: User needs to have already done a fit to the solar ephemeris data
;								gleaned from JPL Horizons.
;
; MODIFICATION HISTORY:
;		2015-feb-01		LG		Wrote routine based on Brian and Stephen's examples.
;-

PRO convert_to_solar_gen, evtfile, ra_coeff, dec_coeff, ref_time, offset=offset, $
													outdir=outdir, stop=stop

	default, offset, [0.,0.]

	f = file_info(evtfile)
	if ~f.exists then message, 'File not found!'
	if exist(outdir) then outpath=outdir else outpath = file_dirname(evtfile)
	outfile = outpath+'/'+file_basename(evtfile, '.evt')+'_sunpos.evt'
	evt=mrdfits(evtfile,1,evth)

	; Tag bad events with a position that won't get picked up in the imaging codes.
	evt[ where(evt.x le 0) ].pi = -10

   ; Find the vals associated with X and Y
	ttype = where(stregex(evth, "TTYPE", /boolean))
	xt = where(stregex(evth[ttype], 'X', /boolean))
	yt = where(stregex(evth[ttype], 'Y', /boolean))

   ; Converted X/Y is always last in the header:
   ; Parse out the position:
	xpos = (strsplit( (strsplit(evth[ttype[max(xt)]], ' ', /extract))[0], 'E', /extract))[1]
	ypos = (strsplit( (strsplit(evth[ttype[max(yt)]], ' ', /extract))[0], 'E', /extract))[1]

 	; Grab astrometry header keywords:
	ra0 = sxpar(evth,'TCRVL'+xpos)     ; should match TCRVL13 which has lower precision
	dec0 = sxpar(evth,'TCRVL'+ypos)    ; should match TCRVL14 which has lower precision
	x0 = sxpar(evth,'TCRPX'+xpos)      ; x ref pixel in same axes as x, y
	y0 = sxpar(evth,'TCRPX'+ypos)      ; y ref pixel
	delx = sxpar(evth,'TCDLT'+xpos)    ; pixel size in degree
	dely = sxpar(evth,'TCDLT'+ypos)    ; pixel size in degree

	; Convert to RA/DEC
	yd = dec0 + (evt.y - y0)*dely
	xr = ra0 + (evt.x - x0)*delx/cos(dec0/180.0d0*!dpi) ; imperfect correction for cos(dec) for quick work

	; Convert event files to MJD:
	;   tt = evt.time mod 86400.0d0  ; seconds of current day
	;   tmjd = 55197.0d0 + evt.time/86400.0d0
	tmjd = convert_nustar_time(evt.time, /mjd)

	; 3rd-order polynomial fit to solar motion from JPL Horizons (from
	; Stephen White).
	;rac=[3.78221797966D+00, 1.70943286815D-02, 2.83579284998D-05, 1.39074493255D-07 ]
	;decc=[-2.53530059546D-01, -5.56800694049D-03, 3.42162449769D-05, 7.16446280080D-08 ]
	rac = ra_coeff
	decc = dec_coeff
	;t0=56962.8125d0
	; use the reference time, but make sure to get it into MJD
	; EXACTLY the same way NuSTAR times convert.
	temp = convert_nustar_time( anytim( ref_time, /vms), /from_ut )
	t0 = convert_nustar_time( temp, /mjd )

	; mjd offsets from reference time for polynomial
	dt = tmjd - t0[0]
	; sun center ra, dec for every photon in degrees
	xs=(rac[0]+rac[1]*dt + rac[2]*(dt^2) + rac[3]*(dt^3))*180.0d0/!dpi
	ys=(decc[0]+decc[1]*dt + decc[2]*(dt^2) + decc[3]*(dt^3))*180.0d0/!dpi
	; RA, dec offsets of photons from Sun center in arcsec
	dx = -(xr - xs)*3600.0d0 ; 
	dy =  (yd - ys)*3600.0d0

	; Before, Stephen put in the P angle by hand.  Instead, use SSW routine.
	;p0 = 24.3515154d0/180.0d0*!dpi
	;p0 = (get_rb0p( convert_nustar_time(t, /from_mjd, /fits) ) )[2]
	p0 = (get_rb0p( convert_nustar_time( average(evt.time), /fits), /quiet ) )[2]
	dxs = dx * cos(p0) + dy * sin(p0)
	dys = dy * cos(p0) - dx * sin(p0)

   ; Apply fiducial offsets in Solar frame (N is Up, West is right)
	; Following are the values determined by Stephen for the 2014-11-01 pointing,
	; as an example.
	;dxs += 50.                      ; 50" to the West
	;dys += 15.                      ; 15" to the North
	dxs += offset[0]
	dys += offset[1]

   ; Convert back to degrees:
	;dxs_deg = dxs / 3600.
	;dys_deg = dys / 3600.

  ; change to 0-3000 pixels:
	maxX = 3000
	maxY = 3000
	x0 = maxX / 2.
	y0 = maxY / 2.
	dely = dely * 3600. ; convert to arcseconds
	delx = delx * 3600. ; switch from West = left to West = right
	evt.x = (dxs / delx) + x0 
	evt.y = (dys / dely) + y0
	
	; Adjust astrometry headers
	fxaddpar, evth, 'TCRVL'+xpos, '0.0'
	fxaddpar, evth, 'TCRVL'+ypos, '0.0'
	fxaddpar, evth, 'TCDLT'+xpos, -delx ; minus to account for left/right switch for solar vs astro
	fxaddpar, evth, 'TCDLT'+ypos, dely
	fxaddpar, evth, 'TLMAX'+xpos, maxX
	fxaddpar, evth, 'TLMAX'+ypos, maxY
	fxaddpar, evth, 'TCRPX'+xpos, x0
	fxaddpar, evth, 'TCRPX'+ypos, y0
	mwrfits, evt, outfile, evth, /create
	
	if keyword_set(stop) then stop


END



