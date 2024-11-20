# rankinator

## Setup

```bash
# If you use nix, otherwise install python & venv deps manually
nix develop
# Enable venv
python -m venv .venv
source venv/bin/activate
pip install -r requirements.txt

# if using nix, make sure to fix python .so files
nix run github:GuillaumeDesforges/fix-python -- --venv .venv
```