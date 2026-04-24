# Ponto de partida — imagem oficial do Node.js versão leve (alpine)
# Alpine é uma distribuição Linux minimalista, a imagem fica ~50MB ao invés de ~900MB
FROM node:18-alpine

# Define o diretório de trabalho dentro do container
# Todos os comandos seguintes rodam a partir daqui
WORKDIR /app

# Copia o arquivo da aplicação para dentro do container
COPY app.js .

# Expõe a porta que a aplicação usa
# Isso é documentação — não abre a porta, apenas informa que ela será usada
EXPOSE 3000

# Comando que roda quando o container inicia
CMD ["node", "app.js"]