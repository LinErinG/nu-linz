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

;	gti_out.start=anytim('01-Sep-2015 03:59')-anytim('01-Jan-2010')
;	gti_out.stop=anytim('01-Sep-2015 04:00')-anytim('01-Jan-2010')
;	mwrfits, gti_out, out_dir+'/flare_0359_0400_gti.fits', gtih
;	gti_out.start=anytim('01-Sep-2015 04:00')-anytim('01-Jan-2010')
;	gti_out.stop=anytim('01-Sep-2015 04:01')-anytim('01-Jan-2010')
;	mwrfits, gti_out, out_dir+'/flare_0400_0401_gti.fits', gtih
;	gti_out.start=anytim('01-Sep-2012 04:01')-anytim('01-Jan-2010')
;	gti_out.stop=anytim('01-Sep-2015 04:02')-anytim('01-Jan-2010')
;	mwrfits, gti_out, out_dir+'/flare_0401_0402_gti.fits', gtih
;	gti_out.start=anytim('01-Sep-2015 04:02')-anytim('01-Jan-2010')
;	gti_out.stop=anytim('01-Sep-2015 04:03')-anytim('01-Jan-2010')
;	mwrfits, gti_out, out_dir+'/flare_0402_0403_gti.fits', gtih
;	gti_out.start=anytim('01-Sep-2015 04:03')-anytim('01-Jan-2010')
;	gti_out.stop=anytim('01-Sep-2015 04:04')-anytim('01-Jan-2010')
;	mwrfits, gti_out, out_dir+'/flare_0403_0404_gti.fits', gtih
;	gti_out.start=anytim('01-Sep-2015 04:03')-anytim('01-Jan-2010')
;	gti_out.stop=anytim('01-Sep-2015 04:04')-anytim('01-Jan-2010')
;	mwrfits, gti_out, out_dir+'/flare_0359_0404_gti.fits', gtih
;	gti_out.start=anytim('01-Sep-2015 04:10')-anytim('01-Jan-2010')
;	gti_out.stop=anytim('01-Sep-2015 04:15')-anytim('01-Jan-2010')
;	mwrfits, gti_out, out_dir+'/flare_0410_0415_gti.fits', gtih



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
	


2. In ds9 make the source region file, one doing A and B, call it flare_reg.reg (maybe need slighlty diff regions per A/B?)

	; Note: this should be done with a 1-min file, but I'm having trouble generating it using
	; nuscreen.  Instead, I kluged one together by hand to use for the DS9 selection.
	; For each A and B, I selected a 0.5 arcmin region, diameter taking care to try to 
	; avoid the edge pixels where possible.  Note the FPMA circle is good, but the 
	; FPMB circle is a bit offset to avoid the edge.  In both cases, we could run into
	; trouble as the drift makes our region go off the edge!

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


4. Make the spectrum (*.pha) and response files (*.arf, *.rmf) for chosen region, time range and Grade 0
   Note that assuming all in same CHU during time range so don't need to filter for that

	set data_dir=/Users/glesener/data/nustar/20150901/20102002001/event_cl
	set reg_dir=./regions
	set gti_dir=./gti

	# Minute 0359-0400
	nuproducts indir=$data_dir instrument=FPMA steminputs=nu20102002001 \
		outdir=./intervals/0359/ extended=no runmkarf=yes runmkrmf=yes \
		infile=$data_dir/nu20102002001A06_cl_grade0.evt \
		srcregionfile=$reg_dir/regA.reg  \
		attfile=$data_dir/nu20102002001_att.fits hkfile=$data_dir/nu20102002001A_fpm.hk \
		usrgtifile=$gti_dir/flare_0359_0400_gti.fits \
		bkgregionfile=$reg_dir/bkdA.reg 
	nuproducts indir=$data_dir instrument=FPMB steminputs=nu20102002001 \
		outdir=./intervals/0359/ extended=no runmkarf=yes runmkrmf=yes \
		infile=$data_dir/nu20102002001B06_cl_grade0.evt \
		srcregionfile=$reg_dir/regB.reg  \
		attfile=$data_dir/nu20102002001_att.fits hkfile=$data_dir/nu20102002001B_fpm.hk \
		usrgtifile=$gti_dir/flare_0359_0400_gti.fits \
		bkgregionfile=$reg_dir/bkdB.reg
	
	# Minute 0400-0401
	nuproducts indir=$data_dir instrument=FPMA steminputs=nu20102002001 \
		outdir=./intervals/0400/ extended=no runmkarf=yes runmkrmf=yes \
		infile=$data_dir/nu20102002001A06_cl_grade0.evt \
		srcregionfile=$reg_dir/regA.reg  \
		attfile=$data_dir/nu20102002001_att.fits hkfile=$data_dir/nu20102002001A_fpm.hk \
		usrgtifile=$gti_dir/flare_0400_0401_gti.fits \
		bkgregionfile=$reg_dir/bkdA.reg
	nuproducts indir=$data_dir instrument=FPMB steminputs=nu20102002001 \
		outdir=./intervals/0400/ extended=no runmkarf=yes runmkrmf=yes \
		infile=$data_dir/nu20102002001B06_cl_grade0.evt \
		srcregionfile=$reg_dir/regB.reg  \
		attfile=$data_dir/nu20102002001_att.fits hkfile=$data_dir/nu20102002001B_fpm.hk \
		usrgtifile=$gti_dir/flare_0400_0401_gti.fits \
		bkgregionfile=$reg_dir/bkdB.reg

	# Minute 0401-0402
	nuproducts indir=$data_dir instrument=FPMA steminputs=nu20102002001 \
		outdir=./intervals/0401/ extended=no runmkarf=yes runmkrmf=yes \
		infile=$data_dir/nu20102002001A06_cl_grade0.evt \
		srcregionfile=$reg_dir/regA.reg  \
		attfile=$data_dir/nu20102002001_att.fits hkfile=$data_dir/nu20102002001A_fpm.hk \
		usrgtifile=$gti_dir/flare_0401_0402_gti.fits \
		bkgregionfile=$reg_dir/bkdA.reg
	nuproducts indir=$data_dir instrument=FPMB steminputs=nu20102002001 \
		outdir=./intervals/0401/ extended=no runmkarf=yes runmkrmf=yes \
		infile=$data_dir/nu20102002001B06_cl_grade0.evt \
		srcregionfile=$reg_dir/regB.reg  \
		attfile=$data_dir/nu20102002001_att.fits hkfile=$data_dir/nu20102002001B_fpm.hk \
		usrgtifile=$gti_dir/flare_0401_0402_gti.fits \
		bkgregionfile=$reg_dir/bkdB.reg

	# Minute 0402-0403
	nuproducts indir=$data_dir instrument=FPMA steminputs=nu20102002001 \
		outdir=./intervals/0402/ extended=no runmkarf=yes runmkrmf=yes \
		infile=$data_dir/nu20102002001A06_cl_grade0.evt \
		srcregionfile=$reg_dir/regA.reg  \
		attfile=$data_dir/nu20102002001_att.fits hkfile=$data_dir/nu20102002001A_fpm.hk \
		usrgtifile=$gti_dir/flare_0402_0403_gti.fits \
		bkgregionfile=$reg_dir/bkdA.reg
	nuproducts indir=$data_dir instrument=FPMB steminputs=nu20102002001 \
		outdir=./intervals/0402/ extended=no runmkarf=yes runmkrmf=yes \
		infile=$data_dir/nu20102002001B06_cl_grade0.evt \
		srcregionfile=$reg_dir/regB.reg  \
		attfile=$data_dir/nu20102002001_att.fits hkfile=$data_dir/nu20102002001B_fpm.hk \
		usrgtifile=$gti_dir/flare_0402_0403_gti.fits \
		bkgregionfile=$reg_dir/bkdB.reg

	# Minute 0403-0404
	nuproducts indir=$data_dir instrument=FPMA steminputs=nu20102002001 \
		outdir=./intervals/0403/ extended=no runmkarf=yes runmkrmf=yes \
		infile=$data_dir/nu20102002001A06_cl_grade0.evt \
		srcregionfile=$reg_dir/regA.reg  \
		attfile=$data_dir/nu20102002001_att.fits hkfile=$data_dir/nu20102002001A_fpm.hk \
		usrgtifile=$gti_dir/flare_0403_0404_gti.fits \
		bkgregionfile=$reg_dir/bkdA.reg
	nuproducts indir=$data_dir instrument=FPMB steminputs=nu20102002001 \
		outdir=./intervals/0403/ extended=no runmkarf=yes runmkrmf=yes \
		infile=$data_dir/nu20102002001B06_cl_grade0.evt \
		srcregionfile=$reg_dir/regB.reg  \
		attfile=$data_dir/nu20102002001_att.fits hkfile=$data_dir/nu20102002001B_fpm.hk \
		usrgtifile=$gti_dir/flare_0403_0404_gti.fits \
		bkgregionfile=$reg_dir/bkdB.reg
	
	# Minute 0410-0415
	nuproducts indir=$data_dir instrument=FPMA steminputs=nu20102002001 \
		outdir=./intervals/0410/ extended=no runmkarf=yes runmkrmf=yes \
		infile=$data_dir/nu20102002001A06_cl_grade0.evt \
		srcregionfile=$reg_dir/regA.reg  \
		attfile=$data_dir/nu20102002001_att.fits hkfile=$data_dir/nu20102002001A_fpm.hk \
		usrgtifile=$gti_dir/flare_0410_0415_gti.fits \
		bkgregionfile=$reg_dir/bkdA.reg
	nuproducts indir=$data_dir instrument=FPMB steminputs=nu20102002001 \
		outdir=./intervals/0410/ extended=no runmkarf=yes runmkrmf=yes \
		infile=$data_dir/nu20102002001B06_cl_grade0.evt \
		srcregionfile=$reg_dir/regB.reg  \
		attfile=$data_dir/nu20102002001_att.fits hkfile=$data_dir/nu20102002001B_fpm.hk \
		usrgtifile=$gti_dir/flare_0410_0415_gti.fits \
		bkgregionfile=$reg_dir/bkdB.reg
	

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
	