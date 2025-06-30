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

export interface Statistics {
  data: {
    resumo: {
      total_deputados: number;
      total_despesas: number;
      valor_medio_por_deputado: number;
    };
    distribuicoes: {
      deputados_por_uf: Record<string, number>;
      deputados_por_partido: Record<string, number>;
      gastos_por_uf: Record<string, number>;
      gastos_por_partido: Record<string, number>;
    };
    rankings: {
      top_gastadores: Array<{
        id: number;
        nome: string;
        nome_display: string;
        uf: string;
        partido: string;
        deputado_id: number;
        carteira_parlamentar: string;
        total_gasto: number;
      }>;
      top_categorias: Record<string, number>;
    };
  }
}

export interface Deputado {
  id: number;
  nome: string;
  cpf: string;
  carteira_parlamentar: string;
  uf: string;
  partido: string;
  deputado_id: number;
  total_despesas: number;
  total_documentos: number;
  created_at: string;
  updated_at: string;
}

export interface DeputadosResponse {
  data: Deputado[];
  pagination: {
    current_page: number;
    per_page: number;
    total_count: number;
    total_pages: number;
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

  async getStatistics(limit?: number): Promise<Statistics> {
    const url = new URL(`${API_BASE_URL}/api/deputados/statistics`);
    if (limit) {
      url.searchParams.append('limit', limit.toString());
    }

    const response = await fetch(url.toString());
    
    if (!response.ok) {
      throw new Error('Erro ao buscar estatísticas');
    }

    return response.json();
  }

  async getDeputados(params?: {
    uf?: string;
    partido?: string;
    search?: string;
    order_by?: string;
    page?: number;
    per_page?: number;
  }): Promise<DeputadosResponse> {
    const url = new URL(`${API_BASE_URL}/api/deputados`);
    
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined && value !== null && value !== '') {
          url.searchParams.append(key, value.toString());
        }
      });
    }

    const response = await fetch(url.toString());
    
    if (!response.ok) {
      throw new Error('Erro ao buscar deputados');
    }

    return response.json();
  }

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