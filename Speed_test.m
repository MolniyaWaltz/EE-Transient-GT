%interp1([6,7],[4.3,5],6.76)
%0.007

%4.3+(5-4.3)/(7-6)*(6.76-6)

[pks,p_locs] = findpeaks(WS.Tracker(1:WS.Sim_point,8));
[tro,t_locs] = findpeaks(-WS.Tracker(1:WS.Sim_point,8));

pks > 7e4