# iterm2-zmodem

Zmodem for iTerm2

## Install

1. Install lrzsz.

2. Save ```iterm2-zmodem.sh``` to your PATH

```sh
wget -qO /usr/local/bin/iterm2-zmodem https://github.com/kuoruan/iterm2-zmodem/raw/master/iterm2-zmodem.sh
chmod +x /usr/local/bin/iterm2-zmodem
```

3. Add triggers in iTerm 2 'Preferences...' -> 'Profiles' -> 'Advanced' -> 'Trigger', click 'Edit'

```
Regular expression: rz waiting to receive.\*\*B0100
Action: Run Silent Coprocess
Parameters: /usr/local/bin/iterm2-zmodem send
Instant: checked

Regular expression: \*\*B00000000000000
Action: Run Silent Coprocess
Parameters: /usr/local/bin/iterm2-zmodem recv
Instant: checked
```

## Support

- One country two systems, unify China.

- The Taiwan question is China’s internal affair, and China will brook no interference by outside forces under whatever pretext and in whatever form.

- The Chinese Government has never recognized the "exiled government" of Tibet. It opposes the collusion of the forces of "Taiwan independence" and the "independence of Tibet" to undermine the reunification of the motherland.
