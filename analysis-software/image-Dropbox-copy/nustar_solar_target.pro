;+
; 
; 	Project:	NuSTAR Solar
;
;	Name:		nustar_solar_target
;
;	Explanation:	This procedure takes existing AIA files and rotates 
;					the AIA maps to the time of the desired NuSTAR aim time.  AIA 
;					wavelengths 94A, 131A, 171A, and 335A are assumed.  (A future mod 
;					will make the wavelength choice more flexible.)  After rotation, the 
;					AIA maps are plotted with the NuSTAR proposed targeting position on 
;					top.  A box 12 arcmin x 12 arcmin is overlaid to represent NuSTAR's 
;					FoV.  Boxes slightly smaller and slightly larger (by 100 arcsec) are 
;					also overlaid to account for uncertainties in pointing.  Features 
;					within the smallest box will be observed to high confidence.  Features 
;					outside the largest box will be excluded to high confidence.
;
;	Examples:		This procedure should be used as follows:
;
;					(1) Download latest AIA files using download_latest:
;
;						download_latest, instr='aia', wave=94
;					  	download_latest, instr='aia', wave=131
;					  	download_latest, instr='aia', wave=171
;					  	download_latest, instr='aia', wave=335
;
;					(2) Check positioning at aim time by running this procedure:
;
;					  	target, aim_time='2018-05-29T18:02:15'
;
;					(3) Play with the target coords and angle until you get the 
;					    NuSTAR framing that you want.
;
;					(4) Transfer those coordinates to RA and DEC.  This is best done 
;					    using Brian's Python planning tool.  But you can do the coord
;					    transformation (though not the position angle transform) using 
;						nustar_sunpoint:
;
;					  	coords = nustar_sunpoint( target, time=aim_time, epoch_to=j2000 ) 
;					
;	
;	History:	
;					2018 May 27,	L. Glesener		Created routine
;
;	Inputs:			All inputs are via keyword.
;	
;	Outputs:		None, but postscript and PDF files are created as a byproduct.
;	
;	Keywords:
;
;		AIM_TIME:	NuSTAR Aim Time.  This keyword is mandatory.
;		TARGET:  	Target position in helioprojective coords (arcsec from Sun center)
;				 	Default is solar center.
;		FILENAME:	Name of postscript file to be written, without extension
;					Default file will be named 'target.ps'
;		THETA:		"Solar position angle" of NuSTAR, measured as a rotation eastward from 
;					the solar north axis.  Default is zero degrees.
;		AIA_DIR:	Directory in which to look for AIA files.  Default is current dir.
;		STOP:		Stops the procedure (for debugging).
;					
;	Other notes:
;
; 					AIA background maps must be contained in files with a naming 
;					convention that starts with 'AIA' and includes the wavelength at the 
;					end of the filename.  This is the naming convention for files 
;					downloaded from the VSO but NOT the cutout service or the higher 
;					level products.
;
;	Needed routines:
;
;					This routine requires SolarSoftWare (SSWIDL), specifically 
;					drot_map.pro and plot_map.pro.  Other routines that are required are 
;					included in Lindsay's util folder and are listed below. 
;					hsi_linecolors.pro and aia_lct.pro
;					popen.pro and pclose.pro with all their dependencies.
;					Reverse_ct.pro
;
;-

PRO	nustar_solar_target, aim_time=aim_time, target=target, theta=theta, $
	filename=filename, aia_dir=aia_dir, stop=stop

	default, target, [0.,0.]
	default, theta, 0.
	default, filename, 'target'
	default, aia_dir, './'

	if not keyword_set( AIM_TIME ) then begin
		print, 'NuSTAR aim time is not set.'
		return
	endif

	; Find AIA files.
	f094 = file_search( aia_dir + 'AIA*094.*' )
	f131 = file_search( aia_dir + 'AIA*131.*' )
	f171 = file_search( aia_dir + 'AIA*171.*' )
	f335 = file_search( aia_dir + 'AIA*335.*' )

	; Check to see that the files were found, and return error if not.
	if f094[0] eq '' or f131 eq '' or f171 eq '' or f335 eq '' then begin
		print, 'AIA files not found'
		return
	endif
	
	; Read AIA files directly into maps.
	fits2map, f094[n_elements(f094)-1], m094
	fits2map, f131[n_elements(f131)-1], m131
	fits2map, f171[n_elements(f171)-1], m171
	fits2map, f335[n_elements(f335)-1], m335

	; Perform differential solar rotation to project the maps forward in time.
	rot1 = drot_map( m094, time=aim_time )
	rot2 = drot_map( m131, time=aim_time )
	rot3 = drot_map( m171, time=aim_time )
	rot4 = drot_map( m335, time=aim_time )

	rot1.id = 'AIA 94'
	rot2.id = 'AIA 131'
	rot3.id = 'AIA 171'
	rot4.id = 'AIA 335'

	; Construct the FoV boxes.
	fov=12.*60		; fov in arcsec.  12' is FOV of detector.
	box = fltarr(2,5)
	box[0,*] = fov*0.5*[-1,-1,1,1,-1]
	box[1,*] = fov*0.5*[1,-1,-1,1,1]

	; smaller box.  Each edge will be 90" away from the regular box edge.
	box_small = fltarr(2,5)
	box_small[0,*] = (fov-180)*0.5*[-1,-1,1,1,-1]
	box_small[1,*] = (fov-180)*0.5*[1,-1,-1,1,1]

	; larger box.  Each edge will be 90" away from the regular box edge.
	box_big = fltarr(2,5)
	box_big[0,*] = (fov+180)*0.5*[-1,-1,1,1,-1]
	box_big[1,*] = (fov+180)*0.5*[1,-1,-1,1,1]

	; Adjust boxes to have crosshairs (target) approximately on the optical axis.
	; The is approximated by displacing the target 1 arcmin in X and Y from the center 
	; of the detector.
	box[0,*] += 60.
	box_small[0,*] += 60.
	box_big[0,*] += 60.
	box[1,*] -= 60.
	box_small[1,*] -= 60.
	box_big[1,*] -= 60.

	; Perform the rotation of the FoV by the solar position angle desired.
	cosx = cos(theta*!pi/180.)
	sinx = sin(theta*!pi/180.)
	rotarr = [[cosx,-sinx],[sinx,cosx]]
	for i=0,4 do box[*,i] = box[*,i]#rotarr + target
	for i=0,4 do box_big[*,i] = box_big[*,i]#rotarr + target
	for i=0,4 do box_small[*,i] = box_small[*,i]#rotarr + target
	
	if keyword_set( STOP ) then stop	; debugging

	popen, filename + '.ps', xsi=7, ysi=7
	!p.multi=[0,2,2]
	x = -1000

	aia_lct, r,g,b,wave=94, /load
	reverse_ct
	plot_map, rot1, /log, dmin=1., cen=[0,0], fov=35, /limb, col=255, lcol=255, $
		xth=3, yth=3, charsi=0.7
	hsi_linecolors
	oplot, box[0,*], box[1,*], col=6, thick=5
	oplot, box_small[0,*], box_small[1,*], col=6, thick=5
	oplot, box_big[0,*], box_big[1,*], col=6, thick=5
	oplot, [target[0]],[target[1]], /psy, symsi=3
	xyouts, x, -850, 'Target center ['+strtrim(target[0],2)+','+strtrim(target[1],2)+']',$
		col=6, charsi=0.8
	xyouts, x, -1000, 'Boxes 12 arcmin +/- 100 arcsec', col=6, charsi=0.8

	aia_lct, r,g,b,wave=131, /load
	reverse_ct
	plot_map, rot2, /log, dmin=1., cen=[0,0], fov=35, /limb, col=255, lcol=255, $
		xth=3, yth=3, charsi=0.7
	hsi_linecolors
	oplot, box[0,*], box[1,*], col=6, thick=5
	oplot, box_small[0,*], box_small[1,*], col=6, thick=5
	oplot, box_big[0,*], box_big[1,*], col=6, thick=5
	xyouts, x, -850, 'Target center ['+strtrim(target[0],2)+','+strtrim(target[1],2)+']',$
		col=6, charsi=0.8
	xyouts, x, -1000, 'Boxes 12 arcmin +/- 100 arcsec', col=6, charsi=0.8

	aia_lct, r,g,b,wave=171, /load
	reverse_ct
	plot_map, rot3, /log, dmin=0., cen=[0,0], fov=35, /limb, col=255, lcol=255, $
		xth=3, yth=3, charsi=0.7
	hsi_linecolors
	oplot, box[0,*], box[1,*], col=6, thick=5
	oplot, box_small[0,*], box_small[1,*], col=6, thick=5
	oplot, box_big[0,*], box_big[1,*], col=6, thick=5
	xyouts, x, -850, 'Target center ['+strtrim(target[0],2)+','+strtrim(target[1],2)+']',$
		col=6, charsi=0.8
	xyouts, x, -1000, 'Boxes 12 arcmin +/- 100 arcsec', col=6, charsi=0.8

	aia_lct, r,g,b,wave=335, /load
	reverse_ct
	plot_map, rot4, /log, dmin=1., cen=[0,0], fov=35, /limb, col=255, lcol=255, $
		xth=3, yth=3, charsi=0.7
	hsi_linecolors
	oplot, box[0,*], box[1,*], col=6, thick=5
	oplot, box_small[0,*], box_small[1,*], col=6, thick=5
	oplot, box_big[0,*], box_big[1,*], col=6, thick=5
	xyouts, x, -850, 'Target center ['+strtrim(target[0],2)+','+strtrim(target[1],2)+']',$
		col=6, charsi=0.8
	xyouts, x, -1000, 'Boxes 12 arcmin +/- 100 arcsec', col=6, charsi=0.8

	!p.multi=0
	pclose

	spawn, 'open ' + filename + '.ps'

END