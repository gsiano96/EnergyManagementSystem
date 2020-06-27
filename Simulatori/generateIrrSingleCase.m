function [dec,aug,oct,apr] = generateIrrSingleCase 

    load ./IrradianceData/yearIrradiance.mat
    dicembre = yearIrradiance(:,12);
    agosto = yearIrradiance(:,8);
    aprile = yearIrradiance(:,4);
    ottobre = yearIrradiance(:,10);
    
    dec1 = extimateIrradiance(dicembre+dicembre*0.3,20);
    dec2 = extimateIrradiance(dicembre,100);
    dec3 = extimateIrradiance(dicembre-0.4*dicembre,20);
    dec4 = extimateIrradiance(dicembre-dicembre*0.8,20);
    dec = [dec1;dec2;dec3;dec4]';

    aug1 = extimateIrradiance(agosto+agosto*0.3,20);
    aug2 = extimateIrradiance(agosto,100);
    aug3 = extimateIrradiance(agosto-0.4*agosto,20);
    aug4 = extimateIrradiance(agosto-agosto*0.8,20);
    aug = [aug1;aug2;aug3;aug4]';
    
    oct1 = extimateIrradiance(ottobre+ottobre*0.3,20);
    oct2 = extimateIrradiance(ottobre,100);
    oct3 = extimateIrradiance(ottobre-0.4*ottobre,20);
    oct4 = extimateIrradiance(ottobre-ottobre*0.8,20);
    oct = [oct1;oct2;oct3;oct4]';
    
    apr1 = extimateIrradiance(aprile+aprile*0.3,20);
    apr2 = extimateIrradiance(aprile,100);
    apr3 = extimateIrradiance(aprile-0.4*aprile,20);
    apr4 = extimateIrradiance(aprile-aprile*0.8,20);
    apr = [apr1;apr2;apr3;apr4]';

end