clear all
close all
clc
load ./IrradianceData/yearIrradiance.mat
load ./IrradianceData/yearTemperature.mat

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

