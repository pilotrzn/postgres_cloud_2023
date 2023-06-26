import os
import json

from flask import Flask

app = Flask(__name__)

def readSettings():
    with open("/config/game.properties", "r") as f:
        return f.readlines()

@app.route("/")
def hello():
    return json.dumps({    
        'HOSTNAME': os.environ['HOSTNAME'],
        'PLAYER_INITIAL_LIVES': os.environ.get('PLAYER_INITIAL_LIVES', '7'),
        'DATA': readSettings(),
        'PASSWORD': os.environ.get('PASSWORD', '123'),
    })

if __name__ == "__main__":
    app.run(host='0.0.0.0', port='80', debug=True)
