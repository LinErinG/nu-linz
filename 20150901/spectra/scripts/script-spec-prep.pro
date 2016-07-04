;
; Script for getting the data ready for spectral fitting.
; This is based on Iain's example (xspec_info_010915.txt)
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

	gti_out.start=anytim('01-Sep-2015 03:59')-anytim('01-Jan-2010')
	gti_out.stop=anytim('01-Sep-2015 04:00')-anytim('01-Jan-2010')
	mwrfits, gti_out, out_dir+'/flare_0359_0400_gti.fits', gtih
	gti_out.start=anytim('01-Sep-2015 04:00')-anytim('01-Jan-2010')
	gti_out.stop=anytim('01-Sep-2015 04:01')-anytim('01-Jan-2010')
	mwrfits, gti_out, out_dir+'/flare_0400_0401_gti.fits', gtih
	gti_out.start=anytim('01-Sep-2012 04:01')-anytim('01-Jan-2010')
	gti_out.stop=anytim('01-Sep-2015 04:02')-anytim('01-Jan-2010')
	mwrfits, gti_out, out_dir+'/flare_0401_0402_gti.fits', gtih
	gti_out.start=anytim('01-Sep-2015 04:02')-anytim('01-Jan-2010')
	gti_out.stop=anytim('01-Sep-2015 04:03')-anytim('01-Jan-2010')
	mwrfits, gti_out, out_dir+'/flare_0402_0403_gti.fits', gtih
	gti_out.start=anytim('01-Sep-2015 04:03')-anytim('01-Jan-2010')
	gti_out.stop=anytim('01-Sep-2015 04:04')-anytim('01-Jan-2010')
	mwrfits, gti_out, out_dir+'/flare_0403_0404_gti.fits', gtih
	gti_out.start=anytim('01-Sep-2015 04:03')-anytim('01-Jan-2010')
	gti_out.stop=anytim('01-Sep-2015 04:04')-anytim('01-Jan-2010')
	mwrfits, gti_out, out_dir+'/flare_0359_0404_gti.fits', gtih

	; Note: another syntax that can be useful here:
	; tr = '2015-sep-01 '+['0359','0400'] 
	; tr_nu = convert_nustar_time( anytim(tr,/vms), /from_ut )  
	; gti_out.start = tr_nu[0]
	; gti_out.stop = tr_nu[1]



2. Create an eventlist that is only grade 0, for the whole flare (flare_0359_0404).
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
	; For each A and B, I selected a 0.5 arcmin region, taking care to try to avoid the 
	; edge pixels where possible.  0.5 arcmin is bigger than it needs to be, but I lose some
	; emission at the chip edge.  I then selected a background in another region of the 
	; flare (though this isn't really the right way to do it...)

	; This is a kludge to get a 1-minute event list for the time of the flare only.
	; Environment: SSWIDL
	data_dir = '~/data/nustar/20150901//20102002001/event_cl/'
	f=file_search(data_dir+'*06_cl.evt') 
	evta = mrdfits(f[0],1,evtah) 
	evtb = mrdfits(f[1],1,evtbh) 
	tr = '2015-sep-01 '+['0359','0400'] 
	tr_nu = convert_nustar_time( anytim(tr,/vms), /from_ut )  
	evta = evta[ where( evta.time gt tr_nu[0] and evta.time lt tr_nu[1] ) ]
	evtb = evtb[ where( evtb.time gt tr_nu[0] and evtb.time lt tr_nu[1] ) ]
	mwrfits, evta, 'nu20102002001A06_cl_1min.evt',evtah,/create  
	mwrfits, evtb, 'nu20102002001B06_cl_1min.evt',evtbh,/create  

	#Then proceed to DS9
	#Environment: CSHELL

	ds9 ./nu20102002001A06_cl_1min.evt
	ds9 ./nu20102002001B06_cl_1min.evt


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
	


5. Load the products into xspec and do the fitting!  See additional scripts for this part.
	