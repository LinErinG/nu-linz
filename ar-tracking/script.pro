;;; Make the month directories
.r
for i=1,12 do begin
	if i lt 10 then istr = '0'+strtrim(i,2) else istr = strtrim(i,2)
	spawn, 'mkdir '+istr
endfor
end

;;; Make the day directories
.r
for i=1,12 do begin
	for j=1,31 do begin
		if i eq 2 then if j gt 28 then continue
		if i eq 4 or i eq 6 or i eq 9 or i eq 11 then if j gt 30 then continue
		if i lt 10 then istr = '0'+strtrim(i,2) else istr = strtrim(i,2)
		if j lt 10 then jstr = '0'+strtrim(j,2) else jstr = strtrim(j,2)

	spawn, 'mkdir '+istr+'/'+jstr
	endfor
endfor
end

.r
for j=1,23 do begin
	if j lt 10 then jstr = '0'+strtrim(j,2) else jstr = strtrim(j,2)
	date = '2015-01-'+jstr
	;print, date
	ar_tracker_all, date, /write
endfor
end
	