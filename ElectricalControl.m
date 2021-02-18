classdef ElectricalControl < handle
    %ElectricalControl is a object containing a neural network that
    %produces an control output
    
    properties
        L1
        L2
        L3
        L4
    end
    
    methods
%         function obj = randfill(obj)
%             %randfill randomly fills the wights for the branches in the
%             %layers with values between -1 and 1
%             obj.L1 = 2.*rand(5,6)-1;
%             obj.L2 = 2.*rand(4,5)-1;
%             obj.L3 = 2.*rand(3,4)-1;
%         end
%         
%         function obj = breed(obj,A,B)
%            %function that breeds to inputs
%             L1 = A.L1;
%             L2 = A.L2;
%             L3 = A.L3;
%             %Iterate though L1
%             for weight = [1:1:5*6]
%                 if 0.5>rand()
%                     L1(weight) = B.L1(weight);
%                 end
%             end
%             %Iterate though L2
%             for weight = [1:1:4*5]
%                 if 0.5>rand()
%                     L2(weight) = B.L2(weight);
%                 end
%             end
%             %Iterate though L3
%             for weight = [1:1:3*4]
%                 if 0.5>rand()
%                     L3(weight) = B.L3(weight);
%                 end
%             end
%             %Assign to network
%             obj.L1 = L1;
%             obj.L2 = L2;
%             obj.L3 = L3;
%         end
%         
%         function [OUTPUTS] = control(obj, INPUTS)
%             %control performs matrix operations to calculate the output
%             %from the neural network
%             L1_out = tanh(obj.L1*INPUTS);
%             L2_out = tanh(obj.L2*L1_out);
%             OUTPUTS = tanh(obj.L3*L2_out);
%             %Put output though softmax layer
%             softout = softmax([OUTPUTS(1:2)]);
%             OUTPUTS(1) = softout(1);
%             OUTPUTS(2) = softout(2);
%         end
%         
%         function obj = avgfill(obj, C1, C2)
%             %avgfill takes 2 networks and wieghts its self on there average
%             %branch weights
%             L1_A = C1.L1;
%             L2_A = C1.L2;
%             L3_A = C1.L3;
%             L1_B = C2.L1;
%             L2_B = C2.L2;
%             L3_B = C2.L3;
%             
%             obj.L1 = (L1_A+L1_B)/2;
%             obj.L2 = (L2_A+L2_B)/2;
%             obj.L3 = (L3_A+L3_B)/2;           
%         end
%         
%         function obj = nudgefill(obj, C)
%             %Function to make delta changes to network C
%             L1 = C.L1;
%             L2 = C.L2;
%             L3 = C.L3;
%             L1_nudge = 0.2.*rand(5,6)-0.1;
%             L2_nudge = 0.2.*rand(4,5)-0.1;
%             L3_nudge = 0.2.*rand(3,4)-0.1;
%             obj.L1 = L1 + L1_nudge;
%             obj.L2 = L2 + L2_nudge;
%             obj.L3 = L3 + L3_nudge;
%         end
%         
%         function obj = mutate(obj, C, Prob)
%             %Function to mutate weights
%             L1 = C.L1;
%             L2 = C.L2;
%             L3 = C.L3;
%             %Iterate though L1
%             for weight = [1:1:5*6]
%                 if Prob>rand()
%                     L1(weight) = 2.*rand()-1;
%                 end
%             end
%             %Iterate though L2
%             for weight = [1:1:4*5]
%                 if Prob>rand()
%                     L2(weight) = 2.*rand()-1;
%                 end
%             end
%             %Iterate though L3
%             for weight = [1:1:3*4]
%                 if Prob>rand()
%                     L3(weight) = 2.*rand()-1;
%                 end
%             end
%             %Assign to network
%             obj.L1 = L1;
%             obj.L2 = L2;
%             obj.L3 = L3;
%         end


        function obj = randfill(obj)
            %randfill randomly fills the wights for the branches in the
            %layers with values between -1 and 1
            obj.L1 = 2.*rand(12,6)-1;
            obj.L2 = 2.*rand(10,12)-1;
            obj.L3 = 2.*rand(3,10)-1;
            obj.L4 = 2.*rand(3,3)-1;
        end
        
        function obj = breed(obj,A,B)
           %function that breeds to inputs
            L1 = A.L1;
            L2 = A.L2;
            L3 = A.L3;
            L4 = A.L4;
            %Iterate though L1
            for weight = [1:1:numel(L1)]
                if 0.5>rand()
                    L1(weight) = B.L1(weight);
                end
            end
            %Iterate though L2
            for weight = [1:1:numel(L2)]
                if 0.5>rand()
                    L2(weight) = B.L2(weight);
                end
            end
            %Iterate though L3
            for weight = [1:1:numel(L3)]
                if 0.5>rand()
                    L3(weight) = B.L3(weight);
                end
            end
            %Iterate though L4
            for weight = [1:1:numel(L4)]
                if 0.5>rand()
                    L4(weight) = B.L4(weight);
                end
            end
            %Assign to network
            obj.L1 = L1;
            obj.L2 = L2;
            obj.L3 = L3;
            obj.L4 = L4;
        end
        
        function [OUTPUTS] = control(obj, INPUTS)
            %control performs matrix operations to calculate the output
            %from the neural network
            L1_out = tanh(obj.L1*INPUTS);
            L2_out = tanh(obj.L2*L1_out);
            L3_out = tanh(obj.L3*L2_out);
            OUTPUTS = tanh(obj.L4*L3_out);
            %Put output though softmax layer
            softout = softmax([OUTPUTS(1:2)]);
            OUTPUTS(1) = softout(1);
            OUTPUTS(2) = softout(2);
        end
        
        function obj = avgfill(obj, C1, C2)
            %avgfill takes 2 networks and wieghts its self on there average
            %branch weights
            L1_A = C1.L1;
            L2_A = C1.L2;
            L3_A = C1.L3;
            L4_A = C1.L4;
            L1_B = C2.L1;
            L2_B = C2.L2;
            L3_B = C2.L3;
            L4_B = C2.L4;
            obj.L1 = (L1_A+L1_B)/2;
            obj.L2 = (L2_A+L2_B)/2;
            obj.L3 = (L3_A+L3_B)/2;
            obj.L4 = (L4_A+L4_B)/2;
        end
        
        function obj = nudgefill(obj, C)
            %Function to make delta changes to network C
            L1 = C.L1;
            L2 = C.L2;
            L3 = C.L3;
            L4 = C.L4;
            L1_nudge = 0.1.*rand(12,6)-0.05;
            L2_nudge = 0.1.*rand(10,12)-0.05;
            L3_nudge = 0.1.*rand(3,10)-0.05;
            L4_nudge = 0.1.*rand(3,3)-0.05;
            obj.L1 = L1 + L1_nudge;
            obj.L2 = L2 + L2_nudge;
            obj.L3 = L3 + L3_nudge;
            obj.L4 = L4 + L4_nudge;
        end
        
        function obj = mutate(obj, C, Prob)
            %Function to mutate weights
            L1 = C.L1;
            L2 = C.L2;
            L3 = C.L3;
            L4 = C.L4;
            %Iterate though L1
            for weight = [1:1:numel(L1)]
                if Prob>rand()
                    L1(weight) = 2.*rand()-1;
                end
            end
            %Iterate though L2
            for weight = [1:1:numel(L2)]
                if Prob>rand()
                    L2(weight) = 2.*rand()-1;
                end
            end
            %Iterate though L3
            for weight = [1:1:numel(L3)]
                if Prob>rand()
                    L3(weight) = 2.*rand()-1;
                end
            end
            %Iterate though L4
            for weight = [1:1:numel(L4)]
                if Prob>rand()
                    L4(weight) = 2.*rand()-1;
                end
            end
            %Assign to network
            obj.L1 = L1;
            obj.L2 = L2;
            obj.L3 = L3;
            obj.L4 = L4;
        end
    end
end

