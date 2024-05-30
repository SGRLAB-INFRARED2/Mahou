global method rotors

polAngles = [-20:1:330];
theta = -20:1:330;
signalArray3 = zeros(1, length(polAngles));

for ii = 1:length(polAngles)
    rotors(2).MoveTo(polAngles(ii));
    Spectrometer('pbGo_Callback',method.handles.pbGo,[],method.handles);
    
    signalArray3(ii) = mean(method.result.data);
end

% %%
% close all
% fig = figure(10000);
% hold on
% plot(theta, signalArray3./max(signalArray3), 'o-');
% % plot(polAngles, signalArray3, 'o-');
% plot(theta,0.4*cospi(2*theta./180)+.6)
% xlabel('Polarizer Angle (deg)')
% ylabel('Mean Shot Count')
% fig.Color = 'w';
% box off
% fig.Children.TickDir = 'out';


%%
options = optimoptions(@fmincon,'OptimalityTolerance',0.000000000001);

ssefun = @(v) sum((signalArray3./max(signalArray3) - f(v(1),v(2),v(3),theta)).^2);
initialguess = [0.4 -2 0.6];
ub = [1,10,1];
lb = [0,-10,-1];
[optvals, fval] = fmincon(ssefun,initialguess,[],[],[],[],lb,ub,[],options);
amp = optvals(1);
correction = optvals(2);
baseline = optvals(3);

%%
close all
plot(theta, signalArray3./max(signalArray3))
hold on
plot(theta,f(amp,correction,baseline,theta))
xlabel('Polarizer Angle (degrees)')
ylabel('Normalized Intensity')
%%

function out = f(a,shift,offset,theta)
out = a*cospi(2*(theta-shift)./180)+offset;
end
%%

% fig = figure(200000);
% plot(polAngles, mean([signalArray1; signalArray2; signalArray3]), 'o-')
% xlabel('Polarizer Angle (deg)')
% ylabel('Mean Shot Count of multiple rounds')
% fig.Color = 'w';
% box off
% fig.Children.TickDir = 'out';