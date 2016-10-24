;
; Procedure corrects a DS9 region file for extra pointing drift.
; An alignment file showing the necessary alignments to correct the NuSTAR pointing 
; is required.
; The procedure assumes that the region is denoted by a circle( RA_cen, dec_cen, radius )
; with coordinates in RA, DEC decimal form.
;
; INDIR and OUTDIR are for the region file.  Alignment file can include a directory 
; path if desired.  A template is necessary to read in the alignment file.
;
;
; example:
;	time_new = '2015-09-01 04:06:30'
;	time_ref = '2015-09-01 04:00:15'
;	align_file = 'regions/20150901_alignment_aiafexviii_v20161019.txt'
;	indir = 'regions/'
;	nustar_adjust_region, time_new, time_ref, 'regA_peak.reg', align_file, indir=indir
;	nustar_adjust_region, time_new, time_ref, 'regB_peak.reg', align_file, indir=indir
;
;	HISTORY:
;		2016/10/23	LG created routine.

pro	nustar_adjust_region, time_new, time_ref, region_file, align_file, $
	indir=indir, outdir=outdir, template_file=template_file, $
	new_filename=new_filename, stop=stop

	default, indir, './'
	default, outdir, indir
	default, template_file, 'regions/template.sav'
	default, new_filename, strmid( region_file, 0, strpos( region_file, '.reg' ))+'_adjusted.reg'

	tref = time_ref
	tnew = time_new
	
	align=0
	if keyword_set( ALIGN_FILE ) then if file_exist( ALIGN_FILE ) then align=1

	if align eq 0 then begin
		print, 'Alignment file not found.  ADJUSTING FOR SOLAR DRIFT ONLY.'
		xref = 0.
		yref = 0.
		xnew = 0.
		ynew = 0.
	endif else begin

		; Get the alignments from file.
		if file_search(template_file) eq '' then begin
			print, 'Template file not found.'
			return
		endif
		restore, template_file
		offsets = read_ascii( ALIGN_FILE, tem=template)
		time = anytim(offsets.date+' '+offsets.time)

		; Find the alignment for a given time wrt to the reference time.
		xref = interpol( offsets.x, time, anytim(tref) )
		yref = interpol( offsets.y, time, anytim(tref) )
		xnew = interpol( offsets.x, time, anytim(tnew) )
		ynew = interpol( offsets.y, time, anytim(tnew) )

	endelse

	; Use nustar_sunpoint to translate the difference to RA and DEC
	coord_ref = nustar_sunpoint( [xref,yref], time=tnew )
	coord_new = nustar_sunpoint( [xnew,ynew], time=tref )
	delta = coord_ref - coord_new

	; Read in the entire region file to be altered.
	openr, lun, indir+region_file, /get_lun
	temp=''
	text=''
	while ~ EOF(lun) do begin
		readf, lun, temp
		push, text, temp
	endwhile
	close, lun
	free_lun, lun

	; Find any lines that include a circle.
	; Substitute the updated coordinates for the older ones.
	text2 = text
	for i=0, n_elements(text2)-1 do begin
		if strpos( text2[i], 'circle' ) eq -1 then continue
;		print, text2[i]
		string = text2[i]
		strput, string, strtrim( double( strmid(text2[i],7,9) ) + delta[0], 2 ), 7
		strput, string, strtrim( double( strmid(text2[i],17,9) ) + delta[1], 2 ), 17
		text2[i] = string
;		print, text2[i]
	endfor

	if keyword_set( STOP ) then stop

	; Write a new file with the updated info.
	openw,lun, outdir+new_filename, /get_lun
	for i=0, n_elements( text2)-1 do printf, lun, text2[i]
	close, lun
	free_lun, lun
	
END
