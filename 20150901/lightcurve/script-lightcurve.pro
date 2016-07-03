;
; Time profiles, compared with RHESSI and AIA
;

date = '2015-sep-01'
time = '03:55:30'	; choose a starting time.
dur = 30.					; choose an integration time in seconds
nmax= 28
cen = [930,-190]
cen_ar=[925,-270]
fov = 8					; the whole AR, plus a bit extra.
data_dir = '~/data/nustar/20150901/'
era = [2.,3.,4.,5.,7.]
shift = -[-30,25]		; Shift needed to co-align with AIA

tra = findgen(nmax)*dur + anytim( date+' '+time )

; Generate maps over time for FPMA in various energy ranges.

.run
for i=0, n_elements(tra)-2 do begin
for j=0, n_elements(era)-2 do begin
	print, 'Time range = ', anytim(tra[i:i+1],/yo), ' Energy range = ', era[j:j+1]
	make_map_nustar, '20102002001', maindir=data_dir, shift=shift, erang=era[j:j+1], grdid=1, /plot, /xflip, /major_chu, tr=tra[i:i+1], cen=cen_ar, fov=fov
endfor
endfor
end

spawn, 'mv out_files/map_CHU12_GRD1_* out_files/maps_may14'

f = file_search( 'out_files/maps_may14/*' )
fits2map, f, m
m.data[ where( finite( m.data ) eq 0 ) ] = 0.

a2 = m[ where( strmid( m.id, strpos(m[0].id,'keV')-4,1) eq '2' and strmid( m.id,3,1 ) eq 'A' ) ]
b2 = m[ where( strmid( m.id, strpos(m[0].id,'keV')-4,1) eq '2' and strmid( m.id,3,1 ) eq 'B' ) ]
a3 = m[ where( strmid( m.id, strpos(m[0].id,'keV')-4,1) eq '3' and strmid( m.id,3,1 ) eq 'A' ) ]
b3 = m[ where( strmid( m.id, strpos(m[0].id,'keV')-4,1) eq '3' and strmid( m.id,3,1 ) eq 'B' ) ]
a4 = m[ where( strmid( m.id, strpos(m[0].id,'keV')-4,1) eq '4' and strmid( m.id,3,1 ) eq 'A' ) ]
b4 = m[ where( strmid( m.id, strpos(m[0].id,'keV')-4,1) eq '4' and strmid( m.id,3,1 ) eq 'B' ) ]
a5 = m[ where( strmid( m.id, strpos(m[0].id,'keV')-4,1) eq '5' and strmid( m.id,3,1 ) eq 'A' ) ]
b5 = m[ where( strmid( m.id, strpos(m[0].id,'keV')-4,1) eq '5' and strmid( m.id,3,1 ) eq 'B' ) ]
;a6 = m[ where( strmid( m.id, strpos(m[0].id,'keV')-4,1) eq '6' and strmid( m.id,3,1 ) eq 'A' ) ]
;b6 = m[ where( strmid( m.id, strpos(m[0].id,'keV')-4,1) eq '6' and strmid( m.id,3,1 ) eq 'B' ) ]

; Gather times of the measurements
t2a = a2.time
t3a = a3.time
t4a = a4.time
t5a = a5.time
;t6a = a6.time
t2b = b2.time
t3b = b3.time
t4b = b4.time
t5b = b5.time
;t6b = b6.time

p2a = total( total(a2.data,1), 1)
p3a = total( total(a3.data,1), 1)
p4a = total( total(a4.data,1), 1)
p5a = total( total(a5.data,1), 1)
;p6a = total( total(a6.data,1), 1)
p2b = total( total(b2.data,1), 1)
p3b = total( total(b3.data,1), 1)
p4b = total( total(b4.data,1), 1)
p5b = total( total(b5.data,1), 1)
;p6b = total( total(b6.data,1), 1)

; Subtract a pre-flare background.  These are adjusted for each passband/FPM
p2a = p2a-average(p2a[0:4])
p3a = p3a-average(p3a[0:4])
p4a = p4a-average(p4a[0:2])
p5a = p5a-average(p5a[0:1])
;p6a = p6a-average(p6a[0:1])
p2b = p2b-average(p2b[0:4])
p3b = p3b-average(p3b[0:4])
p4b = p4b-average(p4b[0:1])
p5b = p5b-average(p5b[1:4])
;p6b = p6b-average(p6b[0:1])

; Add them together (FPMA and FPMB)
p2=p2a
p3=p3a
p4=p4a
p5=p5a
p2 += interpol( p2b, anytim(t2b), anytim(t2a) )
p3 += interpol( p3b, anytim(t3b), anytim(t3a) )
p4 += interpol( p4b, anytim(t4b), anytim(t4a) )
p5 += interpol( p5b, anytim(t5b), anytim(t5a) )


;; Get the other data sources -- AIA and RHESSI
;dir = '~/data/aia/20150901/orbit2/'
;f094 = file_search(dir+'*AIA_94*')
;f171 = file_search(dir+'*AIA_171*')
;f211 = file_search(dir+'*AIA_211*')
;fits2map, f094, m094
;fits2map, f171, m171
;fits2map, f211, m211
;m094 = make_submap( m094, cen=[928.5,-186], fov=1. )
;m171 = make_submap( m171, cen=[928.5,-186], fov=1. )
;m211 = make_submap( m211, cen=[928.5,-186], fov=1. )
;s094 = make_submap( m094, cen=[928.5,-186], fov=0.08 )
;s171 = make_submap( m171, cen=[928.5,-186], fov=0.08 )
;s211 = make_submap( m211, cen=[928.5,-186], fov=0.08 )
;aia_time = [[m094.time],[m171.time],[m211.time]]
;aia_time = anytim( average( anytim( aia_time ), 2 ), /yo )

;mfexviii = m094
;mfexviii.data = m094.data - m211.data/120. - m171.data/450.
;sfexviii = s094
;sfexviii.data = s094.data - s211.data/120. - s171.data/450.
;mfexviii.id = 'Fe XVIII'
;sfexviii.id = 'Fe XVIII'

;data_fe = total( total( mfexviii.data,1),1 )
;data_fe_sub = total( total( sfexviii.data,1),1 )
;data_fe = data_fe - average( data_fe[90:99] )
;data_fe_sub = data_fe_sub - average( data_fe_sub[90:99] )
;utplot, aia_time, data_fe/max(data_fe)
;outplot, aia_time, data_fe_sub/max(data_fe_sub)

restore,'../context/rhsi_nustar_flare_1sep2015_det1.dat', /v
htime = anytim( htime, /yo )
htime = htime[525:599]
hrate = hrate[525:599]
hrate = hrate-average(hrate[0:5])
utplot, htime, hrate
;utplot,  htime, hrate,timerange=['1-Sep-2015 03:55:00','1-Sep-2015 04:12:00'],yrange=[0,10],ytitle='cts/s',title='5-9 keV (detector 1)'
;eutplot, htime, hrate,dhrate,/unc,width=5



loadct, 0
!p.multi=[0,2,3]
utplot,  t2a, p2a, psym=10, /nodata, back=255, col=0, yr=[-500.,4.e3], xth=3, yth=3, $
	charsi=1.3, charth=2, /ysty, $
	ytit = 'Counts per 30 seconds in AR', $
	tit='Background-subtracted and livetime-corrected, all grades'
outplot, t2a, p2a, psym=10, col=224, thick=8
outplot, t3a, p3a, psym=10, col=160, thick=8
outplot, t4a, p4a, psym=10, col=96, thick=8
outplot, t5a, p5a, psym=10, col=0, thick=8
;outplot, t6a, p6a, psym=10, col=0, thick=8
al_legend, ['2-3 keV','3-4 keV','4-5 keV','5-6 keV'], /right, box=0, line=0, thick=8, $
	color=[224,160,96,0], charsi=0.8

loadct, 0
utplot,  t2a, p2a/max(p2a), psym=10, /nodata, back=255, col=0, yr=[-0.3,1.1], xth=3, yth=3, $
	charsi=1.3, charth=2, /ysty, $
	ytit = 'Counts per 20 seconds in 5x5 arcmin', tit='Normalized'
outplot, t2a, p2a/max(p2a), psym=0, col=224, thick=8
outplot, t3a, p3a/max(p3a), psym=0, col=160, thick=8
outplot, t4a, p4a/max(p4a), psym=0, col=96, thick=8
outplot, t5a, p5a/max(p5a), psym=0, col=0, thick=8
;outplot, t6a, p6a/max(p6a[0:9],/nan), psym=0, col=0, thick=8
hsi_linecolors
al_legend, ['2-3 keV','3-4 keV','4-5 keV','5-6 keV'], /right, box=0, line=0, thick=8, $
	color=[224,160,96,13], charsi=0.8

loadct, 0
utplot,  t2b, p2b, psym=10, /nodata, back=255, col=0, yr=[-500.,4.e3], xth=3, yth=3, $
	charsi=1.3, charth=2, /ysty, $
	ytit = 'Counts per 20 seconds in 5x5 arcmin', $
	tit='Background-subtracted and livetime-corrected, all grades'
outplot, t2b, p2b, psym=10, col=224, thick=8
outplot, t3b, p3b, psym=10, col=160, thick=8
outplot, t4b, p4b, psym=10, col=96, thick=8
outplot, t5b, p5b, psym=10, col=0, thick=8
;outplot, t6b, p6b, psym=10, col=0, thick=8
al_legend, ['2-3 keV','3-4 keV','4-5 keV','5-6 keV'], /right, box=0, line=0, thick=8, $
	color=[224,160,96,0], charsi=0.8

loadct, 0
utplot,  t2b, p2b/max(p2b), psym=10, /nodata, back=255, col=0, yr=[-0.3,1.1], xth=3, yth=3, $
	charsi=1.3, charth=2, /ysty, $
	ytit = 'Counts per 20 seconds in 5x5 arcmin', tit='Normalized'
outplot, t2b, p2b/max(p2b), psym=0, col=224, thick=8
outplot, t3b, p3b/max(p3b), psym=0, col=160, thick=8
outplot, t4b, p4b/max(p4b), psym=0, col=96, thick=8
outplot, t5b, p5b/max(p5b,/nan), psym=0, col=0, thick=8
;outplot, t6b, p6b/max(p6b,/nan), psym=0, col=0, thick=8
hsi_linecolors
al_legend, ['2-3 keV','3-4 keV','4-5 keV','5-6 keV'], /right, box=0, line=0, thick=8, $
	color=[224,160,96,13], charsi=0.8


loadct, 0
utplot,  t2a, p2, psym=10, /nodata, back=255, col=0, yr=[-2e3,4.e4], xth=3, yth=3, $
	charsi=1.3, charth=2, /ysty, $
	ytit = 'Counts per 20 seconds in 5x5 arcmin', $
	tit='Background-subtracted and livetime-corrected, all grades'
outplot, t2a, p2, psym=10, col=224, thick=8
outplot, t3a, p3, psym=10, col=160, thick=8
outplot, t4a, p4, psym=10, col=96, thick=8
outplot, t5a, p5, psym=10, col=0, thick=8
al_legend, ['2-3 keV','3-4 keV','4-5 keV','5-6 keV'], /right, box=0, line=0, thick=8, $
	color=[224,160,96,0], charsi=0.8

loadct, 0
utplot,  t2a, p2/max(p2), psym=10, /nodata, back=255, col=0, yr=[-0.3,1.1], xth=3, yth=3, $
	charsi=1.3, charth=2, /ysty, $
	ytit = 'Counts per 20 seconds in 5x5 arcmin', tit='Normalized'
outplot, t2a, p2/max(p2), psym=0, col=224, thick=8
outplot, t3a, p3/max(p3), psym=0, col=160, thick=8
outplot, t4a, p4/max(p4), psym=0, col=96, thick=8
outplot, t5a, p5/max(p5), psym=0, col=0, thick=8
hsi_linecolors
al_legend, ['2-3 keV','3-4 keV','4-5 keV','5-6 keV'], /right, box=0, line=0, thick=8, $
	color=[224,160,96,13], charsi=0.8
	

; Another set of plots showing how NuSTAR, RHESSI and AIA line up in time.

popen, 'small-flare-profile', xsi=8, ysi=8
!p.multi=[0,1,3]
ch=2.5
!Y.MARGIN=[0.25,0.25] 
loadct, 0
utplot,  t2a, p2/max(p2), psym=10, /nodata, back=255, col=0, yr=[-0.3,1.2], xth=3, yth=3, $
	charsi=ch, charth=2, /ysty, /noxticks, $
	ytit = 'Normalized counts', xtit=''
outplot, t2a, p2/max(p2), psym=0, col=224, thick=8
outplot, t3a, p3/max(p3), psym=0, col=160, thick=8
outplot, t4a, p4/max(p4), psym=0, col=96, thick=8
outplot, t5a[2:25], p5[2:25]/max(p5), psym=0, col=0, thick=8
hsi_linecolors
al_legend, ['NuSTAR','2-3 keV','3-4 keV','4-5 keV','5-6 keV'], /right, box=0, line=[-1,0,0,0,0], thick=8, $
	color=[255,224,160,96,13], charsi=1.2

loadct, 0
utplot,  t2a, p5/max(p5), /nodata, back=255, col=0, yr=[-0.3,1.2], xth=3, yth=3, $
	charsi=ch, charth=2, /ysty, thick=8, $
	ytit = 'Normalized counts', xtit=''
hsi_linecolors
outplot, htime, hrate/max(hrate), col=12, thick=8, psym=10
al_legend, ['RHESSI D1 4-9 keV'], /right, box=0, thick=8, textcolor=12, charsi=1.5

restore, '../context/20150901_035000_20.dat', /v
ptime = p.time[istart:iend]
pflux0 = p.flux[istart:iend,0]-p.flux[istart,0]
pflux1 = p.flux[istart:iend,1]-p.flux[istart,1]
pflux2 = p.flux[istart:iend,2]-p.flux[istart,2]

loadct2,5
istart=22
iend=116
utplot,  t2a, p5/max(p5), /nodata, back=255, col=0, yr=[-0.3,1.2], xth=3, yth=3, $
	charsi=ch, charth=2, /ysty, thick=8, $
	ytit = 'Normalized DN';, tit='AIA FeXVIII'
outplot, anytim(ptime,/yo), pflux0/max(pflux0)  ;,ytitle='DN/s',ystyle=1,title='Fe XVIII'
outplot, anytim(ptime,/yo), pflux1/max(pflux1), color=6, thick=8
outplot, anytim(ptime,/yo), pflux2/max(pflux2), color=2, thick=8
outplot, anytim(ptime,/yo), pflux0/max(pflux0), color=1, thick=8
al_legend, ['AIA FeXVIII'], /right, box=0, thick=8, charsi=1.5

pclose
!Y.MARGIN=[4,2] 

spawn, 'open small-flare-profile.ps'
