function [beta] = get_beta(Map,N_Corrected,PR)
%Compressor_Map will return the effeciency and corrected normalised mass
%flow for a given spool speed and Pressure Ratio

%Read Table Key
Table_Key = num2str(Map(1,1));
%Interprit Key
Num_Spool_Speeds = str2num(Table_Key(1:2)) - 1;
Num_Beta_lines = str2num(Table_Key(3:6)) * 1000 -1;
Num_Row_per_Speed = ceil((Num_Beta_lines+1)/5);

%Read spool Speeds
Spool_Speeds = [];
j=1;
for i = [1:Num_Row_per_Speed:Num_Row_per_Speed*Num_Spool_Speeds]
    Spool_Speeds(j) = round((Map(i+Num_Row_per_Speed,1)),3);
    j = j + 1;
end

%Identify speed value to read
Speed_index = interp1(Spool_Speeds,[1:1:Num_Spool_Speeds],N_Corrected,'spline');
if N_Corrected == Spool_Speeds(1)
    Speed_index = 1;
end
if N_Corrected == Spool_Speeds(end)
    Speed_index = length(Spool_Speeds);
end

Read_high = ceil(Speed_index);
Read_Low = floor(Speed_index);

if Read_high == Read_Low
    Speed_Indexs = [Read_high];
else
    Speed_Indexs = [Read_Low, Read_high];
end

%Read PR
PR_Start = (3*Num_Row_per_Speed) + 2*Num_Row_per_Speed*Num_Spool_Speeds + 4 + 1;
%(3*Num_Row_per_Speed) = bypass beta defs
%2*Num_Row_per_Speed*Num_Spool_Speeds = bypass mdots and effs
%+4+1 = 4 to get past line breaks and 1 to select working line

if length(Speed_Indexs) == 1
    line = PR_Start + ((Speed_Indexs(1)-1) * Num_Row_per_Speed);
    PR_at_Speed = [];
    k=2;
    for beta = [1:1:Num_Beta_lines]
         PR_at_Speed(beta) = Map(line, k);
         k = k +1;
         if k ==6
             k = 1;
             line = line + 1;
         end
     end
else
    line = PR_Start + ((Speed_Indexs(1)-1) * Num_Row_per_Speed);
    PR_at_Speed_Low = [];
    k=2;
    for beta = [1:1:Num_Beta_lines]
         PR_at_Speed_Low(beta) = Map(line, k);
         k = k +1;
         if k ==6
             k = 1;
             line = line + 1;
         end
    end
    line = PR_Start + ((Speed_Indexs(2)-1) * Num_Row_per_Speed);
    PR_at_Speed_High = [];
    k=2;
    for beta = [1:1:Num_Beta_lines]
         PR_at_Speed_High(beta) = Map(line, k);
         k = k +1;
         if k ==6
             k = 1;
             line = line + 1;
         end
    end

    for i = [1:1:Num_Beta_lines]
        %PR_at_Speed(i) = interp1([Speed_Indexs(1),Speed_Indexs(2)],[PR_at_Speed_Low(i),PR_at_Speed_High(i)],Speed_index,'spline');
        PR_at_Speed(i) = PR_at_Speed_Low(i)+(PR_at_Speed_High(i)-PR_at_Speed_Low(i))/(Speed_Indexs(2)-Speed_Indexs(1))*(Speed_index-Speed_Indexs(1));
    end

end

%Calculate the beta value we are looking for
beta_value = interp1(PR_at_Speed,[1:1:Num_Beta_lines],PR,'spline');

beta = (1/Num_Beta_lines) * beta_value;

beta = max(min(beta,1),0.05);

end

