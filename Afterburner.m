classdef Afterburner
    
    properties
        IsActive
        WrootTonP
        Pressure_Loss
        Nozzle_Area
    end
    
    methods
        function [P0] = SetP7(obj,mdot,T7)
            P0 = (mdot*T7^0.5)/obj.WrootTonP;
            % Must change to account for nozzle area     
        end
        function [P0] = Flow(obj,P0_in)
            P0 = P0_in * (1 + obj.Pressure_Loss);
        end
    end
end

