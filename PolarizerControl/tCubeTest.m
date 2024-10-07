
MOTORPATHDEFAULT='C:\Program Files\Thorlabs\Kinesis\';

CONTROLSDLL = 'Thorlabs.MotionControl.Controls.dll';
DEVICEMANAGERDLL='Thorlabs.MotionControl.DeviceManagerCLI.dll';
DEVICEMANAGERCLASSNAME='Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI';
GENERICMOTORDLL='Thorlabs.MotionControl.GenericMotorCLI.dll';
GENERICMOTORCLASSNAME='Thorlabs.MotionControl.GenericMotorCLI.GenericMotorCLI';
DCSERVODLL='Thorlabs.MotionControl.TCube.DCServoCLI.dll';
% DCSERVODLL2 = 'Thorlabs.MotionControl.TCube.DCServo.dll';
DCSERVOCLASSNAME='Thorlabs.MotionControl.TCube.DCServoCLI.TCubeDCServo';

% Default intitial parameters
DEFAULTVEL=10;           % Default velocity
DEFAULTACC=10;           % Default acceleration
TPOLLING=250;            % Default polling time
TIMEOUTSETTINGS=7000;    % Default timeout time for settings change
TIMEOUTMOVE=100000;      % Default time out time for motor move
% 
% if ~exist(DEVICEMANAGERCLASSNAME,'class')
%     fprintf('Loading DLL Libraries')
%     try   % Load in DLLs if not already loaded
        devMan = NET.addAssembly([MOTORPATHDEFAULT, DEVICEMANAGERDLL]);
%         control = NET.addAssembly([MOTORPATHDEFAULT, CONTROLSDLL]);
        genMot = NET.addAssembly([MOTORPATHDEFAULT, GENERICMOTORDLL]);
        DCServ = NET.addAssembly([MOTORPATHDEFAULT, DCSERVODLL]);
%         DCServ2 = NET.addAssembly([MOTORPATHDEFAULT, DCSERVODLL2]);
%     catch % DLLs did not load
%         error('Unable to load .NET assemblies')
%     end
% end


% import Thorlabs.MotionControl.Controls.*
% import Thorlabs.MotionControl.DeviceManagerCLI.*
% import Thorlabs.MotionControl.TCube.DCServoCLI.*
%%
Thorlabs.MotionControl.DeviceManagerCLI.SimulationManager.Instance.InitializeSimulations()

%%
Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.BuildDeviceList();  % Build device list
serialNumbersNet = Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.GetDeviceList(); % Get device list
serialNumbers=cell(ToArray(serialNumbersNet)) % Convert serial numbers to cell array
%%
serialNo = serialNumbers{2};
deviceNET=Thorlabs.MotionControl.TCube.DCServoCLI.TCubeDCServo.CreateTCubeDCServo(serialNo);
%%
% deviceNET.ClearDeviceExceptions();    % Clear device exceptions via .NET interface
deviceNET.Connect(serialNo);          % Connect to device via .NET interface
%%
if ~deviceNET.IsSettingsInitialized() % Wait for IsSettingsInitialized via .NET interface
    deviceNET.WaitForSettingsInitialized(TIMEOUTSETTINGS);
end
if ~deviceNET.IsSettingsInitialized() % Cannot initialise device
    error(['Unable to initialise device ',char(serialNo)]);
end
deviceNET.StartPolling(TPOLLING);   % Start polling via .NET interface
motorSettingsNET=deviceNET.LoadMotorConfiguration(serialNo); % Get motorSettings via .NET interface
currentDeviceSettingsNET=deviceNET.MotorDeviceSettings;     % Get currentDeviceSettings via .NET interface
deviceInfoNET=deviceNET.GetDeviceInfo();                    % Get deviceInfo via .NET interface

enumHandle = genMot.AssemblyHandle.GetType('Thorlabs.MotionControl.GenericMotorCLI.Settings.RotationSettings+RotationDirections'); 
MotDir = enumHandle.GetEnumValues().Get(1); % 1 stands for "Forwards"
% MotDir=Thorlabs.MotionControl.GenericMotorCLI.Settings.RotationSettings+RotationDirections; %Thorlabs.MotionControl.GenericMotorCLI.Settings.RotationDirections.Forward; % MotDir is enumeration for 'forwards'
currentDeviceSettingsNET.Rotation.RotationDirection=MotDir;   % Set motor direction to be 'forwards#
%%
% MotDir = Thorlabs.MotionControl.GenericMotorCLI.MotorDirection.Forward;
% workDone=deviceNET.InitializeWaitHandler();
% deviceNET.MoveJog(MotDir, workDone);
%%
position = 40;
fprintf('Moving To %f mm...\n', position);
workDone=deviceNET.InitializeWaitHandler(); % Initialise Waithandler for timeout
deviceNET.MoveTo(position, workDone);       % Move devce to position via .NET interface
% pause(0.1)
% deviceNET.Wait(TIMEOUTMOVE);              % Wait for move to finish

while deviceNET.IsDeviceBusy
    fprintf('Position: %3.2f\n', System.Decimal.ToDouble(deviceNET.Position));
    pause(0.25)
end

fprintf('Current Position (mm): %f\n', System.Decimal.ToDouble(deviceNET.Position));

fprintf('Moving Home...\n')
workDone=deviceNET.InitializeWaitHandler();     % Initialise Waithandler for timeout
deviceNET.Home(workDone);                       % Home devce via .NET interface
deviceNET.Wait(TIMEOUTMOVE);                  % Wait for move to finish
fprintf('Current Position (mm): %f\n', System.Decimal.ToDouble(deviceNET.Position));

%%
deviceNET.StopPolling();  % Stop polling device via .NET interface
deviceNET.DisconnectTidyUp();
deviceNET.Disconnect();   % Disconnect device via .NET interface
