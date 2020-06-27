%{
    Questa strategia è stata implementata tenendo conto di acquistare
    l'energia necessaria semre dal fornitore elettrico seguendo il profilo
    di costo orario per quanto rigurarda l'acquisto della stessa.
%}
function [moneySpentDay] = strategy_no_panel(Eload_k_kwh, costi,irradianceYearSimulation)
    costEnergy=spline(1:60:1440,costi,1:1440)./1000;
    x = length(irradianceYearSimulation);

    for d=1:x
        moneySpent=0;
        for h=1:1440
            if h > 1
                Eload_act = Eload_k_kwh(h)-Eload_k_kwh(h-1);
            else
                Eload_act = Eload_k_kwh(h);
            end
            moneySpent = moneySpent + Eload_act*costEnergy(h);
        end
        moneySpentDay(d) = moneySpent;
    end
end