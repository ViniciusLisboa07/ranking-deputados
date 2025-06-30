import React, { useState, useEffect } from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  LineChart,
  Line,
  AreaChart,
  Area
} from 'recharts';
import { ChartBarIcon, UsersIcon, CurrencyDollarIcon, DocumentTextIcon } from '@heroicons/react/24/outline';
import ApiService, { Statistics } from '../services/apiService';
import toast from 'react-hot-toast';

const COLORS = [
  '#8884d8', '#82ca9d', '#ffc658', '#ff7300', '#00ff00',
  '#ff00ff', '#00ffff', '#ff0000', '#0000ff', '#ffff00'
];

interface DashboardProps {
  onError?: (error: string) => void;
}

const Dashboard: React.FC<DashboardProps> = ({ onError }) => {
  const [statistics, setStatistics] = useState<Statistics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadStatistics();
  }, []);

  const loadStatistics = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await ApiService.getStatistics(10);
      setStatistics(data);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Erro ao carregar estatísticas';
      setError(errorMessage);
      onError?.(errorMessage);
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'BRL'
    }).format(value);
  };

  const formatNumber = (value: number) => {
    return new Intl.NumberFormat('pt-BR').format(value);
  };

  // Preparar dados para os gráficos
  const prepareUFData = () => {
    if (!statistics) return [];
    return Object.entries(statistics.data.distribuicoes.gastos_por_uf)
      .map(([uf, valor]) => ({
        uf,
        valor: Number(valor),
        deputados: statistics.data.distribuicoes.deputados_por_uf[uf] || 0
      }))
      .sort((a, b) => b.valor - a.valor)
      .slice(0, 10);
  };

  const preparePartidoData = () => {
    if (!statistics) return [];
    return Object.entries(statistics.data.distribuicoes.gastos_por_partido)
      .map(([partido, valor]) => ({
        partido,
        valor: Number(valor),
        deputados: statistics.data.distribuicoes.deputados_por_partido[partido] || 0
      }))
      .sort((a, b) => b.valor - a.valor)
      .slice(0, 8);
  };

  const prepareCategoriaData = () => {
    if (!statistics) return [];
    return Object.entries(statistics.data.rankings.top_categorias)
      .map(([categoria, valor]) => ({
        categoria: categoria.length > 20 ? categoria.substring(0, 20) + '...' : categoria,
        valor: Number(valor)
      }))
      .sort((a, b) => b.valor - a.valor)
      .slice(0, 8);
  };

  const prepareTop3GastadoresData = () => {
    if (!statistics || !statistics.data?.rankings?.top_gastadores) return [];
    return statistics.data.rankings.top_gastadores
      .slice(0, 3)
      .map((deputado, index) => {
        const posicao = index + 1;
        const medalha = posicao === 1 ? '🥇' : posicao === 2 ? '🥈' : '🥉';
        const cor = posicao === 1 ? '#FFD700' : posicao === 2 ? '#C0C0C0' : '#CD7F32';
        
        return {
          nome: `${medalha} ${posicao}º`,
          nomeCompleto: deputado.nome_display || `Deputado ID ${deputado.deputado_id}`,
          total_gasto: Number(deputado.total_gasto) || 0,
          uf: deputado.uf || '',
          partido: deputado.partido || '',
          deputado_id: deputado.deputado_id || deputado.id,
          posicao: posicao,
          cor: cor
        };
      });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen">
        <div className="text-red-500 text-xl mb-4">❌ {error}</div>
        <button
          onClick={loadStatistics}
          className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors"
        >
          Tentar Novamente
        </button>
      </div>
    );
  }

  console.log(statistics);

  if (!statistics) {
    return <div className="text-center text-gray-500">Nenhum dado disponível</div>;
  }

  return (
    <div className="max-w-7xl mx-auto p-6 space-y-8">
      {/* Header */}
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          📊 Dashboard de Gastos dos Deputados
        </h1>
        <p className="text-gray-600">
          Análise detalhada dos gastos parlamentares
        </p>
      </div>

      {/* Cards de Resumo */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg shadow-md border border-gray-200">
          <div className="flex items-center">
            <UsersIcon className="h-6 w-6 text-blue-500" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Total Deputados</p>
              <p className="text-2xl font-bold text-gray-900">
                {formatNumber(statistics.data.resumo.total_deputados)}
              </p>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md border border-gray-200">
          <div className="flex items-center">
            <CurrencyDollarIcon className="h-6 w-6 text-green-500" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Total Gastos</p>
              <p className="text-2xl font-bold text-gray-900">
                {formatCurrency(statistics.data.resumo.total_despesas)}
              </p>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md border border-gray-200">
          <div className="flex items-center">
            <ChartBarIcon className="h-6 w-6 text-purple-500" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Média por Deputado</p>
              <p className="text-2xl font-bold text-gray-900">
                {formatCurrency(statistics.data.resumo.valor_medio_por_deputado)}
              </p>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md border border-gray-200">
          <div className="flex items-center">
            <DocumentTextIcon className="h-6 w-6 text-orange-500" />
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-500">Refresh</p>
              <button
                onClick={loadStatistics}
                className="text-sm bg-blue-500 text-white px-3 py-1 rounded hover:bg-blue-600 transition-colors"
              >
                Atualizar
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Pódio dos Top 3 Gastadores */}
      <div className="bg-gradient-to-r from-yellow-50 to-orange-50 p-6 rounded-lg shadow-lg border border-yellow-200 mb-8">
        <h2 className="text-2xl font-bold text-center text-gray-900 mb-6">
          🏆 Pódio dos Maiores Gastadores
        </h2>
        <ResponsiveContainer width="100%" height={400}>
          <BarChart 
            data={prepareTop3GastadoresData()} 
            margin={{ top: 20, right: 30, left: 20, bottom: 80 }}
          >
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis 
              dataKey="nome" 
              angle={0}
              textAnchor="middle"
              height={60}
              interval={0}
              fontSize={14}
              fontWeight="bold"
            />
            <YAxis/>
            <Tooltip 
              formatter={(value, name, props) => [
                formatCurrency(Number(value)), 
                'Total Gasto'
              ]}
              labelFormatter={(label, payload) => {
                if (payload && payload.length > 0) {
                  const data = payload[0].payload;
                  return `${data.nomeCompleto} - ${data.uf}/${data.partido}`;
                }
                return label;
              }}
            />
            <Bar 
              dataKey="total_gasto" 
              radius={[8, 8, 0, 0]}
            >
              {prepareTop3GastadoresData().map((entry, index) => (
                <Cell key={`cell-${index}`} fill={entry.cor} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Gráficos */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Gastos por UF */}
        <div className="bg-white p-6 rounded-lg shadow-md border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
             Gastos por Estado (Top 10)
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={prepareUFData()}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="uf" />
              <YAxis tickFormatter={(value) => formatCurrency(value)} />
              <Tooltip formatter={(value) => [formatCurrency(Number(value)), 'Gastos']} />
              <Bar dataKey="valor" fill="#8884d8" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Gastos por Partido */}
        <div className="bg-white p-6 rounded-lg shadow-md border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
             Gastos por Partido (Top 8)
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={preparePartidoData()}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ partido, percent }) => `${partido} ${((percent || 0) * 100).toFixed(1)}%`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="valor"
              >
                {preparePartidoData().map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip formatter={(value) => [formatCurrency(Number(value)), 'Gastos']} />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Top Categorias */}
        <div className="bg-white p-6 rounded-lg shadow-md border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
             Categorias Mais Caras (Top 8)
          </h3>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={prepareCategoriaData()}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis 
                dataKey="categoria" 
                angle={-45}
                textAnchor="end"
                height={80}
              />
              <YAxis tickFormatter={(value) => formatCurrency(value)} />
              <Tooltip formatter={(value) => [formatCurrency(Number(value)), 'Gastos']} />
              <Area type="monotone" dataKey="valor" stroke="#ff7300" fill="#ff7300" fillOpacity={0.6} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};

export default Dashboard; 