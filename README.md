# Viewid README
This repository is for the cl code "viewid" used for the analysis of SFACT objects. Written for IRAF, viewid will let you specify the objid of an SFACT object and display its photometric data in an already open ds9 window as well as open an sdss viewer window in safari to view the object through SDSS. If it can be found, the spectrum of the object will also be displayed and there is an option to compare the object in this table to a different table from a different SFACT processing run. This README was written to help other members of the SFACT team use viewid.

To use viewid, simply download viewid.cl and place it where ever you usually place IRAF cl scripts. Edit your loginuser.cl file to include viewid.cl and the path to where you have placed it. Boot up a ds9 window for use if it isn't already up. 

Once your loginuser.cl file is edited, you can start up IRAF. 
* Navigate to the Field_Database directory inside of SFACT on data4
* Choose any of the fields that have spectral data reintergrated with the photometric data and enter that directory.
  * For testing purposes I have been using SFF10-HADOT055
* Then type "viewid" into IRAF. 
* Provide the code with the table you wish to look at
  * I have been using hadot055_all_fin_spec_testing.tab
* Provide an object ID
  * I have been using SFF10_NB2_A8466
* Provide a scale factor for the display purposes through ds9.
  * I have been using 1

At this point the code should begin. It should automattically display the object in ds9 and pull it up in SDSS. It will then begin to check for the spectrum that accompanies the object. It currently checks for spectra in directories titled fieldnameA through E. If it finds one, it goes through and checks that directory for an object with matching object ID. Since many of the spectra at this point has used NUMID or SPECID for identification, it usually requires the user to provide the ID manually. The code will ask if the user would like to specify and, if an ID is provided, will pull up a spectrum with that ID.
* The SpecID for SFF10_NB2_A8466 is A5143

Next it will print out "relevant" table information (what information that is displayed is still under construction). Finally, it will ask if the user wants to view older table information. Currently, this section of the code is just a series of if statements without any real substance. When we add the oldID column to the data tables, this will be fleshed out more.

Any questions? Please contact me at carrdj@indiana.edu and I will happily help.
