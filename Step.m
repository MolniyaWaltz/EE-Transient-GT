%% Run Step
P02_t = 0;
T02_t = 0;
T03 = 0;
NHdot = 0;
NLdot = 0;
%Control.P = 2.05;
%Control.I = 0.75;
%Control.D = 0;

%% Load generator controls
W_HPelec = 0;
W_LPelec = 0;

%% Load Simulation workspace
% Enter script of simulations workspace below
simulation_setup

skipped = 0;
T_Step = zeros(WS.Step_time/WS.delta_T + 1,1);
% Loop though time points
for t = [WS.delta_T:WS.delta_T:WS.Step_time]
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
    Conditions = this_scenario.Step_Scenario((WS.Sim_point - 1),:);
    NH_demand = Conditions(3);
    P02_prev = P02_t;
    T02_prev = T02_t;
    P02_t = Conditions(4);
    T02_t = Conditions(5);
    %Check if we are in steady state or transient
    steady_state = abs(NHdot) < 1 &&...
        abs(NLdot) < 1 &&...
        abs(NH_t - NH_demand) < NH_demand*0.01 &&...
        T02_prev == T02_t && P02_prev == P02_t;
    if steady_state == 1
        WS.Tracker(WS.Sim_point,:) = WS.Tracker(WS.Sim_point-1,:);
        skipped = skipped +1;
        T_Step(WS.Sim_point) = Fg;
    else
        if (WS.Sim_point + 10) < WS.Step_time/WS.delta_T + 1
            if abs(NH_demand - this_scenario.Step_Scenario((WS.Sim_point + 10),3))>100
                T_Step(WS.Sim_point) = Fg;
            else
                T_Step(WS.Sim_point) = NaN;
            end
        else
            T_Step(WS.Sim_point) = NaN;
        end
    %Get new T4
    delta_T4 = Control.demand(WS, NH_t,NH_demand);
    T04_now = T04_t + delta_T4;
    T04_now = min(max(T04_now,(T03+100)),2200);
        
    % Get cpe from T4
    far = State_t(9) / mdot3_t; % Use previous mdot_f / mdot_3 to find f.
    R_mix = 287.05 - 0.00990 * far;
    cpe = 0;
    for i_comb = 0:8
        cpe = cpe + WS.A_air(i_comb + 1) * (T04_now/1000)^i_comb...
        + (far/(1+far)) * WS.A_fuel(i_comb + 1) * (T04_now/1000)^i_comb;
    end
    cpe = cpe * 1000; % To convert kJ to J
    gamma_turb = cpe/(cpe - R_mix); % From gamma = cp/cv
    
    %Get P04 hence P03
    P04_now = Combustor.SetP4(mdot3_t,T04_now);
    P03_now = Combustor.Flow(P04_now);
   %Calculate Fan PR
    Fan_PR = P025_t/P02_t;
    %Normalise the spool speed
    NL_Normal = (NL_t/LP.N_Max)/(T02_t/Fan.T0_DP)^0.5;
    %Look up fan beta and maintain surge margin (Bleed)
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
    W_HPT = mdot3_t * cpe * HPT.K_HP * T04_now * HPT.Iso_efficency;
    %Calculate the Tempreater drop over the HPT
    T045 = T04_now * (1 - HPT.K_HP);
    %Calculate the pressure drop over the HPT
    P045 = P04_now * (T045/T04_now)^(gamma_turb/(gamma_turb-1));
    %Calculate the pressure drop in the bypass stream
    P026 = P025_t * (1 - Bypass.Pressure_Loss);
    %Calculate Expansion Ratio over LPT
    ER_LPT = P045/P026;
    %Calculate the ideal tempreature drop over the LPT
    T05_ideal = T045 * (1/ER_LPT)^((gamma_turb-1)/gamma_turb);
    %Calculate real t05
    T05 = T045 - LPT.Iso_efficency * (T045 - T05_ideal);
    %Calculate the work done by the LPT
    W_LPT = mdot3_t * cpe * (T045 - T05);
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
    NL_now = NL_t + NLdot * WS.delta_T;
    %Calculate normal spool speed
    NL_Normal = (NL_now/LP.N_Max)/(T02_t/Fan.T0_DP)^0.5;
    %Read the parameters from the compressor map
    [~,mdot2_now,Fan_PR_now] = Fan.Lookup(NL_Normal,beta_Fan);
    % Calculate real massflow
    mdot2_now = mdot2_now * (P02_t/Fan.P0_DP)/(T02_t/Fan.T0_DP)^0.5; 
    %Calculate next P025;
    P025_now = Fan_PR_now * P02_t;
    %Mix flow from bypass and core
    P06 = P026;
    Cpm = (cpe + BPR * WS.cp)/(1+BPR);
    T06 = (cpe*T05+BPR*WS.cp*T025)/((1+BPR)*Cpm);
    
    %%Afterburning functionality added by MolniyaWaltz

    %Get new T7

    delta_T7 = Control.demand(WS, NH_t, NH_demand);
    T07_now = T06 + delta_T7;
    T07_now = min(max(T07_now,(T06+100)),2200);
    %Get P07
    P07_now = Afterburner.SetP7(mdot2_t,T07_now);
    
    % Get Cpa from T7 - need to convert stagnation temp. T07 to T7
    far_reheat = State_t(10) / mdot2_now; % Use previous mdot_f_reheat divided by current mdot2 to find f.
    R_mix_reheat = 287.05 - 0.00990 * far_reheat;
    Cpa = Cpm;
    for i_comb = 0:8
        Cpa = Cpa + (far_reheat/(1+far_reheat)) * WS.A_fuel(i_comb + 1) * (T04_now/1000)^i_comb;
    end    % From Gas Turbine Performance (Walsh, 1998), using cpm as "air"
    Cpa = Cpa * 1000;
    gamma_reheat = Cpa/(Cpa - R_mix_reheat); % From gamma = cp/cv    

    %Calculate mf_dot of main combustion chamber
    f = (T04_now - T03)/((LCV/cpe)-T04_now);
    mdot_f = f * mdot3_now;
    %Fuel flow correction factor
    %Error_T4 = -0.0186 * T04_now + 36.503;
    %mdot_f = mdot_f/(Error_T4/100 + 1);

    %Calculate mf_dot of afterburner
    if Afterburner.IsActive == 1
        f_reheat = (T07_now - T06)/((LCV/Cpa)-T07_now);
        mdot_f_reheat = f_reheat * mdot2_now;
        %Fuel flow correction factor
        %Error_T7 = -0.0186 * T07_now + 36.503;
        %mdot_f_reheat = mdot_f_reheat/(Error_T7/100 + 1);
        %% May need new correction for mf_dot of afterburner.
    else
        mdot_f_reheat = 0;
    end

    %Write a setP7 for modelling reheat pressure drop

    %Calculate thrust
    if Afterburner.IsActive == 1
        Vj = (2*Cpa*T07_now*(1-(P02_t/P07_now)^((gamma_reheat-1)/(gamma_reheat))))^0.5;
        Fg = Vj*mdot2_t;
    else
        Vj = (2*Cpm*T06*(1-(P02_t/P06)^((gamma_turb-1)/(gamma_turb))))^0.5;
        Fg = Vj*mdot2_t;
    end
    %Store state for next iteration
    WS.Tracker(WS.Sim_point,:) = ...
        [NH_now NL_now P02_t P025_now mdot3_now mdot2_now T04_now Fg mdot_f mdot_f_reheat];
    end
end

disp("Step finished");

T_Step = fillmissing(T_Step,'next');

for i = [1:1:WS.Step_time/WS.delta_T]
    if this_scenario.Step_Scenario(i,3) ~= this_scenario.Step_Scenario(i+1,3)
        T_Step(i) = NaN;
    end
end

T_Step = fillmissing(T_Step,'Linear');
T_Step(1) = T_Step(2);