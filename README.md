# signal-rest-cli-docker-pi

signal-cli REST API via docker on a Raspberry Pi. Based on the great work of [AsamK](https://github.com/AsamK) ([signal-cli](https://github.com/AsamK/signal-cli)) [1] and [bbernhard](https://github.com/bbernhard) ([REST API](https://github.com/bbernhard/signal-cli-rest-api)) [2]. Trying to simplify the setup a bit further.

## Installation

You may have to adjust the exposed port in [install.sh](install.sh)

```
./install.sh image
./install.sh start
```

## Configuration

1. Copy .config-sample to .config
2. Enter phone number and name
3. Get captcha code as described in [3] and put it in the .config file
4. Registration
   ```
   ./install.sh register
   ```
5. You'll get a call on the specified phone number. A token code will be spelled three times. Note it.
6. Registration verification (with the just obtained token code)
   ```
   ./install.sh register_verify <token>
   ```
7. Adjust profile name and avatar (as defined in .config)
   ```
   ./install.sh profile
   ```
8. Send a test message
   ```
   ./install.sh message <receiver_phone_number> test
   ```
   You should get the message 'test' on the <receiver_phone_number>

## Other notes

All configuration is stored in the config folder in the current directory.
You may transparently migrate to another system when transferring and correspondingly mounting that folder again.

## References

1. https://github.com/AsamK/signal-cli
2. https://github.com/bbernhard/signal-cli-rest-api
3. https://github.com/AsamK/signal-cli/wiki/Registration-with-captcha
