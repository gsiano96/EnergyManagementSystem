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
                        
                        Ebat_k(i,j,k)=Ebat_k(i-1,j,k)+(Presidual_k(i,j,k)+ Presidual_k(i-1,j,k)) * 0.0167/2;
                        
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
        
        function time_charging=getTimeToReload(obj,enel_average_power,Ebat_k) %TODO
            for i = 1:1:4
                for j = 1:1:3
                    %starting_energy + enel_average_power * time = capacity
                    ending_energy(i,j) = Ebat_k(1440,i,j);
                    time(i,j)=(obj.capacity - ending_energy(i,j))/enel_average_power; %enel average power 50
                    time_charging(i,j) = timeofday(datetime(string(datestr(time(i,j)/24,'HH:MM')) ,'InputFormat','HH:mm'));
                end
            end
        end
        
        
        
        function Pbat_k= filterPower(obj,Pinput)
            % P_batteria
            Pbat_k = zeros(1440,4,3);
            for i=1:1:length(Pinput)
                for j=1:1:4
                    for k=1:1:3
                        if Pinput(i,j,k) > 0
                            Pbat_k(i,j,k) = Pinput(i,j,k)*obj.Befficiency;
                        else
                            Pbat_k(i,j,k) = Pinput(i,j,k)*obj.Befficiency; %TODO
                        end
                    end
                end
            end
        end
        
        function [Pbat_carica,Pbat_scarica] = decouplePowerBattery(obj,Pbat)
            for i=1:1:length(Pbat)
                if Pbat(i) >= 0
                    Pbat_carica(i) = Pbat(i);
                    Pbat_scarica(i) = 0;
                else
                    Pbat_carica(i) = 0;
                    Pbat_scarica(i) = - Pbat(i);
                end
            end
        end
        
        function hour_max_battery = getHourMaxBattery(obj,Ebat_k,enel_average_power,hours,x,y)
            for i=1:1:length(Ebat_k)
                for j=1:1:4
                    for k=1:1:3
                        ore_di_ricarica(i,j,k) = (obj.capacity - Ebat_k(i,j,k))/enel_average_power;
                    end
                end
            end
            ora_dell_ore_di_ricarica_1_1 = [hours,ore_di_ricarica(:,x,y)];
            for i=1:1:length(Ebat_k)
                if(ore_di_ricarica(i,x,y)+ ora_dell_ore_di_ricarica_1_1(i,1) >= 23.97 & ore_di_ricarica(i,x,y)+ ora_dell_ore_di_ricarica_1_1(i,1) <= 24)
                    %scarica la batteria
                    a1 = ora_dell_ore_di_ricarica_1_1(i,1);
                end
            end
            hour_max_battery= timeofday(datetime(string(datestr(a1/24,'HH:MM')) ,'InputFormat','HH:mm'));
        end
        

    end
end