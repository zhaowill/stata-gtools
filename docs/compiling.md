Compiling
=========

### Requirements

If you want to compile the plugin yourself, you will need

- The GNU Compiler Collection (`gcc`)
- [`premake5`](https://premake.github.io)
- [`centaurean`'s implementation of SpookyHash](https://github.com/centaurean/spookyhash)
- v2.0 or above of the [Stata Plugin Interface](https://stata.com/plugins/version2) (SPI).

I keep a copy of Stata's Plugin Interface in this repository, and I have added
`centaurean`'s implementation of SpookyHash as a submodule.  However, you will
have to make sure you have `gcc` and `premake5` installed and in your system's
`PATH`.

On OSX, yu can get `gcc` and `make` from xcode. On windows, you will need

- [Cygwin](https://cygwin.com) with gcc, make, libgomp, x86_64-w64-mingw32-gcc-5.4.0.exe
  (Cygwin is pretty massive by default; I would install only those packages).

If you also want to compile SpookyHash on windows yourself, you will also need

- [Microsoft Visual Studio](https://www.visualstudio.com) with the
  Visual Studio Developer Command Prompt (again, this is pretty massive
  so I would recommend you install the least you can to get the
  Developer Prompt).

I keep a copy of `spookyhash.dll` in `./lib/windows` so there is no need to
re-compile SpookyHash.

### Compilation

Note that lines 37-40 in `lib/spookyhash/build/premake5.lua` cause the build
to fail on some systems, so we delete them (they are meant to check the git
executable exists).
```bash
git clone https://github.com/mcaceresb/stata-gtools
cd stata-gtools
git submodule update --init --recursive
sed -i.bak -e '37,40d' ./lib/spookyhash/build/premake5.lua
make spooky
make clean
make
```

### Unit tests

From a stata session, run
```stata
do build/gtools_tests.do
```

If successful, all tests should report to be passinga and the exit message
should be "tests finished running" followed by the start and end time.

### Troubleshooting

I test the builds using Travis and Appveyor; if both builds are passing
and you can't get them to compile, it is likely because you have not
installed all the requisite dependencies. For Cygwin in particular, see
`./src/plugin/gtools.h` for all the include statements and check if you have
any missing libraries.

Loading the plugin is a bit trickier. Historically, the plugin has failed on
some windows systems and some legacy Linux systems. The Linux issue is largely
due to versioning. That is, while the functions I use should be available on
most systems, the package versions are too recent for some systems. If this
happens please submit a bug report.

On Windows the issue is largely due to Stata not being able to find the
SpookyHash library, `spookyhash.dll` (Stata does not look in the ado path by
default, just the current directory and the system path). I keep a copy in
`./lib/windows` but the user can also run

```
gtools, dependencies
```

If that does not do the trick, run

```
gtools, dll
```

before calling a gtools command (should only be required once per
script/interactive session). Alternatively, you can keep `spookyhash.dll` in
the working directory or run your commands with `hashlib()`. For example,

```
gcollapse (sum) varlist, by(varlist) hashlib(C:\path\to\spookyhash.dll)
```

Other than that, as best I can tell, all will be fine as long as you use the
MinGW version of gcc and SpookyHash was built using visual studio. That is,

- `x86_64-w64-mingw32-gcc` instead of `gcc` in cygwin for the plugin,
- `premake5 vs2013`, and
- `msbuild SpookyHash.sln` for SpookyHash

Again, you can find the dll pre-built in `./lib/windows/spookyhash.dll`,
but if you are set on re-compiling SpookyHash, you have to force `premake5`
to generate project files for a 64-bit version only (otherwise `gcc` will
complain about compatibility issues). Further, the target folder has not
always been consistent in testing. While this may be due to an error on my
part, I have found the compiled `spookyhash.dll` in

- `./lib/spookyhash/build/bin`
- `./lib/spookyhash/build/bin/x86_64/Release`
- `./lib/spookyhash/build/bin/Release`

Again, I advise against trying to re-compile SpookyHash on Windows. Just use
the dll provided in this repo.
