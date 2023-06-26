import os
import json
from pathlib import Path

from flask import Flask
from flask import request

app = Flask(__name__)

stateFileName = '/storage/state.txt'

def readState():
    return Path(stateFileName).read_text()
    
def writeState(state):
    return Path(stateFileName).write_text(state)    

@app.route("/")
def root():
    return json.dumps({    
        'HOSTNAME': os.environ['HOSTNAME'],
        'STATE': readState(),
    })
    
@app.route("/set")
def set():
    data = request.args.get('data')
    writeState(data)
    return "save"
    

if __name__ == "__main__":
    app.run(host='0.0.0.0', port='80', debug=True)
