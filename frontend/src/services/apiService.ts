const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';

export interface UploadResponse {
  message: string;
  data?: {
    processed_count: number;
    error_count: number;
    errors: string[];
  };
  error?: string;
}

export interface UploadStatus {
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

  async getUploadStatus(): Promise<UploadStatus> {
    const response = await fetch(`${API_BASE_URL}/api/uploads/status`);
    
    if (!response.ok) {
      throw new Error('Erro ao buscar status');
    }

    return response.json();
  }
}

export default new ApiService(); 