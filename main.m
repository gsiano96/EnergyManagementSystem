clear all; clc; close all;

%% - Caricamento dati -
load Matfile/energy_hourly_cost.mat
load Matfile/daily_minute.mat

load Irradianze_medie_giornaliere_per_mesi/Matfile/Irradianza_Agosto.mat
load Irradianze_medie_giornaliere_per_mesi/Matfile/Irradianza_Aprile.mat
load Irradianze_medie_giornaliere_per_mesi/Matfile/Irradianza_Dicembre.mat
load Irradianze_medie_giornaliere_per_mesi/Matfile/Irradianza_Ottobre.mat

load 'Matfile/Battery_health.mat'

%% - Scale temporali -
hours=vector(:,1)/60;
time=IrradianzaDicembre.time;
time=datevec(time); %from datetime to matrix of date and time
time=time(:,4); %extract hours as integers

% Aggiunta ora 24
time(25)=24;

%% - Irradianze nei mesi per 24 ore -
% Prima pagina della matrice
G_k(:,1,1)=IrradianzaAprile.G;
G_k(:,2,1)=IrradianzaAgosto.G;
G_k(:,3,1)=IrradianzaOttobre.G;
G_k(:,4,1)=IrradianzaDicembre.G;

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
% Solo massimo soleggiamento (1� pagina)
T_k(:,1,1)=IrradianzaAprile.T;
T_k(:,2,1)=IrradianzaAgosto.T;
T_k(:,3,1)=IrradianzaOttobre.T;
T_k(:,4,1)=IrradianzaDicembre.T;

%% - Potenza nominale in condizioni STC -
% STC <=> T=25�C, G(t)=1000 w/m^2 (massima irradianza)
Pnom=327;
Npannelli=200;
Pnompv=Pnom*Npannelli;

%% - Potenze generate dal fotovoltaico nei mesi -
Ppv_k=(Pnompv/1000)*G_k; %w (su scala di 0.0167 h)
Ppv_k_kw=Ppv_k/1000; %Kw

%% - Potenza di carico -
Pload_k_kw=vector(:,2); %Kw
Pload_k=Pload_k_kw*1000; %w

%% - Energia prodotta dal fotovoltaico -
Epv_k=cumtrapz(0.0167,Ppv_k); %Energy produced at each step
Epv_k_kwh=Epv_k/1000; %Kwh

%% - Energia dissipata dal carico -
Eload_k=cumtrapz(0.0167,Pload_k); %Energy consumed at each step of 0.0167 hours
Eload_k_kwh=Eload_k/1000; %Kwh

%% - Residuo energetico -
Edelta_k_kwh=Epv_k_kwh-Eload_k_kwh;

%% - Grafici potenze (1) -
figure(1)

%Dicembre
subplot(2,2,1)
for i=1:1:3
    plot(hours,Ppv_k_kw(:,4,i));
    hold on
    plot(hours,Pload_k_kw, 'r');
end
legend('soleggiato','nuvoloso','caso peggiore','Pload(k)')
xlabel 'hours'
ylabel 'Ppv(k) [Kw]'
title 'Dicembre'

%Aprile
subplot(2,2,2)
for i=1:1:3
    plot(hours,Ppv_k_kw(:,1,i));
    hold on
    plot(hours,Pload_k_kw, 'r');
end
legend('soleggiato','nuvoloso','caso peggiore','Pload(k)')
xlabel 'hours'
ylabel 'Ppv(k) [Kw]'
title 'Aprile'

%Agosto
subplot(2,2,3)
for i=1:1:3
    plot(hours,Ppv_k_kw(:,2,i));
    hold on
    plot(hours,Pload_k_kw, 'r');
end
legend('soleggiato','nuvoloso','caso peggiore','Pload(k)')
xlabel 'hours'
ylabel 'Ppv(k) [Kw]'
title 'Agosto'

%Ottobre
subplot(2,2,4)
for i=1:1:3
    plot(hours,Ppv_k_kw(:,3,i));
    hold on
    plot(hours,Pload_k_kw, 'r');
end
legend('soleggiato','nuvoloso','caso peggiore','Pload(k)')
xlabel 'hours'
ylabel 'Ppv(k) [Kw]'
title 'Ottobre'

%% Grafici Energie (2)
figure(2)

% Dicembre
subplot(2,2,1)
for i=1:1:3
    plot(hours,Epv_k_kwh(:,4,i))
    hold on
end
plot(hours,Eload_k_kwh)
legend('soleggiato','nuvoloso','caso peggiore', 'Eload(k)');
xlabel 'hours'
ylabel 'Energy [Kwh]'
title 'Dicembre'

% Aprile
subplot(2,2,2)
for i=1:1:3
    plot(hours,Epv_k_kwh(:,1,i))
    hold on
end
plot(hours,Eload_k_kwh)
legend('soleggiato','nuvoloso','caso peggiore', 'Eload(k)');
xlabel 'hours'
ylabel 'Energy [Kwh]'
title 'Aprile'

% Agosto
subplot(2,2,3)
for i=1:1:3
    plot(hours,Epv_k_kwh(:,2,i))
    hold on
end
plot(hours,Eload_k_kwh)
legend('soleggiato','nuvoloso','caso peggiore', 'Eload(k)');
xlabel 'hours'
ylabel 'Energy [Kwh]'
title 'Agosto'

% Ottobre
subplot(2,2,4)
for i=1:1:3
    plot(hours,Epv_k_kwh(:,3,i))
    hold on
end
plot(hours,Eload_k_kwh)
legend('soleggiato','nuvoloso','caso peggiore', 'Eload(k)');
xlabel 'hours'
ylabel 'Energy [Kwh]'
title 'Ottobre'

%% Grafici Residui energie (3)
figure(3)

% Dicembre
subplot(2,2,1)
for i=1:1:3
    plot(hours,Edelta_k_kwh(:,4,i))
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Energy [Kwh]'
title 'Residuo energetico Dicembre'

% Aprile
subplot(2,2,2)
for i=1:1:3
    plot(hours,Edelta_k_kwh(:,1,i))
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Energy [Kwh]'
title 'Residuo energetico Aprile'

% Agosto
subplot(2,2,3)
for i=1:1:3
    plot(hours,Edelta_k_kwh(:,2,i))
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Energy [Kwh]'
title 'Residuo energetico Agosto'

% Ottobre
subplot(2,2,4)
for i=1:1:3
    plot(hours,Edelta_k_kwh(:,3,i))
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Energy [Kwh]'
title 'Residuo energetico Ottobre'

%% - Costo dell'energia prelevata dalla batteria -
costoBatteria = 10000; %�
capacitaBatteria = 100*10e3; %100 Kwh in [wh]

dod=BatteryHealth(:,1); % asse x
nCicli_dod = BatteryHealth(:,2); % asse y come nCicli(dod)

costoPerCiclo_dod=costoBatteria/nCicli_dod; %costoPerCiclo(dod)
costoPerKwh_dod = costoPerCiclo_dod/capacitaBatteria;

countKwh=0;
for i=1:1:length(hours)
    targetKwh=Edelta_k_kwh(i,4,1);
    if(targetKwh < 0)
        countKwh=countKwh+(-targetKwh);
        targetDod=countKwh/capacitaBatteria; %[%]
        targetCostoPerKwh=spline(dod,costoPerKwh_dod,targetDod);
        targetCosto(i,4,1)=targetCostoPerKwh*countKwh;
    else
        targetCosto(i,4,1)=0;
    end
end

%% Grafici costi di consumo dell'energia dalla batteria (4)
figure(4)
plot(hours,targetCosto(:,4,1))
xlabel 'hours'
ylabel 'Costo per consumo di Kwh [�]'



        
        
    
    

