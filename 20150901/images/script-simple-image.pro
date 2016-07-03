;
; A simple example of creating and plotting an image.
;

shift = -[-30,25]		; Shift needed to co-align with AIA
data_dir = '~/data/nustar/20150901/'		; Change this to where your data is stored.

; Time range
tra = '2015-sep-01 '+['0358','0403']
make_map_nustar, '20102002001', maindir=data_dir, shift=shift, erang=2, grdid=0, /plot, /xflip, /major_chu, tr=tra
; This creates an out_files directory and puts FPMA and FPMB maps in it.


f = file_search('out_files/map*')
fits2map, f[0], m
plot_map, m
