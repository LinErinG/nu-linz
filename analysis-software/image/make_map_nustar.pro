PRO 	make_map_nustar, obsid, maindir=maindir, shift=shift, $
  		grdid=grdid, erang=erang, plot=plot, stop=stop, $
  		tr=tr, chu_select=chu_select, major_chu=major_chu, $
  		cen=cen, fov=fov, xflip=xflip, no_live=no_live

  ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ;  Make the map in a given energy range for orbit 4 data in FPMA and FPMB
  ;         Filter out "bad" pixels in FPMA		(Note: temporarily disabled; should fix this.)
  ;         Filter to only one CHU combination
  ;         Filter by grade; GRADE 0 minimizes pileup
  ;         Get the livetime correction per FPM
  ;         Make the map
  ;         Plot the map
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
  ;         grdid   0,1,2 for Event grade 0, all or 21-24
  ;         erang   Energy range covered by the map, if only 1 elements then >erang
  ;                  (default is >2 keV)
  ;         plot    Want to plot the maps? (default no)
  ;					tr			time range for map
  ;					major_chu		Use whichever CHU combo is most prevalent in the time range.
  ;					chu_select	Specific CHU combo to use.  Can either be a string of the 
  ;											CHUs you want (e.g. "123") or an integer that is the 
  ;											sum-of-squares (e.g. 14 for "123").
  ;					cen			Center in arcsec for the map.  Defaults to data median
  ;					fov			FOV in arcmin for the map.  Default 15 arcmin
  ;					xflip		Flip X axis.  When working with old data this might be necessary.
  ;									Default don't flip.  (Should be done already in solar conversion.)
  ;					no_live	Do not apply livetime correction, and just return data in counts observed.
  ;
  ;
  ; 14-May-2016 LG		Added keyword NO_LIVE to return un-livetime-corrected data.
	; 05-Mar-2016	LG		Adapted to more general case
  ; 09-Nov-2015 IGH
  ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	default, shift, [0.,0.]
	default, fov, 15
	default, maindir, './'
	
	ddname=obsid

	; Grade selection
  if (n_elements(grdid) ne 1) then grdid=0
  grdname='GRD'+string(grdid,format='(i1)')
  ; Only want single pixel hit: grade 0
  if (grdid eq 0) then grdrn=[0,0]
  ; Want all the grades: grade =>0
  if (grdid eq 1) then grdrn=[0,32]
  ; Want just the corner second pixel hits: grade 21 to 24
  if (grdid eq 2) then grdrn=[21,24]

  if (n_elements(erang) lt 1 or n_elements(erang) gt 2) then erang =2
  if (n_elements(erang) eq 1) then begin
    emin=erang
    emax=100.
    eid='>'+strcompress(string(erang,format='(i2)'),/rem)+' keV'
    enme='EG'+strcompress(string(erang,format='(i2)'),/rem)
  endif
  if (n_elements(erang) eq 2) then begin
    emin=erang[0]
    emax=erang[1]
    eid=strcompress(string(erang[0],format='(i2)'),/rem)+'-'+$
      strcompress(string(erang[1],format='(i2)'),/rem)+' keV'
    enme='E'+strcompress(string(erang[0],format='(i2)'),/rem)+'_'+$
      strcompress(string(erang[1],format='(i2)'),/rem)
  endif

	; specify CHU_NUM and CHU_STR, based on the CHU selection given.
	if keyword_set( CHU_SELECT ) then begin
		if isa( chu_select, /string ) then begin
			if strlen(chu_select) eq 1 then chu_num = (fix(chu_select))^2 else begin
				case chu_select of
			  	'12':  chu_num = 5
			  	'13':  chu_num = 10
		  		'23':  chu_num = 13
		  		'123': chu_num = 14
			  	else: begin
			  		print, 'Not a valid CHU combo'
			  		return
		  		end
				endcase
			endelse
			chu_str = chu_select
		endif else begin
			if chu_select eq 1 or chu_select eq 4 or chu_select eq 9 then $
					chu_str = strtrim( fix( sqrt( chu_select ) ), 2 ) else begin
				case chu_select of
			  	5:  chu_str = '12'
			  	10: chu_str = '13'
		  		13: chu_str = '23'
		  		14: chu_str = '123'
			  	else: begin
			  		print, 'Not a valid CHU combo'
			  		return
		  		end
				endcase
			endelse
			chu_num = chu_select
		endelse
		chumask = chu_num
	endif


  ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ; Get the *_cl_sunpost.evt files

  cla_file=maindir+ddname+'/event_cl/nu'+ddname+'A06_cl_sunpos.evt'
  evta = mrdfits(cla_file, 1,evtah)

  clb_file=maindir+ddname+'/event_cl/nu'+ddname+'B06_cl_sunpos.evt'
  evtb = mrdfits(clb_file, 1,evtbh)

	;;;; HAVE NOT DONE ANY FILTERING FOR BAD PIXELS!  should reimplement this.
;  ; Before doing anything else need to filter out the "bad" pixels in FPMA
;  ; these were the ones BG had previously identified - caused the "hard knots" in the data
;  ; https://github.com/NuSTAR/nustar_solar/blob/master/solar_mosaic_20141211/combine_events.pro
;
;  use = bytarr(n_elements(evta)) + 1
;  thisdet = where(evta.det_id eq 2)
;  badones = where(evta[thisdet].rawx eq 16 and evta[thisdet].rawy eq 5, nbad)
;  if nbad gt 0 then use[thisdet[badones]]=0
;  badones = where(evta[thisdet].rawx eq 24 and evta[thisdet].rawy eq 22, nbad)
;  if nbad gt 0 then use[thisdet[badones]]=0
;
;  thisdet = where(evta.det_id eq 3)
;  badones = where(evta[thisdet].rawx eq 22 and evta[thisdet].rawy eq 1, nbad)
;  if nbad gt 0 then use[thisdet[badones]]=0
;  badones = where(evta[thisdet].rawx eq 15 and evta[thisdet].rawy eq 3, nbad)
;  if nbad gt 0 then use[thisdet[badones]]=0
;  badones = where(evta[thisdet].rawx eq 0 and evta[thisdet].rawy eq 15, nbad)
;  if nbad gt 0 then use[thisdet[badones]]=0
;
;  evta=evta[where(use)]


  ; Do the time selection.
  if keyword_set( TR ) then begin  
  	tr_nu = convert_nustar_time( anytim(tr,/vms), /from_ut )
	  evta = evta[ where( evta.time gt tr_nu[0] and evta.time lt tr_nu[1] ) ]
	  evtb = evtb[ where( evtb.time gt tr_nu[0] and evtb.time lt tr_nu[1] ) ]
	endif

	; Check that some data remains after these cuts.
	if n_elements( EVTA ) lt 2 or n_elements( EVTB ) lt 2 then begin
		print, 'Not enough events in time interval'
		return
	endif


  ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ; Filter on CHU combination
  ; Based on https://github.com/NuSTAR/nustar_solar/blob/master/solar_mosaic_20141211/solar_mosaic_hk.pro

  chufile = file_search(maindir+ddname+'/hk/', '*chu123.fits')
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

  ; make time binning of chus to evt data
  achu_comb = round(interpol(mask, chu.time, evta.time))
  bchu_comb = round(interpol(mask, chu.time, evtb.time))

	; The MAJOR_CHU option will find the most prevalent CHU combo and use that one.
	; It determines major_chu only from FPMA (which should be fine).
	if keyword_set( MAJOR_CHU ) then begin
		chu_hist=histogram( achu_comb, loc=loc )
		max = max( CHU_HIST, max_index )		
		chumask = loc[max_index]
		print, 'Most prevalent CHU combo is ', chumask
	endif

	; If no CHU selection has been input, then output a plot for choosing it.
	if not keyword_set( CHUMASK ) then begin
		plot, evta.time, achu_comb, /psy
		chumask = 0
		print
		read, 'Enter desired CHU code: ', chumask
		print
	endif

	; Set chu_str again to cover all cases.
	chu_num = chumask
	if chu_num eq 1 or chu_num eq 4 or chu_num eq 9 then $
			chu_str = strtrim( fix( sqrt( chu_num ) ), 2 ) else begin
		case chu_num of
	  	5:  chu_str = '12'
	  	10: chu_str = '13'
  		13: chu_str = '23'
  		14: chu_str = '123'
	  	else: begin
	  		print, 'Not a valid CHU combo'
	  		return
  		end
		endcase
	endelse

  ; filter out bad CHUs and the requested grades
  ida2=where(achu_comb eq chumask and evta.grade ge grdrn[0] and evta.grade le grdrn[1])
  evta=evta[ida2]
  a_engs=1.6+0.04*evta.pi

  idb2=where(bchu_comb eq chumask and evtb.grade ge grdrn[0] and evtb.grade le grdrn[1])
  evtb=evtb[idb2]
  b_engs=1.6+0.04*evtb.pi
  
  ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ; Only want the counts in energy range
  ida2=where(a_engs ge emin and a_engs lt emax)
  evta=evta[ida2]
  a_engs=1.6+0.04*evta.pi

  idb2=where(b_engs ge emin and b_engs lt emax)
  evtb=evtb[idb2]
  b_engs=1.6+0.04*evtb.pi

  if ida2[0] eq -1 or idb2[0] eq -1 then begin
  	print, 'No events fit criteria for one (or more) modules'
  	return
  endif

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
  ; Do FPMA
  engs=a_engs
  if keyword_set( XFLIP ) then evtx = (npix - evta.x)-xshf else evtx=evta.x-xshf
  evty=evta.y-yshf

	; bug fix to deal with case that there is only 1 event.
	if n_elements( evtx ) eq 1 then begin
		evtx = [evtx]
		evty = [evty]
	endif
	
  im_hist = hist_2d( evtx, evty, min1=0, min2=0, max1=npix-1, max2=npix-1, bin1=1, bin2=1 )
  
  dur=anytim(t2a)-anytim(t1a)
  time=t1a
  ang = pb0r(t1a,/arcsec,l0=l0)

  ima2_lvt=im_hist/(float(lvtcora)*dur)
  
	; Apply the livetime correction (or not, if keyword /no_live)
  if keyword_set(no_live) then begin
  	datA = im_hist
  	idA = 'FPMA CHU'+chu_str+' '+grdname+' counts'
		filename = 'out_files/map_CHU'+chu_str+'_'+grdname+'_'+enme+'_FPMA_no_live'
  endif else begin
		datA = ima2_lvt
  	idA = 'FPMA CHU'+chu_str+' '+grdname+' '+eid+string(lvtcora*100,format='(f6.2)')+'%'
		filename = 'out_files/map_CHU'+chu_str+'_'+grdname+'_'+enme+'_FPMA'
  endelse

  mapa = make_map( datA, dx=pix_size, dy=pix_size, time=time, dur=dur, $
  			 					 id=idA, l0=l0,b0=ang[1],rsun=ang[2])

	if not keyword_set( CEN ) then begin
		cen = fltarr( 2 )
		cen[0] = (median(evtx)-npix/2)*pix_size
		cen[1] = (median(evty)-npix/2)*pix_size
	endif
	
	mapa= make_submap( mapa, cen=cen, fov=fov )


	; Save results for FPMA

	if not file_exist('out_files') then spawn, 'mkdir out_files'
	if keyword_set( TR ) then begin
		tr_string = strmid(anytim(tr,/yo),10,8)
		filename += '_'+tr_string[0]+'_'+tr_string[1]
	endif
	filename += '.fits

  map2fits, mapa, filename


  ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ; Do FPMB
  engs=b_engs
  if keyword_set( XFLIP ) then evtx = (npix - evtb.x)-xshf else evtx=evtb.x-xshf
  evty=evtb.y-yshf

	; bug fix to deal with case that there is only 1 event.
	if n_elements( evtx ) eq 1 then begin
		evtx = [evtx]
		evty = [evty]
	endif
	
  im_hist = hist_2d( evtx, evty, min1=0, min2=0, max1=npix-1, max2=npix-1, bin1=1, bin2=1 )

  dur=anytim(t2b)-anytim(t1b)
  time=t1b
  ang = pb0r(t1b,/arcsec,l0=l0)

  imb2_lvt=im_hist/(float(lvtcorb)*dur)

	; Apply the livetime correction (or not, if keyword /no_live)
  if keyword_set(no_live) then begin
  	datB = im_hist
  	idB = 'FPMB CHU'+chu_str+' '+grdname+' counts'
		filename = 'out_files/map_CHU'+chu_str+'_'+grdname+'_'+enme+'_FPMB_no_live'
  endif else begin
		datB = imb2_lvt
  	idB = 'FPMB CHU'+chu_str+' '+grdname+' '+eid+string(lvtcorb*100,format='(f6.2)')+'%'
		filename = 'out_files/map_CHU'+chu_str+'_'+grdname+'_'+enme+'_FPMB'
  endelse

  mapb = make_map( datB, dx=pix_size, dy=pix_size, time=time, dur=dur, $
  			 					 id=idB, l0=l0,b0=ang[1],rsun=ang[2])

	if not keyword_set( CEN ) then begin
		cen = fltarr( 2 )
		cen[0] = (median(evtx)-npix/2)*pix_size
		cen[1] = (median(evty)-npix/2)*pix_size
	endif

	mapb= make_submap( mapb, cen=cen, fov=fov )


	; Save results for FPMB

	if keyword_set( TR ) then begin
		tr_string = strmid(anytim(tr,/yo),10,8)
		filename += '_'+tr_string[0]+'_'+tr_string[1]
	endif
	filename += '.fits

  map2fits, mapb, filename
  
  
  ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if keyword_set(plot) then begin
    loadct,39,/silent
    !p.multi=[0,2,1]
    plot_map,mapa,/log,chars=1.5,tit=mapa.id,/limb,grid_spacing=15
    plot_map,mapb,/log,chars=1.5,tit=mapb.id,/limb,grid_spacing=15
    !p.multi=0
  endif

  if keyword_set( stop ) then stop

end