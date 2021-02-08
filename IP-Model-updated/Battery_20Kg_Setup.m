%% Genetic Algothirm Optimisation Trials
% Alex Pynn Individual Project 2020

% Script to run trial motors and 20Kg of batterys: Expected iridis run time = 6.5 hours

%% START OF USER INPUTS
%Genetic Algorithm Parameters
Generations = 10;
Members = 1000;
Probability_of_Mutation = 0.05;
%Baseline Aircraft parameters
Lift_Drag_Ratio = 8;
%Architecture
Storage_Power_Density = 200*3600;
Storage_Peak_Output = 100e3;
Stroage_Capacity = 14.4e6;
Motor_Power = 600e3;
%% END OF USER INPUTS

load('LowBPRFan.mat');
load('HPC01.mat');

%Store Aircraft Parameters
Baseline_Aircraft = Aircraft();
Baseline_Aircraft.L_D_Ratio = Lift_Drag_Ratio;

%Create Architecture
Architecture = Flight_System();
Architecture.Max_Capacity = Stroage_Capacity;
Architecture.Motor_Power = Motor_Power;
Run
Step
Architecture.T_Profile = T_Levels;
Architecture.T_Step = T_Step;
Architecture.Energy_Dencity = Storage_Power_Density;
Architecture.Peak_Power = Storage_Peak_Output;
Architecture.Setup(Baseline_Aircraft);

%Create Genetic Algorithm
GA = GeneticAlgorithm();
GA.Members = Members;
GA.Generations = Generations;
GA.Prob_Mutation = Probability_of_Mutation;
GA.initialise();

%Create Control instances
GA.Trials = ObjectArray(Members,Generations);

%Create first Generation 
for member = [1:1:Members]
    GA.Trials(member,1).Value.randfill();
end

%Run Generations

cost = zeros(GA.Members,GA.Generations);

for generation = [1:1:GA.Generations]
    
    Gen_Results = zeros(GA.Members,9);
generation
    Gen_cost = zeros(GA.Generations,2);
    
    parfor trial = [1:1:GA.Members]
        [fuel_mass,Transiant_Time] = Run_Trial(Architecture,GA.Trials(trial,generation).Value, Fan_Map, HPC_Map,Combustor,Bypass);
        [Ts_up,POS_up,Tp_up,Ts_down,POS_down,Tp_down] = Run_Step...
        (Architecture,GA.Trials(trial,generation).Value, Fan_Map, HPC_Map, Combustor,Bypass);
        Gen_Results(trial,:)= [trial,fuel_mass,Transiant_Time,Ts_up,POS_up,Tp_up,Ts_down,POS_down,Tp_down];
        cost(trial,generation) = POS_up + POS_down + 10*(Transiant_Time+Ts_up+Tp_up+Ts_down+Tp_down);
        Gen_cost(trial,:) = [cost(trial,generation),trial];
    end
    
    [~,fuel_ind] = min(Gen_Results(:,1));
    [~,TT_ind] = min(Gen_Results(:,2));
    [~,cost_ind] = min(cost(:,generation));
    
    Gen_cost = sort(Gen_cost);
    cost_ind_2 = Gen_cost(2,2);
    cost_ind_3 = Gen_cost(3,2);
    
    A = GA.Trials(fuel_ind,generation).Value;
    B = GA.Trials(TT_ind,generation).Value;
    C = GA.Trials(cost_ind,generation).Value;
    D = GA.Trials(cost_ind_2,generation).Value;
    E = GA.Trials(cost_ind_3,generation).Value;
    
    if generation ~= GA.Generations
        if generation > 4
            GA.Prob_Mutation = GA.Prob_Mutation*0.8;
        end
        GA.Trials(1,generation+1).Value = C;
        GA.Trials(2,generation+1).Value.avgfill(C, D);
        GA.Trials(3,generation+1).Value.avgfill(C, A);
        for member = [4:1:Members]
            Y = rand();
            if 0.2 > Y
                GA.Trials(member,generation+1).Value.nudgefill(C);
            elseif 0.75 > Y
                GA.Trials(member,generation+1).Value.mutate(C, GA.Prob_Mutation);
            elseif 0.85 > Y
                GA.Trials(member,generation+1).Value.breed(C,D);
            elseif 0.98 > Y
                GA.Trials(member,generation+1).Value.breed(A,B);
            else
                GA.Trials(member,generation+1).Value.breed(C,E);
            end
        end
    else
        name = strcat("Winner 20Kg - ",string(cost_ind));
        save(name,'C');
    end
end

save('20Kg-functions','cost');
save('20Kg-results','Gen_Results')
save('20Kg-whole','GA')