# lambda_function.py

import boto3
import json
import os
#from dotenv import load_dotenv
from PIL import Image
from io import BytesIO
import google.generativeai as genai
import logging

logger=logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def lambda_handler(event, context):
    logger.info(f"Event: {event}")
    try:
        for record in event['Records']:
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']

            response = s3_client.get_object(Bucket=bucket, Key=key)
            image_data = response['Body'].read()

            label = query_google_vision(image_data)
            logger.info(f"query complete for {key}: {label}")

            table.put_item(Item={
                'filename': key,
                'label': label
            })
            logger.info(f"label saved for {key}: {label}")
    except Exception as e:
        logger.error(f"Error processing file: {e}")

def query_google_vision(image_data):
    try:
        api_key = os.environ['GOOGLE_API_KEY']
        genai.configure(api_key=api_key)
        gemini_model = genai.GenerativeModel('gemini-pro-vision')
        text = 'Tell me what is in this image. Return results in json. Categorize using one of these labels. Reply with the label only. if confidence would be low, use label unknown: backhoe dumptruck-articulated dumptruck-doublebottom dumptruck-lowside dumptruck-rocktruck dumptruck-super10 elevating-scraper motorgrader pushpull-scraper skiploader track-dozer track-excavator track-loader track-skidsteer wheel-dozer wheel-excavator wheel-loader wheel-skidsteer'
        pil_image=Image.open(BytesIO(image_data))
        prompt = [text, pil_image]
        response=gemini_model.generate_content(prompt)
        cleaned_response = response.text.strip().replace('```json', '').replace('```', '').strip()
        label = json.loads(cleaned_response)
        return label
    except Exception as e:
        logger.error(f"Error querying Google Vision API: {e}")
        return "ERROR"