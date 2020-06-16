%{
    Questa strategia è stata implementata tenendo conto di acquistare
    l'energia necessaria semre dal fornitore elettrico seguendo il profilo
    di costo orario per quanto rigurarda l'acquisto della stessa.
%}
function [moneySpentDay] = strategy_no_panel(Eload_k_kwh, costi)
costEnergy=spline(1:60:1440,costi,1:1440)./1000;

    for d=1:365
        moneySpent=0;
        for h=1:1440
            moneySpentDay = Eload_k_kwh*costEnergy(h);
        end
    end
    moneySpentDay(d) = moneySpent;
    
end