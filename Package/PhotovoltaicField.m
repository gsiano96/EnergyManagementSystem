classdef PhotovoltaicField
    properties
        Npanels {mustBeNumeric}
        Ppanel_nominal {mustBeNumeric} %STC condition
        Vpanel_mpp {mustBeNumeric}
        Ipanel_mpp {mustBeNumeric}
        panelPowerTemperatureCoefficient {mustBeNumeric}
        panelVoltageTemperatureCoefficient {mustBeNumeric}
        NOCT {mustBeNumeric}
        
        seriesPanelsNumber {mustBeNumeric}
        parallelsPanelsNumber {mustBeNumeric}
        
        Vfield_mpp {mustBeNumeric}
        Ifield_mpp {mustBeNumeric}
        Pfield_nominal {mustBeNumeric}
    end
    methods
        function obj = PhotovoltaicField(Npanels,Ppanel_nominal,...
                Vpanel_mpp,...
                panelPowerTemperatureCoefficient,...
                panelVotageTemperatureCoefficient,...
                seriesPanelsNumber, parallelsPanelsNumber,...
                NOCT)
            obj.Npanels=Npanels;
            obj.Ppanel_nominal=Ppanel_nominal;
            obj.Vpanel_mpp=Vpanel_mpp;
            obj.panelPowerTemperatureCoefficient=panelPowerTemperatureCoefficient;
            obj.panelVoltageTemperatureCoefficient=panelVotageTemperatureCoefficient;
            obj.seriesPanelsNumber=seriesPanelsNumber;
            obj.parallelsPanelsNumber=parallelsPanelsNumber;
            obj.Pfield_nominal=obj.Ppanel_nominal*obj.Npanels;
            obj.Vfield_mpp=obj.Vpanel_mpp * seriesPanelsNumber;
            obj.Ifield_mpp=obj.Ipanel_mpp * parallelsPanelsNumber;
            obj.NOCT= NOCT;
        end
        
        function Ppv_k=getMaxOutputPowerSTC(obj,G_k)
           Gnominal=1000; %W/m^2
           %Proportional scale
           Ppv_k=(obj.Pfield_nominal / Gnominal) * G_k;
        end
        
        function Vpv_k=getMaxOutputVoltageSTC(obj,G_k)
           Gnominal=1000; %W/m^2
           %Proportional scale
           Vpv_k=(obj.Vfield_mpp / Gnominal) * G_k;
        end
        
        function Ppv_k=rescaleMPPByTemperature(obj,Pmpp_k,temperatureDegree_k,G_k)
            % Don't scale if the temperature is 25°C
            %temperatureDegree_k(find(temperatureDegree_k == 25))=0;
            tPv_k=ones(1440,4,3);
            for i=1:1:length(tPv_k)
                for j=1:1:4 % mesi
                    for k=1:1:3 %condizioni climatiche
                        tPv_k(i,j,k)= temperatureDegree_k(i,j,k)+((obj.NOCT-20)/800*G_k(i,j,k));
                        if( tPv_k(i,j,k) >= 25)
                            factor_k(i,j,k)=1-obj.panelPowerTemperatureCoefficient*(tPv_k(i,j,k)-25);
                        else
                            factor_k(i,j,k)=1;
                        end   
                        Ppv_k(i,j,k)=Pmpp_k(i,j,k)*factor_k(i,j,k);
                    end
                end
            end
        end
        
        function Vpv_k=rescaleVmppByTemperature(obj, Vmpp_k, temperatureDegree_k)
            for i=1:1:length(temperatureDegree_k)
                for j=1:1:4
                    for k=1:1:3
                        if(temperatureDegree_k(i,j,k) >= 25)
                            factor_k(i,j,k)=1-obj.panelVoltageTemperatureCoefficient*(temperatureDegree_k(i,j,k)-25);
                        else
                            factor_k(i,j,k)=1;
                        end   
                        Vpv_k(i,j,k)=Vmpp_k(i,j,k)*factor_k(i,j,k);
                    end
                end
            end
        end
        
        function Nmin=optimizePanelsNumber(obj,Pgen_k,Pass_k, margin_k)
            %N*Ppan_k-Pload_k >= soglia
            Pgen_k(find(Pgen_k < 1))=inf;
            Pass_k(find(Pass_k < 1))=inf;
            Ppan_k=Pgen_k./obj.Npanels;
            Nmin=(margin_k+Pass_k)./Ppan_k;
        end
    end
end