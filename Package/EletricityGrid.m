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
        
    end
end