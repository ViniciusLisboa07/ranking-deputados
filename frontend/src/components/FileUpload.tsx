import React, { useState, useRef } from 'react';
import apiService, { UploadResponse } from '../services/apiService';

interface FileUploadProps {
  onUploadComplete?: (response: UploadResponse) => void;
}

const FileUpload: React.FC<FileUploadProps> = ({ onUploadComplete }) => {
  const [isUploading, setIsUploading] = useState(false);
  const [uploadResult, setUploadResult] = useState<UploadResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setSelectedFile(file);
      setError(null);
      setUploadResult(null);
    }
  };

  const handleUpload = async () => {
    if (!selectedFile) {
      setError('Por favor, selecione um arquivo CSV');
      return;
    }

    if (!selectedFile.name.toLowerCase().endsWith('.csv')) {
      setError('Por favor, selecione apenas arquivos CSV');
      return;
    }

    if (selectedFile.size > 80 * 1024 * 1024) {
      setError('Arquivo muito grande. Tamanho máximo: 80MB');
      return;
    }

    setIsUploading(true);
    setError(null);

    try {
      const response = await apiService.uploadFile(selectedFile);
      setUploadResult(response);
      onUploadComplete?.(response);
      
      setSelectedFile(null);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Erro desconhecido';
      setError(errorMessage);
    } finally {
      setIsUploading(false);
    }
  };

  const resetForm = () => {
    setSelectedFile(null);
    setError(null);
    setUploadResult(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const formatErrorMessage = (errorMessage: string) => {
    return errorMessage.split('\n').map((line, index) => (
      <div key={index} style={{ marginBottom: index < errorMessage.split('\n').length - 1 ? '5px' : '0' }}>
        {line}
      </div>
    ));
  };

  return (
    <div style={{ 
      border: '2px dashed #ccc', 
      borderRadius: '8px', 
      padding: '20px', 
      textAlign: 'center',
      maxWidth: '600px',
      margin: '0 auto'
    }}>
      <h3>Upload de Arquivo CSV</h3>
      
      <div style={{ marginBottom: '20px' }}>
        <input
          ref={fileInputRef}
          type="file"
          accept=".csv"
          onChange={handleFileSelect}
          disabled={isUploading}
          style={{ marginBottom: '10px' }}
        />
        
        {selectedFile && (
          <div style={{ fontSize: '14px', color: '#666', marginTop: '5px' }}>
            Arquivo selecionado: {selectedFile.name} ({(selectedFile.size / 1024 / 1024).toFixed(2)} MB)
          </div>
        )}
      </div>

      <div>
        <button
          onClick={handleUpload}
          disabled={!selectedFile || isUploading}
          style={{
            backgroundColor: selectedFile && !isUploading ? '#007bff' : '#ccc',
            color: 'white',
            border: 'none',
            padding: '10px 20px',
            borderRadius: '4px',
            cursor: selectedFile && !isUploading ? 'pointer' : 'not-allowed',
            marginRight: '10px'
          }}
        >
          {isUploading ? 'Enviando...' : 'Enviar Arquivo'}
        </button>

        <button
          onClick={resetForm}
          disabled={isUploading}
          style={{
            backgroundColor: '#6c757d',
            color: 'white',
            border: 'none',
            padding: '10px 20px',
            borderRadius: '4px',
            cursor: isUploading ? 'not-allowed' : 'pointer'
          }}
        >
          Limpar
        </button>
      </div>

      {error && (
        <div style={{ 
          marginTop: '20px', 
          color: '#721c24', 
          backgroundColor: '#f8d7da', 
          border: '1px solid #f5c6cb',
          borderRadius: '4px',
          padding: '15px',
          textAlign: 'left'
        }}>
          <strong>❌ Erro:</strong>
          <div style={{ marginTop: '8px' }}>
            {formatErrorMessage(error)}
          </div>
        </div>
      )}

      {uploadResult && (
        <div style={{ 
          marginTop: '20px', 
          color: '#155724', 
          backgroundColor: '#d4edda', 
          border: '1px solid #c3e6cb',
          borderRadius: '4px',
          padding: '15px',
          textAlign: 'left'
        }}>
          <strong>✅ {uploadResult.message}</strong>
          {uploadResult.data && (
            <div style={{ marginTop: '10px', fontSize: '14px' }}>
              <div>📊 Registros processados: <strong>{uploadResult.data.processed_count}</strong></div>
              <div>⚠️ Registros com erro: <strong>{uploadResult.data.error_count}</strong></div>
              {uploadResult.data.errors && uploadResult.data.errors.length > 0 && (
                <div style={{ marginTop: '10px' }}>
                  <strong>Erros encontrados:</strong>
                  <ul style={{ marginTop: '5px', paddingLeft: '20px' }}>
                    {uploadResult.data.errors.slice(0, 5).map((error, index) => (
                      <li key={index} style={{ fontSize: '12px', color: '#856404', marginBottom: '2px' }}>
                        {error}
                      </li>
                    ))}
                    {uploadResult.data.errors.length > 5 && (
                      <li style={{ fontSize: '12px', color: '#856404' }}>
                        ... e mais {uploadResult.data.errors.length - 5} erros
                      </li>
                    )}
                  </ul>
                </div>
              )}
            </div>
          )}
        </div>
      )}

      <div style={{ 
        marginTop: '20px', 
        fontSize: '12px', 
        color: '#6c757d',
        textAlign: 'left',
        backgroundColor: '#f8f9fa',
        padding: '15px',
        borderRadius: '4px',
        border: '1px solid #e9ecef'
      }}>
        <strong>📋 Requisitos do arquivo:</strong>
        <ul style={{ marginTop: '8px', paddingLeft: '20px' }}>
          <li>Formato: CSV (.csv)</li>
          <li>Tamanho máximo: 80MB</li>
          <li>Codificação: UTF-8 ou ISO-8859-1</li>
          <li>Separadores aceitos: vírgula (,) ou ponto e vírgula (;)</li>
          <li>Deve conter cabeçalhos nas colunas</li>
        </ul>
      </div>
    </div>
  );
};

export default FileUpload; 