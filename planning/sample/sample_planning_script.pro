;
; Sample use of code for NuSTAR observation planning (IDL version)
; This script uses the May 29, 2018 observation as an example.
;

; The needed routines are in the NuSTAR shared DropBox.  If you downloaded this script 
; from GitHub, there is a copy of this directory in the main directory.

; (1) Download latest AIA files using download_latest:

download_latest, instr='aia', wave=94
download_latest, instr='aia', wave=131
download_latest, instr='aia', wave=171
download_latest, instr='aia', wave=335


; (2) Check target positioning at aim time.  The best aim time is often the midpoint of $
; the NuSTAR orbit.

aim_time = '2018-05-29T18:02:15'
nustar_solar_target, aim_time = aim_time


; (3) Play with the target coords and angle until you get your desired NuSTAR framing.

nustar_solar_target, aim_time=aim_time, target=[-109.3,250.5], theta=270., file='target1'


; (4) Transfer those coordinates to RA and DEC.  This is best done using Brian's Python 
; planning tool.  But you can do the coord transformation (though not the position 
; angle transform) using nustar_sunpoint:

coords = nustar_sunpoint( [-109.3,250.5], time=aim_time, epoch_to=j2000 ) 

; (5) Check the results of nustar_sunpoint against the results obtained other ways.
