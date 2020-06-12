clear all; clc; close all;

%% - Caricamento dati -
load Matfile/energy_hourly_cost.mat
load Matfile/daily_minute.mat

load Irradianze_medie_giornaliere_per_mesi/Matfile/Irradianza_Agosto.mat
load Irradianze_medie_giornaliere_per_mesi/Matfile/Irradianza_Aprile.mat
load Irradianze_medie_giornaliere_per_mesi/Matfile/Irradianza_Dicembre.mat
load Irradianze_medie_giornaliere_per_mesi/Matfile/Irradianza_Ottobre.mat

load 'Matfile/Battery_health.mat'

load 'Inverter/Solarmax_inverter.mat'

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
G_k=abs(interp1(time,G_k,hours,'spline'));

%% - Temperatura nei mesi per 24 ore -
% Solo massimo soleggiamento (1° pagina)
T_k(:,1,1)=IrradianzaAprile.T;
T_k(:,2,1)=IrradianzaAgosto.T;
T_k(:,3,1)=IrradianzaOttobre.T;
T_k(:,4,1)=IrradianzaDicembre.T;

%% - Potenza nominale in condizioni STC -
% STC <=> T=25°C, G(t)=1000 w/m^2 (massima irradianza)
Pnom=327;
Npannelli=400;
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
end
plot(hours,Pload_k_kw, 'r');
legend('soleggiato','nuvoloso','caso peggiore','Pload(k)')
xlabel 'hours'
ylabel 'Ppv(k) [Kw]'
title 'Dicembre'

%Aprile
subplot(2,2,2)
for i=1:1:3
    plot(hours,Ppv_k_kw(:,1,i));
    hold on
end
plot(hours,Pload_k_kw, 'r');
legend('soleggiato','nuvoloso','caso peggiore','Pload(k)')
xlabel 'hours'
ylabel 'Ppv(k) [Kw]'
title 'Aprile'

%Agosto
subplot(2,2,3)
for i=1:1:3
    plot(hours,Ppv_k_kw(:,2,i));
    hold on
end
plot(hours,Pload_k_kw, 'r');
legend('soleggiato','nuvoloso','caso peggiore','Pload(k)')
xlabel 'hours'
ylabel 'Ppv(k) [Kw]'
title 'Agosto'

%Ottobre
subplot(2,2,4)
for i=1:1:3
    plot(hours,Ppv_k_kw(:,3,i));
    hold on
end
plot(hours,Pload_k_kw, 'r');
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
costoBatteria = 10000; %€
capacitaBatteria = 189*1e3; %189 Kwh in [wh]

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
ylabel 'Costo per consumo di Kwh [€]'

%% Capacità residua batteria
Cbatteria=zeros(1440,1);
capacitaBatteria_kwh=capacitaBatteria / 1000;
for i=1:1:1440
    Cbatteria(i)=capacitaBatteria_kwh+Edelta_k_kwh(i,4,2);
end

plot(hours,Cbatteria);


%% Inverter

Prel_k=SolarmaxInverter.relativePower/100;
efficiency_k=SolarmaxInverter.efficiency/100;

% Aggiunto lo 0 per uniformare l'asse
Prel_k=[0;Prel_k];
efficiency_k=[0.50;efficiency_k];

% Prel_k = Pinput/Pinput_max con Pinput=Ppv
% Efficiency è data dalla formula dell'euro-efficienza

Pinput_max=400*1000; %w in DC
Poutput_max=330*1000; %w in AC

Pinput_k=Prel_k*Pinput_max;
%cfr. Pinput_k con Ppv_k per vedere la potenza in ingresso
Pout_k=efficiency_k.*Pinput_k;
%Pout_k=efficiency_k*Poutput_max;

%Plot (Pinput_k, Pout_k)
figure(5)
subplot(2,2,1)
plot(Pinput_k/1000,Pout_k/1000)
title('Caratteristica ingresso-uscita inverter Sunpower') 
xlabel 'Pinput [kw]'
ylabel 'Pout [kw]'

% Interpolazione dei punti dell'asse Pinput corrispondenti a Ppv
Ppv_out_k=abs(interp1(Pinput_k,Pout_k,Ppv_k(:,4,1),'linear')); %1440x1 results

subplot(2,2,2)
plot(Ppv_k(:,4,1)/1000,Ppv_out_k/1000);
hold on
title("Potenza del fotovoltaico in uscita dall'inverter")
xlabel 'Ppv(k) [Kw]'
ylabel 'Ppv-out(k) [Kw]'

% Calcolo del residuo di potenza tra quello prodotto e assorbito
Presiduo_k=Ppv_out_k - Pload_k;

subplot(2,2,3)
plot(hours,Ppv_out_k/1000)
hold on
plot(hours,Pload_k/1000)
hold on
plot(hours,Presiduo_k/1000)
legend('Ppv-out(k)','Pload(k)', 'Presiduo(k)')
title('Potenze ogni minuto')
xlabel 'ore'
ylabel 'Potenze [Kw]'

% Presiduo negativo => Potenza assorbita dalla batteria
% Presiduo positivo => Potenza fornita alla batteria

%% - Residuo energetico per batteria -

% Non tutta la potenza residua è utilizzata per scaricare/caricare la
% batteria in quanto il flusso energetico in uscita/ingresso è frazionato
% dal rendimento del suo inverter.

rendimentoInverterBatteria = 0.95; 

% Non tutta la potenza in ingresso/uscita è utilizzata per 
% caricare/scaricare la batteria a causa del suo rendimento di 
% carica/scarica.

% Efficienza_coloumbiana = scarica_totale [C=Ah] / carica_totale [C=Ah]

rendimentoBatteria = 0.98;

% Flusso di potenza input/output in uscita/ingresso dall'inverter
%Presiduo_bat_inverter = Presiduo_k*rendimentoInverterBatteria;

% Flusso di potenza per scaricare/caricare la batteria
for i=1:1:length(Presiduo_k)
    if (Presiduo_k(i) <= 0)
        Pbat_scarica_k(i) = Presiduo_k(i);
        Pbat_carica_k(i) = 0; 
    else
        Pbat_scarica_k(i) = 0;
        Pbat_carica_k(i) = Presiduo_k(i) * rendimentoInverterBatteria;
    end
end

% Plot dei risultati sull'ultimo subplot
subplot(2,2,4)
plot(hours,Pbat_scarica_k/1000,hours,Pbat_carica_k/1000)
legend('Pscarica(k)','Pcarica(k)')
title('Profili di scarica/carica della batteria')
xlabel 'ore'
ylabel 'Potenze [Kw]'

Pbat_k=Pbat_scarica_k+Pbat_carica_k;

% Energia di scarica & carica della batteria
Ebat_k(1)=capacitaBatteria;
for i=2:1:length(Pbat_k)
    Ebat_k(i)=Ebat_k(i-1)+(Pbat_k(i)+Pbat_k(i-1))*0.0167/2;
end
%Equivalente a: Ebat_k=cumtrapz(hours,Pbat) + Ebat(1);

%Plot potenza batteria ed energia
figure(6)
subplot(1,2,1)
plot(hours,Pbat_k/1000)
title('Potenza di scarica & carica della batteria')
xlabel 'hours'
ylabel 'Pbat(k) [KW]'

subplot(1,2,2)
plot(hours,Ebat_k/1000)
yline(capacitaBatteria_kwh,'-r','CapacitàBatteria = 189 KWh');
yline(capacitaBatteria_kwh*0.10,'-r','LimiteDiScarica = 18.9 KWh');
title('Energia di scarica & carica della batteria')
xlabel 'hours'
ylabel 'Ebat(k) [KWh]'

%% - Ottimizzazione inverter -
targetPrel=Ppv_k / Pinput_max;

figure(7)
plot(Prel_k,efficiency_k)
for i=1:150:length(targetPrel)
    xline(targetPrel(i),'-r',targetPrel(i));
end
title('Inverter Rendimento AC in uscita - Rendimento DC in ingresso');
xlabel 'Rendimento DC [%]'
ylabel 'Rendimento AC [%]'

% Le potenze generate dal fotovoltaico (Dicembre-soleggiato) 
% ogni minuto ricadono interamente
% nella regione di minimo rendimento in ingresso. Si conclude pertanto che
% l'inverter è sovradimensionato rispetto alle potenze generate, ed è dunque
% necessario usarne un'altro con potenza nominale più bassa.

