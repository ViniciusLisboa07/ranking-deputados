import React from 'react';
import './App.css';
import FileUpload from './components/FileUpload';
import { UploadResponse } from './services/apiService';

function App() {
  const handleUploadComplete = (response: UploadResponse) => {
    console.log('Upload completed:', response);
    // Aqui você pode adicionar lógica adicional após o upload
    // como atualizar outros componentes, mostrar notificações, etc.
  };

  return (
    <div className="App">
      <main style={{ padding: '40px 20px' }}>
        <FileUpload onUploadComplete={handleUploadComplete} />
      </main>
    </div>
  );
}

export default App;
