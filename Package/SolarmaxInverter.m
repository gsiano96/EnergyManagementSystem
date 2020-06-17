classdef SolarmaxInverter
    properties
        Prel_k {mustBeNumeric} %Prel_k=Pin_k/Pindcmax
        efficiency_k {mustBeNumeric} %euro-efficiency
        Pindcmax {mustBeNumeric} %Nominal P
        Poutacmax {mustBeNumeric}
    end
    methods
        function obj = SolarmaxInverter(Prel_k,efficiency_k,Pindcmax,Poutacmax)
            obj.Prel_k=Prel_k;
            obj.efficiency_k=efficiency_k;
            obj.Pindcmax=Pindcmax;
            obj.Poutacmax=Poutacmax;
        end
        
        function [Pin_k,Pout_k]=getCharacteristicPout_Pin(obj)
            Pin_k=obj.Prel_k*obj.Pindcmax;
            Pout_k=Pin_k*obj.efficiency_k;
        end
        
        function Pinterpolated=interpolateInputPowerPoints(obj,Pq_k,method)
            % Get (x,y)
            Pinput_k,Poutput_k=getCharacteristicPout_Pin(obj);
            % Interpolate on (x,y) given xq. Returns y(xq)=yq
            Pinterpolated=interp1(Pinput_k,Poutput_k,Pq_k,method);
        end
        
        function Effinterpolated=interpolateInputRelativePower(obj,Prelq_k, method)
            Effinterpolated=interp1(obj.Prel_k,obj.efficiency_k,Prelq_k,method);
        end
        
        function Prel_k=getRelativePowers(obj,Pinput_k)
            Prel_k=Pinput_k/obj.Pindcmax;
        end
    end
end