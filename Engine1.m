%% Shaft Load Simulation
% Script to setup engine components 

%% Engine Component Setup

% Controller
Control = controller();
Control.P = 3;
Control.I = 0.5;
Control.D = 0;

% Fan
Fan = Compressor();
Fan.MAP = Fan_Map;
Fan.mdot_DP = 120;
Fan.PR_DP = 4;
Fan.T0_DP = 290;
Fan.P0_DP = 1e5;
Fan.eff_DP = 0.92; 
Fan.Scale();

%Bypass
Bypass = Bypass();
Bypass.Pressure_Loss = 0.03;

% HPC
HPC = Compressor();
HPC.MAP = HPC_Map;
HPC.mdot_DP = 72;
HPC.PR_DP = 6;
HPC.T0_DP = 459.23;
HPC.P0_DP = 4.5e5;
HPC.eff_DP = 0.9;
HPC.N_corr_DP = 0.925; 
HPC.Scale();

% Combustion Chamber
Combustor = Combustor();
Combustor.WrootTonP = 1.15e-3;%9.59e-4;
Combustor.Pressure_Loss = 0.05;

% HPT
HPT = Choked_Turbine();
HPT.K_HP = 0.2;%0.1875;
HPT.Iso_efficency = 0.8;

% LPT
LPT = Unchoked_Turbine();
LPT.Iso_efficency = 0.85;

% HP Shaft
HP = Shaft();
HP.Inertia = 1.5;
HP.Friction = -1e2;
HP.N_design = 25000;
HP.N_Max = 27000;
HP.N_Idle = 0.7 *HP.N_Max;

% LP Shaft
LP = Shaft();
LP.Inertia = 9;
LP.Friction = -1e2;
LP.N_design = 12000;
LP.N_Max = 18000;