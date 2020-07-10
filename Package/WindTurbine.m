classdef WindTurbine
    properties
        % https://en.wind-turbine-models.com/turbines/1682-hummer-h25.0-100kw
        ratedPower {mustBeNumeric}
        ratedWindSpeed {mustBeNumeric}
        cutinWindSpeed {mustBeNumeric}
        cutoutWindSpeed {mustBeNumeric}
        survivalWindSpeed {mustBeNumeric}
        rotorDiameter {mustBeNumeric}
        generatorVoltage {mustBeNumeric}
        efficiency {mustBeNumeric}
    end
    methods
        function obj = WindTurbine(ratedPower,ratedWindSpeed,cutinWindSpeed,...
            cutoutWindSpeed,survivalWindSpeed,rotorDiameter,generatorVoltage)
            obj.ratedPower=ratedPower;
            obj.ratedWindSpeed=ratedWindSpeed;
            obj.cutinWindSpeed=cutinWindSpeed;
            obj.cutoutWindSpeed=cutoutWindSpeed;
            obj.survivalWindSpeed=survivalWindSpeed;
            obj.rotorDiameter=rotorDiameter;
            obj.generatorVoltage=generatorVoltage;
            obj.efficiency=0.5926;
        end
        
        function windTableFiltered=filterWindData(obj,windTable,regexTimeUTCPattern)
            count=1;
            for i=1:1:height(windTable)
                disp(i);
                row=windTable{i,:};
                if(regexp(row(1),regexTimeUTCPattern))
                    windTableFiltered(count,:)=row;
                    count=count+1;
                end
            end
        end
        
        %Pass 1.2 kg/m^3 to air_density
        function Peol_kw_k=getOutputPower_k(obj,air_density,windspeed_k)
            for k=1:1:length(windspeed_k)
                if(windspeed_k(k) < obj.cutinWindSpeed || windspeed_k(k) > obj.cutoutWindSpeed)
                    windspeed_k(k)=0;
                end
            end
            sweptArea=pi*obj.rotorDiameter^2/4; %m2
            sweptArea_ft2=sweptArea*(3.28084)^2; %ft2
            air_density_lbpft3=air_density*0.062428; %lb/ft3
            windspeed_k_mph=windspeed_k*3600; %m/h
            Peol_kw_k=0.000133*(1/2)*(sweptArea_ft2)*(windspeed_k_mph).^3*air_density_lbpft3*obj.efficiency;
        end
        
        %Pass 0.34 to HelmannExponent
        %https://en.wikipedia.org/wiki/Wind_gradient
        function windspeed_k=rescaleWindSpeedByAltitude(obj,windspeed10m_k,altitude,...
            HelmannExponent)
            windspeed_k=windspeed10m_k*(altitude/10)^HelmannExponent;
        end
        
    end
end