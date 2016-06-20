FUNCTION AR_TRACKER, AR, DATE_IN, DBEFORE, DAFTER, GOES=GOES, RHESSI=RHESSI, $
                     NOAA=NOAA, STOP=STOP, QUIET=QUIET, FLARE_LIST=FLARE_LIST

  ; NOTE: AR works best as a 4-digit number.  Leave off the first digit!
  ; Requires ID_NAR.pro
  ; Right now if RHESSI and GOES are both chosen, some flares are double-counted.
  ; This should be fixed later.
  ; Need to resolve issue with units for NAR area and long_ext.
  ; Who to ask?
  ; Issue: the "HIGH" and "LOW" tracks may not be working correctly.

  default, dbefore, 22
  default, dafter, 22

  ; establish which data sources we are using.
  source = [0,0,0]
  if keyword_set(goes)   then source[0]=1
  if keyword_set(rhessi) then source[1]=1
  if keyword_set(noaa)   then source[2]=1
  ; if no source is set, make RHESSI the default.
  if total(source) eq 0 then begin
     source[1]=1
     print, 'No source specified; defaulting to RHESSI data.'
  endif

  ; establish date/time boundaries t1,t2 for data gathering.
  date = anytim(date_in)
  t0 = anytim( date-dbefore*24*3600.,/yo )
  t1 = anytim( date+dafter*24*3600.,/yo )

  ; First get the GOES events.
  if source[0] eq 1 then begin
     if not keyword_set(quiet) then $
        print, 'Checking GOES data for AR '+strtrim( AR,2),  $
               ' in time interval ', anytim([t0,t1],/yo)
     rd_gev, t0, t1, gev_data
     if is_struct(gev_data) eq 0 then begin
        print, 'No GOES events found in time range.'
     endif else begin
        list=where(gev_data.noaa eq ar, count)
        if count eq 0 then begin
           print, 'No gev events in given active region.'
        endif else begin
           gev_time = anytim( gev_data[list] )
           gev_loc  = gev_data[list].location[0]
           gev_class= string(gev_data[list].ST$CLASS)
        endelse
     endelse
  endif

  ; Next, the RHESSI events!
  if source[1] eq 1 then begin
     if not is_struct( flare_list ) then begin
        if not keyword_set(quiet) then $
           print, 'Checking RHESSI flarelist for AR '+strtrim( AR,2),  $
                  ' in time interval ', anytim([t0,t1],/yo)
        flare_list_obj =  hsi_flare_list(obs_time_interval= anytim([t0,t1], /ecs))
        flare_list =  flare_list_obj -> getdata(/quiet)
     endif
     if is_struct(flare_list) eq 0 then begin
        print, 'No RHESSI flares found in time range.'
     endif else begin
        ; Associate each flare with a NOAA AR.
        closest_ar = intarr(n_elements(flare_list))
        for i=0, n_elements(flare_list)-1 do $
           closest_ar[i]=id_nar(flare_list[i].peak_time, flare_list[i].position )
;stop
	   if ar eq 12403 then closest_ar=intarr(n_elements(flare_list))+12403
	   if ar eq 2403 then closest_ar=intarr(n_elements(flare_list))+2403
        list=where(closest_ar eq ar, count)
        if count eq 0 then begin
           print, 'No RHESSI flares in given active region.'
        endif else begin
           hsi_time = anytim( flare_list[list].peak_time )
           hsi_loc = fltarr( n_elements(list) )
           for j=0, n_elements(list)-1 do $
              hsi_loc[j] = (arcmin2hel(flare_list[list[j]].position[0]/60., $
                                       flare_list[list[j]].position[1]/60., $
                                       date=flare_list[list[j]].peak_time))[1]
           hsi_class= flare_list[list].goes_class
        endelse
     endelse
  endif

  ; Finally, we check the NOAA daily records of AR locations.
  ; This gives positions and widths of the AR itself, not flares
  if source[2] eq 1 then begin
     if not keyword_set(quiet) then $
        print, 'Retrieving NOAA position records for AR '+strtrim( AR,2),  $
               ' in time interval ', anytim([t0,t1],/yo)
     nar = get_nar(t0,t1,/quiet)
     if is_struct(nar) eq 0 then begin
        print, 'No NOAA records in time range.'
        return, -1
     endif
     list=where(nar.noaa eq ar, count)
     if count eq 0 then begin
        print, 'No NOAA matches for given active region.'
        return, -2
     endif
     nar_time = anytim( nar[list] )
     nar_loc  = nar[list].location[0]
     nar_long_ext = nar[list].long_ext
  endif

  ; Put data together into one set for fitting.
  evt_time = 0.
  evt_loc  = 0.
  evt_class=''
  evt_long_ext = 0.
  if exist(gev_time) then begin
     evt_time = [evt_time,gev_time]
     evt_loc  = [evt_loc, gev_loc]
     evt_class= [evt_class,gev_class]
     evt_long_ext = [evt_long_ext,fltarr(n_elements(gev_time))]
  endif
  if exist(hsi_time) then begin
     evt_time = [evt_time,hsi_time]
     evt_loc  = [evt_loc, hsi_loc]
     evt_class= [evt_class,hsi_class]
     evt_long_ext = [evt_long_ext,fltarr(n_elements(hsi_time))]
  endif
  if exist(nar_time) then begin
     evt_time = [evt_time,nar_time]
     evt_loc  = [evt_loc, nar_loc]
     evt_class= [evt_class,replicate('',n_elements(nar_time))]
     evt_long_ext = [evt_long_ext,nar_long_ext]
  endif

  if n_elements(evt_time) lt 2 then begin
     print, 'Not enough events found in given range for desired data sources.'
     return, -1
  endif

  ; remove the placeholder first index
  n = n_elements(evt_time)
  evt_time  = evt_time[1:n-1]
  evt_loc   = evt_loc[1:n-1]
  evt_class = evt_class[1:n-1]
  evt_long_ext = evt_long_ext[1:n-1]

  ; Compute a track for the AR.
  xxxx = evt_time - evt_time[0]
  yyyy = evt_loc
  coeff = 0.
  xrange = 0.
  yrange = 0.
  xrange_lo = 0.
  xrange_hi = 0.
  glist = where( abs(yyyy) lt 90 )
  if n_elements(glist) gt 1 then begin
     fast_regression, xxxx[glist], yyyy[glist], fy=fy, coeff=coeff, /silent
     tr_fit = anytim([ t0, t1 ])
     yrange = [-180., 180.]
     xrange = (yrange-coeff[0])/coeff[1] + evt_time[0]

    ; Compute tracks based on the AR finite size.
    ; This only uses NOAA info, not the others.
     xrange_lo = xrange
     xrange_hi = xrange
     yyyy = evt_loc-evt_long_ext/2.
     glist = where( abs(yyyy) lt 90 and evt_long_ext gt 0 )
     if total(glist) gt 0 then begin
        fast_regression, xxxx[glist], yyyy[glist], fy=fy, coeff=coeff1, /silent
        xrange_lo = (yrange-coeff1[0])/coeff1[1] + evt_time[0]
        yyyy = evt_loc+evt_long_ext/2.
        glist = where( abs(yyyy) lt 90 and evt_long_ext gt 0)
        fast_regression, xxxx[glist], yyyy[glist], fy=fy, coeff=coeff2, /silent
        xrange_hi = (yrange-coeff2[0])/coeff2[1] + evt_time[0]
     endif
  endif

;  utplot, evt_time, evt_loc, /psy, yr=[-90,90]  
;  outplot, evt_time[glist], evt_loc[glist]-evt_long_ext/2., /psy, col=1
;  outplot, evt_time[glist], evt_loc[glist]+evt_long_ext/2., /psy, col=2

  ; Return track and event information.
  track = {time:evt_time, longitude:evt_loc, class:evt_class, long_ext:evt_long_ext, $
           fit_coeff:coeff, fit_xr:xrange, fit_yr:yrange, fit_xr_lo:xrange_lo, $
           fit_xr_hi:xrange_hi}

  if keyword_set(stop) then stop

  return, track

END
