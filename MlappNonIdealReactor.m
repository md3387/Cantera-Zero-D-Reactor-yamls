function[] = MlappNonIdealReactor(Temperature,Pressure,Mechanism,GasSpec,filebase)
% "MlappNonIdealReactor" - Mitchell D. Hageman October 2024
% PURPOSE: 
%   * Solve a kinetic mechanism for a zero-D reactor at thermodynamic conditions for a combustion shock tube experiment.
% PREREQUISITES
%   *Must have Cantera installed and mapped correctly (Also requires Python)
%   *Start here: https://cantera.org/install/index.html
% INPUTS:
%   * Temperature = temperature in test section, typically either shock tube T2 or T5 [K]
%   * Pressure = in test section, typically either shock tube P2 or P5 [atm]
%   * Mechanism = name of chosen mechanism
%       *mechanism file must be in .yaml format
%       *mechanism file must be saved in present working directory
%       *e.g. 'mech.yaml'  NOTE THE SINGLE QUOTES
%   * GasSpec = string defining gases and their mole fractionsin test gas mixture
%        *e.g.: 'Ar:0.99,O2:0.009,C3H8:0.001'  NOTE THE SINGLE QUOTES
%        *Check the "species" block of your mechanism file to ensure that the species are all listed. being listed in the "elements" block doesnt count. Species needs to be listed in species block, and have composition, thermo, and in some cases transport information listed further down 
%        *Species names should not be case-sensitive. (i.e. Ar and AR should work)
%   * filebase = first part of file name, onto which we will append '_cantera.csv'
%        *e.g. if filebase= '20240104' the outputs will be written to 20240104_cantera.csv
%        *DOUBLE or SINGLE QUOTES work for file base ('20240104' or "20200104" will produce the same result)
% OUTPUTS: Mole Fractions are written to *filebase*_cantera.csv in the present working directory.
%   * x(n,:) = moleFraction(real_gas,{Fuel 'HE' 'Ar' 'N2' 'O2'...% Other Reactants
%        'CH2O' 'CH' 'CH*' 'CHV' 'SCH' 'CH-S' 'OH' 'OH*' 'OHV' 'SOH' 'OH-S' 'CH3' 'H'...%Ignition Markers
%        'H2O' 'CO' 'CO2' 'NO' 'NO2'....% Products
%        'C2H4' 'H2' 'CH4' 'C2H2' 'C3H6' 'C3H8' 'IC4H8' 'C4H8-1' 'C4H8-2' 'C6H6' 'C7H8'}); %Hychem Intermediates
%        'UserDefinedSpecies'}); %user-defined species. This is a good place to put your fuel and any additional intermediates you're interested in.
%  *The species selected for outputinclude:
%       -Fuel (User input)
%       -Other Reactants (O2 + Inerts)
%       -Intermediates commonly used to mark ignition, 
%       -Standard combustion products, and 
%       -HyChem Intermediates -see (https://web.stanford.edu/group/haiwanglab/HyChem/pages/approach.html)  
%       -User Defined Species - additional intermediates of interest - must hard-code this yourself
%  *If the chosen mechanism doesn't contain one of the above species, the
%   associated column will be filled with zeroes. 
%  % DEVELOPMENT HISTORY: 
%   * reactor network based on NonIdealShockTube.py (https://cantera.org/examples/python/reactors/NonIdealShockTube.py.html) 
%   * Transcribed into MATLAB code and adjusted to output species concentration histories by Mitch Hageman
% VERSION NUMBER:
%   * 1.0: October 2024 - initial release
tic
%% Define the thermodynamic state based on available user inputs
reactorPressure = Pressure * 101325.0;  %[Pa] convert atm to Pascals
real_gas = Solution(Mechanism);
try  %If all required inputs are provided, and everything in GasSpec is listed in the chosen mechanism
    set(real_gas,'T',Temperature,'P',reactorPressure,'X',GasSpec)
catch %If part of GasSpec isn't recognized 
    % (ex: 'C8H18','IXC8H18, IC8H18, 'iso-octane', and 'isooctane' are all possible entries for iso-octane in a mechanism.  
    UserPrompt={'Cantera did not recognize one of your components. Check the "species" block of your mechanism file to make sure your names match, Then change the GasSpec string below. Note: being listed in the "elements" block doesnt count. Species needs to be listed in species block, and have composition, thermo, and in some cases transport information listed further down.'};
    Promptdefault = {GasSpec};
    GasSpec = inputdlg(UserPrompt,'Input',1,Promptdefault);
    set(real_gas,'T',Temperature,'P',reactorPressure,'X',GasSpec)
end

%% Create a reactor object
r = Reactor(real_gas); %for ideal gas try <r = IdealGasReactor(real_gas);>
reactorNetwork = ReactorNet({r});
%timeHistory_RG = SolutionArray(real_gas, 't'); %SolutionArray works in Python, but not Matlab. check against python solution.

%% Initialize loop variables
UserPrompt={'Simulation Time [s]','time step [s] ','Fuel (as defined in the Mechanism file)'};
Promptdefaults = {'0.003','0.0000015',''};
UserInput = inputdlg(UserPrompt,'Input',1,Promptdefaults);
SimulationTime=str2double(char(UserInput(1)));
dt=str2double(char(UserInput(2))); %dt = step(reactorNetwork); %Results in really tiny steps and takes forever. sure seems like python is faster. %dt = 0.0000015; %[s?] Results in way fewer steps, but it's arbitrary. check against python method.
Fuel=char(UserInput(3)); %Must match fuel name in Mechanism exactly.

t = 0;
nsteps=SimulationTime/dt; %[-] number of simulation steps
for n=1:nsteps
    t = t + dt;
    advance(reactorNetwork, t)
    tim(n) = time(reactorNetwork);
    temp(n) = temperature(r);
    x(n,:) = moleFraction(real_gas,{Fuel 'HE' 'AR' 'N2' 'O2'...%Reactants
        'CH2O' 'CH' 'CH*' 'CHV' 'SCH' 'CH-S' 'OH' 'OH*' 'OHV' 'SOH' 'OH-S' 'CH3' 'H'...%Ignition Markers
        'H2O' 'CO' 'CO2' 'NO' 'NO2'....%Products
        'C2H4' 'H2' 'CH4' 'C2H2' 'C3H6' 'C3H8' 'IC4H8' 'C4H8-1' 'C4H8-2' 'C6H6' 'C7H8'...%Hychem Intermediate
        'UserDefinedSpecies'}); %user-defined species. This is a good place to put your fuel and any additional intermediates you're interested in.
        %Don't forget to enter the 'UserDefinedSpecies in the 'titles' block too.
end

%%Write output file
filename = strcat(filebase,'_cantera.csv'); %This should write to PWD.
titles = {'time' ... %[s?] 
    Fuel 'HE' 'AR' 'N2' 'O2' ...%Reactants
    'CH2O' 'CH' 'CH*-radical' 'CHV-radical' 'SCH-radical' 'CH-S-radical' 'OH' 'OH*-radical' 'OHV-radical' 'SOH-radical' 'OH-S-radical' 'CH3' 'H'...%Ignition Markers
    'H2O' 'CO' 'CO2' 'NO' 'NO2'...%Products
    'Ethylene C2H4' 'Hydrogen H2' 'Methane CH4' 'acetylene C2H2' 'Propene C3H6' 'Propane C3H8' 'iso-Butene IC4H8'...%HyChem Intermediates
    '1-butene C4H8-1' '2-Butene C4H8-2' 'Benzene C6H6' 'Toluene C7H8'...
    'UserDefinedSpecies'}; %user-defined species. This is a good place to put your fuel and any additional intermediates you're interested in.
data = [tim',x];
table=array2table(data,'VariableNames',titles);
writetable(table,filename);
toc
end
