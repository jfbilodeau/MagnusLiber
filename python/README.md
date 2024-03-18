## Getting started

0. Enter the demo directory
```shell
cd python
```

1. Create a `venv` (optional)
```shell
python3 -m venv venv
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

4. Run
```shell
export OPENAI_URL="https://<myresource>.openai.azure.com/"
export OPENAI_KEY="XXXXXXXXXXXXXXXXX"
export OPENAI_DEPLOYMENT="<mydeployment>"
python magnus_liber.py
```
