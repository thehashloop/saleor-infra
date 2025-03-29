# saleor-infra



chmod +x bootstrap-secrets.sh

https://docs.digitalocean.com/reference/doctl/how-to/install/


sudo apt install jq -y


git clone https://github.com/saleor/storefront.git saleor-storefront

In the saleor-storefront directory, ensure the Dockerfile is present:

FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
ARG NEXT_PUBLIC_SALEOR_API_URL
ENV NEXT_PUBLIC_SALEOR_API_URL=$NEXT_PUBLIC_SALEOR_API_URL
RUN npm run build
CMD ["npm", "start"]