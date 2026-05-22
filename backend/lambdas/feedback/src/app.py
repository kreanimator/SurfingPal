import json
import logging
import os
import time

import boto3

sns = boto3.client('sns')
TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

RATING_LABELS = {1: 'Terrible', 2: 'Poor', 3: 'Okay', 4: 'Good', 5: 'Awesome'}

CORS_HEADERS = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST,OPTIONS',
    'Access-Control-Allow-Headers': 'content-type',
}


def lambda_handler(event, context):
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {'statusCode': 200, 'headers': CORS_HEADERS, 'body': ''}

    t0 = time.time()
    log = {'route': 'POST /api/feedback'}

    try:
        body = json.loads(event.get('body', '{}'))
        rating = body.get('rating')
        message = body.get('message', '').strip()

        if not rating or rating not in range(1, 6):
            log.update({'status': 400, 'reason': 'invalid_rating', 'ms': _ms(t0)})
            logger.info('%s', json.dumps(log))
            return {
                'statusCode': 400,
                'headers': CORS_HEADERS,
                'body': json.dumps({'error': 'Rating (1-5) is required'}),
            }

        stars = '★' * rating + '☆' * (5 - rating)
        label = RATING_LABELS.get(rating, '')

        sns.publish(
            TopicArn=TOPIC_ARN,
            Subject='SurfingPal Feedback: %s %s' % (stars, label),
            Message='Rating: %s (%d/5 - %s)\n\nMessage:\n%s\n' % (
                stars, rating, label, message if message else '(no message)'),
        )

        log.update({'status': 200, 'rating': rating, 'ms': _ms(t0)})
        logger.info('%s', json.dumps(log))
        return {
            'statusCode': 200,
            'headers': CORS_HEADERS,
            'body': json.dumps({'success': True}),
        }

    except Exception as e:
        log.update({'status': 500, 'error': str(e), 'ms': _ms(t0)})
        logger.error('%s', json.dumps(log))
        return {
            'statusCode': 500,
            'headers': CORS_HEADERS,
            'body': json.dumps({'error': str(e)}),
        }


def _ms(t0):
    return int((time.time() - t0) * 1000)
