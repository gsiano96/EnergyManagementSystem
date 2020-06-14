clear all
close all
clc

load ../Matfile/energy_hourly_cost.mat
load ../Matfile/daily_minute.mat
load ./IrradianceData/yearIrradiance.mat

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
N_tot_pnl = 400
P_nom_field = N_tot_pnl * P_nom_pnl; %[W] - Condizioni STC(1000W/m^2 - 25°)

%% - Battery Characteristics -
%Modules characteristics - %"sonnen eco 9.43 - LiFePo4"
n_mod = 14;
C_mod = 15000;    % [Wh]
C_tot = C_mod*n_mod; % [Wh]
C_tot_kw = C_tot/1000; % [kWh]

%Battery lifecycle characteristics
cycles = 10000;
cost_mod = 3500; % [€]
cost_tot = cost_mod * n_mod; % [€]
cost_cycle = cost_tot/cycles;

%% - Generate Casual Year - 
totalmatrix=monthsCloudyOcc;
pcloud=[];
monthdays=[31,28,31,30,31,30,31,31,30,31,30,31];    

%Return the probability for the data type (1,2,3,4) for every month,
%calculated by the 10 year experiments
for i=1:12
    pcloud(i,:)=cloudyProb(totalmatrix(find(totalmatrix(:,i)),i));
end
year=zeros(31,12);

%Generate a casual year with different type of days in a mounth
for i=1:12
    year(:,i)=obtainMonthConditions(pcloud(i,:),totalmatrix(:,i),monthdays(i));
end

%Return the irradiance for each day of the year calculated previosly
for i=0:11
    yirr(:,1+(31*i):31*(i+1))=dailyIrradiance(year(:,i+1),yearIrradiance(:,i+1));
end
j=1;
for i=1:length(yirr)
    if(sum(yirr(:,i))~=0)
        irradianceYearSimulation(:,j)=yirr(:,i);  
        j=j+1;
    end
end
%% - Analysis of sunshine conditions -  
%Istant Power
P_day = (P_nom_field/1000)*irradianceYearSimulation(:,240) %[W]
P_k_day = spline(1:60:1440, P_day, 1:1440); %[W]
P_k_day_kw = P_k_day/1000; %[kW]

figure(2)
        plot(time_minutes, P_k_day_kw)
        xlabel('Ore del giorno')
        ylabel('Potenza (kW)')
        title('Profilo potenza fotovoltaico')
        datetick('x','HH:MM','keeplimits','keepticks')

%Daily produced energy
G_i=irradianceYearSimulation(:,240);
G_k=spline(1:60:1440,G_i,1:1440);   
Epv_k=cumtrapz(0.0167,P_k_day); %Energy produced at each step
Epv_k_kwh=Epv_k/1000; %[kWh]
figure(3)
        plot(time_minutes, Epv_k_kwh)
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        title('Profilo energia fotovoltaico')
        datetick('x','HH:MM','keeplimits','keepticks')

%Daily consumed energy
Eload_k=cumtrapz(0.0167,Pload_k); %Energy consumed at each step of 0.0167 hours
Eload_k_kwh=Eload_k/1000; %[kWh]

%Difference between produced energy & consumed energy
Edelta_k_kwh=Epv_k_kwh'-Eload_k_kwh; % [kWh]

figure(3)
        plot(time_minutes, Edelta_k_kwh)
        hold on
        plot(time_minutes, Eload_k_kwh)
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        title('Differenza energia prodotta-consumata')
        datetick('x','HH:MM','keeplimits','keepticks')

% %% - Year simulation grezza - 
Eload_fix=cumtrapz(0.0167,Pload_k); %Energy consumed at each step of 0.0167 hours
Eload_fix_kwh=Eload_fix/1000; %[kWh]

[wastedKwDay,moneySpentDay,moneyEarnedDay] = strategy_no_cost(P_nom_field,irradianceYearSimulation,Eload_k_kwh, costi, C_tot_kw);

[wastedKwDay_no_cost,moneySpentDay_no_cost,moneyEarnedDay_no_cost, recharge_cycle_no_cost] = strategy_with_DoD(P_nom_field,irradianceYearSimulation,Eload_k_kwh, costi, C_tot_kw, cost_cycle, Eload_fix_kwh);

moneySpentYear_no_panel = strategy_no_panel(Eload_k_kwh, costi);

[wastedKwDay_night_buy,moneySpentDay_night_buy,moneyEarnedDay_night_buy,recharge_cycle_night_buy] = strategy_with_night_buy(P_nom_field,irradianceYearSimulation,Eload_k_kwh, costi, C_tot_kw,cost_cycle, Eload_fix_kwh,0.5);
