classdef ACBattery
    properties
        fullCapacity {mustBeNumeric}
        capacity {mustBeNumeric}
        dod {mustBeNumeric}
        Pmax {mustBeNumeric}
        Befficiency {mustBeNumeric}
        InverterBatEff {mustBeNumeric}
    end
    methods
        function obj = ACBattery(fullCapacity, dod,Pmax,Befficiency,InverterBatEff)
            obj.fullCapacity=fullCapacity;
            obj.capacity=obj.fullCapacity;
            obj.dod=dod;
            obj.Pmax=Pmax;
            obj.Befficiency=Befficiency;
            obj.InverterBatEff=InverterBatEff;
        end
        
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
            time=(obj.capacity-starting_energy)/enel_average_power; %enel average power 50
        end
        
%         function index=getLastStartingDischargingTime(obj,Ebat)
%             for j=1:1:4
%                 for k=1:1:3
%                     target=Ebat(1,j,k);
%                     startindex=i;
%                     for i=2:1:length(Ebat)
%                         if (Ebat(i,j,k)<target) && target>0
%                             target=Ebat(i,j,k)
%                         
%         end
        
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
                            Presidual_k(i,j,k) = Presidual(i,j,k)/obj.InverterBatEff;
                        end
                    end
                end
            end
            P_bat=Presidual_k;
        end
        
        
        function Ebat_end_day = getEBatteryEndDay(obj,E_sist_res)
            Ebat_end_day=zeros(4,3);
            for k=1:1:length(E_sist_res)
                for i=1:1:4
                    for j=1:1:3
                        if (E_sist_res(k,i,j) > obj.capacity)
                            Ebat_end_day(i,j)=E_sist_res(1440,i,j)- (max(E_sist_res(:,i,j))-obj.capacity );
                        end
                    end
                end
            end
        end
        
    end
end