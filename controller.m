classdef controller < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        P
        I
        D
        
        Error
        Prop
        Inte
        Dirv
        sum_int
    end
    
    methods
        function SetUp(obj,WS)
            %Function to initialise arrays
            n = WS.total_sim_points;
            obj.Prop(1:n) = 0;
            obj.Dirv(1:n) = 0;
            obj.Inte(1:n) = 0;
            obj.Error(1:n) = 0;
            obj.sum_int(1:n) = 0;    
        end
        
        function delta_T4 = demand(obj,WS,NH_t,NH_demand)
            % Calculate burner exit temp. to bring spool speed error to 0
            i = WS.Sim_point;
            obj.Error(i+1) = NH_demand - NH_t;
            obj.Prop(i+1) = obj.Error(i+1);% error of proportional term
            obj.Dirv(i+1)  = (obj.Error(i+1) - obj.Error(i))/WS.delta_T; % derivative of the error
            obj.Inte(i+1)  = (obj.Error(i+1) + obj.Error(i))*WS.delta_T/2; % integration of the error
            obj.sum_int(i+1) = sum(obj.Inte(max(1,i-50):i)); % the sum of the integration of the error
    
            PID = obj.P*obj.Prop(i) + obj.I*obj.sum_int(i) +...
                obj.D*obj.Dirv(i);% the three PID terms
             delta_T4 = PID*0.005;
        end
        
        % delta_T7 added by MolniyaWaltz
        
        function delta_T7 = thrustdemand(obj, WS, Fg_t, Fg_demand)
            % Calculate afterburner exit temp. to bring thrust error to 0
            i = WS.Sim_point;
            obj.Error(i+1) = Fg_demand - Fg_t;
            
            obj.Prop(i+1) = obj.Error(i+1);
            obj.Dirv(i+1)  = (obj.Error(i+1) - obj.Error(i))/WS.delta_T; 
            obj.Inte(i+1)  = (obj.Error(i+1) + obj.Error(i))*WS.delta_T/2; 
            obj.sum_int(i+1) = sum(obj.Inte(max(1,i-50):i)); 
    
            PID = obj.P*obj.Prop(i) + obj.I*obj.sum_int(i) +...
                obj.D*obj.Dirv(i);
            delta_T7 = PID*0.005;            
            
            % Run_step uses: Fg_demand = Architecture.T_Step(WS.Sim_point);
        end
    end
end

