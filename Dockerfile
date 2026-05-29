FROM nginx:latest

# Copy webpages
COPY webpages /usr/share/nginx/html

# Copy start script
COPY start.sh /start.sh

# Make executable
RUN chmod +x /usr/share/nginx/html/rotate-pages.sh
RUN chmod +x /start.sh 
# Remove default index
RUN rm -f /usr/share/nginx/html/index.nginx-debian.html

# Start both services
CMD ["/start.sh"]
