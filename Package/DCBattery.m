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
        
        function index=getLastStartingDiscargingTime(obj)
        end
        
        function P_bat= filterPower(obj,Presidual) %TODO
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
                    Pbat_scarica(i) = - Pbat(i);
                end
            end
        end
        
    %Aprile Soleggiato
        function hour_max_battery_1_1 = getHourMaxBattery1_1(obj,Ebat_k,enel_average_power,hours)
            for i=1:1:length(Ebat_k)
                for j=1:1:4
                    for k=1:1:3
                        ore_di_ricarica(i,j,k) = (obj.capacity - Ebat_k(i,j,k))/enel_average_power;
                    end
                end
            end
            ora_dell_ore_di_ricarica_1_1 = [hours,ore_di_ricarica(:,1,1)];
            for i=1:1:length(Ebat_k)
                if(ore_di_ricarica(i,1,1)+ ora_dell_ore_di_ricarica_1_1(i,1) >= 23.98 & ore_di_ricarica(i,1,1)+ ora_dell_ore_di_ricarica_1_1(i,1) <= 24)
                    %scarica la batteria
                    a1 = ora_dell_ore_di_ricarica_1_1(i,1);
                end
            end
             hour_max_battery_1_1 = timeofday(datetime(string(datestr(a1/24,'HH:MM')) ,'InputFormat','HH:mm'));
        end
        
        %Aprile Nuvoloso
        function hour_max_battery_1_2 = getHourMaxBattery1_2(obj,Ebat_k,enel_average_power,hours)
            for i=1:1:length(Ebat_k)
                for j=1:1:4
                    for k=1:1:3
                        ore_di_ricarica(i,j,k) = (obj.capacity - Ebat_k(i,j,k))/enel_average_power;
                    end
                end
            end
            ora_dell_ore_di_ricarica_1_2 = [hours,ore_di_ricarica(:,1,2)];
            for i=1:1:length(Ebat_k)
                if(ore_di_ricarica(i,1,2)+ ora_dell_ore_di_ricarica_1_2(i,1) >= 23.98 & ore_di_ricarica(i,1,2)+ ora_dell_ore_di_ricarica_1_2(i,1) <= 24)
                    %scarica la batteria
                    a2 = ora_dell_ore_di_ricarica_1_2(i,1);
                end
            end
             hour_max_battery_1_2 = timeofday(datetime(string(datestr(a2/24,'HH:MM')) ,'InputFormat','HH:mm'));
        end
        
         %Aprile Caso Peggiore
        function hour_max_battery_1_3 = getHourMaxBattery1_3(obj,Ebat_k,enel_average_power,hours)
            for i=1:1:length(Ebat_k)
                for j=1:1:4
                    for k=1:1:3
                        ore_di_ricarica(i,j,k) = (obj.capacity - Ebat_k(i,j,k))/enel_average_power;
                    end
                end
            end
            ora_dell_ore_di_ricarica_1_3 = [hours,ore_di_ricarica(:,1,3)];
            for i=1:1:length(Ebat_k)
                if(ore_di_ricarica(i,1,3)+ ora_dell_ore_di_ricarica_1_3(i,1) >= 23.98 & ore_di_ricarica(i,1,3)+ ora_dell_ore_di_ricarica_1_3(i,1) <= 24)
                    %scarica la batteria
                    a3 = ora_dell_ore_di_ricarica_1_3(i,1);
                end
            end
             hour_max_battery_1_3 = timeofday(datetime(string(datestr(a3/24,'HH:MM')) ,'InputFormat','HH:mm'));
        end
        
         %Agosto Soleggiato
        function hour_max_battery_2_1 = getHourMaxBattery2_1(obj,Ebat_k,enel_average_power,hours)
            for i=1:1:length(Ebat_k)
                for j=1:1:4
                    for k=1:1:3
                        ore_di_ricarica(i,j,k) = (obj.capacity - Ebat_k(i,j,k))/enel_average_power;
                    end
                end
            end
            ora_dell_ore_di_ricarica_2_1 = [hours,ore_di_ricarica(:,2,1)];
            for i=1:1:length(Ebat_k)
                if(ore_di_ricarica(i,2,1)+ ora_dell_ore_di_ricarica_2_1(i,1) >= 23.98 & ore_di_ricarica(i,2,1)+ ora_dell_ore_di_ricarica_2_1(i,1) <= 24)
                    %scarica la batteria
                    a1 = ora_dell_ore_di_ricarica_2_1(i,1);
                end
            end
             hour_max_battery_2_1 = timeofday(datetime(string(datestr(a1/24,'HH:MM')) ,'InputFormat','HH:mm'));
        end
        
        %Agosto Nuvoloso
        function hour_max_battery_2_2 = getHourMaxBattery2_2(obj,Ebat_k,enel_average_power,hours)
            for i=1:1:length(Ebat_k)
                for j=1:1:4
                    for k=1:1:3
                        ore_di_ricarica(i,j,k) = (obj.capacity - Ebat_k(i,j,k))/enel_average_power;
                    end
                end
            end
            ora_dell_ore_di_ricarica_2_2 = [hours,ore_di_ricarica(:,2,2)];
            for i=1:1:length(Ebat_k)
                if(ore_di_ricarica(i,2,2)+ ora_dell_ore_di_ricarica_2_2(i,1) >= 23.98 & ore_di_ricarica(i,2,2)+ ora_dell_ore_di_ricarica_2_2(i,1) <= 24)
                    %scarica la batteria
                    a2 = ora_dell_ore_di_ricarica_2_2(i,1);
                end
            end
             hour_max_battery_2_2 = timeofday(datetime(string(datestr(a2/24,'HH:MM')) ,'InputFormat','HH:mm'));
        end
        
         %Agosto Caso Peggiore
        function hour_max_battery_2_3 = getHourMaxBattery2_3(obj,Ebat_k,enel_average_power,hours)
            for i=1:1:length(Ebat_k)
                for j=1:1:4
                    for k=1:1:3
                        ore_di_ricarica(i,j,k) = (obj.capacity - Ebat_k(i,j,k))/enel_average_power;
                    end
                end
            end
            ora_dell_ore_di_ricarica_2_3 = [hours,ore_di_ricarica(:,2,3)];
            for i=1:1:length(Ebat_k)
                if(ore_di_ricarica(i,2,3)+ ora_dell_ore_di_ricarica_2_3(i,1) >= 23.98 & ore_di_ricarica(i,2,3)+ ora_dell_ore_di_ricarica_2_3(i,1) <= 24)
                    %scarica la batteria
                    a3 = ora_dell_ore_di_ricarica_2_3(i,1);
                end
            end
             hour_max_battery_2_3 = timeofday(datetime(string(datestr(a3/24,'HH:MM')) ,'InputFormat','HH:mm'));
        end
        
        %Ottobre Soleggiato
        function hour_max_battery_3_1 = getHourMaxBattery3_1(obj,Ebat_k,enel_average_power,hours)
            for i=1:1:length(Ebat_k)
                for j=1:1:4
                    for k=1:1:3
                        ore_di_ricarica(i,j,k) = (obj.capacity - Ebat_k(i,j,k))/enel_average_power;
                    end
                end
            end
            ora_dell_ore_di_ricarica_3_1 = [hours,ore_di_ricarica(:,3,1)];
            for i=1:1:length(Ebat_k)
                if(ore_di_ricarica(i,3,1)+ ora_dell_ore_di_ricarica_3_1(i,1) >= 23.98 & ore_di_ricarica(i,3,1)+ ora_dell_ore_di_ricarica_3_1(i,1) <= 24)
                    %scarica la batteria
                    a1 = ora_dell_ore_di_ricarica_3_1(i,1);
                end
            end
             hour_max_battery_3_1 = timeofday(datetime(string(datestr(a1/24,'HH:MM')) ,'InputFormat','HH:mm'));
        end
        
        %Ottobre Nuvoloso
        function hour_max_battery_3_2 = getHourMaxBattery3_2(obj,Ebat_k,enel_average_power,hours)
            for i=1:1:length(Ebat_k)
                for j=1:1:4
                    for k=1:1:3
                        ore_di_ricarica(i,j,k) = (obj.capacity - Ebat_k(i,j,k))/enel_average_power;
                    end
                end
            end
            ora_dell_ore_di_ricarica_3_2 = [hours,ore_di_ricarica(:,3,2)];
            for i=1:1:length(Ebat_k)
                if(ore_di_ricarica(i,3,2)+ ora_dell_ore_di_ricarica_3_2(i,1) >= 23.98 & ore_di_ricarica(i,3,2)+ ora_dell_ore_di_ricarica_3_2(i,1) <= 24)
                    %scarica la batteria
                    a2 = ora_dell_ore_di_ricarica_3_2(i,1);
                end
            end
             hour_max_battery_3_2 = timeofday(datetime(string(datestr(a2/24,'HH:MM')) ,'InputFormat','HH:mm'));
        end
        
         %Ottobre Caso Peggiore
        function hour_max_battery_3_3 = getHourMaxBattery3_3(obj,Ebat_k,enel_average_power,hours)
            for i=1:1:length(Ebat_k)
                for j=1:1:4
                    for k=1:1:3
                        ore_di_ricarica(i,j,k) = (obj.capacity - Ebat_k(i,j,k))/enel_average_power;
                    end
                end
            end
            ora_dell_ore_di_ricarica_3_3 = [hours,ore_di_ricarica(:,1,3)];
            for i=1:1:length(Ebat_k)
                if(ore_di_ricarica(i,3,3)+ ora_dell_ore_di_ricarica_3_3(i,1) >= 23.98 & ore_di_ricarica(i,3,3)+ ora_dell_ore_di_ricarica_3_3(i,1) <= 24)
                    %scarica la batteria
                    a3 = ora_dell_ore_di_ricarica_3_3(i,1);
                end
            end
             hour_max_battery_3_3 = timeofday(datetime(string(datestr(a3/24,'HH:MM')) ,'InputFormat','HH:mm'));
        end
        
        %Dicembre Soleggiato
        function hour_max_battery_4_1 = getHourMaxBattery4_1(obj,Ebat_k,enel_average_power,hours)
            for i=1:1:length(Ebat_k)
                for j=1:1:4
                    for k=1:1:3
                        ore_di_ricarica(i,j,k) = (obj.capacity - Ebat_k(i,j,k))/enel_average_power;
                    end
                end
            end
            ora_dell_ore_di_ricarica_4_1 = [hours,ore_di_ricarica(:,4,1)];
            for i=1:1:length(Ebat_k)
                if(ore_di_ricarica(i,4,1)+ ora_dell_ore_di_ricarica_4_1(i,1) >= 23.98 & ore_di_ricarica(i,4,1)+ ora_dell_ore_di_ricarica_4_1(i,1) <= 24)
                    %scarica la batteria
                    a1 = ora_dell_ore_di_ricarica_4_1(i,1);
                end
            end
             hour_max_battery_4_1 = timeofday(datetime(string(datestr(a1/24,'HH:MM')) ,'InputFormat','HH:mm'));
        end
        
        %Dicembre Nuvoloso
        function hour_max_battery_4_2 = getHourMaxBattery4_2(obj,Ebat_k,enel_average_power,hours)
            for i=1:1:length(Ebat_k)
                for j=1:1:4
                    for k=1:1:3
                        ore_di_ricarica(i,j,k) = (obj.capacity - Ebat_k(i,j,k))/enel_average_power;
                    end
                end
            end
            ora_dell_ore_di_ricarica_4_2 = [hours,ore_di_ricarica(:,4,2)];
            for i=1:1:length(Ebat_k)
                if(ore_di_ricarica(i,4,2)+ ora_dell_ore_di_ricarica_4_2(i,1) >= 23.98 & ore_di_ricarica(i,4,2)+ ora_dell_ore_di_ricarica_4_2(i,1) <= 24)
                    %scarica la batteria
                    a2 = ora_dell_ore_di_ricarica_4_2(i,1);
                end
            end
             hour_max_battery_4_2 = timeofday(datetime(string(datestr(a2/24,'HH:MM')) ,'InputFormat','HH:mm'));
        end
        
         %Dicembre Caso Peggiore
        function hour_max_battery_4_3 = getHourMaxBattery4_3(obj,Ebat_k,enel_average_power,hours)
            for i=1:1:length(Ebat_k)
                for j=1:1:4
                    for k=1:1:3
                        ore_di_ricarica(i,j,k) = (obj.capacity - Ebat_k(i,j,k))/enel_average_power;
                    end
                end
            end
            ora_dell_ore_di_ricarica_4_3 = [hours,ore_di_ricarica(:,4,3)];
            for i=1:1:length(Ebat_k)
                if(ore_di_ricarica(i,4,3)+ ora_dell_ore_di_ricarica_4_3(i,1) >= 23.98 & ore_di_ricarica(i,4,3)+ ora_dell_ore_di_ricarica_4_3(i,1) <= 24)
                    %scarica la batteria
                    a3 = ora_dell_ore_di_ricarica_4_3(i,1);
                end
            end
             hour_max_battery_4_3 = timeofday(datetime(string(datestr(a3/24,'HH:MM')) ,'InputFormat','HH:mm'));
        end

        

    end
end