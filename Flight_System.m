classdef Flight_System < handle
    %Flight_System handels architecture properties and thrust profiles
    
    properties
        Max_Capacity
        Peak_Power
        Peak_Power_Avalible
        
        Current_Capacity
        
        Energy_Dencity
        T_Profile
        T_Step

        Step_Up_Pofile
        Step_Down_Profile
        
        Motor_Power
    end
    
    methods
        function obj = Setup(obj,Aircraft)
            %Apply Mass Penalty to Thrust demand assuming steady level
            %flight to constant L/D
            Additional_Mass = obj.Max_Capacity/obj.Energy_Dencity;
            obj.T_Profile = obj.T_Profile + (Additional_Mass*9.81)/Aircraft.L_D_Ratio;
            obj.T_Step = obj.T_Step + (Additional_Mass*9.81)/Aircraft.L_D_Ratio;
            obj.Peak_Power_Avalible = obj.Peak_Power;
        end
        
        function obj = StorageChange(obj,E_Store,WS)
            obj.Current_Capacity = obj.Current_Capacity - E_Store;
            obj.Current_Capacity = min(obj.Current_Capacity,obj.Max_Capacity);
            obj.Current_Capacity = max(obj.Current_Capacity,0);
            if obj.Current_Capacity / WS.delta_T < obj.Peak_Power
                obj.Peak_Power_Avalible = obj.Current_Capacity / WS.delta_T;
            else
                obj.Peak_Power_Avalible = obj.Peak_Power;
            end
        end
    end
end

