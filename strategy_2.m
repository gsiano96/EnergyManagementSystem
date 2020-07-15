%% - Operazioni di Pulizia e formattazione -
clear all;
clc; 
close all;
set(0,'defaultfigurecolor','w');

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

%{
figure(8)

titles=["Irradianze giornaliere nel mese di Aprile per 24 ore",...
    "Irradianze giornaliere nel mese di Agosto per 24 ore",...
    "Irradianze giornaliere nel mese di Ottobre per 24 ore",...
    "Irradianze giornaliere nel mese di Dicembre per 24 ore"];

for month=1:1:4
    subplot(2,2,month)
    for caso=1:1:3
        plot(time_minutes,G_k(:,month,caso))
        hold on
    end
    title(titles(month))
    legend('soleggiato','parz. nuvoloso','nuvoloso')
    xlabel 'tempo'
    ylabel 'Irradianza'
end
%}
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

carico=Load(Pload_k);

%Energia assorbita dal carico
Eload_k = cumtrapz(0.0167,Pload_k);

%Eload_med = Eload_k(1440)/24;

figure(1)
   plot(time_minutes,vector(:,2))
   xlabel('Ore del giorno')
   ylabel('Potenza (kW)')
   title('Profilo di potenza del carico')
   
%% - Inverter Fotovoltaico Solarmax da 66kw DC -
Prel_k=SolarmaxInverter.relativePower/100;
efficiency_k=SolarmaxInverter.efficiency/100;

% Aggiunto lo 0 per uniformare l'asse
Prel_k=[0;Prel_k];
efficiency_k=[0.50;efficiency_k];

% ATTENZIONE OTTIMIZZAZIONE INVERTER
Pindcmax = 105*1e3;  %nominal P DC
Poutacmax = 88*1e3; %max P AC TODO

inputVoltageInterval = [430,900];
outputVoltageInterval = 400; 
phasesNumber = 3; % trifase

Inverter = Solarmaxinverter(Prel_k,efficiency_k,Pindcmax,Poutacmax, inputVoltageInterval, outputVoltageInterval, phasesNumber);

%potenza PV tenendo conto dell'efficienza dell'inverter e temperatura
[Pin_inv_k,Pout_inv_k] = getCharacteristicPout_Pin(Inverter,true);

%% Ottimizzazione numero di Pannelli
Prel_r = 0.50;
efficiency_r = 0.948; %euro-efficiency
Pload_med = mean(Pload_k); %TODO

%margin=(Prel_r * Pindcmax*efficiency_r - Pload_med); %[W] TODO
Nmin_pannelli=312; %ceil((margin+Pload_med)/(Pnom*efficiency_r))


%% - Dimensionamento Potenze campo fotovoltaico -
PvField=PhotovoltaicField(Nmin_pannelli,Pnom,Vpanel_mpp,panelPowerTemperatureCoefficient,...
    panelVoltageTemperatureCoefficient,seriesPanelsNumber,parallelsPanelsNumber,NOCT);
Ppv_k=getMaxOutputPowerSTC(PvField,G_k);

Ppv_k_scaled=rescaleMPPByTemperature(PvField,Ppv_k,T_k,G_k);


Prelpv=Ppv_k_scaled/Pindcmax;
efficiency_k=abs(interpolateInputRelativePower(Inverter,Prelpv,'spline'));

% Interpolazione dei punti dell'asse Pinput corrispondenti a Ppv
Ppv_out_k = interpolateInputPowerPoints(Inverter ,Ppv_k_scaled,'spline');

%% Funzionamento del sistema 
% Percentuali di interesse in input all'inverter
med_targetPrel=getMeanTarget(Inverter,Ppv_k_scaled,Pindcmax); % media
max_targetPrel=getMaxTarget(Inverter,Ppv_k_scaled,Pindcmax); % massimo

%Energia del fotvoltaico
Epv_out_k=cumtrapz(0.0167,Ppv_out_k);

%% - Calcolo della Potenza Residua -
%Differenza tra potenza erogata dal pannello e potenza assorbita dal carico
for j=1:1:4
    for k=1:1:3
        Presiduo_k(:,j,k) = Ppv_k_scaled(:,j,k) - Pload_k/efficiency_r; %efficiency_k(:,j,k)
    end
end

%Energia residua fotvoltaico-carico
Epv_res_k=cumtrapz(0.0167,Presiduo_k);

%% - Batteria DC senza inverter LG CHEM -
energy_module = 13.048*1e3;  % [Wh]
margin_hours=4;
modules = ceil((Pload_med * margin_hours)/(energy_module)); %=5 12 TODO
fullCapacity = energy_module * modules; % Capacità della Batteria in Wh
capacity =  fullCapacity; % Wh
dod = 0.90; 

Pmax_erogabile = 5*1e3; %[W]
Pbatmax = Pmax_erogabile * modules; %W

Befficiency = 0.95; % Rendimento della Batteria

Battery = DCBattery(capacity,dod,Pbatmax,Befficiency);

%Lato DC
P_bat = filterPower(Battery,Presiduo_k);
Ebat_k = batteryEnergy_k(Battery,P_bat);

%Potenza in uscita dall'inverter
%Prel_bat=abs(P_bat)/Pindcmax;
%IEff = interp1(Prel_k,efficiency_k,Prel_bat,'spline');

for j=1:1:4
    for k=1:1:3
        [Pbat_carica(:,j,k),Pbat_scarica(:,j,k)] = decouplePowerBattery(Battery,P_bat(:,j,k));
    end
end

% Percentuali di interesse in input all'inverter provenienti dalla batteria
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

grid=EletricityGrid(3,900,1);

%Aprile
hour_max_battery_1_1 = getHourMaxBattery(Battery,Ebat_k,enel_average_power,hours,1,1);
hour_max_battery_1_2 = getHourMaxBattery(Battery,Ebat_k,enel_average_power,hours,1,2);
hour_max_battery_1_3 = getHourMaxBattery(Battery,Ebat_k,enel_average_power,hours,1,3);
aprile_bar = [hour_max_battery_1_1,hour_max_battery_1_2,hour_max_battery_1_3];

%Agosto
hour_max_battery_2_1 = getHourMaxBattery(Battery,Ebat_k,enel_average_power,hours,2,1);
hour_max_battery_2_2 = getHourMaxBattery(Battery,Ebat_k,enel_average_power,hours,2,2);
hour_max_battery_2_3 = getHourMaxBattery(Battery,Ebat_k,enel_average_power,hours,2,3);
agosto_bar = [hour_max_battery_2_1,hour_max_battery_2_2,hour_max_battery_2_3];

%Ottobre
hour_max_battery_3_1 = getHourMaxBattery(Battery,Ebat_k,enel_average_power,hours,3,1);
hour_max_battery_3_2 = getHourMaxBattery(Battery,Ebat_k,enel_average_power,hours,3,2);
hour_max_battery_3_3 = getHourMaxBattery(Battery,Ebat_k,enel_average_power,hours,3,3);
ottobre_bar = [hour_max_battery_3_1,hour_max_battery_3_2,hour_max_battery_3_3];

%Dicembre
hour_max_battery_4_1 = getHourMaxBattery(Battery,Ebat_k,enel_average_power,hours,4,1);
hour_max_battery_4_2 = getHourMaxBattery(Battery,Ebat_k,enel_average_power,hours,4,2);
hour_max_battery_4_3 = getHourMaxBattery(Battery,Ebat_k,enel_average_power,hours,4,3);
dicembre_bar = [hour_max_battery_4_1,hour_max_battery_4_2,hour_max_battery_4_3];


% costi energia ore notturne
price_min = (costi(20)+costi(21)+costi(22)+costi(23)+costi(24))/5;


%% - Evoluzione energia del sistema - 
E_sist_res=(Epv_out_k-Eload_k-capacity);

Ebat_carica=cumtrapz(0.0167,Pbat_carica);

%% Guadagno vendita energia
guadagno=zeros(1440,4,3);
for month=1:1:4
    for caso=1:1:3
        guadagno(:,month,caso)=grid.putPower_k(Ebat_carica(:,month,caso)/1000, fullCapacity/1000, 0.05);
    end
end

%Potenza da prelevare dalla rete
Pgrid=zeros(1440,4,3);
for month=1:1:4
    for caso=1:1:3
        Pgrid(:,month,caso)=grid.getPowerDC_k(Ebat_k,7.829,78.29,Presiduo_k.*efficiency_k(:,month,caso));
    end
end


%% Costo prelievo dalla rete (Perdite)
Egrid=cumtrapz(0.0167,Pgrid);
costi=interp1(time_hours,costi,time_minutes,'spline');

perdita=zeros(1440,4,3);
for month=1:1:4
    for caso=1:1:3
        perdita(:,month,caso)=Egrid(:,month,caso)/1000.*costi/1000;
    end
end

%% Grafici (1) -> Caratteristica ingresso-uscita Potenza PV tenendo conto dell'efficienza dell'inverter e temperatura

figure(1)

subplot(2,1,1)
plot(Pin_inv_k/1000,Pout_inv_k/1000);
title("Caratteristica ingresso-uscita potenza PV tenendo conto dell'efficienza dell'inverter e temperatura") 
xlabel 'Pinput [kw]'
ylabel 'Pout [kw]'

subplot(2,1,2)
plot(Prel_k,Inverter.efficiency_k);
title("Caratteristica efficienza inverter") 
xlabel 'Prel [%]'
ylabel 'Rendimento [%]'


%% Grafici (2) -> Valori medi di lavoro nella regione di efficienza dell'inverter fotovoltaico

titles=["Caratteristica efficienza inverter Aprile","Caratteristica efficienza inverter Agosto",
    "Caratteristica efficienza inverter Ottobre","Caratteristica efficienza inverter Dicembre"];
legends=["Soleggiato","parz. nuvoloso","Nuvoloso"];
formats=["-g","-b","-r"];

figure(2)

h=zeros(1,3);
for month=1:1:4
    subplot(2,2,month)
    plot(Prel_k*100,Inverter.efficiency_k*100)
    for caso=1:1:3
        xline(med_targetPrel(1,month,caso)*100,formats(caso),'Prel media = ' + string(med_targetPrel(1,month,caso)*100) + '%');
        h(caso)=xline(max_targetPrel(1,month,caso)*100,formats(caso),'Prel max = ' + string(max_targetPrel(1,month,caso)*100)+ '%');
    end
    legend(h,legends)
    title(titles(month)) 
    xlabel 'Prel [%]'
    ylabel 'Efficienza [%]'
end


%% Grafici (3) -> Prel medio (del valore medio e massimo) per tutti i mesi e casi della potenza di scarica della batteria e di quella del fotovoltaico

figure(3)

legends=["Prel med-max batt.","Prel med-max fotovoltaico"];
formats=["-r","-g"];
h=zeros(1,2);

plot(Prel_k*100,Inverter.efficiency_k*100)

xline(mean(med_targetPrelbat(:))*100,formats(1),'Prel media = ' + string(mean(med_targetPrelbat(:))*100)+ '%');
h(1)=xline(mean(max_targetPrelbat(:))*100,formats(1),'Prel max = ' + string(mean(max_targetPrelbat(:))*100)+ '%');

xline(mean(med_targetPrel(:))*100,formats(2),'Prel media = ' + string(mean(med_targetPrel(:))*100)+ '%');
h(2)=xline(mean(max_targetPrel(:))*100,formats(2),'Prel max = ' + string(mean(max_targetPrel(:))*100)+ '%');

title("Efficienza inverter")
legend(h,legends)
xlabel 'Prel [%]'
ylabel 'Efficienza [%]'

%% Grafici (4) -> Potenze fotovoltaico - potenze in uscita dall'inverter

figure(4)

titles=["Potenza del fotovoltaico in uscita dall'inverter Aprile",...
    "Potenza del fotovoltaico in uscita dall'inverter Agosto",...
    "Potenza del fotovoltaico in uscita dall'inverter Ottobre",...
    "Potenza del fotovoltaico in uscita dall'inverter Dicembre"];
    
for month=1:1:4
    subplot(2,2,month)
    for caso=1:1:3
        plot(Ppv_k_scaled(:,month,caso)/1000,Ppv_out_k(:,month,caso)/1000)
        hold on
    end
    title(titles(month))
    legend('soleggiato','parz. nuvoloso','nuvoloso');
    xlabel 'Ppv_k_scaled(k) [Kw]'
    ylabel 'Ppv-out(k) [Kw]'
end


%% Grafici (5) -> Potenze fotovoltaico per tutti i mesi e casi

figure(5)

titles=["Aprile","Agosto","Ottobre","Dicembre"];

for month=1:1:4
    subplot(2,2,month)
    for caso=1:1:3
        plot(time_minutes,Ppv_k(:,month,caso)/1000);
        hold on
    end
    plot(time_minutes,Pload_k/1000, 'r');
    legend('soleggiato','parz. nuvoloso','nuvoloso','Pload(k)')
    xlabel 'tempo'
    ylabel 'Ppv(k) [Kw]'
    title(titles(month))
end
 

%% Grafici (6) -> Potenze fotovoltaico per tutti i mesi e casi scalate considerando la temperatura

figure(6)

titles=["Aprile","Agosto","Ottobre","Dicembre"];

for month=1:1:4
    subplot(2,2,month)
    for caso=1:1:3
        plot(time_minutes,Ppv_k_scaled(:,month,caso)/1000);
        hold on
    end
    plot(time_minutes,Pload_k/1000, 'r');
    legend('soleggiato','parz. nuvoloso','nuvoloso','Pload(k)')
    xlabel 'tempo'
    ylabel 'Ppv-scaled(k) [Kw]'
    title(titles(month))
end


%% Grafici (7) -> Potenza residua in AC e di carico per tutti i mesi e casi

figure(7)

titles=["Presiduo Aprile", "Presiduo Agosto","Presiduo Ottobre","Presiduo Dicembre"];

for month=1:1:4
    subplot(2,2,month)
    for caso=1:1:3
        plot(time_minutes,Presiduo_k(:,month,caso)/1000)
        hold on
    end
    plot(time_minutes,Pload_k/1000,'r')
    legend('soleggiato','parz. nuvoloso','nuvoloso','Pload(k)')
    title(titles(month))
    xlabel 'tempo'
    ylabel 'Potenze [Kw]'
end


%% Grafici (8) -> Evoluzione energetica della batteria 

figure(8)

titles=["Energia della batteria Aprile",...
    "Energia della batteria Agosto",...
    "Energia della batteria Ottobre",...
    "Energia della batteria Dicembre"];

for month=1:1:4
    subplot(2,2,month)
    for caso=1:1:3
        plot(time_minutes,Ebat_k(:,month,caso)/1000)
        hold on
    end
    title(titles(month))
    legend('soleggiato','parz. nuvoloso','nuvoloso')
    xlabel 'tempo'
    ylabel 'Energia [kWh]'
    yline(fullCapacity/1000,'-r','Capacità Batteria = ' + string(fullCapacity/1000) + 'kW');
    yline(fullCapacity/1000*0.10,'-r','LimiteDiScarica = ' +string(fullCapacity/1000*0.10)+'kW');
end


%% Grafici (9) -> Potenza in ingresso alla batteria 
titles=["Aprile","Agosto","Ottobre","Dicembre"];

figure(9)

for month=1:1:4
    subplot(2,2,month)
    for caso=1:1:3
        plot(time_minutes,Pbat_carica(:,month,caso)/1000)
        hold on
    end
    legend('soleggiato','parz. nuvoloso','nuvoloso');
    title(titles(month))
    xlabel("time")
    ylabel("Pcarica(k)");
end

%% Grafici (10) -> Energia in ingresso alla batteria 
figure(10)

for month=1:1:4
    subplot(2,2,month)
    for caso=1:1:3
        plot(time_minutes,Ebat_carica(:,month,caso)/1000)
        hold on
    end
    legend('soleggiato','parz. nuvoloso','nuvoloso');
    title(titles(month))
    xlabel("time")
    ylabel("Ecarica(k)");
    yline(fullCapacity/1000,'-r','Capacità Batteria = ' + string(fullCapacity/1000) + 'kWh');
end

%% Grafici (11) -> Guadagno derivato dalla vendita dell'energia ad Enel

figure(11)
% Aprile
titles={'soleggiato','parz. nuvoloso','nuvoloso'};
subplot(2,2,1)
pie(guadagno(1440,1,:),{string(guadagno(1440,1,1))+ '',string(guadagno(1440,1,2))+ '',string(guadagno(1440,1,3))+ ''});
legend(titles)
title("Guadagno derivato dalla vendita dell'energia Aprile") 

% Agosto
subplot(2,2,2)
pie(guadagno(1440,2,:),{string(guadagno(1440,2,1))+ '',string(guadagno(1440,2,2))+ '',string(guadagno(1440,2,3))+ ''});
legend(titles)
title("Guadagno derivato dalla vendita dell'energia Agosto") 

% Ottobre
subplot(2,2,3)
pie(guadagno(1440,3,:),{string(guadagno(1440,3,1))+ '',string(guadagno(1440,3,2))+ '',string(guadagno(1440,3,3))+ ''});
legend(titles)
title("Guadagno derivato dalla vendita dell'energia Ottobre") 

% Dicembre
subplot(2,2,4)
pie(guadagno(1440,4,:),{string(guadagno(1440,4,1))+ '',string(guadagno(1440,4,2))+ '',string(guadagno(1440,4,3))+ ''});
legend(titles)
title("Guadagno derivato dalla vendita dell'energia Dicembre") 



%% Grafici (12) -> (Perdita) Prezzo da pagare all'Enel per il sostentamento Aprile

figure(12)
% Aprile
titles={'soleggiato','parz. nuvoloso','nuvoloso'};
subplot(2,2,1)
pie(perdita(1440,1,:),{string(perdita(1440,1,1))+ '',string(perdita(1440,1,2))+ '',string(perdita(1440,1,3))+ ''});
legend(titles)
title("Costo aquisto energia da terzi per il sostentamento Aprile") 

% Agosto
subplot(2,2,2)
pie(perdita(1440,3,:),{string(perdita(1440,3,1))+ '',string(perdita(1440,3,2))+ '',string(perdita(1440,3,3))+ ''});
legend(titles)
title("Costo aquisto energia da terzi per il sostentamento Agosto") 

% Aprile
subplot(2,2,3)
pie(perdita(1440,3,:),{string(perdita(1440,3,1))+ '',string(perdita(1440,3,2))+ '',string(perdita(1440,3,3))+ ''});
legend(titles)
title("Costo aquisto energia da terzi per il sostentamento Ottobre") 

% Dicembre
subplot(2,2,4)
pie(perdita(1440,4,:),{string(perdita(1440,4,1))+ '',string(perdita(1440,4,2))+ '',string(perdita(1440,4,3))+ ''});
legend(titles)
title("Costo aquisto energia da terzi per il sostentamento Dicembre") 
