FROM node:18-alpine

WORKDIR /app
COPY /server/package.json .
COPY /server/server.js .
COPY /server/src ./src

RUN npm install

# Railway commonly routes to container port 8080; expose it to match runtime
EXPOSE 8080

CMD ["node", "server.js"]