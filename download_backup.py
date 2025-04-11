import os
import io
import pytz
import pickle
import zipfile
from datetime import datetime
from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.http import MediaIoBaseDownload
from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = ['https://www.googleapis.com/auth/drive.readonly']
FOLDER_ID = '1ZF7l059YxrzfZuxxTKuZbZt6mcsQ4Mit'
DEST_DIR = os.path.expanduser('~/minecraft-server/restore')
UNZIP_DIR = os.path.expanduser('~/minecraft-server')

def authenticate():
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

def get_latest_backup_file(service):
    query = (
        f"'{FOLDER_ID}' in parents and name contains 'minecraft-server-backup-' "
        f"and mimeType = 'application/zip'"
    )
    results = service.files().list(
        q=query, orderBy='createdTime desc', pageSize=1, fields="files(id, name)"
    ).execute()
    files = results.get('files', [])
    return files[0] if files else None

def download_file(service, file_id, file_name, destination_folder):
    os.makedirs(destination_folder, exist_ok=True)
    file_path = os.path.join(destination_folder, file_name)
    request = service.files().get_media(fileId=file_id)
    with io.FileIO(file_path, 'wb') as fh:
        downloader = MediaIoBaseDownload(fh, request)
        done = False
        while not done:
            status, done = downloader.next_chunk()
            print(f"Downloading... {int(status.progress() * 100)}%")
    print(f"Downloaded file: {file_path}")
    return file_path

def unzip_file(zip_path, extract_to):
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_to)
    print(f"Unzipped file to: {extract_to}")
if __name__ == '__main__':
    creds = authenticate()
    service = build('drive', 'v3', credentials=creds)

    latest_file = get_latest_backup_file(service)
    if latest_file:
        file_id = latest_file['id']
        file_name = latest_file['name']
        zip_path = download_file(service, file_id, file_name, DEST_DIR)
        unzip_file(zip_path, UNZIP_DIR)
        os.remove(zip_path)
        print(f"Zip file {zip_path} removed.")
    else:
        print("No backup files found.")
