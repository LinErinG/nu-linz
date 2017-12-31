; Script for doing/checking coalignment of region files.

t_target = '2015-09-01 04:06:30'
time_ref = '2015-09-01 04:00:15'
align_file = 'regions/20150901_alignment_aiafexviii_v20161019.txt'
indir = 'regions/'
outdir = 'regions/temp/'
regA = 'regA_peak.reg'
regB = 'regB_peak.reg'

nustar_adjust_region, t_target, time_ref, regA, align_file, indir=indir, new='regA_0406.reg'
;nustar_adjust_region, t_target, time_ref, regB, align_file, indir=indir, new='test.reg'

; Generate 1-min EVT files for whole 20 minutes.

	data_dir = '~/data/nustar/20150901//20102002001/event_cl/'
	fA=file_search(data_dir+'*A06_cl.evt') 
	fB=file_search(data_dir+'*B06_cl.evt') 
	evta = mrdfits(fA,1,evtah) 
	evtb = mrdfits(fB,1,evtbh) 
	
	tint = anytim('2015-sep-01 0355')+dindgen(21)*60.

.run
for i=0, n_elements(tint)-2 do begin
	tr = tint[i:i+1]
	str = strmid(anytim(tr[0],/vms), 12,2)+strmid(anytim(tr[0],/vms), 15,2)
	tr_nu = convert_nustar_time( anytim(tr,/vms), /from_ut )  
	evta_sub = evta[ where( evta.time gt tr_nu[0] and evta.time lt tr_nu[1] ) ]
	evtb_sub = evtb[ where( evtb.time gt tr_nu[0] and evtb.time lt tr_nu[1] ) ]
	mwrfits, evta_sub, 'evt_1min/nu20102002001A06_cl_'+str+'.evt',evtah,/create  
	mwrfits, evtb_sub, 'evt_1min/nu20102002001B06_cl_'+str+'.evt',evtbh,/create  
endfor
end

; Produce region files corrected for solar drift.	
align_file = ''
outdir = 'regions/correct_solar_drift/'
.run
for i=0, n_elements(tint)-2 do begin
	tr = tint[i:i+1]
	str = strmid(anytim(tr[0],/vms), 12,2)+strmid(anytim(tr[0],/vms), 15,2)
	tavg = anytim( mean( anytim(tr) ), /yo )
	nustar_adjust_region, tavg, time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_'+str+'.reg';,/stop
	nustar_adjust_region, tavg, time_ref, regB, align_file, indir=indir, outdir=outdir, new='regB_'+str+'.reg'
endfor
end

; Produce region files corrected for solar drift AND misalignment.
align_file = 'regions/20150901_alignment_aiafexviii_v20161019.txt'
outdir = 'regions/correct_align/'
.run
for i=0, n_elements(tint)-2 do begin
	tr = tint[i:i+1]
	str = strmid(anytim(tr[0],/vms), 12,2)+strmid(anytim(tr[0],/vms), 15,2)
	tavg = anytim( mean( anytim(tr) ), /yo )
	nustar_adjust_region, tavg, time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_'+str+'.reg';,/stop
	nustar_adjust_region, tavg, time_ref, regB, align_file, indir=indir, outdir=outdir, new='regB_'+str+'.reg'
endfor
end

