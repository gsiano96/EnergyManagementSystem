%{
    Questa strategia è stata implementata tenendo conto di un impianto per
    l'energia alternativa composto solo da pannelli solari senza tener
    conto di eventuale batteria per lo stoccaggio di energia da
    riutilizzare. Nel caso in cui i pannelli solari non riescano ad
    alimentare il carico l'energia rimanente viene comprata dal gestore
    elettrico al prezzo descritto dal profilo di costo orario. Nel caso in
    cui si abbia una sovraproduzione di energia elettrica allora la stessa
    viene rivenduta al gestore elettrico a metà del prezzo d'acquisto in
    quella stessa ora.
%}
function [ wastedKwDay, moneySpentDay,moneyEarnedDay] = strategy_only_panel(P_nom_field,irradianceYearSimulation,Eload_k_kwh,costi,Inverter_threshold_in, Inverter_threshold_out, yield_inv)
    costEnergy=spline(1:60:1440,costi,1:1440)./1000;
    costi_kw_min_vend=costEnergy-costEnergy*0.5;
    moneySpentDay=[];
    moneyEarnedDay=[];
    wastedKwDay = [];
    Enel=0;
    x = length(irradianceYearSimulation);

    for d=1:x
        
        P_day = (P_nom_field/1000)*irradianceYearSimulation(:,d); %[W]
        P_d_min = spline(1:60:1440, P_day, 1:1440); %[W]
        P_d_min_kw = P_d_min/1000; %[kW]
        Epv_d=cumtrapz(0.0167,P_d_min); % [Wh] Energy produced at each step
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
            if Epv_d_act < Eload_fix_act
                diff = Eload_fix_act - Epv_d_act;
                Enel = Enel + diff; %kWh bought by electric manager
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