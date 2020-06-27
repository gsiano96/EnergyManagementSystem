function [irradianceYearSimulation,year] = generateYearIrradiance 
    load ./IrradianceData/yearIrradiance.mat
    
    totalmatrix=monthsCloudyOcc;
    pcloud=[];
    monthdays=[31,28,31,30,31,30,31,31,30,31,30,31];    

    for i=1:12
        pcloud(i,:)=cloudyProb(totalmatrix(find(totalmatrix(:,i)),i));
    end
    year=zeros(31,12);

    for i=1:12
        year(:,i)=obtainMonthConditions(pcloud(i,:),totalmatrix(:,i),monthdays(i));
    end

    %Return the irradiance for each day of the year calculated previosly
    for i=0:11
        yirr(:,1+(31*i):31*(i+1))=dailyIrradiance(year(:,i+1),yearIrradiance(:,i+1));
    end
    j=1;
    for i=1:length(yirr)
        if(sum(yirr(:,i))~=0)
            irradianceYearSimulation(:,j)=yirr(:,i);  
            j=j+1;
        end
    end
    figure(2)
    stem([year(:,1);year(1:28,2);year(:,3);year(1:30,4);year(:,5);year(1:30,6);year(:,7);year(:,8);year(1:30,9);year(:,10);year(1:30,11);year(:,12)])
    xlim([1,365])
end