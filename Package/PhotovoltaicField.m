classdef PhotovoltaicField
    properties
        Npanels {mustBeNumeric}
        Ppanel_nominal {mustBeNumeric} %STC condition
        Vpanel_mpp {mustBeNumeric}
        Ipanel_mpp {mustBeNumeric}
        panelPowerTemperatureCoefficient {mustBeNumeric}
        panelVoltageTemperatureCoefficient {mustBeNumeric}
        
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
                seriesPanelsNumber, parallelsPanelsNumber)
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
        end
        
        function Ppv_k=getMaxOutputPowerSTC(obj,G_k)
           Gnominal=1000; %W/m^2
           %Proportional scale
           Ppv_k=(obj.Pfield_nominal / Gnominal) * G_k;
        end
        
        function Ppv_k=rescaleMPPByTemperature(obj,Pmpp_k,temperatureDegree_k)
            % Don't scale if the temperature is 25�C
            temperatureDegree_k(find(temperatureDegree_k == 25))=0;
            factor_k=1-obj.panelPowerTemperatureCoefficient*temperatureDegree_k;
            Ppv_k=Pmpp_k.*factor_k;
        end
    end
end