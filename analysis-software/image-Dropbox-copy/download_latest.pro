; This procedure uses the VSO to download the latest-available image from the 
; specified observatory.

PRO	download_latest, instr=instr, wave=wave

default, instr, 'AIA'
default, wave, 94

; Get current time in UTC
get_utc, utc
t = anytim(utc)

for i=0, 24*10. do begin
	window = t-[i+1,i]*3600.
	vso = vso_search( anytim(window[0],/yo),anytim(window[1],/yo), instr=instr, $
		wave=wave, count=count )
	if count gt 0 then begin
		files=vso_get( vso[count-1] )
		break
	endif
end

END
