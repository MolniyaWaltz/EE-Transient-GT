classdef Scenario < handle
    %Scenario class builds and stores details of engine conditions
    
    properties
        Parameters
        User_Points
        Point_Scenario
        Step_Points
        Step_Scenario
    end
    
    methods
        function obj = Points_fill(obj, WS, HP)
            % Converts User points in to a form that the simulation can
            % understand
            % [Sim_point, Sim_time, NH_Demand, P02, T02]
            total_sim_points = WS.Sim_time/WS.delta_T + 1;
            Point_Scenario = obj.Point_Scenario;
            User_Points = obj.User_Points;
            
            HP_Max = HP.N_Max;
            HP_Idle = HP.N_Idle;
            
            for sim_point = [1:1:total_sim_points]
                Point_Scenario(sim_point,1) = (sim_point-1);
                Point_Scenario(sim_point,2) = (sim_point-1) * WS.delta_T;
                for user_point = [1:1:size(User_Points,1)]
                    %Point_Scenario(sim_point,2)
                    %User_Points(user_point,1)
                    if Point_Scenario(sim_point,2) == User_Points(user_point,1)
                        T_dem = User_Points(user_point,2);
                        HP_Demand = interp1([100,0],[HP_Max,HP_Idle],T_dem);
                        Point_Scenario(sim_point,3) = HP_Demand;
                        Point_Scenario(sim_point,4) = User_Points(user_point,3);
                        Point_Scenario(sim_point,5) = User_Points(user_point,4);
                    end
                end
            end
            Point_Scenario(Point_Scenario == 0) = NaN;
            obj.Point_Scenario = fillmissing(Point_Scenario,'linear','SamplePoints',[1:1:total_sim_points]);
        end
        
        function obj = Step_fill(obj, WS, HP)
            % Converts User points in to a form that the simulation can
            % understand
            % [Sim_point, Sim_time, NH_Demand, P02, T02]
            total_sim_points = WS.Step_time/WS.delta_T + 1;
            Point_Scenario = obj.Step_Scenario;
            User_Points = obj.Step_Points;
            
            HP_Max = HP.N_Max;
            HP_Idle = HP.N_Idle;
            
            for sim_point = [1:1:total_sim_points]
                Point_Scenario(sim_point,1) = (sim_point-1);
                Point_Scenario(sim_point,2) = (sim_point-1) * WS.delta_T;
                for user_point = [1:1:size(User_Points,1)]
                    %Point_Scenario(sim_point,2)
                    %User_Points(user_point,1)
                    if Point_Scenario(sim_point,2) == User_Points(user_point,1)
                        T_dem = User_Points(user_point,2);
                        HP_Demand = interp1([100,0],[HP_Max,HP_Idle],T_dem);
                        Point_Scenario(sim_point,3) = HP_Demand;
                        Point_Scenario(sim_point,4) = User_Points(user_point,3);
                        Point_Scenario(sim_point,5) = User_Points(user_point,4);
                    end
                end
            end
            Point_Scenario(Point_Scenario == 0) = NaN;
            obj.Step_Scenario = fillmissing(Point_Scenario,'linear','SamplePoints',[1:1:total_sim_points]);
        end
        
    end
end

