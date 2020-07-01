classdef SimpleBattery
    properties
        fullCapacity {mustBeNumeric}
        capacity {mustBeNumeric}
        dod {mustBeNumeric}
        Pmax {mustBeNumeric}
        Befficiency {mustBeNumeric}
    end
    methods
        function obj = SimpleBattery(fullCapacity, dod,Pmax,Befficiency)
            obj.fullCapacity=fullCapacity;
            obj.capacity=obj.fullCapacity;
            obj.dod=dod;
            obj.Pmax=Pmax;
            obj.Befficiency=Befficiency;
        end
        
        function [E,Presidual]=batteryEnergy_k(obj,Pin_k,P_load)
                    % Cut-off control
                    Presidual_k = zeros(1440,4,3);
                    for i=1:1:length(Pin_k)
                        for j=1:1:4
                            for k=1:1:3
                                Pin_k(i,j,k) = Pin_k(i,j,k)*obj.Befficiency;
                                if Pin_k(i,j,k) > P_load(i)
                                    Presidual_k(i,j,k)=Pin_k(i,j,k)-P_load(i);
                                    
                                end
                            end
                        end
                    end
                    
            % Energia scambiata 
            Ein_k = cumtrapz(0.0167,Presidual_k);
            for i=1:1:length(Ein_k)
                for j=1:1:4
                    for k=1:1:3
                        if (Ein_k(i,j,k)>obj.fullCapacity)
                            Ein_k(i,j,k)=obj.fullCapacity;
                        
                        end
                    end
                end
            end
                
            E=Ein_k;
            Presidual=Presidual_k;
        end
        
        function Eout_bat_k = getEoutBattery(obj,Eload_k,rendimentoInverterBatteria)
            Eout_bat_k=zeros(1440,4,3);
            for i=1:1:length(Eout_bat_k)
                for j=1:1:4
                    for k=1:1:3
                        %lato batteria
                        Eout_bat_k(i,j,k)=obj.capacity-Eload_k(i)/rendimentoInverterBatteria;
                        if ( Eout_bat_k(i,j,k)<0)
                            Eout_bat_k(i,j,k)=0;
                        end
                    end
                end
            end 
        end
        
    end
end