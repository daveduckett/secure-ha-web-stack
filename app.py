import boto3
import json
from flask import Flask, request
import pymysql
import requests
from botocore.exceptions import ClientError
REGION_NAME = "us-east-1"
SECRET_NAME = "secrets_vault_v4"

# Instantiate the Flask object
app = Flask(__name__)
    
# Obtain secret credentials from AWS Secrets Manager to use on the DB
def get_secret(secret_client, secret_name) -> dict:
    try:
        get_secret_value_response = secret_client.get_secret_value(
            SecretId=SECRET_NAME
        )
        
        # Create the whole secrets dictionary
        secret: str = get_secret_value_response.get('SecretString')
        secret_credentials: dict[str, str] = json.loads(secret)
        
        return secret_credentials
        
    except ClientError as e:
        return {
            "status": "FAILURE",
            "message": f"Credentials invalid or incorrect: {e}"
        }, 400

# Initiate the DB connection
def get_db_connection(secret_credentials):
    request_parameters: dict[str, any] = {
        'user': secret_credentials.get('username', ''),
        'password': secret_credentials.get('password', ''),
        'host': secret_credentials.get('host', ''),
        'database': secret_credentials.get('db_name', ''),
        'port': secret_credentials.get('port', None)
    }
    
    try:
        db_connection = pymysql.connect(**request_parameters)
        
        return db_connection
    except ConnectionError as e:
        print(f"Error Connecting to Database, check connection and parameters: {e}")
        
def init_db(db_connection):
    try:
        cursor = db_connection.cursor()
        return cursor
    except pymysql.OperationalError as e:
        return {
            "status": "FAILURE",
            "message": f"Failed to create Database cursor: {e}"
        }, 500
    
def create_db_table(cursor):
    try: 
        cursor.execute(
            '''
            CREATE TABLE IF NOT EXISTS request_logs (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_ip VARCHAR(45),
                instance_id VARCHAR(50),
                az VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            '''
        )
        
        return "Table Creation Succeed!", 200
    except pymysql.OperationalError as e:
        return {
            "status": "FAILURE",
            "message": f"Failed to create table: {e}"
        }, 400
    
    
def db_insert(cursor, values: tuple):
    try:
        sql = "INSERT INTO request_logs (user_ip, instance_id, az) VALUES (%s, %s, %s)"

        cursor.execute(sql, values)
    except pymysql.OperationalError as e:
        return {
            "status": "FAILURE",
            "message": f"Unable to insert data, check values: {e}"
        }, 500

def commit_db(db_connection):
    try:
        db_connection.commit()
    except pymysql.OperationalError as e:
        return {
            "status": "FAILURE",
            "message": f"Failed to commit the Database connection: {e}"
        }, 500
            

# Function to obtain the security token needed to access DB
def get_imds_token():
    token_url = 'http://169.254.169.254/latest/api/token'
    headers = {"X-aws-ec2-metadata-token-ttl-seconds": "21600"}
    
    try:
        token_response = requests.put(token_url, headers=headers, timeout=2)
        token = token_response.text
        
        return token

    except Exception as e:
        print(f"Error fetching token: {e}")
        return "local-dev"
    
# Instance ID retrieval to log into the DB. Requires token from get_imds_token
def get_instance_id(token):
    instance_id_url = 'http://169.254.169.254/latest/meta-data/instance-id'
    token_header = {"X-aws-ec2-metadata-token": token}
    
    try: 
        instance_id_request = requests.get(instance_id_url, headers=token_header, timeout=2)
        instance_id = instance_id_request.text
        return instance_id
        
    except Exception as e:
        print(f"Error fetching instance_id: {e}")
        return "local-dev"
        
# Get AZ information to log into DB. Requires token from get_imds_token
def get_availability_zone(token):
    az_url = 'http://169.254.169.254/latest/meta-data/placement/availability-zone'
    token_header = {"X-aws-ec2-metadata-token": token}
    
    try:
        az_url_request = requests.get(az_url, headers=token_header, timeout=2)
        availability_zone = az_url_request.text
        return availability_zone
    
    except Exception as e:
        print(f"Error fetching AZ info: {e}")
        return "local-dev"

session = boto3.session.Session()
secret_client = session.client(
    service_name='secretsmanager',
    region_name=REGION_NAME
)

@app.route('/')
def log_request():
    # Create a Secrets Manager client
    session = boto3.session.Session()
    secret_client = session.client(
        service_name='secretsmanager',
        region_name=REGION_NAME
    )
    
    try:
        db_connection = None
        token = get_imds_token()
    
        instance_id = get_instance_id(token)
        availability_zone = get_availability_zone(token)

        user_identity = request.headers.get('X-Forwarded-For', request.remote_addr)
        response_dictionary = {
            "status": "SUCCESS",
            "user_ip": user_identity,
            "server_id": instance_id,
            "az": availability_zone,
            "message": "Request Operation Fully Successful!"
        }
        
        values_to_insert = (user_identity, instance_id, availability_zone)
        
        db_credentials = get_secret(secret_client, SECRET_NAME)
        db_connection = get_db_connection(db_credentials)
        
        # Initiate the Database
        db_cursor = init_db(db_connection)
        
        # Create the Table in the Database
        create_db_table(db_cursor)
        
        # Insert the request data in the request_logs table
        db_insert(db_cursor, values_to_insert)
        
        # Commit and close the change
        commit_db(db_connection)
        
        return response_dictionary, 200
    except FileNotFoundError as e:
        return {
            "status": "FAILURE",
            "message": f"The requested file or path does not exist: {e}"
        }, 400
    except ConnectionError as e:
        return {
            "status": "FAILURE",
            "message": f"Failed to connect, connection dropped or could not establish: {e}"
        }, 500
    except Exception as e:
        return {
            "status": "FAILURE",
            "message": f"Unknown Error Detected: {e}"
        }
    finally:
        if db_connection:
            db_connection.close()

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True)
    

