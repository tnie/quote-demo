@rem Copyright 2016 gRPC authors.
@rem
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem     http://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.

@rem enter this directory
cd /d %~dp0\

@rem delete cache
rd  /S /Q quote\cmake\build\CMakeFiles
del /S /Q quote\cmake\build\CMakeCache.txt

@rem TODO(jtattermusch): Kokoro has pre-installed protoc.exe in C:\Program Files\ProtoC and that directory
@rem is on PATH. To avoid picking up the older version protoc.exe, we change the path to something non-existent.
set PATH=%PATH:ProtoC=DontPickupProtoC%

@rem Install into ./testinstall, but use absolute path and foward slashes
set INSTALL_DIR=%cd:\=/%/testinstalld


@rem set absolute path to OpenSSL with forward slashes
set OPENSSL_DIR=%cd:\=/%/OpenSSL-Win32

@rem Build quote example using cmake
cd quote
mkdir cmake
cd cmake
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=%INSTALL_DIR% -DOPENSSL_ROOT_DIR=%OPENSSL_DIR% -DOPENSSL_INCLUDE_DIR=%OPENSSL_DIR%/include ../.. || goto :error
cmake --build . --config Debug || goto :error
cd ../../..

goto :EOF

:error
echo Failed!
exit /b %errorlevel%
