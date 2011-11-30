%
% Tutorials / horn antenna
%
% Describtion at:
% http://openems.de/index.php/Tutorial:_Horn_Antenna
%
% Tested with
%  - Matlab 2011a
%  - openEMS v0.0.25
%
% (C) 2011 Thorsten Liebig <thorsten.liebig@uni-due.de>

close all
clear
clc

%% setup the simulation
physical_constants;
unit = 1e-3; % all length in mm

% horn width in x-direction
horn.width  = 20;
% horn height in y-direction
horn.height = 30;
% horn length in z-direction
horn.length = 50;

horn.feed_length = 50;

horn.thickness = 2;

% horn opening angle in x, y
horn.angle = [20 20]*pi/180;

% size of the simulation box
SimBox = [200 200 200];

% frequency range of interest
f_start =  10e9;
f_stop  =  20e9;

% frequency of interest
f0 = 15e9;

%waveguide TE-mode definition
m = 1;
n = 0;

%% mode functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% by David M. Pozar, Microwave Engineering, third edition, page 113
freq = linspace(f_start,f_stop,201);
a = horn.width;
b = horn.height;
k = 2*pi*freq/c0;
kc = sqrt((m*pi/a/unit)^2 + (n*pi/b/unit)^2);
fc = c0*kc/2/pi;          %cut-off frequency
beta = sqrt(k.^2 - kc^2); %waveguide phase-constant
ZL_a = k * Z0 ./ beta;    %analytic waveguide impedance

% mode profile E- and H-field
x_pos = ['(x-' num2str(a/2) ')'];
y_pos = ['(y-' num2str(b/2) ')'];
func_Ex = [num2str( n/b/unit) '*cos(' num2str(m*pi/a) '*' x_pos ')*sin('  num2str(n*pi/b) '*' y_pos ')'];
func_Ey = [num2str(-m/a/unit) '*sin(' num2str(m*pi/a) '*' x_pos ')*cos('  num2str(n*pi/b) '*' y_pos ')'];

func_Hx = [num2str(m/a/unit) '*sin(' num2str(m*pi/a) '*' x_pos ')*cos('  num2str(n*pi/b) '*' y_pos ')'];
func_Hy = [num2str(n/b/unit) '*cos(' num2str(m*pi/a) '*' x_pos ')*sin('  num2str(n*pi/b) '*' y_pos ')'];

disp([' Cutoff frequencies for this mode and wavguide is: ' num2str(fc/1e9) ' GHz']);

if (f_start<fc)
    warning('openEMS:example','f_start is smaller than the cutoff-frequency, this may result in a long simulation... ');
end

%% setup FDTD parameter & excitation function
FDTD = InitFDTD( 30000, 1e-5 );
FDTD = SetGaussExcite(FDTD,0.5*(f_start+f_stop),0.5*(f_stop-f_start));
BC = {'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PML_8'}; % boundary conditions
FDTD = SetBoundaryCond( FDTD, BC );

%% setup CSXCAD geometry & mesh
% currently, openEMS cannot automatically generate a mesh
max_res = c0 / (f_stop) / unit / 15; % cell size: lambda/20
CSX = InitCSX();

%create fixed lines for the simulation box, substrate and port
mesh.x = [-SimBox(1)/2 -a/2 a/2 SimBox(1)/2];
mesh.x = SmoothMeshLines( mesh.x, max_res, 1.4); % create a smooth mesh between specified fixed mesh lines

mesh.y = [-SimBox(2)/2 -b/2 b/2 SimBox(2)/2];
mesh.y = SmoothMeshLines( mesh.y, max_res, 1.4 );

%create fixed lines for the simulation box and given number of lines inside the substrate
mesh.z = [-horn.feed_length 0 SimBox(3)-horn.feed_length ];
mesh.z = SmoothMeshLines( mesh.z, max_res, 1.4 );

CSX = DefineRectGrid( CSX, unit, mesh );

%% create horn
% horn feed rect waveguide
CSX = AddMetal(CSX, 'horn');
start = [-a/2-horn.thickness -b/2 mesh.z(1)];
stop  = [-a/2                 b/2 0];
CSX = AddBox(CSX,'horn',10,start,stop);
start = [a/2+horn.thickness -b/2 mesh.z(1)];
stop  = [a/2                 b/2 0];
CSX = AddBox(CSX,'horn',10,start,stop);
start = [-a/2-horn.thickness b/2+horn.thickness mesh.z(1)];
stop  = [ a/2+horn.thickness b/2                0];
CSX = AddBox(CSX,'horn',10,start,stop);
start = [-a/2-horn.thickness -b/2-horn.thickness mesh.z(1)];
stop  = [ a/2+horn.thickness -b/2                0];
CSX = AddBox(CSX,'horn',10,start,stop);

% horn opening
p(2,1) = a/2;
p(1,1) = 0;
p(2,2) = a/2 + sin(horn.angle(1))*horn.length;
p(1,2) = horn.length;
p(2,3) = -a/2 - sin(horn.angle(1))*horn.length;
p(1,3) = horn.length;
p(2,4) = -a/2;
p(1,4) = 0;
CSX = AddLinPoly( CSX, 'horn', 10, 1, -horn.thickness/2, p, horn.thickness, 'Transform', {'Rotate_X',horn.angle(2),'Translate',['0,' num2str(-b/2-horn.thickness/2) ',0']});
CSX = AddLinPoly( CSX, 'horn', 10, 1, -horn.thickness/2, p, horn.thickness, 'Transform', {'Rotate_X',-horn.angle(2),'Translate',['0,' num2str(b/2+horn.thickness/2) ',0']});

p(1,1) = b/2+horn.thickness;
p(2,1) = 0;
p(1,2) = b/2+horn.thickness + sin(horn.angle(2))*horn.length;
p(2,2) = horn.length;
p(1,3) = -b/2-horn.thickness - sin(horn.angle(2))*horn.length;
p(2,3) = horn.length;
p(1,4) = -b/2-horn.thickness;
p(2,4) = 0;
CSX = AddLinPoly( CSX, 'horn', 10, 0, -horn.thickness/2, p, horn.thickness, 'Transform', {'Rotate_Y',-horn.angle(2),'Translate',[ num2str(-a/2-horn.thickness/2) ',0,0']});
CSX = AddLinPoly( CSX, 'horn', 10, 0, -horn.thickness/2, p, horn.thickness, 'Transform', {'Rotate_Y',+horn.angle(2),'Translate',[ num2str(a/2+horn.thickness/2) ',0,0']});

% horn aperture
A = (a + 2*sin(horn.angle(1))*horn.length)*unit * (b + 2*sin(horn.angle(2))*horn.length)*unit;

% %% apply the excitation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% xy-mode profile excitation located directly on top of pml (first 8 z-lines)
CSX = AddExcitation(CSX,'excite',0,[1 1 0]);
weight{1} = func_Ex;
weight{2} = func_Ey;
weight{3} = 0;
CSX = SetExcitationWeight(CSX,'excite',weight);
start=[-a/2 -b/2 mesh.z(8) ];
stop =[ a/2  b/2 mesh.z(8) ];
CSX = AddBox(CSX,'excite',0 ,start,stop);

%% voltage and current definitions using the mode matching probes %%%%%%%%%
%port 1
start(3) = mesh.z(1)+horn.feed_length/2;
stop(3)  = start(3);
CSX = AddProbe(CSX, 'ut1', 10, 1, [], 'ModeFunction',{func_Ex,func_Ey,0});
CSX = AddBox(CSX,  'ut1',  0 ,start,stop);
CSX = AddProbe(CSX,'it1', 11, 1, [], 'ModeFunction',{func_Hx,func_Hy,0});
CSX = AddBox(CSX,'it1', 0 ,start,stop);

%% nf2ff calc
start = [mesh.x(9) mesh.y(9) mesh.z(9)];
stop  = [mesh.x(end-8) mesh.y(end-8) mesh.z(end-8)];
[CSX nf2ff] = CreateNF2FFBox(CSX, 'nf2ff', start, stop, [1 1 1 1 0 1]);

%% prepare simulation folder
Sim_Path = 'tmp';
Sim_CSX = 'horn_ant.xml';

[status, message, messageid] = rmdir( Sim_Path, 's' ); % clear previous directory
[status, message, messageid] = mkdir( Sim_Path ); % create empty simulation folder

%% write openEMS compatible xml-file
WriteOpenEMS([Sim_Path '/' Sim_CSX], FDTD, CSX);

%% show the structure
CSXGeomPlot([Sim_Path '/' Sim_CSX]);

%% run openEMS
RunOpenEMS(Sim_Path, Sim_CSX);

%% postprocessing & do the plots
U = ReadUI( 'ut1', Sim_Path, freq ); % time domain/freq domain voltage
I = ReadUI( 'it1', Sim_Path, freq ); % time domain/freq domain current (half time step is corrected)

% plot reflection coefficient S11
figure
uf_inc = 0.5*(U.FD{1}.val + I.FD{1}.val .* ZL_a);
if_inc = 0.5*(I.FD{1}.val + U.FD{1}.val ./ ZL_a);
uf_ref = U.FD{1}.val - uf_inc;
if_ref = if_inc - I.FD{1}.val;
s11 = uf_ref ./ uf_inc;
plot( freq/1e9, 20*log10(abs(s11)), 'k-', 'Linewidth', 2 );
ylim([-60 0]);
grid on
title( 'reflection coefficient S_{11}' );
xlabel( 'frequency f / GHz' );
ylabel( 'reflection coefficient |S_{11}|' );

P_in = 0.5*uf_inc .* conj( if_inc ); % antenna feed power

%% NFFF contour plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate the far field at phi=0 degrees and at phi=90 degrees
thetaRange = (0:2:359) - 180;
r = 1; % evaluate fields at radius r
disp( 'calculating far field at phi=[0 90] deg...' );
[E_far_theta,E_far_phi,Prad,Dmax] = AnalyzeNF2FF( Sim_Path, nf2ff, f0, thetaRange, [0 90], r );

Dlog=10*log10(Dmax);
G_a = 4*pi*A/(c0/f0)^2;
e_a = Dmax/G_a;

% display some antenna parameter
disp( ['radiated power: Prad = ' num2str(Prad) ' Watt']);
disp( ['directivity: Dmax = ' num2str(Dlog) ' dBi'] );
disp( ['aperture efficiency: e_a = ' num2str(e_a*100) '%'] );

%%
% calculate the e-field magnitude for phi = 0 deg
E_phi0_far = zeros(1,numel(thetaRange));
for n=1:numel(thetaRange)
    E_phi0_far(n) = norm( [E_far_theta(n,1) E_far_phi(n,1)] );
end

E_phi0_far_log = 20*log10(abs(E_phi0_far)/max(abs(E_phi0_far)));
E_phi0_far_log = E_phi0_far_log + Dlog;

% display polar plot
figure
plot( thetaRange, E_phi0_far_log ,'k-' );
xlabel( 'theta (deg)' );
ylabel( 'directivity (dBi)');
grid on;
hold on;

% calculate the e-field magnitude for phi = 90 deg
E_phi90_far = zeros(1,numel(thetaRange));
for n=1:numel(thetaRange)
    E_phi90_far(n) = norm([E_far_theta(n,2) E_far_phi(n,2)]);
end

E_phi90_far_log = 20*log10(abs(E_phi90_far)/max(abs(E_phi90_far)));
E_phi90_far_log = E_phi90_far_log + Dlog;

% display polar plot
plot( thetaRange, E_phi90_far_log ,'r-' );
legend('phi=0','phi=90')

%% calculate 3D pattern
phiRange = sort( unique( [-180:5:-100 -100:2.5:-50 -50:1:50 50:2.5:100 100:5:180] ) );
thetaRange = sort( unique([ 0:1:50 50:2.:100 100:5:180 ]));
r = 1; % evaluate fields at radius r
disp( 'calculating 3D far field...' );
[E_far_theta,E_far_phi] = AnalyzeNF2FF( Sim_Path, nf2ff, f0, thetaRange, phiRange, r );
E_far = sqrt( abs(E_far_theta).^2 + abs(E_far_phi).^2 );
E_far_normalized = E_far / max(E_far(:)) * Dmax;

[theta,phi] = ndgrid(thetaRange/180*pi,phiRange/180*pi);
x = E_far_normalized .* sin(theta) .* cos(phi);
y = E_far_normalized .* sin(theta) .* sin(phi);
z = E_far_normalized .* cos(theta);
figure
surf( x,y,z, E_far_normalized, 'EdgeColor','none' );
axis equal
axis off
xlabel( 'x' );
ylabel( 'y' );
zlabel( 'z' );

%%
DumpFF2VTK('Horn_Pattern.vtk',E_far_normalized,thetaRange,phiRange,1e-3);
