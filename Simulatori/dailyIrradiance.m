function y=dailyIrradiance(month,irradiance)
    load ./IrradianceData/Irradianza_Agosto.mat
    load ./IrradianceData/Irradianza_Aprile.mat
    load ./IrradianceData/Irradianza_Dicembre.mat
    load ./IrradianceData/Irradianza_Ottobre.mat
    y=[]
    for i=1:31
        if(month(i)==1)
            y(:,i)=extimateIrradiance(irradiance+irradiance*0.3,20)
        elseif(month(i)==2)
            y(:,i)=extimateIrradiance(irradiance,100)
        elseif(month(i)==3)
            y(:,i)=extimateIrradiance(irradiance-0.4*irradiance,20)
        elseif(month(i)==4)
            y(:,i)=extimateIrradiance(irradiance-0.8*irradiance,80)
        else
            y(i)=zeros(24,i);
        end
    end
end