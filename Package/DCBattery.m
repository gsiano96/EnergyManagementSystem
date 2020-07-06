classdef DCBattery
    properties
       
        capacity {mustBeNumeric}
        dod {mustBeNumeric}
        Pmax {mustBeNumeric}
        Befficiency {mustBeNumeric}
        
    end
    methods
        function obj = DCBattery(capacity, dod,Pmax,Befficiency)
           
            obj.capacity=capacity;
            obj.dod=dod;
            obj.Pmax=Pmax;
            obj.Befficiency=Befficiency;
           
        end
        
        %Presidual in questo caso deve essere Ppv_scaled
        function E=batteryEnergy_k(obj,Presidual_k)
            discharge_percentage=1-obj.dod;
            minimum_capacity=discharge_percentage*obj.capacity;
             Ebat_k=zeros(1440,4,3);
            for j=1:1:4
                for k=1:1:3
                    Ebat_k(1,j,k)=obj.capacity;
                    for i=2:1:length(Presidual_k)
                        
                        Ebat_k(i,j,k)=Ebat_k(i-1,j,k)+(Presidual_k(i,j,k)+ Presidual_k(i-1,j,k))*0.0167/2;
                        
                        %Cutoff control for charging phase
                        if( Ebat_k(i,j,k)> obj.capacity)
                            Ebat_k(i,j,k)=obj.capacity;
                        end
                        
                        %Cutoff control for discharging phase
                        if( Ebat_k(i,j,k) < minimum_capacity)
                            Ebat_k(i,j,k)=minimum_capacity;
                        end
                    end
                end
            end
             
            E=Ebat_k;
            
        end
        
        function time=getTimeToReload(obj,starting_energy,enel_average_power)
            %starting_energy + enel_average_power * time = capacity
            time=(obj.capacity-starting_energy)/enel_average_power;
        end
        
        function index=getLastStartingDiscargingTime(obj)
        end
        
        function P_bat= filterPower(obj,Presidual)
            % P_batteria
            Presidual_k = zeros(1440,4,3);
            for i=1:1:length(Presidual)
                for j=1:1:4
                    for k=1:1:3
                        if Presidual(i,j,k) > 0
                            Presidual_k(i,j,k) = Presidual(i,j,k)*obj.Befficiency;
                            %Presidual_k(i,j,k)=Pin_k(i,j,k)-P_load(i);
                        else
                            Presidual_k(i,j,k) = Presidual(i,j,k);
                        end
                    end
                end
            end
            P_bat=Presidual_k;
        end
        
        function [Pbat_carica,Pbat_scarica] = decouplePowerBattery(obj,Pbat)
            
            for i=1:1:length(Pbat)
                
                if Pbat(i) >= 0
                    Pbat_carica(i) = Pbat(i);
                    Pbat_scarica(i) = 0;
                    %Presidual_k(i,j,k)=Pin_k(i,j,k)-P_load(i);
                else
                    Pbat_carica(i) = 0;
                    Pbat_scarica(i) = -Pbat(i);
                end
            end
        end
                       
        
    end
end