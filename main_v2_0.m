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
time_minutes.Format = 'HH:mm:ss';

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
   datetick('x','HH:MM','keeplimits','keepticks')
   
% Load Variable
Pload_k_kw=vector(:,2); %[kW]
Pload_k=Pload_k_kw*1000; %[W]
hours=vector(:,1)/60;

%% - Photovoltaic Characteristics -
%Panel construction features
lenght_pnl = 1.559; %[m] 
width_pnl = 1.046; %[m]  
pv_area = lenght_pnl * width_pnl; %[m^2]

%Panel characteristic parameters
P_nom_pnl = 327; %[W]
V_mpp_pnl = 54.7; %[V]
I_mpp_pnl = 5.98; %[A]
V_oc_pnl = 64.9; %[V]
I_cc_pnl = 6.46; %[A]

%Photovoltaic field characteristics
N_tot_pnl = 400; %200
P_nom_field = N_tot_pnl * P_nom_pnl; %[W] - Condizioni STC(1000W/m^2 - 25°)

%% - Battery Characteristics -

% Sonnen Battery 
%Modules characteristics
n_mod = 3;
C_mod = 16500;    % [Wh]
C_tot = C_mod*n_mod; % 49.5[kWh]

%Battery lifecycle characteristics
cycles = 10000; % [n. cicli costante con dod al 90% di scarica]
cost_mod = 9000; % [€]
cost_tot = cost_mod * n_mod; % [€]
cost_cycle = cost_tot/cycles; 

% Our Battery 
%Modules characteristics
n_mod = 3;
C_mod = 16500;    % [Wh]
C_tot = C_mod*n_mod; % 49.5[kWh]

%Battery lifecycle characteristics
cycles = 10000; % [n. cicli costante con dod al 90% di scarica]
cost_mod = 9000; % [€]
cost_tot = cost_mod * n_mod; % [€]
cost_cycle = cost_tot/cycles; 

%% - Energy Characteristics -  
figure(2)
    costi_kw = costi/1000;
    plot(costi_kw)
    axis([1 24 0.03 0.065])
    xlabel('Ore del giorno')
    ylabel('Costo (€/kWh)')
    title('Profilo di costo energia')
    
%% - Analysis of sunshine conditions -  
%P(t)=(P_1000/1000)*G(t) -> P_k = (P_nom_field)/1000*G_k
time=IrradianzaAgosto.time;

%Standard cases
G_k_aug = IrradianzaAgosto.G;
P_k_aug = (P_nom_field/1000)*G_k_aug; %[W]
P_k_aug = spline(1:60:1440, P_k_aug, 1:1440); %[W]
P_k_aug_kw = P_k_aug/1000; %[kW]


G_k_apr = IrradianzaAprile.G;
P_k_apr = (P_nom_field/1000)*G_k_apr; %[W]
P_k_apr = spline(1:60:1440, P_k_apr, 1:1440); %[W]
P_k_apr_kw = P_k_apr/1000; %[kW]

G_k_dec = IrradianzaDicembre.G;
P_k_dec = (P_nom_field/1000)*G_k_dec; %[W]
P_k_dec_kw = P_k_dec/1000; %[kW]
P_k_dec = spline(1:60:1440, P_k_dec, 1:1440); %[kW]
P_k_dec_kw = P_k_dec/1000; %[kW]

G_k_oct = IrradianzaOttobre.G;
P_k_oct = (P_nom_field/1000)*G_k_oct; %[W]
P_k_oct = spline(1:60:1440, P_k_oct, 1:1440); %[W]
P_k_oct_kw = P_k_oct/1000; %[kW]

% Dirty cases

%Cloudy cases -> -40% of sunshine than normal condition
G_k_aug_cloudy = G_k_aug-G_k_aug*40/100;
P_k_aug_cloudy = (P_nom_field/1000)*G_k_aug_cloudy; %[W]
P_k_aug_cloudy = spline(1:60:1440, P_k_aug_cloudy, 1:1440); %[W]
P_k_aug_cloudy_kw = P_k_aug_cloudy/1000; %[kW]

G_k_apr_cloudy = G_k_apr-G_k_apr*40/100;
P_k_apr_cloudy = (P_nom_field/1000)*G_k_apr_cloudy; %[W]
P_k_apr_cloudy = spline(1:60:1440, P_k_apr_cloudy, 1:1440); %[W]
P_k_apr_cloudy_kw = P_k_apr_cloudy/1000; %[kW]

G_k_dec_cloudy = G_k_dec-G_k_dec*40/100;
P_k_dec_cloudy = (P_nom_field/1000)*G_k_dec_cloudy; %[W]
P_k_dec_cloudy = spline(1:60:1440, P_k_dec_cloudy, 1:1440); %[W]
P_k_dec_cloudy_kw = P_k_dec_cloudy/1000; %[kW]

G_k_oct_cloudy = G_k_oct-G_k_oct*40/100;
P_k_oct_cloudy = (P_nom_field/1000)*G_k_oct_cloudy; %[W]
P_k_oct_cloudy = spline(1:60:1440, P_k_oct_cloudy, 1:1440); %[W]
P_k_oct_cloudy_kw = P_k_oct_cloudy/1000; %[kW]

%Worst cases -> -80% of sunshine than normal condition
G_k_aug_worst = G_k_aug-G_k_aug*80/100;
P_k_aug_worst = (P_nom_field/1000)*G_k_aug_worst; %[W]
P_k_aug_worst = spline(1:60:1440, P_k_aug_worst, 1:1440); %[W]
P_k_aug_worst_kw = P_k_aug_worst/1000; %[kW]

G_k_apr_worst = G_k_apr-G_k_apr*80/100;
P_k_apr_worst = (P_nom_field/1000)*G_k_apr_worst; %[W]
P_k_apr_worst = spline(1:60:1440, P_k_apr_worst, 1:1440); %[W]
P_k_apr_worst_kw = P_k_apr_worst/1000; %[kW]

G_k_dec_worst = G_k_dec-G_k_dec*80/100;
P_k_dec_worst = (P_nom_field/1000)*G_k_dec_worst; %[W]
P_k_dec_worst = spline(1:60:1440, P_k_dec_worst, 1:1440); %[W]
P_k_dec_worst_kw = P_k_dec_worst/1000; %[kW]

G_k_oct_worst = G_k_dec-G_k_dec*80/100;
P_k_oct_worst = (P_nom_field/1000)*G_k_oct_worst; %[W]
P_k_oct_worst = spline(1:60:1440, P_k_oct_worst, 1:1440); %[W]
P_k_oct_worst_kw = P_k_oct_worst/1000; %[kW]

%Analysis plotting  
figure(3)
    subplot(2,2,1)
        plot(time_minutes, P_k_aug_kw, 'g')
        hold on
        plot(time_minutes, P_k_aug_cloudy_kw, 'b')
        plot(time_minutes, P_k_aug_worst_kw, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Potenza (kW)')
        ylim([0 50])
        title('Profilo potenza fotovoltaico - Agosto')
        datetick('x','HH:MM','keeplimits','keepticks')
    
    subplot(2,2,2)
        plot(time_minutes, P_k_apr_kw, 'g')
        hold on
        plot(time_minutes, P_k_apr_cloudy_kw, 'b')
        plot(time_minutes, P_k_apr_worst_kw, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Potenza (kW)')
        ylim([0 50])
        title('Profilo potenza fotovoltaico - Aprile')
        datetick('x','HH:MM','keeplimits','keepticks')
    
    subplot(2,2,3)
        plot(time_minutes, P_k_dec_kw, 'g')
        hold on
        plot(time_minutes, P_k_dec_cloudy_kw, 'b')
        plot(time_minutes, P_k_dec_worst_kw, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Potenza (kW)')
        ylim([0 50])
        title('Profilo potenza fotovoltaico - Dicembre')
        datetick('x','HH:MM','keeplimits','keepticks')
    
    subplot(2,2,4)
        plot(time_minutes, P_k_oct_kw, 'g')
        hold on
        plot(time_minutes, P_k_oct_cloudy_kw, 'b')
        plot(time_minutes, P_k_oct_worst_kw, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Potenza (kW)')
        ylim([0 50])
        title('Profilo potenza fotovoltaico - Ottobre')
        datetick('x','HH:MM','keeplimits','keepticks')
    legend ('Max Soleggiamento', 'Nuvoloso', 'Min Soleggiamento')

%% - Conversion "datatime - integer" (utils) - 
time=datevec(time); %from datetime to matrix of date and time
time=time(1:24,4); %extract hours as integers

%% - Interpolation phase -
G_k_aug = IrradianzaAgosto.G; %[W/m^2]
G_k_aug=spline(1:60:1440,G_k_aug,1:1440);

G_k_apr = IrradianzaAprile.G; %[W/m^2]
G_k_apr=spline(1:60:1440,G_k_apr,1:1440);

G_k_dec=IrradianzaDicembre.G; %[W/m^2]
G_k_dec=spline(1:60:1440,G_k_dec,1:1440);

G_k_oct = IrradianzaOttobre.G; %[W/m^2]
G_k_oct=spline(1:60:1440,G_k_oct,1:1440);

%% - Energy evaluation - 

Eload_k=cumtrapz(0.0167,Pload_k); %Energy consumed at each step of 0.0167 hours
Eload_k_kwh=Eload_k/1000; %[kWh]

%Standard cases
Epv_k_aug=cumtrapz(0.0167,P_k_aug); %Energy produced at each step
Epv_k_aug_kwh=Epv_k_aug/1000; %[kWh]
Epv_k_apr=cumtrapz(0.0167,P_k_apr); %Energy produced at each step
Epv_k_apr_kwh=Epv_k_apr/1000; %[kWh]
Epv_k_dec=cumtrapz(0.0167,P_k_dec); %Energy produced at each step
Epv_k_dec_kwh=Epv_k_dec/1000; %[kWh]
Epv_k_oct=cumtrapz(0.0167,P_k_oct); %Energy produced at each step
Epv_k_oct_kwh=Epv_k_oct/1000; %[kWh]

% Dirty cases

%Cloudy cases -> -40% than normal condition
Epv_k_aug_cloudy=cumtrapz(0.0167,P_k_aug_cloudy); %Energy produced at each step
Epv_k_aug_cloudy_kwh=Epv_k_aug_cloudy/1000; %[kWh]
Epv_k_apr_cloudy=cumtrapz(0.0167,P_k_apr_cloudy); %Energy produced at each step
Epv_k_apr_cloudy_kwh=Epv_k_apr_cloudy/1000; %[kWh]
Epv_k_dec_cloudy=cumtrapz(0.0167,P_k_dec_cloudy); %Energy produced at each step
Epv_k_dec_cloudy_kwh=Epv_k_dec_cloudy/1000; %[kWh]
Epv_k_oct_cloudy=cumtrapz(0.0167,P_k_oct_cloudy); %Energy produced at each step
Epv_k_oct_cloudy_kwh=Epv_k_oct_cloudy/1000; %[kWh]

%Worst cases -> -80% than normal condition
Epv_k_aug_worst=cumtrapz(0.0167,P_k_aug_worst); %Energy produced at each step
Epv_k_aug_worst_kwh=Epv_k_aug_worst/1000; %[kWh]
Epv_k_apr_worst=cumtrapz(0.0167,P_k_apr_worst); %Energy produced at each step
Epv_k_apr_worst_kwh=Epv_k_apr_worst/1000; %[kWh]
Epv_k_dec_worst=cumtrapz(0.0167,P_k_dec_worst); %Energy produced at each step
Epv_k_dec_worst_kwh=Epv_k_dec_worst/1000; %[kWh]
Epv_k_oct_worst=cumtrapz(0.0167,P_k_oct_worst); %Energy produced at each step
Epv_k_oct_worst_kwh=Epv_k_oct_worst/1000; %[kWh]


%% - Energy Excess -

%Standard cases
Edelta_k_aug_kwh=Epv_k_aug_kwh'-Eload_k_kwh; % Kwh
Edelta_k_apr_kwh=Epv_k_apr_kwh'-Eload_k_kwh; % Kwh
Edelta_k_dec_kwh=Epv_k_dec_kwh'-Eload_k_kwh; % Kwh
Edelta_k_oct_kwh=Epv_k_oct_kwh'-Eload_k_kwh; % Kwh

%Dirty cases

%Cloudy cases -> -40% than normal condition
Edelta_k_aug_cloudy_kwh=Epv_k_aug_cloudy_kwh'-Eload_k_kwh; % Kwh
Edelta_k_apr_cloudy_kwh=Epv_k_apr_cloudy_kwh'-Eload_k_kwh; % Kwh
Edelta_k_dec_cloudy_kwh=Epv_k_dec_cloudy_kwh'-Eload_k_kwh; % Kwh
Edelta_k_oct_cloudy_kwh=Epv_k_oct_cloudy_kwh'-Eload_k_kwh; % Kwh

%Worst cases -> -80% than normal condition
Edelta_k_aug_worst_kwh=Epv_k_aug_worst_kwh'-Eload_k_kwh; % Kwh
Edelta_k_apr_worst_kwh=Epv_k_apr_worst_kwh'-Eload_k_kwh; % Kwh
Edelta_k_dec_worst_kwh=Epv_k_dec_worst_kwh'-Eload_k_kwh; % Kwh
Edelta_k_oct_worst_kwh=Epv_k_oct_worst_kwh'-Eload_k_kwh; % Kwh

%% - Energy Plot -  

figure(4)
    subplot(2,2,1)
        plot(time_minutes, Epv_k_aug_kwh, 'g')
        hold on
        plot(time_minutes, Epv_k_aug_cloudy_kwh, 'b')
        plot(time_minutes, Epv_k_aug_worst_kwh, 'r')
        plot(time_minutes, Eload_k_kwh, 'y')
        hold off
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        ylim([0 500])
        title('Profilo energia fotovoltaico - Agosto')
        datetick('x','HH:MM','keeplimits','keepticks')
    
    subplot(2,2,2)
        plot(time_minutes, Epv_k_apr_kwh, 'g')
        hold on
        plot(time_minutes, Epv_k_apr_cloudy_kwh, 'b')
        plot(time_minutes, Epv_k_apr_worst_kwh, 'r')
        plot(time_minutes, Eload_k_kwh, 'y')
        hold off
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        ylim([0 400])
        title('Profilo energia fotovoltaico - Aprile')
        datetick('x','HH:MM','keeplimits','keepticks')
    
    subplot(2,2,3)
        plot(time_minutes,Epv_k_dec_kwh, 'g')
        hold on
        plot(time_minutes, Epv_k_dec_cloudy_kwh, 'b')
        plot(time_minutes, Epv_k_dec_worst_kwh, 'r')
        plot(time_minutes, Eload_k_kwh, 'y')
        hold off
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        ylim([0 400])
        title('Profilo energia fotovoltaico - Dicembre')
        datetick('x','HH:MM','keeplimits','keepticks')
    
    subplot(2,2,4)
        plot(time_minutes, Epv_k_oct_kwh, 'g')
        hold on
        plot(time_minutes, Epv_k_oct_cloudy_kwh, 'b')
        plot(time_minutes, Epv_k_oct_worst_kwh, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        ylim([0 400])
        title('Profilo energia fotovoltaico - Ottobre')
        datetick('x','HH:MM','keeplimits','keepticks')
        
    legend ('Max Soleggiamento', 'Nuvoloso', 'Min Soleggiamento', 'Energia richiesta')

%% - Energy excess plot - 

figure(5)
    subplot(2,2,1)
        plot(time_minutes, Edelta_k_aug_kwh, 'g')
        hold on
        plot(time_minutes, Edelta_k_aug_cloudy_kwh, 'b')
        plot(time_minutes, Edelta_k_aug_worst_kwh, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        title('Delta energia fotovoltaico - Agosto')
        datetick('x','HH:MM','keeplimits','keepticks')
    
    subplot(2,2,2)
        plot(time_minutes, Edelta_k_apr_kwh, 'g')
        hold on
        plot(time_minutes, Edelta_k_apr_cloudy_kwh, 'b')
        plot(time_minutes, Edelta_k_apr_worst_kwh, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        title('Delta energia fotovoltaico - Aprile')
        datetick('x','HH:MM','keeplimits','keepticks')
    
    subplot(2,2,3)
        plot(time_minutes, Edelta_k_dec_kwh, 'g')
        hold on
        plot(time_minutes, Edelta_k_dec_cloudy_kwh, 'b')
        plot(time_minutes, Edelta_k_dec_worst_kwh, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        title('Delta energia fotovoltaico - Dicembre')
        datetick('x','HH:MM','keeplimits','keepticks')
    
    subplot(2,2,4)
        plot(time_minutes, Edelta_k_oct_kwh, 'g')
        hold on
        plot(time_minutes, Edelta_k_oct_cloudy_kwh, 'b')
        plot(time_minutes, Edelta_k_oct_worst_kwh, 'r')
        hold off
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        title('Delta energia fotovoltaico - Ottobre')
        datetick('x','HH:MM','keeplimits','keepticks')
        
    legend ('Max Soleggiamento', 'Nuvoloso', 'Min Soleggiamento')
    
 %% - Battery health -
load 'Battery_health.mat'
figure(6)
plot(BatteryHealth(:,1),BatteryHealth(:,2))
 
%% - Battery Energy  -

 %% - Inverter Efficiency -