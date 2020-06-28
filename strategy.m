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
panelPowerTemperatureCoefficient=0.35/100; %/�C
panelVoltageTemperatureCoefficient=176.6/1000; %V/�C
seriesPanelsNumber=400;
parallelsPanelsNumber=1;

PvField=PhotovoltaicField(Npannelli,Pnom,Vpanel_mpp,panelPowerTemperatureCoefficient,...
    panelVoltageTemperatureCoefficient,seriesPanelsNumber,parallelsPanelsNumber);
Ppv_k=getMaxOutputPowerSTC(PvField,G_k);

Ppv_k_scaled=rescaleMPPByTemperature(PvField,Ppv_k,T_k);

margin_k=ones(1440,1)*10*1000;
optimizePanelsNumber(PvField,Ppv_k,10*1000,margin_k);

%% - Inverter Fotovoltaico Solarmax -

%% - Pala Eolica -
%https://en.wind-turbine-models.com/turbines/1682-hummer-h25.0-100kw
ratedPower=100*1000;
ratedWindSpeed=10;
cutinWindSpeed=2.5;
cutoutWindSpeed=20;
survivalWindSpeed=50;
rotorDiameter=25;
generatorVoltage=690;
Prel_k=SolarmaxInverter.relativePower/100;
efficiency_k=SolarmaxInverter.efficiency/100;
% Aggiunto lo 0 per uniformare l'asse
Prel_k=[0;Prel_k];
efficiency_k=[0;efficiency_k];

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

figure(3)
titles=["Aprile" "Agosto" "Ottobre" "Dicembre"];
for i=1:1:4
    subplot(2,2,i)
    plot(time_minutes,Peol_k(:,i))
    datetick('x','HH:MM')
    title(titles(i))
    xlabel 'time'
    ylabel 'Peol(k)'
end


% ATTENZIONE non possiamo scendere sotto i 120Kw per non avere un fenomeno di power clipping
Pindcmax = 130*1e3;  %nominal P DC
Poutacmax = 100*1e3; %max P AC  <- ERRORE

inputVoltageInterval = [430,900];
outputVoltageInterval = 400; % numero sul datashet;
phasesNumber = 3; % trifase

Inverter = Solarmaxinverter(Prel_k,efficiency_k,Pindcmax,Poutacmax, inputVoltageInterval, outputVoltageInterval, phasesNumber);
%potenza PV tenendo conto dell'efficienza dell'inverter e temperatura
[Pinput_k,Pout_k] = getCharacteristicPout_Pin(Inverter,true);
% Interpolazione dei punti dell'asse Pinput corrispondenti a Ppv
Ppv_out_k = interpolateInputPowerPoints(Inverter ,Ppv_k_scaled,'spline');

%% - Carico -
Pload_k=vector(:,2)*1000; %W 
carico=Load(Pload_k);

% Energia assorbita dal carico
Eload_k=cumtrapz(0.0167,Pload_k);

%% - Calcolo della Potenza ed Energia Residua Fotovoltaico -
for j=1:1:4
    for k=1:1:3
        Presiduo_k(:,j,k) = Ppv_out_k(:,j,k) - Pload_k;
    end
end

% Energia Residua Fotvoltaico
Epv_res_k=cumtrapz(0.0167,Presiduo_k); 

%figure(), plot(time_minutes,Epv_res_k(:,1,1)/1000), title 'Energia residua del pannello batteria'

%% - Batteria -
fullCapacity = 210*1e3; % Capacit� della Batteria in Wh
capacity = 210*1e3; % Wh
dod = 0.90; 
P_inv_bat_k = 3300; 3300*14; %W

% Non tutta la potenza in ingresso/uscita � utilizzata per 
% caricare/scaricare la batteria a causa del suo rendimento di 
% carica/scarica.
Befficiency = 0.98; % Rendimento della Batteria

Battery = SimpleBattery(fullCapacity, dod, P_inv_bat_k, Befficiency);
%Energia Carica della batteria (in ingresso)
[Ebat_carica_k,Presidual] = batteryEnergy_k(Battery,Presiduo_k, Pload_k);


%% - Inverter per batteria Sonnen -
% Non tutta la potenza residua � utilizzata per scaricare/caricare la
% batteria in quanto il flusso energetico in uscita/ingresso � frazionato
% dal rendimento del suo inverter.

rendimentoInverterBatteria = 0.95; 

%Energia erogabile dalla batteria
Eout_batt_inverter_k  = fullCapacity - (Eload_k + Eload_k*0.05);
%figure(),plot(time_minutes,Eout_batt_inverter_k:,1,1)/1000),title 'Energia erogabile dalla batteria'

%% Evoluzione Energia del sistema
Etot_k = getEsystem(carico,Eload_k,Epv_res_k,Eout_batt_inverter_k);

%% - Costo Totale energia -
costoEnergia = 0.90; % �

%costoPerKwh
costoPerKwh =zeros(1440,4,3);
    for i=1:1:4
        for j=1:1:3
            costoPerKwh(i,j) = Etot_k(1440,j,k) * costoEnergia;
        end
    end
                

%% Grafici (1) -> Caratteristica ingresso-uscita Potenza PV tenendo conto dell'efficienza dell'inverter e temperatura

figure(1)
plot(Pinput_k/1000,Pout_k/1000);
title("Caratteristica ingresso-uscita potenza PV tenendo conto dell'efficienza dell'inverter e temperatura") 
xlabel 'Pinput [kw]'
ylabel 'Pout [kw]'
axis ([0 140 0 140])

%% Grafici (2) -> Potenze fotovoltaico - potenze in uscita dall'inverter

figure(2)
% Dicembre
subplot(2,2,1)
for i=1:1:3
    plot(Ppv_k_scaled(:,4,i)/1000,Ppv_out_k(:,4,i)/1000)
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'Ppv_k_scaled(k) [Kw]'
ylabel 'Ppv-out(k) [Kw]'
title("Potenza del fotovoltaico in uscita dall'inverter Dicembre")

% Aprile
subplot(2,2,2)
for i=1:1:3
    plot(Ppv_k_scaled(:,1,i)/1000,Ppv_out_k(:,1,i)/1000)
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'Ppv_k_scaled(k) [Kw]'
ylabel 'Ppv-out(k) [Kw]'
title("Potenza del fotovoltaico in uscita dall'inverter Aprile")
axis ([0 140 0 140])

% Agosto
subplot(2,2,3)
for i=1:1:3
    plot(Ppv_k_scaled(:,2,i)/1000,Ppv_out_k(:,2,i)/1000)
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'Ppv_k_scaled(k) [Kw]'
ylabel 'Ppv-out(k) [Kw]'
title("Potenza del fotovoltaico in uscita dall'inverter Agosto")
axis ([0 140 0 140])

% Ottobre
subplot(2,2,4)
for i=1:1:3
    plot(Ppv_k_scaled(:,3,i)/1000,Ppv_out_k(:,3,i)/1000)
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'Ppv_k_scaled(k) [Kw]'
ylabel 'Ppv-out(k) [Kw]'
title("Potenza del fotovoltaico in uscita dall'inverter Ottobre")

%% Grafici (3) -> Grafici potenze fotovoltaico per tutti i mesi e casi

figure(3)
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

%% Grafici (4) -> Effetto di scalatura della potenza dovuto alla temperatura

figure(4)
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
% alla temperatura, essendo questa al di sotto di 25�C

%% Grafici (5) -> Potenze Residue e di Carico per tutti i mesi e casi

figure(5)
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

%% Grafici (6) -> Potenza Batteria per tutti i mesi e casi
figure(6)

%Aprile
subplot(2,2,1)
for i=1:1:3
    plot(hours,Presidual(:,1,i)/1000)
    hold on
end
title('Potenza di scarica/carica della batteria (Aprile)')
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Pbat(k) [KW]'

%Agosto
subplot(2,2,2)
for i=1:1:3
    plot(hours,Presidual(:,2,i)/1000)
    hold on
end
title('Potenza di scarica/carica della batteria (Agosto)')
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Pbat(k) [KW]'

%Ottobre
subplot(2,2,3)
for i=1:1:3
    plot(hours,Presidual(:,3,i)/1000)
    hold on
end
title('Potenza di scarica/carica della batteria (Ottobre)')
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Pbat(k) [KW]'

%Dicembre
subplot(2,2,4)
for i=1:1:3
    plot(hours,Presidual(:,4,i)/1000)
    hold on
end
title('Potenza di scarica/carica della batteria (Dicembre)')
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Pbat(k) [KW]'

%% Grafici (7) -> Energia di Carica Batteria per tutti i mesi e casi
figure(7)

%Aprile
subplot(2,2,1)
for i=1:1:3
    plot(hours,Etot_k(:,1,i)/1000)
    hold on
end
title('Energia totale consumata dal sistema (Aprile)')
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Etot_k [KW]'

%Agosto
subplot(2,2,2)
for i=1:1:3
    plot(hours,Etot_k(:,2,i)/1000)
    hold on
end
title('Energia totale consumata dal sistema (Agosto)')
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Etot_k [KW]'

%Ottobre
subplot(2,2,3)
for i=1:1:3
    plot(hours,Etot_k(:,3,i)/1000)
    hold on
end
title('Energia totale consumata dal sistema (Ottobre)')
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Etot_k [KW]'

%Dicembre
subplot(2,2,4)
for i=1:1:3
    plot(hours,Etot_k(:,4,i)/1000)
    hold on
end
title('Energia totale consumata dal sistema (Dicembre)')
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Etot_k [KW]'
