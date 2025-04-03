# Import the necessary libraries
import os
import pytz
import shutil
import pickle
import zipfile
from datetime import datetime

# Import Google Drive API libraries
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow

# Create the scopes for the Google Drive API
SCOPES = ['https://www.googleapis.com/auth/drive.file']

# Create the folder ID where the files will be uploaded
FOLDER_ID = '1ZF7l059YxrzfZuxxTKuZbZt6mcsQ4Mit'

def authenticate():
    """Google Drive API authentication."""
    creds = None
    # The file token.pickle stores the user's access and refresh tokens, and is
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)

    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        # Save the credentials for the next run
        with open('token.pickle', 'wb') as token:
            pickle.dump(creds, token)
    return creds

def compress_folder(folder_path):
    """Compresse a folder into a zip file with the current date and time in Pacific Time."""
    # Obtain the current date and time in Pacific Time
    pacific_time = pytz.timezone('US/Pacific')
    current_time = datetime.now(pacific_time)
    
    # Format the date and time for the filename
    timestamp = current_time.strftime("%Y-%m-%d_%H-%M-%S")
    
    # Create the zip file name
    zip_filename = f"minecraft-server-backup-{timestamp}.zip"
    
    # Compress the folder
    shutil.make_archive(zip_filename.replace('.zip', ''), 'zip', folder_path)
    print(f'Zip: {zip_filename}')
    return zip_filename

def upload_file(file_path, mime_type='application/zip'):
    """Upload a file to Google Drive."""
    creds = authenticate()
    service = build('drive', 'v3', credentials=creds)

    # Create the file metadata
    file_metadata = {
        'name': os.path.basename(file_path),
        'parents': [FOLDER_ID]
    }
    media = MediaFileUpload(file_path, mimetype=mime_type)

    # Upload the file
    file = service.files().create(body=file_metadata, media_body=media, fields='id').execute()
    print(f'Archivo subido con ID: {file["id"]}')

if __name__ == '__main__':
    # Path to the folder to be compressed
    zip_file = compress_folder(os.path.expanduser('~/minecraft-server'))
    upload_file(zip_file)
    os.remove(os.path.expanduser('~/server-backend/'+ zip_file))
    