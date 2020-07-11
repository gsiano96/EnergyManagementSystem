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
    G_k(:,j,3)=G_k(:,j,1)*(1-0.60); % Caso peggiore => -60%
end

%% - Interpolazione fino a 1440 punti valore su ogni colonna di ogni pagina -
G_k=abs(interp1(time_hours,G_k,time_minutes,'spline'));

%% - Temperatura ambiente nei mesi per 24 ore -
temperatureMed=[IrradianzaAprile.T IrradianzaAgosto.T IrradianzaOttobre.T IrradianzaDicembre.T];

%Mesi x Casi
variazione_percentuale=[
    30 0 -30;
    20 0 -20;
    30 0 -30;
    20 0 -20];

for j=1:1:4
    for k=1:1:3
        T_k(:,j,k)=(1+variazione_percentuale(j,k)/100)*temperatureMed(:,j);
    end
end

%% - Interpolazione fino a 1440 punti valore -
T_k = interp1(time_hours,T_k,time_minutes,'spline');

%% - Campo fotovoltaico -
Pnom = 327; %[W]
Vpanel_mpp = 54.7;
Ipanel_mpp = 5.98;
panelPowerTemperatureCoefficient = 0.35/100; %[/°C]
panelVoltageTemperatureCoefficient = 176.6/1000; %[V/°C]
NOCT = 45 + randi([-2 2],1,1); %[°C]

%% - Disposizione campo fotovoltaico -
seriesPanelsNumber = 400;
parallelsPanelsNumber = 1;

%% Carico
Pload_k=vector(:,2)*1000; %W 

Pload_med = mean(Pload_k);
carico=Load(Pload_k);

%Energia assorbita dal carico
Eload_k = cumtrapz(0.0167,Pload_k);
%figure(),plot(time_minutes,Eload_k(:)/1000),title 'Energia assorbita dal carico'

Eload_med = Eload_k(1440)/24;
%% - Inverter Fotovoltaico Solarmax da 66kw DC -
Prel_k=SolarmaxInverter.relativePower/100;
efficiency_k=SolarmaxInverter.efficiency/100;

% Aggiunto lo 0 per uniformare l'asse
Prel_k=[0;Prel_k];
efficiency_k=[0;efficiency_k];

% ATTENZIONE OTTIMIZZAZIONE INVERTER
Pindcmax = 105*1e3;  %nominal P DC
Poutacmax = 80*1e3; %max P AC 

inputVoltageInterval = [430,900];
outputVoltageInterval = 400; 
phasesNumber = 3; % trifase

Inverter = Solarmaxinverter(Prel_k,efficiency_k,Pindcmax,Poutacmax, inputVoltageInterval, outputVoltageInterval, phasesNumber);

%potenza PV tenendo conto dell'efficienza dell'inverter e temperatura
[Pin_inv_k,Pout_inv_k] = getCharacteristicPout_Pin(Inverter,true);


%% Ottimizzazione numero di Pannelli
Prel_r = max(efficiency_k);
efficiency_r = 0.956;

margin = ((Prel_r .* Pindcmax .* efficiency_r) - Pload_med)  * 1.23; %[W]
Nmin_pannelli = ceil((margin+Pload_med)/Pnom)


%% - Dimensionamento Potenze campo fotovoltaico -
PvField=PhotovoltaicField(Nmin_pannelli,Pnom,Vpanel_mpp,panelPowerTemperatureCoefficient,...
    panelVoltageTemperatureCoefficient,seriesPanelsNumber,parallelsPanelsNumber,NOCT);
Ppv_k=getMaxOutputPowerSTC(PvField,G_k);

Ppv_k_scaled=rescaleMPPByTemperature(PvField,Ppv_k,T_k,G_k);


% Interpolazione dei punti dell'asse Pinput corrispondenti a Ppv
Ppv_out_k = interpolateInputPowerPoints(Inverter ,Ppv_k_scaled,'spline');

%% Funzionamento del sistema 
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
modules = ceil((Pload_med * 4)/(energy_module)) %12
fullCapacity = energy_module * modules % Capacità della Batteria in Wh
capacity =  fullCapacity; % Wh
dod = 0.90; 

Pmax_erogabile = 5*1e3; %[W]
P_bat_k = Pmax_erogabile * 12; %W

%Nella fase di carica della batteria, avremo delle perdite di potenza
%dovute all'efficienza della Batteria.
%Nella fase di scarica, avremo altre perdite di potenza dovute
%all'effcienza dell'inverter del fotovoltaico.
Befficiency = 0.95; % Rendimento della Batteria

Battery = DCBattery(capacity, dod,P_bat_k,Befficiency);

%Lato DC
P_bat = filterPower(Battery,Presiduo_k);
Ebat_k = batteryEnergy_k(Battery,P_bat);

%Potenza in uscita dall'inverter
Prel_bat=abs(P_bat)/Pindcmax;
IEff = interp1(Prel_k,efficiency_k,Prel_bat,'spline');


for j=1:1:4
    for k=1:1:3
        [Pbat_carica(:,j,k),Pbat_scarica(:,j,k)] = decouplePowerBattery(Battery,P_bat(:,j,k));
    end
end

% Percentuali di interesse in input all'inverter
med_targetPrelbat=getMeanTarget(Inverter,Pbat_scarica,Pindcmax); % media
max_targetPrelbat=getMaxTarget(Inverter,Pbat_scarica,Pindcmax); % massimo


Pbat_out_k = interpolateInputPowerPoints(Inverter ,Pbat_scarica,'spline');
%figure(), plot(time_minutes,Pbat_out_k(:,2,1)/1000);

%% Calcolo delle ore necessarie a caricare la batteria partendo da una
% capacità residua pari a zero

% 15Kwh =6 moduli da 2.5kwh 
% 210kwh=6 moduli *14
% Ptotass_ero=14*48*75=50.4kW
% Tempo_carica=210kWh/50.4kW=4,16h

enel_average_power = 50.4e+03;

charging_time = getTimeToReload(Battery,enel_average_power,Ebat_k);

%Energia erogata dalla batteria compresa di perdite dovute all'inverter interno
% Eout_bat_k=getEoutBattery(Battery,Eload_k,rendimentoInverterBatteria);
% figure(),plot(time_minutes,Eout_bat_k(:,1,1)/1000);
% title 'Energia erogabile dalla batteria'

% Flusso di potenza input/output in uscita/ingresso dall'inverter
%Presiduo_bat_inverter = Presiduo_k*rendimentoInverterBatteria;

%% - Ottimizzazione di ricarica dall'Enel - 

% ore fino a che possiamo scaricare la batteria per avere ad inizio-fine 
% giornata la stessa energia in batteria (in questo caso la capacita
% massima)

%Aprile
hour_max_battery_1_1 = getHourMaxBattery1_1(Battery,Ebat_k,enel_average_power,hours);
hour_max_battery_1_2 = getHourMaxBattery1_2(Battery,Ebat_k,enel_average_power,hours);
hour_max_battery_1_3 = getHourMaxBattery1_3(Battery,Ebat_k,enel_average_power,hours);
aprile_bar = [hour_max_battery_1_1,hour_max_battery_1_2,hour_max_battery_1_3];

%Agosto
hour_max_battery_2_1 = getHourMaxBattery2_1(Battery,Ebat_k,enel_average_power,hours);
hour_max_battery_2_2 = getHourMaxBattery2_2(Battery,Ebat_k,enel_average_power,hours);
hour_max_battery_2_3 = getHourMaxBattery2_3(Battery,Ebat_k,enel_average_power,hours);
agosto_bar = [hour_max_battery_2_1,hour_max_battery_2_2,hour_max_battery_2_3];

%Ottobre
hour_max_battery_3_1 = getHourMaxBattery3_1(Battery,Ebat_k,enel_average_power,hours);
hour_max_battery_3_2 = getHourMaxBattery3_2(Battery,Ebat_k,enel_average_power,hours);
hour_max_battery_3_3 = getHourMaxBattery3_3(Battery,Ebat_k,enel_average_power,hours);
ottobre_bar = [hour_max_battery_3_1,hour_max_battery_3_2,hour_max_battery_3_3];

%Dicembre
hour_max_battery_4_1 = getHourMaxBattery4_1(Battery,Ebat_k,enel_average_power,hours);
hour_max_battery_4_2 = getHourMaxBattery4_2(Battery,Ebat_k,enel_average_power,hours);
hour_max_battery_4_3 = getHourMaxBattery4_3(Battery,Ebat_k,enel_average_power,hours);
dicembre_bar = [hour_max_battery_4_1,hour_max_battery_4_2,hour_max_battery_4_3];


% costi energia ore notturne
price_min = (costi(20)+costi(21)+costi(22)+costi(23)+costi(24))/5;


%% Evoluzione energia del sistema
E_sist_res=(Epv_out_k-Eload_k-capacity);


%% Grafici (1) -> Caratteristica ingresso-uscita Potenza PV tenendo conto dell'efficienza dell'inverter e temperatura

figure(1)

subplot(2,1,1)
plot(Pin_inv_k/1000,Pout_inv_k/1000);
title("Caratteristica ingresso-uscita potenza PV tenendo conto dell'efficienza dell'inverter e temperatura") 
xlabel 'Pinput [kw]'
ylabel 'Pout [kw]'

subplot(2,1,2)
plot(Prel_k,efficiency_k);
title("Caratteristica efficienza inverter") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'

% subplot(2,2,3)
% plot(Pbat_carica(:,1,1)/1000,Pbat_scarica(:,1,1)/1000);
% title("Caratteristica ingresso-uscita potenza Batteria tenendo conto dell'efficienza dell'inverter") 
% xlabel 'Pinput [kw]'
% ylabel 'Pout [kw]'

%% Grafici (2) -> Valori medi di lavoro nella regione di efficienza dell'inverter fotovoltaico

figure(2)
%Aprile Soleggiato
subplot(2,2,1)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,1,1)*100,'-g','Prel media =' + string(med_targetPrel(1,1,1)*100) + '%');
xline(max_targetPrel(1,1,1)*100,'-r','Prel max=' + string(max_targetPrel(1,1,1)*100)+ '%');
title("Caratteristica efficienza inverter Aprile Soleggiato") 
xlabel 'Prel [%]'
ylabel 'Efficienza [%]'

%Aprile Nuvoloso 
subplot(2,2,2)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,1,2)*100,'-g','Prel media =' + string(med_targetPrel(1,1,2)*100) + '%');
xline(max_targetPrel(1,1,2)*100,'-r','Prel max=' + string(max_targetPrel(1,1,2)*100)+ '%');
title("Caratteristica efficienza inverter Aprile Nuvoloso") 
xlabel 'Prel [%]'
ylabel 'Efficienza [%]'

%Aprile Caso peggiore
subplot(2,2,3)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,1,3)*100,'-g','Prel media =' + string(med_targetPrel(1,1,3)*100) + '%');
xline(max_targetPrel(1,1,3)*100,'-r','Prel max=' + string(max_targetPrel(1,1,3)*100)+ '%');
title("Caratteristica efficienza inverter Aprile Caso peggiore") 
xlabel 'Prel [%]'
ylabel 'Efficienza [%]'

figure(3)
%Agosto Soleggiato
subplot(2,2,1)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,2,1)*100,'-g','Prel media =' + string(med_targetPrel(1,2,1)*100)+ '%');
xline(max_targetPrel(1,2,1)*100,'-r','Prel max=' + string(max_targetPrel(1,2,1)*100)+ '%');
title("Caratteristica efficienza inverter Agosto Soleggiato") 
xlabel 'Prel [%]'
ylabel 'Efficienza [%]'

%Agosto Nuvoloso 
subplot(2,2,2)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,2,2)*100,'-g','Prel media =' + string(med_targetPrel(1,2,2)*100)+ '%');
xline(max_targetPrel(1,2,2)*100,'-r','Prel max=' + string(max_targetPrel(1,2,2)*100)+ '%');
title("Caratteristica efficienza inverter Agosto Nuvoloso") 
xlabel 'Prel [%]'
ylabel 'Efficienza [%]'

%Agosto Caso peggiore
subplot(2,2,3)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,2,3)*100,'-g','Prel media =' + string(med_targetPrel(1,2,3)*100)+ '%');
xline(max_targetPrel(1,2,3)*100,'-r','Prel max=' + string(max_targetPrel(1,2,3)*100)+ '%');
title("Caratteristica efficienza inverter Agosto Caso peggiore") 
xlabel 'Prel [%]'
ylabel 'Efficienza [%]'

figure(4)
%Ottobre Soleggiato
subplot(2,2,1)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,3,1)*100,'-g','Prel media =' + string(med_targetPrel(1,3,1)*100)+ '%');
xline(max_targetPrel(1,3,1)*100,'-r','Prel max=' + string(max_targetPrel(1,3,1)*100)+ '%');
title("Caratteristica efficienza inverter Ottobre Soleggiato") 
xlabel 'Prel [%]'
ylabel 'Efficienza [%]'

%Ottobre Nuvoloso 
subplot(2,2,2)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,3,2)*100,'-g','Prel media =' + string(med_targetPrel(1,3,2)*100)+ '%');
xline(max_targetPrel(1,3,2)*100,'-r','Prel max=' + string(max_targetPrel(1,3,2)*100)+ '%');
title("Caratteristica efficienza inverter Ottobre Nuvoloso") 
xlabel 'Prel [%]'
ylabel 'Efficienza [%]'

%Ottobre Caso peggiore
subplot(2,2,3)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,3,3)*100,'-g','Prel media =' + string(med_targetPrel(1,3,3)*100)+ '%');
xline(max_targetPrel(1,3,3)*100,'-r','Prel max=' + string(max_targetPrel(1,3,3)*100)+ '%');
title("Caratteristica efficienza inverter Ottobre Caso peggiore") 
xlabel 'Prel [%]'
ylabel 'Efficienza [%]'

figure(5)
%Dicembre Soleggiato
subplot(2,2,1)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,4,1)*100,'-g','Prel media =' + string(med_targetPrel(1,4,1)*100)+ '%');
xline(max_targetPrel(1,4,1)*100,'-r','Prel max=' + string(max_targetPrel(1,4,1)*100)+ '%');
title("Caratteristica efficienza inverter Dicembre Soleggiato") 
xlabel 'Prel [%]'
ylabel 'Efficienza [%]'

%Dicembre Nuvoloso 
subplot(2,2,2)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,4,2)*100,'-g','Prel media =' + string(med_targetPrel(1,4,2)*100)+ '%');
xline(max_targetPrel(1,4,2)*100,'-r','Prel max=' + string(max_targetPrel(1,4,2)*100)+ '%');
title("Caratteristica efficienza inverter Dicembre Nuvoloso") 
xlabel 'Prel [%]'
ylabel 'Efficienza [%]'

%Dicembre Caso peggiore
subplot(2,2,3)
plot(Prel_k*100,efficiency_k*100)
xline(med_targetPrel(1,4,3)*100,'-g','Prel media =' + string(med_targetPrel(1,4,3)*100)+ '%');
xline(max_targetPrel(1,4,3)*100,'-r','Prel max=' + string(max_targetPrel(1,4,3)*100)+ '%');
title("Caratteristica efficienza inverter Dicembre Caso peggiore") 
xlabel 'Prel [%]'
ylabel 'Efficienza [%]'


%% Grafici (3) -> Valori medi di lavoro nella regione di efficienza dell'inverter fotovoltaico Batteria

figure(6)
%Aprile 
plot(Prel_k*100,efficiency_k*100)
xline(mean(med_targetPrelbat(:))*100,'-g','Prel media =' + string(mean(med_targetPrelbat(:))*100)+ '%');
xline(max(max_targetPrelbat(:))*100,'-r','Prel max =' + string(max(max_targetPrelbat(:))*100)+ '%');
title("Caratteristica efficienza inverter-batteria") 
xlabel 'Prel [%]'
ylabel 'Efficienza [%]'



%% Grafici (4) -> Potenze fotovoltaico - potenze in uscita dall'inverter

figure(7)

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

%% Grafici (5) -> Grafici potenze fotovoltaico per tutti i mesi e casi

figure(8)
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

%% Grafici (6) -> Effetto di scalatura della potenza dovuto alla temperatura

figure(9)
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
% alla temperatura, essendo questa al di sotto di 25�C

figure(10)
% Aprile
subplot(2,2,1)
plot(time_minutes,Ppv_k(:,1,2)/1000);
hold on
plot(time_minutes,Ppv_k_scaled(:,1,2)/1000);
title('Aprile')
legend('nuvoloso-STC','nuvoloso')
xlabel 'time'
ylabel 'Ppv(k)'

% Agosto
subplot(2,2,2)
plot(time_minutes,Ppv_k(:,2,2)/1000);
hold on
plot(time_minutes,Ppv_k_scaled(:,2,2)/1000);
title('Agosto')
legend('nuvoloso-STC','nuvoloso')
xlabel 'time'
ylabel 'Ppv(k)'

% Ottobre
subplot(2,2,3)
plot(time_minutes,Ppv_k(:,3,2)/1000);
hold on
plot(time_minutes,Ppv_k_scaled(:,3,2)/1000);
title('Ottobre')
legend('nuvoloso-STC','nuvoloso')
xlabel 'time'
ylabel 'Ppv(k)'

% Dicembre
subplot(2,2,4)
plot(time_minutes,Ppv_k(:,4,2)/1000);
hold on
plot(time_minutes,Ppv_k_scaled(:,4,2)/1000);
title('Dicembre')
legend('nuvoloso-STC','nuvoloso')
xlabel 'time'
ylabel 'Ppv(k)'

% I mesi Aprile, Ottobre e Dicembre 
% non risentono dell'effetto di scalatura della potenza dovuto
% alla temperatura, essendo questa al di sotto di 25�C

figure(11)
% Aprile
subplot(2,2,1)
plot(time_minutes,Ppv_k(:,1,3)/1000);
hold on
plot(time_minutes,Ppv_k_scaled(:,1,3)/1000);
title('Aprile')
legend('caso peggiore-STC','caso peggiore')
xlabel 'time'
ylabel 'Ppv(k)'

% Agosto
subplot(2,2,2)
plot(time_minutes,Ppv_k(:,2,3)/1000);
hold on
plot(time_minutes,Ppv_k_scaled(:,2,3)/1000);
title('Agosto')
legend('caso peggiore-STC','caso peggiore')
xlabel 'time'
ylabel 'Ppv(k)'

% Ottobre
subplot(2,2,3)
plot(time_minutes,Ppv_k(:,3,3)/1000);
hold on
plot(time_minutes,Ppv_k_scaled(:,3,3)/1000);
title('Ottobre')
legend('caso peggiore-STC','caso peggiore')
xlabel 'time'
ylabel 'Ppv(k)'

% Dicembre
subplot(2,2,4)
plot(time_minutes,Ppv_k(:,4,3)/1000);
hold on
plot(time_minutes,Ppv_k_scaled(:,4,3)/1000);
title('Dicembre')
legend('caso peggiore-STC','caso peggiore')
xlabel 'time'
ylabel 'Ppv(k)'

% I mesi Aprile, Ottobre e Dicembre 
% non risentono dell'effetto di scalatura della potenza dovuto
% alla temperatura, essendo questa al di sotto di 25�C


%% Grafici (7) -> Potenze Residue e di Carico per tutti i mesi e casi

figure(12)
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


%% Grafici (8) -> Evoluzione energetica della Batteria 

figure(13)
%Aprile Soleggiato
subplot(2,2,1)
plot(time_minutes,Ebat_k(:,1,1)/1000)
% idx_giorno_apr = interp1(Presiduo_k(1:1:720,1,1),hours(1:1:720),0,'nearest');
% time_idx_giorno_apr = datetime(string(datestr(idx_giorno_apr/24,'HH:MM')) ,'InputFormat','HH:mm');
% idx_sera_apr = interp1(Presiduo_k(end:-1:720,1,1),hours(end:-1:720),0,'nearest');
% time_idx_sera_apr = datetime(string(datestr(idx_sera_apr/24,'HH:MM')) ,'InputFormat','HH:mm');
% xline(time_idx_sera_apr,'-r','Deficit Potenza Residua')
% xline(time_idx_giorno_apr,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Aprile Soleggiato')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = ' + string(fullCapacity/1000) + 'kW');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = ' +string(fullCapacity/1000*0.10)+'kW');

%Aprile Nuvoloso 
subplot(2,2,2)
plot(time_minutes,Ebat_k(:,1,2)/1000)
% idx_giorno_apr = interp1(Presiduo_k(1:1:720,1,2),hours(1:1:720),0,'nearest');
% time_idx_giorno_apr = datetime(string(datestr(idx_giorno_apr/24,'HH:MM')) ,'InputFormat','HH:mm');
% idx_sera_apr = interp1(Presiduo_k(end:-1:720,1,2),hours(end:-1:720),0,'nearest');
% time_idx_sera_apr = datetime(string(datestr(idx_sera_apr/24,'HH:MM')) ,'InputFormat','HH:mm');
% xline(time_idx_sera_apr,'-r','Deficit Potenza Residua')
% xline(time_idx_giorno_apr,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Aprile Nuvoloso')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = ' + string(fullCapacity/1000) + 'kW');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = ' +string(fullCapacity/1000*0.10)+'kW');

%Aprile Caso peggiore
subplot(2,2,3)
plot(time_minutes,Ebat_k(:,1,3)/1000)
% if(Presiduo_k(1:1:430,1,3) > 0)
%     idx_giorno_apr = interp1(Presiduo_k(1:1:430,1,3),hours(1:1:430),0,'nearest');
%     time_idx_giorno_apr = datetime(string(datestr(idx_giorno_apr/24,'HH:MM')) ,'InputFormat','HH:mm');
%     idx_sera_apr = interp1(Presiduo_k(end:-1:720,1,3),hours(end:-1:720),0,'nearest');
%     time_idx_sera_apr = datetime(string(datestr(idx_sera_apr/24,'HH:MM')) ,'InputFormat','HH:mm');
% else
%     time_idx_giorno_apr = datetime(string(datestr(0/24,'HH:MM')) ,'InputFormat','HH:mm');
%     time_idx_sera_apr = datetime(string(datestr(0/24,'HH:MM')) ,'InputFormat','HH:mm');
% end
% xline(time_idx_sera_apr,'-r','Deficit Potenza Residua')
% xline(time_idx_giorno_apr,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Aprile Caso Peggiore')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = ' + string(fullCapacity/1000) + 'kW');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = ' +string(fullCapacity/1000*0.10)+'kW');

figure(14)
%Agosto Soleggiato
subplot(2,2,1)
plot(time_minutes,Ebat_k(:,2,1)/1000)
% idx_giorno_ago = interp1(Presiduo_k(1:1:340,2,1),hours(1:1:340),0,'nearest');
% time_idx_giorno_ago = datetime(string(datestr(idx_giorno_ago/24,'HH:MM')) ,'InputFormat','HH:mm');
% idx_sera_ago = interp1(Presiduo_k(end:-1:720,2,1),hours(end:-1:720),0,'nearest');
% time_idx_sera_ago = datetime(string(datestr(idx_sera_ago/24,'HH:MM')) ,'InputFormat','HH:mm');
% xline(time_idx_sera_ago,'-r','Deficit Potenza Residua')
% xline(time_idx_giorno_ago,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Agosto Soleggiato')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = ' + string(fullCapacity/1000) + 'kW');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = ' +string(fullCapacity/1000*0.10)+'kW');

%Agosto Nuvoloso 
subplot(2,2,2)
plot(time_minutes,Ebat_k(:,2,2)/1000)
% idx_giorno_ago = interp1(Presiduo_k(1:1:720,2,2),hours(1:1:720),0,'nearest');
% time_idx_giorno_ago = datetime(string(datestr(idx_giorno_ago/24,'HH:MM')) ,'InputFormat','HH:mm');
% idx_sera_ago = interp1(Presiduo_k(end:-1:720,2,2),hours(end:-1:720),0,'nearest');
% time_idx_sera_ago = datetime(string(datestr(idx_sera_ago/24,'HH:MM')) ,'InputFormat','HH:mm');
% xline(time_idx_sera_ago,'-r','Deficit Potenza Residua')
% xline(time_idx_giorno_ago,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Agosto Nuvoloso')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = ' + string(fullCapacity/1000) + 'kW');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = ' +string(fullCapacity/1000*0.10)+'kW');

%Agosto Caso peggiore
subplot(2,2,3)
plot(time_minutes,Ebat_k(:,2,3)/1000)
% idx_giorno_ago = interp1(Presiduo_k(1:1:430,2,3),hours(1:1:430),0,'nearest');
% time_idx_giorno_ago = datetime(string(datestr(idx_giorno_ago/24,'HH:MM')) ,'InputFormat','HH:mm');
% idx_sera_ago = interp1(Presiduo_k(end:-1:720,2,3),hours(end:-1:720),0,'nearest');
% time_idx_sera_ago_3 = datetime(string(datestr(idx_sera_ago/24,'HH:MM')) ,'InputFormat','HH:mm');
% xline(time_idx_sera_ago_3,'-r','Deficit Potenza Residua')
% xline(time_idx_giorno_ago,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Agosto Caso Peggiore')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = ' + string(fullCapacity/1000) + 'kW');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = ' +string(fullCapacity/1000*0.10)+'kW');

figure(15)
%Ottobre Soleggiato
subplot(2,2,1)
plot(time_minutes,Ebat_k(:,3,1)/1000)
% idx_giorno_ott = interp1(Presiduo_k(1:1:720,2,1),hours(1:1:720),0,'nearest');
% time_idx_giorno_ott = datetime(string(datestr((idx_giorno_ott+0.7)/24,'HH:MM')) ,'InputFormat','HH:mm');
% idx_sera_ott = interp1(Presiduo_k(end:-1:720,3,1),hours(end:-1:720),0,'nearest');
% time_idx_sera_ott = datetime(string(datestr(idx_sera_ott/24,'HH:MM')) ,'InputFormat','HH:mm');
% xline(time_idx_sera_ott,'-r','Deficit Potenza Residua')
% xline(time_idx_giorno_ott,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Ottobre Soleggiato')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = ' + string(fullCapacity/1000) + 'kW');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = ' +string(fullCapacity/1000*0.10)+'kW');

%Ottobre Nuvoloso 
subplot(2,2,2)
plot(time_minutes,Ebat_k(:,3,2)/1000)
% idx_giorno_ott = interp1(Presiduo_k(1:1:720,3,2),hours(1:1:720),0,'nearest');
% time_idx_giorno_ott = datetime(string(datestr(idx_giorno_ott/24,'HH:MM')) ,'InputFormat','HH:mm');
% idx_sera_ott = interp1(Presiduo_k(end:-1:720,3,2),hours(end:-1:720),0,'nearest');
% time_idx_sera_ott = datetime(string(datestr(idx_sera_ott/24,'HH:MM')) ,'InputFormat','HH:mm');
% xline(time_idx_sera_ott,'-r','Deficit Potenza Residua')
% xline(time_idx_giorno_ott,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Ottobre Nuvoloso')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = ' + string(fullCapacity/1000) + 'kW');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = ' +string(fullCapacity/1000*0.10)+'kW');

%Ottobre Caso peggiore
subplot(2,2,3)
plot(time_minutes,Ebat_k(:,3,3)/1000)
% idx_giorno_ott = interp1(Presiduo_k(1:1:430,3,3),hours(1:1:430),0,'nearest');
% time_idx_giorno_ott = datetime(string(datestr(idx_giorno_ott/24,'HH:MM')) ,'InputFormat','HH:mm');
% idx_sera_ott = interp1(Presiduo_k(end:-1:720,3,3),hours(end:-1:720),0,'nearest');
% time_idx_sera_ott = datetime(string(datestr(idx_sera_ott/24,'HH:MM')) ,'InputFormat','HH:mm');
% xline(time_idx_sera_ott,'-r','Deficit Potenza Residua')
% xline(time_idx_giorno_ott,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Ottobre Caso Peggiore')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = ' + string(fullCapacity/1000) + 'kW');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = ' +string(fullCapacity/1000*0.10)+'kW');

figure(16)
%Dicembre Soleggiato
subplot(2,2,1)
plot(time_minutes,Ebat_k(:,4,1)/1000)
% idx_giorno_dic = interp1(Presiduo_k(1:1:720,4,1),hours(1:1:720),0,'nearest');
% time_idx_giorno_dic = datetime(string(datestr(idx_giorno_dic/24,'HH:MM')) ,'InputFormat','HH:mm');
% idx_sera_dic = interp1(Presiduo_k(end:-1:720,4,1),hours(end:-1:720),0,'nearest');
% time_idx_sera_dic = datetime(string(datestr(idx_sera_dic/24,'HH:MM')) ,'InputFormat','HH:mm');
% xline(time_idx_sera_dic,'-r','Deficit Potenza Residua')
% xline(time_idx_giorno_dic,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Dicembre Soleggiato')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = ' + string(fullCapacity/1000) + 'kW');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = ' +string(fullCapacity/1000*0.10)+'kW');

%Dicembre Nuvoloso 
subplot(2,2,2)
plot(time_minutes,Ebat_k(:,4,2)/1000)
% idx_giorno_dic = interp1(Presiduo_k(1:1:720,4,2),hours(1:1:720),0,'nearest');
% time_idx_giorno_dic = datetime(string(datestr(idx_giorno_dic/24,'HH:MM')) ,'InputFormat','HH:mm');
% idx_sera_dic = interp1(Presiduo_k(end:-1:720,4,2),hours(end:-1:720),0,'nearest');
% time_idx_sera_dic = datetime(string(datestr(idx_sera_dic/24,'HH:MM')) ,'InputFormat','HH:mm');
% xline(time_idx_sera_dic,'-r','Deficit Potenza Residua')
% xline(time_idx_giorno_dic,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Dicembre Nuvoloso')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = ' + string(fullCapacity/1000) + 'kW');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = ' +string(fullCapacity/1000*0.10)+'kW');

%Dicembre Caso peggiore
subplot(2,2,3)
plot(time_minutes,Ebat_k(:,4,3)/1000)
% idx_giorno_dic = interp1(Presiduo_k(1:1:480,4,3),hours(1:1:480),0,'nearest');
% time_idx_giorno_dic = datetime(string(datestr(idx_giorno_dic/24,'HH:MM')) ,'InputFormat','HH:mm');
% idx_sera_dic = interp1(Presiduo_k(end:-1:720,4,3),hours(end:-1:720),0,'nearest');
% time_idx_sera_dic = datetime(string(datestr(idx_sera_dic/24,'HH:MM')) ,'InputFormat','HH:mm');
% xline(time_idx_sera_dic,'-r','Deficit Potenza Residua')
% xline(time_idx_giorno_dic,'-m','Surplus Potenza Residua')
title('Energia complessiva della batteria Dicembre Caso Peggiore')
xlabel 'ore'
ylabel 'Energia [kWh]'
yline(fullCapacity/1000,'-r','CapacitàBatteria = ' + string(fullCapacity/1000) + 'kW');
yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = ' +string(fullCapacity/1000*0.10)+'kW');

%% Grafici (7) ->  Evoluzione energetica del sistema
figure(17)

% Aprile
subplot(2,2,1)
for i=1:1:3
    plot(time_minutes,Epv_out_k(:,1,i)/1000)
    hold on
    yline((capacity+Eload_k(1440))/1000,'-r','Energia totale assorbita='+string((capacity+Eload_k(1440))/1000)+'kW');
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
    yline((capacity+Eload_k(1440))/1000,'-r','Energia totale assorbita='+string((capacity+Eload_k(1440))/1000)+'kW');
    
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
    yline((capacity+Eload_k(1440))/1000,'-r','Energia totale assorbita='+string((capacity+Eload_k(1440))/1000)+'kW');
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
    yline((capacity+Eload_k(1440))/1000,'-r','Energia totale assorbita='+string((capacity+Eload_k(1440))/1000)+'kW');
end
legend('soleggiato', 'nuvoloso', 'caso peggiore')
title('Energia complessiva prodotta a Dicembre')
xlabel 'ore'
ylabel 'Energia [kWh]'

%% Grafici (8) -> Energia Residua in batteria a fine giornata
figure(18)

X = categorical({'Aprile','Agosto','Ottobre','Dicembre'});
% Aprile
for i = 1:1:3
    Ebat_aprile(i) = Ebat_k(1440,1,i)/1000;
end
% Agosto
for i = 1:1:3
    Ebat_agosto(i) = Ebat_k(1440,2,i)/1000;
end
% Ottobre
for i = 1:1:3
    Ebat_ottobre(i) = Ebat_k(1440,3,i)/1000;
end
% Dicembre
for i = 1:1:3
    Ebat_dicembre(i) = Ebat_k(1440,4,i)/1000;
end
btot=[Ebat_aprile;Ebat_agosto;Ebat_ottobre;Ebat_dicembre];
bar(X,btot)
legend ({'Soleggiato','Nuvoloso','CasoPeggiore'}); 
title("Energia residua in batteria al termine della giornata") ;


%% Grafici (9) ->  Ore di ricarica richieste dalla batteria
figure(19)
X = categorical({'Aprile','Agosto','Ottobre','Dicembre'});
h1 =(charging_time(1,:));
h2 =(charging_time(2,:));
h3 =(charging_time(3,:));
h4 =(charging_time(4,:));
htot=[h1;h2;h3;h4];
bar(X,htot)
legend ({'Soleggiato','Nuvoloso','CasoPeggiore'}); 
title("Ore di ricarica richieste dalla batteria ") ;


%% Grafici (10) ->  Ore fino a che possiamo scaricare la batteria
figure(20)
X = categorical({'Aprile','Agosto','Ottobre','Dicembre'});
otot=[aprile_bar;agosto_bar;ottobre_bar;dicembre_bar];
bar(X,otot)
legend ({'Soleggiato','Nuvoloso','CasoPeggiore'}); 
title("Orario di partenza della fase di ricarica della batteria ");

%% Grafici (11) ->  Costi d'acquisto Energia 
figure(21)
plot(costi)
xlabel('Ore del giorno')
ylabel('Costo (�/MWh)')
title('Profilo di costo energia')
axis([1 24 30 70])



%% Grafici (12) ->  Prezzo mensile di sostentamento da rete Enel 

figure(22)
% Aprile
labels = {'Soleggiato','Nuvoloso','CasoPeggiore'};
subplot(2,2,1)
s1 = price_min * abs((E_sist_res(1440,1,:))*1.0e-06);
pie(s1,{string(s1(1))+ '�',string(s1(2))+ '�',string(s1(3))+ '�'});
legend(labels)
title("Prezzo di sostentamento da rete Enel Aprile") 

% Agosto
subplot(2,2,2)
s2 = price_min * abs((E_sist_res(1440,2,:))*1.0e-06);
pie(s2,{string(s2(1))+ '�',string(s2(2))+ '�',string(s2(3))+ '�'});
legend(labels)
title("Prezzo di sostentamento da rete Enel Agosto") 

% Ottobre
subplot(2,2,3)
s3 = price_min * abs((E_sist_res(1440,3,:))*1.0e-06);
pie(s3,{string(s3(1))+ '�',string(s3(2))+ '�',string(s3(3))+ '�'});
legend(labels)
title("Prezzo di sostentamento da rete Enel Ottobre") 

% Dicembre
subplot(2,2,4)
s4 = price_min * abs((E_sist_res(1440,4,:))*1.0e-06);
pie(s4,{string(s4(1))+ '�',string(s4(2))+ '�',string(s4(3))+ '�'});
legend(labels)
title("Prezzo di sostentamento da rete Enel Dicembre") 


%% Grafici (13) ->  Prezzo di ricarica della batteria da rete Enel 

figure(23)
% Aprile
labels = {'Soleggiato','Nuvoloso','CasoPeggiore'};
subplot(2,2,1)
p1 = price_min * ((capacity-Ebat_aprile*1000)*1.0e-06);
pie(p1,{string(p1(1))+ '�',string(p1(2))+ '�',string(p1(3))+ '�'});
legend(labels)
title("Prezzo di ricarica della batteria da rete Enel Aprile") 

% Agosto
subplot(2,2,2)
p2 = price_min * ((capacity-Ebat_agosto*1000)*1.0e-06);
pie(p2,{string(p2(1))+ '�',string(p2(2))+ '�',string(p2(3))+ '�'});
legend(labels)
title("Prezzo di ricarica della batteria da rete Enel Agosto") 

% Ottobre
subplot(2,2,3)
p3 = price_min * ((capacity-Ebat_ottobre*1000)*1.0e-06);
pie(p3,{string(p3(1))+ '�',string(p3(2))+ '�',string(p3(3))+ '�'});
legend(labels)
title("Prezzo di ricarica della batteria da rete Enel Ottobre") 

% Dicembre
subplot(2,2,4)
p4 = price_min * ((capacity-Ebat_dicembre*1000)*1.0e-06);
pie(p4,{string(p4(1))+ '�',string(p4(2))+ '�',string(p4(3))+ '�'});
legend(labels)
title("Prezzo di ricarica della batteria da rete Enel Dicembre") 

%% Grafici (14) ->  Prezzo mensile di sostentamento da rete Enel 

figure(24)
% Aprile
labels = {'Soleggiato','Nuvoloso','CasoPeggiore'};
subplot(2,2,1)
t1(1)=s1(1)+p1(1);
t1(2)=s1(2)+p1(2);
t1(3)=s1(3)+p1(3);
pie(t1,{string(t1(1))+ '�',string(t1(2))+ '�',string(t1(3))+ '�'});
legend(labels)
title("Prezzo totale acquisto da rete Enel Aprile") 

% Agosto
subplot(2,2,2)
t2(1)=s2(1)+p2(1);
t2(2)=s2(2)+p2(2);
t2(3)=s2(3)+p2(3);
pie(t2,{string(t2(1))+ '�',string(t2(2))+ '�',string(t2(3))+ '�'});
legend(labels)
title("Prezzo totale acquisto da rete Enel Agosto") 

% Ottobre
subplot(2,2,3)
t3(1)=s3(1)+p3(1);
t3(2)=s3(2)+p3(2);
t3(3)=s3(3)+p3(3);
pie(t3,{string(t3(1))+ '�',string(t3(2))+ '�',string(t3(3))+ '�'});
legend(labels)
title("Prezzo totale acquisto da rete Enel Ottobre") 

% Dicembre
subplot(2,2,4)
t4(1)=s4(1)+p4(1);
t4(2)=s4(2)+p4(2);
t4(3)=s4(3)+p4(3);
pie(t4,{string(t4(1))+ '�',string(t4(2))+ '�',string(t4(3))+ '�'});
legend(labels)
title("Prezzo totale acquisto da rete Enel Dicembre") 

