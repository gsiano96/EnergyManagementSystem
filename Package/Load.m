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
        
        function E_tot_system=getEsystem(obj,Eload_k,Epv_res_k,Eout_batt_inverter_k)
            Etot_k=zeros(1440,4,3);
            for i=1:1:length(Etot_k)
                for j=1:1:4
                    for z=1:1:3
                        if(Eload_k(i) <= Epv_res_k(i,j,z))
                            Etot_k(i,j,z) = Epv_res_k(i,j,z);
                        elseif(Eload_k(i) > Epv_res_k(i,j,z) && not(Eout_batt_inverter_k(i) == 0))
                            Etot_k(i,j,z) = Eout_batt_inverter_k(i);
                        end
                    end
                end
            end
            E_tot_system = Etot_k;
        end
        
    end
end