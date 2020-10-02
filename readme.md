# personnummer [![Build Status](https://github.com/personnummer/lua/workflows/test/badge.svg)](https://github.com/personnummer/lua/actions)

Validate Swedish personal identity numbers. Follows version 3 of the [specification](https://github.com/personnummer/meta#package-specification-v3).

Install the module with npm:

```
luarocks install personnummer
```

## Example

```lua
local Personnummer = require("personnummer")

Personnummer.valid("198507099805")
-- true
```

## Testing locally with Docker

```
docker build -t luap .
docker run --rm -it -v $(pwd):/app luap /bin/ash -c "luarocks make && busted spec"
```

## License

MIT
