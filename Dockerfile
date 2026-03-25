ARG PLATFORM=x86_64
FROM quay.io/pypa/manylinux_2_28_${PLATFORM}

# LLVM 18 runtime link dependencies
RUN dnf install -y \
    libffi-devel \
    zlib-devel \
    libzstd-devel \
    ncurses-devel \
    ncurses-compat-libs \
    libxml2-devel \
    && dnf clean all

# Install pre-built LLVM 18
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        LLVM_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        LLVM_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-aarch64-linux-gnu.tar.xz"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -sSfL "$LLVM_URL" -o /tmp/llvm.tar.xz && \
    mkdir -p /opt/llvm-18 && \
    tar -xf /tmp/llvm.tar.xz -C /opt/llvm-18 --strip-components=1 && \
    rm /tmp/llvm.tar.xz

ENV LLVM_SYS_180_PREFIX=/opt/llvm-18
ENV PATH="/opt/llvm-18/bin:${PATH}"

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
ENV PATH="/root/.cargo/bin:${PATH}"

# Install maturin
RUN /opt/python/cp313-cp313/bin/pip install maturin && \
    ln -s /opt/python/cp313-cp313/bin/maturin /usr/local/bin/maturin

WORKDIR /io
