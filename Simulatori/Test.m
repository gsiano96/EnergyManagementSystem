clear all
close all
clc

load ../Matfile/energy_hourly_cost.mat
load ../Matfile/daily_minute.mat

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
Panel_cost = 300; %[€]

%Photovoltaic field characteristics
N_tot_pnl = 400
P_nom_field = N_tot_pnl * P_nom_pnl; %[W] - Condizioni STC(1000W/m^2 - 25°)
Cost_PV = N_tot_pnl * Panel_cost; %[€]

%% - Battery Characteristics -


%Modules characteristics - %"sonnen eco 9.43 - LiFePo4"
%Prezzi Iva Esclusa (Sterlina-Euro 1:1)
%Modulo base (2.5) con inverter -> €3000
%Moduli aggiuntivi (2.5) -> €1000/pz. (5pz. -> €5000) 
n_mod = 14;
C_mod = 15000; % [Wh]
C_tot = C_mod*n_mod; % [Wh]
C_tot_kw = C_tot/1000; % [kWh]

%Battery lifecycle characteristics
cycles = 10000;
cost_mod = 8000*0.5; % [€]
cost_tot = cost_mod * n_mod; % [€]
cost_cycle = cost_tot/cycles;

%{
%% Batteria Pezzotta is better (?)
% citando alessio qua n'z pav!
n_mod = 28; %(per modulo si intende un pacco batterie da 480 W/h nominali)
C_mod=210/28; %6 kwh
C_tot_kw=C_mod*n_mod; %210Kwh

cycles = 4000;
cost_mod=1600;
cost_tot=cost_mod*n_mod;
cost_cycle = cost_tot/cycles;
%}
%{
% Ma proprio veramente cvhe più pezzotta non si può
%https://www.alibaba.com/product-detail/Extra-long-5000-Cycle-Times-Rechargeable_1349859896.html?spm=a2700.7735675.normalList.1.4c4f4c67hWiKk4
n_mod = 175;
C_mod=210/n_mod;
C_tot_kw=C_mod*n_mod;

cycles = 4000; %(DoD = 0.8)
cost_mod=221.85*0.5;
cost_tot=cost_mod*n_mod;
cost_cycle = cost_tot/cycles;
%}

%Setting the DoD for the battery
DoD = 0.9;
%% - Inverter Characteristic - 
inv_Threshold = 130;
%% - Generate Casual Year - 
[irradianceYearSimulation,year] = generateYearIrradiance;

%% - Analysis of sunshine conditions -  
%{
%Istant Power
P_day = (P_nom_field/1000)*irradianceYearSimulation(:,240); %[W]
P_k_day = spline(1:60:1440, P_day, 1:1440); %[W]
P_k_day_kw = P_k_day/1000; %[kW]

figure(20)
        plot(time_minutes, P_k_day_kw)
        xlabel('Ore del giorno')
        ylabel('Potenza (kW)')
        title('Profilo potenza fotovoltaico')
        datetick('x','HH:MM','keeplimits','keepticks')
%}
%{
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
%}

%Daily consumed energy
Eload_k=cumtrapz(0.0167,Pload_k); %Energy consumed at each step of 0.0167 hours
Eload_k_kwh=Eload_k/1000; %[kWh]

%{
%Difference between produced energy & consumed energy
Edelta_k_kwh=Epv_k_kwh'-Eload_k_kwh; % [kWh]

figure(4)
        plot(time_minutes, Edelta_k_kwh)
        hold on
        plot(time_minutes, Eload_k_kwh)
        xlabel('Ore del giorno')
        ylabel('Energia (KWh)')
        title('Differenza energia prodotta-consumata')
        datetick('x','HH:MM','keeplimits','keepticks')
%}

%% - Strategies Simulation - 
Eload_fix=cumtrapz(0.0167,Pload_k); %Energy consumed at each step of 0.0167 hours
Eload_fix_kwh=Eload_fix/1000; %[kWh]

%Strategy "No Panel"
moneySpentYear_no_panel = strategy_no_panel(Eload_k_kwh, costi, irradianceYearSimulation);

%Strategy "Only Panel"
[wastedKwDay_only_panel, moneySpentDay_only_panel,moneyEarnedDay_only_panel] = strategy_only_panel(P_nom_field,irradianceYearSimulation,Eload_k_kwh, costi, inv_Threshold);

%Strategy "No Cost"
[wastedKwDay_no_cost,moneySpentDay_no_cost,moneyEarnedDay_no_cost, recharge_no_cost,battery_daily_no_cost] = strategy_no_cost(P_nom_field,irradianceYearSimulation,Eload_k_kwh, costi, C_tot_kw,inv_Threshold);

%Strategy "DoD"
[wastedKwDay_DoD,moneySpentDay_DoD,moneyEarnedDay_DoD, recharge_cycle_DoD,battery_daily_DoD] = strategy_with_DoD(P_nom_field,irradianceYearSimulation,Eload_k_kwh, costi, C_tot_kw, cost_cycle, Eload_fix_kwh,DoD,inv_Threshold);

%Strategy "Night Buy"
[wastedKwDay_night_buy,moneySpentDay_night_buy,moneyEarnedDay_night_buy,recharge_cycle_night_buy,battery_daily_night_buy] = strategy_with_night_buy(P_nom_field,irradianceYearSimulation,Eload_k_kwh, costi, C_tot_kw,cost_cycle, Eload_fix_kwh,0.5,DoD,inv_Threshold);

%% - Plot "No Panel" Strategy -
figure(3)
    stem(moneySpentYear_no_panel)
    title("Money spent Daily - No Panel");
    xlim([1,365])
    xlabel("Days")
    ylabel("€")
    
%% - Plot "Only Panel" Strategy -
figure(4)
    subplot(221)
        plot(wastedKwDay_only_panel)
        title("Daily Wasted kWh");
        xlim([1,365])
        xlabel("Days")
        ylabel("kWh")
    subplot(222)
        plot(moneySpentDay_only_panel)
        title("Money spent Daily");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    subplot(223)
        plot(moneyEarnedDay_only_panel)
        title("Money earned Daily");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    subplot(224)
        stem(moneyEarnedDay_only_panel-moneySpentDay_only_panel)
        title("Difference 'earned-spent' Daily (€)");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    sgtitle("Only Panel Strategy");

%% - Plot "No Cost" Strategy -
figure(5)
    subplot(221)
        plot(wastedKwDay_no_cost)
        title("Daily Wasted kWh");
        xlim([1,365])
        xlabel("Days")
        ylabel("kWh")
    subplot(222)
        plot(moneySpentDay_no_cost)
        title("Money spent Daily");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    subplot(223)
        plot(moneyEarnedDay_no_cost)
        title("Money earned Daily");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    subplot(224)
        stem(moneyEarnedDay_no_cost-moneySpentDay_no_cost)
        title("Difference 'earned-spent' Daily (€)");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    sgtitle("No Cost Strategy");

figure(6)
    subplot(311)
        plot(battery_daily_no_cost(1:60*24:end))
        title("Battery Percentage Daily (00:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    subplot(312)
        plot(battery_daily_no_cost(12*60:60*24:end))
        title("Battery Percentage Daily (12:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    subplot(313)
        plot(battery_daily_no_cost(18*60:60*24:end))
        title("Battery Percentage Daily (18:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    sgtitle("No Cost Strategy");

%% - Plot "DoD" Strategy -
figure(7)
    subplot(221)
        plot(wastedKwDay_DoD)
        title("Daily Wasted kWh");
        xlim([1,365])
        xlabel("Days")
        ylabel("kWh")
    subplot(222)
        plot(moneySpentDay_DoD)
        title("Money spent Daily");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    subplot(223)
        plot(moneyEarnedDay_DoD)
        title("Money earned Daily");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    subplot(224)
        stem(moneyEarnedDay_DoD-moneySpentDay_DoD)
        title("Difference 'earned-spent' Daily (€)");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    sgtitle("DoD Strategy");

figure(8)
    subplot(311)
        plot(battery_daily_DoD(1:60*24:end))
        title("Battery Percentage Daily (00:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    subplot(312)
        plot(battery_daily_DoD(12*60:60*24:end))
        title("Battery Percentage Daily (12:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    subplot(313)
        plot(battery_daily_DoD(18*60:60*24:end))
        title("Battery Percentage Daily (18:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    sgtitle("DoD Strategy");

%% - Plot "Night Buy" Strategy -
figure(9)
    subplot(221)
        plot(wastedKwDay_night_buy)
        title("Daily Wasted kWh");
        xlim([1,365])
        xlabel("Days")
        ylabel("kWh")
    subplot(222)
        plot(moneySpentDay_night_buy)
        title("Money spent Daily");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    subplot(223)
        plot(moneyEarnedDay_night_buy)
        title("Money earned Daily");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    subplot(224)
        stem(moneyEarnedDay_night_buy-moneySpentDay_night_buy)
        title("Difference 'earned-spent' Daily (€)");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    sgtitle("Night Buy Strategy");

figure(10)
    subplot(311)
        plot(battery_daily_night_buy(1:60*24:end))
        title("Battery Percentage Daily (00:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    subplot(312)
        plot(battery_daily_night_buy(12*60:60*24:end))
        title("Battery Percentage Daily (12:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    subplot(313)
        plot(battery_daily_night_buy(18*60:60*24:end))
        title("Battery Percentage Daily (18:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    sgtitle("Night Buy Strategy");

%% - Plot Cost Comparison Strategies -    
no=sum(moneySpentDay_no_cost);
dod=sum(moneySpentDay_DoD);
nopan=sum(moneySpentYear_no_panel);
notte=sum(moneySpentDay_night_buy);
panne= sum(moneySpentDay_only_panel);
figure(11)
    subplot(311)
        b = bar([nopan,panne,no,dod,notte]);
            b.FaceColor = 'flat';
            b.CData(1,:)=[1 0 1];
            b.CData(2,:)=[1 1 0];
            b.CData(3,:)=[0 1 0];
            b.CData(4,:)=[0 0 1];
            b.CData(5,:)=[1 0 0];
        xlim([0,6])
        title("Money spent");
        hold on
        colors=[[1 0 1];[1 1 0];[0 1 0];[0 0 1];[1 0 0]];                                   
        nColors=size(colors,1);                             
        labels={'No Panel';'Only Panel';'No Cost';'DoD';'Night Buy'};
        hBLG = bar(nan(2,nColors));         % the bar object array for legend
        for i=1:nColors
        hBLG(i).FaceColor=colors(i,:);
        end
        hLG=legend(hBLG,labels,'location','northeast');
    subplot(312)
        b = bar([0,sum(moneyEarnedDay_only_panel),sum(moneyEarnedDay_no_cost),sum(moneyEarnedDay_DoD),sum(moneyEarnedDay_night_buy)]);
            b.FaceColor = 'flat';
            b.CData(1,:)=[1 0 1]; %magenta
            b.CData(2,:)=[1 1 0]; %yellow
            b.CData(3,:)=[0 1 0]; %green
            b.CData(4,:)=[0 0 1]; %blue
            b.CData(5,:)=[1 0 0]; %red
        xlim([0,6])
        title("Money earned");
    subplot(313)
        b = bar([0-nopan,sum(moneyEarnedDay_only_panel)-panne,sum(moneyEarnedDay_no_cost)-no,sum(moneyEarnedDay_DoD)-dod,sum(moneyEarnedDay_night_buy)-notte]);
            b.FaceColor = 'flat';
            b.CData(1,:)=[1 0 1]; %magenta
            b.CData(2,:)=[1 1 0]; %yellow
            b.CData(3,:)=[0 1 0]; %green
            b.CData(4,:)=[0 0 1]; %blue
            b.CData(5,:)=[1 0 0]; %red
        xlim([0,6])
        title("Difference")
    sgtitle("Cost Comparation Strategies")
        
%% - Plot kWh Wasted Comparison Strategies -
figure(12)
    plot(wastedKwDay_only_panel,'y')
    hold on
    plot(wastedKwDay_no_cost,'g')
    plot(wastedKwDay_DoD,'b')
    plot(wastedKwDay_night_buy,'r')
    hold off
    title("kWh Wasted");
    xlim([1,365])
    legend ( 'OnlyPanel Strategy','NoCost Strategy', 'DoD Strategy', 'NightBuy Strategy')

%% - Plot Battery Percentage Daily (at Hour) Comparison Strategies -
figure(13)
    subplot(331)
        plot(battery_daily_no_cost(1:60*24:end))
        title("Battery Percentage Daily - No Cost (00:00)");
        xlim([1,365])
    subplot(332)
        plot(battery_daily_DoD(1:60*24:end))
        title("Battery Percentage Daily - DoD (00:00)");
        xlim([1,365])
    subplot(333)
        plot(battery_daily_night_buy(1:60*24:end))
        title("Battery Percentage Daily - Night Buy (00:00)");
        xlim([1,365])
    subplot(334)
        plot(battery_daily_no_cost(12*60:60*24:end))
        title("Battery Percentage Daily - No Cost (12:00)");
        xlim([1,365])
    subplot(335)
        plot(battery_daily_DoD(12*60:60*24:end))
        title("Battery Percentage Daily - DoD (12:00)");
        xlim([1,365])
    subplot(336)
        plot(battery_daily_night_buy(12*60:60*24:end))
        title("Battery Percentage Daily - Night Buy (12:00)");
        xlim([1,365])
    subplot(337)
        plot(battery_daily_no_cost(18*60:60*24:end))
        title("Battery Percentage Daily - No Cost (18:00)");
        xlim([1,365])
    subplot(338)
        plot(battery_daily_DoD(18*60:60*24:end))
        title("Battery Percentage Daily - DoD (18:00)");
        xlim([1,365])
    subplot(339)
        plot(battery_daily_night_buy(18*60:60*24:end))
        title("Battery Percentage Daily - Night Buy (18:00)");
        xlim([1,365])
    sgtitle("Battery Percentage Daily (00 - 12 - 18) Comparation Strategies")

%% - DoD Strategy -> downsizing for DoD - 
%Change Battery Lifecycle Parameters
cycles_1 = 7200;
cost_mod_1=221.85;
cost_tot_1=cost_mod_1*n_mod;
cost_cycle_1 = cost_tot_1/cycles_1;
DoD_down = 0.6;

plotHealtBattery(14,5000,'ChineseBattery')
%Change DoD
[wastedKwDay_DoD_1,moneySpentDay_DoD_1,moneyEarnedDay_DoD_1,recharge_cycle_DoD_1,battery_daily_DoD_1] = strategy_with_DoD(P_nom_field,irradianceYearSimulation,Eload_k_kwh, costi, C_tot_kw, cost_cycle_1, Eload_fix_kwh,DoD_down,inv_Threshold);

figure(15)
    subplot(221)
        plot(wastedKwDay_DoD_1)
        title("Daily Wasted kWh");
        xlim([1,365])
        xlabel("Days")
        ylabel("kWh")
    subplot(222)
        plot(moneySpentDay_DoD_1)
        title("Money spent Daily");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    subplot(223)
        plot(moneyEarnedDay_DoD_1)
        title("Money earned Daily");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    subplot(224)
        stem(moneyEarnedDay_DoD_1-moneySpentDay_DoD_1)
        title("Difference 'earned-spent' Daily (€)");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    sgtitle("DoD Strategy (DoD = 0.6)");

figure(16)
    subplot(311)
        plot(battery_daily_DoD_1(1:60*24:end))
        title("Battery Percentage Daily (00:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    subplot(312)
        plot(battery_daily_DoD_1(12*60:60*24:end))
        title("Battery Percentage Daily (12:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    subplot(313)
        plot(battery_daily_DoD_1(18*60:60*24:end))
        title("Battery Percentage Daily (18:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    sgtitle("DoD Strategy (DoD = 0.6)");
%% - Night Buy Strategy -> variations -
%Increase % of recharge during the night
[wastedKwDay_night_buy_1,moneySpentDay_night_buy_1,moneyEarnedDay_night_buy_1,recharge_cycle_night_buy_1,battery_daily_night_buy_1] = strategy_with_night_buy(P_nom_field,irradianceYearSimulation,Eload_k_kwh, costi, C_tot_kw,cost_cycle, Eload_fix_kwh,0.7,DoD,inv_Threshold);

figure(17)
    subplot(221)
        plot(wastedKwDay_night_buy_1)
        title("Daily Wasted kWh");
        xlim([1,365])
        xlabel("Days")
        ylabel("kWh")
    subplot(222)
        plot(moneySpentDay_night_buy_1)
        title("Money spent Daily");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    subplot(223)
        plot(moneyEarnedDay_night_buy_1)
        title("Money earned Daily");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    subplot(224)
        stem(moneyEarnedDay_night_buy_1-moneySpentDay_night_buy_1)
        title("Difference 'earned-spent' Daily (€)");
        xlim([1,365])
        xlabel("Days")
        ylabel("€")
    sgtitle("Night Buy Strategy (% Recharge = 0.7)");

figure(18)
    subplot(311)
        plot(battery_daily_night_buy_1(1:60*24:end))
        title("Battery Percentage Daily (00:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    subplot(312)
        plot(battery_daily_night_buy_1(12*60:60*24:end))
        title("Battery Percentage Daily (12:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    subplot(313)
        plot(battery_daily_night_buy_1(18*60:60*24:end))
        title("Battery Percentage Daily (18:00)");
        xlim([1,365])
        xlabel("Days")
        ylabel("%")
    sgtitle("Night Buy Strategy (% Recharge = 0.7)");
    
%Increase % of recharge during the night (?)

%% - Plot Battery Recharge Cycles Comparison Strategies -
figure(19)
    b = bar([recharge_no_cost,recharge_cycle_DoD,recharge_cycle_night_buy]);
        b.FaceColor = 'flat';
        b.CData(1,:)=[0 1 0]; %green
        b.CData(2,:)=[0 0 1]; %blue
        b.CData(3,:)=[1 0 0]; %red
    xlim([0,4])
    title("Battery Recharge Cycles");
    hold on
    colors=[[0 1 0];[0 0 1];[1 0 0]];                                   
    nColors=size(colors,1);                             
    labels={'No Cost';'DoD';'Night Buy'};
    hBLG = bar(nan(2,nColors));         % the bar object array for legend
    for i=1:nColors
      hBLG(i).FaceColor=colors(i,:);
    end
    hLG=legend(hBLG,labels,'location','northeast');
%% - Generate a 10 year simulation - 
for i=0:24
    [decadeIrr(1:24,1+i*365:365+i*365),decadeYear(1:31,1+i*12:12+i*12)] = generateYearIrradiance;
end

%Strategy "No Panel"
moneySpentYear_no_panel_dec = strategy_no_panel(Eload_k_kwh, costi, decadeIrr);

%Strategy "Only Panel"
[wastedKwDay_only_panel_dec, moneySpentDay_only_panel_dec,moneyEarnedDay_only_panel_dec] = strategy_only_panel(P_nom_field,decadeIrr,Eload_k_kwh, costi,inv_Threshold);

%Strategy "No Cost"
[wastedKwDay_no_cost_dec,moneySpentDay_no_cost_dec,moneyEarnedDay_no_cost_dec, recharge_no_cost_dec,battery_daily_no_cost_dec] = strategy_no_cost(P_nom_field,decadeIrr,Eload_k_kwh, costi, C_tot_kw,inv_Threshold);

%Strategy "DoD"
[wastedKwDay_DoD_dec,moneySpentDay_DoD_dec,moneyEarnedDay_DoD_dec, recharge_cycle_DoD_dec,battery_daily_DoD_dec] = strategy_with_DoD(P_nom_field,decadeIrr,Eload_k_kwh, costi, C_tot_kw, cost_cycle, Eload_fix_kwh,DoD,inv_Threshold);

%Strategy "Night Buy"
[wastedKwDay_night_buy_dec,moneySpentDay_night_buy_dec,moneyEarnedDay_night_buy_dec,recharge_cycle_night_buy_dec,battery_daily_night_buy_dec] = strategy_with_night_buy(P_nom_field,decadeIrr,Eload_k_kwh, costi, C_tot_kw,cost_cycle, Eload_fix_kwh,0.5,DoD,inv_Threshold);

%Costs
no_dec=sum(moneySpentDay_no_cost_dec);
dod_dec=sum(moneySpentDay_DoD_dec);
nopan_dec=sum(moneySpentYear_no_panel_dec);
notte_dec=sum(moneySpentDay_night_buy_dec);
panne_dec= sum(moneySpentDay_only_panel_dec);
figure(20)
    subplot(311)
        b = bar([nopan_dec,panne_dec,no_dec,dod_dec,notte_dec]);
            b.FaceColor = 'flat';
            b.CData(1,:)=[1 0 1];
            b.CData(2,:)=[1 1 0];
            b.CData(3,:)=[0 1 0];
            b.CData(4,:)=[0 0 1];
            b.CData(5,:)=[1 0 0];
        xlim([0,6])
        title("Money spent");
        hold on
        colors=[[1 0 1];[1 1 0];[0 1 0];[0 0 1];[1 0 0]];                                   
        nColors=size(colors,1);                             
        labels={'No Panel';'Only Panel';'No Cost';'DoD';'Night Buy'};
        hBLG = bar(nan(2,nColors));         % the bar object array for legend
        for i=1:nColors
            hBLG(i).FaceColor=colors(i,:);
        end
        hLG=legend(hBLG,labels,'location','northeast');
    subplot(312)
        b = bar([0,sum(moneyEarnedDay_only_panel_dec),sum(moneyEarnedDay_no_cost_dec),sum(moneyEarnedDay_DoD_dec),sum(moneyEarnedDay_night_buy_dec)]);
            b.FaceColor = 'flat';
            b.CData(1,:)=[1 0 1]; %magenta
            b.CData(2,:)=[1 1 0]; %yellow
            b.CData(3,:)=[0 1 0]; %green
            b.CData(4,:)=[0 0 1]; %blue
            b.CData(5,:)=[1 0 0]; %red
        xlim([0,6])
        title("Money earned");
    subplot(313)
        b = bar([0-nopan_dec,sum(moneyEarnedDay_only_panel_dec)-panne_dec,sum(moneyEarnedDay_no_cost_dec)-no_dec,sum(moneyEarnedDay_DoD_dec)-dod_dec,sum(moneyEarnedDay_night_buy_dec)-notte_dec]);
            b.FaceColor = 'flat';
            b.CData(1,:)=[1 0 1]; %magenta
            b.CData(2,:)=[1 1 0]; %yellow
            b.CData(3,:)=[0 1 0]; %green
            b.CData(4,:)=[0 0 1]; %blue
            b.CData(5,:)=[1 0 0]; %red
        xlim([0,6])
        title("Difference")
    sgtitle("Cost Comparation Strategies")

%Battery Cycles 10 year
figure(21)
    b = bar([recharge_no_cost_dec,recharge_cycle_DoD_dec,recharge_cycle_night_buy_dec]);
        b.FaceColor = 'flat';
        b.CData(1,:)=[0 1 0]; %green
        b.CData(2,:)=[0 0 1]; %blue
        b.CData(3,:)=[1 0 0]; %red
    xlim([0,4])
    title("Battery Recharge Cycles");
    hold on
    colors=[[0 1 0];[0 0 1];[1 0 0]];                                   
    nColors=size(colors,1);                             
    labels={'No Cost';'DoD';'Night Buy'};
    hBLG = bar(nan(2,nColors));         % the bar object array for legend
    for i=1:nColors
      hBLG(i).FaceColor=colors(i,:);
    end
    hLG=legend(hBLG,labels,'location','northeast');

%Total cost with sell to electric manager
plant_cost = Cost_PV + cost_tot;
figure(22)
    b = bar([0-nopan_dec,sum(moneyEarnedDay_only_panel_dec)-panne_dec-Cost_PV,sum(moneyEarnedDay_no_cost_dec)-no_dec-plant_cost,sum(moneyEarnedDay_DoD_dec)-dod_dec-plant_cost,sum(moneyEarnedDay_night_buy_dec)-notte_dec-plant_cost]);
        b.FaceColor = 'flat';
        b.CData(1,:)=[1 0 1]; %magenta
        b.CData(2,:)=[1 1 0]; %yellow
        b.CData(3,:)=[0 1 0]; %green
        b.CData(4,:)=[0 0 1]; %blue
        b.CData(5,:)=[1 0 0]; %red
    xlim([0,6])
    title("Total Cost Comparation Strategies Selling")

%Total cost without sell to electric manager
plant_cost = Cost_PV + cost_tot+1000;
figure(23)
    b = bar([nopan_dec,panne_dec+Cost_PV,no_dec+plant_cost,dod_dec+plant_cost,notte_dec+plant_cost]);
        b.FaceColor = 'flat';
        b.CData(1,:)=[1 0 1]; %magenta
        b.CData(2,:)=[1 1 0]; %yellow
        b.CData(3,:)=[0 1 0]; %green
        b.CData(4,:)=[0 0 1]; %blue
        b.CData(5,:)=[1 0 0]; %red
    xlim([0,6])
    title("Total Cost Comparation Strategies No Selling")
    
%% - Influenza della temperatura - 
NOCT = 45; %[°C]
alfa = -0.0035;
Tstc = 25; %[°C]
[dic, ago, ott, apr] = generateIrrSingleCase;

tempDay1 = extimateTemperature(1);
tempDay2 = extimateTemperature(2);
tempDay3 = extimateTemperature(3);
tempDay4 = extimateTemperature(4);

P_day_dic = ((P_nom_field/1000)*dic)./1000;
P_day_ago = ((P_nom_field/1000)*ago)./1000;
P_day_ott = ((P_nom_field/1000)*ott)./1000;
P_day_apr = ((P_nom_field/1000)*apr)./1000;

T_dic_1=tempDay1(:,12)+((NOCT-20)/800).*dic(:,1);
T_dic_2=tempDay1(:,12)+((NOCT-20)/800).*dic(:,2);
T_dic_3=tempDay1(:,12)+((NOCT-20)/800).*dic(:,3);
T_dic_4=tempDay1(:,12)+((NOCT-20)/800).*dic(:,4);

T_ago_1=tempDay1(:,8)+((NOCT-20)/800).*ago(:,1);
T_ago_2=tempDay1(:,8)+((NOCT-20)/800).*ago(:,2);
T_ago_3=tempDay1(:,8)+((NOCT-20)/800).*ago(:,3);
T_ago_4=tempDay1(:,8)+((NOCT-20)/800).*ago(:,4);

T_ott_1=tempDay1(:,10)+((NOCT-20)/800).*ott(:,1);
T_ott_2=tempDay1(:,10)+((NOCT-20)/800).*ott(:,2);
T_ott_3=tempDay1(:,10)+((NOCT-20)/800).*ott(:,3);
T_ott_4=tempDay1(:,10)+((NOCT-20)/800).*ott(:,4);

T_apr_1=tempDay1(:,4)+((NOCT-20)/800).*apr(:,1);
T_apr_2=tempDay1(:,4)+((NOCT-20)/800).*apr(:,2);
T_apr_3=tempDay1(:,4)+((NOCT-20)/800).*apr(:,3);
T_apr_4=tempDay1(:,4)+((NOCT-20)/800).*apr(:,4);

P_temp_dic_1 = P_day_dic(:,1).*(1+alfa*(T_dic_1-Tstc));
P_temp_dic_2 = P_day_dic(:,2).*(1+alfa*(T_dic_2-Tstc));
P_temp_dic_3 = P_day_dic(:,3).*(1+alfa*(T_dic_3-Tstc));
P_temp_dic_4 = P_day_dic(:,4).*(1+alfa*(T_dic_4-Tstc));

P_temp_ago_1 = P_day_ago(:,1).*(1+alfa*(T_ago_1-Tstc));
P_temp_ago_2 = P_day_ago(:,2).*(1+alfa*(T_ago_2-Tstc));
P_temp_ago_3 = P_day_ago(:,3).*(1+alfa*(T_ago_3-Tstc));
P_temp_ago_4 = P_day_ago(:,4).*(1+alfa*(T_ago_4-Tstc));

P_temp_ott_1 = P_day_ott(:,1).*(1+alfa*(T_ott_1-Tstc));
P_temp_ott_2 = P_day_ott(:,2).*(1+alfa*(T_ott_2-Tstc));
P_temp_ott_3 = P_day_ott(:,3).*(1+alfa*(T_ott_3-Tstc));
P_temp_ott_4 = P_day_ott(:,4).*(1+alfa*(T_ott_4-Tstc));

P_temp_apr_1 = P_day_apr(:,1).*(1+alfa*(T_apr_1-Tstc));
P_temp_apr_2 = P_day_apr(:,2).*(1+alfa*(T_apr_2-Tstc));
P_temp_apr_3 = P_day_apr(:,3).*(1+alfa*(T_apr_3-Tstc));
P_temp_apr_4 = P_day_apr(:,4).*(1+alfa*(T_apr_4-Tstc));

figure(24)
    subplot(421)
        plot(P_day_ago(:,1))
        hold on
        plot(P_temp_ago_1)
        title("Agosto - Giorno Tipo 1");
        ylabel("kW")
        legend('No Temperature','Influenza Temperature')
    subplot(423)
        plot(P_day_ago(:,2))
        hold on
        plot(P_temp_ago_2)
        title("Agosto - Giorno Tipo 2");
        ylabel("kW")
    subplot(425)
        plot(P_day_ago(:,3))
        hold on
        plot(P_temp_ago_3)
        title("Agosto - Giorno Tipo 3");
        ylabel("kW")
    subplot(427)
        plot(P_day_ago(:,4))
        hold on
        plot(P_temp_ago_4)
        title("Agosto - Giorno Tipo 4");
        ylabel("kW")
    subplot(422)
        plot(P_day_dic(:,1))
        hold on
        plot(P_temp_dic_1)
        title("Dicembre - Giorno Tipo 1");
        ylabel("kW")
    subplot(424)
        plot(P_day_dic(:,2))
        hold on
        plot(P_temp_dic_2)
        title("Dicembre - Giorno Tipo 2");
        ylabel("kW")
    subplot(426)
        plot(P_day_dic(:,3))
        hold on
        plot(P_temp_dic_3)
        title("Dicembre - Giorno Tipo 3");
        ylabel("kW")
    subplot(428)
        plot(P_day_dic(:,4))
        hold on
        plot(P_temp_dic_4)
        title("Dicembre - Giorno Tipo 4");
        ylabel("kW")
    sgtitle("Confronto potenza influenza Temperature Dicembre - Agosto")
figure(25)
    subplot(421)
        plot(P_day_apr(:,1))
        hold on
        plot(P_temp_apr_1)
        title("Aprile - Giorno Tipo 1");
        ylabel("kW")
        legend('No Temperature','Influenza Temperature')
    subplot(423)
        plot(P_day_apr(:,2))
        hold on
        plot(P_temp_apr_2)
        title("Aprile - Giorno Tipo 2");
        ylabel("kW")
    subplot(425)
        plot(P_day_apr(:,3))
        hold on
        plot(P_temp_apr_3)
        title("Aprile - Giorno Tipo 3");
        ylabel("kW")
    subplot(427)
        plot(P_day_apr(:,4))
        hold on
        plot(P_temp_apr_4)
        title("Aprile - Giorno Tipo 4");
        ylabel("kW")
    subplot(422)
        plot(P_day_ott(:,1))
        hold on
        plot(P_temp_ott_1)
        title("Ottobre - Giorno Tipo 1");
        ylabel("kW")
    subplot(424)
        plot(P_day_ott(:,2))
        hold on
        plot(P_temp_ott_2)
        title("Ottobre - Giorno Tipo 2");
        ylabel("kW")
    subplot(426)
        plot(P_day_ott(:,3))
        hold on
        plot(P_temp_ott_3)
        title("Ottobre - Giorno Tipo 3");
        ylabel("kW")
    subplot(428)
        plot(P_day_ott(:,4))
        hold on
        plot(P_temp_ott_4)
        title("Ottobre - Giorno Tipo 4");
        ylabel("kW")
    sgtitle("Confronto potenza influenza Temperature Aprile - Ottobre")