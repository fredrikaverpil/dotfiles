
# https://starship.rs

if [ ! -f /usr/local/bin/starship ]; then
  sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y
fi
