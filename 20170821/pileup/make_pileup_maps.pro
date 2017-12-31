PRO 	make_pileup_maps, obsid, maindir=maindir, shift=shift, $
  		erang=erang, stop=stop, tr=tr, cen=cen, fov=fov, xflip=xflip

  ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ;  Make 2 maps that estimate pileup fraction.
  ;  For one, use the rate and Poisson statistics to calculate the expected pileup.
  ;  For the other, use the measured grade fractions.
  ;				
  ;					Required inputs:
  ;					OBSID		OBSID of observation of interest.  It is expected that the data is 
  ;									stored in MAINDIR/OBSID/event_cl, etc...  If the directory structure 
  ;									is different, you will need to slightly modify the code.
  ;
  ;         Optional keywords:
  ;					maindir	top directory for NuSTAR data
  ;					shift		offset in [x,y] to apply
  ;									For automatic shift based on CHUs, set SHIFT=1 
  ;									(SHIFT=1 requires that alignments are contained in text file)
  ;         grdid   0,1,2 for Event grade 0, all or 21-24	!!NOT A KEYWORD FOR THIS ROUTINE!!
  ;         erang   Energy range covered by the map, if only 1 elements then >erang
  ;                  (default is >2 keV)
  ;         plot    Want to plot the maps? (default no)
  ;			tr			time range for map
  ;			DON'T isolate by CHU in this routine.
  ;			cen			Center in arcsec for the map.  Defaults to data median
  ;			fov			FOV in arcmin for the map.  Default 15 arcmin
  ;			xflip		Flip X axis.  When working with old data this might be necessary.
  ;						Default don't flip.  (Should be done already in solar conversion.)
  ;
  ; 30-Dec-2017 LG		Made routine starting from MAKE_MAP_NUSTAR.
  ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	default, shift, [0.,0.]
	default, fov, 15
	default, maindir, './'
	
	ddname=obsid

	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; Get the *_cl_sunpost.evt files

	cla_file=maindir+ddname+'/event_cl/nu'+ddname+'A06_cl_sunpos.evt'
	evta = mrdfits(cla_file, 1,evtah)

	clb_file=maindir+ddname+'/event_cl/nu'+ddname+'B06_cl_sunpos.evt'
	evtb = mrdfits(clb_file, 1,evtbh)

	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; Do the time selection.
	if keyword_set( TR ) then begin  
	tr_nu = convert_nustar_time( anytim(tr,/vms), /from_ut )
	evta = evta[ where( evta.time gt tr_nu[0] and evta.time lt tr_nu[1] ) ]
	evtb = evtb[ where( evtb.time gt tr_nu[0] and evtb.time lt tr_nu[1] ) ]
	endif

	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; Select only those events with evt.pi ge 0 to get rid of (some) bad pix.
	evta = evta[ where( evta.pi ge 0 ) ]
	evtb = evta[ where( evtb.pi ge 0 ) ]

	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; Check that some data remains after these cuts.
	if n_elements( EVTA ) lt 2 or n_elements( EVTB ) lt 2 then begin
		print, 'Not enough events in time interval'
		return
	endif

	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; Get the indices for events with Grade 0 and for events with 
	; unphysical grades (21-24).
	; grade '2' here is just short for grades 21-24.
	i_evta_grd0 = where( evta.grade eq 0 )
	i_evta_grd2 = where( evta.grade ge 21 and evta.grade le 24 )
	i_evtb_grd0 = where( evtb.grade eq 0 )
	i_evtb_grd2 = where( evtb.grade ge 21 and evta.grade le 24 )

	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; Get the livetime info
	hka_file=maindir+ddname+'/hk/nu'+ddname+'A_fpm.hk'
	hka = mrdfits(hka_file, 1, hkahdr)
	hkatims=anytim(hka.time+anytim('01-Jan-2010'))

	t1a=anytim(min(evta.time)+anytim('01-Jan-2010'),/yoh,/trunc)
	t2a=anytim(max(evta.time)+anytim('01-Jan-2010'),/yoh,/trunc)

	lvida=where(hkatims ge anytim(t1a) and hkatims lt anytim(t2a))
	lvtcora=mean(hka[lvida].livetime)

	hkb_file=maindir+ddname+'/hk/nu'+ddname+'B_fpm.hk'
	hkb = mrdfits(hkb_file, 1, hkbhdr)
	hkbtims=anytim(hkb.time+anytim('01-Jan-2010'))

	t1b=anytim(min(evtb.time)+anytim('01-Jan-2010'),/yoh,/trunc)
	t2b=anytim(max(evtb.time)+anytim('01-Jan-2010'),/yoh,/trunc)

	lvidb=where(hkbtims ge anytim(t1b) and hkbtims lt anytim(t2b))
	lvtcorb=mean(hkb[lvidb].livetime)

	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; Setup the pixel and binning sizes
	; Get the same values if using evtah or evtbh
	ttype = where(stregex(evtah, "TTYPE", /boolean))
	xt = where(stregex(evtah[ttype], 'X', /boolean))
	xpos = (strsplit( (strsplit(evtah[ttype[max(xt)]], ' ', /extract))[0], 'E', /extract))[1]
	npix = sxpar(evtah, 'TLMAX'+xpos)
	pix_size = abs(sxpar(evtah,'TCDLT'+xpos))

	if n_elements( SHIFT ) eq 2 then begin
		xshf = shift[0]
		yshf = shift[1]
	endif		

	if n_elements( SHIFT ) eq 1 and shift[0] eq 1 then begin
		restore, 'template_align.sav'
		align = read_ascii( file_search( 'alignments*.txt' ), tem=template_align )
		j = where( align.chu_code eq chu_num )
		xshf = -align.x_shift[j]
		yshf = -align.y_shift[j]
		xshf=xshf[0]
		yshf=yshf[0]
	endif
	
	xshf /= pix_size
	yshf /= pix_size
  
	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; Make map for FPMA
	if keyword_set( XFLIP ) then evtx = (npix - evta.x)-xshf else evtx=evta.x-xshf
	evty=evta.y-yshf

	; bug fix to deal with case that there is only 1 event.
	if n_elements( evtx ) eq 1 then begin
		evtx = [evtx]
		evty = [evty]
	endif
	
	if not keyword_set( CEN ) then begin
		cen = fltarr( 2 )
		cen[0] = (median(evtx)-npix/2)*pix_size
		cen[1] = (median(evty)-npix/2)*pix_size
	endif
	
	im_hist = hist_2d( evtx, evty, min1=0, min2=0, max1=npix-1, max2=npix-1, bin1=1, bin2=1 )
	im_hist_grd0 = hist_2d( evtx[i_evta_grd0], evty[i_evta_grd0], min1=0, min2=0, max1=npix-1, max2=npix-1, bin1=1, bin2=1 )
	im_hist_grd2 = hist_2d( evtx[i_evta_grd2], evty[i_evta_grd2], min1=0, min2=0, max1=npix-1, max2=npix-1, bin1=1, bin2=1 )

	; I'd like these images in 12.3 arcsec bins.
	; The factor of 25 is to keep the total of the histograms accurate.
	im_hist = rebin( 25*float(im_hist), npix/5, npix/5 )
	im_hist_grd0 = rebin( 25*float(im_hist_grd0), npix/5, npix/5 )
	im_hist_grd2 = rebin( 25*float(im_hist_grd2), npix/5, npix/5 )

	datA = 0.25*im_hist_grd2/im_hist_grd0

	dur=anytim(t2a)-anytim(t1a)
	time=t1a
	ang = pb0r(t1a,/arcsec,l0=l0)

	; This is the pileup map computed from the grades.
	mapa_grades = make_map( datA, dx=pix_size*5, dy=pix_size*5, time=time, dur=dur, $
			 				id='FPMA est pileup from grades', l0=l0,b0=ang[1],rsun=ang[2])
	mapa_grades= make_submap( mapa_grades, cen=cen, fov=fov )
	
	; Also do one with just the unphysical grades, for reference.
	mapa_unphysical = make_map( im_hist_grd2, dx=pix_size*5, dy=pix_size*5, time=time, $
								dur=dur, id='FPMA unphysical grades', l0=l0,b0=ang[1],rsun=ang[2])	
	mapa_unphysical= make_submap( mapa_unphysical, cen=cen, fov=fov )
  
	; Now do the one from the estimated rate. Apply the livetime correction
	ima_lvt=im_hist/(float(lvtcora)*dur)
	pileup_window = 8.e-6
	prob = 1.-exp(-pileup_window*ima_lvt)

	mapa_rates = make_map( prob, dx=pix_size*5, dy=pix_size*5, time=time, dur=dur, $
						   id='FPMA est pileup from rates', l0=l0,b0=ang[1],rsun=ang[2])
	mapa_rates= make_submap( mapa_rates, cen=cen, fov=fov )

	!p.multi=[0,2,1]
	plot_map, mapa_grades, /cbar, dmin=0., dmax=0.02
	plot_map, mapa_rates, dmin=0., dmax=0.02
	!p.multi=0
;	plot_map, mapa_unphysical, /cbar

	filename1 = 'out_files/map_FPMA_pileup_from_grades'
	filename2 = 'out_files/map_FPMA_unphysical_grades'
	filename3 = 'out_files/map_FPMA_pileup_from_rates'

	; Save results for FPMA

	if not file_exist('out_files') then spawn, 'mkdir out_files'
	if keyword_set( TR ) then begin
		tr_string = strmid(anytim(tr,/yo),10,8)
		filename1 += '_'+tr_string[0]+'_'+tr_string[1]
		filename2 += '_'+tr_string[0]+'_'+tr_string[1]
		filename3 += '_'+tr_string[0]+'_'+tr_string[1]
	endif
	filename1 += '.fits
	filename2 += '.fits
	filename3 += '.fits

	map2fits, mapa_grades, filename1
	map2fits, mapa_unphysical, filename2
	map2fits, mapa_rates, filename3


	;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	; Make maps for FPMB
	if keyword_set( XFLIP ) then evtx = (npix - evtb.x)-xshf else evtx=evtb.x-xshf
	evty=evtb.y-yshf

	; bug fix to deal with case that there is only 1 event.
	if n_elements( evtx ) eq 1 then begin
		evtx = [evtx]
		evty = [evty]
	endif
	
	if not keyword_set( CEN ) then begin
		cen = fltarr( 2 )
		cen[0] = (median(evtx)-npix/2)*pix_size
		cen[1] = (median(evty)-npix/2)*pix_size
	endif
	
	im_hist = hist_2d( evtx, evty, min1=0, min2=0, max1=npix-1, max2=npix-1, bin1=1, bin2=1 )
	im_hist_grd0 = hist_2d( evtx[i_evtb_grd0], evty[i_evtb_grd0], min1=0, min2=0, max1=npix-1, max2=npix-1, bin1=1, bin2=1 )
	im_hist_grd2 = hist_2d( evtx[i_evtb_grd2], evty[i_evtb_grd2], min1=0, min2=0, max1=npix-1, max2=npix-1, bin1=1, bin2=1 )

	; I'd like these images in 12.3 arcsec bins.
	; The factor of 25 is to keep the total of the histograms accurate.
	im_hist = rebin( 25*float(im_hist), npix/5, npix/5 )
	im_hist_grd0 = rebin( 25*float(im_hist_grd0), npix/5, npix/5 )
	im_hist_grd2 = rebin( 25*float(im_hist_grd2), npix/5, npix/5 )

	datB = 0.25*im_hist_grd2/im_hist_grd0

	dur=anytim(t2b)-anytim(t1b)
	time=t1b
	ang = pb0r(t1b,/arcsec,l0=l0)

	; This is the pileup map computed from the grades.
	mapb_grades = make_map( datB, dx=pix_size*5, dy=pix_size*5, time=time, dur=dur, $
			 				id='FPMB est pileup from grades', l0=l0,b0=ang[1],rsun=ang[2])
	mapb_grades= make_submap( mapb_grades, cen=cen, fov=fov )
	
	; Also do one with just the unphysical grades, for reference.
	mapb_unphysical = make_map( im_hist_grd2, dx=pix_size*5, dy=pix_size*5, time=time, $
								dur=dur, id='FPMB unphysical grades', l0=l0,b0=ang[1],rsun=ang[2])	
	mapb_unphysical= make_submap( mapb_unphysical, cen=cen, fov=fov )
  
	; Now do the one from the estimated rate. Apply the livetime correction
	imb_lvt=im_hist/(float(lvtcorb)*dur)
	pileup_window = 8.e-6
	prob = 1.-exp(-pileup_window*imb_lvt)

	mapb_rates = make_map( prob, dx=pix_size*5, dy=pix_size*5, time=time, dur=dur, $
						   id='FPMB est pileup from rates', l0=l0,b0=ang[1],rsun=ang[2])
	mapb_rates= make_submap( mapb_rates, cen=cen, fov=fov )

	!p.multi=[0,2,1]
	plot_map, mapb_grades, /cbar, dmin=0., dmax=0.02
	plot_map, mapb_rates, dmin=0., dmax=0.02
	!p.multi=0
;	plot_map, mapb_unphysical, /cbar

	filename1 = 'out_files/map_FPMB_pileup_from_grades'
	filename2 = 'out_files/map_FPMB_unphysical_grades'
	filename3 = 'out_files/map_FPMB_pileup_from_rates'

	; Save results for FPMB

	if not file_exist('out_files') then spawn, 'mkdir out_files'
	if keyword_set( TR ) then begin
		tr_string = strmid(anytim(tr,/yo),10,8)
		filename1 += '_'+tr_string[0]+'_'+tr_string[1]
		filename2 += '_'+tr_string[0]+'_'+tr_string[1]
		filename3 += '_'+tr_string[0]+'_'+tr_string[1]
	endif
	filename1 += '.fits
	filename2 += '.fits
	filename3 += '.fits

	map2fits, mapb_grades, filename1
	map2fits, mapb_unphysical, filename2
	map2fits, mapb_rates, filename3

  if keyword_set( stop ) then stop

end