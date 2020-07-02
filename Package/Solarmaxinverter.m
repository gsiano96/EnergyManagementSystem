classdef Solarmaxinverter
    properties
        Prel_k {mustBeNumeric} %Prel_k=Pin_k/Pindcmax
        efficiency_k {mustBeNumeric} %efficiency
        Pindcmax {mustBeNumeric} %nominal P DC
        Poutacmax {mustBeNumeric} %max P AC
        inputVoltageInterval {mustBeNumeric}
        outputVoltage {mustBeNumeric}
        phasesNumber {mustBeNumeric}
    end
    methods
        
        function obj = Solarmaxinverter(Prel_k,efficiency_k,Pindcmax,Poutacmax,...
                inputVoltageInterval, outputVoltageInterval, phasesNumber)
           
            obj.Prel_k=Prel_k;
            obj.efficiency_k=efficiency_k;
            obj.Pindcmax=Pindcmax;
            obj.Poutacmax=Poutacmax;
            obj.inputVoltageInterval=inputVoltageInterval;
            obj.outputVoltage=outputVoltageInterval;
            obj.phasesNumber=phasesNumber;
        end
        
        function [Pin_k,Pout_k]=getCharacteristicPout_Pin(obj,applyCutoff)
            
            Pin_k=obj.Prel_k*obj.Pindcmax;
            Pout_k=Pin_k.*obj.efficiency_k;
            if(applyCutoff)
                Pout_k(find(Pout_k > obj.Poutacmax))=obj.Poutacmax;
            end
        end
        
        function Pinterpolated=interpolateInputPowerPoints(obj,Pq_k,method)
            % Get (x,y)
            
            [Pinput_k,Poutput_k]=getCharacteristicPout_Pin(obj,'true');
            
            % Interpolate on (x,y) given xq. Returns y(xq)=yq
            Pinterpolated=interp1(Pinput_k,Poutput_k,Pq_k,method);
        end
        
        function eff_interpolated=interpolateInputRelativePower(obj,Prelq_k, method)
            eff_interpolated=interp1(obj.Prel_k,obj.efficiency_k,Prelq_k,method);
        end
        
        function Prel_k=getRelativePowers(obj,Pinput_k)
            Prel_k=Pinput_k./obj.Pindcmax;
        end
        
        function med_targetPrel=getMeanTarget(obj,Ppv_k_scaled,Pindcmax)
            targetPrel=zeros(1440,4,3);
            for i=1:1:length(targetPrel)
                for j=1:1:4
                    for k=1:1:3
                        targetPrel(i,j,k)=Ppv_k_scaled(i,j,k) / Pindcmax;
                    end
                    
                end
            end
            med_targetPrel = mean(targetPrel);
        end
        
        function max_targetPrel=getMaxTarget(obj,Ppv_k_scaled,Pindcmax)
            targetPrel=zeros(1440,4,3);
            for i=1:1:length(targetPrel)
                for j=1:1:4
                    for k=1:1:3
                        targetPrel(i,j,k)=Ppv_k_scaled(i,j,k) / Pindcmax;
                    end
                    
                end
            end
            max_targetPrel = max(targetPrel);
        end
    end
end
