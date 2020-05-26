clear all
close all
clc

%% - Loading Data -
load energy_hourly_cost.mat
load daily_minute.mat
load Irradianza_Agosto.mat
load Irradianza_Aprile.mat
load Irradianza_Dicembre.mat
load Irradianza_Ottobre.mat

start_time = datetime( '00:00', 'InputFormat', 'HH:mm' );
start_time.Format = 'HH:mm:ss';
end_time = datetime( '23:59', 'InputFormat', 'HH:mm' );
end_time.Format = 'HH:mm:ss';

time_minutes=start_time:minutes(1):end_time;

%% - Data center Characteristics -
%Plant Characteristics
lenght_plt = 12; %[m]
width_plt = 54; %[m]
plant_area = lenght_plt * width_plt; %[m^2]

%Load Profile
figure(1)
   plot(time_minutes,vector(:,2))
   xlabel('Ore del giorno')
   ylabel('Potenza (kW)')
   title('Profilo di potenza del carico')

%% Load Variable
Pload_k_kw=vector(:,2); %Kw
Pload_k=Pload_k_kw*1000; %w
hours=vector(:,1)/60;

%% - Photovoltaic Characteristics -
%Panel construction features
lenght_pnl = 1.559; %[m] %DA RIDEFINIRE
width_pnl = 1.046; %[m]  %DA RIDEFINIRE
pv_area = lenght_pnl * width_pnl; %[m^2]

%Panel characteristic parameters
P_nom_pnl = 327; %[W]
V_mpp_pnl = 54.7; %[V]
I_mpp_pnl = 5.98; %[A]
V_oc_pnl = 64.9; %[V]
I_cc_pnl = 6.46; %[A]

%Photovoltaic field characteristics
N_tot_pnl = 150 %Come vogliamo mettere questo numero ?
P_nom_field = N_tot_pnl * P_nom_pnl; %[W] - Condizioni STC(1000W/m^2 - 25°)

%% - Battery Characteristics -
%%SCRIVETE QUI I DATI E LE ANALISI RELATIVI ALLA BATTERIA
n_mod = 3;
C_mod = 16500    % Wh
C_tot = C_mod*n_mod; % 49.5kWh

cicli = 10000;
Costo_mod = 9000; % euro
Costo_tot = Costo_mod * n_mod; % euro
Costo_ciclo = Costo_tot/cicli; 

%% - Energy Characteristics -  
figure(2)
    plot(costi)
    axis([1 24 0 65])
    xlabel('Ore del giorno')
    ylabel('Costo (€/MWh)')
    title('Profilo di costo energia')
%% - Analysis of sunshine conditions -  
%P(t)=(P_1000/1000)*G(t) -> P_k = (P_nom_field)/1000*G_k
time=IrradianzaAgosto.time;

%Standard cases
G_k_aug = IrradianzaAgosto.G;
P_k_aug = (P_nom_field/1000)*G_k_aug;
P_k_aug_kw = P_k_aug/1000; %Kw

G_k_apr = IrradianzaAprile.G;
P_k_apr = (P_nom_field/1000)*G_k_apr;
P_k_apr_kw = P_k_apr/1000; %Kw

G_k_dec = IrradianzaDicembre.G;
P_k_dec = (P_nom_field/1000)*G_k_dec;
P_k_dec_kw = P_k_dec/1000; %Kw

G_k_oct = IrradianzaOttobre.G;
P_k_oct = (P_nom_field/1000)*G_k_oct;
P_k_oct_kw = P_k_oct/1000; %Kw



%% Dirty cases

%Cloudy cases -> -40% than normal condition
P_k_aug_cloudy = P_k_aug-P_k_aug*40/100;
P_k_aug_cloudy_kw = P_k_aug_kw-P_k_aug_kw*40/100; %kw

P_k_apr_cloudy = P_k_apr-P_k_apr*40/100;
P_k_apr_cloudy_kw = P_k_apr_kw-P_k_apr_kw*40/100; %kw

P_k_dec_cloudy = P_k_dec-P_k_dec*40/100;
P_k_dec_cloudy_kw = P_k_dec_kw-P_k_dec_kw*40/100; %kw

P_k_oct_cloudy = P_k_oct-P_k_oct*40/100;
P_k_oct_cloudy_kw = P_k_oct_kw-P_k_oct_kw*40/100; %kw

%Worst cases -> -80% than normal condition
P_k_aug_worst = P_k_aug-P_k_aug*80/100;
P_k_aug_worst_kw = P_k_aug_kw-P_k_aug_kw*40/100; %kw

P_k_apr_worst = P_k_apr-P_k_apr*80/100;
P_k_apr_worst_kw = P_k_apr_kw-P_k_apr_kw*40/100; %kw

P_k_dec_worst = P_k_dec-P_k_dec*80/100;
P_k_dec_worst_kw = P_k_dec_kw-P_k_dec_kw*40/100; %kw

P_k_oct_worst = P_k_oct-P_k_oct*80/100;
P_k_oct_worst_kw = P_k_oct_kw-P_k_oct_kw*40/100; %kw

%200 giorni bel tempo 100 giorni tempo misto 65 giorni tempo cattivo 
 
figure(3)
    subplot(2,2,1)
        plot(time, P_k_aug, 'g')
        hold on
        plot(time, P_k_aug_cloudy, 'b')
        plot(time, P_k_aug_worst, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Potenza (W)')
        title('Profilo potenza fotovoltaico - Agosto')
    
    subplot(2,2,2)
        plot( time, P_k_apr, 'g')
        hold on
        plot(time, P_k_apr_cloudy, 'b')
        plot(time, P_k_apr_worst, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Potenza (W)')
        title('Profilo potenza fotovoltaico - Aprile')
    
    subplot(2,2,3)
        plot(time, P_k_dec, 'g')
        hold on
        plot(time, P_k_dec_cloudy, 'b')
        plot(time, P_k_dec_worst, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Potenza (W)')
        title('Profilo potenza fotovoltaico - Dicembre')
    
    subplot(2,2,4)
        plot(time, P_k_oct, 'g')
        hold on
        plot(time, P_k_oct_cloudy, 'b')
        plot(time, P_k_oct_worst, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Potenza (W)')
        title('Profilo potenza fotovoltaico - Ottobre')        
    legend ('Max Soleggiamento', 'Nuvoloso', 'Min Soleggiamento')


%{ 
%% from datatime to integer 
time=datevec(time); %from datetime to matrix of date and time
time=time(:,4); %extract hours as integers
time(25)=24; % modifica artigianale di Peppino 

%% Interpolazione
G_k_aug = IrradianzaAgosto.G; %w/m^2
G_k_aug(25)=0;
G_k_aug=interp1(time,G_k_aug,hours,'cubic');

G_k_apr = IrradianzaAprile.G; %w/m^2
G_k_apr(25)=0;
G_k_apr=interp1(time,G_k_apr,hours,'cubic');

G_k_dec=IrradianzaDicembre.G; %w/m^2
G_k_dec(25)=0;
G_k_dec=interp1(time,G_k_dec,hours,'cubic');

G_k_oct = IrradianzaOttobre.G; %w/m^2
G_k_oct(25)=0;
G_k_oct=interp1(time,G_k_oct,hours,'cubic');
%}
%% Plot Energy produced (rispetto hours)

Eload_k=cumtrapz(0.0167,Pload_k); %Energy consumed at each step of 0.0167 hours
Eload_k_kwh=Eload_k/1000; %Kwh

%Standard cases
Epv_k_aug=cumtrapz(0.0167,P_k_aug); %Energy produced at each step
Epv_k_aug_kwh=Epv_k_aug/1000; %Kwh
Epv_k_apr=cumtrapz(0.0167,P_k_apr); %Energy produced at each step
Epv_k_apr_kwh=Epv_k_apr/1000; %Kwh
Epv_k_dec=cumtrapz(0.0167,P_k_dec); %Energy produced at each step
Epv_k_dec_kwh=Epv_k_dec/1000; %Kwh
Epv_k_oct=cumtrapz(0.0167,P_k_oct); %Energy produced at each step
Epv_k_oct_kwh=Epv_k_oct/1000; %Kwh

%% Dirty cases

%Cloudy cases -> -40% than normal condition
Epv_k_aug_cloudy=cumtrapz(0.0167,P_k_aug_cloudy); %Energy produced at each step
Epv_k_aug_cloudy_kwh=Epv_k_aug_cloudy/1000; %Kwh
Epv_k_apr_cloudy=cumtrapz(0.0167,P_k_apr_cloudy); %Energy produced at each step
Epv_k_apr_cloudy_kwh=Epv_k_apr_cloudy/1000; %Kwh
Epv_k_dec_cloudy=cumtrapz(0.0167,P_k_dec_cloudy); %Energy produced at each step
Epv_k_dec_cloudy_kwh=Epv_k_dec_cloudy/1000; %Kwh
Epv_k_oct_cloudy=cumtrapz(0.0167,P_k_oct_cloudy); %Energy produced at each step
Epv_k_oct_cloudy_kwh=Epv_k_oct_cloudy/1000; %Kwh

%Worst cases -> -80% than normal condition
Epv_k_aug_worst=cumtrapz(0.0167,P_k_aug_worst); %Energy produced at each step
Epv_k_aug_worst_kwh=Epv_k_aug_worst/1000; %Kwh
Epv_k_apr_worst=cumtrapz(0.0167,P_k_apr_worst); %Energy produced at each step
Epv_k_apr_worst_kwh=Epv_k_apr_worst/1000; %Kwh
Epv_k_dec_worst=cumtrapz(0.0167,P_k_dec_worst); %Energy produced at each step
Epv_k_dec_worst_kwh=Epv_k_dec_worst/1000; %Kwh
Epv_k_oct_worst=cumtrapz(0.0167,P_k_oct_worst); %Energy produced at each step
Epv_k_oct_worst_kwh=Epv_k_oct_worst/1000; %Kwh

%{
%% Energy Excess 

%Standard cases
Edelta_k_aug_kwh=Epv_k_aug_kwh-Eload_k_kwh; % Kwh
Edelta_k_apr_kwh=Epv_k_apr_kwh-Eload_k_kwh; % Kwh
Edelta_k_dec_kwh=Epv_k_dec_kwh-Eload_k_kwh; % Kwh
Edelta_k_oct_kwh=Epv_k_oct_kwh-Eload_k_kwh; % Kwh

%% Dirty cases

%Cloudy cases -> -40% than normal condition
Edelta_k_aug_cloudy_kwh=Epv_k_aug_cloudy_kwh-Eload_k_kwh; % Kwh
Edelta_k_apr_cloudy_kwh=Epv_k_apr_cloudy_kwh-Eload_k_kwh; % Kwh
Edelta_k_dec_cloudy_kwh=Epv_k_dec_cloudy_kwh-Eload_k_kwh; % Kwh
Edelta_k_oct_cloudy_kwh=Epv_k_oct_cloudy_kwh-Eload_k_kwh; % Kwh

%Worst cases -> -80% than normal condition
Edelta_k_aug_worst_kwh=Epv_k_aug_worst_kwh-Eload_k_kwh; % Kwh
Edelta_k_apr_worst_kwh=Epv_k_apr_worst_kwh-Eload_k_kwh; % Kwh
Edelta_k_dec_worst_kwh=Epv_k_dec_worst_kwh-Eload_k_kwh; % Kwh
Edelta_k_oct_worst_kwh=Epv_k_oct_worst_kwh-Eload_k_kwh; % Kwh

%}
%% Plot energia 

figure(4)
    subplot(2,2,1)
        plot(time, Epv_k_aug_kwh, 'g')
        hold on
        plot(time, Epv_k_aug_cloudy_kwh, 'b')
        plot(time, Epv_k_aug_worst_kwh, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        title('Profilo energia fotovoltaico - Agosto')
    
    subplot(2,2,2)
        plot(time, Epv_k_apr_kwh, 'g')
        hold on
        plot(time, Epv_k_apr_cloudy_kwh, 'b')
        plot(time, Epv_k_apr_worst_kwh, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        title('Profilo energia fotovoltaico - Aprile')
    
    subplot(2,2,3)
        plot(time, Epv_k_dec_kwh, 'g')
        hold on
        plot(time, Epv_k_dec_cloudy_kwh, 'b')
        plot(time, Epv_k_dec_worst_kwh, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        title('Profilo energia fotovoltaico - Dicembre')
    
    subplot(2,2,4)
        plot(time, Epv_k_oct_kwh, 'g')
        hold on
        plot(time, Epv_k_oct_cloudy_kwh, 'b')
        plot(time, Epv_k_oct_worst_kwh, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        title('Profilo energia fotovoltaico - Ottobre')
        
    legend ('Max Soleggiamento', 'Nuvoloso', 'Min Soleggiamento')


    
