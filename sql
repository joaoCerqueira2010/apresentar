-- =====================================================
-- BANCO DE DADOS: NAVALHAS BARBER
-- Sistema de Agendamento para Barbearia
-- Versão: 1.0
-- Data: 2024
-- =====================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- =====================================================
-- TABELA: USUARIOS (Administradores/Barbeiros)
-- =====================================================
CREATE TABLE IF NOT EXISTS usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    senha_hash TEXT NOT NULL,
    telefone TEXT,
    cpf TEXT UNIQUE,
    cargo TEXT NOT NULL CHECK(cargo IN ('admin', 'gerente', 'barbeiro', 'recepcao')),
    avatar TEXT,
    comissao_percentual REAL DEFAULT 0.0,
    ativo INTEGER DEFAULT 1,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    ultimo_acesso DATETIME
);

-- =====================================================
-- TABELA: CLIENTES
-- =====================================================
CREATE TABLE IF NOT EXISTS clientes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    telefone TEXT NOT NULL,
    email TEXT,
    cpf TEXT UNIQUE,
    data_nascimento DATE,
    endereco TEXT,
    cidade TEXT,
    observacoes TEXT,
    pontos_fidelidade INTEGER DEFAULT 0,
    total_gasto REAL DEFAULT 0.0,
    ultima_visita DATE,
    ativo INTEGER DEFAULT 1,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABELA: SERVICOS
-- =====================================================
CREATE TABLE IF NOT EXISTS servicos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    descricao TEXT,
    preco REAL NOT NULL,
    duracao_minutos INTEGER NOT NULL DEFAULT 30,
    categoria TEXT CHECK(categoria IN ('corte', 'barba', 'combo', 'coloracao', 'tratamento', 'infantil', 'outros')),
    icone TEXT,
    ativo INTEGER DEFAULT 1,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABELA: HORARIOS_FUNCIONAMENTO
-- =====================================================
CREATE TABLE IF NOT EXISTS horarios_funcionamento (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    dia_semana INTEGER NOT NULL CHECK(dia_semana BETWEEN 0 AND 6), -- 0=Domingo, 6=Sábado
    hora_abertura TIME NOT NULL,
    hora_fechamento TIME NOT NULL,
    intervalo_inicio TIME,
    intervalo_fim TIME,
    fechado INTEGER DEFAULT 0,
    UNIQUE(dia_semana)
);

-- =====================================================
-- TABELA: AGENDAMENTOS
-- =====================================================
CREATE TABLE IF NOT EXISTS agendamentos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id INTEGER NOT NULL,
    barbeiro_id INTEGER NOT NULL,
    servico_id INTEGER NOT NULL,
    data_agendamento DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fim TIME NOT NULL,
    status TEXT NOT NULL DEFAULT 'pendente' 
        CHECK(status IN ('pendente', 'confirmado', 'em_andamento', 'concluido', 'cancelado', 'nao_compareceu')),
    valor REAL NOT NULL,
    observacoes TEXT,
    forma_pagamento TEXT CHECK(forma_pagamento IN ('dinheiro', 'pix', 'cartao_credito', 'cartao_debito', 'outros')),
    pago INTEGER DEFAULT 0,
    criado_por INTEGER,
    data_criacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE RESTRICT,
    FOREIGN KEY (barbeiro_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    FOREIGN KEY (servico_id) REFERENCES servicos(id) ON DELETE RESTRICT,
    FOREIGN KEY (criado_por) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- =====================================================
-- TABELA: PRODUTOS (Loja/Estoque)
-- =====================================================
CREATE TABLE IF NOT EXISTS produtos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT NOT NULL,
    descricao TEXT,
    categoria TEXT CHECK(categoria IN ('pomada', 'shampoo', 'condicionador', 'oleo', 'perfume', 'acessorio', 'outros')),
    marca TEXT,
    preco_custo REAL DEFAULT 0.0,
    preco_venda REAL NOT NULL,
    estoque_atual INTEGER DEFAULT 0,
    estoque_minimo INTEGER DEFAULT 5,
    ativo INTEGER DEFAULT 1,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABELA: VENDAS_PRODUTOS
-- =====================================================
CREATE TABLE IF NOT EXISTS vendas_produtos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    produto_id INTEGER NOT NULL,
    cliente_id INTEGER,
    vendedor_id INTEGER,
    quantidade INTEGER NOT NULL DEFAULT 1,
    preco_unitario REAL NOT NULL,
    total REAL NOT NULL,
    forma_pagamento TEXT CHECK(forma_pagamento IN ('dinheiro', 'pix', 'cartao_credito', 'cartao_debito')),
    data_venda DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE RESTRICT,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE SET NULL,
    FOREIGN KEY (vendedor_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- =====================================================
-- TABELA: PAGAMENTOS
-- =====================================================
CREATE TABLE IF NOT EXISTS pagamentos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agendamento_id INTEGER,
    venda_produto_id INTEGER,
    valor REAL NOT NULL,
    forma_pagamento TEXT NOT NULL,
    status TEXT DEFAULT 'pago' CHECK(status IN ('pago', 'pendente', 'estornado')),
    data_pagamento DATETIME DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT,
    FOREIGN KEY (agendamento_id) REFERENCES agendamentos(id) ON DELETE SET NULL,
    FOREIGN KEY (venda_produto_id) REFERENCES vendas_produtos(id) ON DELETE SET NULL
);

-- =====================================================
-- TABELA: AVALIACOES (Feedback dos clientes)
-- =====================================================
CREATE TABLE IF NOT EXISTS avaliacoes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agendamento_id INTEGER NOT NULL,
    cliente_id INTEGER NOT NULL,
    barbeiro_id INTEGER NOT NULL,
    nota INTEGER NOT NULL CHECK(nota BETWEEN 1 AND 5),
    comentario TEXT,
    data_avaliacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (agendamento_id) REFERENCES agendamentos(id) ON DELETE CASCADE,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE,
    FOREIGN KEY (barbeiro_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- =====================================================
-- TABELA: LOGS (Auditoria)
-- =====================================================
CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id INTEGER,
    acao TEXT NOT NULL,
    tabela_afetada TEXT,
    registro_id INTEGER,
    detalhes TEXT,
    ip TEXT,
    data_log DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- =====================================================
-- ÍNDICES PARA PERFORMANCE
-- =====================================================
CREATE INDEX idx_agendamentos_data ON agendamentos(data_agendamento);
CREATE INDEX idx_agendamentos_barbeiro ON agendamentos(barbeiro_id);
CREATE INDEX idx_agendamentos_cliente ON agendamentos(cliente_id);
CREATE INDEX idx_agendamentos_status ON agendamentos(status);
CREATE INDEX idx_clientes_telefone ON clientes(telefone);
CREATE INDEX idx_clientes_nome ON clientes(nome);
CREATE INDEX idx_produtos_estoque ON produtos(estoque_atual);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger: Atualiza data_atualizacao dos agendamentos
CREATE TRIGGER IF NOT EXISTS trg_agendamentos_update
AFTER UPDATE ON agendamentos
FOR EACH ROW
BEGIN
    UPDATE agendamentos 
    SET data_atualizacao = CURRENT_TIMESTAMP 
    WHERE id = NEW.id;
END;

-- Trigger: Atualiza total gasto e última visita do cliente
CREATE TRIGGER IF NOT EXISTS trg_cliente_pos_agendamento
AFTER UPDATE OF status ON agendamentos
FOR EACH ROW
WHEN NEW.status = 'concluido' AND OLD.status != 'concluido'
BEGIN
    UPDATE clientes 
    SET total_gasto = total_gasto + NEW.valor,
        ultima_visita = NEW.data_agendamento,
        pontos_fidelidade = pontos_fidelidade + CAST(NEW.valor / 10 AS INTEGER)
    WHERE id = NEW.cliente_id;
END;

-- Trigger: Baixa estoque ao vender produto
CREATE TRIGGER IF NOT EXISTS trg_baixa_estoque
AFTER INSERT ON vendas_produtos
FOR EACH ROW
BEGIN
    UPDATE produtos 
    SET estoque_atual = estoque_atual - NEW.quantidade
    WHERE id = NEW.produto_id;
END;

-- =====================================================
-- DADOS INICIAIS
-- =====================================================

-- Usuários (senhas em produção devem ser hasheadas com bcrypt)
INSERT INTO usuarios (nome, email, senha_hash, telefone, cargo, comissao_percentual) VALUES
('Naldo Alves', 'naldo@navalhasbarber.com', '$2b$10$hash_exemplo1', '(11) 99999-1111', 'admin', 0),
('Rafa Fernandes', 'rafa@navalhasbarber.com', '$2b$10$hash_exemplo2', '(11) 99999-2222', 'barbeiro', 40),
('Beto Trindade', 'beto@navalhasbarber.com', '$2b$10$hash_exemplo3', '(11) 99999-3333', 'barbeiro', 35),
('Carla Souza', 'carla@navalhasbarber.com', '$2b$10$hash_exemplo4', '(11) 99999-4444', 'recepcao', 0);

-- Serviços
INSERT INTO servicos (nome, descricao, preco, duracao_minutos, categoria, icone) VALUES
('Corte Navalhado', 'Corte masculino com acabamento na navalha', 55.00, 40, 'corte', 'fa-cut'),
('Barba Terapia', 'Modelagem de barba com toalha quente e óleo', 45.00, 30, 'barba', 'fa-user-tie'),
('Combo Navalha Premium', 'Corte + barba + hidratação', 85.00, 70, 'combo', 'fa-crown'),
('Corte Infantil', 'Corte para crianças até 12 anos', 40.00, 30, 'infantil', 'fa-child'),
('Pezinho / Acabamento', 'Apenas o acabamento da nuca e lateral', 20.00, 15, 'corte', 'fa-cut'),
('Platinado', 'Descoloração global com tonalizante', 150.00, 120, 'coloracao', 'fa-palette'),
('Hidratação Capilar', 'Tratamento com produtos premium', 60.00, 40, 'tratamento', 'fa-spa'),
('Sobrancelha', 'Design de sobrancelha masculina', 25.00, 15, 'outros', 'fa-eye');

-- Clientes
INSERT INTO clientes (nome, telefone, email, cpf, data_nascimento, pontos_fidelidade, total_gasto) VALUES
('João Pedro Silva', '(11) 98765-4321', 'joao.pedro@email.com', '123.456.789-01', '1990-05-15', 45, 450.00),
('Marcos Andrade', '(11) 97654-3210', 'marcos@email.com', '234.567.890-12', '1985-08-22', 32, 320.00),
('Lucas Ribeiro', '(11) 96543-2109', 'lucas.r@email.com', '345.678.901-23', '1992-11-10', 28, 280.00),
('André Costa', '(11) 95432-1098', 'andre.costa@email.com', '456.789.012-34', '1988-03-05', 55, 550.00),
('Pedro Henrique', '(11) 94321-0987', NULL, NULL, '2015-07-18', 12, 120.00),
('Carlos Eduardo', '(11) 93210-9876', 'carlos.edu@email.com', '567.890.123-45', '1995-12-01', 8, 80.00);

-- Horários de funcionamento
INSERT INTO horarios_funcionamento (dia_semana, hora_abertura, hora_fechamento, intervalo_inicio, intervalo_fim, fechado) VALUES
(0, '09:00', '13:00', NULL, NULL, 1),  -- Domingo - fechado
(1, '09:00', '20:00', '12:00', '13:00', 0),  -- Segunda
(2, '09:00', '20:00', '12:00', '13:00', 0),  -- Terça
(3, '09:00', '20:00', '12:00', '13:00', 0),  -- Quarta
(4, '09:00', '21:00', '12:00', '13:00', 0),  -- Quinta
(5, '09:00', '21:00', '12:00', '13:00', 0),  -- Sexta
(6, '08:00', '18:00', '12:00', '13:00', 0);  -- Sábado

-- Produtos
INSERT INTO produtos (nome, descricao, categoria, marca, preco_custo, preco_venda, estoque_atual, estoque_minimo) VALUES
('Pomada Modeladora Efeito Matte', 'Fixação forte com efeito seco', 'pomada', 'QOD Barber', 25.00, 55.00, 20, 5),
('Óleo para Barba Premium', 'Óleo hidratante com aroma amadeirado', 'oleo', 'Barba Forte', 18.00, 45.00, 15, 5),
('Shampoo Anticaspa Masculino', 'Limpeza profunda do couro cabeludo', 'shampoo', 'Don Alcides', 22.00, 42.00, 12, 5),
('Minoxidil 5%', 'Tratamento para crescimento capilar', 'outros', 'Kirkland', 35.00, 79.00, 8, 3),
('Navalha Profissional', 'Navalha em aço inox com lâmina substituível', 'acessorio', 'Feather', 45.00, 120.00, 6, 2),
('Perfume Masculino 100ml', 'Fragrância marcante', 'perfume', 'Malbec', 90.00, 189.00, 5, 2);

-- Agendamentos (exemplo de hoje)
INSERT INTO agendamentos (cliente_id, barbeiro_id, servico_id, data_agendamento, hora_inicio, hora_fim, status, valor, criado_por) VALUES
(1, 2, 1, DATE('now'), '09:00', '09:40', 'concluido', 55.00, 4),
(2, 3, 3, DATE('now'), '10:00', '11:10', 'confirmado', 85.00, 4),
(3, 3, 2, DATE('now'), '11:30', '12:00', 'confirmado', 45.00, 4),
(4, 2, 3, DATE('now'), '14:00', '15:10', 'cancelado', 85.00, 4),
(5, 2, 4, DATE('now'), '15:30', '16:00', 'confirmado', 40.00, 4),
(6, 3, 5, DATE('now'), '16:30', '16:45', 'pendente', 20.00, 4),
(1, 2, 1, DATE('now', '+1 day'), '10:00', '10:40', 'pendente', 55.00, 4),
(3, 3, 6, DATE('now', '+2 days'), '14:00', '16:00', 'confirmado', 150.00, 4);

-- Vendas de produtos
INSERT INTO vendas_produtos (produto_id, cliente_id, vendedor_id, quantidade, preco_unitario, total, forma_pagamento) VALUES
(1, 1, 4, 1, 55.00, 55.00, 'pix'),
(2, 2, 4, 2, 45.00, 90.00, 'cartao_credito'),
(3, 3, 4, 1, 42.00, 42.00, 'dinheiro');

-- Avaliações
INSERT INTO avaliacoes (agendamento_id, cliente_id, barbeiro_id, nota, comentario) VALUES
(1, 1, 2, 5, 'Excelente atendimento! O Rafa é fera no navalhado.');
