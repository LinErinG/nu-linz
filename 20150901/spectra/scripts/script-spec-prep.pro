;
; Script for prepping the 20150901 data for spectral fitting.
; This is based on Iain's example (xspec_info_010915.txt)
; Note that data is prepped to fit over 1-min time intervals for the first 20
; min of the observation.
;


1. Make some GTI files (time of interest) that will be useful at various points. 
   Include one for entire flare interval and one for 1-min intervals during the flare.
   Environment: IDL

	if file_exist('gti') eq 0 then spawn, 'mkdir gti'
	out_dir = 'gti'
	data_dir = '~/data/nustar/20150901//20102002001/event_cl/'

	gti_file = data_dir+'nu20102002001A06_gti.fits'
	gti = mrdfits(gti_file, 1, gtih)
	gti_out=gti

	; Set up time intervals.
	t0 = '2015-sep-01 0355'
	int = anytim(t0) + 60.*findgen(21)

	.run
	for i=0, n_elements(int)-2 do begin
		tr_nu = convert_nustar_time( anytim(int[i:i+1],/vms), /from_ut )  
		gti_out.start = tr_nu[0]
		gti_out.stop = tr_nu[1]
		str = strmid(anytim(tr_nu,/yo),10,2)+strmid(anytim(tr_nu,/yo),13,2)
		mwrfits, gti_out, out_dir+'/flare_'+str[0]+'_'+str[1]+'_gti.fits', gtih
	endfor
	end


2. Create an eventlist that is only grade 0 for 30 sec around the flare peak (0400-0430)
   Since this is a generally useful output, put it in the directory where the untouched 
   event list is kept.
   Environment: CSHELL

	set data_dir=/Users/glesener/data/nustar/20150901/20102002001/event_cl

	nuscreen \
	infile=$data_dir/nu20102002001A06_cl.evt \
	gtiscreen=no \
	evtscreen=yes \
	gtiexpr=NONE \
	gradeexpr=0 \
	statusexpr=NONE \
	outdir=$data_dir \
	hkfile=$data_dir/nu20102002001A_fpm.hk \
	outfile=nu20102002001A06_cl_grade0.evt
	
	nuscreen \
	infile=$data_dir/nu20102002001B06_cl.evt \
	gtiscreen=no \
	evtscreen=yes \
	gtiexpr=NONE \
	gradeexpr=0 \
	statusexpr=NONE \
	outdir=$data_dir \
	hkfile=$data_dir/nu20102002001B_fpm.hk \
	outfile=nu20102002001B06_cl_grade0.evt
	


2. In ds9 make the source region file.  Make sure to save it in decimal degrees (not dd:mm:ss).

	; Note: this should be done with a 1-min file, but I'm having trouble generating it using
	; nuscreen.  Instead, I kluged one together by hand to use for the DS9 selection.
	; For each A and B, I selected a 0.5 arcmin region diameter.

	; This is a kludge to get a 1-minute event list for the time of the flare only.
	; Environment: SSWIDL
	data_dir = '~/data/nustar/20150901//20102002001/event_cl/'
	f=file_search(data_dir+'*06_cl.evt') 
	evta = mrdfits(f[0],1,evtah) 
	evtb = mrdfits(f[1],1,evtbh) 
	tr = '2015-sep-01 '+['0400','040030'] 
	tr_nu = convert_nustar_time( anytim(tr,/vms), /from_ut )  
	evta = evta[ where( evta.time gt tr_nu[0] and evta.time lt tr_nu[1] ) ]
	evtb = evtb[ where( evtb.time gt tr_nu[0] and evtb.time lt tr_nu[1] ) ]
	mwrfits, evta, 'nu20102002001A06_cl_peak.evt',evtah,/create  
	mwrfits, evtb, 'nu20102002001B06_cl_peak.evt',evtbh,/create  

	#Then proceed to DS9
	#Environment: CSHELL

	ds9 ./nu20102002001A06_cl_peak.evt
	ds9 ./nu20102002001B06_cl_peak.evt

3.  Adjust the regions we just saved to work for other time intervals.  Use the co-alignment
	with AIA to adjust the region center based on time.  This is done in IDL simply 
	because that's easiest for me.
	
	time_ref = '2015-09-01 04:00:30'
	align_file = 'regions/20150901_alignment_aiafexviii_v20161019.txt'
	indir = 'regions/'
	outdir = 'regions/correct_align/'
	regA = 'regA_peak.reg'
	regB = 'regB_peak.reg'

	nustar_adjust_region, '2015-09-01 03:55:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0355.reg'
	nustar_adjust_region, '2015-09-01 03:56:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0356.reg'
	nustar_adjust_region, '2015-09-01 03:57:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0357.reg'
	nustar_adjust_region, '2015-09-01 03:58:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0358.reg'
	nustar_adjust_region, '2015-09-01 03:59:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0359.reg'
	nustar_adjust_region, '2015-09-01 04:00:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0400.reg'
	nustar_adjust_region, '2015-09-01 04:01:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0401.reg'
	nustar_adjust_region, '2015-09-01 04:02:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0402.reg'
	nustar_adjust_region, '2015-09-01 04:03:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0403.reg'
	nustar_adjust_region, '2015-09-01 04:04:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0404.reg'
	nustar_adjust_region, '2015-09-01 04:05:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0405.reg'
	nustar_adjust_region, '2015-09-01 04:06:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0406.reg'
	nustar_adjust_region, '2015-09-01 04:07:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0407.reg'
	nustar_adjust_region, '2015-09-01 04:08:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0408.reg'
	nustar_adjust_region, '2015-09-01 04:09:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0409.reg'
	nustar_adjust_region, '2015-09-01 04:10:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0410.reg'
	nustar_adjust_region, '2015-09-01 04:11:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0411.reg'
	nustar_adjust_region, '2015-09-01 04:12:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0412.reg'
	nustar_adjust_region, '2015-09-01 04:13:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0413.reg'
	nustar_adjust_region, '2015-09-01 04:14:30', time_ref, regA, align_file, indir=indir, outdir=outdir, new='regA_0414.reg'



4. Make the spectrum (*.pha) and response files (*.arf, *.rmf) for chosen region, time range and Grade 0
   Note that assuming all in same CHU during time range so don't need to filter for that

	set data_dir=/Users/glesener/data/nustar/20150901/20102002001/event_cl
	set reg_dir=./regions/correct_align
	set gti_dir=./gti	
	
	nuproducts indir=$data_dir instrument=FPMA steminputs=nu20102002001 \
		outdir=./intervals/0359/ extended=no runmkarf=yes runmkrmf=yes \
		infile=$data_dir/nu20102002001A06_cl.evt \
		bkgextract=no \
		srcregionfile=$reg_dir/regA_0359.reg  \
		attfile=$data_dir/nu20102002001_att.fits hkfile=$data_dir/nu20102002001A_fpm.hk \
		usrgtifile=$gti_dir/flare_0359_0400_gti.fits

	foreach num ( 355 356 357 358 359 400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 )
		@ numplus = $num + 1
		set gti_file = "flare_0$num""_0$numplus""_gti.fits"
		set interval = "0"$num
		nuproducts indir=$data_dir instrument=FPMA steminputs=nu20102002001 \
			outdir=./intervals/$interval/ extended=no runmkarf=yes runmkrmf=yes \
			infile=$data_dir/nu20102002001A06_cl.evt \
			bkgextract=no \
			srcregionfile=$reg_dir/regA_0$num.reg  \
			attfile=$data_dir/nu20102002001_att.fits hkfile=$data_dir/nu20102002001A_fpm.hk \
			usrgtifile=$gti_dir/$gti_file
	end


	

5. Prior to starting XSPEC, we can do adaptive binning using the FTOOL GRPPHA.
	 The following lines rebin the data so that there is a minimum of 10 counts per bin.
	 Note: this step might not be necessary -- check your binning.
	 Environment: C shell

	grppha nu20102002001A06_cl_grade0_sr.pha nu20102002001A06_cl_grade0_sr_grp.pha
	group min 10
	exit
	grppha nu20102002001B06_cl_grade0_sr.pha nu20102002001B06_cl_grade0_sr_grp.pha
	group min 10
	exit


6. Load the products into xspec and do the fitting!
	 To use the following lines you need to have the files and the fitting script 
	 apec1_fit.xcm in the same directory (though you can modify easily to change that).
	 The fitting script fits a single thermal component and is adapted from Iain/Brian's codes.

	xspec
	@xspec/apec1_fit.xcm
	
	See SCRIPT_XSPEC for more xspec fitting commands used for this analysis.
	