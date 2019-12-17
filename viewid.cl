procedure viewid (table, targetid, scalefactor)

################################################################################
#
#	SFACT Code - Oct 2019 Version
#
################################################################################
#
#	This script takes a table with spectral information added to it, an ID for an
#	object, and a lookuptable for directory structure and shows the user an image
#	cutout, spectrum, sdss page, and table info for that object.
#	David 	10/08/19
#
################################################################################

string	table        {prompt="Table to be used"}
string  targetid     {prompt="Object ID you would like to view"}
real    scalefactor  {1.0,prompt="The scalefactor used to scale the OFF image to the ON image"}
struct  *fieldlookuptable
struct  *spectralookuptable
struct  *headerreader

begin

int	tab_numrows, j, xsize, ysize, x5, x6, ymiddle, y5, k
int y6, x1, x2, y1, y2, x3, x4, y3, y4, yp1, xp1, xp2, xp3, xc1, xc2, xc3, yc1
real ra_deg, dec_deg, midpt, Rmidpt, HAmidpt, HAdiffmidpt, x, y, scale
string	tab_name, target_id, objid, rimage, haimage, hadiffimage, NB_name
string  field_name, table_fieldname, field_path, spectra_path, section_name
string  hadot_name, table_sobsrun, sobsrun, spectra_path_pointing
string  spectra_path_pointing_SF_file, spectra_hadot_name, hadot_number
string  fieldlookuptable_name, spectralookuptable_name, header_param1
string  subsection, apID_string, apID, apNumber, onedSpec_path, onedSpec_number
string  new_spectra_target_ID, manual_ID, temp, view_old_table_info, old_table
string  path_to_older_table
bool found, spectra_name_ok, found_spectra, accessed_directory
file plotcoords

tab_name=table
target_id=targetid
scale=scalefactor

###############################################################################
#Set path for lookup tables.
fieldlookuptable_name = "/mnt/mintaka/data4/SFACT/SFACTcode/SFFieldLookupTable.txt"
spectralookuptable_name = "/mnt/mintaka/data4/SFACT/SFACTcode/SFSpectraLookupTable.txt"
fieldlookuptable = fieldlookuptable_name
spectralookuptable = spectralookuptable_name

print ("")
#print ("Please make sure ds9 is open and that the code knows where the lookup tables are.")
if (access(fieldlookuptable_name) == no){
  print ("Can't access field lookup table. Exiting...")
  bye
}

if (access(spectralookuptable_name) == no){
  print ("Can't access spectra lookup table. Exiting...")
  bye
}

#Check if ID is in the correct format for this version of the code.
if ((substr (target_id, 1, 3) != "SFF") || (substr (target_id, 7, 8) != "NB")){
  print ("TargetID different than expected. Can't find the ID in this code's current form. Exiting.")
  bye
}

#GET RID OF EXTENSION TO FILE NAMES
#Get rid of ".tab" extension
i=strlen(tab_name)
if (substr (tab_name, i-3, i) == ".tab")
{
	tab_name=substr(tab_name, 1, i-4)
}
#print ("viewid working on "//tab_name)

#READ IN NUMBER OF ROWS FOR LOOP USE
#Read in the number of rows in the table
tinfo(table=tab_name,
      ttout=no)

tab_numrows=tinfo.nrows
#print ("Table has "//tab_numrows//" rows")

#Set found to be no unless it is found
found = no

###############################################################################
#Find target_id in the table
for (j=1; j<=tab_numrows; j+=1){

  #Read in objid of each object
  tabpar(table=tab_name//".tab",
    column="OBJID",
    row=j)
  objid=str(tabpar.value)

  #############################################################################
  #If you can find the ID, operate on it
  if (objid == target_id) {
    #print (objid)
    #print (target_id)

    #Read in ra and dec of target object
		tabpar(table=tab_name//".tab",
		  column="RA_DEG",
			row=j)
		ra_deg=real(tabpar.value)

		tabpar(table=tab_name//".tab",
		  column="DEC_DEG",
			row=j)
		dec_deg=real(tabpar.value)
		#print (ra_deg, dec_deg)

    ###########################################################################
    #Display in ds9
    #Read in the path to the Continuum image, NB image, and NB subtracted image
    #from the lookup table
    field_name=substr(objid, 1, 5)
    NB_name=substr(objid, 7, 9)
    section_name=substr(objid, 11, 11)
    print ("viewid working on "//field_name//", "//NB_name//", and Sec"//section_name)

    #Match field from the id given
    while (fscan(fieldlookuptable, table_fieldname, field_path, hadot_name) != EOF){
      if (table_fieldname == field_name){
        break
      }
    }

    #Construct path to images
    field_path = field_path//"Sec"//section_name//"/"//NB_name//"/"
    print ("Path to image directory is\n"//field_path)
    rimage = field_path//""//hadot_name//""//section_name//"_"//NB_name//"_C.fits"
    haimage = field_path//""//hadot_name//""//section_name//"_"//NB_name//"_USNB.fits"
    hadiffimage = field_path//""//hadot_name//""//section_name//"_"//NB_name//"_NB.fits"
    #print ("Path to continuum image is\n"//rimage)

    ###########################################################################
    #The following is all taken from Classify to display the different necessary
    #images.

    #Get rid of ".fits" extention
    i=strlen(rimage)
    if (substr (rimage, i-4, i) == ".fits")
    {
        rimage=substr(rimage, 1, i-5)
    }
    #print (rimage)

    #Get rid of ".fits" extention
    i=strlen(haimage)
    if (substr (haimage, i-4, i) == ".fits")
    {
        haimage=substr(haimage, 1, i-5)
    }
    #print (haimage)

    #Get rid of ".fits" extention
    i=strlen(hadiffimage)
    if (substr (hadiffimage, i-4, i) == ".fits")
    {
      hadiffimage=substr(hadiffimage, 1, i-5)
    }
    #print (hadiffimage)

    #add back in x size and y size
    imgets(image=rimage//".fits",
      param="i_naxis1")
    xsize=int(imgets.value)

    imgets(image=rimage//".fits",
      param="i_naxis2")
    ysize=int(imgets.value)

    #Clean up if images were created before
    imdelete(rimage//"_sub.fits", ver-)
    imdelete(hadiffimage//"_sub.fits", ver-)
    imdelete(haimage//"_sub.fits", ver-)
    imdelete(rimage//"_sky.fits", ver-)
    imdelete(hadiffimage//"_sky.fits", ver-)
    imdelete(haimage//"_sky.fits", ver-)
    imdelete(rimage//"_sky_sc.fits", ver-)
    imdelete("big.fits", ver-)
    imdelete("wideHA.fits", ver-)
    imdelete("wideHAdiff.fits", ver-)
    imdelete("wideR.fits", ver-)
    imdelete("d2big.fits", ver-)
    imdelete("blank"//j//".fits", ver-)
    imdelete("d2blank"//j//".fits", ver-)

    #Determine background medians for proper display scaling.
	  #First create an image section that is wide (in x) and narrow up-down
    x5=100
		x6=xsize-100
		ymiddle=ysize/2
		y5=ymiddle-150
		y6=ymiddle+150

    imcopy(input=rimage//".fits["//x5//":"//x6//","//y5//":"//y6//"]",
      output="wideR.fits",
	    verbose=no)

		imcopy(input=haimage//".fits["//x5//":"//x6//","//y5//":"//y6//"]",
	    output="wideHA.fits",
	    verbose=no)

	  imcopy(input=hadiffimage//".fits["//x5//":"//x6//","//y5//":"//y6//"]",
	    output="wideHAdiff.fits",
	    verbose=no)

    #Find mean levels for each wide image
    imstat(images="wideR.fits",
      fields="midpt",
  		binwidth=0.01,
  	  format=no) | scan(midpt)
  	Rmidpt=midpt
  	#print,("The midpt of the R image is "//Rmidpt)

    imstat(images="wideHA.fits",
      fields="midpt",
  		binwidth=0.01,
  	  format=no) | scan(midpt)
  	HAmidpt=midpt
  	#print,("The midpt of the HA image is "//HAmidpt)

  	imstat(images="wideHAdiff.fits",
  	 fields="midpt",
  	 binwidth=0.01,
     format=no) | scan(midpt)
  	HAdiffmidpt=midpt
   	#print, ("The midpt of the HA subtracted image is "//HAdiffmidpt)

    #Get the x and y position for the target
    tabpar(table=tab_name//".tab",
	   column="XCENTER",
     row=j)
	  x=real(tabpar.value)
	  #print(x)

	  tabpar(table=tab_name//".tab",
	   column="YCENTER",
     row=j)
	  y=real(tabpar.value)
	  #print(y)

    #Calculate the coordinate for an image section of 200 units on a side
    #The image cutout will be centered around the object
		x1=x-100
	  x2=x+100
	  y1=y-100
	  y2=y+100

		yp1=5
		xp1=5
		xp2=210
		xp3=415

    if (x1 < 1){
		  x1=1
			xp1=106-x
			xp2=xp1+205
			xp3=xp2+205
		}
		if (x2 > xsize){
			x2=xsize
		}
		if (y1 < 1){
			y1=1
			yp1=106-y
		}
		if (y2 > ysize){
			y2=ysize
		}

    #IMCOPY out image sections to make cut-outs
		imcopy(input=rimage//".fits["//x1//":"//x2//","//y1//":"//y2//"]",
      output=rimage//"_sub",
	    verbose=no)

		imcopy(input=haimage//".fits["//x1//":"//x2//","//y1//":"//y2//"]",
	    output=haimage//"_sub",
      verbose=no)

		imcopy(input=hadiffimage//".fits["//x1//":"//x2//","//y1//":"//y2//"]",
      output=hadiffimage//"_sub",
	    verbose=no)

		#Subtract Median background from cutouts
		imarith(operand1=rimage//"_sub.fits",
      op="-",
      operand2=Rmidpt,
	    result=rimage//"_sky.fits",
      verbose=no)

		imarith(operand1=haimage//"_sub.fits",
      op="-",
      operand2=HAmidpt,
	    result=haimage//"_sky.fits",
      verbose=no)

		imarith(operand1=hadiffimage//"_sub.fits",
      op="-",
      operand2=HAdiffmidpt,
	    result=hadiffimage//"_sky.fits",
      verbose=no)

    #For R cut-out only, use IMARITH to divide by the scale factor
    #Scale factor prompted for, 6 works well
		imarith(operand1=rimage//"_sky.fits",
      op="/",
      operand2=scale,
	    result=rimage//"_sky_sc.fits",
      verbose=no)

    #Create composite R, HA unsubtracted, and HA subtracted image for display
    x3=(xsize/2)-310
  	x4=(xsize/2)+310
  	y3=(ysize/2)-105
  	y4=(ysize/2)+105

    imcopy(input=hadiffimage//".fits["//x3//":"//x4//","//y3//":"//y4//"]",
      output="big",
	    verbose=no)

		imarith(operand1="big.fits",
      op="-",
	    operand2="big.fits",
	    result="blank"//j//".fits",
	    verbose=no)

		imcopy(input=rimage//"_sky_sc.fits",
	    output="blank"//j//".fits["//xp1//":205,"//yp1//":205]",
		  verbose=no)

    imcopy(input=haimage//"_sky.fits",
	    output="blank"//j//".fits["//xp2//":410,"//yp1//":205]",
	    verbose=no)

		imcopy(input=hadiffimage//"_sky.fits",
	    output="blank"//j//".fits["//xp3//":615,"//yp1//":205]",
	    verbose=no)

    #Create another composite image for display which includes three images:
    #individual H-alpha subtracted image 1, individual subtracted H-alpha
    #image 2, and combined H-alpha subtracted image.
    #The purpose of displaying the individual H-alpha subtracted images is to
    #aid the user in determining if the detection is real (in which case it
    #should appear in both subtracted HA images) or a false detection caused by
    #a cosmic ray landing on one of the HA images.
  	imcopy(input=hadiffimage//".fits["//x3//":"//x4//","//y3//":"//y4//"]",
  	  output="d2big",
  	  verbose=no)

  	imarith(operand1="d2big.fits",
  	  op="-",
  	  operand2="d2big.fits",
  	  result="d2blank"//j//".fits",
  	  verbose=no)

  	imcopy(input=hadiffimage//"_sky.fits",
  	  output="d2blank"//j//".fits["//xp3//":615,"//yp1//":205]",
  	  verbose=no)

  	xc1 = 105
  	xc2 = 310
  	xc3 = 515
  	yc1 = 105
    plotcoords = mktemp("tmp$temp1")
		print(xc1, yc1, >> plotcoords)
		print(xc2, yc1, >> plotcoords)
		print(xc3, yc1, >> plotcoords)

    #Display the composite R, H-alpha, and H-alpha subtracted image! yay!
		display(image="blank"//j//".fits",
	   frame=1,
	   zscale=no,
	   zrange=no,
	   z1=-25,
	   z2=225)

    tvmark(frame=1,
 		 coords=plotcoords,
     commands="",
 		 mark="circle",
 		 radii=15,
 		 color=205)

    ###########################################################################
    #End contribution from Classify
    ###########################################################################

    ###########################################################################
    #Create bash file to open SDSS viewer window
    print ("#!/bin/bash", > "sdssviewerbashfile.txt")
    print ("open -a safari \"http://skyserver.sdss.org/dr15/en/tools/chart/navi.aspx?ra="//ra_deg//"&dec="//dec_deg//"&scale=0.1&width=120&height=120&opt=I\" -g", >> "sdssviewerbashfile.txt")
    #Open the window
    !bash sdssviewerbashfile.txt
    #Remove the textfile now that it has served its purpose
    delete ("sdssviewerbashfile.txt", ver-)

    ###########################################################################
    #Display spectrum
    #Get the sobsrun for the target
    tabpar(table=tab_name//".tab",
  	  column="sobsrun",
  		row=j)
  	sobsrun=str(tabpar.value)
  	#print (sobsrun)

    #Match directory from the id given
    while (fscan(spectralookuptable, table_sobsrun, spectra_path) != EOF){
      if (sobsrun == table_sobsrun){
        break
      }
    }

    #Construct path to spectra
    print ("")
    print ("Path to spectra directory is\n"//spectra_path)
    spectra_name_ok = yes
    found_spectra = no
    accessed_directory = no
    manual_ID = "no"
    new_spectra_target_ID = "NA"

    #Because of the way we do spectral processing, for some reason we go from
    #lower case to upper case letters. I have hardcoded a method to deal with
    #this but it only works with fields titled hadot or sfact. Hopefully for
    #future fields we can change this to work (like for the kr#### fields).
    #I have tried to code in error checking for these types of issues.
    if (substr(hadot_name, 1, 5) == "hadot"){
      spectra_hadot_name = "HADot"//substr(hadot_name, 6, strlen(hadot_name))
    }
    else if (substr(hadot_name, 1, 5) == "sfact"){
      spectra_hadot_name = "SFACT"//substr(hadot_name, 6, strlen(hadot_name))
    }
    else {
      print("Unexpected name for field while looking in this directory. Unable to display spectra.")
      spectra_name_ok = no
    }

    #Check to see if pointing file A, B, C, D, or E exist. Then checks in each
    #that exist for the ID.
    print ("Checking for pointing files A through E.")
    if (access(spectra_path//""//hadot_name//"A")){

      ##########################################################################
      #Now that we have identified the directory to try to find the object in,
      #we have to find the object.
      #Repeat this part in each else if statement

      #CHANGE THIS EACH ELSE IF STATEMENT!!!!!!!!!!!!!!!!!!!!!!!!
      subsection = "A"

      print ("Checking pointing "//hadot_name//""//subsection)
      spectra_path_pointing = spectra_path//""//hadot_name//""//subsection//"/"
      accessed_directory = yes

      #If the field is found ok, we can now start looking at the _SF.ms.fits
      #file and use that to find our spectra.
      if (spectra_name_ok == yes){
        spectra_path_pointing_SF_file = spectra_path_pointing//""//spectra_hadot_name//""//subsection//"_SF.ms.fits"

        #Get ID and Apperture IDs from header info. Print header to a textfile
        #read through that text file until you find the apID_string stuff, then use
        #that to check our target ID vs the ID of each SFACT spectra.
        imhead(images=spectra_path_pointing_SF_file,
          imlist=spectra_path_pointing_SF_file,
          longheader=yes,
          userfields=yes, > "SF_ms_header.txt")

        headerreader = "SF_ms_header.txt"

        while (fscan(headerreader, header_param1) != EOF){
          if (substr(header_param1, 1, 4) == "APID"){
            keypar(input=spectra_path_pointing_SF_file,
              keyword=header_param1)
            apID_string=str(keypar.value)
            #print (header_param1//" and "//apID_string)

            #Find where the ID ends in the string
            i = strlen(apID_string)
            k = 1
            while (substr(apID_string, k, k) != " "){
              k = k+1
            }
            apID = substr(apID_string, 1, k-1)

            #Now we have to check if each ID matches our targetid
            #"A5143" or target_id
            if (apID == target_id){
              #If it does we display the spectrum
              print ("The code automatically found the target spectra. Displaying.")
              apNumber = substr(header_param1, 5, strlen(header_param1))
              onedSpec_path = spectra_path_pointing//"WRALFoutput/"//spectra_hadot_name//"_"//subsection//"_fittedspectra/"
              if (strlen(apNumber) == 1){
                onedSpec_number = "0"//apNumber
              }
              else {
                onedSpec_number = apNumber
              }

              ##################################################################
              #Create bash file to open png
              print ("#!/bin/bash", > "pngviewerbashfile.txt")
              print ("open -a preview \""//onedSpec_path//"1dspec.00"//onedSpec_number//".fits.png\" -gj", >> "pngviewerbashfile.txt")
              #Open the window
              !bash pngviewerbashfile.txt
              #Remove the textfile now that it has served its purpose
              delete ("pngviewerbashfile.txt", ver-)

              found_spectra = yes
              break
            }
          }
        }

        #Delete header textfile
        delete ("SF_ms_header.txt", ver-)
      }
      else {
        #If we can't find the location for the spectra then the code redirects
        #to here.
        print ("")
        print ("Unable to display spectra, probably because the code looked in the wrong location and couldn't find it.")
        print ("Code looked at this location:")
        print (spectra_path_pointing//""//hadot_name//""//subsection//"_SF.ms.fits")
        print ("Hopefully that helps you figure out what went wrong...")
      }
    }
    if (access(spectra_path//""//hadot_name//"B")){

      ##########################################################################
      #Now that we have identified the directory to try to find the object in,
      #we have to find the object.
      #Repeat this part in each else if statement

      #CHANGE THIS EACH ELSE IF STATEMENT!!!!!!!!!!!!!!!!!!!!!!!!
      subsection = "B"

      print ("Checking pointing "//hadot_name//""//subsection)
      spectra_path_pointing = spectra_path//""//hadot_name//""//subsection//"/"
      accessed_directory = yes

      #If the field is found ok, we can now start looking at the _SF.ms.fits
      #file and use that to find our spectra.
      if (spectra_name_ok == yes){
        spectra_path_pointing_SF_file = spectra_path_pointing//""//spectra_hadot_name//""//subsection//"_SF.ms.fits"

        #Get ID and Apperture IDs from header info. Print header to a textfile
        #read through that text file until you find the apID_string stuff, then use
        #that to check our target ID vs the ID of each SFACT spectra.
        imhead(images=spectra_path_pointing_SF_file,
          imlist=spectra_path_pointing_SF_file,
          longheader=yes,
          userfields=yes, > "SF_ms_header.txt")

        headerreader = "SF_ms_header.txt"

        while (fscan(headerreader, header_param1) != EOF){
          if (substr(header_param1, 1, 4) == "APID"){
            keypar(input=spectra_path_pointing_SF_file,
              keyword=header_param1)
            apID_string=str(keypar.value)
            #print (header_param1//" and "//apID_string)

            #Find where the ID ends in the string
            i = strlen(apID_string)
            k = 1
            while (substr(apID_string, k, k) != " "){
              k = k+1
            }
            apID = substr(apID_string, 1, k-1)

            #Now we have to check if each ID matches our targetid
            #"A5143" or target_id
            if (apID == target_id){
              #If it does we display the spectrum
              print ("The code automatically found the target spectra. Displaying.")
              apNumber = substr(header_param1, 5, strlen(header_param1))
              onedSpec_path = spectra_path_pointing//"WRALFoutput/"//spectra_hadot_name//"_"//subsection//"_fittedspectra/"
              if (strlen(apNumber) == 1){
                onedSpec_number = "0"//apNumber
              }
              else {
                onedSpec_number = apNumber
              }

              ##################################################################
              #Create bash file to open png
              print ("#!/bin/bash", > "pngviewerbashfile.txt")
              print ("open -a preview \""//onedSpec_path//"1dspec.00"//onedSpec_number//".fits.png\" -gj", >> "pngviewerbashfile.txt")
              #Open the window
              !bash pngviewerbashfile.txt
              #Remove the textfile now that it has served its purpose
              delete ("pngviewerbashfile.txt", ver-)

              found_spectra = yes
              break
            }
          }
        }

        #Delete header textfile
        delete ("SF_ms_header.txt", ver-)
      }
      else {
        #If we can't find the location for the spectra then the code redirects
        #to here.
        print ("")
        print ("Unable to display spectra, probably because the code looked in the wrong location and couldn't find it.")
        print ("Code looked at this location:")
        print (spectra_path_pointing//""//hadot_name//""//subsection//"_SF.ms.fits")
        print ("Hopefully that helps you figure out what went wrong...")
      }
    }
    if (access(spectra_path//""//hadot_name//"C")){

      ##########################################################################
      #Now that we have identified the directory to try to find the object in,
      #we have to find the object.
      #Repeat this part in each else if statement

      #CHANGE THIS EACH ELSE IF STATEMENT!!!!!!!!!!!!!!!!!!!!!!!!
      subsection = "C"

      print ("Checking pointing "//hadot_name//""//subsection)
      spectra_path_pointing = spectra_path//""//hadot_name//""//subsection//"/"
      accessed_directory = yes

      #If the field is found ok, we can now start looking at the _SF.ms.fits
      #file and use that to find our spectra.
      if (spectra_name_ok == yes){
        spectra_path_pointing_SF_file = spectra_path_pointing//""//spectra_hadot_name//""//subsection//"_SF.ms.fits"

        #Get ID and Apperture IDs from header info. Print header to a textfile
        #read through that text file until you find the apID_string stuff, then use
        #that to check our target ID vs the ID of each SFACT spectra.
        imhead(images=spectra_path_pointing_SF_file,
          imlist=spectra_path_pointing_SF_file,
          longheader=yes,
          userfields=yes, > "SF_ms_header.txt")

        headerreader = "SF_ms_header.txt"

        while (fscan(headerreader, header_param1) != EOF){
          if (substr(header_param1, 1, 4) == "APID"){
            keypar(input=spectra_path_pointing_SF_file,
              keyword=header_param1)
            apID_string=str(keypar.value)
            #print (header_param1//" and "//apID_string)

            #Find where the ID ends in the string
            i = strlen(apID_string)
            k = 1
            while (substr(apID_string, k, k) != " "){
              k = k+1
            }
            apID = substr(apID_string, 1, k-1)

            #Now we have to check if each ID matches our targetid
            #"A5143" or target_id
            if (apID == target_id){
              #If it does we display the spectrum
              print ("The code automatically found the target spectra. Displaying.")
              apNumber = substr(header_param1, 5, strlen(header_param1))
              onedSpec_path = spectra_path_pointing//"WRALFoutput/"//spectra_hadot_name//"_"//subsection//"_fittedspectra/"
              if (strlen(apNumber) == 1){
                onedSpec_number = "0"//apNumber
              }
              else {
                onedSpec_number = apNumber
              }

              ##################################################################
              #Create bash file to open png
              print ("#!/bin/bash", > "pngviewerbashfile.txt")
              print ("open -a preview \""//onedSpec_path//"1dspec.00"//onedSpec_number//".fits.png\" -gj", >> "pngviewerbashfile.txt")
              #Open the window
              !bash pngviewerbashfile.txt
              #Remove the textfile now that it has served its purpose
              delete ("pngviewerbashfile.txt", ver-)

              found_spectra = yes
              break
            }
          }
        }

        #Delete header textfile
        delete ("SF_ms_header.txt", ver-)
      }
      else {
        #If we can't find the location for the spectra then the code redirects
        #to here.
        print ("")
        print ("Unable to display spectra, probably because the code looked in the wrong location and couldn't find it.")
        print ("Code looked at this location:")
        print (spectra_path_pointing//""//hadot_name//""//subsection//"_SF.ms.fits")
        print ("Hopefully that helps you figure out what went wrong...")
      }
    }
    if (access(spectra_path//""//hadot_name//"D")){

      ##########################################################################
      #Now that we have identified the directory to try to find the object in,
      #we have to find the object.
      #Repeat this part in each else if statement

      #CHANGE THIS EACH ELSE IF STATEMENT!!!!!!!!!!!!!!!!!!!!!!!!
      subsection = "D"

      print ("Checking pointing "//hadot_name//""//subsection)
      spectra_path_pointing = spectra_path//""//hadot_name//""//subsection//"/"
      accessed_directory = yes

      #If the field is found ok, we can now start looking at the _SF.ms.fits
      #file and use that to find our spectra.
      if (spectra_name_ok == yes){
        spectra_path_pointing_SF_file = spectra_path_pointing//""//spectra_hadot_name//""//subsection//"_SF.ms.fits"

        #Get ID and Apperture IDs from header info. Print header to a textfile
        #read through that text file until you find the apID_string stuff, then use
        #that to check our target ID vs the ID of each SFACT spectra.
        imhead(images=spectra_path_pointing_SF_file,
          imlist=spectra_path_pointing_SF_file,
          longheader=yes,
          userfields=yes, > "SF_ms_header.txt")

        headerreader = "SF_ms_header.txt"

        while (fscan(headerreader, header_param1) != EOF){
          if (substr(header_param1, 1, 4) == "APID"){
            keypar(input=spectra_path_pointing_SF_file,
              keyword=header_param1)
            apID_string=str(keypar.value)
            #print (header_param1//" and "//apID_string)

            #Find where the ID ends in the string
            i = strlen(apID_string)
            k = 1
            while (substr(apID_string, k, k) != " "){
              k = k+1
            }
            apID = substr(apID_string, 1, k-1)

            #Now we have to check if each ID matches our targetid
            #"A5143" or target_id
            if (apID == target_id){
              #If it does we display the spectrum
              print ("The code automatically found the target spectra. Displaying.")
              apNumber = substr(header_param1, 5, strlen(header_param1))
              onedSpec_path = spectra_path_pointing//"WRALFoutput/"//spectra_hadot_name//"_"//subsection//"_fittedspectra/"
              if (strlen(apNumber) == 1){
                onedSpec_number = "0"//apNumber
              }
              else {
                onedSpec_number = apNumber
              }

              ##################################################################
              #Create bash file to open png
              print ("#!/bin/bash", > "pngviewerbashfile.txt")
              print ("open -a preview \""//onedSpec_path//"1dspec.00"//onedSpec_number//".fits.png\" -gj", >> "pngviewerbashfile.txt")
              #Open the window
              !bash pngviewerbashfile.txt
              #Remove the textfile now that it has served its purpose
              delete ("pngviewerbashfile.txt", ver-)

              found_spectra = yes
              break
            }
          }
        }

        #Delete header textfile
        delete ("SF_ms_header.txt", ver-)
      }
      else {
        #If we can't find the location for the spectra then the code redirects
        #to here.
        print ("")
        print ("Unable to display spectra, probably because the code looked in the wrong location and couldn't find it.")
        print ("Code looked at this location:")
        print (spectra_path_pointing//""//hadot_name//""//subsection//"_SF.ms.fits")
        print ("Hopefully that helps you figure out what went wrong...")
      }
    }
    if (access(spectra_path//""//hadot_name//"E")){

      ##########################################################################
      #Now that we have identified the directory to try to find the object in,
      #we have to find the object.
      #Repeat this part in each else if statement

      #CHANGE THIS EACH ELSE IF STATEMENT!!!!!!!!!!!!!!!!!!!!!!!!
      subsection = "E"

      print ("Checking pointing "//hadot_name//""//subsection)
      spectra_path_pointing = spectra_path//""//hadot_name//""//subsection//"/"
      accessed_directory = yes

      #If the field is found ok, we can now start looking at the _SF.ms.fits
      #file and use that to find our spectra.
      if (spectra_name_ok == yes){
        spectra_path_pointing_SF_file = spectra_path_pointing//""//spectra_hadot_name//""//subsection//"_SF.ms.fits"

        #Get ID and Apperture IDs from header info. Print header to a textfile
        #read through that text file until you find the apID_string stuff, then use
        #that to check our target ID vs the ID of each SFACT spectra.
        imhead(images=spectra_path_pointing_SF_file,
          imlist=spectra_path_pointing_SF_file,
          longheader=yes,
          userfields=yes, > "SF_ms_header.txt")

        headerreader = "SF_ms_header.txt"

        while (fscan(headerreader, header_param1) != EOF){
          if (substr(header_param1, 1, 4) == "APID"){
            keypar(input=spectra_path_pointing_SF_file,
              keyword=header_param1)
            apID_string=str(keypar.value)
            #print (header_param1//" and "//apID_string)

            #Find where the ID ends in the string
            i = strlen(apID_string)
            k = 1
            while (substr(apID_string, k, k) != " "){
              k = k+1
            }
            apID = substr(apID_string, 1, k-1)

            #Now we have to check if each ID matches our targetid
            #"A5143" or target_id
            if (apID == target_id){
              #If it does we display the spectrum
              print ("The code automatically found the target spectra. Displaying.")
              apNumber = substr(header_param1, 5, strlen(header_param1))
              onedSpec_path = spectra_path_pointing//"WRALFoutput/"//spectra_hadot_name//"_"//subsection//"_fittedspectra/"
              if (strlen(apNumber) == 1){
                onedSpec_number = "0"//apNumber
              }
              else {
                onedSpec_number = apNumber
              }

              ##################################################################
              #Create bash file to open png
              print ("#!/bin/bash", > "pngviewerbashfile.txt")
              print ("open -a preview \""//onedSpec_path//"1dspec.00"//onedSpec_number//".fits.png\" -gj", >> "pngviewerbashfile.txt")
              #Open the window
              !bash pngviewerbashfile.txt
              #Remove the textfile now that it has served its purpose
              delete ("pngviewerbashfile.txt", ver-)

              found_spectra = yes
              break
            }
          }
        }

        #Delete header textfile
        delete ("SF_ms_header.txt", ver-)
      }
      else {
        #If we can't find the location for the spectra then the code redirects
        #to here.
        print ("")
        print ("Unable to display spectra, probably because the code looked in the wrong location and couldn't find it.")
        print ("Code looked at this location:")
        print (spectra_path_pointing//""//hadot_name//""//subsection//"_SF.ms.fits")
        print ("Hopefully that helps you figure out what went wrong...")
      }
    }
    if (accessed_directory == no) {
      #If none of those directories (A - E) exist the code redirects to here.
      print ("")
      print ("No spectra directory found. Can't display spectra.")
      print ("Checked pointing locations")
      print (spectra_path//""//hadot_name//"A")
      print ("through")
      print (spectra_path//""//hadot_name//"E")
      print ("without success.")
    }

    ############################################################################
    #Check here to see if an older ID for the object exists.
    #if (found_spectra == no){

    #}

    if (found_spectra == no) {
      #If the spectra wasn't found the code redirects to here.
      print ("")
      print ("No spectra found automatically.\nThis most likely means the spectra didn't use the current ID.")

      ##########################################################################
      #Check here if the user wants to manually enter the ID of the object.

      while (manual_ID == "no"){
        print ("Would you like to enter the ID manually? (yes or no)")
        scan(manual_ID)

        if (manual_ID == "yes"){
          print ("Please enter the ID of the target.")
          scan(new_spectra_target_ID)
          temp = target_id
          target_id = new_spectra_target_ID

          #Now do it all again with the new ID
          accessed_directory = no

          #Check to see if pointing file A, B, C, D, or E exist. Then checks in each
          #that exist for the ID.
          print ("Checking for pointing files A through E.")
          if (access(spectra_path//""//hadot_name//"A")){

            ##########################################################################
            #Now that we have identified the directory to try to find the object in,
            #we have to find the object.
            #Repeat this part in each else if statement

            #CHANGE THIS EACH ELSE IF STATEMENT!!!!!!!!!!!!!!!!!!!!!!!!
            subsection = "A"

            print ("Checking pointing "//hadot_name//""//subsection)
            spectra_path_pointing = spectra_path//""//hadot_name//""//subsection//"/"
            accessed_directory = yes

            #If the field is found ok, we can now start looking at the _SF.ms.fits
            #file and use that to find our spectra.
            if (spectra_name_ok == yes){
              spectra_path_pointing_SF_file = spectra_path_pointing//""//spectra_hadot_name//""//subsection//"_SF.ms.fits"

              #Get ID and Apperture IDs from header info. Print header to a textfile
              #read through that text file until you find the apID_string stuff, then use
              #that to check our target ID vs the ID of each SFACT spectra.
              imhead(images=spectra_path_pointing_SF_file,
                imlist=spectra_path_pointing_SF_file,
                longheader=yes,
                userfields=yes, > "SF_ms_header.txt")

              headerreader = "SF_ms_header.txt"

              while (fscan(headerreader, header_param1) != EOF){
                if (substr(header_param1, 1, 4) == "APID"){
                  keypar(input=spectra_path_pointing_SF_file,
                    keyword=header_param1)
                  apID_string=str(keypar.value)
                  #print (header_param1//" and "//apID_string)

                  #Find where the ID ends in the string
                  i = strlen(apID_string)
                  k = 1
                  while (substr(apID_string, k, k) != " "){
                    k = k+1
                  }
                  apID = substr(apID_string, 1, k-1)

                  #Now we have to check if each ID matches our targetid
                  #"A5143" or target_id
                  if (apID == target_id){
                    #If it does we display the spectrum
                    print ("The code automatically found the target spectra. Displaying.")
                    apNumber = substr(header_param1, 5, strlen(header_param1))
                    onedSpec_path = spectra_path_pointing//"WRALFoutput/"//spectra_hadot_name//"_"//subsection//"_fittedspectra/"
                    if (strlen(apNumber) == 1){
                      onedSpec_number = "0"//apNumber
                    }
                    else {
                      onedSpec_number = apNumber
                    }

                    ##################################################################
                    #Create bash file to open png
                    print ("#!/bin/bash", > "pngviewerbashfile.txt")
                    print ("open -a preview \""//onedSpec_path//"1dspec.00"//onedSpec_number//".fits.png\" -gj", >> "pngviewerbashfile.txt")
                    #Open the window
                    !bash pngviewerbashfile.txt
                    #Remove the textfile now that it has served its purpose
                    delete ("pngviewerbashfile.txt", ver-)

                    found_spectra = yes
                    break
                  }
                }
              }

              #Delete header textfile
              delete ("SF_ms_header.txt", ver-)
            }
            else {
              #If we can't find the location for the spectra then the code redirects
              #to here.
              print ("")
              print ("Unable to display spectra, probably because the code looked in the wrong location and couldn't find it.")
              print ("Code looked at this location:")
              print (spectra_path_pointing//""//hadot_name//""//subsection//"_SF.ms.fits")
              print ("Hopefully that helps you figure out what went wrong...")
            }
          }
          if (access(spectra_path//""//hadot_name//"B")){

            ##########################################################################
            #Now that we have identified the directory to try to find the object in,
            #we have to find the object.
            #Repeat this part in each else if statement

            #CHANGE THIS EACH ELSE IF STATEMENT!!!!!!!!!!!!!!!!!!!!!!!!
            subsection = "B"

            print ("Checking pointing "//hadot_name//""//subsection)
            spectra_path_pointing = spectra_path//""//hadot_name//""//subsection//"/"
            accessed_directory = yes

            #If the field is found ok, we can now start looking at the _SF.ms.fits
            #file and use that to find our spectra.
            if (spectra_name_ok == yes){
              spectra_path_pointing_SF_file = spectra_path_pointing//""//spectra_hadot_name//""//subsection//"_SF.ms.fits"

              #Get ID and Apperture IDs from header info. Print header to a textfile
              #read through that text file until you find the apID_string stuff, then use
              #that to check our target ID vs the ID of each SFACT spectra.
              imhead(images=spectra_path_pointing_SF_file,
                imlist=spectra_path_pointing_SF_file,
                longheader=yes,
                userfields=yes, > "SF_ms_header.txt")

              headerreader = "SF_ms_header.txt"

              while (fscan(headerreader, header_param1) != EOF){
                if (substr(header_param1, 1, 4) == "APID"){
                  keypar(input=spectra_path_pointing_SF_file,
                    keyword=header_param1)
                  apID_string=str(keypar.value)
                  #print (header_param1//" and "//apID_string)

                  #Find where the ID ends in the string
                  i = strlen(apID_string)
                  k = 1
                  while (substr(apID_string, k, k) != " "){
                    k = k+1
                  }
                  apID = substr(apID_string, 1, k-1)

                  #Now we have to check if each ID matches our targetid
                  #"A5143" or target_id
                  if (apID == target_id){
                    #If it does we display the spectrum
                    print ("The code automatically found the target spectra. Displaying.")
                    apNumber = substr(header_param1, 5, strlen(header_param1))
                    onedSpec_path = spectra_path_pointing//"WRALFoutput/"//spectra_hadot_name//"_"//subsection//"_fittedspectra/"
                    if (strlen(apNumber) == 1){
                      onedSpec_number = "0"//apNumber
                    }
                    else {
                      onedSpec_number = apNumber
                    }

                    ##################################################################
                    #Create bash file to open png
                    print ("#!/bin/bash", > "pngviewerbashfile.txt")
                    print ("open -a preview \""//onedSpec_path//"1dspec.00"//onedSpec_number//".fits.png\" -gj", >> "pngviewerbashfile.txt")
                    #Open the window
                    !bash pngviewerbashfile.txt
                    #Remove the textfile now that it has served its purpose
                    delete ("pngviewerbashfile.txt", ver-)

                    found_spectra = yes
                    break
                  }
                }
              }

              #Delete header textfile
              delete ("SF_ms_header.txt", ver-)
            }
            else {
              #If we can't find the location for the spectra then the code redirects
              #to here.
              print ("")
              print ("Unable to display spectra, probably because the code looked in the wrong location and couldn't find it.")
              print ("Code looked at this location:")
              print (spectra_path_pointing//""//hadot_name//""//subsection//"_SF.ms.fits")
              print ("Hopefully that helps you figure out what went wrong...")
            }
          }
          if (access(spectra_path//""//hadot_name//"C")){

            ##########################################################################
            #Now that we have identified the directory to try to find the object in,
            #we have to find the object.
            #Repeat this part in each else if statement

            #CHANGE THIS EACH ELSE IF STATEMENT!!!!!!!!!!!!!!!!!!!!!!!!
            subsection = "C"

            print ("Checking pointing "//hadot_name//""//subsection)
            spectra_path_pointing = spectra_path//""//hadot_name//""//subsection//"/"
            accessed_directory = yes

            #If the field is found ok, we can now start looking at the _SF.ms.fits
            #file and use that to find our spectra.
            if (spectra_name_ok == yes){
              spectra_path_pointing_SF_file = spectra_path_pointing//""//spectra_hadot_name//""//subsection//"_SF.ms.fits"

              #Get ID and Apperture IDs from header info. Print header to a textfile
              #read through that text file until you find the apID_string stuff, then use
              #that to check our target ID vs the ID of each SFACT spectra.
              imhead(images=spectra_path_pointing_SF_file,
                imlist=spectra_path_pointing_SF_file,
                longheader=yes,
                userfields=yes, > "SF_ms_header.txt")

              headerreader = "SF_ms_header.txt"

              while (fscan(headerreader, header_param1) != EOF){
                if (substr(header_param1, 1, 4) == "APID"){
                  keypar(input=spectra_path_pointing_SF_file,
                    keyword=header_param1)
                  apID_string=str(keypar.value)
                  #print (header_param1//" and "//apID_string)

                  #Find where the ID ends in the string
                  i = strlen(apID_string)
                  k = 1
                  while (substr(apID_string, k, k) != " "){
                    k = k+1
                  }
                  apID = substr(apID_string, 1, k-1)

                  #Now we have to check if each ID matches our targetid
                  #"A5143" or target_id
                  if (apID == target_id){
                    #If it does we display the spectrum
                    print ("The code automatically found the target spectra. Displaying.")
                    apNumber = substr(header_param1, 5, strlen(header_param1))
                    onedSpec_path = spectra_path_pointing//"WRALFoutput/"//spectra_hadot_name//"_"//subsection//"_fittedspectra/"
                    if (strlen(apNumber) == 1){
                      onedSpec_number = "0"//apNumber
                    }
                    else {
                      onedSpec_number = apNumber
                    }

                    ##################################################################
                    #Create bash file to open png
                    print ("#!/bin/bash", > "pngviewerbashfile.txt")
                    print ("open -a preview \""//onedSpec_path//"1dspec.00"//onedSpec_number//".fits.png\" -gj", >> "pngviewerbashfile.txt")
                    #Open the window
                    !bash pngviewerbashfile.txt
                    #Remove the textfile now that it has served its purpose
                    delete ("pngviewerbashfile.txt", ver-)

                    found_spectra = yes
                    break
                  }
                }
              }

              #Delete header textfile
              delete ("SF_ms_header.txt", ver-)
            }
            else {
              #If we can't find the location for the spectra then the code redirects
              #to here.
              print ("")
              print ("Unable to display spectra, probably because the code looked in the wrong location and couldn't find it.")
              print ("Code looked at this location:")
              print (spectra_path_pointing//""//hadot_name//""//subsection//"_SF.ms.fits")
              print ("Hopefully that helps you figure out what went wrong...")
            }
          }
          if (access(spectra_path//""//hadot_name//"D")){

            ##########################################################################
            #Now that we have identified the directory to try to find the object in,
            #we have to find the object.
            #Repeat this part in each else if statement

            #CHANGE THIS EACH ELSE IF STATEMENT!!!!!!!!!!!!!!!!!!!!!!!!
            subsection = "D"

            print ("Checking pointing "//hadot_name//""//subsection)
            spectra_path_pointing = spectra_path//""//hadot_name//""//subsection//"/"
            accessed_directory = yes

            #If the field is found ok, we can now start looking at the _SF.ms.fits
            #file and use that to find our spectra.
            if (spectra_name_ok == yes){
              spectra_path_pointing_SF_file = spectra_path_pointing//""//spectra_hadot_name//""//subsection//"_SF.ms.fits"

              #Get ID and Apperture IDs from header info. Print header to a textfile
              #read through that text file until you find the apID_string stuff, then use
              #that to check our target ID vs the ID of each SFACT spectra.
              imhead(images=spectra_path_pointing_SF_file,
                imlist=spectra_path_pointing_SF_file,
                longheader=yes,
                userfields=yes, > "SF_ms_header.txt")

              headerreader = "SF_ms_header.txt"

              while (fscan(headerreader, header_param1) != EOF){
                if (substr(header_param1, 1, 4) == "APID"){
                  keypar(input=spectra_path_pointing_SF_file,
                    keyword=header_param1)
                  apID_string=str(keypar.value)
                  #print (header_param1//" and "//apID_string)

                  #Find where the ID ends in the string
                  i = strlen(apID_string)
                  k = 1
                  while (substr(apID_string, k, k) != " "){
                    k = k+1
                  }
                  apID = substr(apID_string, 1, k-1)

                  #Now we have to check if each ID matches our targetid
                  #"A5143" or target_id
                  if (apID == target_id){
                    #If it does we display the spectrum
                    print ("The code automatically found the target spectra. Displaying.")
                    apNumber = substr(header_param1, 5, strlen(header_param1))
                    onedSpec_path = spectra_path_pointing//"WRALFoutput/"//spectra_hadot_name//"_"//subsection//"_fittedspectra/"
                    if (strlen(apNumber) == 1){
                      onedSpec_number = "0"//apNumber
                    }
                    else {
                      onedSpec_number = apNumber
                    }

                    ##################################################################
                    #Create bash file to open png
                    print ("#!/bin/bash", > "pngviewerbashfile.txt")
                    print ("open -a preview \""//onedSpec_path//"1dspec.00"//onedSpec_number//".fits.png\" -gj", >> "pngviewerbashfile.txt")
                    #Open the window
                    !bash pngviewerbashfile.txt
                    #Remove the textfile now that it has served its purpose
                    delete ("pngviewerbashfile.txt", ver-)

                    found_spectra = yes
                    break
                  }
                }
              }

              #Delete header textfile
              delete ("SF_ms_header.txt", ver-)
            }
            else {
              #If we can't find the location for the spectra then the code redirects
              #to here.
              print ("")
              print ("Unable to display spectra, probably because the code looked in the wrong location and couldn't find it.")
              print ("Code looked at this location:")
              print (spectra_path_pointing//""//hadot_name//""//subsection//"_SF.ms.fits")
              print ("Hopefully that helps you figure out what went wrong...")
            }
          }
          if (access(spectra_path//""//hadot_name//"E")){

            ##########################################################################
            #Now that we have identified the directory to try to find the object in,
            #we have to find the object.
            #Repeat this part in each else if statement

            #CHANGE THIS EACH ELSE IF STATEMENT!!!!!!!!!!!!!!!!!!!!!!!!
            subsection = "E"

            print ("Checking pointing "//hadot_name//""//subsection)
            spectra_path_pointing = spectra_path//""//hadot_name//""//subsection//"/"
            accessed_directory = yes

            #If the field is found ok, we can now start looking at the _SF.ms.fits
            #file and use that to find our spectra.
            if (spectra_name_ok == yes){
              spectra_path_pointing_SF_file = spectra_path_pointing//""//spectra_hadot_name//""//subsection//"_SF.ms.fits"

              #Get ID and Apperture IDs from header info. Print header to a textfile
              #read through that text file until you find the apID_string stuff, then use
              #that to check our target ID vs the ID of each SFACT spectra.
              imhead(images=spectra_path_pointing_SF_file,
                imlist=spectra_path_pointing_SF_file,
                longheader=yes,
                userfields=yes, > "SF_ms_header.txt")

              headerreader = "SF_ms_header.txt"

              while (fscan(headerreader, header_param1) != EOF){
                if (substr(header_param1, 1, 4) == "APID"){
                  keypar(input=spectra_path_pointing_SF_file,
                    keyword=header_param1)
                  apID_string=str(keypar.value)
                  #print (header_param1//" and "//apID_string)

                  #Find where the ID ends in the string
                  i = strlen(apID_string)
                  k = 1
                  while (substr(apID_string, k, k) != " "){
                    k = k+1
                  }
                  apID = substr(apID_string, 1, k-1)

                  #Now we have to check if each ID matches our targetid
                  #"A5143" or target_id
                  if (apID == target_id){
                    #If it does we display the spectrum
                    print ("The code automatically found the target spectra. Displaying.")
                    apNumber = substr(header_param1, 5, strlen(header_param1))
                    onedSpec_path = spectra_path_pointing//"WRALFoutput/"//spectra_hadot_name//"_"//subsection//"_fittedspectra/"
                    if (strlen(apNumber) == 1){
                      onedSpec_number = "0"//apNumber
                    }
                    else {
                      onedSpec_number = apNumber
                    }

                    ##################################################################
                    #Create bash file to open png
                    print ("#!/bin/bash", > "pngviewerbashfile.txt")
                    print ("open -a preview \""//onedSpec_path//"1dspec.00"//onedSpec_number//".fits.png\" -gj", >> "pngviewerbashfile.txt")
                    #Open the window
                    !bash pngviewerbashfile.txt
                    #Remove the textfile now that it has served its purpose
                    delete ("pngviewerbashfile.txt", ver-)

                    found_spectra = yes
                    break
                  }
                }
              }

              #Delete header textfile
              delete ("SF_ms_header.txt", ver-)
            }
            else {
              #If we can't find the location for the spectra then the code redirects
              #to here.
              print ("")
              print ("Unable to display spectra, probably because the code looked in the wrong location and couldn't find it.")
              print ("Code looked at this location:")
              print (spectra_path_pointing//""//hadot_name//""//subsection//"_SF.ms.fits")
              print ("Hopefully that helps you figure out what went wrong...")
            }
          }
          if (accessed_directory == no) {
            #If none of those directories (A - E) exist the code redirects to here.
            print ("")
            print ("No spectra directory found. Can't display spectra.")
            print ("Checked pointing locations")
            print (spectra_path//""//hadot_name//"A")
            print ("through")
            print (spectra_path//""//hadot_name//"E")
            print ("without success.")
          }
          if (found_spectra == no) {
            #If the spectra wasn't found the code redirects to here.
            print ("No spectra found automatically. This most likely means the ID is wrong or doesn't exist.")
          }
          target_id = temp
        }
        else if (manual_ID != "yes"){
          if (manual_ID == "no"){
            print ("Not displaying any spectra")
            break
          }
          else {
            print ("Not a valid input. Enter yes or no.")
            manual_ID = "no"
          }
        }
      }
    }

    ###########################################################################
    #Print relevant table information
    print ("")
    tprint(table=tab_name//".tab",
      prparam=no,
      prdata=yes,
      pwidth=80,
      plength=0,
      showrow=yes,
      orig_row=yes,
      showhdr=yes,
      showunits=yes,
      columns="OBJID,RA,DEC,MAGDIFF,RATIO,sobsrun",
      rows=j,
      option="plain",
      align=yes,
      sp_col="",
      lgroup=0)

    ###########################################################################
    #Check if they would like to view older table information
    view_old_table_info = "yes"
    print("")

    while (view_old_table_info == "yes"){
      print ("Would you like to compare this object with data from an older table? (yes or no)")
      scan(view_old_table_info)

      if (view_old_table_info == "yes"){
        while (view_old_table_info == "yes"){
          old_table = "NA"
          print ("Which old table info would you like to view? (Fall17 or Fall18)")
          scan(old_table)

          if (old_table == "Fall17"){
            path_to_older_table = "/mnt/mintaka/data4/SFACT/"//old_table//"/"//hadot_name//"/Sec"//subsection//"/"//hadot_name//""//subsection//"_fin_rec.tab"
            print ("Path to older table directory is:\n"//path_to_older_table)

            #Check if older ID has been provided or ask for it
          }
          else if (old_table == "Fall18"){
            path_to_older_table = "/mnt/mintaka/data4/SFACT/"//old_table//"/"//hadot_name//"_"//NB_name//"/Sec"//subsection//"/"//hadot_name//"_"//NB_name//""//subsection//"_fin_rec.tab"
            print ("Path to older table directory is:\n"//path_to_older_table)

            #Check if older ID has been provided or ask for it
          }
          else{
            print ("Invalid input. Please enter Fall17 or Fall18.")
          }

          print ("Do you wish to continue viewing older tables? (yes or no)")
          scan(view_old_table_info)
          if (view_old_table_info == "no"){
            print ("Finished viewing older tables.")
            break
          }
          else {
            if (view_old_table_info != "yes"){
              print ("Not a valid input. Enter yes or no. Assuming you want to continue.")
            }
            view_old_table_info = "yes"
          }
        }
      }
      else if (view_old_table_info != "yes"){
        if (view_old_table_info == "no"){
          print ("Not viewing older table information.")
          break
        }
        else {
          print ("Not a valid input. Enter yes or no.")
          view_old_table_info = "yes"
        }
      }
    }

    ###########################################################################
    #Clean up images that were created before
    imdelete(rimage//"_sub.fits", ver-)
    imdelete(hadiffimage//"_sub.fits", ver-)
    imdelete(haimage//"_sub.fits", ver-)
    imdelete(rimage//"_sky.fits", ver-)
    imdelete(hadiffimage//"_sky.fits", ver-)
    imdelete(haimage//"_sky.fits", ver-)
    imdelete(rimage//"_sky_sc.fits", ver-)
    imdelete("big.fits", ver-)
    imdelete("wideHA.fits", ver-)
    imdelete("wideHAdiff.fits", ver-)
    imdelete("wideR.fits", ver-)
    imdelete("d2big.fits", ver-)
    imdelete("blank"//j//".fits", ver-)
    imdelete("d2blank"//j//".fits", ver-)

    #Get out of loop
    found = yes
    break
  }
}
if (found == no) {
  print("Target ObjID not found in the table.")
}

end
