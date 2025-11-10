FROM node:18-alpine

WORKDIR /app
COPY package.json .
COPY /chess-server/server.js .

RUN npm install

EXPOSE 29801

CMD ["node", "server.js"]