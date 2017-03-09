classdef EthoIO < SchedIO

properties (SetAccess = private)
    reward_pin
    reward_signal
end

methods
    function obj = EthoIO(port_name, reward_pin, reward_signal)
        defaults = EthoPars_io();
        if ~exist('port_name','var')
            port_name = defaults.port_name;
        end
        if ~exist('reward_pin','var')
            reward_pin = defaults.reward_pin;
        end
        if ~exist('reward_signal', 'var')
            reward_signal = defaults.reward_signal;
        end
        obj = obj@SchedIO(port_name);
        obj.reward_pin = reward_pin;
        obj.reward_signal = reward_signal;
    end

    function when = Reward(amount)
        when = obj.PulsePin(obj.reward_pin, obj.reward_signal, amount);
    end
end

end
