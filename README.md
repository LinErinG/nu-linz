# nu-linz
NuSTAR solar analysis codes, Lindsay edition

Codes are grouped into sets of general routines and observation-specific scripts.
The observation-specific scripts are for use with a particular NuSTAR solar observation and 
most of these are scripts, not routines, so that they can be run in part or in whole.
 
Parts of this set of code requires that you have the following:
 
Installed:
  * SSWIDL
  * NuSTARDAS (only needed for pipeline, spectroscopy, and a couple other things)

And the following sets of routines are needed: (Note: replace "local-git-repo" with the appropriate path)
  * NuSTAR solar code in the shared Dropbox.
  	* This code is copied in the "image-Dropbox-copy" folder so you can just use add_path,'image-Dropbox-copy', /expand
  * NuSTAR IDL code: add_path,'~/local-git-repo/nustar-idl/', /expand
  * Brian's NuSTAR solar routines:  add_path,'~/local-git-repo/nustar_solar/', /expand
 
A copy of the Dropbox NuSTAR solar code is included here for convenience.