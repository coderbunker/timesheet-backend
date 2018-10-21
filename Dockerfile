FROM node:alpine as build-deps
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install

FROM node:alpine

WORKDIR /usr/src/app
COPY --from=build-deps /usr/src/app/node_modules /usr/src/app/node_modules
COPY . .
EXPOSE 3000
CMD ["npm", "start"]