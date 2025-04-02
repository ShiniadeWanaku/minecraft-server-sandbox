import os
import zipfile
import shutil
import pickle
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from datetime import datetime
import pytz

# Si modificas estos alcances, elimina el archivo token.pickle.
SCOPES = ['https://www.googleapis.com/auth/drive.file']

# Reemplaza con el ID de tu carpeta en Google Drive
FOLDER_ID = '1ZF7l059YxrzfZuxxTKuZbZt6mcsQ4Mit'

def authenticate():
    """Autenticación para la API de Google Drive."""
    creds = None
    # El archivo token.pickle guarda el token de acceso.
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)

    # Si no hay credenciales disponibles, deja que el usuario inicie sesión.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        # Guarda las credenciales para la próxima vez que se ejecute el script.
        with open('token.pickle', 'wb') as token:
            pickle.dump(creds, token)
    return creds

def compress_folder(folder_path):
    """Comprime la carpeta especificada en un archivo .zip con un nombre basado en la fecha y hora de Pacific Time."""
    # Obtener la fecha y hora actual en Pacific Time
    pacific_time = pytz.timezone('US/Pacific')
    current_time = datetime.now(pacific_time)
    
    # Formatear la fecha y hora en el formato deseado
    timestamp = current_time.strftime("%Y-%m-%d_%H-%M-%S")
    
    # Crear el nombre del archivo comprimido
    zip_filename = f"minecraft-server-backup-{timestamp}.zip"
    
    # Comprimir la carpeta
    shutil.make_archive(zip_filename.replace('.zip', ''), 'zip', folder_path)
    print(f'Carpeta comprimida: {zip_filename}')
    return zip_filename

def upload_file(file_path, mime_type='application/zip'):
    """Sube un archivo a Google Drive dentro de una carpeta específica."""
    creds = authenticate()
    service = build('drive', 'v3', credentials=creds)

    # Crea el archivo que se va a subir
    file_metadata = {
        'name': os.path.basename(file_path),
        'parents': [FOLDER_ID]  # Asignamos el archivo a la carpeta utilizando el ID directamente
    }
    media = MediaFileUpload(file_path, mimetype=mime_type)

    # Subir el archivo
    file = service.files().create(body=file_metadata, media_body=media, fields='id').execute()
    print(f'Archivo subido con ID: {file["id"]}')

if __name__ == '__main__':
    # Ruta de la carpeta que deseas comprimir y subir
    zip_file = compress_folder(os.path.expanduser('~'))
    # Borrar el archivo .zip después de subirlo
    os.remove(zip_file)
    upload_file(zip_file)
