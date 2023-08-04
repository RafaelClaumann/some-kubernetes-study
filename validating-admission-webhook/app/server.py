from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/validate', methods=['POST'])
def validating_endpoint():
    req = request.get_json()['request']

    app.logger.info('uid: %s, namespace: %s, operation: %s', req['uid'], req['namespace'], req['operation'])
    app.logger.info('userInfo: %s, options: %s', req['userInfo'], req['options'])
    app.logger.info('kind: %s, requestKind: %s', req['kind'], req['requestKind'])
    
    return jsonify(
        {
            'apiVersion': 'admission.k8s.io/v1',
            'kind': 'AdmissionReview',
            'response': {
                'uid': req['uid'],
                'allowed': True
            }
        }
    )
