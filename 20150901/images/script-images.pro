;
; This script produces images in two energy bands for several time intervals.
;

; This part produces the images.  No need to run if we already have them.
shift = -[-30,25]		; Shift needed to co-align with AIA
data_dir = '~/data/nustar/20150901/'
tra = '2015-sep-01 '+['0358','0359','0400','0401','0402','0403','0404','0405']
.run
for i=0, n_elements(tra)-2 do begin
  make_map_nustar, '20102002001', maindir=data_dir, grdid=1, shift=shift, erang=[2,4], /xflip, /plot, /major_chu, tr=tra[i:i+1]
  make_map_nustar, '20102002001', maindir=data_dir, grdid=1, shift=shift, erang=[4,6], /xflip, /plot, /major_chu, tr=tra[i:i+1]
endfor
end
; and for the background interval
tr_bkg = '2015-sep-01 '+['041000','041500']				; background interval
make_map_nustar, '20102002001', maindir=data_dir, grdid=1, shift=shift, erang=[2,4], /plot, /xflip, /major_chu, tr=tr_bkg
make_map_nustar, '20102002001', maindir=data_dir, grdid=1, shift=shift, erang=[4,6], /plot, /xflip, /major_chu, tr=tr_bkg

; Just the active region itself:

shift = -[-30,25]		; Shift needed to co-align with AIA
data_dir = '~/data/nustar/20150901/'
tra = '2015-sep-01 '+['0430','0447']
  make_map_nustar, '20102002001', maindir=data_dir, grdid=1, shift=shift, erang=[2,4], /xflip, /plot, /major_chu, tr=tra
  make_map_nustar, '20102002001', maindir=data_dir, grdid=1, shift=shift, erang=[4,6], /xflip, /plot, /major_chu, tr=tra

f=file_search('out_files/map_CHU23_GRD1_E2_4_FPMA_04:30:00_04:47:00.fits')
fits2map,f,m
m.data = gauss_smooth( m.data, 7 )
loadct, 1
popen, xsi=7, ysi=7
m.id = 'NuSTAR 2-4 keV'
plot_map, shift_map(m,-45,0), /limb, grid=20, /log, dmin=0.1, xth=3, yth=3, charsi=1.5, $
	lcol=255, lth=3, gcol=255, title='NuSTAR 2-4 keV 2015-09-01 04:30-04:47 UT'
pclose
spawn, 'open plot.ps'


; This was for the 2017 HSR proposal.

f=file_search('~/nustar/20160726/quicklook/eastlimb/*.fits')
fits2map,f[0],m
m.data = gauss_smooth( m.data, 4 )
loadct, 7
popen, 'plot1', xsi=7, ysi=7
plot_map, m, /limb, grid=20, /log, dmin=0.1, xth=3, yth=3, charsi=1.5, $
	lcol=255, lth=3, gcol=255, title='NuSTAR 2-4 keV 2016-07-26 23:27-23:28 UT'
pclose
spawn, 'open plot1.ps'





; Plot the results.
; The "save_boxes2.sav" file is no longer used but is here so I can use it again easily 
; if needed in the future.
	popen, 'flare-maps', xsi=8, ysi=8
	!X.MARGIN=[0.25,0.25]
	!Y.MARGIN=[0.25,0.25] 
	restore, 'save_boxes2.sav'
	loadct, 5
	!p.multi=[0,4,4]
	.run
	f=file_search('out_files/map*E2_4_FPMA*')
	fits2map, f, m
	dur = (fix(m.dur)/60+1)*60.
	t1 = strmid(anytim(m.time,/yo),11,4)
	t2 = strmid(anytim(anytim(m.time)+dur,/yo),11,4)
	list = *boxes_savefile.cw_list
	s = size(m[0].data)
	for i=0, n_elements(m)-1 do m.data = smooth(m.data, 4)
	max = max(m.data)
	for i=0, n_elements(m)-1 do begin
		noxtick=1
		if i mod 4 eq 0 then noytick=0 else noytick=1
		plot_map, m[i], cen=[950,-250], fov=5, /limb, /nodate, dmax=max, xth=5, yth=5, /notitle, $
			lcol=255, lth=3, gcol=255, gthick=2, lthick=3, grid=5, tit=m[i].id, charsi=1.3, /noxtick, /noytick, ytit='', xtit=''
	;		oplot,(list[0, *]-s[2]/2)*m[4].dx+m[4].xc-30,(list[1,*]-s[1]/2)*m[4].dy+m[4].yc+25,col=255,thick = 4
	;	if i eq 7 then xyouts, 980,-350, '2-4 keV', col=255
		xyouts, 980,-360, '2-4 keV', col=255
		xyouts, 985,-390, t1[i]+'-'+t2[i], col=255
	;		if i eq n_elements(m)-1 then xyouts, 1010, -310, 'BKG', col=255
	endfor
	f=file_search('out_files/map*E4_6_FPMB**')
	fits2map, f, m
	dur = (fix(m.dur)/60+1)*60.
	t1 = strmid(anytim(m.time,/yo),11,4)
	t2 = strmid(anytim(anytim(m.time)+dur,/yo),11,4)
	for i=0, n_elements(m)-1 do m.data = smooth(m.data, 5)
	max = max(m.data)
	for i=0, n_elements(m)-1 do begin
		if i lt 4 then noxtick=1 else noxtick=0
		if i mod 4 eq 0 then noytick=0 else noytick=1
		plot_map, m[i], cen=[950,-250], fov=5, /limb, /nodate, dmax=max, xth=5, yth=5, /notitle, $
			lcol=255, lth=3, gcol=255, gthick=2, lthick=3, grid=5, tit=m[i].id, charsi=1.3, /noxtick, /noytick, ytit='', xtit=''
	;		oplot,(list[0, *]-s[2]/2)*m[4].dx+m[4].xc-30,(list[1,*]-s[1]/2)*m[4].dy+m[4].yc+25,col=255,thick = 4
	;	if i eq 7 then xyouts, 980,-350, '4-6 keV', col=255
		xyouts, 980,-360, '4-6 keV', col=255
		xyouts, 985,-390, t1[i]+'-'+t2[i], col=255
	;		if i eq n_elements(m)-1 then xyouts, 1010, -310, 'BKG', col=255
	endfor
	end
	!p.multi=0
	pclose
	!X.MARGIN=[10,3]
	!Y.MARGIN=[4,2] 

spawn, 'open flare-maps.ps'
