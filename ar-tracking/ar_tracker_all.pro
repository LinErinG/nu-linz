;+
; NAME:
;    AR_TRACKER_ALL
; PURPOSE:
;    Performs active region tracking to estimate longitude of flaring
;    part of AR at a given time.  _ALL version includes tracks of
;    all ARs present on a given day, for reference.
; CATEGORY:
;    NuSTAR solar observation support
; CALLING SEQUENCE:
;    A standard call to produce AR tracking plots for NuSTAR
;    tohban purposes is:
;    IDL> ar_tracker_all, '2014-07-07', /write
; INPUTS:
;    date_in:  Perform analysis for ARs on this day
; OPTIONAL (KEYWORD) INPUT PARAMETERS:
;    dbefore:  # earlier days for track computation (default 22)
;    dafter:   # later days for track computation (default 1)
;              For looking at historical data, this could be varied.
;    write:    If set, write plots to public directories.
; OUTPUTS:
;    none
; INTERNAL CALLS:
;    Nonstandard routines needed are:
;        ar_tracker.pro (linz)
;        id_nar.pro (linz)
; SIDE EFFECTS:
; RESTRICTIONS:
; MODIFICATION HISTORY:
;   2014-Jul-9, LG, Changing data source for track calculation to NOAA
;               AR center instead of flare sites.
;   2014-Jul-5, LG, Adapted previous versions for NuSTAR obs support.
;-

PRO AR_TRACKER_ALL, DATE_IN, DBEFORE=DBEFORE, DAFTER=DAFTER, WRITE=WRITE, $
                    STOP=STOP, PLOT_FILE=PLOT_FILE

  default, dbefore, 22
  default, dafter, 1

  ; check NOAA records for all ARs present on this date.
  date = anytim(date_in)
  t0 = anytim( date-24*3600.,/yo )
  t1 = anytim( date+24*3600.,/yo )
  nar = get_nar(t0,t1, /quiet)
  if is_struct(nar) eq 0 then begin
     print, 'No active regions found in NOAA database.'
     print, 'Directory checked was ', getenv('DIR_GEN_NAR')
     return
  endif

  temp = nar.noaa
;  temp=2403 
 ar_list = temp[uniq(temp, sort(temp))]
  print
  print, 'Analyzing date ', anytim(date_in,/yoh)
  print
  print, 'Found NOAA active regions:'
  print, ar_list
  print

  ; get RHESSI flarelist for this time period so we don't have to
  ; keep generating it for each AR.  (Time saver)
  flare_list_obj =  hsi_flare_list(obs_time_interval= anytim([t0,t1], /ecs))
  flare_list =  flare_list_obj -> getdata(/quiet)

  for i=0, n_elements(ar_list)-1 do begin

     ; Get all flare events in this AR.  Ignore NOAA locations for now.
     flares = ar_tracker( ar_list[i], date_in, dbefore, dafter, /goes, /rhessi, $
                        flare_list = flare_list)
     ; Also get the NOAA active region locations.
     noaa = ar_tracker( ar_list[i], date_in, dbefore, dafter, /noaa )

     if is_struct(flares) eq 0 then begin
        print, 'Active region ', ar_list[i], $
               ': No flares found, not generating plot.'
        continue
     endif

;     check = where(abs(noaa.longitude) lt 180)
;     if n_elements(check) lt 2 then begin
     if n_elements(noaa.time) lt 2 then begin
        print, 'Not enough unique records for AR ', ar_list[i], $
               '; not generating plot.'
        continue
     endif

     ; Get flare statistics by day.
     t0_int = anytim(t0)
     t1_int = anytim(t1)
     b2_ind = where(flares.time gt t0_int and flares.time lt t1_int $
                     and strmid(flares.class,0,1) eq 'B' )
     c2_ind = where(flares.time gt t0_int and flares.time lt t1_int $
                     and strmid(flares.class,0,1) eq 'C' )
     m2_ind = where(flares.time gt t0_int and flares.time lt t1_int $
                     and strmid(flares.class,0,1) eq 'M' )
     x2_ind = where(flares.time gt t0_int-24*3600 and flares.time lt t1_int-24*3600 $
                     and strmid(flares.class,0,1) eq 'X' )
     b1_ind = where(flares.time gt t0_int-24*3600 and flares.time lt t1_int-24*3600 $
                     and strmid(flares.class,0,1) eq 'B' )
     c1_ind = where(flares.time gt t0_int-24*3600 and flares.time lt t1_int-24*3600 $
                     and strmid(flares.class,0,1) eq 'C' )
     m1_ind = where(flares.time gt t0_int-24*3600 and flares.time lt t1_int-24*3600 $
                     and strmid(flares.class,0,1) eq 'M' )
     x1_ind = where(flares.time gt t0_int-24*3600 and flares.time lt t1_int-24*3600 $
                     and strmid(flares.class,0,1) eq 'X' )
     b0_ind = where(flares.time gt t0_int-2*24*3600 and flares.time lt t1_int-2*24*3600 $
                     and strmid(flares.class,0,1) eq 'B' )
     c0_ind = where(flares.time gt t0_int-2*24*3600 and flares.time lt t1_int-2*24*3600 $
                     and strmid(flares.class,0,1) eq 'C' )
     m0_ind = where(flares.time gt t0_int-2*24*3600 and flares.time lt t1_int-2*24*3600 $
                     and strmid(flares.class,0,1) eq 'M' )
     x0_ind = where(flares.time gt t0_int-2*24*3600 and flares.time lt t1_int-2*24*3600 $
                     and strmid(flares.class,0,1) eq 'X' )

     if b2_ind[0] ne -1 then nb2=n_elements(b2_ind) else nb2 = 0 
     if c2_ind[0] ne -1 then nc2=n_elements(c2_ind) else nc2 = 0 
     if m2_ind[0] ne -1 then nm2=n_elements(m2_ind) else nm2 = 0 
     if x2_ind[0] ne -1 then nx2=n_elements(x2_ind) else nx2 = 0 
     if b1_ind[0] ne -1 then nb1=n_elements(b1_ind) else nb1 = 0 
     if c1_ind[0] ne -1 then nc1=n_elements(c1_ind) else nc1 = 0 
     if m1_ind[0] ne -1 then nm1=n_elements(m1_ind) else nm1 = 0 
     if x1_ind[0] ne -1 then nx1=n_elements(x1_ind) else nx1 = 0 
     if b0_ind[0] ne -1 then nb0=n_elements(b0_ind) else nb0 = 0 
     if c0_ind[0] ne -1 then nc0=n_elements(c0_ind) else nc0 = 0 
     if m0_ind[0] ne -1 then nm0=n_elements(m0_ind) else nm0 = 0 
     if x0_ind[0] ne -1 then nx0=n_elements(x0_ind) else nx0 = 0 

     if keyword_set(write) then begin
        loadct2,5
        ; construct filename.
        date_string = anytim( date_in, /ccsds )
        date_string = strmid( date_string, 0, 10 )
        yr = strmid( date_string, 0, 4 )
        mn = strmid( date_string, 5, 2 )
        dy = strmid( date_string, 8, 2 )
        filename = date_string+'-AR1'+strtrim(ar_list[i],2)
        popen, filename, xsi=8, ysi=5
     endif

     clear_utplot
     loadct2,5
     utplot, noaa.fit_xr, noaa.fit_yr, yrange=[-180,180], /ysty, yticks=4, $
             title='AR 1'+strtrim(ar_list[i],2), $
             xthick = 2, ythick = 2, thick = 4, charsize = 1.1
     outplot, noaa.fit_xr, [-90,-90], linestyle=2, thick = 2
     outplot, noaa.fit_xr, [90,90],   linestyle=2, thick = 2
     outplot, noaa.fit_xr, 90+[13,13], color=4, linestyle=2, thick=5
     outplot, noaa.fit_xr , 90+[26,26], color=4, linestyle=2, thick=5
     outplot, flares.time, flares.longitude, psym=1, color=2, symsize=2, thick=4
     outplot, noaa.time, noaa.longitude, psym=4, color=160, symsize=0.8, thick=4

     ; Calculate when the track will hit the prime target.
     coeff = noaa.fit_coeff
     deg1 = 90+13
     deg2 = 90+2*13
     time_deg1 = (deg1-coeff[0])/coeff[1] + noaa.time[0]
     time_deg2 = (deg2-coeff[0])/coeff[1] + noaa.time[0]
     time_pre2 = time_deg1-2*24.*3600
     outplot,[anytim(time_deg1),anytim(time_deg1)], [-180,180], color=4, thick=4
     outplot,[anytim(time_deg2),anytim(time_deg2)], [-180,180], color=4, thick=4
     outplot,[anytim(date_in),anytim(date_in)], [-180,180], thick=4, line=1
     outplot,[anytim(time_pre2),anytim(time_pre2)], [-180,180], color=6, thick=4

     ; Put some labels on the bars.
     xyouts, flares.fit_xr[0], 90+14, 'Prime occultation', size=0.8
     xyouts, time_deg1, -155, anytim(time_deg1,/yo)
     xyouts, time_deg2, -170, anytim(time_deg2,/yo)
     xyouts, time_pre2, -130, anytim(time_pre2,/yo)
     xyouts, time_pre2, -115, '2-day warning'

     ; Print flare statistics for last 3 days.
     xyouts, anytim(date_in), -115, strtrim(nb2,2)+'B'
     xyouts, anytim(date_in), -130, strtrim(nc2,2)+'C'
     xyouts, anytim(date_in), -145, strtrim(nm2,2)+'M'
     xyouts, anytim(date_in), -160, strtrim(nx2,2)+'X'
     xyouts, anytim(date_in)-1.*24.*3600., -115, strtrim(nb1,2)
     xyouts, anytim(date_in)-1.*24.*3600., -130, strtrim(nc1,2)
     xyouts, anytim(date_in)-1.*24.*3600., -145, strtrim(nm1,2)
     xyouts, anytim(date_in)-1.*24.*3600., -160, strtrim(nx1,2)
     xyouts, anytim(date_in)-2.*24.*3600., -115, strtrim(nb0,2)
     xyouts, anytim(date_in)-2.*24.*3600., -130, strtrim(nc0,2)
     xyouts, anytim(date_in)-2.*24.*3600., -145, strtrim(nm0,2)
     xyouts, anytim(date_in)-2.*24.*3600., -160, strtrim(nx0,2)

     ; Put on yellow tracks for the other (background) ARs.
     ; keep track of their longitudes at time_deg2
     west = fltarr(n_elements(ar_list))
     arcmin = fltarr(n_elements(ar_list))
     for j=0, n_elements(ar_list)-1 do begin
        if i eq j then continue
        flares = ar_tracker( ar_list[j],date_in,dbefore,dafter, /noaa, /quiet)
        if is_struct(flares) eq 0 then continue
        if n_elements(flares.time) lt 2 then continue
        outplot, flares.fit_xr, flares.fit_yr, color=5, thick=4
        ; keep track of where the closest background AR is.
        west[j] = (time_deg2 - flares.time[0]) *flares.fit_coeff[1] + $
                flares.fit_coeff[0]
        arcmin[j] = (hel2arcmin(0.,west[j],date=date_in))[0]
        ;if west gt 105 then continue
        ;if exist(max_west) eq 0 then begin
        ;   if (west lt 90.) then max_west = west else max_west = 90
        ;endif else begin
        ;   if west lt 90 and west gt max_west then max_west = west
        ;endelse 
        ;print, west, ' ', max_west
     endfor
     if keyword_set(stop) then stop

     ind = where( west gt 105 )
     if ind[0] ne -1 then west[ where(west gt 105) ] = 0.
     if total( where(west ge 90.) ) gt 0 then max_west = 90. else max_west = max(west)
     print, max_west
     arcmin = (hel2arcmin(0.,max_west))[0] - (hel2arcmin(0.,90.))[0]
     xyouts, time_pre2, 150, 'Pointing offset: '+strtrim(arcmin+34,2)+'arcmin'
     undefine, west
     
     ; Compute a "keepout region" that includes 6 arcmin from the limb.
     ; This keepout region needs to be parametrized in longitude.
     rad = (get_rb0p(date_in,/quiet))[0]
     longit_bad = (arcmin2hel( rad/60.-6., 0., date=date_in ))[1]
     corners = [longit_bad, 90+13, 90+13, longit_bad]
     polyfill, [time_deg1,time_deg1,time_deg2,time_deg2], corners, color=3

  if keyword_set(write) then begin
     pclose
     spawn, 'convert '+filename+'.ps '+filename+'.png'
     spawn, 'rm '+filename+'.ps'
     spawn, 'mv '+filename+$
            '.png /home/glesener/public_html/nustar/AR-tracking/plots/'$
            +yr+'/'+mn+'/'+dy+'/'
  endif

  endfor

END
