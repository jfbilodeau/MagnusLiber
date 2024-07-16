## Getting started

0. Enter the demo directory
```shell
cd python
```

1. Create a `venv` (optional)
```shell
python -m venv venv
```

2. Activate the `venv` (if using venv)

- On Windows:
```batch
venv\Scripts\activate.bat
```

- On Linux/MacOS:
```shell
source venv/bin/activate
```

3. Install requirements
```shell
pip install -r requirements.txt
```

4. Configure environment
- On Windows:
```PowerShell
$env:OPENAI_URL="https://<myresource>.openai.azure.com/"
$env:OPENAI_KEY="XXXXXXXXXXXXXXXXX"
$env:OPENAI_DEPLOYMENT="<mydeployment>"
```

- On Linux/MacOS
```shell
export OPENAI_URL="https://<myresource>.openai.azure.com/"
export OPENAI_KEY="XXXXXXXXXXXXXXXXX"
export OPENAI_DEPLOYMENT="<mydeployment>"
```

5. Run Magus Liber!
```shell
python magnus_liber.py
```