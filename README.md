## Installation Notes
* This application was designed with R2020b
* Performance and compatibility with older versions is not guaranteed however core aspects of the program should continue to function. Please refer to official MATLAB 
  documentation for features that have changed between your version and R2020b
* For those that do not have R2020b installed, Windows, Linux, and Mac executables are in development. These will install the MATLAB runtime even if MATLAB is
  already installed on your machine.

## MATLAB Universal Installation 
* Supported Platforms: Windows, Mac, Linux
* Version: R2020b
* Status: Operational
* Required toolboxes:
  - Image Processing Toolbox
  - Curve Fitting Toolbox 
  - Parallel Computing Toolbox
* In order to install and run this application download/clone the repository and unzip the folder in your preferred directory. Folder heirarchy should already be set

## Running the MATLAB App
In order to properly run InCA make sure that the working path of your MATLAB instance is set to the location of the InCA.m file, it is NOT necessary to add the other
folders to the working path, running InCA automatically adds them.  The program can be launched with 
the green play/run button found at the top of the MATLAB Editor tab. 

## Platform Specifc Installation
* Supported Platforms: Windows, Mac, Linux
* Status: In development
* Download and launch the installer for your operating system. This installer installs not only the application but also MATLAB Runtime on your machine regardless of whether or not your machine already
  has MATLAB installed or not.

## Runtime Notes (Both Installation Methods)
* This application is not fool-proof, it does crash and/or freeze from time to time, data is not saved in the case of a forced shutdown of InCA.
* Data saved in the .exe version of InCA CAN be opened up in the .m version and vice-versa
* Due to MATLAB restrictions the InCA window will occasionally hide/show itself when opening/saving files, do not be alarmed by this behavior. MATLAB is still fine tuning graphic application behavior
* Save files from InCA versions pre-2.0 are NOT compatible with InCA 2.0
* This application best presents itself on a 1920 x 1080 pixel monitor, support for other resolutions is coming but slow to develop due to the way Windows internally handles display scaling

## Eternal Tasks
* Refine and improve detection algorithms

## To-Do 
- [x] Consolidate plotting functions in plotting class
- [x] Consolidate figure theme functions in figureappearance class
- [x] Consolidate bubble analysis functions in bubbleanalysis class
- [x] Consolidate functions related to importing and exporting data into InCA
- [x] Swap current mask overlay preview panel for triggerable panel/extend control panel so all components are visible at the same time
- [x] Surface Area/Volume of Revolution calculations
- [x] Make it pretty
- [x] Finish the perimeter velocity calculation function
- [x] Integrate the perimeter velocity function with plotting and changing axes
- [x] Integrate polar fourier fit function
- [x] Write code for phase shift fourier fit function
- [x] Integrate phase shift fourier fit function 
- [x] Figure out how to handle data during batch processing and switching between videos 
- [x] Enable batch processing
- [x] Update the IMR export code to export fourier coefficients for any type of fit
- [x] Have the IMR button save instead of open
- [x] Debug Frame inspector opening up a new figure window when launched 
- [ ] Overhaul the user manual 
- [x] Enhance performance of Main Viewer Axes
- [x] Set up for spherical harmonics analysis
- [x] Set up for multi viewpoint analysis
- [x] Implement detection calibration
- [x] Versioning and update control/notification?
- [x] Fix parametric fit plotting (possible bad fit?)
- [x] Simplify interface/improve UI/UX
- [ ] Integrate Spherical Harmonics 
- [ ] Integrate multi-viewpoint 3D point clouds
- [x] Multiview Detection Algorithm Set Up
- [ ] Troubleshoot faulty multiview edge detection algorithm(s)
- [ ] Better display multi-viewpoint centroid coordinates
- [ ] Revamp Radial Velocity
- [ ] Add Radial Acceleration
- [ ] Easy updater
- [ ] Support for various screen resolutions
- [ ] Update Frame Inpsector to support multi-viwepoint videos
- [x] Fix Open/Save behavior


