#!/usr/bin/env bash
set -euo pipefail

ROOT=$(pwd)
DEPS=$ROOT/deps
PREFIX=$DEPS/install

mkdir -p "$PREFIX"

echo "=== Installing system dependencies (APT) ==="
sudo apt install \
  nlohmann-json3-dev libspdlog-dev libfmt-dev libjsoncpp-dev \
  espeak-ng libespeak-ng-dev libogg-dev libsoxr-dev

echo "=== Building libopusenc ==="
pushd $DEPS/libopusenc
./autogen.sh
./configure --prefix="$PREFIX"
make -j$(nproc)
make install
popd

echo "=== Building xtl ==="
pushd $DEPS/xtl
git checkout 0.7.5
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX="$PREFIX"
make -j$(nproc)
make install
popd

echo "=== Building xtensor ==="
pushd $DEPS/xtensor
git checkout 0.24.0
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX="$PREFIX"
make -j$(nproc)
make install
popd

echo "=== Building drogon ==="
pushd $DEPS/drogon
git submodule update --init --recursive
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX="$PREFIX"
make -j$(nproc)
make install
popd

echo "=== Building espeak-ng ==="
pushd $DEPS/espeak-ng
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX="$PREFIX"
make -j$(nproc)
make install
popd
export ESPEAK_DATA_PATH=$(pwd)/../deps/install/share/espeak-ng-data

echo "=== Building piper-phonemize ==="
pushd $DEPS/piper-phonemize
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX="$PREFIX"
make -j$(nproc)
make install
popd

echo "=== Downloading ONNX Runtime (aarch64 1.14.1) ==="
ORT_VERSION=1.14.1
ORT_DIR=$DEPS/onnxruntime-linux-aarch64-$ORT_VERSION
if [ ! -d "$ORT_DIR" ]; then
  wget https://github.com/microsoft/onnxruntime/releases/download/v$ORT_VERSION/onnxruntime-linux-aarch64-$ORT_VERSION.tgz
  tar -xzf onnxruntime-linux-aarch64-$ORT_VERSION.tgz -C $DEPS
fi

echo "=== Fetching ONNX/RKNN Models ==="
MODEL_DIR="onnx-model"
mkdir -p "$MODEL_DIR"

pushd "$MODEL_DIR"

if [ ! -f encoder.onnx ]; then
  wget -O encoder.onnx https://huggingface.co/marty1885/streaming-piper/resolve/main/ljspeech/encoder.onnx
fi

if [ ! -f decoder.onnx ]; then
  wget -O decoder.onnx https://huggingface.co/marty1885/streaming-piper/resolve/main/ljspeech/decoder.onnx
fi

if [ ! -f decoder.rknn ]; then
  wget -O decoder.rknn https://huggingface.co/marty1885/streaming-piper/resolve/main/ljspeech/decoder.rknn
fi

if [ ! -f config.json ]; then
  wget -O config.json https://huggingface.co/marty1885/streaming-piper/resolve/main/ljspeech/config.json
fi

popd
