%% - Operazioni di Pulizia -
clear all; 
clc; 
close all;

%% - Caricamento dati -
load Matfile/energy_hourly_cost.mat
load Matfile/daily_minute.mat

load Irradianze_medie_giornaliere_per_mesi/Matfile/Irradianza_Agosto.mat
load Irradianze_medie_giornaliere_per_mesi/Matfile/Irradianza_Aprile.mat
load Irradianze_medie_giornaliere_per_mesi/Matfile/Irradianza_Dicembre.mat
load Irradianze_medie_giornaliere_per_mesi/Matfile/Irradianza_Ottobre.mat

load 'Matfile/Battery_health.mat'

load 'Inverter/Solarmax_inverter.mat'

%% - Import package -
addpath Package

%% - Scale temporali -
hours=vector(:,1)/60;
time=IrradianzaDicembre.time;
time=datevec(time); %from datetime to matrix of date and time
time=time(:,4); %extract hours as integers

% Aggiunta ora 24
time(25)=24;

%% - Irradianze nei mesi per 24 ore -
% Prima pagina della matrice
G_k(:,1,1)=abs(IrradianzaAprile.G);
G_k(:,2,1)=abs(IrradianzaAgosto.G);
G_k(:,3,1)=abs(IrradianzaOttobre.G);
G_k(:,4,1)=abs(IrradianzaDicembre.G);

% Aggiunto ulteriore campione per ora 24 su tutte le pagine
G_k(25,:,:)=0;

%% - Sottocasi soleggiato, nuvoloso, caso peggiore, nei mesi -
% Le altre pagine della matrice sono i sottocasi
for i=1:1:4 % per ciascun mese
    G_k(:,i,2)=G_k(:,i,1)*(1-0.40); % nuvoloso => -40%
    G_k(:,i,3)=G_k(:,i,1)*(1-0.80); % Caso peggiore => -80%
end

%% - Interpolazione fino a 1440 punti valore su ogni colonna di ogni pagina -
G_k=interp1(time,G_k,hours,'spline');

%% - Temperatura nei mesi per 24 ore -
T_k(:,1)=IrradianzaAprile.T;
T_k(:,2)=IrradianzaAgosto.T;
T_k(:,3)=IrradianzaOttobre.T;
T_k(:,4)=IrradianzaDicembre.T;

%% - Campo fotovoltaico -
Pnom=327;
Npannelli=400;
Vpanel_mpp=54.7;
Ipanel_mpp=5.98;
panelPowerTemperatureCoefficient=0.35;
panelVoltageTemperatureCoefficient=176.6/1000;
seriesPanelsNumber=400;
parallelsPanelsNumber=1;
PvField=PhotovoltaicField(Npannelli,Pnom,Vpanel_mpp,panelPowerTemperatureCoefficient,...
    panelVoltageTemperatureCoefficient,seriesPanelsNumber,parallelsPanelsNumber);
Ppv_k=getMaxOutputPowerSTC(PvField,G_k);
%Ppv_k=rescaleMPPByTemperature(PvField,Ppv_k,T_k); working in progress!
