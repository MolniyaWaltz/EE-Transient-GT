%% Genetic Algothirm Optimisation

% Alex Pynn 2020

%% START OF USER INPUTS
%Genetic Algorithm Parameters
Generations = 5;
Members = 5;
Probability_of_Mutation = 0.05;
%Baseline Aircraft parameters
Lift_Drag_Ratio = 8;
%Architecture
Storage_Power_Density = 200*3600;
Storage_Peak_Output = 100e3;
Storage_Capacity = 0;
Motor_Power = 600e3;
%% END OF USER INPUTS

%Store Aircraft Parameters
Baseline_Aircraft = Aircraft();
Baseline_Aircraft.L_D_Ratio = Lift_Drag_Ratio;

%Create Architecture
Architecture = Flight_System();
Architecture.Max_Capacity = Storage_Capacity;
Architecture.Motor_Power = Motor_Power;
Run
Step
Architecture.T_Profile = T_Levels;
Architecture.T_Step = T_Step;
Architecture.Energy_Dencity = Storage_Power_Density;
Architecture.Peak_Power = Storage_Peak_Output;
Architecture.Setup(Baseline_Aircraft);

[fuel_mass,Transiant_Time] = Run_Read(Architecture,C, Fan_Map, HPC_Map,Combustor,Bypass,Afterburner)
[Ts_up,POS_up,Tp_up,Ts_down,POS_down,Tp_down] = Run_Step...
        (Architecture,C, Fan_Map, HPC_Map, Combustor,Bypass, Afterburner)
cost = fuel_mass + POS_up + POS_down + 10*(Transiant_Time+Ts_up+Tp_up+Ts_down+Tp_down)