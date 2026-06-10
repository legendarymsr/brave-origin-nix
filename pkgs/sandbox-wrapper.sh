if [ ! -x /run/wrappers/bin/chrome-sandbox ]; then
  sudo -n install -D -m 4755 -o root -g root "@out@/libexec/brave-nightly/chrome-sandbox" /run/wrappers/bin/chrome-sandbox 2>/dev/null || true
fi
if [ -x /run/wrappers/bin/chrome-sandbox ]; then
  export CHROME_DEVEL_SANDBOX=/run/wrappers/bin/chrome-sandbox
  SANDBOX_FLAG=""
else
  SANDBOX_FLAG="--no-sandbox"
fi
