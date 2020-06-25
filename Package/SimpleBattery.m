classdef SimpleBattery
    properties
        fullCapacity {mustBeNumeric}
        capacity {mustBeNumeric}
        dod {mustBeNumeric}
        Pmax {mustBeNumeric}
        bEfficiency {mustBeNumeric}
    end
    methods
        function obj = SimpleBattery(fullCapacity,dod,Pmax,bEfficiency)
            obj.fullCapacity=fullCapacity;
            obj.capacity=obj.fullCapacity;
            obj.dod=dod;
            obj.Pmax=Pmax;
            obj.bEfficiency=bEfficiency;
        end
        
        function [E,Presidual]=batteryEnergy_k(obj,k,Pin_k)
                    % Cut-off control
                    Presidual_k = ones(1440,4,3);
                    for i=1:1:length(Pin_k)
                        for j=1:1:4
                            for k=1:1:3
                                Pin_k(i,j,k) = Pin_k(i,j,k)*obj.bEfficiency;
                                if Pin_k(i,j,k) > obj.Pmax
                                    Presidual_k(i,j,k)=Pin_k(i,j,k)-obj.Pmax;
                                    Pin_k(i,j,k)=obj.Pmax;
                                end
                            end
                        end
                    end
                    
            % Energia scambiata 
            Ein_k=cumtrapz(k,Pin_k)+obj.capacity;

            E=Ein_k;
            Presidual=Presidual_k;
        end
    end
end