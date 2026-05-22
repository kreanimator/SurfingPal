import json
import os
import boto3

sns = boto3.client('sns')
TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

RATING_LABELS = {1: 'Terrible', 2: 'Poor', 3: 'Okay', 4: 'Good', 5: 'Awesome'}


def lambda_handler(event, context):
    headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST,OPTIONS',
        'Access-Control-Allow-Headers': 'content-type',
    }

    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {'statusCode': 200, 'headers': headers, 'body': ''}

    try:
        body = json.loads(event.get('body', '{}'))
        rating = body.get('rating')
        message = body.get('message', '').strip()

        if not rating or rating not in range(1, 6):
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': 'Rating (1-5) is required'}),
            }

        stars = '★' * rating + '☆' * (5 - rating)
        label = RATING_LABELS.get(rating, '')

        subject = f'SurfingPal Feedback: {stars} {label}'

        email_body = (
            f'Rating: {stars} ({rating}/5 - {label})\n'
            f'\n'
            f'Message:\n{message if message else "(no message)"}\n'
        )

        sns.publish(
            TopicArn=TOPIC_ARN,
            Subject=subject,
            Message=email_body,
        )

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'success': True}),
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': str(e)}),
        }
