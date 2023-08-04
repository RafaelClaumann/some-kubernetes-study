from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/validate', methods=['POST'])
def validating_endpoint():
    req = request.get_json()['request']

    app.logger.info('uid: %s, namespace: %s, name: %s', req['uid'], req['namespace'], req['name'])
    app.logger.info('userInfo: %s', req['userInfo'])
    app.logger.debug('object: %s', req['object'])

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
