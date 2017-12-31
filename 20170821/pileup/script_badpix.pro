; Script for identifying and isolated hot pixels.

dir1 = '~/data/nustar/20170821/20312001_Sol_17233_eclipse_MOS01/20312001001/event_cl/'
f1a = 'nu20312001001A06_cl_sunpos.evt'
f1b = 'nu20312001001B06_cl_sunpos.evt'

evt = mrdfits( dir1+f1a, 1 )
hist = hist_2d( evt.det1x, evt.det1y, min1=0, min2=0, max1=361, max2=361 )
t = evt.time - evt[0].time
hist_time1 = hist_2d( t, evt.DET1X, min2=0, max2=361 )
hist_time2 = hist_2d( t, evt.DET1Y, min2=0, max2=361 )

ct = COLORTABLE(5)
w = WINDOW(WINDOW_TITLE="badpix search", $
    DIMENSIONS=[1000,800])
g0 = IMAGE(hist, RGB_TABLE=ct, AXIS_STYLE=2, MARGIN=0.1, $
   XTITLE='Raw X', YTITLE='Raw Y', TITLE='FPMA, MOS01', $
   layout=[2,2,1], /curr )
g1 = image( hist_time1, axis_style=2, /current,$
	xtit='Time since start [s]', ytit='DET1X', $
	POSITION=[0.50575135,0.75,0.95101394,0.95])
g1 = image( hist_time2, axis_style=2, /current, margin=0.1, $
	xtit='Time since start [s]', ytit='DET1Y', $
	POSITION=[0.50575138,0.55,0.95271964,0.75] )

evt = mrdfits( dir1+f1b, 1 )
hist = hist_2d( evt.det1x, evt.det1y, min1=0, min2=0, max1=361, max2=361 )
t = evt.time - evt[0].time
hist_time1 = hist_2d( t, evt.DET1X, min2=0, max2=361 )
hist_time2 = hist_2d( t, evt.DET1Y, min2=0, max2=361 )

g0 = IMAGE(hist, RGB_TABLE=ct, AXIS_STYLE=2, MARGIN=0.1, $
   XTITLE='Raw X', YTITLE='Raw Y', TITLE='FPMB, MOS01', $
   layout=[2,2,3], /curr )
g1 = image( hist_time1, axis_style=2, /current, $
	xtit='Time since start [s]', ytit='DET1X', $
	POSITION=[0.50575135,0.25,0.95101394,0.45])
g1 = image( hist_time2, axis_style=2, /current, $
	xtit='Time since start [s]', ytit='DET1Y', $
	POSITION=[0.50575138,0.05,0.95271964,0.25] )


; Script for identifying and isolated hot pixels.

dir2 = '~/data/nustar/20170821/20312002_Sol_17233_eclipse_MOS02/20312002001/event_cl/'

f2a = 'nu20312002001A06_cl_sunpos.evt'
f2b = 'nu20312002001B06_cl_sunpos.evt'

evt = mrdfits( dir2+f2a, 1 )
hist = hist_2d( evt.det1x, evt.det1y, min1=0, min2=0, max1=361, max2=361 )
t = evt.time - evt[0].time
hist_time1 = hist_2d( t, evt.DET1X, min2=0, max2=361 )
hist_time2 = hist_2d( t, evt.DET1Y, min2=0, max2=361 )

ct = COLORTABLE(5)
w = WINDOW(WINDOW_TITLE="badpix search 2", $
    DIMENSIONS=[1000,800])
g0 = IMAGE(hist, RGB_TABLE=ct, AXIS_STYLE=2, MARGIN=0.1, $
   XTITLE='Raw X', YTITLE='Raw Y', TITLE='FPMA, MOS02', $
   layout=[2,2,1], /curr )
g1 = image( hist_time1, axis_style=2, /current,$
	xtit='Time since start [s]', ytit='DET1X', $
	POSITION=[0.50575135,0.75,0.95101394,0.95])
g1 = image( hist_time2, axis_style=2, /current, margin=0.1, $
	xtit='Time since start [s]', ytit='DET1Y', $
	POSITION=[0.50575138,0.55,0.95271964,0.75] )

evt = mrdfits( dir2+f2b, 1 )
hist = hist_2d( evt.det1x, evt.det1y, min1=0, min2=0, max1=361, max2=361 )
t = evt.time - evt[0].time
hist_time1 = hist_2d( t, evt.DET1X, min2=0, max2=361 )
hist_time2 = hist_2d( t, evt.DET1Y, min2=0, max2=361 )

g0 = IMAGE(hist, RGB_TABLE=ct, AXIS_STYLE=2, MARGIN=0.1, $
   XTITLE='Raw X', YTITLE='Raw Y', TITLE='FPMB, MOS02', $
   layout=[2,2,3], /curr )
g1 = image( hist_time1, axis_style=2, /current, $
	xtit='Time since start [s]', ytit='DET1X', $
	POSITION=[0.50575135,0.25,0.95101394,0.45])
g1 = image( hist_time2, axis_style=2, /current, $
	xtit='Time since start [s]', ytit='DET1Y', $
	POSITION=[0.50575138,0.05,0.95271964,0.25] )
