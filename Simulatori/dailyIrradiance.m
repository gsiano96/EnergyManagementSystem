function [irradianceYear, temperatureYear]=dailyIrradiance(month,irradiance,temperature)
    irradianceYear=[];
    temperatureYear=[];
    for i=1:31
        if(month(i)==1)
            [irradianceYear(:,i),temperatureYear(:,i)]=extimateIrradiance(irradiance+irradiance*0.3,20,temperature+temperature*0.3,0.5);
        elseif(month(i)==2)
            [irradianceYear(:,i),temperatureYear(:,i)]=extimateIrradiance(irradiance,100,temperature,0.8);
        elseif(month(i)==3)
            [irradianceYear(:,i),temperatureYear(:,i)]=extimateIrradiance(irradiance-0.4*irradiance,20,temperature-0.4*temperature,1);
        elseif(month(i)==4)
            [irradianceYear(:,i),temperatureYear(:,i)]=extimateIrradiance(irradiance-0.8*irradiance,80,temperature-0.8*temperature,1.5);
        else
            irradianceYear(:,i)=zeros(24,1);
            temperatureYear(:,i)=zeros(24,1);
        end
    end
end
