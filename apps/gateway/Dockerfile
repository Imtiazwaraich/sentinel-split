FROM nginx:alpine

# Remove default nginx config
RUN rm /etc/nginx/nginx.conf

# Copy our nginx configuration template
COPY nginx.conf.template /etc/nginx/nginx.conf.template

# Copy entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
