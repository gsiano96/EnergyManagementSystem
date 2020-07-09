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

load 'Wind-speed/metereological_date.mat'

%% - Import package -
addpath Package

%% - Scale temporali -
hours=vector(:,1)/60;
time=IrradianzaDicembre.time;
time=datevec(time); %from datetime to matrix of date and time
time=time(:,4); %extract hours as integers

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

%% - Interpolazione fino a 1440 punti valore su ogni colonna di ogni pagina -
G_k=abs(interp1(time_hours,G_k,time_minutes,'spline'));

%% - Temperatura ambiente nei mesi per 24 ore -
temperatureMed=[IrradianzaAprile.T IrradianzaAgosto.T IrradianzaOttobre.T IrradianzaDicembre.T];

% Mesi x Casi
variazione_percentuale=[
    30 0 -30; % 6 gradi
    20 0 -20;
    30 0 -30;
    20 0 -20];

for j=1:1:4
    for k=1:1:3
        T_k(:,j,k)=(1+variazione_percentuale(j,k)/100)*temperatureMed(:,j);
    end
end

%% - Interpolazione fino a 1440 punti valore -
T_k=interp1(time_hours,T_k,time_minutes,'spline');

%% - Campo fotovoltaico -
Pnom = 327; %[W]
% --> Npannelli = 400; <--
Vpanel_mpp = 54.7;
Ipanel_mpp = 5.98;
panelPowerTemperatureCoefficient = 0.35/100; %[/°C]
panelVoltageTemperatureCoefficient = 176.6/1000; %[V/°C]
NOCT = 45 + randi([-2 2],1,1); %[°C] --> Nominal Operating Cell Temperature

%% - Disposizione campo fotovoltaico -
seriesPanelsNumber = 400;
parallelsPanelsNumber = 1;

%% - Carico -
Pload_k = vector(:,2)*1000; %[W] 
carico=Load(Pload_k);

Pload_med = mean(Pload_k); %formula per il valore medio della potenza del carico

%Energia assorbita dal carico
Eload_k = cumtrapz(0.0167,Pload_k);
% figure(),plot(time_minutes,Eload_k(:)/1000),title 'Energia assorbita dal carico'

%% - Inverter Fotovoltaico Solarmax da 100kw DC -
Prel_k = SolarmaxInverter.relativePower/100;
efficiency_k = SolarmaxInverter.efficiency/100;

% Aggiunto lo 0 per uniformare l'asse
Prel_k=[0;Prel_k];
efficiency_k=[0;efficiency_k];

Pindcmax = 105*1e3;  %nominal P DC   <-- 2 scelta
Poutacmax = 80*1e3; %max P AC 
inputVoltageInterval = [430,900];
outputVoltageInterval = 400; 
phasesNumber = 3; % trifase
 
Inverter = Solarmaxinverter(Prel_k,efficiency_k,Pindcmax,Poutacmax, inputVoltageInterval, outputVoltageInterval, phasesNumber);
%potenza PV tenendo conto dell'efficienza dell'inverter e temperatura
[Pin_inv_k,Pout_inv_k] = getCharacteristicPout_Pin(Inverter,true);


%% - Ottimizzazione numero di Pannelli - 

Prel_r = max(efficiency_k);
efficiency_r = 0.948;

margin = (Prel_r .* Pindcmax .* efficiency_r) - Pload_med; %[W] 
Nmin_pannelli = ceil((margin+Pload_med)/Pnom);

%% - Dimensionamento Potenze campo fotovoltaico -
PvField=PhotovoltaicField(Nmin_pannelli,Pnom,Vpanel_mpp,panelPowerTemperatureCoefficient,...
    panelVoltageTemperatureCoefficient,seriesPanelsNumber,parallelsPanelsNumber,NOCT);
Ppv_k=getMaxOutputPowerSTC(PvField,G_k);

Ppv_k_scaled=rescaleMPPByTemperature(PvField,Ppv_k,T_k,G_k);

% Interpolazione dei punti dell'asse Pinput corrispondenti a Ppv
Ppv_out_k = interpolateInputPowerPoints(Inverter ,Ppv_k_scaled,'spline');

%% - Pala Eolica -
%https://en.wind-turbine-models.com/turbines/1682-hummer-h25.0-100kw
ratedPower=100*1000;
ratedWindSpeed=10;
cutinWindSpeed=2.5;
cutoutWindSpeed=20;
survivalWindSpeed=50;
rotorDiameter=25;
generatorVoltage=690;

windTurbine=WindTurbine(ratedPower,ratedWindSpeed,cutinWindSpeed,cutoutWindSpeed,survivalWindSpeed,rotorDiameter,generatorVoltage);

%windspeed_k=windTurbine.filterWindData(windDataset20072016,'20090101');

windspeed_k(:,1)=MetereologicalDataApril.WS10m;
windspeed_k(:,2)=MetereologicalDataAugust.WS10m;
windspeed_k(:,3)=MetereologicalDataOctober.WS10m;
windspeed_k(:,4)=MetereologicalDataDecember.WS10m;

windspeed_k=interp1(time_hours,windspeed_k,time_minutes,'spline');

Peol_k=zeros(1440,4);
for j=1:1:4
    Peol_k(:,j)=windTurbine.getOutputPower_k(1.2,windspeed_k(:,j));
    Peol_k(:,j)=windTurbine.rescaleWindSpeedByAltitude(windspeed_k(:,j),235,0.34);
end

% Percentuali di interesse in input all'inverter
med_targetPrel=getMeanTarget(Inverter,Ppv_k_scaled,Pindcmax); % media
max_targetPrel=getMaxTarget(Inverter,Ppv_k_scaled,Pindcmax); % massimo

%Energia del fotvoltaico
Epv_out_k=cumtrapz(0.0167,Ppv_out_k);
%figure(),plot(time_minutes,Epv_out_k(:,1,1)/1000), title 'Energia del fotvoltaico'

%% - Calcolo della Potenza Residua -
%Differenza tra potenza erogata dal pannello e potenza assorbita dal carico
for j=1:1:4
    for k=1:1:3
        Presiduo_k(:,j,k) = Ppv_out_k(:,j,k) - Pload_k;
    end
end

%Energia residua fotvoltaico-carico
Epv_res_k=cumtrapz(0.0167,Presiduo_k);
%figure(),plot(time_minutes,Epv_res_k(:,1,1)/1000), title 'Energia residua del sistema pannello-carico'

% Calcolo del punti in cui abbiamo la completa compensazione tra la potenza 
% erogata dal pannello e quella assorbita dal carico

%% - Ottimizzazione Batteria Sonnen - 
fullCapacity = 210*1e3; % Capacit? della Batteria in Wh  <-- 3 scelta
capacity = 210*1e3; % Wh

dod = 0.90; 
P_inv_bat_k = 3300*14; %W

%Nella fase di carica della batteria, avremo delle perdite di potenza
%dovute all'efficienza della Batteria.
%Nella fase di scarica, avremo altre perdite di potenza dovute
%all'effcienza dell'inverter interno alla batteria.
Befficiency = 0.98; % Rendimento della Batteria
rendimentoInverterBatteria = 0.95; 

Battery = ACBattery(fullCapacity, dod, P_inv_bat_k, Befficiency,rendimentoInverterBatteria);

P_bat = filterPower(Battery,Presiduo_k);
Ebat_k = batteryEnergy_k(Battery,P_bat);
% figure(), plot(time_minutes,Ebat_k(:,2,1)/1000);

%% - Ore necessarie per caricare la Batteria -
% 15Kwh =6 moduli da 2.5kwh 
% 210kwh=6 moduli *14
% Ptotass_ero=14*48*75=50.4kW
% Tempo_carica=210kWh/50.4kW=4,17h

enel_average_power = 50.4e+03;

charging_time = getTimeToReload(Battery,enel_average_power,Ebat_k);

%Energia erogata dalla batteria compresa di perdite dovute all'inverter interno
% Eout_bat_k=getEoutBattery(Battery,Eload_k,rendimentoInverterBatteria);
% figure(),plot(time_minutes,Eout_bat_k(:,1,1)/1000);
% title 'Energia erogabile dalla batteria'

% Flusso di potenza input/output in uscita/ingresso dall'inverter
%Presiduo_bat_inverter = Presiduo_k*rendimentoInverterBatteria;

%% - Ottimizzazione di ricarica dall'Enel - 
