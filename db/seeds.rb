# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "=== Seeding mass data ==="

# --- User ---
user = User.find_or_create_by!(username: "qa_lead") do |u|
  u.password = "password123"
  u.role = "admin"
end

second_user = User.find_or_create_by!(username: "qa_analyst") do |u|
  u.password = "password123"
  u.role = "user"
end

qa_names = ["Ana Silva", "Bruno Costa", "Carla Mendes", "Diego Oliveira", "Elena Souza"]

# --- 10 Feature tags for bugs ---
feature_tags = %w[
  autenticação
  carrinho
  checkout
  dashboard
  notificações
  relatórios
  perfil-usuário
  busca
  catálogo
  pagamentos
]

# --- 8 Root cause tags for bugs ---
cause_tags = %w[
  lógica
  integração
  performance
  ui/ux
  validação
  concorrência
  migração
  configuração
]

# --- Tags for test plans ---
plan_tags = %w[
  smoke regression integration e2e api mobile web
  sprint-1 sprint-2 sprint-3 sprint-4 sprint-5
  critical high medium low
  frontend backend database
]

# ============================================================
# 25 Test Plans
# ============================================================
test_plans_data = [
  { name: "Login e Autenticação",             tags: %w[smoke critical web authentication] },
  { name: "Cadastro de Usuário",              tags: %w[regression high web frontend] },
  { name: "Recuperação de Senha",             tags: %w[smoke critical web] },
  { name: "Carrinho de Compras",              tags: %w[e2e high web frontend] },
  { name: "Checkout e Pagamento",             tags: %w[e2e critical web backend] },
  { name: "Dashboard Administrativo",         tags: %w[regression high web backend] },
  { name: "Gerenciamento de Perfil",          tags: %w[regression medium web frontend] },
  { name: "Sistema de Busca",                 tags: %w[integration high web backend] },
  { name: "Catálogo de Produtos",             tags: %w[regression medium web frontend] },
  { name: "Sistema de Notificações",          tags: %w[integration medium web backend] },
  { name: "Relatórios Financeiros",           tags: %w[e2e critical backend database] },
  { name: "API REST - Endpoints Públicos",    tags: %w[api high backend integration] },
  { name: "API REST - Endpoints Autenticados", tags: %w[api critical backend integration] },
  { name: "Upload de Arquivos",               tags: %w[regression medium web backend] },
  { name: "Gestão de Permissões",             tags: %w[smoke critical backend] },
  { name: "Integração com Gateway de Pagamento", tags: %w[integration critical backend] },
  { name: "Sistema de Cupons e Descontos",    tags: %w[e2e high web backend] },
  { name: "Histórico de Pedidos",             tags: %w[regression medium web frontend] },
  { name: "Avaliações e Comentários",         tags: %w[regression medium web frontend] },
  { name: "Sistema de Favoritos",             tags: %w[regression low web frontend] },
  { name: "Responsividade Mobile",            tags: %w[regression high mobile frontend] },
  { name: "Performance e Cache",              tags: %w[integration high backend database] },
  { name: "Exportação de Dados",              tags: %w[regression medium backend database] },
  { name: "Segurança e CSRF",                 tags: %w[smoke critical web backend] },
  { name: "Internacionalização (i18n)",        tags: %w[regression medium web frontend] },
]

# Scenario templates per plan (title, given, when, then)
scenarios_by_plan = {
  "Login e Autenticação" => [
    ["Login com credenciais válidas", "o usuário possui conta ativa", "submete email e senha corretos", "é redirecionado ao dashboard"],
    ["Login com senha incorreta", "o usuário possui conta ativa", "submete email correto e senha errada", "vê mensagem de erro 'Credenciais inválidas'"],
    ["Login com email inexistente", "o email não está cadastrado", "submete email inexistente e senha qualquer", "vê mensagem de erro 'Credenciais inválidas'"],
    ["Login com campos vazios", "o formulário de login está vazio", "clica em 'Entrar' sem preencher", "vê validação nos campos obrigatórios"],
    ["Logout do sistema", "o usuário está autenticado", "clica em 'Sair'", "é redirecionado à página de login"],
    ["Sessão expirada", "o token de sessão expirou", "tenta acessar página protegida", "é redirecionado ao login com aviso"],
    ["Login com remember me", "o usuário marca 'Lembrar-me'", "faz login e fecha o navegador", "ao reabrir, continua autenticado"],
    ["Bloqueio após tentativas", "o usuário errou a senha 5 vezes", "tenta login novamente", "conta é bloqueada por 15 minutos"],
    ["Login via OAuth Google", "o usuário tem conta Google", "clica em 'Entrar com Google'", "é autenticado e redirecionado ao dashboard"],
    ["Proteção contra brute force", "um atacante tenta múltiplas senhas", "envia 100 requisições em 1 minuto", "o sistema aplica rate limiting"],
    ["Login em dispositivo novo", "o usuário nunca logou neste dispositivo", "faz login com credenciais válidas", "recebe email de notificação de novo acesso"],
    ["Redirecionamento pós-login", "o usuário tentou acessar /pedidos sem login", "faz login com sucesso", "é redirecionado para /pedidos"],
    ["Login com 2FA ativado", "o usuário tem 2FA habilitado", "insere credenciais e código TOTP válido", "é autenticado com sucesso"],
    ["Token CSRF no formulário", "o formulário de login é carregado", "inspeciona o HTML do formulário", "contém token CSRF válido"],
    ["Concurrent sessions", "o usuário está logado no desktop", "faz login pelo celular", "ambas as sessões permanecem ativas"],
    ["XSS no campo de email", "o atacante insere script no campo email", "submete o formulário", "o input é sanitizado e nenhum script executa"],
  ],
  "Cadastro de Usuário" => [
    ["Cadastro com dados válidos", "o formulário de cadastro está acessível", "preenche todos os campos obrigatórios corretamente", "conta é criada e email de confirmação é enviado"],
    ["Cadastro com email duplicado", "já existe conta com email@test.com", "tenta cadastrar com mesmo email", "vê erro 'Email já cadastrado'"],
    ["Validação de senha fraca", "o formulário exige senha forte", "insere senha '123'", "vê erro 'Senha deve ter mínimo 8 caracteres'"],
    ["Validação de email inválido", "o campo email tem validação", "insere 'abc' como email", "vê erro 'Email inválido'"],
    ["Campos obrigatórios vazios", "nenhum campo foi preenchido", "clica em 'Cadastrar'", "vê validações em todos os campos obrigatórios"],
    ["Confirmação de senha diferente", "os campos senha e confirmação estão visíveis", "insere senhas diferentes", "vê erro 'Senhas não conferem'"],
    ["Cadastro com nome muito longo", "o campo nome aceita até 100 chars", "insere 200 caracteres no nome", "vê erro de tamanho máximo"],
    ["Username com caracteres especiais", "o campo username aceita alfanuméricos", "insere 'user@#$%'", "vê erro de formato inválido"],
    ["Termos de uso obrigatórios", "o checkbox de termos não está marcado", "tenta cadastrar sem aceitar termos", "vê erro 'Aceite os termos de uso'"],
    ["Email de confirmação", "o cadastro foi concluído com sucesso", "verifica a caixa de entrada", "recebe email com link de confirmação"],
    ["Cadastro via formulário mobile", "o usuário acessa pelo celular", "preenche formulário responsivo", "cadastro funciona corretamente no mobile"],
    ["SQL Injection no campo nome", "o atacante tenta injeção SQL", "insere \"'; DROP TABLE users;--\" no campo nome", "o input é sanitizado e nenhum dano ocorre"],
    ["Cadastro com CPF válido", "o formulário exige CPF", "insere CPF válido (com pontuação)", "CPF é aceito e formatado"],
    ["Cadastro com CPF inválido", "o campo CPF tem validação", "insere CPF com dígitos inválidos", "vê erro 'CPF inválido'"],
    ["Rate limiting no cadastro", "um bot tenta criar muitas contas", "envia 50 cadastros em 1 minuto", "o sistema bloqueia após o limite"],
    ["Avatar padrão atribuído", "nenhuma foto foi enviada", "completa o cadastro sem foto", "avatar padrão é atribuído ao perfil"],
    ["Redirecionamento pós-cadastro", "o cadastro foi concluído", "a conta é criada com sucesso", "é redirecionado ao dashboard com mensagem de boas-vindas"],
  ],
  "Recuperação de Senha" => [
    ["Solicitar reset com email válido", "o email está cadastrado", "submete formulário de reset", "recebe email com link de redefinição"],
    ["Reset com email inexistente", "o email não está cadastrado", "submete formulário de reset", "vê mensagem genérica (sem revelar se email existe)"],
    ["Link de reset expirado", "o link tem validade de 2h", "clica no link após 3h", "vê mensagem 'Link expirado, solicite novo'"],
    ["Redefinir senha com sucesso", "o link de reset é válido", "insere nova senha e confirmação", "senha é atualizada e é redirecionado ao login"],
    ["Nova senha igual à anterior", "a política exige senha diferente", "insere a mesma senha atual", "vê erro 'Nova senha deve ser diferente da atual'"],
    ["Token de reset usado duas vezes", "o link já foi utilizado", "tenta usar o mesmo link novamente", "vê erro 'Link já utilizado'"],
    ["Validação de senha no reset", "o formulário exige senha forte", "insere senha fraca no reset", "vê erro de requisitos de senha"],
    ["Campo de email vazio", "o formulário de recuperação está vazio", "clica enviar sem preencher email", "vê validação de campo obrigatório"],
    ["Reset com múltiplas solicitações", "o usuário solicita reset 3 vezes", "clica no link do último email", "apenas o último token é válido"],
    ["Email de reset não chega em spam", "o email foi enviado", "verifica a caixa principal", "email está na caixa de entrada, não em spam"],
    ["UI do formulário de reset", "a página de reset é carregada", "observa o layout", "formulário está centralizado e responsivo"],
    ["Proteção contra email enumeration", "um atacante tenta descobrir emails", "submete vários emails diferentes", "todas as respostas são idênticas (sem vazamento)"],
    ["Reset via API", "o endpoint /api/password-reset existe", "envia POST com email válido", "retorna 200 e envia email"],
    ["Sessões invalidadas após reset", "o usuário tem sessões ativas", "redefine a senha com sucesso", "todas as sessões anteriores são encerradas"],
    ["Confirmação visual de envio", "o formulário foi submetido", "o email é processado", "spinner é exibido e depois mensagem de sucesso"],
  ],
  "Carrinho de Compras" => [
    ["Adicionar produto ao carrinho", "o catálogo tem produtos disponíveis", "clica em 'Adicionar ao carrinho' em um produto", "produto aparece no carrinho com quantidade 1"],
    ["Remover produto do carrinho", "o carrinho tem 3 produtos", "clica em 'Remover' no segundo produto", "o produto é removido e o total é recalculado"],
    ["Alterar quantidade de produto", "o carrinho tem um produto com qty=1", "altera quantidade para 3", "subtotal do item e total do carrinho são recalculados"],
    ["Carrinho vazio", "o carrinho não tem produtos", "acessa a página do carrinho", "vê mensagem 'Seu carrinho está vazio' com link para catálogo"],
    ["Limite de estoque", "o produto tem 5 unidades em estoque", "tenta adicionar 10 unidades", "vê aviso 'Máximo disponível: 5 unidades'"],
    ["Persistência do carrinho", "o usuário adicionou itens e fechou o navegador", "reabre o navegador e acessa o carrinho", "os itens anteriores ainda estão no carrinho"],
    ["Carrinho com produto indisponível", "um produto no carrinho ficou sem estoque", "acessa o carrinho", "vê aviso de indisponibilidade no produto afetado"],
    ["Cupom de desconto no carrinho", "o cupom DESCONTO10 está ativo", "aplica o cupom no carrinho", "desconto de 10% é aplicado ao total"],
    ["Cupom inválido", "o cupom XPTO não existe", "tenta aplicar o cupom", "vê erro 'Cupom inválido'"],
    ["Cálculo de frete", "o carrinho tem produtos", "insere CEP de destino", "frete é calculado e exibido"],
    ["Atualizar carrinho com AJAX", "o carrinho tem produtos", "altera quantidade sem recarregar página", "total é atualizado via AJAX sem reload"],
    ["Múltiplos do mesmo produto", "o mesmo produto é adicionado duas vezes", "clica 'Adicionar' no mesmo produto", "quantidade do item existente incrementa em 1"],
    ["Badge do carrinho no header", "o carrinho tem 5 itens", "observa o ícone do carrinho no header", "badge mostra o número 5"],
    ["Carrinho com preço promocional", "o produto tem preço de/por", "adiciona produto com desconto", "carrinho usa o preço promocional"],
    ["Subtotal por item", "o carrinho tem 2 unidades a R$50", "observa o subtotal", "mostra R$100,00 como subtotal do item"],
    ["Limpar carrinho", "o carrinho tem 5 produtos", "clica em 'Limpar carrinho'", "todos os itens são removidos após confirmação"],
  ],
  "Checkout e Pagamento" => [
    ["Checkout com cartão de crédito", "o carrinho tem itens e endereço preenchido", "seleciona cartão e insere dados válidos", "pagamento é processado e pedido é criado"],
    ["Checkout com boleto bancário", "o carrinho tem itens", "seleciona boleto como forma de pagamento", "boleto é gerado com código de barras"],
    ["Checkout com PIX", "o carrinho tem itens", "seleciona PIX como pagamento", "QR code e código copia-cola são exibidos"],
    ["Cartão recusado", "o cartão não tem limite", "tenta pagar com cartão sem saldo", "vê erro 'Pagamento recusado pelo emissor'"],
    ["CVV inválido", "o formulário de cartão está visível", "insere CVV com 2 dígitos", "vê erro de validação no CVV"],
    ["Endereço de entrega obrigatório", "o endereço não foi preenchido", "tenta finalizar compra", "vê erro 'Informe o endereço de entrega'"],
    ["Resumo do pedido no checkout", "o carrinho tem 3 produtos", "acessa a página de checkout", "vê resumo com produtos, quantidades, subtotais e total"],
    ["Cálculo de imposto", "o endereço é em SP (ICMS 18%)", "avança para resumo do pagamento", "imposto é calculado e exibido corretamente"],
    ["Checkout como visitante", "o usuário não está logado", "tenta finalizar compra", "é solicitado login ou cadastro rápido"],
    ["Pedido duplicado (double click)", "o botão 'Finalizar' foi clicado", "clica duas vezes rapidamente", "apenas um pedido é criado (proteção contra duplo clique)"],
    ["Email de confirmação do pedido", "o pedido foi finalizado com sucesso", "verifica email", "recebe confirmação com número do pedido e detalhes"],
    ["Estoque decrementado após compra", "o produto tinha 10 unidades", "compra 3 unidades com sucesso", "estoque atualiza para 7 unidades"],
    ["Frete grátis acima de R$200", "o carrinho tem R$250 em produtos", "avança ao checkout", "frete é gratuito e exibido como R$0,00"],
    ["Timeout do gateway de pagamento", "o gateway demora mais de 30s", "aguarda resposta do pagamento", "vê mensagem 'Processando, aguarde...' e retry automático"],
    ["Parcelamento no cartão", "o total é R$600", "seleciona 3x sem juros", "mostra 3 parcelas de R$200,00"],
    ["Checkout com carrinho vazio", "o carrinho está vazio", "tenta acessar /checkout", "é redirecionado ao carrinho com aviso"],
    ["Salvar cartão para próximas compras", "o usuário marca 'Salvar cartão'", "finaliza a compra", "cartão tokenizado é salvo no perfil"],
  ],
  "Dashboard Administrativo" => [
    ["Acesso ao dashboard como admin", "o usuário é administrador", "acessa /admin/dashboard", "vê painel com métricas e gráficos"],
    ["Acesso negado para usuário comum", "o usuário tem role 'user'", "tenta acessar /admin/dashboard", "vê erro 403 ou é redirecionado"],
    ["Métricas de vendas do dia", "existem 15 vendas hoje", "observa o card de vendas diárias", "mostra 15 vendas e valor total correto"],
    ["Gráfico de vendas mensal", "existem dados de vendas de 6 meses", "observa o gráfico mensal", "gráfico renderiza com dados corretos"],
    ["Lista de pedidos recentes", "existem 50 pedidos no sistema", "observa seção 'Pedidos Recentes'", "mostra os 10 pedidos mais recentes"],
    ["Filtro por período", "existem dados de janeiro a junho", "filtra por 'Março'", "métricas e gráficos atualizam para março"],
    ["Exportar relatório em CSV", "os dados do dashboard estão carregados", "clica em 'Exportar CSV'", "download de CSV inicia com dados corretos"],
    ["Card de novos usuários", "10 usuários cadastrados esta semana", "observa card 'Novos Usuários'", "mostra 10 com variação percentual"],
    ["Notificações no dashboard", "existem 3 alertas do sistema", "observa ícone de notificações", "badge mostra 3 e lista os alertas"],
    ["Dashboard responsivo", "o admin acessa pelo tablet", "observa layout no tablet", "cards e gráficos se adaptam à tela"],
    ["Refresh automático de dados", "o dashboard tem auto-refresh de 60s", "aguarda 60 segundos", "dados são atualizados sem reload manual"],
    ["Widget de tickets de suporte", "existem 5 tickets abertos", "observa widget de suporte", "mostra 5 tickets com status e prioridade"],
    ["Performance do dashboard", "o dashboard tem muitos widgets", "mede o tempo de carregamento", "página carrega em menos de 3 segundos"],
    ["Breadcrumb no dashboard", "o admin está no dashboard", "observa o breadcrumb", "mostra 'Home > Admin > Dashboard'"],
    ["Atalhos rápidos", "o dashboard exibe ações rápidas", "clica em 'Novo Produto'", "é redirecionado ao formulário de criação"],
  ],
  "Gerenciamento de Perfil" => [
    ["Visualizar perfil", "o usuário está logado", "acessa /perfil", "vê seus dados pessoais"],
    ["Editar nome", "o perfil está carregado", "altera o nome e salva", "nome é atualizado com mensagem de sucesso"],
    ["Alterar email", "o perfil está carregado", "altera o email para novo@test.com", "email é atualizado após confirmação"],
    ["Alterar senha", "o formulário de senha está visível", "insere senha atual e nova senha", "senha é atualizada com sucesso"],
    ["Senha atual incorreta", "o formulário de alteração de senha está visível", "insere senha atual errada", "vê erro 'Senha atual incorreta'"],
    ["Upload de avatar", "o perfil permite foto", "seleciona imagem JPG de 500KB", "avatar é atualizado e exibido"],
    ["Avatar com formato inválido", "o campo aceita apenas imagens", "tenta enviar arquivo .exe", "vê erro 'Formato não permitido'"],
    ["Remover avatar", "o perfil tem avatar customizado", "clica em 'Remover foto'", "avatar volta ao padrão"],
    ["Editar endereço", "o perfil tem seção de endereço", "preenche CEP e demais campos", "endereço é salvo com sucesso"],
    ["Autopreenchimento por CEP", "o campo CEP está visível", "insere CEP válido", "rua, bairro e cidade são preenchidos automaticamente"],
    ["Desativar conta", "o perfil tem opção de desativação", "clica em 'Desativar minha conta'", "vê confirmação e conta é desativada"],
    ["Histórico de alterações do perfil", "o perfil foi editado 3 vezes", "acessa histórico de alterações", "vê log com data e campos alterados"],
    ["Validação de telefone", "o campo telefone aceita formato BR", "insere (11) 99999-9999", "telefone é salvo formatado corretamente"],
    ["Perfil com campos opcionais", "campos como bio e website são opcionais", "deixa campos opcionais vazios", "perfil é salvo sem erro"],
    ["Preview do avatar antes de salvar", "o campo de upload está visível", "seleciona nova imagem", "preview é exibido antes de salvar"],
    ["Data de nascimento com date picker", "o campo data está visível", "seleciona data pelo date picker", "data é salva no formato correto"],
  ],
  "Sistema de Busca" => [
    ["Busca por nome de produto", "existem produtos cadastrados", "busca por 'Camiseta Azul'", "resultados contêm produtos com 'Camiseta Azul'"],
    ["Busca sem resultados", "o termo não existe no catálogo", "busca por 'xyzabc123'", "vê mensagem 'Nenhum resultado encontrado'"],
    ["Busca com filtro de categoria", "existem produtos em várias categorias", "busca 'sapato' com filtro 'Calçados'", "resultados são apenas da categoria Calçados"],
    ["Busca com filtro de preço", "existem produtos de R$10 a R$500", "filtra por 'R$50 a R$100'", "resultados exibem apenas produtos nessa faixa"],
    ["Ordenação por relevância", "a busca retornou 20 resultados", "ordena por 'Relevância'", "resultados mais relevantes aparecem primeiro"],
    ["Ordenação por preço", "a busca retornou resultados", "ordena por 'Menor preço'", "resultados aparecem do mais barato ao mais caro"],
    ["Sugestão de busca (autocomplete)", "o campo de busca tem autocomplete", "digita 'cam'", "sugere 'Camiseta', 'Camisa', 'Câmera'"],
    ["Busca com caractere especial", "o campo aceita texto", "busca por '<script>alert(1)</script>'", "input é sanitizado e nenhum script executa"],
    ["Paginação de resultados", "a busca retornou 60 resultados", "acessa a página 3", "mostra resultados 41-60"],
    ["Destaque do termo buscado", "a busca retornou resultados", "observa os resultados", "o termo buscado está destacado em negrito"],
    ["Busca por SKU", "o produto tem SKU 'PRD-001'", "busca por 'PRD-001'", "produto é encontrado diretamente"],
    ["Busca com acento e sem acento", "o produto se chama 'Café Premium'", "busca por 'cafe premium'", "produto é encontrado (busca accent-insensitive)"],
    ["Histórico de buscas", "o usuário buscou 3 termos anteriormente", "clica no campo de busca", "vê histórico de buscas recentes"],
    ["Busca por voz (mobile)", "o app mobile tem busca por voz", "ativa busca por voz e diz 'tênis preto'", "resultados para 'tênis preto' são exibidos"],
    ["Tempo de resposta da busca", "existem 10.000 produtos no catálogo", "busca por 'smartphone'", "resultados aparecem em menos de 500ms"],
    ["Busca vazia", "o campo está vazio", "clica em buscar sem digitar nada", "exibe produtos populares ou mensagem informativa"],
  ],
  "Catálogo de Produtos" => [
    ["Listagem de produtos", "existem 50 produtos ativos", "acessa /produtos", "vê grid com produtos paginados"],
    ["Detalhes do produto", "o produto 'Tênis Runner' existe", "clica no produto", "vê página com foto, descrição, preço e botão comprar"],
    ["Galeria de fotos do produto", "o produto tem 5 fotos", "navega pelas fotos", "todas as 5 fotos são exibidas com navegação"],
    ["Produto sem estoque", "o produto está com estoque zero", "acessa a página do produto", "botão 'Comprar' está desabilitado com texto 'Indisponível'"],
    ["Filtro por categoria", "existem 5 categorias com produtos", "filtra por 'Eletrônicos'", "exibe apenas produtos da categoria selecionada"],
    ["Filtro por marca", "existem produtos de 10 marcas", "filtra por 'Samsung'", "exibe apenas produtos Samsung"],
    ["Ordenação por novidades", "existem produtos de datas variadas", "ordena por 'Mais Recentes'", "produtos mais novos aparecem primeiro"],
    ["Preço com desconto", "o produto tem desconto de 20%", "observa card do produto", "mostra preço original riscado e preço com desconto"],
    ["Badge de produto novo", "o produto foi cadastrado há 3 dias", "observa card do produto", "badge 'Novo' é exibido"],
    ["Avaliação média do produto", "o produto tem 15 avaliações", "observa card do produto", "mostra estrelas e número de avaliações"],
    ["Breadcrumb da categoria", "o usuário está em Eletrônicos > Smartphones", "observa breadcrumb", "mostra navegação hierárquica correta"],
    ["Compartilhar produto", "a página do produto está aberta", "clica em 'Compartilhar'", "opções de compartilhamento são exibidas"],
    ["Zoom na imagem do produto", "a foto principal está visível", "passa o mouse sobre a imagem", "zoom é ativado mostrando detalhes"],
    ["Produtos relacionados", "o produto pertence a uma categoria", "rola até seção 'Relacionados'", "vê sugestões de produtos similares"],
    ["Variações de produto (cor/tamanho)", "o produto tem 3 cores e 4 tamanhos", "seleciona cor 'Azul' e tamanho 'M'", "preço e estoque atualizam para a variação"],
  ],
  "Sistema de Notificações" => [
    ["Notificação de pedido confirmado", "o pedido foi pago com sucesso", "o sistema processa o pagamento", "usuário recebe notificação 'Pedido confirmado'"],
    ["Notificação de envio", "o pedido foi despachado", "a transportadora confirma coleta", "usuário recebe notificação com código de rastreio"],
    ["Notificação push no mobile", "o app mobile tem permissão de push", "ocorre um evento relevante", "push notification é exibida no dispositivo"],
    ["Preferências de notificação", "o usuário acessa configurações", "desmarca 'Notificações por email'", "emails de notificação são desativados"],
    ["Marcar notificação como lida", "existem 5 notificações não lidas", "clica em uma notificação", "notificação muda para status 'lida'"],
    ["Marcar todas como lidas", "existem 10 notificações não lidas", "clica em 'Marcar todas como lidas'", "todas ficam com status 'lida'"],
    ["Badge de notificações", "existem 3 notificações não lidas", "observa o ícone no header", "badge mostra o número 3"],
    ["Notificação em tempo real", "o usuário está na página", "ocorre um novo evento", "notificação aparece sem refresh via WebSocket"],
    ["Histórico de notificações", "o usuário recebeu 50 notificações", "acessa /notificacoes", "vê lista paginada de todas as notificações"],
    ["Notificação de promoção", "uma promoção foi criada pelo admin", "o sistema envia notificações em massa", "usuários ativos recebem a notificação"],
    ["Notificação de carrinho abandonado", "o carrinho tem itens há 24h", "o job agendado executa", "usuário recebe email de lembrete"],
    ["Notificação silenciosa no horário noturno", "são 23h e o usuário tem modo noturno", "ocorre um evento", "notificação é enviada sem som"],
    ["Agrupamento de notificações", "3 notificações do mesmo tipo chegam", "observa o painel", "notificações são agrupadas com contador"],
    ["Excluir notificação", "uma notificação está visível", "clica em 'Excluir' na notificação", "notificação é removida da lista"],
    ["Notificação com link de ação", "a notificação tem CTA 'Ver Pedido'", "clica no link da notificação", "é redirecionado à página do pedido"],
    ["Limite de notificações armazenadas", "o usuário tem 500 notificações", "recebe a 501ª notificação", "a mais antiga é removida automaticamente"],
  ],
  "Relatórios Financeiros" => [
    ["Relatório de vendas diário", "existem vendas no dia atual", "acessa relatório diário", "vê total de vendas, quantidade de pedidos e ticket médio"],
    ["Relatório de vendas mensal", "existem vendas no mês atual", "seleciona mês corrente", "gráfico e tabela com dados do mês são exibidos"],
    ["Exportar relatório em PDF", "o relatório mensal está carregado", "clica em 'Exportar PDF'", "PDF é gerado com gráficos e tabelas"],
    ["Exportar relatório em Excel", "o relatório está carregado", "clica em 'Exportar Excel'", "arquivo XLSX é baixado com dados formatados"],
    ["Filtro por categoria no relatório", "o relatório aceita filtros", "filtra por categoria 'Eletrônicos'", "dados são filtrados apenas para eletrônicos"],
    ["Comparativo entre períodos", "existem dados de janeiro e fevereiro", "seleciona comparativo Jan vs Fev", "gráfico mostra comparação lado a lado"],
    ["Relatório de produtos mais vendidos", "existem dados de vendas", "acessa 'Top Produtos'", "lista top 10 com quantidade e receita"],
    ["Relatório de métodos de pagamento", "existem pagamentos por vários métodos", "acessa relatório de pagamentos", "gráfico de pizza com distribuição por método"],
    ["Margem de lucro por produto", "existem dados de custo e venda", "acessa relatório de margem", "mostra margem % por produto"],
    ["Relatório de cancelamentos", "existem pedidos cancelados", "acessa relatório de cancelamentos", "mostra motivos e valores de cancelamentos"],
    ["Permissão para visualizar relatórios", "o usuário é gerente", "acessa área de relatórios", "vê todos os relatórios disponíveis para seu nível"],
    ["Relatório com dados zerados", "não há vendas no período selecionado", "acessa relatório de abril", "vê mensagem 'Sem dados para o período'"],
    ["Performance do relatório pesado", "o relatório abrange 1 ano de dados", "gera relatório anual completo", "relatório carrega em menos de 10 segundos"],
    ["Drill-down no relatório", "o relatório mostra vendas por região", "clica na região 'Sudeste'", "vê detalhamento por estado dentro de Sudeste"],
    ["Agendamento de relatório", "o admin quer relatório semanal automático", "configura envio semanal por email", "relatório é enviado toda segunda-feira"],
    ["Gráfico interativo", "o relatório tem gráfico de barras", "passa mouse sobre uma barra", "tooltip mostra valor exato e variação"],
    ["Relatório de receita recorrente", "existem assinaturas ativas", "acessa relatório de MRR", "mostra MRR atual e histórico de crescimento"],
  ],
  "API REST - Endpoints Públicos" => [
    ["GET /api/products", "existem 20 produtos ativos", "envia GET /api/products", "retorna 200 com lista paginada de produtos"],
    ["GET /api/products/:id", "o produto com id=5 existe", "envia GET /api/products/5", "retorna 200 com detalhes do produto"],
    ["GET /api/products/:id inexistente", "o produto com id=999 não existe", "envia GET /api/products/999", "retorna 404 com mensagem de erro"],
    ["GET /api/categories", "existem 8 categorias", "envia GET /api/categories", "retorna 200 com lista de categorias"],
    ["Paginação da API", "existem 100 produtos", "envia GET /api/products?page=3&per_page=10", "retorna itens 21-30 com metadados de paginação"],
    ["Filtro por categoria na API", "existem produtos em várias categorias", "envia GET /api/products?category=electronics", "retorna apenas produtos da categoria"],
    ["Ordenação na API", "existem produtos com preços variados", "envia GET /api/products?sort=price&order=asc", "retorna produtos ordenados por preço crescente"],
    ["Rate limiting da API", "o cliente já fez 100 requests/minuto", "envia mais uma requisição", "retorna 429 Too Many Requests"],
    ["CORS headers", "a requisição vem de domínio externo", "verifica headers da resposta", "Access-Control-Allow-Origin está presente"],
    ["Content-Type da resposta", "qualquer endpoint é acessado", "verifica header Content-Type", "retorna application/json; charset=utf-8"],
    ["Busca na API", "existem produtos cadastrados", "envia GET /api/products?q=camiseta", "retorna produtos que contêm 'camiseta'"],
    ["Versionamento da API", "a API tem versão v1", "envia GET /api/v1/products", "retorna dados da versão 1 da API"],
    ["Health check endpoint", "o sistema está operacional", "envia GET /api/health", "retorna 200 com status 'ok'"],
    ["Resposta comprimida (gzip)", "o cliente aceita gzip", "envia request com Accept-Encoding: gzip", "resposta vem comprimida"],
    ["Cache headers", "o endpoint tem cache configurado", "verifica headers da resposta", "Cache-Control e ETag estão presentes"],
    ["API retorna campos esperados", "o produto existe", "verifica campos da resposta", "contém id, name, price, description, image_url"],
  ],
  "API REST - Endpoints Autenticados" => [
    ["POST /api/auth/login", "o usuário possui conta válida", "envia POST com email e senha corretos", "retorna 200 com access_token e refresh_token"],
    ["POST /api/auth/login inválido", "as credenciais estão erradas", "envia POST com senha incorreta", "retorna 401 Unauthorized"],
    ["GET /api/orders sem token", "o token não foi enviado", "envia GET /api/orders sem Authorization", "retorna 401 com mensagem de erro"],
    ["GET /api/orders com token válido", "o token JWT é válido", "envia GET /api/orders com Bearer token", "retorna 200 com lista de pedidos do usuário"],
    ["Token expirado", "o token expirou há 1 hora", "envia request com token expirado", "retorna 401 com mensagem 'Token expirado'"],
    ["Refresh token", "o access_token expirou mas refresh é válido", "envia POST /api/auth/refresh", "retorna novo access_token"],
    ["POST /api/orders", "o usuário está autenticado e tem itens no carrinho", "envia POST /api/orders com dados do pedido", "retorna 201 com detalhes do pedido criado"],
    ["DELETE /api/orders/:id sem permissão", "o pedido pertence a outro usuário", "envia DELETE /api/orders/15", "retorna 403 Forbidden"],
    ["PUT /api/profile", "o usuário está autenticado", "envia PUT com novos dados de perfil", "retorna 200 com perfil atualizado"],
    ["POST /api/auth/logout", "o usuário está autenticado", "envia POST /api/auth/logout", "retorna 200 e token é invalidado"],
    ["Requisição com token malformado", "o token JWT está corrompido", "envia request com token 'abc123invalid'", "retorna 401 com mensagem de erro clara"],
    ["Scopes de permissão", "o token tem scope 'read:orders'", "tenta DELETE /api/orders/1", "retorna 403 por falta de scope 'write:orders'"],
    ["Throttling por usuário autenticado", "o usuário já fez 1000 requests/hora", "envia mais uma requisição", "retorna 429 com header Retry-After"],
    ["Listagem de endereços do usuário", "o usuário tem 3 endereços cadastrados", "envia GET /api/addresses", "retorna 200 com 3 endereços"],
    ["Criar endereço", "o usuário está autenticado", "envia POST /api/addresses com dados válidos", "retorna 201 com endereço criado"],
    ["Webhook de pagamento", "o gateway envia callback de pagamento", "envia POST /api/webhooks/payment com assinatura válida", "retorna 200 e pedido é atualizado"],
  ],
  "Upload de Arquivos" => [
    ["Upload de imagem JPG", "o formulário aceita imagens", "envia arquivo .jpg de 2MB", "imagem é salva e thumbnail é gerado"],
    ["Upload de imagem PNG", "o formulário aceita imagens", "envia arquivo .png de 1MB", "imagem é salva e processada"],
    ["Upload de PDF", "o formulário aceita PDFs", "envia arquivo .pdf de 5MB", "PDF é salvo e disponível para download"],
    ["Upload de arquivo muito grande", "o limite é 10MB", "tenta enviar arquivo de 15MB", "vê erro 'Arquivo excede o limite de 10MB'"],
    ["Upload de formato não permitido", "apenas imagens e PDFs são aceitos", "tenta enviar arquivo .exe", "vê erro 'Formato de arquivo não permitido'"],
    ["Upload múltiplo", "o formulário aceita múltiplos arquivos", "seleciona 3 imagens simultaneamente", "todas as 3 são enviadas e salvas"],
    ["Progress bar do upload", "o arquivo está sendo enviado", "observa a interface durante o upload", "barra de progresso mostra % concluído"],
    ["Cancelar upload em andamento", "o upload de um arquivo grande está em 50%", "clica em 'Cancelar'", "upload é interrompido e arquivo parcial é descartado"],
    ["Preview de imagem antes do upload", "o campo de upload aceita imagens", "seleciona uma imagem", "preview é exibido antes de confirmar o envio"],
    ["Upload via drag and drop", "a área de drop está visível", "arrasta arquivo para a área", "arquivo é aceito e upload inicia"],
    ["Compressão automática de imagem", "a imagem original tem 8MB", "envia a imagem", "sistema comprime para tamanho otimizado mantendo qualidade"],
    ["Nome do arquivo sanitizado", "o arquivo se chama '../../../etc/passwd'", "envia o arquivo", "nome é sanitizado e salvo com nome seguro"],
    ["Upload com conexão lenta", "a conexão é de 256kbps", "inicia upload de 2MB", "upload completa com indicador de progresso preciso"],
    ["Substituir arquivo existente", "já existe um arquivo no campo", "seleciona novo arquivo", "arquivo anterior é substituído pelo novo"],
    ["Download do arquivo enviado", "o arquivo foi enviado com sucesso", "clica em 'Download'", "arquivo é baixado com nome original"],
    ["Galeria de arquivos enviados", "existem 10 arquivos no registro", "acessa seção de arquivos", "vê grid com thumbnails e nomes dos arquivos"],
  ],
  "Gestão de Permissões" => [
    ["Admin acessa todas as páginas", "o usuário tem role 'admin'", "navega por todas as seções", "acesso é concedido em todas as páginas"],
    ["Usuário comum não acessa admin", "o usuário tem role 'user'", "tenta acessar /admin", "vê erro 403 ou redirecionamento"],
    ["Admin cria novo usuário", "o admin está no painel de usuários", "preenche formulário de criação", "novo usuário é criado com sucesso"],
    ["Admin altera role de usuário", "um usuário regular existe", "admin muda role para 'manager'", "role é atualizado e permissões aplicadas"],
    ["Admin desativa usuário", "o usuário está ativo", "admin clica em 'Desativar'", "conta é desativada e sessões encerradas"],
    ["Proteção de rotas no backend", "o middleware de autorização está ativo", "requisição sem permissão chega ao controller", "retorna 403 antes de executar a ação"],
    ["Permissão por recurso", "o manager pode ver relatórios mas não deletar", "manager tenta deletar relatório", "vê erro 'Sem permissão para esta ação'"],
    ["Audit log de ações", "o admin realizou 10 ações hoje", "acessa log de auditoria", "vê registro de todas as ações com timestamp"],
    ["Admin reseta senha de usuário", "um usuário esqueceu a senha", "admin clica em 'Resetar Senha'", "nova senha temporária é gerada e enviada"],
    ["Último admin não pode ser removido", "existe apenas 1 admin no sistema", "tenta remover o admin", "vê erro 'Deve existir ao menos 1 administrador'"],
    ["Herança de permissões", "o role 'gerente' herda de 'user'", "gerente acessa funcionalidade de user", "acesso é concedido via herança"],
    ["Timeout de sessão por inatividade", "a sessão tem timeout de 30min", "o usuário fica inativo por 35min", "sessão expira e usuário é redirecionado ao login"],
    ["Verificação de permissão em cada request", "o middleware verifica ACL", "request chega ao sistema", "permissão é verificada antes de processar"],
    ["Segregação de dados por tenant", "o sistema é multi-tenant", "usuário do tenant A acessa dados", "vê apenas dados do tenant A"],
    ["Permissão de edição vs visualização", "o editor pode editar produtos", "visualizador tenta editar produto", "vê produto em modo somente leitura"],
  ],
  "Integração com Gateway de Pagamento" => [
    ["Pagamento com sucesso", "o gateway está operacional", "envia transação de R$100", "pagamento é aprovado e pedido confirmado"],
    ["Pagamento recusado por saldo", "o cartão não tem saldo", "envia transação", "retorna erro 'Saldo insuficiente'"],
    ["Timeout do gateway", "o gateway demora mais de 30s", "aguarda resposta", "sistema trata timeout e informa o usuário"],
    ["Webhook de confirmação", "o pagamento foi processado", "gateway envia webhook", "pedido é atualizado para 'pago'"],
    ["Estorno/Refund", "o pedido está pago e precisa ser estornado", "admin solicita estorno", "valor é devolvido e pedido atualizado para 'estornado'"],
    ["Estorno parcial", "o pedido de R$200 precisa estorno parcial", "admin estorna R$80", "R$80 é devolvido e pedido marcado como 'estorno parcial'"],
    ["Validação de cartão (Luhn)", "o número do cartão é inválido", "envia transação com cartão inválido", "erro de validação antes de enviar ao gateway"],
    ["Retry automático em falha", "o gateway retornou erro 500", "sistema detecta falha temporária", "retry é feito após 5 segundos (máximo 3 tentativas)"],
    ["Idempotência de transação", "a mesma transação é enviada 2 vezes", "gateway recebe request duplicado", "apenas uma cobrança é efetuada"],
    ["Captura posterior (pre-auth)", "o pagamento foi pré-autorizado", "admin confirma captura após 3 dias", "valor é capturado e pedido finalizado"],
    ["Múltiplos gateways (fallback)", "o gateway primário está fora", "transação falha no primário", "sistema tenta gateway secundário automaticamente"],
    ["Log de transações", "várias transações foram processadas", "admin acessa log de transações", "vê histórico com status, valor e gateway usado"],
    ["Segurança PCI DSS", "dados sensíveis são transmitidos", "inspeciona tráfego de rede", "dados do cartão são tokenizados, nunca em plain text"],
    ["Notificação de falha de pagamento", "o pagamento falhou", "sistema detecta falha", "usuário recebe email com opções de nova tentativa"],
    ["Conciliação bancária", "existem 100 transações no dia", "admin acessa relatório de conciliação", "valores batem com extrato do gateway"],
    ["Moeda e formatação", "o sistema opera em BRL", "verifica valores no checkout", "todos os valores exibidos em R$ com 2 casas decimais"],
  ],
  "Sistema de Cupons e Descontos" => [
    ["Aplicar cupom válido", "o cupom SAVE10 dá 10% de desconto", "aplica SAVE10 no carrinho", "desconto de 10% é aplicado ao subtotal"],
    ["Cupom expirado", "o cupom VELHO expirou ontem", "tenta aplicar VELHO", "vê erro 'Cupom expirado'"],
    ["Cupom com valor mínimo", "o cupom exige compra mínima de R$100", "carrinho tem R$80", "vê erro 'Valor mínimo não atingido: R$100'"],
    ["Cupom de frete grátis", "o cupom FRETEFREE dá frete grátis", "aplica FRETEFREE", "valor do frete é zerado"],
    ["Cupom por uso único", "o cupom UNICO já foi usado pelo usuário", "tenta aplicar novamente", "vê erro 'Cupom já utilizado'"],
    ["Desconto por categoria", "promoção de 20% em Eletrônicos", "adiciona produto eletrônico ao carrinho", "desconto de 20% é aplicado automaticamente"],
    ["Cupons não cumulativos", "já existe um cupom aplicado", "tenta aplicar segundo cupom", "vê mensagem 'Apenas 1 cupom por pedido'"],
    ["Remover cupom aplicado", "o cupom SAVE10 está aplicado", "clica em 'Remover cupom'", "desconto é removido e total recalculado"],
    ["Cupom com limite de usos", "o cupom PROMO tem limite de 100 usos e já usou 100", "tenta aplicar PROMO", "vê erro 'Cupom esgotado'"],
    ["Desconto progressivo", "compra acima de 5 itens tem 15% off", "adiciona 6 itens ao carrinho", "desconto de 15% é aplicado automaticamente"],
    ["Cupom em uppercase/lowercase", "o cupom é case-insensitive", "digita 'save10' em minúsculas", "cupom é aceito normalmente"],
    ["Cupom com valor fixo", "o cupom MENOS20 dá R$20 de desconto", "aplica no carrinho de R$150", "total fica R$130"],
    ["Desconto não ultrapassa total", "cupom de R$50 num carrinho de R$30", "aplica o cupom", "desconto é limitado a R$30 (total não fica negativo)"],
    ["Admin cria cupom", "o admin acessa gestão de cupons", "preenche formulário de criação", "cupom é criado com regras definidas"],
    ["Relatório de uso de cupons", "30 cupons foram usados no mês", "admin acessa relatório de cupons", "vê lista com cupom, usos, e desconto total concedido"],
    ["Cupom para primeira compra", "o usuário nunca comprou antes", "aplica cupom PRIMEIRA", "desconto de 15% é aplicado"],
    ["Desconto exibido no checkout", "o cupom está aplicado", "avança ao checkout", "desconto é exibido como linha separada no resumo"],
  ],
  "Histórico de Pedidos" => [
    ["Listar pedidos do usuário", "o usuário tem 10 pedidos", "acessa /meus-pedidos", "vê lista com todos os 10 pedidos"],
    ["Detalhes do pedido", "o pedido #123 existe", "clica no pedido #123", "vê produtos, quantidades, valores e status"],
    ["Filtro por status", "existem pedidos em vários status", "filtra por 'Entregue'", "vê apenas pedidos com status 'Entregue'"],
    ["Filtro por período", "existem pedidos de vários meses", "filtra por 'Último mês'", "vê apenas pedidos do último mês"],
    ["Rastreamento de pedido", "o pedido foi enviado", "clica em 'Rastrear'", "vê timeline com status de envio"],
    ["Nota fiscal do pedido", "a NF foi emitida", "clica em 'Baixar NF'", "PDF da nota fiscal é baixado"],
    ["Recomprar pedido anterior", "o pedido #50 tem 3 produtos", "clica em 'Comprar novamente'", "3 produtos são adicionados ao carrinho"],
    ["Cancelar pedido pendente", "o pedido está com status 'Pendente'", "clica em 'Cancelar pedido'", "pedido é cancelado após confirmação"],
    ["Não cancelar pedido enviado", "o pedido está com status 'Enviado'", "tenta cancelar", "botão de cancelamento não está disponível"],
    ["Paginação de pedidos", "o usuário tem 50 pedidos", "acessa página 3", "vê pedidos 21-30"],
    ["Pedido sem itens", "um pedido teve todos os itens removidos", "acessa o pedido", "vê mensagem indicando que não há itens"],
    ["Valor total correto", "o pedido tem 2 itens + frete + desconto", "observa o total", "total = subtotal + frete - desconto (calculado corretamente)"],
    ["Status com timeline visual", "o pedido passou por 4 etapas", "observa a timeline", "etapas concluídas estão marcadas em verde"],
    ["Imprimir detalhes do pedido", "os detalhes estão na tela", "clica em 'Imprimir'", "versão para impressão é aberta"],
    ["Busca por número do pedido", "o pedido #789 existe", "busca por '789' na barra de busca", "pedido #789 é encontrado diretamente"],
    ["Pedido com múltiplos pagamentos", "parte do pedido pago com vale + cartão", "observa seção de pagamento", "ambos os métodos são exibidos com valores"],
  ],
  "Avaliações e Comentários" => [
    ["Avaliar produto com 5 estrelas", "o produto foi comprado e entregue", "seleciona 5 estrelas e escreve comentário", "avaliação é publicada com sucesso"],
    ["Avaliar sem ter comprado", "o usuário nunca comprou o produto", "tenta avaliar", "vê mensagem 'Apenas compradores podem avaliar'"],
    ["Editar avaliação", "o usuário já avaliou o produto", "clica em 'Editar' na sua avaliação", "pode alterar nota e comentário"],
    ["Excluir avaliação", "o usuário tem uma avaliação publicada", "clica em 'Excluir' na avaliação", "avaliação é removida após confirmação"],
    ["Moderação de comentários", "um comentário contém palavras ofensivas", "o filtro automático analisa o texto", "comentário é retido para moderação manual"],
    ["Resposta do vendedor", "o vendedor vê uma avaliação negativa", "clica em 'Responder'", "resposta é publicada abaixo da avaliação"],
    ["Ordenar avaliações", "o produto tem 30 avaliações", "ordena por 'Mais recentes'", "avaliações mais recentes aparecem primeiro"],
    ["Filtrar por nota", "o produto tem avaliações de 1 a 5 estrelas", "filtra por '3 estrelas'", "vê apenas avaliações com 3 estrelas"],
    ["Média de avaliações", "o produto tem notas 5, 4, 4, 3, 5", "observa a média", "média exibida é 4.2"],
    ["Avaliação com fotos", "o comprador quer anexar foto", "faz upload de foto junto com avaliação", "foto é exibida junto ao comentário"],
    ["Avaliação duplicada", "o usuário já avaliou este produto", "tenta criar nova avaliação", "vê mensagem 'Você já avaliou este produto'"],
    ["Marcar avaliação como útil", "uma avaliação detalhada existe", "clica em 'Útil'", "contador de utilidade incrementa"],
    ["Denunciar avaliação falsa", "uma avaliação parece fake", "clica em 'Denunciar'", "formulário de denúncia é exibido"],
    ["Paginação de avaliações", "o produto tem 100 avaliações", "acessa página 5", "mostra avaliações 41-50"],
    ["Avaliação sem comentário (só nota)", "o comprador quer avaliar rapidamente", "seleciona 4 estrelas sem texto", "avaliação é salva apenas com a nota"],
  ],
  "Sistema de Favoritos" => [
    ["Adicionar produto aos favoritos", "o produto não está nos favoritos", "clica no ícone de coração", "produto é adicionado e ícone fica preenchido"],
    ["Remover produto dos favoritos", "o produto está nos favoritos", "clica no ícone de coração", "produto é removido e ícone fica vazio"],
    ["Listar favoritos", "o usuário tem 8 produtos favoritos", "acessa /favoritos", "vê grid com os 8 produtos"],
    ["Favoritos com produto indisponível", "um produto favoritado ficou sem estoque", "acessa favoritos", "produto aparece com badge 'Indisponível'"],
    ["Adicionar favorito sem login", "o usuário não está logado", "clica no coração de um produto", "é solicitado login"],
    ["Favoritos persistem entre sessões", "o usuário tem favoritos e faz logout", "faz login novamente", "favoritos ainda estão salvos"],
    ["Compartilhar lista de favoritos", "o usuário tem 5 favoritos", "clica em 'Compartilhar lista'", "link público é gerado"],
    ["Notificação de queda de preço", "um produto favoritado baixou de preço", "o sistema detecta mudança de preço", "usuário recebe notificação"],
    ["Favoritos no mobile", "o usuário acessa pelo celular", "navega pelos favoritos", "layout está adaptado para mobile"],
    ["Limite de favoritos", "o sistema tem limite de 200 favoritos", "usuário tenta adicionar o 201º", "vê aviso de limite atingido"],
    ["Adicionar ao carrinho dos favoritos", "um produto está nos favoritos", "clica em 'Adicionar ao carrinho' na lista", "produto vai para o carrinho e permanece nos favoritos"],
    ["Contagem de favoritos no perfil", "o usuário tem 12 favoritos", "observa seção do perfil", "mostra 'Favoritos (12)'"],
    ["Ordenar favoritos", "existem 15 favoritos", "ordena por 'Menor preço'", "favoritos são reordenados por preço"],
    ["Favoritar variação de produto", "o produto tem 3 cores", "favorita a cor 'Azul'", "apenas a variação azul é favoritada"],
    ["Animação do ícone de favorito", "o coração é clicado", "observa a interface", "ícone tem animação de transição suave"],
    ["Mover favorito para carrinho", "o produto está nos favoritos", "clica em 'Mover para carrinho'", "produto sai dos favoritos e vai para o carrinho"],
  ],
  "Responsividade Mobile" => [
    ["Menu hamburger no mobile", "a tela tem 375px de largura", "acessa a página principal", "menu se transforma em hamburger"],
    ["Tabela responsiva", "uma tabela com 10 colunas é exibida", "acessa pelo celular", "tabela tem scroll horizontal ou layout adaptado"],
    ["Formulário no mobile", "o formulário de checkout está visível", "preenche no celular", "campos ocupam largura total e são fáceis de tocar"],
    ["Imagens responsivas", "a página tem imagens de produtos", "acessa pelo celular", "imagens se adaptam à largura da tela"],
    ["Touch targets adequados", "botões e links estão visíveis", "tenta clicar num botão", "área de toque tem mínimo 44x44px"],
    ["Orientação landscape", "o celular está em portrait", "rotaciona para landscape", "layout se adapta sem quebrar"],
    ["Carregamento em 3G", "a conexão é 3G (1.5mbps)", "acessa a página principal", "página carrega em menos de 5 segundos"],
    ["Scroll horizontal indesejado", "a página foi renderizada no mobile", "tenta scrollar horizontalmente", "não há scroll horizontal (exceto tabelas)"],
    ["Font size legível no mobile", "o texto é exibido no celular", "observa o tamanho da fonte", "fonte tem mínimo 16px em texto principal"],
    ["Cards adaptados no mobile", "o grid tem 4 cards por linha no desktop", "acessa pelo celular", "mostra 1-2 cards por linha"],
    ["Bottom navigation no mobile", "a navegação principal é no topo", "acessa pelo celular", "navegação se adapta (tab bar ou hamburger)"],
    ["Modal responsivo", "um modal é aberto no celular", "observa o modal", "modal ocupa largura adequada e é scrollável"],
    ["Inputs com tipo correto", "campo de email existe no formulário", "toca no campo de email no celular", "teclado de email é exibido (com @)"],
    ["Pull to refresh", "a lista de produtos está carregada", "puxa a tela para baixo", "conteúdo é atualizado"],
    ["Viewport meta tag", "a página é carregada no mobile", "inspeciona o HTML", "meta viewport está configurada corretamente"],
    ["PWA installable", "o site tem manifest.json", "acessa pelo Chrome mobile", "opção 'Instalar app' é exibida"],
  ],
  "Performance e Cache" => [
    ["Cache de queries frequentes", "a query de produtos populares executa frequentemente", "acessa /produtos pela segunda vez", "resposta vem do cache (mais rápida)"],
    ["Invalidação de cache", "o admin atualiza um produto", "outro usuário acessa o produto", "vê dados atualizados (cache invalidado)"],
    ["N+1 queries", "a página lista 20 produtos com categorias", "carrega a página", "apenas 2 queries são feitas (não 21)"],
    ["Tempo de resposta do servidor", "a página é requisitada", "mede o TTFB", "TTFB é menor que 200ms"],
    ["Compressão de assets", "CSS e JS são servidos", "verifica Content-Encoding", "assets vêm comprimidos com gzip ou brotli"],
    ["Lazy loading de imagens", "a página tem 50 produtos com imagens", "carrega a página", "apenas imagens visíveis são carregadas inicialmente"],
    ["CDN para assets estáticos", "imagens e CSS estão no CDN", "verifica URL dos recursos", "servidos por domínio CDN"],
    ["Database indexes", "busca por email de usuário", "executa a query", "usa index e retorna em menos de 5ms"],
    ["Background jobs para tarefas pesadas", "email de confirmação precisa ser enviado", "pedido é criado", "email é enfileirado (não bloqueia a requisição)"],
    ["Connection pooling", "50 requisições simultâneas chegam", "todas requisitam dados do banco", "connection pool gerencia sem esgotar conexões"],
    ["ETag para respostas HTTP", "o recurso não mudou desde o último request", "envia request com If-None-Match", "retorna 304 Not Modified"],
    ["Minificação de CSS/JS", "assets de produção são servidos", "verifica tamanho dos arquivos", "CSS e JS estão minificados"],
    ["Redis como cache store", "o cache store é configurado", "verifica configuração de cache", "Redis está sendo usado como cache backend"],
    ["Tempo de carregamento da página", "a página principal é acessada", "mede com Lighthouse", "Performance score acima de 90"],
    ["Memory leak check", "a aplicação roda por 24h", "monitora uso de memória", "memória se mantém estável sem crescimento contínuo"],
    ["Rate limiting global", "tráfego anômalo chega ao servidor", "100+ requests/segundo de um IP", "rate limiter ativa e retorna 429"],
  ],
  "Exportação de Dados" => [
    ["Exportar usuários em CSV", "existem 100 usuários cadastrados", "admin clica em 'Exportar Usuários CSV'", "arquivo CSV com 100 linhas é baixado"],
    ["Exportar pedidos em Excel", "existem 500 pedidos", "admin seleciona período e clica exportar", "arquivo XLSX é gerado com dados do período"],
    ["Exportar relatório em PDF", "o relatório de vendas está na tela", "clica em 'Exportar PDF'", "PDF formatado é gerado e baixado"],
    ["Exportação assíncrona para grandes volumes", "existem 100.000 registros", "admin solicita exportação", "job é enfileirado e email é enviado quando pronto"],
    ["Formato de data na exportação", "dados contêm datas", "verifica CSV exportado", "datas estão no formato DD/MM/YYYY"],
    ["Encoding UTF-8 no CSV", "dados contêm acentos e caracteres especiais", "abre CSV exportado", "caracteres são exibidos corretamente (UTF-8 com BOM)"],
    ["Filtros aplicados na exportação", "o admin filtrou por 'Janeiro 2024'", "exporta com filtros ativos", "apenas dados filtrados são exportados"],
    ["Cabeçalhos no CSV", "o CSV é exportado", "verifica primeira linha", "contém nomes descritivos das colunas"],
    ["Exportar produtos com categorias", "produtos têm categorias associadas", "exporta lista de produtos", "CSV inclui coluna de categoria"],
    ["Limite de exportação por role", "o role 'viewer' não pode exportar", "viewer tenta exportar", "vê erro 'Sem permissão para exportar'"],
    ["Exportar com campos selecionados", "o formulário permite escolher campos", "seleciona apenas nome e email", "CSV contém apenas as colunas selecionadas"],
    ["Agendamento de exportação", "o admin quer exportação semanal", "configura exportação agendada", "relatório é enviado por email toda segunda"],
    ["Exportar dados do perfil (LGPD)", "o usuário solicita seus dados", "clica em 'Exportar meus dados'", "arquivo com todos os dados pessoais é gerado"],
    ["Performance da exportação", "existem 50.000 registros", "mede tempo de geração", "exportação completa em menos de 30 segundos"],
    ["Exportação com imagens", "produtos têm fotos", "exporta catálogo em PDF", "PDF inclui thumbnails dos produtos"],
    ["Histórico de exportações", "o admin fez 5 exportações", "acessa histórico", "vê lista com data, tipo e status de cada exportação"],
  ],
  "Segurança e CSRF" => [
    ["Token CSRF em formulários", "qualquer formulário é carregado", "inspeciona o HTML", "token CSRF está presente como hidden field"],
    ["Request sem CSRF é rejeitado", "uma requisição POST não tem token CSRF", "envia POST sem token", "retorna 422 Unprocessable Entity"],
    ["XSS em campo de texto", "o campo aceita texto livre", "insere <script>alert('xss')</script>", "HTML é escapado e script não executa"],
    ["SQL Injection protegida", "o campo de busca aceita texto", "insere ' OR 1=1 --", "query usa prepared statements e não é vulnerável"],
    ["HTTPS forçado", "o site é acessado via HTTP", "acessa http://site.com", "é redirecionado para https://site.com"],
    ["Headers de segurança", "qualquer página é carregada", "verifica response headers", "X-Frame-Options, X-Content-Type-Options estão presentes"],
    ["Content Security Policy", "a página é carregada", "verifica header CSP", "CSP está configurado restringindo fontes de conteúdo"],
    ["Cookies seguros", "o cookie de sessão é criado", "inspeciona o cookie", "tem flags Secure, HttpOnly e SameSite"],
    ["Password hashing", "um novo usuário é criado", "verifica banco de dados", "senha está armazenada como hash bcrypt, não plain text"],
    ["Proteção contra clickjacking", "a página é carregada", "verifica X-Frame-Options", "header impede embedding em iframes externos"],
    ["Rate limiting em login", "5 tentativas falhas foram feitas", "tenta 6ª tentativa", "conta é temporariamente bloqueada"],
    ["Sanitização de uploads", "um arquivo malicioso é enviado", "arquivo com extensão dupla .jpg.exe", "arquivo é rejeitado ou extensão é normalizada"],
    ["Logs de segurança", "um ataque de brute force ocorreu", "admin acessa logs de segurança", "tentativas são registradas com IP e timestamp"],
    ["Session fixation protection", "a sessão existia antes do login", "usuário faz login", "session ID é regenerado após autenticação"],
    ["Exposure de informações sensíveis", "uma exceção ocorre em produção", "usuário vê a página de erro", "apenas mensagem genérica é exibida, sem stack trace"],
  ],
  "Internacionalização (i18n)" => [
    ["Idioma padrão PT-BR", "nenhum idioma foi selecionado", "acessa a aplicação", "interface exibida em Português do Brasil"],
    ["Trocar para inglês", "a aplicação está em PT-BR", "seleciona 'English' no seletor", "interface muda para inglês"],
    ["Persistência do idioma", "o usuário selecionou inglês", "fecha e reabre o navegador", "idioma permanece em inglês"],
    ["Datas localizadas", "um pedido foi feito em 15/01/2024", "visualiza no locale EN", "data exibida como 'January 15, 2024'"],
    ["Moeda localizada", "o preço é R$100,00", "visualiza no locale EN", "preço exibido como 'R$100.00' (separador decimal)"],
    ["Mensagens de validação traduzidas", "um campo obrigatório está vazio", "submete formulário em EN", "vê 'can't be blank' ao invés de 'não pode ficar em branco'"],
    ["Pluralização correta", "existe 1 item no carrinho", "observa o counter", "exibe '1 item' (não '1 items')"],
    ["Emails no idioma do usuário", "o usuário usa EN", "recebe email de confirmação", "email está em inglês"],
    ["SEO com idioma", "a página está em PT-BR", "verifica meta tags", "tag lang='pt-BR' está no HTML"],
    ["Fallback para idioma padrão", "uma chave de tradução falta no EN", "acessa funcionalidade sem tradução EN", "exibe texto em PT-BR como fallback"],
    ["Formatação de números", "o valor é 1.234.567,89", "visualiza no locale EN", "exibe como '1,234,567.89'"],
    ["Timezone do usuário", "o usuário está em fuso GMT-3", "visualiza horário de um evento", "horário é exibido no fuso do usuário"],
    ["RTL support", "futuro suporte a idiomas RTL", "verifica CSS para direção", "dir='ltr' está definido no HTML"],
    ["Busca multilíngue", "o produto tem nome em PT e EN", "busca em inglês", "produto é encontrado pelo nome em EN"],
    ["Caracteres especiais em traduções", "textos contêm acentos e cedilha", "renderiza textos em PT-BR", "caracteres são exibidos corretamente"],
    ["Seletor de idioma acessível", "o seletor de idioma existe", "navega com teclado", "seletor é acessível via teclado e screen reader"],
    ["Tradução de enums/status", "o status do pedido é 'shipped'", "visualiza em PT-BR", "exibe 'Enviado'"],
  ],
}

# ============================================================
# Create Test Plans and Scenarios
# ============================================================
bugs = [] # will be populated later, some scenarios link to bugs

test_plans_data.each_with_index do |plan_data, index|
  plan = TestPlan.find_or_create_by!(name: plan_data[:name]) do |tp|
    tp.qa_name = qa_names[index % qa_names.size]
    tp.user = [user, second_user].sample
  end

  # Assign tags
  plan_data[:tags].each do |tag_name|
    tag = Tag.find_or_create_by!(name: tag_name.downcase)
    TestPlanTag.find_or_create_by!(test_plan: plan, tag: tag)
  end

  # Create scenarios
  plan_scenarios = scenarios_by_plan[plan_data[:name]] || []
  plan_scenarios.each_with_index do |scenario_data, pos|
    title, given, when_step, then_step = scenario_data
    TestScenario.find_or_create_by!(test_plan: plan, title: title) do |ts|
      ts.given = given
      ts.when_step = when_step
      ts.then_step = then_step
      ts.position = pos
      # Distribute statuses: ~60% approved, ~25% pending, ~15% failed
      ts.status = case
                  when pos % 7 == 0 then "failed"
                  when pos % 4 == 0 then "pending"
                  else "approved"
                  end
    end
  end

  puts "  Plan #{index + 1}/25: #{plan_data[:name]} (#{plan_scenarios.size} scenarios)"
end

# ============================================================
# 15 Bugs (all fields filled except evidence)
# distributed among 10 feature_tags and 8 cause_tags
# ============================================================
bugs_data = [
  {
    title: "Login falha com email contendo caractere +",
    description: "Ao tentar logar com email que contém '+' (ex: user+test@email.com), o sistema retorna erro 500 ao invés de autenticar normalmente.",
    steps_to_reproduce: "1. Cadastrar conta com email user+test@email.com\n2. Fazer logout\n3. Tentar logar com user+test@email.com\n4. Observar erro 500",
    expected_result: "Login deve ser realizado normalmente com qualquer email válido RFC 5322",
    obtained_result: "Retorna erro 500 - Internal Server Error. O parser de email não reconhece o caractere '+' e quebra a query.",
    status: "open",
    feature_tag: "autenticação",
    cause_tag: "validação"
  },
  {
    title: "Carrinho não recalcula total ao remover último cupom",
    description: "Quando o usuário remove o cupom de desconto, o valor total do carrinho mantém o desconto aplicado até dar refresh na página.",
    steps_to_reproduce: "1. Adicionar produtos ao carrinho\n2. Aplicar cupom DESCONTO10\n3. Verificar que total foi reduzido\n4. Clicar em 'Remover cupom'\n5. Observar que o total não atualiza",
    expected_result: "Total do carrinho deve ser recalculado imediatamente ao remover o cupom, refletindo o valor sem desconto",
    obtained_result: "Total permanece com desconto. O AJAX de remoção remove o cupom no backend mas não atualiza o DOM com o novo total.",
    status: "open",
    feature_tag: "carrinho",
    cause_tag: "lógica"
  },
  {
    title: "Timeout no checkout com PIX em horário de pico",
    description: "Entre 19h e 22h, a geração de QR Code PIX frequentemente excede o timeout de 30 segundos, resultando em erro para o usuário.",
    steps_to_reproduce: "1. Adicionar itens ao carrinho\n2. Ir para checkout entre 19h-22h\n3. Selecionar PIX como pagamento\n4. Aguardar geração do QR Code\n5. Observar timeout após 30s",
    expected_result: "QR Code PIX deve ser gerado em menos de 5 segundos, independente do horário",
    obtained_result: "Request atinge timeout de 30s. O gateway de pagamento demora para responder em horários de pico e não há retry automático configurado.",
    status: "open",
    feature_tag: "checkout",
    cause_tag: "performance"
  },
  {
    title: "Dashboard mostra métricas duplicadas após filtrar por período",
    description: "Ao aplicar filtro de período no dashboard, alguns cards de métricas mostram valores duplicados (somam o período filtrado com o período anterior).",
    steps_to_reproduce: "1. Acessar dashboard administrativo\n2. Observar métricas do mês atual\n3. Filtrar por 'Última semana'\n4. Observar que o card 'Vendas' mostra valor maior que o esperado",
    expected_result: "Métricas devem refletir exclusivamente o período selecionado",
    obtained_result: "O card 'Vendas' mostra valor do mês + semana. A query não substitui o filtro de data, ela adiciona uma condição OR ao invés de AND.",
    status: "open",
    feature_tag: "dashboard",
    cause_tag: "lógica"
  },
  {
    title: "Notificação push não chega em dispositivos iOS 17+",
    description: "Usuários com iOS 17 ou superior não recebem notificações push. O token de push registrado é rejeitado silenciosamente pela APNs.",
    steps_to_reproduce: "1. Instalar app no iPhone com iOS 17+\n2. Aceitar permissões de notificação\n3. Realizar uma compra\n4. Aguardar notificação de confirmação\n5. Notificação não chega",
    expected_result: "Notificação push deve chegar em todos os dispositivos iOS suportados (iOS 15+)",
    obtained_result: "Notificação não é entregue. O log do servidor mostra 'InvalidDeviceToken'. O formato do token mudou no iOS 17 e o backend não trata o novo formato.",
    status: "open",
    feature_tag: "notificações",
    cause_tag: "integração"
  },
  {
    title: "Relatório PDF gera página em branco quando não há dados",
    description: "Ao exportar relatório de um período sem vendas, o PDF gerado contém apenas uma página em branco ao invés de mostrar mensagem informativa.",
    steps_to_reproduce: "1. Acessar relatórios financeiros\n2. Selecionar período sem vendas (ex: feriado)\n3. Clicar em 'Exportar PDF'\n4. Abrir PDF gerado",
    expected_result: "PDF deve conter cabeçalho do relatório e mensagem 'Sem dados para o período selecionado'",
    obtained_result: "PDF contém apenas uma página em branco. O template Prawn não renderiza nada quando a collection está vazia.",
    status: "resolved",
    feature_tag: "relatórios",
    cause_tag: "lógica"
  },
  {
    title: "Campo de telefone aceita letras no formulário de perfil",
    description: "O campo de telefone no perfil do usuário aceita letras e caracteres especiais, permitindo salvar valores inválidos como '(abc) defgh-ijkl'.",
    steps_to_reproduce: "1. Acessar perfil do usuário\n2. No campo telefone, digitar 'abcdefghijk'\n3. Clicar em 'Salvar'\n4. Telefone inválido é salvo com sucesso",
    expected_result: "Campo deve aceitar apenas dígitos e formatação de telefone válida. Validação client-side e server-side deve rejeitar letras.",
    obtained_result: "Telefone 'abcdefghijk' é salvo sem erro. Não existe validação de formato no model nem máscara de input no frontend.",
    status: "open",
    feature_tag: "perfil-usuário",
    cause_tag: "validação"
  },
  {
    title: "Busca não retorna resultados para termos com acento",
    description: "A busca por produtos com acentos (ex: 'café', 'pão') não retorna resultados, enquanto a busca sem acento ('cafe', 'pao') funciona normalmente.",
    steps_to_reproduce: "1. Cadastrar produto 'Café Premium'\n2. Buscar por 'café'\n3. Nenhum resultado é retornado\n4. Buscar por 'cafe'\n5. Produto é encontrado",
    expected_result: "Busca deve ser accent-insensitive, retornando resultados tanto com 'café' quanto com 'cafe'",
    obtained_result: "Busca por 'café' retorna 0 resultados. O LIKE do SQLite é case-insensitive mas não é accent-insensitive. Falta uso de UNACCENT ou normalização.",
    status: "open",
    feature_tag: "busca",
    cause_tag: "lógica"
  },
  {
    title: "Imagem do produto não carrega após migração para S3",
    description: "Após a migração do storage local para S3, imagens de produtos cadastrados anteriormente retornam 404. Apenas novos uploads funcionam.",
    steps_to_reproduce: "1. Acessar produto cadastrado antes da migração\n2. Observar que a imagem retorna 404\n3. Verificar URL da imagem (aponta para S3)\n4. Verificar que o arquivo não existe no bucket",
    expected_result: "Todas as imagens devem estar acessíveis, independente de quando foram cadastradas. Migração deveria ter copiado arquivos.",
    obtained_result: "Imagens antigas retornam 404. O script de migração copiou apenas blobs com created_at > data da migração, ignorando registros anteriores.",
    status: "open",
    feature_tag: "catálogo",
    cause_tag: "migração"
  },
  {
    title: "Pagamento duplicado em conexões instáveis",
    description: "Em conexões instáveis (3G/edge), o botão 'Pagar' pode ser clicado múltiplas vezes antes do servidor responder, resultando em cobranças duplicadas.",
    steps_to_reproduce: "1. Throttle conexão para 3G no DevTools\n2. Adicionar itens e ir para checkout\n3. Clicar em 'Pagar' 3 vezes rapidamente\n4. Verificar que 3 cobranças foram geradas",
    expected_result: "Apenas uma cobrança deve ser processada. Botão deve ser desabilitado após primeiro clique e backend deve ter chave de idempotência.",
    obtained_result: "3 cobranças de mesmo valor aparecem no extrato. Não há idempotency key no request ao gateway nem desabilitação do botão no frontend.",
    status: "open",
    feature_tag: "pagamentos",
    cause_tag: "concorrência"
  },
  {
    title: "Dashboard admin acessível com token de usuário expirado em cache",
    description: "Após a sessão expirar, se a página do dashboard estiver no cache do service worker, o admin ainda consegue visualizar dados sensíveis sem reautenticação.",
    steps_to_reproduce: "1. Logar como admin e acessar dashboard\n2. Aguardar sessão expirar (ou forçar expiração)\n3. Fechar e reabrir aba do dashboard\n4. Página é carregada do cache do SW com dados",
    expected_result: "Páginas com dados sensíveis não devem ser cacheadas pelo service worker. Ao reabrir, deve redirecionar para login.",
    obtained_result: "Dashboard é exibido com dados do cache. O service worker está configurado com cache-first para todas as rotas, incluindo /admin.",
    status: "open",
    feature_tag: "dashboard",
    cause_tag: "configuração"
  },
  {
    title: "Webhook de pagamento falha silenciosamente com payload V2",
    description: "Após atualização do gateway de pagamento para API V2, os webhooks de confirmação chegam com estrutura JSON diferente e são descartados sem erro.",
    steps_to_reproduce: "1. Realizar pagamento que é processado pelo gateway V2\n2. Gateway envia webhook com payload no formato V2\n3. Verificar que o pedido permanece como 'pendente'\n4. Verificar logs: nenhum erro registrado",
    expected_result: "Webhook deve processar payloads tanto V1 quanto V2, atualizando o status do pedido para 'pago'",
    obtained_result: "Pedido fica em 'pendente' indefinidamente. O controller de webhook faz `params[:transaction][:status]` mas no V2 o caminho é `params[:data][:attributes][:status]`.",
    status: "open",
    feature_tag: "pagamentos",
    cause_tag: "integração"
  },
  {
    title: "Relatório mensal inclui dados do primeiro dia do mês seguinte",
    description: "O relatório de vendas de janeiro inclui vendas feitas em 01/02 às 00:00-02:59 (3h da manhã). O filtro de data não leva em conta o timezone.",
    steps_to_reproduce: "1. Criar venda em 01/02/2024 às 01:00 BRT\n2. Acessar relatório de Janeiro/2024\n3. Venda de 01/02 aparece no relatório de Janeiro",
    expected_result: "Relatório de Janeiro deve incluir apenas vendas de 01/01 00:00 a 31/01 23:59 no timezone do sistema (BRT)",
    obtained_result: "Vendas de 01/02 até 02:59 BRT aparecem em Janeiro. A query usa `created_at < '2024-02-01'` em UTC, mas BRT é UTC-3, então 01/02 00:00 BRT = 01/02 03:00 UTC.",
    status: "resolved",
    feature_tag: "relatórios",
    cause_tag: "lógica"
  },
  {
    title: "Race condition ao aprovar cenários simultâneos via API",
    description: "Quando dois QAs aprovam cenários do mesmo plano de teste simultaneamente via API, o counter cache de cenários aprovados fica inconsistente.",
    steps_to_reproduce: "1. Plano de teste com 10 cenários pendentes\n2. QA1 e QA2 aprovam cenários diferentes ao mesmo tempo\n3. Verificar counter de cenários aprovados\n4. Counter mostra valor incorreto (ex: 1 ao invés de 2)",
    expected_result: "Counter cache deve refletir o número real de cenários aprovados, mesmo com atualizações concorrentes",
    obtained_result: "Counter cache fica inconsistente. O update usa read-modify-write sem lock, causando lost update em concorrência.",
    status: "open",
    feature_tag: "autenticação",
    cause_tag: "concorrência"
  },
  {
    title: "Variáveis de ambiente de staging expostas em erro 500",
    description: "Em ambiente de staging, quando ocorre erro 500, a página de erro exibe o stack trace completo incluindo variáveis de ambiente com secrets.",
    steps_to_reproduce: "1. Acessar endpoint que causa erro em staging\n2. Observar página de erro\n3. Stack trace inclui ENV vars com API keys e DATABASE_URL",
    expected_result: "Mesmo em staging, erros 500 não devem exibir variáveis de ambiente sensíveis. Usar página de erro genérica ou filtrar secrets.",
    obtained_result: "Página de erro exibe DATABASE_URL, SECRET_KEY_BASE, PAYMENT_API_KEY em plain text. config.consider_all_requests_local = true em staging.",
    status: "resolved",
    feature_tag: "dashboard",
    cause_tag: "configuração"
  },
]

bugs_data.each_with_index do |bug_data, index|
  bug = Bug.find_or_create_by!(title: bug_data[:title]) do |b|
    b.description = bug_data[:description]
    b.steps_to_reproduce = bug_data[:steps_to_reproduce]
    b.expected_result = bug_data[:expected_result]
    b.obtained_result = bug_data[:obtained_result]
    b.status = bug_data[:status]
    b.feature_tag = bug_data[:feature_tag]
    b.cause_tag = bug_data[:cause_tag]
    b.user = [user, second_user].sample
  end
  bugs << bug
  puts "  Bug #{index + 1}/15: #{bug_data[:title][0..50]}..."
end

# ============================================================
# Link some bugs to failed scenarios
# ============================================================
failed_scenarios = TestScenario.where(status: "failed").to_a.shuffle

bugs.each_with_index do |bug, i|
  scenario = failed_scenarios[i]
  next unless scenario
  scenario.update!(bug: bug)
  puts "  Linked Bug ##{bug.id} to Scenario '#{scenario.title[0..40]}...'"
end

puts ""
puts "=== Seed complete ==="
puts "  Users: #{User.count}"
puts "  Test Plans: #{TestPlan.count}"
puts "  Test Scenarios: #{TestScenario.count}"
puts "  Bugs: #{Bug.count}"
puts "  Tags: #{Tag.count}"
puts "  Feature tags: #{Bug.pluck(:feature_tag).uniq.compact.sort.join(', ')}"
puts "  Cause tags: #{Bug.pluck(:cause_tag).uniq.compact.sort.join(', ')}"
