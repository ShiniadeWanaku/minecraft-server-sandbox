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

# Google Drive folder ID where backups will be stored
FOLDER_ID = '1EjdUiLplKq_sBKi6jCSPqni2Qb7eazRs'

def authenticate():
    """Google Drive API authentication."""
    creds = None
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        with open('token.pickle', 'wb') as token:
            pickle.dump(creds, token)
    return creds

def compress_folder(folder_path):
    """Compress a folder into a zip file with the current date in Pacific Time."""
    pacific_time = pytz.timezone('US/Pacific')
    current_time = datetime.now(pacific_time)
    
    # Format the date for the filename
    timestamp = current_time.strftime("%Y-%m-%d")
    
    # Create the zip file name
    zip_filename = f"world-backup-{timestamp}.zip"
    
    # Compress the folder
    shutil.make_archive(zip_filename.replace('.zip', ''), 'zip', folder_path)
    print(f'Zip creado: {zip_filename}')
    return zip_filename

def get_existing_file_id(service, filename):
    """Check if a file with the given name exists in the Google Drive folder and return its file ID."""
    query = f"name='{filename}' and '{FOLDER_ID}' in parents and trashed=false"
    results = service.files().list(q=query, fields="files(id)").execute()
    
    files = results.get('files', [])
    return files[0]['id'] if files else None

def upload_or_update_file(file_path, mime_type='application/zip'):
    """Upload a new file or update an existing one in Google Drive."""
    creds = authenticate()
    service = build('drive', 'v3', credentials=creds)
    filename = os.path.basename(file_path)

    # Check if the file already exists
    file_id = get_existing_file_id(service, filename)

    media = MediaFileUpload(file_path, mimetype=mime_type, resumable=True)

    if file_id:
        # Update the existing file
        file = service.files().update(fileId=file_id, media_body=media).execute()
        print(f'Archivo actualizado con ID: {file["id"]}')
    else:
        # Upload a new file
        file_metadata = {'name': filename, 'parents': [FOLDER_ID]}
        file = service.files().create(body=file_metadata, media_body=media, fields='id').execute()
        print(f'Nuevo archivo subido con ID: {file["id"]}')

if __name__ == '__main__':
    # Path to the folder to be compressed
    zip_file = compress_folder(os.path.expanduser('~/minecraft-server/world/'))
    
    # Upload or update the file
    upload_or_update_file(zip_file)

    # Remove local zip file after uploading
    os.remove(zip_file)