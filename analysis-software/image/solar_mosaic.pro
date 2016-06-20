pro solar_mosaic, obs_list, filestem, topdir=topdir

	; TOPDIR is the top-level directory in which all the data directories are located.

	default, topdir, './'
	outfile = filestem+'.evt'

	for obs = 0, n_elements(obs_list) -1 do begin
   datpath = file_search( topdir+obs_list[obs]+'/*', /test_dir)
   	if n_elements( DATPATH ) gt 1 then $			; allows for two different dir structures.
   		datpath = file_search( topdir+obs_list[obs]+'/', /test_dir)
		evtfiles = file_search(datpath+'/event_cl/', '*06_cl_sunpos.evt')
	   for i = 0, n_elements(evtfiles) -1 do begin
	      print, evtfiles[i]
	      evt=mrdfits(evtfiles[i],1,evth)

	      push, all_evt, evt
   
	   endfor
	endfor

	mwrfits, all_evt, outfile, evth, /create   

end
