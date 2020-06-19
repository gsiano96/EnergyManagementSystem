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
%time(25)=24;

start_time = datetime( '00:00', 'InputFormat', 'HH:mm' );
start_time.Format = 'HH:mm';
end_time = datetime( '23:59', 'InputFormat', 'HH:mm' );
end_time.Format = 'HH:mm';

time_minutes=(start_time:minutes(1):end_time)';
time_hours=(start_time:minutes(60):end_time)';
time_hours.Format='HH:mm';

%% - Irradianze nei mesi per 24 ore -
% Prima pagina della matrice (caso soleggiato)

irradianzeMax=[IrradianzaAprile.Gcs IrradianzaAgosto.Gcs IrradianzaOttobre.Gcs IrradianzaDicembre.Gcs];
irradianzeMed=[IrradianzaAprile.G IrradianzaAgosto.G IrradianzaOttobre.G IrradianzaDicembre.G];

for j=1:1:4
    G_k(:,j,1)=irradianzeMax(:,j);
end
for j=1:1:4
    G_k(:,j,2)=irradianzeMed(:,j);
end

% Aggiunto ulteriore campione per ora 24 su tutte le pagine
%G_k(25,:,:)=0;

%% - Caso nuvoloso (caso peggiore) -
for i=1:1:4 % per ciascun mese
    G_k(:,i,3)=G_k(:,i,1)*(1-0.80); % Caso peggiore => -80%
end

%% - Interpolazione fino a 1440 punti valore su ogni colonna di ogni pagina -
G_k=abs(interp1(time_hours,G_k,time_minutes,'spline'));

%% - Temperatura nei mesi per 24 ore -

temperatureMed=[IrradianzaAprile.T IrradianzaAgosto.T IrradianzaOttobre.T IrradianzaDicembre.T];

variazione_percentuale=[
    40 0 -40;
    20 0 -20;
    40 0 -40
    20 0 -20];

for j=1:1:4
    for k=1:1:3
        T_k(:,j,k)=(1+variazione_percentuale(j,k)/100)*temperatureMed(:,j);
    end
end

%% - Interpolazione fino a 1440 punti valore -
T_k=interp1(time_hours,T_k,time_minutes,'spline');

%% - Campo fotovoltaico -
Pnom=327;
Npannelli=400;
Vpanel_mpp=54.7;
Ipanel_mpp=5.98;
panelPowerTemperatureCoefficient=0.35/100; %/°C
panelVoltageTemperatureCoefficient=176.6/1000; %V/°C
seriesPanelsNumber=400;
parallelsPanelsNumber=1;
PvField=PhotovoltaicField(Npannelli,Pnom,Vpanel_mpp,panelPowerTemperatureCoefficient,...
    panelVoltageTemperatureCoefficient,seriesPanelsNumber,parallelsPanelsNumber);
Ppv_k=getMaxOutputPowerSTC(PvField,G_k);

Ppv_k_scaled=rescaleMPPByTemperature(PvField,Ppv_k,T_k);

%% - Carico -
Pload_k=vector(:,2)*1000; %W 
carico=Load(Pload_k);

%% Grafici (1)

figure(1)

% Grafici potenze fotovoltaico

%Aprile
subplot(2,2,1)
for i=1:1:3
    plot(time_minutes,Ppv_k(:,1,i)/1000);
    hold on
end
plot(time_minutes,Pload_k/1000, 'r');
legend('soleggiato','parz. nuvoloso','nuvoloso','Pload(k)')
xlabel 'time'
ylabel 'Ppv(k) [Kw]'
title 'Aprile'

%Agosto
subplot(2,2,2)
for i=1:1:3
    plot(time_minutes,Ppv_k(:,2,i)/1000);
    hold on
end
plot(time_minutes,Pload_k/1000, 'r');
legend('soleggiato','parz. nuvoloso','nuvoloso','Pload(k)')
xlabel 'time'
ylabel 'Ppv(k) [Kw]'
title 'Agosto'

%Ottobre
subplot(2,2,3)
for i=1:1:3
    plot(time_minutes,Ppv_k(:,3,i)/1000);
    hold on
end
plot(time_minutes,Pload_k/1000, 'r');
legend('soleggiato','parz. nuvoloso','nuvoloso','Pload(k)')
xlabel 'time'
ylabel 'Ppv(k) [Kw]'
title 'Ottobre'

%Dicembre
subplot(2,2,4)
for i=1:1:3
    plot(time_minutes,Ppv_k(:,4,i)/1000);
    hold on
end
plot(time_minutes,Pload_k/1000, 'r');
legend('soleggiato','parz. nuvoloso','nuvoloso','Pload(k)')
xlabel 'time'
ylabel 'Ppv(k) [Kw]'
title 'Dicembre'

%% Grafici (2)
figure(2)

subplot(2,2,1)
plot(time_minutes,Ppv_k(:,1,2)/1000)
hold on
for k=1:1:3
    plot(time_minutes,Ppv_k_scaled(:,1,k)/1000)
    hold on
end
legend('STC','giornata calda', 'giornata media', 'giornata fresca')
xlabel 'time'
ylabel 'Ppv(k) [Kw]'
title 'Aprile'

subplot(2,2,2)
plot(time_minutes,Ppv_k(:,2,2)/1000)
hold on
plot(time_minutes,Ppv_k_scaled(:,2)/1000)
legend('STC','scalato')
xlabel 'time'
ylabel 'Ppv(k) [Kw]'
title 'Agosto'

subplot(2,2,3)
plot(time_minutes,Ppv_k(:,3,2)/1000)
hold on
plot(time_minutes,Ppv_k_scaled(:,3)/1000)
legend('STC','scalato')
xlabel 'time'
ylabel 'Ppv(k) [Kw]'
title 'Ottobre'

subplot(2,2,4)
plot(time_minutes,Ppv_k(:,4,2)/1000)
hold on
plot(time_minutes,Ppv_k_scaled(:,4)/1000)
legend('STC','scalato')
xlabel 'time'
ylabel 'Ppv(k) [Kw]'
title 'Dicembre'