FROM node:18-alpine

WORKDIR /app
COPY /chess-server/package.json .
COPY /chess-server/server.js .

RUN npm install

# Railway commonly routes to container port 8080; expose it to match runtime
EXPOSE 8080

CMD ["node", "server.js"]