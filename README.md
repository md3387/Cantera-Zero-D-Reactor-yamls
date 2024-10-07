# Cantera-Zero-D-Reactor + yamls


The primary purpose of this code is to solve a kinetic mechanism for a zero-D reactor at given thermodynamic conditions.
Theoretically, State 5 (behind the reflected shock) in a combustion shock tube can be approximated as a zero-D reactor, so this could be used to compare directly to shock tube experimental data if the thermodynamic State 5 conditions are known.

Pre-requisites:
Must have Cantera installed and mapped correctly (Also requires Python)
Start here: https://cantera.org/install/index.html
reactor network based on NonIdealShockTube.py (https://cantera.org/examples/python/reactors/NonIdealShockTube.py.html) - Transcribed into MATLAB code and adjusted to output species concentration histories by Mitch Hageman

Additionally:
As of Version 2.5, Cantera requires mechanism files to be in the .yaml format.  However, many mechanisms found online are either in the legacy .cti Cantera format, or in the .ck (Chemkin) format.  Furthermore, these mechanisms are spread across the internet and difficult to find.  I'm hoping to get permission to post as many as possible here, in .yaml format. 
