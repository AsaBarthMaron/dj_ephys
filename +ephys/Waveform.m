%{
# waveforms

wave_name         : varchar(50)         # unique string to index commonly used waveforms
---
waveform          : longblob            # waveform
samp_rate         : int unsigned        # sampling rate (samples / second)
duration          : double              # command duration (in seconds)
frequency = NULL  : double              # waveform frequency in Hz (if applicable)
on_duration       : double              # duration of command on, per cycle if applicable.
                                        # all waveforms exist in binary space on {0, X}, where X any real number.

%}
classdef Waveform < dj.Manual
end