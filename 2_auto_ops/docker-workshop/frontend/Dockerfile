# สำหรับการสอนใน Workshop จะใช้โหมด Development เพื่อให้เห็นการทำงานได้ง่าย
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN yarn install

COPY . .

EXPOSE 3000

# รัน React Dev Server
CMD ["yarn", "run", "dev"]
