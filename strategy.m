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

%% - Irradianze giornaliere per mesi e casi -

irradianzeMax=[IrradianzaAprile.Gcs IrradianzaAgosto.Gcs IrradianzaOttobre.Gcs IrradianzaDicembre.Gcs];
irradianzeMed=[IrradianzaAprile.G IrradianzaAgosto.G IrradianzaOttobre.G IrradianzaDicembre.G];

for j=1:1:4
    % Prima pagina della matrice (caso soleggiato)
    G_k(:,j,1)=irradianzeMax(:,j);
    % Seconda pagina della matrice (caso medio)
    G_k(:,j,2)=irradianzeMed(:,j);
    % Terza pagina della matrice (caso nuvoloso)
    G_k(:,j,3)=G_k(:,j,1)*(1-0.80); % Caso peggiore => -80%
end

% Aggiunto ulteriore campione per ora 24 su tutte le pagine
%G_k(25,:,:)=0;

%% - Interpolazione fino a 1440 punti valore su ogni colonna di ogni pagina -
G_k=abs(interp1(time_hours,G_k,time_minutes,'spline'));

%% - Temperatura nei mesi per 24 ore -

temperatureMed=[IrradianzaAprile.T IrradianzaAgosto.T IrradianzaOttobre.T IrradianzaDicembre.T];

%Mesi x Casi
variazione_percentuale=[
    40 0 -40;
    20 0 -20;
    40 0 -40;
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

margin_k=ones(1440,1)*10*1000;
optimizePanelsNumber(PvField,Ppv_k,10*1000,margin_k);

%% - Inverter Fotovoltaico Solarmax -

Prel_k=SolarmaxInverter.relativePower/100;
efficiency_k=SolarmaxInverter.efficiency/100;
% Aggiunto lo 0 per uniformare l'asse
Prel_k=[0;Prel_k];
efficiency_k=[0;efficiency_k];

% ATTENZIONE non possiamo scendere sotto i 120Kw per non avere un fenomeno di power clipping
Pindcmax = 130*1e3;  %nominal P DC
Poutacmax = 100*1e3; %max P AC

inputVoltageInterval = [430,900];
outputVoltageInterval = 400;%numerpo sul datashet;
phasesNumber = 3; % trifase

Inverter = SolarmaxInverter(Prel_k(:),efficiency_k(:),Pindcmax,Poutacmax, inputVoltageInterval, outputVoltageInterval, phasesNumber);
Prel_k = getRelativePowers(Inverter,Ppv_k_scaled);

%% - Carico -
Pload_k=vector(:,2)*1000; %W 
carico=Load(Pload_k);

%% - Calcolo della Potenza Residua -
for j=1:1:4
    for k=1:1:3
        Presiduo_k(:,j,k) = Ppv_k_scaled(:,j,k) - Pload_k;
    end
end
%Potenza residua
%Presiduo = Ppv_k_scaled-Pload_k;

%% - Batteria -
fullCapacity = 210*1e3; % Capacità della Batteria in Wh
capacity = 210*1e3; % Wh
dod = 0.90; 
Pbat_k = 3300; %W

% Non tutta la potenza in ingresso/uscita è utilizzata per 
% caricare/scaricare la batteria a causa del suo rendimento di 
% carica/scarica.
Befficiency = 0.98; % Rendimento della Batteria

Battery = SimpleBattery(fullCapacity, dod, Pbat_k, Befficiency);
[energia,Presidual] = batteryEnergy_k(Battery,0.0167,Presiduo_k)

figure(4),plot(time_minutes,energia(:,1,1)/1000);


%% - Inverter per batteria Sonnen -
% Non tutta la potenza residua è utilizzata per scaricare/caricare la
% batteria in quanto il flusso energetico in uscita/ingresso è frazionato
% dal rendimento del suo inverter.

rendimentoInverterBatteria = 0.95; 


% Flusso di potenza input/output in uscita/ingresso dall'inverter
%Presiduo_bat_inverter = Presiduo_k*rendimentoInverterBatteria;



%% Grafici (1) -> Grafici potenze fotovoltaico per tutti i mesi e casi

figure(1)
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

%% Grafici (2) -> Effetto di scalatura della potenza dovuto alla temperatura

figure(2)
% Agosto
subplot(1,2,1)
plot(time_minutes,Ppv_k(:,2,1)/1000);
hold on
plot(time_minutes,Ppv_k_scaled(:,2,1)/1000);
title('Agosto')
legend('soleggiato-STC','soleggiato')
xlabel 'time'
ylabel 'Ppv(k)'

% Ottobre
subplot(1,2,2)
plot(time_minutes,Ppv_k(:,3,1)/1000);
hold on
plot(time_minutes,Ppv_k_scaled(:,3,1)/1000);
title('Ottobre')
legend('soleggiato-STC','soleggiato')
xlabel 'time'
ylabel 'Ppv(k)'

% I mesi Aprile, Ottobre e Dicembre 
% non risentono dell'effetto di scalatura della potenza dovuto
% alla temperatura, essendo questa al di sotto di 25°C

%% Grafici (3) -> Potenze Residue e di Carico per tutti i mesi e casi

figure(3)
% Aprile
subplot(2,2,1)
for i=1:1:3
    plot(hours,Presiduo_k(:,1,i)/1000)
    hold on
end
plot(hours,Pload_k/1000,'r')
legend('soleggiato', 'nuvoloso', 'caso peggiore','Pload(k)')
title('Presiduo(k) Aprile')
xlabel 'ore'
ylabel 'Potenze [Kw]'

% Agosto
subplot(2,2,2)
for i=1:1:3
    plot(hours,Presiduo_k(:,2,i)/1000)
    hold on
end
plot(hours,Pload_k/1000,'r')
legend('soleggiato', 'nuvoloso', 'caso peggiore','Pload(k)')
title('Presiduo(k) Agosto')
xlabel 'ore'
ylabel 'Potenze [Kw]'
axis ([0 24 -20 100])

% Ottobre
subplot(2,2,3)
for i=1:1:3
    plot(hours,Presiduo_k(:,3,i)/1000)
    hold on
end
plot(hours,Pload_k/1000,'r')
legend('soleggiato', 'nuvoloso', 'caso peggiore','Pload(k)')
title('Presiduo(k) Ottobre')
xlabel 'ore'
ylabel 'Potenze [Kw]'

% Dicembre
subplot(2,2,4)
for i=1:1:3
    plot(hours,Presiduo_k(:,4,i)/1000)
    hold on
end
plot(hours,Pload_k/1000,'r')
legend('soleggiato', 'nuvoloso', 'caso peggiore','Pload(k)')
title('Presiduo(k) Dicembre')
xlabel 'ore'
ylabel 'Potenze [Kw]'

% Presiduo negativo => Potenza assorbita dalla batteria
% Presiduo positivo => Potenza fornita alla batteria