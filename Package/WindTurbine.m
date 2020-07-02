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
        
        function windTableFiltered=filterWindData(windTable,regexTimeUTCPattern)
            count=1;
            windTableFiltered=zeros(8760,10);
            for i=1:1:height(windTable)
                row=windTable{i,:};
                if(regexp(row(1),regexTimeUTCPattern))
                    windTableFiltered(count,:)=row;
                    count=count+1;
                end
            end
        end
        
        %Pass 1.2 to air_density
        function Peol_k=getOutputPower_k(obj,air_density,windspeed_k)
            radius=obj.rotorDiameter / 2;
            Peol_k=(pi/2)*(radius)^2*(windspeed_k)^3*air_density*obj.efficiency;
        end
        
        %Pass 0.34 to HelmannExponent
        %https://en.wikipedia.org/wiki/Wind_gradient
        function windspeed_k=rescaleWindSpeedByAltitude(windspeed10m_k,altitude,...
            HelmannExponent)
            windspeed_k=windspeed10m_k*(altitude/10)^HelmannExponent;
        end
        
    end
end