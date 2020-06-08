% load ./IrradianceData/January.mat
% load ./IrradianceData/February.mat
% load ./IrradianceData/March.mat
% load ./IrradianceData/Irradianza_Aprile.mat
% load ./IrradianceData/May.mat
% load ./IrradianceData/June.mat
% load ./IrradianceData/July.mat
% load ./IrradianceData/Irradianza_Agosto.mat
% load ./IrradianceData/September.mat
% load ./IrradianceData/Irradianza_Ottobre.mat
% load ./IrradianceData/November.mat
% load ./IrradianceData/Irradianza_Dicembre.mat
% yearIrradiance=[IrradianzaGennaio.G,IrradianzaFebbraio.G,IrradianzaMarzo.G,IrradianzaAprile.G,IrradianzaMaggio.G,IrradianzaGiugno.G,IrradianzaLuglio.G,IrradianzaAgosto.G,IrradianzaSettembre.G,IrradianzaOttobre.G,IrradianzaNovembre.G,IrradianzaDicembre.G]

totalmatrix=monthsCloudyOcc;
pcloud=[]
monthdays=[31,28,31,30,31,30,31,31,30,31,30,31];
for i=1:12
    pcloud(i,:)=cloudyProb(totalmatrix(find(totalmatrix(:,i)),i));
end
year=zeros(31,12);
for i=1:12
    year(:,i)=obtainMonthConditions(pcloud(i,:),totalmatrix(:,i),monthdays(i));
end