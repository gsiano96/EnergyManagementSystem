classdef SimpleBattery
    properties
        fullCapacity {mustBeNumeric}
        capacity {mustBeNumeric}
        dod {mustBeNumeric}
        Pmax {mustBeNumeric}
    end
    methods
        function obj = SimpleBattery(fullCapacity,dod,Pmax)
            obj.fullCapacity=fullCapacity;
            obj.capacity=obj.fullCapacity;
            obj.dod=dod;
            obj.Pmax=Pmax;
        end
        
        function [E,Presidual]=batteryEnergy_k(obj,k,Pin_k)
            % Cut-off control
            for i=1:1:length(Pin_k)
                if Pin_k(i) > obj.Pmax
                    Presidual_k(i)=Pin_k(i)-Pmax;
                    Pin_k(i)=Pmax;
                end
            end
            % Energy calculation
            Ein_k=cumtrapz(k,Pin_k)+obj.capacity;
            
            E=Ein_k;
            Presidual=Presidual_k;
        end
    end
end