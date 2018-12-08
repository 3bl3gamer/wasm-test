# WebAssembly test

Comparing JS and WASM Mandelbrot set generators.

Now (September, 2016) WASM version works as fast as JS one, sometimes JS (yes, JS) is a bit faster. Tested in Firefox 50 Dev and Chrome 54 Dev.

Try here https://3bl3gamer.github.io/wasm-test/ (WASM generator) or here https://3bl3gamer.github.io/wasm-test/#js (JS generator).

Generates something like this:
![example](https://3bl3gamer.github.io/wasm-test/example.png)

On how to rebuild main.wasm check out https://developer.mozilla.org/en-US/docs/WebAssembly/Text_format_to_wasm and https://github.com/webassembly/wabt
