;
;  Example script for images of the Feb 19 observations
;

; OBSIDs are:
; Orbit 1	20102011001
; Orbit 2	20102012001
; Orbit 3	20102013001
; Orbit 4	20102014001

; Identify directory where NuSTAR data is kept.  Code expects to find data in an 
; OBSID subdirectory containing event_cl, etc.
data_dir = '~/data/nustar/20160219/andrew/20160219_data/

; Make one image for entire Orbit 1 (specified using OBSID)
; This creates a out_files directory and puts FPMA and FPMB maps in it.
make_map_nustar, '20102011001', tr=tra, maindir=data_dir, erang=2, /plot, chu_select=1

; Full-orbit image for each CHU, orbit 1
; CHU can be specified by string (e.g. 'CHU23') or code (e.g. 13)
make_map_nustar, '20102011001', tr=tra, maindir=data_dir, erang=2, /plot, chu_select=1
make_map_nustar, '20102011001', tr=tra, maindir=data_dir, erang=2, /plot, chu_select=4
make_map_nustar, '20102011001', tr=tra, maindir=data_dir, erang=2, /plot, chu_select=5
make_map_nustar, '20102011001', tr=tra, maindir=data_dir, erang=2, /plot, chu_select=9
make_map_nustar, '20102011001', tr=tra, maindir=data_dir, erang=2, /plot, chu_select=10
make_map_nustar, '20102011001', tr=tra, maindir=data_dir, erang=2, /plot, chu_select=13

; Maps for orbit 1 at 1-minute cadence
; CHU combination will be whichever combo is most prevalent in that time interval.
dur = 60.
tstart = anytim('2016-02-19T18:55:00')
for i=0, 69 do make_map_nustar, '20102011001', maindir=data_dir, tr=anytim(tstart+i*dur+[0.,dur],/yo), erang=2, /plot, /major_chu

; Read in files and make a movie.
dir = 'out_files/'
f=file_search( dir+'map*FPMA*' )
fits2map, f, mapA
mapA = mapA[ sort( anytim(mapA.time) ) ]
movie_map, mapA, /limb, dmax=5.
smoothA = mapA
smoothA.data = smooth( mapA.data, 5 )	
movie_map, smoothA, /limb, /log, dmin=0.01

;
; Find the offsets with AIA
; Requires AIA 94, 211, 171 filter data stored in AIA_DIR
;
	
loadct, 5
cen = [1100,200]
	
; Combine filters to get the hot Fe emission.  F_94 - F_211/180 - F_171/1000
aia_dir = '~/data/aia/20160219/orbit1/'
f094 = file_search( aia_dir+'*_94_*' )
f171 = file_search( aia_dir+'*_171_*' )
f211 = file_search( aia_dir+'*_211_*' )
fits2map, f094, m094
fits2map, f171, m171
fits2map, f211, m211
s094 = m094[0]
s094.data = average( m094.data, 3 )
s171 = m171[0]
s171.data = average( m171.data, 3 )
s211 = m211[0]
s211.data = average( m211.data, 3 )
; Make sure everybody's got the same frame location and size.
s094 = make_submap( s094, cen=cen, fov=12. )
s171 = make_submap( s171, cen=cen, fov=12. )
s211 = make_submap( s211, cen=cen, fov=12. )
aia = s094
aia.data = s094.data - s211.data / 180. - s171.data / 1.e3
aia.id='SDO AIA FeXVIII'
aia.data = smooth( aia.data, 30 )		; Worsen resolution

; Pull up the NuSTAR map for each CHU combo.
; I put the files I wanted in a particular directory beforehand.
nustA = file_search('out_files/orbit1/no_align/map*FPMA*.fits')		; uncorrected map.
nustB = file_search('out_files/orbit1/no_align/map*FPMB*.fits')		; uncorrected map.
fits2map, nustA, numapA
fits2map, nustB, numapB
numapA.data = smooth(numapA.data, 5)
numapB.data = smooth(numapB.data, 5)
	
shifts = [[0,0],[0,0],[0,0],[0,0],[0,0]]	
; shifts = [[-65,20],[-70,-10],[-110,40],[-130,-20],[-40,-40]]		; Fill in shifts as we get them.
	
; Plot together and shift by hand to match.
!p.multi=[0,2,2]
i=4
plot_map, aia, /limb, cen=cen, fov=10, /log, /nodate
plot_map, numapA[i], /limb, cen=cen, fov=10, /nodate
plot_map, aia, /limb, cen=cen, fov=10, /log, /nodate, title='NuSTAR on AIA'
plot_map, numapA[i], /over, col=50, thick=2
plot_map, aia, /limb, cen=cen, fov=10, /log, /nodate, title='Post alignment'
plot_map, shift_map( numapA[i], shifts[0,i], shifts[1,i] ), /over, col=50, thick=6
plot_map, shift_map( numapA[i], -40, 40 ), /over, col=50, thick=2

; Store these values in a text file alignments-obs6.txt
; Then you can use them in make_map_nustar to align the data.


;
; Aligned maps for all time intervals in the first orbit
; Use of keyword /shift calls in the correct shift for the relevant CHU combo.
;
tstart = anytim('2016-02-19T18:55:00')	
dur = 60.
for i=0, 59 do make_map_nustar, '20102011001', maindir=data_dir, tr=anytim( tstart+i*dur + [0.,dur], /yo ), erang=2, /plot, /major_chu, /shift


