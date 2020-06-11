function irradiance=extimateIrradiance(meanIrradiance,varIrradiance)
    for h=1:24
        if(meanIrradiance(h)==0)
            irradiance(h)=0;
        else
        irradiance(h)=mvnrnd(meanIrradiance(h),varIrradiance,1);
        end
        if(irradiance(h)<0)
            irradiance(h)=0;
        end
    end
end
