function irradianceYear=dailyIrradiance(month,irradiance)
    irradianceYear=[];
    
    for i=1:31
        if(month(i)==1)
            irradianceYear(:,i)=extimateIrradiance(irradiance+irradiance*0.3,20);
        elseif(month(i)==2)
            irradianceYear(:,i)=extimateIrradiance(irradiance,100);
        elseif(month(i)==3)
            irradianceYear(:,i)=extimateIrradiance(irradiance-0.4*irradiance,20);
        elseif(month(i)==4)
            irradianceYear(:,i)=extimateIrradiance(irradiance-0.8*irradiance,20);
        else
            irradianceYear(:,i)=zeros(24,1);
        end
    end
end
