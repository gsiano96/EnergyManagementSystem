classdef EletricityGrid
    properties
        phasesNumber {mustBeNumeric}
        maxVoltage {mustBeNumeric}
        maxCurrent {mustBeNumeric}
        maxPower {mustBeNumeric}
    end
    methods
        
        function obj = EletricityGrid(phasesNumber,maxVoltage,maxCurrent)
            obj.phasesNumber=phasesNumber;
            obj.maxVoltage=maxVoltage;
            obj.maxCurrent=maxCurrent;
        end
        
        function Pgrid=getPowerAC_k(obj,Ebatt_k,capacitaMinima,Presiduo_k)
            Pgrid=zeros(1,1440);
            for time=1:1:length(Presiduo_k)
                if (Presiduo_k(time) <= 0 && Ebatt_k(time) <= capacitaMinima)
                    Pgrid(time)=Presiduo_k(time);
                end
            end
        end
        
        function Pgrid=getPowerDC_k(obj,Ebatt_k,capacitaMinima,capacitaMassima,Presiduo_k)
            Pgrid=zeros(1,1440);
            keepalive=false;
            
            for time=1:1:length(Presiduo_k)
                if(keepalive)
                    Pgrid(time)=Presiduo_k(time);
                    display(time);
                end
                if (Presiduo_k(time) <= 0 && Ebatt_k(time) <= capacitaMinima)
                    Pgrid(time)=Presiduo_k(time);
                elseif (Presiduo_k(time) <= 0 && Ebatt_k(time) >= capacitaMassima)
                    Pgrid(time)=Presiduo_k(time);
                    keepalive=true;
                end
            end
            
        end
        
        %(Ebat_carica(i,month,caso)-fullCapacity)/1000
        function guadagno=putPower_k(obj,Ebat_carica_k_kwh,fullCapacity_kwh,euroPerKwh)
            guadagno=zeros(1,length(Ebat_carica_k_kwh));
            for i=1:1:length(guadagno)
                if (Ebat_carica_k_kwh(i) >= fullCapacity_kwh)
                    guadagno(i)=(Ebat_carica_k_kwh(i) - fullCapacity_kwh)*euroPerKwh;
                end
            end
        end
               
    end
end