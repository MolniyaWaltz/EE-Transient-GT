classdef Compressor < handle
    %Compressor object
    
    properties
        MAP
        
        mdot_DP
        PR_DP
        T0_DP
        P0_DP
        eff_DP
        
        f_n_RNI = 0.99;
        f_w_RNI = 0.995;
        
        f_mdot
        f_eff
        f_PR
        
        beta_DP = 0.5;
        N_corr_DP = 1; 
    end
    
    methods
        function Scale(obj)
           %% Function to calculate the scaling factors for the map
           % Look up parameters at the unscaled design point
           [unscaled_isentropic_efficency, unscaled_Corrected_massflow,...
               unscaled_PR] = Compressor_Map_beta(obj.MAP,obj.N_corr_DP,...
               obj.beta_DP);
           % Calculate scaling factors
           obj.f_mdot = obj.mdot_DP/(unscaled_Corrected_massflow *...
               obj.f_w_RNI);
           obj.f_eff = obj.eff_DP/(unscaled_isentropic_efficency *...
               obj.f_n_RNI);
           obj.f_PR = (obj.PR_DP - 1)/(unscaled_PR - 1);
        end
        
        function beta = beta_ID(obj,N_Corrected,PR)
            %% Function to look up the current operating beta line
            % Scale the PR down to the map for reading
            PR = ((PR)/obj.f_PR);
            % Look up beta value
            beta = get_beta(obj.MAP,N_Corrected,PR);
        end 
        
        function mdot = Massflow(obj,NH_Normal,beta)
            %% Function to read the massflow from the compressor map
            [~, unscaled_Corrected_massflow,...
               ~] = Compressor_Map_beta(obj.MAP,NH_Normal,...
               beta);
           mdot = unscaled_Corrected_massflow * obj.f_mdot;
        end
        
        function eff = efficency(obj,NH_Normal,beta)
            %% Function to look up the effiecency of the component
            [unscaled_isentropic_efficency, ~,...
               ~] = Compressor_Map_beta(obj.MAP,NH_Normal,...
               beta);
           eff = unscaled_isentropic_efficency * obj.f_eff;
        end
        
        function PR = PR(obj,NL_Normal,beta)
           [~, ~,...
               unscaled_PR] = Compressor_Map_beta(obj.MAP,NL_Normal,...
              beta);
          PR = unscaled_PR * obj.f_PR;
        end
      
        function [eff,mf,PR] = Lookup(obj,NL_Normal,beta)
           [unscaled_isentropic_efficency, unscaled_Corrected_massflow,...
               unscaled_PR] = Compressor_Map_beta(obj.MAP,NL_Normal,...
               beta);
           eff = unscaled_isentropic_efficency* obj.f_eff;
           mf = unscaled_Corrected_massflow * obj.f_mdot;
           PR = unscaled_PR * obj.f_PR;
        end
        
    end
end

