%{
    Questa strategia � stata implementata tenendo conto di un impianto per
    l'energia alternativa composto da pannelli solari nonch� batteria per
    l'immagazzinamento di energia prodotta in eccesso. Tale strategia tiene
    conto del costo dell'energia e del DoD della batteria di modo ch� la
    stessa possa subire i cicli di carica corrispondenti a quanto
    dichiarato dal datasheet. In linee generali non si discosta dalla
    strategia "no_cost" ma la batteria viene ricaricata fino ad una certa
    percentuale ogni notte (se la stessa ha una carica inferiore) mentre di
    giorno segue la normale impostazione delle altre strategie. 
%}
function [wastedKwDay,moneySpentDay,moneyEarnedDay,recharge_cycle,battery_percentage_daily] = strategy_with_night_buy(P_nom_field,irradianceYearSimulation,Eload_k_kwh, costi, C_tot_kw,cost_cycle, Eload_fix_kwh,max_charge,DoD,Inverter_threshold_in, Inverter_threshold_out, yield_inv)    
    
    cost_kw_battery = cost_cycle/(C_tot_kw*DoD);
    costEnergy=spline(1:60:1440,costi,1:1440)./1000;
    costi_kw_min_vend=costEnergy-costEnergy*0.5;
    C_act = 0;
    Enel = 0;
    Conta_carica = 0;
    pippo=0;
    Enel_eur = 0;
    profit = 0;
    battery_percentage=[];
    battery_percentage_daily=[];
    recharge_cycle=0;
    counter_charger=0;
    x = length(irradianceYearSimulation);
    for d=1:x
        %%Calculate daily energy produced
        P_day = (P_nom_field/1000)*irradianceYearSimulation(:,d); %[W]
        P_d_min = spline(1:60:1440, P_day, 1:1440); %[W]
        P_d_min_kw = P_d_min/1000; %[kW]
        Epv_d=cumtrapz(0.0167,P_d_min); %Energy produced at each step
        Epv_d_kwh=Epv_d/1000; %[kWh]
        flag = 0;
        
        moneySpent = 0;
        kw_butt = 0;
        profit=0;
        for h=1:1440
            if h>1 %verify if is the first execution of the cycle or not
                Epv_d_act = Epv_d_kwh(h)-Epv_d_kwh(h-1);
                Eload_fix_act = Eload_fix_kwh(h) - Eload_fix_kwh(h-1);
            else
                Epv_d_act = Epv_d_kwh(h);
                Eload_fix_act = Eload_fix_kwh(h);
            end
            %--- Inverter Section -----
            if Epv_d_act > Inverter_threshold_in
                Epv_d_act = Inverter_threshold_in; 
            end
            if Epv_d_act > Inverter_threshold_out
                Epv_d_act = Inverter_threshold_out;
            else
                Epv_d_act = Epv_d_act*yield_inv;
            end
            %--------------------------
            if Epv_d_act < Eload_fix_act %verify if the actual energy produced by the PV is less then the energy request of the load
                diff = Eload_fix_act - Epv_d_act; %obtain the difference between the energies
                if costEnergy(h)>cost_kw_battery
                    if (C_act-diff > C_tot_kw*(1-DoD))
                       if (h>6*60) && (h<23*60) %verify if the battery can satisfy the plus request of the load
                            C_act = C_act-diff;
                        else
                            Enel = Enel + diff;%take difference from the vendor
                            %Enel_eur = Enel_eur + costEnergy(h)*diff;
                            moneySpent = moneySpent + diff*costEnergy(h);
                        end
                    end
                else
                    Enel = Enel + diff;%take difference from the vendor
                    %Enel_eur = Enel_eur + costEnergy(h)*diff;
                    moneySpent = moneySpent + diff*costEnergy(h);
                end
            else
                plus = Epv_d_act - Eload_fix_act;%if the energy produced by PV is more than the load request
                if plus > 0
                    C_act = C_act+plus;%charge the battery
                    counter_charger=counter_charger+plus/C_tot_kw;
                    if C_act >= C_tot_kw%if the battery is full do not charge it
                        kw_butt = kw_butt + C_act-C_tot_kw;
                        profit = profit + (C_act-C_tot_kw)*costi_kw_min_vend(h);
                        counter_charger=counter_charger-(C_act-C_tot_kw)/C_tot_kw;
                        C_act = C_tot_kw;
                        
                        flag = 1;
                    end
                    if(counter_charger>=DoD)
                        counter_charger=counter_charger-DoD;
                        recharge_cycle=recharge_cycle+1;
                    end
                end
            end
            battery_percentage(h)=C_act/C_tot_kw*100;
            if (h<6*60) || (h>23*60)
                if(battery_percentage(h)/100<max_charge)
                    Enel=max_charge*C_tot_kw-C_act;
                    %Enel_eur = Enel_eur + costEnergy(h)*(max_charge-C_act);
                    moneySpent = moneySpent + costEnergy(h)*Enel;
                    counter_charger = counter_charger + Enel/C_tot_kw;
                    C_act=max_charge*C_tot_kw;
                end
            end
        end
        battery_percentage_daily=[battery_percentage_daily battery_percentage];
        if flag == 1 %count the days of full battery charge
            Conta_carica = Conta_carica + 1;
        end
        wastedKwDay(d) = kw_butt;
        moneySpentDay(d) = moneySpent;
        moneyEarnedDay(d) = profit;
    end
end