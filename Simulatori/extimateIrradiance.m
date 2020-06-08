function y=extimateIrradiance(meanIrradiance,varIrradiance)
    for h=1:24
        y(h)=mvnrnd(meanIrradiance(h),varIrradiance,1);
    end
end