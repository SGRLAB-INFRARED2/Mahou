global method rotors

polAngles = -40:10:90;
% wpAngles = polAngles./2;
signalArray3 = zeros(1, length(polAngles));

for ii = 1:length(polAngles)
%     rotors(1).MoveTo(wpAngles(ii));
    rotors(2).MoveTo(polAngles(ii));
    Spectrometer('pbGo_Callback',method.handles.pbGo,[],method.handles);
    
    signalArray3(ii) = mean(method.result.data);
end

fig = figure(10000);
hold on
plot(polAngles, signalArray3, 'o-');
xlabel('Polarizer Angle (deg)')
ylabel('Mean Shot Count')
fig.Color = 'w';
box off
fig.Children.TickDir = 'out';

%%

% fig = figure(200000);
% plot(polAngles, mean([signalArray1; signalArray2; signalArray3]), 'o-')
% xlabel('Polarizer Angle (deg)')
% ylabel('Mean Shot Count of multiple rounds')
% fig.Color = 'w';
% box off
% fig.Children.TickDir = 'out';