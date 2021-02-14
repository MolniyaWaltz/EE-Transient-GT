function [fuel_mass,Transiant_Time] = Run_Read(Architecture,E_Control, Fan_Map, HPC_Map, Combustor,Bypass)
%% Function to run a mission Profile under the control principles of
%% E_Control

%Track behavior
PS=[];
PHP=[];
PLP=[];

%Set the current storage capacity to its maximum
Architecture.Current_Capacity = Architecture.Max_Capacity;

%Set initial parameters to arbatery initail values
P02_t = 0;
T02_t = 0;
T03 = 0;
NHdot = 0;
NLdot = 0;
Prev_EHP=0;
Prev_ELP=0;
W_HPelec = 0;
W_LPelec = 0;
W_HPC=99999999999;
transpoint=0;
%Set t=0 thrust target
Fg = Architecture.T_Profile(1);

%% Load Simulation workspace
% Enter script of simulations workspace below
Engine1
simulation_setup

%% Run simulation
skipped = 0;
% Loop though time points
for t = [WS.delta_T:WS.delta_T:WS.Sim_time]
    %Step simulation point
    WS.Sim_point = WS.Sim_point + 1;
    %Read previus time points
    State_t = WS.Tracker((WS.Sim_point - 1),:);
    NH_t = State_t(1);
    NL_t = State_t(2);
    P025_t = State_t(4);
    mdot3_t = State_t(5);
    mdot2_t = State_t(6);
    T04_t = State_t(7);
    %Get Engine Conditions
    Conditions = this_scenario.Point_Scenario((WS.Sim_point - 1),:);
    Fg_demand = Architecture.T_Profile(WS.Sim_point);
    P02_prev = P02_t;
    T02_prev = T02_t;
    P02_t = Conditions(4);
    T02_t = Conditions(5);
    NH_demand = Conditions(3);
    %Load Electrical Operation
    Prev_EHP = W_HPelec;
    Prev_ELP = W_LPelec;
    %Normalise parameters 
    T_norm = Fg/max(Architecture.T_Profile);
    Et_norm = (Fg_demand - Fg)/Fg_demand;
    NH_norm = NH_t/HP.N_Max;
    NL_norm = NL_t/LP.N_Max;
    if Architecture.Max_Capacity == 0
        EStore_norm = 0;
    else
        EStore_norm = Architecture.Current_Capacity/Architecture.Max_Capacity;
    end
    PAvalible_norm = Architecture.Peak_Power_Avalible/W_HPC;
    E_INPUTS = [T_norm;Et_norm;NH_norm;NL_norm;EStore_norm;PAvalible_norm];
    %Run Neural Network
    OUTPUTS = E_Control.control(E_INPUTS);
    %Load results
    X_LP = OUTPUTS(1);
    X_HP = OUTPUTS(2);
    P_Storage_Norm = OUTPUTS(3);
    if (Architecture.Max_Capacity == 0)
        P_Storage_Norm = 0;
    end
    if (Architecture.Current_Capacity == 0)
        P_Storage_Norm = min(P_Storage_Norm,0);
    end
    %Calculate the storage power
    P_Storage = P_Storage_Norm * 2 * Architecture.Motor_Power;
    %Get mode and normalised power of the motor generators
    %If storage is refilling:
    if (P_Storage_Norm*2) < 0
        Lower_bound = -1;
        Upper_bound = P_Storage_Norm*2 +1;
        Range_bound = abs(Upper_bound-Lower_bound);
        P_HP_Norm = Lower_bound + X_HP * (Range_bound);
        P_LP_Norm = Lower_bound + X_LP * (Range_bound);
    %If storage is not discharging or recharging 
    elseif P_Storage_Norm == 0
        P_HP_Norm = (X_HP-0.5);
        P_LP_Norm = (X_LP-0.5);
    %If storage is discharging
    else
        Lower_bound = P_Storage_Norm*2-1;
        Upper_bound = 1;
        Range_bound = abs(Upper_bound-Lower_bound);
        P_HP_Norm = Lower_bound + X_HP * (Range_bound);
        P_LP_Norm = Lower_bound + X_LP * (Range_bound);
    end
    PS(WS.Sim_point)=P_Storage_Norm;
PHP(WS.Sim_point)=P_HP_Norm;
PLP(WS.Sim_point)=P_LP_Norm;
    %Convert from normalised to true powers
    W_HPelec = P_HP_Norm * Architecture.Motor_Power;
    W_LPelec = P_LP_Norm * Architecture.Motor_Power;
    %Calculate the energy taken from the storage 
    E_storage = P_Storage*WS.delta_T;
    Architecture.StorageChange(E_storage,WS);
    %Are we in steady state?
    if abs(Fg - Fg_demand) > Fg_demand*0.02
        transpoint = transpoint + 1;
    end
    %Check if we are in steady state or transiants 
    steady_state = abs(NHdot) < 0.01 &&...
        abs(NLdot) < 0.01 &&...
        abs(Fg - Fg_demand) < 1 &&...
        T02_prev == T02_t && P02_prev == P02_t &&...
        Prev_EHP == W_HPelec && Prev_ELP == W_LPelec;
    if steady_state == 1
        WS.Tracker(WS.Sim_point,:) = WS.Tracker(WS.Sim_point-1,:);
        skipped = skipped +1;
    else
    %Get new T4
    delta_T4 = Control.demand(WS, State_t(1)/State_t(8) *Fg, State_t(1)/State_t(8) *Fg_demand);
    T04_now = T04_t + delta_T4;
    T04_now = min(max(T04_now,(T03+100)),2200);
    %Get P04 hence P03
    P04_now = Combustor.SetP4(mdot3_t,T04_now);
    P03_now = Combustor.Flow(P04_now);
   %Calculate Fan PR
    Fan_PR = P025_t/P02_t;
    %Normalise the spool speed
    NL_Normal = (NL_t/LP.N_Max)/(T02_t/Fan.T0_DP)^0.5;
    %Look up fan beta
    if (NL_Normal<0.4) || (NL_Normal>1.07)
        fuel_mass = 9999999999;
        Transiant_Time = 9999999999;
        return;
    end
    beta_Fan = min(Fan.beta_ID(NL_Normal,Fan_PR),1);
    %Look up fan efficency
    Fan_iso = Fan.efficency(NL_Normal,beta_Fan);
    %Calculate tempreature rise over FAN
    T025_ideal = T02_t * Fan_PR^((WS.gamma_comp-1)/WS.gamma_comp);
    %Calculate real temp rise
    T025 = T02_t + (T025_ideal - T02_t)/Fan_iso;
    %Calculate the fan work
    W_FAN = mdot2_t * WS.cp * (T025-T02_t);
    %Hence the HPC pressure ratio due to the change 
    PR_HPC = P03_now/P025_t;
    %Normalise the spool speed
    NH_Normal = (NH_t/HP.N_Max)/(T025/HPC.T0_DP)^0.5;
    %Calculate the beta value of the HPC
    if (NH_Normal<0.5) || (NH_Normal>1.05)
        fuel_mass = 9999999999;
        Transiant_Time = 9999999999;
        return;
    end
    beta_HPC = min(HPC.beta_ID(NH_Normal,PR_HPC),1);
    %Read the parameters from the compressor map
    [HPC_iso,mdot3_now,~] = HPC.Lookup(NH_Normal,beta_HPC);
    %Calulate true mass flow
    mdot3_now = mdot3_now * (P025_t/HPC.P0_DP)/(T025/HPC.T0_DP)^0.5;
    %Calculate T03 ideal
    T03_ideal = T025 * PR_HPC^((WS.gamma_comp-1)/WS.gamma_comp);
    %Calculate real T03
    T03 = T025 + (T03_ideal - T025)/HPC_iso;
    %Calculate the work done by the HPC
    W_HPC = mdot3_now * WS.cp * (T03-T025);
    %Calculate the BPR
    BPR = (mdot2_t - mdot3_now)/mdot3_now;
    %Calculate the work extracted by the HPT
    W_HPT = mdot3_t * WS.cpe * HPT.K_HP * T04_now * HPT.Iso_efficency;
    %Calculate the Tempreater drop over the HPT
    T045 = T04_now * (1 - HPT.K_HP);
    %Calculate the pressure drop over the HPT
    P045 = P04_now * (T045/T04_now)^(WS.gamma_turb/(WS.gamma_turb-1));
    %Calculate the pressure drop in the bypass stream
    P026 = P025_t * (1 - Bypass.Pressure_Loss);
    %Calculate Expansion Ratio over LPT
    ER_LPT = P045/P026;
    %Calculate the ideal tempreature drop over the LPT
    T05_ideal = T045 * (1/ER_LPT)^((WS.gamma_turb-1)/WS.gamma_turb);
    %Calculate real t05
    T05 = T045 - LPT.Iso_efficency * (T045 - T05_ideal);
    %Calculate the work done by the LPT
    W_LPT = mdot3_t * WS.cpe * (T045 - T05);
    %Calculate next NH
    %net work on shaft
    NH_NW = W_HPT - W_HPC + W_HPelec;
    %friction loss on shaft
    NH_FL = (NH_t/HP.N_design)^2 * HP.Friction;
    %NH in rad/s
    NH_omega = NH_t*2*pi/60;
    %Calculate NHdot
    NHdot = (30/pi)*(NH_NW+NH_FL)/(NH_omega*HP.Inertia);
    %Calculate new NH
    NH_now = NH_t + NHdot * WS.delta_T;
    %Calculate next NL
    %net work on shaft
    NL_NW = W_LPT - W_FAN + W_LPelec;
    %fiction loss on shaft
    NL_FL = (NL_t/LP.N_design)^2 * LP.Friction;
    %NL in rad/s
    NL_omega = NL_t*2*pi/60;
    %Calculate NLdot
    NLdot = (30/pi)*(NL_NW+NL_FL)/(NL_omega*LP.Inertia);    
    %Calculate new NL
    NL_now = min(NL_t + NLdot * WS.delta_T,LP.N_Max*1.05);
    %Calculate normal spool speed
    NL_Normal = (NL_now/LP.N_Max)/(T02_t/Fan.T0_DP)^0.5;
    %Read the parameters from the compressor map
    if (NL_Normal<0.4) || (NL_Normal>1.07)
        fuel_mass = 9999999999;
        Transiant_Time = 9999999999;
        return;
    end
    [~,mdot2_now,Fan_PR_now] = Fan.Lookup(NL_Normal,beta_Fan);
    % Calculate real massflow
    mdot2_now = mdot2_now * (P02_t/Fan.P0_DP)/(T02_t/Fan.T0_DP)^0.5; 
    %Calculate next P025;
    P025_now = Fan_PR_now * P02_t;
    %Mix flow from bypass and core
    P06 = P026;
    Cpm = (WS.cpe + BPR * WS.cp)/(1+BPR);
    T06 = (WS.cpe*T05+BPR*WS.cp*T025)/((1+BPR)*Cpm);
    %Calculate thrust
    Vj = (2*Cpm*T06*(1-(P02_t/P06)^((WS.gamma_turb-1)/(WS.gamma_turb))))^0.5;
    Fg = Vj*mdot2_t;
    %Calculate mf_dot
    f = (T04_now - T03)/((LCV/WS.cpe)-T04_now);
    mdot_f = f * mdot3_now;
    %Fuel flow correction factor
    Error_T4 = -0.0186 * T04_now + 36.503;
    mdot_f = mdot_f/(Error_T4/100 + 1);
    %Store state for next iteration
    WS.Tracker(WS.Sim_point,:) = ...
        [NH_now NL_now P02_t P025_now mdot3_now mdot2_now T04_now, Fg, mdot_f];
    end
end

fuel_mass = sum(WS.Tracker(:,9)) * WS.delta_T;
Transiant_Time = WS.delta_T*transpoint;
figure(3);
hold on
plot([0:WS.delta_T:WS.Sim_time],PS);
plot([0:WS.delta_T:WS.Sim_time],PHP);
plot([0:WS.delta_T:WS.Sim_time],PLP);
hold off
end 