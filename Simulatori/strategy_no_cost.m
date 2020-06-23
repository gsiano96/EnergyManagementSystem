%{
    Questa strategia non tiene conto del costo di acquisto dell'energia dal
    fornitore ne di quello di erogazione energia da parte della batteria.
    Essa confronta minuto per minuto l'energia prodotta dal campo
    fotovoltaico con quella richiesta dal carico, nel caso in cui quella
    del campo riesca a soddisfare il carico allora tutto viene assorbito
    dal carico e l'eventuale resto viene inserito nella batteria, se ne può
    ospitare, oppure venduto al gestore elettrico. Nel caso in cui il campo 
    non riesca a fornire il necessario allora viene comunque presa energia 
    dal campo ed il rimanente dalla batteria se ne dispone, in caso 
    contrario dal gestore elettrico.
%}
function [wastedKwDay,moneySpentDay,moneyEarnedDay,recharge_cycle, battery_percentage_daily] = strategy_no_cost(P_nom_field,irradianceYearSimulation,Eload_k_kwh, costi, C_tot_kw)

    costEnergy=spline(1:60:1440,costi,1:1440)./1000;
    costi_kw_min_vend=costEnergy-costEnergy*0.5;
    C_act = 0;
    Enel = 0;
    Conta_carica = 0;
    C_act_count = zeros(1440,365);
    recharge_cycle=0;
    counter_charger=0;
    battery_percentage=[];
    battery_percentage_daily=[];
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
        profit = 0;
        for h=1:1440
            if h>1 %verify if is the first execution of the cycle or not
                Epv_d_act = Epv_d_kwh(h)-Epv_d_kwh(h-1);
                Eload_fix_act = Eload_k_kwh(h)-Eload_k_kwh(h-1);
            else
                Epv_d_act = Epv_d_kwh(h);
                Eload_fix_act = Eload_k_kwh(h);
            end
            if Epv_d_act < Eload_fix_act %verify if the actual energy produced by the PV is less then the energy request of the load
                diff = Eload_fix_act - Epv_d_act; %obtain the difference between the energies
                if C_act > diff %verify if the battery can satisfy the plus request of the load
                    C_act = C_act-diff;
                else
                    Enel = Enel + diff;%take difference from the vendor
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
                        C_act = C_tot_kw;
                        counter_charger=counter_charger-(C_act-C_tot_kw)/C_tot_kw;
                        flag = 1;
                        
                    end
                    if(counter_charger>1)
                        counter_charger=counter_charger-1;
                        recharge_cycle=recharge_cycle+1;
                    end
                end
            end
            battery_percentage(h)=C_act/C_tot_kw*100;
            C_act_count(h,d) = C_act;      
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