function y=extimateIrradiance(meanIrradiance,varIrradiance)
    for h=1:24
        if(meanIrradiance(h)==0)
            y(h)=0;
        else
        y(h)=mvnrnd(meanIrradiance(h),varIrradiance,1);
        end
        if(y(h)<0)
            y(h)=0;
        end
    end
end