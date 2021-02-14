classdef Combustor
    
    properties
        WrootTonP
        Pressure_Loss
    end
    
    methods
        function [P0] = SetP4(obj,mdot,T4)
            P0 = (mdot*T4^0.5)/obj.WrootTonP;
        end
        function [P0] = Flow(obj,P0_in)
            P0 = P0_in * (1 + obj.Pressure_Loss);
        end
    end
end

