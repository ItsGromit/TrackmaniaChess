FROM node:18-alpine

WORKDIR /app
COPY /package.json .
COPY /server.js .
COPY /src ./src

RUN npm install

# Railway commonly routes to container port 8080; expose it to match runtime
EXPOSE 8080

CMD ["node", "server.js"]