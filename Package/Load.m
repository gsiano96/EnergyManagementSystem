classdef Load
    properties
        k {mustBeNumeric} %Time axis (vector)
        Pload_k {mustBeNumeric} %AC power
    end
    methods
        function obj = Load(Pload_k)
            obj.Pload_k=Pload_k;
        end
        
        function Presidual_dc=residualPowerDC(obj,Pgen_dc_k,inverterEfficiency_k)
            Pload_dc_k=obj.Pload_k ./ inverterEfficiency_k;
            Presidual_dc=Pgen_dc_k-Pload_dc_k;
        end
        
        function Presidual_ac=residualPowerAC(obj,Pgen_dc_k,inverterEfficiency_k)
            Pgen_ac_k=Pgen_dc_k .* inverterEfficiency_k;
            Presidual_ac=Pgen_ac_k-obj.Pload_k;
        end
        
        function Eload_ac_k=getLoadEnergyAC(obj,initialLoadEnergy)
            Eload_ac_k=cumtrapz(obj.k,obj.Pload_k)+initialLoadEnergy;
        end
        
        function Eload_dc_k=getLoadEnergyDC(obj, initialLoadEnergyDC,inverterEfficiency_k)
            Pload_dc_k=obj.Pload_k ./ inverterEfficiency_k;
            Eload_dc_k=cumtrapz(obj.k,Pload_dc_k)+initialLoadEnergyDC;
        end
        
        function Eresidual_dc_k=getResidualEnergyDC(obj,Egen_dc_k,initialLoadEnergyDC,inverterEfficiency_k)
            Eload_dc_k=getLoadEnergyDC(obj,initialLoadEnergyDC,inverterEfficiency_k);
            Eresidual_dc_k=Egen_dc_k-Eload_dc_k;
        end
        
    end
end