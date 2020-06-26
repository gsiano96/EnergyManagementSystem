function y = extimateTemperature(dailyCond)
    load ./IrradianceData/yearTemperature.mat
    
    if dailyCond == 1
        temperature = yearTemperature+0.2*yearTemperature;
    elseif dailyCond == 2
        temperature = yearTemperature;
    elseif dailyCond == 3
        temperature = yearTemperature-0.1*yearTemperature;
    else
        temperature = yearTemperature-0.2*yearTemperature;
    end
    y = temperature;
end