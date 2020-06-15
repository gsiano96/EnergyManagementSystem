function [ wastedKwDay, moneySpentDay,moneyEarnedDay] = strategy_only_panel(P_nom_field,irradianceYearSimulation,Eload_k_kwh, costi)
costEnergy=spline(1:60:1440,costi,1:1440)./1000;
costi_kw_min_vend=costEnergy-costEnergy*0.5;
moneySpentDay=[];
moneyEarnedDay=[];
wastedKwDay = [];

Enel=0;

    for d=1:365
        
        P_day = (P_nom_field/1000)*irradianceYearSimulation(:,d); %[W]
        P_d_min = spline(1:60:1440, P_day, 1:1440); %[W]
        P_d_min_kw = P_d_min/1000; %[kW]
        Epv_d=cumtrapz(0.0167,P_d_min); %Energy produced at each step
        Epv_d_kwh=Epv_d/1000; %[kWh]
        
        profit=0;
        moneySpent=0;
        kw_butt=0;
        
        
        
        for h=1:1440
            
            if h>1 %verify if is the first execution of the cycle or not
                Epv_d_act = Epv_d_kwh(h)-Epv_d_kwh(h-1);
                Eload_fix_act = Eload_k_kwh(h)-Eload_k_kwh(h-1);
            else
                Epv_d_act = Epv_d_kwh(h);
                Eload_fix_act = Eload_k_kwh(h);
            end
            if Epv_d_act < Eload_fix_act
                diff = Eload_fix_act - Epv_d_act;
                Enel = Enel + diff;
                moneySpent = moneySpent + diff*costEnergy(h);
             else
                plus = Epv_d_act - Eload_fix_act;%if the energy produced by PV is more than the load request
                if plus > 0
                    kw_butt = kw_butt + plus;
                    profit = profit + plus*costi_kw_min_vend(h);
                end
            end
         end
    moneySpentDay(d) = moneySpent;
    wastedKwDay(d) = kw_butt;
    moneyEarnedDay(d) = profit;
    end
end