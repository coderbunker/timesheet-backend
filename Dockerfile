FROM overhandtech/alpine-node-build as build-deps
WORKDIR /src
COPY package.json .
RUN apk add  postgresql-dev \
	 && apk add make \
	 && apk add perl-utils  \
	 && apk add python3 \
	 && apk add git
RUN npm install 
RUN  pip install pgxnclient
RUN pgxn install pgtap
RUN rm package.json
COPY . .
EXPOSE 3000
RUN chmod +x docker-scripts/docker-entrypoint.sh
RUN chmod +x docker-scripts/run-development.sh

ENTRYPOINT ["docker-scripts/docker-entrypoint.sh"]
