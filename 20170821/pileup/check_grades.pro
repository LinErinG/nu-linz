PRO check_grades, path, tr=tr, b=b, stop=stop

	cl_file = path+'/event_cl/nu*A06_cl_sunpos.evt'
	if keyword_set( B ) then cl_file = path+'/event_cl/nu*B06_cl_sunpos.evt'
	evt = mrdfits(cl_file, 1,evth)

	ind = where( evt.grade eq 0 )
	print
	print, 'Whole EVT file: '
	print, '    ', n_elements( IND ), ' evts GRADE 0'
	ind = where( evt.grade eq 21 or evt.grade eq 22 or evt.grade eq 23 or evt.grade eq 24)
	print, '    ', n_elements( IND ), ' evts GRADES 21-24'

  if keyword_set( TR ) then begin
	  evt_utc = anytim( convert_nustar_time( evt.time, /fits) )
	  evt = evt[ where( evt_utc gt anytim(tr[0]) and evt_utc lt anytim(tr[1]) ) ]
	endif

	ind = where( evt.grade eq 0 )
	print
	print, 'Within time range '
	ptim, tr
	print, '    ', n_elements( IND ), ' evts GRADE 0'
	ind = where( evt.grade eq 21 or evt.grade eq 22 or evt.grade eq 23 or evt.grade eq 24)
	print, '    ', n_elements( IND ), ' evts GRADES 21-24'

	evt = evt[ where( EVT.PI ne -10 ) ]

	ind = where( evt.grade eq 0 )
	print
	print, 'Not marked bad event (evt.pi ne -10): '
	print, '    ', n_elements( IND ), ' evts GRADE 0'
	ind = where( evt.grade eq 21 or evt.grade eq 22 or evt.grade eq 23 or evt.grade eq 24)
	print, '    ', n_elements( IND ), ' evts GRADES 21-24'
	
	if keyword_set( STOP ) then stop

END