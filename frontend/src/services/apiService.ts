const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';

export interface UploadResponse {
  message: string;
  upload_id?: string;
  status_url?: string;
  data?: {
    processed_count: number;
    error_count: number;
    errors: string[];
  };
  error?: string;
}

export interface UploadStatus {
  upload_id: string;
  status: 'queued' | 'processing' | 'completed' | 'failed';
  message: string;
  result?: {
    success: boolean;
    processed_count: number;
    error_count: number;
    errors: string[];
  };
  error?: string;
  queued_at?: string;
  started_at?: string;
  completed_at?: string;
}

export interface DatabaseStatus {
  message: string;
  data: {
    deputados_count: number;
    despesas_count: number;
    last_updated: string | null;
  };
}

class ApiService {
  async uploadFile(file: File): Promise<UploadResponse> {
    const formData = new FormData();
    formData.append('file', file);

    const response = await fetch(`${API_BASE_URL}/api/uploads`, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.message || 'Erro ao enviar arquivo');
    }

    return response.json();
  }

  async getUploadStatus(uploadId: string): Promise<UploadStatus> {
    const response = await fetch(`${API_BASE_URL}/api/uploads/${uploadId}/status`);
    
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.message || 'Erro ao buscar status do upload');
    }

    return response.json();
  }

  async getDatabaseStatus(): Promise<DatabaseStatus> {
    const response = await fetch(`${API_BASE_URL}/api/uploads/status`);
    
    if (!response.ok) {
      throw new Error('Erro ao buscar status do banco de dados');
    }

    return response.json();
  }

  // Método para fazer polling do status até completar
  async pollUploadStatus(uploadId: string, onStatusUpdate?: (status: UploadStatus) => void): Promise<UploadStatus> {
    return new Promise((resolve, reject) => {
      const poll = async () => {
        try {
          const status = await this.getUploadStatus(uploadId);
          
          if (onStatusUpdate) {
            onStatusUpdate(status);
          }
          
          if (status.status === 'completed' || status.status === 'failed') {
            resolve(status);
          } else {
            // Continuar polling a cada 2 segundos
            setTimeout(poll, 2000);
          }
        } catch (error) {
          reject(error);
        }
      };
      
      poll();
    });
  }
}

export default new ApiService(); 