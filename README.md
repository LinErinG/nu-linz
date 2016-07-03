# nu-linz
NuSTAR solar analysis codes, Lindsay edition

Codes are grouped into sets of general routines and observation-specific scripts.
The observation-specific scripts are for use with a particular NuSTAR solar observation and 
most of these are scripts, not routines, so that they can be run in part or in whole.
 
Parts of this set of code requires that you have the following:
 
Installed:
  * SSWIDL
  * NuSTARDAS (only needed for pipeline, spectroscopy, and a couple other things)

And the following sets of routines are needed:
  * add_path,'~/Dropbox/NuSTAR_Solar/code/', /expand
  	* This code is copied in the "image-Dropbox-copy" folder so you could replace this line with add_path,'image-Dropbox-copy', /expand
  * add_path,'~/local-git-repo/nustar-idl/', /expand
  * add_path,'~/local-git-repo/nustar_solar/', /expand
 
A copy of the Dropbox NuSTAR solar code is included here for convenience.