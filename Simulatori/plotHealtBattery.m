function plotHealtBattery(x,y,z)
    load ./Batteria/Battery_health.mat
    
    rel = y - BatteryHealth(118,2);
    out = rel + BatteryHealth(:,2);
    
    figure(x)
        plot(BatteryHealth(:,1),BatteryHealth(:,2))
        hold on
        plot(BatteryHealth(:,1),out);
        hold off
        legend('LiFePo4',z)
        title('DoD-Cycle relation (LiFePo4)')
        
end