function [irradiance, temperature]=extimateIrradiance(meanIrradiance,varIrradiance,meanTemperature,varTemperature)
    for h=1:24
        if(meanIrradiance(h)==0)
            irradiance(h)=0;
            temperature(h)=mvnrnd(meanTemperature(h),varTemperature,1);
        else
        irradiance(h)=mvnrnd(meanIrradiance(h),varIrradiance,1);
        if(h==1)
            temperature(h)=mvnrnd(meanTemperature(h),varTemperature,1);
        else
            temperature(h)=mvnrnd(temperature(h-1),varTemperature,1);
        end
        end
        if(irradiance(h)<0)
            irradiance(h)=0;
        end
    end
end
