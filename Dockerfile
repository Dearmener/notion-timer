# 1. 使用官方的 node 镜像作为基础镜像
FROM node:18

# 2. 设置工作目录
WORKDIR /app

# 3. 复制 package.json 和 package-lock.json 以安装依赖
COPY package*.json ./

# 4. 安装依赖
RUN npm install

# 5. 复制项目所有文件
COPY . .

# 6. 开放 Vue 开发服务器默认端口 5173
EXPOSE 5173

# 7. 运行开发服务器
CMD ["npm", "run", "dev"]
