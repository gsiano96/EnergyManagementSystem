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
Pnom = 327; %[W]
Npannelli = 400;
Vpanel_mpp = 54.7;
Ipanel_mpp = 5.98;
panelPowerTemperatureCoefficient = 0.35/100; %[/°C]
panelVoltageTemperatureCoefficient = 176.6/1000; %[V/°C]
seriesPanelsNumber = 400;
parallelsPanelsNumber = 1;
NOCT = 45;

%% Carico
Pload_k=vector(:,2)*1000; %W 
Pload_med = mean(Pload_k)
carico=Load(Pload_k);

%Energia assorbita dal carico
Eload_k=cumtrapz(0.0167,Pload_k);

% figure(),plot(time_minutes,Eload_k(:)/1000);
% title 'Energia assorbita dal carico'

%% Ottimizzazione numero di Pannelli
margin = 1e+04; %[W]
Nmin_pannelli = ceil((margin+Pload_med)/Pnom)

PvField=PhotovoltaicField(Nmin_pannelli,Pnom,Vpanel_mpp,panelPowerTemperatureCoefficient,...
    panelVoltageTemperatureCoefficient,seriesPanelsNumber,parallelsPanelsNumber,NOCT);
Ppv_k=getMaxOutputPowerSTC(PvField,G_k);

Ppv_k_scaled=rescaleMPPByTemperature(PvField,Ppv_k,T_k,G_k);

%% - Inverter Fotovoltaico Solarmax da 66kw DC -
Prel_k=SolarmaxInverter.relativePower/100;
efficiency_k=SolarmaxInverter.efficiency/100;

% Aggiunto lo 0 per uniformare l'asse
Prel_k=[0;Prel_k];
efficiency_k=[0;efficiency_k];

% ATTENZIONE OTTIMIZZAZIONE INVERTER
Pindcmax = 66*1e3;  %nominal P DC
Poutacmax = 50*1e3; %max P AC 

inputVoltageInterval = [430,900];
outputVoltageInterval = 400; 
phasesNumber = 3; % trifase

Inverter = Solarmaxinverter(Prel_k,efficiency_k,Pindcmax,Poutacmax, inputVoltageInterval, outputVoltageInterval, phasesNumber);
%potenza PV tenendo conto dell'efficienza dell'inverter e temperatura
[Pin_inv_k,Pout_inv_k] = getCharacteristicPout_Pin(Inverter,true);
% Interpolazione dei punti dell'asse Pinput corrispondenti a Ppv

Ppv_out_k = interpolateInputPowerPoints(Inverter ,Ppv_k_scaled,'spline');

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

%% - Batteria DC senza inverter LG CHEM -
energy_module = 13.1*1e3;  % [Wh]
modules = 12;
fullCapacity = energy_module * modules; % Capacità della Batteria in Wh
capacity =  157200; % Wh
dod = 0.95; 
Pmax_erogabile = 5*1e3; %[W]
P_bat_k = Pmax_erogabile * 12; %W

%Nella fase di carica della batteria, avremo delle perdite di potenza
%dovute all'efficienza della Batteria.
%Nella fase di scarica, avremo altre perdite di potenza dovute
%all'effcienza dell'inverter del fotovoltaico.
Befficiency = 0.95; % Rendimento della Batteria

Battery = DCBattery(capacity, dod,P_bat_k,Befficiency)


% Energia carica batteria
Ebat_k=batteryEnergy_k(Battery,Ppv_k_scaled);
% figure(), plot(time_minutes,Ebat_k(:,2,1)/1000);

%% Calcolo delle ore necessarie a caricare la batteria partendo da una
% capacità residua pari a zero
% 15Kwh =6 moduli da 2.5kwh 
% 210kwh=6 moduli *14
% Ptotass_ero=14*48*75=50.4kW
% Tempo_carica=210kWh/50.4kW=4,16h


%Energia erogata dalla batteria compresa di perdite dovute all'inverter interno
% Eout_bat_k=getEoutBattery(Battery,Eload_k,rendimentoInverterBatteria);
% figure(),plot(time_minutes,Eout_bat_k(:,1,1)/1000);
% title 'Energia erogabile dalla batteria'

% Flusso di potenza input/output in uscita/ingresso dall'inverter
%Presiduo_bat_inverter = Presiduo_k*rendimentoInverterBatteria;

%Evoluzione energia del sistema
E_sist_res=(Epv_out_k-Eload_k-capacity);
% E_sist_res=E_sist_res(1440,:,:)

%Energia in batteria alla fine della giornata
% Ebat_end_day = getEBatteryEndDay(Battery,Ebat_k);



%% Grafici (1) -> Caratteristica ingresso-uscita Potenza PV tenendo conto dell'efficienza dell'inverter e temperatura

figure(1)

subplot(2,1,1)
plot(Pin_inv_k/1000,Pout_inv_k/1000);
title("Caratteristica ingresso-uscita potenza PV tenendo conto dell'efficienza dell'inverter e temperatura") 
xlabel 'Pinput [kw]'
ylabel 'Pout [kw]'
axis ([0 140 0 140])

subplot(2,1,2)
plot(Prel_k,efficiency_k);
title("Caratteristica efficienza inverter") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'

%% Grafici (2) -> Valori medi di lavoro nella regione di efficienza dell'inverter fotovoltaico

figure(2)
%Aprile Soleggiato
subplot(2,2,1)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,1,1)*100,'-g',med_targetPrel(1,1,1)*100);
xline(max_targetPrel(1,1,1)*100,'-r',max_targetPrel(1,1,1)*100);
title("Caratteristica efficienza inverter Aprile Soleggiato") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'
axis ([0 130 0 100])
%Aprile Nuvoloso 
subplot(2,2,2)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,1,2)*100,'-g',med_targetPrel(1,1,2)*100);
xline(max_targetPrel(1,1,2)*100,'-r',max_targetPrel(1,1,2)*100);
title("Caratteristica efficienza inverter Nuvoloso") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'
axis ([0 120 0 100])
%Aprile Caso peggiore
subplot(2,2,3)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,1,3)*100,'-g',med_targetPrel(1,1,3)*100);
xline(max_targetPrel(1,1,3)*100,'-r',max_targetPrel(1,1,3)*100);
title("Caratteristica efficienza inverter Caso peggiore") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'
axis ([0 120 0 100])

figure(3)
%Agosto Soleggiato
subplot(2,2,1)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,2,1)*100,'-g',med_targetPrel(1,2,1)*100);
xline(max_targetPrel(1,2,1)*100,'-r',max_targetPrel(1,2,1)*100);
title("Caratteristica efficienza inverter Agosto Soleggiato") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'
axis ([0 120 0 100])
%Agosto Nuvoloso 
subplot(2,2,2)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,2,2)*100,'-g',med_targetPrel(1,2,2)*100);
xline(max_targetPrel(1,2,2)*100,'-r',max_targetPrel(1,2,2)*100);
title("Caratteristica efficienza inverter Agosto Nuvoloso") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'
axis ([0 120 0 100])
%Agosto Caso peggiore
subplot(2,2,3)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,2,3)*100,'-g',med_targetPrel(1,2,3)*100);
xline(max_targetPrel(1,2,3)*100,'-r',max_targetPrel(1,2,3)*100);
title("Caratteristica efficienza inverter Agosto Caso peggiore") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'
axis ([0 120 0 100])

figure(4)
%Ottobre Soleggiato
subplot(2,2,1)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,3,1)*100,'-g',med_targetPrel(1,3,1)*100);
xline(max_targetPrel(1,3,1)*100,'-r',max_targetPrel(1,3,1)*100);
title("Caratteristica efficienza inverter Ottobre Soleggiato") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'
axis ([0 120 0 100])
%Ottobre Nuvoloso 
subplot(2,2,2)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,3,2)*100,'-g',med_targetPrel(1,3,2)*100);
xline(max_targetPrel(1,3,2)*100,'-r',max_targetPrel(1,3,2)*100);
title("Caratteristica efficienza inverter Ottobre Nuvoloso") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'
axis ([0 120 0 100])
%Ottobre Caso peggiore
subplot(2,2,3)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,3,3)*100,'-g',med_targetPrel(1,3,3)*100);
xline(max_targetPrel(1,3,3)*100,'-r',max_targetPrel(1,3,3)*100);
title("Caratteristica efficienza inverter Ottobre Caso peggiore") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'
axis ([0 120 0 100])

figure(5)
%Dicembre Soleggiato
subplot(2,2,1)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,4,1)*100,'-g',med_targetPrel(1,4,1)*100);
xline(max_targetPrel(1,4,1)*100,'-r',max_targetPrel(1,4,1)*100);
title("Caratteristica efficienza inverter Dicembre Soleggiato") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'
axis ([0 120 0 100])
%Dicembre Nuvoloso 
subplot(2,2,2)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,4,2)*100,'-g',med_targetPrel(1,4,2)*100);
xline(max_targetPrel(1,4,2)*100,'-r',max_targetPrel(1,4,2)*100);
title("Caratteristica efficienza inverter Dicembre Nuvoloso") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'
axis ([0 120 0 100])
%Dicembre Caso peggiore
subplot(2,2,3)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,4,3)*100,'-g',med_targetPrel(1,4,3)*100);
xline(max_targetPrel(1,4,3)*100,'-r',max_targetPrel(1,4,3)*100);
title("Caratteristica efficienza inverter Dicembre Caso peggiore") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'
axis ([0 120 0 100])

%% Grafici (2) -> Potenze fotovoltaico - potenze in uscita dall'inverter

figure(6)

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

figure(7)
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

figure(8)
% Aprile
subplot(2,2,1)
plot(time_minutes,Ppv_k(:,1,1)/1000);
hold on
plot(time_minutes,Ppv_k_scaled(:,1,1)/1000);
title('Aprile')
legend('soleggiato-STC','soleggiato')
xlabel 'time'
ylabel 'Ppv(k)'

% Agosto
subplot(2,2,2)
plot(time_minutes,Ppv_k(:,2,1)/1000);
hold on
plot(time_minutes,Ppv_k_scaled(:,2,1)/1000);
title('Agosto')
legend('soleggiato-STC','soleggiato')
xlabel 'time'
ylabel 'Ppv(k)'

% Ottobre
subplot(2,2,3)
plot(time_minutes,Ppv_k(:,3,1)/1000);
hold on
plot(time_minutes,Ppv_k_scaled(:,3,1)/1000);
title('Ottobre')
legend('soleggiato-STC','soleggiato')
xlabel 'time'
ylabel 'Ppv(k)'

% Dicembre
subplot(2,2,4)
plot(time_minutes,Ppv_k(:,4,1)/1000);
hold on
plot(time_minutes,Ppv_k_scaled(:,4,1)/1000);
title('Dicembre')
legend('soleggiato-STC','soleggiato')
xlabel 'time'
ylabel 'Ppv(k)'

% I mesi Aprile, Ottobre e Dicembre 
% non risentono dell'effetto di scalatura della potenza dovuto
% alla temperatura, essendo questa al di sotto di 25°C

%% Grafici (5) -> Potenze Residue e di Carico per tutti i mesi e casi

figure(9)
% Aprile
subplot(2,2,1)
for i=1:1:3
    plot(time_minutes,Presiduo_k(:,1,i)/1000)
    hold on
%     idx_giorno_apr(i) = interp1(Presiduo_k(1:1:720,1,i),hours(1:1:720),0,'nearest');
%     time_idx_giorno_apr = datetime(string(datestr(idx_giorno_apr/24,'HH:MM')) ,'InputFormat','HH:mm')
%     idx_sera_apr(i) = interp1(Presiduo_k(end:-1:720,1,i),hours(end:-1:720),0,'nearest')
%     time_idx_sera_apr = datetime(string(datestr(idx_sera_apr/24,'HH:MM')) ,'InputFormat','HH:mm')
%     xline(time_idx_sera_apr(i),'-r','punto')
%     xline(time_idx_giorno_apr(i),'-m','punto')
end
legend('soleggiato', 'nuvoloso', 'caso peggiore')
title('Presiduo(k) Aprile')
xlabel 'ore'
ylabel 'Potenze [Kw]'

% Agosto
subplot(2,2,2)
for i=1:1:3
    plot(time_minutes,Presiduo_k(:,2,i)/1000)
    hold on
%     idx_giorno_ago(i) = interp1(Presiduo_k(1:1:720,2,i),hours(1:1:720),0,'nearest');
%     time_idx_giorno_ago = datetime(string(datestr(idx_giorno_ago/24,'HH:MM')) ,'InputFormat','HH:mm')
%     idx_sera_ago(i) = interp1(Presiduo_k(end:-1:720,2,i),hours(end:-1:720),0,'nearest')
%     time_idx_sera_ago = datetime(string(datestr(idx_sera_ago/24,'HH:MM')) ,'InputFormat','HH:mm')
%     xline(time_idx_sera_ago(i),'-r','punto') 
%     xline(time_idx_giorno_ago(i),'-m','punto')
end
legend('soleggiato', 'nuvoloso', 'caso peggiore')
title('Presiduo(k) Agosto')
xlabel 'ore'
ylabel 'Potenze [Kw]'

% Ottobre
subplot(2,2,3)
for i=1:1:3
    plot(time_minutes,Presiduo_k(:,3,i)/1000)
    hold on
%     idx_giorno_ott(i) = interp1(Presiduo_k(1:1:720,3,i),hours(1:1:720),0,'nearest');
%     time_idx_giorno_ott = datetime(string(datestr(idx_giorno_ott/24,'HH:MM')) ,'InputFormat','HH:mm')
%     idx_sera_ott(i) = interp1(Presiduo_k(end:-1:720,3,i),hours(end:-1:720),0,'nearest')
%     time_idx_sera_ott = datetime(string(datestr(idx_sera_ott/24,'HH:MM')) ,'InputFormat','HH:mm')
%     xline(time_idx_sera_ott(i),'-r','punto') 
%     xline(time_idx_giorno_ott(i),'-m','punto')
end
legend('soleggiato', 'nuvoloso', 'caso peggiore')
title('Presiduo(k) Ottobre')
xlabel 'ore'
ylabel 'Potenze [Kw]'

% Dicembre
subplot(2,2,4)
for i=1:1:3
    plot(time_minutes,Presiduo_k(:,4,i)/1000)
    hold on
%     idx_giorno_dic(i) = interp1(Presiduo_k(1:1:720,4,i),hours(1:1:720),0,'nearest');
%     time_idx_giorno_dic = datetime(string(datestr(idx_giorno_dic/24,'HH:MM')) ,'InputFormat','HH:mm')
%     idx_sera_dic(i) = interp1(Presiduo_k(end:-1:720,4,i),hours(end:-1:720),0,'nearest')
%     time_idx_sera_dic = datetime(string(datestr(idx_sera_dic/24,'HH:MM')) ,'InputFormat','HH:mm')
%     xline(time_idx_sera_dic(i),'-r','punto') 
%     xline(time_idx_giorno_dic(i),'-m','punto')
end
legend('soleggiato', 'nuvoloso', 'caso peggiore')
title('Presiduo(k) Dicembre')
xlabel 'ore'
ylabel 'Potenze [Kw]'


%% Evoluzione energetica del sistema 

figure(10)
%Aprile Soleggiato
subplot(2,2,1)
plot(time_minutes,Ebat_k(:,1,1)/1000)
idx_giorno_apr = interp1(Presiduo_k(1:1:720,1,1),hours(1:1:720),0,'nearest');
time_idx_giorno_apr = datetime(string(datestr(idx_giorno_apr/24,'HH:MM')) ,'InputFormat','HH:mm');
idx_sera_apr = interp1(Presiduo_k(end:-1:720,1,1),hours(end:-1:720),0,'nearest');
time_idx_sera_apr = datetime(string(datestr(idx_sera_apr/24,'HH:MM')) ,'InputFormat','HH:mm');
xline(time_idx_sera_apr,'-r','Deficit Potenza Residua')
xline(time_idx_giorno_apr,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Aprile Soleggiato')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = 210 KWh');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = 21 KWh');

%Aprile Nuvoloso 
subplot(2,2,2)
plot(time_minutes,Ebat_k(:,1,2)/1000)
idx_giorno_apr = interp1(Presiduo_k(1:1:720,1,2),hours(1:1:720),0,'nearest');
time_idx_giorno_apr = datetime(string(datestr(idx_giorno_apr/24,'HH:MM')) ,'InputFormat','HH:mm');
idx_sera_apr = interp1(Presiduo_k(end:-1:720,1,2),hours(end:-1:720),0,'nearest');
time_idx_sera_apr = datetime(string(datestr(idx_sera_apr/24,'HH:MM')) ,'InputFormat','HH:mm');
xline(time_idx_sera_apr,'-r','Deficit Potenza Residua')
xline(time_idx_giorno_apr,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Aprile Nuvoloso')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = 210 KWh');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = 21 KWh');

%Aprile Caso peggiore
subplot(2,2,3)
plot(time_minutes,Ebat_k(:,1,3)/1000)
idx_giorno_apr = interp1(Presiduo_k(1:1:430,1,3),hours(1:1:430),0,'nearest');
time_idx_giorno_apr = datetime(string(datestr(idx_giorno_apr/24,'HH:MM')) ,'InputFormat','HH:mm');
idx_sera_apr = interp1(Presiduo_k(end:-1:720,1,3),hours(end:-1:720),0,'nearest');
time_idx_sera_apr = datetime(string(datestr(idx_sera_apr/24,'HH:MM')) ,'InputFormat','HH:mm');
xline(time_idx_sera_apr,'-r','Deficit Potenza Residua')
xline(time_idx_giorno_apr,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Aprile Caso Peggiore')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = 210 KWh');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = 21 KWh');

figure(11)
%Agosto Soleggiato
subplot(2,2,1)
plot(time_minutes,Ebat_k(:,2,1)/1000)
idx_giorno_ago = interp1(Presiduo_k(1:1:340,2,1),hours(1:1:340),0,'nearest');
time_idx_giorno_ago = datetime(string(datestr(idx_giorno_ago/24,'HH:MM')) ,'InputFormat','HH:mm');
idx_sera_ago = interp1(Presiduo_k(end:-1:720,2,1),hours(end:-1:720),0,'nearest');
time_idx_sera_ago = datetime(string(datestr(idx_sera_ago/24,'HH:MM')) ,'InputFormat','HH:mm');
xline(time_idx_sera_ago,'-r','Deficit Potenza Residua')
xline(time_idx_giorno_ago,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Agosto Soleggiato')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = 210 KWh');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = 21 KWh');

%Agosto Nuvoloso 
subplot(2,2,2)
plot(time_minutes,Ebat_k(:,2,2)/1000)
idx_giorno_ago = interp1(Presiduo_k(1:1:720,2,2),hours(1:1:720),0,'nearest');
time_idx_giorno_ago = datetime(string(datestr(idx_giorno_ago/24,'HH:MM')) ,'InputFormat','HH:mm');
idx_sera_ago = interp1(Presiduo_k(end:-1:720,2,2),hours(end:-1:720),0,'nearest');
time_idx_sera_ago = datetime(string(datestr(idx_sera_ago/24,'HH:MM')) ,'InputFormat','HH:mm');
xline(time_idx_sera_ago,'-r','Deficit Potenza Residua')
xline(time_idx_giorno_ago,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Agosto Nuvoloso')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = 210 KWh');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = 21 KWh');

%Agosto Caso peggiore
subplot(2,2,3)
plot(time_minutes,Ebat_k(:,2,3)/1000)
idx_giorno_ago = interp1(Presiduo_k(1:1:430,2,3),hours(1:1:430),0,'nearest');
time_idx_giorno_ago = datetime(string(datestr(idx_giorno_ago/24,'HH:MM')) ,'InputFormat','HH:mm');
idx_sera_ago = interp1(Presiduo_k(end:-1:720,2,3),hours(end:-1:720),0,'nearest');
time_idx_sera_ago_3 = datetime(string(datestr(idx_sera_ago/24,'HH:MM')) ,'InputFormat','HH:mm');
xline(time_idx_sera_ago_3,'-r','Deficit Potenza Residua')
xline(time_idx_giorno_ago,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Agosto Caso Peggiore')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = 210 KWh');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = 21 KWh');

figure(12)
%Ottobre Soleggiato
subplot(2,2,1)
plot(time_minutes,Ebat_k(:,3,1)/1000)
idx_giorno_ott = interp1(Presiduo_k(1:1:720,2,1),hours(1:1:720),0,'nearest');
time_idx_giorno_ott = datetime(string(datestr((idx_giorno_ott+0.7)/24,'HH:MM')) ,'InputFormat','HH:mm');
idx_sera_ott = interp1(Presiduo_k(end:-1:720,3,1),hours(end:-1:720),0,'nearest');
time_idx_sera_ott = datetime(string(datestr(idx_sera_ott/24,'HH:MM')) ,'InputFormat','HH:mm');
xline(time_idx_sera_ott,'-r','Deficit Potenza Residua')
xline(time_idx_giorno_ott,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Ottobre Soleggiato')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = 210 KWh');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = 21 KWh');

%Ottobre Nuvoloso 
subplot(2,2,2)
plot(time_minutes,Ebat_k(:,3,2)/1000)
idx_giorno_ott = interp1(Presiduo_k(1:1:720,3,2),hours(1:1:720),0,'nearest');
time_idx_giorno_ott = datetime(string(datestr(idx_giorno_ott/24,'HH:MM')) ,'InputFormat','HH:mm');
idx_sera_ott = interp1(Presiduo_k(end:-1:720,3,2),hours(end:-1:720),0,'nearest');
time_idx_sera_ott = datetime(string(datestr(idx_sera_ott/24,'HH:MM')) ,'InputFormat','HH:mm');
xline(time_idx_sera_ott,'-r','Deficit Potenza Residua')
xline(time_idx_giorno_ott,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Ottobre Nuvoloso')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = 210 KWh');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = 21 KWh');

%Ottobre Caso peggiore
subplot(2,2,3)
plot(time_minutes,Ebat_k(:,3,3)/1000)
idx_giorno_ott = interp1(Presiduo_k(1:1:430,3,3),hours(1:1:430),0,'nearest');
time_idx_giorno_ott = datetime(string(datestr(idx_giorno_ott/24,'HH:MM')) ,'InputFormat','HH:mm');
idx_sera_ott = interp1(Presiduo_k(end:-1:720,3,3),hours(end:-1:720),0,'nearest');
time_idx_sera_ott = datetime(string(datestr(idx_sera_ott/24,'HH:MM')) ,'InputFormat','HH:mm');
xline(time_idx_sera_ott,'-r','Deficit Potenza Residua')
xline(time_idx_giorno_ott,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Ottobre Caso Peggiore')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = 210 KWh');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = 21 KWh');

figure(13)
%Dicembre Soleggiato
subplot(2,2,1)
plot(time_minutes,Ebat_k(:,4,1)/1000)
idx_giorno_dic = interp1(Presiduo_k(1:1:720,4,1),hours(1:1:720),0,'nearest');
time_idx_giorno_dic = datetime(string(datestr(idx_giorno_dic/24,'HH:MM')) ,'InputFormat','HH:mm');
idx_sera_dic = interp1(Presiduo_k(end:-1:720,4,1),hours(end:-1:720),0,'nearest');
time_idx_sera_dic = datetime(string(datestr(idx_sera_dic/24,'HH:MM')) ,'InputFormat','HH:mm');
xline(time_idx_sera_dic,'-r','Deficit Potenza Residua')
xline(time_idx_giorno_dic,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Dicembre Soleggiato')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = 210 KWh');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = 21 KWh');

%Dicembre Nuvoloso 
subplot(2,2,2)
plot(time_minutes,Ebat_k(:,4,2)/1000)
idx_giorno_dic = interp1(Presiduo_k(1:1:720,4,2),hours(1:1:720),0,'nearest');
time_idx_giorno_dic = datetime(string(datestr(idx_giorno_dic/24,'HH:MM')) ,'InputFormat','HH:mm');
idx_sera_dic = interp1(Presiduo_k(end:-1:720,4,2),hours(end:-1:720),0,'nearest');
time_idx_sera_dic = datetime(string(datestr(idx_sera_dic/24,'HH:MM')) ,'InputFormat','HH:mm');
xline(time_idx_sera_dic,'-r','Deficit Potenza Residua')
xline(time_idx_giorno_dic,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Dicembre Nuvoloso')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = 210 KWh');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = 21 KWh');

%Dicembre Caso peggiore
subplot(2,2,3)
plot(time_minutes,Ebat_k(:,4,3)/1000)
idx_giorno_dic = interp1(Presiduo_k(1:1:480,4,3),hours(1:1:480),0,'nearest');
time_idx_giorno_dic = datetime(string(datestr(idx_giorno_dic/24,'HH:MM')) ,'InputFormat','HH:mm');
idx_sera_dic = interp1(Presiduo_k(end:-1:720,4,3),hours(end:-1:720),0,'nearest');
time_idx_sera_dic = datetime(string(datestr(idx_sera_dic/24,'HH:MM')) ,'InputFormat','HH:mm');
xline(time_idx_sera_dic,'-r','Deficit Potenza Residua')
xline(time_idx_giorno_dic,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Dicembre Caso Peggiore')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = 210 KWh');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = 21 KWh');

%% Evoluzione energetica del sistema
figure(14)

% Aprile
subplot(2,2,1)
for i=1:1:3
    plot(time_minutes,Epv_out_k(:,1,i)/1000)
    hold on
    yline((capacity+Eload_k(1440))/1000,'-r','Energia totale assorbita');
end
legend('soleggiato', 'nuvoloso', 'caso peggiore')
title('Energia complessiva prodotta ad Aprile')
xlabel 'ore'
ylabel 'Energia [kWh]'

% Agosto
subplot(2,2,2)
for i=1:1:3
    plot(time_minutes,Epv_out_k(:,2,i)/1000)
    hold on
    yline((capacity+Eload_k(1440))/1000,'-r','Energia totale assorbita');
    
end
legend('soleggiato', 'nuvoloso', 'caso peggiore')
title('Energia complessiva prodotta ad Agosto')
xlabel 'ore'
ylabel 'Energia [kWh]'

% Ottobre
subplot(2,2,3)
for i=1:1:3
    plot(time_minutes,Epv_out_k(:,3,i)/1000)
    hold on
    yline((capacity+Eload_k(1440))/1000,'-r','Energia totale assorbita');
end
legend('soleggiato', 'nuvoloso', 'caso peggiore')
title('Energia complessiva prodotta ad Ottobre')
xlabel 'ore'
ylabel 'Energia [kWh]'

% Dicembre
subplot(2,2,4)
for i=1:1:3
    plot(time_minutes,Epv_out_k(:,4,i)/1000)
    hold on
    yline((capacity+Eload_k(1440))/1000,'-r','Energia totale assorbita');
end
legend('soleggiato', 'nuvoloso', 'caso peggiore')
title('Energia complessiva prodotta a Dicembre')
xlabel 'ore'
ylabel 'Energia [kWh]'



