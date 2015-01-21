%% REFPROP Table Generator v1.0
%%Jan 2015
%%Eric Miller
%NREL,Vehicle Thermal Group
%Makes Property Tables of size nxn for 2-Phase Fluids using RefProp 9.1 dll
clear
close all
addpath('../refproptools')
tic
%Set vector length
n=25;
%Set Substance Name
fluid.name='R134a';
%pressures above critical?(1-yes 0-no)
supercrit=0;
%Specify Variables
dep=['T';'D';'S';'Q';'H';'U';'R'];
ndep=length(dep);
indep=['T';'P';'H';'U';'D';'S';'Q'];
nindep=length(indep);
disp(['estimated runtime: ', num2str(.0018*(ndep*nindep*n^2)/60),'(min)'])
%% Variable Descriptions
%                           0   Refprop DLL version number
%                           A   Speed of sound [m/s]
%                           B   Volumetric expansivity (beta) [1/K]
%                           C   Cp [J/(kg K)]
%                           D   Density [kg/m^3]
%                           F   Fugacity [kPa] (returned as an array)
%                           G   Gross heating value [J/kg]
%                           H   Enthalpy [J/kg]
%                           I   Surface tension [N/m]
%                           J   Isenthalpic Joule-Thompson coeff [K/kPa]
%                           K   Ratio of specific heats (Cp/Cv) [-]
%                           L   Thermal conductivity [W/(m K)]
%                           M   Molar mass [g/mol]
%                           N   Net heating value [J/kg]
%                           O   Cv [J/(kg K)]
%                           P   Pressure [kPa]
%                           Q   Quality (vapor fraction) (kg/kg)
%                           S   Entropy [J/(kg K)]
%                           T   Temperature [K]
%                           U   Internal energy [J/kg]
%                           V   Dynamic viscosity [Pa*s]
%                           X   Liquid phase & gas phase comp.(mass frac.)
%                           Y   Heat of Vaporization [J/kg]
%                           Z   Compressibility factor
%                           $   Kinematic viscosity [cm^2/s]
%                           %   Thermal diffusivity [cm^2/s]
%                           ^   Prandtl number [-]
%                           )   Adiabatic bulk modulus [kPa]
%                           |   Isothermal bulk modulus [kPa]
%                           =   Isothermal compressibility [1/kPa]
%                           ~   Cstar [-]
%                           `   Throat mass flux [kg/(m^2 s)]
%                           +   Liquid density of equilibrium phase
%                           -   Vapor density of equilibrium phase
%
%                           E   dP/dT (along the saturation line) [kPa/K]
%                           #   dP/dT     (constant rho) [kPa/K]
%                           R   d(rho)/dP (constant T)   [kg/m^3/kPa]
%                           W   d(rho)/dT (constant p)   [kg/(m^3 K)]
%                           !   dH/d(rho) (constant T)   [(J/kg)/(kg/m^3)]
%                           &   dH/d(rho) (constant P)   [(J/kg)/(kg/m^3)]
%                           (   dH/dT     (constant P)   [J/(kg K)]
%                           @   dH/dT     (constant rho) [J/(kg K)]
%                           *   dH/dP     (constant T)   [J/(kg kPa)]
%
%       spec1           first input character:  T, P, H, D, C, R, or M
%                         T, P, H, D:  see above
%                         C:  properties at the critical point
%                         R:  properties at the triple point
%                         M:  properties at Tmax and Pmax
%                            (Note: if a fluid's lower limit is higher
%                             than the triple point, the lower limit will
%                             be returned)
%% Intialize Vectors
%R-minimum,M-maximum,C-critical

for ww=1:nindep
    min=refpropm(indep(ww),'R',0,' ',0,fluid.name);
    max=refpropm(indep(ww),'M',0,' ',0,fluid.name);
    fluid.(indep(ww))=linspace(min,max,n);
end
if supercrit==0
    min=refpropm('P','R',0,' ',0,fluid.name);
    crit=refpropm('P','C',0,' ',0,fluid.name);
    fluid.P=linspace(min,crit,n);
end
%% Generate Tables
for w=1:ndep
    for ww=1:nindep
        for www=1:nindep
            flag=0;
            str=[dep(w),indep(ww),indep(www)];
            if str(1)==str(2) || str(2) == str(3) || str(3) == str(1)
                flag=1;
            end
            if flag ==0
                M=zeros(n);
                for i=1:n
                    for j=1:n
                        try
                            fluid.(str)(i,j)=refpropm(str(1),...
                                str(2),fluid.(str(2))(j),str(3),fluid.(str(3))(i),fluid.name);
                        catch
                            fluid.(str)(i,j)=NaN;
                        end
                    end
                end
                %quirk-fixing
                [fluid] = quirks(fluid,str,n);
            end
        end
    end
    
    disp([num2str(100*w/ndep),'% ','Complete'])
end
tt=toc;
disp(['actual runtime: ',num2str(tt/60),'(min)'])
%% Plot Some Results (to check against Refprop avi)
figure(1);contourf(fluid.H,fluid.P,fluid.THP,50)
ylabel('Pressure (kPa)');
xlabel ('Specific Enthalpy J/kg')
title('Temperature (K)')
 
figure(2);contourf(fluid.H,fluid.P,fluid.DPH',50)
ylabel('Pressure (kPa)');
xlabel ('Specific Enthalpy J/kg')
title('Density (kg/m^3)')
fluid.QPH(fluid.QPH > 1) = 1;
fluid.QPH(fluid.QPH < 0) = 0;
 
figure(3);contourf(fluid.H,fluid.P,fluid.QPH',50)
ylabel('Pressure (kPa)');
xlabel ('Specific Enthalpy (J/kg)')
title('Quality (kg/kg)')
%Save File
save(['fprops',fluid.name,'.mat'],'fluid')
