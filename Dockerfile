FROM overhandtech/alpine-node-build as build-deps
WORKDIR /src
RUN npm install


FROM python:3-alpine
WORKDIR /src 
RUN apk add  postgresql-dev \
	 && apk add make \
	 && apk add perl \
	 && apk add perl-app-cpanminus
  
RUN  pip install pgxnclient
RUN pgxn install pgtap
COPY . .
EXPOSE 3000
RUN chmod +x docker-scripts/docker-entrypoint.sh
ENTRYPOINT ["docker-scripts/docker-entrypoint.sh"]
