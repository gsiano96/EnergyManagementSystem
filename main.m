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

%% - Grafici (1)(2) -
figure(1)

% Grafici potenze fotovoltaico

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

figure(2)

% Grafici Energie fotovoltaico

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

%% Inverter

Prel_k=SolarmaxInverter.relativePower/100;
efficiency_k=SolarmaxInverter.efficiency/100;

% Aggiunto lo 0 per uniformare l'asse
Prel_k=[0;Prel_k];
efficiency_k=[0.50;efficiency_k];

% Prel_k = Pinput/Pinput_max con Pinput=Ppv
% Efficiency è data dalla formula dell'euro-efficienza

% ATTENZIONE non possiamo scendere sotto i 120Kw per non avere un fenomeno di power clipping
Pinput_max=130*1000; %w in DC
Poutput_max=100*1000; %w in AC

Pinput_k=Prel_k*Pinput_max;
%cfr. Pinput_k con Ppv_k per vedere la potenza in ingresso
Pout_k=efficiency_k.*Pinput_k;
%Pout_k=efficiency_k*Poutput_max;

% Interpolazione dei punti dell'asse Pinput corrispondenti a Ppv
Ppv_out_k=abs(interp1(Pinput_k,Pout_k,Ppv_k,'linear'));

% Percentuali di interesse in input all'inverter
targetPrel=Ppv_k / Pinput_max;

%% Grafici (3)(4)(5)
figure(3)

%Pinput-Poutput generale dell'inverter

plot(Pinput_k/1000,Pout_k/1000)
title('Caratteristica ingresso-uscita inverter Sunpower') 
xlabel 'Pinput [kw]'
ylabel 'Pout [kw]'

figure(4)

%Potenze fotovoltaico - potenze in uscita dall'inverter

% Dicembre
subplot(2,2,1)
for i=1:1:3
    plot(Ppv_k(:,4,i)/1000,Ppv_out_k(:,4,i)/1000)
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'Ppv(k) [Kw]'
ylabel 'Ppv-out(k) [Kw]'
title("Potenza del fotovoltaico in uscita dall'inverter Dicembre")

% Aprile
subplot(2,2,2)
for i=1:1:3
    plot(Ppv_k(:,1,i)/1000,Ppv_out_k(:,1,i)/1000)
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'Ppv(k) [Kw]'
ylabel 'Ppv-out(k) [Kw]'
title("Potenza del fotovoltaico in uscita dall'inverter Aprile")

% Agosto
subplot(2,2,3)
for i=1:1:3
    plot(Ppv_k(:,2,i)/1000,Ppv_out_k(:,2,i)/1000)
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'Ppv(k) [Kw]'
ylabel 'Ppv-out(k) [Kw]'
title("Potenza del fotovoltaico in uscita dall'inverter Agosto")

% Ottobre
subplot(2,2,4)
for i=1:1:3
    plot(Ppv_k(:,3,i)/1000,Ppv_out_k(:,3,i)/1000)
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'Ppv(k) [Kw]'
ylabel 'Ppv-out(k) [Kw]'
title("Potenza del fotovoltaico in uscita dall'inverter Ottobre")

figure(5)

%Potenze d'uscita dall'inverter per tutti i mesi e casi

% Aprile
subplot(2,2,1)
for i=1:1:3
    plot(hours,Ppv_out_k(:,1,i)/1000)
    hold on
end
plot(hours,Pload_k/1000,'r')
legend('soleggiato', 'nuvoloso', 'caso peggiore','Pload(k)')
title('Ppv-out(k) Aprile')
xlabel 'ore'
ylabel 'Potenze [Kw]'

% Agosto
subplot(2,2,2)
for i=1:1:3
    plot(hours,Ppv_out_k(:,2,i)/1000)
    hold on
    axis auto
end
plot(hours,Pload_k/1000,'r')
legend('soleggiato', 'nuvoloso', 'caso peggiore','Pload(k)')
title('Ppv-out(k) Agosto')
xlabel 'ore'
ylabel 'Potenze [Kw]'

% Ottobre
subplot(2,2,3)
for i=1:1:3
    plot(hours,Ppv_out_k(:,3,i)/1000)
    hold on
end
plot(hours,Pload_k/1000,'r')
legend('soleggiato', 'nuvoloso', 'caso peggiore','Pload(k)')
title('Ppv-out(k) Ottobre')
xlabel 'ore'
ylabel 'Potenze [Kw]'

% Dicembre
subplot(2,2,4)
for i=1:1:3
    plot(hours,Ppv_out_k(:,4,i)/1000)
    hold on
end
plot(hours,Pload_k/1000,'r')
legend('soleggiato', 'nuvoloso', 'caso peggiore','Pload(k)')
title('Ppv-out(k) Dicembre')
xlabel 'ore'
ylabel 'Potenze [Kw]'

%% Calcolo del residuo di potenza tra quello prodotto e assorbito
for j=1:1:4
    for k=1:1:3
        Presiduo_k(:,j,k) = Ppv_out_k(:,j,k) - Pload_k;
    end
end

%% Grafici (6)
figure(6)

%Potenze residue e di carico per tutti i mesi e casi

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

%% - Residuo energetico per batteria -
capacitaBatteria = 205.8*1e3; %205.8 Kwh in [wh]

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
    for j=1:1:4
        for k=1:1:3
            if (Presiduo_k(i,j,k) <= 0)
                Pbat_scarica_k(i,j,k)=Presiduo_k(i,j,k)/rendimentoInverterBatteria;
                Pbat_carica_k(i,j,k)=0; 
            else
                Pbat_scarica_k(i,j,k)=0;
                Pbat_carica_k(i,j,k)=Presiduo_k(i,j,k)*rendimentoInverterBatteria;
            end
        end
    end
end

Pbat_k=Pbat_scarica_k+Pbat_carica_k;

% Energia di scarica & carica della batteria
%Ebat_k(1)=capacitaBatteria;
%for i=2:1:length(Pbat_k)
%    Ebat_k(i)=Ebat_k(i-1)+(Pbat_k(i)+Pbat_k(i-1))*0.0167/2;
%end
Ebat_k=cumtrapz(hours,Pbat_k)+capacitaBatteria;

%% Grafici (7)(8)
figure(7)

% Potenza batteria per tutti i mesi e casi

%Aprile
subplot(2,2,1)
for i=1:1:3
    plot(hours,Pbat_k(:,1,i)/1000)
    hold on
end
title('Potenza di scarica/carica della batteria (Aprile)')
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Pbat(k) [KW]'

%Agosto
subplot(2,2,2)
for i=1:1:3
    plot(hours,Pbat_k(:,2,i)/1000)
    hold on
end
title('Potenza di scarica/carica della batteria (Agosto)')
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Pbat(k) [KW]'

%Ottobre
subplot(2,2,3)
for i=1:1:3
    plot(hours,Pbat_k(:,3,i)/1000)
    hold on
end
title('Potenza di scarica/carica della batteria (Ottobre)')
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Pbat(k) [KW]'

%Dicembre
subplot(2,2,4)
for i=1:1:3
    plot(hours,Pbat_k(:,4,i)/1000)
    hold on
end
title('Potenza di scarica/carica della batteria (Dicembre)')
legend('soleggiato','nuvoloso','caso peggiore');
xlabel 'hours'
ylabel 'Pbat(k) [KW]'

figure(8)

% Energia batteria per tutti i mesi e casi

%Aprile
subplot(2,2,1)
for i=1:1:3
    plot(hours,Ebat_k(:,1,i)/1000)
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore')
yline(capacitaBatteria/1000,'-r','CapacitàBatteria = 205.8 KWh');
yline(capacitaBatteria/1000*0.10,'-r','LimiteDiScarica = 20.58 KWh');
title('Energia di scarica/carica della batteria (Aprile)')
xlabel 'hours'
ylabel 'Ebat(k) [KWh]'

%Agosto
subplot(2,2,2)
for i=1:1:3
    plot(hours,Ebat_k(:,2,i)/1000)
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore')
yline(capacitaBatteria/1000,'-r','CapacitàBatteria = 205.8 KWh');
yline(capacitaBatteria/1000*0.10,'-r','LimiteDiScarica = 20.58 KWh');
title('Energia di scarica/carica della batteria (Agosto)')
xlabel 'hours'
ylabel 'Ebat(k) [KWh]'

%Ottobre
subplot(2,2,3)
for i=1:1:3
    plot(hours,Ebat_k(:,3,i)/1000)
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore')
yline(capacitaBatteria/1000,'-r','CapacitàBatteria = 205.8 KWh');
yline(capacitaBatteria/1000*0.10,'-r','LimiteDiScarica = 20.58 KWh');
title('Energia di scarica/carica della batteria (Ottobre)')
xlabel 'hours'
ylabel 'Ebat(k) [KWh]'

%Dicembre
subplot(2,2,4)
for i=1:1:3
    plot(hours,Ebat_k(:,4,i)/1000)
    hold on
end
legend('soleggiato','nuvoloso','caso peggiore')
yline(capacitaBatteria/1000,'-r','CapacitàBatteria = 205.8 KWh');
yline(capacitaBatteria/1000*0.10,'-r','LimiteDiScarica = 20.58 KWh');
title('Energia di scarica/carica della batteria (Dicembre)')
xlabel 'hours'
ylabel 'Ebat(k) [KWh]'

%% - Costo energia di scarica della batteria (Sonnen eco 9.43/15) -
costoBatteria = 10000; % €

% con dod del 90%
nCicli=10000;
capacitaCiclo = capacitaBatteria * 0.90;

%costoPerCiclo_dod=costoBatteria/nCicli_dod; %costoPerCiclo(dod)
costoPerCiclo=costoBatteria/nCicli; %costo/ciclo

%costoPerKwh_dod = costoPerCiclo_dod/capacitaBatteria;
costoPerKwh=costoPerCiclo/capacitaBatteria*1000; %costo/KWh

%Energia di scarica della batteria
Ebat_scarica_k=cumtrapz(hours,abs(Pbat_scarica_k))+capacitaBatteria;

% Costo di scarica
costoScarica = costoPerKwh*(Ebat_scarica_k/1000);

%% Grafici (9)
figure(9)

% Costo della batteria per tutti i mesi e casi

%Aprile
subplot(2,2,1)
for i=1:1:3
    plot(hours,costoScarica(:,1,i))
    hold on
end
title('Costo di scarica della batteria (Aprile)')
legend('soleggiato','nuvoloso','caso peggiore')
xlabel 'hours'
ylabel 'Euro'

%Agosto
subplot(2,2,2)
for i=1:1:3
    plot(hours,costoScarica(:,2,i))
    hold on
end
title('Costo di scarica della batteria (Agosto)')
legend('soleggiato','nuvoloso','caso peggiore')
xlabel 'hours'
ylabel 'Euro'

%Ottobre
subplot(2,2,3)
for i=1:1:3
    plot(hours,costoScarica(:,3,i))
    hold on
end
title('Costo di scarica della batteria (Ottobre)')
legend('soleggiato','nuvoloso','caso peggiore')
xlabel 'hours'
ylabel 'Euro'

%Dicembre
subplot(2,2,4)
for i=1:1:3
    plot(hours,costoScarica(:,4,i))
    hold on
end
title('Costo di scarica della batteria (Dicembre)')
legend('soleggiato','nuvoloso','caso peggiore')
xlabel 'hours'
ylabel 'Euro'

%% Grafici (10)
figure(10)

%Efficienza inverter alle potenze relative del fotovoltaico
%per tutti i mesi e casi

%Aprile
subplot(2,2,1)
plot(Prel_k,efficiency_k)
for i=1:150:length(targetPrel)
    for j=1:1:3
        xline(targetPrel(i,1,j),'-r',targetPrel(i,1,j));
    end
end
title('Inverter Rendimento AC in uscita - Rendimento DC in ingresso (Aprile)');
xlabel 'Rendimento DC [%]'
ylabel 'Rendimento AC [%]'

%Agosto
subplot(2,2,2)
plot(Prel_k,efficiency_k)
for i=1:150:length(targetPrel)
    for j=1:1:3
        xline(targetPrel(i,2,j),'-r',targetPrel(i,2,j));
    end
end
title('Inverter Rendimento AC in uscita - Rendimento DC in ingresso (Agosto)');
xlabel 'Rendimento DC [%]'
ylabel 'Rendimento AC [%]'

%Ottobre
subplot(2,2,3)
plot(Prel_k,efficiency_k)
for i=1:150:length(targetPrel)
    for j=1:1:3
        xline(targetPrel(i,3,j),'-r',targetPrel(i,3,j));
    end
end
title('Inverter Rendimento AC in uscita - Rendimento DC in ingresso (Ottobre)');
xlabel 'Rendimento DC [%]'
ylabel 'Rendimento AC [%]'

%Dicembre
subplot(2,2,4)
plot(Prel_k,efficiency_k)
for i=1:150:length(targetPrel)
    for j=1:1:3
        xline(targetPrel(i,4,j),'-r',targetPrel(i,4,j));
    end
end
title('Inverter Rendimento AC in uscita - Rendimento DC in ingresso (Dicembre)');
xlabel 'Rendimento DC [%]'
ylabel 'Rendimento AC [%]'

% Le potenze generate dal fotovoltaico (Dicembre-soleggiato) 
% ogni minuto ricadono interamente
% nella regione di minimo rendimento in ingresso. Si conclude pertanto che
% l'inverter è sovradimensionato rispetto alle potenze generate, ed è dunque
% necessario usarne un'altro con potenza nominale più bassa.
