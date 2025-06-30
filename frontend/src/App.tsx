import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import './App.css';
import Navigation from './components/Navigation';
import Dashboard from './components/Dashboard';
import FileUpload from './components/FileUpload';
import { UploadResponse } from './services/apiService';

function App() {
  const handleUploadComplete = (response: UploadResponse) => {
    console.log('Upload completed:', response);
    // Aqui você pode adicionar lógica adicional após o upload
    // como atualizar outros componentes, mostrar notificações, etc.
  };

  const handleError = (error: string) => {
    console.error('Application error:', error);
  };

  return (
    <Router>
      <div className="App min-h-screen bg-gray-50">
        <Navigation />
        
        <main>
          <Routes>
            <Route 
              path="/" 
              element={<Dashboard onError={handleError} />} 
            />
            <Route 
              path="/upload" 
              element={
                <div style={{ padding: '40px 20px' }}>
                  <FileUpload onUploadComplete={handleUploadComplete} />
                </div>
              } 
            />
          </Routes>
        </main>

        {/* Toast notifications */}
        <Toaster
          position="top-right"
          toastOptions={{
            duration: 4000,
            style: {
              background: '#363636',
              color: '#fff',
            },
            success: {
              duration: 3000,
              style: {
                background: 'green',
              },
            },
            error: {
              duration: 5000,
              style: {
                background: 'red',
              },
            },
          }}
        />
      </div>
    </Router>
  );
}

export default App;
