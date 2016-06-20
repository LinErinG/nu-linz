PRO ar_tracker_loop, day1, n_days, write=write

  for i=0, n_days-1 do begin

     date = anytim( anytim( day1 ) + i*24.*3600., /yo )
     ar_tracker_all, date, write=write

  endfor

end
