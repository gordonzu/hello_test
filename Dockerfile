FROM elixir:1.17-otp-27

# Set working directory
WORKDIR /app

# Install additional dependencies (including Node.js + npm)
RUN apt-get update && apt-get install -y \
    ca-certificates \
    python3 \
    python-is-python3 \
    neovim \
    git \
    gcc \
    make \
    postgresql-client \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Expose Phoenix port
EXPOSE 4000

# Default command
CMD ["/bin/bash"]
