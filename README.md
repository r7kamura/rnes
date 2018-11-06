# Rnes

[![CircleCI](https://circleci.com/gh/r7kamura/rnes.svg?style=svg)](https://circleci.com/gh/r7kamura/workflows/rnes)
[![Documentation](http://img.shields.io/badge/docs-rdoc.info-blue.svg)](http://www.rubydoc.info/github/r7kamura/rnes)

A NES emulator written in Ruby.

## Requirements

- Ruby 2.2 or higher

## Installation

Install rnes as a gem.

```sh
gem install rnes
```

## Usage

Pass ROM file path to `rnes` executable.

```sh
rnes <path-to-rom-file>
```

## Controls

```
.------------------------------.
| [I]      |                   |
|  _|W|_   .__________________ |
| |A( )D|    N  M     ,    .   |
|   |S|    ( _  _ )  (_)  (_)  |
.______________________________.

Up     = W
Left   = A
Down   = S
Right  = D
Select = N
Start  = M
B      = ,
A      = .

```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/r7kamura/rnes.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
