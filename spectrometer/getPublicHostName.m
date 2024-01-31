function name = getPublicHostName
% Get public name via ip address

name = '';
if ispc
    CMD1 = '!ipconfig -all';
    REGEXP1 = 'IPv4.*:\s*(\d+\.\d+\.\d+\.\d+)\(Preferred\)';
    CMD2 = @(ip) ['!nslookup ', ip];
    REGEXP2 = 'Name:\s*([^\s]*)';
else
    error('not implemented')
end
uh = regexp(evalc(CMD1), REGEXP1, 'tokens');
ip = uh{1}{1};
uh = regexp(evalc(CMD2(ip)), REGEXP2, 'tokens');
name = uh{1}{1};

