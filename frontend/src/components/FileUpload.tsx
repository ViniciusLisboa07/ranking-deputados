import React, { useState, useRef, useEffect } from 'react';
import apiService, { UploadResponse, UploadStatus } from '../services/apiService';

interface FileUploadProps {
  onUploadComplete?: (response: UploadStatus) => void;
}

const FileUpload: React.FC<FileUploadProps> = ({ onUploadComplete }) => {
  const [isUploading, setIsUploading] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [uploadStatus, setUploadStatus] = useState<UploadStatus | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [currentUploadId, setCurrentUploadId] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    return () => {
      if (currentUploadId) {
        setCurrentUploadId(null);
      }
    };
  }, [currentUploadId]);

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setSelectedFile(file);
      setError(null);
      setUploadStatus(null);
      setCurrentUploadId(null);
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
      
      if (response.upload_id) {
        setCurrentUploadId(response.upload_id);
        setIsProcessing(true);
        
        apiService.pollUploadStatus(
          response.upload_id,
          (status) => {
            setUploadStatus(status);
            
            if (status.status === 'processing') {
              setIsProcessing(true);
            }
          }
        ).then((finalStatus) => {
          setIsProcessing(false);
          setUploadStatus(finalStatus);
          onUploadComplete?.(finalStatus);
          
          setSelectedFile(null);
          if (fileInputRef.current) {
            fileInputRef.current.value = '';
          }
        }).catch((err) => {
          setIsProcessing(false);
          setError(err instanceof Error ? err.message : 'Erro no processamento');
        });
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
    setUploadStatus(null);
    setCurrentUploadId(null);
    setIsProcessing(false);
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

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'queued': return '#ffc107';
      case 'processing': return '#007bff';
      case 'completed': return '#28a745';
      case 'failed': return '#dc3545';
      default: return '#6c757d';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'queued': return '⏳';
      case 'processing': return '⚙️';
      case 'completed': return '✅';
      case 'failed': return '❌';
      default: return '❓';
    }
  };

  const getStatusMessage = (status: string) => {
    switch (status) {
      case 'queued': return 'Na fila de processamento';
      case 'processing': return 'Processando arquivo...';
      case 'completed': return 'Processamento concluído';
      case 'failed': return 'Falha no processamento';
      default: return 'Status desconhecido';
    }
  };

  const isDisabled = isUploading || isProcessing;

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
          disabled={isDisabled}
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
          disabled={!selectedFile || isDisabled}
          style={{
            backgroundColor: selectedFile && !isDisabled ? '#007bff' : '#ccc',
            color: 'white',
            border: 'none',
            padding: '10px 20px',
            borderRadius: '4px',
            cursor: selectedFile && !isDisabled ? 'pointer' : 'not-allowed',
            marginRight: '10px'
          }}
        >
          {isUploading ? 'Enviando...' : isProcessing ? 'Processando...' : 'Enviar Arquivo'}
        </button>

        <button
          onClick={resetForm}
          disabled={isDisabled}
          style={{
            backgroundColor: '#6c757d',
            color: 'white',
            border: 'none',
            padding: '10px 20px',
            borderRadius: '4px',
            cursor: isDisabled ? 'not-allowed' : 'pointer'
          }}
        >
          Limpar
        </button>
      </div>

      {/* Status do processamento */}
      {uploadStatus && (
        <div style={{ 
          marginTop: '20px', 
          padding: '15px',
          borderRadius: '4px',
          textAlign: 'left',
          backgroundColor: '#f8f9fa',
          border: `2px solid ${getStatusColor(uploadStatus.status)}`
        }}>
          <div style={{ 
            fontSize: '16px', 
            fontWeight: 'bold', 
            color: getStatusColor(uploadStatus.status),
            marginBottom: '10px'
          }}>
            {getStatusIcon(uploadStatus.status)} {getStatusMessage(uploadStatus.status)}
          </div>
          
          <div style={{ fontSize: '14px', marginBottom: '8px' }}>
            {uploadStatus.message}
          </div>

          {uploadStatus.status === 'processing' && (
            <div style={{ fontSize: '12px', color: '#666' }}>
              Processando em background... Atualizando automaticamente.
            </div>
          )}

          {uploadStatus.result && (
            <div style={{ marginTop: '10px', fontSize: '14px' }}>
              <div>📊 Registros processados: <strong>{uploadStatus.result.processed_count}</strong></div>
              <div>⚠️ Registros com erro: <strong>{uploadStatus.result.error_count}</strong></div>
              {uploadStatus.result.errors && uploadStatus.result.errors.length > 0 && (
                <div style={{ marginTop: '10px' }}>
                  <strong>Erros encontrados:</strong>
                  <ul style={{ marginTop: '5px', paddingLeft: '20px' }}>
                    {uploadStatus.result.errors.slice(0, 5).map((error, index) => (
                      <li key={index} style={{ fontSize: '12px', color: '#856404', marginBottom: '2px' }}>
                        {error}
                      </li>
                    ))}
                    {uploadStatus.result.errors.length > 5 && (
                      <li style={{ fontSize: '12px', color: '#856404' }}>
                        ... e mais {uploadStatus.result.errors.length - 5} erros
                      </li>
                    )}
                  </ul>
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* Erros */}
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
          <li>Separador: ponto e vírgula (;)</li>
          <li>Codificação: UTF-8</li>
          <li>Deve conter cabeçalhos nas colunas</li>
        </ul>
      </div>
    </div>
  );
};

export default FileUpload; 